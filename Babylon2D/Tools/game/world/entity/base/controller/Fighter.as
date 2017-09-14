/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.base.controller
{
    import common.consts.SharedDef;

    import game.world.entity.base.model.FighterData;

    import tempest.data.obj.GuidObject;

    public class Fighter extends MovableEntity
    {
        public function Fighter()
        {
            super();
        }

        override public function initData(guidObject:GuidObject):void
        {
            super.initData(guidObject);

            fighterData.hp = guidObject.GetUInt32(SharedDef.UNIT_FIELD_HEALTH);
            fighterData.maxHp = guidObject.GetUInt32(SharedDef.UNIT_FIELD_MAXHEALTH);
        }

        public function get fighterData():FighterData
        {
            return _data as FighterData;
        }
    }
}
