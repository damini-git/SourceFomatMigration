@IsTest
private class AccountClassQaTest {

    /**
     * Tests successful  Account creation.
     */
    @IsTest
    static void testCreateAccount() {
        User testUser = createTestUser();

        System.runAs(testUser) {
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
    }

    /**
     * Tests that no Account is created when the name is blank.
     */
    @IsTest
    static void testCreateAccountWithBlankName() {
        User testUser = createTestUser();

        System.runAs(testUser) {
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
    }

    /**
     * Creates a test user for runAs testing.
     *
     * @return A test user.
     */
    private static User createTestUser() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        String uniqueUserName =
            'standarduser' +
            DateTime.now().getTime() +
            '@testorg.com';

        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );

        insert testUser;

        return testUser;
    }
}