/**
 * Created by caijingxiao on 2017/7/20.
 */
package game.world.entity.base.controller
{
    import easiest.utils.NameUtil;

    import flash.utils.getQualifiedClassName;

    import game.world.base.controller.BaseProcess;
    import game.world.base.model.GameWorldEvent;
    import game.world.entity.base.model.EntityModel;

    public class UpdateEntityProcess extends BaseProcess
    {
        public static const Event:String = NameUtil.getUnqualifiedClassName(UpdateEntityProcess);

        public static function addEvent(guid:String, stackTrace:Object):void
        {
            GameWorldEvent.addEventList(Event, guid);
        }

        public function UpdateEntityProcess()
        {
            super(Event);
        }

        override public function process():void
        {
            var guidList:Array = getList();
            for (var i:int = 0; i < guidList.length; i++)
            {
                var guid:String = guidList[i];
                var entity:Entity = EntityModel.getEntity(guid);
                if (entity == null)
                    continue;
                entity.updateData();
            }
        }
    }
}
