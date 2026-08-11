public class RSSCreationHandler implements TriggerHandlerBase.TriggerHandler {

    public static String s = '';
    //public static string siteName = '';

    public static void handle(){

        //Trigger_Control__c trigCon = Trigger_Control__c.getInstance();

        //System.debug(trigCon.Trigger_On_Off__c);

        //if(trigCon.Trigger_On_Off__c){

        List<Org__c> orgList = trigger.new;

        List<Org__c> orgListOld = trigger.old;

        Map<Id,Org__c> oldOrgMap = New Map<Id,Org__c>(orgListOld);

        for(Org__c org : orgList){

            if(oldOrgMap.get(org.Id).Domain_Url__c != org.Domain_URL__c){

                callout(org.Id);

            }

        }

    }

    

    @future(callout = true)

    public static void callout(String orgId){

        Org__c org1 = [Select Id, Name, Domain_Url__c from Org__c where Id =: orgId];

        Http http = New Http();

        HttpRequest req = New HttpRequest();

        req.setMethod('GET');

        req.setEndpoint(Url.getSalesforceBaseUrl().toExternalForm()+'/services/data/v56.0/tooling/query/?q=select+id,SiteName,EndpointUrl+from+RemoteProxy');

        req.setHeader('Authorization', 'Bearer '+UserInfo.getSessionId().subString(15));

        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = http.send(req);

        if(res.getStatusCode() == 200){

            System.JsonParser json = JSON.createParser(res.getBody());

            while(json.nextToken()!=null){
            
		    if(json.getText() == org1.Domain_URL__c){

                    s = 'Found';

                }

            }

        }

        if(s != 'Found'){

                    MetadataService.RemoteSiteSetting rss = new MetadataService.RemoteSiteSetting();

                    rss.fullName = String.valueOf(org1.Name).deleteWhitespace();

                    rss.description = 'Created for SF Release Package. Remove Cautiously';

                    rss.isActive = true;

                    rss.url = org1.Domain_URL__c;

                    rss.disableProtocolSecurity = false;

                    if(!test.isRunningTest()){

                    DynamicRSSCreation.upsertMetadata(rss);

                    }

                }

    }

}