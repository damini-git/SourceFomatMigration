@isTest
public class PostRefreshAutomationClassMock implements HttpCalloutMock {
    
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        // Determine the endpoint to simulate appropriate response
        if (req.getEndpoint().contains('/services/oauth2/token')) {
            // Mock the response for the access token endpoint
            String tokenResponse = '{"access_token": "00Dxx0000000gxxx!AR8AQxxxxxxxxxxxxxxx", "refresh_token": "5Aep861Axxxxxxxxxxx", "instance_url": "https://test.salesforce.com"}';
            res.setBody(tokenResponse);
            res.setStatusCode(200);
        } else if (req.getEndpoint().contains('/services/oauth2/userinfo')) {
            // Mock the response for the user info endpoint
            String userInfoResponse = '{"preferred_username": "testuser@example.com"}';
            res.setBody(userInfoResponse);
            res.setStatusCode(200);
        } else if (req.getEndpoint().contains('/services/Soap/m/59.0')) {
            // Mock the response for the Metadata API deploy call
            String metadataResponse = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Body><deployResponse xmlns="http://soap.sforce.com/2006/04/metadata"><result><id>12345</id><done>true</done><state>Succeeded</state></result></deployResponse></soapenv:Body></soapenv:Envelope>';
            res.setBody(metadataResponse);
            res.setStatusCode(200);
        }
        
        return res;
    }
}