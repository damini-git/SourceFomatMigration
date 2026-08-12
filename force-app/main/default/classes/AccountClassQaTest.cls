@IsTest
private class AccountClassQaTest {

    /**
     * Tests Account creation through AccountClassQa.
     */
    @IsTest
    static void testCreateAccount() {
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
}