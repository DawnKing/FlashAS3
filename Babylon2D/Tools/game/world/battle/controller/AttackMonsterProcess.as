/**
 * Created by caijingxiao on 2017/8/1.
 */
package game.world.battle.controller
{
    import common.data.dataobject.SpellData;
    import common.events.GameEvent;
    import common.manager.MainCharWalkMgr;
    import common.manager.MessageMgr;
    import common.util.translate;

    import easiest.managers.FrameManager;

    import easiest.utils.NameUtil;

    import flash.geom.Point;

    import flash.utils.getQualifiedClassName;

    import game.world.base.controller.BaseProcess;
    import game.world.base.model.GameWorldEvent;
    import game.world.entity.base.controller.Entity;
    import game.world.entity.base.model.EntityModel;
    import game.world.entity.player.controller.SelfPlayer;
    import game.world.entity.player.model.SelfPlayerModel;

    import modules.heroinfo.signal.HeroSignal;

    import modules.spell.model.SpellModel;

    import tempest.core.IMagicScene;
    import tempest.enum.Status;

    import tempest.utils.Geom;

    public class AttackMonsterProcess extends BaseProcess
    {
        public static const Event:String = NameUtil.getUnqualifiedClassName(AttackMonsterProcess);

        public static function addEvent(guid:String):void
        {
            GameWorldEvent.addEvent(Event, guid);
        }

        public static function stop():void
        {
            GameWorldEvent.removeEvent(Event);
        }

        public static var _spell:SpellData;
        private var _moving:Boolean;
        private var _cooling:int;

        public function AttackMonsterProcess()
        {
            super(Event);
        }

        override public function process():void
        {
            if (_cooling > FrameManager.time)
                return;
            _cooling = FrameManager.time + 1000;
            if (_moving)
                return;
            if (!_spell.canUse())
            {
                stop();
                return;
            }

            var guid:String = getParam() as String;
            var target:Entity = EntityModel.getEntity(guid);
            if (target == null)
            {
                stop();
                return;
            }

            var selfPlayer:SelfPlayer = SelfPlayerModel.getPlayer();
            var distance:int=_spell.attackDis;
            var targetTile:Point=target.data.tile;
            if (_spell.noTarget || selfPlayer.inDistance(targetTile, distance))
            {
                targetTile=Geom.GetEndPoint(selfPlayer.data.tile, targetTile, distance);
                sendSpell(_spell, targetTile, target.data.uguid);
            }
            else
            {
                MainCharWalkMgr.walkSignal.addOnce(onWalkComplete);
                MainCharWalkMgr.heroWalk(App.hero.currentMapid, targetTile, distance - 1, false, false);
            }
        }

        private function sendSpell(spell:SpellData, targetTile:Point, target:uint):Boolean
        {
            var scene:IMagicScene=App.iscene;
            var selfPlayer:SelfPlayer = SelfPlayerModel.getPlayer();
            var isJump:Boolean=spell.spellInfo.isJumpSkill;
            if (!scene || !scene.mapConfig)
            {
                return false;
            }
            if ((selfPlayer.data.status == Status.WALK)) //移动中先停止 只是客户端停止了
            {
                MainCharWalkMgr.stopMove(false);
            }
            if (isJump && App.iscene.mapConfig.isBlock(targetTile.x, targetTile.y)) //不能对掩码点使用技能
            {
                MessageMgr.instance.addHint(translate(466, "目标点为障碍区域，技能无法释放"));
                return false;
            }
            selfPlayer.faceToTile1(targetTile); //朝向技能目标点
            App.netService.conn.spell_start(spell.templateId, targetTile.x, targetTile.y, target); //使用技能发包
            if (!isJump)
            {
                SpellModel.instance.updateCd(spell.templateId, spell.spellInfo.spell_cd);
            }
            GameEvent.dispatchEvent(HeroSignal.HERO_ATTACK, spell.templateId, target); //主角使用技能
            return true;
        }

        private function onWalkComplete(...arg):void
        {
            _moving = false;
        }

        override public function complete():void
        {
            // 不自动移除事件，使用stop移除
        }
    }
}
