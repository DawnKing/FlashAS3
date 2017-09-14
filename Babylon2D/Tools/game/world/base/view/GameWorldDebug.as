/**
 * Created by caijingxiao on 2017/7/26.
 */
package game.world.base.view
{
    import easiest.managers.FrameManager;

    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.utils.Dictionary;

    import game.world.base.model.GameWorldEvent;
    import game.world.entity.base.controller.Entity;
    import game.world.entity.base.model.EntityModel;
    import game.world.map.model.MapModel;

    public class GameWorldDebug extends Sprite
    {
        private var _dragging:Boolean;		            // 正被拖动
        private var _map:MapView;

        private var m_textGameWorldEvent:TextField;

        public function GameWorldDebug()
        {
            super();

            this.graphics.beginFill(0xFFFFFF, 0.5);
            this.graphics.drawRect(0, 0, 1024, 768);
            this.graphics.endFill();

            this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0 ,true);
            this.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0 ,true);
            this.addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0 ,true);

            _map = new MapView(MapModel.mapData.backgroundUrl);
            addChild(_map);

            addGameWorldEvent(MapView.WIDTH, 0);

            FrameManager.add(process, FrameManager.REAL_TIME);
        }

        private function addGameWorldEvent(posX:int, posY:int):void
        {
            var sprite:MovableSprite = new MovableSprite;
            this.addChild(sprite);
            sprite.x = posX;
            sprite.y = posY;

            m_textGameWorldEvent = new TextField;
            m_textGameWorldEvent.selectable = false;
            m_textGameWorldEvent.autoSize = TextFieldAutoSize.LEFT;
            sprite.addChild(m_textGameWorldEvent);
        }

        private function process():void
        {
            _map.reset();
            var entities:Dictionary = EntityModel.entities;
            for each (var entity:Entity in entities)
            {
                _map.addEntity(entity);
            }

            processGameWorldEvent();
        }

        private function processGameWorldEvent():void
        {
            var eventList:Dictionary = GameWorldEvent.eventList;
            var eventInfo:String = "事件：\n";
            for (var eventType:String in eventList)
            {
                var info:String = "";
                eventInfo += eventType+info+"\n";
            }
            m_textGameWorldEvent.text = eventInfo;
        }

        private function mouseDownHandler(event:MouseEvent):void
        {
            event.stopImmediatePropagation();
            startDragWindow();
        }

        protected function mouseUpHandler(event:MouseEvent):void
        {
            event.stopImmediatePropagation();
            stopDragWindow();
        }

        // 鼠标离屏处理
        private function rollOverHandler(event:MouseEvent):void
        {
            if (_dragging && !event.buttonDown)
                stopDragWindow();
        }

        // 开始移动窗口
        private function startDragWindow():void
        {
            if (_dragging)
                return;
            _dragging = true;
            this.startDrag();
        }

        // 停止移动窗口
        private function stopDragWindow():void
        {
            if (!_dragging)
                return;
            _dragging = false;
            this.stopDrag();
        }
    }
}

import easiest.managers.load.AssetData;
import easiest.managers.load.AssetManager;
import easiest.managers.load.AssetType;

import flash.display.Bitmap;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import game.world.entity.base.controller.Entity;

class MapView extends Sprite
{
    public static const WIDTH:Number = 800;
    public static const HEIGHT:Number = 600;

    private var _map:Bitmap;
    private var _mapWidth:Number = Number.MAX_VALUE;
    private var _mapHeight:Number = Number.MAX_VALUE;
    private var _positionErrorCount:int;
    private var _txt:TextField;
    private var _fixed:TextField;
    private var _showTxt:Boolean;
    private var _showFixed:Boolean;

    public function MapView(url:String)
    {
        _txt = new TextField();
        _txt.autoSize = TextFieldAutoSize.LEFT;
        _txt.background = true;
        _txt.backgroundColor = 0;
        _txt.textColor = 0xFFFFFF;
        _txt.mouseEnabled = false;
        _fixed = new TextField();
        _fixed.autoSize = TextFieldAutoSize.LEFT;
        _fixed.background = true;
        _fixed.backgroundColor = 0;
        _fixed.textColor = 0xFFFFFF;
        _fixed.mouseEnabled = false;
        AssetManager.load(url, onComplete, AssetType.BITMAP);
    }

    private function onComplete(asset:AssetData):void
    {
        if (asset.asset == null)
            return;
        _map = asset.asset as Bitmap;
        addChild(_map);
        _map.alpha = 0.8;
        _mapWidth = _map.width;
        _mapHeight = _map.height;

        scaleX = WIDTH / _map.width;
        scaleY = HEIGHT / _map.height;
        _txt.scaleX = 1 / scaleX;
        _txt.scaleY = 1 / scaleY;
        _fixed.scaleX = 1 / scaleX;
        _fixed.scaleY = 1 / scaleY;
    }

    public function reset():void
    {
        _positionErrorCount = 0;
        removeChildren();
        if (_map)
            addChild(_map);
        if (_showTxt)
            addChild(_txt);
        if (_showFixed)
            addChild(_fixed);
    }

    public function addEntity(entity:Entity):void
    {
        var point:Sprite = new Sprite();
        point.addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
        point.addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
        point.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
        point.scaleX = 1 / scaleX;
        point.scaleY = 1 / scaleY;
        addChildAt(point, _map ? 1 : 0);

        var posX:Number = entity.data.x;
        var posY:Number = entity.data.y;
        if (isNaN(posX) || isNaN(posY) || posX < 0 || posY < 0 || posX > _mapWidth || posY > _mapHeight)
        {
            point.graphics.beginFill(0xFF0000);
            point.x = -1;
            point.y = -20 * _positionErrorCount++;
        }
        else
        {
            point.graphics.beginFill(entity.data.nameColor);
            point.x = posX;
            point.y = posY;
        }
        point.graphics.drawCircle(-2, -2, 4);
        point.graphics.endFill();

        function onMouseDown(event:MouseEvent):void
        {
            if (!event.shiftKey)
                return;
            _fixed.x = _mapWidth;
            _fixed.text = entity.toString();
            _showFixed = true;
        }

        function onRollOver(event:MouseEvent):void
        {
            _txt.x = posX;
            _txt.y = posY;
            _txt.text = entity.toString();
            _showTxt = true;
        }

        function onRollOut(event:MouseEvent):void
        {
            _showTxt = false;
        }
    }
}

class MovableSprite extends Sprite
{
    private var m_isDragging:Boolean;		            // 正被拖动
    private var m_switch:Sprite = new Sprite;

    public function MovableSprite()
    {
        m_switch.graphics.beginFill(0xFF0000);
        m_switch.graphics.drawCircle(-10, 10, 10);
        m_switch.graphics.endFill();
        m_switch.addEventListener(MouseEvent.CLICK, onClose, false, 0, true);
        this.addChild(m_switch);

        this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0 ,true);
        this.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0 ,true);
        this.addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0 ,true);
    }

    protected function onClose(event:MouseEvent):void
    {
        for (var i:int = 0; i < this.numChildren; i++)
        {
            var object:DisplayObject = this.getChildAt(i);
            if (object != m_switch)
                object.visible = !object.visible;
        }
    }

    private function mouseDownHandler(event:MouseEvent):void
    {
        event.stopImmediatePropagation();
        startDragWindow();
    }

    protected function mouseUpHandler(event:MouseEvent):void
    {
        event.stopImmediatePropagation();
        stopDragWindow();
    }

    // 鼠标离屏处理
    private function rollOverHandler(event:MouseEvent):void
    {
        if(m_isDragging && !event.buttonDown)
            stopDragWindow();
    }

    // 开始移动窗口
    private function startDragWindow():void
    {
        if(m_isDragging)
            return;
        m_isDragging = true;
        this.startDrag();
    }

    // 停止移动窗口
    private function stopDragWindow():void
    {
        if(!m_isDragging)
            return;
        m_isDragging = false;
        this.stopDrag();
    }
}

