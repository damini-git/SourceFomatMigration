public class CsvconverterClass implements database.batchable<id>,Database.Stateful,Database.AllowsCallouts{
    public string instanceUrl;
    public string accessToken;
    public map<id,String> jobIdMap;
    public list<string> jobIdList;
    public id logId;
    public string jobName;
    public List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
    public List<ContentDocumentLink> contentLinksToInsert = new List<ContentDocumentLink>();
    public Map<Id, String> userIdToUsername = new Map<Id, String>();
    public CsvconverterClass(string jobName,map<id,String> jobIdMap, string instanceUrl, string accessToken,id logId){
        this.jobName = jobName;
        this.jobIdMap = jobIdMap;
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.logId = logId;
    }
    
    public List<string> start(Database.BatchableContext bc) {
        string userQuery = '/services/data/v59.0/query/?q=SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC';
        this.userIdToUsername = getCurrentUsersFromTargetOrg(instanceUrl,accessToken,userQuery);
        List<id> jobIdList = new List<id>(jobIdMap.keySet());
        system.debug('JobIdList -------->>>>>>>'+jobIdList);
        return jobIdList;
    }
    
    public void execute(Database.BatchableContext bc, List<id> jobIdList){
        system.debug('Target Org users Size ALL---->'+userIdToUsername.size());
        this.contentVersionsToInsert=contentVersionsToInsert;
        Logs__c log = [select id,name,Status__c,Details__c from Logs__c where id =:logId];
        if(log.Status__c != 'Failed'){
            try{
                errorLogScheduler(jobIdList[0],jobIdMap,instanceUrl,accessToken,logId );
                successLogScheduler(jobIdList[0],jobIdMap,instanceUrl,accessToken,logId );
                this.contentVersionsToInsert = contentVersionsToInsert;
                system.debug('Version Size----->>>>'+contentVersionsToInsert.size());
            }catch(exception e){
                system.debug(e.getMessage());
                String errorMessage = jobIdMap.get(jobIdList[0]) + e.getMessage();
                
                if (log.status__c == 'InProgress') {
                    log.Status__c = 'Failed';
                    log.Details__c = errorMessage;
                    update log;
                }
            }
        }
    }
    public void finish(Database.BatchableContext bc){
        Logs__c log = [select id,name,Status__c,Details__c from Logs__c where id =:logId];
        if(log.status__c != 'Failed'){
            this.contentVersionsToInsert = contentVersionsToInsert;
            
            if (!contentVersionsToInsert.isEmpty()) {
                insert contentVersionsToInsert;
                
                for (ContentVersion contentVersion : contentVersionsToInsert) {
                    ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                    contentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId 
                                                             FROM ContentVersion 
                                                             WHERE Id = :contentVersion.Id
                                                            ].ContentDocumentId;
                    contentDocumentLink.LinkedEntityId = logId; 
                    contentDocumentLink.ShareType = 'V';
                    contentDocumentLink.Visibility = 'AllUsers'; 
                    contentLinksToInsert.add(contentDocumentLink); 
                }
                
                insert contentLinksToInsert;
            }
            
            system.debug('contentVersionsToInsert Size----->>>>'+contentVersionsToInsert.size());
            
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            for(ContentVersion content : contentVersionsToInsert){
                Blob fileData = content.VersionData;
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(content.Title + '.csv');
                attachment.setBody(fileData);
                emailAttachments.add(attachment);
            }
            
            Id userId = UserInfo.getUserId();
            
            User currentUser = [SELECT Email,Lastname FROM User WHERE Id = :userId LIMIT 1];
            String userEmail = currentUser.Email;
            string lastName = String.valueOf(currentUser.LastName);
            List<String> emailAddresses = new List<String>();
            emailaddresses.add(userEmail);
            
            
            Logs__c logName = [select Id, Name,Parent_Template__c,Parent_Template__r.Parent_Org__r.name from Logs__c where id =: logid];
            string name = logName.Name;
            string orgName = logName.Parent_Template__r.Parent_Org__r.name;
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            
            if(!test.isRunningTest()){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(emailAddresses);
                email.setSubject('Completion of User Restoration for '+orgName);
                email.setHtmlBody('Dear <b>' + lastName + '</b>,<br/><br/>' +
                                  'We are pleased to inform you that the User Restoration process for the sandbox <b>' + orgName + '</b> has been successfully completed.<br/><br/>' +
                                  'Attached to this email, you will find CSV documents detailing both the success and failure records. For a more comprehensive log, please refer to the following link: <a href="' + baseUrl + '/lightning/r/Logs__c/' + log.id + '/view">' + name + '</a><br/><br/>' +
                                  'Thank you for your attention.<br/><br/>' +
                                  '<hr>' + // This adds a horizontal line between the sections
                                  '<b>This is a system generated mail. Please do not reply to this email ID.</b>');
                email.setFileAttachments(emailAttachments);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
            if(log.Status__c != 'Failed'){
                log.Status__c = 'Completed';
                log.Details__c = ''; 
                update log;
            }
            cancelScheduledJob(jobName);
        }
    }
    public  Map<id, string> getCurrentUsersFromTargetOrg(string instanceUrl, string accessToken,string userQuery) {
        //system.debug('log.Status__c in getCurrentUsersFromTargetOrg--->>>'+log.Status__c);
        
        //Map<id, string> currentusers = new Map<id, string>();
        try{
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + userQuery);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (result.containsKey('records')) {
                    List<Object> records = (List<Object>) result.get('records');
                    
                    
                    for (Object recordObj : records) {
                        Map<String, Object> record = (Map<String, Object>) recordObj;
                        
                        String userId = (String) record.get('Id');
                        String username = (String) record.get('Username');
                        
                        if (userId != null && username != null) {
                            userIdToUsername.put((Id)userId, username);
                        }
                    }
                    
                    String newNextRecordsUrl = (String) result.get('nextRecordsUrl');
                    if (!String.isEmpty(newNextRecordsUrl)) {
                        getCurrentUsersFromTargetOrg(instanceUrl,accessToken,newNextRecordsUrl);
                    }
                } else {
                    //system.debug('No records found in response: ' + res.getBody());
                }
            } 
            //system.debug('Target Org users---->'+currentusers);
            //system.debug('Target Org users Size---->'+currentusers.size());
            //this.userIdToUsername.putAll(currentusers);
            system.debug('Target Org users Size ALL---->'+userIdToUsername.size());
            return userIdToUsername;
        }catch(exception e){
            //system.debug('Error fetching users from target org: ' + e.getMessage());
            
            throw new AuraHandledException('Error fetching users from target org: ' + e.getMessage());
        }
    }
    
    public void errorLogScheduler(id jobId,map<id,string>jobIdMap, String instanceUrl, String accessToken,id logId){
        String bulkApiEndpoint = '/services/data/v58.0/jobs/ingest';
        String objectName = jobIdMap.get(jobId);  
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + bulkApiEndpoint + '/' + jobId + '/failedResults');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeOut(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        String body = res.getBody();
        system.debug('Error log Body---------->>>>>'+ body);
        System.debug('Error Log Body for JobId ' + jobId + ' ------->>' + body);
        String updatedCSV;
        List<String> lines = body.split('\n');
        //system.debug('Body Lines data------>>>'+ lines);
        //system.debug('Body Lines data 1------>>>'+ lines[0]);
        //system.debug('Body Lines data 2------>>>'+ lines[1]);
        
        if (lines.isEmpty()) return;
        if(lines.size() >1){
            if(objectName != 'Insertion'){
                
                String header = lines[0];
                header = header.replace('sf__Id', 'User ID');
                header = header.replace('sf__Error', 'Error');
                header = header.replace('sf__Created', 'Created');
                header = header.replace('email', 'Email');
                List<String> headers = header.split(',');
                
                String userIdHeader = '';
                Integer userIdIndex = headers.indexOf('Id');
                if (userIdIndex != -1) {
                    userIdHeader = 'Id';
                } else{
                    userIdIndex = headers.indexOf('AssigneeId');
                    if (userIdIndex != -1) {
                        userIdHeader = 'AssigneeId';
                    }else{
                        userIdIndex = headers.indexOf('UserOrGroupId');
                        if (userIdIndex != -1) {
                            userIdHeader = 'UserOrGroupId';
                        }else{
                            userIdIndex = headers.indexOf('id');
                            if (userIdIndex != -1) {
                                userIdHeader = 'UserName';
                            }
                        }
                    }
                }
                if (userIdIndex == -1) return;
                
                Set<Id> userIds = new Set<Id>();
                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> cols = lines[i].split(',');
                    if (cols.size() > userIdIndex) {
                        String rawId = cols[userIdIndex].trim().replace('"', '');
                        if (rawId != null && rawId.length() >= 15) {
                            try {
                                userIds.add((Id)rawId);
                            } catch (Exception e) {
                                System.debug('Skipping invalid ID: ' + rawId);
                            }
                        }
                    }
                }
                
                System.debug('User Map------>>>>' + userIdToUsername);
                
                List<String> updatedLines = new List<String>();
                
                updatedLines.add(header.replace(userIdHeader, 'Username'));
                
                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> cols = lines[i].split(',');
                    if (cols.size() > userIdIndex) {
                        String rawId = cols[userIdIndex].trim().replace('"', '');
                        String username = userIdToUsername.containsKey(rawId) ? userIdToUsername.get(rawId) : rawId;
                        cols[userIdIndex] = username;
                    }
                    updatedLines.add(String.join(cols, ','));
                }
                system.debug('updatedLines after'+updatedLines);
                updatedCSV = String.join(updatedLines, '\n');
            }else{
                updatedCSV = body;
            }
            
            
            if (String.isNotBlank(updatedCSV)) {
                Blob csvFileBlob = Blob.valueOf(updatedCSV);
                
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = objectName + ' failed.csv';
                contentVersion.PathOnClient = contentVersion.Title;  // Full file path for the client
                contentVersion.VersionData = csvFileBlob;
                
                contentVersionsToInsert.add(contentVersion);
                
                System.debug('CSV for JobId ' + jobId + ' prepared.');
            }
        }
    }
    
    public void successLogScheduler(id jobId,map<id,string>jobIdMap, String instanceUrl, String accessToken,id logId){
        String bulkApiEndpoint = '/services/data/v58.0/jobs/ingest';
        
        
        String objectName = jobIdMap.get(jobId);  
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + bulkApiEndpoint + '/' + jobId + '/successfulResults');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeOut(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        String body = res.getBody();
        System.debug('Success Log Body for JobId ' + jobId + ' ------->>' + body);
        
        String updatedCSV;
        List<String> lines = body.split('\n');
        if (lines.isEmpty()) return;
        if(lines.size() >1){
            if(objectName != 'Insertion'){
                
                
                String header = lines[0];
                header = header.replace('sf__Id', 'User ID');
                header = header.replace('sf__Error', 'Error');
                header = header.replace('sf__Created', 'Created');
                header = header.replace('email', 'Email');
                List<String> headers = header.split(',');
                
                String userIdHeader = '';
                Integer userIdIndex = headers.indexOf('Id');
                if (userIdIndex != -1) {
                    userIdHeader = 'Id';
                } else{
                    userIdIndex = headers.indexOf('AssigneeId');
                    if (userIdIndex != -1) {
                        userIdHeader = 'AssigneeId';
                    }else{
                        userIdIndex = headers.indexOf('UserOrGroupId');
                        if (userIdIndex != -1) {
                            userIdHeader = 'UserOrGroupId';
                        }else{
                            userIdIndex = headers.indexOf('id');
                            if (userIdIndex != -1) {
                                userIdHeader = 'UserName';
                            }
                        }
                    }
                }
                if (userIdIndex == -1) return;
                
                Set<Id> userIds = new Set<Id>();
                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> cols = lines[i].split(',');
                    if (cols.size() > userIdIndex) {
                        String rawId = cols[userIdIndex].trim().replace('"', '');
                        if (rawId != null && rawId.length() >= 15) {
                            try {
                                userIds.add((Id)rawId);
                            } catch (Exception e) {
                                System.debug('Skipping invalid ID: ' + rawId);
                            }
                        }
                    }
                }
                
                System.debug('User Map------>>>>' + userIdToUsername);
                
                List<String> updatedLines = new List<String>();
                
                updatedLines.add(header.replace(userIdHeader, 'Username'));
                
                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> cols = lines[i].split(',');
                    if (cols.size() > userIdIndex) {
                        String rawId = cols[userIdIndex].trim().replace('"', '');
                        String username = userIdToUsername.containsKey(rawId) ? userIdToUsername.get(rawId) : rawId;
                        cols[userIdIndex] = username;
                    }
                    updatedLines.add(String.join(cols, ','));
                }
                system.debug('updatedLines after'+updatedLines);
                updatedCSV = String.join(updatedLines, '\n');
            }else{
                updatedCSV = body;
            }
            
            
            if (String.isNotBlank(updatedCSV)) {
                Blob csvFileBlob = Blob.valueOf(updatedCSV);
                
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = objectName + ' Success.csv';
                contentVersion.PathOnClient = contentVersion.Title; 
                contentVersion.VersionData = csvFileBlob;
                
                contentVersionsToInsert.add(contentVersion); 
                
                System.debug('CSV for JobId ' + jobId + ' prepared.');
            }        
            this.contentVersionsToInsert=contentVersionsToInsert;
        }
    }
    private void cancelScheduledJob(String jobName) {
        List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        if (jobs.size() > 0) {
            for (CronTrigger job : jobs) {
                System.abortJob(job.Id); 
            }
            System.debug('Scheduled job ' + jobName + ' has been aborted.');
        } else {
            System.debug('No scheduled job found with name ' + jobName);
        }
    }
}