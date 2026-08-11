@isTest
public class PostRefreshUserProvisionTest {
    @testSetUp
    static void setUp(){
        /*Sandbox__c sandbox = new Sandbox__c();
        sandbox.Sandbox_Name__c = 'Test';
        sandbox.Domain_Url__c = 'testUrl.com';
        Test.setMock(HttpCalloutMock.class, new SandboxRSSCreationHandlerMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        insert sandbox;*/
        
        org__c org = new org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'Test';
        org.Access_Token__c = 'testToken';
        org.Sandbox_Info_Id__c = '0G123344';
        insert Org;
        
        Refresh_Template__c rt = new Refresh_Template__c();
        rt.name = 'Test Template';
        //rt.Sandbox__c= sandbox.id;
        rt.Parent_Org__c = org.id;
        insert rt;
        
        //list<string> usernames = new List<string>{'test1.com','test2.com','test3.com'};
    }
    @isTest
    static void testGetAllUsersWithProfilesAndRoles() {
        /*String jsonResponse = '{"records":[' +
                              '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}' +
                              ']}';*/
	   	Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
        system.debug('sandbox Id------------> '+sid.Id);
        
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
       
        
        list<string> usernames = new List<string>{'test1.com','test2.com','test3.com'};
        Test.startTest();
         
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        PostRefreshUserProvision.getAllUsersWithProfilesAndRoles(sid.id,rt.id,usernames);
        Test.stopTest();
     }
   
     @isTest
    static void testGetGroups() {
        String jsonResponse = '{"records":[' +
                              '{"Id": "00Gxx0000000N3wEAE", "Name": "005xx000001Sv6cAAC", "DeveloperName": "Group1"}' +
                              ']}';
        
        String jsonResponse1 = '{"records":[' +
                              '{"Id": "011Ig000000c923IAA", "GroupId": "00Gxx0000000N3wEAE", "UserOrGroupId": "005xx000001Sv6cAAC"}' +
                              ']}';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(jsonResponse1));
        
        List<Map<String, Object>> usersList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => '005xx000001Sv6cAAC',
                'Username' => 'jdoe@example.com'
            }
        };
       Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
           // groupIds.add('00Gxx0000000N3wEAE');
        List<Id> groupIds = new List<Id>{'00Gxx0000000N3wEAE'};
        
             Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
            
        Test.startTest();
        PostRefreshUserProvision.getGroups(sid.Id,rt.Id, usersList);
        //PostRefreshUserProvision.getGroupMembers(sid.Id,groupIds, usersList);
        Test.stopTest();
        
        System.assertNotEquals(0, usersList.size());
        //System.assertEquals(1, usersList[0].get('Groups').size());
        //System.assertEquals('Group1', usersList[0].get('Groups')[0]);
    }
    
    @isTest
    static void testGetGroupMembers() {
        
        /*String jsonResponse = '{"records":[' +
                              '{"Id": "011Ig000000c923IAA", "GroupId": "00Gxx0000000N3wEAE", "UserOrGroupId": "005xx000001Sv6cAAC"}' +
                              ']}';*/

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<Map<String, Object>> usersList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => '005xx000001Sv6cAAC',
                'Username' => 'jdoe@example.com'
            }
        };
       Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
         Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
           // groupIds.add('00Gxx0000000N3wEAE');
        List<Id> groupIds = new List<Id>{'00Gxx0000000N3wEAE'};
        
        Test.startTest();
        PostRefreshUserProvision.getGroupMembers(sid.Id,rt.id,groupIds, usersList);
        Test.stopTest();
        
        System.assertNotEquals(0, usersList.size());
        //System.assertEquals(1, usersList[0].get('Groups').size());
        //System.assertEquals('Group1', usersList[0].get('Groups')[0]);
    }
    
     @isTest
    static void testGetPermsetAndPSG() {
       /* String jsonResponse = '{"records":[' +
                              '{"AssigneeId": "005xx000001Sv6cAAC", "Assignee": {"Username": "jdoe@example.com"}, "PermissionSet": {"Name": "Read Only"}, "PermissionSetGroup": {"DeveloperName": "PSG1"}}' +
                              ']}';*/

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<Map<String, Object>> usersList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Username' => 'jdoe@example.com'
            }
        };
         Org__c sid = [select id, Name,Access_Token__c from org__c where name = 'testOrg' limit 1];
         Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        Test.startTest();
        PostRefreshUserProvision.getPermsetAndPSG(sid.id,rt.id,usersList);
        Test.stopTest();
    }
    
     @isTest
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
        PostRefreshUserProvision.saveJSONContent(sid.id,rt.id,'Test User Export', usersList);
        Test.stopTest();
    }
    
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public String responseBody;
        
        /*public MockHttpResponseGenerator(String responseBody) {
            this.responseBody = responseBody;
        }*/
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User')){
                res.setBody('{"records":[' +
                              '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}' +
                              ']}');
                system.debug('UserBody'+res.getBody());
            }else if (req.getEndpoint().contains('SELECT+AssigneeId,Assignee.Username,PermissionSet.Name,PermissionSetGroup.DeveloperName+FROM+PermissionSetAssignment')){
                res.setBody('{"records":[' +
                              '{"AssigneeId": "005xx000001Sv6cAAC", "Assignee": {"Username": "jdoe@example.com"}, "PermissionSet": {"Name": "Read Only"}, "PermissionSetGroup": {"DeveloperName": "PSG1"}}' +
                              ']}');
                system.debug('PermissionSetAssignmentBody'+res.getBody());
            }else if (req.getEndpoint().contains('SELECT+Id,Name,DeveloperName+FROM+Group')){
                res.setBody('{"records":[' +
                              '{"Id": "00Gxx0000000N3wEAE", "Name": "005xx000001Sv6cAAC", "DeveloperName": "Group1"}' +
                              ']}');
                system.debug('GroupBody'+res.getBody());
            }else if (req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId,group.DeveloperName+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records": [{"Id": "011Ig000000c923IAA","GroupId": "00Gxx0000000N3wEAE","UserOrGroupId": "005xx000001Sv6cAAC","Group": {"DeveloperName":"Chairmans_Group"}}]}');
                system.debug('GroupMemberBody'+res.getBody());
            }
            return res;
        }
    }
}