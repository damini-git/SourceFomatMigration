public class BulkApiJobPoller implements Schedulable, Database.AllowsCallouts,database.stateful{
    
    public string instanceUrl;
    public string accessToken;
    public id logId;
    public string jobName;
    public string orgName;
    public string logType;
    public Map<id,string> jobIds;
    private String scheduledJobName;
    public static string errorCsvContent;
    public static List<ContentVersion> cv = new List<ContentVersion>();
    
    
    public BulkApiJobPoller(String jobName,Map<id,string> jobIds,string instanceUrl, string accessToken,id logId,string orgName) {
        this.jobIds = jobIds;
        this.scheduledJobName = jobName;
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.logId = logId;
        this.logType = logType;
        this.orgName = orgName;
        system.debug('jobIds---->>>>>'+jobIds);
    }
    
    public void execute(SchedulableContext context) {
        Boolean allJobsComplete;
        
        Logs__c log = [SELECT Id, Name, Log_Type__c, Status__c, Details__c, Error_Code__c,JobStatus__c,Parent_Template__c FROM Logs__c where Id =: logId ];
        List<String> jobStatusList = new List<String>();
        system.debug('JobStatus----->>>>'+log.JobStatus__c);
        if(log.JobStatus__c != null){
            jobStatusList = log.JobStatus__c.split(',');
            system.debug('jobStatusList inside Execution----->>>>'+jobStatusList);
            if(jobStatusList.contains('Open') || jobStatusList.contains('UploadComplete') || jobStatusList.contains('InProgress')){
                allJobsComplete = false;
                log.JobStatus__c ='';
                update log;
                system.enqueueJob(new BulkApiJobStatusQueueableClass(jobIds,instanceUrl,accessToken,logId)); 
                cancelScheduledJob(scheduledJobName);
                
                //String jobName = 'BulkJobPoller';
                Datetime nextRunTime = Datetime.now().addMinutes(5);
                String cronExpression = nextRunTime.second() + ' ' +
                    nextRunTime.minute() + ' ' +
                    nextRunTime.hour() + ' ' +
                    nextRunTime.day() + ' ' +
                    nextRunTime.month() + ' ? ' +
                    nextRunTime.year();
                BulkApiJobpoller poller = new BulkApiJobpoller(scheduledJobName,jobIds, instanceUrl, accesstoken,logId,orgName);
                String scheduleJobId = system.schedule(scheduledJobName, cronExpression, poller);
                log.JobStatus__c = '';
                update log;
            }else if(jobStatusList.contains('JobComplete') || jobStatusList.contains('Aborted') || jobStatusList.contains('Failed') && jobIds.keyset().size() == jobStatusList.size()){
                allJobsComplete = true;
            }
        }else{
            allJobsComplete = false;
            system.enqueueJob(new BulkApiJobStatusQueueableClass(jobIds,instanceUrl,accessToken,logId));
            cancelScheduledJob(scheduledJobName);
            
            String jobName = 'BulkJobPoller';
            Datetime nextRunTime = Datetime.now().addMinutes(5);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
            BulkApiJobpoller poller = new BulkApiJobpoller(scheduledJobName,jobIds, instanceUrl, accesstoken,logId,orgName);
            String scheduleJobId = system.schedule(scheduledJobName, cronExpression, poller);
        }
        
        if (allJobsComplete) {
            System.debug('All jobs are in a terminal state. Fetching successful results...');
            system.debug('jobIds Inside Execution before Completion--------->>>'+jobIds);
            database.executeBatch(new CsvconverterClass(scheduledJobName,jobIds,instanceUrl,accessToken,logId),1);
        } else {
            System.debug('Jobs are not yet complete. Will check again in 5 minutes.');
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