public class UserActivation implements database.batchable<id>, Database.Stateful, Database.AllowsCallouts{
    public List<Id> userIds;
    public Id refTempId;
    public string logType;
    public string accessToken;
    public string instanceUrl;
    public string orgId;
    public string jobId;
    public string orgName;
    public id logId;
    public Logs__c log;
    public Refresh_Template__c refTemp;
    public Map<Id, String> jobIds = new Map<Id, String>();
    public UserActivation(Id refTempId, List<Id> userIds,string logType,id logId) {
        this.userIds = userIds;
        this.refTempId = refTempId;
        this.logType = logType;
        this.logId = logId;
        this.log = [select Id, Name,Status__c, Parent_Template__c, Details__c,Log_Type__c from Logs__c where id =: logId];
    }
    
    public List<Id> start(Database.BatchableContext bc) {
        try{
            Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c,Parent_Org__r.name FROM Refresh_Template__c where id =: refTempId LIMIT 1];
            instanceUrl = refTemp.Parent_Org__r.Domain_Url__c;
            orgId = refTemp.Parent_Org__c;
            orgName = refTemp.Parent_Org__r.name;
           
            return userIds;
        }catch(exception e){
            system.debug(e.getMessage());
            log.Status__c = 'Failed';
            log.Details__c = e.getMessage();
            update log; 
            throw e;
        }
    }
    
    public void execute(Database.BatchableContext bc, List<id> userIds) {
        
        if(!test.isRunningTest()){ accessToken = RefreshTokenCallout.fetchAT1(orgId);
        }else{
            accessToken ='1234567890';
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        try{
            jobId = BulkUserActivation.activateUsersUsingBulkAPI(userIds, instanceUrl, accesstoken);
            id logId = log.Id;
            string logType = log.Log_Type__c;
            jobIds.put(jobId,'User Activation');
            DateTime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
            string jobName = 'BulkJobPoller '+system.now();
            string operationtype = 'User Activation';
            BulkApiJobStatusPoller scheduledJob = new BulkApiJobStatusPoller(jobName,jobIds, instanceUrl, accesstoken,logId,orgName,operationtype);
            String scheduleJobId = system.schedule(jobName, cronExpression, scheduledJob);
        }catch(exception e){
            system.debug(e.getMessage());
            log.Status__c = 'Failed';
            log.Details__c = e.getMessage();
            update log;
        }
    }
}