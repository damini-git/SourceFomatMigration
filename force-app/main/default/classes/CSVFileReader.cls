public with sharing class CSVFileReader {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> readCSVFromRelatedFiles(Id recordId) {
        List<Map<String, Object>> fileData = new List<Map<String, Object>>();
        List<String> skippedFiles = new List<String>(); // Track skipped files
        
        // Query for the related ContentDocuments
        List<ContentDocumentLink> contentLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];
        
        // Get the ContentDocumentIds
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : contentLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }
        
        // Query ContentDocuments and retrieve the filenames
        List<ContentDocument> documents = [
            SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIds
        ];
        
        // Define the partial filenames to exclude
        Set<String> excludedFileNames = new Set<String>{
            'User Data - Export - JSON', 
                'Scheduled Jobs', 
                'packageXml',
                'metadata.zip'
                };
                    
                    System.debug('Total files found: ' + documents.size());
        
        for (ContentDocument document : documents) {
            // Retrieve the file name
            String fileName = document.Title;
            
            // Log file name for debugging
            System.debug('Processing file: ' + fileName);
            
            // Check if the filename starts with the excluded names
            Boolean excludeFile = false;
            for (String excludedName : excludedFileNames) {
                if (fileName.startsWith(excludedName)) {
                    excludeFile = true;
                    skippedFiles.add(fileName + ' (matched pattern: ' + excludedName + ')');
                    System.debug('Skipping file: ' + fileName + ' - Matches excluded pattern: ' + excludedName);
                    break;
                }
            }
            
            // If the file name starts with an excluded name, skip it
            if (excludeFile) {
                continue; // Skip processing this file
            }
            
            try {
                // Fetch the content of the CSV file (ContentVersion)
                List<ContentVersion> versions = [
                    SELECT VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId = :document.Id
                    ORDER BY CreatedDate DESC LIMIT 1
                ];
                
                if (!versions.isEmpty()) {
                    ContentVersion version = versions[0];
                    String csvContent = version.VersionData.toString();
                    
                    // Create a map to return the data
                    Map<String, Object> fileDetails = new Map<String, Object>();
                    fileDetails.put('filename', fileName);
                    fileDetails.put('content', csvContent);
                    
                    fileData.add(fileDetails);
                    System.debug('Successfully processed file: ' + fileName);
                } else {
                    skippedFiles.add(fileName + ' (no versions found)');
                    System.debug('Skipping file: ' + fileName + ' - No versions found');
                }
            } catch (Exception e) {
                skippedFiles.add(fileName + ' (error: ' + e.getMessage() + ')');
                System.debug('Error processing file: ' + fileName + ' - ' + e.getMessage());
            }
        }
        
        // Log summary
        System.debug('Total files processed: ' + fileData.size());
        System.debug('Total files skipped: ' + skippedFiles.size());
        System.debug('Skipped files list: ' + skippedFiles);
        System.debug('Successfully processed files: ' + fileData);
        
        return fileData;
    }
    
    // New method to pass CSV data for schedule jobs only
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getScheduleJobCSVData(Id recordId) {
        List<Map<String, Object>> scheduleJobData = new List<Map<String, Object>>();
        
        // Query for the related ContentDocuments
        List<ContentDocumentLink> contentLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];
        
        // Get the ContentDocumentIds
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : contentLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }
        
        // Query ContentDocuments and retrieve the filenames
        List<ContentDocument> documents = [
            SELECT Id, Title 
            FROM ContentDocument 
            WHERE Id IN :contentDocumentIds
        ];
        
        // Iterate through the documents
        for (ContentDocument document : documents) {
            String fileName = document.Title;
            
            // Check if the filename contains 'Scheduled Jobs'
            if (fileName != null && fileName.contains('Scheduled Jobs')) {
                // Fetch the content of the CSV file (ContentVersion)
                List<ContentVersion> versions = [
                    SELECT VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId = :document.Id
                    ORDER BY CreatedDate DESC LIMIT 1
                ];
                
                if (!versions.isEmpty()) {
                    ContentVersion version = versions[0];
                    String csvContent = version.VersionData.toString();
                    
                    // Parse the CSV content for schedule job data
                    List<Map<String, Object>> parsedCSV = parseScheduleJobCSV(csvContent);
                    
                    // Add the parsed data to the schedule job data list
                    scheduleJobData.addAll(parsedCSV);
                }
            }
        }
        
        // Log the number of records found
        System.debug('Schedule Job Data Count: ' + scheduleJobData.size());
        
        return scheduleJobData;
    }
    
    // The parseScheduleJobCSV method remains the same as in the original code
    private static List<Map<String, Object>> parseScheduleJobCSV(String csvContent) {
        List<Map<String, Object>> parsedData = new List<Map<String, Object>>();
        
        // Split the CSV content into rows based on newline
        List<String> rows = csvContent.split('\n');
        
        // Log the CSV content for debugging
        System.debug('CSV Content: ' + csvContent);
        
        // Get the headers (first row)
        List<String> headers = rows.isEmpty() ? new List<String>() : rows[0].split(',');
        
        // Log the headers for debugging
        System.debug('CSV Headers: ' + headers);
        
        // Process each subsequent row as a schedule job
        for (Integer i = 1; i < rows.size(); i++) {
            String row = rows[i];
            if (String.isBlank(row)) continue; // Skip empty rows
            
            // Split the row into columns (accounting for potential extra commas)
            List<String> columns = row.split(',');
            
            // Log row data for debugging
            System.debug('CSV Row Data: ' + columns);
            
            // Map each column value to the corresponding header
            if (columns.size() >= 4) {
                Map<String, Object> scheduleJob = new Map<String, Object>();
                scheduleJob.put('name', columns[0].trim()); // Job Name
                scheduleJob.put('type', columns[1].trim()); // Job Type
                scheduleJob.put('class', columns[2].trim()); // Apex Class
                scheduleJob.put('cron', columns[3].trim()); // Cron Expression
                
                parsedData.add(scheduleJob);
            }
        }
        
        // Log the parsed data count for debugging
        System.debug('Parsed Data Count: ' + parsedData.size());
        
        return parsedData;
    }
    
    @AuraEnabled
    public static List<String> fetchCustomSettings(Id recordId){
        List<String> customSettingsAttached = new List<String>();
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];
        
        for (ContentDocumentLink link : contentDocumentLinks) {
            if(link.ContentDocument.Title.contains('__c')){
            String fileName = link.ContentDocument.Title;
            customSettingsAttached.add(fileName);
            }
        }
        system.debug('customSettingsAttached --- ' + customSettingsAttached);
        return customSettingsAttached;
    }
    
    @AuraEnabled
    public static List<Refresh_Template__c> fetchCreatedDate1(Id recordId) {
        System.debug('Fetching Created Date for recordId: ' + recordId);
        
        List<Refresh_Template__c> results = [
            SELECT Id, CreatedDate 
            FROM Refresh_Template__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        
        System.debug('Query results: ' + JSON.serialize(results));
        return results;
    }    
    
    
    @AuraEnabled
    public static Map<String, List<ContentDocumentWrapper>> fetchCreatedDate(Id recordId) {
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocument.Id, ContentDocument.Title, 
            ContentDocument.FileType, ContentDocument.LastModifiedDate,
            ContentDocument.FileExtension
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :recordId
        ];
        
        Map<String, List<ContentDocumentWrapper>> fileMap = new Map<String, List<ContentDocumentWrapper>>();
        
        for(ContentDocumentLink cdl : docLinks) {
            ContentDocument doc = cdl.ContentDocument;
            ContentDocumentWrapper wrapper = new ContentDocumentWrapper(
                doc.Id, 
                doc.Title, 
                doc.LastModifiedDate
            );
            
            // Handle User Data - Export - JSON file
            if(doc.Title.containsIgnoreCase('User Data - Export - JSON')) {
                if(!fileMap.containsKey('users')) {
                    fileMap.put('users', new List<ContentDocumentWrapper>());
                }
                fileMap.get('users').add(wrapper);
            }
            // Handle Scheduled Jobs file
            else if(doc.Title.containsIgnoreCase('Scheduled Jobs')) {
                if(!fileMap.containsKey('schedule')) {
                    fileMap.put('schedule', new List<ContentDocumentWrapper>());
                }
                fileMap.get('schedule').add(wrapper);
            }
            // All other CSV files are treated as custom settings
            else if(doc.FileExtension.equalsIgnoreCase('csv')) {
                if(!fileMap.containsKey('settings')) {
                    fileMap.put('settings', new List<ContentDocumentWrapper>());
                }
                fileMap.get('settings').add(wrapper);
            }
        }
        
        return fileMap;
    }
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<Refresh_Template__c> fetchTargetOrgSandbox(Id recordId) {
        // Fetch the Refresh_Template record by Id and get the Target_Refresh_Org__c and Last_Refreshed_Date__c
        List<Refresh_Template__c> results = [
            SELECT Id, Target_Refresh_Org__c,CreatedDate
            FROM Refresh_Template__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        System.debug('Fetched Refresh_Template record: ' + results);
        
        if (results.size() > 0) {
            String targetOrgName = results[0].Target_Refresh_Org__c;  // Name of the Target Org (not an Id)
            //DateTime lastRefreshedDate = results[0].Last_Refreshed_Date__c; // Extract the DateTime
            
            System.debug('Target Org Name from Refresh_Template: ' + targetOrgName);
            
            // Query the Org__c records based on the name from Target_Refresh_Org__c
            List<Org__c> targetOrgRecords = [
                SELECT Id, Name
                FROM Org__c
                WHERE Name = :targetOrgName
                LIMIT 1
            ];
            
            System.debug('Fetched Org__c records based on Target Org Name: ' + targetOrgRecords);
            
            if (targetOrgRecords.size() > 0) {
                // Create a result record
                Refresh_Template__c result = new Refresh_Template__c();
                result.Target_Refresh_Org__c = targetOrgRecords[0].Id;  // Org ID
                result.Name = targetOrgRecords[0].Name; // Org Name
                
                // Only set Last_Refreshed_Date__c if it is not null
                /* if (lastRefreshedDate != null) {
result.Last_Refreshed_Date__c = lastRefreshedDate; // Retain DateTime as is
}*/
                
                return new List<Refresh_Template__c> { result };
                    } else {
                        System.debug('No Org__c record found for Target Org Name: ' + targetOrgName);
                    }
        } else {
            System.debug('No Refresh_Template record found for Id: ' + recordId);
        }
        
        return new List<Refresh_Template__c>(); // Return empty if no match
    }
    
    private static final String USER_DATA_FILE = 'User Data - Export - JSON';
    private static final String SCHEDULED_JOBS_FILE = 'Scheduled Jobs';
    
    @AuraEnabled(cacheable=true)
    public static boolean checkDataRetrievalStatus(Id templateId) {
        try {
            // Get the template record with all checkbox fields
            Refresh_Template__c refTemp = [
                SELECT Id, Custom_Setting_Names__c, Is_User_Data_Selected__c, 
                Is_Scheduled_Jobs_Selected__c, Is_Metadata_Selected__c 
                FROM Refresh_template__c 
                WHERE Id = :templateId
            ];
            
            // Get all attached files
            List<String> attachedFiles = new List<String>();
            for(ContentDocumentLink link : [
                SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :templateId
            ]) {
                attachedFiles.add(link.ContentDocument.Title.replaceAll('__c\\([^\\)]*\\)', '__c'));
            }
            System.debug('Attached Files: ' + attachedFiles);
            
            Boolean allPresent = true;
            
            // 1. Check User Data only if selected
            if(refTemp.Is_User_Data_Selected__c) {
                System.debug('Checking User Data file...');
                if(!attachedFiles.contains(USER_DATA_FILE)) {
                    System.debug('User Data file missing');
                    allPresent = false;
                }
            }
            
            // 2. Check Scheduled Jobs only if selected
            if(refTemp.Is_Scheduled_Jobs_Selected__c) {
                System.debug('Checking Scheduled Jobs file...');
                if(!attachedFiles.contains(SCHEDULED_JOBS_FILE)) {
                    System.debug('Scheduled Jobs file missing');
                    allPresent = false;
                }
            }
            
            // 3. Check Custom Settings only if values exist
            if(String.isNotBlank(refTemp.Custom_Setting_Names__c)) {
                List<String> requiredSettings = refTemp.Custom_Setting_Names__c.split(',');
                system.debug('requiredSettings size --- ' + requiredSettings.size());
                for(String setting : requiredSettings) {
                    String trimmedSetting = setting.trim();
                    system.debug('attachedFiles --- ' + attachedFiles);
                    if(!attachedFiles.contains(trimmedSetting)) {
                        System.debug('Custom Setting file missing: ' + trimmedSetting);
                        allPresent = false;
                        break;
                    }
                }
            }
            
            // 4. Check Metadata only if selected
            if(refTemp.Is_Metadata_Selected__c) {
                System.debug('Checking Metadata ZIP...');
                List<Attachment> metadataZip = [
                    SELECT Id 
                    FROM Attachment 
                    WHERE ParentId = :templateId
                    AND Name LIKE '%.zip'
                    LIMIT 1
                ];
                
                if(metadataZip.isEmpty()) {
                    System.debug('Metadata ZIP file missing');
                    allPresent = false;
                }
            }
            
            System.debug('Final check result: ' + allPresent);
            return allPresent;
            
        } catch(Exception e) {
            System.debug('Error in checkDataRetrievalStatus: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return false;
        }
    }
    
    public class ContentDocumentWrapper {
        @AuraEnabled public Id docId;
        @AuraEnabled public String title;
        @AuraEnabled public DateTime lastModifiedDate;
        
        public ContentDocumentWrapper(Id docId, String title, DateTime lastModifiedDate) {
            this.docId = docId;
            this.title = title;
            this.lastModifiedDate = lastModifiedDate;
        }
    }
    
}