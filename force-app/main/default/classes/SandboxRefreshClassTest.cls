@IsTest
public class SandboxRefreshClassTest {
    
    @TestSetup
    public static void setupTestData() {
        Org__c prodOrg = new Org__c(
            Name = 'ProdOrg',
            Domain_Url__c = 'https://login.salesforce.com',
            Access_Token__c = 'testAccessToken',
            Sandbox_Info_Id__c = 'testSandboxInfoId',
            License_Type__c = 'testLicenseType',
            Org_Type__c = 'Production',
            Org_Id__c = 'abuib!1234'
        );
        insert prodOrg;
        
        Org__c org = new Org__c(
            Name = 'TestOrg',
            Domain_Url__c = 'https://test.salesforce.com',
            Production_Org__c = prodOrg.Id,
            Access_Token__c = 'testAccessToken',
            Sandbox_Info_Id__c = 'testSandboxInfoId',
            License_Type__c = 'testLicenseType',
            Org_Type__c = 'Sandbox',
            Org_Id__c = 'abuib!1234'
        );
        insert org;
        
        Org__c org1 = new Org__c(
            Name = 'TestOrg1',
            Production_Org__c = prodOrg.Id,
            Domain_Url__c = 'https://test.salesforce.com',
            Access_Token__c = 'testAccessToken',
            Sandbox_Info_Id__c = 'testSandboxInfoId',
            License_Type__c = 'testLicenseType',
            Org_Type__c = 'Sandbox',
            Org_Id__c = 'abuib!1234'
        );
        insert org1;
        
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'Test',
                                                              Parent_Org__c = org1.Id,
                                                              Last_Refreshed_Date__c = system.today());
        insert refTemp;
        
        String metadataPackageXmlContent = '<Package><types><members>Apex1</members><name>ApexClass</name></types></Package>';
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'packageXml.txt';
        contentVersion.PathOnClient = 'packageXml.txt';
        contentVersion.VersionData = Blob.valueOf(metadataPackageXmlContent);
        contentVersion.FirstPublishLocationId = refTemp.Id;
        insert contentVersion;
        
        ConnectedAppCredentials__c creds = new ConnectedAppCredentials__c(Key__c = '12345',
                                                                          Secret__c = '09876'
                                                                          
        );
        insert creds;
        
        Logs__c refreshLog = new Logs__c(Parent_Template__c = refTemp.Id,
                                  Log_Type__c = 'Sandbox Refresh',
                                  Status__c = 'InProgress',
                                  Source_Org_For_Refresh__c = org.Id,
                                  Last_Refreshed_Date__c = system.now());
        insert refreshLog;
        
        Logs__c validateLog = new Logs__c(Parent_Template__c = refTemp.Id,
                                  Log_Type__c = 'Validate Template',
                                  Status__c = 'InProgress',
                                  Last_Validate_Async_Id__c = '0A12345',
                                  Source_Org_For_Validation__c = org1.Id);
        insert validateLog;
        
        Logs__c deployLog = new Logs__c(Parent_Template__c = refTemp.Id,
                                  Log_Type__c = 'Deploy - Metadata Restoration',
                                  Status__c = 'InProgress',
                                  Last_Deployment_Async_Id__c = '0A123456',
                                  Source_Org_For_Deployment__c = org1.Id);
        insert deployLog;
        
        Logs__c metadataTransformationLog = new Logs__c(Parent_Template__c = refTemp.Id,
                                  Log_Type__c = 'Search & Replace - Metadata Transformation',
                                  Status__c = 'InProgress',
                                  Last_Deployment_Async_Id__c = '0A123456',
                                  Source_Org_For_Deployment__c = org.Id);
        insert metadataTransformationLog;
        
        Logs__c apexMetadataTransformationLog = new Logs__c(Parent_Template__c = refTemp.Id,
                                  Log_Type__c = 'Apex Script - Metadata Transformation',
                                  Status__c = 'InProgress',
                                  Last_Deployment_Async_Id__c = '0A123456',
                                  Source_Org_For_Deployment__c = org.Id);
        insert apexMetadataTransformationLog;
        
        Logs__c dataTransformationLog = new Logs__c(Parent_Template__c = refTemp.Id,
                                  Log_Type__c = 'Data Transformation',
                                  Status__c = 'InProgress',
                                  Last_Deployment_Async_Id__c = '0A123456',
                                  Source_Org_For_Deployment__c = org.Id);
        insert dataTransformationLog;
    }
    
    @isTest
    static void testFetchSandboxInfo() {
        Test.setMock(HttpCalloutMock.class, new SandboxRefreshMock());
        
        Org__c testOrg = [SELECT Id FROM Org__c LIMIT 1];
        
        Test.startTest();
        SandboxRefreshClass.fetchSandboxInfo(testOrg.Id);
        Test.stopTest();
        
        Org__c updatedOrg = [SELECT Sandbox_Info_Id__c, License_Type__c FROM Org__c WHERE Id = :testOrg.Id];
        System.assertNotEquals('0GQ6g000000kCP3GAM', updatedOrg.Sandbox_Info_Id__c, 'Sandbox Info ID should be updated');
        System.assertNotEquals('DEVELOPER', updatedOrg.License_Type__c, 'License Type should be updated');
    }
    
    @isTest
    static void testFetchSandboxInfo1() {
        Test.setMock(HttpCalloutMock.class, new SandboxRefreshMock());
        
        Org__c testOrg = [SELECT Id FROM Org__c where Org_Type__c = 'Sandbox' LIMIT 1];
        
        Test.startTest();
        SandboxRefreshClass.fetchSandboxInfo(testOrg.Id);
        Test.stopTest();
        
        Org__c updatedOrg = [SELECT Sandbox_Info_Id__c, License_Type__c FROM Org__c WHERE Id = :testOrg.Id];
        System.assertNotEquals('0GQ6g000000kCP3GAM', updatedOrg.Sandbox_Info_Id__c, 'Sandbox Info ID should be updated');
        System.assertNotEquals('DEVELOPER', updatedOrg.License_Type__c, 'License Type should be updated');
    }
    
    @IsTest
    public static void testRefreshSandboxQueueable() {
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c log = [select Id, Status__c, Details__c from Logs__c limit 1];
        
       	String sandboxName = 'TestSandbox';
        String description = 'test description';
        boolean autoActivate = true;
        String apexClassName = 'SampleScheduledClass1';
        //Id apexClassId = '01p123456789XYZ';
        //Id publicGroupId = 'mockId12344';
        
        Test.startTest();
        
        SandboxRefreshMock mock = new SandboxRefreshMock();
        Test.setMock(HttpCalloutMock.class, mock);
        
        SandboxRefreshClass.RefreshSandboxQueueable refreshJob = new SandboxRefreshClass.RefreshSandboxQueueable(org.Id, refTemp.Id, sandboxName, description, autoActivate, refTemp.Id, refTemp.Id, log.Id);
        System.enqueueJob(refreshJob);
        
        SandboxRefreshClass.callRefreshSandboxQueueable(org.Id, refTemp.Id, sandboxName, description, autoActivate, apexClassName, refTemp.Id);
        
        Test.stopTest();
        
        Org__c updatedOrg = [SELECT Status__c FROM Org__c WHERE Id = :org.Id];
    }
    
    @IsTest
    public static void testRefreshSandboxQueueable2() {
        Org__c org = [SELECT Id FROM Org__c where Org_Type__c = 'Sandbox' LIMIT 1];
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c log = [select Id, Status__c, Details__c from Logs__c limit 1];
        
       	String sandboxName = 'TestSandbox';
        String description = 'test description';
        boolean autoActivate = true;
        String apexClassName = 'SampleScheduledClass1';
        //Id apexClassId = '01p123456789XYZ';
        //Id publicGroupId = 'mockId12344';
        
        Test.startTest();
        
        SandboxRefreshMock mock = new SandboxRefreshMock();
        Test.setMock(HttpCalloutMock.class, mock);
        
        SandboxRefreshClass.RefreshSandboxQueueable refreshJob = new SandboxRefreshClass.RefreshSandboxQueueable(org.Id, refTemp.Id, sandboxName, description, autoActivate, refTemp.Id, refTemp.Id, log.Id);
        System.enqueueJob(refreshJob);
        
        SandboxRefreshClass.callRefreshSandboxQueueable(org.Id, refTemp.Id, sandboxName, description, autoActivate, apexClassName, null);
        
        Test.stopTest();
        
        Org__c updatedOrg = [SELECT Status__c FROM Org__c WHERE Id = :org.Id];
    }
    
    @IsTest
    public static void testRefreshSandboxQueueable3() {
        Org__c org = [SELECT Id FROM Org__c where Org_Type__c = 'Sandbox' LIMIT 1];
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c log = [select Id, Status__c, Details__c from Logs__c limit 1];
        
       	String sandboxName = 'TestSandbox';
        String description = 'test description';
        boolean autoActivate = true;
        String apexClassName = 'SampleScheduledClass1';
        //Id apexClassId = '01p123456789XYZ';
        //Id publicGroupId = 'mockId12344';
        
        Test.startTest();
        
        SandboxRefreshMockForRefreshSandboxQueueable3 mock = new SandboxRefreshMockForRefreshSandboxQueueable3();
        Test.setMock(HttpCalloutMock.class, mock);
        
        SandboxRefreshClass.RefreshSandboxQueueable refreshJob = new SandboxRefreshClass.RefreshSandboxQueueable(org.Id, refTemp.Id, sandboxName, description, autoActivate, refTemp.Id, refTemp.Id, log.Id);
        System.enqueueJob(refreshJob);
        
        SandboxRefreshClass.callRefreshSandboxQueueable(org.Id, refTemp.Id, sandboxName, description, autoActivate, apexClassName, refTemp.Id);
        
        Test.stopTest();
        
        Org__c updatedOrg = [SELECT Status__c FROM Org__c WHERE Id = :org.Id];
    }
    
    private class SandboxRefreshMockForRefreshSandboxQueueable3 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"message":"Your source org is being created or refreshed. Provide the ID of one of this org’s completed sandboxes.","errorCode":"INVALID_INPUT","fields":[]}]');
            res.setStatusCode(403);
            return res;
        }
    }
    
    @isTest
    public static void testGetSourceOrgType(){
        Org__c org = [SELECT Id, Org_Type__c FROM Org__c LIMIT 1];
        
        Test.startTest();
        SandboxRefreshClass.getSourceOrgType(org.Id);
        Test.stopTest();
    }
    
    @IsTest
    public static void testGetSandboxStatus() {
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c log = [select Id, Status__c, Details__c from Logs__c limit 1];
        
        Test.startTest();
        SandboxRefreshMockForGetSandboxStatus mock = new SandboxRefreshMockForGetSandboxStatus();
        Test.setMock(HttpCalloutMock.class, mock);
        String status = SandboxRefreshClass.getSandboxStatus(log.Id, refTemp.Id);
        Test.stopTest();
    }
    
    private class SandboxRefreshMockForGetSandboxStatus implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"SandboxProcess","records":[{"attributes":{"type":"SandboxProcess","url":"/services/data/v59.0/tooling/sobjects/SandboxProcess/0GR6g00000095ASGAY"},"Id":"0GR6g00000095ASGAY","LicenseType":"DEVELOPER","SandboxName":"TestSandbox","SandboxInfoId":"0GQ6g000000kCP3GAM"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testValidatePackage() {
        SandboxRefreshWebServiceMock mock = new SandboxRefreshWebServiceMock();
        Test.setMock(WebServiceMock.class, mock);
        
        Org__c org = new Org__c(
            Name = 'Test Org',
            Access_Token__c = 'testAccessToken',
            Domain_Url__c = 'https://test.salesforce.com'
        );
        insert org;

        Refresh_Template__c template = new Refresh_Template__c(
            Name = 'Test Template',
            Package_xml_Val__c = '<Package>Test</Package>',
            Parent_Org__c = org.Id
        );
        insert template;

        Attachment zipAttachment = new Attachment(
            ParentId = template.Id,
            Name = 'TestPackage.zip',
            Body = Blob.valueOf('Dummy zip content')
        );
        insert zipAttachment;

        Test.startTest();
        Id asyncResultId = SandboxRefreshClass.validatePackage(org.Id, template.Id);
        Id asyncResultDeployId = SandboxRefreshClass.deployPackage(org.Id, template.Id);
        Test.stopTest();

        System.assertNotEquals(null, asyncResultId, 'AsyncResult ID should not be null.');
    }
    
    @isTest
    public static void testCountMembersInPackageXml(){
        String packageXml = '<Package><types><members>Apex1</members><name>ApexClass</name></types></Package>';
        
        Test.startTest();
        
        Integer count = SandboxRefreshClass.countMembersInPackageXml(packageXml);
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetValidationResultSuccess() {
        MockRefreshTokenCallout mockTokenCallout = new MockRefreshTokenCallout();
        Test.setMock(HttpCalloutMock.class, mockTokenCallout);
        
        MockDeployRequestCallout mockDeployCallout = new MockDeployRequestCallout();
        Test.setMock(HttpCalloutMock.class, mockDeployCallout);
        
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];
        Refresh_Template__c template = [SELECT Id FROM Refresh_Template__c LIMIT 1];
        Logs__c log = [select Id, Status__c, Details__c, Log_Type__c from Logs__c where Log_Type__c = 'Validate Template' limit 1];
        
        Test.startTest();
        //SandboxRefreshClass.WrapperForValidateResult result = SandboxRefreshClass.getValidationResult(org.Id, template.Id, 'mockAsyncResultId');
        SandboxRefreshClass.WrapperForValidateResult result = SandboxRefreshClass.getValidationResult(log.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testGetValidationResultFailure() {
        MockDeployRequestCalloutWithFailures mockDeployFailureCallout = new MockDeployRequestCalloutWithFailures();
        Test.setMock(HttpCalloutMock.class, mockDeployFailureCallout);
        
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];
        Refresh_Template__c template = [SELECT Id FROM Refresh_Template__c LIMIT 1];
        Logs__c log = [select Id, Status__c, Details__c, Log_Type__c from Logs__c where Log_Type__c = 'Validate Template' limit 1];
        
        Test.startTest();
        //SandboxRefreshClass.WrapperForValidateResult result = SandboxRefreshClass.getValidationResult(org.Id, template.Id, 'mockAsyncResultId');
        SandboxRefreshClass.WrapperForValidateResult result = SandboxRefreshClass.getValidationResult(log.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testGetDeployResultSuccess() {
        MockRefreshTokenCallout mockTokenCallout = new MockRefreshTokenCallout();
        Test.setMock(HttpCalloutMock.class, mockTokenCallout);
        
        MockDeployRequestCallout mockDeployCallout = new MockDeployRequestCallout();
        Test.setMock(HttpCalloutMock.class, mockDeployCallout);
        
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];
        Refresh_Template__c template = [SELECT Id FROM Refresh_Template__c LIMIT 1];
        Logs__c log = [select Id, Status__c, Details__c, Log_Type__c from Logs__c where Log_Type__c = 'Deploy - Metadata Restoration' limit 1];
        
        Test.startTest();
        //SandboxRefreshClass.WrapperForValidateResult result = SandboxRefreshClass.getValidationResult(org.Id, template.Id, 'mockAsyncResultId');
        SandboxRefreshClass.WrapperForValidateResult result = SandboxRefreshClass.getDeployResult(log.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testGetDeployResultFailure() {
        MockDeployRequestCalloutWithFailures mockDeployFailureCallout = new MockDeployRequestCalloutWithFailures();
        Test.setMock(HttpCalloutMock.class, mockDeployFailureCallout);
        
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];
        Refresh_Template__c template = [SELECT Id FROM Refresh_Template__c LIMIT 1];
        Logs__c log = [select Id, Status__c, Details__c, Log_Type__c from Logs__c where Log_Type__c = 'Deploy - Metadata Restoration' limit 1];
        
        Test.startTest();
        //SandboxRefreshClass.WrapperForValidateResult result = SandboxRefreshClass.getValidationResult(org.Id, template.Id, 'mockAsyncResultId');
        SandboxRefreshClass.WrapperForValidateResult result = SandboxRefreshClass.getDeployResult(log.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testCountMembersInPackageXml1() {
        String packageXml = '<Package><types><members>Test1</members><members>Test2</members></types></Package>';
        Integer count = SandboxRefreshClass.countMembersInPackageXml(packageXml);
    }
    
    private class MockRefreshTokenCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mockAccessToken"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class MockDeployRequestCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"deployResult":{"numberComponentsTotal":3,"details":{"componentSuccesses":[{"fullName":"Test1","componentType":"ApexClass"},{"fullName":"Test2","componentType":"ApexTrigger"}],"componentFailures":[]}}}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class MockDeployRequestCalloutWithFailures implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"deployResult":{"numberComponentsTotal":3,"details":{"componentSuccesses":[{"fullName":"Test1","componentType":"ApexClass"}],"componentFailures":[{"fullName":"Test2","componentType":"ApexTrigger","problem":"Syntax error","problemType":"Error","success":false,"warning":false,"lineNumber":"10","columnNumber":"15"}]}}}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testWebServiceMock() {
        SandboxRefreshWebServiceMock mock = new SandboxRefreshWebServiceMock();
        
        Object stub = null;
        Object request = null;
        Map<String, Object> response = new Map<String, Object>();
        String endpoint = 'https://test.salesforce.com';
        String soapAction = 'deploy';
        String requestName = 'deploy';
        String responseName = 'deployResponse';
        String responseNamespace = 'http://soap.sforce.com/2006/04/metadata';
        String responseNamespaceX = '';
        
        mock.doInvoke(
            stub,
            request,
            response,
            endpoint,
            soapAction,
            requestName,
            responseName,
            responseNamespace,
            responseNamespaceX
        );
        
        System.assert(response.containsKey(responseName), 'Response should contain the key: ' + responseName);
        
        MetadataService.deployResponse_element deployResponse = 
            (MetadataService.deployResponse_element) response.get(responseName);
        
        System.assertEquals('1234567890', deployResponse.result.Id, 'AsyncResult ID mismatch');
        System.assertEquals('Queued', deployResponse.result.State, 'AsyncResult State mismatch');
    }
    
    @isTest
    static void testCreateNewSandbox(){
        Org__c testOrg = new Org__c(Name = 'CFProd',
                                    Domain_Url__c = 'https://login.salesforce.com',
                                    Access_Token__c = '12345',
                                    Sandbox_Info_Id__c = '00G1234',
                                    License_Type__c = 'DEVELOPER'
                                   );
        insert testOrg;
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
        
        String sandboxName = 'TestSandbox';
        String licenseType = 'DEVELOPER';
        
        Test.startTest();
        SandboxRefreshClass.createNewSandbox(sandboxName, licenseType);
        SandboxRefreshClass.cloneExistingSandbox(testOrg.Id, sandboxName);
        SandboxRefreshClass.getNewSandboxStatus();
        Test.stopTest();
    }
    
    @isTest
    static void testCheckValidationStatus(){
        Logs__c validateLog = [select Id, Status__c, Details__c, Source_Org_For_Validation__c, Log_Type__c, Last_Validate_Async_Id__c from Logs__c where Log_Type__c = 'Validate Template' limit 1];
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
         
        Test.startTest();
        SandboxRefreshClass.checkValidationStatus(validateLog.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckDeploymentStatus(){
        Logs__c deployLog = [select Id, Status__c, Details__c, Log_Type__c, Source_Org_For_Deployment__c, Last_Deployment_Async_Id__c from Logs__c where Log_Type__c = 'Deploy - Metadata Restoration' limit 1];
        
        Test.setMock(HttpCalloutMock.class, new PreRefreshAutomationClassMock());
         
        Test.startTest();
        SandboxRefreshClass.checkDeploymentStatus(deployLog.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetValidateLogs(){
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c log = [select Id, Parent_Template__c, Status__c, Last_Validated_Date__c, Name, LastModifiedBy.Name from Logs__c where Parent_Template__c =: refTemp.Id AND Log_Type__c = 'Validate Template' ORDER BY CreatedDate DESC limit 1];
        
        Test.startTest();
        Logs__c logRec = SandboxRefreshClass.getValidationLogRecordofRefreshTemplate(refTemp.Id);
        Logs__c logRec1 = SandboxRefreshClass.getValidationLogRecord(log.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetDeploymentLogs(){
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c log = [select Id, Parent_Template__c, Status__c, Last_Deployment_Date__c, Name, LastModifiedBy.Name from Logs__c where Parent_Template__c =: refTemp.Id AND Log_Type__c = 'Deploy - Metadata Restoration' ORDER BY CreatedDate DESC limit 1];
        
        Test.startTest();
        Logs__c logRec = SandboxRefreshClass.getDeployLogRecordofRefreshTemplate(refTemp.Id);
        Logs__c logRec1 = SandboxRefreshClass.getDeployLogRecord(log.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetRefreshLogs(){
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c log = [select Id, Last_Refreshed_Date__c, Parent_Template__r.Parent_Org__r.License_Type__c, 
                       Parent_Template__c, Status__c, Parent_Template__r.Last_Refreshed_Date__c, Name, 
                       Parent_Template__r.Last_Run_Status__c, Parent_Template__r.Last_Refreshed_By__r.Name 
                       from Logs__c where Parent_Template__c =: refTemp.Id AND Log_Type__c = 'Sandbox Refresh' 
                       ORDER BY CreatedDate DESC limit 1];
            
       	Test.startTest();
        Logs__c logRec = SandboxRefreshClass.getRefreshLogRecordofRefreshTemplate(refTemp.Id);
        Logs__c logRec1 = SandboxRefreshClass.getRefreshLogRecord(log.Id);
        Boolean bool = SandboxRefreshClass.checkForMetadataZipFiles(refTemp.Id);
        Test.stopTest();
    }
    
    /*private class MockHttpResponseGeneratorForPGAndApexC implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('FROM+Group')) {
                res.setBody('{done=true, entityTypeName=Group, queryLocator=null, records=({Id=00GNS00000TJCO92AP, Name=Test, attributes={type=Group, url=/services/data/v57.0/tooling/sobjects/Group/00GNS00000TJCO92AP}}, {Id=00GNS00001TJCO92AP, Name=Test1, attributes={type=Group, url=/services/data/v57.0/tooling/sobjects/Group/00GNS00001TJCO92AP}}, {Id=00GNS00002TJCO92AP, Name=Test2, attributes={type=Group, url=/services/data/v57.0/tooling/sobjects/Group/00GNS00002TJCO92AP}}), size=3, totalSize=3}');
            } else if (req.getEndpoint().contains('FROM+ApexClass')) {
                res.setBody('{done=true, entityTypeName=ApexClass, queryLocator=null, records=({Id=01pNS000005YDj7YAG, Name=SampleScheduledClass1, attributes={type=ApexClass, url=/services/data/v57.0/tooling/sobjects/ApexClass/01pNS000005YDj7YAG}}, {Id=01pNS000015YDj7YAG, Name=SampleScheduledClass2, attributes={type=ApexClass, url=/services/data/v57.0/tooling/sobjects/ApexClass/01pNS000015YDj7YAG}}, {Id=01pNS000025YDj7YAG, Name=SampleScheduledClass2, attributes={type=ApexClass, url=/services/data/v57.0/tooling/sobjects/ApexClass/01pNS000025YDj7YAG}}), size=1, totalSize=1}');
            } else {
                res.setBody('{"records":[]}');
            }
            return res;
        }
    }*/
    
    private class MockHttpResponseGeneratorForPGAndApexC implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('FROM+Group')) {
                res.setBody('{"done": true, "entityTypeName": "Group", "queryLocator": null, "records": ['
                            + '{"Id": "00GNS00000TJCO92AP", "Name": "Test", "attributes": {"type": "Group", "url": "/services/data/v57.0/tooling/sobjects/Group/00GNS00000TJCO92AP"}},'
                            + '{"Id": "00GNS00001TJCO92AP", "Name": "Test1", "attributes": {"type": "Group", "url": "/services/data/v57.0/tooling/sobjects/Group/00GNS00001TJCO92AP"}},'
                            + '{"Id": "00GNS00002TJCO92AP", "Name": "Test2", "attributes": {"type": "Group", "url": "/services/data/v57.0/tooling/sobjects/Group/00GNS00002TJCO92AP"}}'
                            + '], "size": 3, "totalSize": 3}');
            } else if (req.getEndpoint().contains('FROM+ApexClass')) {
                res.setBody('{"done": true, "entityTypeName": "ApexClass", "queryLocator": null, "records": ['
                            + '{"Id": "01pNS000005YDj7YAG", "Name": "SampleScheduledClass1", "attributes": {"type": "ApexClass", "url": "/services/data/v57.0/tooling/sobjects/ApexClass/01pNS000005YDj7YAG"}},'
                            + '{"Id": "01pNS000015YDj7YAG", "Name": "SampleScheduledClass2", "attributes": {"type": "ApexClass", "url": "/services/data/v57.0/tooling/sobjects/ApexClass/01pNS000015YDj7YAG"}},'
                            + '{"Id": "01pNS000025YDj7YAG", "Name": "SampleScheduledClass3", "attributes": {"type": "ApexClass", "url": "/services/data/v57.0/tooling/sobjects/ApexClass/01pNS000025YDj7YAG"}}'
                            + '], "size": 3, "totalSize": 3}');
            } else {
                res.setBody('{"records":[]}');
            }
            return res;
        }
    }

    
    @isTest
    static void testFetchPublicGroupOfSource() {
        Org__c testOrg1 = [select Id from Org__c where Name = 'TestOrg1' limit 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForPGAndApexC());

        Test.startTest();
        List<Map<String, String>> result = SandboxRefreshClass.fetchPublicGroupOfSource(testOrg1.Id);
        Test.stopTest();
    }

    @isTest
    static void testFetchApexClassIdFromSource() {        
        Org__c testOrg1 = [select Id from Org__c where Name = 'TestOrg1' limit 1];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForPGAndApexC());
        
        Test.startTest();
        Id apexClassId = SandboxRefreshClass.fetchApexClassIdFromSource(testOrg1.Id, 'SampleScheduledClass1');
        Test.stopTest();
    }
    
    @isTest
    static void testGetUsersDataRestoreLogRecordofRefreshTemplate() {        
        Org__c testOrg1 = [select Id from Org__c where Name = 'TestOrg1' limit 1];
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTemp',
                                                             Parent_Org__c = testOrg1.Id);
        insert refTemp;
        
        Test.startTest();
        SandboxRefreshClass.getUsersDataRestoreLogRecordofRefreshTemplate(refTemp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetCustomSettingsDataRestoreLogRecordofRefreshTemplate() {        
        Org__c testOrg1 = [select Id from Org__c where Name = 'TestOrg1' limit 1];
        Refresh_Template__c refTemp = new Refresh_Template__c(Name = 'testTemp',
                                                             Parent_Org__c = testOrg1.Id);
        insert refTemp;
        
        Test.startTest();
        SandboxRefreshClass.getCustomSettingsDataRestoreLogRecordofRefreshTemplate(refTemp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetDataTransformationLogs(){
        Refresh_Template__c refTemp = [select Id from Refresh_Template__c limit 1];
        Logs__c log = [select Id, Parent_Template__c, Status__c, Last_Deployment_Date__c, Name, LastModifiedBy.Name from Logs__c where Parent_Template__c =: refTemp.Id AND Log_Type__c = 'Data Transformation' ORDER BY CreatedDate DESC limit 1];
        
        Test.startTest();
        Logs__c logRec = SandboxRefreshClass.getDataTransformLogRecordofRefreshTemplate(refTemp.Id);
        Logs__c logRec1 = SandboxRefreshClass.getDataTransformLogRecord(log.Id);
        Test.stopTest();
    }
}