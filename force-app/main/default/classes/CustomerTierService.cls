/**
 * US-101: Customer Tier on Account
 * Recalculates Total Won Amount and Customer Tier for a set of Accounts.
 */
public with sharing class CustomerTierService {

    // TODO (US-101 pending): move thresholds to Custom Metadata (Customer_Tier_Setting__mdt)
    // so business admins can change them without a deployment.
    private static final Decimal SILVER_MIN   = 50000;
    private static final Decimal GOLD_MIN     = 200000;
    private static final Decimal PLATINUM_MIN = 500000;

    public static void recalculateTiers(Set<Id> accountIds) {
        if (accountIds == null) {
            return;
        }
        accountIds.remove(null);
        if (accountIds.isEmpty()) {
            return;
        }

        // Start every Account at 0 so Accounts with no won deals drop back to Bronze
        Map<Id, Decimal> totalsByAccount = new Map<Id, Decimal>();
        for (Id accId : accountIds) {
            totalsByAccount.put(accId, 0);
        }

        for (AggregateResult ar : [
            SELECT AccountId accId, SUM(Amount) total
            FROM Opportunity
            WHERE AccountId IN :accountIds AND IsWon = true
            GROUP BY AccountId
        ]) {
            Decimal total = (Decimal) ar.get('total');
            totalsByAccount.put((Id) ar.get('accId'), total == null ? 0 : total);
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Id accId : totalsByAccount.keySet()) {
            Decimal total = totalsByAccount.get(accId);
            accountsToUpdate.add(new Account(
                Id = accId,
                Total_Won_Amount__c = total,
                Customer_Tier__c = getTier(total),
                Tier_Last_Updated__c = System.now()
            ));
        }

        // TODO (US-101 pending): use Database.update(list, false) and log failures
        update accountsToUpdate;
    }

    public static String getTier(Decimal total) {
        if (total == null) {
            return 'Bronze';
        }
        if (total >= PLATINUM_MIN) {
            return 'Platinum';
        }
        if (total >= GOLD_MIN) {
            return 'Gold';
        }
        if (total >= SILVER_MIN) {
            return 'Silver';
        }
        return 'Bronze';
    }
}