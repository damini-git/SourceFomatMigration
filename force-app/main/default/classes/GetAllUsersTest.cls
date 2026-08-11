@isTest
public class GetAllUsersTest {
    Public static List<Id> userIds = new List<Id> {'005NS000000b6CFYAM','005NS000000b6CFYAY'};
    Public static List<Id> testuserIds = new List<Id> {'005NS000000b6CFYAM'};
    //Public static List<Map<String, string>>emailList = new List<Map<String, string>>();
        
    @TestSetup
    public static void setupTestData() {
            Org__c org = new Org__c(
            Name = 'Testorg',
            Domain_Url__c = 'https://test.salesforce.com',
            Access_Token__c = 'testAccessToken'
        );
        insert org;
        
        Refresh_Template__c rt = new Refresh_Template__c();
        rt.name = 'Test Template';
        rt.Parent_Org__c = org.id;
        insert rt;
        
        Logs__c log = new Logs__c();
        log.Log_Type__c = 'User Email Validation - Post Refresh';
        log.JobStatus__c = 'Open';
        log.Parent_Template__c = rt.id;
        Insert log;
        
        Logs__c log1 = new Logs__c();
        log1.Log_Type__c = 'User Email Validation - Post Refresh';
        log1.JobStatus__c = 'JobComplete';
        log1.Parent_Template__c = rt.id;
        Insert log1;
        
        Org__c org1 = new Org__c();
        org1.Name = 'TestOrg1';
        insert org1;
        
        Refresh_Template__c rt1 = new Refresh_Template__c();
        rt1.name = 'Test Template1';
        rt1.Parent_Org__c = org1.id;
        insert rt1;
        
        
    }
    
    @IsTest
    public static void testFetchAllUsers() {
        string usersType = 'Active Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        PaginatedUserResponse jobList = GetAllUsers.fetchAllUsers(rt.Id, null, 'A', null,usersType);
        Test.stopTest();
    }
    @IsTest
    public static void testFetchAllUsersSort() {
        string usersType = 'Active Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        PaginatedUserResponse jobList = GetAllUsers.fetchAllUsers(rt.Id, null, null, 'Integration Use1r',usersType);
        Test.stopTest();
    }
    @IsTest
    public static void testFetchAllUsers1() {
        string usersType = 'InActive Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        PaginatedUserResponse jobList = GetAllUsers.fetchAllUsers(rt.Id, null, 'A', null,usersType);
        Test.stopTest();
    }
    @IsTest
    public static void testFetchAllUsers1Sort() {
        string usersType = 'InActive Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        PaginatedUserResponse jobList = GetAllUsers.fetchAllUsers(rt.Id, null, null, 'Integration Use1r',usersType);
        Test.stopTest();
    }
    @IsTest
    public static void testFetchAllUsers2() {
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        PaginatedUserResponse jobList = GetAllUsers.fetchAllUsers(rt.Id, null, 'A', '',usersType);
        Test.stopTest();
    }
    @IsTest
    public static void testFetchAllUsers2Sort() {
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        PaginatedUserResponse jobList = GetAllUsers.fetchAllUsers(rt.Id, null, null, 'Integration Use1r',usersType);
        Test.stopTest();
    }
    @IsTest
    public static void executeDataPassword() {
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        GetAllUsers.executeData(rt.Id, testuserIds, null, 'Reset User Password - Post Refresh');
        Test.stopTest();
    }
    @IsTest
    public static void executeDataDeactivation() {
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        GetAllUsers.executeData(rt.Id, userIds, null, 'User Deactivation - Post Refresh');
        Test.stopTest();
    }
    @IsTest
    public static void executeDataDeactivationExceptionHandling() {
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        system.debug('Temp Id--->>'+rt.Id);
        
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock1());
        
        Test.startTest();
        
        GetAllUsers.executeData(rt.Id, userIds, null, 'User Deactivation - Post Refresh');
        Test.stopTest();
    }
    @IsTest
    public static void executeDataActivation() {
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        GetAllUsers.executeData(rt.Id, userIds, null, 'User Activation - Post Refresh');
        Test.stopTest();
    }
    @IsTest
    public static void executeDataActivationExceptionHandling() {
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        system.debug('Temp Id--->>'+rt.Id);
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock1());
        
        Test.startTest();
        GetAllUsers.executeData(rt.Id, userIds, null, 'User Activation - Post Refresh');
        Test.stopTest();
    }
    @IsTest
    public static void executeEmailValidation() {
        List<Map<String, string>>emailList = new List<Map<String, string>>();
        Map<String, String> user1 = new Map<String, String>();
        user1.put('userId', 'user1');
        user1.put('emailId', 'user1@@gmail.com.invalid');
        emailList.add(user1);

        Map<String, String> user2 = new Map<String, String>();
        user2.put('userId', 'user2');
        user2.put('emailId', 'user2@@gmail.com.invalid');
        emailList.add(user2);
        
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        
        Test.startTest();
        GetAllUsers.executeData(rt.Id, null, emailList, 'User Email Validation - Post Refresh');
        Test.stopTest();
    }
    @IsTest
    public static void executeEmailValidationExceptionHandling() {
        List<Map<String, string>>emailList = new List<Map<String, string>>();
        Map<String, String> user1 = new Map<String, String>();
        user1.put('userId', 'user1');
        user1.put('emailId', 'user1@@gmail.com.invalid');
        emailList.add(user1);

        Map<String, String> user2 = new Map<String, String>();
        user2.put('userId', 'user2');
        user2.put('emailId', 'user2@@gmail.com.invalid');
        emailList.add(user2);
        
        string usersType = 'All Users';
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock1());
        
        Test.startTest();
        GetAllUsers.executeData(rt.Id, null, emailList, 'User Email Validation - Post Refresh');
        Test.stopTest();
    }
    
     @IsTest
    public static void executeBulkApiJobStatusPoller() {
        Map<Id, String> jobIds = new Map<Id, String>();
        Refresh_Template__c rt =[SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c,Parent_Org__r.name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Logs__c log = [SELECT Id,Log_Type__c,JobStatus__c,Parent_Template__c from Logs__c where Parent_Template__c =: rt.id and JobStatus__c = 'Open'];
        string instanceUrl = rt.Parent_Org__r.Domain_Url__c;
        string accessToken ='1234567890';
        string logType = log.Log_Type__c;
        string orgName = rt.Parent_Org__r.name;
            jobIds.put('750D0000000XXXX','User Deactivation');
            DateTime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        Test.startTest();
            BulkApiJobStatusPoller scheduledJob = new BulkApiJobStatusPoller('BulkApiJobPoller',jobIds, instanceUrl, accesstoken,log.Id,orgName,logType);
            String scheduleJobId = system.schedule('BulkApiJobPoller', cronExpression, scheduledJob);
        Test.stopTest();
    }
    
    @IsTest
    public static void executeBulkApiJobStatusPollerJobComplete() {
        Map<Id, String> jobIds = new Map<Id, String>();
        Refresh_Template__c rt =[SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c,Parent_Org__r.name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Logs__c log = [SELECT Id,Log_Type__c,JobStatus__c,Parent_Template__c from Logs__c where Parent_Template__c =: rt.id and JobStatus__c = 'JobComplete'];
        string instanceUrl = rt.Parent_Org__r.Domain_Url__c;
        string accessToken ='1234567890';
        string logType = log.Log_Type__c;
        string orgName = rt.Parent_Org__r.name;
            jobIds.put('750D0000000XXXX','User Deactivation');
            DateTime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
        Test.setMock(HttpCalloutMock.class, new DataPickerHttpCalloutMock());
        Test.startTest();
            BulkApiJobStatusPoller scheduledJob = new BulkApiJobStatusPoller('BulkApiJobPoller',jobIds, instanceUrl, accesstoken,log.Id,orgName,logType);
            String scheduleJobId = system.schedule('BulkApiJobPoller', cronExpression, scheduledJob);
        Test.stopTest();
    }
    
    private class DataPickerHttpCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('/services/data/v56.0/query/?q=SELECT')) {
                //res.setBody('{"records":[{"Name":"Test User 1","Email":"testuser1@example.com","Username": "integration@00dns000000vys82am.com","Profile": {"attributes": {"type": "Profile","url": "/services/data/v56.0/sobjects/Profile/00eNS000000VhODYA0"},"Name": "Analytics Cloud Integration User"}},{"Name":"Test User 2","Email":"testuser2@example.com"}]}');
                res.setBody('{"totalSize": 2,"done": false,"nextRecordsUrl": "/services/data/v56.0/query/0r8xx3mONziEJSfAMO-2000","records": [{"attributes": {"type": "User","url": "/services/data/v56.0/sobjects/User/005NS000000b6CFYAM"},"Id": "005NS000000b6CFYAM","Name": "Integration Use1r","Email": "norepl1y@example.com", "IsActive": false,"Username": "integratio1n@00dns000000vys82am.com","Profile": {"attributes": {"type": "Profile","url": "/services/data/v56.0/sobjects/Profile/00eNS000000VhODYA0"},"Name": "Analytics Cloud Integration User"}},{"attributes": {"type": "User","url": "/services/data/v56.0/sobjects/User/005NS000000b6CFYAY"},"Id": "005NS000000b6CFYAY","Name": "Integration User","Email": "noreply@example.com", "IsActive": true,"Username": "integration@00dns000000vys82am.com","Profile": {"attributes": {"type": "Profile","url": "/services/data/v56.0/sobjects/Profile/00eNS000000VhODYA0"},"Name": "Analytics Cloud Integration User"}}]}');
            }else if (req.getEndpoint().contains('SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('UserBody'+res.getBody());
            }else if (req.getEndpoint().contains('password' )) {
                 res.setBody('{"NewPassword": "b57Naef4P"}');
            }else if (req.getEndpoint().contains('/services/data/v58.0/jobs/ingest') ){
                if (req.getMethod() == 'POST') {
                    res.setStatusCode(201);
                    res.setBody('{"id":"750D0000000XXXX","state":"Open"}');
                } else if (req.getMethod() == 'PUT') {
                    res.setStatusCode(201);
                    res.setBody('{"id":"750D0000000XXXX","state":"InProgress"}');
                } else if (req.getMethod() == 'PATCH') {
                    res.setStatusCode(200);
                    res.setBody('{"id":"750D0000000XXXX","state":"UploadComplete"}');
                }else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive \n "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false" \n "0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false" \n "0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false" \n "0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "Open"}');
                } 
            }
            return res;
        }
    }
    
    private class DataPickerHttpCalloutMock1 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            
            if (req.getEndpoint().contains('/services/data/v56.0/query/?q=SELECT')) {
                //res.setBody('{"records":[{"Name":"Test User 1","Email":"testuser1@example.com","Username": "integration@00dns000000vys82am.com","Profile": {"attributes": {"type": "Profile","url": "/services/data/v56.0/sobjects/Profile/00eNS000000VhODYA0"},"Name": "Analytics Cloud Integration User"}},{"Name":"Test User 2","Email":"testuser2@example.com"}]}');
                res.setBody('{"totalSize": 2,"done": false,"nextRecordsUrl": "/services/data/v56.0/query/0r8xx3mONziEJSfAMO-2000","records": [{"attributes": {"type": "User","url": "/services/data/v56.0/sobjects/User/005NS000000b6CFYAM"},"Id": "005NS000000b6CFYAM","Name": "Integration Use1r","Email": "norepl1y@example.com", "IsActive": false,"Username": "integratio1n@00dns000000vys82am.com","Profile": {"attributes": {"type": "Profile","url": "/services/data/v56.0/sobjects/Profile/00eNS000000VhODYA0"},"Name": "Analytics Cloud Integration User"}},{"attributes": {"type": "User","url": "/services/data/v56.0/sobjects/User/005NS000000b6CFYAY"},"Id": "005NS000000b6CFYAY","Name": "Integration User","Email": "noreply@example.com", "IsActive": true,"Username": "integration@00dns000000vys82am.com","Profile": {"attributes": {"type": "Profile","url": "/services/data/v56.0/sobjects/Profile/00eNS000000VhODYA0"},"Name": "Analytics Cloud Integration User"}}]}');
            }else if (req.getEndpoint().contains('password' )) {
                 res.setBody('{"NewPassword": "b57Naef4P"}');
            }else if (req.getEndpoint().contains('/services/data/v58.0/jobs/ingest') ){
                if (req.getMethod() == 'POST') {
                    res.setStatusCode(400);
                    res.setBody('{"id":"750D0000000XXXX","state":"Open"}');
                } else if (req.getMethod() == 'PUT') {
                    res.setStatusCode(400);
                    res.setBody('{"id":"750D0000000XXXX","state":"InProgress"}');
                } else if (req.getMethod() == 'PATCH') {
                    res.setStatusCode(400);
                    res.setBody('{"id":"750D0000000XXXX","state":"UploadComplete"}');
                }else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(400);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive,"0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(400);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "Open"}');
                } 
            }
            return res;
        }
    }
}