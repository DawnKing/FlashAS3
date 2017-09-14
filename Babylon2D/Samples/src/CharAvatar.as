/**
 * Created by caijingxiao on 2017/6/20.
 */
package {
    import easiest.managers.FrameManager;
    import easiest.rendering.Scene;
    import easiest.rendering.sprites.PngProgressBar;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.atlas.PngAnimation;
    import easiest.rendering.sprites.text.BitmapText;
    import easiest.utils.MathUtil;

    import flash.events.MouseEvent;

    import tempest.core.IAvatar;
    import tempest.template.ActionConfig;
    import tempest.template.OffsetInfo;

    public class CharAvatar extends SpriteContainer implements IAvatar
    {
        private var _id:int;
        private var _char:PngAnimation;
        private var _weapon:PngAnimation;
        private var _ride:PngAnimation;
        private var _wing:PngAnimation;
        private var _list:Vector.<PngAnimation> = new <PngAnimation>[];

        private var _hpBar:PngProgressBar;
        private var _name:BitmapText;
        private var _offsetX:int = -320;
        private var _offsetY:int = -240;

        private var _gid:int;
        private var _status:int;

        public function CharAvatar(id:int, gid:int)
        {
            super();
            _id = id;
            _gid = gid;

//            var charActionList:Array =   [0,  1,  2, 3,  4, 7, 8];
//            var charFrameList:Array = [10, 10, 8, 4, 10, 5, 7];
            var charActionList:Array =   [0,  1];
            var charFrameList:Array =    [10, 10];

            var weaponActionList:Array = [0, 1, 2];
            var weaponFrame:Array =      [6, 6, 3];

            var rideActionList:Array =   [0, 1];
            var rideFrameList:Array =    [6, 5];

            var wingActionList:Array =   [0];
            var wingFrameList:Array =    [6];

            _wing = addComponent(GamePath.Wing, wingActionList, wingFrameList);
            _ride = addComponent(GamePath.Ride, rideActionList, rideFrameList);
            _weapon = addComponent(GamePath.Weapon, weaponActionList, weaponFrame);
            _char = addComponent(GamePath.Char, charActionList, charFrameList);

            const list:Array = ["bargray", "bargreen", "barred"];
            var name:String = list[MathUtil.getIntRandom(0, list.length-1)];
            _hpBar = new PngProgressBar(GamePath.HpBar, "bargreen", "barbg");
            _hpBar.percent = MathUtil.getNumberRandom(0, 1);
            addChild(_hpBar);

//            _name = E2DTextMgr.inst.createText("我的名字非常的长" + gid, 0);
//            addChild(_name);

            x = 0;
            y = 0;

            mouseEnabled = true;
            mouseChildren = true;
            addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            addEventListener(MouseEvent.CLICK, onMouseClick);
        }

        override public function dispose():void
        {
            if (_name)
                _name.dispose();
            _name = null;
            super.dispose();
        }

        private function onMouseClick(event:MouseEvent):void
        {
            trace("click"+_gid);
        }

        private function onMouseDown(event:MouseEvent):void
        {
//            addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            FrameManager.add(move, FrameManager.REAL_TIME);
        }

        private function move():void
        {
            x = Scene.mouseX;
            y = Scene.mouseY;
        }

        private function onMouseUp(event:MouseEvent):void
        {
            FrameManager.remove(move);
//            removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        }

        private function onMouseMove(event:MouseEvent):void
        {
//            x = Scene.mouseX - 300;
//            y = Scene.mouseY - 300;
        }

        private function addComponent(url:String, actionList:Array, frameList:Array):PngAnimation
        {
            url += _id;
            var random:int = MathUtil.getIntRandom(0, actionList.length-1);
            var action:int = actionList[random];
            var totalFrame:int = frameList[random];

            var component:PngAnimation = new PngAnimation(url);
            component.action = action;
            component.totalFrame = totalFrame;
            addChild(component);
            _list.push(component);
            component.mouseEnabled = true;
            return component;
        }

        public function set action(value:int):void
        {
            for each(var c:PngAnimation in _list)
            {
                c.action = value;
            }
        }

        public function set direction(value:int):void
        {
            for each(var c:PngAnimation in _list)
            {
                c.direction = value;
            }
        }

        override public function set x(value:Number):void
        {
            super.x = value + _offsetX;
            _weapon.x = 180;
            _ride.x = 170;
            _wing.x = 170;
            _hpBar.x = 280;
            if (_name)
                _name.x = 280;
        }

        override public function set y(value:Number):void
        {
            super.y = value + _offsetY;
            _weapon.y = 110;
            _ride.y = 150;
            _wing.y = 120;
            _hpBar.y = 170;
            if (_name)
                _name.y = 150;
        }

        public function addAvatarItem(id:int, type:int, path:String=null, sortRule:int=Array.NUMERIC):void
        {
        }

        public function getAvatarItem(type:int):*
        {
            return null;
        }

        public function set intervalScale(value:Number):void
        {
            // TODO Auto Generated method stub
//            Log.log("intervalScale", this);
        }

        public function set isShowShadow(value:Boolean):void
        {
            // TODO Auto Generated method stub
//            Log.log("isShowShadow", this);
        }

        public function get isShowShadow():Boolean
        {
            // TODO Auto Generated method stub
//            Log.log("isShowShadow", this);
            return false;
        }

        public function get offsetInfo():OffsetInfo
        {
            // TODO Auto Generated method stub
//            Log.log("offsetInfo", this);
            return null;
        }

        public function playTo(status:int=-1, dir:int=-1, apc:ActionConfig=null, onEffectFrame:Function=null, onCompleteFrame:Function=null, resetFrame:Boolean=false):void
        {
            _status = status;
            if (status != -1)
                action = status;
            if (dir != -1)
                direction = dir;
        }

        public function removeAvatarItem(type:int):void
        {
            // TODO Auto Generated method stub
//            Log.log("removeAvatarItem", this);
        }

        public function setClickRect(w:int=145, h:int=80):void
        {
            // TODO Auto Generated method stub
//            Log.log("setClickRect", this);
        }

        public function get status():int
        {
            return _status;
        }

        public function get usable():Boolean
        {
            // TODO Auto Generated method stub
//            Log.log("usable", this);
            return false;
        }

        public function removeAllItem():void
        {
            // TODO Auto Generated method stub

        }

    }
}
