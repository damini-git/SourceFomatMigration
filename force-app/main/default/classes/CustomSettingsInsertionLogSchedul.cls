public class CustomSettingsInsertionLogSchedul implements database.batchable<string>,Database.Stateful,Database.AllowsCallouts{
    public string instanceUrl;
    public string accessToken;
    public map<string,String> jobIdMap;
    public list<string> jobIdList;
    public id logId;
    public string jobName;
    public List<Map<String, Object>> currentUserRecords;
    public List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
    public List<ContentDocumentLink> contentLinksToInsert = new List<ContentDocumentLink>();
    
    public CustomSettingsInsertionLogSchedul(string jobName,map<string,String> jobIdMap, string instanceUrl, string accessToken,id logId){
        
        this.jobName = jobName;
        this.jobIdMap = jobIdMap;
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.logId = logId; 
    }
    
    public List<string> start(Database.BatchableContext bc) {
        List<String> jobIdList = new List<String>(jobIdMap.keySet());
        system.debug('JobIdList -------->>>>>>>'+jobIdList);
        return jobIdList;
    }
    
    public void execute(Database.BatchableContext bc, List<string> jobIdList){
        errorLogScheduler(jobIdList[0],jobIdMap,instanceUrl,accessToken,logId );
        successLogScheduler(jobIdList[0],jobIdMap,instanceUrl,accessToken,logId );
        this.contentVersionsToInsert = contentVersionsToInsert;
        system.debug('Version Size----->>>>'+contentVersionsToInsert.size());
        
    }
    public void finish(Database.BatchableContext bc){
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
        Logs__c log = [select id,name,Status__c,Details__c from Logs__c where id =:logId];
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
            email.setSubject('Completion of Custom Settings Restoration for '+orgName);
            email.setHtmlBody('Dear <b>' + lastName + '</b>,<br/><br/>' +
                              'We are pleased to inform you that the Custom Settings Restoration process for the sandbox <b>' + orgName + '</b> has been successfully completed.<br/><br/>' +
                              'Attached to this email, you will find CSV documents detailing both the success and failure records. For a more comprehensive log, please refer to the following link: <a href="' + baseUrl + '/lightning/r/Logs__c/' + log.id + '/view">' + name + '</a><br/><br/>' +
                              'Thank you for your attention.<br/><br/>' +
                              '<hr>' + // This adds a horizontal line between the sections
                              '<b>This is a system generated mail. Please do not reply to this email ID.</b>');
            email.setFileAttachments(emailAttachments);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
        
        log.Status__c = 'Completed';
        log.Details__c = ''; 
        update log;
        cancelScheduledJob(jobName);
    }
    
    public void errorLogScheduler(String jobId,map<string,string>jobIdMap, String instanceUrl, String accessToken,id logId){
        String bulkApiEndpoint = '/services/data/v58.0/jobs/ingest';
        String objectName = jobIdMap.get(jobId);  
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + bulkApiEndpoint + '/' + jobId + '/failedResults');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        String body = res.getBody();
        system.debug('Error log Body---------->>>>>'+ body);
        System.debug('Error Log Body for JobId ' + jobId + ' ------->>' + body);
        
        
        
        // Step 1: Parse the CSV into lines
        List<String> lines = body.split('\n');
        if (lines.isEmpty()) return; // No data
        
        // Step 2: Get header and determine the index of the UserId column
        String header = lines[0];
        List<String> headers = header.split(',');
        
        Integer userIdIndex = headers.indexOf('UserId'); // Adjust if field name is different
        if (userIdIndex == -1) return; // No UserId column found
        
        // Step 3: Extract all UserIds from the rows
        Set<Id> userIds = new Set<Id>();
        for (Integer i = 1; i < lines.size(); i++) {
            List<String> cols = lines[i].split(',');
            if (cols.size() > userIdIndex) {
                userIds.add(cols[userIdIndex]);
            }
        }
        
        // Step 4: Query Users
        Map<Id, String> userIdToUsername = new Map<Id, String>();
        for (User u : [SELECT Id, Username FROM User WHERE Id IN :userIds]) {
            userIdToUsername.put(u.Id, u.Username);
        }
        
        // Step 5: Replace UserIds with Usernames
        List<String> updatedLines = new List<String>();
        updatedLines.add(header.replace('UserId', 'Username')); // update header
        
        for (Integer i = 1; i < lines.size(); i++) {
            List<String> cols = lines[i].split(',');
            
            if (cols.size() > userIdIndex) {
                String uid = cols[userIdIndex];
                String username = userIdToUsername.get(uid);
                if (username != null) {
                    cols[userIdIndex] = username;
                }
            }
            updatedLines.add(String.join(cols, ','));
        }
        
        // Step 6: Reconstruct and save CSV
        String updatedCSV = String.join(updatedLines, '\n');
        
        
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
    
    
    public void successLogScheduler(String jobId,map<string,string>jobIdMap, String instanceUrl, String accessToken,id logId){
        String bulkApiEndpoint = '/services/data/v58.0/jobs/ingest';
        
        
        String objectName = jobIdMap.get(jobId);  
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + bulkApiEndpoint + '/' + jobId + '/successfulResults');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        String body = res.getBody();
        System.debug('Success Log Body for JobId ' + jobId + ' ------->>' + body);
        
        if (String.isNotBlank(body)) {                
            Blob csvFileBlob = Blob.valueOf(body);
            
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = objectName + ' Success.csv';
            contentVersion.PathOnClient = contentVersion.Title; 
            contentVersion.VersionData = csvFileBlob;
            
            contentVersionsToInsert.add(contentVersion); 
            
            System.debug('CSV for JobId ' + jobId + ' prepared.');
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
    
    public static void testcsv(){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://cloudfulcrum46-dev-ed.develop.my.salesforce.com/services/data/v58.0/jobs/ingest/750NS00000Ec0uzYAB/failedResults');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer !AQEAQPutfRBGx30pGiW1ZWidXXFrNKpehwD6EQqNiuIxprhdeMYvKPsUgOFTikcfC94LhWc94g4d_5vAJHr7rDYNxZs7Phcf');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        String body = res.getBody();
        system.debug('Error log Body---------->>>>>'+ body);
        
        List<String> lines = body.split('\n');
        if (lines.isEmpty()) return;
        
        String header = lines[0];
        List<String> headers = header.split(',');
        
        Integer userIdIndex = headers.indexOf('Id'); 
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
        
        Map<Id, String> userIdToUsername = new Map<Id, String>();
        userIdToUsername.put('005NS000000Aep0YAC','Testing1');
        userIdToUsername.put('005NS000000Aep3YAC','Testing1');
        userIdToUsername.put('005NS000000Aep2YAC','Testing1');
        
        List<String> updatedLines = new List<String>();
        updatedLines.add(header.replace('UserId', 'Username'));
        
        for (Integer i = 1; i < lines.size(); i++) {
            List<String> cols = lines[i].split(',');
            
            if (cols.size() > userIdIndex) {
                String uid = cols[userIdIndex].trim().replace('"', '');
                String username = userIdToUsername.get(uid);
                if (username != null) {
                    cols[userIdIndex] = '"' + username + '"'; // Maintain CSV format
                }
            }
            updatedLines.add(String.join(cols, ','));
        }
        system.debug('updatedLines after'+updatedLines);
        String updatedCSV = String.join(updatedLines, '\n');
        
        Blob csvFileBlob = Blob.valueOf(updatedCSV);
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Username testing failed.csv';
        contentVersion.PathOnClient = contentVersion.Title;  // Full file path for the client
        contentVersion.VersionData = csvFileBlob;
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId 
                                                 FROM ContentVersion 
                                                 WHERE Id = :contentVersion.Id
                                                ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = 'a3xSu0000012uf3IAA'; 
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers'; 
        insert contentDocumentLink;
        
    }
}