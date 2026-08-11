//*** Damini */
public with sharing class SandboxRefreshTemplateClass {
   @AuraEnabled
    public static Boolean metaExecuteDisableButton(Id refreshTemplateId) {
        List<Logs__c> logs = [
            SELECT Id, Parent_Template__c, Log_Type__c, Status__c
            FROM Logs__c 
            WHERE Parent_Template__c = :refreshTemplateId
            AND Log_Type__c = 'Metadata - Backup Regeneration'
            AND Status__c != 'Success'
            AND Status__c != 'Failed'
            LIMIT 1
        ];
        return !logs.isEmpty();
    }

    @AuraEnabled
    public static Boolean hasDataInProgressBackupLogs(Id refreshTemplateId) {
        List<Logs__c> logs = [
            SELECT Id, Parent_Template__c, Log_Type__c, Status__c
            FROM Logs__c 
            WHERE Parent_Template__c = :refreshTemplateId
            AND Log_Type__c IN (
                'Users - Backup Regeneration', 
                'Scheduled Jobs - Backup Regeneration', 
                'Custom Settings - Backup Regeneration'
            )
            AND Status__c != 'Success'
            AND Status__c != 'Failed'
            LIMIT 1
        ];
        return !logs.isEmpty();
    }


    @AuraEnabled
    public static List<Logs__c> getLatestLogs(Id refreshTemplateId) {
        return [
            SELECT Id, Name, Log_Type__c, Status__c, LastModifiedDate
            FROM Logs__c
            WHERE Parent_Template__c = :refreshTemplateId
            AND Log_Type__c IN (
                'Metadata - Backup Regeneration',
                'Users - Backup Regeneration',
                'Scheduled Jobs - Backup Regeneration',
                'Custom Settings - Backup Regeneration'
            )
            ORDER BY LastModifiedDate DESC
        ];
    }

    @AuraEnabled
    public static Map<String, String> getAllDataRestoreStatuses(Id templateId) {
        Map<String, String> statusMap = new Map<String, String>();

        List<Logs__c> logs = [
            SELECT Log_Type__c, Status__c, LastModifiedDate
            FROM Logs__c
            WHERE Parent_Template__c = :templateId
            AND Log_Type__c IN (
                'User Restoration - Post Refresh',
                'Custom Settings Restoration - Post Refresh'
            )
            ORDER BY LastModifiedDate DESC
        ];

        for (Logs__c log : logs) {
            if (!statusMap.containsKey(log.Log_Type__c)) {
                statusMap.put(log.Log_Type__c, log.Status__c);
            }
        }

        return statusMap;
    }

     @AuraEnabled
    public static Map<String, String> getAllDataRestoreInprogressStatuses(Id templateId) {
        Map<String, String> statusMap = new Map<String, String>();

        List<Logs__c> logs = [
            SELECT Log_Type__c, Status__c, LastModifiedDate
            FROM Logs__c
            WHERE Parent_Template__c = :templateId
            AND Log_Type__c IN (
                'User Restoration - Post Refresh',
                'Custom Settings Restoration - Post Refresh'
            ) AND Status__c = 'InProgress'
            ORDER BY LastModifiedDate DESC
        ];

        for (Logs__c log : logs) {
            if (!statusMap.containsKey(log.Log_Type__c)) {
                statusMap.put(log.Log_Type__c, log.Status__c);
            }
        }

        return statusMap;
    }

    @AuraEnabled(cacheable=true)
    public static Datetime getLatestRefreshLogCreatedDate(Id templateId) {
        List<Logs__c> logs = [
            SELECT CreatedDate
            FROM Logs__c
            WHERE Parent_Template__c = :templateId
            AND Log_Type__c = 'Sandbox Refresh'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (!logs.isEmpty()) {
            return logs[0].CreatedDate;
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasCompletedRefreshLog(Id templateId) {
        List<Logs__c> sandRefLogs = [
            SELECT Id
            FROM Logs__c
            WHERE Parent_Template__c = :templateId
            AND Log_Type__c = 'Sandbox Refresh'
            AND Status__c != 'Forbidden'
            LIMIT 1
        ];
        return (sandRefLogs.size() > 0) ? true : false;
    }

     @AuraEnabled(cacheable=true)
    public static List<Logs__c> getInProgressTemplateLogs(Id templateId) {
        List<Logs__c> logList = new  List<Logs__c>();

        logList = [
            SELECT Id, Name, Log_Type__c, Status__c
            FROM Logs__c
            WHERE Parent_Template__c = :templateId
            AND (
                Log_Type__c LIKE '%Template Creation'
                OR Log_Type__c LIKE '%Update Template'
            )
            AND Status__c = 'InProgress'
        ];

        if(logList.size()>0){
            return logList;
        }
        else{
            return null;
        }
    }
}