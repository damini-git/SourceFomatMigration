@isTest
public class OrgLastRunNextRunUpdateTest {
    @testSetup
    Public Static void checkTest(){
        Trigger_Control__c trigCon = Trigger_Control__c.getInstance();
        trigcon.Trigger_On_Off__c = True;
        insert trigcon;
    }
    @isTest
    public static void checkTest1(){
        CodeCoverageUtilityTestDataFactory.createLastNextOrg();
        Org__c orgCheck = [Select Next_Run__c, Next_Schedule_On__c from Org__c Where Name =: 'TestOrgLN'];
        Assert.isNull(orgCheck.Next_Run__c, 'There is no next run');
    }
    @isTest
    public static void checkTest2(){
        Org__c org = CodeCoverageUtilityTestDataFactory.createLastNextOrg();
        org.Next_Schedule_On__c = DateTime.newInstance(2023, 6, 25, 18, 30, 0);
        org.Next_Run__c = System.now().addhours(1);
        update org;
        Test.startTest();
        Org__c orgCheck = [Select Next_Run__c, Next_Schedule_On__c from Org__c Where Name =: 'TestOrgLN'];
        Assert.isnotNull(orgCheck.Next_Run__c, 'There is no next run');
        Test.stopTest();
    }
}