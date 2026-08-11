global class FetchRecordsInBatchForMasking implements Database.Batchable<Map<String, Object>>, Database.AllowsCallouts {
    private String objectName;
    private List<String> fieldsToMask;
    private String domainUrl;
    private String accessToken;
    private List<Map<String, Object>> recordsFromOrg2;
    private Id dataTransformLogId;
    
    public FetchRecordsInBatchForMasking(String objectName, List<String> fieldsToMask, String domainUrl, String accessToken, Id dataTransformLogId) {
        this.objectName = objectName;
        this.fieldsToMask = fieldsToMask;
        this.domainUrl = domainUrl;
        this.accessToken = accessToken;
        this.recordsFromOrg2 = new List<Map<String, Object>>();
        this.dataTransformLogId = dataTransformLogId;
    }
    
    global Iterable<Map<String, Object>> start(Database.BatchableContext bc) {
        recordsFromOrg2 = fetchRecordsFromTargetOrg();
        return recordsFromOrg2;
    }
    
    global void execute(Database.BatchableContext bc, List<Map<String, Object>> records) {
        System.enqueueJob(new MaskDataQueueable(records, fieldsToMask, objectName, domainUrl, accessToken, 0, dataTransformLogId));
    }
    
    global void finish(Database.BatchableContext bc) {
        try {
            Logs__c log = [SELECT Id, Status__c, Details__c FROM Logs__c WHERE Id = :dataTransformLogId];
            system.debug('log.Status__c in finish method of batch class --- ' + log.Status__c);
            if (log.Status__c != 'Failed') { log.Status__c = 'Completed'; log.Details__c = ''; update log;
            }
        } catch(Exception ex) {
            System.debug('Error updating log in finish: ' + ex.getMessage());
        }
        System.debug('Batch Job Completed Successfully');
    }
    
    private List<Map<String, Object>> fetchRecordsFromTargetOrg() {
        Logs__c dataTransformLog = [select Id, Status__c, Details__c from Logs__c where Id =: dataTransformLogId];
        
        List<Map<String, Object>> recordsList = new List<Map<String, Object>>();
        try {
            String endpoint = domainUrl + '/services/data/v60.0/query/?q=SELECT+Id,+' + String.join(fieldsToMask, ',') + '+FROM+' + objectName;

            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);

            Http http = new Http();
            HttpResponse response = http.send(request);
            System.debug('Org2 Response: ' + response.getBody());

            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> records = (List<Object>) jsonResponse.get('records');
                system.debug('records of target org --- ' + records);

                for (Object recordObj : records) {
                    recordsList.add((Map<String, Object>) recordObj);
                }
                system.debug('recordsList size --- ' + recordsList.size());
            }
            else {
                updateLogFailure('Callout failed in fetchRecordsFromTargetOrg. Status Code: ' + response.getStatusCode() + ', Response: ' + response.getBody());
            }
        } catch (Exception e) {
            updateLogFailure('Error fetching records from target org: ' + e.getMessage());
            System.debug('Error fetching records from target org: ' + e.getMessage());
        }
        return recordsList;
    }
    
    private void updateLogFailure(String errorMessage) {
        try {
            Logs__c log = [SELECT Id, Status__c, Details__c FROM Logs__c WHERE Id = :dataTransformLogId];
            log.Status__c = 'Failed';
            log.Details__c = (log.Details__c == null ? '' : log.Details__c + ' ') + errorMessage;
            update log; } catch(Exception ex) {
            System.debug('Error updating log failure: ' + ex.getMessage());
        }
    }
}