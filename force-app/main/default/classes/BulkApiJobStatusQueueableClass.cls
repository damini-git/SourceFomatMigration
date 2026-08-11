public class BulkApiJobStatusQueueableClass implements Queueable,Database.AllowsCallouts{
    public Map<id,string> jobIds;
    public String instanceUrl;
    public String accessToken;
    public Id logId;
    
    
    public BulkApiJobStatusQueueableClass(Map<id,string> jobIds, String instanceUrl, String accessToken, Id logId) {
        this.jobIds = jobIds;
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.logId = logId;
    }
    
    public void execute(QueueableContext context) {
        Logs__c log = [SELECT Id, Name, Log_Type__c, Status__c, Details__c, Error_Code__c,JobStatus__c,Parent_Template__c FROM Logs__c where Id =: logId ];
        //Logs__c log = (Logs__c)JSON.deserialize(logJson, Logs__c.class);
        for(Id jobId : jobIds.keyset()){
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
                    system.debug('JobStatus----->>>>'+log.JobStatus__c);
                } else {
                    log.JobStatus__c = state;  
                    system.debug('JobStatus----->>>>'+log.JobStatus__c);
                }
                
            }
        }
        update log;
    }
}