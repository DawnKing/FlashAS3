/**
 * Created by caijingxiao on 2017/8/1.
 */
package game.world.modules.shenshou
{
    import common.events.GameEvent;

    import flash.events.Event;

    import game.world.entity.npc.controller.Monster;

    import modules.scene.signal.SceneSignal;

    import tempest.data.obj.GuidObject;

    public class ShenShou extends Monster
    {
        public function ShenShou()
        {
            super();
        }

        override protected function initialize():void
        {
            super.initialize();
        }

        override public function initData(guidObject:GuidObject):void
        {
            super.initData(guidObject);
        }

        override protected function onClick(event:Event):void
        {
            if(fighterData.hp/fighterData.maxHp<=0.1)
            {
                GameEvent.dispatchEvent(SceneSignal.SCENE_COLLECT, this);
            }
        }
    }
}
