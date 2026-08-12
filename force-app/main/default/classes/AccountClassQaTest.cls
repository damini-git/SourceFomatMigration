@IsTest
private class AccountClassQaTest {

    @IsTest
    static void testCreateAccount() {
        Test.startTest();
        AccountClassQa.createAccount('Test Account');
        Test.stopTest();

        Account accountRecord = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        System.assertEquals('Test Account', accountRecord.Name);
    }
}