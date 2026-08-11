public class PaginatedUserResponse {
    @AuraEnabled public List<UserWrapper> users { get; set; }
    @AuraEnabled public String nextRecordsUrl { get; set; }
    @AuraEnabled public Integer totalRecords { get; set; }
    
    public class UserWrapper {
        @AuraEnabled public string id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String username { get; set; }
        @AuraEnabled public String profile { get; set; }
        @AuraEnabled public boolean isActive { get; set; }
    }
}