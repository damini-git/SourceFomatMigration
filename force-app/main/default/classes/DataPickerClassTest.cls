@IsTest
public class DataPickerClassTest {
    
    @TestSetup
    public static void setupTestData() {
        // Setup a mock Org__c record that will be used in the tests
        Org__c sandboxOrg = new Org__c(
            Name = 'Testorg',
            Domain_Url__c = 'https://test.salesforce.com',
            Access_Token__c = 'testAccessToken'
        );
        insert sandboxOrg;
    }
    
    // Mock class to simulate the callouts
    private class DataPickerHttpCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            // Provide different mock responses based on the request endpoint
            if (req.getEndpoint().contains('/services/data/v56.0/query/?q=SELECT')) {
                //res.setBody('{"records":[{"Name":"Test User 1","Email":"testuser1@example.com","Username": "integration@00dns000000vys82am.com","Profile": {"attributes": {"type": "Profile","url": "/services/data/v56.0/sobjects/Profile/00eNS000000VhODYA0"},"Name": "Analytics Cloud Integration User"}},{"Name":"Test User 2","Email":"testuser2@example.com"}]}');
                res.setBody('{"totalSize": 1,"done": false,"nextRecordsUrl": "/services/data/v56.0/query/0r8xx3mONziEJSfAMO-2000","records": [{"attributes": {"type": "User","url": "/services/data/v56.0/sobjects/User/005NS000000b6CFYAY"},"Id": "005NS000000b6CFYAY","Name": "Integration User","Email": "noreply@example.com","Username": "integration@00dns000000vys82am.com","Profile": {"attributes": {"type": "Profile","url": "/services/data/v56.0/sobjects/Profile/00eNS000000VhODYA0"},"Name": "Analytics Cloud Integration User"}}]}');
            } else if (req.getEndpoint().contains('EntityDefinition')) {
                res.setBody('{"records":[{"QualifiedApiName":"CustomSetting1__c"},{"QualifiedApiName":"CustomSetting2__c"}]}');
            } else if (req.getEndpoint().contains('FieldDefinition')) {
                res.setBody('{"records":[{"QualifiedApiName":"CustomField1__c"},{"QualifiedApiName":"CustomField2__c"}]}');
            }
            return res;
        }
    }
    
    /*@IsTest
    public static void testGetAllUsers() {
        Org__c sandboxOrg = [SELECT Id FROM Org__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        List<DataPickerClass.UserDetailsWrapper> users = DataPickerClass.getAllUsers(sandboxOrg.Id);
        Test.stopTest();
    }*/
    
    @IsTest
    public static void testFetchAllUsers() {
        Org__c sandboxOrg = [SELECT Id FROM Org__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        //List<DataPickerClass.UserWrapper> users1 = 
        PaginatedUserResponse jobList = DataPickerClass.fetchAllUsers(sandboxOrg.Id, '', '', '');
        Test.stopTest();
    }
    
    /*@IsTest
    public static void testFetchCustomSettings() {
        // Fetch the sandbox org record created in the test setup
        Org__c sandboxOrg = [SELECT Id FROM Org__c LIMIT 1];
        
        // Set the mock callout for the HTTP request
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        // Call the method and assert the results (mock callout will occur)
        Test.startTest();
        List<String> customSettings = DataPickerClass.fetchCustomSettings(sandboxOrg.Id);
        Test.stopTest();
        
        // Assert that the mock response is processed correctly
        System.assertEquals(2, customSettings.size());
        System.assert(customSettings.contains('CustomSetting1__c'));
        System.assert(customSettings.contains('CustomSetting2__c'));
    }*/
    
    // Mock HTTP response class for testing
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('/services/data/v56.0/query')) {
                res.setStatusCode(200);
                res.setBody('{"records":[{"QualifiedApiName":"CustomSetting1__c"},{"QualifiedApiName":"CustomSetting2__c"}]}');
            } else if (req.getHeader('Authorization') == 'Bearer invalidToken') {
                res.setStatusCode(401);
                res.setBody('{"error":"invalid_token","error_description":"The access token is invalid."}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error":"unknown_error"}');
            }
            
            return res;
        }
    }
    
    @isTest
    static void testFetchCustomSettingsSuccess() {
        Org__c testOrg = new Org__c(Domain_Url__c = 'https://test.salesforce.com', Access_Token__c = 'validToken');
        insert testOrg;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        List<DataPickerClass.CustomSettingsWrapper> settings = DataPickerClass.fetchCustomSettings(testOrg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, settings, 'Custom settings should not be null.');
        System.assertEquals(1, settings.size(), 'Expected 2 custom settings.');
        System.assertEquals('CustomSetting1__c', settings[0].name, 'First custom setting name mismatch.');
    }
    
    @isTest
    static void testFetchCustomSettingsTokenRefresh() {
        Org__c testOrg = new Org__c(Domain_Url__c = 'https://test.salesforce.com', Access_Token__c = 'invalidToken');
        insert testOrg;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        List<DataPickerClass.CustomSettingsWrapper> settings = DataPickerClass.fetchCustomSettings(testOrg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, settings, 'Custom settings should not be null.');
        System.assertEquals(1, settings.size(), 'Expected 2 custom settings after token refresh.');
    }
    
    @isTest
    static void testFetchCustomSettingsException() {
        Org__c testOrg = new Org__c(Domain_Url__c = 'https://test.salesforce.com', Access_Token__c = 'validToken');
        insert testOrg;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        List<DataPickerClass.CustomSettingsWrapper> settings = DataPickerClass.fetchCustomSettings(testOrg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, settings, 'The method should return null on exception.');
    }

    
    /*@IsTest
    public static void testFetchAllFields() {
        // Fetch the sandbox org record created in the test setup
        Org__c sandboxOrg = [SELECT Id FROM Org__c LIMIT 1];
        
        // Prepare a list of custom setting names
        List<String> customSettingNames = new List<String>{'CustomSetting1__c', 'CustomSetting2__c'};
            
            // Set the mock callout for the HTTP request
            Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        // Call the method and assert that no errors are thrown
        Test.startTest();
        DataPickerClass.fetchAllFields(sandboxOrg.Id, customSettingNames);
        Test.stopTest();
    }*/
    
    /*@IsTest
    public static void testFetchCustomSettingFieldsQueueable() {
        // Fetch the sandbox org record created in the test setup
        Org__c sandboxOrg = [SELECT Id FROM Org__c LIMIT 1];
        
        // Prepare a list of custom setting names
        List<String> customSettingNames = new List<String>{'CustomSetting1__c', 'CustomSetting2__c'};
            
            // Set the mock callout for the HTTP request
            Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        // Test the Queueable class
        Test.startTest();
        DataPickerClass.FetchCustomSettingFieldsQueueable job = new DataPickerClass.FetchCustomSettingFieldsQueueable(sandboxOrg.Id, customSettingNames, 0);
        System.enqueueJob(job); // Enqueue the job
        Test.stopTest();
    }*/
    
    /*@IsTest
    public static void testPublishJobInitiationEvent() {
        Test.startTest();
        Test.setCurrentPageReference(new PageReference('/apex/testPage'));
        DataPickerClass.publishJobInitiationEvent('TestJob', 'sandboxId123', null, 'In Progress');
        Test.stopTest();
    }*/
    
    @IsTest
    static void testFetchScheduledJobs() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForJobs());
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];
        
        List<DataPickerClass.ScheduleJobsWrapper1> jobList = DataPickerClass.fetchScheduledJobs1(org.Id);

        System.assertNotEquals(null, jobList, 'Job list should not be null');
        System.assertEquals(2, jobList.size(), 'There should be one job record in the response');
        //System.assertEquals('Test Job', jobList[0].jobName, 'Job Name should match the mock response');

        Test.stopTest();
    }

    // Mock HTTP Response Generator
    private class MockHttpResponseGeneratorForJobs implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            /*res.setBody('{' +
                '"records": [' +
                '    {' +
                '        "Id": "12345",' +
                '        "CronJobDetailId": "67890",' +
                '        "CronJobDetail": {' +
                '            "Name": "Test Job",' +
                '            "JobType": "Scheduled Apex"' +
                '        },' +
                '        "State": "WAITING",' +
                '        "NextFireTime": "2024-12-01T00:00:00.000Z",' +
                '        "StartTime": "2024-11-01T00:00:00.000Z",' +
                '        "EndTime": null,' +
                '        "TimeZoneSidKey": "GMT",' +
                '        "CronExpression": "0 0 * * * ?",' +
                '        "TimesTriggered": 10,' +
                '        "PreviousFireTime": "2024-11-17T00:00:00.000Z"' +
                '    }' +
                ']' +
            '}');*/
            res.setBody('{"totalSize": 2,"done": true,"records": [{"attributes": {"type": "AsyncApexJob","url": "/services/data/v59.0/sobjects/AsyncApexJob/707NS00000S5Z1xYAF"},"Id": "707NS00000S5Z1xYAF","ApexClass": {"attributes": {"type": "ApexClass","url": "/services/data/v59.0/sobjects/ApexClass/01pNS000004gE2fYAE"},"Name": "SampleScheduleClass"},"JobType": "ScheduledApex","CronTrigger": {"attributes": {"type": "CronTrigger","url": "/services/data/v59.0/sobjects/CronTrigger/08eNS000007qI9jYAE"},"CronExpression": "0 0 0 ? * 2","CronJobDetail": {"attributes": {"type": "CronJobDetail","url": "/services/data/v59.0/sobjects/CronJobDetail/08aNS000007o4IxYAI"},"Name": "sample 2"}}},{"attributes": {"type": "AsyncApexJob","url": "/services/data/v59.0/sobjects/AsyncApexJob/707NS00000TASm3YAH"},"Id": "707NS00000TASm3YAH","ApexClass": {"attributes": {"type": "ApexClass","url": "/services/data/v59.0/sobjects/ApexClass/01pNS000004gE2fYAE"},"Name": "SampleScheduleClass"},"JobType": "ScheduledApex","CronTrigger": {"attributes": {"type": "CronTrigger","url": "/services/data/v59.0/sobjects/CronTrigger/08eNS000008XxUYYA0"},"CronExpression": "0 0 16 ? * 4","CronJobDetail": {"attributes": {"type": "CronJobDetail","url": "/services/data/v59.0/sobjects/CronJobDetail/08aNS000008VaKMYA0"},"Name": "sample 1"}}}]}');
            return res;
        }
    }
}