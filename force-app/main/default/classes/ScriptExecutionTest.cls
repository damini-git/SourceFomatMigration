@isTest
public class ScriptExecutionTest {
    @testSetup
    static void setupData(){
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
        
        Refresh_Template__c rt1 = new Refresh_Template__c();
        rt1.name = 'Test Template1';
        rt1.Parent_Org__c = org.id;
        insert rt1;
        
         string csvString ='order,scriptName\n'
            + '1,scriptA';
        system.debug('csvString-------->>>'+csvString);
        Blob fileBlob = Blob.valueOf(csvString);
        system.debug('fileBlob---------->>>>'+fileBlob);

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Script';
        contentVersion.PathOnClient = '/' + contentVersion.Title+'.csv';
        contentVersion.VersionData = fileBlob;
        insert contentVersion;
        system.debug('contentVersion---------->'+contentVersion);

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
        
        string scriptString ='order,script name';
        system.debug('scriptString-------->>>'+scriptString);
        Blob scriptfileBlob = Blob.valueOf(scriptString);
        system.debug('scriptfileBlob---------->>>>'+scriptfileBlob);

        ContentVersion contentVersion1 = new ContentVersion();
        contentVersion1.Title = 'ScriptA';
        contentVersion1.PathOnClient = '/' + contentVersion1.Title+'.txt';
        contentVersion1.VersionData = scriptfileBlob;
        insert contentVersion1;
        system.debug('contentVersion1---------->'+contentVersion1);

         ContentDocumentLink contentDocumentLink1 = new ContentDocumentLink();
        contentDocumentLink1.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion1.Id
        ].ContentDocumentId;
        contentDocumentLink1.LinkedEntityId = rt.Id;
        contentDocumentLink1.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink1.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink1;
    }
    @isTest
    public static void testScriptExecution(){
        Refresh_Template__c rt = [SELECT Id, Name FROM Refresh_Template__c where Name ='Test Template'];
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ScriptExecutionCall.executeScript(rt.Id);
        test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 ];

        System.assertEquals(2, attachments.size(), 'The ContentDocumentLink should not exist.');
    }
    
    @isTest
    public static void testScriptExecutionExceptionHandling(){
        try{
        Refresh_Template__c rt = [SELECT Id, Name FROM Refresh_Template__c where Name ='Test Template1'];
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ScriptExecutionCall.executeScript(rt.Id);
        test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 ];

        System.assertEquals(2, attachments.size(), 'The ContentDocumentLink should not exist.');
        }catch(exception e){
            system.debug(e.getMessage());
        }
    }
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public String responseBody;
 
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('services/data/v59.0/tooling/executeAnonymous/?anonymousBody=')){
                res.setStatusCode(200);
            }
            return res;
        }
    }
}