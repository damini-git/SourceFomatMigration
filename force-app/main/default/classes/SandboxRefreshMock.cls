@isTest
global class SandboxRefreshMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"SandboxProcess","records":[{"attributes":{"type":"SandboxProcess","url":"/services/data/v59.0/tooling/sobjects/SandboxProcess/0GR6g00000095ASGAY"},"Id":"0GR6g00000095ASGAY","LicenseType":"DEVELOPER","SandboxName":"TestSandbox","SandboxInfoId":"0GQ6g000000kCP3GAM"}]}');
        return res;
    }
}