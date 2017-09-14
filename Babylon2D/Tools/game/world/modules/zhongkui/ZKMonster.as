/**
 * Created by caijingxiao on 2017/8/2.
 */
package game.world.modules.zhongkui
{
    import flash.events.Event;

    import game.world.base.model.GameWorldModel;

    import game.world.entity.npc.controller.Monster;
    import game.world.entity.npc.model.MonsterData;

    public class ZKMonster extends Monster
    {
        public function ZKMonster()
        {
            super();
        }

        override protected function initialize():void
        {
            _data = new MonsterData();
            _avatar = new ZKMonsterAvatar(onClick);
        }

        override protected function onClick(event:Event):void
        {
            if(monsterData.zkzgMyCamp==App.heroUnit.zkzgMyCamp)
                GameWorldModel.select = this;
        }
    }
}
