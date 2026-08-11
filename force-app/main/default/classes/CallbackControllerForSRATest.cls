@isTest
public class CallbackControllerForSRATest {
    @isTest
    static void testVFPageCallback(){
        String testCode = 'testCode';
        CallbackControllerForSRA.code = testCode;
        Org__c org = new Org__c(Name = 'TestOrg123',
                                Domain_Url__c = 'https://test.salesforce.com',
                                Access_Token__c = '12344',
                                Org_Type__c = 'Production',
                                Refresh_Token__c = 'abcdefghijklmnopqrstuvwxyz');
        insert org;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTemp',
                                                              Parent_Org__c = org.Id);
        insert refTemp;
        
        Logs__c reAuthLog = new Logs__c(Log_Type__c = 'Re-Authenticate',
                                        Parent_Template__c = refTemp.Id);
        insert reAuthLog;
        
        LogId__c logId = LogId__c.getInstance();
        logId.Id__c = reAuthLog.Id;
        upsert logId;
        
        ConnectedAppCredentialsForSRA__c creds = ConnectedAppCredentialsForSRA__c.getInstance();
        creds.Key__c = 'iuhddiuayd98doqwhd98xsidpsd';
        creds.Secret__c = 'dwdu8wd8hopwndi9w8yd9a8sndoasyud';
        creds.CallbackUrl__c = 'https://cloudfulcrum.copadodev.com';
        upsert creds;
        
        CodeCoverageUtilityTestDataFactory.createCustomSetting();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new CallbackControllerMock());
        CallbackControllerForSRA.captureCode();
        Org__c org1 = [Select Id, Name,Refresh_Token__c from Org__c where Name =: 'TestOrg123' Limit 1];
        Assert.areEqual(org1.Refresh_Token__c, 'abcdefghijklmnopqrstuvwxyz', 'The value of Refresh_Token__c is not as expected.');
        Test.stopTest();
    }
    
    @isTest
    static void testCatchBlock(){
        String testCode = 'testCode';
        CallbackControllerForSRA.code = testCode;
        
        Org__c org = new Org__c(Name = 'TestOrg123',
                                Domain_Url__c = 'https://test.salesforce.com',
                                Access_Token__c = '12344',
                                Org_Type__c = 'Production',
                                Refresh_Token__c = 'abcdefghijklmnopqrstuvwxyz');
        insert org;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTemp',
                                                              Parent_Org__c = org.Id);
        insert refTemp;
        
        Logs__c reAuthLog = new Logs__c(Log_Type__c = 'Re-Authenticate',
                                        Parent_Template__c = refTemp.Id);
        insert reAuthLog;
        
        LogId__c logId = LogId__c.getInstance();
        logId.Id__c = reAuthLog.Id;
        upsert logId;
        
        ConnectedAppCredentialsForSRA__c creds = ConnectedAppCredentialsForSRA__c.getInstance();
        creds.Key__c = 'iuhddiuayd98doqwhd98xsidpsd';
        creds.Secret__c = 'dwdu8wd8hopwndi9w8yd9a8sndoasyud';
        creds.CallbackUrl__c = 'https://cloudfulcrum.copadodev.com';
        upsert creds;
        
        CodeCoverageUtilityTestDataFactory.createCustomSetting();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new CallbackControllerMockFailure());
        CallbackControllerForSRA.captureCode();
        Org__c org1 = [Select Id, Name,Refresh_Token__c from Org__c where Name =: 'TestOrg123' Limit 1];
        Assert.areEqual(org1.Refresh_Token__c, 'abcdefghijklmnopqrstuvwxyz', 'The value of Refresh_Token__c is not as expected.');
        Test.stopTest();        
    }
    
    private class CallbackControllerMockFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/x-www-form-urlencoded');
            res.setStatusCode(400);
            res.setBody('Bad Request');
            return res;
        }
    }
}