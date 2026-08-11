public class OrgTriggerHandler extends TriggerHandlerBase {
    public OrgTriggerHandler(){
        ConvertTimeZoneToUser cTI = New ConvertTimeZoneToUser();
        OrgLastRunNextRunUpdate oLU = new OrgLastRunNextRunUpdate();
        OrgLastRunNextRunInsert oLI = new OrgLastRunNextRunInsert();
        RSSCreationHandler rss = New RSSCreationHandler();
       // AuditLogDataSync au = New AuditLogDataSync();
       // bind(Evt.afterinsert,au).bind(Evt.afterUpdate,au);
        bind(Evt.beforeinsert, cTI).bind(Evt.beforeinsert,oLI);
        bind(Evt.beforeupdate, cTI).bind(Evt.beforeupdate,oLU);
        bind(Evt.afterupdate,rss);
        
        //bind(Evt.beforeupdate,oLU);
        
        //bind(Evt.beforeInsert,oLI);
        
    }
}