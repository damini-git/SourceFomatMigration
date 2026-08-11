public class PostRefreshUserRestorationErrorScheduler implements Schedulable, Database.AllowsCallouts,database.stateful {
    public string instanceUrl;
    public string accessToken;
    public string orgName;
    public Map<Id, String> jobIds; // Changed from List<string> to Map<Id, String>
    public id logId;
    public static string errorCsvContent;
    public static List<ContentVersion> cv = new List<ContentVersion>();
    
    public PostRefreshUserRestorationErrorScheduler(Map<Id, String> jobIds, string instanceUrl, string accessToken, id logId, string orgName) {
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.jobIds = jobIds; 
        this.logId = logId;
        this.orgName = orgName;
    }
    
    public void execute(SchedulableContext sc) {
        errorLogScheduler(jobIds, instanceUrl, accessToken, logId, orgName);
    }
    
    @future(callout=true)
    public static void errorLogScheduler(Map<Id, String> jobIds, string instanceUrl, string accessToken, id logId, string orgName) {
        Logs__c log = [SELECT id, name, Status__c, Details__c FROM Logs__c WHERE id = :logId];
        
        try {
            String bulkApiEndpoint = '/services/data/v58.0/jobs/ingest';
            List<String> errorLog = new List<String>();
            
            for (Id jobId : jobIds.keySet()) {
                String jobName = jobIds.get(jobId); 
                HttpRequest req = new HttpRequest();
                req.setEndpoint(instanceUrl + bulkApiEndpoint + '/' + jobId + '/failedResults');
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json');
                req.setTimeOut(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                String body = res.getBody();
                
                errorLog.add(body);
                
                String jobErrorCsvContent = generateCsvContent(body, jobName, 'Failure');
                if (!String.isEmpty(jobErrorCsvContent)) {
                    Blob csvFileBlob = Blob.valueOf(jobErrorCsvContent);
                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.Title = 'User Restoration Failure Logs - ' + jobName;  
                    contentVersion.PathOnClient = contentVersion.Title + '.csv';  
                    contentVersion.VersionData = csvFileBlob; 
                    
                    cv.add(contentVersion);
                }
            }
            
            List<String> successLog = new List<String>();
            for (Id jobId : jobIds.keySet()) {
                String jobName = jobIds.get(jobId);
                HttpRequest req = new HttpRequest();
                req.setEndpoint(instanceUrl + bulkApiEndpoint + '/' + jobId + '/successfulResults');
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json');
                req.setTimeOut(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                String body = res.getBody();
                
                successLog.add(body);
                
                String jobSuccessCsvContent = generateCsvContent(body, jobName, 'Success');
                if (!String.isEmpty(jobSuccessCsvContent)) {
                    Blob csvFileBlob = Blob.valueOf(jobSuccessCsvContent);
                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.Title = 'User Restoration Success Logs - ' + jobName;  
                    contentVersion.PathOnClient = contentVersion.Title + '.csv';  
                    contentVersion.VersionData = csvFileBlob; 
                    
                    cv.add(contentVersion);
                }
            }
            insert cv;
            
            List<id> cvId = new List<id>();
            for(contentVersion cid : cv){
                cvId.add(cid.id);
            }
            
            List<contentDocumentLink> cdl = new List<contentDocumentLink>();
            for(id cId : cvId){
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = [
                    SELECT ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id = :cId
                ].ContentDocumentId;
                contentDocumentLink.LinkedEntityId = log.Id;
                contentDocumentLink.ShareType = 'V'; 
                contentDocumentLink.Visibility = 'AllUsers'; 
                cdl.add(contentDocumentLink);
            }
            insert cdl;
            
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            for(ContentVersion content : cv){
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
            
            
            Logs__c logName = [select Id, Name from Logs__c where id =: log.id];
            string name = logName.Name;
            
            if(!test.isRunningTest()){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(emailAddresses);
                email.setSubject('Completion of User Restoration for '+orgName);
                email.setHtmlBody('Dear <b>' + lastName + '</b>,<br/><br/>' +
                                  'We are pleased to inform you that the User Restoration process for the sandbox <b>' + orgName + '</b> has been successfully completed.<br/><br/>' +
                                  'Attached to this email, you will find CSV documents detailing both the success and failure records. For a more comprehensive log, please refer to the following link: <a href="' + URL.getOrgDomainUrl() + '/lightning/r/Logs__c/' + log.id + '/view">' + name + '</a><br/><br/>' +
                                  'Thank you for your attention.<br/><br/>' +
                                  '<hr>' + // This adds a horizontal line between the sections
                                  '<b>This is a system generated mail. Please do not reply to this email ID.</b>');
                email.setFileAttachments(emailAttachments);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
            
            if (log.Status__c != 'Failed') {
                log.Status__c = 'Success';
                log.Details__c = 'The User Restoration Process has been successfully executed';    
                update log;
            }
        } catch (Exception e) {
            if (log.Status__c == 'InProgress') {
                log.Status__c = 'Failed';
                log.Details__c = 'Error Occurred while capturing Logs: ' + e.getMessage();
                update log;
            }
        }
    }
    
    private static String generateCsvContent(String logLine, String jobName, String logType) {
        String csvContent = '';
        if (String.isNotBlank(logLine)) {
            List<String> rows = logLine.split('\n');
            if (!rows.isEmpty()) {
                String headerLine = rows[0];
                csvContent += headerLine + '\n';
                
                for (Integer i = 1; i < rows.size(); i++) {
                    String dataRow = rows[i];
                    if (String.isNotBlank(dataRow)) {
                        if (!dataRow.contains('DUPLICATE_VALUE')) {
                            csvContent += dataRow + '\n';
                        }
                    }
                }
            }
        }
        return csvContent;
    }
}