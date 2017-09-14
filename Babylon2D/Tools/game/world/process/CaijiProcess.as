/**
 * Created by caijingxiao on 2017/8/1.
 */
package game.world.process
{
    import easiest.utils.NameUtil;

    import flash.utils.getQualifiedClassName;

    import game.world.base.controller.BaseProcess;
    import game.world.base.model.GameWorldEvent;
    import game.world.entity.base.model.EntityModel;
    import game.world.entity.npc.controller.Collect;
    import game.world.entity.npc.model.CollectData;
    import game.world.entity.player.model.PlayerData;
    import game.world.entity.player.model.SelfPlayerModel;

    import tempest.enum.Status;

    public class CaijiProcess extends BaseProcess
    {
        public static const Event:String = NameUtil.getUnqualifiedClassName(CaijiProcess);
        private static var _isCollecting:Boolean;

        public static function addEvent(guid:String):void
        {
            GameWorldEvent.addEvent(Event, guid);
        }

        public static function stop():void
        {
            GameWorldEvent.removeEvent(Event);
            var selfPlayerData:PlayerData=SelfPlayerModel.getPlayer().playerData;
            selfPlayerData.status=Status.STAND;

            _isCollecting = false;
        }

        public function CaijiProcess()
        {
            super(Event);
        }

        override public function process():void
        {
            var guid:String = getParam() as String;
            var collect:Collect = EntityModel.getEntity(guid) as Collect;
            if (collect == null)
                return;
            var collectData:CollectData=collect.collectData;
            var selfPlayerData:PlayerData=SelfPlayerModel.getPlayer().playerData;
            selfPlayerData.direction=selfPlayerData.getTileDir(collectData.tileX, collectData.tileY);
            selfPlayerData.status=Status.CAIJI;
            EntityModel.removeMove(selfPlayerData.guid);

            _isCollecting = true;
        }

        override public function complete():void
        {
            // 不自动移除事件，使用stop移除
        }

        public static function get isCollecting():Boolean
        {
            return _isCollecting;
        }
    }
}
