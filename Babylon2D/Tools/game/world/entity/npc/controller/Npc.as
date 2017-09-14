/**
 * Created by caijingxiao on 2017/7/25.
 */
package game.world.entity.npc.controller
{
    import game.world.entity.base.controller.MovableEntity;
    import game.world.entity.npc.model.NpcData;
    import game.world.entity.npc.view.NpcAvatar;

    import tempest.data.obj.GuidObject;

    public class Npc extends MovableEntity
    {
        public function Npc()
        {
            super();
        }

        override protected function initialize():void
        {
            _data = new NpcData();
            _avatar = new NpcAvatar(onClick);
        }

        override public function initData(guidObject:GuidObject):void
        {
            super.initData(guidObject);
        }

        override public function initAvatar():void
        {
            super.initAvatar();
        }

        override public function update():void
        {
            super.update();
        }
    }
}
