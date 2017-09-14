/**
 * Created by caijingxiao on 2017/7/27.
 */
package game.world.entity.npc.controller
{
    import common.manager.FightMgr;

    import flash.events.Event;

    import game.world.base.model.GameWorldModel;
    import game.world.battle.controller.AttackMonsterProcess;

    import game.world.entity.base.controller.Fighter;
    import game.world.entity.npc.model.MonsterData;
    import game.world.entity.npc.view.MonsterAvatar;

    public class Monster extends Fighter
    {
        public function Monster()
        {
            super();
        }

        override protected function initialize():void
        {
            _data = new MonsterData();
            _avatar = new MonsterAvatar(onClick);
        }

        override protected function onClick(event:Event):void
        {
            GameWorldModel.select = this;
            AttackMonsterProcess.addEvent(data.guid);
        }

        public function get monsterData():MonsterData
        {
            return _data as MonsterData;
        }
    }
}
