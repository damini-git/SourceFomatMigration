public with sharing class PackageXMLController {
    private static final String FILE_NAME = 'packageXml.txt';
	private static final String FILE_TYPE = 'TEXT';    
    private static final String CLASS_NAME = 'PackageXMLController';
    
    @AuraEnabled(cacheable=true)
    public static List<ComponentWrapper> getPackageContents(Id recordId) {
        List<ComponentWrapper> componentList = new List<ComponentWrapper>();
        System.debug('DEBUG [' + CLASS_NAME + '] Starting getPackageContents for recordId: ' + recordId);
        
        try {
            // First, query ContentDocumentLink to get ContentDocumentId
            List<ContentDocumentLink> contentLinks = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId
            ];
            
            System.debug('DEBUG [' + CLASS_NAME + '] Found ' + contentLinks.size() + ' linked documents');
            
            if (contentLinks.isEmpty()) {
                String errorMsg = 'No files found linked to this record.';
                System.debug('ERROR [' + CLASS_NAME + '] ' + errorMsg);
                throw new AuraHandledException(errorMsg);
            }
            
            // Get all ContentDocument Ids
            Set<Id> contentDocIds = new Set<Id>();
            for (ContentDocumentLink link : contentLinks) {
                contentDocIds.add(link.ContentDocumentId);
            }
            
            // Query ContentVersion for the specific file
            ContentVersion contentVersion = [
                SELECT VersionData, Title, ContentSize 
                FROM ContentVersion 
                WHERE ContentDocumentId IN :contentDocIds
                AND Title = : FILE_NAME
                AND FileType = : FILE_TYPE
                AND IsLatest = true
                LIMIT 1
            ];
            
            System.debug('DEBUG [' + CLASS_NAME + '] Found ContentVersion: ' + contentVersion.Title + 
                        ' | Size: ' + contentVersion.ContentSize + ' bytes');

            // Get the XML content
            String xmlContent = contentVersion.VersionData.toString();
            System.debug('DEBUG [' + CLASS_NAME + '] Successfully retrieved XML content, length: ' + xmlContent.length());
            
            // Parse XML
            Dom.Document doc = new Dom.Document();
            doc.load(xmlContent);
            
            // Get the root element
            Dom.XMLNode packageNode = doc.getRootElement();
            
            // Track counter across all types
            Integer globalCounter = 1;
            
            // Process each types node
            for(Dom.XMLNode typesNode : packageNode.getChildElements()) {
                if(typesNode.getName() == 'types') {
                    String componentType = '';
                    List<String> members = new List<String>();
                    
                    // Get members and name for this type
                    for(Dom.XMLNode child : typesNode.getChildElements()) {
                        if(child.getName() == 'name') {
                            componentType = child.getText();
                        } else if(child.getName() == 'members') {
                            members.add(child.getText());
                        }
                    }
                    
                    System.debug('DEBUG [' + CLASS_NAME + '] Processing type: ' + componentType + ' with ' + members.size() + ' members');
                    
                    // Add each member to the list
                    for(String member : members) {
                        componentList.add(new ComponentWrapper(
                            globalCounter++,
                            member,
                            componentType
                        ));
                    }
                }
            }
            
            System.debug('DEBUG [' + CLASS_NAME + '] Successfully processed ' + componentList.size() + ' components');
            
        } catch(Exception e) {
            String errorMsg = 'Error processing XML: ' + e.getMessage();
            System.debug('ERROR [' + CLASS_NAME + '] Exception: ' + errorMsg);
            System.debug('ERROR [' + CLASS_NAME + '] Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException(errorMsg);
        }
        
        return componentList;
    }
    
    
     @AuraEnabled
    public static List<PermissionSet> getAssignedPermissionSets() {
        // Get the logged-in user's ID
        String userId = UserInfo.getUserId();
        
        // Retrieve the logged-in user's profile ID
        User loggedInUser = [SELECT ProfileId FROM User WHERE Id = :userId LIMIT 1];
        Id profileId = loggedInUser.ProfileId;
        
        // Retrieve all users with the same profile ID
        List<User> usersWithSameProfile = [
            SELECT Id 
            FROM User 
            WHERE ProfileId = :profileId
        ];
        
        // Collect User IDs
        Set<Id> userIds = new Set<Id>();
        for (User user : usersWithSameProfile) {
            userIds.add(user.Id);
        }
        
        // Retrieve all Permission Sets assigned to these users
        List<PermissionSetAssignment> assignments = [
            SELECT PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId IN :userIds
        ];
        
        // Collect Permission Set IDs
        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionSetAssignment assignment : assignments) {
            permissionSetIds.add(assignment.PermissionSetId);
        }
        
        // Retrieve the Permission Set records for the IDs
        List<PermissionSet> permissionSets = [
            SELECT Id, Name 
            FROM PermissionSet 
            WHERE Id IN :permissionSetIds
        ];
        return permissionSets;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getProfileName() {
        // Get the current user's profile name
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        return currentUser.Profile.Name;
    }
    
    public class ComponentWrapper {
        @AuraEnabled public Integer index { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        
        public ComponentWrapper(Integer index, String name, String type) {
            this.index = index;
            this.name = name;
            this.type = type;
        }
    }
}