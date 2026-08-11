@isTest
public class ExportCustomSettingToCSVQueueableTest {
    @testSetup
    static void setupTestData(){
        Org__c org = new Org__c();
        org.Name = 'TestOrg';
        org.Access_Token__c = 'Test AccesToken';
        org.Domain_URL__c = 'https://test.salesforce.com';
        insert org;
        
        Refresh_Template__c refTemp = new Refresh_Template__c();
        reftemp.Parent_Org__c = org.id;
        reftemp.Name = 'TestTemplate';
        reftemp.Custom_Setting_Names__c = 'ConnectedAppCreds__c';
        insert reftemp;
        
        Logs__c log = new Logs__c();
        log.Parent_Template__c = reftemp.id;
        log.Status__c = 'InProgress';
        log.Log_Type__c = 'Custom Settings Retrieve - Template Creation';
        insert log;       
    }
    @isTest
    static void testCalloutToExternalOrg(){
        List<String> fieldNames = new List<String>{'Field1__c', 'Field2__c'};
            
            Org__c testOrg = [SELECT Id,Name, Access_Token__c,Domain_URL__c FROM Org__c WHERE Name = 'TestOrg' ];
        Refresh_Template__c template = [SELECT Id, Name from Refresh_Template__c WHERE Name = 'TestTemplate' ];
        Logs__c log = [select Id, Name from Logs__c limit 1];
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        ExportCustomSettingToCSVQueueable.calloutToExternalOrg('ConnectedAppCreds__c', fieldNames, testOrg.Id, template.Id, testOrg.Access_Token__c, log.Id);
        test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :template.Id 
                                                ];
        system.debug('Cs Attachments Size 1----->>>'+attachments.size());
        
        System.assertEquals(1, attachments.size(), 'The Attachments Size should be 1 instead of '+attachments.size());
    }
    
    @isTest
    static void testCalloutToExternalOrg1(){
        List<String> fieldNames = new List<String>{'Field1__c', 'Field2__c'};
            
            Org__c testOrg = [SELECT Id,Name, Access_Token__c,Domain_URL__c FROM Org__c WHERE Name = 'TestOrg' ];
        Refresh_Template__c template = [SELECT Id, Name from Refresh_Template__c WHERE Name = 'TestTemplate' ];
        Logs__c log = [select Id, Name from Logs__c limit 1];
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock1());
        ExportCustomSettingToCSVQueueable.calloutToExternalOrg('ConnectedAppCreds__c', fieldNames, testOrg.Id, template.Id, testOrg.Access_Token__c, log.Id);
        test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :template.Id 
                                                ];
        system.debug('Cs Attachments Size 2------->>>>>>>'+attachments.size());
        
        
        System.assertEquals(0, attachments.size(), 'The Attachments Size should be 0 instead of '+attachments.size());
    }
    
    public class Mock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            
            if(endpoint.contains('/services/data/v58.0/query?q=')){
                res.setBody('{"totalSize":2,"done":true,"records":[{"attributes":{"type":"ConnectedAppCreds__c"},"Name":"Test cred","CallbackUrl__c":"https://ardevelopers3-dev-ed.develop.my.salesforce.com/apex/AuthCodeCallbackVfp","Key__c":"nkedmelfenfke","Secret__c":"ndkenfkendejnfjednked"},{"attributes":{"type":"ConnectedAppCreds__c"},"Name":"Test cred2","CallbackUrl__c":"g trbgrbb","Key__c":"rbrtbrtbrtbrtb","Secret__c":"rtbrtbrtbrtb"}]}');
                res.setStatusCode(200);
            }
            return res;
        }
    }
    
    public class Mock1 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            
            if(endpoint.contains('/services/data/v58.0/query?q=')){
                res.setBody('{"totalSize":2,"done":true,"records":[{"attributes":{"type":"ConnectedAppCreds__c"},"Name":"Test cred","CallbackUrl__c":"https://ardevelopers3-dev-ed.develop.my.salesforce.com/apex/AuthCodeCallbackVfp","Key__c":"nkedmelfenfke","Secret__c":"ndkenfkendejnfjednked"},{"attributes":{"type":"ConnectedAppCreds__c"},"Name":"Test cred2","CallbackUrl__c":"g trbgrbb","Key__c":"rbrtbrtbrtbrtb","Secret__c":"rtbrtbrtbrtb"}]}');
                res.setStatusCode(401);
            }else if (req.getEndpoint().contains('/services/oauth2/token?grant_type=refresh_token&client_id=')){
                res.setBody('{"access_token": "01020304050607.123456789","signature": "abcdefghijklmnopq","scope": "refresh_token full","instance_url": "https://test.salesforce.com","id": "https://test.salesforce.com/id/0","token_type": "Bearer","issued_at": "1627054"}');
                res.setStatusCode(401);
            }
            return res;
        }
    }
}