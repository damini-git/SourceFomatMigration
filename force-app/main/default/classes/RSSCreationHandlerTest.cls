@isTest
public class RSSCreationHandlerTest {
	@isTest
    static void testMet(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new RSSCreationHandlerMock());
        Org__c org = CodeCoverageUtilityTestDataFactory.createOrg();
        org.Domain_URL__c = 'https://login.salesforce.com';
        update org;
        Assert.isNotNull(org.Domain_URL__c, 'There is no Domain Url');
        Test.stopTest();
    }
    @isTest
    static void testNotMet(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new RSSCreationHandlerMock());
        Org__c org = CodeCoverageUtilityTestDataFactory.createOrg();
        org.Domain_URL__c = 'https://test.salesforce.com';
        update org;
        Assert.isNotNull(org.Domain_URL__c, 'There is no Domain Url');
        Test.stopTest();
    }
}