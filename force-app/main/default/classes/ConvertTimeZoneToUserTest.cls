/*** Author - Teja Amere
 * Description - This is test class for ConvertTimeZoneToUser
 * */

/*** Author - Teja Amere
 * Description - This is test class for ConvertTimeZoneToUser
 * */

@isTest
public class ConvertTimeZoneToUserTest {
    @isTest
    static void convertTimeZone() {
        Trigger_Control__c trigCon = new Trigger_Control__c();
        trigCon.Trigger_On_Off__c = true;
        insert trigCon;

        Org__c org = new Org__c();
        org.Name = 'Test Org';
        org.Next_Schedule_On__c = System.now();
        org.Desired_TimeZone__c = 'America/New_York';

        insert org;

        Org__c updatedOrg = [SELECT Id, Next_Schedule_Based_on_TimeZone__c, Next_Schedule_On__c, Desired_TimeZone__c FROM Org__c WHERE Id = :org.Id];

        System.assertNotEquals(org.Next_Schedule_On__c, updatedOrg.Next_Schedule_Based_on_TimeZone__c, 'The Next_Schedule_Based_on_TimeZone__c should be updated');

        trigCon.Trigger_On_Off__c = false;
        update trigCon;

        Org__c org2 = new Org__c();
        org2.Name = 'Test Org 2';
        org2.Next_Schedule_On__c = System.now();
        org2.Desired_TimeZone__c = 'America/Los_Angeles';
        insert org2;

        Org__c updatedOrg2 = [SELECT Id, Next_Schedule_Based_on_TimeZone__c, Next_Schedule_On__c, Desired_TimeZone__c FROM Org__c WHERE Id = :org2.Id];

        System.assertEquals(null, updatedOrg2.Next_Schedule_Based_on_TimeZone__c, 'The Next_Schedule_Based_on_TimeZone__c should not be updated when the trigger is off');

        // Additional test cases for coverage
        Org__c org3 = new Org__c();
        org3.Name = 'Test Org 3';

        Org__c org4 = new Org__c();
        org4.Name = 'Test Org 4';
        org4.Next_Schedule_On__c = System.now();

        insert new List<Org__c>{org3, org4};
         Test.startTest();
        ConvertTimeZoneToUser.handle();
        Test.stopTest();

        Org__c updatedOrg3 = [SELECT Id, Next_Schedule_Based_on_TimeZone__c FROM Org__c WHERE Id = :org3.Id];
        Org__c updatedOrg4 = [SELECT Id, Next_Schedule_Based_on_TimeZone__c FROM Org__c WHERE Id = :org4.Id];

        System.assertEquals(null, updatedOrg3.Next_Schedule_Based_on_TimeZone__c, 'The Next_Schedule_Based_on_TimeZone__c should not be updated for org3');
        System.assertEquals(null, updatedOrg4.Next_Schedule_Based_on_TimeZone__c, 'The Next_Schedule_Based_on_TimeZone__c should not be updated for org4 when Desired_TimeZone__c is not set');
    }
}