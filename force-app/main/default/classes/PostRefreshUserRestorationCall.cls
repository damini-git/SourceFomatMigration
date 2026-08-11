public class PostRefreshUserRestorationCall {
    @AuraEnabled
    public static void callRestoreBatch(Id recordId) {
        Logs__c log = new Logs__c();
        log.Status__c = 'InProgress';
        try {
            Id refTempId = recordId;
            log.Log_Type__c = 'User Restoration - Post Refresh';
            log.Parent_Template__c = refTempId;
            
            List<Logs__c> grouplogs = [SELECT Id, Name, Log_Type__c, Last_Refreshed_Public_Group_Id__c, Parent_Template__c 
                                       FROM Logs__c 
                                       WHERE Parent_Template__c = :recordId 
                                       AND Log_Type__c = 'Sandbox Refresh' 
                                       LIMIT 1];
            
            Id groupId;
            if (grouplogs.isEmpty()) {
                groupId = null;
            } else {
                groupId = grouplogs[0].Last_Refreshed_Public_Group_Id__c;
            }
            database.executeBatch(new PostRefreshUserRestoration(refTempId, log, groupId));
        } catch (Exception e) {
            if (log.Status__c == 'InProgress') {
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                insert log;
            }
            system.debug(e.getMessage());
        }
    }
}