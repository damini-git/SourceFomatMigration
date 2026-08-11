/*Author -- Teja Amere
* Description - This class helps to convert Next_Schedule_On__c value to user's desired time zone which is given in Desired_TimeZone__c
* RUNS ON BEFORE INSERT TRIGGER
* */
public class ConvertTimeZoneToUser implements TriggerHandlerBase.TriggerHandler {
    public static void handle(){
        Trigger_Control__c trigCon = Trigger_Control__c.getInstance();
        System.debug(trigCon.Trigger_On_Off__c);
        if(trigCon.Trigger_On_Off__c){
            List<Org__c> orgList = trigger.new;
            for(Org__c org : orgList){
                if(org.Desired_TimeZone__c != null && org.Next_Schedule_On__c != null){
                    Datetime originalDateTime = org.Next_Schedule_On__c;
                    String targetTimezone = org.Desired_TimeZone__c;
                    String userTimezone = UserInfo.getTimeZone().getID();
                    System.debug(originalDateTime);
                    Datetime userDateTime = DateTime.valueOf(originalDateTime.format('yyyy-MM-dd HH:mm:ss', userTimezone));
                    Datetime targetDateTime = DateTime.valueOf(userDateTime.format('yyyy-MM-dd HH:mm:ss', targetTimezone));
                    org.Next_Schedule_Based_on_TimeZone__c = targetDateTime;
                }
            }
        }
    }
}