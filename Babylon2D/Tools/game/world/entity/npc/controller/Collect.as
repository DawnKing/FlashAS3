/**
 * Created by caijingxiao on 2017/7/28.
 */
package game.world.entity.npc.controller
{
    import common.events.GameEvent;
    import common.interfaces.ICollect;
    import common.template.Tb_gameobject;
    import common.util.translate;

    import flash.events.Event;
    import flash.geom.Point;

    import game.world.entity.base.controller.Entity;
    import game.world.entity.npc.model.CollectData;
    import game.world.entity.npc.view.CollectAvatar;

    import modules.scene.signal.SceneSignal;

    import tempest.data.obj.GuidObject;

    public class Collect extends Entity implements ICollect
    {
        public function Collect()
        {
            super();
        }

        override protected function initialize():void
        {
            _data = new CollectData();
            _avatar = new CollectAvatar(onClick);
        }

        override public function initData(guidObject:GuidObject):void
        {
            super.initData(guidObject);
            collectData.binPath = "images/dropitem/output/dropitem/dropitem";
            collectData.body = 4;
        }

        override public function update():void
        {
            // 不需要每帧更新
        }

        public function get collectData():CollectData
        {
            return _data as CollectData;
        }

        override protected function onClick(event:Event):void
        {
            GameEvent.dispatchEvent(SceneSignal.SCENE_COLLECT, this);
        }

        public function get collect_time():int
        {
            var tb_gameobject:Tb_gameobject=App.staticData.getTempl(Tb_gameobject, data.templateId);
            if (tb_gameobject)
                return tb_gameobject.collect_time;
            else
                return 10; //GetUInt32(SharedDef.GO_QUEST_GATHER_TIME);
        }

        public function get delay():Number
        {
            return collect_time;
        }

        public function get canCollect():Boolean
        {
            return true;
        }

        public function get tile():Point
        {
            return data.worldPosition.tile;
        }

        public function get mapId():int
        {
            return data.mapId;
        }

        public function get desc():String
        {
            return translate(415, "采集进度");
        }

        public function get canStop():Boolean
        {
            return true;
        }

        public function get playAction():Boolean
        {
            return false; //!(subflags & 1 << SharedDef.GO_FLAG_LOOT_BIND_DROP_ID); //的特殊采集物品不播放动作
        }

        public function collectBegin():void
        {
            App.netService.conn.use_gameobject_start(data.uguid); //发采集开始
        }

        public function collectEnd():void
        {
            App.netService.conn.use_gameobject(data.uguid);
        }
    }
}
