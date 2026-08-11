@isTest
public class AuthorizationCodeFlowTest {
    @testSetup
    static void makeData(){
        CodeCoverageUtilityTestDataFactory.createOrg();
        CodeCoverageUtilityTestDataFactory.createCredsCustomSetting();
    }
	@isTest
    static void testMet(){
        Org__c org = [Select Id, Name, Access_Token__c, Domain_Url__c from Org__c where Name = 'TestOrg123'];
       // Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthorizationCodeFlowMock());
        test.startTest();
        String checkStr = AuthorizationCodeFlow.auth(org.Id);
        test.stopTest();
      //  Test.stopTest();
       Assert.areEqual(checkStr, 'Redirected to the Login Page', 'The return value is not as expected.');
    }
}