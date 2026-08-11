public with sharing class JSONFileReader {
    /* @AuraEnabled(cacheable=true)
public static List<Map<String, Object>> readJSONFromRelatedFiles(Id recordId) {
System.debug('Apex Method Called with Record ID: ' + recordId);

// Validate input
if (recordId == null) {
System.debug('Record ID is null');
return new List<Map<String, Object>>();
}

List<Map<String, Object>> allJsonData = new List<Map<String, Object>>();

try {
// Find JSON files related to the record
List<ContentDocumentLink> links = [
SELECT ContentDocument.Id, 
ContentDocument.Title, 
ContentDocument.LatestPublishedVersionId
FROM ContentDocumentLink 
WHERE LinkedEntityId = :recordId 
AND ContentDocument.FileType = 'JSON'
];

System.debug('Number of JSON links found: ' + links.size());

for (ContentDocumentLink link : links) {
ContentVersion cv = [
SELECT VersionData, Title 
FROM ContentVersion 
WHERE Id = :link.ContentDocument.LatestPublishedVersionId 
AND IsLatest = true
LIMIT 1
];

// Convert blob to string
String jsonContent = cv.VersionData.toString();

System.debug('JSON Filename: ' + cv.Title);
System.debug('JSON Content: ' + jsonContent);

// Parse JSON content
List<Map<String, Object>> parsedData = parseJSON(jsonContent);

// Add parsed data for this file
allJsonData.addAll(parsedData);
}
} catch (Exception e) {
System.debug('Error in readJSONFromRelatedFiles: ' + e.getMessage());
System.debug('Stack Trace: ' + e.getStackTraceString());
throw new AuraHandledException('Error reading JSON: ' + e.getMessage());
}

System.debug('Total JSON data rows: ' + allJsonData.size());
return allJsonData;
}

private static List<Map<String, Object>> parseJSON(String jsonContent) {
List<Map<String, Object>> parsedData = new List<Map<String, Object>>();

try {
// Parse the JSON content
Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonContent);

// Check for specific keys
String[] possibleKeys = new String[]{
'User', 'data', 'records', 'results', 'items', 'users'
};

for (String key : possibleKeys) {
if (jsonMap.containsKey(key)) {
Object dataObj = jsonMap.get(key);

if (dataObj instanceof List<Object>) {
List<Object> dataList = (List<Object>)dataObj;
for (Object obj : dataList) {
if (obj instanceof Map<String, Object>) {
parsedData.add((Map<String, Object>)obj);
}
}

if (!parsedData.isEmpty()) {
break;
}
}
}
}
} catch (Exception e) {
System.debug('JSON Parsing Error: ' + e.getMessage());
}

return parsedData;
}*/
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> readJSONFromRelatedFiles(Id recordId) {
        try {
            // Query ContentDocumentLink to get ContentDocumentId related to the given recordId
            List<ContentDocumentLink> links = [SELECT ContentDocument.LatestPublishedVersionId, ContentDocumentId 
                                               FROM ContentDocumentLink 
                                               WHERE LinkedEntityId = :recordId 
                                               AND ContentDocument.FileType = 'JSON'
                                               LIMIT 1];
            
            // If no JSON file found, return empty list instead of throwing error
            if (links.isEmpty()) {
                return new List<Map<String, Object>>();
            }
            
            ContentDocumentLink link = links[0];
            
            // Query ContentVersion to retrieve the JSON file content
            ContentVersion contentVersion = [SELECT VersionData FROM ContentVersion 
                                             WHERE ContentDocumentId = :link.ContentDocumentId 
                                             LIMIT 1];
            
            // Decode the VersionData from Base64 and URL-decode it
            String decodedJson = EncodingUtil.urlDecode(contentVersion.VersionData.toString(), 'UTF-8');
            
            try {
                // Deserialize the JSON into a UserResponse object
                UserResponse response = (UserResponse)JSON.deserialize(decodedJson, UserResponse.class);
                
                // If no user data in JSON, return empty list
                if (response == null || response.User == null || response.User.isEmpty()) {
                    return new List<Map<String, Object>>();
                }
                
                // Extract the list of users and process them
                List<Map<String, Object>> filteredData = new List<Map<String, Object>>();
                
                for (User user : response.User) {
                    Map<String, Object> filteredUser = new Map<String, Object>();
                    
                    filteredUser.put('LastName', user.LastName);
                    filteredUser.put('FirstName', user.FirstName);
                    filteredUser.put('Name', user.Name);
                    filteredUser.put('Username', user.Username);
                    filteredUser.put('Email', user.Email);
                    filteredUser.put('ProfileName', user.Profile != null ? user.Profile.Name : 'N/A');
                    
                    filteredData.add(filteredUser);
                }
                
                return filteredData;
            } catch (JSONException e) {
                // If JSON parsing fails, return empty list
                return new List<Map<String, Object>>();
            }
            
        } catch (Exception e) {
            // For any other unexpected errors, throw exception
            throw new CustomException(e.getMessage());
        }
    }
    
    public class CustomException extends Exception {}
    
    // Inner classes for JSON deserialization remain the same
    public class UserResponse {
        public List<User> user;  // Use camelCase for variable names
    }
    
    public class User {
        public String lastName;  // Use camelCase for variable names
        public String firstName; // Use camelCase for variable names
        public String name;      // Use camelCase for variable names
        public String username;  // Use camelCase for variable names
        public String email;     // Use camelCase for variable names
        public Profile profile;  // Use camelCase for variable names
    }
    
    public class Profile {
        public String name;  // Use camelCase for variable names
    }
    
    
}