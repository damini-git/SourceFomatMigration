public class PreRefreshUserBackup {
    public static String instanceUrl; 
    public static String accessToken; 
    
    //@future(callout = true)
    @AuraEnabled
    public static void getAllUsersWithProfilesAndRoles(Id refTempId,List<string> usernames,string accessToken, id userDataRetrieveLogId) {
        Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c FROM Refresh_Template__c where id =: refTempId LIMIT 1];
        string domainUrl = refTemp.Parent_Org__r.Domain_Url__c;
        
        Integer totalBatchSize = usernames.size();
        Integer index = 0;
        Integer totalUsernames = usernames.size();
        List<Map<String, Object>> usersList = new List<Map<String, Object>>();
        Integer count = 0;
        
        if(!test.isRunningTest()){
            system.enqueueJob(new GetAllUsersQueueable(refTempId, domainUrl, accessToken, usersList, usernames, index, count, totalBatchSize,userDataRetrieveLogId));
        }else{
            AsyncOptions asyncOptions = new AsyncOptions();
            asyncOptions.MaximumQueueableStackDepth = 100;
            system.enqueueJob(new GetAllUsersQueueable(refTempId, domainUrl, accessToken, usersList, usernames, index, count, totalBatchSize,userDataRetrieveLogId),asyncOptions);
        }
    }
    
    public class GetAllUsersQueueable implements Queueable, Database.AllowsCallouts{
        private Id refTempId;
        private String domainUrl;
        private String accessToken;
        private List<Map<String, Object>> usersList;
        private List<String> usernames;
        private Integer index = 0;
        private integer count = 0;
        private integer totalBatchSize;
        private id userDataRetrieveLogId;
        
        public GetAllUsersQueueable(Id refTempId, String domainUrl, String accessToken, List<Map<String, Object>> usersList, List<String> usernames, Integer index, Integer count, Integer totalBatchSize, id userDataRetrieveLogId) { // String queryEndpoint,
            this.refTempId = refTempId;
            this.domainUrl = domainUrl;
            this.accessToken = accessToken;
            this.usersList = usersList;
            this.usernames = usernames;
            this.index = index;
            this.count = count;
            this.totalBatchSize = totalBatchSize;
            this.userDataRetrieveLogId = userDataRetrieveLogId;
        }
        
        public void execute(QueueableContext context) {
            logs__c log = [SELECT Id, Name, Log_Type__c, Status__c FROM Logs__c where id =:userDataRetrieveLogId];
            try{
                List<String> currentBatch = new List<String>();
                Integer i;
                Integer batch = totalBatchSize / 200;
                system.debug('totalBatchSize --- ' + totalBatchSize);
                system.debug('batch --- ' + batch);
                if(index == 0){
                    currentBatch.add(usernames[0]);
                    index = (totalBatchSize == 1) ? 0 : index + 1;
                }
                
                system.debug('index before for loop --- ' + index);
                system.debug('totalBatchSize---->>>>'+totalBatchSize);
                if(totalBatchSize <= 200){
                    for(i = index; i < totalBatchSize; i++){
                        currentBatch.add(usernames[i]);
                    }
                }
                else{
                    if(Math.Mod(totalBatchSize, index) == 0){
                        system.debug('inside 0 reminder if condition');
                        if(totalBatchSize > 200){
                            for(i = index; i < index + 199; i++){
                                currentBatch.add(usernames[i]);
                            }
                            count += 1;
                        }
                        else{
                            for(i = index; i < totalBatchSize; i++){
                                currentBatch.add(usernames[i]);
                            }
                            count += 1;
                        }
                    }
                    if(Math.Mod(totalBatchSize, index) != 0){
                        system.debug('inside  NOT 0 reminder if condition');
                        
                        if(count != batch){
                            for(i = index; i <= index + 199 ; i++){
                                currentBatch.add(usernames[i]);
                            }
                            count += 1;
                        }
                        else if(count == batch){
                            for(i = index; i <= index + Math.Mod(totalBatchSize, index) - 1 ; i++){
                                currentBatch.add(usernames[i]);
                            }
                            count += 1;
                        }
                    }
                    index = i;
                }
                
                system.debug('batch count --- ' + count);
                system.debug('index after for loop --- ' + index);
                
                String userStr = '(\'' + String.join(currentBatch, '\',\'') + '\')';
                String queryEndpoint = '/services/data/v59.0/query/?q=SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User+WHERE+username+IN+' + userStr + '+ORDER+BY+Name+ASC';
                
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(domainUrl + queryEndpoint);
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json');
                req.setTimeout(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    String jsonResponse = res.getBody();
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                    List<Object> records = (List<Object>) response.get('records');
                    
                    for (Object groupObj : records) {
                        Map<String, Object> record = (Map<String, Object>) groupObj;
                        String recId = (String) record.get('Id');
                        Map<String, Object> user = new Map<String, Object>();
                        user.put('Id', recId);
                        user.put('Name', record.get('Name'));
                        user.put('FirstName', record.get('FirstName'));
                        user.put('LastName', record.get('LastName'));
                        user.put('Email', record.get('Email'));
                        user.put('Alias', record.get('Alias'));
                        user.put('Username', record.get('Username'));
                        user.put('TimeZoneSidKey', record.get('TimeZoneSidKey'));
                        user.put('LocaleSidKey', record.get('LocaleSidKey'));
                        user.put('LanguageLocaleKey', record.get('LanguageLocaleKey'));
                        user.put('EmailEncodingKey', record.get('EmailEncodingKey'));
                        user.put('IsActive', record.get('IsActive'));
                        
                        if (record.get('Profile') != null) {
                            Map<String, Object> profile = (Map<String, Object>) record.get('Profile');
                            user.put('Profile', new Map<String, String>{ 'Name' => (String) profile.get('Name') });
                        } else {
                            user.put('Profile', new Map<String, String>{ 'Name' => null });
                        }
                        
                        if (record.get('UserRole') != null) {
                            Map<String, Object> role = (Map<String, Object>) record.get('UserRole');
                            user.put('UserRole', new Map<String, String>{ 'DeveloperName' => (String) role.get('DeveloperName') });
                        } else {
                            user.put('UserRole', new Map<String, String>{ 'DeveloperName' => null });
                        }
                        
                        usersList.add(user);
                        //system.debug('usersList.size inside----------->>>>'+usersList.size());
                        //system.debug('totalBatchSize inside--------->>>>>>'+totalBatchSize);
                    }
                    system.debug('usersList.size----------->>>>'+usersList.size());
                    system.debug('totalBatchSize--------->>>>>>'+totalBatchSize);
                    system.debug('index--------->>>>'+index);
                    
                    if(usersList.size() != totalBatchSize){
                        system.debug(System.AsyncInfo.getCurrentQueueableStackDepth());
                        system.debug(System.AsyncInfo.getMaximumQueueableStackDepth());
                        system.debug(System.AsyncInfo.getMinimumQueueableDelayInMinutes());
                        
                        system.enqueueJob(new GetAllUsersQueueable(refTempId, domainUrl, accessToken, usersList, usernames, index, count, totalBatchSize,userDataRetrieveLogId));
                    }
                    
                    if(usersList.size() == totalBatchSize){
                        string endPoint = '/services/data/v59.0/query/?q=SELECT+Id,Name,DeveloperName+FROM+Group';
                        
                        system.debug('Get Groups Endpoint----------->>>>'+endPoint);
                        system.debug('Get Groups domainUrl----------->>>>'+domainUrl);
                        system.enqueueJob(new GetGroupsQueueable(endPoint, refTempId, usersList, domainUrl, accessToken, userDataRetrieveLogId));
                    }
                }else{
                    log.Status__c = 'Failed';
                    log.Details__c = res.getStatus();
                    update log;
                }
            }
            catch(exception e){
                system.debug('Error------>>>>'+e.getMessage());
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                update log;
            }
        }
    }
    
    public class GetGroupsQueueable implements Queueable, Database.AllowsCallouts {
        private Id orgId;
        private string endpoint;
        private Id refTempId;
        private List<Map<String, Object>> usersList;
        private string instanceUrl;
        Private string accessToken;
        private id userDataRetrieveLogId;
        
        public GetGroupsQueueable(string endpoint,Id refTempId, List<Map<String, Object>> usersList,string instanceUrl, string accessToken,id userDataRetrieveLogId){
            //this.orgId = orgId;
            this.endpoint = endpoint;
            this.refTempId = refTempId;
            this.usersList = usersList;
            this.instanceUrl = instanceUrl;
            this.accessToken = accessToken;
            this.userDataRetrieveLogId = userDataRetrieveLogId;
        }
        
        public void execute(QueueableContext context){
            logs__c log = [SELECT Id, Name, Log_Type__c, Status__c FROM Logs__c where id =:userDataRetrieveLogId];
            //system.debug('InsideGetGroups------>' + 'YES');
            try{
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(instanceUrl+endpoint);
                req.setHeader('Authorization', 'Bearer ' + accessToken); 
                req.setHeader('Content-Type', 'application/json');
                req.setTimeout(120000);
                //system.debug('GetGroupsQueueablequeryEndpoint------>>>'+endpoint);
                //system.debug('GetGroupsQueueablequeryEndpoint------>>>'+req.getEndpoint());
                Http http = new Http();
                HttpResponse res = http.send(req);
                //system.debug(res.getBody());
                
                List<Id> groupIds = new List<Id>();
                if (res.getStatusCode() == 200) {
                    String jsonResponse = res.getBody();
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                    List<Object> records = (List<Object>) response.get('records');
                    
                    for (Object groupObj : records) {
                        Map<String, Object> record = (Map<String, Object>) groupObj;
                        Id recId = (Id) record.get('Id');
                        groupIds.add(recId);
                    }
                    //system.debug(groupIds);
                    
                    String newNextRecordsUrl = (String) response.get('nextRecordsUrl');
                    if (!String.isEmpty(newNextRecordsUrl)) {
                        //system.debug('Next records URL found. Enqueuing another GetGroupsQueueable job.');
                        System.enqueueJob(new GetGroupsQueueable(newNextRecordsUrl, refTempId, usersList,instanceUrl,accessToken,userDataRetrieveLogId));
                    } else {
                        //system.debug('all data is fetched...');
                        //system.debug(System.AsyncInfo.getCurrentQueueableStackDepth());
                        //system.debug(System.AsyncInfo.getMaximumQueueableStackDepth());
                        //system.debug(System.AsyncInfo.getMinimumQueueableDelayInMinutes());
                        string gmEndpoint = '/services/data/v59.0/query/?q=SELECT+Id,GroupId,UserOrGroupId,group.DeveloperName+FROM+GroupMember+WHERE+GroupId+IN' ;
                        system.enqueueJob(new GetGroupMembersQueueable(refTempId,groupIds, usersList,gmEndpoint,instanceUrl,accessToken,userDataRetrieveLogId));
                    }
                }else{
                    log.Status__c = 'Failed';
                    log.Details__c = res.getStatus();
                    update log;
                }
            }
            catch(exception e){
                system.debug('Error------>>>>'+e.getMessage());
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                update log;
            }
        }
    }
    
    public class GetGroupMembersQueueable implements Queueable, Database.AllowsCallouts {
        //private Id orgId;
        private Id refTempId;
        Private List<Id> groupIds;
        private List<Map<String, Object>> usersList;
        private string gmEndpoint;
        private string instanceUrl;
        private string accessToken;
        private id userDataRetrieveLogId;
        
        public GetGroupMembersQueueable(Id refTempId,List<Id> groupIds, List<Map<String, Object>> usersList,string gmEndpoint,string instanceUrl,string accessToken,id userDataRetrieveLogId){
            // this.orgId = orgId;
            this.refTempId = refTempId;
            this.groupIds = groupIds;
            this.usersList = usersList;
            this.gmEndpoint = gmEndpoint;
            this.instanceUrl = instanceUrl;
            this.accessToken = accessToken;
            this.userDataRetrieveLogId = userDataRetrieveLogId;
        }
        
        public void execute(QueueableContext context){
            logs__c log = [SELECT Id, Name, Log_Type__c, Status__c FROM Logs__c where id =:userDataRetrieveLogId];
            try{
                //system.debug('InsideGetGroupMembers------>' + 'YES');
                String idList = '(\'' + String.join(groupIds, '\',\'') + '\')';
                //system.debug('GroupIds------->>>'+idList);
                String endpoint = instanceUrl+gmEndpoint+idList;
                
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(endpoint);
                req.setHeader('Authorization', 'Bearer ' + accessToken); 
                req.setHeader('Content-Type', 'application/json');
                req.setTimeOut(120000);
                //system.debug('GetGroupmembersQueueablequeryEndpoint------>>>'+req.getEndpoint());
                Http http = new Http();
                HttpResponse res = http.send(req);
                //system.debug(res.getBody());
                
                Map<Id, List<String>> userGroupsMap = new Map<Id, List<String>>();
                //system.debug(res.getStatusCode());
                
                if (res.getStatusCode() == 200) {
                    String jsonResponse = res.getBody();
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                    List<Object> records = (List<Object>) response.get('records');
                    
                    for (Object groupObj : records) {
                        Map<String, Object> record = (Map<String, Object>) groupObj;
                        //system.debug('GetGroupMembers-------->'+record);
                        Id userId = (Id) record.get('UserOrGroupId');
                        Id groupId = (Id) record.get('GroupId');
                        
                        if (!userGroupsMap.containsKey(userId)) {
                            userGroupsMap.put(userId, new List<String>());
                        }
                        Map<String, Object> groups = (Map<String, Object>)record.get('Group');
                        String groupName = (String) groups.get('DeveloperName');
                        //system.debug(groupName);
                        userGroupsMap.get(userId).add(groupName);
                    }
                    
                    //system.debug('USERGROUPMAP--------->>'+userGroupsMap);
                    
                    for (Map<String, Object> user : usersList) {
                        Id userId = (Id) user.get('Id');
                        //system.debug('UserId--->>>'+userId);
                        //system.debug('USER in the List or not--------------->>>>>'+userGroupsMap.containsKey(userId));
                        if (userGroupsMap.containsKey(userId)) {
                            user.put('Groups', userGroupsMap.get(userId));
                            //system.debug('Corresponding Groups------------>>>>>'+userGroupsMap.get(userId));
                        } else {
                            user.put('Groups', new List<String>());
                        }
                    }
                    //system.debug('usersList.size in groupMembers---------->>>>>>'+usersList.size());
                    
                    String newNextRecordsUrl = (String) response.get('nextRecordsUrl');
                    if (!String.isEmpty(newNextRecordsUrl)) {
                        //system.debug('Next records URL found. Enqueuing another GetGroupMembersQueueable job.');
                        System.enqueueJob(new GetGroupMembersQueueable( refTempId, groupIds, usersList,newNextRecordsUrl,instanceUrl,accessToken,userDataRetrieveLogId));
                    } else {
                        //system.debug('all data is fetched...');
                        string psEndpoint = '/services/data/v59.0/query?q=SELECT+Id,AssigneeId,Assignee.Name,Assignee.Username,PermissionSetId,PermissionSet.Name,PermissionSetGroup.DeveloperName+From+PermissionSetAssignment+Order+By+Assignee.Name+ASC';

                        
                        //system.debug(System.AsyncInfo.getCurrentQueueableStackDepth());
                        //system.debug(System.AsyncInfo.getMaximumQueueableStackDepth());
                        //system.debug(System.AsyncInfo.getMinimumQueueableDelayInMinutes());
                        
                        system.enqueueJob(new GetPermsetAndPSGQueueable( refTempId, usersList,userGroupsMap,psEndpoint,instanceUrl,accessToken,userDataRetrieveLogId));
                    }
                }
                else{
                    log.Status__c = 'Failed';
                    log.Details__c = res.getStatus();
                    update log; 
                }
            }
            catch(exception e){
                system.debug('Error------>>>>'+e.getMessage());
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                update log;
            }
        }
    }
    
    public class GetPermsetAndPSGQueueable implements Queueable, Database.AllowsCallouts {
        // private Id orgId;
        private Id refTempId;
        private Map<Id, List<String>> userGroupsMap;
        private List<Map<String, Object>> usersList;
        private String psEndpoint;
        private String instanceUrl;
        private String accessToken;
        private id userDataRetrieveLogId;
        
        public GetPermsetAndPSGQueueable( Id refTempId, List<Map<String, Object>> usersList, Map<Id, List<String>> userGroupsMap, String psEndpoint, String instanceUrl, String accessToken,id userDataRetrieveLogId) {
            // this.orgId = orgId;
            this.refTempId = refTempId;
            this.userGroupsMap = userGroupsMap;
            this.usersList = usersList;
            this.psEndpoint = psEndpoint;
            this.instanceUrl = instanceUrl;
            this.accessToken = accessToken;
            this.userDataRetrieveLogId = userDataRetrieveLogId;
        }
        
        public void execute(QueueableContext context) {
            logs__c log = [SELECT Id, Name, Log_Type__c, Status__c FROM Logs__c where id =:userDataRetrieveLogId];
            
            try{
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(instanceUrl + psEndpoint);
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setHeader('Content-Type', 'application/json');
                req.setTimeout(120000);
                
                //system.debug('GetPermsetsQueueablequeryEndpoint------>>>'+req.getEndpoint());
                Http http = new Http();
                HttpResponse res = http.send(req);
                system.debug(res.getBody());
                
                Map<String, Map<String, Object>> usernameToUserMap = new Map<String, Map<String, Object>>();
                for (Map<String, Object> user : usersList) {
                    String username = (String) user.get('Username');
                    if (username != null) {
                        usernameToUserMap.put(username, user);
                    }
                }
                
                if (res.getStatusCode() == 200) {
                    String jsonResponse = res.getBody();
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                    List<Object> records = (List<Object>) response.get('records');
                    
                    for (Object recordObj : records) {
                        Map<String, Object> record = (Map<String, Object>) recordObj;
                        String permissionSetName;
                        String psgName;
                        String username = (String) ((Map<String, Object>) record.get('Assignee')).get('Username');
                        
                        if (usernameToUserMap.containsKey(username)) {
                            Map<String, Object> user = usernameToUserMap.get(username);
                            
                            if (record.get('PermissionSet') != null) {
                                permissionSetName = (String) ((Map<String, Object>) record.get('PermissionSet')).get('Name');
                            }
                            if (record.get('PermissionSetGroup') != null) {
                                psgName = (String) ((Map<String, Object>) record.get('PermissionSetGroup')).get('DeveloperName');
                            }
                            
                            if (permissionSetName != null) {
                                if (!user.containsKey('PermissionSet')) {
                                    user.put('PermissionSet', new List<Map<String, String>>());
                                }
                                ((List<Map<String, String>>) user.get('PermissionSet')).add(new Map<String, String>{ 'Name' => permissionSetName });
                            }
                            
                            if (psgName != null) {
                                if (!user.containsKey('PermissionSetGroup')) {
                                    user.put('PermissionSetGroup', new List<Map<String, String>>());
                                }
                                ((List<Map<String, String>>) user.get('PermissionSetGroup')).add(new Map<String, String>{ 'Name' => psgName });
                            }
                        }
                    }
                    
                    /*for (Map<String, Object> user : usersList) {
                        if (!user.containsKey('PermissionSet')) {
                            user.put('PermissionSet', new List<Map<String, String>>());
                        }
                        if (!user.containsKey('PermissionSetGroup')) {
                            user.put('PermissionSetGroup', new List<Map<String, String>>());
                        }
                    }*/
                    //system.debug('usersList.size in PermSet---------->>>>>>' + usersList.size());
                    
                    String newNextRecordsUrl = (String) response.get('nextRecordsUrl');
                    if (!String.isEmpty(newNextRecordsUrl) && shouldContinueProcessing(records)) {
                        //system.debug('Next records URL found. Enqueuing another GetPermsetAndPSGQueueable job.');
                        System.enqueueJob(new GetPermsetAndPSGQueueable( refTempId, usersList, userGroupsMap, newNextRecordsUrl, instanceUrl, accessToken,userDataRetrieveLogId));
                        
                        //system.debug(System.AsyncInfo.getCurrentQueueableStackDepth());
                        //system.debug(System.AsyncInfo.getMaximumQueueableStackDepth());
                        //system.debug(System.AsyncInfo.getMinimumQueueableDelayInMinutes());
                        
                        
                    } else {
                        //system.debug('All data fetched, saving results...');
                        
                        //system.debug(System.AsyncInfo.getCurrentQueueableStackDepth());
                        //system.debug(System.AsyncInfo.getMaximumQueueableStackDepth());
                        //system.debug(System.AsyncInfo.getMinimumQueueableDelayInMinutes());
                        
                        saveJSONContent( refTempId, 'User Data', usersList,userDataRetrieveLogId);
                    }
                }else{
                    log.Status__c = 'Failed';
                    log.Details__c = res.getStatus();
                    update log;
                }
            }catch(exception e){
                system.debug('Error------>>>>'+e.getMessage());
                log.Status__c = 'Failed';
                log.Details__c = e.getMessage();
                update log; 
            }
        }
        
        private Boolean shouldContinueProcessing(List<Object> records) {
            Integer maxRecordsPerBatch = 100; 
            return records.size() > 0 && records.size() <= maxRecordsPerBatch;
        }
    }
    
    public static void saveJSONContent( Id refTempId, String name, List<Map<String, Object>> userList,id userDataRetrieveLogId) {
        logs__c log = [SELECT Id, Name, Log_Type__c, Status__c FROM Logs__c where id =:userDataRetrieveLogId];
        String jsonContent = JSON.serialize(new Map<String, List<Map<String, Object>>>{ 'User' => userList });
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = name + ' - Export - JSON';
        contentVersion.PathOnClient = '/' + contentVersion.Title + '.json';
        contentVersion.VersionData = Blob.valueOf(jsonContent);
        insert contentVersion;
        
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = refTempId;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink;
        
        log.Status__c = 'Success';
        update log;
                
        //system.debug('JSON export completed: ' + contentVersion.Title);
    }
}