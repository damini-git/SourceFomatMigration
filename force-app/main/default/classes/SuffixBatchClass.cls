public class SuffixBatchClass implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful{
    
    private MetadataService.MetadataPort service;
    private string metadataType;
    private string maskingType;
    private string suffixValue;
    private Id metaTransformLogId;
    
    public Set<Map<String, String>> successRecords;
    public Set<Map<String, String>> failedRecords;
    
    public SuffixBatchClass(MetadataService.MetadataPort service, String metadataType, String maskingType, String suffixValue, Id metaTransformLogId) {
        this.service = service;
        this.metadataType = metadataType;
        this.maskingType = maskingType;
        this.suffixValue = suffixValue;
        this.metaTransformLogId = metaTransformLogId;
        
        this.successRecords = new Set<Map<String, String>>();
        this.failedRecords = new Set<Map<String, String>>();
    }
    
    public List<String> start(Database.BatchableContext context) {
        system.debug('metadataType in start method --- ' + metadataType);
        
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
        
        MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
        query.type_x = (metadataType == 'CustomLabels') ? 'CustomLabel' : metadataType;
        queries.add(query);
        
        List<String> metadataCompNames = new List<String>();
        
        if(!test.isRunningTest()){
            MetadataService.FileProperties[] tempProperties = service.listMetadata(new List<MetadataService.ListMetadataQuery>{ query }, Double.valueOf(42.0));
            for (MetadataService.FileProperties prop : tempProperties) {
                metadataCompNames.add(prop.fullName);
            }
        }
        else{
            metadataCompNames.add('test1');
            metadataCompNames.add('Test_CustomMetadata');
            metadataCompNames.add('TestWorkflowAlert');
            metadataCompNames.add('TestConnectedApp');
            metadataCompNames.add('TestEmailServicesFunction');
        }
        
        system.debug('metadataCompNames size in start method --- ' + metadataCompNames.size());
        return metadataCompNames;
    }
    
    public void execute(Database.BatchableContext context, List<String> batch) {
        system.debug('batch size coming from start method --- ' + batch.size());
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern pattern = Pattern.compile(emailRegex);
        
        List<MetadataService.Metadata> lToUpdate = new List<MetadataService.Metadata>();
        MetadataService.Metadata[] records;
        
        if (Test.isRunningTest()) {
            MetadataService.CustomLabel mockLabel = new MetadataService.CustomLabel();
            mockLabel.fullName = batch[0];
            mockLabel.value = 'login.m@abc.com';
            records = new List<MetadataService.Metadata> { mockLabel };
                lToUpdate.add(mockLabel);
            
            MetadataService.CustomMetadata mockCustomMetadata = new MetadataService.CustomMetadata();
            mockCustomMetadata.fullName = batch[1];
            
            MetadataService.CustomMetadataValue mockField1 = new MetadataService.CustomMetadataValue();
            mockField1.field = 'Field1';
            mockField1.value = 'login.value@example.com';
            
            MetadataService.CustomMetadataValue mockField2 = new MetadataService.CustomMetadataValue();
            mockField2.field = 'Field2';
            mockField2.value = 'static.value@example.com';
            
            mockCustomMetadata.values = new List<MetadataService.CustomMetadataValue>{ mockField1, mockField2 };
                records.add(mockCustomMetadata);
            lToUpdate.add(mockCustomMetadata);
            
            List<String> ccEmailList = new List<String>{'login.cc@abc.com'};
                MetadataService.WorkflowAlert mockWorkflowAlert = new MetadataService.WorkflowAlert();
            mockWorkflowAlert.fullName = batch[2];
            mockWorkflowAlert.ccEmails = ccEmailList;
            records.add(mockWorkflowAlert);
            lToUpdate.add(mockWorkflowAlert);
            
            MetadataService.ConnectedApp mockConnectedApp = new MetadataService.ConnectedApp();
            mockConnectedApp.fullName = batch[3];
            mockConnectedApp.contactEmail = 'login.contact@abc.com';
            records.add(mockConnectedApp);
            lToUpdate.add(mockConnectedApp);
            
            MetadataService.EmailServicesFunction mockEmailServicesFunction = new MetadataService.EmailServicesFunction();
            mockEmailServicesFunction.fullName = batch[4];
            mockEmailServicesFunction.errorRoutingAddress = 'login.error@abc.com';
            records.add(mockEmailServicesFunction);
            lToUpdate.add(mockEmailServicesFunction);
            
        } else {
            system.debug('batch inside else of execute --- ' + batch.size());
            MetadataService.IReadResult readResult = service.readMetadata(metadataType, batch);
            system.debug('readResult.getRecords() size --- ' + readResult.getRecords().size());
            records = readResult.getRecords();
        }
        
        for (MetadataService.Metadata record : records) {
			system.debug('record full name --- ' + record.fullName);
            
            if(metadataType == 'CustomLabel' && maskingType == 'Suffix'){
                if (record instanceof MetadataService.CustomLabel) {
                    MetadataService.CustomLabel cl = (MetadataService.CustomLabel) record;
                    
                    if(cl.fullName != null && cl.value != null){
                        System.debug('Custom Label Name: ' + cl.fullName);
                        System.debug('Custom Label Body: ' + cl.value);
                        Matcher matcher = pattern.matcher(cl.value);
                        if(matcher.matches()){
                            cl.value += suffixValue;
                            lToUpdate.add(cl);
                        }
                    }
                } else {
                    System.debug('Unsupported Metadata Type: ' + record.fullName);
                }
            }
            
            if(metadataType == 'ConnectedApp' && maskingType == 'Suffix'){
                if (record instanceof MetadataService.ConnectedApp) {
                    MetadataService.ConnectedApp conApp = (MetadataService.ConnectedApp) record;
                    
                    if(conApp.fullName != null && conApp.contactEmail != null){
                        System.debug('ConnectedApp Name: ' + conApp.fullName);
                        System.debug('ConnectedApp contactEmail: ' + conApp.contactEmail);
                        Matcher matcher = pattern.matcher(conApp.contactEmail);
                        if(matcher.matches()){
                            conApp.contactEmail += suffixValue;
                            lToUpdate.add(conApp);
                        }
                    }
                }
            }
            
            if(metadataType == 'EmailServicesFunction' && maskingType == 'Suffix'){
                if (record instanceof MetadataService.EmailServicesFunction) {
                    MetadataService.EmailServicesFunction emailServ = (MetadataService.EmailServicesFunction) record;
                    
                    if(emailServ.fullName != null && emailServ.errorRoutingAddress != null){
                        System.debug('EmailServicesFunction Name: ' + emailServ.fullName);
                        System.debug('EmailServicesFunction Name: ' + emailServ.errorRoutingAddress);
                        Matcher matcher = pattern.matcher(emailServ.errorRoutingAddress);
                        if(matcher.matches()){
                            emailServ.errorRoutingAddress += suffixValue;
                            lToUpdate.add(emailServ);
                        }
                    }
                }
            }
            
            if(metadataType == 'CustomMetadata' && maskingType == 'Suffix'){
                if (record instanceof MetadataService.CustomMetadata) {
                    MetadataService.CustomMetadata custMet = (MetadataService.CustomMetadata) record;
                    
                    if(custMet.fullName != null && custMet.values != null){
                        System.debug('CustomMetadata Name: ' + custMet.fullName);
                        System.debug('CustomMetadata values: ' + custMet.values);
                        MetadataService.CustomMetadataValue[] custMetFields = (MetadataService.CustomMetadataValue[]) custMet.values;
                        system.debug('custMetFields size --- ' + custMetFields.size());
                        
                        if (custMetFields != null && !custMetFields.isEmpty()) {
                            for(MetadataService.CustomMetadataValue custMetField : custMetFields){
                                system.debug('field values --- ' + custMetField.value);
                                Matcher matcher = pattern.matcher(custMetField.value);
                                if(matcher.matches()){
                                    custMetField.value += suffixValue;
                                    lToUpdate.add(custMet);
                                }
                            }
                        }
                    }
                } else {
                    System.debug('Unsupported Metadata Type: ' + record.fullName);
                }
            }
            
            if(metadataType == 'WorkflowAlert' && maskingType == 'Suffix'){
                if (record instanceof MetadataService.WorkflowAlert) {
                    MetadataService.WorkflowAlert workflowAlert = (MetadataService.WorkflowAlert) record;
                    
                    if(workflowAlert.fullName != null && workflowAlert.ccEmails.size() > 0){
                        System.debug('WorkflowAlert Name: ' + workflowAlert.fullName);
                        System.debug('WorkflowAlert template: ' + workflowAlert.template);
                        System.debug('WorkflowAlert ccEmails: ' + workflowAlert.ccEmails);
                        
                        List<String> newListOfCCEmails = new List<String>();
                        if(workflowAlert.ccEmails != null){
                            String[] ccEmails = (String[]) workflowAlert.ccEmails;
                            for(String ccEmail : ccEmails){
                                ccEmail += suffixValue;
                                system.debug('ccEmail inside for --- ' + ccEmail);
                                newListOfCCEmails.add(ccEmail);
                            }
                            workflowAlert.ccEmails = newListOfCCEmails;
                            lToUpdate.add(workflowAlert);
                        }
                    }
                }
            }
        }
        
        system.debug('lToUpdate.size() --- ' + lToUpdate.size());
        if(lToUpdate.size() > 0 && !test.isRunningTest()){
            system.debug(' ------ updating ------ ');
            MetadataService.UpsertResult[] upsertResults = service.upsertMetadata(new List<MetadataService.Metadata> (lToUpdate));
            system.debug('upsertResults size --- ' + upsertResults.size());
            system.debug('upsertResults body --- ' + upsertResults);
            
            for (Integer j = 0; j < upsertResults.size(); j++) {
                MetadataService.UpsertResult result = upsertResults[j];
                system.debug('result --- ' + result.fullName);
                system.debug('result of upsertResults --- ' + result.success);
                if (result.success) {
                    System.debug('Metadata upsert successful for: ' + result.fullName);
                    Map<String, String> successRecs = new Map<String, String>();
                    successRecs.put(result.fullName, '');
                    successRecords.add(successRecs);
                } else {
                    System.debug('Metadata upsert failed for: ' + result.fullName);
                    for (MetadataService.Error error : result.errors) {
                        Map<String, String> failedRecs = new Map<String, String>();
                        failedRecs.put(result.fullName, error.message);
                        failedRecords.add(failedRecs);
                        System.debug('Error Message: ' + error.message);
                        System.debug('Error Status Code: ' + error.statusCode);
                    }
                }
            }
        }
        
        system.debug('successRecords size in execute method --- ' + successRecords.size());
        system.debug('failedRecords size in execute method --- ' + failedRecords.size());
    }
    
    public void finish(Database.BatchableContext context) {
        system.debug('in finish method ------- ');
        system.debug('successRecords.size() --- ' + successRecords.size());
        system.debug('failedRecords.size() --- ' + failedRecords.size());
        
        if(successRecords.size() > 0){ PostRefreshAutomationClass.attachCsvToLog(successRecords, metadataType + '_SuccessRecords.csv', false, metaTransformLogId);
                                     }
        if(failedRecords.size() > 0){ PostRefreshAutomationClass.attachCsvToLog(failedRecords, metadataType + '_FailedRecords.csv', true, metaTransformLogId);
                                    }
    }
}