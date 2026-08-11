@IsTest
private class JSONFileReaderTest {
    
    /* @IsTest
static void testReadJSONFromRelatedFiles() {
// Create a test account to link files to
Account testAccount = new Account(Name = 'Test Account', Sales_Owner__c = 'Shalini');
insert testAccount;

// Prepare test JSON content
String jsonContent = JSON.serialize(new Map<String, Object>{
'records' => new List<Object>{
new Map<String, Object>{
'id' => '001',
'name' => 'Test Record 1'
},
new Map<String, Object>{
'id' => '002',
'name' => 'Test Record 2'
}
}
});

// Create content version with JSON file
ContentVersion testContentVersion = new ContentVersion(
Title = 'Test JSON File',
PathOnClient = 'TestFile.json',
VersionData = Blob.valueOf(jsonContent),
IsMajorVersion = true
);
insert testContentVersion;

// Get the content document
ContentDocument testContentDocument = [
SELECT Id, LatestPublishedVersionId 
FROM ContentDocument 
WHERE Id IN (
SELECT ContentDocumentId 
FROM ContentVersion 
WHERE Id = :testContentVersion.Id
)
];

// Create content document link
ContentDocumentLink link = new ContentDocumentLink(
LinkedEntityId = testAccount.Id,
ContentDocumentId = testContentDocument.Id,
ShareType = 'V'
);
insert link;

// Test the method
Test.startTest();
List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(testAccount.Id);
Test.stopTest();

// Assertions
System.assertEquals(2, result.size(), 'Should return two records from JSON');
System.assertEquals('001', result[0].get('id'), 'First record ID should match');
System.assertEquals('Test Record 1', result[0].get('name'), 'First record name should match');
}

@IsTest
static void testReadJSONFromRelatedFilesWithAlternateKeys() {
// Create a test account to link files to
Account testAccount = new Account(Name = 'Test Account', Sales_Owner__c = 'Shalini');
insert testAccount;

// Prepare test JSON content with alternate key
String jsonContent = JSON.serialize(new Map<String, Object>{
'users' => new List<Object>{
new Map<String, Object>{
'userId' => '001',
'userName' => 'John Doe'
},
new Map<String, Object>{
'userId' => '002',
'userName' => 'Jane Smith'
}
}
});

// Create content version with JSON file
ContentVersion testContentVersion = new ContentVersion(
Title = 'Test Users JSON File',
PathOnClient = 'TestUsers.json',
VersionData = Blob.valueOf(jsonContent),
IsMajorVersion = true
);
insert testContentVersion;

// Get the content document
ContentDocument testContentDocument = [
SELECT Id, LatestPublishedVersionId 
FROM ContentDocument 
WHERE Id IN (
SELECT ContentDocumentId 
FROM ContentVersion 
WHERE Id = :testContentVersion.Id
)
];

// Create content document link
ContentDocumentLink link = new ContentDocumentLink(
LinkedEntityId = testAccount.Id,
ContentDocumentId = testContentDocument.Id,
ShareType = 'V'
);
insert link;

// Test the method
Test.startTest();
List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(testAccount.Id);
Test.stopTest();

// Assertions
System.assertEquals(2, result.size(), 'Should return two records from JSON');
System.assertEquals('001', result[0].get('userId'), 'First record user ID should match');
System.assertEquals('John Doe', result[0].get('userName'), 'First record username should match');
}

@IsTest
static void testReadJSONFromRelatedFilesNoFiles() {
// Create a test account with no related files
Account testAccount = new Account(Name = 'Test Account', Sales_Owner__c = 'Shalini');
insert testAccount;

// Test the method with no files
Test.startTest();
List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(testAccount.Id);
Test.stopTest();

// Assertions
System.assertEquals(0, result.size(), 'Should return empty list when no files');
}

@IsTest
static void testReadJSONFromRelatedFilesNullRecordId() {
// Test the method with null record ID
Test.startTest();
List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(null);
Test.stopTest();

// Assertions
System.assertEquals(0, result.size(), 'Should return empty list for null record ID');
}

@IsTest
static void testAssignPermissionsAndGroups() {
// Create a test account
Account testAccount = new Account(Name = 'Test Account', Sales_Owner__c = 'Shalini');
insert testAccount;

// Test the method with different combinations of flags
Test.startTest();
JSONFileReader.assignPermissionsAndGroups(true, false, testAccount.Id);
JSONFileReader.assignPermissionsAndGroups(false, true, testAccount.Id);
JSONFileReader.assignPermissionsAndGroups(true, true, testAccount.Id);
Test.stopTest();

// No specific assertions needed, just ensuring the method runs without exceptions
System.assert(true, 'Method should execute without throwing an exception');
}*/
  
    
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
        
        // Create test ContentVersion (JSON file)
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test JSON';
        cv.PathOnClient = 'test.json';
        cv.VersionData = Blob.valueOf('{"User":[{"LastName":"Doe","FirstName":"John","Name":"John Doe","Username":"jdoe","Email":"jdoe@test.com","Profile":{"Name":"System Administrator"}},{"LastName":"Smith","FirstName":"Jane","Name":"Jane Smith","Username":"jsmith","Email":"jsmith@test.com","Profile":{"Name":"Standard User"}}]}');
        cv.IsMajorVersion = true;
        insert cv;
        
        // Get ContentDocument Id
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conDocId;
        cdl.LinkedEntityId = template.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
    
    @IsTest
    static void testSuccessfulJSONRead() {
        
        Refresh_Template__c template = [SELECT Id, Parent_Org__c FROM Refresh_Template__c LIMIT 1];
        
        Test.startTest();
        List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(template.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should have returned 2 users');
        
        // Verify first user data
        Map<String, Object> firstUser = result[0];
        System.assertEquals('Doe', firstUser.get('LastName'), 'Incorrect LastName for first user');
        System.assertEquals('John', firstUser.get('FirstName'), 'Incorrect FirstName for first user');
        System.assertEquals('John Doe', firstUser.get('Name'), 'Incorrect Name for first user');
        System.assertEquals('jdoe@test.com', firstUser.get('Email'), 'Incorrect Email for first user');
        System.assertEquals('System Administrator', firstUser.get('ProfileName'), 'Incorrect Profile for first user');
        
        // Verify second user data
        Map<String, Object> secondUser = result[1];
        System.assertEquals('Smith', secondUser.get('LastName'), 'Incorrect LastName for second user');
        System.assertEquals('Jane', secondUser.get('FirstName'), 'Incorrect FirstName for second user');
        System.assertEquals('Jane Smith', secondUser.get('Name'), 'Incorrect Name for second user');
        System.assertEquals('jsmith@test.com', secondUser.get('Email'), 'Incorrect Email for second user');
        System.assertEquals('Standard User', secondUser.get('ProfileName'), 'Incorrect Profile for second user');
    }
    
    @IsTest
    static void testNoJSONFileFound() {
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
        List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(template.Id);
        Test.stopTest();
        
        // Verify empty list is returned
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should have returned empty list');
    }
    
    @IsTest
    static void testInvalidJSONFormat() {
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
        
        // Create ContentVersion with invalid JSON
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Invalid JSON';
        cv.PathOnClient = 'invalid.json';
        cv.VersionData = Blob.valueOf('{"User":[{"InvalidFormat"]}');
        cv.IsMajorVersion = true;
        insert cv;
        
        // Get ContentDocument Id
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conDocId;
        cdl.LinkedEntityId = template.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        Test.startTest();
        List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(template.Id);
        Test.stopTest();
        
        // Verify empty list is returned for invalid JSON
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should have returned empty list');
    }
    
    @IsTest
    static void testEmptyJSONResponse() {
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
        
        // Create ContentVersion with empty user list
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Empty JSON';
        cv.PathOnClient = 'empty.json';
        cv.VersionData = Blob.valueOf('{"User":[]}');
        cv.IsMajorVersion = true;
        insert cv;
        
        // Get ContentDocument Id
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conDocId;
        cdl.LinkedEntityId = template.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        Test.startTest();
        List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(template.Id);
        Test.stopTest();
        
        // Verify empty list is returned
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should have returned empty list');
    }
    
    @IsTest
    static void testUserWithNullProfile() {
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
        
        // Create ContentVersion with user having null profile
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Null Profile JSON';
        cv.PathOnClient = 'null_profile.json';
        cv.VersionData = Blob.valueOf('{"User":[{"LastName":"Doe","FirstName":"John","Name":"John Doe","Username":"jdoe","Email":"jdoe@test.com","Profile":null}]}');
        cv.IsMajorVersion = true;
        insert cv;
        
        // Get ContentDocument Id
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conDocId;
        cdl.LinkedEntityId = template.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        Test.startTest();
        List<Map<String, Object>> result = JSONFileReader.readJSONFromRelatedFiles(template.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should have returned 1 user');
        System.assertEquals('N/A', result[0].get('ProfileName'), 'Profile should be N/A for null profile');
    }
    @IsTest
    static void testSystemException() {
        Test.startTest();
        try {
            // Pass null to force a System Exception
            JSONFileReader.readJSONFromRelatedFiles(null);
            System.assert(false, 'Should have thrown an exception');
        } catch (JSONFileReader.CustomException e) {
            System.assert(true, 'Expected custom exception');
        }
        Test.stopTest();
    }
    
}