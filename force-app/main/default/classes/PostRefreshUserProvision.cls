public class PostRefreshUserProvision {
    public static string instanceUrl;// = 'https://cloudfulcrum--refreshsf.sandbox.my.salesforce.com';
    public static string accessToken;// = '!AQEAQAVPryiLKdt2yGbUeFv7rOEjsbxi_U.0pxlzhc_egWEh7.truKvvkRZSY18ruEunI079BuMT5jS3f8ikqiyca46BbSXS';
    
    @future(callout = true)
    public static void getAllUsersWithProfilesAndRoles(Id orgId,Id refTempId,List<string> usernames) {
        String userStr = '(\''+String.join(usernames,'\',\'')+'\')';
        instanceUrl = [select Id, Name, Domain_Url__c, Access_Token__c from Org__c where Id =: orgId].Domain_Url__c;
        if(!test.isRunningTest()){
            accessToken = RefreshTokenCallout.fetchAT1(orgId);
        }else{
            accessToken ='123456789';
        }
        system.debug('InstanceUrl---------->'+instanceUrl);
        system.debug('accessToken---------->'+accessToken);
        
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(instanceUrl+'/services/data/v59.0/query/?q=SELECT+Id,name,FirstName,LastName,Email,Alias,Username,IsActive,TimeZoneSidKey,LocaleSidKey,Profile.name,UserRole.DeveloperName,LanguageLocaleKey,EmailEncodingKey+FROM+User+WHERE+username+IN+'+userStr);
        req.setHeader('Authorization', 'Bearer '+ accessToken); 
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug(res.getBody());
        
        if (res.getStatusCode() == 200) {
            String jsonResponse = res.getBody();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            system.debug('response----------->'+response);
            List<Object> records = (List<Object>) response.get('records');
            List<Map<String, Object>> usersList = new List<Map<String, Object>>();
            List<Id> uid = new List<Id>();
            system.debug(records);
            for (Object groupObj : records) {
                Map<String, Object> record = (Map<String, Object>) groupObj;
                String recId = (String) record.get('Id');
                uid.add(recId);
                
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
            }
            getGroups(orgId,refTempId, usersList);
            
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
    }
    
    public static void getGroups(Id orgId,Id refTempId, List<Map<String, Object>> usersList) {
        system.debug('InsideGetGroups------>'+'YES');
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(instanceUrl+'/services/data/v59.0/query/?q=SELECT+Id,Name,DeveloperName+FROM+Group');
        req.setHeader('Authorization', 'Bearer '+ accessToken); 
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug(res.getBody());
        
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
            System.debug(groupIds);
            getGroupMembers(orgId,refTempId,groupIds, usersList);
        }            
    }
    
    public static void getGroupMembers(Id orgId,Id refTempId,List<Id> groupIds, List<Map<String, Object>> usersList) {
        system.debug('InsideGetGroupMembers------>'+'YES');
        String idList = '(\'' + String.join(groupIds, '\',\'') + '\')';
       // String query = 'SELECT+Id,GroupId,UserOrGroupId,group.DeveloperName+FROM+GroupMember+WHERE+GroupId+IN ' + idList;
        String endpoint = instanceUrl+'/services/data/v59.0/query/?q=SELECT+Id,GroupId,UserOrGroupId,group.DeveloperName+FROM+GroupMember+WHERE+GroupId+IN' + idList;
        
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Bearer '+ accessToken); 
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug(res.getBody());
        
        if (res.getStatusCode() == 200) {
            String jsonResponse = res.getBody();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            system.debug('GetGroupMembersresponse-------->'+response);
            List<Object> records = (List<Object>) response.get('records');
            
            Map<Id, List<String>> userGroupsMap = new Map<Id, List<String>>();
            
            for (Object groupObj : records) {
                Map<String, Object> record = (Map<String, Object>) groupObj;
                system.debug('GetGroupMembers-------->'+record);
                Id userId = (Id) record.get('UserOrGroupId');
                Id groupId = (Id) record.get('GroupId');
                
                if (!userGroupsMap.containsKey(userId)) {
                    userGroupsMap.put(userId, new List<String>());
                }
                Map<String, Object> groups = (Map<String, Object>)record.get('Group');
                String groupName = (String) groups.get('DeveloperName');
                System.debug(groupName);
                userGroupsMap.get(userId).add(groupName);
            }
            
            for (Map<String, Object> user : usersList) {
                Id userId = (Id) user.get('Id');
                if (userGroupsMap.containsKey(userId)) {
                    user.put('Groups', userGroupsMap.get(userId));
                } else {
                    user.put('Groups', new List<String>());
                }
            }
            getPermsetAndPSG(orgId,refTempId,usersList);
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
    }
    
    public static void getPermsetAndPSG(Id orgId,Id refTempId,List<Map<String, Object>> usersList) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(instanceUrl+'/services/data/v59.0/query/?q=SELECT+AssigneeId,Assignee.Username,PermissionSet.Name,PermissionSetGroup.DeveloperName+FROM+PermissionSetAssignment');
        req.setHeader('Authorization', 'Bearer '+ accessToken); 
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug(res.getBody());
        
        if (res.getStatusCode() == 200) {
            String jsonResponse = res.getBody();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            List<Object> records = (List<Object>) response.get('records');
            
            Map<String, Map<String, Object>> userPermissionsMap = new Map<String, Map<String, Object>>();
            
            for (Object recordObj : records) {
                Map<String, Object> record = (Map<String, Object>) recordObj;
                String permissionSetName;
                String psgName; 
                
                String username = (String) ((Map<String, Object>) record.get('Assignee')).get('Username');
                if(record.get('PermissionSet')!=null){
                    permissionSetName = (String) ((Map<String, Object>) record.get('PermissionSet')).get('Name');
                }
                if(record.get('PermissionSetGroup')!=null){
                    psgName = (String) ((Map<String, Object>) record.get('PermissionSetGroup')).get('DeveloperName');
                }
                
                for (Map<String, Object> user : usersList) {
                    if (user.get('Username') != null && user.get('Username').equals(username)) {
                        if (!userPermissionsMap.containsKey(username)) {
                            userPermissionsMap.put(username, new Map<String, Object>{
                                'PermissionSet' => new List<Map<String, String>>(),
                                    'PermissionSetGroup' => new List<Map<String, String>>()
                                    });
                        }
                        
                        if (permissionSetName != null) {
                            ((List<Map<String, String>>) userPermissionsMap.get(username).get('PermissionSet')).add(new Map<String, String>{ 'Name' => permissionSetName });
                        }
                        
                        if (psgName != null) {
                            ((List<Map<String, String>>) userPermissionsMap.get(username).get('PermissionSetGroup')).add(new Map<String, String>{ 'Name' => psgName });
                        }
                    }
                }
            }
            
            for (Map<String, Object> user : usersList) {
                String username = (String) user.get('Username');
                if (userPermissionsMap.containsKey(username)) {
                    user.put('PermissionSet', userPermissionsMap.get(username).get('PermissionSet'));
                    user.put('PermissionSetGroup', userPermissionsMap.get(username).get('PermissionSetGroup'));
                } else {
                    user.put('PermissionSet', new List<Map<String, String>>());
                    user.put('PermissionSetGroup', new List<Map<String, String>>());
                }
            }
            
            saveJSONContent(orgId,refTempId,'User Data', usersList);
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
    }
    
    
    public static void saveJSONContent(Id orgId,Id refTempId,String name, List<Map<String, Object>> userList) {
        // Create a JSON string
        String jsonContent = JSON.serialize(new Map<String, List<Map<String, Object>>>{ 'User' => userList });
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = name + ' - Export - JSON';
        contentVersion.PathOnClient = '/' + contentVersion.Title + '.json';
        contentVersion.VersionData = Blob.valueOf(jsonContent);
        insert contentVersion;
        
        Org__c sid = [select id, Name from org__c where id =: orgId];
        Refresh_Template__c rt = [select Id, name from Refresh_Template__c WHERE Id =: refTempId];
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id
        ].ContentDocumentId;
        contentDocumentLink.LinkedEntityId = rt.Id;
        contentDocumentLink.ShareType = 'V';  // V stands for Viewer
        contentDocumentLink.Visibility = 'AllUsers'; // Optionally set visibility
        insert contentDocumentLink;
        System.debug('JSON export completed: ' + contentVersion.Title);
    }
}