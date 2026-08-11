public with sharing class PostRefreshAutomationClass {
    
    // Create and return a MetadataService.MetadataPort object initialized with session information
    @TestVisible private static MetadataService.MetadataPort createService(Id sandboxId, String domainUrl) {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        String version = '42.0';
        service.endpoint_x = domainUrl + '/services/Soap/m/' + version;
        service.SessionHeader.sessionId = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(sandboxId);
        service.timeout_x = 120000;
        return service;
    }
    
    @AuraEnabled
    public static Id callFindAndReplaceQueueable(Id templateId, String findAndReplaceTemp){
        Refresh_Template__c refTemp = [select Id, Name, Find_And_Replace_Template__c, Parent_Org__c from Refresh_Template__c where Id =: templateId];
        Id sandboxId = refTemp.Parent_Org__c;
        
        Org__c sand = [SELECT Id, Name, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        
        MetadataService.MetadataPort service = createService(sandboxId, domainUrl);
        
        Logs__c metaTransformLog = new Logs__c();
        metaTransformLog.Log_type__c = 'Search & Replace - Metadata Transformation';
        metaTransformLog.Status__c = 'InProgress';
        metaTransformLog.Parent_Template__c = refTemp.Id;
        metaTransformLog.Last_Search_And_Replace_Date__c = system.now();
        insert metaTransformLog;
        system.debug('metaTransformLog id --- ' + metaTransformLog.Id);
        
        system.debug('findAndReplaceTemp --- ' + findAndReplaceTemp);
        List<Object> metadataList = (List<Object>) JSON.deserializeUntyped(findAndReplaceTemp);
        
        for (Object item : metadataList) {
            Map<String, Object> metadata = (Map<String, Object>) item;
            
            String metadataType = (String) metadata.get('metadataType');
            metadataType = (metadataType == 'CustomLabels') ? 'CustomLabel' : metadataType;
            String maskingType = (String) metadata.get('maskingType');
            String searchKey = (String) metadata.get('searchKey');
            String replaceValue = (String) metadata.get('replaceValue');
            
            System.debug('Metadata Type: ' + metadataType);
            System.debug('Masking Type: ' + maskingType);
            System.debug('Search Key: ' + searchKey);
            System.debug('Replace Value: ' + replaceValue);
            
            Database.executeBatch(new FindAndReplaceBatchClass(service, metadataType, maskingType, searchKey, replaceValue, metaTransformLog.Id), 10);
        }
        
        return metaTransformLog.Id;
    }
    
    public static void attachCsvToLog(Set<Map<String, String>> records, String fileName, Boolean isFailureFile, Id metaTransformLogId) {
        if (records.isEmpty()) return;
        system.debug('records --- ' + records);
        
        String csvContent = '';
        if(isFailureFile){
            csvContent += '"Metadata Member","Failed Reason"\n';
        }
        else{
            csvContent += '"Metadata Member"\n';
        }
        
        for (Map<String, String> recordMap : records) {
            for (String key : recordMap.keySet()) {
                String cellValue;
                if(recordMap.get(key) != null || recordMap.get(key) != ''){
                    cellValue = recordMap.get(key);
                    csvContent += key + ',' + cellValue + '\n';
                }
                else{
                    cellValue = '';
                    csvContent += key + '\n';
                }
            }
        }
        
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = Blob.valueOf(csvContent)
            //FirstPublishLocationId = metaTransformLogId
        );
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = metaTransformLogId;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        
        insert contentDocumentLink;
    }
    
    @AuraEnabled
    public static Id callSuffixQueueable(Id templateId, String suffixTemp){
        Refresh_Template__c refTemp = [select Id, Name, Find_And_Replace_Template__c, Parent_Org__c from Refresh_Template__c where Id =: templateId];
        Id sandboxId = refTemp.Parent_Org__c;
        
        Org__c sand = [SELECT Id, Name, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        
        MetadataService.MetadataPort service = createService(sandboxId, domainUrl);
        
        Logs__c metaTransformLog = new Logs__c();
        metaTransformLog.Log_type__c = 'Suffix - Metadata Transformation';
        metaTransformLog.Status__c = 'InProgress';
        metaTransformLog.Parent_Template__c = refTemp.Id;
        metaTransformLog.Last_Suffix_Date__c = system.now();
        insert metaTransformLog;
        system.debug('metaTransformLog id --- ' + metaTransformLog.Id);
        
        system.debug('suffixTemp --- ' + suffixTemp);
        List<Object> metadataList = (List<Object>) JSON.deserializeUntyped(suffixTemp);
        
        for (Object item : metadataList) {
            Map<String, Object> metadata = (Map<String, Object>) item;
            
            String metadataType = (String) metadata.get('metadataType');
            metadataType = (metadataType == 'CustomLabels') ? 'CustomLabel' : metadataType;
            String maskingType = (String) metadata.get('maskingType');
            String suffixValue = (String) metadata.get('suffixValue');
            
            System.debug('Metadata Type: ' + metadataType);
            System.debug('Masking Type: ' + maskingType);
            System.debug('Suffix: ' + suffixValue);
            
            Database.executeBatch(new SuffixBatchClass(service, metadataType, maskingType, suffixValue, metaTransformLog.Id), 10);
        }
        
        return metaTransformLog.Id;
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getMetadataMaskingLogRecord(Id logRecId){
        Logs__c latestLog = [select Id, Last_Deployment_Date__c , Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Last_Search_And_Replace_Date__c from Logs__c where Id =: logRecId AND Log_Type__c = 'Search & Replace - Metadata Transformation' ORDER BY CreatedDate DESC limit 1];
        system.debug('Last Validated Date --- ' + latestLog.Last_Deployment_Date__c);
        return latestLog;
    }
    
    @AuraEnabled
    public static Logs__c getMetadataMaskingLogRecordofRefreshTemplate(Id templateId){
        Logs__c metaTransLog = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Last_Search_And_Replace_Date__c from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Search & Replace - Metadata Transformation' ORDER BY CreatedDate DESC limit 1];
        system.debug('metaTransLog.Status__c --- ' + metaTransLog.Status__c);
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :metaTransLog.Id];
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        List<Logs__c> logToUpdate = new List<Logs__c>();
        List<ContentVersion> contentVersion = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :docIds];
        if(contentVersion.size() > 0){
            for(ContentVersion con : contentVersion){
                if(metaTransLog.Status__c == 'InProgress'){
                    system.debug('inside inprogress --- ');
                    if(con.Title.contains('_FailedRecords.csv')){
                        metaTransLog.Status__c = 'Failed';
                    }
                    else{
                        metaTransLog.Status__c = 'Completed';
                    }
                    logToUpdate.add(metaTransLog);
                }
            }
        }
        else{
            metaTransLog.Status__c = 'Completed';
            logToUpdate.add(metaTransLog);
        }
        
        if(logToUpdate.size() > 0){
            system.debug('inside update --- ');
            update logToUpdate;
        }
        return metaTransLog;
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getSearchRulesRecordofRefreshTemplate(Id templateId){
        List<Logs__c> logList = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Last_Search_And_Replace_Date__c from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Search & Replace - Metadata Transformation' ORDER BY CreatedDate DESC limit 1];
        if (!logList.isEmpty()) {
            system.debug('Lastest Date --- ' + logList[0].Last_Deployment_Date__c);
            return logList[0]; } 
        else { 
            system.debug('No log found for template: ' + templateId); 
            return null;  
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getSuffixLogRecord(Id logRecId){
        Logs__c latestLog = [select Id, Last_Deployment_Date__c , Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Last_Suffix_Date__c from Logs__c where Id =: logRecId AND Log_Type__c = 'Suffix - Metadata Transformation' ORDER BY CreatedDate DESC limit 1];
        system.debug('Last Validated Date --- ' + latestLog.Last_Deployment_Date__c);
        return latestLog;
    }
    
    @AuraEnabled
    public static Logs__c getSuffixLogRecordofRefreshTemplate(Id templateId){
        Logs__c metaTransLog = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Last_Suffix_Date__c from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Suffix - Metadata Transformation' ORDER BY CreatedDate DESC limit 1];
        system.debug('metaTransLog.Status__c --- ' + metaTransLog.Status__c);
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :metaTransLog.Id];
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        List<Logs__c> logToUpdate = new List<Logs__c>();
        List<ContentVersion> contentVersion = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :docIds];
        
        if(contentVersion.size() > 0){
            for(ContentVersion con : contentVersion){
                if(metaTransLog.Status__c == 'InProgress'){
                    if(con.Title.contains('_FailedRecords.csv')){
                        metaTransLog.Status__c = 'Failed';
                    }
                    else{
                        metaTransLog.Status__c = 'Completed';
                    }
                    logToUpdate.add(metaTransLog);
                }
            }
        }
        else{
            metaTransLog.Status__c = 'Completed';
            logToUpdate.add(metaTransLog);
        }
        if(logToUpdate.size() > 0){
            update logToUpdate;
        }
        return metaTransLog;
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getSuffixRulesRecordofRefreshTemplate(Id templateId){
        List<Logs__c> logList = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Last_Suffix_Date__c from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Suffix - Metadata Transformation' ORDER BY CreatedDate DESC limit 1];
        if (!logList.isEmpty()) {
            system.debug('Lastest Date --- ' + logList[0].Last_Deployment_Date__c);
            return logList[0]; } 
        else { 
            system.debug('No log found for template: ' + templateId); 
            return null;  
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getApexScriptLogRecord(Id logRecId){
        Logs__c latestLog = [select Id, Last_Deployment_Date__c , Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Last_ApexScript_Date__c from Logs__c where Id =: logRecId AND Log_Type__c = 'Apex Script - Metadata Transformation' ORDER BY CreatedDate DESC limit 1];
        system.debug('Last Validated Date --- ' + latestLog.Last_Deployment_Date__c);
        return latestLog;
    }
    
    @AuraEnabled(cacheable=true)
    public static Logs__c getApexScriptLogRecordofRefreshTemplate(Id templateId){
        List<Logs__c> logList = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Last_ApexScript_Date__c from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Apex Script - Metadata Transformation' ORDER BY CreatedDate DESC limit 1];
        if (!logList.isEmpty()) {
            system.debug('Lastest Date --- ' + logList[0].Last_Deployment_Date__c);
            return logList[0]; } 
        else { 
            system.debug('No log found for template: ' + templateId); 
            return null;  
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String fetchMetadataMaskingTemplate(Id templateId){
        Refresh_Template__c refTemp = [select Id, Name, Find_And_Replace_Template__c from Refresh_Template__c where Id =: templateId];
        
        String metaMaskTemp = refTemp.Find_And_Replace_Template__c;
        system.debug('metaMaskTemp --- ' + metaMaskTemp);
        return metaMaskTemp;
    }
    
    public static String generateApexCodeToAbortJobs(String orgName) {
        String targetJobName = 'sample 1';
        List<String> jobType = new List<String>{'A', '8', '7'};
            String formattedJobType = '\'' + String.join(jobType, '\', \'') + '\'';
        User currentUser = [SELECT Lastname,Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        string emailId = currentUser.email;
        string name = currentUser.LastName;
        
        String scriptContent = '';
        scriptContent += 'List<CronTrigger> cronTriggers = [SELECT Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger];\n';
        scriptContent += 'String csvData = \'ScheduleJob Name,Status\\n\';\n';  
        scriptContent += 'if(cronTriggers.size() > 0) {\n';
        scriptContent += 'for(CronTrigger cronTrigger : cronTriggers) {\n';
        scriptContent += '    System.debug(\'name of job---->>>\'+cronTrigger.CronJobDetail.Name);\n';
        scriptContent += '    System.debug(\'Job Type---->>>\'+cronTrigger.CronJobDetail.JobType);\n';
        scriptContent += '    System.debug(\'Job Id---->>>\'+cronTrigger.Id);\n';
        scriptContent += '    if (cronTrigger.CronJobDetail != null && cronTrigger.CronJobDetail.JobType != \'}\') {\n';
        scriptContent += '        System.abortJob(cronTrigger.Id);\n';
        scriptContent += '        csvData += cronTrigger.CronJobDetail.Name + \',Deleted\\n\';\n'; 
        scriptContent += '    }\n';
        scriptContent += '    else{\n';
        scriptContent += '    System.debug(\'Skipping job with null JobType or CronJobDetail: \' + cronTrigger.Id);\n';
        scriptContent += '        csvData += cronTrigger.CronJobDetail.Name + \',Unable to delete the schedule job beacause the job detail or job type is not defined\\n\';\n';
        scriptContent += '    }\n';
        scriptContent += '}\n';
        
        scriptContent += 'Blob csvBlob = Blob.valueOf(csvData);\n';
        scriptContent += 'ContentVersion version = new ContentVersion();\n';
        scriptContent += 'version.Title = \'ScheduleJobs Status\';\n';
        scriptContent += 'version.PathOnClient = version.Title+\'.csv\';\n';
        scriptContent += 'version.VersionData = csvBlob;\n';
        scriptContent += 'insert version;\n';
        scriptContent += 'List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();\n';
        scriptContent += 'Blob fileData = version.VersionData;\n';
        scriptContent += 'Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();\n';
        scriptContent += 'attachment.setFileName(version.Title+\'.csv\');\n';
        scriptContent += 'attachment.setBody(fileData);\n';
        scriptContent += 'emailAttachments.add(attachment);\n';
        
        
        
        String apexCode = 
            'String errorMessage;\n' +
            'String emailBody;\n' +
            'try {\n' +
            scriptContent + '\n' + 
            '    emailBody =  \'Dear <b>' + name + '</b>,<br/><br/>\';\n' +  // Fixed variable usage
            '    emailBody += \'The Schedule Jobs of <b>' + orgName + '</b> org has been aborted successfully\';\n' +
            '    emailBody += \'<br/><br/>\' +\n' +
            '                \'<hr>\' +\n' +
            '                \'<b>This is a system generated mail. Please do not reply to this email ID.</b>\';\n' +  // Fixed concatenation
            '    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();\n' +
            '    email.setToAddresses(new String[] { \'' + emailId + '\' });\n' +
            '    email.setSubject(\'Aborting the Schedule Jobs \');\n' +
            '    email.setHtmlBody(emailBody);  // Changed to setHtmlBody\n' +  // Use HTML body
            '    email.setFileAttachments(emailAttachments);\n' +
            '    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });\n' +
            '    }else{\n' +
            'String emailBody;\n' +
            '    emailBody =  \'Dear <b>' + name + '</b>,<br/><br/>\';\n' +  // Fixed variable usage
            '    emailBody += \'There are no scheduled jobs in the <b>' + orgName + '</b> to abort.\';\n' +
            '    emailBody += \'<br/><br/>\' +\n' +
            '                \'<hr>\' +\n' +
            '                \'<b>This is a system generated mail. Please do not reply to this email ID.</b>\';\n' +  // Fixed concatenation
            '    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();\n' +
            '    email.setToAddresses(new String[] { \'' + emailId + '\' });\n' +
            '    email.setSubject(\'Aborting the Schedule Jobs \');\n' +
            '    email.setHtmlBody(emailBody);  // Changed to setHtmlBody\n' +  // Use HTML body
            '    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });\n' +
            '    }\n' +
            '} catch (Exception e) {\n' +
            '    System.debug(\'Error occurred while aborting the Scheduled Jobs: \' + e.getMessage());\n' +
            '    errorMessage = e.getMessage();\n' +
            '    if (!String.isBlank(errorMessage)) {\n' +
            '    emailBody =  \'Dear <b>' + name + '</b>,<br/><br/>\';\n' +
            '        emailBody = \'The following errors occurred while aborting the Scheduled Jobs of ' + orgName + 'Org: \' + errorMessage;\n' +
            '    emailBody += \'<br/><br/>\' +\n' +
            '                \'<hr>\' +\n' +
            '                \'<b>This is a system generated mail. Please do not reply to this email ID.</b>\';\n' +  // Fixed concatenation
            '        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();\n' +
            '        email.setToAddresses(new String[] { \'' + emailId + '\' });\n' +
            '        email.setSubject(\'Aborting the Schedule Jobs \');\n' +
            '        email.setHtmlBody(emailBody);  // Use HTML body\n' +  // Changed to setHtmlBody
            '        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });\n' +
            '    }\n' +
            '}';
        system.debug('Apexcode------>>>'+apexCode);
        return apexCode;
    }
    
    @AuraEnabled
    public static void abortScheduledJobsViaExecuteAnonymous(Id templateId) {
        Refresh_Template__c refTemp = [select Id, Name, Parent_Org__c from Refresh_Template__c where Id =: templateId];
        Org__c org = [select Id, Name, Domain_Url__c, Access_Token__c from Org__c where Id =: refTemp.Parent_Org__c];
        
        String apexCode = generateApexCodeToAbortJobs(org.Name);
        String encodedApex = EncodingUtil.urlEncode(apexCode, 'UTF-8');
        
        Logs__c abortSJobsLogs = new Logs__c();
        abortSJobsLogs.Log_type__c = 'Delete Scheduled Jobs - Post Refresh';
        abortSJobsLogs.Parent_Template__c = templateId;
        
        String targetOrgUrl = org.Domain_Url__c;
        String accessToken = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(org.Id);
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(targetOrgUrl + '/services/data/v59.0/tooling/executeAnonymous/?anonymousBody=' + encodedApex);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        try {
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                abortSJobsLogs.Status__c = 'Success';
                System.debug('Scheduled jobs aborted successfully: ' + response.getBody());
            } else {
                abortSJobsLogs.Status__c = 'Failed';
                abortSJobsLogs.Details__c = response.getBody();
                System.debug('Failed to abort scheduled jobs: ' + response.getStatusCode());
                System.debug('Error response: ' + response.getBody());
            }
        } catch (Exception e) {
            abortSJobsLogs.Status__c = 'Failed';
            abortSJobsLogs.Details__c = e.getMessage();
            System.debug('Error occurred while executing anonymous Apex: ' + e.getMessage());
        }
        insert abortSJobsLogs;
    }
    
    @AuraEnabled
    public static void initiateScheduleJobRestoration(Id templateId) {
        Refresh_Template__c refTemp = [select Id, Name, Parent_Org__c from Refresh_Template__c where Id =: templateId];
        Org__c org = [select Id, Domain_Url__c from Org__c where Id =: refTemp.Parent_Org__c];
        
        String targetOrgUrl = org.Domain_Url__c;
        String accessToken = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(org.Id);
        
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :refTemp.Id];
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : contentDocumentLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }
        
        String csvFileName;
        String csvFileContent;
        if (!contentDocumentIds.isEmpty()) {
            List<ContentVersion> contentVersions = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND Title = 'Scheduled Jobs' limit 1];
            system.debug('contentVersions size --- ' + contentVersions.size());
            
            csvFileName = contentVersions[0].Title;
            system.debug('csvFileName --- ' + csvFileName);
            csvFileContent = contentVersions[0].VersionData.toString();
            system.debug('csvFileContent --- ' + csvFileContent);
        }
        
        String fileContentBase64 = EncodingUtil.base64Encode(Blob.valueOf(csvFileContent));
        
        //MetadataService.MetadataPort service = createService(org.Id, targetOrgUrl);
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        String version = '59.0';
        service.endpoint_x = targetOrgUrl + '/services/Soap/m/' + version;
        if(!test.isRunningTest()){ service.SessionHeader.sessionId = accessToken; }
        else{ service.SessionHeader.sessionId = '12345'; }
        service.timeout_x = 120000;
        
        MetadataService.StaticResource staticResource = new MetadataService.StaticResource();
        staticResource.fullName = 'ScheduledJobBackup'+templateId;
        staticResource.cacheControl = 'Public';
        staticResource.contentType = 'text/csv';
        staticResource.content = fileContentBase64;
        
        List<MetadataService.SaveResult> results = new List<MetadataService.SaveResult>();
        if(!test.isRunningTest()){ results = service.createMetadata(new MetadataService.Metadata[] { staticResource }); }
        else {
            MetadataService.SaveResult mockResult = new MetadataService.SaveResult();
            mockResult.fullName = 'ScheduledJobBackup'+templateId;
            mockResult.success = true;
            mockResult.errors = null;
            
            results.add(mockResult);
        }
        // below is the response when the static resource is created successfully in the target org
        // results = '(SaveResult:[apex_schema_type_info=(http://soap.sforce.com/2006/04/metadata, true, false), errors=null, errors_type_info=(errors, http://soap.sforce.com/2006/04/metadata, null, 0, -1, false), field_order_type_info=(errors, fullName, success), fullName=ScheduledJobBackup, fullName_type_info=(fullName, http://soap.sforce.com/2006/04/metadata, null, 1, 1, false), success=true, success_type_info=(success, http://soap.sforce.com/2006/04/metadata, null, 1, 1, false)])';
        
        if (results != null && results[0].success) {
            System.debug('Static Resource uploaded successfully: ' + results[0].fullName);
            scheduleJobsInTargetOrg(templateId, accessToken);
        } else {
            System.debug('Failed to upload Static Resource: ' + results[0].errors[0].message);
        }
    }
    
    public static String generateScheduleJobsFromCsvCode(String staticResourceName, String emailId) {
        String apexCode = 
            'StaticResource staticResource = [SELECT Body FROM StaticResource WHERE Name = \'' + staticResourceName + '\' LIMIT 1];\n' +
            'Blob csvBlob = staticResource.Body;\n' +
            'String csvContent = csvBlob.toString();\n' +
            'List<String> lines = csvContent.split(\'\\n\');\n' +
            'List<String> errorMessages = new List<String>();\n' +
            'for (Integer i = 1; i < lines.size(); i++) {\n' +
            '    String line = lines[i].trim();\n' +
            '    if (!String.isEmpty(line)) {\n' +
            '        List<String> columns = line.split(\',\');\n' +
            '        if (columns.size() >= 4) {\n' +
            '            String jobName = columns[0].trim().removeStart(\'"\').removeEnd(\'"\');\n' +
            '            String apexClassName = columns[2].trim().removeStart(\'"\').removeEnd(\'"\');\n' +
            '            String cronExpression = columns[3].trim().removeStart(\'"\').removeEnd(\'"\');\n' +
            '            System.debug(\'Processing job: \' + jobName + \', Apex Class: \' + apexClassName + \', Cron: \' + cronExpression);\n' +
            '            try {\n' +
            '                Type apexClassType = Type.forName(apexClassName);\n' +
            '                if (apexClassType != null) {\n' +
            '                    Schedulable schedulableJob = (Schedulable) apexClassType.newInstance();\n' +
            '                    System.schedule(jobName, cronExpression, schedulableJob);\n' +
            '                    System.debug(\'Job successfully scheduled: \' + jobName);\n' +
            '                } else {\n' +
            '                    errorMessages.add(\'Apex class not found for job: \' + jobName + \' (Class: \' + apexClassName + \')\');\n' +
            '                }\n' +
            '            } catch (Exception e) {\n' +
            '                errorMessages.add(\'Error scheduling job: \' + jobName + \n' +
            '                                  \' (Class: \' + apexClassName + \', Cron: \' + cronExpression + \')\\n\' + \n' +
            '                                  \'Error Details: \' + e.getMessage());\n' +
            '            }\n' +
            '        } else {\n' +
            '            errorMessages.add(\'Invalid CSV row: \' + line);\n' +
            '        }\n' +
            '    }\n' +
            '}\n' +
            '// Send a single email if there are errors\n' +
            'if (!errorMessages.isEmpty()) {\n' +
            '    String emailBody = \'The following errors occurred while scheduling jobs:\\n\\n\' + String.join(errorMessages, \'\\n\\n\');\n' +
            '    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();\n' +
            '    email.setToAddresses(new String[] { \'' + emailId + '\' });\n' +
            '    email.setSubject(\'Errors in Scheduling Jobs\');\n' +
            '    email.setPlainTextBody(emailBody);\n' +
            '    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });\n' +
            '}\n';
        
        return apexCode;
    }
    
    public static void scheduleJobsInTargetOrg(Id templateId, String accessToken) {
        String staticResourceName = 'ScheduledJobBackup'+templateId;
        Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c FROM Refresh_Template__c WHERE Id = :templateId];
        Org__c org = [SELECT Id, Name, Domain_Url__c FROM Org__c WHERE Id = :refTemp.Parent_Org__c];
        String targetOrgUrl = org.Domain_Url__c;
        
        String emailId = [select Id, Name, Email from User where Id =: userInfo.getUserId()].Email;
        
        String apexCode = generateScheduleJobsFromCsvCode(staticResourceName, emailId);
        String encodedApex = EncodingUtil.urlEncode(apexCode, 'UTF-8');
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(targetOrgUrl + '/services/data/v59.0/tooling/executeAnonymous/?anonymousBody=' + encodedApex);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        Logs__c sJobsRestoration = new Logs__c();
        sJobsRestoration.Log_Type__c = 'Scheduled Jobs Restoration - Post Refresh';
        sJobsRestoration.Parent_Template__c = templateId;
        
        if (response.getStatusCode() == 200) {
            System.debug('Scheduled jobs successfully created: ' + response.getBody());
            
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Boolean compiled = (Boolean) result.get('compiled');
            system.debug('compiled --- ' + compiled);
            Boolean success = (Boolean) result.get('success');
            system.debug('success --- ' + success);
            Integer line = (Integer) result.get('line');
            Integer column = (Integer) result.get('column');
            String exceptionStackTrace = (String) result.get('exceptionStackTrace');
            String exceptionMessage = (String) result.get('exceptionMessage');
            
            if(compiled && success){
                sJobsRestoration.Status__c = 'Success';
            }
            else{
                sJobsRestoration.Status__c = 'Failed';
                sJobsRestoration.Details__c = exceptionMessage;
                system.debug('Line: --- ' + line + ' --- Column: --- ' + column);
                system.debug('Exception Stack Trace: --- ' + exceptionStackTrace);
                system.debug('Exception Message: --- ' + exceptionMessage);
            }
            
            insert sJobsRestoration;
            deletStaticResourceInTargetOrg(targetOrgUrl, accessToken, staticResourceName);
        } else {
            sJobsRestoration.Status__c = 'Failed';
            sJobsRestoration.Details__c = response.getBody();
            insert sJobsRestoration;
            //update sJobsRestoration;
            System.debug('Failed to schedule jobs: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }
    
    @future(callout=true)
    public static void deletStaticResourceInTargetOrg(String domainUrl, String accessToken, String staticResourceName) {
        try {
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            service.SessionHeader = new MetadataService.SessionHeader_element();
            String version = '59.0';
            service.endpoint_x = domainUrl + '/services/Soap/m/' + version;
            service.SessionHeader.sessionId = test.isRunningTest() ? '12345' : accessToken;
            service.timeout_x = 120000;
            
            MetadataService.DeleteResult[] deleteResults;
            
            if (!Test.isRunningTest()) { deleteResults = service.deleteMetadata('StaticResource', new String[] { staticResourceName }); } 
            else {
                deleteResults = new List<MetadataService.DeleteResult>();
                MetadataService.DeleteResult mockResult = new MetadataService.DeleteResult();
                mockResult.success = true;
                mockResult.errors = null;
                deleteResults.add(mockResult);
            }
            
            for (MetadataService.DeleteResult result : deleteResults) {
                if (result.success) {
                    System.debug('Successfully deleted the static resource: ' + staticResourceName);
                } else {
                    System.debug('Failed to delete static resource: ' + staticResourceName + ' - Error: ' + result.errors[0].message);
                }
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw e;
        }
    }
    
    @AuraEnabled
    public static Id applyDataMasking(Id sandboxId, Id refTempId, String mapJson){
        system.debug('mapJson --- ' + mapJson);
        Org__c org = [SELECT Id, Name, Domain_Url__c FROM Org__c WHERE Id = :sandboxId];
        String domainUrl = org.Domain_Url__c;
        String accessToken = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(sandboxId);
        
        List<Object> tempList = (List<Object>) JSON.deserializeUntyped(mapJson);
        List<Map<String, Object>> selectedData = new List<Map<String, Object>>();
        
        for (Object obj : tempList) {
            Map<String, Object> map1 = (Map<String, Object>) obj;
            selectedData.add(map1);
        }
        
        if (selectedData.isEmpty()) { throw new AuraHandledException('No data received for masking.');
                                    }
        
        Logs__c dataTransformLog = new Logs__c();
        dataTransformLog.Log_type__c = 'Data Transformation';
        dataTransformLog.Status__c = 'InProgress';
        dataTransformLog.Parent_Template__c = refTempId;
        insert dataTransformLog;
        system.debug('dataTransformLog id --- ' + dataTransformLog.Id);
        
        for (Map<String, Object> item : selectedData) {
            String objectType = (String) item.get('type');
            Map<String, Object> item1 = (Map<String, Object>) item;
            
            List<Object> membersList = (List<Object>) item1.get('members');
            List<String> fieldsToMask = new List<String>();
            
            for (Object member : membersList) {
                String field = String.valueOf(member);
                field = field.contains('.') ? field.split('\\.')[1] : field;
                fieldsToMask.add(field);
            }
            
            Database.executeBatch(new FetchRecordsInBatchForMasking(objectType, fieldsToMask, domainUrl, accessToken, dataTransformLog.Id), 25);
        }
        
        return dataTransformLog.Id;
    }
}