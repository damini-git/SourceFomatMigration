public with sharing class ScriptDataController implements Comparable {
    
    // Wrapper class to match the datatable structure
    public class ScriptWrapper implements Comparable {
        @AuraEnabled public Integer order { get; set; }
        @AuraEnabled public String scriptName { get; set; }
        @AuraEnabled public String scriptData { get; set; }
        @AuraEnabled public String id { get; set; }
        
        public ScriptWrapper(Integer order, String scriptName, String scriptData) {
            this.order = order;
            this.scriptName = scriptName;
            this.scriptData = scriptData;
            this.id = String.valueOf(order);
        }
        
        // Implement compareTo method for sorting
        public Integer compareTo(Object compareTo) {
            ScriptWrapper compareToEmp = (ScriptWrapper)compareTo;
            if (order == compareToEmp.order) return 0;
            if (order > compareToEmp.order) return 1;
            return -1;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ScriptWrapper> readCSVFile(Id recordId) {
        List<ScriptWrapper> scriptList = new List<ScriptWrapper>();
        
        try {
            // Query ContentDocumentLink to get CSV files related to the record
            List<ContentDocumentLink> links = [SELECT ContentDocument.LatestPublishedVersionId, 
                                                    ContentDocumentId,
                                                    ContentDocument.Title,
                                                    ContentDocument.CreatedDate
                                             FROM ContentDocumentLink 
                                             WHERE LinkedEntityId = :recordId 
                                             AND ContentDocument.FileType = 'CSV'
                                             AND ContentDocument.Title = 'Scripts'
                                             ORDER BY ContentDocument.CreatedDate DESC
                                             LIMIT 1];
            
            if (links.isEmpty()) {
                return scriptList; // Return empty list if no CSV found
            }
            
            // Get the ContentVersion for the latest CSV file
            ContentVersion csvFile = [SELECT VersionData, Title 
                                    FROM ContentVersion 
                                    WHERE ContentDocumentId = :links[0].ContentDocumentId
                                    AND IsLatest = true 
                                    LIMIT 1];
            
            if (csvFile != null && csvFile.VersionData != null) {
                // Convert the file content to string and handle BOM marker
                String fileContent = EncodingUtil.urlDecode(csvFile.VersionData.toString(), 'UTF-8');
                fileContent = fileContent.replace('\uFEFF', ''); // Remove BOM if present
                
                // Split into lines and handle different line endings
                List<String> lines = fileContent.split('\\r?\\n');
                
                // Validate header row
                if (lines.isEmpty() || !isValidHeader(lines[0])) {
                    throw new AuraHandledException('Invalid CSV format: Missing or invalid header row');
                }
                
                // Process each line (skip header)
                for (Integer i = 1; i < lines.size(); i++) {
                    String line = lines[i].trim();
                    if (String.isNotBlank(line)) {
                        try {
                            ScriptWrapper script = parseCSVLine(line, i);
                            if (script != null) {
                                scriptList.add(script);
                            }
                        } catch (Exception e) {
                            System.debug('Error parsing line ' + i + ': ' + e.getMessage());
                            continue; // Skip invalid lines
                        }
                    }
                }
                
                // Sort the list by order
                scriptList.sort();
            }
            
            return scriptList;
            
        } catch (QueryException qe) {
            throw new AuraHandledException('CSV file not found: ' + qe.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error processing CSV file: ' + e.getMessage());
        }
    }
    
    // Helper method to validate header row
    private static Boolean isValidHeader(String headerRow) {
        if (String.isBlank(headerRow)) return false;
        List<String> headers = headerRow.split(',');
        return headers.size() >= 3 && 
               headers[0].trim().equalsIgnoreCase('order') &&
               headers[1].trim().equalsIgnoreCase('scriptname') &&
               headers[2].trim().equalsIgnoreCase('scriptdata');
    }
    
    // Helper method to parse CSV line
    private static ScriptWrapper parseCSVLine(String line, Integer lineNumber) {
        if (String.isBlank(line)) return null;
        
        List<String> fields = line.split(',');
        if (fields.size() >= 3) {
            try {
                Integer order = Integer.valueOf(fields[0].trim());
                String scriptName = fields[1].trim();
                String scriptData = fields[2].trim();
                
                if (order <= 0) {
                    System.debug('Invalid order number on line ' + lineNumber);
                    return null;
                }
                
                return new ScriptWrapper(order, scriptName, scriptData);
            } catch (Exception e) {
                System.debug('Error parsing values on line ' + lineNumber + ': ' + e.getMessage());
                return null;
            }
        }
        return null;
    }
    
    // Implement compareTo method for the outer class (required by Comparable interface)
    public Integer compareTo(Object compareTo) {
        return 0; // Not used but required by the interface
    }
}