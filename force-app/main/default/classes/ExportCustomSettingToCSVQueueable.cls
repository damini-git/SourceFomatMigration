public class ExportCustomSettingToCSVQueueable{
    
    @future(callout = true)
    public static void calloutToExternalOrg(String customSettingName, List<String> fieldNames, Id sandboxId, Id refTempId, String accessToken, Id customSettingRetrieveLogId) {
        System.enqueueJob(new FetchRecordsQueueable(customSettingName, fieldNames, sandboxId, refTempId, accessToken, customSettingRetrieveLogId));
    }
    
    private class FetchRecordsQueueable implements Queueable, Database.AllowsCallouts {
        private String customSettingName;
        private List<String> fieldNames;
        private Id sandboxId;
        private Id refTempId;
        private String accessToken;
        private String domainUrl;
        private String nextRecordsUrl;
        private String csvContent;
        private Id customSettingRetrieveLogId;
        
        public FetchRecordsQueueable(String customSettingName, List<String> fieldNames, Id sandboxId, Id refTempId, String accessToken, Id customSettingRetrieveLogId) {
            this.customSettingName = customSettingName;
            this.fieldNames = fieldNames;
            this.sandboxId = sandboxId;
            this.refTempId = refTempId;
            this.accessToken = accessToken;
            this.csvContent = String.join(fieldNames, ',') + '\n';
            this.domainUrl = [SELECT Domain_Url__c FROM Org__c WHERE Id = :sandboxId].Domain_Url__c;
            this.customSettingRetrieveLogId = customSettingRetrieveLogId;
        }
        
        public void execute(QueueableContext context) {
            Logs__c customSettingRetrieveLog = [select Id, Status__c, Details__c from Logs__c where Id =: customSettingRetrieveLogId];
            
            try {
                String endpoint = String.isNotEmpty(nextRecordsUrl) ? domainUrl + nextRecordsUrl : domainUrl + '/services/data/v58.0/query?q=' + EncodingUtil.urlEncode(getQuery(), 'UTF-8');
                
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json');
                req.setTimeout(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 401) {
                    accessToken = RefreshTokenCallout.fetchAT1(sandboxId);
                    req.setHeader('Authorization', 'Bearer ' + accessToken);
                    res = http.send(req);
                }
                
                if (res.getStatusCode() == 200) {
                    processResponse(res.getBody(),refTempId,customSettingName);
                } else {
                    System.debug('Error fetching records: ' + res.getBody());
                    return;
                }
            } catch (Exception e) {
                customSettingRetrieveLog.Status__c = 'Failed';
                customSettingRetrieveLog.Details__c = e.getMessage();
                update customSettingRetrieveLog;
                System.debug('Error during callout: ' + e.getMessage());
            }
        }
        
        private String getQuery() {
            return 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + customSettingName;
        }
        
        private void processResponse(String responseBody, id refTempId,String customSettingName) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> records = (List<Object>) responseMap.get('records');
            system.debug('Response of Custom Settings Records --------->>>'+responseMap);
            system.debug('Response of Custom Settings Records Size --------->>>'+responseMap.get('totalSize'));
            object size = responseMap.get('totalSize');
            
            for (Object record : records) {
                Map<String, Object> csRecord = (Map<String, Object>) record;
                List<String> rowValues = new List<String>();
                for (String fieldName : fieldNames) {
                    String value = csRecord.containsKey(fieldName) ? String.valueOf(csRecord.get(fieldName)) : '';
                    rowValues.add(value);
                }
                csvContent += String.join(rowValues, ',') + '\n';
            }
            
            if (responseMap.containsKey('nextRecordsUrl')) {
                nextRecordsUrl = (String) responseMap.get('nextRecordsUrl');
                System.enqueueJob(this);
            } else {
                saveCSVContent(size);
            }
        }
        
        private void saveCSVContent(Object size) {
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = customSettingName + '(' + size + ')';
            contentVersion.PathOnClient = '/' + contentVersion.Title + '.csv';
            contentVersion.VersionData = Blob.valueOf(csvContent);
            insert contentVersion;
            
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :contentVersion.Id
            ].ContentDocumentId;
            contentDocumentLink.LinkedEntityId = refTempId;
            contentDocumentLink.ShareType = 'V';  // Viewer access
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;
            
            System.debug('CSV export completed: ' + contentVersion.Title);
        }
    }

}