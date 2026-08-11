public with sharing class DTDetailController {

    public class FileInfo {
        @AuraEnabled public String name;
        @AuraEnabled public String title;
    }

    @AuraEnabled(cacheable=true)
    public static List<FileInfo> getUniqueFilesForRecord(Id recordId) {
        Map<String, FileInfo> uniqueFiles = new Map<String, FileInfo>();

        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ]) {
            if (!uniqueFiles.containsKey(link.ContentDocument.Title)) {
                FileInfo f = new FileInfo();
                f.name = link.ContentDocument.Title;
                f.title = link.ContentDocument.Title;
                uniqueFiles.put(f.name, f);
            }
        }
        return uniqueFiles.values();
    }

    @AuraEnabled(cacheable=true)
    public static String getMergedFileBodyByName(Id recordId, String fileName) {
        List<Id> documentIds = new List<Id>();

        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId AND ContentDocument.Title = :fileName
        ]) {
            documentIds.add(link.ContentDocumentId);
        }

        if (documentIds.isEmpty()) {
            return '';
        }

        String mergedText = '';

        for (ContentVersion ver : [
            SELECT VersionData, FileType
            FROM ContentVersion
            WHERE ContentDocumentId IN :documentIds
            ORDER BY VersionNumber ASC
        ]) {
            if (ver.FileType == 'CSV' || ver.FileType == 'TXT' || ver.FileType == 'PLAINTEXT') {
                String text = ver.VersionData.toString();
                mergedText += text + '\n';
            }
        }

        return mergedText;
    }
}