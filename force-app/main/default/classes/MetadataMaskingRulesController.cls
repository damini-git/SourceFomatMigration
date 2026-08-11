public with sharing class MetadataMaskingRulesController {

    public static String searchExecutionOrder;
    public static String suffixExecutionOrder;

    // Wrapper classes for rules (same as before)
    public class SearchRule {
        @AuraEnabled public String metadataType;
        @AuraEnabled public String maskingType;
        @AuraEnabled public String searchKey;
        @AuraEnabled public String replaceValue;
        @AuraEnabled public String executionorder;
        
        public SearchRule(String metadataType, String maskingType, String searchKey, String replaceValue) {
            this.metadataType = metadataType;
            this.maskingType = maskingType;
            this.searchKey = searchKey;
            this.replaceValue = replaceValue;
            this.executionorder = searchExecutionOrder;
        }
    }
    
    public class SuffixRule {
        @AuraEnabled public String metadataType;
        @AuraEnabled public String maskingType;
        @AuraEnabled public String suffixValue;
        @AuraEnabled public String executionorder;
        
        public SuffixRule(String metadataType, String maskingType, String suffixValue) {
            this.metadataType = metadataType;
            this.maskingType = maskingType;
            this.suffixValue = suffixValue;
            this.executionorder = suffixExecutionOrder;
        }
    }
    
    public class MetadataMaskingRulesWrapper {
        @AuraEnabled public List<SearchRule> searchRules;
        @AuraEnabled public List<SuffixRule> suffixRules;
        
        public MetadataMaskingRulesWrapper() {
            searchRules = new List<SearchRule>();
            suffixRules = new List<SuffixRule>();
        }
    }
    
    /**
     * Retrieves and parses all CSV files attached to the Refresh_Template__c record.
     * Matches files based on headers rather than filename.
     */
    @AuraEnabled(cacheable=false)
    public static MetadataMaskingRulesWrapper getMetadataMaskingRules(Id refreshTemplateId) {
        MetadataMaskingRulesWrapper wrapper = new MetadataMaskingRulesWrapper();
        
        try {
            // Query all ContentDocumentLinks for files attached to the record
            List<ContentDocumentLink> cdLinks = [SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title,
                                                ContentDocument.FileExtension
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId = :refreshTemplateId];
            
            if(cdLinks.isEmpty()) {
                // No files found
                return wrapper;
            }
            
            // Process each CSV file
            for(ContentDocumentLink cdLink : cdLinks) {
                // Skip if not a CSV file
                if(cdLink.ContentDocument.FileExtension != 'csv') {
                    continue;
                }
                
                // Get the content version
                List<ContentVersion> cvList = [
                    SELECT VersionData, Title, FileExtension 
                    FROM ContentVersion 
                    WHERE Id = :cdLink.ContentDocument.LatestPublishedVersionId
                    LIMIT 1
                ];
                
                if(!cvList.isEmpty()) {
                    try {
                        // Convert the Blob to a String
                        String csvContent = cvList[0].VersionData.toString();
                        
                        // Process the CSV content and identify the file type based on headers
                        MetadataMaskingRulesWrapper tempWrapper = parseAndIdentifyCsv(csvContent);
                        
                        // Merge the results
                        if(tempWrapper.searchRules != null && !tempWrapper.searchRules.isEmpty()) {
                            wrapper.searchRules.addAll(tempWrapper.searchRules);
                        }
                        if(tempWrapper.suffixRules != null && !tempWrapper.suffixRules.isEmpty()) {
                            wrapper.suffixRules.addAll(tempWrapper.suffixRules);
                        }
                    } catch(Exception e) {
                        System.debug('Error processing CSV file ' + cvList[0].Title + ': ' + e.getMessage());
                        // Continue to the next file instead of failing completely
                    }
                }
            }
        } catch(Exception e) {
            System.debug('Error in getMetadataMaskingRules: ' + e.getMessage());
            // We'll just return an empty wrapper on error
        }
        
        return wrapper;
    }
    
    /**
     * Parses CSV content and identifies whether it's a Search Rules or Suffix Rules file
     * based on the headers
     */
    private static MetadataMaskingRulesWrapper parseAndIdentifyCsv(String csvContent) {
        MetadataMaskingRulesWrapper wrapper = new MetadataMaskingRulesWrapper();
        
        List<String> lines = csvContent.split('\n');
        if(lines.isEmpty()) {
            return wrapper;
        }
        
        // Find header line (assumed to be the first non-blank line)
        Integer headerIndex = 0;
        while(headerIndex < lines.size() && String.isBlank(lines[headerIndex].trim())) {
            headerIndex++;
        }
        if(headerIndex >= lines.size()) {
            return wrapper;
        }
        
        // Read header line
        String headerLine = lines[headerIndex].trim();
        List<String> headers = parseCSVLine(headerLine);
        
        // Normalize headers to handle case sensitivity and whitespace
        List<String> normalizedHeaders = new List<String>();
        for(String header : headers) {
            normalizedHeaders.add(header.trim().toLowerCase());
        }
        
        // Determine file type based on headers
        Boolean isSearchRulesFile = false;
        Boolean isSuffixRulesFile = false;
        
        // Check for all required headers for Search Rules
        if(normalizedHeaders.contains('metadata type') && 
           normalizedHeaders.contains('masking type') && 
           normalizedHeaders.contains('search key') && 
           normalizedHeaders.contains('replace value')) {
            isSearchRulesFile = true;
        }
        
        // Check for all required headers for Suffix Rules
        if(normalizedHeaders.contains('metadata type') && 
           normalizedHeaders.contains('masking type') && 
           normalizedHeaders.contains('suffix value')) {
            isSuffixRulesFile = true;
        }
        
        // If we can't determine the file type from headers, return empty
        if(!isSearchRulesFile && !isSuffixRulesFile) {
            return wrapper;
        }
        
        // Map header positions
        Map<String, Integer> headerMap = new Map<String, Integer>();
        for(Integer i = 0; i < normalizedHeaders.size(); i++) {
            headerMap.put(normalizedHeaders[i], i);
        }
        
        // Process the remaining rows
        for (Integer i = headerIndex + 1; i < lines.size(); i++) {
            String line = lines[i].trim();
            if(String.isBlank(line)) {
                continue;
            }
            
            try {
                List<String> cols = parseCSVLine(line);
                if(cols.size() < 2) {
                    continue;
                }
                
                // Get values using header positions to handle different column orders
                String metadataType = headerMap.containsKey('metadata type') && cols.size() > headerMap.get('metadata type') ? 
                                    cols[headerMap.get('metadata type')] : '';
                String maskingType = headerMap.containsKey('masking type') && cols.size() > headerMap.get('masking type') ? 
                                    cols[headerMap.get('masking type')] : '';
                
                // Skip row if required fields are missing
                if(String.isBlank(metadataType) || String.isBlank(maskingType)) {
                    continue;
                }
                system.debug('headerMap :: '+headerMap);
                system.debug('cols :: '+cols);
                // Process as Search & Replace rule
                if(isSearchRulesFile && maskingType.equalsIgnoreCase('Search & Replace')) {
                    //searchExecutionOrder = cols[headerMap.get('execution order')];
                    String searchKey = headerMap.containsKey('search key') && cols.size() > headerMap.get('search key') ? 
                                    cols[headerMap.get('search key')] : '';
                    String replaceValue = headerMap.containsKey('replace value') && cols.size() > headerMap.get('replace value') ? 
                                        cols[headerMap.get('replace value')] : '';
                    
                    wrapper.searchRules.add(new SearchRule(metadataType, maskingType, searchKey, replaceValue));
                }
                // Process as Suffix rule
                else if(isSuffixRulesFile && maskingType.equalsIgnoreCase('Suffix')) {
                    //suffixExecutionOrder = cols[headerMap.get('execution order')];
                    String suffixValue = headerMap.containsKey('suffix value') && cols.size() > headerMap.get('suffix value') ? 
                                        cols[headerMap.get('suffix value')] : '';
                    
                    wrapper.suffixRules.add(new SuffixRule(metadataType, maskingType, suffixValue));
                }
            } catch(Exception e) {
                System.debug('Error processing CSV line ' + i + ': ' + e.getMessage());
                // Continue to next line instead of failing
            }
        }
        
        return wrapper;
    }
    
    /**
     * A CSV file upload and parsing method for Search Rules
     */
    @AuraEnabled
    public static String uploadSearchRulesCSV(Id refreshTemplateId, String csvContent) {
        try {
            if(String.isBlank(csvContent)) {
                return 'Error: Empty file content';
            }
            
            // First, validate the CSV has the proper headers
            List<String> lines = csvContent.split('\n');
            if(lines.isEmpty()) {
                return 'Error: File is empty';
            }
            
            String headerLine = lines[0].trim();
            List<String> headers = parseCSVLine(headerLine);
            List<String> normalizedHeaders = new List<String>();
            for(String header : headers) {
                normalizedHeaders.add(header.trim().toLowerCase());
            }
            
            // Verify required headers
            Boolean hasRequiredHeaders = 
                normalizedHeaders.contains('metadata type') && 
                normalizedHeaders.contains('masking type') && 
                normalizedHeaders.contains('search key') && 
                normalizedHeaders.contains('replace value');
                
            if(!hasRequiredHeaders) {
                return 'Error: CSV does not have the required headers (Metadata Type, Masking Type, Search Key, Replace Value)';
            }
            
            // Parse the CSV to extract rules
            MetadataMaskingRulesWrapper wrapper = parseAndIdentifyCsv(csvContent);
            
            // Skip if no valid search rules were found
            if(wrapper.searchRules == null || wrapper.searchRules.isEmpty()) {
                return 'No valid Search Rules found in the CSV file';
            }
            
            // Create a new ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Search_Rules_' + System.now().format('yyyy-MM-dd_HH-mm-ss') + '.csv';
            cv.PathOnClient = cv.Title;
            cv.VersionData = Blob.valueOf(csvContent);
            cv.IsMajorVersion = true;
            
            insert cv;
            
            // Get the ContentDocument Id
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            
            // Create a new ContentDocumentLink
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = refreshTemplateId;
            cdl.ContentDocumentId = contentDocumentId;
            cdl.ShareType = 'V'; // Viewer permission
            cdl.Visibility = 'AllUsers';
            
            insert cdl;
            
            return 'Successfully uploaded ' + wrapper.searchRules.size() + ' search rules';
        } catch(Exception e) {
            System.debug('Error in uploadSearchRulesCSV: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return 'Error: ' + e.getMessage();
        }
    }
    
    /**
     * A CSV file upload and parsing method for Suffix Rules
     */
    @AuraEnabled
    public static String uploadSuffixRulesCSV(Id refreshTemplateId, String csvContent) {
        try {
            if(String.isBlank(csvContent)) {
                return 'Error: Empty file content';
            }
            
            // First, validate the CSV has the proper headers
            List<String> lines = csvContent.split('\n');
            if(lines.isEmpty()) {
                return 'Error: File is empty';
            }
            
            String headerLine = lines[0].trim();
            List<String> headers = parseCSVLine(headerLine);
            List<String> normalizedHeaders = new List<String>();
            for(String header : headers) {
                normalizedHeaders.add(header.trim().toLowerCase());
            }
            
            // Verify required headers
            Boolean hasRequiredHeaders = 
                normalizedHeaders.contains('metadata type') && 
                normalizedHeaders.contains('masking type') && 
                normalizedHeaders.contains('suffix value');
                
            if(!hasRequiredHeaders) {
                return 'Error: CSV does not have the required headers (Metadata Type, Masking Type, Suffix Value)';
            }
            
            // Parse the CSV to extract rules
            MetadataMaskingRulesWrapper wrapper = parseAndIdentifyCsv(csvContent);
            
            // Skip if no valid suffix rules were found
            if(wrapper.suffixRules == null || wrapper.suffixRules.isEmpty()) {
                return 'No valid Suffix Rules found in the CSV file';
            }
            
            // Create a new ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Suffix_Rules_' + System.now().format('yyyy-MM-dd_HH-mm-ss') + '.csv';
            cv.PathOnClient = cv.Title;
            cv.VersionData = Blob.valueOf(csvContent);
            cv.IsMajorVersion = true;
            
            insert cv;
            
            // Get the ContentDocument Id
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            
            // Create a new ContentDocumentLink
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = refreshTemplateId;
            cdl.ContentDocumentId = contentDocumentId;
            cdl.ShareType = 'V'; // Viewer permission
            cdl.Visibility = 'AllUsers';
            
            insert cdl;
            
            return 'Successfully uploaded ' + wrapper.suffixRules.size() + ' suffix rules';
        } catch(Exception e) {
            System.debug('Error in uploadSuffixRulesCSV: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return 'Error: ' + e.getMessage();
        }
    }
    
    /**
     * A basic CSV line parser. Adjust if your CSV uses different quoting or delimiters.
     */
    private static List<String> parseCSVLine(String line) {
        List<String> result = new List<String>();
        Boolean inQuotes = false;
        String value = '';
        
        for(Integer i = 0; i < line.length(); i++) {
            String c = line.substring(i, i+1);
            if(c == '"') {
                inQuotes = !inQuotes;
            } else if(c == ',' && !inQuotes) {
                result.add(value.trim());
                value = '';
            } else {
                value += c;
            }
        }
        result.add(value.trim());
        return result;
    }
}