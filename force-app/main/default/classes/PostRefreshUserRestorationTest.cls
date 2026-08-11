@isTest
public class PostRefreshUserRestorationTest {
@testSetup
    static void dataSetup(){
        org__c org = new org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'https://test.com';
        org.Access_Token__c = 'testToken';
        insert Org;
        
        Refresh_Template__c rt = new Refresh_Template__c();
        rt.name = 'Test Template';
        rt.Parent_Org__c = org.id;
        insert rt;
        
        Refresh_Template__c rt1 = new Refresh_Template__c();
        rt1.name = 'Test Template1';
        rt1.Parent_Org__c = org.id;
        insert rt1;
        
        Refresh_Template__c rt2 = new Refresh_Template__c();
        rt2.name = 'Test Template2';
        rt2.Parent_Org__c = org.id;
        insert rt2;
        
        Logs__c log = new Logs__c();
        log.Log_Type__c = 'Sandbox Refresh';
        log.JobStatus__c = 'Open';
        log.Last_Refreshed_Public_Group_Id__c = '00G6g000002qijCEAQ';
        log.Parent_Template__c = rt.id;
        insert log;
        
        Logs__c log1 = new Logs__c();
        log1.Log_Type__c = 'Sandbox Refresh';
        log1.JobStatus__c = 'JobComplete';
        log1.Last_Refreshed_Public_Group_Id__c = '00G6g000002qijCEAQ';
        log1.Parent_Template__c = rt1.id;
        insert log1;
        
        Logs__c log2 = new Logs__c();
        log2.Log_Type__c = 'Validate Template';
        log2.Status__c = 'InProgress';
        log2.JobStatus__c = 'JobComplete';
        log2.Last_Refreshed_Public_Group_Id__c = '00G6g000002qijCEAQ';
        log2.Parent_Template__c = rt2.id;
        insert log2;
        
        String jsonContent = '{"User":[{"PermissionSetGroup":[{"Name":"PSG123"}],"PermissionSet":[{"Name":"X00ex00000018ozh_128_09_04_12_1"},{"Name":"opspermissionset"},{"Name":"Experience_Profile_Manager"},{"Name":"Opsbridge_Permission_Set"},{"Name":"PSG123"},{"Name":"PS3"},{"Name":"PS2"}],"Groups":["Chairmans_Group","Directors_Group","Payment_Escalation"],"UserRole":{"DeveloperName":"Chairman_Managing_director"},"Profile":{"Name":"System Administrator"},"IsActive":true,"EmailEncodingKey":"UTF-8","LanguageLocaleKey":"en_US","LocaleSidKey":"en_IN","TimeZoneSidKey":"Asia/Kolkata","Username":"jdoe@example.com","Alias":"ARedd","Email":"divyajendu@gmail.com","LastName":"Reddy","FirstName":"Aritra","Name":"Aritra Reddy","Id":"0052w000009hEUXAA2"},{"PermissionSetGroup":[{"Name":"PSG123"}],"PermissionSet":[{"Name":"X00ex00000018ozh_128_09_04_12_1"},{"Name":"opspermissionset"},{"Name":"Experience_Profile_Manager"},{"Name":"Opsbridge_Permission_Set"},{"Name":"PSG123"},{"Name":"PS3"},{"Name":"PS2"}],"Groups":["Chairmans_Group","Directors_Group","Payment_Escalation"],"UserRole":{"DeveloperName":"Chairman_Managing_director"},"Profile":{"Name":"System Administrator"},"IsActive":true,"EmailEncodingKey":"UTF-8","LanguageLocaleKey":"en_US","LocaleSidKey":"en_IN","TimeZoneSidKey":"Asia/Kolkata","Username":"johnydoe@example.com","Alias":"ARedd","Email":"divyajendu@gmail.com","LastName":"Reddy","FirstName":"Aritra","Name":"Aritra Reddy","Id":"0052w000009hEUXAA2"}]}';
        //system.debug('jsonContent-------->>>'+jsonContent);
        Blob fileBlob = Blob.valueOf(jsonContent);
        //system.debug('fileBlob---------->>>>'+fileBlob);
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'User Data - Export - JSON';
        contentVersion.PathOnClient = '/' + contentVersion.Title + '.json';
        contentVersion.VersionData = fileBlob;
        insert contentVersion;
        //system.debug('contentVersion---------->'+contentVersion);
        
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
    }
    
    @isTest
    static void testPostRefreshUserRestorationCall() {
        try{
            Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template2' ];
            Test.startTest();
            PostRefreshUserRestorationCall.callRestoreBatch(rt.Id);        
            Test.stopTest();
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :rt.Id 
                                                     AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
            
            System.assertEquals(0, attachments.size(), 'The ContentDocumentLink should exist.');
            
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
            
            System.assertNotEquals(null, version, 'The ContentVersion should exist.');
            System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    
    @isTest
    static void testPostRefreshUserRestorationwithoutAttachments() {
        try{
            Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template1' ];
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new WithoutAttachmentsMock());
            PostRefreshUserRestorationCall.callRestoreBatch(rt.Id);        
            Test.stopTest();
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :rt.Id 
                                                     AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
            
            System.assertEquals(0, attachments.size(), 'The ContentDocumentLink should exist.');
            
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
            
            System.assertNotEquals(null, version, 'The ContentVersion should exist.');
            System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    
    @isTest
    static void testPostRefreshUserRestoration() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        PostRefreshUserRestorationCall.callRestoreBatch(rt.Id);        
        Test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
        
        System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
        
        ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
        
        System.assertNotEquals(null, version, 'The ContentVersion should exist.');
        System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
    }
    
    @isTest
    static void getCurrentUsersFromTargetOrgException() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetCurrentUsersFromTargetOrgExceptionMock());
        PostRefreshUserRestorationCall.callRestoreBatch(rt.Id);        
        Test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
        
        System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
        
        ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
        
        System.assertNotEquals(null, version, 'The ContentVersion should exist.');
        System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
    }
    
    @isTest
    static void getCurrentUsersFromTargetOrgException1() {
        try{
            Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
            Logs__c log = new Logs__c();
            log.Status__c = 'InProgress';
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GetCurrentUsersFromTargetOrgExceptionMock());
            PostRefreshUserRestoration.getCurrentUsersFromTargetOrg(null,null,log,null);        
            Test.stopTest();
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :rt.Id 
                                                     AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
            
            System.assertEquals(0, attachments.size(), 'The ContentDocumentLink should not exist.');
            
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
            
            System.assertNotEquals(null, version, 'The ContentVersion should exist.');
            System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    
    @isTest
    static void getProfilesFromTargetOrgException() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetprofilesFromTargetOrgExceptionMock());
        PostRefreshUserRestorationCall.callRestoreBatch(rt.Id);        
        Test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
        
        System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
        
        ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
        
        System.assertNotEquals(null, version, 'The ContentVersion should exist.');
        System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
    }
    
    @isTest
    static void getProfilesFromTargetOrgException1() {
        try{
            Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
            Logs__c log = new Logs__c();
            log.Status__c = 'InProgress';
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GetprofilesFromTargetOrgExceptionMock1());
            PostRefreshUserRestoration.getProfilesFromTargetOrg(null,null,log);        
            Test.stopTest();
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :rt.Id 
                                                     AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
            
            System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
            
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
            
            System.assertNotEquals(null, version, 'The ContentVersion should exist.');
            System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    
    @isTest
    static void getRolesFromTargetOrgException() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetRolesFromTargetOrgExceptionMock());
        PostRefreshUserRestorationCall.callRestoreBatch(rt.Id);        
        Test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
        
        System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
        
        ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
        
        System.assertNotEquals(null, version, 'The ContentVersion should exist.');
        System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
    }
    
    @isTest
    static void getRolesFromTargetOrgException1() {
        try{
            Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
            Logs__c log = new Logs__c();
            log.Status__c = 'InProgress';
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GetprofilesFromTargetOrgExceptionMock1());
            PostRefreshUserRestoration.getRolesFromTargetOrg(null,null,log);        
            Test.stopTest();
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :rt.Id 
                                                     AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
            
            System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
            
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
            
            System.assertNotEquals(null, version, 'The ContentVersion should exist.');
            System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    
    @isTest
    static void getPermissionSetsFromTargetOrgException() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetPermissionsetsFromTargetOrgExceptionMock());
        PostRefreshUserRestorationCall.callRestoreBatch(rt.Id);        
        Test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
        
        System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
        
        ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
        
        System.assertNotEquals(null, version, 'The ContentVersion should exist.');
        System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
    }
    
    @isTest
    static void getPermissionSetsFromTargetOrgException1() {
        try{
            Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
            Logs__c log = new Logs__c();
            log.Status__c = 'InProgress';
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GetprofilesFromTargetOrgExceptionMock1());
            PostRefreshUserRestoration.getPermissionSets(null,null,log);        
            Test.stopTest();
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :rt.Id 
                                                     AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
            
            System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
            
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
            
            System.assertNotEquals(null, version, 'The ContentVersion should exist.');
            System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    
    @isTest
    static void getPsgFromTargetOrgException() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetPsgFromTargetOrgExceptionMock());
        PostRefreshUserRestorationCall.callRestoreBatch(rt.Id);        
        Test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
        
        System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
        
        ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
        
        System.assertNotEquals(null, version, 'The ContentVersion should exist.');
        System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
    }
    
    @isTest
    static void getPsgFromTargetOrgException1() {
        try{
            Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
            Logs__c log = new Logs__c();
            log.Status__c = 'InProgress';
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GetprofilesFromTargetOrgExceptionMock1());
            PostRefreshUserRestoration.getPSG(null,null,log);        
            Test.stopTest();
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :rt.Id 
                                                     AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
            
            System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
            
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
            
            System.assertNotEquals(null, version, 'The ContentVersion should exist.');
            System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    
    
    
    @isTest
    static void getGroupsFromTargetOrgException() {
        try{
            Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c WHERE Name = 'Test Template' ];
            Logs__c log = new Logs__c();
            log.Status__c = 'InProgress';
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GetprofilesFromTargetOrgExceptionMock1());
            PostRefreshUserRestoration.getGroups(null,null,log);        
            Test.stopTest();
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :rt.Id 
                                                     AND ContentDocument.Title LIKE '%User Data - Export - JSON%'];
            
            System.assertEquals(1, attachments.size(), 'The ContentDocumentLink should exist.');
            
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];
            
            System.assertNotEquals(null, version, 'The ContentVersion should exist.');
            System.assertEquals('User Data - Export - JSON', version.Title, 'The ContentVersion title should match.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    
    @IsTest
        public static void executeBulkApiJobPoller() {
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
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            Test.startTest();
            BulkApiJobPoller scheduledJob = new BulkApiJobPoller('BulkApiJobPoller',jobIds, instanceUrl, accesstoken,log.Id,orgName);
            String scheduleJobId = system.schedule('BulkApiJobPoller', cronExpression, scheduledJob);
            Test.stopTest();
        }
    
     @IsTest
        public static void executeBulkApiJobPoller1() {
            Map<Id, String> jobIds = new Map<Id, String>();
            Refresh_Template__c rt =[SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c,Parent_Org__r.name FROM Refresh_Template__c WHERE Name = 'Test Template1' ];
            Logs__c log = [SELECT Id,Log_Type__c,JobStatus__c,Parent_Template__c from Logs__c where Parent_Template__c =: rt.id and JobStatus__c = 'JobComplete'];
            string instanceUrl = rt.Parent_Org__r.Domain_Url__c;
            string accessToken ='1234567890';
            string logType = log.Log_Type__c;
            string orgName = rt.Parent_Org__r.name;
            jobIds.put('750D0000000XXXX','Deactivation');
            DateTime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            Test.startTest();
            BulkApiJobPoller scheduledJob = new BulkApiJobPoller('BulkApiJobPoller',jobIds, instanceUrl, accesstoken,log.Id,orgName);
            String scheduleJobId = system.schedule('BulkApiJobPoller', cronExpression, scheduledJob);
            Test.stopTest();
        }
    
    @IsTest
        public static void executeBulkApiJobPoller2() {
            Map<Id, String> jobIds = new Map<Id, String>();
            Refresh_Template__c rt =[SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c,Parent_Org__r.name FROM Refresh_Template__c WHERE Name = 'Test Template1' ];
            Logs__c log = [SELECT Id,Log_Type__c,JobStatus__c,Parent_Template__c from Logs__c where Parent_Template__c =: rt.id and JobStatus__c = 'JobComplete'];
            string instanceUrl = rt.Parent_Org__r.Domain_Url__c;
            string accessToken ='1234567890';
            string logType = log.Log_Type__c;
            string orgName = rt.Parent_Org__r.name;
            jobIds.put('750D0000000XXX1','Insertion');
            DateTime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            Test.startTest();
            BulkApiJobPoller scheduledJob = new BulkApiJobPoller('BulkApiJobPoller',jobIds, instanceUrl, accesstoken,log.Id,orgName);
            String scheduleJobId = system.schedule('BulkApiJobPoller', cronExpression, scheduledJob);
            Test.stopTest();
        }
    
    @IsTest
        public static void executeBulkApiJobPoller3() {
            Map<Id, String> jobIds = new Map<Id, String>();
            Refresh_Template__c rt =[SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c,Parent_Org__r.name FROM Refresh_Template__c WHERE Name = 'Test Template1' ];
            Logs__c log = [SELECT Id,Log_Type__c,JobStatus__c,Parent_Template__c from Logs__c where Parent_Template__c =: rt.id and JobStatus__c = 'JobComplete'];
            string instanceUrl = rt.Parent_Org__r.Domain_Url__c;
            string accessToken ='1234567890';
            string logType = log.Log_Type__c;
            string orgName = rt.Parent_Org__r.name;
            jobIds.put('750D0000000XXX2','PermissionSet Assignment');
            DateTime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            Test.startTest();
            BulkApiJobPoller scheduledJob = new BulkApiJobPoller('BulkApiJobPoller',jobIds, instanceUrl, accesstoken,log.Id,orgName);
            String scheduleJobId = system.schedule('BulkApiJobPoller', cronExpression, scheduledJob);
            Test.stopTest();
        }
    
    @IsTest
        public static void executeBulkApiJobPoller4() {
            Map<Id, String> jobIds = new Map<Id, String>();
            Refresh_Template__c rt =[SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c,Parent_Org__r.name FROM Refresh_Template__c WHERE Name = 'Test Template1' ];
            Logs__c log = [SELECT Id,Log_Type__c,JobStatus__c,Parent_Template__c from Logs__c where Parent_Template__c =: rt.id and JobStatus__c = 'JobComplete'];
            string instanceUrl = rt.Parent_Org__r.Domain_Url__c;
            string accessToken ='1234567890';
            string logType = log.Log_Type__c;
            string orgName = rt.Parent_Org__r.name;
            jobIds.put('750D0000000XXX3','GroupAssignment');
            DateTime nextRunTime = Datetime.now().addMinutes(1);
            String cronExpression = nextRunTime.second() + ' ' +
                nextRunTime.minute() + ' ' +
                nextRunTime.hour() + ' ' +
                nextRunTime.day() + ' ' +
                nextRunTime.month() + ' ? ' +
                nextRunTime.year();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            Test.startTest();
            BulkApiJobPoller scheduledJob = new BulkApiJobPoller('BulkApiJobPoller',jobIds, instanceUrl, accesstoken,log.Id,orgName);
            String scheduleJobId = system.schedule('BulkApiJobPoller', cronExpression, scheduledJob);
            Test.stopTest();
        }
    
    public class WithoutAttachmentsMock implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                //system.debug('UserBody'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records":[{"Id":"0116g000000uVdxxxx","GroupId":"00G6g000002qijCEAQ","UserOrGroupId":"0056g000008HQaxxxx"}]}');
                //system.debug('GetGroupMembers Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('select+Id,Username+from+User+Where+UserName')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('Initiated User'+res.getBody());
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
                } else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive,"0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "JobComplete"}');
                } 
            }
            return res;
        }
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                //system.debug('UserBody'+res.getBody());
            }
            else if (req.getEndpoint().contains('SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('UserBody'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+Profile')){
                res.setBody('{"records":[{"Name":"TestProfile","Id":"TestProfileId"}]}');
                //system.debug('GetProfiles Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,DeveloperName+FROM+UserRole')){
                res.setBody('{"records":[{"DeveloperName":"TestRoleName","Id":"TestRoleId"}]}');
                //system.debug('GetRoles Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+PermissionSet')){
                res.setBody('{"records":[{"Id":"TestPermSetId","Name":"TestPermsetName"}]}');
                //system.debug('GetPermissionSets Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,DeveloperName+FROM+PermissionSetGroup')){
                res.setBody('{"records":[{"Id":"TestPSGId","DeveloperName":"TestPSGName"}]}');
                //system.debug('GetPSg Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name,DeveloperName+FROM+Group')){
                res.setBody('{"records":[{"Id":"TestGroupId","DeveloperName":"TestGroupName"}]}');
                //system.debug('GetGroups Json Body------->'+res.getBody());
            }
            else if(req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records":[{"Id":"0116g000000uVdxxxx","GroupId":"00G6g000002qijCEAQ","UserOrGroupId":"0056g000008HQaxxxx"}]}');
                //system.debug('GetGroupMembers Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('select+Id,Username+from+User+Where+UserName')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('Initiated User'+res.getBody());
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
                } else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    if(req.getEndpoint().contains('750D0000000XXXX')){
                    res.setBody('"sf__Id","sf__Error",Id,IsActive \n "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false" "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                    }else if(req.getEndpoint().contains('750D0000000XXX1')){
                    res.setBody('"sf__Id","sf__Error",Id,IsActive \n "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false" "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                    }else if(req.getEndpoint().contains('750D0000000XXX2')){
                    res.setBody('"sf__Id","sf__Error",UserOrGroupId,IsActive \n "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false" "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                    }else if(req.getEndpoint().contains('750D0000000XXX3')){
                    res.setBody('"sf__Id","sf__Error",UserOrGroupId,IsActive \n "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false" "0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                    }
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "JobComplete"}');
                } 
            }
            return res;
        }
    }
    
    public class MockHttpResponseGenerator1 implements HttpCalloutMock {
        public String responseBody;
                
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if(req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records":[{"Id":"0116g000000uVdxxxx","GroupId":"00G6g000002qijCEAQ","UserOrGroupId":"0056g000008HQaxxxx"}]}');
                res.setStatusCode(200);
                //system.debug('GetGroupMembers Json Body------->'+res.getBody());
            }else if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                res.setStatusCode(200);
                //system.debug('UserBody'+res.getBody());
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
                } else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive,"0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "JobComplete"}');
                }
            }else{
                res.setStatusCode(400);
            }
            return res;
        }
    }
    public class GetCurrentUsersFromTargetOrgExceptionMock implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                //system.debug('UserBody'+res.getBody());
            }
            else if (req.getEndpoint().contains('SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('UserBody'+res.getBody());
                res.setStatusCode(400);
            }
            else if(req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records":[{"Id":"0116g000000uVdxxxx","GroupId":"00G6g000002qijCEAQ","UserOrGroupId":"0056g000008HQaxxxx"}]}');
                //system.debug('GetGroupMembers Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('select+Id,Username+from+User+Where+UserName')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('Initiated User'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+Profile')){
                res.setBody('{"records":[{"Name":"TestProfile","Id":"TestProfileId"}]}');
                //system.debug('GetProfiles Json Body------->'+res.getBody());
                res.setStatusCode(400);
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
                } else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive,"0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "JobComplete"}');
                } 
            }
            return res;
        }
    }
    
    public class GetCurrentUsersFromTargetOrgExceptionMock1 implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class GetprofilesFromTargetOrgExceptionMock implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                //system.debug('UserBody'+res.getBody());
            }
            else if (req.getEndpoint().contains('SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('UserBody'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+Profile')){
                res.setBody('{"records":[{"Name":"TestProfile","Id":"TestProfileId"}]}');
                //system.debug('GetProfiles Json Body------->'+res.getBody());
                res.setStatusCode(400);
            }else if(req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records":[{"Id":"0116g000000uVdxxxx","GroupId":"00G6g000002qijCEAQ","UserOrGroupId":"0056g000008HQaxxxx"}]}');
                //system.debug('GetGroupMembers Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('select+Id,Username+from+User+Where+UserName')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('Initiated User'+res.getBody());
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
                } else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive,"0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "JobComplete"}');
                } 
            }
            return res;
        }
    }
    
    public class GetprofilesFromTargetOrgExceptionMock1 implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class GetRolesFromTargetOrgExceptionMock implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                //system.debug('UserBody'+res.getBody());
            }
            else if (req.getEndpoint().contains('SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('UserBody'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+Profile')){
                res.setBody('{"records":[{"Name":"TestProfile","Id":"TestProfileId"}]}');
                //system.debug('GetProfiles Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,DeveloperName+FROM+UserRole')){
                res.setBody('{"records":[{"DeveloperName":"TestRoleName","Id":"TestRoleId"}]}');
                //system.debug('GetRoles Json Body------->'+res.getBody());
                res.setStatusCode(400);
            }else if(req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records":[{"Id":"0116g000000uVdxxxx","GroupId":"00G6g000002qijCEAQ","UserOrGroupId":"0056g000008HQaxxxx"}]}');
                //system.debug('GetGroupMembers Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('select+Id,Username+from+User+Where+UserName')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('Initiated User'+res.getBody());
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
                } else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive,"0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "JobComplete"}');
                } 
            }
            return res;
        }
    }
    
    public class GetPermissionsetsFromTargetOrgExceptionMock implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                //system.debug('UserBody'+res.getBody());
            }
            else if (req.getEndpoint().contains('SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('UserBody'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+Profile')){
                res.setBody('{"records":[{"Name":"TestProfile","Id":"TestProfileId"}]}');
                //system.debug('GetProfiles Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,DeveloperName+FROM+UserRole')){
                res.setBody('{"records":[{"DeveloperName":"TestRoleName","Id":"TestRoleId"}]}');
                //system.debug('GetRoles Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+PermissionSet')){
                res.setBody('{"records":[{"Id":"TestPermSetId","Name":"TestPermsetName"}]}');
                //system.debug('GetPermissionSets Json Body------->'+res.getBody());
                res.setStatusCode(400);
            }else if(req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records":[{"Id":"0116g000000uVdxxxx","GroupId":"00G6g000002qijCEAQ","UserOrGroupId":"0056g000008HQaxxxx"}]}');
                //system.debug('GetGroupMembers Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('select+Id,Username+from+User+Where+UserName')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('Initiated User'+res.getBody());
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
                } else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive,"0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "JobComplete"}');
                } 
            }
            return res;
        }
    }
    
    public class GetPsgFromTargetOrgExceptionMock implements HttpCalloutMock {
        public String responseBody;
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                //system.debug('UserBody'+res.getBody());
            }
            else if (req.getEndpoint().contains('SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('UserBody'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+Profile')){
                res.setBody('{"records":[{"Name":"TestProfile","Id":"TestProfileId"}]}');
                //system.debug('GetProfiles Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,DeveloperName+FROM+UserRole')){
                res.setBody('{"records":[{"DeveloperName":"TestRoleName","Id":"TestRoleId"}]}');
                //system.debug('GetRoles Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,Name+FROM+PermissionSet')){
                res.setBody('{"records":[{"Id":"TestPermSetId","Name":"TestPermsetName"}]}');
                //system.debug('GetPermissionSets Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('SELECT+Id,DeveloperName+FROM+PermissionSetGroup')){
                res.setBody('{"records":[{"Id":"TestPSGId","DeveloperName":"TestPSGName"}]}');
                //system.debug('GetPSg Json Body------->'+res.getBody());
                res.setStatusCode(400);
            }else if(req.getEndpoint().contains('SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId')){
                res.setBody('{"records":[{"Id":"0116g000000uVdxxxx","GroupId":"00G6g000002qijCEAQ","UserOrGroupId":"0056g000008HQaxxxx"}]}');
                //system.debug('GetGroupMembers Json Body------->'+res.getBody());
            }else if(req.getEndpoint().contains('select+Id,Username+from+User+Where+UserName')){
                res.setBody('{"records":[{"Id": "0056g000001Sv6cxxx","Username": "jdoe@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"},{"Id": "0056g000001Sv7cxxx","Username": "jdo8968@example.com","Email": "johndoe@example.com", "IsActive": true, "ProfileId": "00e6g000001Jpthxxx", "UserRoleId": "00E6g000000ZPrAxxx"}]}');
                //system.debug('Initiated User'+res.getBody());
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
                } else if (req.getMethod() == 'GET' && (req.getEndpoint().contains('failedResults')||req.getEndpoint().contains('successfulResults'))) {
                    res.setStatusCode(200);
                    res.setBody('"sf__Id","sf__Error",Id,IsActive,"0052w000009lr4fAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4fAAA","false","0052w000009lr4iAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4iAAA","false","0052w000009lr4hAAA","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w000009lr4hAAA","false","0052w00000H6YjzAAF","INSUFFICIENT_ACCESS_OR_READONLY:Cannot insert a user with this profile:--","0052w00000H6YjzAAF","false"');
                } else if (req.getMethod() == 'GET') {
                    res.setStatusCode(200);
                    res.setBody('{"id": "7501J000000123TQAQ","operation": "ingest","object": "Account","state": "JobComplete"}');
                } 
            }
            return res;
        }
    }
}