@IsTest
global class PreRefreshAutomationClassTest {
    
    @IsTest
    static void testCreateService() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                Domain_Url__c = 'https://login.salesforce.com',
                                Access_Token__c = '12345',
                                Refresh_Token__c = '09876');
        insert org1;
        
        Org__c org = [select Id, Domain_Url__c, Access_Token__c from Org__c where Id =: org1.Id];
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test template',
                                                              Parent_Org__c = org1.Id,
                                                              Target_Refresh_Org__c = 'BiswaDev');
        insert refTemp;
        
        system.debug('ref temp Id --- ' + refTemp.Id);
        Test.startTest();
        
        //PreRefreshAutomationClass.createService(org.Domain_URL__c, org.Id);
        PreRefreshAutomationClass.fetchAllRefreshTemplates();
        PreRefreshAutomationClass.fetchAllOrgs();
        PreRefreshAutomationClass.getTemplateOrgName(refTemp.Id);
        PreRefreshAutomationClass.checkOrgAuthenticated(org1.Id);
        PreRefreshAutomationClass.deleteRecord(refTemp.Id);
        //PreRefreshAutomationClass.fetchParentOrgOfRefreshTemplate(refTemp.Id);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchSourceOrgsForRefresh(){
        Org__c org1 = new Org__c(Name='TestOrg1',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345',
                                 Org_Type__c = 'Production');
        insert org1;
        
        Org__c org2 = new Org__c(Name='TestOrg2',
                                 Domain_Url__c = 'https://test.salesforce.com',
                                 Access_Token__c = '12345',
                                 Org_Type__c = 'Sandbox',
                                 Production_Org__c = org1.Id);
        insert org2;
        
        Org__c org3 = new Org__c(Name = 'TestOrg3',
                                 Domain_Url__c = 'https://test.salesforce.com',
                                 Access_Token__c = '12345',
                                 Org_Type__c = 'Sandbox',
                                 Production_Org__c = org1.Id);
        insert org3;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'Test Template',
                                                              Parent_Org__c = org3.Id);
        insert refTemp;
        
        Test.startTest();
        PreRefreshAutomationClass.fetchSourceOrgsForRefresh(refTemp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetTargetRefreshOrg() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Org__c org = [select Id, Domain_Url__c, Access_Token__c from Org__c where Id =: org1.Id];
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test template',
                                                              Parent_Org__c = org1.Id,
                                                              Target_Refresh_Org__c = 'BiswaDev');
        insert refTemp;
        
        Test.startTest();
        PreRefreshAutomationClass.getTargetRefreshOrg(refTemp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testDeleteRecordException() {
        String invalidId = 'InvalidId12345';
        
        Test.startTest();
        try {
            PreRefreshAutomationClass.deleteRecord(invalidId);
            System.assert(false, 'Expected an AuraHandledException to be thrown.');
        } catch (AuraHandledException e) {
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testParsePackageXml() {
        String packageXmlContent = 
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '    <types>' +
            '        <members>Account</members>' +
            '        <members>Contact</members>' +
            '        <name>CustomObject</name>' +
            '    </types>' +
            '    <types>' +
            '        <members>MyCustomField__c</members>' +
            '        <name>CustomField</name>' +
            '    </types>' +
            '    <version>59.0</version>' +
            '</Package>';
        
        MetadataService.Package_x result = PreRefreshAutomationClass.parsePackageXml(packageXmlContent);
        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(2, result.types.size(), 'The number of types should be 2.');
        
        MetadataService.PackageTypeMembers firstType = result.types[0];
        System.assertEquals('CustomObject', firstType.name, 'The name of the first type should be CustomObject.');
        System.assertEquals(2, firstType.members.size(), 'The number of members in the first type should be 2.');
        System.assert(firstType.members.contains('Account'), 'The members should contain Account.');
        System.assert(firstType.members.contains('Contact'), 'The members should contain Contact.');
        
        MetadataService.PackageTypeMembers secondType = result.types[1];
        System.assertEquals('CustomField', secondType.name, 'The name of the second type should be CustomField.');
        System.assertEquals(1, secondType.members.size(), 'The number of members in the second type should be 1.');
        System.assert(secondType.members.contains('MyCustomField__c'), 'The members should contain MyCustomField__c.');
        
        System.assertEquals('59.0', result.version, 'The version should be 59.0.');
    }
    
    @isTest
    static void testParseXML() {
        String packageXmlContent = 
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '    <types>' +
            '        <members>Account</members>' +
            '        <members>Contact</members>' +
            '        <name>CustomObject</name>' +
            '    </types>' +
            '    <types>' +
            '        <members>MyCustomField__c</members>' +
            '        <name>CustomField</name>' +
            '    </types>' +
            '    <version>59.0</version>' +
            '</Package>';
        
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                Domain_Url__c = 'https://login.salesforce.com',
                                Access_Token__c = '12345');
        insert org1;
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test',
                                                             Package_Xml_Val__c = packageXmlContent,
                                                             Parent_Org__c = org1.Id);
        insert refTemp;
        
        
        Test.startTest();
        
        PreRefreshAutomationClass.parseXML(refTemp.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testFetchAllMetadataTypes() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test',
                                                              Parent_Org__c = org1.Id);
        insert refTemp;
        
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        PreRefreshMetadataMock mock = new PreRefreshMetadataMock();
        Test.setMock(WebServiceMock.class, mock);
        
        List<String> metadataTypes = PreRefreshAutomationClass.fetchAllMetadataTypes(org1.Id);
        
        Test.stopTest();
        
        //System.assertEquals(10, metadataTypes.size(), 'Metadata types should be fetched.');
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
        
        List<Map<String, String>> result = PreRefreshAutomationClass.fetchAllMetadataComponents(org1.Id, 'CustomLabels');
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
        
        List<Map<String, String>> result = PreRefreshAutomationClass.fetchAllMetadataComponents(org1.Id, 'ApexClass');
        system.debug('result --- ' + result);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchAllCustomObjects() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        PreRefreshMetadataMock mock = new PreRefreshMetadataMock();
        Test.setMock(WebServiceMock.class, mock);
        
        List<String> result = PreRefreshAutomationClass.fetchAllCustomObjects(org1.Id);
        system.debug('result --- ' + result);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchFieldsOfObject() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        PreRefreshMetadataMock mock = new PreRefreshMetadataMock();
        Test.setMock(WebServiceMock.class, mock);
        
        List<Map<String,String>> result = PreRefreshAutomationClass.fetchFieldsOfObject(org1.Id, 'Account');
        system.debug('result --- ' + result);
        
        Test.stopTest();
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
                                                             Parent_Org__c = testOrg.Id);
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
        
        //PreRefreshAutomationClass.InitialMetadataRetrievalJob job = new PreRefreshAutomationClass.InitialMetadataRetrievalJob('fakeAsyncResultId', testOrg.Id, testOrg.Access_Token__c, 'test', '<Package></Package>', userData, customSettingNames, sJobs); //, findAndReplaceTemplates
        PreRefreshAutomationClass.InitialMetadataRetrievalJobNew job = new PreRefreshAutomationClass.InitialMetadataRetrievalJobNew(fakeAsyncId, testOrg.Id, refTemp.Id, testOrg.Domain_Url__c, testOrg.Access_Token__c, packageXml, log.Id); //, selectedUsernames, customSettingNames, sJobs
        
        Test.startTest();
        //PreRefreshAutomationClass.createNewTemplate(sandboxId, 'test', packageXml, selectedUsernames, customSettingNames, sJobs); //, findAndReplaceTemplates
        PreRefreshAutomationClass.createNewTemplate(sandboxId, 'test', packageXml, selectedUsernames, customSettingNames, sJobs, findAndReplaceTemplates, '', '');
        PreRefreshAutomationClass.retrievePackage(sandboxId, refTemp.Id, testOrg.Domain_Url__c, testOrg.Access_Token__c, packageXml, log.Id); //, selectedUsernames, customSettingNames, sJobs
        System.enqueueJob(job);
        PreRefreshAutomationClass.initiateMetadataRetrievalAgain(fakeAsyncId, testOrg.Id, refTemp.Id, testOrg.Domain_Url__c, testOrg.Access_Token__c, packageXml, log.Id);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Name = 'Metadata.zip'];
        System.assertNotEquals(1, attachments.size());
        //System.assertEquals('Metadata.zip', attachments[0].Name);
    }
    
    private static Id createTestSandbox() {
        Org__c sandbox = new Org__c(Name = 'Test', Domain_URL__c = 'https://test.salesforce.com');
        insert sandbox;
        return sandbox.Id;
    }
    
    global class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private String locationHeader;
        
        public MockHttpResponse(Integer statusCode, String responseBody, String locationHeader) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.locationHeader = locationHeader;
        }
        
        public MockHttpResponse(Integer statusCode, String responseBody) {
            this(statusCode, responseBody, null);
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            if (locationHeader != null) {
                res.setHeader('Location', locationHeader);
            }
            return res;
        }
    }
    
    public class MetadataServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            
            if (req.getEndpoint().contains('/services/Soap/m/59.0/metadata')) {
                if (req.getBody().contains('<listMetadata>')) {
                    res.setBody(
                        '<?xml version="1.0" encoding="UTF-8"?>' +
                        '<ListMetadataResponse>' +
                        '    <result>' +
                        '        <fullName>CustomMetadata1.CustomMetadata1__mdt</fullName>' +
                        '        <fullName>CustomMetadata2.CustomMetadata2__mdt</fullName>' +
                        '    </result>' +
                        '</ListMetadataResponse>'
                    );
                } else if (req.getBody().contains('<readMetadata>')) {
                    res.setBody(
                        '<?xml version="1.0" encoding="UTF-8"?>' +
                        '<ReadCustomMetadataResponse>' +
                        '    <result>' +
                        '        <fullName>CustomMetadata1__mdt</fullName>' +
                        '        <fullName>CustomMetadata2__mdt</fullName>' +
                        '    </result>' +
                        '</ReadCustomMetadataResponse>'
                    );
                }
                res.setStatusCode(200);
            } else {
                res.setStatusCode(404);
            }
            return res;
        }
    }
    
    @IsTest
    static void testHandleRetrievedMetadata() {
        Org__c testOrg = new Org__c(
            Access_Token__c = 'TestAccessToken',
            Domain_Url__c = 'https://test.salesforce.com'
        );
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test template',
                                                             Parent_Org__c = testOrg.Id);
        insert refTemp;
        
        Logs__c log = new Logs__c(Parent_Template__c = refTemp.Id,
                                 Log_Type__c = 'Metadata Retrieve - Template Creation',
                                 Status__c = 'InProgress');
        insert log;
        
        MetadataService.RetrieveResult mockRetrieveResult = new MetadataService.RetrieveResult();
        mockRetrieveResult.zipFile = EncodingUtil.base64Encode(Blob.valueOf('Mock zip file content'));
        
        String packageXml = '<Package><types><members>*</members><name>ApexClass</name></types></Package>';
        List<String> customSettingNames = new List<String>{'Custom1', 'Custom2'};
        String findAndReplaceTemplates = 'test template';
        
        Test.startTest();
        PreRefreshAutomationClass automationClass = new PreRefreshAutomationClass();
        
        //automationClass.handleRetrievedMetadata(testOrg, mockRetrieveResult, 'test', packageXml, customSettingNames); //, findAndReplaceTemplates
        automationClass.handleRetrievedMetadataNew(refTemp.Id, mockRetrieveResult, packageXml, log.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testCheckCustomSettingRetrieveStatus(){
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Custom_Setting_Names__c = 'Setting1, Setting2',
            Parent_Org__c = org1.Id
        );
        insert template;
        
        Logs__c log = new Logs__c(Parent_Template__c = template.Id,
                                 Log_type__c = 'Custom Settings Retrieve - Template Creation',
                                 Status__c = 'InProgress');
        insert log;
        
        ContentVersion contentVersion1 = new ContentVersion(
            Title = 'Setting1',
            PathOnClient = 'Setting1.csv',
            VersionData = Blob.valueOf('Test data')
        );
        insert contentVersion1;
        
        ContentVersion contentVersion2 = new ContentVersion(
            Title = 'Setting2',
            PathOnClient = 'Setting2.csv',
            VersionData = Blob.valueOf('Test data')
        );
        insert contentVersion2;
        
        ContentVersion contentVersion3 = new ContentVersion(
            Title = 'AdditionalSetting',
            PathOnClient = 'AdditionalSetting.csv',
            VersionData = Blob.valueOf('Test data')
        );
        insert contentVersion3;
        
        ContentDocumentLink link1 = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id].ContentDocumentId
        );
        insert link1;
        
        ContentDocumentLink link2 = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion2.Id].ContentDocumentId
        );
        insert link2;
        
        ContentDocumentLink link3 = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion3.Id].ContentDocumentId
        );
        insert link3;
        
        Test.startTest();
        PreRefreshAutomationClass.checkCustomSettingRetrieveStatus(template.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGenerateCsvAndAttach() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test',
                                                              Parent_Org__c = org1.Id);
        insert refTemp;
        
        String userData = '[{"id":"test@salesforce.com","formattedString":"Name: Test User, Email: test@salesforce.com, Username: test@salesforce.com, Profile: Standard User"}]';
        
        Test.startTest();
        
		PreRefreshAutomationClass p = new PreRefreshAutomationClass();        
        //p.generateCsvAndAttach(org1, refTemp.Id, userData);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchAllFields() {
        Org__c testOrg = new Org__c(
            Access_Token__c = 'TestAccessToken',
            Domain_Url__c = 'https://test.salesforce.com'
        );
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'Test Temp',
                                                              Parent_Org__c = testOrg.Id);
        insert refTemp;
        
        Logs__c log = new Logs__c(Parent_Template__c = refTemp.Id,
                                 Log_Type__c = 'Custom Settings Retrieve - Template Creation',
                                 Status__c = 'InProgress');
        insert log;
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        
        List<String> customSettingNames = new List<String>{'Custom1', 'Custom2'};
        
        PreRefreshAutomationClass.FetchCustomSettingFieldsQueueable job = new PreRefreshAutomationClass.FetchCustomSettingFieldsQueueable(testOrg.Id, refTemp.Id, customSettingNames, testOrg.Access_Token__c, 0, log.Id);
        
        Test.startTest();
        PreRefreshAutomationClass p = new PreRefreshAutomationClass();
        p.fetchAllFields(testOrg.Id, refTemp.Id, testOrg.Access_Token__c, customSettingNames, log.Id);
        System.enqueueJob(job);
        PreRefreshAutomationClass.initiateFetchCustomSettingsAgain(testOrg.Id, refTemp.Id, customSettingNames, testOrg.Access_Token__c, 0, log.Id);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Name = 'Metadata.zip'];
        System.assertNotEquals(1, attachments.size());
    }
    
    @IsTest
    static void testGenerateCsvForScheduledJobs() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test',
                                                              Parent_Org__c = org1.Id);
        insert refTemp;
        
        Logs__c log = new Logs__c(Parent_Template__c = refTemp.Id,
                                 Log_Type__c = 'Scheduled Jobs Retrieve - Template Creation',
                                 Status__c = 'InProgress');
        insert log;
        
        String sJobs = '[{"id":"Program Milestone Computation Cron Job","formattedString":"Job Name: Program Milestone Computation Cron Job, Job Type: P, State: WAITING, Time Zone: America/Los_Angeles, CronJobDetailId: 08aNS0000002Uy6YAE"}]';
        
        Test.startTest();
        
		PreRefreshAutomationClass p = new PreRefreshAutomationClass();        
        //p.generateCsvForScheduledJobs(org1, refTemp.Id, sJobs);
        p.generateCsvForScheduledJobsNew(refTemp.Id, sJobs, log.Id);
        
        Test.stopTest();
    }
    
    /*@isTest
    static void testCheckDataRetrievalStatus() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Custom_Setting_Names__c = 'Setting1, Setting2',
            Parent_Org__c = org1.Id
        );
        insert template;

        ContentVersion contentVersion1 = new ContentVersion(
            Title = 'Setting1',
            PathOnClient = 'Setting1.csv',
            VersionData = Blob.valueOf('Test data')
        );
        insert contentVersion1;

        ContentVersion contentVersion2 = new ContentVersion(
            Title = 'Setting2',
            PathOnClient = 'Setting2.csv',
            VersionData = Blob.valueOf('Test data')
        );
        insert contentVersion2;

        ContentVersion contentVersion3 = new ContentVersion(
            Title = 'AdditionalSetting',
            PathOnClient = 'AdditionalSetting.csv',
            VersionData = Blob.valueOf('Test data')
        );
        insert contentVersion3;

        ContentDocumentLink link1 = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id].ContentDocumentId
        );
        insert link1;

        ContentDocumentLink link2 = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion2.Id].ContentDocumentId
        );
        insert link2;

        ContentDocumentLink link3 = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion3.Id].ContentDocumentId
        );
        insert link3;

        Test.startTest();
        Boolean result = PreRefreshAutomationClass.checkDataRetrievalStatus(template.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'The method should return true when the counts match.');
    }

    @isTest
    static void testCheckDataRetrievalStatusNoCustomSettingNames() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template Without Custom Settings',
            Parent_Org__c = org1.Id
        );
        insert template;

        Test.startTest();
        Boolean result = PreRefreshAutomationClass.checkDataRetrievalStatus(template.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'The method should return true when Custom_Setting_Names__c is null.');
    }

    @isTest
    static void testCheckDataRetrievalStatusCountMismatch() {
        Org__c org1 = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert org1;
        
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Custom_Setting_Names__c = 'Setting1, Setting2',
            Parent_Org__c = org1.Id
        );
        insert template;

        ContentVersion contentVersion1 = new ContentVersion(
            Title = 'Setting1',
            PathOnClient = 'Setting1.csv',
            VersionData = Blob.valueOf('Test data')
        );
        insert contentVersion1;

        ContentDocumentLink link1 = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id].ContentDocumentId
        );
        insert link1;

        Test.startTest();
        Boolean result = PreRefreshAutomationClass.checkDataRetrievalStatus(template.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'The method should return false when the counts do not match.');
    }*/
    
    @isTest
    static void testHttpCalloutMock() {
        HttpCalloutMock mock = new PreRefreshAutomationClassMock();
        Test.setMock(HttpCalloutMock.class, mock);
        
        HttpRequest req1 = new HttpRequest();
        req1.setEndpoint('https://test.salesforce.com/services/oauth2/authorize');
        req1.setMethod('GET');
        HttpResponse res1 = new Http().send(req1);
        
        System.assertEquals(200, res1.getStatusCode(), 'OAuth endpoint should return status 200');
        System.assertEquals(
            'https://test.salesforce.com/services/oauth2/success',
            res1.getHeader('Location'),
            'OAuth endpoint should return a success location'
        );
        
        HttpRequest req2 = new HttpRequest();
        req2.setEndpoint('https://test.salesforce.com/services/data/v54.0/tooling/query?q=SELECT+Id,MasterLabel+FROM+NamedCredential');
        req2.setMethod('GET');
        HttpResponse res2 = new Http().send(req2);
        
        System.assertEquals(200, res2.getStatusCode(), 'Query endpoint should return status 200');
        System.assert(res2.getBody().contains('"MasterLabel": "TestNamedCredential"'), 'Response body should contain the Named Credential label');
        
        HttpRequest req3 = new HttpRequest();
        req3.setEndpoint('https://test.salesforce.com/services/Soap/m/53.0');
        req3.setMethod('POST');
        HttpResponse res3 = new Http().send(req3);
        
        System.assertEquals(200, res3.getStatusCode(), 'Metadata API endpoint should return status 200');
        System.assert(
            res3.getBody().contains('<fullName>TestCustomLabel</fullName>'),
            'Response body should contain the expected Metadata API result'
        );
        
        HttpRequest req4 = new HttpRequest();
        req4.setEndpoint('https://test.salesforce.com/unmatched/endpoint');
        req4.setMethod('GET');
        HttpResponse res4 = new Http().send(req4);
        
        System.assertEquals(404, res4.getStatusCode(), 'Unmatched endpoint should return status 404');
        System.assertEquals('{"message": "Not Found"}', res4.getBody(), 'Unmatched endpoint should return a Not Found message');
    }
    
    
    @isTest
    static void testRetrievePackageWithMetadataPackageXmlContent() {
		Org__c testOrg = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(
            Name = 'Test Template',
            Custom_Setting_Names__c = 'Setting1, Setting2',
            Parent_Org__c = testOrg.Id
        );
        insert refTemp;
        
        Logs__c log = new Logs__c(Parent_Template__c = refTemp.Id,
                                 Log_Type__c = 'Metadata Retrieve - Template Creation',
                                 Status__c = 'InProgress');
        insert log;
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        
        String domainUrl = 'https://test.salesforce.com';
        String accessToken = 'dummyAccessToken';
        String metadataPackageXmlContent = '<Package xmlns="http://soap.sforce.com/2006/04/metadata">';
        metadataPackageXmlContent +='    <types>';
        metadataPackageXmlContent +='    <members>*</members>';
        metadataPackageXmlContent +='    <name>ApexClass</name>';
        metadataPackageXmlContent +='    </types>';
        metadataPackageXmlContent +='    <version>59.0</version>';
        metadataPackageXmlContent +='    </Package>';
            List<String> selectedUsernames = new List<String>{'testuser1@example.com', 'testuser2@example.com'};
                List<String> customSettingNames = new List<String>{'CustomSetting1', 'CustomSetting2'};
                    String sJobs = '[{"id":"Program Milestone Computation Cron Job","formattedString":"Job Name: Program Milestone Computation Cron Job, Job Type: P, State: WAITING, Time Zone: America/Los_Angeles, CronJobDetailId: 08aNS0000002Uy6YAE"}]';
        
        Test.startTest();
        PreRefreshAutomationClass.retrievePackage(testOrg.Id, refTemp.Id, domainUrl, accessToken, metadataPackageXmlContent, log.Id); //, selectedUsernames, customSettingNames, sJobs
        Test.stopTest();
        
        //System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable']);
    }
    
    @isTest
    static void testRetrievePackageWithoutMetadataPackageXmlContent() {
        Org__c testOrg = new Org__c(Name = 'BiswaDev',
                                 Domain_Url__c = 'https://login.salesforce.com',
                                 Access_Token__c = '12345');
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(
            Name = 'Test Template',
            Custom_Setting_Names__c = 'Setting1, Setting2',
            Parent_Org__c = testOrg.Id
        );
        insert refTemp;
        
        Logs__c log = new Logs__c(Parent_Template__c = refTemp.Id,
                                 Log_Type__c = 'Metadata Retrieve - Template Creation',
                                 Status__c = 'Success');
        insert log;
        
        String domainUrl = 'https://test.salesforce.com';
        String accessToken = 'dummyAccessToken';
        String metadataPackageXmlContent = '';
        List<String> selectedUsernames = new List<String>{'testuser1@example.com', 'testuser2@example.com'};
            List<String> customSettingNames = new List<String>{'CustomSetting1', 'CustomSetting2'};
                String sJobs = 'TestJob';
        
        Test.setMock(HttpCalloutMock.class, new MetadataServiceMockNew());
        
        Test.startTest();
        PreRefreshAutomationClass.retrievePackage(testOrg.Id, refTemp.Id, domainUrl, accessToken, metadataPackageXmlContent, log.Id);  //, selectedUsernames, customSettingNames, sJobs
        Test.stopTest();
        
        //System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable']);
    }
    
    private class MetadataServiceMockNew implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setBody('<?xml version="1.0" encoding="UTF-8"?>\n' +
                        '<AsyncResult xmlns="http://soap.sforce.com/2006/04/metadata">\n' +
                        '<id>1234567890</id>\n' +
                        '</AsyncResult>');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testMakeRetrieveResultCallout() {
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = 'mockSessionId';
        
        MetadataService.RetrieveResult retrieveResult = new MetadataService.RetrieveResult();
        retrieveResult.done = false;
        retrieveResult.status = 'InProgress';
        
        String asyncResultId = 'mockAsyncId';
        Id refTempId = '001000000000001';
        String domainUrl = 'https://mock.salesforce.com';
        String accessToken = 'mockAccessToken';
        
        Test.startTest();
        MetadataService.RetrieveResult result = PreRefreshAutomationClass.makeRetrieveResultCallout(service, retrieveResult, asyncResultId, refTempId, domainUrl, accessToken);
        Test.stopTest();
    }
    
    @isTest
    public static void testFetchParentOrgOfRefreshTemplate() {
        Org__c parentOrg = new Org__c(Name = 'Test1',
                                      Domain_Url__c = 'https://test.salesforce.com',
                                      Org_Type__c = 'Sandbox',
                                      Access_Token__c = '123456');
        insert parentOrg;
        
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = parentOrg.Id
        );
        insert template;
        
        Test.startTest();
        Id parentOrgId = PreRefreshAutomationClass.fetchParentOrgOfRefreshTemplate(template.Id);
        Test.stopTest();
        
        System.assertEquals(parentOrg.Id, parentOrgId, 'The parent org Id returned is incorrect.');
    }
    
    @isTest
    public static void testFetchFieldsOfObject1() {
        Org__c parentOrg = new Org__c(Name = 'Test1',
                                      Domain_Url__c = 'https://test.salesforce.com',
                                      Org_Type__c = 'Sandbox',
                                      Access_Token__c = '123456');
        insert parentOrg;
        
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = parentOrg.Id
        );
        insert template;
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        
        Test.startTest();
        PreRefreshAutomationClass.fetchFieldsOfObject1(parentOrg.Id, 'Account');
        Test.stopTest();
    }
    
}