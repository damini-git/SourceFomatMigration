@isTest
public class BulkCustomSettingsInsertionTest {
    @testSetUp
    static void setUp(){        
        org__c org = new org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'Test';
        org.Access_Token__c = 'testToken';
        org.Sandbox_Info_Id__c = '0G123344';
        insert Org;
        
        Refresh_Template__c rt = new Refresh_Template__c();
        rt.name = 'Test Template';
        rt.Parent_Org__c = org.id;
        rt.Custom_Setting_Names__c = 'fileName';
        insert rt; 
        
        Refresh_Template__c rt1 = new Refresh_Template__c();
        rt1.name = 'Test Template1';
        rt1.Parent_Org__c = org.id;
        rt1.Custom_Setting_Names__c = 'fileName';
        insert rt1;
        
        logs__c log = new Logs__c();
        log.Status__c = 'InProgress';
        log.Parent_Template__c = rt1.id;
        insert log;
        
        
         ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'fileName'; 
        contentVersion.PathOnClient =  '/' + contentVersion.Title + '.csv'; 
        contentVersion.VersionData = Blob.valueOf('Field1,Field2\nValue1,Value2\nValue3,Value4');
        insert contentVersion; 
        
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
    static void testInsertCustomSettingsUsingBulkAPI() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
       
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new BulkApiMock());
        CustomSettingsRestorationCall.callCustomSettingsBatch(rt.Id);
        //dataBase.executeBAtch(new BulkCustomSettingsInsertionBatch(rt.Id),1);
        Test.stopTest();
    }
        
    @isTest
    static void testInsertCustomSettingsUsingBulkAPI1() {
        //try{
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template1' limit 1];
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new BulkApiMock());
        CustomSettingsRestorationCall.callCustomSettingsBatch(rt.Id);
        Test.stopTest();
        /*}catch(exception e){
            system.debug(e.getMessage());
        }*/
    }
    
    @isTest
    static void testInsertCustomSettingsUsingBulkAPIInsertion1() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
       
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new BulkApiMock1());
        CustomSettingsRestorationCall.callCustomSettingsBatch(rt.Id);
        //dataBase.executeBAtch(new BulkCustomSettingsInsertionBatch(rt.Id),1);
        Test.stopTest();
    }
    
    @isTest
    static void testInsertCustomSettingsUsingBulkAPIInsertion2() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
       
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new BulkApiMock2());
        CustomSettingsRestorationCall.callCustomSettingsBatch(rt.Id);
        //dataBase.executeBAtch(new BulkCustomSettingsInsertionBatch(rt.Id),1);
        Test.stopTest();
    }
    
    @isTest
    static void testInsertCustomSettingsUsingBulkAPIInsertion3() {
        Refresh_Template__c rt =[SELECT Id, Name FROM Refresh_Template__c where name = 'Test Template'];
       
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new BulkApiMock3());
        CustomSettingsRestorationCall.callCustomSettingsBatch(rt.Id);
        //dataBase.executeBAtch(new BulkCustomSettingsInsertionBatch(rt.Id),1);
        Test.stopTest();
    }
        
    public class BulkApiMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();

            if(endpoint.contains('failedResults')){
                res.setBody('{"sf__Id": "","sf__Error" \n "DUPLICATE_VALUE:duplicate value found: SetupOwnerId duplicates value on record with id: 00DNS000000Fubt2AC:--","Name": "a00NS00000HIoPZ","Field_1__c": "Test Field 1"}');
            }
            else if(endpoint.contains('successfulResults')){
                res.setBody('{"sf__Id": "","sf__Created": "" \n "Name": "","Field_1__c": ""}');
            }
            else if (endpoint.contains('/services/data/v58.0/jobs/ingest')) {
                if (req.getMethod() == 'POST') {
                    res.setStatusCode(201);
                    res.setBody('{"id":"750D0000000XXXX","state":"Open"}');
                } else if (req.getMethod() == 'PUT') {
                    res.setStatusCode(201);
                    res.setBody('{"id":"750D0000000XXXX","state":"InProgress"}');
                } else if (req.getMethod() == 'PATCH') {
                    res.setStatusCode(200);
                    res.setBody('{"id":"750D0000000XXXX","state":"UploadComplete"}');
                }
            }
            return res;
        }
    }
    
    public class BulkApiMock1 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();

            if (endpoint.contains('/services/data/v58.0/jobs/ingest')) {
                if (req.getMethod() == 'POST') {
                    res.setStatusCode(400);
                    res.setBody('{"id":"750D0000000XXXX","state":"Open"}');
                }
            }
            return res;
        }
    }
    
    public class BulkApiMock2 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();

            if (endpoint.contains('/services/data/v58.0/jobs/ingest')) {
                if (req.getMethod() == 'POST') {
                    res.setStatusCode(201);
                    res.setBody('{"id":"750D0000000XXXX","state":"Open"}');
                } else if (req.getMethod() == 'PUT') {
                    res.setStatusCode(400);
                    res.setBody('{"id":"750D0000000XXXX","state":"InProgress"}');
                }
            }
            return res;
        }
    }
    public class BulkApiMock3 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();

            if (endpoint.contains('/services/data/v58.0/jobs/ingest')) {
                if (req.getMethod() == 'POST') {
                    res.setStatusCode(201);
                    res.setBody('{"id":"750D0000000XXXX","state":"Open"}');
                } else if (req.getMethod() == 'PUT') {
                    res.setStatusCode(201);
                    res.setBody('{"id":"750D0000000XXXX","state":"InProgress"}');
                } else if (req.getMethod() == 'PATCH') {
                    res.setStatusCode(400);
                    res.setBody('{"id":"750D0000000XXXX","state":"UploadComplete"}');
                }
            }
            return res;
        }
    }
}