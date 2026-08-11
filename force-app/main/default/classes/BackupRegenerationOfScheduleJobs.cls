public class BackupRegenerationOfScheduleJobs {
    
    @AuraEnabled(cacheable=true)
    public static List<ScheduleJobsWrapper1> fetchScheduledJobs1(string domainUrl, string accessToken, Id refTempId, List<string>jobNames){
        String jobStr = '(\''+String.join(jobNames,'\',\'')+'\')';
        //Blob stringBlob = Blob.valueOf(jobStr);
        String encodedString = EncodingUtil.urlEncode(jobStr,'UTF-8');
        system.debug('JobNames String-------->>>>>'+jobStr);
        system.debug('EncodedJobNames String-------->>>>>'+encodedString);
        
        Logs__c sJobsRegenerationLog = new Logs__c();
        sJobsRegenerationLog.Log_Type__c = 'Scheduled Jobs - Backup Regeneration';
        sJobsRegenerationLog.Parent_Template__c = refTempId;
        
        
        try{
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(domainUrl + '/services/data/v59.0/query/?q=SELECT+Id,ApexClass.Name,JobType,CronTrigger.CronExpression,CronTrigger.CronJobDetail.Name+FROM+AsyncApexJob+WHERE+CronTrigger.CronJobDetail.Name+In+'+encodedString);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeOut(120000);
            
            HttpResponse res = http.send(req);
            system.debug('res status code --- ' + res.getStatusCode());
            
            List<ScheduleJobsWrapper1> jobsWrapList = new List<ScheduleJobsWrapper1>();
            String jobId;
            String jobName;
            String jobType;
            String cronExpression;
            String apexClassName;
            
            if(res.getStatusCode() == 200){
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                system.debug('Response--------->>>'+response);
                List<Object> records = (List<Object>) response.get('records');
                
                for (Object job : records) {
                    Map<String, Object> jobs = (Map<String, Object>) job;
                    //jobId = (String) jobs.get('Id');
                    jobType = (String) jobs.get('JobType');
                    
                    Map<String, Object> cronTrigger = (Map<String, Object>) jobs.get('CronTrigger');
                    system.debug('cronTrigger --- ' + cronTrigger);
                    if(cronTrigger != null){
                        Map<String, Object> apexClassMap = (Map<String, Object>) jobs.get('ApexClass');
                        apexClassName = (String) apexClassMap.get('Name');
                        system.debug('apexClassName --- ' + apexClassName);
                        
                        Map<String, Object> cronJobDetail = (Map<String, Object>) cronTrigger.get('CronJobDetail');
                        jobName = (String) cronJobDetail.get('Name');
                        system.debug('jobName --- ' + jobName);
                        cronExpression = (String) cronTrigger.get('CronExpression');
                        system.debug('cronExpression --- ' + cronExpression);
                        jobsWrapList.add(new ScheduleJobsWrapper1(jobId, jobName, jobType, cronExpression, apexClassName));
                    }
                }
                
                sJobsRegenerationLog.Status__c = 'InProgress';
                insert sJobsRegenerationLog;
            }
            else{
                sJobsRegenerationLog.Status__c = 'Failed';
                sJobsRegenerationLog.Details__c = res.getStatus();
                insert sJobsRegenerationLog;
            }
            
            system.debug('jobsWrapList --- ' + jobsWrapList);
            
            if(jobsWrapList != null){
                generateCsvForScheduledJobs(refTempId, jobsWrapList, sJobsRegenerationLog.Id);
            }
            return jobsWrapList;
        }
        catch(Exception e){
            sJobsRegenerationLog.Status__c = 'Failed';
            sJobsRegenerationLog.Details__c = e.getMessage();
            insert sJobsRegenerationLog;
            throw new AuraHandledException('Error fetching validation status: ' + e.getMessage());
        }
    }
    
    public static void generateCsvForScheduledJobs(Id refTempId, List<ScheduleJobsWrapper1> jobsWrapList, Id sJobsRegenerationLogId){
        system.debug('jobsWrapList---------->>>>'+jobsWrapList);
        List<String> cronJobDetailsIds = new List<String>();
        String csvString = '"Job Name","Job Type","Apex Class","Cron Expression"\n';
        for (ScheduleJobsWrapper1 job : jobsWrapList) {
            String jobName = job.jobName != null ? job.jobName : '';
            String jobType = job.jobType != null ? job.jobType : '';
            String apexClass = job.apexClassName != null ? job.apexClassName : '';
            String cronExpression = job.cronExpression != null ? job.cronExpression : '';
            
            csvString += '"' + jobName + '","' + jobType + '","' + apexClass + '","' + cronExpression + '"\n';
        }
        system.debug('Schedule Jobs Csv--------->>>'+csvString);
        insertCsvAsAttachmentForSJobs(refTempId, csvString, sJobsRegenerationLogId);
    }
    
    private static void insertCsvAsAttachmentForSJobs(Id refTempId, String csvString, Id sJobsRegenerationLogId) {
       Logs__c sJobsRegenerationLog = [select Id, Status__c, Details__c from Logs__c where Id =: sJobsRegenerationLogId];
        
        ContentDocumentLink attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId = :refTempId 
                                           AND ContentDocument.Title LIKE '%Scheduled Jobs%' LIMIT 1
                                          ];
        delete attachments;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Scheduled Jobs';
        contentVersion.PathOnClient = 'Scheduled Jobs.csv';
        contentVersion.VersionData = Blob.valueOf(csvString);
        insert contentVersion;
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = refTempId;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink;
        
        sJobsRegenerationLog.Status__c = 'Success';
        update sJobsRegenerationLog;
    }
    
    public class ScheduleJobsWrapper1 {
        @AuraEnabled public String jobId { get; set; }
        @AuraEnabled public String jobName { get; set; }
        @AuraEnabled public String jobType { get; set; }
        @AuraEnabled public String cronExpression { get; set; }
        @AuraEnabled public String apexClassName { get; set; }
        
        public ScheduleJobsWrapper1(String jobId, String jobName, String jobType, String cronExpression, String apexClassName) {
            this.jobId = jobId;
            this.jobName = jobName;
            this.jobType = jobType;
            this.cronExpression = cronExpression;
            this.apexClassName = apexClassName;
        }
    }
}