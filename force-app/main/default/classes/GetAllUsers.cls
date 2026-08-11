public class GetAllUsers {
    public static Logs__c log;
    @AuraEnabled
    public static PaginatedUserResponse fetchAllUsers(Id refTempId, String queryEndpoint, String searchString, String sortBy,string isActive) {
        Refresh_Template__c reftemp = [SELECT Id, Name, Parent_Org__c,Parent_Org__r.Domain_Url__c,Parent_Org__r.Access_Token__c FROM Refresh_Template__c WHERE Id =:refTempId];
        
        String domainUrl = reftemp.Parent_Org__r.Domain_Url__c;
        String accessToken = Test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(reftemp.Parent_Org__c);
        String endpoint;
        if (queryEndpoint != null && !String.isEmpty(queryEndpoint)) {
            system.debug('inside if ------ ');
            endpoint = queryEndpoint;
            system.debug('endpoint');
        } else if(queryEndpoint == null && isActive == 'Active Users') {
            String query = 'SELECT Id, Name, Email, Username,isActive, Profile.Name FROM User WHERE Profile.UserLicense.Name != null AND isActive = TRUE';
            if(!String.isBlank(searchString)){
                query += ' AND Name LIKE \'%' + searchString + '%\'';
            }else if(!String.isBlank(sortBy) && sortBy != 'All'){
                query += ' AND Name LIKE \'' + sortBy + '%\'';
                System.debug('QUERY ::/'+query);
            }
            
            system.debug('inside else ------- ');
            
            String encodedQuery = EncodingUtil.urlEncode(query + ' ORDER BY Name ASC', 'UTF-8');
            endpoint = '/services/data/v56.0/query/?q=' + encodedQuery;
        }else if(queryEndpoint == null && isActive == 'InActive Users') {
            String query = 'SELECT Id, Name, Email, Username,isActive, Profile.Name FROM User WHERE Profile.UserLicense.Name != null AND isActive = false';
            if(!String.isBlank(searchString)){
                query += ' AND Name LIKE \'%' + searchString + '%\'';
            }else if(!String.isBlank(sortBy) && sortBy != 'All'){
                query += ' AND Name LIKE \'' + sortBy + '%\'';
                System.debug('QUERY ::/'+query);
            }
            
            system.debug('inside else ------- ');
            
            String encodedQuery = EncodingUtil.urlEncode(query + ' ORDER BY Name ASC', 'UTF-8');
            endpoint = '/services/data/v56.0/query/?q=' + encodedQuery;
        }else if(queryEndpoint == null && isActive == 'All Users') {
            String query = 'SELECT Id, Name, Email, Username,isActive,Profile.Name FROM User WHERE Profile.UserLicense.Name != null';
            if(!String.isBlank(searchString)){
                query += ' AND Name LIKE \'%' + searchString + '%\'';
            }else if(!String.isBlank(sortBy) && sortBy != 'All'){
                query += ' AND Name LIKE \'' + sortBy + '%\'';
                System.debug('QUERY ::/'+query);
            }
            
            system.debug('inside else ------- ');
            
            String encodedQuery = EncodingUtil.urlEncode(query + ' ORDER BY Name ASC', 'UTF-8');
            endpoint = '/services/data/v56.0/query/?q=' + encodedQuery;
        }
        
        try {
            System.debug('Next records URL: ' + endpoint);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(domainUrl + endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeout(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('HTTP response status: ' + res.getStatusCode());
            
            if (res.getStatusCode() == 200) {
                String body = res.getBody();
                
                if (!String.isEmpty(body)) {
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(body);
                    List<Object> records = (List<Object>) result.get('records');
                    Integer totalRecords = (Integer) result.get('totalSize');
                    System.debug('Number of records fetched: ' + records.size());
                    System.debug('Total records available: ' + totalRecords);
                    
                    String nextRecordsUrl = (String) result.get('nextRecordsUrl');
                    
                    PaginatedUserResponse responseWrapper = new PaginatedUserResponse();
                    responseWrapper.users = new List<PaginatedUserResponse.UserWrapper>();
                    for (Object recordObj : records) {
                        Map<String, Object> record = (Map<String, Object>) recordObj;
                        PaginatedUserResponse.UserWrapper user = new PaginatedUserResponse.UserWrapper();
                        user.id = (String) record.get('Id');
                        user.name = (String) record.get('Name');
                        user.email = (String) record.get('Email');
                        user.username = (String) record.get('Username');
                        user.profile = (String) ((Map<String, Object>) record.get('Profile')).get('Name');
                        user.isActive = (Boolean) record.get('IsActive');
                        responseWrapper.users.add(user);
                    }
                    responseWrapper.nextRecordsUrl = nextRecordsUrl;
                    responseWrapper.totalRecords = totalRecords;
                    System.debug('PaginatedUserResponse: ' + JSON.serialize(responseWrapper));
                    
                    system.debug('responseWrapper---->>>'+responseWrapper);
                    return responseWrapper;
                    
                } else {
                    System.debug('Empty response body received.');
                    return new PaginatedUserResponse();
                }
            } else {
                System.debug('HTTP response error. Status Code: ' + res.getStatusCode() + ', Status: ' + res.getStatus());
                return new PaginatedUserResponse();
            }
        } catch (Exception e) {
            System.debug('Exception occurred during fetching users execution: ' + e.getMessage());
            throw e;
        }
    }
    @AuraEnabled
    public static void executeData(Id refTempId,List<Id>userIds,List<Map<String, string>>emailList,string logType){
        Refresh_Template__c refTemp = [SELECT Id, Name, Parent_Org__c, Parent_Org__r.access_token__c, Parent_Org__r.Domain_Url__c FROM Refresh_Template__c WHERE id = :refTempId LIMIT 1];
        string instanceUrl = refTemp.Parent_Org__r.Domain_Url__c;
        String accessToken;
        if (!test.isRunningTest()) {
            accessToken = RefreshTokenCallout.fetchAT1(refTemp.Parent_Org__c);
        } else {
            accessToken = '1234567890';
        }
        
        Logs__c log = new Logs__c();
        log.Status__c ='InProgress';
        log.Log_Type__c = logType;
        log.Parent_Template__c = refTempId;
        insert log;
        
        if(logType == 'Reset User Password - Post Refresh'){            
            database.ExecuteBatch(new ResetUserPassword(refTempId,userIds,logType,log.Id,instanceUrl,accessToken),1);
        }else if(logType == 'User Email Validation - Post Refresh'){
            database.ExecuteBatch(new EmailValidation(refTempId,emailList,logType,log.Id));
        }else if(logType == 'User Deactivation - Post Refresh'){
            database.ExecuteBatch(new UserDeactivation(refTempId, userIds,logType,log.Id));
        }else if(logType == 'User Activation - Post Refresh'){
            database.ExecuteBatch(new UserActivation(refTempId, userIds,logType,log.Id));
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Logs__c> getUserTransfLogRecordofRefreshTemplate(Id templateId){
        List<Logs__c> logList = [select Id, Last_Deployment_Date__c, Parent_Template__c, Status__c, Name, LastModifiedBy.Name, Log_Type__c from Logs__c where Parent_Template__c =: templateId ORDER BY CreatedDate DESC];
        if (!logList.isEmpty()) {
            return logList; } 
        else { 
            system.debug('No log found for template: ' + templateId); 
            return null;  
        }
    }
    
}