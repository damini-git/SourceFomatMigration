@IsTest
private class FindReplaceDemoTest {
    
    @IsTest
    static void testGetSupportEmail() {
        Test.startTest();
        
        String email = FindReplaceDemo.getSupportEmail();
        
        Test.stopTest();
        
        System.assertEquals(
            'support-dev@company.com',
            email
        );
    }
}