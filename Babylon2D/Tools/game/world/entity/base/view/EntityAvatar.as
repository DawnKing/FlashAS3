/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.base.view
{
    import com.adobe.utils.StringUtil;

    import easiest.core.IClear;
    import easiest.managers.ObjectPool;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;
    import easiest.rendering.sprites.atlas.SpriteAtlas;
    import easiest.rendering.sprites.text.BitmapText;
    import easiest.rendering.sprites.text.E2DTextMgr;

    import flash.events.MouseEvent;

    import game.base.FilterEnum;
    import game.base.Main;
    import game.world.entity.base.model.EntityData;

    public class EntityAvatar extends SpriteContainer implements IClear
    {
        private var _name:BitmapText;
        private var _shadow:SpriteAtlas;
        protected var _body:IAvatarItem;
        private var _onMouseClick:Function;

        public function EntityAvatar(onMouseClick:Function)
        {
            super();

            _onMouseClick = onMouseClick;

            _shadow = new SpriteAtlas();
            _shadow.name = "shadow";
            _shadow.setAtlas2(Main.sceneAtlas, "shadow");
            addChild(_shadow);
            _shadow.pivotX = _shadow.width / 2;
            _shadow.pivotY = _shadow.height / 2;
        }

        override public function dispose():void
        {
            clear();
            removeMouseEvent();
            super.dispose();
        }

        public function clear():void
        {
            if (_name)
            {
                _name.dispose();
                _name = null;
            }
            if (_body)
            {
                _body.dispose();
                _body = null;
            }
        }

        public function init(data:EntityData):void
        {
            _name = E2DTextMgr.inst.createText(data.textName, data.nameColor);
            _name.name = "name";
            _name.x = -_name.width / 2;
            addChild(_name);

            _body = initBody();
            _body.name = "body";
            addChild(_body as SpriteObject);

            addMouseEvent();
        }

        protected function initBody():IAvatarItem
        {
            return ObjectPool.get(AvatarItem) as AvatarItem;
        }

        protected function addMouseEvent():void
        {
            mouseEnabled = false;
            mouseChildren = true;
            addEventListener(MouseEvent.CLICK, _onMouseClick, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);
        }

        private function removeMouseEvent():void
        {
            removeEventListener(MouseEvent.CLICK, _onMouseClick);
            removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
            removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        }

        protected function onMouseOver(event:MouseEvent):void
        {
            _body.filter = FilterEnum.swhiteFilter;
        }

        protected function onMouseOut(event:MouseEvent):void
        {
            _body.filter = null;
        }

        protected function onBodyUpdate(nameY:Number):void
        {
            _name.y = nameY - _name.height;
        }

        public function updateData(data:EntityData):void
        {
            if (data.bodyChanged)
            {
                _body.itemId = data.body;
                onBodyUpdate(-_body.itemHeight);
            }
        }

        public function update(data:EntityData, frame:int):void
        {
            _body.updateItem(data, frame);
        }

        public function get bodyHeight():uint
        {
            return _body.itemHeight;
        }

        private static const toStr:String = ", bodyHeight:{0}";
        override public function toString():String
        {
            return super.toString() + StringUtil.format(toStr, _body.itemHeight);
        }
    }
}
