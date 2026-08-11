@isTest
public class PreRefreshUserBackupTest {
    @testSetUp
    static void setUp(){        
        org__c org = new org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'Test';
        org.Access_Token__c = 'testToken';
        org.Sandbox_Info_Id__c = '0G123344';
        insert Org;
        
        Refresh_Template__c rt = new Refresh_Template__c();
        rt.name = 'Test Template';
        rt.Parent_Org__c = org.id;
        insert rt;   
        
        
    }
    
    @isTest
    static void testGetAllUsersWithProfilesAndRoles() {
        logs__c log = new logs__c();
        
        insert log;
        
        Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
        system.debug('sandbox Id------------> '+sid.Id);
        
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
           string accessToken = sid.access_Token__c; 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        PreRefreshUserBackup.getAllUsersWithProfilesAndRoles(rt.id,usernames,accessToken,log.id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    
    @isTest
    static void testGetAllUsersWithProfilesAndRoles1() {
        logs__c log = new logs__c();
        insert log;
        
        Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
        system.debug('sandbox Id------------> '+sid.Id);
        
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
           string accessToken = sid.access_Token__c; 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1());
        PreRefreshUserBackup.getAllUsersWithProfilesAndRoles(rt.id,usernames,accessToken,log.id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    
    @isTest
    static void testGetAllUsersWithProfilesAndRoles2() {
        logs__c log = new logs__c();
        insert log;
        
        Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
        system.debug('sandbox Id------------> '+sid.Id);
        
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
           string accessToken = sid.access_Token__c; 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
        PreRefreshUserBackup.getAllUsersWithProfilesAndRoles(rt.id,usernames,accessToken,log.id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    
    @isTest
    static void testGetAllUsersWithProfilesAndRoles3() {
        logs__c log = new logs__c();
        insert log;
        
        Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
        system.debug('sandbox Id------------> '+sid.Id);
        
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
           string accessToken = sid.access_Token__c; 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator3());
        PreRefreshUserBackup.getAllUsersWithProfilesAndRoles(rt.id,usernames,accessToken,log.id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    
    @isTest
    static void testGetAllUsersWithProfilesAndRoles4() {
        logs__c log = new logs__c();
        insert log;
        
        Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
        system.debug('sandbox Id------------> '+sid.Id);
        
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
           string accessToken = sid.access_Token__c; 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator4());
        PreRefreshUserBackup.getAllUsersWithProfilesAndRoles(rt.id,usernames,accessToken,log.id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    
     /*@isTest
    static void testSaveJSONContent() {
        List<Map<String, Object>> usersList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => '005xx000001Sv6cAAC',
                'Username' => 'jdoe@example.com'
            }
        };
            
           Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        Test.startTest();
        system.debug(sid.Id);
        PreRefreshUserBackup.saveJSONContent(rt.id,'Test User Export', usersList);
        Test.stopTest();
    }*/
    
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public String responseBody;
 
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User')){
                res.setBody('{"records":[' +
                            '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}},' +
                            '{"Id": "005xx000001Sv6cAAG", "Name": "J Doe", "FirstName": "J", "LastName": "Doe", "Email": "jdoe@example.com", "Alias": "jdoe", "Username": "jodoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}'+
                            ']}');
                system.debug('UserBody'+res.getBody());
            }else if (req.getEndpoint().contains('/services/data/v59.0/query/?q=SELECT+Id,Name,DeveloperName+FROM+Group')){
                res.setBody('{"records":[' +
                            '{"Id": "00Gxx0000000N3wEAE", "Name": "005xx000001Sv6cAAC", "DeveloperName": "Group1"}' +
                            ']}');
                system.debug('GroupBody'+res.getBody());
            }else if (req.getEndpoint().contains('/services/data/v59.0/query/?q=SELECT+Id,GroupId,UserOrGroupId,group.DeveloperName+FROM+GroupMember+WHERE+GroupId+IN')){
                res.setBody('{"records": [{"Id": "011Ig000000c923IAA","GroupId": "00Gxx0000000N3wEAE","UserOrGroupId": "005xx000001Sv6cAAC","Group": {"DeveloperName":"Chairmans_Group"}}]}');
                system.debug('GroupMemberBody'+res.getBody());
            }
            else if (req.getEndpoint().contains('SELECT+Id,AssigneeId,Assignee.Name,Assignee.Username,PermissionSetId,PermissionSet.Name,PermissionSetGroup.DeveloperName+From+PermissionSetAssignment+Order+By+Assignee.Name+ASC')){
                res.setBody('{"records":[' +
                            '{"AssigneeId": "005xx000001Sv6cAAC", "Assignee": {"Username": "jdoe@example.com","Name":"John Doe"}, "PermissionSet": {"Name": "Read Only"}, "PermissionSetGroup": {"DeveloperName": "PSG1"}}' +
                            ']}');
                system.debug('PermissionSetAssignmentBody'+res.getBody());
            }
            return res;
        }
    }
    public class MockHttpResponseGenerator1 implements HttpCalloutMock {
        public String responseBody;
 
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            if (req.getEndpoint().contains('SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User')){
                res.setBody('{"records":[' +
                            '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}},' +
                            '{"Id": "005xx000001Sv6cAAG", "Name": "J Doe", "FirstName": "J", "LastName": "Doe", "Email": "jdoe@example.com", "Alias": "jdoe", "Username": "jodoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}'+
                            ']}');
                system.debug('UserBody'+res.getBody());
            }
            return res;
        }
    }
    public class MockHttpResponseGenerator2 implements HttpCalloutMock {
        public String responseBody;
 
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User')){
                res.setBody('{"records":[' +
                            '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}},' +
                            '{"Id": "005xx000001Sv6cAAG", "Name": "J Doe", "FirstName": "J", "LastName": "Doe", "Email": "jdoe@example.com", "Alias": "jdoe", "Username": "jodoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}'+
                            ']}');
                res.setStatusCode(200);
                system.debug('UserBody'+res.getBody());
            }else{
                res.setStatusCode(400);
            }
            return res;
        }
    }
    public class MockHttpResponseGenerator3 implements HttpCalloutMock {
        public String responseBody;
 
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User')){
                res.setBody('{"records":[' +
                            '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}},' +
                            '{"Id": "005xx000001Sv6cAAG", "Name": "J Doe", "FirstName": "J", "LastName": "Doe", "Email": "jdoe@example.com", "Alias": "jdoe", "Username": "jodoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}'+
                            ']}');
                res.setStatusCode(200);
                system.debug('UserBody'+res.getBody());
            }else if (req.getEndpoint().contains('/services/data/v59.0/query/?q=SELECT+Id,Name,DeveloperName+FROM+Group')){
                res.setBody('{"records":[' +
                            '{"Id": "00Gxx0000000N3wEAE", "Name": "005xx000001Sv6cAAC", "DeveloperName": "Group1"}' +
                            ']}');
                res.setStatusCode(200);
                system.debug('GroupBody'+res.getBody());
            }else{
                res.setStatusCode(400);
            }
            return res;
        }
    }
    public class MockHttpResponseGenerator4 implements HttpCalloutMock {
        public String responseBody;
 
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User')){
                res.setBody('{"records":[' +
                            '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}},' +
                            '{"Id": "005xx000001Sv6cAAG", "Name": "J Doe", "FirstName": "J", "LastName": "Doe", "Email": "jdoe@example.com", "Alias": "jdoe", "Username": "jodoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}'+
                            ']}');
                res.setStatusCode(200);
                system.debug('UserBody'+res.getBody());
            }else if (req.getEndpoint().contains('/services/data/v59.0/query/?q=SELECT+Id,Name,DeveloperName+FROM+Group')){
                res.setBody('{"records":[' +
                            '{"Id": "00Gxx0000000N3wEAE", "Name": "005xx000001Sv6cAAC", "DeveloperName": "Group1"}' +
                            ']}');
                res.setStatusCode(200);
                system.debug('GroupBody'+res.getBody());
            }else if (req.getEndpoint().contains('/services/data/v59.0/query/?q=SELECT+Id,GroupId,UserOrGroupId,group.DeveloperName+FROM+GroupMember+WHERE+GroupId+IN')){
                res.setBody('{"records": [{"Id": "011Ig000000c923IAA","GroupId": "00Gxx0000000N3wEAE","UserOrGroupId": "005xx000001Sv6cAAC","Group": {"DeveloperName":"Chairmans_Group"}}]}');
                res.setStatusCode(200);
                system.debug('GroupMemberBody'+res.getBody());
            }else{
                res.setStatusCode(400);
            }
            return res;
        }
    }
}