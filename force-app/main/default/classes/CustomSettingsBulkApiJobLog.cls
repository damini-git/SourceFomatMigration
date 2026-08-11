public class CustomSettingsBulkApiJobLog implements database.batchable<string>,Database.Stateful,Database.AllowsCallouts{
    public string instanceUrl;
    public string accessToken;
    public map<string,String> jobIdMap;
    public list<string> jobIdList;
    public id logId;
    public string jobName;
    public List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
    public List<ContentDocumentLink> contentLinksToInsert = new List<ContentDocumentLink>();
    
    public CustomSettingsBulkApiJobLog(string jobName,map<string,String> jobIdMap, string instanceUrl, string accessToken,id logId){
        
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
            if(log.Status__c != 'Failed'){
                log.Status__c = 'Completed';
                log.Details__c = ''; 
                update log;
            }
            cancelScheduledJob(jobName);
        }
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
        List<String> lines = body.split('\n');
        if(lines.size() >1){
            if (String.isNotBlank(body)) {
                Blob csvFileBlob = Blob.valueOf(body);
                
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = objectName + ' failed.csv';
                contentVersion.PathOnClient = contentVersion.Title;  // Full file path for the client
                contentVersion.VersionData = csvFileBlob;
                
                contentVersionsToInsert.add(contentVersion);
                
                System.debug('CSV for JobId ' + jobId + ' prepared.');
            }
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
        List<String> lines = body.split('\n');
        if(lines.size() >1){
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