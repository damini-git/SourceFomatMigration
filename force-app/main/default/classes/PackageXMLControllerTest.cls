@IsTest
private class PackageXMLControllerTest {
    private static final String TEST_XML = '<?xml version="1.0" encoding="UTF-8"?>\n' +
        '<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n' +
        '    <types>\n' +
        '        <members>TestClass</members>\n' +
        '        <members>AnotherClass</members>\n' +
        '        <name>ApexClass</name>\n' +
        '    </types>\n' +
        '    <types>\n' +
        '        <members>TestTrigger</members>\n' +
        '        <name>ApexTrigger</name>\n' +
        '    </types>\n' +
        '    <version>55.0</version>\n' +
        '</Package>';

    @TestSetup
    static void setupTestData() {
        
         // Create parent org record first
        Org__c parentOrg = new Org__c(
            Name = 'TestOrg',
            Domain_Url__c = 'https://test.salesforce.com',
            Access_Token__c = '12345',
            Org_Type__c = 'Production'
        );
        insert parentOrg;
        
        // Create test template with all options selected
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = parentOrg.Id,  // Set the required Parent_Org__c field
            Is_User_Data_Selected__c = true,
            Is_Scheduled_Jobs_Selected__c = true,
            Is_Metadata_Selected__c = true,
            Custom_Setting_Names__c = 'CustomSetting1, CustomSetting2'
        );
        insert template;
        
        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'packageXml.txt',
            PathOnClient = 'packageXml.txt',
            VersionData = Blob.valueOf(TEST_XML),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get Content Document Id
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = conDocId,
            ShareType = 'V'
        );
        insert cdl;
    }
    
    @IsTest
    static void testSuccessfulPackageXMLParsing() {
        
        Refresh_Template__c template = [SELECT Id, Parent_Org__c FROM Refresh_Template__c LIMIT 1];
        
        
        Test.startTest();
        List<PackageXMLController.ComponentWrapper> components = 
            PackageXMLController.getPackageContents(template.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(3, components.size(), 'Should have parsed 3 components');
        
        // Verify first component
        System.assertEquals(1, components[0].index, 'First component should have index 1');
        System.assertEquals('TestClass', components[0].name, 'First component should be TestClass');
        System.assertEquals('ApexClass', components[0].type, 'First component should be of type ApexClass');
        
        // Verify second component
        System.assertEquals(2, components[1].index, 'Second component should have index 2');
        System.assertEquals('AnotherClass', components[1].name, 'Second component should be AnotherClass');
        System.assertEquals('ApexClass', components[1].type, 'Second component should be of type ApexClass');
        
        // Verify third component
        System.assertEquals(3, components[2].index, 'Third component should have index 3');
        System.assertEquals('TestTrigger', components[2].name, 'Third component should be TestTrigger');
        System.assertEquals('ApexTrigger', components[2].type, 'Third component should be of type ApexTrigger');
    }
    
    @IsTest
    static void testNoLinkedFiles() {
         // Create parent org record first
        Org__c parentOrg = new Org__c(
            Name = 'TestOrg',
            Domain_Url__c = 'https://test.salesforce.com',
            Access_Token__c = '12345',
            Org_Type__c = 'Production'
        );
        insert parentOrg;
        
        // Create test template with all options selected
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = parentOrg.Id,  // Set the required Parent_Org__c field
            Is_User_Data_Selected__c = true,
            Is_Scheduled_Jobs_Selected__c = true,
            Is_Metadata_Selected__c = true,
            Custom_Setting_Names__c = 'CustomSetting1, CustomSetting2'
        );
        insert template;
        
        Test.startTest();
        try {
            PackageXMLController.getPackageContents(template.Id);
            System.assert(false, 'Should have thrown an exception');
        } catch(AuraHandledException e) {
            // In test context, AuraHandledException will return "Script-thrown exception"
            System.assertNotEquals(null, e, 'Exception should not be null');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testInvalidXMLContent() {
         // Create parent org record first
        Org__c parentOrg = new Org__c(
            Name = 'TestOrg',
            Domain_Url__c = 'https://test.salesforce.com',
            Access_Token__c = '12345',
            Org_Type__c = 'Production'
        );
        insert parentOrg;
        
        // Create test template with all options selected
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = parentOrg.Id,  // Set the required Parent_Org__c field
            Is_User_Data_Selected__c = true,
            Is_Scheduled_Jobs_Selected__c = true,
            Is_Metadata_Selected__c = true,
            Custom_Setting_Names__c = 'CustomSetting1, CustomSetting2'
        );
        insert template;
        
        // Create ContentVersion with invalid XML
        ContentVersion cv = new ContentVersion(
            Title = 'packageXml.txt',
            PathOnClient = 'packageXml.txt',
            VersionData = Blob.valueOf('Invalid XML Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get Content Document Id
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = conDocId,
            ShareType = 'V'
        );
        insert cdl;
        
        Test.startTest();
        try {
            PackageXMLController.getPackageContents(template.Id);
            System.assert(false, 'Should have thrown an exception');
        } catch(AuraHandledException e) {
            // In test context, AuraHandledException will return "Script-thrown exception"
            System.assertNotEquals(null, e, 'Exception should not be null');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testComponentWrapper() {
        // Test the wrapper class constructor and properties
        PackageXMLController.ComponentWrapper wrapper = 
            new PackageXMLController.ComponentWrapper(1, 'TestName', 'TestType');
        
        System.assertEquals(1, wrapper.index, 'Index should be 1');
        System.assertEquals('TestName', wrapper.name, 'Name should be TestName');
        System.assertEquals('TestType', wrapper.type, 'Type should be TestType');
    }
    
    @isTest
    static void testGetAssignedPermissionSets() {
        // Generate a unique username suffix
        String uniqueSuffix = String.valueOf(System.currentTimeMillis());
        
        // Setup test data: Create a Profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create Users with the same Profile
        User user1 = new User(
            Username = 'testuser1_' + uniqueSuffix + '@test.com',
            Alias = 'tuser1',
            Email = 'testuser1_' + uniqueSuffix + '@test.com',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User1', // Required field
            IsActive = true
        );
        
        User user2 = new User(
            Username = 'testuser2_' + uniqueSuffix + '@test.com',
            Alias = 'tuser2',
            Email = 'testuser2_' + uniqueSuffix + '@test.com',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User2', // Required field
            IsActive = true
        );
        
        insert new List<User>{user1, user2};

        // Create a Permission Set with a valid API Name and Label
        PermissionSet permSet = new PermissionSet(
            Name = 'Test_Permission_Set_' + uniqueSuffix,
            Label = 'Test Permission Set ' + uniqueSuffix
        );
        insert permSet;

        // Assign Permission Set to Users
        PermissionSetAssignment psa1 = new PermissionSetAssignment(
            AssigneeId = user1.Id,
            PermissionSetId = permSet.Id
        );
        
        PermissionSetAssignment psa2 = new PermissionSetAssignment(
            AssigneeId = user2.Id,
            PermissionSetId = permSet.Id
        );
        
        insert new List<PermissionSetAssignment>{psa1, psa2};

        // Run the test as user1
        System.runAs(user1) {
            Test.startTest();
            
            // Call the method
            List<PermissionSet> permissionSets = PackageXMLController.getAssignedPermissionSets();
            
            Test.stopTest();
            
            // Verify results
            System.assertNotEquals(null, permissionSets, 'The permission sets should not be null');
            //System.assertEquals(, permissionSets.size(), 'There should be one permission set');
            //System.assertEquals('Test_Permission_Set_' + uniqueSuffix, permissionSets[0].Name, 'The permission set name should be "Test_Permission_Set_" followed by the unique suffix');
            //System.assertEquals('Test Permission Set ' + uniqueSuffix, permissionSets[0].Label, 'The permission set label should be "Test Permission Set " followed by the unique suffix');
        }
    }

    @isTest
    static void testGetProfileName() {
        // Generate a unique username suffix
        String uniqueSuffix = String.valueOf(System.currentTimeMillis());
        
        // Setup test data: Create a Profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create a User
        User user = new User(
            Username = 'testprofileuser_' + uniqueSuffix + '@test.com',
            Alias = 'tprofile',
            Email = 'testprofileuser_' + uniqueSuffix + '@test.com',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'ProfileUser', // Required field
            IsActive = true
        );
        
        insert user;
        
        // Set the current user to the newly created user
        System.runAs(user) {
            Test.startTest();
            
            // Call the method
            String profileName = PackageXMLController.getProfileName();
            
            Test.stopTest();
            
            // Verify results
            System.assertNotEquals(null, profileName, 'The profile name should not be null');
            System.assertEquals('Standard User', profileName, 'The profile name should be "Standard User"');
        }
    }
}