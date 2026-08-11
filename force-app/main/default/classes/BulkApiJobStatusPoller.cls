public class BulkApiJobStatusPoller implements Schedulable, Database.AllowsCallouts,database.stateful{
    
    public string instanceUrl;
    public string accessToken;
    public id logId;
    public string orgName;
    public string operationType;
    public Map<id,string> jobIds;
    private String scheduledJobName;
    public static string errorCsvContent;
    public static List<ContentVersion> cv = new List<ContentVersion>();
    
    public BulkApiJobStatusPoller(String jobName,Map<id,string> jobIds,string instanceUrl, string accessToken,id logId,string orgName,string operationType) {
        this.jobIds = jobIds;
        this.scheduledJobName = jobName;
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.logId = logId;
        this.operationType = operationType;
        this.orgName = orgName;
        system.debug('jobIds---->>>>>'+jobIds);
    }
    
    public void execute(SchedulableContext context) {
        Boolean allJobsComplete = true;
        
        for (Id jobId : jobIds.keyset()) {
            getJobStatus(jobId,instanceUrl,accessToken,logId); 
        }
        Logs__c log = [SELECT Id, Name, Log_Type__c, Status__c, Details__c, Error_Code__c,JobStatus__c,Parent_Template__c FROM Logs__c where Id =: logId ];
        List<String> jobStatusList = new List<String>();
        system.debug('JobStatus----->>>>'+log.JobStatus__c);
        if(log.JobStatus__c != null){
            jobStatusList = log.JobStatus__c.split(',');
            if(jobStatusList.contains('Open') || jobStatusList.contains('UploadComplete') || jobStatusList.contains('InProgress')){
                allJobsComplete = false;
                cancelScheduledJob(scheduledJobName);
                
                Datetime nextRunTime = Datetime.now().addMinutes(1);
                String cronExpression = nextRunTime.second() + ' ' +
                    nextRunTime.minute() + ' ' +
                    nextRunTime.hour() + ' ' +
                    nextRunTime.day() + ' ' +
                    nextRunTime.month() + ' ? ' +
                    nextRunTime.year();
                BulkApiJobStatusPoller poller = new BulkApiJobStatusPoller(scheduledJobName,jobIds, instanceUrl, accesstoken,logId,orgName,operationType);
                String scheduleJobId = system.schedule(scheduledJobName, cronExpression, poller);
                log.JobStatus__c = '';
                update log;
            }else if(jobStatusList.contains('JobComplete') || jobStatusList.contains('Aborted') || jobStatusList.contains('Failed')){
                allJobsComplete = true;
            }
        }else{
            allJobsComplete = false;
            cancelScheduledJob(scheduledJobName);
            
            Datetime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
            BulkApiJobStatusPoller poller = new BulkApiJobStatusPoller(scheduledJobName,jobIds, instanceUrl, accesstoken,logId,orgName,operationType);
            String scheduleJobId = system.schedule(scheduledJobName, cronExpression, poller);
        }
        
        if (allJobsComplete) {
            System.debug('All jobs are in a terminal state. Fetching successful results...');
            database.executeBatch(new UserTransformationCsvConverterClass(scheduledJobName,jobIds,instanceUrl,accessToken,logId,operationType),1);
        } else {
            System.debug('Jobs are not yet complete. Will check again in 5 minutes.');
        }
    }
    @future(callout=true)
    public static void getJobStatus(Id jobId,string instanceUrl,string accessToken,id logId) {
        Logs__c log = [SELECT Id, Name, Log_Type__c, Status__c, Details__c, Error_Code__c,JobStatus__c,Parent_Template__c FROM Logs__c where Id =: logId ];
        //Logs__c log = (Logs__c)JSON.deserialize(logJson, Logs__c.class);
        String url = instanceUrl + '/services/data/v58.0/jobs/ingest/' + jobId;
        String state;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken); 
        request.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        system.debug('getJobStatus---->>>>'+response);
        if (response != null && response.getStatusCode() == 200) {
            Map<String, Object> jobStatus = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            state = (String) jobStatus.get('state');
            system.debug('getJobStatus state->>>> '+state);
            if (log.JobStatus__c != null) {
                log.JobStatus__c += ', ' + state;  
                update log;
                system.debug('JobStatus----->>>>'+log.JobStatus__c);
            } else {
                log.JobStatus__c = state;  
                update log;
                system.debug('JobStatus----->>>>'+log.JobStatus__c);
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