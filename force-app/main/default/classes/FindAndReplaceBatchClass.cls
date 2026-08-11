public class FindAndReplaceBatchClass implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful{
    
    private MetadataService.MetadataPort service;
    private string metadataType;
    private string maskingType;
    private string searchKey;
    private string replaceValue;
    private Id metaTransformLogId;
    
    public Set<Map<String, String>> successRecords;
    public Set<Map<String, String>> failedRecords;
    
    public FindAndReplaceBatchClass(MetadataService.MetadataPort service, String metadataType, String maskingType, String searchKey, String replaceValue, Id metaTransformLogId) {
        this.service = service;
        this.metadataType = metadataType;
        this.maskingType = maskingType;
        this.searchKey = searchKey;
        this.replaceValue = replaceValue;
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
            metadataCompNames.add('TestRemoteSiteSetting');
            metadataCompNames.add('TestNamedCredential');
            metadataCompNames.add('TestAuthProvider');
            metadataCompNames.add('TestConnectedApp');
            metadataCompNames.add('Test_CustomMetadata');
            metadataCompNames.add('TestWorkflowAlert');
        }
        
        system.debug('metadataCompNames size in start method --- ' + metadataCompNames.size());
        return metadataCompNames;
    }
    
    public void execute(Database.BatchableContext context, List<String> batch) {
        system.debug('batch size coming from start method --- ' + batch.size());
        
        List<MetadataService.Metadata> lToUpdate = new List<MetadataService.Metadata>();
        MetadataService.Metadata[] records;
        
        if (Test.isRunningTest()) {
            MetadataService.CustomLabel mockLabel = new MetadataService.CustomLabel();
            mockLabel.fullName = batch[0];
            mockLabel.value = 'login.m@abc.com';
            records = new List<MetadataService.Metadata> { mockLabel };
                lToUpdate.add(mockLabel);
            
            MetadataService.RemoteSiteSetting mockRemoteSiteSetting = new MetadataService.RemoteSiteSetting();
            mockRemoteSiteSetting.fullName = batch[1];
            mockRemoteSiteSetting.url = 'https://login.example.com';
            records.add(mockRemoteSiteSetting);
            lToUpdate.add(mockRemoteSiteSetting);
            
            MetadataService.NamedCredential mockNamedCredential = new MetadataService.NamedCredential();
            mockNamedCredential.fullName = batch[2];
            mockNamedCredential.endpoint = 'https://login.api.com';
            records.add(mockNamedCredential);
            lToUpdate.add(mockNamedCredential);
            
            MetadataService.AuthProvider mockAuthProvider = new MetadataService.AuthProvider();
            mockAuthProvider.fullName = batch[3];
            mockAuthProvider.authorizeUrl = 'https://login.salesforce.com/services/oauth2/authorize';
            mockAuthProvider.tokenUrl = 'https://login.salesforce.com/services/oauth2/token';
            records.add(mockAuthProvider);
            lToUpdate.add(mockAuthProvider);
            
            MetadataService.ConnectedApp mockConnectedApp = new MetadataService.ConnectedApp();
            mockConnectedApp.fullName = batch[4];
            MetadataService.ConnectedAppOauthConfig config = new MetadataService.ConnectedAppOauthConfig();
            config.callbackUrl = 'https://login.salesforce.com';
            mockConnectedApp.oauthConfig = config;
            records.add(mockConnectedApp);
            lToUpdate.add(mockConnectedApp);
            
            MetadataService.CustomMetadata mockCustomMetadata = new MetadataService.CustomMetadata();
            mockCustomMetadata.fullName = batch[5];
            
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
            mockWorkflowAlert.fullName = batch[6];
            mockWorkflowAlert.ccEmails = ccEmailList;
            records.add(mockWorkflowAlert);
            lToUpdate.add(mockWorkflowAlert);
            
        } else {
            system.debug('batch inside else of execute --- ' + batch.size());
            MetadataService.IReadResult readResult = service.readMetadata(metadataType, batch);
            system.debug('readResult.getRecords() size --- ' + readResult.getRecords().size());
            records = readResult.getRecords();
        }
        
        for (MetadataService.Metadata record : records) {
            
            if(metadataType == 'CustomLabel' && maskingType == 'Search & Replace'){
                if (record instanceof MetadataService.CustomLabel) {
                    MetadataService.CustomLabel cl = (MetadataService.CustomLabel) record;
                    
                    if(cl.fullName != null && cl.value != null){
                        if(cl.value.contains(searchKey)){
                            System.debug('Custom Label Name: ' + cl.fullName);
                            System.debug('Custom Label Body: ' + cl.value);
                            cl.value = cl.value.replace(searchKey, replaceValue);
                            lToUpdate.add(cl);
                        }
                    }
                } else {
                    System.debug('Unsupported Metadata Type: ' + record.fullName);
                }
            }
            
            if(metadataType == 'RemoteSiteSetting' && maskingType == 'Search & Replace'){
                if (record instanceof MetadataService.RemoteSiteSetting) {
                    MetadataService.RemoteSiteSetting rss = (MetadataService.RemoteSiteSetting) record;
                    
                    if(rss.fullName != null && rss.url != null){
                        if(rss.url.contains(searchKey)){
                            System.debug('RemoteSiteSetting Name: ' + rss.fullName);
                            System.debug('RemoteSiteSetting Body: ' + rss.url);
                            rss.url = rss.url.replace(searchKey, replaceValue);
                            lToUpdate.add(rss);
                        }
                    }
                } else {
                    System.debug('Unsupported Metadata Type: ' + record.fullName);
                }
            }
            
            if(metadataType == 'NamedCredential' && maskingType == 'Search & Replace'){
                if (record instanceof MetadataService.NamedCredential) {
                    MetadataService.NamedCredential namedCred = (MetadataService.NamedCredential) record;
                    
                    if(namedCred.fullName != null && namedCred.endpoint != null){
                        if(namedCred.endpoint.contains(searchKey)){
                            System.debug('NamedCredential Name: ' + namedCred.fullName);
                            System.debug('NamedCredential Body: ' + namedCred.endpoint);
                            namedCred.endpoint = namedCred.endpoint.replace(searchKey, replaceValue);
                            lToUpdate.add(namedCred);
                        }
                    }
                } else {
                    System.debug('Unsupported Metadata Type: ' + record.fullName);
                }
            }
            
            if(metadataType == 'AuthProvider' && maskingType == 'Search & Replace'){
                if (record instanceof MetadataService.AuthProvider) {
                    MetadataService.AuthProvider auth = (MetadataService.AuthProvider) record;
                    
                    if(auth.fullName != null && auth.authorizeUrl != null){
                        if(auth.authorizeUrl.contains(searchKey)){
                            System.debug('AuthProvider Name: ' + auth.fullName);
                            System.debug('AuthProvider authorise url: ' + auth.authorizeUrl);
                            auth.authorizeUrl = auth.authorizeUrl.replace(searchKey, replaceValue);
                            system.debug('new value --- ' + auth.authorizeUrl);
                            lToUpdate.add(auth);
                        }
                    }
                    if(auth.fullName != null && auth.tokenUrl != null){
                        if(auth.tokenUrl.contains(searchKey)){
                            System.debug('AuthProvider token url: ' + auth.tokenUrl);
                            auth.tokenUrl = auth.tokenUrl.replace(searchKey, replaceValue);
                            system.debug('new value --- ' + auth.tokenUrl);
                            lToUpdate.add(auth);
                        }
                    }
                } else {
                    System.debug('Unsupported Metadata Type: ' + record.fullName);
                }
            }
            
            if(metadataType == 'ConnectedApp' && maskingType == 'Search & Replace'){
                if (record instanceof MetadataService.ConnectedApp) {
                    MetadataService.ConnectedApp conApp = (MetadataService.ConnectedApp) record;
                    
                    if(conApp.fullName != null){
                        System.debug('ConnectedApp Name: ' + conApp.fullName);
                        MetadataService.ConnectedAppOauthConfig config = (MetadataService.ConnectedAppOauthConfig) conApp.oauthConfig;
                        system.debug('Connected App callback url: ' + config.callbackUrl);
                        if(config.callbackUrl != null && config.callbackUrl.contains(searchKey)){
                            config.callbackUrl = config.callbackUrl.replace(searchKey, replaceValue);
                            lToUpdate.add(conApp);
                        }
                    }
                }
            }
            
            if(metadataType == 'CustomMetadata' && maskingType == 'Search & Replace'){
                if (record instanceof MetadataService.CustomMetadata) {
                    MetadataService.CustomMetadata custMet = (MetadataService.CustomMetadata) record;
                    
                    if(custMet.fullName != null && custMet.values != null){
                        System.debug('CustomMetadata Name: ' + custMet.fullName);
                        System.debug('CustomMetadata values: ' + custMet.values);
                        MetadataService.CustomMetadataValue[] custMetFields = (MetadataService.CustomMetadataValue[]) custMet.values;
                        system.debug('custMetFields size --- ' + custMetFields.size());
                        
                        for(MetadataService.CustomMetadataValue custMetField : custMetFields){
                            system.debug('field values --- ' + custMetField.value);
                            if(custMetField.value.contains(searchKey)){
                                custMetField.value = custMetField.value.replace(searchKey, replaceValue);
                                lToUpdate.add(custMet);
                            }
                        }
                    }
                } else {
                    System.debug('Unsupported Metadata Type: ' + record.fullName);
                }
            }
            
            if(metadataType == 'WorkflowAlert' && maskingType == 'Search & Replace'){
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
                                if(ccEmail.contains(searchKey)){
                                    ccEmail = ccEmail.replace(searchKey, replaceValue);
                                    newListOfCCEmails.add(ccEmail);
                                }
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