public with sharing class CallbackController {
    public static String orgId;
    public static String code { get; set; }
    public static Boolean val { get; set; }
    
    public static void captureCode() {
        val = false;
        code = ApexPages.currentPage().getParameters().get('code');
        getAccessToken();
        val = true;
    }
    
    public static void getAccessToken(){
        OrgId__c org = OrgId__c.getInstance();
        String orgId = org.Id__c;
        System.debug(orgId);
        ConnectedAppCredentials__c creds = ConnectedAppCredentials__c.getInstance();
        Org__c orgMain = [Select Id, Domain_Url__c from Org__c where Id =: orgId];
        Http http = New Http();
        HttpRequest req = New HttpRequest();
        req.setEndpoint(orgMain.Domain_URL__c+'/services/oauth2/token?grant_type=authorization_code&code='+code+'&client_id='+creds.Key__c+'&client_secret='+creds.Secret__c+'&redirect_uri='+creds.CallbackUrl__c);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setMethod('POST');
        HttpResponse res = New HttpResponse();
       /* if(Test.isRunningTest()){
            res = CallbackControllerMock.respond(req);
        }
        else{*/
            res = http.send(req);
        //}
        if(res.getStatusCode() == 200){
            AuthCodeWrapper authWrap = (AuthCodeWrapper) Json.deserialize(res.getBody(), AuthCodeWrapper.class);
            /*Map<String,String>authData = New Map<String,String>();
			authData.put('AccessToken',authWrap.access_token.subString(15));
			authData.put('RefreshToken',authWrap.refresh_token);
			System.debug(authData);*/
            //OrgAuthCredentials.orgAuth(authWrap.access_token.subString(15), authWrap.refresh_token);
            System.debug('Bodyyyy===='+res.getBody());
            String url = authWrap.instance_url;
            System.debug(url);
            orgMain.Refresh_Token__c = authWrap.refresh_token;
            orgMain.Access_Token__c = authWrap.access_token.subString(15);
            orgMain.Domain_URL__c = url;
            orgMain.Authentication_Failure_Reason__c = null;
            orgMain.Org_Id__c = authWrap.access_token.substring(0, 15);
            orgMain.Is_Org_ReAuthenticated__c = false;
            update orgMain;
            
            SandboxRefreshClass.fetchSandboxInfo(orgId);
        }
        else {
            System.debug(res.getStatusCode());
        }
    }
}