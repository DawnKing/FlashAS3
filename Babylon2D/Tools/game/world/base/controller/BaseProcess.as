/**
 * Created by caijingxiao on 2017/7/17.
 */
package game.world.base.controller
{
    import game.world.base.model.GameWorldEvent;

    public class BaseProcess
    {
        private var _event:String;

        public function BaseProcess(event:String)
        {
            _event = event;
        }

        public function isProcess():Boolean
        {
            return GameWorldEvent.hasEvent(_event);
        }

        public function getParam():Object
        {
            return GameWorldEvent.getParam(_event);
        }

        public function getList():Array
        {
            return GameWorldEvent.getParam(_event) as Array;
        }

        public function complete():void
        {
            GameWorldEvent.removeEvent(_event);
        }

        public function process():void
        {
        }
    }
}
