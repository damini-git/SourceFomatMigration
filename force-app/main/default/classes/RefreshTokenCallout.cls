public with sharing class RefreshTokenCallout {
    
    /*@InvocableMethod(label='RefreshToken' description = 'Fetches Access Token through Refresh Token')
    public static void fetchAT(List<Org__c> orgList){
        Org__c org = [Select Id, Name, Refresh_Token__c, Domain_Url__c from Org__c Where Id =: orgList[0].Id Limit 1];
        Http http = New Http();
        HttpRequest req = New HttpRequest();
        ConnectedAppCredentials__c creds = ConnectedAppCredentials__c.getInstance();
        req.setEndpoint(org.Domain_URL__c+'/services/oauth2/token?grant_type=refresh_token&client_id='+creds.Key__c+'&client_secret='+creds.Secret__c+'&refresh_token='+org.Refresh_Token__c);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200){
            RefreshTokenWrapper wrp = (RefreshTokenWrapper) JSON.deserialize(res.getBody(), RefreshTokenWrapper.class);
            System.debug(wrp);
            input.accessToken =  wrp.access_token.subString(15);
        }
        else {
            input.failInfo = res.getStatus()+''+res.getBody();
        }
    }*/
    
    
    public static String fetchAT1(Id orgId){
        Org__c org = [Select Id, Name, Refresh_Token__c, Domain_Url__c, Is_Org_ReAuthenticated__c from Org__c Where Id =: orgId Limit 1];
        Http http = New Http();
        HttpRequest req = New HttpRequest();
        String endpoint;
        if(org.Is_Org_ReAuthenticated__c){ ConnectedAppCredentialsForSRA__c creds = ConnectedAppCredentialsForSRA__c.getInstance();
            endpoint = org.Domain_URL__c+'/services/oauth2/token?grant_type=refresh_token&client_id='+creds.Key__c+'&client_secret='+creds.Secret__c+'&refresh_token='+org.Refresh_Token__c;
        }
        else{
            ConnectedAppCredentials__c creds = ConnectedAppCredentials__c.getInstance();
            endpoint = org.Domain_URL__c+'/services/oauth2/token?grant_type=refresh_token&client_id='+creds.Key__c+'&client_secret='+creds.Secret__c+'&refresh_token='+org.Refresh_Token__c;
        }
        
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        HttpResponse res = http.send(req);
        System.debug('Response Body =>'+res.getBody());
        if(res.getStatusCode() == 200){
            RefreshTokenWrapper wrp = (RefreshTokenWrapper) JSON.deserialize(res.getBody(), RefreshTokenWrapper.class);
            System.debug(wrp);
            return  wrp.access_token.subString(15);
        }
        else {
            return res.getStatus()+''+res.getBody();
        }
    }
    
}