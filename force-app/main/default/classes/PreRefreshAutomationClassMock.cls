public class PreRefreshAutomationClassMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create a new HTTPResponse
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        // Mock different responses based on the request endpoint
        if (req.getEndpoint().contains('/services/oauth2/authorize')) {
            // Simulate OAuth authorization response
            res.setStatusCode(200);
            res.setHeader('Location', 'https://test.salesforce.com/services/oauth2/success');
        }
        else if (req.getEndpoint().contains('/services/data/v54.0/tooling/query')) {
            // Simulate Named Credentials query response
            res.setStatusCode(200);
            res.setBody('{"records": [{"Id": "001", "MasterLabel": "TestNamedCredential"}]}');
        }
        else if (req.getEndpoint().contains('/services/Soap/m/53.0')) {
            // Simulate Metadata API response
            res.setStatusCode(200);
            res.setBody('<?xml version="1.0" encoding="UTF-8"?><Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><listMetadataResponse xmlns="http://soap.sforce.com/2006/04/metadata"><result><fullName>TestCustomLabel</fullName></result></listMetadataResponse></Body></Envelope>');
        }
        else if(req.getEndpoint().contains('/services/data/v57.0/tooling/query/?q=SELECT+Label,QualifiedApiName,DataType,Length,LastModifiedBy.Name,LastModifiedDate+FROM+FieldDefinition+WHERE+EntityDefinition.QualifiedApiName')) {
            res.setStatusCode(200);
            res.setBody('{"size": 60,"totalSize": 60,"done": true,"queryLocator": null,"entityTypeName": "FieldDefinition","records": [{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBkX"},"Label": "Records","QualifiedApiName": "Records__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:44:10.000+0000"},{"attributes": {"type": "FieldDefinition","url": "/services/data/v57.0/tooling/sobjects/FieldDefinition/Account.00NNS00000ISBhJ"},"Label": "Read Result","QualifiedApiName": "Read_Result__c","DataType": "Long Text Area(131072)","Description": null,"Length": 131072,"LastModifiedBy": {"attributes": {"type": "User","url": "/services/data/v57.0/tooling/sobjects/User/005NS000000AenNYAS"},"Name": "Biswanath Mishra"},"LastModifiedDate": "2024-11-21T12:43:49.000+0000"}]}');
        }
        else if(req.getEndpoint().contains('/services/data/v61.0/metadata/deployRequest/')){
            res.setStatusCode(200);
            res.setBody('{"id": "0AfNS00000H2P71","validatedDeployRequestId": null,"deployOptions": null,"deployResult": {"id": "0AfNS00000H2P710AF","messages": null,"retrieveResult": null,"success": true,"checkOnly": true,"ignoreWarnings": true,"rollbackOnError": true,"status": "Succeeded","numberComponentsDeployed": 5,"numberComponentsTotal": 5,"numberComponentErrors": 0,"numberTestsCompleted": 0,"numberTestsTotal": 0,"numberTestErrors": 0,"details": {"componentFailures": [{"componentType": "ApexClass","fileName": "classes/ApexCodeCoverageAPI.cls","fullName": "ApexCodeCoverageAPI","id": "01pNS000002FzzjYAC","problem": null,"success": true,"warning": false,"created": false,"changed": false,"deleted": false,"lineNumber": null,"columnNumber": null,"requiresProductionTestRun": false,"createdDate": "2025-01-22T16:44:14.000+0000","knownPackagingProblem": false,"forPackageManifestFile": false,"problemType": null},{"componentType": "ApexPage","fileName": "pages/CICDPage.page","fullName": "CICDPage","id": "066NS000001iGuyYAE","problem": null,"success": true,"warning": false,"created": false,"changed": false,"deleted": false,"lineNumber": null,"columnNumber": null,"requiresProductionTestRun": false,"createdDate": "2025-01-22T16:44:14.000+0000","knownPackagingProblem": false,"forPackageManifestFile": false,"problemType": null}],"componentSuccesses": [{"componentType": "ApexClass","fileName": "classes/ALMController.cls","fullName": "ALMController","id": "01pNS000002FzziYAC","problem": null,"success": true,"warning": false,"created": false,"changed": false,"deleted": false,"lineNumber": null,"columnNumber": null,"requiresProductionTestRun": false,"createdDate": "2025-01-22T16:44:14.000+0000","knownPackagingProblem": false,"forPackageManifestFile": false,"problemType": null},{"componentType": "ApexClass","fileName": "classes/ApexCodeCoverageWrapper.cls","fullName": "ApexCodeCoverageWrapper","id": "01pNS000002FzzkYAC","problem": null,"success": true,"warning": false,"created": false,"changed": false,"deleted": false,"lineNumber": null,"columnNumber": null,"requiresProductionTestRun": false,"createdDate": "2025-01-22T16:44:14.000+0000","knownPackagingProblem": false,"forPackageManifestFile": false,"problemType": null}],"retrieveResult": null,"runTestResult": {"successes": [],"failures": [],"totalTime": 0.0,"apexLogId": null,"flowCoverage": [],"numFailures": 0,"codeCoverage": [],"codeCoverageWarnings": [],"numTestsRun": 0,"flowCoverageWarnings": []},"allComponentMessages": [{"componentType": "ApexClass","fileName": "classes/ALMController.cls","fullName": "ALMController","id": "01pNS000002FzziYAC","problem": null,"success": true,"warning": false,"created": false,"changed": false,"deleted": false,"lineNumber": null,"columnNumber": null,"requiresProductionTestRun": false,"createdDate": "2025-01-22T16:44:14.000+0000","knownPackagingProblem": false,"forPackageManifestFile": false,"problemType": null}]},"createdDate": "2025-01-22T16:44:12.000+0000","startDate": "2025-01-22T16:44:13.000+0000","lastModifiedDate": "2025-01-22T16:44:14.000+0000","completedDate": "2025-01-22T16:44:14.000+0000","errorStatusCode": null,"errorMessage": null,"stateDetail": null,"createdBy": "005NS000000AenN","createdByName": "Biswanath Mishra","canceledBy": null,"canceledByName": null,"done": true,"runTestResult": null,"runTestsEnabled": false}}');
        }
        else if(req.getEndpoint().contains('/services/data/v60.0/sobjects/')){
            res.setStatusCode(200);
            res.setBody('{"actionOverrides": [],"activateable": false,"associateEntityType": null,"associateParentEntity": null,"childRelationships": [{"cascadeDelete": true,"childSObject": "AIInsightValue","deprecatedAndHidden": false,"field": "SobjectLookupValueId","junctionIdListNames": [],"junctionReferenceTo": [],"relationshipName": null,"restrictedDelete": false}],"compactLayoutable": true,"createable": true,"custom": false,"customSetting": false,"deepCloneable": false,"defaultImplementation": null,"deletable": true,"deprecatedAndHidden": false,"extendedBy": null,"extendsInterfaces": null,"feedEnabled": true,"fields": [{"label": "Account ID","name": "Id","type": "id","updateable": true},{"label": "Deleted","name": "IsDeleted","type": "boolean","updateable": false}]}');
        }
        else {
            // Default response for unmatched endpoints
            res.setStatusCode(404);
            res.setBody('{"message": "Not Found"}');
        }

        return res;
    }
}