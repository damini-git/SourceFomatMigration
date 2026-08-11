public class EditRefreshTemplateClass {
    
    @AuraEnabled
    public static Refresh_Template__c fetchRefreshTemplate(Id refTempId){
        return [select Id, Name, Parent_Org__c, Parent_Org__r.Name from Refresh_Template__c where Id =: refTempId LIMIT 1];
    }
    
    public static MetadataService.MetadataPort createService(String domainUrl, String accessToken) {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        String version = '59.0';
        service.endpoint_x = domainUrl + '/services/Soap/m/' + version;
        service.SessionHeader.sessionId = accessToken;
        service.timeout_x = 120000;
        return service;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchAllMetadataComponentsForEdit(Id sandboxId, String selectedMetadataType) {
        system.debug('selectedMetadataType --- ' + selectedMetadataType);
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(sandboxId);
        
        List<String> metadataComponentNames = new List<String>();
        List<Map<String, String>> metadataComponentNamesMap = new List<Map<String, String>>();
        
        try {
            MetadataService.MetadataPort service = createService(domainUrl, accessToken);
            
            MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
            query.type_x = (selectedMetadataType == 'CustomLabels') ? 'CustomLabel' : selectedMetadataType;
            
            MetadataService.ListMetadataQuery[] queries = new MetadataService.ListMetadataQuery[] { query };
                MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, Double.valueOf(58.0));
            system.debug('fileProperties size --- ' + fileProperties.size());
            
            if (fileProperties != null) {
                for (MetadataService.FileProperties fileProp : fileProperties) {
                    system.debug('metadata --- ' + fileProp.fullName);
                    if (String.isEmpty(fileProp.namespacePrefix)) { metadataComponentNamesMap.add(new Map<String, String>{ 'value' => fileProp.fullName, 'type' => selectedMetadataType }); }
                }
            }
        } catch (Exception ex) {
            System.debug('Error fetching metadata components: ' + ex.getMessage());
        }
        
        return metadataComponentNamesMap;
    }
    
    @AuraEnabled
    public static void updateTemplate(Id parentOrgId, Id refTempId, String templateName, String metadataPackageXmlContent, List<String> selectedUsernames, List<String> customSettingNames, String sJobs, String findAndReplaceTemplate, String jsonData, string csvString){
        Org__c org = [select Id, Name, Domain_Url__c, Access_Token__c from Org__c where Id =: parentOrgId];
        String domainUrl = org.Domain_Url__c;
        String accessToken = Test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(org.Id);
        
        Refresh_Template__c refTemp = [select Id, Name, Is_Metadata_Selected__c, Is_User_Data_Selected__c, Is_Scheduled_Jobs_Selected__c,
                                       Is_Find_And_Replace_Rules_Selected__c, Custom_Setting_Names__c from Refresh_Template__c where Id =: refTempId];
        
        refTemp.Is_Metadata_Selected__c = (!String.isEmpty(metadataPackageXmlContent)) ? true : false;
        refTemp.Is_User_Data_Selected__c = (selectedUsernames.size() > 0) ? true : false;
        refTemp.Is_Scheduled_Jobs_Selected__c = (sJobs != '[]') ? true : false;
        refTemp.Is_Find_And_Replace_Rules_Selected__c = (findAndReplaceTemplate != '[]') ? true : false;
        
        if(customSettingNames.size() > 0){
            String namesOfAllCustomSettings = '';
            for(String cc : customSettingNames){
                namesOfAllCustomSettings += cc + ', ';
            }
            if (namesOfAllCustomSettings.endsWith(', ')) {
                namesOfAllCustomSettings = namesOfAllCustomSettings.substring(0, namesOfAllCustomSettings.length() - 2);
            }
            refTemp.Custom_Setting_Names__c = namesOfAllCustomSettings;
            system.debug('refTemp.Custom_Setting_Names__c --- ' + refTemp.Custom_Setting_Names__c);
            system.debug('namesOfAllCustomSettings --- ' + namesOfAllCustomSettings);
            refTemp.Custom_Setting_Names__c.replaceAll(refTemp.Custom_Setting_Names__c, namesOfAllCustomSettings);
        }
        
        update refTemp;
        system.debug('refTemp updated --- ' + refTemp.Name);
        
        
        List<String> conditions = new List<String>();
        if(!String.isEmpty(metadataPackageXmlContent)){
            conditions.add('case1');
        } else if(!refTemp.Is_Metadata_Selected__c){
            deleteMetdataFileIfEmpty(refTempId, metadataPackageXmlContent);
        }
        
        if(selectedUsernames.size() > 0){
            conditions.add('case2');
        } else if(!refTemp.Is_User_Data_Selected__c){
            deleteUsersDataFileIfEmpty(refTempId, selectedUsernames);
        }
        
        if(customSettingNames.size() > 0){
            conditions.add('case3');
        } else if(refTemp.Custom_Setting_Names__c != '' && refTemp.Custom_Setting_Names__c != null){
            deleteCustomSettingsFileIfEmpty(refTempId);
        }
        
        system.debug('sJobs --- ' + sJobs + ' --- refTemp.Is_Scheduled_Jobs_Selected__c ---' + refTemp.Is_Scheduled_Jobs_Selected__c);
        if(sJobs != '[]'){
            conditions.add('case4');
        } else if(!refTemp.Is_Scheduled_Jobs_Selected__c){
            deleteScheduledJobsFileIfEmpty(refTempId, sJobs);
        }
        
        if(findAndReplaceTemplate != '[]'){
            conditions.add('case5');
        } else if(!refTemp.Is_Find_And_Replace_Rules_Selected__c){
            deleteMetadataMaskingFileIfEmpty(refTempId, findAndReplaceTemplate);
        }
        
        system.debug('jsonData for apex script --- ' + jsonData);
        system.debug('csvString for apex script --- ' + csvString);
        if(!string.isBlank(jsonData) && !string.isBlank(csvString)){ conditions.add('case6'); }
        else{
            deleteApexScriptFileIfEmpty(refTempId);
        }
        
        EditRefreshTemplateClass outerClass = new EditRefreshTemplateClass();
        for(String condition : conditions){
            switch on condition {
                when 'case1' {
                    Logs__c metadataRetrieveLog = new Logs__c();
                    metadataRetrieveLog.Log_type__c = 'Metadata Retrieve - Update Template';
                    metadataRetrieveLog.Status__c = 'InProgress';
                    metadataRetrieveLog.Parent_Template__c = refTempId;
                    insert metadataRetrieveLog;
                    system.debug('metadata retrieve log created --- ' + metadataRetrieveLog.Id);
                    
                    system.debug('Case 1: calling metdata retrieval job for update template ---------- ');
                    BackupRegenerationOfMetadata.retrievePackage(refTempId, domainUrl, accessToken, metadataPackageXmlContent, metadataRetrieveLog.Id);
                }
                
                when 'case2' {
                    Logs__c userDataRetrieveLog = new Logs__c();
                    userDataRetrieveLog.Log_type__c = 'User Retrieve - Update Template';
                    userDataRetrieveLog.Status__c = 'InProgress';
                    userDataRetrieveLog.Parent_Template__c = refTempId;
                    insert userDataRetrieveLog;
                    system.debug('user data retrieve log created --- ' + userDataRetrieveLog.Id);
                    
                    system.debug('Case 2: calling user retrieval job for update template ---------- ');
                    system.debug('selectedUsernames size --- ' + selectedUsernames.size());
                    if(!test.isRunningTest()){BackupRegenerationOfUsers.getAllUsersWithProfilesAndRoles(domainUrl, refTempId, selectedUsernames, accessToken, userDataRetrieveLog.Id);}
                }
                
                when 'case3' {
                    Logs__c customSettingRetrieveLog = new Logs__c();
                    customSettingRetrieveLog.Log_type__c = 'Custom Settings Retrieve - Update Template';
                    customSettingRetrieveLog.Status__c = 'InProgress';
                    customSettingRetrieveLog.Parent_Template__c = refTempId;
                    insert customSettingRetrieveLog;
                    system.debug('custom settings data retrieve log created --- ' + customSettingRetrieveLog.Id);
                    
                    system.debug('Case 3: calling custom settings retrieval job for update template ---------- ');
                    system.debug('inside customSettingNames --- ' + customSettingNames);
                    BackupRegenerationOfCustomSettings.fetchAllFields(parentOrgId, refTempId, accessToken, customSettingNames, customSettingRetrieveLog.Id);
                }
                
                when 'case4' {
                    Logs__c sJobsRetrieveLog = new Logs__c();
                    sJobsRetrieveLog.Log_type__c = 'Scheduled Jobs Retrieve - Update Template';
                    sJobsRetrieveLog.Status__c = 'InProgress';
                    sJobsRetrieveLog.Parent_Template__c = refTempId;
                    insert sJobsRetrieveLog;
                    system.debug('custom settings data retrieve log created --- ' + sJobsRetrieveLog.Id);
                    
                    system.debug('Case 4: calling scheduled jobs retrieval job for update template ---------- ');
                    system.debug('inside sJobs --- ' + sJobs);
                    outerClass.generateCsvForScheduledJobsNew(refTempId, sJobs, sJobsRetrieveLog.Id);
                }
                
                when 'case5' {
                    system.debug('Case 5: calling metadata transformation rules creation job for update template ---------- ');
                    system.debug('inside findAndReplaceTemplate --- ' + findAndReplaceTemplate);
                    createMetadataTransRulesCSV(refTempId, findAndReplaceTemplate);
                }
                
                when 'case6' {
                    Logs__c scriptLog = new Logs__c();
                    scriptLog.Log_Type__c = 'Apex Script - Update Template';
                    scriptLog.Status__c = 'InProgress';
                    scriptLog.Parent_Template__c = refTempId;
                    insert scriptLog;
                    
                    system.debug('Case 6: calling script Template creation job for update template ---------- ');
                    system.debug('inside Script Template creation --- ' + csvString);
                    CreateScriptTemplate.scriptData(refTempId, scriptLog.Id, jsonData, csvString);
                }
            }
        }
    }
    
    public void generateCsvForScheduledJobsNew(Id refTempId, String sJobs, Id sJobsRetrieveLogId){
        system.debug('sJobs --- ' + sJobs);
        List<Object> parsedData = (List<Object>) JSON.deserializeUntyped(sJobs);
        List<String> cronJobDetailsIds = new List<String>();
        
        String csvContent = '"Job Name","Job Type","Apex Class","Cron Expression"\n';
        
        for (Object obj : parsedData) {
            Map<String, Object> data = (Map<String, Object>) obj;
            String formattedString = (String) data.get('formattedString');
            system.debug('job records --- ' + formattedString);
            
            Pattern keyValuePattern = Pattern.compile('([a-zA-Z ]+):(.+?)(?=, [a-zA-Z ]+:|$)');
            Matcher matcher = keyValuePattern.matcher(formattedString);
            
            Map<String, String> fieldMap = new Map<String, String>();
            
            while (matcher.find()) {
                String key = matcher.group(1).trim();
                String value = matcher.group(2).trim();
                fieldMap.put(key, value);
            }
            
            List<String> row = new List<String>();
            row.add('"' + fieldMap.get('Job Name') + '"');
            row.add('"' + fieldMap.get('Job Type') + '"');
            row.add('"' + fieldMap.get('Apex Class') + '"');
            row.add('"' + fieldMap.get('Cron Expression') + '"');
            csvContent += String.join(row, ',') + '\n';
            system.debug('csvContent --- ' + csvContent);
        }
        insertCsvAsAttachmentForSJobsNew(refTempId, csvContent, sJobsRetrieveLogId);
    }
    
    private static void insertCsvAsAttachmentForSJobsNew(Id refTempId, String csvContent, Id sJobsRetrieveLogId) {
        Logs__c sJobsRetrieveLog = [select Id, Status__c, Details__c, Log_Type__c from Logs__c where Id =: sJobsRetrieveLogId];
        
        if(sJobsRetrieveLog.Log_Type__c == 'Scheduled Jobs Retrieve - Update Template'){
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :refTempId 
                                                     AND ContentDocument.Title = 'Scheduled Jobs'
                                                    ];
            system.debug('attachments------>>>>>>'+attachments);
            if(attachments.size() > 0){ delete attachments;
            }
        }
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Scheduled Jobs';
        contentVersion.PathOnClient = 'Scheduled Jobs.csv';
        contentVersion.VersionData = Blob.valueOf(csvContent);
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = refTempId;
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        
        insert contentDocumentLink;
        if(contentDocumentLink.Id != null){
            sJobsRetrieveLog.Status__c = 'Success';
            update sJobsRetrieveLog;
        }
    }
    
    public static void createMetadataTransRulesCSV(Id refTempId, String findAndReplaceTemplate){
        List<Object> dataList = (List<Object>) JSON.deserializeUntyped(findAndReplaceTemplate);
        
        String csvContent = '"Metadata Type","Masking Type","Search Key","Replace Value","Suffix Value"\n';
        
        for (Object obj : dataList) {
            Map<String, Object> dataMap = (Map<String, Object>) obj;
            
            String metadataType = String.valueOf(dataMap.get('metadataType'));
            String maskingType = String.valueOf(dataMap.get('maskingType'));
            String searchKey = dataMap.containsKey('searchKey') ? String.valueOf(dataMap.get('searchKey')) : '';
            String replaceValue = dataMap.containsKey('replaceValue') ? String.valueOf(dataMap.get('replaceValue')) : '';
            String suffixValue = dataMap.containsKey('suffixValue') ? String.valueOf(dataMap.get('suffixValue')) : '';
            
            csvContent += '"' + metadataType + '","' + maskingType + '","' + searchKey + '","' + replaceValue + '","' + suffixValue + '"\n';
        }
        
        System.debug('csvContent --- ' + csvContent);
        attachMetaTransRulesCsvToRefTemp(refTempId, csvContent);
    }
    
    private static void attachMetaTransRulesCsvToRefTemp(Id refTempId, String csvContent) {
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :refTempId 
                                                 AND ContentDocument.Title = 'Metadata_Masking_Rules.csv'
                                                ];
        system.debug('attachments------>>>>>>'+attachments);
        if(attachments.size() > 0){ delete attachments;
        }
        
        ContentVersion content = new ContentVersion();
        content.Title = 'Metadata_Masking_Rules.csv';
        content.PathOnClient = 'Metadata_Masking_Rules.csv';
        content.VersionData = Blob.valueOf(csvContent);
        insert content;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :content.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = refTempId;
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        insert contentDocumentLink;
        
        system.debug('metadata trandformation rules file attached --- ' + contentDocumentLink.Id);
    }
    
    public static void deleteMetdataFileIfEmpty(Id refTempId, String metadataPackageXmlContent){
        /*Refresh_Template__c refTemp = [select Id, Name, Is_Metadata_Selected__c from Refresh_Template__c where Id =: refTempId];
        refTemp.Is_Metadata_Selected__c = (!String.isEmpty(metadataPackageXmlContent)) ? true : false;
        update refTemp;*/
        
        system.debug('--- Deleting the Metadata.zip and packageXml.txt files from Refresh Template as Selected Metadata is Empty --- ');
        /*Logs__c metadataRetrieveLog = new Logs__c();
        metadataRetrieveLog.Log_type__c = 'Metadata Retrieve - Update Template';
        metadataRetrieveLog.Parent_Template__c = refTempId;*/
        
        try{
            List<Attachment> metadataAttachment = [SELECT Id, Name,ParentId FROM Attachment where ParentId=: refTempId AND Name ='Metadata.zip' LIMIT 1];
            if(metadataAttachment.size() > 0){ delete metadataAttachment;
            }
            
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :refTempId 
                                                     AND ContentDocument.Title = 'packageXml.txt'
                                                    ];
            system.debug('attachments------>>>>>>'+attachments);
            if(attachments.size() > 0){ delete attachments;
            }
            //metadataRetrieveLog.Status__c = 'Success';
        }
        catch(Exception e){
            system.debug('Metadata files deletion failed due to the following reason --- ' + e.getMessage());
            /*metadataRetrieveLog.Status__c = 'Failed';
            metadataRetrieveLog.Details__c = e.getMessage();*/
        }
        //insert metadataRetrieveLog;
        //system.debug('metadata retrieve log created for deleting the Metadata files --- ' + metadataRetrieveLog.Id);
    }
    
    public static void deleteUsersDataFileIfEmpty(Id refTempId, List<String> selectedUsernames){
        /*Refresh_template__c refTemp = [select Id, Name, Is_User_Data_Selected__c from Refresh_Template__c where Id =: refTempId];
        refTemp.Is_User_Data_Selected__c = (selectedUsernames.size() > 0) ? true : false;
        update refTemp;*/
        
        system.debug('--- Deleting the User Data JSON file from Refresh Template as Selected Users is Empty --- ');
        /*Logs__c userDataRetrieveLog = new Logs__c();
        userDataRetrieveLog.Log_type__c = 'User Retrieve - Update Template';
        userDataRetrieveLog.Parent_Template__c = refTempId;*/
        
        try{
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :refTempId 
                                                     AND ContentDocument.Title LIKE '%User Data%' LIMIT 1
                                                    ];
            if(attachments.size() > 0){ delete attachments;
            }
            //userDataRetrieveLog.Status__c = 'Success';
        }
        catch(Exception e){
            system.debug('user json files deletion failed due to the following reason --- ' + e.getMessage());
            /*userDataRetrieveLog.Status__c = 'Failed';
            userDataRetrieveLog.Details__c = e.getMessage();*/
        }
        
        //insert userDataRetrieveLog;
        //system.debug('user data retrieve log created for deleting the user json file --- ' + userDataRetrieveLog.Id);
    }
    
    public static void deleteCustomSettingsFileIfEmpty(Id refTempId){
        Refresh_Template__c refTemp = [select Id, Name, Custom_Setting_Names__c from Refresh_Template__c where Id =: refTempId];
        system.debug('Custom_Setting_Names__c --- ' + refTemp.Custom_Setting_Names__c);
        
        system.debug('--- Deleting the Custom Setting files from Refresh Template as Selected Custom Settings List is Empty --- ');
        /*Logs__c customSettingRetrieveLog = new Logs__c();
        customSettingRetrieveLog.Log_type__c = 'Custom Settings Retrieve - Update Template';
        customSettingRetrieveLog.Parent_Template__c = refTempId;*/
        
        try{
            List<String> customSettingsList = new List<String>();
            
            for (String val : refTemp.Custom_Setting_Names__c.deleteWhiteSpace().split(',')) {
                customSettingsList.add(val.trim());
            }
            system.debug('customSettingsList after converting the string into list --- ' + customSettingsList);
            
            List<ContentDocumentLink> attachmentsToDelete = new List<ContentDocumentLink>();
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :refTempId AND ContentDocument.Title IN :customSettingsList];
            for(ContentDocumentLink con : attachments){
                system.debug('names of custom settings to be deleted --- ' + con.ContentDocument.Title);
                attachmentsToDelete.add(con);
            }
            if(attachmentsToDelete.size() > 0){ delete attachmentsToDelete;
            }
            
            //customSettingRetrieveLog.Status__c = 'Success';
            
            refTemp.Custom_Setting_Names__c = '';
            update refTemp;
        }
        catch(Exception e){
            system.debug('custom setting files deletion failed due to the following reason --- ' + e.getMessage());
            /*customSettingRetrieveLog.Status__c = 'Failed';
            customSettingRetrieveLog.Details__c = e.getMessage();*/
        }
        
        //insert customSettingRetrieveLog;
        //system.debug('custom settings data retrieve log created for deleting custom settings files --- ' + customSettingRetrieveLog.Id);
    }
    
    public static void deleteScheduledJobsFileIfEmpty(Id refTempId, String sJobs){
        /*Refresh_Template__c refTemp = [select Id, Name, Is_Scheduled_Jobs_Selected__c from Refresh_Template__c where Id =: refTempId];
        refTemp.Is_Scheduled_Jobs_Selected__c = (sJobs != '[]') ? true : false;
        update refTemp;*/
        
        system.debug('--- Deleting the Scheduled Job file from Refresh Template as Selected Scheduled Jobs List is Empty --- ');
        /*Logs__c sJobsRetrieveLog = new Logs__c();
        sJobsRetrieveLog.Log_type__c = 'Scheduled Jobs Retrieve - Update Template';
        sJobsRetrieveLog.Parent_Template__c = refTempId;*/
        
        try{
            ContentDocumentLink attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                               FROM ContentDocumentLink 
                                               WHERE LinkedEntityId = :refTempId 
                                               AND ContentDocument.Title LIKE '%Scheduled Jobs%' LIMIT 1
                                              ];
            delete attachments;
            //sJobsRetrieveLog.Status__c = 'Success';
        }
        catch(Exception e){
            system.debug('scheduled jobs files deletion failed due to the following reason --- ' + e.getMessage());
            /*sJobsRetrieveLog.Status__c = 'Failed';
            sJobsRetrieveLog.Details__c = e.getMessage();*/
        }
        
        //insert sJobsRetrieveLog;
        //system.debug('custom settings data retrieve log created --- ' + sJobsRetrieveLog.Id);
    }
    
    public static void deleteMetadataMaskingFileIfEmpty(Id refTempId, String findAndReplaceTemplate){
        /*Refresh_Template__c refTemp = [select Id, Name, Is_Find_And_Replace_Rules_Selected__c from Refresh_Template__c where Id =: refTempId];
        refTemp.Is_Find_And_Replace_Rules_Selected__c = (findAndReplaceTemplate != '[]') ? true : false;
        update refTemp;*/
        
        system.debug('--- Deleting the Metadata Transformation file from Refresh Template as Selected Metadata Transformation List is Empty --- ');
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :refTempId 
                                                 AND ContentDocument.Title = 'Metadata_Masking_Rules.csv'
                                                ];
        system.debug('attachments------>>>>>>'+attachments);
        if(attachments.size() > 0){ delete attachments;
                                  }
    }
    
    public static void deleteApexScriptFileIfEmpty(Id refTempId){
        system.debug('--- Deleting the Apex Script files from Refresh Template as Selected Apex Scripts List is Empty --- ');
        /*Logs__c scriptLog = new Logs__c();
        scriptLog.Log_Type__c = 'Apex Script - Update Template';
        scriptLog.Parent_Template__c = refTempId;*/
        
        try{
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
            if(attToDelete.size() > 0){ delete attToDelete;
            }
            //scriptLog.Status__c = 'Success';
        }
        catch(Exception e){
            system.debug('apex script files deletion failed due to the following reason --- ' + e.getMessage());
            /*scriptLog.Status__c = 'Failed';
            scriptLog.Details__c = e.getMessage();*/
        }
        
        //insert scriptLog;
    }

}