public class CustomSettingsRestorationCall {
    @AuraEnabled
    public static void callCustomSettingsBatch(string recordId){
        id refTempId = recordId;
        Logs__c log = new Logs__c();
        log.Log_Type__c = 'Custom Settings Restoration - Post Refresh';
        log.Parent_Template__c = refTempId;
        log.Status__c = 'InProgress';
        
        database.executeBatch(new BulkCustomSettingsInsertionBatch(recordId,log),1);
    }
}