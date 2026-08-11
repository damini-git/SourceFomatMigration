public class BulkUserInsertion {
    private static final String BULK_API_ENDPOINT = '/services/data/v58.0/jobs/ingest';
    @AuraEnabled
    public static string insertUsersUsingBulkAPI(List<Map<String, Object>> usersToInsert, string instanceUrl, string accesstoken) {
        string eId;
        string error;
        if (usersToInsert == null || usersToInsert.isEmpty()) {
            throw new AuraHandledException('No user data provided.');
        }

        String csvData = prepareCSV(usersToInsert);

        String jobId = createBulkJob(instanceUrl,accessToken);

        // Step 3: Upload data to the bulk job
        uploadDataToBulkJob(jobId, csvData,instanceUrl,accessToken);

        // Step 4: Close the job
        eId = closeBulkJob(jobId,instanceUrl,accessToken);
        
        //error = getErrors(jobId,instanceUrl,accessToken);
        //system.debug('Insertion Job id ------>>>>>'+eId);
        return eId;
    }

    // Method to prepare CSV data from the input list
    private static String prepareCSV(List<Map<String, Object>> usersToInsert) {
        String header = 'FirstName,LastName,Email,Username,Alias,TimeZoneSidKey,LocaleSidKey,LanguageLocaleKey,EmailEncodingKey,ProfileId';
        List<String> rows = new List<String>();
        rows.add(header);

        for (Map<String, Object> user : usersToInsert) {
            List<String> values = new List<String>();
            values.add((String) user.get('FirstName'));
            values.add((String) user.get('LastName'));
            values.add((String) user.get('Email'));
            values.add((String) user.get('Username'));
            values.add((String) user.get('Alias'));
            values.add((String) user.get('TimeZoneSidKey'));
            values.add((String) user.get('LocaleSidKey'));
             values.add((String) user.get('LanguageLocaleKey'));
            values.add((String) user.get('EmailEncodingKey'));
            values.add((String) user.get('ProfileId'));
            rows.add(String.join(values, ','));
        }
        //system.debug('Insertion CSV-------->'+String.join(rows, '\n'));
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
            'operation' => 'insert',
            'contentType' => 'CSV',
            'lineEnding' => 'LF'
        });

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        //system.debug('Insertion createBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            //throw new AuraHandledException('Failed to create bulk job: ' + res.getBody());
        }

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        //system.debug('Insertion Job Id---->'+(String) response.get('id'));
        return (String) response.get('id');
    }

    // Method to upload data to the bulk job
    private static void uploadDataToBulkJob(String jobId, String csvData,string instanceUrl, string accesstoken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + BULK_API_ENDPOINT + '/' + jobId + '/batches');
        req.setMethod('PUT');
        req.setHeader('Authorization', 'Bearer ' + accesstoken);
        req.setHeader('Content-Type', 'text/csv');
        req.setBody(csvData);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);
        //system.debug('Insertion uploadDataToBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to upload data to bulk job: ' + res.getBody());
        }
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
        //system.debug('Insertion closeBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to close bulk job: ' + res.getBody());
        }
        return jobId;
    }
}