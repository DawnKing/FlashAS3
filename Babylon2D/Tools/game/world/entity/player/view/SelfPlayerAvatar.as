/**
 * Created by caijingxiao on 2017/7/24.
 */
package game.world.entity.player.view
{
    import common.consts.ColorConst;

    import game.world.entity.base.model.EntityData;

    public final class SelfPlayerAvatar extends PlayerAvatar
    {
        public function SelfPlayerAvatar(onMouseClick:Function)
        {
            super(onMouseClick);
        }

        override public function init(data:EntityData):void
        {
            data.nameColor = ColorConst.Blue3;
            super.init(data);
        }

        override public function updateData(data:EntityData):void
        {
            super.updateData(data);
        }

        override public function update(data:EntityData, frame:int):void
        {
            super.update(data, frame);
        }

        override protected function addMouseEvent():void
        {
            // 自己不需要有鼠标事件
        }
    }
}
