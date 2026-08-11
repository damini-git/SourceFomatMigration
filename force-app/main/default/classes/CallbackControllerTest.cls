@isTest
public class CallbackControllerTest {
	@isTest
    static void testVFPageCallback(){
        String testCode = 'testCode';
        CallbackController.code = testCode;
        CodeCoverageUtilityTestDataFactory.createOrg();
        CodeCoverageUtilityTestDataFactory.createCustomSetting();
        CodeCoverageUtilityTestDataFactory.createCredsCustomSetting();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new CallbackControllerMock());
        CallbackController.captureCode();
        Org__c org = [Select Id, Name,Refresh_Token__c from Org__c where Name =: 'TestOrg123' Limit 1];
        Assert.areEqual(org.Refresh_Token__c, 'abcdefghijklmnopqrstuvwxyz', 'The value of Refresh_Token__c is not as expected.');
        Test.stopTest();
    }
}