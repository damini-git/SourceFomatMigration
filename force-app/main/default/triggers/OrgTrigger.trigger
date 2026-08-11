trigger OrgTrigger on Org__c (before update, before insert, before delete ,after insert, after update, after delete, after undelete) {
    OrgTriggerHandler handler = New OrgTriggerHandler();
    handler.manage();
}