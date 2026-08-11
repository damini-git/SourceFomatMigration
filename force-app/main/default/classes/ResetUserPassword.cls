public class ResetUserPassword implements database.batchable<id>, Database.Stateful, Database.AllowsCallouts {
    public List<Id> userIds;
    public Id refTempId;
    public string logType;
    public id log;
    public Map<Id, String> userIdToUsername = new Map<Id, String>();
    public string instanceUrl;
    public string accessToken;
    
    public  string csvData = 'User Name,Status\n'; 
    
    public ResetUserPassword(Id refTempId, List<Id> userIds,string logType,id log,string instanceUrl, string accessToken) {
        this.userIds = userIds;
        this.refTempId = refTempId;
        this.logType = logtype;
        this.log = log;
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        
        system.debug('userIds In Constructor--->>'+userIds);
    }
    
    public List<Id> start(Database.BatchableContext bc) {
        string userQuery = '/services/data/v59.0/query/?q=SELECT+Id,Name,Username,Email,ProfileId,UserRoleId,IsActive+FROM+User+Order+By+Name+ASC';
        this.userIdToUsername = getCurrentUsersFromTargetOrg(instanceUrl,accessToken,userQuery);
        system.debug('userIds In Start--->>'+userIds);
        return userIds;
    }
    
    public void execute(Database.BatchableContext bc, List<id> userIds) {
        
        system.debug('userIds In Execute--->>'+userIds);
        resetUserPassword(userIds[0],refTempId);
        system.debug('csvData ---->>>' + csvData);
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('CSV Data: ' + csvData);
         Logs__c passwordLog = [select Id, Name,Parent_Template__c,Parent_Template__r.Parent_Org__r.name from Logs__c where id =: log];
        if(!string.isBlank(csvData)){
            Blob csvBlob = Blob.valueOf(csvData);
            ContentVersion version = new ContentVersion();
            version.Title = 'Reset User Password Log'; 
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
            contentDocumentLink.LinkedEntityId = log;
            contentDocumentLink.ShareType = 'V'; 
            contentDocumentLink.Visibility = 'AllUsers'; 
            insert contentDocumentLink;
            
            passwordLog.Status__c = 'Completed';
            update passwordLog;
            
        }else{
            system.debug('csvData Parameter is Null');
            passwordLog.Status__c = 'Failed';
            passwordLog.Details__c = 'There is no csv Data to create template';
            update passwordLog;
        }
    }
    
    public void resetUserPassword(Id userId,Id refTempId) {
        this.csvData = csvdata;
        if (userId != null) {
            Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c FROM Refresh_Template__c WHERE id = :refTempId LIMIT 1];
            string instanceUrl = refTemp.Parent_Org__r.Domain_Url__c;
            String accessToken;
            if (!test.isRunningTest()) {
                accessToken = RefreshTokenCallout.fetchAT1(refTemp.Parent_Org__c);
            } else {
                accessToken = '1234567890';
            }
            
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(instanceUrl + '/services/data/v59.0/sobjects/User/' + userId + '/password');
                req.setMethod('DELETE');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setTimeOut(120000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    csvData += userIdToUsername.get(userId) + ',Successfuly sent an email with a link to reset the password\n'; 
                } else {
                    csvData += userIdToUsername.get(userId) + ',Failed to initiate reset password\n'; 
                }
                system.debug('csvData ---->>>' + csvData);
            } catch (Exception e) {
                csvData += userId + ',failed\n';
                System.debug('Error resetting password for user ' + userId + ': ' + e.getMessage());
            }
        } else {
            csvData += 'NoUserId,failed\n';
        }
    }
    
    public  Map<id, string> getCurrentUsersFromTargetOrg(string instanceUrl, string accessToken,string userQuery) {
        //system.debug('log.Status__c in getCurrentUsersFromTargetOrg--->>>'+log.Status__c);
        
        //Map<id, string> currentusers = new Map<id, string>();
        try{
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + userQuery);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setTimeOut(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (result.containsKey('records')) {
                    List<Object> records = (List<Object>) result.get('records');
                    
                    
                    for (Object recordObj : records) {
                        Map<String, Object> record = (Map<String, Object>) recordObj;
                        
                        String userId = (String) record.get('Id');
                        String username = (String) record.get('Username');
                        
                        if (userId != null && username != null) {
                            userIdToUsername.put((Id)userId, username);
                        }
                    }
                    
                    String newNextRecordsUrl = (String) result.get('nextRecordsUrl');
                    if (!String.isEmpty(newNextRecordsUrl)) {
                        getCurrentUsersFromTargetOrg(instanceUrl,accessToken,newNextRecordsUrl);
                    }
                } else {
                    //system.debug('No records found in response: ' + res.getBody());
                }
            } 
            //system.debug('Target Org users---->'+currentusers);
            //system.debug('Target Org users Size---->'+currentusers.size());
            //this.userIdToUsername.putAll(currentusers);
            system.debug('Target Org users Size ALL---->'+userIdToUsername.size());
            return userIdToUsername;
        }catch(exception e){
            //system.debug('Error fetching users from target org: ' + e.getMessage());
            
            throw new AuraHandledException('Error fetching users from target org: ' + e.getMessage());
        }
    }
}