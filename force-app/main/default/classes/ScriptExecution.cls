public class ScriptExecution implements database.batchable<ContentDocumentLink>,Database.Stateful,Database.AllowsCallouts{
    public id refTempId;
    public string instanceUrl;
    public string accessToken;
    public String csvData = 'Script Name,status\n'; 
    
    public Logs__c log = new Logs__c();
    
    
    public ScriptExecution(Id refTempId){
        Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c FROM Refresh_Template__c where id =: refTempId LIMIT 1];
        String instanceUrl = refTemp.Parent_Org__r.Domain_Url__c;
        String accessToken = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(refTemp.Parent_Org__c);
        
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.refTempId = refTempId;
    }
    public List<ContentDocumentLink> start(Database.BatchableContext bc) {
        try{
            
            ContentDocumentLink attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                               FROM ContentDocumentLink 
                                               WHERE LinkedEntityId = :refTempId 
                                               AND ContentDocument.Title LIKE '%Script%' LIMIT 1
                                              ];
            List<String> scriptNames = new List<String>();
            List<ContentDocumentLink> scriptAttachments = new List<ContentDocumentLink>();
            if(attachments != null){
                ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments.ContentDocumentId LIMIT 1];
                system.debug(version);
                
                Blob csvBlob = version.VersionData;        
                string csvString = csvBlob.toString();
                system.debug('csvString--------->>>>'+csvString);
                
                List<String> rows = csvString.split('\n');
                
                String headerRow = rows[0];
                List<String> headers = headerRow.split(',');
                
                Integer scriptNameIndex = -1;
                for (Integer i = 0; i < headers.size(); i++) {
                    if (headers[i].trim().equalsIgnoreCase('scriptName')) {
                        scriptNameIndex = i;
                        break;
                    }
                }
                
                if (scriptNameIndex == -1) {
                    System.debug('Script Name column not found');
                }
                
                for (Integer i = 1; i < rows.size(); i++) {
                    List<String> columns = rows[i].split(',');
                    
                    if (columns.size() > scriptNameIndex) {
                        scriptNames.add(columns[scriptNameIndex].trim());
                    }
                }
                
                for (Integer i = 0; i < scriptNames.size(); i++) {
                    scriptNames[i] = scriptNames[i].replaceAll('"', '');
                }
                system.debug(scriptNames);
                
            }else{
                system.debug('No Attachments Found');
            }
            if(scriptNames.size() != 0){
                scriptAttachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId
                                     FROM ContentDocumentLink
                                     WHERE LinkedEntityId = :refTempId
                                     AND ContentDocument.Title IN :scriptNames
                                    ];
                
                if(scriptAttachments.size() != 0){
                    system.debug(scriptAttachments[0].ContentDocumentId);
                }
            }
            log.Log_Type__c = 'Apex Script - Metadata Transformation';
            log.Parent_Template__c = refTempId;
            log.Status__c = 'InProgress';
            log.Last_ApexScript_Date__c = system.now();
            insert log;
            return scriptAttachments;
        }catch(exception e){
            system.debug(e.getMessage());
            log.Log_Type__c = 'Apex Script - Metadata Transformation';
            log.Parent_Template__c = refTempId;
            log.Status__c = 'Failed';
            log.Last_ApexScript_Date__c = system.now();
            insert log;
            throw e;
        }
    }
    public void execute(Database.BatchableContext bc, List<ContentDocumentLink> scriptAttachments){
        system.debug('Inside execute');
        
        executeScript(scriptAttachments[0], instanceUrl, accesstoken,log);
    }
    public void finish(Database.BatchableContext bc){
        try{
        Blob csvBlob = Blob.valueOf(csvData);
        ContentVersion version = new ContentVersion();
        version.Title = 'Scripts Execution Status'; 
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
        contentDocumentLink.LinkedEntityId = log.Id;
        contentDocumentLink.ShareType = 'V'; 
        contentDocumentLink.Visibility = 'AllUsers'; 
        insert contentDocumentLink;
        
        log.Status__c = 'Completed';
        log.Details__c = ''; 
        update log;
        }catch(exception e){
            system.debug(e.getMessage());
            log.Status__c = 'Failed';
            log.Details__c = e.getMessage();
            update log;
        }
    }
    public  void executeScript(ContentDocumentLink attachments, String instanceUrl, String accesstoken,Logs__c log){
        ContentVersion version = [SELECT Id, Title, FileType, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments.ContentDocumentId AND FileType ='Text' LIMIT 1];
        system.debug(version);
        system.debug(version.VersionData);
        
        String scriptContent = Version.VersionData.toString();
        system.debug('scriptContent------>>>>'+scriptContent);
        User currentUser = [SELECT Lastname,Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        string emailId = currentUser.email;
        string name = currentUser.LastName;
        system.debug('scriptContent--------->>>>>>'+scriptContent);
        String versionTitle = version.title;
        
        String apexCode = 
            'String errorMessage;\n' +
            'String emailBody;\n' +
            'try {\n' +
            scriptContent + '\n' + 
            '    emailBody =  \'Dear <b>' + name + '</b>,<br/><br/>\';\n' +  // Fixed variable usage
            '    emailBody += \'The following Script <b>' + versionTitle + '</b> has been executed successfully\';\n' + 
            '    emailBody += \'<br/><br/>\' +\n' +
            '                \'<hr>\' +\n' +
            '                \'<b>This is a system generated mail. Please do not reply to this email ID.</b>\';\n' +  // Fixed concatenation
            '    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();\n' +
            '    email.setToAddresses(new String[] { \'' + emailId + '\' });\n' +
            '    email.setSubject(\'Script Execution Success\');\n' +
            '    email.setHtmlBody(emailBody);  // Changed to setHtmlBody\n' +  // Use HTML body
            '    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });\n' +
            '} catch (Exception e) {\n' +
            '    System.debug(\'Error occurred while executing the script: \' + e.getMessage());\n' +
            '    errorMessage = e.getMessage();\n' +
            '    if (!String.isBlank(errorMessage)) {\n' +
            '    emailBody =  \'Dear <b>' + name + '</b>,<br/><br/>\';\n' +
            '        emailBody = \'The following errors occurred while executing the script ' + versionTitle + ': \' + errorMessage;\n' +
            '    emailBody += \'<br/><br/>\' +\n' +
            '                \'<hr>\' +\n' +
            '                \'<b>This is a system generated mail. Please do not reply to this email ID.</b>\';\n' +  // Fixed concatenation
            '        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();\n' +
            '        email.setToAddresses(new String[] { \'' + emailId + '\' });\n' +
            '        email.setSubject(\'Script Execution Error\');\n' +
            '        email.setHtmlBody(emailBody);  // Use HTML body\n' +  // Changed to setHtmlBody
            '        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });\n' +
            '    }\n' +
            '}';
        
        System.debug('apex code --- ' + apexCode);
        
        
        String encodedString = EncodingUtil.urlEncode(apexCode, 'UTF-8');
        
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(instanceUrl + '/services/data/v59.0/tooling/executeAnonymous/?anonymousBody=' + encodedString);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        Http http = new Http();
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                System.debug('Script Executed successfully: ' + response.getBody());
                csvData += versionTitle + ',success\n';
            } else {
                System.debug('Failed to Execute the script: ' + response.getStatusCode());
                System.debug('Error response: ' + response.getBody());
                csvData += versionTitle + ',failed\n';
            }
        } catch (Exception e) {
            System.debug('Error occurred while executing anonymous Apex: ' + e.getMessage());
            csvData += versionTitle + ',Script execution failed due to error '+e.getMessage()+'\n';
        }
    }
}