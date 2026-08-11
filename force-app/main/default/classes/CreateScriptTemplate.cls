public class CreateScriptTemplate {
    @AuraEnabled
    public static void scriptData(Id refTempId, Id scriptLogId, String jsonData, String csvString) {
        Logs__c log = [select Id, Status__c, Details__c, Parent_Template__c, Log_Type__c from Logs__c where Id =: scriptLogId];
        
        if(log.Log_Type__c == 'Apex Script - Update Template'){
            List<ContentDocumentLink> attToDelete = new List<ContentDocumentLink>();
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId, ContentDocument.FileExtension 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :refTempId 
                                                     AND ContentDocument.FileExtension = 'TXT'];
            system.debug('attachments size --- ' + attachments.size());
            List<ContentDocumentLink> attachments1 = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                      FROM ContentDocumentLink 
                                                      WHERE LinkedEntityId = :refTempId 
                                                      AND ContentDocument.Title = 'Scripts' LIMIT 1];
            system.debug('attachments1 size --- ' + attachments1.size());
            if(attachments1.size() > 0){
                system.debug('scripts csv name --- ' + attachments1[0].ContentDocument.Title);
                attToDelete.add(attachments1[0]);
            }
            if(attachments.size() > 0){
                for(ContentDocumentLink con: attachments){
                    system.debug('con.ContentDocument.Title --- ' + con.ContentDocument.Title);
                    if(con.ContentDocument.Title != 'packageXml.txt'){
                        system.debug('text file name --- ' + con.ContentDocument.Title);
                        attToDelete.add(con);
                    }
                }
            }
            if(attToDelete.size() > 0){
                system.debug('attToDelete size --- ' + attToDelete.size());
                delete attToDelete;
            }
            
        }
        
        
        
        if(!string.isBlank(csvString)){
            Blob csvBlob = Blob.valueOf(csvString);
            ContentVersion version = new ContentVersion();
            version.Title = 'Scripts'; 
            version.PathOnClient = version.Title+'.csv';
            version.VersionData = csvBlob;
            insert version;
            system.debug(version.Id);
            
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :version.Id
            ].ContentDocumentId;
            contentDocumentLink.LinkedEntityId = refTempId;
            contentDocumentLink.ShareType = 'V'; 
            contentDocumentLink.Visibility = 'AllUsers'; 
            insert contentDocumentLink;
        }else{
            system.debug('csvString Parameter is Null');
            log.Status__c = 'Failed';
            log.Details__c = 'There is no csv Data to create template';
            update log;
        }
        
        try{
            List<Object> scripts = (List<Object>) JSON.deserializeUntyped(jsonData);
            
            List<ContentVersion> cv = new List<ContentVersion>();
            
            for (Object scriptObj : scripts) {
                Map<String, Object> script = (Map<String, Object>) scriptObj;
                
                String scriptName = (string)script.get('ScriptName');
                String scriptData = (string)script.get('ScriptData');
                String fileContent = '';
                //fileContent += 'Script Name: ' + scriptName + '\n';
                fileContent +=  scriptData + '\n\n';
                
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = scriptName;  
                contentVersion.PathOnClient = scriptName + '.txt'; 
                contentVersion.VersionData = Blob.valueOf(fileContent);
                cv.add(contentVersion);            
            }
            insert cv;
            
            List<id> cvId = new List<id>();
            for(contentVersion cid : cv){
                cvId.add(cid.id);
            }
            
            List<contentDocumentLink> cdl = new List<contentDocumentLink>();
            for(id cId : cvId){
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = [
                    SELECT ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id = :cId
                ].ContentDocumentId;
                contentDocumentLink.LinkedEntityId = refTempId;
                contentDocumentLink.ShareType = 'V'; 
                contentDocumentLink.Visibility = 'AllUsers'; 
                cdl.add(contentDocumentLink);
            }
            insert cdl;
            log.Status__c = 'Success';
            log.Details__c = '';
            update log;
        }catch(exception e){
            system.debug('Error in creating Script templates: '+e.getMessage());
            log.Status__c = 'Failed';
            log.Details__c = 'Error in creating script template: '+e.getMessage();
            update log;
        }
    }
}