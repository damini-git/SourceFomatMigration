public class BackupRegenerationOfCustomSettings {
    public static void fetchAllFields(Id sandboxId, Id refTempId, String accessToken, List<String> customSettingNames, Id csRestorationLogId) {
        /*String customSettingsStr = String.join(customSettingNames, ',');
customSettingsStr = customSettingsStr.replaceAll('\\s+', ''); 
customSettingsStr = customSettingsStr.replaceAll('__c\\([^\\)]*\\)', '__c');
customSettingNames = customSettingsStr.split(',');*/
        
        System.debug('Initiating field fetch for custom settings: ' + customSettingNames);
        FetchCustomSettingFieldsQueueable job = new FetchCustomSettingFieldsQueueable(sandboxId, refTempId, customSettingNames, accessToken, 0, csRestorationLogId);
        System.enqueueJob(job);
    }
    
    @future
    public static void initiateFetchCustomSettingsAgain(Id sandboxId, Id refTempId, List<String> customSettingNames, String accessToken, Integer currentIndex, Id csRestorationLogId){
        FetchCustomSettingFieldsQueueable nextJob = new FetchCustomSettingFieldsQueueable(sandboxId, refTempId, customSettingNames, accessToken, currentIndex, csRestorationLogId);
        System.enqueueJob(nextJob);
    }
    
    public class FetchCustomSettingFieldsQueueable implements Queueable, Database.AllowsCallouts {
        private List<String> customSettingNames;
        private Id sandboxId;
        private Id refTempId;
        private String accessToken;
        private Integer currentIndex;
        private Id csRestorationLogId;
        
        
        public FetchCustomSettingFieldsQueueable(Id sandboxId, Id refTempId, List<String> customSettingNames, String accessToken, Integer currentIndex, Id csRestorationLogId) {
            this.sandboxId = sandboxId;
            this.refTempId = refTempId;
            this.customSettingNames = customSettingNames;
            this.accessToken = accessToken;
            this.currentIndex = currentIndex;
            this.csRestorationLogId = csRestorationLogId;
        }
        
        public void execute(QueueableContext context) {
            Logs__c csRestorationLog = [select Id, Status__c, Details__c from Logs__c where Id =: csRestorationLogId];
            
            try {
                Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id =: sandboxId];
                String domainUrl = sand.Domain_Url__c;
                
                if (currentIndex < customSettingNames.size()) {
                    String customSettingName = customSettingNames[currentIndex];
                    System.debug('Processing custom setting: ' + customSettingName);
                    
                    HttpRequest req = new HttpRequest();
                    HttpResponse res;
                    
                    String query; 
                    query= 'SELECT+QualifiedApiName,DataType,Label,Length,Precision,Scale+FROM+FieldDefinition+WHERE+EntityDefinition.QualifiedApiName=\'' + customSettingName + '\'';
                    
                    req.setEndpoint(domainUrl + '/services/data/v57.0/tooling/query/?q=' +query);
                    req.setMethod('GET');
                    req.setHeader('Authorization', 'Bearer ' + accessToken); // Add authorization header
                    req.setTimeout(120000); // Set timeout to 2 minutes
                    system.debug('Endpoint for '+customSettingName+' ----->>>>'+req.getEndpoint());
                    
                    Http http = new Http();
                    res = http.send(req);
                    
                    String body;
                    
                    if(!test.isRunningTest()){ if (res.getStatusCode() == 200) { body = res.getBody();
                                                                               }
                                             }
                    else{ body = '{"size": 60,"totalSize": 60,"done": true,"queryLocator": null,"entityTypeName": "FieldDefinition","records": [{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBkX"},"Label": "Records","QualifiedApiName": "Records__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:44:10.000+0000"},{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBhJ"},"Label": "Read Result","QualifiedApiName": "Read_Result__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:43:49.000+0000"}]}';
                         
                        }
                    
                    system.debug('body for ' + customSettingName + ' to fetch field details --- ' + body);
                    
                    List<String> settingFields = new List<String>();
                    if (!String.isEmpty(body)) {
                        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(body);
                        system.debug('Deserialized body----->>>'+result);
                        List<Object> records = (List<Object>) result.get('records');
                        System.debug('Fields for custom setting: ' + customSettingName + ' - ' + records);
                        
                        for (Object record : records) {
                            Map<String, Object> settingRecord = (Map<String, Object>) record;
                            if (((String) settingRecord.get('QualifiedApiName')).contains('__c') || (String) settingRecord.get('QualifiedApiName') == 'Name') {
                                settingFields.add((String) settingRecord.get('QualifiedApiName'));
                            }
                        }
                    }
                    
                    system.debug('settingFields in FetchAllFieldsQueueable class --- ' + settingFields);
                    calloutToExternalOrg(customSettingName, settingFields, sandboxId, refTempId, accessToken, csRestorationLogId);
                    
                    if (currentIndex + 1 < customSettingNames.size()) { 
                        initiateFetchCustomSettingsAgain(sandboxId, refTempId, customSettingNames, accessToken, currentIndex + 1, csRestorationLogId);
                        //System.enqueueJob(new FetchCustomSettingFieldsQueueable(sandboxId, refTempId, customSettingNames, accessToken, currentIndex + 1, csRestorationLogId));
                        //FetchCustomSettingFieldsQueueable nextJob = new FetchCustomSettingFieldsQueueable(sandboxId, refTempId, customSettingNames, accessToken, currentIndex + 1, csRestorationLogId);
                    }
                    else{
                        system.debug('customSettingNames to regenrate --- ' + customSettingNames);
                        string str ='';
                        for(string cs : customSettingNames){
                            str= str+'AND (NOT ContentDocument.Title LIKE \''+cs+'%\')';
                            
                        }
                        str = '('+str.removeStart('AND')+')';
                        string attachmentsQuery = 'SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = \''+refTempId+'\' AND '+str;
                        system.debug('attachmentsQuery-------->>>>>>'+attachmentsQuery);
                        List<ContentDocumentLink> attachmentsToDelete = new List<ContentDocumentLink>();
                        List<ContentDocumentLink> attachments = database.query(attachmentsQuery);
                        
                        system.debug('attachments Size--->>>>'+attachments.size());
                        
                        for(ContentDocumentLink con : attachments){
                            if(con.ContentDocument.Title.contains('__c')){
                                system.debug('attachments of cs --- ' + con.ContentDocument.Title);
                                String fileName = con.ContentDocument.Title.replaceAll('__c\\([^\\)]*\\)', '__c');
                                if(!customSettingNames.contains(fileName)){
                                    attachmentsToDelete.add(con);
                                }
                            }
                            system.debug('attachmentsToDelete ------>>>>>> ' + attachmentsToDelete);
                        }
                        if(attachmentsToDelete.size() > 0){
                            delete attachmentsToDelete;
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception occurred while processing custom setting fields: ' + e.getMessage());
                csRestorationLog.Status__c = 'Failed';
                csRestorationLog.Details__c = e.getMessage();
                update csRestorationLog;
            }
        }
    }
    
    @future(callout = true)
    public static void calloutToExternalOrg(String customSettingName, List<String> fieldNames, Id sandboxId, Id refTempId, String accessToken, Id csRestorationLogId) {
        System.enqueueJob(new FetchRecordsQueueable(customSettingName, fieldNames, sandboxId, refTempId, accessToken, csRestorationLogId));
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
        private Id csRestorationLogId;
        
        public FetchRecordsQueueable(String customSettingName, List<String> fieldNames, Id sandboxId, Id refTempId, String accessToken, Id csRestorationLogId) {
            this.customSettingName = customSettingName;
            this.fieldNames = fieldNames;
            this.sandboxId = sandboxId;
            this.refTempId = refTempId;
            this.accessToken = accessToken;
            this.csvContent = String.join(fieldNames, ',') + '\n';
            this.domainUrl = [SELECT Domain_Url__c FROM Org__c WHERE Id = :sandboxId].Domain_Url__c;
            this.csRestorationLogId = csRestorationLogId;
        }
        
        public void execute(QueueableContext context) {
            Logs__c csRestorationLog = [select Id, Status__c, Details__c from Logs__c where Id =: csRestorationLogId];
            
            try {
                //String endpoint = String.isNotEmpty(nextRecordsUrl) ? domainUrl + nextRecordsUrl : domainUrl + '/services/data/v58.0/query?q=' + EncodingUtil.urlEncode(getQuery(), 'UTF-8');
                String endpoint = (!test.isRunningTest()) ? (String.isNotEmpty(nextRecordsUrl) ? domainUrl + nextRecordsUrl : domainUrl + '/services/data/v58.0/query?q=' +getQuery()) : domainUrl + '/services/data/v58.0/query?q='+getQuery();
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json');
                req.setTimeout(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                system.debug('Body------>>>>>>'+res.getBody());
                system.debug('Status Code--->>>>'+res.getStatusCode());
                if (res.getStatusCode() == 401) { accessToken = RefreshTokenCallout.fetchAT1(sandboxId); req.setHeader('Authorization', 'Bearer ' + accessToken); res = http.send(req);
                                                }
                
                if (res.getStatusCode() == 200) {
                    processResponse(res.getBody(), csRestorationLogId,refTempId,customSettingName);
                } else {
                    System.debug('Error fetching records: ' + res.getBody());
                    csRestorationLog.Status__c = 'Failed';
                    csRestorationLog.Details__c = res.getBody();
                    update csRestorationLog;
                    return;
                }
            } catch (Exception e) {
                System.debug('Error during callout: ' + e.getMessage());
                csRestorationLog.Status__c = 'Failed';
                csRestorationLog.Details__c = e.getMessage();
                update csRestorationLog;
            }
        }
        
        private String getQuery() {
            return 'SELECT+' +EncodingUtil.urlEncode(String.join(fieldNames, ','), 'UTF-8') + '+FROM+' + customSettingName;
        }
        
        private void processResponse(String responseBody, Id csRestorationLogId,id refTempId,String customSettingName) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> records = (List<Object>) responseMap.get('records');
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
            
            if (responseMap.containsKey('nextRecordsUrl')) { nextRecordsUrl = (String) responseMap.get('nextRecordsUrl'); System.enqueueJob(this);
                                                           } else {
                                                               saveCSVContent(csRestorationLogId, size);
                                                           }
        }
        
        private void saveCSVContent(Id csRestorationLogId, Object size) {
            Logs__c csRestorationLog = [select id, Status__c, Details__c from Logs__c where Id =: csRestorationLogId];
            
            List<ContentDocumentLink> attachmentsToDelete = new List<ContentDocumentLink>();
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :refTempId];
            for(ContentDocumentLink con : attachments){
                String fileName = con.ContentDocument.Title.replaceAll('__c\\([^\\)]*\\)', '__c');
                if(fileName == customSettingName){
                    attachmentsToDelete.add(con);
                }
                system.debug('attachmentsToDelete ------>>>>>> ' + con.ContentDocument.Title);
            }
            if(attachmentsToDelete.size() > 0){
                delete attachmentsToDelete;
            }           
            
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