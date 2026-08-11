public class AuthorizationCodeFlowForSRA {
    @AuraEnabled
    public static String auth(Id orgId, Id templateId){
        system.debug('AuthorizationCodeFlowForSRA is called ---- ');
        system.debug('orgId==='+orgId);
        ConnectedAppCredentialsForSRA__c creds = ConnectedAppCredentialsForSRA__c.getInstance();
        System.debug(creds.Key__c);
        System.debug(creds.Secret__c);
        system.debug('callback url --- ' + creds.CallbackUrl__c);
        Org__c org = [Select Id, Name, Domain_Url__c, Org_Type__c from Org__c where Id =: orgId];
        
        List<Logs__c> logsToUpdate = new List<Logs__c>();
        List<Logs__c> inProgAuthLogs = [select Id, Name, Status__c, Log_Type__c from Logs__c where Parent_Template__c =: templateId AND Log_Type__c = 'Re-Authenticate' AND Status__c = 'InProgress'];
        system.debug('inProgAuthLogs size --- ' + inProgAuthLogs.size());
        for(Logs__c log : inProgAuthLogs){
            log.Status__c = 'Failed';
            log.Details__c = 'Unknown Reason';
            logsToUpdate.add(log);
        }
        
        try{
            Http http = New Http();
            HttpRequest req = New HttpRequest();
            req.setEndpoint(org.Domain_URL__c+'/services/oauth2/authorize?response_type=code&client_id='+creds.Key__c+'&redirect_uri='+creds.CallbackUrl__c);
            req.setHeader('Content-Type','application/x-www-form-urlencoded');
            req.setMethod('POST');
            req.setTimeout(120000);
            HttpResponse res = New HttpResponse();
            
            res = http.send(req);
            System.debug(res.getHeader('Location'));
            String redirectUrl = res.getHeader('Location');
            System.debug(redirectUrl);
            
            OrgId__c idOrg = OrgId__c.getInstance();
            idOrg.Id__c = org.Id;
            upsert idOrg;
            
            Logs__c reauthenticateLog = new Logs__c();
            reauthenticateLog.Log_type__c = 'Re-Authenticate';
            reauthenticateLog.Status__c = 'InProgress';
            reauthenticateLog.Parent_Template__c = templateId;
            insert reauthenticateLog;
            
            if(logsToUpdate.size() > 0){ update logsToUpdate;
            }
            
            LogId__c logId = LogId__c.getInstance();
            logId.Id__c = reauthenticateLog.Id;
            upsert logId;
            
            return redirectUrl;
        }
        catch(Exception e){
            Logs__c reauthenticateLog = new Logs__c();
            reauthenticateLog.Log_type__c = 'Re-Authenticate';
            reauthenticateLog.Status__c = 'Failed';
            reauthenticateLog.Details__c = e.getMessage();
            reauthenticateLog.Parent_Template__c = templateId;
            insert reauthenticateLog;
            
            System.debug('Exception occurred while processing custom setting fields: ' + e.getMessage());
            return null;
        }
    }
}