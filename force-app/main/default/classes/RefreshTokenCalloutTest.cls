@isTest
public class RefreshTokenCalloutTest {
	@isTest
    static void testRun(){
        Org__c org = CodeCoverageUtilityTestDataFactory.createOrg();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new RefreshTokenCalloutMock());
        String checkStr = RefreshTokenCallout.fetchAT1(org.Id);
        Assert.areEqual(checkStr, '123456789', 'The returned value did not match the expected value.');
    }
}