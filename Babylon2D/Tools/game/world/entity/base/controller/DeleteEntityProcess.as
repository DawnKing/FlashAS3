/**
 * Created by caijingxiao on 2017/7/26.
 */
package game.world.entity.base.controller
{
    import easiest.core.Log;
    import easiest.utils.NameUtil;

    import flash.utils.getQualifiedClassName;

    import game.world.base.controller.BaseProcess;
    import game.world.base.model.GameWorldEvent;
    import game.world.base.view.CharLayer;
    import game.world.entity.base.model.EntityModel;

    public class DeleteEntityProcess extends BaseProcess
    {
        public static const Event:String = NameUtil.getUnqualifiedClassName(DeleteEntityProcess);

        public static function addEvent(guid:String):void
        {
            GameWorldEvent.addEventList(Event, guid);
        }

        private var _charLayer:CharLayer;

        public function DeleteEntityProcess(charLayer:CharLayer)
        {
            super(Event);
            _charLayer = charLayer;
        }

        override public function process():void
        {
            var guidList:Array = getList();
            for (var i:int = 0; i < guidList.length; i++)
            {
                var guid:String = guidList[i];
                if (!EntityModel.containers(guid))
                {
                    Log.error("对象不存在" + guid, this);
                    continue;
                }
                var entity:Entity = EntityModel.getEntity(guid);
                _charLayer.removeChild(entity.avatar);
                EntityModel.removeEntity(guid);
            }
        }
    }
}
