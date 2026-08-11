public class DynamicRSSCreation {
    static MetadataService.MetadataPort createService()
    {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }
    public static List<MetadataService.UpsertResult> upsertMetadata(MetadataService.RemoteSiteSetting input)
    {
        return createService().upsertMetadata(new List<MetadataService.Metadata> { input });
    }    
    
}