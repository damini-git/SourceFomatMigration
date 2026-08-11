@isTest
private class MetadataMaskingRulesControllerTest {
    
    // Test helper method to create test data
    private static Refresh_Template__c createTestTemplate() {
        Org__c orgRec = new Org__c(Name = 'TestOrg');
        insert orgRec;
        Refresh_Template__c rt = new Refresh_Template__c(Name = 'Test Template', Parent_Org__c = orgRec.Id);
        insert rt;
        return rt;
    }
    
    // Test helper method to create test ContentVersion and link it to the template
    private static Id createTestFile(Id templateId, String fileName, String fileContent) {
        // Create ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = Blob.valueOf(fileContent);
        cv.IsMajorVersion = true;
        insert cv;
        
        // Get ContentDocumentId
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = templateId;
        cdl.ContentDocumentId = contentDocumentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        return cv.Id;
    }
    
    // Sample CSV content for tests
    private static String getSearchRulesCsvContent() {
        return 'Metadata Type,Masking Type,Search Key,Replace Value,Execution Order\n' +
               'ApexClass,Search & Replace,Prod,Dev,1\n' +
               'CustomObject,Search & Replace,Customer,Test,2\n' +
               'Profile,Search & Replace,Admin,DevAdmin,3';
    }
    
    private static String getSuffixRulesCsvContent() {
        return 'Metadata Type,Masking Type,Suffix Value,Execution Order\n' +
               'CustomObject,Suffix,_DEV,1\n' +
               'ApexTrigger,Suffix,_TEST,2\n' +
               'Profile,Suffix,_CLONE,3';
    }
    
    private static String getMalformedCsvContent() {
        return 'Column1,Column2\n' +
               'Value1,Value2\n';
    }
    
    @isTest
    static void testGetMetadataMaskingRulesNoFiles() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        
        // Act
        Test.startTest();
        MetadataMaskingRulesController.MetadataMaskingRulesWrapper result = 
            MetadataMaskingRulesController.getMetadataMaskingRules(template.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, result.searchRules.size(), 'Should return empty search rules when no files are attached');
        System.assertEquals(0, result.suffixRules.size(), 'Should return empty suffix rules when no files are attached');
    }
    
    @isTest
    static void testGetMetadataMaskingRulesWithSearchRuleFile() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        createTestFile(template.Id, 'SearchRules.csv', getSearchRulesCsvContent());
        
        // Act
        Test.startTest();
        MetadataMaskingRulesController.MetadataMaskingRulesWrapper result = 
            MetadataMaskingRulesController.getMetadataMaskingRules(template.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, result.searchRules.size(), 'Should have 3 search rules');
        System.assertEquals(0, result.suffixRules.size(), 'Should have no suffix rules');
        
        // Verify content of first search rule
        MetadataMaskingRulesController.SearchRule firstRule = result.searchRules[0];
        System.assertEquals('ApexClass', firstRule.metadataType);
        System.assertEquals('Search & Replace', firstRule.maskingType);
        System.assertEquals('Prod', firstRule.searchKey);
        System.assertEquals('Dev', firstRule.replaceValue);
       // System.assertEquals('1', firstRule.executionorder);
    }
    
    @isTest
    static void testGetMetadataMaskingRulesWithSuffixRuleFile() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        createTestFile(template.Id, 'SuffixRules.csv', getSuffixRulesCsvContent());
        
        // Act
        Test.startTest();
        MetadataMaskingRulesController.MetadataMaskingRulesWrapper result = 
            MetadataMaskingRulesController.getMetadataMaskingRules(template.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, result.searchRules.size(), 'Should have no search rules');
        System.assertEquals(3, result.suffixRules.size(), 'Should have 3 suffix rules');
        
        // Verify content of first suffix rule
        MetadataMaskingRulesController.SuffixRule firstRule = result.suffixRules[0];
        System.assertEquals('CustomObject', firstRule.metadataType);
        System.assertEquals('Suffix', firstRule.maskingType);
        System.assertEquals('_DEV', firstRule.suffixValue);
       // System.assertEquals('1', firstRule.executionorder);
    }
    
    @isTest
    static void testGetMetadataMaskingRulesWithBothFileTypes() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        createTestFile(template.Id, 'SearchRules.csv', getSearchRulesCsvContent());
        createTestFile(template.Id, 'SuffixRules.csv', getSuffixRulesCsvContent());
        
        // Act
        Test.startTest();
        MetadataMaskingRulesController.MetadataMaskingRulesWrapper result = 
            MetadataMaskingRulesController.getMetadataMaskingRules(template.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, result.searchRules.size(), 'Should have 3 search rules');
        System.assertEquals(3, result.suffixRules.size(), 'Should have 3 suffix rules');
    }
    
    @isTest
    static void testGetMetadataMaskingRulesWithMalformedFile() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        createTestFile(template.Id, 'MalformedFile.csv', getMalformedCsvContent());
        
        // Act
        Test.startTest();
        MetadataMaskingRulesController.MetadataMaskingRulesWrapper result = 
            MetadataMaskingRulesController.getMetadataMaskingRules(template.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, result.searchRules.size(), 'Should return empty search rules with malformed file');
        System.assertEquals(0, result.suffixRules.size(), 'Should return empty suffix rules with malformed file');
    }
    
    @isTest
    static void testGetMetadataMaskingRulesWithNonCsvFile() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        
        // Create non-CSV file
        ContentVersion cv = new ContentVersion();
        cv.Title = 'NonCsvFile.txt';
        cv.PathOnClient = 'NonCsvFile.txt';
        cv.VersionData = Blob.valueOf('This is not a CSV file');
        cv.IsMajorVersion = true;
        insert cv;
        
        // Get ContentDocumentId
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = template.Id;
        cdl.ContentDocumentId = contentDocumentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        // Act
        Test.startTest();
        MetadataMaskingRulesController.MetadataMaskingRulesWrapper result = 
            MetadataMaskingRulesController.getMetadataMaskingRules(template.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, result.searchRules.size(), 'Should ignore non-CSV files');
        System.assertEquals(0, result.suffixRules.size(), 'Should ignore non-CSV files');
    }
    
    @isTest
    static void testUploadSearchRulesCSVValid() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        String csvContent = getSearchRulesCsvContent();
        
        // Act
        Test.startTest();
        String result = MetadataMaskingRulesController.uploadSearchRulesCSV(template.Id, csvContent);
        Test.stopTest();
        
        // Assert
        System.assert(result.startsWith('Successfully uploaded'), 'Should return success message');
        System.assert(result.contains('3'), 'Should mention 3 rules uploaded');
        
        // Verify file was created and linked
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :template.Id
        ];
        System.assertEquals(1, links.size(), 'Should have one file linked to template');
        System.assert(links[0].ContentDocument.Title.startsWith('Search_Rules_'), 'File name should start with Search_Rules_');
    }
    
    @isTest
    static void testUploadSearchRulesCSVEmptyContent() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        
        // Act
        Test.startTest();
        String result = MetadataMaskingRulesController.uploadSearchRulesCSV(template.Id, '');
        Test.stopTest();
        
        // Assert
        System.assertEquals('Error: Empty file content', result);
    }
    
    @isTest
    static void testUploadSearchRulesCSVMissingHeaders() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        String csvContent = getMalformedCsvContent();
        
        // Act
        Test.startTest();
        String result = MetadataMaskingRulesController.uploadSearchRulesCSV(template.Id, csvContent);
        Test.stopTest();
        
        // Assert
        System.assert(result.startsWith('Error: CSV does not have the required headers'), 'Should detect missing headers');
    }
    
    @isTest
    static void testUploadSuffixRulesCSVValid() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        String csvContent = getSuffixRulesCsvContent();
        
        // Act
        Test.startTest();
        String result = MetadataMaskingRulesController.uploadSuffixRulesCSV(template.Id, csvContent);
        Test.stopTest();
        
        // Assert
        System.assert(result.startsWith('Successfully uploaded'), 'Should return success message');
        System.assert(result.contains('3'), 'Should mention 3 rules uploaded');
        
        // Verify file was created and linked
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :template.Id
        ];
        System.assertEquals(1, links.size(), 'Should have one file linked to template');
        System.assert(links[0].ContentDocument.Title.startsWith('Suffix_Rules_'), 'File name should start with Suffix_Rules_');
    }
    
    @isTest
    static void testUploadSuffixRulesCSVEmptyContent() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        
        // Act
        Test.startTest();
        String result = MetadataMaskingRulesController.uploadSuffixRulesCSV(template.Id, '');
        Test.stopTest();
        
        // Assert
        System.assertEquals('Error: Empty file content', result);
    }
    
    @isTest
    static void testUploadSuffixRulesCSVMissingHeaders() {
        // Arrange
        Refresh_Template__c template = createTestTemplate();
        String csvContent = getMalformedCsvContent();
        
        // Act
        Test.startTest();
        String result = MetadataMaskingRulesController.uploadSuffixRulesCSV(template.Id, csvContent);
        Test.stopTest();
        
        // Assert
        System.assert(result.startsWith('Error: CSV does not have the required headers'), 'Should detect missing headers');
    }
    
    // Test for empty CSV upload
    @isTest
    static void testUploadEmptyCSV() {
        Refresh_Template__c rt = createTestTemplate();
        
        String csvContent = '';
        
        Test.startTest();
        String searchResult = MetadataMaskingRulesController.uploadSearchRulesCSV(rt.Id, csvContent);
        String suffixResult = MetadataMaskingRulesController.uploadSuffixRulesCSV(rt.Id, csvContent);
        Test.stopTest();
        
        System.assertEquals('Error: Empty file content', searchResult, 'Expected error for empty search rules CSV');
        System.assertEquals('Error: Empty file content', suffixResult, 'Expected error for empty suffix rules CSV');
    }
}