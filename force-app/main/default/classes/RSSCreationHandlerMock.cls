@isTest
public class RSSCreationHandlerMock implements HttpCalloutMock {
	public static HttpResponse respond(HttpRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/x-www-form-urlencoded');
        res.setStatusCode(200);
        if(req.getEndpoint().contains('select+id,SiteName,EndpointUrl+from+RemoteProxy')){
        res.setBody('{"size": 1,"totalSize": 1,"done": true,"queryLocator": null,"entityTypeName": "RemoteProxy","records": [{"attributes": {"type":"RemoteProxy","url": "/services/data/v56.0/tooling/sobjects/RemoteProxy/0rp6g000000gU2jAAE"},"Id": "0rp6g000000gU2jAAE",    "SiteName": "CopadoBackend","EndpointUrl": "https://login.salesforce.com"}]}');
        }
            return res;
    }
}