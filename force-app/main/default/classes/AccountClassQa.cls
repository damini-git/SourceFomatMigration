/**
 * Provides utility methods for creating Account records.
 */
public with sharing class AccountClassQa {

    /**
     * Creates an Account record with the specified name.
     *
     * @param accountName Name of the Account to create.
     */
    public static void createAccount(String accountName) {
        if (String.isBlank(accountName)) {
            return;
        }

        if (!Schema.sObjectType.Account.isCreateable()) {
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