@isTest
public class CreateScriptTemplateTest {
    @isTest
    static void createTemplateWithData(){
        org__c org = new org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'Test';
        org.Access_Token__c = 'testToken';
        org.Sandbox_Info_Id__c = '0G123344';
        insert Org;
        
        Refresh_Template__c rt = new Refresh_Template__c();
        rt.name = 'Test Template';
        rt.Parent_Org__c = org.id;
        insert rt;   
        
        String jsonData = '[{"ScriptName":"WorkflowAlert","ScriptData":"Suffix"},{"ScriptName":"CustomLabel","ScriptData":"Search & Replace"}]';
        
        string csvString ='order,scriptname\n'
            + '1,scriptA\n'
            + '2,scriptB';
        
        Logs__c scriptLog = new Logs__c();
        scriptLog.Log_Type__c = 'Apex Script Template Creation';
        scriptLog.Status__c = 'InProgress';
        scriptLog.Parent_Template__c = rt.Id;
        insert scriptLog;
        
        test.startTest();
        CreateScriptTemplate.scriptData(rt.id, scriptLog.Id, jsonData, csvString);
        test.stopTest();
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 ];
        system.debug(attachments[0].ContentDocument.Title);
        system.debug(attachments[1].ContentDocument.Title);

        System.assertEquals(3, attachments.size(), 'The ContentDocumentLink should exist.');
    }
    
     @isTest
    static void createTemplateWithoutData(){
        org__c org = new org__c();
        org.Name = 'testOrg';
        org.Domain_Url__c = 'Test';
        org.Access_Token__c = 'testToken';
        org.Sandbox_Info_Id__c = '0G123344';
        insert Org;
        
        Refresh_Template__c rt = new Refresh_Template__c();
        rt.name = 'Test Template';
        rt.Parent_Org__c = org.id;
        insert rt;   
        
        //String jsonData = '[{"ScriptName":"WorkflowAlert","ScriptData":"Suffix"},{"ScriptName":"CustomLabel","ScriptData":"Search & Replace"}]';
        
        /*string csvString ='order,scriptname\n'
            + '1,scriptA\n'
            + '2,scriptB';*/
        Logs__c scriptLog = new Logs__c();
        scriptLog.Log_Type__c = 'Apex Script - Update Template';
        scriptLog.Status__c = 'InProgress';
        scriptLog.Parent_Template__c = rt.Id;
        insert scriptLog;
        
        test.startTest();
        CreateScriptTemplate.scriptData(rt.id, scriptLog.Id, null, null);
        test.stopTest();
        
         List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :rt.Id 
                                                 ];

        System.assertEquals(0, attachments.size(), 'The ContentDocumentLink should not exist.');
    }
}