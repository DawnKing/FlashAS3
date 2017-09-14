/**
 * Created by caijingxiao on 2017/8/2.
 */
package game.world.modules.zhongkui
{
    import flash.events.MouseEvent;

    import game.world.entity.npc.view.MonsterAvatar;

    public class ZKMonsterAvatar extends MonsterAvatar
    {
        public function ZKMonsterAvatar(onMouseClick:Function)
        {
            super(onMouseClick);
        }

        override protected function onMouseOver(event:MouseEvent):void
        {
            //小鬼屏蔽鼠标移过去后的选中态
        }

        override protected function onMouseOut(event:MouseEvent):void
        {
        }
    }
}
