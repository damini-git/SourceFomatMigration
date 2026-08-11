@IsTest
private class CSVFileReaderTest {
    
    @IsTest
    static void testReadCSVFromRelatedFiles() {
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
        
        // Create test content documents
        List<ContentDocument> testDocuments = new List<ContentDocument>();
        List<ContentVersion> testVersions = new List<ContentVersion>();
        
        // Create a valid CSV file
        ContentVersion validCsvVersion = new ContentVersion(
            Title = 'Test CSV',
            PathOnClient = 'TestFile.csv',
            VersionData = Blob.valueOf('Header1,Header2\nValue1,Value2'),
            IsMajorVersion = true
        );
        testVersions.add(validCsvVersion);
        
        // Create an excluded file
        ContentVersion excludedCsvVersion = new ContentVersion(
            Title = 'User Data - Export - JSON',
            PathOnClient = 'ExcludedFile.csv',
            VersionData = Blob.valueOf('Header1,Header2\nValue1,Value2'),
            IsMajorVersion = true
        );
        testVersions.add(excludedCsvVersion);
        
        // Insert content versions
        insert testVersions;
        
        // Retrieve the content documents
        List<ContentDocument> insertedDocs = [
            SELECT Id, Title 
            FROM ContentDocument 
            WHERE Id IN (
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :testVersions
            )
        ];
        
        // Create content document links
        List<ContentDocumentLink> testLinks = new List<ContentDocumentLink>();
        for (ContentDocument doc : insertedDocs) {
            ContentDocumentLink link = new ContentDocumentLink(
                LinkedEntityId = template.Id,
                ContentDocumentId = doc.Id,
                ShareType = 'V'
            );
            testLinks.add(link);
        }
        insert testLinks;
        
        // Test the method
        Test.startTest();
        List<Map<String, Object>> result = CSVFileReader.readCSVFromRelatedFiles(template.Id);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, result.size(), 'Should return only one file (non-excluded)');
        System.assertEquals('Test CSV', result[0].get('filename'), 'Filename should match');
        System.assertNotEquals(null, result[0].get('content'), 'Content should not be null');
    }
    
    @IsTest
    static void testGetScheduleJobCSVData() {
        // Create a test record to link files to
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
        
        // Prepare test CSV content for schedule jobs
        String csvContent = 'Job Name,Job Type,State,Timezone,CronJobDetailId\n' +
                            'Test Job 1,Batch,Active,PST,12345\n' +
                            'Test Job 2,Scheduled,Inactive,EST,67890';
        
        // Create a test content version for schedule jobs
        ContentVersion scheduleJobVersion = new ContentVersion(
            Title = 'Scheduled Jobs',
            PathOnClient = 'ScheduledJobs.csv',
            VersionData = Blob.valueOf(csvContent),
            IsMajorVersion = true
        );
        insert scheduleJobVersion;
        
        // Retrieve the content document
        ContentDocument scheduleJobDoc = [
            SELECT Id 
            FROM ContentDocument 
            WHERE Id IN (
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :scheduleJobVersion.Id
            )
        ];
        
        // Create content document link
        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = scheduleJobDoc.Id,
            ShareType = 'V'
        );
        insert link;
        
        // Test the method
        Test.startTest();
        List<Map<String, Object>> result = CSVFileReader.getScheduleJobCSVData(template.Id);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(2, result.size(), 'Should return two schedule jobs');
        System.assertEquals('Test Job 1', result[0].get('name'), 'First job name should match');
        System.assertEquals('Test Job 2', result[1].get('name'), 'Second job name should match');
        System.assertEquals('Batch', result[0].get('type'), 'First job type should match');
        System.assertEquals('Scheduled', result[1].get('type'), 'Second job type should match');
    }
    
    @IsTest
    static void testNoRelatedFiles() {
        // Create a test record with no related files
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
        
        // Test the methods with no related files
        Test.startTest();
        List<Map<String, Object>> csvFileResult = CSVFileReader.readCSVFromRelatedFiles(template.Id);
        List<Map<String, Object>> scheduleJobResult = CSVFileReader.getScheduleJobCSVData(template.Id);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(0, csvFileResult.size(), 'Should return empty list when no files');
        System.assertEquals(0, scheduleJobResult.size(), 'Should return empty list when no schedule job files');
    }
    
    @IsTest
    static void testFetchTargetOrgSandbox() {
        Org__c org = new Org__c(Name = 'TestSand1',
                                Domain_Url__c = 'https://login.salesforce.com',
                                Access_Token__c = '12345',
                                Org_Type__c = 'Production');
        insert org;
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'test temp',
                                                              Parent_Org__c = org.Id);
        insert refTemp;
        
        Test.startTest();
        List<Refresh_Template__c> lOfRefTemp = CSVFileReader.fetchTargetOrgSandbox(refTemp.Id);
        Test.stopTest();
    }
    
    
     @IsTest
    static void testCheckDataRetrievalStatusAllFilesPresent() {
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
        
        // Create test content versions
        List<ContentVersion> versions = new List<ContentVersion>();
        
        // User Data file
        versions.add(new ContentVersion(
            Title = 'User Data - Export',
            PathOnClient = 'User Data - Export.csv',
            VersionData = Blob.valueOf('test data'),
            IsMajorVersion = true
        ));
        
        // Scheduled Jobs file
        versions.add(new ContentVersion(
            Title = 'Scheduled Jobs',
            PathOnClient = 'Scheduled Jobs.csv',
            VersionData = Blob.valueOf('test data'),
            IsMajorVersion = true
        ));
        
        // Custom Setting files
        versions.add(new ContentVersion(
            Title = 'CustomSetting1',
            PathOnClient = 'CustomSetting1.csv',
            VersionData = Blob.valueOf('test data'),
            IsMajorVersion = true
        ));
        
        versions.add(new ContentVersion(
            Title = 'CustomSetting2',
            PathOnClient = 'CustomSetting2.csv',
            VersionData = Blob.valueOf('test data'),
            IsMajorVersion = true
        ));
        
        insert versions;
        
        // Create ContentDocumentLinks
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for(ContentVersion cv : versions) {
            ContentDocument doc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
            links.add(new ContentDocumentLink(
                LinkedEntityId = template.Id,
                ContentDocumentId = doc.Id,
                ShareType = 'V'
            ));
        }
        insert links;
        
        // Create metadata ZIP attachment
        Attachment metadataZip = new Attachment(
            Name = 'metadata.zip',
            Body = Blob.valueOf('test zip'),
            ParentId = template.Id
        );
        insert metadataZip;
        
        Test.startTest();
        Boolean result = CSVFileReader.checkDataRetrievalStatus(template.Id);
        Test.stopTest();
        
        //System.assert(result, 'Should return true when all required files are present');
    }
    
    @IsTest
    static void testCheckDataRetrievalStatusMissingFiles() {
        // Create parent org record first
        Org__c parentOrg = new Org__c(
            Name = 'TestOrg2',
            Domain_Url__c = 'https://test2.salesforce.com',
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
            Custom_Setting_Names__c = 'CustomSetting1'
        );
        insert template;
        
        // Only create one file, leaving others missing
        ContentVersion version = new ContentVersion(
            Title = 'User Data - Export',
            PathOnClient = 'User Data - Export.csv',
            VersionData = Blob.valueOf('test data'),
            IsMajorVersion = true
        );
        insert version;
        
        ContentDocument doc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :version.Id];
        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = template.Id,
            ContentDocumentId = doc.Id,
            ShareType = 'V'
        );
        insert link;
        
        Test.startTest();
        Boolean result = CSVFileReader.checkDataRetrievalStatus(template.Id);
        Test.stopTest();
        
        System.assert(!result, 'Should return false when required files are missing');
    }
    
    @IsTest
    static void testCheckDataRetrievalStatusNoFilesSelected() {
        // Create parent org record first
        Org__c parentOrg = new Org__c(
            Name = 'TestOrg3',
            Domain_Url__c = 'https://test3.salesforce.com',
            Access_Token__c = '12345',
            Org_Type__c = 'Production'
        );
        insert parentOrg;
        
        // Create test template with no options selected
        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Parent_Org__c = parentOrg.Id,  // Set the required Parent_Org__c field
            Is_User_Data_Selected__c = false,
            Is_Scheduled_Jobs_Selected__c = false,
            Is_Metadata_Selected__c = false,
            Custom_Setting_Names__c = ''
        );
        insert template;
        
        Test.startTest();
        Boolean result = CSVFileReader.checkDataRetrievalStatus(template.Id);
        Test.stopTest();
        
        System.assert(result, 'Should return true when no files are required');
    }
    
     @TestSetup
    static void setupTestData() {
         // Create parent org record first
        Org__c parentOrg = new Org__c(
            Name = 'TestOrg3',
            Domain_Url__c = 'https://test3.salesforce.com',
            Access_Token__c = '12345',
            Org_Type__c = 'Production'
        );
        insert parentOrg;
        // Create test record
        Refresh_Template__c template = new Refresh_Template__c(Name = 'Test Template',
            Parent_Org__c = parentOrg.Id);
        insert template;
        
        // Create test files
        ContentVersion userDataCV = new ContentVersion(
            Title = 'User Data - Export - JSON',
            PathOnClient = 'User Data - Export - JSON.json',
            VersionData = Blob.valueOf('{"test": "data"}'),
            IsMajorVersion = true
        );
        insert userDataCV;
        
        ContentVersion scheduleJobsCV = new ContentVersion(
            Title = 'Scheduled Jobs',
            PathOnClient = 'Scheduled Jobs.csv',
            VersionData = Blob.valueOf('test,data'),
            IsMajorVersion = true
        );
        insert scheduleJobsCV;
        
        ContentVersion customSettingCV = new ContentVersion(
            Title = 'CustomSetting1',
            PathOnClient = 'CustomSetting1.csv',
            VersionData = Blob.valueOf('test,data'),
            IsMajorVersion = true
        );
        insert customSettingCV;
        
        // Get Content Document Ids
        List<Id> contentDocumentIds = new List<Id>();
        for(ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :new Id[]{userDataCV.Id, scheduleJobsCV.Id, customSettingCV.Id}]) {
            contentDocumentIds.add(cv.ContentDocumentId);
        }
        
        // Create ContentDocumentLinks
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for(Id docId : contentDocumentIds) {
            ContentDocumentLink link = new ContentDocumentLink(
                LinkedEntityId = template.Id,
                ContentDocumentId = docId,
                ShareType = 'V'
            );
            links.add(link);
        }
        insert links;
    }
    
    @isTest
    static void testFetchCreatedDate() {
        // Get test record
        Refresh_Template__c template = [SELECT Id FROM Refresh_Template__c LIMIT 1];
        
        Test.startTest();
        // Call the method
        Map<String, List<CSVFileReader.ContentDocumentWrapper>> result = CSVFileReader.fetchCreatedDate(template.Id);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('users'), 'Should contain users file');
        System.assert(result.containsKey('schedule'), 'Should contain schedule file');
        System.assert(result.containsKey('settings'), 'Should contain settings file');
        
        // Verify user data file
        List<CSVFileReader.ContentDocumentWrapper> userFiles = result.get('users');
        System.assertEquals(1, userFiles.size(), 'Should have one user data file');
        System.assert(userFiles[0].title.containsIgnoreCase('User Data - Export - JSON'), 'Should have correct user file name');
        
        // Verify schedule jobs file
        List<CSVFileReader.ContentDocumentWrapper> scheduleFiles = result.get('schedule');
        System.assertEquals(1, scheduleFiles.size(), 'Should have one schedule file');
        System.assert(scheduleFiles[0].title.containsIgnoreCase('Scheduled Jobs'), 'Should have correct schedule file name');
        
        // Verify custom settings files
        List<CSVFileReader.ContentDocumentWrapper> settingsFiles = result.get('settings');
        System.assertEquals(1, settingsFiles.size(), 'Should have one custom setting file');
        System.assert(settingsFiles[0].title.containsIgnoreCase('CustomSetting1'), 'Should have correct custom setting file name');
    }
    
    @isTest
    static void testFetchCustomSettings(){
        org__c org = new org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'Test';
        org.Access_Token__c = 'testToken';
        org.Sandbox_Info_Id__c = '0G123344';
        insert Org;
        
        Refresh_Template__c rt1 = new Refresh_Template__c();
        rt1.name = 'Test Template1';
        rt1.Parent_Org__c = org.id;
        rt1.Custom_Setting_Names__c = 'Test__c,Test1__c';
        insert rt1; 
        
        string customSettingJson = '{"size": 02,"totalSize": 02,"done": true,"queryLocator": null,"entityTypeName": "FieldDefinition","records": [{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBkX"},"Label": "Records","QualifiedApiName": "Records__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:44:10.000+0000"},{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBhJ"},"Label": "Read Result","QualifiedApiName": "Read_Result__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:43:49.000+0000"}]}';
        
        
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
        contentDocumentLink1.ShareType = 'V';  
        contentDocumentLink1.Visibility = 'AllUsers'; 
        insert contentDocumentLink1;
        
        Test.startTest();
        CSVFileReader.fetchCustomSettings(rt1.Id);
        Test.stopTest();  
        
    }
    
}