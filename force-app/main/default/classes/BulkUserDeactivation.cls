public class BulkUserDeactivation {
    private static final String BULK_API_ENDPOINT = '/services/data/v58.0/jobs/ingest';
    @AuraEnabled
    public static string deactivateUsersUsingBulkAPI(List<Id> userIds,string instanceUrl, string accesstoken) {
        string eId;
        if (userIds == null || userIds.isEmpty()) {
            throw new AuraHandledException('No user IDs provided.');
        }
        
        
        String csvData = prepareCSV(userIds);
        
        String jobId = createBulkJob(instanceUrl,accessToken);
        //String jobId = '750Ig000004swjdIAA';

        // Step 3: Upload data to the bulk job
        uploadDataToBulkJob(jobId, csvData,instanceUrl,accessToken);

        // Step 4: Close the job
         eId = closeBulkJob(jobId,instanceUrl,accessToken);
        //system.debug('UserDeactivation Job Id---->>>'+eId);
        return eId;
    }
    
    // Method to prepare CSV data for user deactivation
    private static String prepareCSV(List<Id> userIds) {
        String header = 'Id,IsActive';
        List<String> rows = new List<String>();
        rows.add(header);
        
        for (Id userId : userIds) {
            rows.add(userId + ',false');
        }
        //system.debug('Deactivation CSV-------->'+String.join(rows, '\n'));
        return String.join(rows, '\n');
    }
    
    // Method to create a bulk job
    private static String createBulkJob(string instanceUrl, string accesstoken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + BULK_API_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accesstoken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        
        String body = JSON.serialize(new Map<String, Object>{
            'object' => 'User',
                'operation' => 'update',
                'contentType' => 'CSV',
                'lineEnding' => 'LF'
                });
        
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        //system.debug('Deactivation createBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to create bulk job: ' + res.getBody());
        }
        
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        //system.debug('Deactivation Job Id---->'+(String) response.get('id'));
        return (String) response.get('id');
    }
    
    // Method to upload data to the bulk job
    private static string uploadDataToBulkJob(String jobId, String csvData,string instanceUrl, string accesstoken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + BULK_API_ENDPOINT + '/' + jobId + '/batches');
        req.setMethod('PUT');
        req.setHeader('Authorization', 'Bearer ' + accesstoken);
        req.setHeader('Content-Type', 'text/csv');
        req.setBody(csvData);
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        //system.debug('Deactivation uploadDataToBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to upload data to bulk job: ' + res.getBody());
        }
        return jobId;
    }
    
    // Method to close the bulk job
    private static string closeBulkJob(String jobId,string instanceUrl, string accesstoken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + BULK_API_ENDPOINT + '/' + jobId);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + accesstoken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        
        String body = JSON.serialize(new Map<String, Object>{ 'state' => 'UploadComplete' });
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        //system.debug('Deactivation closeBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to close bulk job: ' + res.getBody());
        }
        return jobId;
    }
}