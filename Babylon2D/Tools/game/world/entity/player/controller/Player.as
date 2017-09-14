/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.player.controller
{
    import common.consts.ColorConst;
    import common.consts.SharedDef;
    import common.util.StringNiuXUtils;

    import game.world.entity.base.controller.Fighter;
    import game.world.entity.player.model.PlayerData;

    import tempest.data.obj.GuidObject;

    public class Player extends Fighter
    {
        public function Player()
        {
            super();
        }

        override public function initData(guidObject:GuidObject):void
        {
            super.initData(guidObject);

            var playerData:PlayerData = data as PlayerData;
            //有罪恶值 显示红名 粉名
            if (playerData.evil > 0)
            {
                if (playerData.evil > 9 && playerData.evil <= 29)
                {
                    playerData.nameColor=ColorConst.Zez10;
                }
                else if (playerData.evil > 29 && playerData.evil <= 49)
                {
                    playerData.nameColor=ColorConst.Zez30;
                }
                else if (playerData.evil > 49 && playerData.evil <= 99)
                {
                    playerData.nameColor=ColorConst.Zez50;
                }
                else if (playerData.evil > 99 && playerData.evil <= 149)
                {
                    playerData.nameColor=ColorConst.Zez100;
                }
                else if (playerData.evil > 149)
                {
                    playerData.nameColor=ColorConst.Zez150;
                }
            }

//            playerData.weapon = 2001000;
        }

        override protected function setName(guidObject:GuidObject):void
        {
            var country:uint = guidObject.GetByte(SharedDef.UNIT_FIELD_BYTE_1, 2);
            var nameNative:String = guidObject.GetStr(SharedDef.BINLOG_STRING_FIELD_NAME);
            var name:String = nameNative.substring(nameNative.lastIndexOf(",") + 1, nameNative.length);
            _data.name = StringNiuXUtils.getCountryName(country) + " " + name;
        }

        public function get playerData():PlayerData
        {
            return _data as PlayerData;
        }
    }
}
