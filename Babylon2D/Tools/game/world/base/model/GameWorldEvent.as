package game.world.base.model
{
    import easiest.core.Log;

    import flash.utils.Dictionary;

    import game.world.base.controller.GameWorld;

    /**
     * 游戏事件，存放所有事件信息和其对应的事件数据
     * @author caijingxiao
     * 
     */
    public final class GameWorldEvent
    {
        public static const VALUE:int = 0;
        public static const LIST:int = 1;
        private static var _eventList:Dictionary = new Dictionary(true);
        
        public static function clear():void
        {
            _eventList = new Dictionary(true);
        }
        
        public static function addEvent(event:String, param:Object=null):void
        {
            if (!GameWorld.start)
                return;
            _eventList[event] = param;
        }

        public static function addEventList(event:String, param:Object):void
        {
            if (!GameWorld.start)
                return;
            var list:Array = _eventList[event] == null ? [] : _eventList[event];
            if (list.indexOf(param) == -1)
                list.push(param);
            _eventList[event] = list;

            if (list.length > 300)
                Log.error("事件没删除   "+event);
        }

        public static function spliceEvent(event:String, guid:String):void
        {
            var list:Array = _eventList[event];
            if (list == null)
                return;
            var index:int = list.indexOf(guid);
            if (index != -1)
                list.splice(index, 1);

            if (list.length == 0)
                removeEvent(event);
        }
        
        public static function hasEvent(type:String):Boolean
        {
            return type in _eventList;
        }
        
        public static function removeEvent(type:String):void
        {
            delete _eventList[type];
        }
        
        public static function getParam(type:String):Object
        {
            return _eventList[type];
        }

        public static function get eventList():Dictionary
        {
            return _eventList;
        }
    }
}
