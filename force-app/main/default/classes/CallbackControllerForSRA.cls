public class CallbackControllerForSRA {
    public static String orgId;
    public static String code { get; set; }
    public static Boolean val { get; set; }
    public static String statusCode { get; set; }
    
    
    public static void captureCode() {
        val = false;
        code = ApexPages.currentPage().getParameters().get('code');
        getAccessToken();
        val = true;
    }
    
    public static void getAccessToken(){
        system.debug('CallbackControllerForSRA is called ---- ');
        OrgId__c org = OrgId__c.getInstance();
        String orgId = org.Id__c;
        System.debug('OrgId__c custom setting Id__c in callback controller --- ' + orgId);
        
        LogId__c log = LogId__c.getInstance();
        String logId = log.Id__c;
        system.debug('reauthenticate log id --- ' + logId);
        
        ConnectedAppCredentialsForSRA__c creds = ConnectedAppCredentialsForSRA__c.getInstance();
        Org__c orgMain = [Select Id, Domain_Url__c from Org__c where Id =: orgId];
        
        Logs__c reauthenticateLog = [select Id, Name, Log_Type__c, Status__c, Details__c from Logs__c where Id =: logId];
        
        try{
            Http http = New Http();
            HttpRequest req = New HttpRequest();
            req.setEndpoint(orgMain.Domain_URL__c+'/services/oauth2/token?grant_type=authorization_code&code='+code+'&client_id='+creds.Key__c+'&client_secret='+creds.Secret__c+'&redirect_uri='+creds.CallbackUrl__c);
            req.setHeader('Content-Type','application/x-www-form-urlencoded');
            req.setMethod('POST');
            HttpResponse res = New HttpResponse();
            res = http.send(req);
            statusCode = String.valueOf(res.getStatusCode());
            system.debug('response :: '+res.getBody());
            System.debug('statusCode :: '+statusCode);
            Send_Data_To_LWC__e event = new Send_Data_To_LWC__e(
                Status_Code__c = res.getStatusCode()
            );
            // Publish the Platform Event
            EventBus.publish(event);
            if(res.getStatusCode() == 200){
                AuthCodeWrapper authWrap = (AuthCodeWrapper) Json.deserialize(res.getBody(), AuthCodeWrapper.class);
                System.debug('Bodyyyy===='+res.getBody());
                String url = authWrap.instance_url;
                System.debug(url);
                orgMain.Refresh_Token__c = authWrap.refresh_token;
                orgMain.Access_Token__c = authWrap.access_token.subString(15);
                orgMain.Domain_URL__c = url;
                orgMain.Authentication_Failure_Reason__c = null;
                orgMain.Org_Id__c = authWrap.access_token.substring(0, 15);
                orgMain.Is_Org_ReAuthenticated__c = true;
                update orgMain;
                
                reauthenticateLog.Status__c = 'Success';
                update reauthenticateLog;
                
                SandboxRefreshClass.fetchSandboxInfo(orgId);
            }
            else {
                reauthenticateLog.Status__c = 'Failed';
                reauthenticateLog.Details__c = res.getStatus();
                update reauthenticateLog;
                
                System.debug('status code --- '+ res.getStatusCode());
            }
        }
        catch(Exception e){
            System.debug('Error fetching metadata components: ' + e.getMessage());
            reauthenticateLog.Status__c = 'Failed';
            reauthenticateLog.Details__c = e.getMessage();
            update reauthenticateLog;
        }
    }
}