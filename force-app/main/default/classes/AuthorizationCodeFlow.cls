public with sharing class AuthorizationCodeFlow {
    @AuraEnabled
    public static String auth(Id orgId){
        system.debug('orgId==='+orgId);
        ConnectedAppCredentials__c creds = ConnectedAppCredentials__c.getInstance();
        System.debug(creds.Key__c);
        System.debug(creds.Secret__c);
        Org__c org = [Select Id, Name, Domain_Url__c, Org_Type__c from Org__c where Id =: orgId];
        Http http = New Http();
        HttpRequest req = New HttpRequest();
        req.setEndpoint(org.Domain_URL__c+'/services/oauth2/authorize?response_type=code&client_id='+creds.Key__c+'&redirect_uri='+creds.CallbackUrl__c);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setMethod('POST');
        HttpResponse res = New HttpResponse();
        res = http.send(req);
        System.debug(res.getHeader('Location'));
        String redirectUrl = res.getHeader('Location');
        //PageReference pageRef = new PageReference(redirectUrl);
        //String redirectUrl1 = pageRef.getUrl();
        //pageRef.setRedirect(true);
        System.debug(redirectUrl);
        OrgId__c idOrg = OrgId__c.getInstance();
        idOrg.Id__c = org.Id;
        upsert idOrg;
        //storeValueInCache(org.Id);
        return redirectUrl;
    }
}