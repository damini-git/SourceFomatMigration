public class BulkEmailValidation {
private static final String BULK_API_ENDPOINT = '/services/data/v58.0/jobs/ingest';
    
    @AuraEnabled
    public static string validateEmailUsingBulkAPI(List<Map<String, String>> emailList,string instanceUrl, string accesstoken) {
        string eId;
        if (emailList == null || emailList.isEmpty()) {
            throw new AuraHandledException('No user IDs provided.');
        }
        
        String csvData = prepareCSV(emailList);
        
        String jobId = createBulkJob(instanceUrl,accessToken);

        uploadDataToBulkJob(jobId, csvData,instanceUrl,accessToken);

         eId = closeBulkJob(jobId,instanceUrl,accessToken);
        system.debug('EmailValidation Job Id---->>>'+eId);
        return eId;
    }
    
    // Method to prepare CSV data for user deactivation
    private static String prepareCSV(List<Map<String, String>> emailList) {
        String csvContent = 'id,email\n';
        
        for (Map<String, String> emailMap : emailList) {
            String id = emailMap.get('userId');
            String email = emailMap.get('email');
            
            csvContent += id + ',' + email + '\n';
        }
        system.debug(csvContent);
        return csvContent;
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
        system.debug('Email Validation createBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to create bulk job: ' + res.getBody());
        }
        
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        system.debug('Email Validation Job Id---->'+(String) response.get('id'));
        return (String) response.get('id');
    }
    
    // Method to upload data to the bulk job
    private static string uploadDataToBulkJob(String jobId, String csvData,string instanceUrl, string accesstoken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + BULK_API_ENDPOINT + '/' + jobId + '/batches');
        req.setMethod('PUT');
        req.setHeader('Authorization', 'Bearer ' + accesstoken);
        req.setHeader('Content-Type', 'text/csv');
        req.setTimeout(120000);
        req.setBody(csvData);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        system.debug('Email Validation uploadDataToBulkJob--------->'+res.getStatusCode());
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
        system.debug('Email Validation closeBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Email Validation to close bulk job: ' + res.getBody());
        }
        return jobId;
    }
}