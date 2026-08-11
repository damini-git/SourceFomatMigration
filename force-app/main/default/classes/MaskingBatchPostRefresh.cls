global class MaskingBatchPostRefresh implements Database.Batchable<Map<String, Object>>, Database.AllowsCallouts {
    private String objectType;
    private String domainUrl;
    private String accessToken;
    private List<Map<String, Object>> recordsToUpdate;
    
    public MaskingBatchPostRefresh(String objectType, String domainUrl, String accessToken, List<Map<String, Object>> recordsToUpdate) {
        this.objectType = objectType;
        this.domainUrl = domainUrl;
        this.accessToken = accessToken;
        this.recordsToUpdate = recordsToUpdate;
    }

    global Iterable<Map<String, Object>> start(Database.BatchableContext bc) {
        return recordsToUpdate;
    }

    global void execute(Database.BatchableContext bc, List<Map<String, Object>> scope) {
        System.debug('Processing batch of size: ' + scope.size());
        system.debug('objectType --- ' + objectType);
        
        system.debug('recordsToUpdate --- ' + recordsToUpdate);
        
        for (Map<String, Object> record : scope) {
            String recordId = (String) record.get('Id');
            if (recordId == null) {
                System.debug('Skipping record with no Id');
                continue;
            }

            Map<String, Object> recordForUpdate = new Map<String, Object>(record);
            recordForUpdate.remove('Id');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(domainUrl + '/services/data/v57.0/sobjects/' + objectType + '/' + recordId);
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('PATCH');
            req.setBody(JSON.serialize(recordForUpdate));

            Http http = new Http();
            HttpResponse res;

            try {
                res = http.send(req);
                if (res.getStatusCode() != 204) {
                    System.debug('Failed to update record ' + recordId + ': ' + res.getBody());
                }
            } catch (Exception e) {
                System.debug('Exception caught while making a callout: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('All batches have been processed.');
    }
}