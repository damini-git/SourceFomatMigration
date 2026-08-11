public class PostRefreshUserRestoration implements Database.Batchable<UserData>, Database.Stateful,Database.AllowsCallouts{
    public string jsonString;
    public string instanceUrl;
    public string accessToken;
    public String logJson;
    public string orgName;
    public List<Map<String, Object>> currentUserRecords;
    public Map<String, String> getProfiles;
    public Map<String, String> getRoles;
    public Map<String, String> getPermSet;
    public Map<String, String> getPSG;
    public Map<String, String> getGroups;
    public List<id> getGroupMembers;
    public Map<Id, String> jobIds = new Map<Id, String>();
    public logs__c log;
    public static string userQuery = '/services/data/v59.0/query/?q=SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC';
    public static List<Map<String, Object>> users = new List<Map<String, Object>>();
    public map<id,list<string>> finalPermSet = new map<id,List<string>>();
    public map<id,list<string>> finalGroup = new map<id,List<string>>();
    
    public PostRefreshUserRestoration(id recordId,logs__c log,id groupId){
        this.log = log;
        Id orgId = [select Id, Parent_Org__c from Refresh_Template__c where Id =: recordId].Parent_Org__c;
        Org__c org = [select Id,name, Domain_Url__c from Org__c where Id =: orgId];
        orgName = org.Name;
        String instanceUrl = org.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(org.Id);
        
        getGroupMembers=getGroupMembers(instanceUrl,accessToken,log,groupId,jobIds);
        
        List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                 FROM ContentDocumentLink 
                                                 WHERE LinkedEntityId = :recordId 
                                                 AND ContentDocument.Title LIKE '%User Data - Export - JSON%' LIMIT 1
                                                ];
        if(attachments.size() != 0){        
            ContentVersion version = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :attachments[0].ContentDocumentId LIMIT 1];            
            
            Blob jsonBlob = version.VersionData;        
            this.jsonString = jsonBlob.toString();
            this.instanceUrl = instanceUrl;
            this.accessToken = accessToken;
            this.currentUserRecords = getCurrentUsersFromTargetOrg(instanceUrl,accessToken,log,userQuery);
            this.getProfiles = getProfilesFromTargetOrg(instanceUrl,accessToken,log);
            this.getRoles = getRolesFromTargetOrg(instanceUrl,accessToken,log);
            this.getPermSet = getPermissionSets(instanceUrl,accessToken,log);
            this.getPSG = getPSG(instanceUrl,accessToken,log);
            this.getGroups = getGroups(instanceUrl,accessToken,log);
            //system.debug(jsonString);
            //system.debug('currentUserRecords Size-------->>>>>'+currentUserRecords.size());
        }else{
            //system.debug('There is no attachment named User Data - Export in the Refresh Template');
            //system.debug('log.Status__c--->>>>'+log.Status__c);
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = 'There is no attachment named User Data - Export in the Refresh Template';
                insert log;
            }
        }
    }
    
    public List<UserData> start(Database.BatchableContext bc) {
        Map<String, List<UserData>> jsonMap;
        try {
            jsonMap = (Map<String, List<UserData>>) JSON.deserialize(jsonString, Map<String, List<UserData>>.class);
        } catch (Exception e) {
            //system.debug('Error deserializing JSON: ' + e.getMessage());
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = 'Error deserializing JSON: ' + e.getMessage();
                insert log;
            }
        }
        //system.debug('jsonMap---------->>>>>'+jsonMap);
        List<UserData> backupUsers = jsonMap.get('User');
        //system.debug('backupUsers---------->>>>>'+backupUsers);
        List<User> currentUsers = new List<User>();
        
        //system.debug('currentUserRecords---------->>>>>'+currentUserRecords);
        
        if(log.Status__c != 'Failed'){
            
            for (Map<String, Object> record : currentUserRecords) {
                User user = new User();
                user.Id = (Id)record.get('Id');
                user.Username = (String)record.get('Username');
                user.Email = (String)record.get('Email');
                user.ProfileId = (Id)record.get('ProfileId');
                user.UserRoleId = (Id)record.get('UserRoleId');
                user.IsActive = (Boolean)record.get('IsActive');
                currentUsers.add(user);
            }
            //system.debug('users In Target Org Before Insertion------->>>' +currentUsers);
            
            Set<String> backupUsernames = new Set<String>();
            Set<String> currentUsernames = new Set<String>();
            
            for (UserData userData : backupUsers) {
                if(userData.isActive == 'true'){
                    backupUsernames.add(userData.username);
                }
            }
            //system.debug('backupUsernames------->>>' +backupUsernames);
            for (User user : currentUsers) {
                currentUsernames.add(user.username);
            }
            //system.debug('currentUsernames------->>>' +currentUsernames);
            List<string> usersToDeactivate = new List<string>();
            List<Map<String, Object>> usersToInsert = new List<Map<String, Object>>();
            
            for (User currentUser : currentUsers) {
                if (!backupUsernames.contains(currentUser.Username) && currentUser.IsActive == true) {
                    if(!getGroupMembers.contains(currentUser.Id)){
                        Id deactivateId = currentUser.Id;
                        usersToDeactivate.add(deactivateId);
                    }
                }
            }
            
            for (User currentUser : currentUsers) {
                if (backupUsernames.contains(currentUser.Username) && currentUser.IsActive == false) {
                    Id activateId = currentUser.Id;
                    getGroupMembers.add(activateId);
                }
            }
            
            if(getGroupMembers.size() > 0){
                string jobId;
                jobId = BulkUserActivation.activateUsersUsingBulkAPI(getGroupMembers, instanceUrl, accesstoken);
                jobIds.put(jobId,'Activation');
            }
            //system.debug('usersToDeactivate-------->>>>'+usersToDeactivate);  
            //system.debug('usersToDeactivate Size-------->>>>'+usersToDeactivate.size());  
            for (UserData userData : backupUsers) {
                String username = userData.Username;
                if (!currentUsernames.contains(username)) {
                    Map<String, Object> newUser = new Map<String, Object>();
                    newUser.put('Username', username);
                    newUser.put('Id',userData.id);
                    newUser.put('Email', userData.email);
                    newUser.put('FirstName', userData.firstName);
                    newUser.put('LastName', userData.lastName);
                    newUser.put('Alias', userData.alias);
                    newUser.put('TimeZoneSidKey', userData.timeZoneSidKey);
                    newUser.put('LocaleSidKey', userData.localeSidKey);
                    newUser.put('LanguageLocaleKey', userData.languageLocaleKey);
                    newUser.put('EmailEncodingKey', userData.emailEncodingKey);
                    newUser.put('IsActive',userData.isActive);
                    
                    String profileName = userData.Profile != null ? userData.Profile.Name : null;
                    if(profileName == null || profileName == ''){
                        profileName =  'Chatter Free User';
                    }
                    Id profileId = null;
                    if(profileName != null || profileName != ''){
                        profileId = getProfiles.get(profilename);
                    }else{
                        profileId = getProfiles.get('Chatter Free User');
                    }
                    newUser.put('ProfileId', profileId);
                    
                    String roleName = userData.UserRole != null ? userData.UserRole.DeveloperName : null;
                    Id roleId = null;
                    if(profilename != 'Chatter Free User' && roleName != null && roleName != ''){
                        roleId = getRoles.get(roleName);
                    }else{
                        roleId = null;
                    }
                    newUser.put('UserRoleId', roleId);
                    
                    //system.debug(newUser);
                    usersToInsert.add(newUser);
                    //system.debug('usersToInsert--->'+usersToInsert);
                }
            }
            
            if (!usersToDeactivate.isEmpty()) {
                string userDecativationId;
                userDecativationId = BulkUserDeactivation.deactivateUsersUsingBulkAPI(usersToDeactivate, instanceUrl, accesstoken);
                jobIds.put(userDecativationId,'Deactivation');
                //system.debug('Deactivation Errors---------->'+userDecativationId);
                //system.debug('jobIds after deactivation--------->>>>'+jobIds);
            }
            
            if (!usersToInsert.isEmpty()) {
                string userInsertionId;
                userInsertionId = BulkUserInsertion.insertUsersUsingBulkAPI(usersToInsert, instanceUrl, accesstoken);
                jobIds.put(userInsertionId,'Insertion');
                //system.debug('Insertion Errors---------->'+userInsertionId);    
                //system.debug('jobIds after Insertion--------->>>>'+jobIds);
            }
            //system.debug(backupUsers);
        }
        insert log;
        return backupUsers;
    }
    
    public void execute(Database.BatchableContext bc, List<UserData> scope) {      
        
        List<Map<String, Object>> finalUserRecords = new List<Map<String, Object>> ();
        finalUserRecords = getCurrentUsersFromTargetOrg(instanceUrl,accessToken,log,userQuery);
        List<User> finalUsers = new List<User>();
        map<string,string> finalUserNames = new map<string,string>();
        
        for (Map<String, Object> record : finalUserRecords) {
            User user = new User();
            user.Id = (Id)record.get('Id');
            user.Username = (String)record.get('Username');
            user.IsActive = (Boolean)record.get('IsActive');
            finalUsers.add(user);
        }
        //system.debug('Users In Target Org After Insertion'+finalUsers);
        //system.debug('SIZE Of Users In Target Org After Insertion'+finalUsers.size());
        for (User user : finalUsers) {
            finalUserNames.put(user.Username,user.Id);
        }
        //system.debug('Usernames In Target Org After Insertion'+finalUserNames);
        
        //map<id,list<string>> finalPermSet = new map<id,List<string>>();
        
        Id assigneeId = null;
        for (UserData userData : scope) {
            String name = userData.Username.toLowerCase();
            //system.debug(name);
            //system.debug(finalUserNames.keySet().contains(name));
            if (finalUserNames.keySet().contains(name)) {
                assigneeId = finalUserNames.get(name);
                //system.debug(assigneeId);
                list<string> permSet = new list<string>();
                for(PermissionSet permsetname : userData.PermissionSet){
                    
                    string permissionSetName = permsetname.name;
                    if(permissionSetName != null){
                        Id permissionSetId = getPermSet.get(permissionSetName); 
                        if(permissionSetId != null){
                            permSet.add(permissionSetId);
                        }
                        //system.debug('Permission set size'+permSet.size());
                    }
                }
                finalPermSet.put(assigneeId,permSet);
            }
        }
        //system.debug('finalPermSetbeforePSG---------->'+finalPermSet);        
        
        
        //Id assigneeId = null;
        for (UserData userData : scope) {
            String name = userData.Username.toLowerCase();
            list<string> psgList = new list<string>();
            if (finalUserNames.keySet().contains(name)) {
                assigneeId = finalUserNames.get(name);
                if(userData.PermissionSetGroup != null){
                    for(PermissionSetGroup psg : userData.PermissionSetGroup){
                        string psgName = psg.name;
                        Id psgId = getPSG.get(psgName); 
                        psgList.add(psgId);
                    }
                }
            }
            if(finalPermSet.get(assigneeId)==null){
                finalPermSet.put(assigneeId,psgList);
            }else {
                list<string>list2 = finalPermSet.get(assigneeId);
                list2.addAll(psgList);
                finalPermSet.put(assigneeId,list2);
            }
        }
        //system.debug('finalPermSetSize---------->>>>>>>'+finalPermSet.size());
        //system.debug('finalPermSetafterPSG---------->'+finalPermSet);
        
        //map<id,list<string>> finalGroup = new map<id,List<string>>();
        //system.debug('scope----------->>>>>'+scope);
        for (UserData userData : scope) {
            String name = userData.Username.toLowerCase();
            //system.debug('name----------->>>>>'+name);
            //system.debug('finalUserNames----------->>>>>'+finalUserNames.keySet());
            //system.debug('finalUserNames contains name----------->>>>>'+finalUserNames.keySet().contains(name));
            if (finalUserNames.keySet().contains(name)) {
                assigneeId = finalUserNames.get(name);
                list<string> groupList = new list<string>();
                for (String groupName : userData.Groups) {
                    Id groupId = getGroups.get(groupName);
                    if (groupId != null) { 
                        groupList.add(groupId);
                    }
                }
                finalGroup.put(assigneeId, groupList);
                //system.debug('finalGroup---------->>>>>>>'+finalGroup);
            }
        }
        //system.debug('finalGroupSize---------->>>>>>>'+finalGroup.size());
        //system.debug(finalGroup);
        
    }
    public void finish(Database.BatchableContext bc) {
        if (!finalPermSet.isEmpty()) {
            string userPermissionsetJobId;
            userPermissionsetJobId = BulkPermissionSetAssignment.assignPermissionSetsUsingBulkAPI(finalPermSet, instanceUrl, accesstoken);
            jobIds.put(userPermissionsetJobId,'PermissionSetAssignment');
            //system.debug('PS Errors--------->'+userPermissionsetJobId);
            //system.debug('jobIds after Ps Assignment--------->>>>'+jobIds);
        }
        if (!finalGroup.isEmpty()) {
            string userGroupAssignmentJobId;
            userGroupAssignmentJobId = BulkGroupAssignment.assignGroupsUsingBulkAPI(finalGroup, instanceUrl, accesstoken);
            jobIds.put(userGroupAssignmentJobId,'GroupAssignment');
            //system.debug('Group Errors--------->'+userGroupAssignmentJobId);
        }   
        //system.debug('jobIds Final-------->>>>'+jobIds);      
        id logid = log.id;
        system.debug('jobIds----------->>>>'+jobIds);
        
        DateTime nextRunTime = Datetime.now().addMinutes(1);
        String cronExpression = nextRunTime.second() + ' ' +
            nextRunTime.minute() + ' ' +
            nextRunTime.hour() + ' ' +
            nextRunTime.day() + ' ' +
            nextRunTime.month() + ' ? ' +
            nextRunTime.year();
        string jobName = 'BulkJobPoller '+system.now();
        BulkApiJobpoller scheduledJob = new BulkApiJobpoller(jobName,jobIds, instanceUrl, accesstoken,logId,orgName);
        String scheduleJobId = system.schedule(jobName, cronExpression, scheduledJob);
    }
    
    
    public static List<Map<String, Object>> getCurrentUsersFromTargetOrg(string instanceUrl, string accessToken,logs__c log,string userQuery) {
        //system.debug('log.Status__c in getCurrentUsersFromTargetOrg--->>>'+log.Status__c);
        try{
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + userQuery);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (result.containsKey('records')) {
                    Object records = result.get('records');
                    if (records instanceof List<Object>) {
                        for (Object obj : (List<Object>)records) {
                            users.add((Map<String, Object>)obj);
                        }
                    }
                    String newNextRecordsUrl = (String) result.get('nextRecordsUrl');
                    if (!String.isEmpty(newNextRecordsUrl)) {
                        getCurrentUsersFromTargetOrg(instanceUrl,accessToken,log,newNextRecordsUrl);
                    }
                } else {
                    //system.debug('No records found in response: ' + res.getBody());
                }
            } else {
                //system.debug('Error fetching users from target org: ' + res.getStatusCode() + ' - ' + res.getBody());
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Error_Code__c = String.valueOf(res.getStatusCode());
                    log.Details__c = 'Error fetching users from target org:' + res.getStatus();
                    insert log;
                }
            }
            //system.debug('Target Org users---->'+users);
            return users;
        }catch(exception e){
            //system.debug('Error fetching users from target org: ' + e.getMessage());
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                insert log;
            }
            throw new AuraHandledException('Error fetching users from target org: ' + e.getMessage());
        }
    }
    
    public static Map<String, string> getProfilesFromTargetOrg( String instanceUrl, String accessToken,logs__c log) {
        //system.debug('log.Status__c in getProfilesFromTargetOrg--->>>'+log.Status__c);
        try{
            List<Map<String, Object>> profiles = new List<Map<String, Object>>();
            Map<String, String> profileMap = new Map<String, String>();
            HttpRequest req = new HttpRequest();
            
            String soqlQuery = 'SELECT+Id,Name+FROM+Profile';
            req.setEndpoint(instanceUrl + '/services/data/v59.0/query/?q=' + soqlQuery);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                List<Object> records = (List<Object>) responseMap.get('records');
                
                for (Object recordObj : records) {
                    Map<String, Object> record = (Map<String, Object>) recordObj;
                    
                    String profileName = (String) record.get('Name');
                    String profileId = (String) record.get('Id');
                    
                    profileMap.put(profileName, profileId);
                }        
            }
            else {
                //system.debug('Error fetching profiles from target org: ' + res.getStatusCode() + ' - ' + res.getBody());
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Error_Code__c = String.valueOf(res.getStatusCode());
                    log.Details__c = 'Error fetching profiles from target org:' + res.getStatus();
                    insert log;
                }
            }
            //system.debug('profileMap----------->'+profileMap);
            return profileMap;
        }catch(exception e){
            //system.debug('Error fetching profiles from target org: ' + e.getMessage());
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                insert log;
            }
            throw new AuraHandledException('Error fetching profiles from target org: ' + e.getMessage());
        }
    }
    
    public static Map<String, string> getRolesFromTargetOrg(string instanceUrl, string accessToken,logs__c log) {
        //system.debug('log.Status__c in getRolesFromTargetOrg--->>>'+log.Status__c);
        try{
            List<Map<String, Object>> roles = new List<Map<String, Object>>();
            Map<String, String> roleMap = new Map<String, String>();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + '/services/data/v59.0/query/?q=SELECT+Id,DeveloperName+FROM+UserRole');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) responseMap.get('records');
                
                for (Object recordObj : records) {
                    Map<String, Object> record = (Map<String, Object>) recordObj;
                    
                    String roleName = (String) record.get('DeveloperName');
                    String roleId = (String) record.get('Id');
                    
                    roleMap.put(roleName, roleId);
                } 
            } else {
                //system.debug('Error fetching roles from target org: ' + res.getStatusCode() + ' - ' + res.getBody());
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Error_Code__c = String.valueOf(res.getStatusCode());
                    log.Details__c = 'Error fetching roles from target org:' + res.getStatus();
                    insert log;
                }
            }
            //system.debug('roleMap---->'+roleMap);
            return roleMap;
        }catch(exception e){
            //system.debug('Error fetching roles from target org: ' + e.getMessage());
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                insert log;
            }
            throw new AuraHandledException('Error fetching roles from target org: ' + e.getMessage());
        }
    }
    
    public static map<string,string> getPermissionSets(string instanceUrl,string accessToken,logs__c log){
        //system.debug('log.Status__c in getPermissionSets--->>>'+log.Status__c);
        try{
            Map<String, String> permSetMap = new Map<String, String>();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + '/services/data/v59.0/query/?q=SELECT+Id,Name+FROM+PermissionSet');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) responseMap.get('records');
                
                for (Object recordObj : records) {
                    Map<String, Object> record = (Map<String, Object>) recordObj;
                    
                    String permSetId = (String) record.get('Id');
                    String permSetName = (String) record.get('Name');
                    
                    permSetMap.put(permSetName, permSetId);
                } 
            } else {
                //system.debug('Error fetching PermissionSets from target org: ' + res.getStatusCode() + ' - ' + res.getBody());
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Error_Code__c = String.valueOf(res.getStatusCode());
                    log.Details__c = 'Error fetching PermissionSets from target org:' + res.getStatus();
                    insert log;
                }
            }
            //system.debug('permSetMap->'+permSetMap);
            return permSetMap;
        }catch(exception e){
            //system.debug('Error fetching PermissionSets from target org: ' + e.getMessage());
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                insert log;
            }
            throw new AuraHandledException('Error fetching PermissionSets from target org: ' + e.getMessage());
        }
    } 
    
    public static map<string,string> getPSG(string instanceUrl,string accessToken,logs__c log){
        //system.debug('log.Status__c in getPSG--->>>'+log.Status__c);
        try{
            Map<String, String> psgMap = new Map<String, String>();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + '/services/data/v59.0/query/?q=SELECT+Id,DeveloperName+FROM+PermissionSetGroup');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) responseMap.get('records');
                
                for (Object recordObj : records) {
                    Map<String, Object> record = (Map<String, Object>) recordObj;
                    
                    String psgId = (String) record.get('Id');
                    String psgName = (String) record.get('DeveloperName');
                    
                    psgMap.put(psgName, psgId);
                } 
            } else {
                //system.debug('Error fetching PSG from target org: ' + res.getStatusCode() + ' - ' + res.getBody());
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Error_Code__c = String.valueOf(res.getStatusCode());
                    log.Details__c = 'Error fetching PSG from target org:' + res.getStatus();
                    insert log;
                }
            }
            //system.debug('psgMap->'+psgMap);
            return psgMap;
        }catch(exception e){
            //system.debug('Error fetching PSG from target org: ' + e.getMessage());
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                insert log;
            }
            throw new AuraHandledException('Error fetching PSG from target org: ' + e.getMessage());
        }
    } 
    
    public static map<string,string> getGroups(string instanceUrl,string accessToken,logs__c log){
        //system.debug('log.Status__c in getGroups--->>>'+log.Status__c);
        try{
            Map<String, String> groupMap = new Map<String, String>();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + '/services/data/v59.0/query/?q=SELECT+Id,Name,DeveloperName+FROM+Group');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) responseMap.get('records');
                
                for (Object recordObj : records) {
                    Map<String, Object> record = (Map<String, Object>) recordObj;
                    
                    String groupId = (String) record.get('Id');
                    String groupName = (String) record.get('DeveloperName');
                    
                    groupMap.put(groupName, groupId);
                } 
            } else {
                //system.debug('Error fetching Groups from target org: ' + res.getStatusCode() + ' - ' + res.getBody());
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Error_Code__c = String.valueOf(res.getStatusCode());
                    log.Details__c = 'Error fetching Groups from target org:' + res.getStatus();
                    insert log;
                }
            }
            //system.debug('groupMap->'+groupMap);
            return groupMap;
        }catch(exception e){
            //system.debug('Error fetching Groups from target org: ' + e.getMessage());
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                insert log;
            }
            throw new AuraHandledException('Error fetching Groups from target org: ' + e.getMessage());
        }
    }         
    
    public list<string> getGroupMembers(string instanceUrl,string accessToken,logs__c log,Id groupId,Map<Id,string> jobIds){
        string jobId;
        list<id> groupmembersList = new list<id>();
        //system.debug('log.Status__c in getGroups--->>>'+log.Status__c);
        if(groupId != null){
            try{
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint(instanceUrl + '/services/data/v59.0/query/?q=SELECT+Id,GroupId,UserOrGroupId+FROM+GroupMember+WHERE+GroupId=\''+groupId+'\'');
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setTimeout(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    List<Object> records = (List<Object>) responseMap.get('records');
                    
                    for (Object recordObj : records) {
                        Map<String, Object> record = (Map<String, Object>) recordObj;
                        
                        //String groupId = (String) record.get('GroupId');
                        String userId = (String) record.get('UserOrGroupId');
                        
                        groupmembersList.add(userId);
                    } 
                    string userId1 = (String)UserInfo.getUserId();
                    user userDetails =[SELECT id,Username from user where id =:userId1 LIMIT 1];
                    string userName = (String)userDetails.Username;
                    Id userNameId = getInitiatedUserFromTargetOrg(instanceUrl,accessToken,log,userName);
                    if(!string.isBlank(userNameId)){
                        groupmembersList.add(userNameId);
                    }
                    system.debug('groupmembersList---->>>>'+groupmembersList);
                    /*if(groupmembersList != null){
jobId = BulkUserActivation.activateUsersUsingBulkAPI(groupmembersList, instanceUrl, accesstoken);
jobIds.put(jobId,'Activation');
}*/
                } else {
                    //system.debug('Error fetching Groups from target org: ' + res.getStatusCode() + ' - ' + res.getBody());
                    if(log.Status__c == 'InProgress'){
                        log.Status__c = 'Failed';
                        log.Error_Code__c = String.valueOf(res.getStatusCode());
                        log.Details__c = 'Error fetching Groups from target org:' + res.getStatus();
                        insert log;
                    }
                }
                //system.debug('groupmembersList->'+groupmembersList);
                return groupmembersList;
            }catch(exception e){
                //system.debug('Error fetching Groups from target org: ' + e.getMessage());
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Details__c = e.getMessage();
                    insert log;
                }
                throw new AuraHandledException('Error fetching Groups from target org: ' + e.getMessage());
            }
        }else{
            try{
                string userId1 = (String)UserInfo.getUserId();
                user userDetails =[SELECT id,Username from user where id =:userId1 LIMIT 1];
                string userName = (String)userDetails.Username;
                Id userNameId = getInitiatedUserFromTargetOrg(instanceUrl,accessToken,log,userName);
                if(!string.isBlank(userNameId)){
                    groupmembersList.add(userNameId);
                }
                system.debug('groupmembersList---->>>>'+groupmembersList);
                /*if(groupmembersList.size() > 0){
jobId = BulkUserActivation.activateUsersUsingBulkAPI(groupmembersList, instanceUrl, accesstoken);
jobIds.put(jobId,'Activation');
}*/
                return groupmembersList;
            }catch(exception e){
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Details__c = e.getMessage();
                    insert log;
                }
                throw new AuraHandledException('Error fetching Groups from target org: ' + e.getMessage());
            }
        }
    }
    
    public static Id getInitiatedUserFromTargetOrg(string instanceUrl, string accessToken,logs__c log,string username) {
        Id userId; 
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + '/services/data/v59.0/query/?q=select+Id,Username+from+User+Where+UserName=\''+username+'\'');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> queryResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>)queryResponse.get('records');
                if (!records.isEmpty()) {
                    Map<String, Object> userRecord = (Map<String, Object>)records.get(0);
                    userId = (Id)userRecord.get('Id');
                    system.debug('userId---->>>>'+userId);
                    system.debug('Inside Initiate Users');
                    return userId;
                } else {
                    System.debug('No user found with the username: ' + username);
                    return null;
                }
            } else {
                if(log.Status__c == 'InProgress'){
                    log.Status__c = 'Failed';
                    log.Error_Code__c = String.valueOf(res.getStatusCode());
                    log.Details__c = 'Error fetching Initiated user from target org:' + res.getStatus();
                    insert log;
                }
            }
            return userId;
            //system.debug('Target Org users---->'+users);
        }catch(exception e){
            //system.debug('Error fetching Initiated user from target org: ' + e.getMessage());
            if(log.Status__c == 'InProgress'){
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                insert log;
            }
            throw new AuraHandledException('Error fetching Initiated user from target org: ' + e.getMessage());
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