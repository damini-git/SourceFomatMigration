public class BackupRegenerationOfMetadata {
    public static MetadataService.MetadataPort createService(String domainUrl, String accessToken) {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        String version = '59.0';
        service.endpoint_x = domainUrl + '/services/Soap/m/' + version;
        service.SessionHeader.sessionId = accessToken;
        service.timeout_x = 120000;
        return service;
    }
    
    
    public static MetadataService.Package_x parsePackageXml(String packageXmlContent) {
        MetadataService.Package_x unpackaged = new MetadataService.Package_x();
        unpackaged.types = new List<MetadataService.PackageTypeMembers>();
        
        Dom.Document doc = new Dom.Document();
        doc.load(packageXmlContent);
        Dom.XmlNode packageNode = doc.getRootElement();
        
        
        for (Dom.XmlNode typeNode : packageNode.getChildElements()) {
            if (typeNode.getName() == 'types') {
                MetadataService.PackageTypeMembers packageTypeMember = new MetadataService.PackageTypeMembers();
                packageTypeMember.members = new List<String>();
                
                for (Dom.XmlNode typeChildNode : typeNode.getChildElements()) {
                    if (typeChildNode.getName() == 'name') {
                        packageTypeMember.name = typeChildNode.getText();
                    } else if (typeChildNode.getName() == 'members') {
                        packageTypeMember.members.add(typeChildNode.getText());
                    }
                }
                unpackaged.types.add(packageTypeMember);
            }
        }
        unpackaged.version = '59.0';
        return unpackaged;
    }
    
    @future(callout=true)
    public static void retrievePackage(Id refTempId, String domainUrl, String accessToken, String metadataPackageXmlContent, Id metaRegenerationLogId){
        system.debug('metadataPackageXmlContent --- ' + metadataPackageXmlContent);
        Logs__c metaRegenerationLog = [select Id, Status__c, Details__c from Logs__c where Id =: metaRegenerationLogId];
        
        try{
            MetadataService.MetadataPort service = createService(domainUrl, accessToken);
            MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
            retrieveRequest.apiVersion = 59.0;
            retrieveRequest.singlePackage = true;
            retrieveRequest.unpackaged = parsePackageXml(metadataPackageXmlContent);
            
            MetadataService.AsyncResult asyncResult = service.retrieve(retrieveRequest);
            
            String asyncResultId = asyncResult.id;
            system.debug('asyncResultId --- ' + asyncResultId);
            String queueJobId = System.enqueueJob(new InitialMetadataRetrievalJobNew(asyncResultId, refTempId, domainUrl, accessToken, metadataPackageXmlContent, metaRegenerationLogId));
            system.debug('queueJobId --- ' + queueJobId);
        } catch (Exception e) {
            System.debug('Error retrieving and storing metadata: ' + e.getMessage());
            metaRegenerationLog.Status__c = 'Failed';
            metaRegenerationLog.Details__c = e.getMessage();
            update metaRegenerationLog;
        }
    }
    
    @future(callout=true)
    public static void initiateMetadataRetrievalAgain(String asyncResultId, Id refTempId, String domainUrl, String accessToken, String metadataPackageXmlContent, Id metadataRetrieveLogId){
        system.debug('initiating the metadata check retrieve status again --- ');
        System.enqueueJob(new InitialMetadataRetrievalJobNew(asyncResultId, refTempId, domainUrl, accessToken, metadataPackageXmlContent, metadataRetrieveLogId));
    }
    
    public class InitialMetadataRetrievalJobNew implements Queueable, Database.AllowsCallouts {
        private String asyncResultId;
        private Id refTempId;
        private String domainUrl;
        private String accessToken;
        private String metadataPackageXmlContent;
        private Id metaRegenerationLogId;
        
        public InitialMetadataRetrievalJobNew(String asyncResultId, Id refTempId, String domainUrl, String accessToken, String metadataPackageXmlContent, Id metaRegenerationLogId) {
            this.asyncResultId = asyncResultId;
            this.refTempId = refTempId;
            this.domainUrl = domainUrl;
            this.accessToken = accessToken;
            this.metadataPackageXmlContent = metadataPackageXmlContent;
            this.metaRegenerationLogId = metaRegenerationLogId;
        }
        
        public void execute(QueueableContext context) {
            Logs__c metaRegenerationLog = [select Id, Status__c, Details__c from Logs__c where Id =: metaRegenerationLogId];
            
            try {
                system.debug('asyncResultId --- ' + asyncResultId);
                BackupRegenerationOfMetadata outerClass = new BackupRegenerationOfMetadata();
                boolean isMetadataRetrieveDone = false;
                
                if(!String.isEmpty(asyncResultId)){
                    MetadataService.MetadataPort service = createService(domainUrl, accessToken);
                    MetadataService.RetrieveResult retrieveResult = service.checkRetrieveStatus(asyncResultId, false);
                    system.debug('retrieveResult.done --- ' + retrieveResult.done);
                    
                    if(!retrieveResult.done){
                        initiateMetadataRetrievalAgain(asyncResultId, refTempId, domainUrl, accessToken, metadataPackageXmlContent, metaRegenerationLogId);
                    }
                    
                    if(retrieveResult.done){
                        retrieveResult = service.checkRetrieveStatus(asyncResultId, true);
                        if (retrieveResult == null || retrieveResult.zipFile == null) {
                            system.debug('RetrieveResult or zipFile is null');
                            return;
                        }
                        isMetadataRetrieveDone = true;
                        outerClass.handleRetrievedMetadataNew(refTempId, retrieveResult, metadataPackageXmlContent, metaRegenerationLogId);
                    }
                }
            } catch (Exception e) {
                System.debug('Error in MetadataCompletionJob: ' + e.getMessage());
                metaRegenerationLog.Status__c = 'Failed';
                metaRegenerationLog.Details__c = e.getMessage();
                update metaRegenerationLog;
            }
        }
    }
    
    public void handleRetrievedMetadataNew(Id refTempId, MetadataService.RetrieveResult retrieveResult, String metadataPackageXmlContent, Id metaRegenerationLogId) {
        system.debug('retrieveResult --- ' + retrieveResult.zipFile);
        Logs__c metaRegenerationLog = [select Id, Log_Type__c, Status__c, Details__c from Logs__c where Id =: metaRegenerationLogId];
        
        List<Attachment> metadataAttachment = [SELECT Id, Name,ParentId FROM Attachment where ParentId=: refTempId AND Name ='Metadata.zip' LIMIT 1];
        if(metadataAttachment.size() > 0){
            delete metadataAttachment;
        }
        
        if(metaRegenerationLog.Log_Type__c == 'Metadata Retrieve - Update Template'){
            /*** delete the old packageXml.txt file ***/
            List<ContentDocumentLink> attachments = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocumentId 
                                                     FROM ContentDocumentLink 
                                                     WHERE LinkedEntityId = :refTempId 
                                                     AND ContentDocument.Title = 'packageXml.txt'
                                                    ];
            system.debug('attachments------>>>>>>'+attachments);
            if(attachments.size() > 0){
                delete attachments;
            } 
            
            /*** insert new packageXml.txt file ***/
            Blob zipBlob = EncodingUtil.base64Decode(retrieveResult.zipFile);
            
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'packageXml.txt';
            contentVersion.PathOnClient = 'packageXml.txt';
            contentVersion.VersionData = Blob.valueOf(metadataPackageXmlContent);
            insert contentVersion;
            
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :contentVersion.Id
            ].ContentDocumentId;
            contentDocumentLink.LinkedEntityId = refTempId;
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;
            
            system.debug('Package Xml text file created with ID: ' + contentVersion.Id);
        }
        
        Blob zipBlob = EncodingUtil.base64Decode(retrieveResult.zipFile);
        
        Attachment attachment = new Attachment();
        attachment.ParentId = refTempId;
        attachment.Name = 'Metadata.zip';
        attachment.Body = zipBlob;
        attachment.ContentType = 'application/zip';
        insert attachment;
        
        metaRegenerationLog.Status__c = 'Success';
        update metaRegenerationLog;
        
        system.debug('Attachment created with ID: ' + attachment.Id);
    }
}