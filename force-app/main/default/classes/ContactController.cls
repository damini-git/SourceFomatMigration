public with sharing class ContactController {
  /*  @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts() {
        return [SELECT FirstName, LastName, Email FROM Contact LIMIT 50];
    }*/

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts() {
        throw new AuraHandledException('This is a simulated Apex error.');
    }
}