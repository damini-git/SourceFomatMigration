@isTest
public class AuthorizationCodeFlowForSRATest {
    @TestSetup
    static void makeData(){
        CodeCoverageUtilityTestDataFactory.createOrg();
        CodeCoverageUtilityTestDataFactory.createCredsCustomSetting();
        Org__c org = [Select Id, Name, Access_Token__c, Domain_Url__c from Org__c where Name = 'TestOrg123'];
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTemp',
                                                             Parent_Org__c = org.Id);
        insert refTemp;
    }
    @isTest
    static void testMet(){
        Org__c org = [Select Id, Name, Access_Token__c, Domain_Url__c from Org__c where Name = 'TestOrg123'];
        Refresh_Template__c refTemp = [Select Id, Name, Parent_Org__c from Refresh_Template__c Where Name = 'testTemp'];
              // Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AuthorizationCodeFlowMock());
        Test.startTest();
        String checkStr = AuthorizationCodeFlowForSRA.auth(org.Id, refTemp.Id);
        Test.stopTest();
        Assert.areEqual(checkStr, 'Redirected to the Login Page', 'The return value is not as expected.');
    }
    
    @isTest
    static void testMet2(){
        Org__c org = [Select Id, Name, Access_Token__c, Domain_Url__c from Org__c where Name = 'TestOrg123'];
        
        Test.startTest();
        try {
            String checkStr = AuthorizationCodeFlowForSRA.auth(org.Id, null);
        } catch (Exception e) {
            System.assert(e instanceof DmlException, 'Expected a DmlException');
        }
        Test.stopTest();
    }
}