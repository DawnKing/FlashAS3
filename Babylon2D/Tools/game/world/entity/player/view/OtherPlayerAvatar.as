/**
 * Created by caijingxiao on 2017/7/24.
 */
package game.world.entity.player.view
{
    import common.consts.ColorConst;

    import game.world.entity.base.model.EntityData;

    public final class OtherPlayerAvatar extends PlayerAvatar
    {
        public function OtherPlayerAvatar(onMouseClick:Function)
        {
            super(onMouseClick);
        }

        override public function init(data:EntityData):void
        {
            data.nameColor = ColorConst.white3;
            super.init(data);
        }
    }
}
