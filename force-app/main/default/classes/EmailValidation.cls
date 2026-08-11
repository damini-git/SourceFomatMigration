public class EmailValidation implements database.batchable<Map<String, string>>, Database.Stateful, Database.AllowsCallouts{
    public List<Map<String, string>>emailList;
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
    public EmailValidation(Id refTempId, List<Map<String, string>>emailList,string logType,id logId) {
        this.emailList = emailList;
        this.refTempId = refTempId;
        this.logType = logType;
        this.logId = logId;
        system.debug('logType Inside Email Validation--------->>>>>'+logType);
        this.log = [select Id, Name,Status__c, Parent_Template__c, Details__c,Log_Type__c from Logs__c where id =: logId];
    }
    
    public List<Map<String, string>> start(Database.BatchableContext bc) {
        try{
            Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c,Parent_Org__r.name FROM Refresh_Template__c where id =: refTempId LIMIT 1];
            instanceUrl = refTemp.Parent_Org__r.Domain_Url__c;
            orgId = refTemp.Parent_Org__c;
            orgName = refTemp.Parent_Org__r.name;
           
            system.debug('emailList------->>>'+emailList);
            return emailList;
        }catch(exception e){
            system.debug(e.getMessage());
            log.Status__c = 'Failed';
            log.Details__c = e.getMessage();
            update log; 
            throw e;
        }
    }
    public void execute(Database.BatchableContext bc, List<Map<String, string>>emailList) {
        system.debug('UnProcessed emailList->>>'+ emailList);
        if(!test.isRunningTest()){
            accessToken = RefreshTokenCallout.fetchAT1(orgId);
        }else{
            accessToken ='1234567890';
        }
        for (Map<String, String> emailEntry : emailList) {
                String userId = emailEntry.get('userId');
                String emailId = emailEntry.get('email');
            system.debug('userId-->>>'+ userId);
             system.debug('emailId-->>>'+ emailId);
                
                if (emailId != null && emailId.contains('.invalid')) {
                    emailId = emailId.replace('.invalid', '');
                }
                emailEntry.put('email', emailId);
            }
        system.debug('Processed emailList->>>'+ emailList);
        this.emailList = emailList;
    }
    
    public void finish(Database.BatchableContext bc) {
        id logId = log.Id;
        try{
            system.debug('Processed emailList inside Finish ---->>>'+ emailList);
            jobId = BulkEmailValidation.validateEmailUsingBulkAPI(emailList, instanceUrl, accesstoken);
            system.debug('logId------->>>'+logId);
            string logType = log.Log_Type__c;
            jobIds.put(jobId,'User Email Validation');
            DateTime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
            string jobName = 'BulkJobPoller '+system.now();
            string operationtype = 'Email Validation';
            BulkApiJobStatusPoller scheduledJob = new BulkApiJobStatusPoller(jobName,jobIds, instanceUrl, accesstoken,logId,orgName,operationType);
            String scheduleJobId = system.schedule(jobName, cronExpression, scheduledJob);
        }catch(exception e){
            system.debug(e.getMessage());
            system.debug('logId in exception------->>>'+logId);
            log.Status__c = 'Failed';
            log.Details__c = e.getMessage();
            update log;
        }
    }
}