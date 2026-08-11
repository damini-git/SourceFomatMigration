public with sharing class PreRefreshAutomationClass {
    
    public static MetadataService.MetadataPort createService(String domainUrl, String accessToken) {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        String version = '59.0';
        service.endpoint_x = domainUrl + '/services/Soap/m/' + version;
        service.SessionHeader.sessionId = accessToken;
        service.timeout_x = 120000;
        return service;
    }
    
    public static MetadataService.Package_x parsePackageXml(String packageXmlContent) {
        MetadataService.Package_x unpackaged = new MetadataService.Package_x();
        unpackaged.types = new List<MetadataService.PackageTypeMembers>();
        
        Dom.Document doc = new Dom.Document();
        doc.load(packageXmlContent);
        Dom.XmlNode packageNode = doc.getRootElement();
        
        for (Dom.XmlNode typeNode : packageNode.getChildElements()) {
            if (typeNode.getName() == 'types') {
                MetadataService.PackageTypeMembers packageTypeMember = new MetadataService.PackageTypeMembers();
                packageTypeMember.members = new List<String>();
                
                for (Dom.XmlNode typeChildNode : typeNode.getChildElements()) {
                    if (typeChildNode.getName() == 'name') {
                        packageTypeMember.name = typeChildNode.getText();
                    } else if (typeChildNode.getName() == 'members') {
                        packageTypeMember.members.add(typeChildNode.getText());
                    }
                }
                unpackaged.types.add(packageTypeMember);
            }
        }
        unpackaged.version = '59.0';
        return unpackaged;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Refresh_Template__c> fetchAllRefreshTemplates(){
        return [select Id, Name, Package_xml_Val__c, Parent_Org__c, Source_Refresh_Org__c, Source_Org__c, Target_Refresh_Org__c, Target_Org__c, Last_Run_Status__c, Last_Refreshed_Date__c, Last_Refreshed_By__r.Name, CreatedDate, LastModifiedDate from Refresh_Template__c ORDER BY CreatedDate DESC];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Org__c> fetchAllOrgs(){
        return [select Id, Name from Org__c where Org_Type__c != 'Production' ORDER BY Name ASC];
    }
    
    @AuraEnabled(cacheable=true)
    public static Org__c getTemplateOrgName(Id selectedTemplate){
        Id parentId = [select Id, Name, Parent_Org__c from Refresh_Template__c where Id =: selectedTemplate].Parent_Org__c;
        return [select Id, Name from Org__c where Id =: parentId];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Org__c> fetchSourceOrgsForRefresh(Id templateId){
        Refresh_template__c refTemp = [select Id, Name, Parent_Org__c from Refresh_Template__c where Id =: templateId];
        Org__c org1 = [select Id, Name, Production_Org__c from Org__c where Id =: refTemp.Parent_Org__c limit 1];
        List<Org__c> orgs = [select Id, Name, Production_Org__c from Org__c where Production_Org__c =: org1.Production_Org__c and Id != :refTemp.Parent_Org__c ORDER BY Name ASC];
        orgs.add([select Id, Name from Org__c where Id =: org1.Production_Org__c]);
        return orgs;
    }
    
    @AuraEnabled(cacheable=false)
    public static void deleteRecord(String templateId) {
        try {
            Refresh_Template__c record = [SELECT Id, Name FROM Refresh_Template__c WHERE Id = :templateId LIMIT 1];
            delete record;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting record: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> parseXML(Id selectedTemplate){
        String packageXml = [select Id, Name, Package_Xml_Val__c from Refresh_Template__c where Id =: selectedTemplate].Package_Xml_Val__c;
        system.debug('packageXml --- ' + packageXml);
        Map<String, List<String>> typeMembersMap = new Map<String, List<String>>();
        
        Dom.Document doc = new Dom.Document();
        doc.load(packageXml);
        Dom.XmlNode root = doc.getRootElement();
        
        for (Dom.XmlNode typeNode : root.getChildElements()) {
            String typeName = null;
            List<String> membersList = new List<String>();
            
            for (Dom.XmlNode childNode : typeNode.getChildElements()) {
                if (childNode.getName() == 'name') {
                    typeName = childNode.getText();
                } else if (childNode.getName() == 'members') {
                    membersList.add(childNode.getText());
                }
            }
            
            if (typeName != null) {
                typeMembersMap.put(typeName, membersList);
            }
        }
        system.debug('typeMembersMap --- ' + typeMembersMap);
        return typeMembersMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkOrgAuthenticated(Id orgId) {
        try {
            Org__c orgRecord = [SELECT Id FROM Org__c WHERE Id = :orgId AND Access_Token__c != null AND Refresh_Token__c != null LIMIT 1];
            return true;  
        } catch (Exception e) {
            return false; 
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> fetchAllMetadataTypes(Id sandboxId) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(sandboxId);
        
        List<String> metadataTypeNames = new List<String>();
        
        try {
            MetadataService.MetadataPort service = createService(domainUrl, accessToken);
            
            MetadataService.DescribeMetadataResult result = service.describeMetadata(Double.valueOf(58.0));
            
            if (result != null && result.metadataObjects != null) {
                for (MetadataService.DescribeMetadataObject metadataObject : result.metadataObjects) {
                    metadataTypeNames.add(metadataObject.xmlName);
                }
            }
            //metadataTypeNames.sort();
            
        } catch (Exception ex) {
            System.debug('Error fetching metadata types: ' + ex.getMessage());
        }
        List<String> manualMetadataTypes = new List<String>{
            'AssignmentRule',
                'CustomField',
                'ValidationRule',
                'ListView',
                'SharingReason',
                'BusinessProcess',
                'FieldSet',
                'CompactLayout',
                'WebLink',
                'RecordType',
                'Index',
                'WorkflowAlert',
                'WorkflowTask',
                'WorkflowRule',
                'WorkflowFieldUpdate',
                'WorkflowOutboundMessage',
                'WorkflowSend'
                };
        
        metadataTypeNames.addAll(manualMetadataTypes);
        metadataTypeNames = new List<String>(new Set<String>(metadataTypeNames));
        metadataTypeNames.sort();
        return metadataTypeNames;
    }
    
        
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchAllMetadataComponents(Id sandboxId, String selectedMetadataType) {
        system.debug('selectedMetadataType --- ' + selectedMetadataType);
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(sandboxId);
        
        List<String> metadataComponentNames = new List<String>();
        List<Map<String, String>> metadataComponentNamesMap = new List<Map<String, String>>();
        
        try {
            MetadataService.MetadataPort service = createService(domainUrl, accessToken);
            
            MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
            query.type_x = (selectedMetadataType == 'CustomLabels') ? 'CustomLabel' : selectedMetadataType;
            
            MetadataService.ListMetadataQuery[] queries = new MetadataService.ListMetadataQuery[] { query };
                MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, Double.valueOf(58.0));
            //System.debug('fileProperties ---' + fileProperties);
            
            if (fileProperties != null) {
                for (MetadataService.FileProperties fileProp : fileProperties) {
                    system.debug('namespace prefix --- ' + fileProp.namespacePrefix);
                    system.debug('metadata --- ' + fileProp.fullName + ', lastModifiedBy --- ' + fileProp.lastModifiedByName + ', lastModifiedDate --- ' + fileProp.lastModifiedDate + ', createdBy --- ' + fileProp.createdByName + ', createdDate --- ' + fileProp.createdDate);
                    if (String.isEmpty(fileProp.namespacePrefix)) {
                        metadataComponentNamesMap.add(new Map<String, String>{
                            'value' => fileProp.fullName,
                                'type' => selectedMetadataType,
                                'lastModifiedBy' => fileProp.lastModifiedByName != null ? fileProp.lastModifiedByName : 'N/A',
                                    'lastModifiedDate' => fileProp.lastModifiedDate != null ? String.valueOf(fileProp.lastModifiedDate) : 'N/A',
                                        'createdBy' => fileProp.createdByName != null ? fileProp.createdByName : 'N/A',
                                            'createdDate' => fileProp.createdDate != null ? String.valueOf(fileProp.createdDate) : 'N/A'
                                                });
                    }
                }
                // Extract the 'value' field from each map and sort the keys.
                /*List<String> sortedKeys = new List<String>();
                for (Map<String, String> compMap : metadataComponentNamesMap) {
                    sortedKeys.add(compMap.get('value'));
                }
                sortedKeys.sort();
                
                // Rebuild the sorted list.
                List<Map<String, String>> sortedMetadataComponents = new List<Map<String, String>>();
                for (String key : sortedKeys) {
                    for (Map<String, String> compMap : metadataComponentNamesMap) {
                        if (compMap.get('value') == key) {
                            sortedMetadataComponents.add(compMap);
                            break;
                        }
                    }
                }
                metadataComponentNamesMap = sortedMetadataComponents;*/
            }
        } catch (Exception ex) {
            System.debug('Error fetching metadata components: ' + ex.getMessage());
        }
        
        return metadataComponentNamesMap;
    }
    
    @AuraEnabled
    public static List<String> fetchAllCustomObjects(Id sandboxId) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(sandboxId);
        
        List<String> customObjectNames = new List<String>();
        
        try {
            MetadataService.MetadataPort service = createService(domainUrl, accessToken);
            
            MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
            query.type_x = 'CustomObject';
            
            MetadataService.ListMetadataQuery[] queries = new MetadataService.ListMetadataQuery[] { query };
                
                MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, Double.valueOf(55.0));
            
            if (fileProperties != null) {
                for (MetadataService.FileProperties fileProp : fileProperties) {
                    system.debug('object names --- ' + fileProp.fullName);
                    customObjectNames.add(fileProp.fullName);
                }
            }
            
            customObjectNames.sort();
            
        } catch (Exception ex) {
            System.debug('Error fetching custom objects: ' + ex.getMessage());
        }
        
        return customObjectNames;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchFieldsOfObject(Id sandboxId, String objectName) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(sandboxId);
        
        List<String> fieldNames = new List<String>();
        List<Map<String, String>> fieldNamesMap = new List<Map<String, String>>();
        
        try {
            MetadataService.MetadataPort service = createService(domainUrl, accessToken);
            
            MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
            query.type_x = 'CustomField';
            query.folder = objectName;
            
            MetadataService.ListMetadataQuery[] queries = new MetadataService.ListMetadataQuery[] { query };
                
                MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, Double.valueOf(55.0));
            
            if (fileProperties != null) {
                system.debug('number of fields --- ' + fileProperties.size());
                for (MetadataService.FileProperties fileProp : fileProperties) {
                    system.debug('field names --- ' + fileProp.fullName);
                    fieldNames.add(fileProp.fullName);
                }
            }
            
            fieldNames.sort();
            
            for (String value : fieldNames) {
                fieldNamesMap.add(new Map<String, String>{'value' => value});
            }
            
        } catch (Exception ex) {
            System.debug('Error fetching fields: ' + ex.getMessage());
        }
        
        return fieldNamesMap;
    }
    
    /*@AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchFieldsOfObject1(Id sandboxId, String objectName) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(sandboxId);
        
        String endpointUrl = domainUrl + '/services/data/v57.0/tooling/query/?q=SELECT+Label,QualifiedApiName,DataType,Length,LastModifiedBy.Name,LastModifiedDate+FROM+FieldDefinition+WHERE+EntityDefinition.QualifiedApiName=\'' + objectName + '\'+AND+EntityDefinition.IsEverUpdatable=true';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        
        system.debug('endpoint --- ' + req.getEndPoint());
        
        Http http = new Http();
        HttpResponse res;
        
        try {
            res = http.send(req);
            system.debug('response --------- ' + res);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                system.debug('responseMap --- ' + responseMap);
                
                List<Map<String, String>> fieldsList = new List<Map<String, String>>();
                List<Object> fields = (List<Object>) responseMap.get('records');
                System.debug('fields --- ' + fields);
                
                for (Object field : fields) {
                    Map<String, Object> fieldMap = (Map<String, Object>) field;
                    
                    String label = (String) fieldMap.get('Label');
                    String apiName = (String) fieldMap.get('QualifiedApiName');
                    String dataType = (String) fieldMap.get('DataType');
                    
                    String lastModifiedDate = '';
                    String lastModifiedBy = '';
                    String description = '';
                    
                    if (fieldMap.containsKey('LastModifiedDate') && fieldMap.get('LastModifiedDate') != null) {
                        lastModifiedDate = String.valueOf(fieldMap.get('LastModifiedDate'));
                    }
                    
                    if (fieldMap.containsKey('Description') && fieldMap.get('Description') != null) {
                        description = (String) fieldMap.get('Description');
                    }
                    
                    if (fieldMap.containsKey('LastModifiedBy') && fieldMap.get('LastModifiedBy') != null) {
                        Map<String, Object> lastModified = (Map<String, Object>) fieldMap.get('LastModifiedBy');
                        if (lastModified.containsKey('Name') && lastModified.get('Name') != null) {
                            lastModifiedBy = (String) lastModified.get('Name');
                        }
                    }
                    
                    Map<String, String> fieldDetails = new Map<String, String>();
                    fieldDetails.put('label', label);
                    fieldDetails.put('apiName', apiName);
                    fieldDetails.put('dataType', dataType);
                    fieldDetails.put('lastModifiedDate', lastModifiedDate);
                    fieldDetails.put('lastModifiedBy', lastModifiedBy);
                    fieldDetails.put('description', description);
                    
                    fieldsList.add(fieldDetails);
                }
                system.debug('fieldsList --- ' + fieldsList);
                
                return fieldsList;
            } else {
                System.debug('Error: ' + res.getStatus() + ' - ' + res.getBody());
                return new List<Map<String, String>>();
            }
        } catch (Exception e) {
            System.debug('Error during callout: ' + e.getMessage());
            return new List<Map<String, String>>();
        }
    }*/
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchFieldsOfObject1(Id sandboxId, String objectName) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(sandboxId);
        
        String endpointUrl = domainUrl + '/services/data/v60.0/sobjects/' + objectName + '/describe';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setTimeout(120000);
        
        system.debug('endpoint --- ' + req.getEndPoint());
        
        Http http = new Http();
        HttpResponse res;
        
        try {
            res = http.send(req);
            system.debug('response --------- ' + res);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                system.debug('responseMap --- ' + responseMap);
                
                List<Map<String, String>> fieldsList = new List<Map<String, String>>();
                List<Object> fields = (List<Object>) responseMap.get('fields');
                System.debug('fields --- ' + fields);
                system.debug('number of fields --- ' + fields.size());
                
                for (Object field : fields) {
                    Map<String, Object> fieldMap = (Map<String, Object>) field;
                    Map<String, String> fieldDetails = new Map<String, String>();
                    
                    String label;
                    String apiName;
                    String dataType;
                    
                    if((boolean) fieldMap.get('updateable')){
                        label = (String) fieldMap.get('label');
                        apiName = (String) fieldMap.get('name');
                        dataType = (String) fieldMap.get('type');
                        system.debug('Label: --- ' + label + '  --- Api Name: --- ' + apiName + '  --- DataType: --- ' + dataType);
                        fieldDetails.put('label', label);
                        fieldDetails.put('apiName', apiName);
                        fieldDetails.put('dataType', dataType);
                        fieldsList.add(fieldDetails);
                    }
                }
                system.debug('fieldsList --- ' + fieldsList);
                return fieldsList;
            } else {
                System.debug('Error: ' + res.getStatus() + ' - ' + res.getBody());
                return new List<Map<String, String>>();
            }
        } catch (Exception e) {
            System.debug('Error during callout: ' + e.getMessage());
            return new List<Map<String, String>>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Id fetchParentOrgOfRefreshTemplate(Id templateId){
        return [select Id, Name, Parent_Org__c from Refresh_Template__c where Id =: templateId].Parent_Org__c;
    }
    
    public void fetchAllFields(Id sandboxId, Id refTempId, String accessToken, List<String> customSettingNames, Id customSettingRetrieveLogId) {
        System.debug('Initiating field fetch for custom settings: ' + customSettingNames);
        FetchCustomSettingFieldsQueueable job = new FetchCustomSettingFieldsQueueable(sandboxId, refTempId, customSettingNames, accessToken, 0, customSettingRetrieveLogId);
        System.enqueueJob(job);
    }
    
    @future
    public static void initiateFetchCustomSettingsAgain(Id sandboxId, Id refTempId, List<String> customSettingNames, String accessToken, Integer currentIndex, Id customSettingRetrieveLogId){
        FetchCustomSettingFieldsQueueable nextJob = new FetchCustomSettingFieldsQueueable(sandboxId, refTempId, customSettingNames, accessToken, currentIndex, customSettingRetrieveLogId);
        System.enqueueJob(nextJob);
    }
    
    public class FetchCustomSettingFieldsQueueable implements Queueable, Database.AllowsCallouts {
        private List<String> customSettingNames;
        private Id sandboxId;
        private Id refTempId;
        private String accessToken;
        private Integer currentIndex;
        private Id customSettingRetrieveLogId;
        
        public FetchCustomSettingFieldsQueueable(Id sandboxId, Id refTempId, List<String> customSettingNames, String accessToken, Integer currentIndex, Id customSettingRetrieveLogId) {
            this.sandboxId = sandboxId;
            this.refTempId = refTempId;
            this.customSettingNames = customSettingNames;
            this.accessToken = accessToken;
            this.currentIndex = currentIndex;
            this.customSettingRetrieveLogId = customSettingRetrieveLogId;
        }
        
        public void execute(QueueableContext context) {
            Logs__c customSettingRetrieveLog = [select Id, Status__c, Details__c from Logs__c where Id =: customSettingRetrieveLogId];
            
            try {
                Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id =: sandboxId];
                String domainUrl = sand.Domain_Url__c;
                //String accessToken = sand.Access_Token__c;
                
                if (currentIndex < customSettingNames.size()) {
                    String customSettingName = customSettingNames[currentIndex];
                    System.debug('Processing custom setting: ' + customSettingName);
                    
                    HttpRequest req = new HttpRequest();
                    HttpResponse res;
                    
                    String query = 'SELECT QualifiedApiName, DataType, Label, Length, Precision, Scale ' +
                        'FROM FieldDefinition ' +
                        'WHERE EntityDefinition.QualifiedApiName=\'' + customSettingName + '\'';
                    
                    req.setEndpoint(domainUrl + '/services/data/v57.0/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
                    req.setMethod('GET');
                    req.setHeader('Authorization', 'Bearer ' + accessToken); // Add authorization header
                    req.setTimeout(120000); // Set timeout to 2 minutes
                    
                    Http http = new Http();
                    res = http.send(req);
                    
                    String body;
                    
                    if(!test.isRunningTest()){ if (res.getStatusCode() == 200) { body = res.getBody();
                        }
                    }
                    else{ body = '{"size":12,"totalSize":12,"done":true,"queryLocator":null,"entityTypeName":"FieldDefinition","records":[{"attributes":{"type":"FieldDefinition","url":"/services/data/v57.0/tooling/sobjects/FieldDefinition/01INS000000gURV.Id"},"QualifiedApiName":"Id","DataType":"Lookup()","Label":"Record ID”}]}';
                    }
                    
                    List<String> settingFields = new List<String>();
                    if (!String.isEmpty(body)) {
                        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        List<Object> records = (List<Object>) result.get('records');
                        System.debug('Fields for custom setting: ' + customSettingName + ' - ' + records);
                        
                        for (Object record : records) {
                            Map<String, Object> settingRecord = (Map<String, Object>) record;
                            if (((String) settingRecord.get('QualifiedApiName')).contains('__c') || (String) settingRecord.get('QualifiedApiName') == 'Name') {
                                settingFields.add((String) settingRecord.get('QualifiedApiName'));
                            }
                        }
                    }
                    
                    ExportCustomSettingToCSVQueueable.calloutToExternalOrg(customSettingName, settingFields, sandboxId, refTempId, accessToken, customSettingRetrieveLogId);
                    
                    if (currentIndex + 1 < customSettingNames.size()) {
                        initiateFetchCustomSettingsAgain(sandboxId, refTempId, customSettingNames, accessToken, currentIndex + 1, customSettingRetrieveLogId);
                        //FetchCustomSettingFieldsQueueable nextJob = new FetchCustomSettingFieldsQueueable(sandboxId, refTempId, customSettingNames, accessToken, currentIndex + 1, customSettingRetrieveLogId);
                        //System.enqueueJob(nextJob);
                    }
                }
            } catch (Exception e) {
                customSettingRetrieveLog.Status__c = 'Failed';
                customSettingRetrieveLog.Details__c = e.getMessage();
                update customSettingRetrieveLog;
                System.debug('Exception occurred while processing custom setting fields: ' + e.getMessage());
            }
        }
    }
    
    @AuraEnabled
    public static void checkCustomSettingRetrieveStatus(Id refTempId){
        system.debug('inside custom setting retrieval status to check whether all custom settings are attached ------ ' + refTempId);
        List<Logs__c> customSettingRetrieveLog = new List<Logs__c> ();
        List<Logs__c> customSettingRetrieveLog2 = new List<Logs__c> ();
        List<Logs__c> customSettingRetrieveLog3 = new List<Logs__c> ();
        
        customSettingRetrieveLog = [select Id, Name, Status__c, Details__c, Parent_Template__c from Logs__c where Parent_Template__c =: refTempId and Log_Type__c = 'Custom Settings Retrieve - Template Creation' Order By CreatedDate Desc limit 1];
        customSettingRetrieveLog2 = [select Id, Name, Status__c, Details__c, Parent_Template__c from Logs__c where Parent_Template__c =: refTempId and Log_Type__c = 'Custom Settings - Backup Regeneration' Order By CreatedDate Desc limit 1];
        customSettingRetrieveLog3 = [select Id, Name, Status__c, Details__c, Parent_Template__c from Logs__c where Parent_Template__c =: refTempId and Log_Type__c = 'Custom Settings Retrieve - Update Template' Order By CreatedDate Desc limit 1];
        
        Refresh_Template__c refTemp = [select Id, Custom_Setting_Names__c, Is_Metadata_Selected__c from Refresh_template__c where Id =: refTempId];
        Integer count = 0;
        
        List<String> valuesList = new List<String>();
        if(refTemp.Custom_Setting_Names__c != null){
            string csNames = refTemp.Custom_Setting_Names__c.deleteWhiteSpace();
            valuesList = csNames.split(',');
        }
        
        List<String> customSettingsAttached = new List<String>();
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :refTempId
        ];
        
        for (ContentDocumentLink link : contentDocumentLinks) {
            system.debug('link.ContentDocument.Title before removing count --- ');
            String fileName = link.ContentDocument.Title.replaceAll('__c\\([^\\)]*\\)', '__c');
            system.debug('fileName after removing count --- ' + fileName);
            customSettingsAttached.add(fileName);
        }
        
        system.debug('valuesList --- ' + valuesList + ' --- size of valuesList --- ' + valuesList.size());
        system.debug('customSettingsAttached --- ' + customSettingsAttached + ' --- customSettingsAttached size --- ' + customSettingsAttached.size());
        
        Set<String> setB = new Set<String>(customSettingsAttached);
        Boolean allPresent = true;
        
        for (String item : valuesList) {
            if (!setB.contains(item)) { allPresent = false; break;
            }
        }
        if(customSettingRetrieveLog.size() > 0){
        if(customSettingRetrieveLog[0].Status__c == 'InProgress'){
            system.debug('log is inprogress for --- ' + customSettingRetrieveLog[0].Name);
            if(allPresent){
                system.debug('checking if all custom settings are present...');
                customSettingRetrieveLog[0].Status__c = 'Success';
                update customSettingRetrieveLog[0];
            }
        }
        }
        if(customSettingRetrieveLog2.size() > 0){
            if(customSettingRetrieveLog2[0].Status__c == 'InProgress'){
                system.debug('log is inprogress for --- ' + customSettingRetrieveLog2[0].Name);
                if(allPresent){
                    system.debug('checking if all custom settings are present...');
                    customSettingRetrieveLog2[0].Status__c = 'Success';
                    update customSettingRetrieveLog2;
                }
            }
        }
        if(customSettingRetrieveLog3.size() > 0){
            if(customSettingRetrieveLog3[0].Status__c == 'InProgress'){
                system.debug('log is inprogress for --- ' + customSettingRetrieveLog3[0].Name);
                if(allPresent){
                    system.debug('checking if all custom settings are present...');
                    customSettingRetrieveLog3[0].Status__c = 'Success';
                    update customSettingRetrieveLog3;
                }
            }
        }
    }
    
    
    /*public void generateCsvForScheduledJobs(Org__c sand, Id refTempId, String sJobs){
        system.debug('sJobs --- ' + sJobs);
        
        List<Object> parsedData = (List<Object>) JSON.deserializeUntyped(sJobs);
        List<String> cronJobDetailsIds = new List<String>();
        
        String csvContent = 'Job Name,Job Type,State,Timezone,CronJobDetailId\n'; //Cron Expression,
        
        for (Object obj : parsedData) {
            Map<String, Object> data = (Map<String, Object>) obj;
            String formattedString = (String) data.get('formattedString');
            system.debug('job records --- ' + formattedString);
            
            /*Pattern cronJobIdPattern = Pattern.compile('CronJobDetailId: (\\w+)');
            Matcher matcher = cronJobIdPattern.matcher(formattedString);
            
            if (matcher.find()) {
                String cronJobDetailId = matcher.group(1);
                System.debug('CronJobDetailId: --- ' + cronJobDetailId);
                cronJobDetailsIds.add(cronJobDetailId);
            } else {
                System.debug('CronJobDetailId not found');
            }*/
            
            /*List<String> fields = new List<String>();
            
            for (String field : formattedString.split(',')) {
                fields.add(field.split(':')[1].trim());
            }
            
            csvContent += String.join(fields, ',') + '\n';
            system.debug('csvContent --- ' + csvContent);
        }
        
        insertCsvAsAttachmentForSJobs(sand.Id, refTempId, csvContent);
    }
    
    private static void insertCsvAsAttachmentForSJobs(Id sandboxId, Id refTempId, String csvContent) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Scheduled Jobs';
        contentVersion.PathOnClient = 'Scheduled Jobs.csv';
        contentVersion.VersionData = Blob.valueOf(csvContent);
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = refTempId;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        
        insert contentDocumentLink;
    }*/
    
    /*@AuraEnabled(cacheable=true)
    public static boolean checkDataRetrievalStatus(Id templateId){
        Refresh_Template__c refTemp = [select Id, Custom_Setting_Names__c, Is_Metadata_Selected__c from Refresh_template__c where Id =: templateId];
        Integer count = 0;
        
        List<String> valuesList = new List<String>();
        if(refTemp.Custom_Setting_Names__c != null){
            valuesList = refTemp.Custom_Setting_Names__c.split(', ');
            //system.debug('valuesList size --- ' + valuesList.size());
        }
        //List<String> valuesList = refTemp.Custom_Setting_Names__c.split(', ');
        
        List<Attachment> metadataZip = new List<Attachment>();
        if(refTemp.Is_Metadata_Selected__c){
            metadataZip = [select Id, Name, ParentId from Attachment where ParentId =: templateId];
            system.debug('metadataZip size --------- ' + metadataZip.size());
            system.debug('metadataZip name --------- ' + metadataZip[0].Name);
        }
        
        
        List<AttachedFileInfo> attachedFiles = new List<AttachedFileInfo>();
        List<String> customSettingsAttached = new List<String>();
        
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :templateId
        ];
        
        for (ContentDocumentLink link : contentDocumentLinks) {
            AttachedFileInfo fileInfo = new AttachedFileInfo();
            fileInfo.fileName = link.ContentDocument.Title;
            fileInfo.fileType = link.ContentDocument.FileType;
            customSettingsAttached.add(fileInfo.fileName);
            attachedFiles.add(fileInfo);
        }
        
        system.debug('valuesList --- ' + valuesList);
        system.debug('customSettingsAttached --- ' + customSettingsAttached);
        
        Set<String> setB = new Set<String>(customSettingsAttached);
        Boolean allPresent = true;
        
        for (String item : valuesList) {
            if (!setB.contains(item)) {
                allPresent = false;
                break;
            }
        }
        
        system.debug('refTemp.Is_Metadata_Selected__c --- ' + refTemp.Is_Metadata_Selected__c);
        if(refTemp.Is_Metadata_Selected__c){
            if(metadataZip.size() > 0){
                allPresent = true;
            }
            else{
                allPresent = false;
            }
        }
        
        system.debug('allPresent --- ' + allPresent);
        return allPresent;
    }*/
    
    public class AttachedFileInfo {
        public String fileName { get; set; }
        public String fileType { get; set; }
    }
    
	@AuraEnabled
    public static void createNewTemplate(Id parentOrgId, String templateName, String metadataPackageXmlContent, List<String> selectedUsernames, List<String> customSettingNames, String sJobs, String findAndReplaceTemplate, String jsonData, string csvString){
        Org__c org = [select Id, Name, Domain_Url__c, Access_Token__c from Org__c where Id =: parentOrgId];
        String domainUrl = org.Domain_Url__c;
        String accessToken = Test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(org.Id);
        
        Refresh_Template__c refTemp = new Refresh_Template__c();
        refTemp.Name = templateName;
        refTemp.Parent_Org__c = parentOrgId;
        refTemp.Target_Refresh_Org__c = org.Name;
        refTemp.Target_Org__c = org.Id;
        system.debug('metadataPackageXmlContent before creating template --- ' + metadataPackageXmlContent);
        if(!String.isEmpty(metadataPackageXmlContent)){
            refTemp.Is_Metadata_Selected__c  = true;
        }
        if(selectedUsernames.size() > 0){
            refTemp.Is_User_Data_Selected__c  = true;
        }
        if(sJobs != '[]'){
        //if(sJobs != null && !String.isBlank(sJobs.trim()) && sJobs != '{}'){
            refTemp.Is_Scheduled_Jobs_Selected__c   = true;
        }
        if(findAndReplaceTemplate != '[]'){
            refTemp.Is_Find_And_Replace_Rules_Selected__c = true;
        }
        
        String namesOfAllCustomSettings = '';
        
        for(String cc : customSettingNames){
            namesOfAllCustomSettings += cc + ', ';
        }
        if (namesOfAllCustomSettings.endsWith(', ')) {
            namesOfAllCustomSettings = namesOfAllCustomSettings.substring(0, namesOfAllCustomSettings.length() - 2);
        }
        refTemp.Custom_Setting_Names__c = namesOfAllCustomSettings;
        insert refTemp;
        system.debug('refTemp created --- ' + refTemp.Id);
        
        
        List<String> conditions = new List<String>();
        if(!String.isEmpty(metadataPackageXmlContent)){
            conditions.add('case1');
        }
        if(selectedUsernames.size() > 0){
            conditions.add('case2');
        }
        if(customSettingNames.size() > 0){
            conditions.add('case3');
        }
        if(sJobs != '[]'){
        //if(sJobs != null && !String.isBlank(sJobs.trim()) && sJobs != '{}'){
            conditions.add('case4');
        }
        system.debug('findAndReplaceTemplate --- ' + findAndReplaceTemplate);
        if(findAndReplaceTemplate != '[]'){
            conditions.add('case5');
        }
        if(!string.isBlank(jsonData) && !string.isBlank(csvString)){
            conditions.add('case6');
        }
        
        PreRefreshAutomationClass outerClass = new PreRefreshAutomationClass();
        for(String condition : conditions){
            switch on condition {
                when 'case1' {
                    Logs__c metadataRetrieveLog = new Logs__c();
                    metadataRetrieveLog.Log_type__c = 'Metadata Retrieve - Template Creation';
                    metadataRetrieveLog.Status__c = 'InProgress';
                    metadataRetrieveLog.Parent_Template__c = refTemp.Id;
                    insert metadataRetrieveLog;
                    system.debug('metadata retrieve log created --- ' + metadataRetrieveLog.Id);
                    
                    system.debug('Case 1: calling metdata retrieval job  ---------- ');
                    retrievePackage(parentOrgId, refTemp.Id, domainUrl, accessToken, metadataPackageXmlContent, metadataRetrieveLog.Id); //, selectedUsernames, customSettingNames, sJobs
                }
                
                when 'case2' {
                    Logs__c userDataRetrieveLog = new Logs__c();
                    userDataRetrieveLog.Log_type__c = 'User Retrieve - Template Creation';
                    userDataRetrieveLog.Status__c = 'InProgress';
                    userDataRetrieveLog.Parent_Template__c = refTemp.Id;
                    insert userDataRetrieveLog;
                    system.debug('user data retrieve log created --- ' + userDataRetrieveLog.Id);
                    
                    system.debug('Case 2: calling user retrieval job  ---------- ');
                    system.debug('selectedUsernames size --- ' + selectedUsernames.size());
                    if(!test.isRunningTest()){PreRefreshUserBackup.getAllUsersWithProfilesAndRoles(refTemp.Id, selectedUsernames, accessToken, userDataRetrieveLog.Id);}
                }
                
                when 'case3' {
                    Logs__c customSettingRetrieveLog = new Logs__c();
                    customSettingRetrieveLog.Log_type__c = 'Custom Settings Retrieve - Template Creation';
                    customSettingRetrieveLog.Status__c = 'InProgress';
                    customSettingRetrieveLog.Parent_Template__c = refTemp.Id;
                    insert customSettingRetrieveLog;
                    system.debug('custom settings data retrieve log created --- ' + customSettingRetrieveLog.Id);
                    
                    system.debug('Case 3: calling custom settings retrieval job  ---------- ');
                    system.debug('inside customSettingNames --- ' + customSettingNames);
                    outerClass.fetchAllFields(parentOrgId, refTemp.Id, accessToken, customSettingNames, customSettingRetrieveLog.Id);
                }
                
                when 'case4' {
                    Logs__c sJobsRetrieveLog = new Logs__c();
                    sJobsRetrieveLog.Log_type__c = 'Scheduled Jobs Retrieve - Template Creation';
                    sJobsRetrieveLog.Status__c = 'InProgress';
                    sJobsRetrieveLog.Parent_Template__c = refTemp.Id;
                    insert sJobsRetrieveLog;
                    system.debug('custom settings data retrieve log created --- ' + sJobsRetrieveLog.Id);
                    
                    system.debug('Case 4: calling scheduled jobs retrieval job  ---------- ');
                    system.debug('inside sJobs --- ' + sJobs);
                    outerClass.generateCsvForScheduledJobsNew(refTemp.Id, sJobs, sJobsRetrieveLog.Id);
                }
                
                when 'case5' {
                    system.debug('Case 5: calling metadata transformation rules creation job  ---------- ');
                    system.debug('inside findAndReplaceTemplate --- ' + findAndReplaceTemplate);
                    createMetadataTransRulesCSV(refTemp.Id, findAndReplaceTemplate);
                }
                
                when 'case6' {
                    Logs__c scriptLog = new Logs__c();
                    scriptLog.Log_Type__c = 'Apex Script Template Creation';
                    scriptLog.Status__c = 'InProgress';
                    scriptLog.Parent_Template__c = refTemp.Id;
                    insert scriptLog;
                    
                    system.debug('Case 6: calling script Template creation job  ---------- ');
                    system.debug('inside Script Template creation --- ' + csvString);
                    CreateScriptTemplate.scriptData(refTemp.Id, scriptLog.Id, jsonData, csvString);
                }
            }
        }
    }
    
    @future(callout=true)
    public static void retrievePackage(Id parentOrgId, Id refTempId, String domainUrl, String accessToken, String metadataPackageXmlContent, Id metadataRetrieveLogId){ //, List<String> selectedUsernames, List<String> customSettingNames, String sJobs
        system.debug('metadataPackageXmlContent --- ' + metadataPackageXmlContent);
        Logs__c metadataRetrieveLog = [select Id, Status__c, Details__c from Logs__c where Id =: metadataRetrieveLogId];
        
        try{
            MetadataService.MetadataPort service = createService(domainUrl, accessToken);
            MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
            retrieveRequest.apiVersion = 59.0;
            retrieveRequest.singlePackage = true;
            retrieveRequest.unpackaged = parsePackageXml(metadataPackageXmlContent);
            
            MetadataService.AsyncResult asyncResult = service.retrieve(retrieveRequest);
            
            String asyncResultId = asyncResult.id;
            system.debug('asyncResultId --- ' + asyncResultId);
            String queueJobId = System.enqueueJob(new InitialMetadataRetrievalJobNew(asyncResultId, parentOrgId, refTempId, domainUrl, accessToken, metadataPackageXmlContent, metadataRetrieveLogId)); //, selectedUsernames, customSettingNames, sJobs
            system.debug('queueJobId --- ' + queueJobId);
        } catch (Exception e) {
            metadataRetrieveLog.Status__c = 'Failed';
            metadataRetrieveLog.Details__c = e.getMessage();
            update metadataRetrieveLog;
            System.debug('Error retrieving and storing metadata: ' + e.getMessage());
        }
    }
    
    @future(callout=true)
    public static void initiateMetadataRetrievalAgain(String asyncResultId, Id sandboxId, Id refTempId, String domainUrl, String accessToken, String metadataPackageXmlContent, Id metadataRetrieveLogId){
        system.debug('initiating the metadata check retrieve status again --- ');
        System.enqueueJob(new InitialMetadataRetrievalJobNew(asyncResultId, sandboxId, refTempId, domainUrl, accessToken, metadataPackageXmlContent, metadataRetrieveLogId));
    }
    
    public class InitialMetadataRetrievalJobNew implements Queueable, Database.AllowsCallouts {
        private String asyncResultId;
        private Id sandboxId;
        private Id refTempId;
        private String domainUrl;
        private String accessToken;
        private String metadataPackageXmlContent;
        private Id metadataRetrieveLogId;
        //private List<String> selectedUsernames;
        //private List<String> customSettingNames;
        //private String sJobs;
        
        public InitialMetadataRetrievalJobNew(String asyncResultId, Id sandboxId, Id refTempId, String domainUrl, String accessToken, String metadataPackageXmlContent, Id metadataRetrieveLogId) { //, List<String> selectedUsernames, List<String> customSettingNames, String sJobs
            this.asyncResultId = asyncResultId;
            this.sandboxId = sandboxId;
            this.refTempId = refTempId;
            this.domainUrl = domainUrl;
            this.accessToken = accessToken;
            this.metadataPackageXmlContent = metadataPackageXmlContent;
            this.metadataRetrieveLogId = metadataRetrieveLogId;
            //this.selectedUsernames = selectedUsernames;
            //this.customSettingNames = customSettingNames;
            //this.sJobs = sJobs;
        }
        
        public void execute(QueueableContext context) {
            Logs__c metadataRetrieveLog = [select Id, Status__c, Details__c from Logs__c where Id =: metadataRetrieveLogId];
            
            try {
                system.debug('asyncResultId --- ' + asyncResultId);
                PreRefreshAutomationClass outerClass = new PreRefreshAutomationClass();
                boolean isMetadataRetrieveDone = false;
                
                if(!String.isEmpty(asyncResultId)){
                    MetadataService.MetadataPort service = createService(domainUrl, accessToken);
                    MetadataService.RetrieveResult retrieveResult = service.checkRetrieveStatus(asyncResultId, false);
                    system.debug('retrieveResult.done --- ' + retrieveResult.done);
                    //retrieveResult = makeRetrieveResultCallout(service, retrieveResult, asyncResultId, refTempId, domainUrl, accessToken);
                    
                    if(!retrieveResult.done){
                        initiateMetadataRetrievalAgain(asyncResultId, sandboxId, refTempId, domainUrl, accessToken, metadataPackageXmlContent, metadataRetrieveLogId);
                        //System.enqueueJob(new InitialMetadataRetrievalJobNew(asyncResultId, sandboxId, refTempId, domainUrl, accessToken, metadataPackageXmlContent, metadataRetrieveLogId)); //, selectedUsernames, customSettingNames, sJobs
                    }
                    
                    if(retrieveResult.done){
                        retrieveResult = service.checkRetrieveStatus(asyncResultId, true);
                        if (retrieveResult == null || retrieveResult.zipFile == null) {
                            system.debug('RetrieveResult or zipFile is null');
                            return;
                        }
                        isMetadataRetrieveDone = true;
                        outerClass.handleRetrievedMetadataNew(refTempId, retrieveResult, metadataPackageXmlContent, metadataRetrieveLogId);
                    }
                }
            } catch (Exception e) {
                metadataRetrieveLog.Status__c = 'Failed';
                metadataRetrieveLog.Details__c = e.getMessage();
                update metadataRetrieveLog;
                System.debug('Error in MetadataCompletionJob: ' + e.getMessage());
            }
        }
    }
    
    public static MetadataService.RetrieveResult makeRetrieveResultCallout(MetadataService.MetadataPort service, MetadataService.RetrieveResult retrieveResult, String asyncResultId, Id refTempId, String domainUrl, String accessToken){
        Boolean isMetadataRetrieveDone = false;
        
        Integer loopCount = 0;
        do {
            if(!test.isRunningTest()){retrieveResult = service.checkRetrieveStatus(asyncResultId, false);}
            system.debug('Retrieve Status: ' + retrieveResult.status);
            loopCount ++;
            
            if(loopCount == 98){
                system.debug('loopCount --- ' + loopCount);
                isMetadataRetrieveDone = false;
                break;
            }
            else{
                isMetadataRetrieveDone = true;
            }
        } while (!retrieveResult.done);
        
        return retrieveResult;
    }
    
    public void handleRetrievedMetadataNew(Id refTempId, MetadataService.RetrieveResult retrieveResult, String metadataPackageXmlContent, Id metadataRetrieveLogId) {
        system.debug('retrieveResult --- ' + retrieveResult.zipFile);
        Logs__c metadataRetrieveLog = [select Id, Status__c, Details__c from Logs__c where Id =: metadataRetrieveLogId];
        metadataRetrieveLog.Status__c = 'Success';
        update metadataRetrieveLog;
        
        Blob zipBlob = EncodingUtil.base64Decode(retrieveResult.zipFile);
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'packageXml.txt';
        contentVersion.PathOnClient = 'packageXml.txt';
        contentVersion.VersionData = Blob.valueOf(metadataPackageXmlContent);
        //contentVersion.FirstPublishLocationId = refTempId;
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = refTempId;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink;
        
        system.debug('Package Xml text file created with ID: ' + contentVersion.Id);
        
        Attachment attachment = new Attachment();
        attachment.ParentId = refTempId;
        attachment.Name = 'Metadata.zip';
        attachment.Body = zipBlob;
        attachment.ContentType = 'application/zip';
        insert attachment;
        
        system.debug('Attachment created with ID: ' + attachment.Id);
    }
    
    public void generateCsvForScheduledJobsNew(Id refTempId, String sJobs, Id sJobsRetrieveLogId){
        system.debug('sJobs --- ' + sJobs);
        List<Object> parsedData = (List<Object>) JSON.deserializeUntyped(sJobs);
        List<String> cronJobDetailsIds = new List<String>();
        
        String csvContent = '"Job Name","Job Type","Apex Class","Cron Expression"\n';
        
        for (Object obj : parsedData) {
            Map<String, Object> data = (Map<String, Object>) obj;
            String formattedString = (String) data.get('formattedString');
            system.debug('job records --- ' + formattedString);
            
            Pattern keyValuePattern = Pattern.compile('([a-zA-Z ]+):(.+?)(?=, [a-zA-Z ]+:|$)');
            Matcher matcher = keyValuePattern.matcher(formattedString);
            
            Map<String, String> fieldMap = new Map<String, String>();
            
            while (matcher.find()) {
                String key = matcher.group(1).trim();
                String value = matcher.group(2).trim();
                fieldMap.put(key, value);
            }
            
            List<String> row = new List<String>();
            row.add('"' + fieldMap.get('Job Name') + '"');
            row.add('"' + fieldMap.get('Job Type') + '"');
            row.add('"' + fieldMap.get('Apex Class') + '"');
            row.add('"' + fieldMap.get('Cron Expression') + '"');
            csvContent += String.join(row, ',') + '\n';
            system.debug('csvContent --- ' + csvContent);
        }
        insertCsvAsAttachmentForSJobsNew(refTempId, csvContent, sJobsRetrieveLogId);
    }
    
    private static void insertCsvAsAttachmentForSJobsNew(Id refTempId, String csvContent, Id sJobsRetrieveLogId) {
        Logs__c sJobsRetrieveLog = [select Id, Status__c, Details__c from Logs__c where Id =: sJobsRetrieveLogId];
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Scheduled Jobs';
        contentVersion.PathOnClient = 'Scheduled Jobs.csv';
        contentVersion.VersionData = Blob.valueOf(csvContent);
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = refTempId;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        
        insert contentDocumentLink;
        if(contentDocumentLink.Id != null){
            sJobsRetrieveLog.Status__c = 'Success';
            update sJobsRetrieveLog;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getTargetRefreshOrg(Id recordId) {
        system.debug('recordId --- ' + recordId);
        Refresh_Template__c template = [SELECT Target_Refresh_Org__c FROM Refresh_Template__c WHERE Id = :recordId LIMIT 1];
        //return template.Target_Refresh_Org__c;
        if (template.Target_Refresh_Org__c != null) {
            return template.Target_Refresh_Org__c.replaceAll('\\s+', ''); // Remove spaces
        }
        return null;
    }
    
    public static void createMetadataTransRulesCSV(Id refTempId, String findAndReplaceTemplate){
        Object deserializedObject = JSON.deserializeUntyped(findAndReplaceTemplate);

        if (!(deserializedObject instanceof List<Object>)) {
            throw new IllegalArgumentException('Invalid JSON format: Expected a list');
        }

        List<Object> tempList = (List<Object>) deserializedObject;
        List<Map<String, Object>> inputList = new List<Map<String, Object>>();

        for (Object obj : tempList) {
            if (obj instanceof Map<String, Object>) {
                inputList.add((Map<String, Object>) obj);
            } else {
                throw new IllegalArgumentException('Invalid JSON structure: Expected list of maps');
            }
        }

        List<String> csvRows = new List<String>();
        csvRows.add('"Metadata Type","Masking Type","Search Key","Replace Value","Suffix Value"');

        for (Map<String, Object> record : inputList) {
            String metadataTypes = (String) record.get('metadataTypesForFindAndReplace');
            List<String> metadataTypeList = metadataTypes.split(',');

            for (String metadataType : metadataTypeList) {
                metadataType = metadataType.trim();

                String maskingType = (String) record.get('maskingType');
                String searchKey = record.containsKey('searchKey') ? (String) record.get('searchKey') : '';
                String replaceValue = record.containsKey('replaceValue') ? (String) record.get('replaceValue') : '';
                String suffixValue = record.containsKey('suffixValue') ? (String) record.get('suffixValue') : '';

                String csvRow = '"' + metadataType + '","' + maskingType + '","' + searchKey + '","' + replaceValue + '","' + suffixValue + '"';
                csvRows.add(csvRow);
            }
        }

        String csvContent = String.join(csvRows, '\n');
        attachMetaTransRulesCsvToRefTemp(refTempId, csvContent);
    }
    
    private static void attachMetaTransRulesCsvToRefTemp(Id refTempId, String csvContent) {
        ContentVersion content = new ContentVersion();
        content.Title = 'Metadata_Masking_Rules.csv';
        content.PathOnClient = 'Metadata_Masking_Rules.csv';
        content.VersionData = Blob.valueOf(csvContent);
        insert content;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :content.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = refTempId;
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        insert contentDocumentLink;
        
        system.debug('metadata trandformation rules file attached --- ' + contentDocumentLink.Id);
    }
    
}