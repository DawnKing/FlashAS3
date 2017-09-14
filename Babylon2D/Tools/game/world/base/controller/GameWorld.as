/**
 * Created by caijingxiao on 2017/7/17.
 */
package game.world.base.controller
{
    import easiest.managers.FrameManager;

    import game.world.base.model.GameWorldEvent;

    import game.world.base.view.GameWorldLayer;
    import game.world.battle.controller.AttackMonsterProcess;
    import game.world.entity.base.controller.CreateEntityProcess;
    import game.world.entity.base.controller.DeleteEntityProcess;
    import game.world.entity.base.controller.MoveEntityProcess;
    import game.world.entity.base.controller.UpdateEntityProcess;
    import game.world.entity.base.model.EntityModel;
    import game.world.entity.player.model.SelfPlayerModel;
    import game.world.map.controller.MapProcess;
    import game.world.map.model.MapModel;
    import game.world.process.CaijiProcess;

    public class GameWorld
    {
        public static var start:Boolean = false;
        private var _processes:Vector.<BaseProcess> = new <BaseProcess>[];

        public function GameWorld()
        {
        }

        public function init():void
        {
            var layer:GameWorldLayer = GameWorldLayer.inst;
            layer.init();

            _processes.push(new DeleteEntityProcess(layer.charLayer));
            _processes.push(new CreateEntityProcess(layer.charLayer));
            _processes.push(new UpdateEntityProcess());
            _processes.push(new MoveEntityProcess());

            _processes.push(new CaijiProcess());
            _processes.push(new AttackMonsterProcess());

            _processes.push(new MapProcess(layer.mapLayer, MapModel.mapData));
        }

        public function start():void
        {
            FrameManager.add(process, FrameManager.REAL_TIME);
        }

        public function stop():void
        {
            FrameManager.remove(process);
        }

        public function clear():void
        {
            GameWorldLayer.inst.clear();
            GameWorldEvent.clear();
            EntityModel.clear();
            SelfPlayerModel.clear();
        }

        public function process():void
        {
            var len:int = _processes.length;
            for (var i:int = 0; i < len; i++)
            {
                var p:BaseProcess = _processes[i];
                if (!p.isProcess())
                    continue;
                p.process();
                p.complete();
            }

            EntityModel.update();
        }
    }
}
