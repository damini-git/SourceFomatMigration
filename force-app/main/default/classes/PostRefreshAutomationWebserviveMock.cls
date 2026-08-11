@isTest
global class PostRefreshAutomationWebserviveMock implements WebServiceMock {
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
            MetadataService.listMetadataResponse_element listMetadataResponse = 
                new MetadataService.listMetadataResponse_element();
            
            MetadataService.FileProperties[] fileProps = new MetadataService.FileProperties[1];
            MetadataService.FileProperties prop = new MetadataService.FileProperties();
            prop.fullName = 'TestLabel';
            prop.type_x = 'CustomLabel';
            fileProps[0] = prop;

            listMetadataResponse.result = fileProps;
            response.put('result', listMetadataResponse);
        }

        if (requestName == 'readMetadata') {
            MetadataService.readMetadataResponse_element readMetadataResponse = 
                new MetadataService.readMetadataResponse_element();
            
            MetadataService.ReadResult readResult = new MetadataService.ReadResult();
            MetadataService.Metadata[] metadataRecords = new MetadataService.Metadata[1];
            MetadataService.Metadata metadataRecord = new MetadataService.Metadata();
            metadataRecord.fullName = 'TestLabel';
            metadataRecords[0] = metadataRecord;

            readResult.records = metadataRecords;
            readMetadataResponse.result = readResult;
            response.put('result', readMetadataResponse);
        }

        if (requestName == 'upsertMetadata') {
            MetadataService.upsertMetadataResponse_element upsertMetadataResponse = 
                new MetadataService.upsertMetadataResponse_element();
            
            MetadataService.UpsertResult[] upsertResults = new MetadataService.UpsertResult[1];
            MetadataService.UpsertResult result = new MetadataService.UpsertResult();
            result.fullName = 'TestLabel';
            result.success = true;
            upsertResults[0] = result;

            upsertMetadataResponse.result = upsertResults;
            response.put('result', upsertMetadataResponse);
        }
        
        if (requestName == 'createMetadata') {
            MetadataService.SaveResult saveResult = new MetadataService.SaveResult();
            saveResult.success = true;
            saveResult.fullName = 'ScheduledJobBackup';
            saveResult.errors = new List<MetadataService.Error>();
            
            MetadataService.createMetadataResponse_element responseElement = new MetadataService.createMetadataResponse_element();
            responseElement.result = new List<MetadataService.SaveResult>{ saveResult };

            response.put('return', responseElement);
        }
        
        if (requestName == 'deleteMetadata') {
            MetadataService.deleteMetadataResponse_element deleteMetadataResponse = 
                new MetadataService.deleteMetadataResponse_element();
            
            MetadataService.DeleteResult[] deleteResults = new MetadataService.DeleteResult[1];
            MetadataService.DeleteResult deleteResult = new MetadataService.DeleteResult();
            deleteResult.fullName = 'ScheduledJobBackup';
            deleteResult.success = true;
            deleteResults[0] = deleteResult;
            
            deleteMetadataResponse.result = deleteResults;
            response.put('result', deleteMetadataResponse);
        }
        
        
        
        /*if (request instanceof MetadataService.listMetadata_element) {
            response.put('response_x', createListMetadataResponse());
        }
        else if (request instanceof MetadataService.readMetadata_element) {
            MetadataService.readMetadataResponse_element readResponse = new MetadataService.readMetadataResponse_element();
            MetadataService.ReadResult result = new MetadataService.ReadResult();
            
            MetadataService.CustomLabel label = new MetadataService.CustomLabel();
            label.fullName = 'TestLabel';
            label.value = 'oldValue';
            
            result.records = new List<MetadataService.Metadata>{ label };
                readResponse.result = result;
            response.put('response_x', readResponse);
        }
        else if (request instanceof MetadataService.upsertMetadata_element) {
            response.put('response_x', createUpsertMetadataResponse());
        }*/
    }
    
    /*private MetadataService.listMetadataResponse_element createListMetadataResponse() {
        MetadataService.listMetadataResponse_element response = new MetadataService.listMetadataResponse_element();
        MetadataService.FileProperties prop = new MetadataService.FileProperties();
        prop.fullName = 'TestLabel';
        response.result = new List<MetadataService.FileProperties>{ prop };
        return response;
    }
    
    private MetadataService.upsertMetadataResponse_element createUpsertMetadataResponse() {
        MetadataService.upsertMetadataResponse_element response = new MetadataService.upsertMetadataResponse_element();
        MetadataService.UpsertResult result = new MetadataService.UpsertResult();
        result.success = true;
        response.result = new List<MetadataService.UpsertResult>{ result };
        return response;
    }*/
}