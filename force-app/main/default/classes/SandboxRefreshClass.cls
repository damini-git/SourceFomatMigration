public with sharing class SandboxRefreshClass {
    
    @future(callout=true)
    public static void fetchSandboxInfo(Id orgId) {
        Org__c sand = [SELECT Id, Name, Domain_URL__c, Access_Token__c, Org_Id__c, Production_Org__c, Org_Type__c, Sandbox_Info_Id__c, License_Type__c FROM Org__c where Id =: orgId];
        system.debug('Org Type --- ' + sand.Org_Type__c);
        String domainUrl;
        String accessToken;
        String orgIdOfSandbox = sand.Org_Id__c;    
        
        if(sand.Org_Type__c == 'Production'){
            domainUrl = sand.Domain_URL__c;
            accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        }
        if(sand.Org_Type__c == 'Sandbox'){
            Org__c prodOrg = [select Id, Name, Domain_Url__c from Org__c where Id =: sand.Production_Org__c];
            domainUrl = prodOrg.Domain_URL__c;
            accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(prodOrg.Id);
        }
        
        String endpoint = domainUrl + '/services/data/v59.0/tooling/query?q=SELECT+Id,SandboxOrganization,LicenseType,SandboxName,SandboxInfoId+FROM+SandboxProcess';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000); // Set timeout to 2 minutes
        
        HttpResponse res;
        Http http = new Http();
        res = http.send(req);
        
        String body;
        Integer statusCode;
        String newAccessToken;
        
        String statusToReturn;
        
        List<Org__c> lToUpdate = new List<Org__c>();
        
        if(!Test.isRunningTest()){ if (res.getStatusCode() == 200) { body = res.getBody();
                                                                   }
                                 }
        else{ body = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"SandboxProcess","records":[{"attributes":{"type":"SandboxProcess","url":"/services/data/v59.0/tooling/sobjects/SandboxProcess/0GR6g00000095ASGAY"},"Id":"0GR6g00000095ASGAY","LicenseType":"DEVELOPER","SandboxName":"DEV","SandboxInfoId":"0GQ6g000000kCP3GAM"}]}';
            }
        
        if (!String.isEmpty(body)) {
            system.debug('body --- ' + body);
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(body);
            List<Object> records = (List<Object>) responseBody.get('records');
            system.debug('records --- ' + records);
            
            for (Object record : records) {
                Map<String, Object> sandboxInfo = (Map<String, Object>) record;
                String sandboxName = (String) sandboxInfo.get('SandboxName');
                String sandboxOrgId = (String) sandboxInfo.get('SandboxOrganization');
                String licenseType = (String) sandboxInfo.get('LicenseType');
                String sandboxInfoId = (String) sandboxInfo.get('SandboxInfoId');
                system.debug('sandboxName --- ' + sandboxName + ', sandboxOrgId --- ' + sandboxOrgId + ', sandboxInfoId --- ' + sandboxInfoId + ', licenseType --- ' + licenseType);
                
                if(sandboxOrgId == orgIdOfSandbox){
                    statusToReturn = 'Sandbox Info fetched successfully...';
                    sand.Sandbox_Info_Id__c = sandboxInfoId;
                    sand.License_Type__c = licenseType;
                    lToUpdate.add(sand);
                    break;
                }
            }
            if (lToUpdate.size() > 0) { update lToUpdate;
                                      }
            
        } else {
            System.debug('Error: ' + res.getStatus() + ' --- ' + res.getStatusCode());
            system.debug('Error Body: ' + res.getBody());
        }
    }
    
    @AuraEnabled
    public static Id callRefreshSandboxQueueable(Id selectedSourceForRefresh, Id templateId, String sandboxName, String description, boolean autoActivate, String apexClassName, Id publicGroupId){
        String orgName = [select Id, Name from Org__c where Id =: selectedSourceForRefresh].Name;
        system.debug('Org to be refreshed --- ' + orgName);
        
        String templateName = [select Id, Name from Refresh_Template__c where Id =: templateId].Name;
        system.debug('Template to be used for Refresh --- ' + templateName);
        
        Id apexClassId = null;
        if(!String.isEmpty(apexClassName)){
            apexClassId = fetchApexClassIdFromSource(selectedSourceForRefresh, apexClassName);
        }
        system.debug('apexClassId --- ' + apexClassId);
        system.debug('publicGroupId --- ' + publicGroupId);
        
        Logs__c refreshLog = new Logs__c();
        refreshLog.Log_type__c = 'Sandbox Refresh';
        refreshLog.Status__c = 'InProgress';
        refreshLog.Parent_Template__c = templateId;
        refreshLog.Source_Org_For_Refresh__c = selectedSourceForRefresh;
        if(publicGroupId != null){
            refreshLog.Last_Refreshed_Public_Group_Id__c = publicGroupId;
        }
        refreshLog.Last_Refreshed_Apex_Class_Name__c = (!String.isEmpty(apexClassName)) ? apexClassName : '';
        insert refreshLog;
        
        System.enqueueJob(new RefreshSandboxQueueable(selectedSourceForRefresh, templateId, sandboxName, description, autoActivate, apexClassId, publicGroupId, refreshLog.Id));
        return refreshLog.Id;
    }
    
    public class RefreshSandboxQueueable implements Queueable, Database.AllowsCallouts {
        private Id selectedSourceForRefresh;
        private Id templateId;
        private Id refreshLogId;
        private String sandboxName;
        private String description;
        private boolean autoActivate;
        private Id apexClassId;
        private Id publicGroupId;
        
        public RefreshSandboxQueueable(Id selectedSourceForRefresh, Id templateId, String sandboxName, String description, Boolean autoActivate, Id apexClassId, Id publicGroupId, Id refreshLogId) {
            this.selectedSourceForRefresh = selectedSourceForRefresh;
            this.templateId = templateId;
            this.sandboxName = sandboxName;
            this.description = description;
            this.autoActivate = autoActivate;
            this.apexClassId = apexClassId;
            this.publicGroupId = publicGroupId;
            this.refreshLogId = refreshLogId;
        }
        
        public void execute(QueueableContext context) {
            system.debug('inside refreshSandbox');
            String refreshStatus;
            String version = '62.0';
            String endpoint;
            
            Logs__c refreshLog = [select Id, Status__c, Details__c from Logs__c where Id =: refreshLogId];
            Refresh_Template__c refTemp = [select Id, Name, Source_Refresh_Org__c, Source_Org__c, Last_Run_Status__c, Parent_Org__c from Refresh_Template__c where Id =: templateId];
            
            Org__c sourceOrg = [select Id, Name, Domain_Url__c, License_Type__c, Sandbox_Info_Id__c, Org_Type__c from Org__c where Id =: selectedSourceForRefresh];
            system.debug('source org name --- ' + sourceOrg.Name + ' --- source org sandbox info id --- ' + sourceOrg.Sandbox_Info_Id__c);
            Org__c sandTarget = [SELECT Id, Domain_URL__c, Access_Token__c, Sandbox_Info_Id__c, Production_Org__c, License_Type__c FROM Org__c WHERE Id =: refTemp.Parent_Org__c];
            Org__c prodOrg = new Org__c();
            if(sourceOrg.Org_Type__c == 'Sandbox'){ prodOrg = [select Id, Name, Domain_Url__c, Access_Token__c from Org__c where Id =: sandTarget.Production_Org__c];
                system.debug('prodOrg Name --- ' + prodOrg.Name);
            }
            
            String domainUrl;
            String accessToken;
            if(sourceOrg.Org_Type__c == 'Sandbox'){ domainUrl = prodOrg.Domain_URL__c; accessToken = Test.isRunningTest() ? '123456789abcd' : RefreshTokenCallout.fetchAT1(prodOrg.Id);
            }
            else{
                domainUrl = sourceOrg.Domain_URL__c;
                accessToken = Test.isRunningTest() ? '123456789abcd' : RefreshTokenCallout.fetchAT1(sourceOrg.Id);
            }
            
            try {
                if (accessToken != null) {
                    Http htr = new Http();
                    HttpRequest reqref = new HttpRequest();
                    reqref.setMethod('PATCH');
                    endpoint = domainUrl + '/services/data/v' + version + '/tooling/sobjects/SandboxInfo/' + sandTarget.Sandbox_Info_Id__c;
                    reqref.setEndpoint(endpoint);
                    reqref.setHeader('Content-Type', 'application/json');
                    reqref.setHeader('Authorization', 'Bearer ' + accessToken);
                    reqref.setTimeout(120000);
                    
                    system.debug('auto activate --- ' + autoActivate);
                    //publicGroupId = (publicGroupId == null) ? '' : publicGroupId;
                    system.debug('publicGroupId --- ' + publicGroupId);
                    system.debug('apexClassId --- ' + apexClassId);
                    String body;
                    if(sourceOrg.Org_Type__c == 'Production'){
                        system.debug('inside production org type body --- ');
                        body = '{ "LicenseType": "' + sourceOrg.License_Type__c + '", "SandboxName": "'+ sandboxName +'", "Description": "'+ description +'", "AutoActivate" : "'+ autoActivate +'", "ActivationUserGroupId": "'+ publicGroupId +'"';
                    }
                    else if(sourceOrg.Org_Type__c == 'Sandbox' && publicGroupId == null){
                        system.debug('inside sandbox org type body --- ');
                        body = '{ "LicenseType": "' + sourceOrg.License_Type__c + '", "SourceId": "'+ sourceOrg.Sandbox_Info_Id__c +'", "SandboxName": "'+ sandboxName +'", "Description": "'+ description +'", "AutoActivate" : "'+ autoActivate +'", "ActivationUserGroupId": ""';
                    }
                    else if(sourceOrg.Org_Type__c == 'Sandbox' && publicGroupId != null){
                        system.debug('inside sandbox org type body --- ');
                        body = '{ "LicenseType": "' + sourceOrg.License_Type__c + '", "SourceId": "'+ sourceOrg.Sandbox_Info_Id__c +'", "SandboxName": "'+ sandboxName +'", "Description": "'+ description +'", "AutoActivate" : "'+ autoActivate +'", "ActivationUserGroupId": "'+ publicGroupId +'"';
                    }
                    
                    /*if(publicGroupId != null){
                        system.debug('adding public group id to sandbox refresh call --- ');
                        body += ', "ActivationUserGroupId": "'+ publicGroupId +'"';
                    }*/
                    if(apexClassId != null){
                        system.debug('adding apex class id to sandbox refresh call --- ');
                        body += ', "ApexClassId": "'+ apexClassId +'"';
                    }
                    body += ' }';
                    system.debug('body before hitting the api -------- ' + body);
                    reqref.setBody(body);
                    
                    HttpResponse resref = Test.isRunningTest() ? new HttpResponse() : htr.send(reqref);
                    system.debug('refresh response --- ' + resref);
                    Integer refstatus = Test.isRunningTest() ? 204 : resref.getStatusCode();
                    system.debug('refstatusCode --- ' + refstatus + ', ref Status --- ' + resref.getStatus());
                    
                    if (refstatus == 204) {
                        refreshStatus = 'Sandbox refresh initiated';
                        //sand.Status__c = 'Processing';
                        sandTarget.Last_Refresh__c = System.now();
                        sandTarget.Last_Refresh_By__c = UserInfo.getUserId();
                        if(sandTarget.License_Type__c  == 'DEVELOPER'){ sandTarget.Next_Refresh_Available__c = system.now().addDays(1);
                        }
                        if(sandTarget.License_Type__c  == 'DEVELOPER_PRO'){ sandTarget.Next_Refresh_Available__c = system.now().addDays(1);
                        }
                        if(sandTarget.License_Type__c  == 'PARTIAL'){ sandTarget.Next_Refresh_Available__c = system.now().addDays(5);
                        }
                        if(sandTarget.License_Type__c  == 'FULL'){ sandTarget.Next_Refresh_Available__c = system.now().addDays(29);
                        }
                        //sandTarget.Refresh_Token__c = '';
                        //sandTarget.Access_Token__c = '';
                        update sandTarget;
                        
                        refTemp.Last_Run_Status__c = 'InProgress';
                        refTemp.Source_Refresh_Org__c = sourceOrg.Name;
                        refTemp.Source_Org__c = sourceOrg.Id;
                        refTemp.Last_Refreshed_By__c = UserInfo.getUserId();
                        refTemp.Last_Refreshed_Date__c = system.now();
                        update refTemp;
                        
                        refreshLog.Status__c = 'InProgress';
                        refreshLog.Last_Refresh_Request_By__c = UserInfo.getUserId();
                        refreshLog.Last_Refreshed_Date__c = system.now();
                        if(sandTarget.License_Type__c  == 'DEVELOPER'){ refreshLog.Next_Refresh_Available__c = system.now().addDays(1);
                        }
                        if(sandTarget.License_Type__c  == 'DEVELOPER_PRO'){ refreshLog.Next_Refresh_Available__c = system.now().addDays(1);
                        }
                        if(sandTarget.License_Type__c  == 'PARTIAL'){ refreshLog.Next_Refresh_Available__c = system.now().addDays(5);
                        }
                        if(sandTarget.License_Type__c  == 'FULL'){ refreshLog.Next_Refresh_Available__c = system.now().addDays(29);
                        }
                        update refreshLog;
                    } else {
                        System.JSONParser json = Json.createParser(resref.getBody());
                        while (json.nextToken() != null) {
                            if (json.getText() == 'message') {
                                json.nextToken(); 
                                refreshStatus = json.getText();
                                system.debug('refreshStatus else --- ' + refreshStatus);
                            }
                        }
                        
                        if(resref.getStatus() == 'Forbidden'){
                            sandTarget.Last_Refresh_Status__c = 'Forbidden';
                            
                            refTemp.Last_Run_Status__c = 'Forbidden';
                            refTemp.Source_Refresh_Org__c = sourceOrg.Name;
                            refTemp.Source_Org__c = sourceOrg.Id;
                            
                            refreshLog.Status__c = 'Forbidden';
                            refreshLog.Details__c = refreshStatus;
                        }
                        else{
                            refTemp.Last_Run_Status__c = 'Refresh Failed';
                            refTemp.Source_Refresh_Org__c = sourceOrg.Name;
                            refTemp.Source_Org__c = sourceOrg.Id;
                            
                            refreshLog.Status__c = 'Failed';
                            refreshLog.Details__c = refreshStatus;
                        }
                        
                        update sandTarget;
                        update refTemp;
                        update refreshLog;
                    }
                }
                system.debug('refreshStatus in try block --- ' + refreshStatus);
            } catch (Exception e) {
                refreshStatus = e.getMessage();
                /*refreshLog.Status__c = 'Failed';
				refreshLog.Details__c = e.getMessage();
                refreshLog.Last_Refresh_Request_By__c = UserInfo.getUserId();
                update refreshLog;*/
                system.debug('catch block refreshStatus --- ' + refreshStatus);
            }
        }
    }
    
    @AuraEnabled
    public static String getSandboxStatus(Id logRecordId, Id templateId) {
        String sbxstatus;
        String endpoint;
        String version = '57.0';
        
        Logs__c refreshLog = [select Id, Status__c, Details__c, Parent_Template__c, Log_Type__c, Source_Org_For_Refresh__c, Completed_On__c from Logs__c where Id =: logRecordId];
        
        Refresh_Template__c refTemp = [select Id, Name, Source_Refresh_Org__c, Source_Org__c, Last_Run_Status__c, Parent_Org__c from Refresh_Template__c where Id =: templateId];
        
        Org__c sourceOrg = [select Id, Name, Domain_Url__c, Org_Type__c from Org__c where Id =: refreshLog.Source_Org_For_Refresh__c];
        Org__c sandTarget = [SELECT Id, Name, Domain_URL__c, Access_Token__c, Sandbox_Info_Id__c, Production_Org__c FROM Org__c WHERE Id =: refTemp.Parent_Org__c];
        system.debug('Target Sandbox/Refreshed Sandbox Name --- ' + sandTarget.Name);
        Org__c prodOrg = new Org__c();
        if(sourceOrg.Org_Type__c == 'Sandbox'){ prodOrg = [select Id, Name, Domain_Url__c, Access_Token__c from Org__c where Id =: sandTarget.Production_Org__c];
            system.debug('prodOrg Name --- ' + prodOrg.Name);
        }
        
        String domainUrl;
        String accessToken;
        system.debug('sourceOrg.Org_Type__c --- ' + sourceOrg.Org_Type__c);
        if(sourceOrg.Org_Type__c == 'Sandbox'){ domainUrl = prodOrg.Domain_URL__c; accessToken = Test.isRunningTest() ? '123456789abcd' : RefreshTokenCallout.fetchAT1(prodOrg.Id);
        }
        else{
            domainUrl = sourceOrg.Domain_URL__c;
            accessToken = Test.isRunningTest() ? '123456789abcd' : RefreshTokenCallout.fetchAT1(sourceOrg.Id);
        }
        system.debug('domain url before fetching sandbox process --- ' + domainUrl);
        
        try {
            //String accessToken = Test.isRunningTest() ? '123456789abcd' : RefreshTokenCallout.fetchAT1(sourceOrg.Id);
            system.debug('accessToken --- ' + accessToken);
            
            if (accessToken != null) {
                Http htr = new Http();
                HttpRequest reqref = new HttpRequest();
                reqref.setMethod('GET');
                endpoint = domainUrl + '/services/data/v' + version + '/tooling/query?q=SELECT+Id,sandboxName,status,createddate,StartDate,EndDate+FROM+Sandboxprocess+where+SandboxInfoId=' + '\'' + sandTarget.Sandbox_Info_Id__c + '\'+ORDER+BY+StartDate+DESC+LIMIT+1';
                reqref.setEndpoint(endpoint);
                reqref.setHeader('Content-Type', 'application/json');
                reqref.setHeader('Authorization','Bearer ' + accessToken);
                reqref.setTimeout(120000);
                
                HttpResponse resref = Test.isRunningTest() ? new HttpResponse() : htr.send(reqref);
                Integer refstatus = Test.isRunningTest() ? 200 : resref.getStatusCode();
                system.debug('resref --- ' + resref + ' --- status code --- ' + refstatus);
                
                if (refstatus == 200) {
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(resref.getBody());
                    system.debug('result---'+ result);
                    List<Object> records = (List<Object>) result.get('records');
                    system.debug('records---'+ records);
                    List<String> latestStatus = new List<String>();
                    String endDate;
                    for (Object record : records) {
                        Map<String, Object> status = (Map<String, Object>) record;
                        latestStatus.add((String) status.get('Status'));
                        endDate = (String) status.get('EndDate');
                        system.debug('refresh EndDate from response --- ' + endDate);
                        break;
                    }
                    system.debug('end date after break from response --- ' + endDate);
                    String userTimezone = UserInfo.getTimeZone().getID();
                    Datetime parsedDateTime;
                    if(endDate != null){
                        endDate = endDate.substring(0, 19).replace('T', ' ');
                        DateTime dt = DateTime.valueOfGmt(endDate);
                        parsedDateTime = DateTime.valueOf(dt.format('yyyy-MM-dd HH:mm:ss', userTimezone));
                        system.debug('parsedDateTime --- ' + parsedDateTime);
                    }
                    
                    system.debug('latestStatus --- ' + latestStatus[0]);
                    sbxstatus = latestStatus[0];
                    
                    if(refreshLog.Status__c != 'Forbidden'){
                        if(sbxstatus == 'Completed'){
                            sandTarget.Domain_URL__c = 'https://test.salesforce.com';
                            sandTarget.Access_Token__c = '';
                            sandTarget.Refresh_Token__c = '';
                        }
                        
                        sandTarget.Completed_On__c = (parsedDateTime != null) ? parsedDateTime : null;
                        sandTarget.Last_Refresh_Status__c = sbxstatus;
                        update sandTarget;
                        
                        refTemp.Last_Run_Status__c = sbxstatus;
                        update refTemp;
                        
                        refreshLog.Status__c = sbxstatus;
                        refreshLog.Completed_On__c = (parsedDateTime != null) ? parsedDateTime : null;
                        system.debug('refreshLog.Completed_On__c --- ' + refreshLog.Completed_On__c);
                        refreshLog.Details__c = '';
                        update refreshLog;
                    }
                    else{
                        sbxstatus = 'Forbidden';
                        sandTarget.Last_Refresh_Status__c = sbxstatus;
                        update sandTarget;
                    }
                    
                } else {
                    //sbxstatus = resref.getBody();
                    sbxstatus = 'Failed';
                    system.debug('sbxstatus else --- ' + resref.getBody());
                    
                    refTemp.Last_Run_Status__c = 'Refresh Failed';
                    update refTemp;
                    
                    refreshLog.Status__c = 'Failed';
                    refreshLog.Details__c = resref.getBody();
                    //refreshLog.Last_Refreshed_Date__c = null;
                    //refreshLog.Next_Refresh_Available__c = null;
                    update refreshLog;
                }
            }
        } catch (Exception e) {
            system.debug('sbxstatus catch block --- ' + e.getMessage());
            sbxstatus = 'Sandbox Refresh Failed...';
        }
        return sbxstatus;
    }
    
    private static MetadataService.MetadataPort createService(String accessToken, String domainUrl) {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        String version = '59.0';
        service.endpoint_x = domainUrl + '/services/Soap/m/' + version;
        service.SessionHeader.sessionId = accessToken;
        service.timeout_x = 120000;
        return service;
    }
    
    @AuraEnabled
    public static Id validatePackage(Id orgId, Id templateId){
        Refresh_Template__c ref = [SELECT Id, Package_xml_Val__c, Last_Validated_Org__c FROM Refresh_Template__c WHERE Id = :templateId];
        Org__c sand = [SELECT Id, Access_Token__c, Domain_Url__c, Org_Type__c FROM Org__c WHERE Id = :orgId];
        system.debug('Org type --- ' + sand.Org_Type__c);
        
        String domainUrl = sand.Domain_URL__c;
        String accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        
        MetadataService.MetadataPort service = createService(accessToken, domainUrl);
        MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
        deployOptions.allowMissingFiles = true;
        deployOptions.autoUpdatePackage = false;
        deployOptions.ignoreWarnings = true;
        deployOptions.purgeOnDelete = false;
        deployOptions.rollbackOnError = true;
        deployOptions.checkOnly = true; // Only validation
        deployOptions.testLevel = (sand.Org_Type__c == 'Production') ? 'RunAllTestsInOrg' : 'NoTestRun';
        deployOptions.singlePackage = true;
        deployOptions.performRetrieve = true;
        
        List<Attachment> zipAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :templateId AND Name LIKE '%.zip'];
        
        MetadataService.DeployMessage deployMessage = new MetadataService.DeployMessage();
        deployMessage.changed = true;
        
        Blob zipBlob = zipAttachments[0].Body;
        deployMessage.zipFile = EncodingUtil.base64Encode(zipBlob);
        
        ref.Last_Validated_Org__c = sand.Id;
        
        Logs__c validationLog = new Logs__c();
        validationLog.Log_type__c = 'Validate Template';
        validationLog.Status__c = 'InProgress';
        validationLog.Parent_Template__c = templateId;
        validationLog.Last_Validated_Date__c = system.today();
        validationLog.Source_Org_For_Validation__c = sand.Id;
        
        if(!test.isRunningTest()){ MetadataService.AsyncResult asyncResult = service.deploy(deployMessage.zipFile, deployOptions); system.debug('asyncResult Id --- ' + asyncResult.Id); validationLog.Last_Validate_Async_Id__c = asyncResult.Id;
            //return asyncResult.Id;
        }
        else{
            Id mockAsyncId = orgId;
            //return mockAsyncId;
        }
        update ref;
        insert validationLog;
        return validationLog.Id;
    }
    
    @AuraEnabled
    public static String checkValidationStatus(Id logRecordId){
        system.debug('logRecordId --- ' + logRecordId);
        Logs__c validatedLog = [select Id, Name, Status__c, Parent_Template__r.Parent_Org__c, Source_Org_For_Validation__c, Last_Validate_Async_Id__c, Parent_Template__c from Logs__c where Id =: logRecordId];
        Org__c org = [select Id, Name, Domain_Url__c from Org__c where Id =: validatedLog.Source_Org_For_Validation__c ];
        
        String domainUrl = org.Domain_Url__c;
        String accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(org.Id);
        
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint(domainUrl + '/services/data/v61.0/metadata/deployRequest/' + validatedLog.Last_Validate_Async_Id__c);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if(res.getStatusCode() == 200){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> deployResult = (Map<String, Object>) responseMap.get('deployResult');
                system.debug('deployResult --- ' + deployResult);
                
                String status = (String) deployResult.get('status');
                system.debug('status --- ' + status);
                validatedLog.Status__c = (status == 'Succeeded') ? 'Success' : (status == 'Failed') ? status : (status == 'Pending') ? status : (status == 'InProgress') ? status : '';
                update validatedLog;
                return status;
            }
            else{
                validatedLog.Status__c = 'Failed';
                validatedLog.Details__c = res.getStatus();
                update validatedLog;
                system.debug('Error Status Message: --- ' + res.getStatus());
                system.debug('Error Status Code: --- ' + res.getStatusCode());
                return res.getStatus();
            }
        }
        catch (Exception e){
            validatedLog.Status__c = 'Failed';
            validatedLog.Details__c = e.getMessage();
            update validatedLog;
           throw new AuraHandledException('Error fetching validation status: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id deployPackage(Id orgId, Id templateId){
        Refresh_Template__c ref = [SELECT Id, Package_xml_Val__c FROM Refresh_Template__c WHERE Id = :templateId];
        Org__c sand = [SELECT Id, Access_Token__c, Domain_Url__c, Org_Type__c FROM Org__c WHERE Id = :orgId];
        system.debug('Org type --- ' + sand.Org_Type__c);
        
        String domainUrl = sand.Domain_URL__c;
        String accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        
        MetadataService.MetadataPort service = createService(accessToken, domainUrl);
        MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
        deployOptions.allowMissingFiles = true;
        deployOptions.autoUpdatePackage = false;
        deployOptions.ignoreWarnings = true;
        deployOptions.purgeOnDelete = false;
        deployOptions.rollbackOnError = true;
        deployOptions.checkOnly = false; // Only validation
        deployOptions.testLevel = (sand.Org_Type__c == 'Production') ? 'RunAllTestsInOrg' : 'NoTestRun';
        deployOptions.singlePackage = true;
        deployOptions.performRetrieve = true;
        
        List<Attachment> zipAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :templateId AND Name LIKE '%.zip'];
        
        MetadataService.DeployMessage deployMessage = new MetadataService.DeployMessage();
        deployMessage.changed = true;
        
        Blob zipBlob = zipAttachments[0].Body;
        deployMessage.zipFile = EncodingUtil.base64Encode(zipBlob);
        
        Logs__c deployLog = new Logs__c();
        deployLog.Log_type__c = 'Deploy - Metadata Restoration';
        deployLog.Status__c = 'InProgress';
        deployLog.Parent_Template__c = templateId;
        deployLog.Last_Deployment_Date__c = system.today();
        deployLog.Source_Org_For_Deployment__c = sand.Id;
        
        if(!test.isRunningTest()){ MetadataService.AsyncResult asyncResult = service.deploy(deployMessage.zipFile, deployOptions); system.debug('asyncResult Id --- ' + asyncResult.Id); deployLog.Last_Deployment_Async_Id__c = asyncResult.Id;
        }
        else{
            Id mockAsyncId = orgId;
        }
        insert deployLog;
        return deployLog.Id;
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(Id logRecordId){
        Logs__c deployLog = [select Id, Name, Status__c, Parent_Template__r.Parent_Org__c, Source_Org_For_Deployment__c, Last_Deployment_Async_Id__c, Parent_Template__c from Logs__c where Id =: logRecordId];
        Org__c org = [select Id, Name, Domain_Url__c from Org__c where Id =: deployLog.Source_Org_For_Deployment__c];
        
        String domainUrl = org.Domain_Url__c;
        String accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(org.Id);
        
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint(domainUrl + '/services/data/v61.0/metadata/deployRequest/' + deployLog.Last_Deployment_Async_Id__c);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            system.debug('res.getStatusCode() --- ' + res.getStatusCode());
            
            if(res.getStatusCode() == 200){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> deployResult = (Map<String, Object>) responseMap.get('deployResult');
                
                String status = (String) deployResult.get('status');
                system.debug('status --- ' + status);
                deployLog.Status__c = (status == 'Succeeded') ? 'Success' : (status == 'Failed') ? status : (status == 'Pending') ? status : (status == 'InProgress') ? status : '';
                update deployLog;
                return status;
            }
            else{
                deployLog.Status__c = 'Failed';
                deployLog.Details__c = res.getStatus();
                update deployLog;
                system.debug('Error Status Message: --- ' + res.getStatus());
                system.debug('Error Status Code: --- ' + res.getStatusCode());
                return res.getStatus();
            }
        }
        catch (Exception e){
            deployLog.Status__c = 'Failed';
            deployLog.Details__c = e.getMessage();
            update deployLog;
            throw new AuraHandledException('Error fetching validation status: ' + e.getMessage());
        }
    }
    
    public static Integer countMembersInPackageXml(String packageXml) {
        Integer totalMemberCount = 0;
        try {
            Dom.Document doc = new Dom.Document();
            doc.load(packageXml);
            Dom.XmlNode root = doc.getRootElement();
            
            for (Dom.XmlNode typeNode : root.getChildElements()) {
                if (typeNode.getName() == 'types') {
                    for (Dom.XmlNode childNode : typeNode.getChildElements()) {
                        if (childNode.getName() == 'members') {
                            totalMemberCount++;
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error parsing XML: ' + e.getMessage());
        }
        return totalMemberCount;
    }
    
    @AuraEnabled
    public static WrapperForValidateResult getValidationResult(Id logId){
        Logs__c validationLog = [select Id, Log_Type__c, Status__c, Last_Validate_Async_Id__c, Parent_Template__c, Source_Org_For_Validation__c from Logs__c where Id =: logId];
        Refresh_Template__c refTemp = [select Id, Name, Parent_Org__c from Refresh_Template__c where Id =: validationLog.Parent_Template__c];
        String asyncResultId = validationLog.Last_Validate_Async_Id__c;
        
        //ContentVersion contentVersion = [SELECT Title, VersionData FROM ContentVersion WHERE FirstPublishLocationId = :refTemp.Id AND Title = 'packageXml.txt'];
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :refTemp.Id];
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        ContentVersion contentVersion = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE Title = 'packageXml.txt' AND ContentDocumentId IN :docIds];
        system.debug('content version title --- ' + contentVersion.Title);
        String packageXmlString = contentVersion.VersionData.toString();
        system.debug('package xml --- \n' + packageXmlString);
        
        Integer totalNoOfComponentsInXml = countMembersInPackageXml(packageXmlString);
        
        Org__c sand = [select Id, Domain_Url__c from Org__c where Id =: validationLog.Source_Org_For_Validation__c];
        String domainUrl = sand.Domain_Url__c;
        system.debug('domainUrl --- ' + domainUrl);
        String accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String endpointUrl = domainUrl + '/services/data/v61.0/metadata/deployRequest/'+ asyncResultId + '?includeDetails=true';
        req.setEndpoint(endpointUrl);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setTimeout(120000);
        
        List<ValidateWrapper> lOfValidWrapForSuccess = new List<ValidateWrapper>();
        List<ValidateWrapper> lOfValidWrapForFailure = new List<ValidateWrapper>();
        
        HttpResponse res = http.send(req);
        System.debug('Status: ' + res.getStatusCode());
        System.debug('Status Message: ' + res.getStatus());
        System.debug('Response Body: ' + res.getBody());
        
        WrapperForValidateResult finalWrap = new WrapperForValidateResult();
        
        if(res.getStatusCode() == 200) {
            DeployResponseWrapper parsedJson = (DeployResponseWrapper) System.JSON.deserialize(res.getBody(), DeployResponseWrapper.class);
            DeployResult deployResult = parsedJson.deployResult;
            String deployStatus = (String) deployResult.status;
            system.debug('deployStatus --- ' + deployStatus);
            
            List<ComponentSuccess> successComponents = (List<ComponentSuccess>) deployResult.details.componentSuccesses;
            List<ComponentFailure> failedComponents = (List<ComponentFailure>) deployResult.details.componentFailures;
            system.debug('success components --- \n' + successComponents);
            system.debug('failed components --- \n' + failedComponents);
            
            for(ComponentSuccess comp : successComponents){
                ValidateWrapper validWrap = new ValidateWrapper();
                validWrap.successCompName = comp.fullName;
                validWrap.successCompType = comp.componentType;
                lOfValidWrapForSuccess.add(validWrap);
            }
            finalWrap.successList = lOfValidWrapForSuccess;
            
            
            for(ComponentFailure comp : failedComponents){
                ValidateWrapper validWrap = new ValidateWrapper();
                validWrap.compName = comp.fullName;
                validWrap.compType = comp.componentType;
                validWrap.problem = comp.problem;
                validWrap.problemType = comp.problemType;
                if(!test.isRunningTest()){ validWrap.lineNumber = (comp.lineNumber == null) ? 0 : comp.lineNumber; validWrap.columnNumber = (comp.columnNumber == null) ? 0 : comp.columnNumber;
                }
                lOfValidWrapForFailure.add(validWrap);
            }
            finalWrap.failureList = lOfValidWrapForFailure;
            
            validationLog.Status__c = (deployStatus == 'Succeeded') ? 'Success' : deployStatus;
            update validationLog;
            
            if(deployStatus == 'Failed' || deployStatus == 'Success'){
                system.debug('response length --- ' + res.getBody().length());
            }
            
            finalWrap.allComponentsChecked = (deployStatus == 'Failed' || deployStatus == 'Success') ? true : false;
            return finalWrap; } else{ return null; }
    }
    
    public class DeployResponseWrapper {
        public DeployResult deployResult;
    }
    
    public class DeployResult {
        public String status;
        public Integer numberComponentErrors;
        public Integer numberComponentsDeployed;
        public Integer numberComponentsTotal;
        public Integer numberTestErrors;
        public Integer numberTestsCompleted;
        public Integer numberTestsTotal;
        public Boolean done;
        public Boolean success;
        public DeployDetails details;
    }
    
    public class DeployDetails {
        public List<ComponentSuccess> componentSuccesses;
        public List<ComponentFailure> componentFailures;
    }
    
    public class ComponentSuccess {
        public String fullName;
        public String componentType;
    }
    
    public class ComponentFailure {
        public String fullName;
        public String componentType;
        public String problem;
        public String problemType;
        public Boolean success;
        public Boolean warning;
        public Integer lineNumber;
        public Integer columnNumber;
    }
    
    public class ValidateWrapper{
        @AuraEnabled public string successCompName;
        @AuraEnabled public string successCompType;
        @AuraEnabled public string compName;
        @AuraEnabled public string compType;
        @AuraEnabled public string problem;
        @AuraEnabled public string problemType;
        @AuraEnabled public boolean success;
        @AuraEnabled public boolean warning;
        @AuraEnabled public integer lineNumber;
        @AuraEnabled public integer columnNumber;
    }
    
    public class WrapperForValidateResult{
        @AuraEnabled public List<ValidateWrapper> successList;
        @AuraEnabled public List<ValidateWrapper> failureList;
        @AuraEnabled public boolean allComponentsChecked = false;
    }
    
    @AuraEnabled
    public static WrapperForValidateResult getDeployResult(Id logId){
        Logs__c deployLog = [select Id, Log_Type__c, Status__c, Last_Deployment_Async_Id__c, Parent_Template__c, Source_Org_For_Deployment__c from Logs__c where Id =: logId];
        Refresh_Template__c refTemp = [select Id, Name, Parent_Org__c from Refresh_Template__c where Id =: deployLog.Parent_Template__c];
        String asyncResultId = deployLog.Last_Deployment_Async_Id__c;
        
        //ContentVersion contentVersion = [SELECT VersionData FROM ContentVersion WHERE FirstPublishLocationId = :refTemp.Id ORDER BY CreatedDate DESC LIMIT 1];
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :refTemp.Id];
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        ContentVersion contentVersion = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE Title = 'packageXml.txt' AND ContentDocumentId IN :docIds];
        system.debug('content version title --- ' + contentVersion.Title);
        String packageXmlString = contentVersion.VersionData.toString();
        system.debug('package xml --- \n' + packageXmlString);
        
        Integer totalNoOfComponentsInXml = countMembersInPackageXml(packageXmlString);
        
        Org__c sand = [select Id, Domain_Url__c from Org__c where Id =: deployLog.Source_Org_For_Deployment__c];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String endpointUrl = domainUrl + '/services/data/v61.0/metadata/deployRequest/'+ asyncResultId + '?includeDetails=true';
        req.setEndpoint(endpointUrl);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setTimeout(120000);
        
        List<ValidateWrapper> lOfDeployWrapForSuccess = new List<ValidateWrapper>();
        List<ValidateWrapper> lOfDeployWrapForFailure = new List<ValidateWrapper>();
        
        HttpResponse res = http.send(req);
        System.debug('Status: ' + res.getStatusCode());
        System.debug('Status Message: ' + res.getStatus());
        System.debug('Response Body: ' + res.getBody());
        
        WrapperForValidateResult finalWrap = new WrapperForValidateResult();
        
        if(res.getStatusCode() == 200){
            DeployResponseWrapper parsedJson = (DeployResponseWrapper) System.JSON.deserialize(res.getBody(), DeployResponseWrapper.class);
            DeployResult deployResult = parsedJson.deployResult;
            String deployStatus = (String) deployResult.status;
            system.debug('deployStatus --- ' + deployStatus);
            
            List<ComponentSuccess> successComponents = (List<ComponentSuccess>) deployResult.details.componentSuccesses;
            List<ComponentFailure> failedComponents = (List<ComponentFailure>) deployResult.details.componentFailures;
            system.debug('success components --- \n' + successComponents);
            system.debug('failed components --- \n' + failedComponents);
            
            for(ComponentSuccess comp : successComponents){
                ValidateWrapper deployWrap = new ValidateWrapper();
                deployWrap.successCompName = comp.fullName;
                deployWrap.successCompType = comp.componentType;
                lOfDeployWrapForSuccess.add(deployWrap);
            }
            finalWrap.successList = lOfDeployWrapForSuccess;
            
            
            for(ComponentFailure comp : failedComponents){
                ValidateWrapper deployWrap = new ValidateWrapper();
                deployWrap.compName = comp.fullName;
                deployWrap.compType = comp.componentType;
                deployWrap.problem = comp.problem;
                deployWrap.problemType = comp.problemType;
                if(!test.isRunningTest()){ deployWrap.lineNumber = (comp.lineNumber == null) ? 0 : comp.lineNumber; deployWrap.columnNumber = (comp.columnNumber == null) ? 0 : comp.columnNumber;
                }
                lOfDeployWrapForFailure.add(deployWrap);
            }
            finalWrap.failureList = lOfDeployWrapForFailure;
            
            deployLog.Status__c = (deployStatus == 'Succeeded') ? 'Success' : deployStatus;
            update deployLog;
            
            if(deployStatus == 'Failed' || deployStatus == 'Success'){
                system.debug('response length --- ' + res.getBody().length());
            }
            
            finalWrap.allComponentsChecked = (deployStatus == 'Failed' || deployStatus == 'Success') ? true : false;
            return finalWrap; } else{ return null; }
    }
    
    public static void createNewSandbox(String sandboxName, String licenseType){
        Org__c cfProdOrg = [select Id, Name, Domain_Url__c, Access_Token__c, Sandbox_Info_Id__c from Org__c where Name = 'CFProd'];
        String cfProdDomianUrl = cfProdOrg.Domain_URL__c;
        String cfProdAccessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(cfProdOrg.Id);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfProdDomianUrl + '/services/data/v57.0/tooling/sobjects/SandboxInfo');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + cfProdAccessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"SandboxName": "' + sandboxName + '", "LicenseType": "' + licenseType + '", "AutoActivate": true}');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('Response: ' + res.getBody());
    }
    
    public static void cloneExistingSandbox(Id sandboxId, String clonedSandboxName){
        Org__c org = [select Id, Name, Sandbox_Info_Id__c, License_Type__c, Domain_Url__c from Org__c where Id =: sandboxId];
        String domainUrl = org.Domain_Url__c;
        String accessToken = (test.isRunningTest()) ? '12345' : RefreshTokenCallout.fetchAT1(org.Id);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(domainUrl + '/services/data/v57.0/tooling/sobjects/SandboxInfo');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"SandboxName": "' + clonedSandboxName + '", "LicenseType": "' + org.License_Type__c + '", "SourceId" :"' + org.Sandbox_Info_Id__c + '", "AutoActivate": true}');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('Response: ' + res.getBody());
    }
    
    public static void getNewSandboxStatus(){
        Org__c cfProdOrg = [select Id, Name, Domain_Url__c, Access_Token__c, Sandbox_Info_Id__c from Org__c where Name = 'CFProd'];
        String cfProdDomianUrl = cfProdOrg.Domain_URL__c;
        String cfProdAccessToken = RefreshTokenCallout.fetchAT1(cfProdOrg.Id);
        system.debug('cfProdAccessToken --- ' + cfProdAccessToken);
        
        String sandboxInfoId = '0GQTN000000AmHt4AK';
        String sandboxName = 'MyNewSand';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfProdDomianUrl + '/services/data/v57.0/tooling/query/?q=SELECT+Id,Status+FROM+SandboxProcess+WHERE+SandboxName=\'' + sandboxName + '\'');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + cfProdAccessToken);
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        system.debug('status code: ' + res.getStatusCode());
        System.debug('Response: ' + res.getBody());
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getValidationLogRecordofRefreshTemplate(Id templateId){
         List<Logs__c> logList = [select Id, Last_Refreshed_Date__c, Parent_Template__c, Status__c, Last_Validated_Date__c, Name, LastModifiedBy.Name  from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Validate Template' ORDER BY CreatedDate DESC limit 1];
        //system.debug('Last Validated Date --- ' + latestValidatedLog.Last_Validated_Date__c);
        if (!logList.isEmpty()) {
            system.debug('Last Validated Date --- ' + logList[0].Last_Validated_Date__c);
            return logList[0]; } else { system.debug('No validation log found for template: ' + templateId); return null; }
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getValidationLogRecord(Id logRecId){
        Logs__c latestValidatedLog = [select Id, Last_Refreshed_Date__c, Parent_Template__c, Status__c, Last_Validated_Date__c, Name, LastModifiedBy.Name  from Logs__c where Id =: logRecId AND Log_Type__c = 'Validate Template' ORDER BY CreatedDate DESC limit 1];
        system.debug('Last Validated Date --- ' + latestValidatedLog.Last_Validated_Date__c);
        return latestValidatedLog;
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getDeployLogRecord(Id logRecId){
        Logs__c latestDeployLog = [select Id, Last_Deployment_Date__c , Parent_Template__c, Status__c, Name, LastModifiedBy.Name from Logs__c where Id =: logRecId AND Log_Type__c = 'Deploy - Metadata Restoration' ORDER BY CreatedDate DESC limit 1];
        system.debug('Last Validated Date --- ' + latestDeployLog.Last_Deployment_Date__c);
        return latestDeployLog;
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getDeployLogRecordofRefreshTemplate(Id templateId){
         List<Logs__c> logList = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Deploy - Metadata Restoration' ORDER BY CreatedDate DESC limit 1];
        if (!logList.isEmpty()) {
            system.debug('Last Deployment Date --- ' + logList[0].Last_Deployment_Date__c);
            return logList[0]; } else { system.debug('No deployment log found for template: ' + templateId); return null;  }
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getDataTransformLogRecord(Id logRecId){
        Logs__c latestLog = [select Id, Last_Deployment_Date__c , Parent_Template__c, Status__c, Name, LastModifiedBy.Name from Logs__c where Id =: logRecId AND Log_Type__c = 'Data Transformation' ORDER BY CreatedDate DESC limit 1];
        system.debug('Last Validated Date --- ' + latestLog.Last_Deployment_Date__c);
        return latestLog;
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getDataTransformLogRecordofRefreshTemplate(Id templateId){
         List<Logs__c> logList = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Data Transformation' ORDER BY CreatedDate DESC limit 1];
        if (!logList.isEmpty()) {
            system.debug('Lastest Date --- ' + logList[0].Last_Deployment_Date__c);
            return logList[0]; }  else { return null; }
    }
    @AuraEnabled(cacheable=true)
    public static Logs__c getUsersDataRestoreLogRecordofRefreshTemplate(Id templateId){
         List<Logs__c> logList = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'User Restoration - Post Refresh' ORDER BY CreatedDate DESC limit 1];
        if (!logList.isEmpty()) { system.debug('Lastest Date --- ' + logList[0].Last_Deployment_Date__c); return logList[0]; } 
        else { 
            system.debug('No log found for template: ' + templateId); 
            return null;  
        }
    }
    @AuraEnabled(cacheable=true)
    public static Logs__c getCustomSettingsDataRestoreLogRecordofRefreshTemplate(Id templateId){
         List<Logs__c> logList = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Custom Settings Restoration - Post Refresh' ORDER BY CreatedDate DESC limit 1];
        if (!logList.isEmpty()) { system.debug('Lastest Date --- ' + logList[0].Last_Deployment_Date__c); return logList[0]; } 
        else { 
            system.debug('No log found for template: ' + templateId); 
            return null;  
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getSourceOrgType(Id orgId){
        Org__c sand = [SELECT Id, Name, Domain_URL__c, Access_Token__c, Org_Id__c, Production_Org__c, Org_Type__c, Sandbox_Info_Id__c, License_Type__c FROM Org__c where Id =: orgId];
        system.debug('Org Type --- ' + sand.Org_Type__c);
        return sand.Org_Type__c;
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getRefreshLogRecordofRefreshTemplate(Id templateId){
        List<Logs__c> latestRefreshedLog = [select Id, Last_Refreshed_Date__c, Parent_Template__r.Parent_Org__r.License_Type__c, 
                                      Parent_Template__c, Status__c, Parent_Template__r.Last_Refreshed_Date__c, Name, 
                                      Parent_Template__r.Last_Run_Status__c, Parent_Template__r.Last_Refreshed_By__r.Name, Next_Refresh_Available__c  
                                      from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Sandbox Refresh' 
                                      ORDER BY CreatedDate DESC limit 1];
        //system.debug('Parent Last Refreshed Date --- ' + latestRefreshedLog.Parent_Template__r.Last_Refreshed_Date__c);
        if (!latestRefreshedLog.isEmpty()) {
            //system.debug('Last Validated Date --- ' + latestRefreshedLog[0].Last_Validated_Date__c);
            return latestRefreshedLog[0]; } else { system.debug('No validation log found for template: ' + templateId); return null; }
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getRefreshLogRecord(Id logRecId){
        Logs__c latestRefreshLog = [select Id,  Last_Refreshed_Date__c, Parent_Template__c, Status__c, 
                                    Last_Validated_Date__c, Name, LastModifiedBy.Name, Parent_Template__r.Last_Refreshed_Date__c,
                                    Parent_Template__r.Last_Run_Status__c,Parent_Template__r.Last_Refreshed_By__r.Name,
                                    Parent_Template__r.Parent_Org__r.License_Type__c, Next_Refresh_Available__c 
                                    from Logs__c where Id =: logRecId AND 
                                    Log_Type__c = 'Sandbox Refresh' ORDER BY CreatedDate DESC limit 1];
        //system.debug('Last Refresh Date --- ' + latestValidatedLog.Last_Validated_Date__c);
        return latestRefreshLog;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkForMetadataZipFiles(String templateId) {
        try {
            List<Attachment> attachments = [SELECT Name FROM Attachment WHERE ParentId = :templateId];
            Boolean hasMetadataZip = false;
            for (Attachment attachment : attachments) { if (attachment.Name.endsWith('Metadata.zip')) { hasMetadataZip = true;
                }
            }
            return hasMetadataZip; } catch (Exception ex) { System.debug('Error checking required files: ' + ex.getMessage()); throw new AuraHandledException('Error checking files: ' + ex.getMessage()); }
    }
    
    @AuraEnabled
    public static List<Map<String, String>> fetchPublicGroupOfSource(Id selectedSourceForRefresh){
        Org__c sourceOrg = [select Id, Name, Domain_Url__c from Org__c where Id =: selectedSourceForRefresh];
        String domainUrl = sourceOrg.Domain_URL__c;
        String accessToken = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(sourceOrg.Id);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(domainUrl + '/services/data/v57.0/tooling/query/?q=SELECT+Id,Name+FROM+Group+WHERE+Type=\'Regular\'');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res;
        
        try{
            res = http.send(req);
            system.debug('response --------- ' + res);
            List<Map<String, String>> pgList = new List<Map<String, String>>();
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                system.debug('responseMap --- ' + responseMap);
                
                List<Object> records = (List<Object>) responseMap.get('records');
                
                for (Object record : records) {
                    Map<String, Object> publicGroup = (Map<String, Object>) record;
                    
                    Id pgId = (Id) publicGroup.get('Id');
                    String pgName = (String) publicGroup.get('Name');
                    system.debug('public group id --- ' + pgId);
                    system.debug('public group name --- ' + pgName);
                    
                    Map<String, String> pgDetails = new Map<String, String>();
                    pgDetails.put('Id', pgId);
                    pgDetails.put('Name', pgName);
                    
                    pgList.add(pgDetails);
                }
                system.debug('pgList --- ' + pgList);
                
                return pgList;
            } else {
                System.debug('Error: ' + res.getStatus() + ' - ' + res.getBody());
                return new List<Map<String, String>>();
            }
            
        }catch(Exception e){
            system.debug('Error fetching Public Groups: --- ' + e.getMessage());
            return new List<Map<String, String>>();
        }
    }
    
    @AuraEnabled
    public static Id fetchApexClassIdFromSource(Id selectedSourceForRefresh, String apexClassName){
        Org__c sourceOrg = [select Id, Name, Domain_Url__c from Org__c where Id =: selectedSourceForRefresh];
        String domainUrl = sourceOrg.Domain_URL__c;
        String accessToken = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(sourceOrg.Id);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(domainUrl + '/services/data/v57.0/tooling/query/?q=SELECT+Id,Name+FROM+ApexClass+WHERE+Name=\'' + apexClassName + '\'');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res;
        
        try{
            res = http.send(req);
            system.debug('response --------- ' + res);
            Id apexClassId;
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                system.debug('responseMap --- ' + responseMap);
                List<Object> records = (List<Object>) responseMap.get('records');
                system.debug('records --- ' + records);
                
                if(!records.isEmpty()){
                    for (Object record : records) {
                        Map<String, Object> apexClass = (Map<String, Object>) record;
                        apexClassId = (Id) apexClass.get('Id');
                    }
                } else {
                    System.debug('No Apex Class found.');
                    return null; // Return null instead of throwing an exception
                }

            } else {
                System.debug('Error: ' + res.getStatus() + ' - ' + res.getBody());
            }
            return apexClassId;
            
        }catch(Exception e){
            system.debug('Error fetching Public Groups: --- ' + e.getMessage());
            return null;
            //throw new AuraHandledException('Error deleting record: ' + e.getMessage());
        }
    }
}