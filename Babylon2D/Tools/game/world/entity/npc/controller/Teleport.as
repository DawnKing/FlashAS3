/**
 * Created by caijingxiao on 2017/7/24.
 */
package game.world.entity.npc.controller
{
    import com.adobe.utils.StringUtil;

    import common.consts.ColorConst;
    import common.consts.MapConst;
    import common.consts.SharedDef;
    import common.data.Hero;
    import common.manager.MainCharWalkMgr;

    import flash.events.Event;
    import flash.geom.Point;

    import game.world.entity.base.controller.Entity;
    import game.world.entity.npc.model.TeleportData;
    import game.world.entity.npc.view.NpcAvatar;
    import game.world.entity.player.controller.SelfPlayer;
    import game.world.entity.player.model.SelfPlayerModel;

    import modules.scene.model.vo.MapRes;

    import tempest.core.ISceneCharacter;

    import tempest.data.map.WorldPostion;

    import tempest.data.map.point.Tb_point_teleport;

    import tempest.data.obj.GuidObject;

    public class Teleport extends Entity
    {
        public function Teleport()
        {
            super();
        }

        override protected function initialize():void
        {
            _data = new TeleportData();
            _avatar = new NpcAvatar(onClick);
        }

        override public function initData(guidObject:GuidObject):void
        {
            super.initData(guidObject);
        }

        override protected function setName(guidObject:GuidObject):void
        {
            teleportData.teleport = App.iscene.mapConfig.getTele(data.templateId);
            var name:String = teleportData.teleport.name;
            data.textName=StringUtil.format("[传送]-{0}", name.substring(name.lastIndexOf(",") + 1, name.length));
            data.name = name;
            data.nameColor = ColorConst.white3;
        }

        public function get teleportData():TeleportData
        {
            return _data as TeleportData;
        }

        override protected function onClick(event:Event):void
        {
            var mainChar:ISceneCharacter=App.mainChar;
            if (!mainChar || !mainChar.usable)
            {
                return;
            }
            var wpos:WorldPostion = data.worldPosition;
            var selfPlayer:SelfPlayer = SelfPlayerModel.getPlayer();
            if (selfPlayer.inDistance(wpos.tile, 5))
            {
                transport(true);
            }
            else //走进地图再传送
            {
                MainCharWalkMgr.walkTo(App.hero.currentMapid, wpos.tileX, wpos.tileY, 0, onMoveComplete, null, 3);
            }
        }

        private function onMoveComplete(p:Point=null):void
        {
            transport(true);
        }

        /**
         * 传送
         * @param isCheckPk 是否Pk状态可传送
         *
         */
        public function transport(isCheckPk:Boolean):void
        {
            var teleTemp:Tb_point_teleport = teleportData.teleport;
            var uguid:uint = data.uguid;
            var hero:Hero=App.hero;
            var map:MapRes=(App.staticData.getTempl(MapRes, teleTemp.to_map_id) as MapRes);
            if (!map.checkCanTransport(true, isCheckPk))
            {
                return;
            }
            else
            {
                if (teleTemp.to_map_id == MapConst.MAP_PIG_CAVE)
                {
                    //猪洞传送点
                    if (teleTemp.map_id != MapConst.MAP_PIG_CAVE)
                    {
                        App.netService.conn.instance_enter(teleTemp.to_map_id);
                    }
                    else
                    {
                        if (teleTemp.id == MapConst.MAP_PIG_CAVE_NEXT)
                        {
                            App.netService.conn.instance_next_state(App.mapObj.binlog.GetUInt32(SharedDef.MAP_INT_FIELD_PIG_CAVE_LEVEL) + 1, uguid);
                        }
                        else if (teleTemp.id == MapConst.MAP_PIG_CAVE_PREVIOUS)
                        {
                            App.netService.conn.instance_next_state(App.mapObj.binlog.GetUInt32(SharedDef.MAP_INT_FIELD_PIG_CAVE_LEVEL) - 1, uguid);
                        }
                    }
                }
                else
                {
                    App.netService.conn.use_gameobject(uguid);
                }
            }
        }
    }
}
