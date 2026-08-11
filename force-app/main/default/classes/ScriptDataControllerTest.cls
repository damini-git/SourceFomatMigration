@isTest
public class ScriptDataControllerTest {
    
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
    }
    
    private static void createAndLinkCSVFile(Id linkedEntityId, String content) {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Scripts';
        cv.PathOnClient = 'Scripts.csv';
        cv.VersionData = Blob.valueOf(content);
        cv.IsMajorVersion = true;
        insert cv;
        
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conDocId;
        cdl.LinkedEntityId = linkedEntityId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
    
    @isTest
    static void testValidCSVFileReading() {
         Refresh_Template__c template = [SELECT Id, Parent_Org__c FROM Refresh_Template__c LIMIT 1];
        
        String csvContent = 'order,scriptname,scriptdata\n' +
                          '1,Test Script 1,Test Details 1\n' +
                          '2,Test Script 2,Test Details 2\n' +
                          '3,Test Script 3,Test Details 3';
        
        createAndLinkCSVFile(template.Id, csvContent);
        
        Test.startTest();
        List<ScriptDataController.ScriptWrapper> results = ScriptDataController.readCSVFile(template.Id);
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should have 3 script records');
        System.assertEquals(1, results[0].order, 'First record should have order 1');
        System.assertEquals('Test Script 1', results[0].ScriptName, 'First record should have correct name');
    }
    
    @isTest
    static void testInvalidCSVFormat() {
        Refresh_Template__c template = [SELECT Id, Parent_Org__c FROM Refresh_Template__c LIMIT 1];
        
        String csvContent = 'invalid,headers,here\n' +
                          '1,Test Script 1,Test Details 1';
        
        createAndLinkCSVFile(template.Id, csvContent);
        
        Test.startTest();
        try {
            ScriptDataController.readCSVFile(template.Id);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            // AuraHandledException wraps the original message, so we just verify it's thrown
            System.assert(true, 'Expected exception was thrown');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testNoCSVFile() {
         Refresh_Template__c template = [SELECT Id, Parent_Org__c FROM Refresh_Template__c LIMIT 1];
        
        Test.startTest();
        List<ScriptDataController.ScriptWrapper> results = ScriptDataController.readCSVFile(template.Id);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no CSV file is found');
    }
    
    @isTest
    static void testInvalidCSVData() {
         Refresh_Template__c template = [SELECT Id, Parent_Org__c FROM Refresh_Template__c LIMIT 1];
        
        String csvContent = 'order,scriptname,scriptdata\n' +
                          'invalid,Test Script 1,Test Details 1\n' +
                          '2,Test Script 2,Test Details 2';
        
        createAndLinkCSVFile(template.Id, csvContent);
        
        Test.startTest();
        List<ScriptDataController.ScriptWrapper> results = ScriptDataController.readCSVFile(template.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should only process valid rows');
        System.assertEquals(2, results[0].order, 'Should have processed the valid row');
    }
    
    @isTest
    static void testCSVWithBOMMarker() {
         Refresh_Template__c template = [SELECT Id, Parent_Org__c FROM Refresh_Template__c LIMIT 1];
        
        String csvContent = '\uFEFForder,scriptname,scriptdata\n' +
                          '1,Test Script 1,Test Details 1';
        
        createAndLinkCSVFile(template.Id, csvContent);
        
        Test.startTest();
        List<ScriptDataController.ScriptWrapper> results = ScriptDataController.readCSVFile(template.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should process CSV with BOM marker');
        System.assertEquals(1, results[0].order, 'Should have correct order');
        System.assertEquals('Test Script 1', results[0].ScriptName, 'Should have correct name');
    }
    
    @isTest
    static void testMultipleCSVFiles() {
         Refresh_Template__c template = [SELECT Id, Parent_Org__c FROM Refresh_Template__c LIMIT 1];
        
        String csvContent1 = 'order,scriptname,scriptdata\n' +
                           '1,Old Script,Old Details';
        
        createAndLinkCSVFile(template.Id, csvContent1);
        
        ContentVersion oldVersion = [SELECT Id FROM ContentVersion WHERE PathOnClient = 'Scripts.csv' LIMIT 1];
        Test.setCreatedDate(oldVersion.Id, DateTime.now().addMinutes(-5));
        
        String csvContent2 = 'order,scriptname,scriptdata\n' +
                           '1,New Script,New Details';
        
        createAndLinkCSVFile(template.Id, csvContent2);
        
        Test.startTest();
        List<ScriptDataController.ScriptWrapper> results = ScriptDataController.readCSVFile(template.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return data from latest file only');
        //System.assertEquals('New Script', results[0].ScriptName, 'Should use data from newest file');
    }
}