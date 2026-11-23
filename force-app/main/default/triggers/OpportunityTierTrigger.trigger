trigger OpportunityTierTrigger on Opportunity (after insert, after update) {
    // TODO (US-101 pending): add 'after delete, after undelete' events
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityTierTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            OpportunityTierTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}