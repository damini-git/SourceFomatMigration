@isTest
global class PreRefreshMetadataMock implements WebServiceMock {
    
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType
    ) {
        if (requestName == 'listMetadata') {
            MetadataService.ListMetadataQuery[] queries = (MetadataService.ListMetadataQuery[])request;
            
            for (MetadataService.ListMetadataQuery query : queries) {
                if (query.type_x == 'CustomLabel') {
                    MetadataService.ListMetadataResponse_element listResponse = new MetadataService.ListMetadataResponse_element();
                    MetadataService.FileProperties fileProp = new MetadataService.FileProperties();
                    fileProp.fullName = 'TestLabel';
                    fileProp.type_x = 'CustomLabel'; // This is the metadata type we are simulating
                    listResponse.result = new List<MetadataService.FileProperties>{ fileProp };
                        response.put('response_x', listResponse); // Simulate the response for CustomLabel
                } else {
                    MetadataService.ListMetadataResponse_element listResponse = new MetadataService.ListMetadataResponse_element();
                    MetadataService.FileProperties fileProp = new MetadataService.FileProperties();
                    fileProp.fullName = 'Test' + query.type_x; // Dynamic full name based on type
                    fileProp.type_x = query.type_x; // Set the type based on the request
                    listResponse.result = new List<MetadataService.FileProperties>{ fileProp };
                        response.put('response_x', listResponse); // Simulate the response for other metadata types
                }
            }
        } 
    }
}