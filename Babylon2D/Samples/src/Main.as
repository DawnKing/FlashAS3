package
{
    import easiest.core.EasiestCore;
    import easiest.debug.LogWindow;
    import easiest.debug.Stats;
    import easiest.rendering.Engine;
    import easiest.rendering.Scene;
    import easiest.rendering.sprites.Sprite2D;
    import easiest.rendering.sprites.text.E2DTextMgr;

    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;

    import test.Test;

    public class Main extends Sprite
    {
        public static var scene:Scene;
        public static var txtMgr:E2DTextMgr;

        private var _engine:Engine;
        /**舞台*/
        private var _stage:Stage;
        private var _logWindow:LogWindow;

        public function Main()
        {
            this.visible=false;
            if (stage)
            {
                _stage=stage;
                onAddToStage();
            }
            else
            {
                this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
            }
        }

        private function onAddToStage(e:Event=null):void
        {
            stage.frameRate=60;
            stage.stageFocusRect=false;
            stage.tabChildren=false;

            initApp(this.stage);
        }

        /**
         * 自身初始化
         */
        private function initApp(st:Stage):void
        {
            _stage=st;
            _stage.addChild(new Stats());
            EasiestCore.start(_stage, false);
            _engine=new Engine(_stage);
            _engine.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
            _stage.addEventListener(Event.RESIZE, onResize);
        }

        private function onResize(event:Event):void
        {
            _engine.onResize();
            Sprite2D.onResize(_stage);
            Test.onResize(_stage);
        }

        private function onContext3DCreated(event:Event):void
        {
            scene=new Scene(_engine, _stage);
            Sprite2D.init(_stage);
            txtMgr=new E2DTextMgr(512, 512);

//            Test.testWeather(scene, _stage);

//            _stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            _stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

//            Test.testMap(scene, _stage);

//            Test.testSprite2D(scene);
//            Test.testAnimation(scene);
//            Test.testSpriteAtlas(scene);
//            Test.testText(scene, txtMgr);
//            Test.testCharAvatar(scene);
            Test.testEffect(scene);
//            Test.testBatching();
//            TestScene.testAddRemoveCharAvatar(scene, 50);
        }

        private function onKeyDown(event:KeyboardEvent):void
        {
            switch (event.keyCode)
            {
                case Keyboard.F2:
                    Scene.useChar = !Scene.useChar;
                    break;
                case Keyboard.F3:
                    Scene.useEffect = !Scene.useEffect;
                    break;
                case Keyboard.F4:
                    Scene.useWeather = !Scene.useWeather;
                    break;
                case Keyboard.F6:
                    break;
                case Keyboard.NUMPAD_SUBTRACT:
                    if (!_logWindow)
                        _logWindow = new LogWindow();
                    if (_stage.contains(_logWindow))
                        _stage.removeChild(_logWindow);
                    else
                        _stage.addChild(_logWindow);
                    break;
            }
        }
    }
}