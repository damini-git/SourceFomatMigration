/**
 * US-101: Collects the Accounts whose tier may have changed and
 * hands them to CustomerTierService.
 */
public with sharing class OpportunityTierTriggerHandler {

    public static void handleAfterInsert(List<Opportunity> newList) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newList) {
            if (opp.IsWon && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        CustomerTierService.recalculateTiers(accountIds);
    }

    public static void handleAfterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            Boolean wonStatusChanged = opp.IsWon != oldOpp.IsWon;
            Boolean wonAmountChanged = opp.IsWon && opp.Amount != oldOpp.Amount;

            if (wonStatusChanged || wonAmountChanged) {
                accountIds.add(opp.AccountId);
            }

            // TODO (US-101 pending): handle re-parenting.
            // If AccountId changes on a won Opportunity, the OLD Account
            // also needs recalculation (add oldOpp.AccountId).
        }
        CustomerTierService.recalculateTiers(accountIds);
    }

    // TODO (US-101 pending): handleAfterDelete(List<Opportunity> oldList)
    // TODO (US-101 pending): handleAfterUndelete(List<Opportunity> newList)
}