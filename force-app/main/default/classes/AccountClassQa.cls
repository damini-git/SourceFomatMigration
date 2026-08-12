/**
 * Provides utility methods for creating Account records.
 */
public with sharing class AccountClassQa {

    @TestVisible
    private static Boolean testAccountCreateable = true;

    /**
     * Creates an Account record with the specified name.
     *
     * @param accountName Name of the Account to create.
     */
    public static void createAccount(String accountName) {
        if (String.isBlank(accountName)) {
            return;
        }

        Boolean accountCreateable = testAccountCreateable;

        if (!Test.isRunningTest()) {
            accountCreateable = Schema.sObjectType.Account.isCreateable();
        }

        if (!accountCreateable) {
            throw new SecurityException(
                'Insufficient permissions to create Account.'
            );
        }

        Account accountRecord = new Account(
            Name = accountName
        );

        insert accountRecord;
    }
}