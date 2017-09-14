/**
 * Created by caijingxiao on 2017/7/25.
 */
package game.world.entity.npc.model
{
    import game.world.entity.base.model.MovableData;

    public class NpcData extends MovableData
    {
        public function NpcData()
        {
            super();
        }

        override public function set body(value:int):void
        {
            super.body = value;
        }

        override public function set status(value:int):void
        {
            super.status = value;
        }
    }
}
