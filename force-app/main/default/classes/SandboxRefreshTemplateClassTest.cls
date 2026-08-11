@isTest
public class SandboxRefreshTemplateClassTest {

    @testSetup
    static void setupTestData() {
        // Create Org
        Org__c org = new Org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'Test';
        org.Access_Token__c = 'testToken';
        org.Sandbox_Info_Id__c = '0G123344';
        insert org;

    
        Refresh_Template__c rt1 = new Refresh_Template__c(Name = 'RT-Meta-InProgress', Parent_Org__c = org.Id);
        insert rt1;

        Logs__c metadataInProgress = new Logs__c(
            Log_Type__c = 'Metadata - Backup Regeneration',
            Status__c = 'InProgress',
            Parent_Template__c = rt1.Id
        );
        insert metadataInProgress;

    
        Refresh_Template__c rt2 = new Refresh_Template__c(Name = 'RT-Meta-Success', Parent_Org__c = org.Id);
        insert rt2;

        Logs__c metadataSuccess = new Logs__c(
            Log_Type__c = 'Metadata - Backup Regeneration',
            Status__c = 'Success',
            Parent_Template__c = rt2.Id
        );
        insert metadataSuccess;

        
        Refresh_Template__c rt3 = new Refresh_Template__c(Name = 'RT-Data-InProgress', Parent_Org__c = org.Id);
        insert rt3;

        Logs__c userDataInProgress = new Logs__c(
            Log_Type__c = 'Users - Backup Regeneration',
            Status__c = 'InProgress',
            Parent_Template__c = rt3.Id
        );
        insert userDataInProgress;

        
        Refresh_Template__c rt4 = new Refresh_Template__c(Name = 'RT-Data-Success', Parent_Org__c = org.Id);
        insert rt4;

        Logs__c sJobsSuccess = new Logs__c(
            Log_Type__c = 'Scheduled Jobs - Backup Regeneration',
            Status__c = 'Success',
            Parent_Template__c = rt4.Id
        );
        insert sJobsSuccess;
        
        Refresh_Template__c rtDataRestore = new Refresh_Template__c(Name = 'RT-DataRestore-Success', Parent_Org__c = org.Id);
        insert rtDataRestore;

        Logs__c userDataRestoreLog = new Logs__c(
            Log_Type__c = 'User Restoration - Post Refresh',
            Status__c = 'InProgress',
            Parent_Template__c = rtDataRestore.Id
        );
        insert userDataRestoreLog;

        // Logs for warning message tests
        Refresh_Template__c warningTemplate = new Refresh_Template__c(Name = 'RT-Warning', Parent_Org__c = org.Id);
        insert warningTemplate;

        Logs__c log1 = new Logs__c(
            Log_Type__c = 'Custom Settings Retrieve - Template Creation',
            Status__c = 'InProgress',
            Parent_Template__c = warningTemplate.Id
        );

        Logs__c log2 = new Logs__c(
            Log_Type__c = 'Scheduled Jobs Retrieve - Update Template',
            Status__c = 'InProgress',
            Parent_Template__c = warningTemplate.Id
        );

        Logs__c unrelatedLog = new Logs__c(
            Log_Type__c = 'Custom Settings - Backup Regeneration',
            Status__c = 'InProgress',
            Parent_Template__c = warningTemplate.Id
        );

        insert new List<Logs__c>{ log1, log2, unrelatedLog };

    }

    @isTest
    public static void testMetaExecuteDisableButtonTrue() {
        Id templateId = [SELECT Id FROM Refresh_Template__c WHERE Name = 'RT-Meta-InProgress' LIMIT 1].Id;

        Test.startTest();
        Boolean result = SandboxRefreshTemplateClass.metaExecuteDisableButton(templateId);
        Test.stopTest();

        System.assertEquals(true, result, 'Should return TRUE for Metadata InProgress');
    }

    @isTest 
    public static void testMetaExecuteDisableButtonFalse() {
        Id templateId = [SELECT Id FROM Refresh_Template__c WHERE Name = 'RT-Meta-Success' LIMIT 1].Id;

        Test.startTest();
        Boolean result = SandboxRefreshTemplateClass.metaExecuteDisableButton(templateId);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return FALSE for Metadata Success');
    }

    @isTest 
    public static void testHasDataInProgressBackupLogsTrue() {
        Id templateId = [SELECT Id FROM Refresh_Template__c WHERE Name = 'RT-Data-InProgress' LIMIT 1].Id;

        Test.startTest();
        Boolean result = SandboxRefreshTemplateClass.hasDataInProgressBackupLogs(templateId);
        Test.stopTest();

        System.assertEquals(true, result, 'Should return TRUE for Data InProgress');
    }

    @isTest 
    public static void testHasDataInProgressBackupLogsFalse() {
        Id templateId = [SELECT Id FROM Refresh_Template__c WHERE Name = 'RT-Data-Success' LIMIT 1].Id;

        Test.startTest();
        Boolean result = SandboxRefreshTemplateClass.hasDataInProgressBackupLogs(templateId);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return FALSE for Data Success');
    }

    @isTest 
    public static void testGetLatestLogs() {
        Id templateId = [SELECT Id FROM Refresh_Template__c WHERE Name = 'RT-Data-InProgress' LIMIT 1].Id;

        Test.startTest();
        List<Logs__c> logs = SandboxRefreshTemplateClass.getLatestLogs(templateId);
        Test.stopTest();

        System.assert(logs.size() > 0, 'Should return latest logs');
        
    }

    @isTest 
    public static void testGetAllDataRestoreStatuses() {
        Id templateId = [SELECT Id FROM Refresh_Template__c WHERE Name = 'RT-DataRestore-Success' LIMIT 1].Id;

        Test.startTest();
        Map<String, String> result = SandboxRefreshTemplateClass.getAllDataRestoreStatuses(templateId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('User Restoration - Post Refresh'), 'Result should contain User Restoration log type');
        System.assertEquals('InProgress', result.get('User Restoration - Post Refresh'), 'User Restoration status should be InProgress');
    }

    @isTest 
    public static void testGetAllDataRestoreInprogressStatuses() {
        Id templateId = [SELECT Id FROM Refresh_Template__c WHERE Name = 'RT-DataRestore-Success' LIMIT 1].Id;

        Test.startTest();
        Map<String, String> result = SandboxRefreshTemplateClass.getAllDataRestoreInprogressStatuses(templateId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('User Restoration - Post Refresh'), 'Result should contain User Restoration log type');
        System.assertEquals('InProgress', result.get('User Restoration - Post Refresh'), 'User Restoration status should be InProgress');
    }

    @isTest
    public static void testGetLatestRefreshLogCreatedDate() {
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];
        Refresh_Template__c rt = new Refresh_Template__c(Name = 'RT-Sandbox-Refresh', Parent_Org__c = org.Id);
        insert rt;

        Logs__c oldLog = new Logs__c(
            Log_Type__c = 'Sandbox Refresh',
            Status__c = 'Success',
            Parent_Template__c = rt.Id
        );
        insert oldLog;

        Test.startTest();

        Logs__c latestLog = new Logs__c(
            Log_Type__c = 'Sandbox Refresh',
            Status__c = 'Success',
            Parent_Template__c = rt.Id
        );
        insert latestLog;

        Datetime result = SandboxRefreshTemplateClass.getLatestRefreshLogCreatedDate(rt.Id);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Resulting CreatedDate should not be null');
    }
   
    
     @isTest
    static void testHasCompletedRefreshLog() {
        Org__c org = new Org__c(Name = 'Test Org');
        insert org;

        Refresh_Template__c template = new Refresh_Template__c(Name = 'Test Template', Parent_Org__c = org.Id);
        insert template;

        Logs__c validLog = new Logs__c(
            Parent_Template__c = template.Id,
            Log_Type__c = 'Sandbox Refresh',
            Status__c = 'Completed'
        );
        insert validLog;

        Test.startTest();
        Boolean result = SandboxRefreshTemplateClass.hasCompletedRefreshLog(template.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true when valid log exists');
    }

    @isTest
    static void testHasCompletedRefreshLogForbidden() {
        Org__c org = new Org__c(Name = 'Test Org 2');
        insert org;

        Refresh_Template__c template = new Refresh_Template__c(Name = 'Test Template 2', Parent_Org__c = org.Id);
        insert template;

        Logs__c forbiddenLog = new Logs__c(
            Parent_Template__c = template.Id,
            Log_Type__c = 'Sandbox Refresh',
            Status__c = 'Forbidden'
        );
        insert forbiddenLog;

        Test.startTest();
        Boolean result = SandboxRefreshTemplateClass.hasCompletedRefreshLog(template.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when only Forbidden log exists');
    }

    @isTest
    static void testGetInProgressTemplateLogs() {
        Id templateId = [SELECT Id FROM Refresh_Template__c WHERE Name = 'RT-Warning' LIMIT 1].Id;

        Test.startTest();
        List<Logs__c> result = SandboxRefreshTemplateClass.getInProgressTemplateLogs(templateId);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return only logs ending with Template Creation or Update Template and InProgress');
        for (Logs__c log : result) {
            System.assertEquals('InProgress', log.Status__c);
            System.assert(
                log.Log_Type__c.endsWith('Template Creation') || log.Log_Type__c.endsWith('Update Template'),
                'Returned log should match the correct type'
            );
        }
    }


}