@IsTest
public class EnvVariableClassTest {
    
    @IsTest
    static void testGetUserEmail() {
        Test.startTest();
        
        String email = EnvVariableClass.testUserEmail();
        
        Test.stopTest();
        
        System.assertEquals(
            'testuser.source@example.com',
            email,
            'The user email should match the expected source email.'
        );
    }
}