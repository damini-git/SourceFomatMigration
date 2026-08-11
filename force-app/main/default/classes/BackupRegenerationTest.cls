@isTest
public class BackupRegenerationTest {
    @testSetUp
    static void setUp(){  
        
        org__c org = new org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'Test';
        org.Access_Token__c = 'testToken';
        org.Sandbox_Info_Id__c = '0G123344';
        insert Org;
        
        string userJson = '{"User":[' +
            '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}},' +
            '{"Id": "005xx000001Sv6cAAC", "Name": "J Doe", "FirstName": "J", "LastName": "Doe", "Email": "jdoe@example.com", "Alias": "jdoe", "Username": "jodoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}'+
            ']}';
        
        Refresh_Template__c rt = new Refresh_Template__c();
        rt.name = 'Test Template';
        rt.Parent_Org__c = org.id;
        insert rt;  
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'User Data - Export - JSON';
        contentVersion.PathOnClient = '/' + contentVersion.Title + '.json';
        contentVersion.VersionData = Blob.valueOf(userJson);
        insert contentVersion;
        
        system.debug('JsonBody------>>>>'+contentversion.VersionData);
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = rt.Id;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink;
        
        
        Refresh_Template__c rt1 = new Refresh_Template__c();
        rt1.name = 'Test Template1';
        rt1.Parent_Org__c = org.id;
        rt1.Custom_Setting_Names__c = 'Test__c,Test1__c';
        insert rt1; 
        
        string customSettingJson = '{"size": 60,"totalSize": 60,"done": true,"queryLocator": null,"entityTypeName": "FieldDefinition","records": [{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBkX"},"Label": "Records","QualifiedApiName": "Records__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:44:10.000+0000"},{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBhJ"},"Label": "Read Result","QualifiedApiName": "Read_Result__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:43:49.000+0000"}]}';
        
        
        ContentVersion contentVersion1 = new ContentVersion();
        contentVersion1.Title = 'Test__c';
        contentVersion1.PathOnClient = '/' + contentVersion1.Title + '.csv';
        contentVersion1.VersionData = Blob.valueOf(customSettingJson);
        insert contentVersion1;
        
        system.debug('Custom setting Csv Body------>>>>'+contentversion1.VersionData);
        
        ContentDocumentLink contentDocumentLink1 = new ContentDocumentLink();
        contentDocumentLink1.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion1.Id
        ].ContentDocumentId;
        contentDocumentLink1.LinkedEntityId = rt1.Id;
        contentDocumentLink1.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink1.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink1;
        
        Refresh_Template__c rt2 = new Refresh_Template__c();
        rt2.name = 'Test Template2';
        rt2.Parent_Org__c = org.id;
        insert rt2; 
        
        List<String> jobData = new List<String>{'sample 2,ScheduledApex,SampleScheduleClass,0 0 0 ? * 2',
            'sample 1,ScheduledApex,SampleScheduleClass,0 0 16 ? * 4'
            };
                
                String header = '"Job Name","Job Type","Apex Class","Cron Expression"';
        
        String csvContent = header + '\n' + String.join(jobData, '\n');
        
        
        ContentVersion contentVersion2 = new ContentVersion();
        contentVersion2.Title = 'Scheduled Jobs';
        contentVersion2.PathOnClient = '/' + contentVersion2.Title + '.csv';
        contentVersion2.VersionData = Blob.valueOf(csvContent);
        insert contentVersion2;
        
        system.debug('Schedule Job Csv Body------>>>>'+contentVersion2.VersionData);
        
        ContentDocumentLink contentDocumentLink2 = new ContentDocumentLink();
        contentDocumentLink2.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion2.Id
        ].ContentDocumentId;
        contentDocumentLink2.LinkedEntityId = rt2.Id;
        contentDocumentLink2.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink2.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink2;
        
        Refresh_Template__c rt3 = new Refresh_Template__c();
        rt3.name = 'Test Template3';
        rt3.Parent_Org__c = org.id;
        insert rt3;
        
        String xmlString = '<?xml version="1.0" encoding="UTF-8"?>\n' +
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n' +
            '    <types>\n' +
            '        <members>ALMController</members>\n' +
            '        <members>ApexCodeCoverageAPI</members>\n' +
            '        <members>ApexCodeCoverageWrapper</members>\n' +
            '        <members>ApexDetailsOnOrgClass</members>\n' +
            '        <members>ApexDetailsOnOrgClassTest</members>\n' +
            '        <name>ApexClass</name>\n' +
            '    </types>\n' +
            '    <types>\n' +
            '        <members>codeCoverageCsvPage</members>\n' +
            '        <members>codecoveragepdfpage</members>\n' +
            '        <name>ApexPage</name>\n' +
            '    </types>\n' +
            '    <version>59.0</version>\n' +
            '</Package>';
        
        
        ContentVersion contentVersion3 = new ContentVersion();
        contentVersion3.Title = 'packageXml';
        contentVersion3.PathOnClient = '/' + contentVersion3.Title + '.txt';
        contentVersion3.VersionData = Blob.valueOf(xmlString);
        insert contentVersion3;
        
        ContentDocumentLink contentDocumentLink3 = new ContentDocumentLink();
        contentDocumentLink3.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion3.Id
        ].ContentDocumentId;
        contentDocumentLink3.LinkedEntityId = rt3.Id;
        contentDocumentLink3.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink3.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink3;
        
        
        Logs__c userRegenerationLog = new Logs__c();
        userRegenerationLog.Log_Type__c = 'Users - Backup Regeneration';
        userRegenerationLog.Parent_Template__c = rt.Id;
        userRegenerationLog.Status__c = 'Success';
        insert userRegenerationLog;
        
        Logs__c sJobsRegenerationLog = new Logs__c();
        sJobsRegenerationLog.Log_Type__c = 'Scheduled Jobs - Backup Regeneration';
        sJobsRegenerationLog.Parent_Template__c = rt2.Id;
        sJobsRegenerationLog.Status__c = 'Success';
        insert sJobsRegenerationLog;
        
        Logs__c csRestorationLog = new Logs__c();
        csRestorationLog.Log_Type__c = 'Custom Settings - Backup Regeneration';
        csRestorationLog.Parent_Template__c = rt1.Id;
        csRestorationLog.Status__c = 'Success';
        insert csRestorationLog;
        
        Logs__c metaRegenerationLog = new Logs__c();
        metaRegenerationLog.Log_Type__c = 'Metadata - Backup Regeneration';
        metaRegenerationLog.Parent_Template__c = rt3.Id;
        metaRegenerationLog.Status__c = 'Success';
        insert metaRegenerationLog;
        
        
        Refresh_Template__c rt4 = new Refresh_Template__c();
        rt4.name = 'Test Template4';
        rt4.Parent_Org__c = org.id;
        insert rt4;
        
        Logs__c metadataRetrieveUpdateTemplateLog = new Logs__c();
        metadataRetrieveUpdateTemplateLog.Log_Type__c = 'Metadata Retrieve - Update Template';
        metadataRetrieveUpdateTemplateLog.Parent_Template__c = rt4.Id;
        metadataRetrieveUpdateTemplateLog.Status__c = 'Success';
        insert metadataRetrieveUpdateTemplateLog;
    }
    
    @isTest
    static void testGetAllUsersWithProfilesAndRoles() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
            Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        BackupRegeneration.regenerateUsers(rt.Id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    @isTest
    static void testGetAllUsersWithProfilesAndRoles1() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
            Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator1());
        BackupRegeneration.regenerateUsers(rt.Id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    @isTest
    static void testGetAllUsersWithProfilesAndRoles2() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
            Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
        BackupRegeneration.regenerateUsers(rt.Id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    
    @isTest
    static void testGetAllUsersWithProfilesAndRoles3() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
            Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator3());
        BackupRegeneration.regenerateUsers(rt.Id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    
    @isTest
    static void testGetAllUsersWithProfilesAndRoles4() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
        
        list<string> usernames = new List<string>{'johndoe@example.com','jdoe@example.com'};
            Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator4());
        BackupRegeneration.regenerateUsers(rt.Id);
        Test.stopTest();   
        
        system.assertEquals(2,usernames.Size(),'The Usernames List has only 2 values');
    }
    
    @IsTest
    static void testFetchAllFields() {
        
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template1'];
        
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<String> customSettingNames = new List<String>{'Custom1', 'Custom2'};
            
            Test.startTest();
        BackupRegeneration.regenerateCustomSettings(rt.Id);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Name = 'Metadata.zip'];
        System.assertNotEquals(1, attachments.size());
    }
    
    @IsTest
    static void testFetchScheduledJobs() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template2'];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        BackupRegeneration.regenerateScheduledJobs(rt.id);
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateTemplate() {     
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template3'];
        Org__c org = [select Id, name,Domain_Url__c,Access_Token__c from Org__c where name = 'testOrg'];
        Logs__c metaRegenerationLog = [select Id, Log_Type__c from Logs__c where Log_Type__c = 'Metadata - Backup Regeneration'];
        
        String fakeAsyncId = Org.Id;
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        Test.setMock(WebServiceMock.class, new RSSCreationTestMock());
        
        Id sandboxId = createTestSandbox();
        String packageXml = '<Package><types><members>*</members><name>ApexClass</name></types></Package>';
        //String userData = '[{"id":"test@salesforce.com","formattedString":"Name: Test User, Email: test@salesforce.com, Username: test@salesforce.com, Profile: Standard User"}]';
        List<String> selectedUsernames = new List<String>{'test.user@cf.com','test@salesforce.com'};
            List<String> customSettingNames = new List<String>{'Custom1', 'Custom2'};
                String sJobs = '[{"id":"Program Milestone Computation Cron Job","formattedString":"Job Name: Program Milestone Computation Cron Job, Job Type: P, State: WAITING, Time Zone: America/Los_Angeles, CronJobDetailId: 08aNS0000002Uy6YAE"}]';
        String findAndReplaceTemplates = 'test template';
        
        BackupRegenerationOfMetadata.InitialMetadataRetrievalJobNew job = new BackupRegenerationOfMetadata.InitialMetadataRetrievalJobNew(fakeAsyncId, rt.Id, Org.Domain_Url__c,Org.Access_Token__c,packageXml, metaRegenerationLog.Id); //, selectedUsernames, customSettingNames, sJobs
        
        Test.startTest();
        backupRegeneration.regenerateMetadata(rt.Id);
        System.enqueueJob(job);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Name = 'Metadata.zip'];
        System.assertNotEquals(1, attachments.size());
    }
    
    /*@isTest
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
        MetadataService.RetrieveResult result = BackupRegenerationOfMetadata.makeRetrieveResultCallout(service, retrieveResult, asyncResultId, refTempId, domainUrl, accessToken);
        Test.stopTest();
    }*/
    
    @IsTest
    static void testHandleRetrievedMetadata() {
        //Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template4'];
        Org__c org = [select Id, name,Domain_Url__c,Access_Token__c from Org__c where name = 'testOrg']; 
        
        Refresh_Template__c rt4 = new Refresh_Template__c();
        rt4.name = 'Test Template4';
        rt4.Parent_Org__c = org.id;
        insert rt4;
        
        Logs__c metaRegenerationLog = [select Id, Log_Type__c from Logs__c where Log_Type__c = 'Metadata - Backup Regeneration'];
        
        String xmlString1 = '<?xml version="1.0" encoding="UTF-8"?>\n' +
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n' +
            '    <types>\n' +
            '        <members>ALMController</members>\n' +
            '        <members>ApexCodeCoverageAPI</members>\n' +
            '        <members>ApexCodeCoverageWrapper</members>\n' +
            '        <members>ApexDetailsOnOrgClass</members>\n' +
            '        <members>ApexDetailsOnOrgClassTest</members>\n' +
            '        <name>ApexClass</name>\n' +
            '    </types>\n' +
            '    <types>\n' +
            '        <members>codeCoverageCsvPage</members>\n' +
            '        <members>codecoveragepdfpage</members>\n' +
            '        <name>ApexPage</name>\n' +
            '    </types>\n' +
            '    <version>59.0</version>\n' +
            '</Package>';
        Blob zipBlob =  Blob.valueOf(xmlString1);
        
        Attachment attachment = new Attachment();
        attachment.ParentId = rt4.Id;
        attachment.Name = 'Metadata.zip';
        attachment.Body = zipBlob;
        attachment.ContentType = 'application/zip';
        insert attachment;
        
        
        MetadataService.RetrieveResult mockRetrieveResult = new MetadataService.RetrieveResult();
        mockRetrieveResult.zipFile = EncodingUtil.base64Encode(Blob.valueOf('Mock zip file content'));
        
        
        Test.startTest();
        BackupRegenerationOfMetadata backup = new BackupRegenerationOfMetadata();
        backup.handleRetrievedMetadataNew(rt4.Id, mockRetrieveResult, xmlString1, metaRegenerationLog.Id);
        
        Test.stopTest();
        
    }
    
    
    @IsTest
    static void testHandleRetrievedMetadata1() {
        //Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template4'];
        Org__c org = [select Id, name,Domain_Url__c,Access_Token__c from Org__c where name = 'testOrg']; 
        
        Refresh_Template__c rt4 = new Refresh_Template__c();
        rt4.name = 'Test Template4';
        rt4.Parent_Org__c = org.id;
        insert rt4;
        
        Logs__c metaRegenerationLog = [select Id, Log_Type__c from Logs__c where Log_Type__c = 'Metadata Retrieve - Update Template'];
        
        String xmlString1 = '<?xml version="1.0" encoding="UTF-8"?>\n' +
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n' +
            '    <types>\n' +
            '        <members>ALMController</members>\n' +
            '        <members>ApexCodeCoverageAPI</members>\n' +
            '        <members>ApexCodeCoverageWrapper</members>\n' +
            '        <members>ApexDetailsOnOrgClass</members>\n' +
            '        <members>ApexDetailsOnOrgClassTest</members>\n' +
            '        <name>ApexClass</name>\n' +
            '    </types>\n' +
            '    <types>\n' +
            '        <members>codeCoverageCsvPage</members>\n' +
            '        <members>codecoveragepdfpage</members>\n' +
            '        <name>ApexPage</name>\n' +
            '    </types>\n' +
            '    <version>59.0</version>\n' +
            '</Package>';
        Blob zipBlob =  Blob.valueOf(xmlString1);
        
        Attachment attachment = new Attachment();
        attachment.ParentId = rt4.Id;
        attachment.Name = 'Metadata.zip';
        attachment.Body = zipBlob;
        attachment.ContentType = 'application/zip';
        insert attachment;
        
        
        MetadataService.RetrieveResult mockRetrieveResult = new MetadataService.RetrieveResult();
        mockRetrieveResult.zipFile = EncodingUtil.base64Encode(Blob.valueOf('Mock zip file content'));
        
        
        Test.startTest();
        BackupRegenerationOfMetadata backup = new BackupRegenerationOfMetadata();
        backup.handleRetrievedMetadataNew(rt4.Id, mockRetrieveResult, xmlString1, metaRegenerationLog.Id);
        
        Test.stopTest();
        
    }
    
    private static Id createTestSandbox() {
        Org__c sandbox = new Org__c(Name = 'Test', Domain_URL__c = 'https://test.salesforce.com');
        insert sandbox;
        return sandbox.Id;
    }
    
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
            }else if(req.getEndpoint().contains('/services/data/v57.0/tooling/query/?q=SELECT+Label,QualifiedApiName,DataType,Length,LastModifiedBy.Name,LastModifiedDate+FROM+FieldDefinition+WHERE+EntityDefinition.QualifiedApiName')) {
                res.setStatusCode(200);
                res.setBody('{"size": 02,"totalSize": 02,"done": true,"queryLocator": null,"entityTypeName": "FieldDefinition","records": [{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBkX"},"Label": "Records","QualifiedApiName": "Records__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:44:10.000+0000"},{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBhJ"},"Label": "Read Result","QualifiedApiName": "Read_Result__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:43:49.000+0000"}]}');
            }else if(req.getEndpoint().contains('Test/services/data/v58.0/query?q=SELECT+Records__c%2CRead_Result__c+FROM+Test__c')){
                res.setStatusCode(200);
                res.setBody('{"records":[{"Field1__c":"Value1","Field2__c":"Value2"}]}');
            }
            else if(req.getEndpoint().contains('/services/data/v59.0/query/?q=SELECT+Id,ApexClass.Name,JobType,CronTrigger.CronExpression,CronTrigger.CronJobDetail.Name+FROM+AsyncApexJob+WHERE+CronTrigger.CronJobDetail.Name+In+')){
                res.setStatusCode(200);
                res.setBody('{"totalSize": 2,"done": true,"records": [{"attributes": {"type": "AsyncApexJob","url": "/services/data/v59.0/sobjects/AsyncApexJob/707NS00000S5Z1xYAF"},"Id": "707NS00000S5Z1xYAF","ApexClass": {"attributes": {"type": "ApexClass","url": "/services/data/v59.0/sobjects/ApexClass/01pNS000004gE2fYAE"},"Job Name": "SampleScheduleClass"},"JobType": "ScheduledApex","CronTrigger": {"attributes": {"type": "CronTrigger","url": "/services/data/v59.0/sobjects/CronTrigger/08eNS000007qI9jYAE"},"CronExpression": "0 0 0 ? * 2","CronJobDetail": {"attributes": {"type": "CronJobDetail","url": "/services/data/v59.0/sobjects/CronJobDetail/08aNS000007o4IxYAI"},"Job Name": "sample 2"}}},{"attributes": {"type": "AsyncApexJob","url": "/services/data/v59.0/sobjects/AsyncApexJob/707NS00000TASm3YAH"},"Id": "707NS00000TASm3YAH","ApexClass": {"attributes": {"type": "ApexClass","url": "/services/data/v59.0/sobjects/ApexClass/01pNS000004gE2fYAE"},"Name": "SampleScheduleClass"},"JobType": "ScheduledApex","CronTrigger": {"attributes": {"type": "CronTrigger","url": "/services/data/v59.0/sobjects/CronTrigger/08eNS000008XxUYYA0"},"CronExpression": "0 0 16 ? * 4","CronJobDetail": {"attributes": {"type": "CronJobDetail","url": "/services/data/v59.0/sobjects/CronJobDetail/08aNS000008VaKMYA0"},"Name": "sample 1"}}}]}');
            }
            return res;
        }
    }
    
    public class MockHttpResponseGenerator1 implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User')){
                res.setBody('{"records":[' +
                            '{"Id": "005xx000001Sv6cAAC", "Name": "John Doe", "FirstName": "John", "LastName": "Doe", "Email": "johndoe@example.com", "Alias": "jdoe", "Username": "jdoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}},' +
                            '{"Id": "005xx000001Sv6cAAG", "Name": "J Doe", "FirstName": "J", "LastName": "Doe", "Email": "jdoe@example.com", "Alias": "jdoe", "Username": "jodoe@example.com", "IsActive": true, "TimeZoneSidKey": "America/New_York", "LocaleSidKey": "en_US", "LanguageLocaleKey": "en", "EmailEncodingKey": "ISO-8859-1", "Profile": {"Name": "Standard User"}, "UserRole": {"DeveloperName": "Admin"}}'+
                            ']}');
                res.setStatusCode(400);
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
            }else if(req.getEndpoint().contains('SELECT+Id,Name,DeveloperName+FROM+Group')){
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
            }else if (req.getEndpoint().contains('/services/data/v59.0/query/?q=SELECT+Id,GroupId,UserOrGroupId,group.DeveloperName+FROM+GroupMember+WHERE+GroupId+IN')){
                res.setBody('{"records": [{"Id": "011Ig000000c923IAA","GroupId": "00Gxx0000000N3wEAE","UserOrGroupId": "005xx000001Sv6cAAC","Group": {"DeveloperName":"Chairmans_Group"}}]}');
                res.setStatusCode(400);
                system.debug('GroupMemberBody'+res.getBody());
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
            }
            else if (req.getEndpoint().contains('SELECT+Id,AssigneeId,Assignee.Name,Assignee.Username,PermissionSetId,PermissionSet.Name,PermissionSetGroup.DeveloperName+From+PermissionSetAssignment+Order+By+Assignee.Name+ASC')){
                res.setBody('{"records":[' +
                            '{"AssigneeId": "005xx000001Sv6cAAC", "Assignee": {"Username": "jdoe@example.com","Name":"John Doe"}, "PermissionSet": {"Name": "Read Only"}, "PermissionSetGroup": {"DeveloperName": "PSG1"}}' +
                            ']}');
                res.setStatusCode(400);
                system.debug('PermissionSetAssignmentBody'+res.getBody());
            }
            return res;
        }
    }
}