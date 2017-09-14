/**
 * Created by caijingxiao on 2017/7/20.
 */
package game.world.entity.base.controller
{
    import easiest.managers.FrameManager;
    import easiest.utils.NameUtil;

    import flash.utils.getQualifiedClassName;

    import game.world.base.controller.BaseProcess;
    import game.world.base.model.GameWorldEvent;
    import game.world.battle.controller.AttackMonsterProcess;
    import game.world.entity.base.model.EntityModel;
    import game.world.entity.base.model.EntityMove;

    import tempest.enum.Status;

    public class MoveEntityProcess extends BaseProcess
    {
        public static const Event:String = NameUtil.getUnqualifiedClassName(MoveEntityProcess);

        public static function addEvent(guid:String):void
        {
            GameWorldEvent.addEventList(Event, guid);
        }

        public static function removeEvent(guid:String):void
        {
            GameWorldEvent.spliceEvent(Event, guid);
        }

        private var _preDiff:int;
        private var _preDiff2:int;

        public function MoveEntityProcess()
        {
            super(Event);
        }

        override public function complete():void
        {
        }

        override public function process():void
        {
            var count:int=1;
            if (_preDiff != 0)
            {
                count++;
            }
            if (_preDiff2 != 0)
            {
                count++;
            }
            var diff:Number=((FrameManager.deltaTime + _preDiff + _preDiff2) / count);
            _preDiff2=_preDiff;
            _preDiff=diff;

            var guidList:Array = getList();
            for (var i:int = 0; i < guidList.length; i++)
            {
                var guid:String = guidList[i];
                var move:EntityMove = EntityModel.getMove(guid);
                var entity:MovableEntity = EntityModel.getMovableEntity(guid);
                if (entity == null)
                    continue;
                entity.updateMove(diff, move);
                // 不在移动状态，从事件池中移除
                if (entity.data.status != Status.WALK)
                    GameWorldEvent.spliceEvent(Event, guid);
            }
        }
    }
}
