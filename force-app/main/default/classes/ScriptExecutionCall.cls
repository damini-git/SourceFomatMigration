public class ScriptExecutionCall {
    @AuraEnabled
    public static void executeScript(Id refTempId){
        database.executeBatch(new ScriptExecution(refTempId),1);
    }
}