/**
 * Created by caijingxiao on 2017/7/27.
 */
package game.world.entity.npc.model
{
    import common.consts.SharedDef;

    import game.world.entity.base.model.FighterData;

    import tempest.data.obj.GuidObject;

    public class MonsterData extends FighterData
    {
        /**钟馗捉鬼--当前我的阵营数据*/
        public var zkzgMyCamp:uint;

        public function MonsterData()
        {
            super();
        }


        override public function init(guidObject:GuidObject):void
        {
            super.init(guidObject);
            zkzgMyCamp = guidObject.GetByte(SharedDef.UNIT_FIELD_MAP_TEMP_HP, 2);
        }
    }
}
