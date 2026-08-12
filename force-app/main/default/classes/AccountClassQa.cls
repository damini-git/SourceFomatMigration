public with sharing class AccountClassQa {

    public static void createAccount(String accountName) {
        if (String.isBlank(accountName)) {
            return;
        }

        if (!Schema.sObjectType.Account.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Account.');
        }

        Account accountRecord = new Account();
        accountRecord.Name = accountName;

        insert accountRecord;
    }
}