@IsTest
private class AccountClassQaTest {

    /**
     * Tests successful Account creation.
     */
    @IsTest
    static void testCreateAccount() {
        Test.startTest();

        AccountClassQa.createAccount('Test Account');

        Test.stopTest();

        Account createdAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        System.assertEquals(
            'Test Account',
            createdAccount.Name,
            'The Account should be created successfully.'
        );
    }

    /**
     * Tests that no Account is created when the account name is blank.
     */
    @IsTest
    static void testCreateAccountWithBlankName() {
        Test.startTest();

        AccountClassQa.createAccount('');

        Test.stopTest();

        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name = ''
        ];

        System.assertEquals(
            0,
            accounts.size(),
            'No Account should be created when the name is blank.'
        );
    }

    /**
     * Tests the security exception when Account creation is not permitted.
     */
    @IsTest
    static void testCreateAccountWithoutCreatePermission() {
        AccountClassQa.testAccountCreateable = false;

        Test.startTest();

        try {
            AccountClassQa.createAccount('Unauthorized Account');

            System.assert(
                false,
                'A SecurityException should have been thrown.'
            );
        } catch (SecurityException securityError) {
            System.assertEquals(
                'Insufficient permissions to create Account.',
                securityError.getMessage(),
                'The expected security exception should be thrown.'
            );
        } finally {
            AccountClassQa.testAccountCreateable = true;
        }

        Test.stopTest();
    }
}