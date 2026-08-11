public class OrgLastRunNextRunInsert implements TriggerHandlerBase.TriggerHandler{
    public static void handle(){
        Trigger_Control__c trigCon = Trigger_Control__c.getInstance();
        System.debug(trigCon.Trigger_On_Off__c);
        if(trigCon.Trigger_On_Off__c){
            List<Org__c>orgList = trigger.new;
            for(Org__c org : orgList){
                if(org.Next_Run__c < System.now().addMinutes(2)){
                    org.Next_Run__c = null;
                }
                if(org.Next_Schedule_On__c < System.now().addMinutes(2)){
                    org.Next_Schedule_On__c =  null;
                    org.Next_Schedule_Based_on_TimeZone__c = null;
                }
            }
        }
    }
}