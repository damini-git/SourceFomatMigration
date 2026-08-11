@isTest
global class EditRefreshTemplateClassTest {
    
    @isTest
    static void testFetchRefreshTemplate(){
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test template',
                                                             Parent_Org__c = org1.Id);
        insert refTemp;
        
        Test.startTest();
        EditRefreshTemplateClass.fetchRefreshTemplate(refTemp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchAllMetadataComponents() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        PreRefreshMetadataMock mock = new PreRefreshMetadataMock();
        Test.setMock(WebServiceMock.class, mock);
        
        List<Map<String, String>> result = EditRefreshTemplateClass.fetchAllMetadataComponentsForEdit(org1.Id, 'CustomLabels');
        system.debug('result --- ' + result);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchAllMetadataComponents1() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        PreRefreshMetadataMock mock = new PreRefreshMetadataMock();
        Test.setMock(WebServiceMock.class, mock);
        
        List<Map<String, String>> result = EditRefreshTemplateClass.fetchAllMetadataComponentsForEdit(org1.Id, 'ApexClass');
        system.debug('result --- ' + result);
        
        Test.stopTest();
    }
    
    private static Id createTestSandbox() {
        Org__c sandbox = new Org__c(Name = 'Test', Domain_URL__c = 'https://test.salesforce.com');
        insert sandbox;
        return sandbox.Id;
    }
    
    @IsTest
    static void testCreateTemplate() {
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"id":"mockAsyncId"}'));
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"done":true,"zipFile":"UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA=="}'));
        Org__c testOrg = new Org__c(
            Access_Token__c = 'TestAccessToken',
            Domain_Url__c = 'https://test.salesforce.com'
        );
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test template',
                                                             Parent_Org__c = testOrg.Id,
                                                             Custom_Setting_Names__c = 'Custom1, Custom2');
        insert refTemp;
        
        Logs__c log = new Logs__c(Parent_Template__c = refTemp.Id,
                                 Log_Type__c = 'Metadata Retrieve - Template Creation',
                                 Status__c = 'InProgress');
        insert log;
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        
        Id sandboxId = createTestSandbox();
        String fakeAsyncId = testOrg.Id;
        String packageXml = '<Package><types><members>*</members><name>ApexClass</name></types></Package>';
        //String userData = '[{"id":"test@salesforce.com","formattedString":"Name: Test User, Email: test@salesforce.com, Username: test@salesforce.com, Profile: Standard User"}]';
        List<String> selectedUsernames = new List<String>{'test.user@cf.com','test@salesforce.com'};
        List<String> customSettingNames = new List<String>{'Custom1', 'Custom2'};
            String sJobs = '[{"id":"Program Milestone Computation Cron Job","formattedString":"Job Name: Program Milestone Computation Cron Job, Job Type: P, State: WAITING, Time Zone: America/Los_Angeles, CronJobDetailId: 08aNS0000002Uy6YAE"}]';
        String findAndReplaceTemplates = '[{"id":1,"metadataTypesForFindAndReplace":"CustomLabel,CustomMetadata","maskingType":"Search & Replace","searchKey":"biswa","replaceValue":"akhil"},{"id":2,"metadataTypesForFindAndReplace":"NamedCredential","maskingType":"Search & Replace","searchKey":"login","replaceValue":"test"},{"id":3,"metadataTypesForFindAndReplace":"WorkflowAlert","maskingType":"Suffix","suffixValue":".invalid"}]';
        String jsonData = '[{"ScriptName":"WorkflowAlert","ScriptData":"Suffix"},{"ScriptName":"CustomLabel","ScriptData":"Search & Replace"}]';
        
        string csvString ='order,scriptname\n'
            + '1,scriptA\n'
            + '2,scriptB';
        
        //PreRefreshAutomationClass.InitialMetadataRetrievalJob job = new PreRefreshAutomationClass.InitialMetadataRetrievalJob('fakeAsyncResultId', testOrg.Id, testOrg.Access_Token__c, 'test', '<Package></Package>', userData, customSettingNames, sJobs); //, findAndReplaceTemplates
        BackupRegenerationOfMetadata.InitialMetadataRetrievalJobNew job = new BackupRegenerationOfMetadata.InitialMetadataRetrievalJobNew(fakeAsyncId, refTemp.Id, testOrg.Domain_Url__c, testOrg.Access_Token__c, packageXml, log.Id); //, selectedUsernames, customSettingNames, sJobs
        
        Test.startTest();
        //PreRefreshAutomationClass.createNewTemplate(sandboxId, 'test', packageXml, selectedUsernames, customSettingNames, sJobs); //, findAndReplaceTemplates
        EditRefreshTemplateClass.updateTemplate(sandboxId, refTemp.Id, 'test', packageXml, selectedUsernames, customSettingNames, sJobs, findAndReplaceTemplates, jsonData, csvString);
        BackupRegenerationOfMetadata.retrievePackage(refTemp.Id, testOrg.Domain_Url__c, testOrg.Access_Token__c, packageXml, log.Id); //, selectedUsernames, customSettingNames, sJobs
        System.enqueueJob(job);
        BackupRegenerationOfMetadata.initiateMetadataRetrievalAgain(fakeAsyncId, refTemp.Id, testOrg.Domain_Url__c, testOrg.Access_Token__c, packageXml, log.Id);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Name = 'Metadata.zip'];
        System.assertNotEquals(1, attachments.size());
        //System.assertEquals('Metadata.zip', attachments[0].Name);
    }
    
    @IsTest
    static void testUpdateTemplate() {
        Org__c testOrg = new Org__c(
            Access_Token__c = 'TestAccessToken',
            Domain_Url__c = 'https://test.salesforce.com'
        );
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test template',
                                                              Parent_Org__c = testOrg.Id,
                                                              Is_Metadata_Selected__c = true,
                                                              Is_User_Data_Selected__c = true,
                                                              Custom_Setting_Names__c = 'Custom1__c',
                                                              Is_Scheduled_Jobs_Selected__c = true,
                                                              Is_Find_And_Replace_Rules_Selected__c = true);
        insert refTemp;
        
        Logs__c log = new Logs__c(Parent_Template__c = refTemp.Id,
                                 Log_Type__c = 'Metadata Retrieve - Update Template',
                                 Status__c = 'InProgress');
        insert log;
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        
        Id sandboxId = createTestSandbox();
        String fakeAsyncId = testOrg.Id;
        String packageXml = '';
        List<String> selectedUsernames = new List<String>();
        List<String> customSettingNames = new List<String>();
            String sJobs = '[]';
        String findAndReplaceTemplates = '[]';
        String jsonData = '';
        string csvString ='';
        
        Test.startTest();
        EditRefreshTemplateClass.updateTemplate(sandboxId, refTemp.Id, 'test', packageXml, selectedUsernames, customSettingNames, sJobs, findAndReplaceTemplates, jsonData, csvString);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Name = 'Metadata.zip'];
        System.assertNotEquals(1, attachments.size());
    }

}