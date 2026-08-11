public class CustomSettingsInsertionLogScheduler implements Schedulable, Database.AllowsCallouts{
    public string instanceUrl;
    public string accessToken;
    public map<string,String> jId;
    public id logId;
    public string jobName;
    
    public CustomSettingsInsertionLogScheduler(string jobName,map<string,String> jId, string instanceUrl, string accessToken,id logId){
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.jId = jid;
        this.logId = logId;
        this.jobName = jobName;
    }
    
    public void execute(SchedulableContext sc){
        Logs__c log = [select Id, Name,status__c,details__c from Logs__c where id =: logid];
        if(log.Status__c != 'Failed'){
            database.executeBatch(new CustomSettingsBulkApiJobLog(jobName,jId,instanceUrl,accessToken,logId),1);
        }
    }
}