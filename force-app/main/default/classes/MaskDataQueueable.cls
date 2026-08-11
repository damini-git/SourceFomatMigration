public class MaskDataQueueable implements Queueable, Database.AllowsCallouts {
    private List<Map<String, Object>> records;
    private List<String> fieldsToMask;
    private String objectName;
    private String domainUrl;
    private String accessToken;
    private Integer startIndex;
    private Id dataTransformLogId;
    
    public MaskDataQueueable(List<Map<String, Object>> records, List<String> fieldsToMask, String objectName, String domainUrl, String accessToken, Integer startIndex, Id dataTransformLogId) {
        this.records = records;
        this.fieldsToMask = fieldsToMask;
        this.objectName = objectName;
        this.domainUrl = domainUrl;
        this.accessToken = accessToken;
        this.startIndex = startIndex;
        this.dataTransformLogId = dataTransformLogId;
    }
    
    public void execute(QueueableContext context) {
        Integer batchSize = 25; // Composite API limit
        Integer endIndex = Math.min(startIndex + batchSize, records.size());
        
        List<Map<String, Object>> recordsToUpdate = new List<Map<String, Object>>();
        system.debug('Processing records from index ' + startIndex + ' to ' + (endIndex - 1));
        
        for (Integer i = startIndex; i < endIndex; i++) {
            Map<String, Object> record = records[i];
            system.debug('record columns size --- ' + record.keySet().size());
            Map<String, Object> recordMap = new Map<String, Object>();
            recordMap.put('Id', record.get('Id'));
            
            for (String field : fieldsToMask) {
                Object value = record.get(field);
                if (value != null) {
                    recordMap.put(field, generateRandomValue(value));
                }
                else{
                    recordMap.put(field, null);
                }
            }
            recordsToUpdate.add(recordMap);
        }
        
        if (!recordsToUpdate.isEmpty()) {
            sendMaskedDataToOrg2(recordsToUpdate);
        }
        
        if (endIndex < records.size()) { System.enqueueJob(new MaskDataQueueable(records, fieldsToMask, objectName, domainUrl, accessToken, endIndex, dataTransformLogId));
                                       }
    }
    
    private void sendMaskedDataToOrg2(List<Map<String, Object>> maskedRecords) {
        List<Map<String, Object>> recordsList = new List<Map<String, Object>>();
        Integer counter = 1;
        Map<String, Map<String, Object>> recordMap = new Map<String, Map<String, Object>>();
        
        for (Map<String, Object> record : maskedRecords) {
            Map<String, Object> recordBody = new Map<String, Object>(record);
            String recordId = (String) record.get('Id');
            recordBody.remove('Id');
            
            recordsList.add(new Map<String, Object>{
                'method' => 'PATCH',
                    'url' => '/services/data/v60.0/sobjects/' + objectName + '/' + recordId,
                    'referenceId' => 'ref' + counter,  
                    'body' => recordBody
                    });
            
            recordMap.put('ref' + counter, record);
            counter++;
        }
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'allOrNone' => false,
                'compositeRequest' => recordsList
                };
                    system.debug('requestBody --- ' + requestBody);
        
        try{
            HttpRequest request = new HttpRequest();
            request.setEndpoint(domainUrl + '/services/data/v60.0/composite');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setTimeout(120000);
            request.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            List<Map<String, Object>> successRecords = new List<Map<String, Object>>();
            List<Map<String, Object>> failedRecords = new List<Map<String, Object>>();
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                system.debug('responseMap --- ' + responseMap);
                List<Object> compositeResponses = (List<Object>) responseMap.get('compositeResponse');
                system.debug('compositeResponses --- ' + compositeResponses);
                
                for (Object resp : compositeResponses) {
                    Map<String, Object> respMap = (Map<String, Object>) resp;
                    System.debug('Response: ' + JSON.serialize(respMap));
                    String refId = (String) respMap.get('referenceId');
                    Integer statusCode = (Integer) respMap.get('httpStatusCode');
                    
                    Map<String, Object> originalRecord = recordMap.get(refId);
                    system.debug('originalRecord --- ' + originalRecord.keySet().size());
                    if (statusCode >= 200 && statusCode < 300) {
                        successRecords.add(originalRecord);
                    } else {
                        List<Object> errorList = (List<Object>) respMap.get('body');
                        List<Map<String, Object>> errors = new List<Map<String, Object>>();
                        
                        for (Object obj : errorList) {
                            if (obj instanceof Map<String, Object>) {
                                errors.add((Map<String, Object>) obj);
                            }
                        }
                        String errorMessage = errors.isEmpty() ? 'Unknown Error' : (String) errors[0].get('message');
                        originalRecord.put('Failed Reason', errorMessage);
                        failedRecords.add(originalRecord);
                    }
                }
            } else {
                system.debug('Composite call failed. Status Code: ' + response.getStatusCode() + ', Response: ' + response.getBody());
            }
            system.debug('successRecords.size() --- ' + successRecords.size());
            system.debug('failedRecords.size() --- ' + failedRecords.size());
            
            if(successRecords.size() > 0){
                attachCsvToLog(successRecords, objectName + '_SuccessRecords.csv', false);
            }
            if(failedRecords.size() > 0){
                attachCsvToLog(failedRecords, objectName + '_FailedRecords.csv', true);
            }
        }
        catch(Exception e){
            updateLogFailure('Exception in sendMaskedDataToOrg2: ' + e.getMessage());
            System.debug('Exception in sendMaskedDataToOrg2: ' + e.getMessage());
        }
    }
    
    private void updateLogFailure(String errorMessage) {
        try {
            Logs__c log = [SELECT Id, Status__c, Details__c FROM Logs__c WHERE Id = :dataTransformLogId];
            log.Status__c = 'Failed';
            log.Details__c = (log.Details__c == null ? '' : log.Details__c + ' ') + errorMessage;
            update log; } catch(Exception ex) {
                System.debug('Error updating log failure in Queueable: ' + ex.getMessage());
            }
    }
    
    public void attachCsvToLog(List<Map<String, Object>> records, String fileName, Boolean isFailureFile) {
        if (records.isEmpty()) return;
        system.debug('records --- ' + records);
        
        String csvContent = '';
        Set<String> fieldNamesSet = records[0].keySet();
        Set<String> fieldNames = new Set<String>(fieldNamesSet);
        system.debug('field names size --- ' + fieldNames.size());
        
        if (isFailureFile) {
            fieldNames.add('Failed Reason');
        }
        
        csvContent += String.join(fieldNames, ',') + '\n';
        
        for (Map<String, Object> record : records) {
            List<String> row = new List<String>();
            for (String field : fieldNames) {
                Object value = record.get(field);
                String cellValue = (value != null) ? String.valueOf(value) : '';
                
                if (cellValue.contains(',')) {
                    cellValue = '"' + cellValue + '"';
                }
                
                row.add(cellValue);
            }
            csvContent += String.join(row, ',') + '\n';
        }
        
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = Blob.valueOf(csvContent)
            //FirstPublishLocationId = dataTransformLogId
        );
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = dataTransformLogId;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        
        insert contentDocumentLink;
    }
    
    public static Object generateRandomValue(Object originalValue) {
        if (originalValue == null) return null;
        system.debug('originalValue --- ' + originalValue);
        
        if (originalValue instanceof String) {
            system.debug('its a string ---- ');
            if (isValidDate(originalValue) || isValidDateTime(originalValue)) {
                system.debug('inside valid date and datetime condition --- ');
                Integer randomDays = Math.abs(Crypto.getRandomInteger());
                return Date.today().addDays(-Math.mod(randomDays, 365));
            }
            else if (isValidEmail(originalValue)) {
                system.debug('inside valid email condition --- ');
                String randomEmail = 'user' + Math.mod(Math.abs(Crypto.getRandomInteger()), 1000) + '@example.com';
                return randomEmail;
            }
            else if (isValidUrl(originalValue)) {
                system.debug('inside valid url condition --- ');
                String randomUrl = 'https://www.random' + Math.mod(Math.abs(Crypto.getRandomInteger()), 1000) + '.com';
                return randomUrl;
            }
            system.debug('didnt pass any condition above --- ');
            return Math.abs(Crypto.getRandomInteger());
        } else if (originalValue instanceof Integer) {
            system.debug('its an integer ---- ');
            return Math.abs(Crypto.getRandomInteger());
        } else if (originalValue instanceof Decimal) {
            system.debug('its a decimal ---- ');
            return Math.abs(Crypto.getRandomInteger()) * 0.01;
        } else if (originalValue instanceof Boolean) {
            system.debug('its a boolean ---- ');
            return (Crypto.getRandomInteger() & 1) == 0;
        }
        return originalValue;
    }
    
    private static Boolean isValidDate(Object value) {
        Pattern datePattern = Pattern.compile('\\d{4}-\\d{2}-\\d{2}');
        Matcher matcher = datePattern.matcher((String)value);
        if(matcher.matches()){
            return true;
        }
        else{
            return false;
        }
    }
    
    private static Boolean isValidDateTime(Object value){
        Pattern datePattern = Pattern.compile('\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}\\+\\d{4}');
        Matcher matcher = datePattern.matcher((String)value);
        if(matcher.matches()){ return true;
        }
        else{
            return false;
        }
    }
    
    private static Boolean isValidEmail(Object value) {
        String emailRegex = '^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$';
        return Pattern.matches(emailRegex, (String)value);
    }
    
    private static Boolean isValidUrl(Object value) {
        String urlRegex = '^https?://(?:www\\.)?[-a-zA-Z0-9@:%_\\+.~#?&//=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)$';
        return Pattern.matches(urlRegex, (String)value);
    }
}