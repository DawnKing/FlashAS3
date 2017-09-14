/**
 * Created by caijingxiao on 2017/7/19.
 */
package game.world.entity.base.controller
{
    import common.consts.SharedDef;
    import common.net.ObjectDef;

    import easiest.core.Log;
    import easiest.managers.ObjectPool;
    import easiest.utils.NameUtil;

    import game.scene.E2DScene;
    import game.world.base.controller.BaseProcess;
    import game.world.base.model.GameWorldEvent;
    import game.world.base.view.CharLayer;
    import game.world.entity.base.model.EntityModel;
    import game.world.entity.npc.controller.Collect;
    import game.world.entity.npc.controller.Monster;
    import game.world.entity.npc.controller.Npc;
    import game.world.entity.npc.controller.Teleport;
    import game.world.entity.player.controller.OtherPlayer;
    import game.world.entity.player.controller.SelfPlayer;
    import game.world.entity.player.model.SelfPlayerModel;
    import game.world.modules.shenshou.ShenShou;
    import game.world.modules.zhongkui.ZKMonster;

    import modules.scene.model.vo.MapTbCreature;

    import tempest.data.obj.GuidObject;
    import tempest.data.obj.GuidObjectTable;

    public class CreateEntityProcess extends BaseProcess
    {
        public static const Event:String = NameUtil.getUnqualifiedClassName(CreateEntityProcess);

        public static function addEvent(guid:String):void
        {
            GameWorldEvent.addEventList(Event, guid);
        }

        private var _charLayer:CharLayer;

        public function CreateEntityProcess(charLayer:CharLayer)
        {
            super(Event);
            _charLayer = charLayer;
        }

        override public function process():void
        {
            var guidList:Array = getList();
            var guidObjects:GuidObjectTable = E2DScene.guidObjectList;
            for (var i:int = 0; i < guidList.length; i++)
            {
                var guid:String = guidList[i];
                if (EntityModel.containers(guid))
                {
                    Log.error("已经存在对象" + guid, this);
                    continue;
                }
                var guidObject:GuidObject = guidObjects.Get(guid);
                if (guidObject == null)
                {
                    Log.error("创建对象失败" + guid, this);
                    continue;
                }
                var entity:Entity = null;
                var subType:int;
                var type:int = guidObject.GetByte(SharedDef.UNIT_FIELD_BYTE_0, 0);
                var templateId:uint = guidObject.GetUInt16(SharedDef.UNIT_FIELD_UINT16_0, 0);
                switch (type)
                {
                    case SharedDef.TYPEID_PLAYER:
                        if (ObjectDef.getSuffixFromGuid(guid) == SelfPlayerModel.guid)
                            entity = ObjectPool.get(SelfPlayer) as SelfPlayer;
                        else
                            entity = ObjectPool.get(OtherPlayer) as OtherPlayer;
                        entity.data.body=100002;
                        break;
                    case SharedDef.TYPEID_UNIT: // 生物精灵，如怪物，NPC,宝宝,机器人等。。。
                        subType=guidObject.GetByte(SharedDef.UNIT_FIELD_BYTE_0, 1);
                        switch (subType)
                        {
                            case SharedDef.UNIT_TYPE_MONSTER:
                                if(App.mapRes.type==SharedDef.MAP_TYPE_ZHONGKUIZHAOGUI)
                                {
                                    entity=ObjectPool.get(ZKMonster) as ZKMonster;
                                }
                                else
                                {
                                    var creatureTplt:MapTbCreature = App.staticData.getTempl(MapTbCreature, templateId);
                                    if (creatureTplt.ainame == "ai_shenshou")
                                        entity=ObjectPool.get(ShenShou) as ShenShou;
                                    else
                                        entity=ObjectPool.get(Monster) as Monster;
                                }
                                entity.data.body=119997;
                                break;
                            case SharedDef.UNIT_TYPE_NPC:
                                entity=ObjectPool.get(Npc) as Npc;
                                entity.data.body=120000;
                                break;
                            case SharedDef.UNIT_TYPE_PET:
                                entity=ObjectPool.get(Npc) as Npc;
                                entity.data.body=130000;
                                break;
                            default:
                                Log.error(type+"未定义对象"+subType, this);
                                break;
                        }
                        break;
                    case SharedDef.TYPEID_GAMEOBJECT: // 游戏对象精灵
                        subType=guidObject.GetUInt32(SharedDef.GO_FIELD_FLAGS);
                        if (subType & (1 << SharedDef.GO_FLAG_DYNAMIC)) // 是否动态对象,由不是由地图刷出来的
                        {
                            entity=ObjectPool.get(Collect) as Collect;
                            entity.data.body=5;
                        }
                        else if (subType & (1 << SharedDef.GO_FLAG_TELE)) // 是否传送点对象
                        {
                            entity=ObjectPool.get(Teleport) as Teleport;
                            entity.data.body=3000158;
                        }
                        else if (subType & (1 << SharedDef.GO_FLAG_QUEST)) // 是否任务对象
                        {
                            entity=ObjectPool.get(Collect) as Collect;
                            entity.data.body=6;
                        }
                        else if (subType & (1 << SharedDef.GO_FLAG_MATERIAL)) // 是否采集材料
                        {
                            entity=ObjectPool.get(Collect) as Collect;
                            entity.data.body=4;
                        }
                        else if (subType & (1 << SharedDef.GO_FLAG_SCRIPT)) // 是否任务对象
                        {
                            entity=ObjectPool.get(Collect) as Collect;
                            entity.data.body=7;
                        }
                        else
                        {
                            entity=ObjectPool.get(Collect) as Collect;
                            entity.data.body=8;
                        }
                        break;
                    default:
                        Log.error(type+"未定义对象"+subType, this);
                        break;
                }
                if (entity == null)
                    continue;
                entity.initData(guidObject);
                entity.initAvatar();
                EntityModel.addEntity(entity);
                _charLayer.addChild(entity.avatar);

                UpdateEntityProcess.addEvent(guid, this);
            }
        }
    }
}
