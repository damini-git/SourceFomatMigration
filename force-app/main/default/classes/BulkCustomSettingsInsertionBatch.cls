public class BulkCustomSettingsInsertionBatch implements database.batchable<ContentDocumentLink>,Database.Stateful,Database.AllowsCallouts{
    public id recordId;
    public string instanceUrl;
    public string accessToken;
    public string jobId;
    public string orgName;
    public List<map<string,string>> jobIds = new List<map<string,string>>();
    public map<string,string> objIdMap = new map<string,string>();
    public Logs__c log;
    Public List<String> csNamesList;
    public BulkCustomSettingsInsertionBatch(Id recordId,logs__c log){
        Refresh_Template__c refTemp = [select Id, Parent_Org__c,Parent_Org__r.name,Parent_Org__r.Domain_Url__c,Custom_Setting_Names__c from Refresh_Template__c where Id =: recordId];
        String instanceUrl = refTemp.Parent_Org__r.Domain_Url__c;
        String accessToken = RefreshTokenCallout.fetchAT1(refTemp.Parent_Org__c);
        string orgName = refTemp.Parent_Org__r.name;
        string csNames = refTemp.Custom_Setting_Names__c.deleteWhiteSpace();
        csNames = csNames.replaceAll('\\s+', ''); // Remove all whitespace
        csNames = csNames.replaceAll('__c\\([^\\)]*\\)', '__c');
        system.debug('orgname in constructor-------->>>>>>'+orgName);
        csNamesList = csNames.split(',');
        
        this.instanceUrl = instanceUrl;
        this.accessToken = accessToken;
        this.recordId = recordId;
        this.log = log;
        this.orgName=orgName;
    }
    public List<ContentDocumentLink> start(Database.BatchableContext bc) {
        system.debug('Custom Settings Names List'+csNamesList);
        string str ='';
        for(string cs : csNamesList){
            str= str+'OR ContentDocument.Title LIKE \''+cs+'%\'';
            
        }
        str = '('+str.removeStart('OR')+')';
        string query = 'SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = \''+recordId+'\' AND '+str;
        system.debug('query-------->>>>>>'+query);
        
        List<ContentDocumentLink> attachments = database.query(query);
        system.debug('attachments Inside Start------>>>>>>'+attachments);
        system.debug('attachments Size Inside Start---------->>>>>'+attachments.size());
        if(attachments.size() == 0){
            log.Status__c = 'Failed';
            insert log;
        }else{
            insert log;
        }
        return attachments;
    }
    public void execute(Database.BatchableContext bc, List<ContentDocumentLink> attachments){
        this.log = log;
        Logs__c log = [select Id, Name,status__c,details__c from Logs__c where id =: log.id];
        if(log.Status__c != 'Failed'){
            try{
                system.debug('Inside execute');
                Map<String,String> dupMap = New Map<String,String>();
                system.debug('attachments inside Execute----->>>>'+attachments[0]);
                dupMap = BulkCustomSettingsInsertion.insertCustomSettingsUsingBulkAPI(attachments[0], instanceUrl, accesstoken,log.Id);
                system.debug('dupMap ------>>>'+dupMap);
                if(dupmap != null && !dupMap.isEmpty()){
                String str = new List<String>(dupMap.keySet())[0];
                objIdMap.put(new List<String>(dupMap.keySet())[0],dupMap.get(new List<String>(dupMap.keySet())[0]));
                jobIds.add(objIdMap);
                system.debug('status Of lOg in execute ------>>>'+log.status__c);
                system.debug('Final List Of JobIds------>'+jobIds);
                }
            }catch(exception e){
                system.debug(e.getMessage());
                log.Status__c = 'Failed';
                log.Details__c = 'Custom Setting Restoration has been Failed due to '+e.getMessage();
                update log;
            }
        }
    }
    public void finish(Database.BatchableContext bc){
        system.debug('orgname in finish-------->>>>>>'+orgName);
        this.log = log;
         system.debug('status Of lOg in Finish ------>>>'+log.status__c);
        Logs__c log = [select Id, Name,status__c,details__c from Logs__c where id =: log.id];
        system.debug('status Of lOg in Finish after Query ------>>>'+log.status__c);
        if(log.Status__c !='Failed'){
            DateTime oneMinuteLater = System.now().addMinutes(1);
            string jobName = 'Custom Settings Error Log '+system.now().format();    
            String cronExpression = '0 ' + oneMinuteLater.minute() + ' ' + oneMinuteLater.hour() + ' ' + oneMinuteLater.day() + ' ' + oneMinuteLater.month() + ' ? ' + oneMinuteLater.year();
            CustomSettingsInsertionLogScheduler scheduledJob = new CustomSettingsInsertionLogScheduler(jobName,objIdMap, instanceUrl, accesstoken,log.Id);
            String scheduleJobId = system.schedule(jobName, cronExpression, scheduledJob);
        }
    }
}