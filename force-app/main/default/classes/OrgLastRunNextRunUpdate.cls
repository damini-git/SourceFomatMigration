public class OrgLastRunNextRunUpdate implements TriggerHandlerBase.TriggerHandler {
    public static void handle(){
        Trigger_Control__c trigCon = Trigger_Control__c.getInstance();
        System.debug(trigCon.Trigger_On_Off__c);
        if(trigCon.Trigger_On_Off__c){
            Map<Id,Org__c>oldOrgMap = (Map<Id,Org__c>) trigger.oldMap;
            Map<Id,Org__c>newOrgMap = (Map<Id,Org__c>) trigger.newMap;
            for(Org__c org : newOrgMap.values()){
                System.debug(newOrgMap.get(org.Id).Status__c);
                System.debug(oldOrgMap.get(org.Id).Status__c);
                if((newOrgMap.get(org.Id).Status__c == 'Completed') && (oldOrgMap.get(org.Id).Status__c== 'Completed')){
                    if(org.Next_Run__c < System.now().addMinutes(2)){
                        org.Next_Run__c = null;
                    }
                    else if(org.Next_Schedule_On__c < System.now().addMinutes(2)){
                        org.Next_Schedule_On__c =  null;
                        org.Next_Schedule_Based_on_TimeZone__c = null;
                    }
                }
                /*List<AggregateResult>overallCoverageList = [Select Org__r.Id og, AVG(Total_Code_Coverage__c)aver from Code_Coverage__c Where Org__r.Id =: org.Id Group By Org__r.Id];
List<OrgCoverageTrends__c> orgTrendList = New List<OrgCoverageTrends__c>();
Map<Id,Decimal> overallCCOrgsList = New Map<Id,Decimal>();
for(AggregateResult agg : overallCoverageList){
//String orgId = (String)agg.get('Org__c');
Id orgId = String.valueOf(agg.get('og'));
System.debug(orgId);
Decimal overallCC = (Decimal)agg.get('aver');
overallCCOrgsList.put(orgId,overallCC);
}
if(org.Overall_Code_Coverage__c != overallCCOrgsList.get(org.Id)){
org.Overall_Code_Coverage__c = overallCCOrgsList.get(org.Id);
}*/
            }
        }
    }
}