public class BulkPermissionSetAssignment {
    public static String bulkApiEndpoint = '/services/data/v58.0/jobs/ingest';
    @AuraEnabled
    public static string assignPermissionSetsUsingBulkAPI(Map<Id, List<String>> finalPermSet,string instanceUrl, string accesstoken) {
        string eId;
        string error;
        if (finalPermSet == null || finalPermSet.isEmpty()) {
            throw new AuraHandledException('No permission set assignments provided.');
        }

        String csvData = prepareCSV(finalPermSet);

        String jobId = createBulkJob(instanceUrl,accessToken);

        // Step 3: Upload data to the bulk job
        uploadDataToBulkJob(jobId, csvData,instanceUrl,accessToken);

        // Step 4: Close the job
        eid = closeBulkJob(jobId,instanceUrl,accessToken);
        
        //error = getErrors(eid,instanceUrl,accessToken);
        //system.debug('Permission Set Assignment JobId----->>>>'+eId);
        return eid;
    }

    // Method to prepare CSV data for permission set assignments
    public static String prepareCSV(Map<Id, List<String>> finalPermSet) {
        String header = 'AssigneeId,PermissionSetId';
        List<String> rows = new List<String>();
        rows.add(header);

        for (Id assigneeId : finalPermSet.keySet()) {
            Set<String> uniquePermSetId = new Set<String>(finalPermSet.get(assigneeId));
            for (String permSetId : uniquePermSetId) {
                rows.add(assigneeId + ',' + permSetId);
            }
        }
        //system.debug('PermSet CSV-------->'+String.join(rows, '\n'));
        return String.join(rows, '\n');
    }

    // Method to create a bulk job
    public static String createBulkJob(string instanceUrl, string accesstoken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + '/services/data/v58.0/jobs/ingest');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accesstoken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        String body = JSON.serialize(new Map<String, Object>{
            'object' => 'PermissionSetAssignment',
            'operation' => 'insert',
            'contentType' => 'CSV',
            'lineEnding' => 'LF'
        });

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
         //system.debug('PermSet createBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to create bulk job: ' + res.getBody());
        }

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        //system.debug('PermSet Job Id---->'+(String) response.get('id'));
        return (String) response.get('id');
    }

    // Method to upload data to the bulk job
    public static void uploadDataToBulkJob(String jobId, String csvData,string instanceUrl, string accesstoken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + '/services/data/v58.0/jobs/ingest' + '/' + jobId + '/batches');
        req.setMethod('PUT');
        req.setHeader('Authorization', 'Bearer ' + accesstoken);
        req.setHeader('Content-Type', 'text/csv');
        req.setBody(csvData);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);
         //system.debug('PermSet uploadDataToBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to upload data to bulk job: ' + res.getBody());
        }
    }

    // Method to close the bulk job
    public static string closeBulkJob(String jobId,string instanceUrl, string accesstoken) {
        string error;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + '/services/data/v58.0/jobs/ingest' + '/' + jobId);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + accesstoken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        String body = JSON.serialize(new Map<String, Object>{ 'state' => 'UploadComplete' });
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        //system.debug('PermSet closeBulkJob--------->'+res.getStatusCode());
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Failed to close bulk job: ' + res.getBody());
        }
        return jobId;
    }
}