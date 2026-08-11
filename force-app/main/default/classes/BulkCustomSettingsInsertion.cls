public class BulkCustomSettingsInsertion {
    private static final String BULK_API_ENDPOINT = '/services/data/v58.0/jobs/ingest';
    
    @AuraEnabled
    public static Map<String,string> insertCustomSettingsUsingBulkAPI(ContentDocumentLink attachments, String instanceUrl, String accesstoken,id logid) {
        
        map<string,string> objIdMap = new map<string,string>();
        List<String> jobIds = new List<String>();
        
        ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments.ContentDocumentId LIMIT 1];
        Blob csvBlob = version.VersionData;
        String csvData = csvBlob.toString();
        String objName = version.Title.replaceAll('__c\\([^\\)]*\\)', '__c');
        
        List<string> lines = csvData.split('\n');
        system.debug('Size of Body lines------->>>>>>'+lines.size());
        system.debug(' Body lines------->>>>>>'+lines);
        
        if(lines.size() >1){
        objIdMap = createBulkJob(objName, instanceUrl, accesstoken,logId);
        
        string jobId = objIdMap.keySet().iterator().next();
        
        uploadDataToBulkJob(jobId, csvData, instanceUrl, accesstoken,logId);
        
        string jid = closeBulkJob(jobId, instanceUrl, accesstoken,logId);
        system.debug('JobId------->'+jid);
            
            system.debug(objIdMap);
        return objIdMap;
        }else{
            return null;
        }
         
    }
    
    public static map<string,string> createBulkJob(String objName, String instanceUrl, String accesstoken,id logid) {
        Logs__c log = [select Id, Name,status__c,details__c from Logs__c where id =: logid];
        map<string,string> idObjMap = new map<string,string>();
        if(log.status__c != 'Failed'){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + BULK_API_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accesstoken);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            system.debug('CustomSettings Name-------------->'+ObjName);
            
            String body = JSON.serialize(new Map<String, Object>{
                'object' => objName,  
                    'operation' => 'insert',          
                    'contentType' => 'CSV',         
                    'lineEnding' => 'LF'            
                    });
            
            req.setBody(body);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
                log.Status__c = 'Failed';
                log.Error_Code__c = res.getStatusCode().toString();
                log.Details__c = req.getBody();
                update log;
                system.debug('status Of lOg in Bulk APi ------>>>'+log.status__c);
            }else{
                system.debug(res.getBody());
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                string obj = (String) response.get('id');
                idObjMap.put(obj,objName);
                system.debug((String) response.get('id'));
            }        
        }
        return idObjMap;
    }
    
    public static void uploadDataToBulkJob(String jobId, String csvData, String instanceUrl, String accesstoken,id logid) {
        Logs__c log = [select Id, Name,status__c,details__c from Logs__c where id =: logid];
        if(log.status__c != 'Failed'){
            if (String.isEmpty(csvData)) {
                throw new AuraHandledException('CSV data is empty or invalid.');
            }else{
                try {
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(instanceUrl + BULK_API_ENDPOINT + '/' + jobId + '/batches');
                    req.setMethod('PUT'); 
                    req.setHeader('Authorization', 'Bearer ' + accesstoken);
                    req.setHeader('Content-Type', 'text/csv');  
                    req.setTimeout(120000);
                    
                    req.setBody(csvData);  
                    
                    Http http = new Http();
                    HttpResponse res = http.send(req);
                    
                    if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
                        log.Status__c = 'Failed';
                        log.Error_Code__c = res.getStatusCode().toString();
                        log.Details__c = req.getBody();
                        update log;
                    }
                } catch (Exception e) {
                    log.Status__c = 'Failed';
                    log.Details__c = e.getMessage();
                    update log;
                    throw new AuraHandledException('Error while uploading CSV data: ' + e.getMessage());
                }
            }
        }
    }
    
    public static String closeBulkJob(String jobId, String instanceUrl, String accesstoken,id logid) {
        Logs__c log = [select Id, Name,status__c,details__c from Logs__c where id =: logid];
        if(log.Status__c != 'Failed'){
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
            
            if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
                log.Status__c = 'Failed';
                log.Error_Code__c = res.getStatusCode().toString();
                log.Details__c = req.getBody();
                update log;
            }
        }
        return jobId;  
    }
}