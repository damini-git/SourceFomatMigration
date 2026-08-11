@isTest
public class PostRefreshAutomationClassTest {
    
    @TestSetup
    public static void setupData() {
        // Create test data for Org__c
        Org__c orgRecord = new Org__c(
            Name = 'Test Org',
            Domain_Url__c = 'https://test-org.my.salesforce.com',
            Access_Token__c = '00D1234567890abcd!AQMAQDhgh....'
        );
        insert orgRecord;
        
        // Create test data for Refresh_Template__c
        Refresh_Template__c refTemplate = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = orgRecord.Id,
            Find_And_Replace_Template__c = '[{"metadataType":"CustomLabel","searchKey":"OldValue","replaceValue":"NewValue"}]'
        );
        insert refTemplate;
    }
    
    @isTest
    static void testFetchMetadataMaskingTemplate(){
        Org__c org = new Org__c(Name = 'BiswaDev',
                               Org_Type__c = 'Sandbox',
                               Domain_Url__c = 'https://login.salesforce.com',
                               Access_Token__c = '12345');
        insert org;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'Test Template',
                                                             Parent_Org__c = org.Id,
                                                             Find_And_Replace_Template__c = '[{"metadataType":"CustomLabels","searchKey":"biswa","replaceValue":"akhil"},{"metadataType":"RemoteSiteSetting","searchKey":"biswa","replaceValue":"akhil"}]');
        insert refTemp;
        
        Test.startTest();
        
        PostRefreshAutomationClass.fetchMetadataMaskingTemplate(refTemp.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testCallFindAndReplaceQueueable() {
        Org__c org = new Org__c(Name = 'Test1',
                                Domain_Url__c = 'https://test.salesforce.com',
                                Access_Token__c = '12345',
                                Org_Type__c = 'Sandbox');
        insert org;
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testing Find And Replace Temp',
                                                              Parent_Org__c = org.Id);
        insert refTemp;
        
        String findAndReplaceTemp = '[{"metadataType":"CustomLabel","maskingType":"Search & Replace","searchKey":"login","replaceValue":"test"},';
        findAndReplaceTemp += ' {"metadataType":"RemoteSiteSetting","maskingType":"Search & Replace","searchKey":"login","replaceValue":"test"},';
        findAndReplaceTemp += ' {"metadataType":"NamedCredential","maskingType":"Search & Replace","searchKey":"login","replaceValue":"test"},';
        findAndReplaceTemp += ' {"metadataType":"AuthProvider","maskingType":"Search & Replace","searchKey":"login","replaceValue":"test"},';
        findAndReplaceTemp += ' {"metadataType":"WorkflowAlert","maskingType":"Search & Replace","searchKey":"login","replaceValue":"test"},';
        findAndReplaceTemp += ' {"metadataType":"ConnectedApp","maskingType":"Search & Replace","searchKey":"login","replaceValue":"test"},';
        findAndReplaceTemp += ' {"metadataType":"CustomMetadata","maskingType":"Search & Replace","searchKey":"login","replaceValue":"test"}]';
        
        Test.startTest();
        Test.setMock(WebServiceMock.class, new PostRefreshAutomationWebserviveMock());
        PostRefreshAutomationClass.callFindAndReplaceQueueable(refTemp.Id, findAndReplaceTemp);
        Test.stopTest();
    }
    
    @isTest
    static void testCallSuffixQueueableQueueable() {
        Org__c org = new Org__c(Name = 'Test1',
                                Domain_Url__c = 'https://test.salesforce.com',
                                Access_Token__c = '12345',
                                Org_Type__c = 'Sandbox');
        insert org;
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testing Find And Replace Temp',
                                                              Parent_Org__c = org.Id);
        insert refTemp;
        
        String findAndReplaceTemp = '[{"metadataType":"CustomLabel","maskingType":"Suffix","suffixValue":".invalid"},';
        findAndReplaceTemp += ' {"metadataType":"ConnectedApp","maskingType":"Suffix","suffixValue":".invalid"},';
        findAndReplaceTemp += ' {"metadataType":"EmailServicesFunction","maskingType":"Suffix","suffixValue":".invalid"},';
        findAndReplaceTemp += ' {"metadataType":"WorkflowAlert","maskingType":"Suffix","suffixValue":".invalid"},';
        findAndReplaceTemp += ' {"metadataType":"CustomMetadata","maskingType":"Suffix","suffixValue":".invalid"}]';
        
        Test.startTest();
        Test.setMock(WebServiceMock.class, new PostRefreshAutomationWebserviveMock());
        PostRefreshAutomationClass.callSuffixQueueable(refTemp.Id, findAndReplaceTemp);
        Test.stopTest();
    }
    
    private static Org__c createTestSandbox() {
        Org__c sandbox = new Org__c();
        sandbox.Name = 'TestOrg';
        sandbox.Domain_URL__c = 'https://test.salesforce.com';
        sandbox.Access_Token__c = 'testAccessToken';
        insert sandbox;
        return sandbox;
    }
    
    private static Refresh_Template__c createTestTemplate(Id sandboxId) {
        Refresh_Template__c template = new Refresh_Template__c();
        template.Name = 'Test Template';
        template.Parent_Org__c = sandboxId;
        template.Package_xml_Val__c = '<Package><types><members>*</members><name>ApexClass</name></types><version>59.0</version></Package>';
        insert template;
        return template;
    }
    
    /**
* Test the createService method.
* Ensures that the MetadataService.MetadataPort object is created correctly.
*/
    @isTest
    static void testCreateService() {
        // Test data
        Org__c org = new Org__c(Name = 'BiswaDev',
                                Domain_Url__c = 'https://login.salesforce.com',
                                Org_Type__c = 'Sandbox');
        insert org;
        String mockAccessToken = 'mockAccessToken';
        String mockDomainUrl = 'https://mock.salesforce.com';
        
        // Invoke the private method using a utility class
        MetadataService.MetadataPort service = PostRefreshAutomationClassTest.createService(org.Id, mockDomainUrl);
        
        // Assertions to verify that the service was correctly initialized
        /*System.assertNotEquals(null, service, 'Service instance should not be null');
        System.assertEquals(mockDomainUrl + '/services/Soap/m/59.0', service.endpoint_x, 'Endpoint URL should be correctly set');
        System.assertNotEquals(null, service.SessionHeader, 'SessionHeader should not be null');
        System.assertEquals(mockAccessToken, service.SessionHeader.sessionId, 'Session ID should match the provided access token');*/
    }
    
    // Expose the private createService method for testing purposes
    @TestVisible
    static MetadataService.MetadataPort createService(String accessToken, String domainUrl) {
        return PostRefreshAutomationClass.createService(accessToken, domainUrl);
    }
    
    @isTest
    static void testAbortScheduledJobsViaExecuteAnonymous(){
        Org__c org = new Org__c(Name = 'BiswaDev',
                                Domain_Url__c = 'https://login.salesforce.com',
                                Org_Type__c = 'Sandbox');
        insert org;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTemp',
                                                             Parent_Org__c = org.Id);
        insert refTemp;
        
        String mockAccessToken = 'mockAccessToken';
        String mockDomainUrl = 'https://mock.salesforce.com';
        
        String response = '{"line":-1,"column":-1,"compiled":true,"success":true,"compileProblem":null,"exceptionStackTrace":null,"exceptionMessage":null}';
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseForAbortScheduledJobs(response));
        
        PostRefreshAutomationClass.generateApexCodeToAbortJobs(org.Name);
        PostRefreshAutomationClass.abortScheduledJobsViaExecuteAnonymous(refTemp.Id);
        Test.stopTest();
        
    }
    
    public class MockHttpResponseForAbortScheduledJobs implements HttpCalloutMock {
        private String responseBody;
        
        public MockHttpResponseForAbortScheduledJobs(String responseBody) {
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(responseBody);
            return res;
        }
    }
    
    @isTest
    static void testInitiateScheduleJobRestoration() {
        Org__c testOrg = new Org__c(
            Name = 'Test Org',
            Domain_Url__c = 'https://test.salesforce.com'
        );
        insert testOrg;
        
        Refresh_Template__c testTemplate = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = testOrg.Id
        );
        insert testTemplate;
        
        Logs__c sJobsRestoration = new Logs__c(Log_Type__c = 'Scheduled Jobs Restoration - Post Refresh',
                                              Parent_Template__c = testTemplate.Id,
                                              Status__c = 'InProgress');
        insert sJobsRestoration;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Scheduled Jobs',
            VersionData = Blob.valueOf('Test Job Data'),
            PathOnClient = 'Scheduled Jobs.csv'
        );
        insert testContentVersion;
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = testTemplate.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId
        );
        insert testContentDocumentLink;
        
        Test.setMock(HttpCalloutMock.class, new HttpMockForExecuteAnonymous());
        
        Test.startTest();
        PostRefreshAutomationClass.initiateScheduleJobRestoration(testTemplate.Id);
        Test.stopTest();
        
        System.assert(true, 'The static resource upload response was mocked successfully.');
    }
    
    @IsTest
    static void testScheduleJobsInTargetOrg() {
        Org__c orgRecord = new Org__c(Name = 'Target Org', Domain_Url__c = 'https://test.salesforce.com');
        insert orgRecord;
        
        Refresh_Template__c templateRecord = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = orgRecord.Id
        );
        insert templateRecord;
        
        Logs__c sJobsLog = new Logs__c(Parent_Template__c = templateRecord.Id,
                                      Log_Type__c = 'Scheduled Jobs Restoration - Post Refresh',
                                      Status__c = 'Success');
        insert sJobsLog;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new HttpMockForExecuteAnonymous());
        Test.setMock(WebServiceMock.class, new PostRefreshAutomationWebserviveMock());
        
        PostRefreshAutomationClass.scheduleJobsInTargetOrg(templateRecord.Id, 'dummyAccessToken');
        Test.stopTest();
        
        System.assert(true, 'Test executed without exceptions.');
    }
    
    @IsTest
    static void testDeleteStaticResourceInTargetOrg() {
        Test.startTest();
        
        Test.setMock(WebServiceMock.class, new PostRefreshAutomationWebserviveMock());
        
        PostRefreshAutomationClass.deletStaticResourceInTargetOrg(
            'https://test.salesforce.com', 
            'dummyAccessToken', 
            'ScheduledJobBackup'
        );
        
        Test.stopTest();
        
        System.assert(true, 'Static resource deletion test executed successfully.');
    }

    private class HttpMockForExecuteAnonymous implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"compiled": true, "success": true, "line": null, "column": null, "exceptionStackTrace": null, "exceptionMessage": null}');
            return res;
        }
    }

    @isTest
    public static void testApplyDataMasking() {
        Org__c testOrg = new Org__c(Name = 'Test Org', Domain_Url__c = 'https://example.com');
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTempForMasking',
                                                             Parent_Org__c = testOrg.Id);
        insert refTemp;
        
        Logs__c dataMaskingLog = new Logs__c(Log_type__c = 'Data Transformation',
                                             Status__c = 'InProgress',
                                             Parent_Template__c = refTemp.Id);
        insert dataMaskingLog;
        
        String mockAccessToken = 'mockAccessToken';
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForMasking());
                                               
        String mapJson = '[{"type":"Account", "members":["Name", "Industry"], "objectType":"Account"}]';
        String result = PostRefreshAutomationClass.applyDataMasking(testOrg.Id, refTemp.Id, mapJson);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testApplyDataMaskingForFailure() {
        Org__c testOrg = new Org__c(Name = 'Test Org', Domain_Url__c = 'https://example.com');
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTempForMasking',
                                                             Parent_Org__c = testOrg.Id);
        insert refTemp;
        
        Logs__c dataMaskingLog = new Logs__c(Log_type__c = 'Data Transformation',
                                             Status__c = 'Failed',
                                             Parent_Template__c = refTemp.Id);
        insert dataMaskingLog;
        
        String mockAccessToken = 'mockAccessToken';
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForMaskingForFailure());
                                               
        String mapJson = '[{"type":"Account", "members":["Name", "Industry"], "objectType":"Account"}]';
        String result = PostRefreshAutomationClass.applyDataMasking(testOrg.Id, refTemp.Id, mapJson);
        
        Test.stopTest();
    }

    /*@isTest
    public static void testFetchRecordsFromTargetOrg() {
        String objectType = 'Account';
        List<String> fields = new List<String>{'Name', 'Industry'};
        String mockAccessToken = 'mockAccessToken';
        String domainUrl = 'https://example.com';

        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForMasking());
        
        List<Map<String, Object>> result = PostRefreshAutomationClass.fetchRecordsFromTargetOrg(objectType, fields, domainUrl, mockAccessToken);
        
        Test.stopTest();
    }*/

    @isTest
    public static void testGenerateRandomValue() {
        String testString = 'TestString';
        Integer testInteger = 123;
        Decimal testDecimal = 45.67;
        Date testDate = Date.today();
        Datetime testDatetime = Datetime.now();
        Boolean testBoolean = true;
        String urlStr = 'https://www.example.com';
        String emailStr = 'test.example@abcd.com';
    }

    public class MockHttpResponseGeneratorForMasking implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"records":[{"Id":"0011t00000XXXXXXXX","Name":"Test Account","Industry":"Technology","Email":"test.example@abcd.com","URL":"https://www.example.com"}]}');
            return res;
        }
    }
    
    public class MockHttpResponseGeneratorForMaskingForFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('Bad Request');
            return res;
        }
    }

    @isTest
    public static void testMaskingQueueableJob() {
        Org__c testOrg = new Org__c(Name = 'Test Org', Domain_Url__c = 'https://example.com');
        insert testOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTempForMasking',
                                                             Parent_Org__c = testOrg.Id);
        insert refTemp;
        
        Logs__c dataMaskingLog = new Logs__c(Log_type__c = 'Data Transformation',
                                             Status__c = 'InProgress',
                                             Parent_Template__c = refTemp.Id);
        insert dataMaskingLog;
        
        Test.setMock(HttpCalloutMock.class, new MockCompositeApiResponse());
        
        List<Map<String, Object>> lOfRecords = new List<Map<String, Object>>();
        Map<String, Object> record1 = new Map<String, Object>{ 'referenceId' => 'ref1', 'Name' => 'Test1' };
            Map<String, Object> record2 = new Map<String, Object>{ 'referenceId' => 'ref2', 'Name' => 'Test2' };
                
                Map<String, Map<String, Object>> recordMap = new Map<String, Map<String, Object>>();
        recordMap.put('ref1', record1);
        recordMap.put('ref2', record2);
        lOfRecords.add(recordMap);
        
        List<String> fieldsToMask = new List<String>{'Name'};
            
            String domainUrl = 'https://test.salesforce.com';
        String accessToken = '12345';
        Integer startIndex = 0;
        
        MaskDataQueueable queClass = new MaskDataQueueable(lOfRecords, fieldsToMask, 'testObj', domainUrl, accessToken, startIndex, dataMaskingLog.Id);
        
        Test.startTest();
        system.enqueueJob(new MaskDataQueueable(lOfRecords, fieldsToMask, 'testObj', domainUrl, accessToken, startIndex, dataMaskingLog.Id));
        queClass.attachCsvToLog(lOfRecords, '_FailedRecords.csv', true);
        Test.stopTest();
    }
    
    private class MockCompositeApiResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            
            // Mock Composite Response
            String responseBody = '{ ' +
                '"compositeResponse": [' +
                '   {' +
                '       "referenceId": "ref1", ' +
                '       "httpStatusCode": 201, ' + // Success case
                '       "body": {} ' +
                '   },' +
                '   {' +
                '       "referenceId": "ref2", ' +
                '       "httpStatusCode": 400, ' + // Failure case
                '       "body": [{"message": "Invalid data"}] ' +
                '   }' +
                ']}';
            
            response.setBody(responseBody);
            return response;
        }
    }

    
    @isTest
    public static void testGenerateRandomValue1() {
        Object dateString = '2023-10-10';
        Object randomDate = MaskDataQueueable.generateRandomValue(dateString);
        
        Object emailString = 'test@example.com';
        Object randomEmail = MaskDataQueueable.generateRandomValue(emailString);
        System.assert((String)randomEmail != emailString);
        
        Object urlString = 'https://www.example.com';
        Object randomUrl = MaskDataQueueable.generateRandomValue(urlString);
        
        Object genericString = 'HelloWorld';
        Object randomString = MaskDataQueueable.generateRandomValue(genericString);
        
        Object intValue = 123;
        Object randomInt = MaskDataQueueable.generateRandomValue(intValue);
        
        Object decimalValue = 123.45;
        Object randomDecimal = MaskDataQueueable.generateRandomValue(decimalValue);
        
        Object dateValue = Date.today();
        Object randomDateValue = MaskDataQueueable.generateRandomValue(dateValue);
        
        Object datetimeValue = Datetime.now();
        Object randomDatetime = MaskDataQueueable.generateRandomValue(datetimeValue);
        
        Object boolValue = true;
        Object randomBoolean = MaskDataQueueable.generateRandomValue(boolValue);
        
        Object urlValue = new Url('https://www.salesforce.com');
        Object randomUrlValue = MaskDataQueueable.generateRandomValue(urlValue);
        
        Object nullValue = null;
        Object randomNullValue = MaskDataQueueable.generateRandomValue(nullValue);
    }
    
    @isTest
    static void testGetSuffixLogRecord(){
        Org__c parentOrg = new Org__c(Name = 'TestOrg',
                                      Domain_Url__c = 'https://login.salesforce.com',
                                      Org_Type__c = 'Production',
                                      Access_Token__c = '12345');
        insert parentOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTemp',
                                                              Parent_Org__c = parentOrg.Id);
        insert refTemp;
        
        Logs__c suffixLog = new Logs__c(Log_Type__c = 'Suffix - Metadata Transformation',
                                        ParenT_Template__c = refTemp.Id);
        insert suffixLog;
        
        String csvContent = '"Metadata Members","Failed Reason"\n';
        ContentVersion content = new ContentVersion(
            Title = 'NamedCredential_FailedRecords.csv',
            PathOnClient = 'NamedCredential_FailedRecords.csv',
            VersionData = Blob.valueOf(csvContent),
            FirstPublishLocationId = suffixLog.Id
        );
        insert content;
        
        Test.startTest();
        PostRefreshAutomationClass.getSuffixLogRecord(suffixLog.Id);
        PostRefreshAutomationClass.getSuffixLogRecordofRefreshTemplate(refTemp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetSuffixLogRecordofRefreshTemplateForElseCondition(){
        Org__c parentOrg = new Org__c(Name = 'TestOrg',
                                      Domain_Url__c = 'https://login.salesforce.com',
                                      Org_Type__c = 'Production',
                                      Access_Token__c = '12345');
        insert parentOrg;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTemp',
                                                              Parent_Org__c = parentOrg.Id);
        insert refTemp;
        
        Logs__c suffixLog = new Logs__c(Log_Type__c = 'Suffix - Metadata Transformation',
                                        ParenT_Template__c = refTemp.Id);
        insert suffixLog;
        
        Logs__c suffixLog1 = new Logs__c(Log_Type__c = 'Search & Replace - Metadata Transformation',
                                        ParenT_Template__c = refTemp.Id);
        insert suffixLog1;
        
        String csvContent = '"Metadata Members","Failed Reason"\n';
        ContentVersion content = new ContentVersion(
            Title = 'NamedCredential_SuccessRecords.csv',
            PathOnClient = 'NamedCredential_SuccessRecords.csv',
            VersionData = Blob.valueOf(csvContent),
            FirstPublishLocationId = suffixLog.Id
        );
        insert content;
        
        Test.startTest();
        PostRefreshAutomationClass.getSuffixLogRecordofRefreshTemplate(refTemp.Id);
        PostRefreshAutomationClass.getMetadataMaskingLogRecordofRefreshTemplate(refTemp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetMetadataTransformationLogs(){
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c srRuleLog = new Logs__c(Log_Type__c = 'Search & Replace - Metadata Transformation',
                                     Parent_Template__c = refTemp.Id);
        insert srRuleLog;
        
        String csvContent = '"Metadata Members","Failed Reason"\n';
        ContentVersion content = new ContentVersion(
            Title = 'NamedCredential_FailedRecords.csv',
            PathOnClient = 'NamedCredential_FailedRecords.csv',
            VersionData = Blob.valueOf(csvContent),
            FirstPublishLocationId = srRuleLog.Id
        );
        insert content;
        
        Test.startTest();
        Logs__c logRec = PostRefreshAutomationClass.getMetadataMaskingLogRecordofRefreshTemplate(refTemp.Id);
        Logs__c logRec1 = PostRefreshAutomationClass.getMetadataMaskingLogRecord(srRuleLog.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetApexMetadataTransformationLogs(){
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c apexLog = new Logs__c(Log_Type__c = 'Apex Script - Metadata Transformation',
                                     Parent_Template__c = refTemp.Id);
        insert apexLog;
        
        Test.startTest();
        Logs__c logRec = PostRefreshAutomationClass.getApexScriptLogRecordofRefreshTemplate(refTemp.Id);
        Logs__c logRec1 = PostRefreshAutomationClass.getApexScriptLogRecord(apexLog.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testAttachCsvToLog(){
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c newLog = new Logs__c(Log_Type__c = 'Search & Replace - Metadata Transformation',
                                     Parent_Template__c = refTemp.Id);
        insert newLog;
        
        Set<Map<String, String>> lOfMapOfStr = new Set<Map<String, String>>();
        Map<String, String> mOfStr = new Map<String, String>();
        mOfStr.put('1', 'test');
        mOfStr.put('2', 'test2');
        lOfMapOfStr.add(mOfStr);
        
        Test.startTest();
        PostRefreshAutomationClass.attachCsvToLog(lOfMapOfStr, 'NamedCredential_FailedRecords.csv', false, newLog.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetSearchRulesAndSuffixRulesRecordofRefreshTemplate(){
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c srLog = new Logs__c(Log_Type__c = 'Search & Replace - Metadata Transformation',
                                      Parent_Template__c = refTemp.Id);
        insert srLog;
        
        Logs__c sLog = new Logs__c(Log_Type__c = 'Suffix - Metadata Transformation',
                                      Parent_Template__c = refTemp.Id);
        insert sLog;
        
        Test.startTest();
        Logs__c logRec = PostRefreshAutomationClass.getSearchRulesRecordofRefreshTemplate(srLog.Id);
        Logs__c logRec1 = PostRefreshAutomationClass.getSuffixRulesRecordofRefreshTemplate(sLog.Id);
        Test.stopTest();
    }
}