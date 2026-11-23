@IsTest
private class CustomerTierServiceTest {

    @IsTest
    static void closedWonInsertSetsGoldTier() {
        Account acc = new Account(Name = 'Tier Test Account');
        insert acc;

        Test.startTest();
        insert new Opportunity(
            Name = 'Big Deal',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 250000
        );
        Test.stopTest();

        Account result = [SELECT Customer_Tier__c, Total_Won_Amount__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Gold', result.Customer_Tier__c, 'Account should be Gold');
        Assert.areEqual(250000, result.Total_Won_Amount__c, 'Total won amount mismatch');
    }

    @IsTest
    static void getTierBoundaries() {
        Assert.areEqual('Bronze',   CustomerTierService.getTier(null));
        Assert.areEqual('Bronze',   CustomerTierService.getTier(49999));
        Assert.areEqual('Silver',   CustomerTierService.getTier(50000));
        Assert.areEqual('Gold',     CustomerTierService.getTier(200000));
        Assert.areEqual('Platinum', CustomerTierService.getTier(500000));
    }

    // TODO (US-101 pending): open opp moved to Closed Won (update path)
    // TODO (US-101 pending): won opp amount changed
    // TODO (US-101 pending): bulk test with 200 opportunities
    // TODO (US-101 pending): delete / undelete / re-parenting scenarios
}