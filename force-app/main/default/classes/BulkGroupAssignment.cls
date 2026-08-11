public class BulkGroupAssignment {
    private static final String BULK_API_ENDPOINT = '/services/data/v58.0/jobs/ingest';
    @AuraEnabled
    public static string assignGroupsUsingBulkAPI(Map<Id, List<String>> finalGroup,string instanceUrl, string accesstoken) {
        string eId;
        string error;
        if (finalGroup == null || finalGroup.isEmpty()) {
            throw new AuraHandledException('No group assignments provided.');
        }

        String csvData = prepareCSV(finalGroup);

        // Step 2: Create a bulk job
        String jobId = createBulkJob(instanceUrl,accessToken);
        //String jobId = '750Ig000004swjdIAA';

        // Step 3: Upload data to the bulk job
        uploadDataToBulkJob(jobId, csvData,instanceUrl,accessToken);

        // Step 4: Close the job
        eid = closeBulkJob(jobId,instanceUrl,accessToken);
        
       //error = getErrors(jobId,instanceUrl,accessToken);
       //system.debug('User group Assignment JobId----->>>>'+eId);
        return eid;
    }

    // Method to prepare CSV data for permission set assignments
    private static String prepareCSV(Map<Id, List<String>> finalGroup) {
        String header = 'UserOrGroupId,GroupId';
        List<String> rows = new List<String>();
        rows.add(header);

        for (Id assigneeId : finalGroup.keySet()) {
             Set<String> uniqueGroupId = new Set<String>(finalGroup.get(assigneeId));
            for (String groupId : uniqueGroupId) {
                rows.add(assigneeId + ',' + groupId);
            }
        }
        //system.debug('Group CSV--------->'+String.join(rows, '\n'));
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
            'object' => 'GroupMember',
            'operation' => 'insert',
            'contentType' => 'CSV',
            'lineEnding' => 'LF'
        });

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        //system.debug('Group createBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to create bulk job: ' + res.getBody());
        }

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        //system.debug('Group Job Id---->'+(String) response.get('id'));
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
        //system.debug('Group uploadDataToBulkJob--------->'+res.getStatusCode());
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
        //system.debug('Group closeBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to close bulk job: ' + res.getBody());
        }
        return jobId;
    }
}