@isTest
public class TestStringOperations {
   
    // Test the reverseString method with a normal string
static testMethod void testReverseString() {
        String original = 'hello';
        String expected = 'olleh';
        String result = StringOperations.reverseString(original);
        System.assertEquals(expected, result, 'The string should be reversed correctly.');
    }

    // Test the reverseString method with an empty string
static testMethod void testReverseEmptyString() {
        String original = '';
        String expected = '';
        String result = StringOperations.reverseString(original);
        System.assertEquals(expected, result, 'An empty string should return an empty string.');
    }

    // Test the reverseString method with null
static testMethod void testReverseNull() {
        String result = StringOperations.reverseString(null);
        System.assertEquals(null, result, 'Null input should return null.');
    }
}