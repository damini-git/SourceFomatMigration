public with sharing class DataPickerClass {
    
    @AuraEnabled(cacheable=true)
    public static List<CustomSettingsWrapper> fetchCustomSettings(Id sandboxId) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id =: sandboxId];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        
        try {
            HttpRequest req = new HttpRequest();
            HttpResponse res;
            String endPointUrl = domainUrl + '/services/data/v56.0/query/?q=SELECT+Id,Label,MasterLabel,DeveloperName,QualifiedApiName+FROM+EntityDefinition+WHERE+isCustomSetting=true';
            
            req.setEndpoint(endPointUrl);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken); // Add authorization header
            req.setTimeout(120000);
            
            Http http = new Http();
            res = http.send(req);
            
            List<CustomSettingsWrapper> customSettingsWrapper = new List<CustomSettingsWrapper>();
            String name;
            
            List<Map<String, String>> customSettingsMap = new List<Map<String, String>>();
            List<String> customSettings = new List<String>();
            String body;
            
            if(!Test.isRunningTest()){ if (res.getStatusCode() == 200) { body = res.getBody(); }}
            else{ body = '{"size": 1,"totalSize": 1,"done": true,"queryLocator": null,"entityTypeName": "EntityDefinition","records": [{"attributes": {"type": "EntityDefinition","url": "/services/data/v57.0/tooling/sobjects/EntityDefinition/01INS000000gURV"},"Id": "000000000000000AAA","Label": "Custom 1","MasterLabel": "Custom 1","DeveloperName": "CustomSetting1__c","QualifiedApiName": "CustomSetting1__c"}]}'; }
            
            if (!String.isEmpty(body)) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(body);
                system.debug('result --- ' + result);
                List<Object> records = (List<Object>) result.get('records');
                system.debug('records --- ' + records);
                
                for (Object record : records) {
                    Map<String, Object> settingRecord = (Map<String, Object>) record;
                    system.debug('settingRecord --- ' + settingRecord);
                    name = (String) settingRecord.get('QualifiedApiName');
                    customSettingsWrapper.add(new CustomSettingsWrapper(name));
                }
            } else {
                System.debug('Error: ' + res.getStatus() + ' - ' + res.getBody());
            }
            
            return customSettingsWrapper;
            
        } catch (Exception e) {
            System.debug('Exception occurred while fetching custom settings: ' + e.getMessage());
            return null;
        }
    }
    
    public class CustomSettingsWrapper {
        @AuraEnabled public String name { get; set; }
        
        public CustomSettingsWrapper(String name) {
            this.name = name;
        }
    }
    
    /*@AuraEnabled(cacheable=true)
    public static List<ScheduleJobsWrapper> fetchScheduledJobs(Id sandboxId){
        Org__c sand = [SELECT Id, Name, Access_Token__c, Domain_Url__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String accessToken = '';
        if(!test.isRunningTest()){ accessToken = RefreshTokenCallout.fetchAT1(sand.Id);
                                 }
        else{
            accessToken = '12345';
        }
        String domainUrl = sand.Domain_Url__c;
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sand.Domain_Url__c + '/services/data/v59.0/query/?q=SELECT+Id,CronJobDetailId,CronJobDetail.Name,CronJobDetail.JobType,State,NextFireTime,StartTime,EndTime,TimeZoneSidKey,OwnerId,CronExpression,TimesTriggered,PreviousFireTime+FROM+CronTrigger');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        
        HttpResponse res = http.send(req);
        system.debug('res status code --- ' + res.getStatusCode());
        
        List<String> lOfJobNames = new List<String>();
        List<Map<String, String>> mapOfJobNames = new List<Map<String, String>>();
        
        List<ScheduleJobsWrapper> jobsWrapList = new List<ScheduleJobsWrapper>();
        String jobId;
        String cronJobDetailId;
        String jobName;
        String jobType;
        String state;
        String nextFireTime;
        String startTime;
        String endTime;
        String timeZoneSidKey;
        String cronExpression;
        Integer timesTriggered;
        String previousFireTime;
        
        if(res.getStatusCode() == 200){
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) response.get('records');
            List<Object> cronJobDetailObj = new List<Object>();
            
            for (Object job : records) {
                Map<String, Object> jobs = (Map<String, Object>) job;
                jobId = (String) jobs.get('Id');
                cronJobDetailId = (String) jobs.get('CronJobDetailId');
                
                Map<String, Object> cronDetailMap = (Map<String, Object>) jobs.get('CronJobDetail');
                jobName = (String) cronDetailMap.get('Name');
                jobType = (String) cronDetailMap.get('JobType');
                
                state = (String) jobs.get('State');
                nextFireTime = (String) jobs.get('NextFireTime');
                startTime = (String) jobs.get('StartTime');
                endTime = (String) jobs.get('EndTime');
                timeZoneSidKey = (String) jobs.get('TimeZoneSidKey');
                cronExpression = (String) jobs.get('CronExpression');
                system.debug('cronExpression --- ' + cronExpression);
                timesTriggered = (Integer) jobs.get('TimesTriggered');
                previousFireTime = (String) jobs.get('PreviousFireTime');
                
                jobsWrapList.add(new ScheduleJobsWrapper(jobId, cronJobDetailId, jobName, jobType, state, nextFireTime, startTime, endTime, timeZoneSidKey, cronExpression, timesTriggered, previousFireTime));
            }
        }
        
        return jobsWrapList;
    }
    
    public class ScheduleJobsWrapper {
        @AuraEnabled public String jobId { get; set; }
        @AuraEnabled public String cronJobDetailId { get; set; }
        @AuraEnabled public String jobName { get; set; }
        @AuraEnabled public String jobType { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String nextFireTime { get; set; }
        @AuraEnabled public String startTime { get; set; }
        @AuraEnabled public String endTime { get; set; }
        @AuraEnabled public String timeZoneSidKey { get; set; }
        @AuraEnabled public String cronExpression { get; set; }
        @AuraEnabled public Integer timesTriggered { get; set; }
        @AuraEnabled public String previousFireTime { get; set; }
        
        public ScheduleJobsWrapper(String jobId, String cronJobDetailId, String jobName, String jobType, String state, String nextFireTime, String startTime, String endTime, String timeZoneSidKey, String cronExpression, Integer timesTriggered, String previousFireTime) {
            this.jobId = jobId;
            this.cronJobDetailId = cronJobDetailId;
            this.jobName = jobName;
            this.jobType = jobType;
            this.state = state;
            this.nextFireTime = nextFireTime;
            this.startTime = startTime;
            this.endTime = endTime;
            this.timeZoneSidKey = timeZoneSidKey;
            this.cronExpression = cronExpression;
            this.timesTriggered = timesTriggered;
            this.previousFireTime = previousFireTime;
        }
    }*/
    
    /*@AuraEnabled
    public static void fetchAllUsers(Id sandboxId) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id =: sandboxId];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = Test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        
        try {
            String queryEndpoint = '/services/data/v56.0/query/?q=SELECT+Id,Name,Email,Username,Profile.Name+FROM+User+WHERE+Profile.UserLicense.Name!=null+AND+isActive=TRUE';
            System.debug('Query endpoint: ' + queryEndpoint);
            
            System.enqueueJob(new FetchUsersQueueable(domainUrl, accessToken, queryEndpoint, sandboxId));
            System.debug('FetchUsersQueueable job enqueued successfully.');
        } catch (Exception e) {
            System.debug('Exception occurred while enqueuing fetch users job: ' + e.getMessage());
        }
    }
    
    public class FetchUsersQueueable implements Queueable, Database.AllowsCallouts {
        private String domainUrl;
        private String accessToken;
        private String queryEndpoint;
        private Id sandboxId;
        
        public FetchUsersQueueable(String domainUrl, String accessToken, String queryEndpoint, Id sandboxId) {
            this.domainUrl = domainUrl;
            this.accessToken = accessToken;
            this.queryEndpoint = queryEndpoint;
            this.sandboxId = sandboxId;
        }
        
        public void execute(QueueableContext context) {
            try {
                System.debug('FetchUsersQueueable execute started for sandbox ID: ' + sandboxId);
                System.debug('Next records URL: ' + queryEndpoint);
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint(domainUrl + queryEndpoint);
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
                        System.debug('Number of records fetched: ' + records.size());
                        
                        List<UserWrapper> userBatch = new List<UserWrapper>();
                        for (Object obj : records) {
                            Map<String, Object> user = (Map<String, Object>) obj;
                            String name = (String) user.get('Name');
                            String email = (String) user.get('Email');
                            String username = (String) user.get('Username');
                            Map<String, Object> profile = (Map<String, Object>) user.get('Profile');
                            String profileName = profile != null ? (String) profile.get('Name') : '';
                            userBatch.add(new UserWrapper(name, email, username, profileName));
                        }
                        
                        String newNextRecordsUrl = (String) result.get('nextRecordsUrl');
                        if (!String.isEmpty(newNextRecordsUrl)) {
                            System.debug('Next records URL found. Enqueuing another FetchUsersQueueable job.');
                            System.enqueueJob(new FetchUsersQueueable(domainUrl, accessToken, newNextRecordsUrl, sandboxId));
                        } else {
                            system.debug('all users are fetched...');
                        }
                    } else {
                        System.debug('Empty response body received.');
                    }
                } else {
                    System.debug('HTTP response error. Status Code: ' + res.getStatusCode() + ', Status: ' + res.getStatus());
                }
            } catch (Exception e) {
                System.debug('Exception occurred during FetchUsersQueueable execution: ' + e.getMessage());
            }
        }
    }

    public class UserWrapper {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String username { get; set; }
        @AuraEnabled public String profileName { get; set; }
        
        public UserWrapper(String name, String email, String username, String profileName) {
            this.name = name;
            this.email = email;
            this.username = username;
            this.profileName = profileName;
        }
    }*/
    
    /*@AuraEnabled(cacheable=true)
    public static List<CustomSettingsWrapper> fetchCustomSettings(Id sandboxId) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id =: sandboxId];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = '';
        
        if (!Test.isRunningTest()) {
            accessToken = RefreshTokenCallout.fetchAT1(sand.Id);
        } else {
            accessToken = '12345';
        }
        
        try {
            List<CustomSettingsWrapper> customSettingsWrapper = new List<CustomSettingsWrapper>();
            String queryUrl = domainUrl + '/services/data/v56.0/query/?q=SELECT+Id,Label,MasterLabel,DeveloperName,QualifiedApiName+FROM+EntityDefinition+WHERE+isCustomSetting=true';
            Boolean isDone = false;
            
            while (!isDone) {
                HttpRequest req = new HttpRequest();
                HttpResponse res;
                
                if (Test.isRunningTest()) {
                    res = new HttpResponse();
                    res.setStatusCode(200);
                    res.setBody('{"size": 2000, "totalSize": 3000, "done": false, "nextRecordsUrl": "/services/data/v56.0/query/01gABC123", "records": [{"QualifiedApiName": "CustomSetting1__c"}, {"QualifiedApiName": "CustomSetting2__c"}]}');
                } else {
                    req.setEndpoint(queryUrl);
                    req.setMethod('GET');
                    req.setHeader('Authorization', 'Bearer ' + accessToken); // Add authorization header
                    req.setTimeout(120000);
                    
                    Http http = new Http();
                    res = http.send(req);
                }
                
                if (res.getStatusCode() == 200) {
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    List<Object> records = (List<Object>) result.get('records');
                    
                    for (Object record : records) {
                        Map<String, Object> settingRecord = (Map<String, Object>) record;
                        String name = (String) settingRecord.get('QualifiedApiName');
                        customSettingsWrapper.add(new CustomSettingsWrapper(name));
                    }
                    
                    if (result.containsKey('nextRecordsUrl')) {
                        queryUrl = domainUrl + (String) result.get('nextRecordsUrl');
                    } else {
                        isDone = true;
                    }
                } else {
                    throw new CalloutException('Error fetching custom settings: ' + res.getBody());
                }
            }
            
            return customSettingsWrapper;
        } catch (Exception e) {
            System.debug('Exception occurred while fetching custom settings: ' + e.getMessage());
            return null;
        }
    }
    
    public class CustomSettingsWrapper {
        @AuraEnabled public String name { get; set; }
        
        public CustomSettingsWrapper(String name) {
            this.name = name;
        }
    }*/
    
    @AuraEnabled
    public static PaginatedUserResponse fetchAllUsers(Id sandboxId, String queryEndpoint, String searchString, String sortBy) {
        Org__c sand = [SELECT Id, Domain_Url__c, Access_Token__c FROM Org__c WHERE Id =: sandboxId];
        String domainUrl = sand.Domain_Url__c;
        String accessToken = Test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        String endpoint;
        if (queryEndpoint != null && !String.isEmpty(queryEndpoint)) {
            system.debug('inside if ------ ');
            endpoint = queryEndpoint;
        } else {
            //String query = 'SELECT+Id,Name,Email,Username,Profile.Name+FROM+User+WHERE+Profile.UserLicense.Name!=null+AND+isActive=TRUE';//+ORDER+BY+Name+ASC
            String query = 'SELECT Id, Name, Email, Username, Profile.Name FROM User WHERE Profile.UserLicense.Name != null AND isActive = TRUE';
            if(!String.isBlank(searchString)){
                //query += '+AND+Name+LIKE+\'%' + SearchString + '%\'';
                query += ' AND Name LIKE \'%' + searchString + '%\'';
            }else if(!String.isBlank(sortBy) && sortBy != 'All'){
                //query += '+AND+Name+LIKE+\'' + sortBy + '%\'';
                query += ' AND Name LIKE \'' + sortBy + '%\'';
                System.debug('QUERY ::/'+query);
            }
            
            system.debug('inside else ------- ');
            
            String encodedQuery = EncodingUtil.urlEncode(query + ' ORDER BY Name ASC', 'UTF-8');
            endpoint = '/services/data/v56.0/query/?q=' + encodedQuery;
            //endpoint = '/services/data/v56.0/query/?q='+query+'+ORDER+BY+Name+ASC';
            //endpoint = '/services/data/v56.0/query/?q=SELECT+Id,Name,Email,Username,Profile.Name+FROM+User+WHERE+Profile.UserLicense.Name!=null+AND+isActive=TRUE+ORDER+BY+Name+ASC';
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
                    system.debug('result --- ' + result);
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
                        user.name = (String) record.get('Name');
                        user.email = (String) record.get('Email');
                        user.username = (String) record.get('Username');
                        user.profile = (String) ((Map<String, Object>) record.get('Profile')).get('Name');
                        responseWrapper.users.add(user);
                    }
                    responseWrapper.nextRecordsUrl = nextRecordsUrl;
                    responseWrapper.totalRecords = totalRecords;
                    System.debug('PaginatedUserResponse: ' + JSON.serialize(responseWrapper));
                    
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
    
    @AuraEnabled(cacheable=true)
    public static List<ScheduleJobsWrapper1> fetchScheduledJobs1(Id sandboxId){
        Org__c sand = [SELECT Id, Name, Access_Token__c, Domain_Url__c FROM Org__c WHERE Id = :sandboxId LIMIT 1];
        String accessToken = test.isRunningTest() ? '12345' : RefreshTokenCallout.fetchAT1(sand.Id);
        String domainUrl = sand.Domain_Url__c;
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sand.Domain_Url__c + '/services/data/v59.0/query/?q=SELECT+Id,ApexClass.Name,JobType,CronTrigger.CronExpression,CronTrigger.CronJobDetail.Name+FROM+AsyncApexJob+WHERE+JobType=\'ScheduledApex\'');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setTimeout(120000);
        
        HttpResponse res = http.send(req);
        system.debug('res status code --- ' + res.getStatusCode());
        
        List<ScheduleJobsWrapper1> jobsWrapList = new List<ScheduleJobsWrapper1>();
        String jobId;
        String jobName;
        String jobType;
        String cronExpression;
        String apexClassName;
        
        if(res.getStatusCode() == 200){
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) response.get('records');
            
            for (Object job : records) {
                Map<String, Object> jobs = (Map<String, Object>) job;
                jobId = (String) jobs.get('Id');
                jobType = (String) jobs.get('JobType');
                
                Map<String, Object> cronTrigger = (Map<String, Object>) jobs.get('CronTrigger');
                system.debug('cronTrigger --- ' + cronTrigger);
                if(cronTrigger != null){
                    Map<String, Object> apexClassMap = (Map<String, Object>) jobs.get('ApexClass');
                    apexClassName = (String) apexClassMap.get('Name');
                    system.debug('apexClassName --- ' + apexClassName);
                    
                    Map<String, Object> cronJobDetail = (Map<String, Object>) cronTrigger.get('CronJobDetail');
                    jobName = (String) cronJobDetail.get('Name');
                    system.debug('jobName --- ' + jobName);
                    cronExpression = (String) cronTrigger.get('CronExpression');
                    system.debug('cronExpression --- ' + cronExpression);
                    jobsWrapList.add(new ScheduleJobsWrapper1(jobId, jobName, jobType, cronExpression, apexClassName));
                }
            }
        }
        
        system.debug('jobsWrapList --- ' + jobsWrapList);
        return jobsWrapList;
    }
    
    public class ScheduleJobsWrapper1 {
        @AuraEnabled public String jobId { get; set; }
        @AuraEnabled public String jobName { get; set; }
        @AuraEnabled public String jobType { get; set; }
        @AuraEnabled public String cronExpression { get; set; }
        @AuraEnabled public String apexClassName { get; set; }
        
        public ScheduleJobsWrapper1(String jobId, String jobName, String jobType, String cronExpression, String apexClassName) {
            this.jobId = jobId;
            this.jobName = jobName;
            this.jobType = jobType;
            this.cronExpression = cronExpression;
            this.apexClassName = apexClassName;
        }
    }
}