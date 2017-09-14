/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.base
{
    import common.SceneCache;

    import easiest.core.EasiestCore;
    import easiest.debug.Stats;
    import easiest.managers.FrameManager;
    import easiest.managers.load.BinManager;
    import easiest.rendering.Engine;
    import easiest.rendering.Scene;
    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.rendering.sprites.Sprite2D;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.text.E2DTextMgr;

    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;

    import game.scene.E2DScene;
    import game.world.base.controller.GameWorld;
    import game.world.base.view.GameWorldDebug;
    import game.world.base.view.GameWorldLayer;

    import starling.animation.Juggler;

    import tempest.core.IApp;

    public final class Main extends SpriteContainer
    {
        private static var _instance:Main;
        public static function get inst():Main { if (_instance == null) _instance = new Main(); return _instance; }

        public static var txtMgr:E2DTextMgr;
        public static var stScene:E2DScene;
        public static var sceneAtlas:TextureAtlas;

        private var _scene:Scene;
        private var _stage:Stage;
        private var _iApp:IApp;
        private var _engine:Engine;
        private var _gameWorld:GameWorld;
        private var _gameWorldDebug:GameWorldDebug;

        public function Main()
        {
            mouseEnabled = false;
            mouseChildren = true;
        }

        public function init(iApp:IApp):void
        {
            _iApp = iApp;
            _stage = _iApp.stage;
            _stage.addChild(new Stats());
            EasiestCore.start(_stage, false);
            _engine=new Engine(_stage);
            _engine.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
            _stage.addEventListener(Event.RESIZE, onResize);
            _stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        private function onKeyDown(event:KeyboardEvent):void
        {
            switch (event.keyCode)
            {
                case Keyboard.F2:
                    if (_gameWorldDebug)
                    {
                        _stage.removeChild(_gameWorldDebug);
                        _gameWorldDebug = null;
                    }
                    else
                    {
                        _gameWorldDebug = new GameWorldDebug();
                        _stage.addChild(_gameWorldDebug);
                    }
                    break;
            }
        }

        private function onContext3DCreated(event:Event):void
        {
            _scene=new Scene(_engine, _stage);
            BinManager.init();
            Sprite2D.init(_stage);
            txtMgr=new E2DTextMgr(512, 512);

            BinManager.loadBin(SceneCache.binPath + "scene", onBinComplete);
        }

        private function onBinComplete(atlas:TextureAtlas):void
        {
            sceneAtlas = atlas;

            stScene=new E2DScene(_iApp.objData);
            _scene.addChild(stScene);
            _iApp.initScene(stScene);
            Object(stScene.camera).setBounds(4348,2390);
            Object(stScene.camera).setView(_stage.stageWidth, _stage.stageHeight);

            _gameWorld = new GameWorld();
            _gameWorld.init();

            var layer:GameWorldLayer = GameWorldLayer.inst;
            addChild(layer);

            _scene.addChild(this);

            FrameManager.add(process);
        }

        private function process(passedTime:Number):void
        {
            Juggler.instance.advanceTime(passedTime / 1000);
        }

        private function onResize(event:Event):void
        {
            _engine.onResize();
            Sprite2D.onResize(_stage);
        }

        public function get gameWorld():GameWorld
        {
            return _gameWorld;
        }
    }
}
