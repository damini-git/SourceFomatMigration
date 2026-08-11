public abstract class TriggerHandlerBase {
    public TriggerHandlerBase(){}
    
    public enum Evt 
    {
        afterdelete, afterinsert, afterundelete,
        afterupdate, beforedelete, beforeinsert, beforeupdate   
    }
        
    public interface TriggerHandler{
        void handle();
        }
    
    Map<String, List<TriggerHandler>> eventHandlerMaps = New Map<String, List<TriggerHandler>>();
    
    public TriggerHandlerBase bind( Evt evet , TriggerHandler hand){
    	List<TriggerHandler> handler =  eventHandlerMaps.get(evet.Name());
        if (handler == null){
            handler = New List<TriggerHandler>();
            eventHandlerMaps.put(evet.Name(),handler);
        }
        handler.add(hand);
        return this;
    }
    
    public void manage(){
        Evt even = null;
        if(Trigger.isInsert && Trigger.isBefore)
        {
            even = Evt.beforeinsert;
        }
        else if(Trigger.isInsert && Trigger.isAfter)
        {
            even = Evt.afterinsert;
        }
        else if(Trigger.isUpdate && Trigger.isBefore)
        {
            even = Evt.beforeupdate;
        }
        else if(Trigger.isUpdate && Trigger.isAfter)
        {
            even = Evt.afterupdate;
        }
        else if(Trigger.isDelete && Trigger.isBefore)
        {
            even = Evt.beforedelete;
        }
        else if(Trigger.isDelete && Trigger.isAfter)
        {
            even = Evt.afterdelete;
        }
        else if(Trigger.isundelete)
        {
            even = Evt.afterundelete;             
        }
        List<TriggerHandler> handler = eventHandlerMaps.get(even.Name());
        if(handler != null && !handler.isEmpty()){
            for (TriggerHandler h : handler){
                h.handle();
            }
        }
    }
}