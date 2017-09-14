package easiest.managers
{
    import easiest.core.EasiestCore;
    import easiest.debug.EasiestProfile;

    import flash.display.Stage;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;

    public final class KeyboardManager
    {
        private static var _keyDownList:Array = [];
        private static var _profile:EasiestProfile;
        private static var _func:Vector.<Function> = new <Function>[];
        
        public static function start(stage:Stage):void
        {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        }

        public static function add(func:Function):void
        {
            var index:int = _func.indexOf(func);
            if (index == -1)
                _func.push(func);
        }

        public static function remove(func:Function):void
        {
            var index:int = _func.indexOf(func);
            if (index != -1)
                _func.removeAt(index);
        }

        private static function onKeyDown(event:KeyboardEvent):void
        {
//            event.stopImmediatePropagation();

            _keyDownList[event.keyCode] = true;

            for (var i:int = 0; i < _func.length; i++)
            {
                _func[i](event);
            }

            switch(event.keyCode)
            {
                case Keyboard.NUMPAD_DIVIDE:
                    if (_profile)
                    {
                        EasiestCore.stage.removeChild(_profile);
                        _profile.dispose();
                        _profile = null;
                    }
                    else
                    {
                        _profile = new EasiestProfile();
                        EasiestCore.stage.addChild(_profile);
                    }
                    break;
            }
        }

        private static function onKeyUp(event:KeyboardEvent):void
        {
//            event.stopImmediatePropagation();

            _keyDownList[event.keyCode] = false;
        }

        public static function isDown(KeyCode:uint):Boolean
        {
            return _keyDownList[KeyCode] == true;
        }
    }
}
