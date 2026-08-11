global class SandboxRefreshWebServiceMock implements WebServiceMock {
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseName,
        String responseNamespace,
        String responseNamespaceX
    ) {
        if (requestName == 'deploy') {
            MetadataService.deployResponse_element deployResponse = new MetadataService.deployResponse_element();
            MetadataService.AsyncResult asyncResult = new MetadataService.AsyncResult();
            asyncResult.Id = '1234567890';
            asyncResult.State = 'Queued';
            deployResponse.result = asyncResult;
            response.put(responseName, deployResponse);
        }
    }
}