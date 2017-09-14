/**
 * Created by caijingxiao on 2017/7/25.
 */
package game.world.entity.npc.view
{
    import game.world.entity.base.model.EntityData;
    import game.world.entity.base.view.EntityAvatar;

    public class NpcAvatar extends EntityAvatar
    {
        public function NpcAvatar(onMouseClick:Function)
        {
            super(onMouseClick);
        }

        override public function init(data:EntityData):void
        {
            super.init(data);
        }
    }
}
