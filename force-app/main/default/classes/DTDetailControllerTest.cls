@isTest
public class DTDetailControllerTest {

    @isTest
    static void testGetUniqueFilesForRecord() {
        // Create test logs__c
        logs__c acc = new logs__c(log_type__c = 'Data Transformation');
        insert acc;

        // Insert ContentVersion (this auto-creates ContentDocument)
        ContentVersion ver = new ContentVersion(
            Title = 'TestFile.csv',
            PathOnClient = 'TestFile.csv',
            VersionData = Blob.valueOf('Name,Email\nJohn,john@example.com')
        );
        insert ver;

        // Fetch the generated ContentDocumentId
        ver = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :ver.Id LIMIT 1];

        // Link the file to the logs__c via ContentDocumentLink
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = ver.ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        Test.startTest();
        List<DTDetailController.FileInfo> files1 = new List<DTDetailController.FileInfo>();
        files1 = DTDetailController.getUniqueFilesForRecord(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, files1, 'File list should not be null');
        System.assertEquals(1, files1.size(), 'One file expected');
        System.assertEquals('TestFile.csv', files1[0].title, 'File title should match');
    }

    @isTest
    static void testGetMergedFileBodyByName() {
        // Create a test logs__c
        logs__c acc = new logs__c(log_type__c = 'Data Transformation');
        insert acc;

        List<ContentVersion> versions = new List<ContentVersion>();

        // Insert two ContentVersions with the same Title
        for (Integer i = 1; i <= 2; i++) {
            ContentVersion ver = new ContentVersion(
                Title = 'MergeTest.csv',
                PathOnClient = 'MergeTest.csv',
                VersionData = Blob.valueOf('Name,Email\nUser'+i+',user'+i+'@example.com')
            );
            versions.add(ver);
        }
        insert versions;

        // Query back ContentDocumentIds and link them to the logs__c
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion v : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versions]) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = v.ContentDocumentId,
                LinkedEntityId = acc.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert links;

        Test.startTest();
        String merged = DTDetailController.getMergedFileBodyByName(acc.Id, 'MergeTest.csv');
        Test.stopTest();

        System.assertNotEquals(null, merged, 'Merged content should not be null');
        System.assert(merged.contains('Name,Email'), 'Merged content must contain headers');
        System.assert(merged.contains('user1@example.com'), 'Merged content must contain User1 data');
        System.assert(merged.contains('user2@example.com'), 'Merged content must contain User2 data');
    }
}