@isTest
private class MaskingBatchPostRefreshTest {
    @isTest
    static void testMaskingBatchPostRefresh() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String objectType = 'Account';
        String domainUrl = 'https://test.salesforce.com';
        String accessToken = 'mockAccessToken';
        List<Map<String, Object>> recordsToUpdate = new List<Map<String, Object>>{
            new Map<String, Object>{'Id' => '001ABC123456789', 'Name' => 'Test Account 1'},
            new Map<String, Object>{'Id' => '001DEF123456789', 'Name' => 'Test Account 2'},
            new Map<String, Object>{'Id' => null, 'Name' => 'Test Account 3'}
        };

        MaskingBatchPostRefresh batch = new MaskingBatchPostRefresh(objectType, domainUrl, accessToken, recordsToUpdate);

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        Set<String> successfulIds = new Set<String>();

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint();
            String recordId = endpoint.substringAfterLast('/');

            if (recordId.startsWith('001')) {
                successfulIds.add(recordId);
                res.setStatusCode(204);
            } else {
                res.setStatusCode(400);
                res.setBody('{"error":"Invalid Id"}');
            }

            return res;
        }
    }
}