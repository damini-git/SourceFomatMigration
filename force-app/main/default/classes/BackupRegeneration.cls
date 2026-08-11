public class BackupRegeneration {
    @AuraEnabled
    public static void regenerateUsers(id refTempId){
        Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c FROM Refresh_Template__c where id =: refTempId LIMIT 1];
        
        string domainUrl = refTemp.Parent_Org__r.Domain_Url__c;
        id orgId = refTemp.Parent_Org__c;
        string accessToken = (test.isRunningTest()) ? '123456789' : RefreshTokenCallout.fetchAT1(refTemp.Parent_Org__c);
        
        Logs__c userRegenerationLog = new Logs__c();
        userRegenerationLog.Log_Type__c = 'Users - Backup Regeneration';
        userRegenerationLog.Parent_Template__c = refTempId;
        
        ContentDocumentLink attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId = :refTempId 
                                           AND ContentDocument.Title LIKE '%User Data%' LIMIT 1
                                          ];
        if(attachments != null){
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments.ContentDocumentId LIMIT 1];
            system.debug(version);
            
            Blob jsonBlob = version.VersionData;        
            string jsonString = jsonBlob.toString();
            system.debug('jsonString-------->>>>'+jsonString);
            
            Map<String, List<UserData>> jsonMap;
            try {
                jsonMap = (Map<String, List<UserData>>) JSON.deserialize(jsonString, Map<String, List<UserData>>.class);
            } catch (Exception e) {
                System.debug('Error deserializing JSON: ' + e.getMessage());
            }
            List<UserData> backupUsers = jsonMap.get('User');
            List<String> usernames = new List<String>();
            for (UserData userData : backupUsers) {
                usernames.add(userData.Username);
            }
            system.debug('Usernames------->>>' +usernames);
            
            userRegenerationLog.Status__c = 'InProgress';
            insert userRegenerationLog;
            
            BackupRegenerationOfUsers.getAllUsersWithProfilesAndRoles(domainUrl, refTempId, usernames, accessToken, userRegenerationLog.Id);
        }
        else{
            userRegenerationLog.Status__c = 'Failed';
            userRegenerationLog.Details__c = 'No Attachments found in the template to regenerate Users.';
            insert userRegenerationLog;
            system.debug('No attachments found');
        }
    }
    
    @AuraEnabled
    public static void regenerateScheduledJobs(id refTempId){
        Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c FROM Refresh_Template__c where id =: refTempId LIMIT 1];
        
        string domainUrl = refTemp.Parent_Org__r.Domain_Url__c;
        Id orgId = refTemp.Parent_Org__c;
        string accessToken = (test.isRunningTest()) ? '123456789' : RefreshTokenCallout.fetchAT1(refTemp.Parent_Org__c);
        
        ContentDocumentLink attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId = :refTempId 
                                           AND ContentDocument.Title LIKE '%Scheduled Jobs%'
                                          ];
        
        if(attachments != null){
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments.ContentDocumentId LIMIT 1];
            system.debug(version);
            
            Blob csvBlob = version.VersionData;        
            string csvString = csvBlob.toString();
            system.debug('csvString--------->>>>'+csvString);
            
            List<String> jobNames = new List<String>();
            List<String> rows = csvString.split('\n');
            
            String headerRow = rows[0];
            List<String> headers = headerRow.split(',');
            
            Integer jobNameIndex = -1;
            for (Integer i = 0; i < headers.size(); i++) {
                if (headers[i].trim().equalsIgnoreCase('"Job Name"')) {
                    jobNameIndex = i;
                    break;
                }
            }
            
            if (jobNameIndex == -1) {
                System.debug('jobName column not found');
            }
            
            for (Integer i = 1; i < rows.size(); i++) {
                List<String> columns = rows[i].split(',');
                
                if (columns.size() > jobNameIndex) {
                    jobNames.add(columns[jobNameIndex].trim());
                }
            }
            
            for (Integer i = 0; i < jobNames.size(); i++) {
                jobNames[i] = jobNames[i].replaceAll('"', ''); // Removes any quotes from each string
            }
            system.debug(jobNames);
            
            BackupRegenerationOfScheduleJobs.fetchScheduledJobs1(domainUrl, accessToken, refTempId, jobNames);
        }else{
            system.debug('No Attachments Found');
        }
        
    }
    @AuraEnabled
    public static void regenerateCustomSettings(Id refTempId){
        Refresh_Template__c refTemp = [SELECT Id, Name, Custom_Setting_Names__c, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c FROM Refresh_Template__c where id =: refTempId LIMIT 1];
        
        string domainUrl = refTemp.Parent_Org__r.Domain_Url__c;
        id orgId = refTemp.Parent_Org__c;
        string customSettingNames = refTemp.Custom_Setting_Names__c.deleteWhiteSpace();
        //customSettingNames = customSettingNames.replaceAll('\\s+', ''); // Remove all whitespace
        //customSettingNames = customSettingNames.replaceAll('__c\\([^\\)]*\\)', '__c');
        string accessToken = (test.isRunningTest()) ? '123456789' : RefreshTokenCallout.fetchAT1(refTemp.Parent_Org__c);        
        
        Logs__c csRestorationLog = new Logs__c();
        csRestorationLog.Log_Type__c = 'Custom Settings - Backup Regeneration';
        csRestorationLog.Parent_Template__c = refTempId;
        
        List<string> customSettingsNamesList = new List <string>();
        customSettingsNamesList = customSettingNames.split(',');
        
        system.debug('customSettingsNames field outside Execution---------->>>>>>'+customSettingNames);
        
        system.debug('customSettingsNames outside Execution---------->>>>>>'+customSettingsNamesList);
        if(customSettingsNamesList.size() > 0){
            system.debug('customSettingsNames---------->>>>>>'+customSettingsNamesList);
            
            csRestorationLog.Status__c = 'InProgress';
            insert csRestorationLog;
            
            BackupRegenerationOfCustomSettings.fetchAllFields(orgId, refTempId, accessToken, customSettingsNamesList, csRestorationLog.Id);
        }else{
            system.debug('No Attachments Found');
            csRestorationLog.Status__c = 'Failed';
            csRestorationLog.Details__c = 'No Attachments found in the template to regenerate Custom Settings.';
            insert csRestorationLog;
        }
    }
    
    
    @AuraEnabled
    public static void regenerateMetadata(Id refTempId) {
        Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c FROM Refresh_Template__c where id =: refTempId LIMIT 1];
        
        string domainUrl = refTemp.Parent_Org__r.Domain_Url__c;
        string accessToken = (test.isRunningTest()) ? '123456789' : RefreshTokenCallout.fetchAT1(refTemp.Parent_Org__c);
        
        
        Logs__c metaRegenerationLog = new Logs__c();
        metaRegenerationLog.Log_Type__c = 'Metadata - Backup Regeneration';
        metaRegenerationLog.Parent_Template__c = refTempId;
        
        ContentDocumentLink attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId = :refTempId 
                                           AND ContentDocument.Title LIKE '%PackageXml%' LIMIT 1
                                          ];
        
        if(attachments != null){
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments.ContentDocumentId LIMIT 1];
            system.debug(version);
            system.debug(version.VersionData);
            
            String metadataPackageXmlContent = Version.VersionData.toString();
            system.debug(metadataPackageXmlContent);
            
            metaRegenerationLog.Status__c = 'InProgress';
            insert metaRegenerationLog;
            
            BackupRegenerationOfMetadata.retrievePackage(refTempId, domainUrl, accessToken, metadataPackageXmlContent, metaRegenerationLog.Id);
        }else{
            system.debug('No Attachments Found');
            metaRegenerationLog.Status__c = 'Failed';
            metaRegenerationLog.Details__c = 'No Attachments found in the template to regenerate Metadata.';
            insert metaRegenerationLog;
        }
        
    }
    
    public class UserData {
        public String username;
        public Id id;
        public String name;
        public String email;
        public String firstName;
        public String lastName;
        public String alias;
        public String timeZoneSidKey;
        public String localeSidKey;
        public String languageLocaleKey;
        public String emailEncodingKey;
        public String isActive;
        public Profile profile;
        public UserRole userRole;
        public List<PermissionSet> permissionSet;
        public List<PermissionSetGroup> permissionSetGroup;
        public List<string> groups;
    }
    public class Profile {
        public String name;
    }
    public class UserRole {
        public String developerName;
    }
    public class PermissionSet {
        public String name;
    }
    public class PermissionSetGroup {
        public String name;
    }
    public class UserResponse {
        public String id { get; set; }
        public Boolean success { get; set; }
        public List<String> errors { get; set; }
    }
}