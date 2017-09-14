package easiest.debug
{
    import easiest.managers.AssetManager;
    import easiest.managers.FrameManager;
    import easiest.managers.TimerManager;
    import easiest.utils.TimeUtil;

    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;

    public final class EasiestProfile extends Sprite
    {
        private var m_isDragging:Boolean;

        private var m_gameCore:TextField;
        private var m_assetManager:TextField;
        private var m_frameFunctionList:TextField;
        private var m_timerFunctionList:TextField;

        public function EasiestProfile()
        {
            super();
            this.graphics.beginFill(0xFFFFFF, 0.5);
            this.graphics.drawRect(0, 0, 1000, 500);
            this.graphics.endFill();
            
            addGameCore(0);
            addAssetManager(20);
            addFrameFunctionList(100);
            addTimerFunctionList(160);

            FrameManager.add(process, FrameManager.REAL_TIME);

            this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0 ,true);
            this.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0 ,true);
            this.addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0 ,true);
        }

        public function dispose():void
        {
            FrameManager.remove(process);
        }
        
        private function process(passedTime:Number):void
        {
            processGameCore(passedTime);
            processAssetManager();
            processFrameFunctionList();
            processTimerFunctionList();
        }
        
        private function addGameCore(posY:int):void
        {
            var sprite:MovableSprite = new MovableSprite;
            this.addChild(sprite);
            sprite.x = 0;
            sprite.y = posY;
            
            m_gameCore = new TextField;
            m_gameCore.selectable = false;
            m_gameCore.autoSize = TextFieldAutoSize.LEFT;
            sprite.addChild(m_gameCore);
        }
        
        private function processGameCore(passedTime:Number):void
        {
            var str:String = "本地时间：" + TimeUtil.formatTimestamp(FrameManager.timer)/** + "=" + FrameManager.timer + "=" + getTimer()*/;
            str += " 服务器时间：" + TimeUtil.formatTimestamp(FrameManager.serverTime);
            str += " passedTime=" + passedTime + "  curFrameTime=" + FrameManager.currentFrameTime + " 分数" + FrameManager.frameScore;
            str += " 显示对象数量(按F8打印)=" + getDisplayObjectCount(this.stage);
            str += "privateMemory=" + int(System.privateMemory/1024/1024) + "MB, totalMemory=" + int(System.totalMemory/1024/1024) + "MB, freeMemory=" + int(System.freeMemory/1024/1024) + "MB";

            m_gameCore.text = str;
        }
        
        private static function getDisplayObjectCount(container:DisplayObjectContainer):int
        {
            var count:int = 0;
            for (var i:int = 0; i < container.numChildren; i++)
            {
                var display:DisplayObject = container.getChildAt(i);
                if (display is DisplayObjectContainer)
                    count += getDisplayObjectCount(display as DisplayObjectContainer);
                count++;
            }
            return count;
        }
        
        private function addAssetManager(posY:int):void
        {
            var sprite:MovableSprite = new MovableSprite;
            this.addChild(sprite);
            sprite.x = 0;
            sprite.y = posY;
            
            m_assetManager = new TextField;
            m_assetManager.selectable = false;
            m_assetManager.autoSize = TextFieldAutoSize.LEFT;
            sprite.addChild(m_assetManager);
        }
        
        private function processAssetManager():void
        {
            var str:String = AssetManager.getMemoryInfo();
            str += AssetManager.getLoadInfo();
            m_assetManager.text = str; 
        }
        
        
        private function addFrameFunctionList(posY:int):void
        {
            var sprite:MovableSprite = new MovableSprite;
            this.addChild(sprite);
            sprite.x = 0;
            sprite.y = posY;
            
            m_frameFunctionList = new TextField;
            m_frameFunctionList.selectable = false;
            m_frameFunctionList.autoSize = TextFieldAutoSize.LEFT;
            sprite.addChild(m_frameFunctionList);
        }
        
        private function processFrameFunctionList():void
        {
            m_frameFunctionList.text = FrameManager.getFunctionList();
        }
        
        private function addTimerFunctionList(posY:int):void
        {
            var sprite:MovableSprite = new MovableSprite;
            this.addChild(sprite);
            sprite.x = 0;
            sprite.y = posY;
            
            m_timerFunctionList = new TextField;
            m_timerFunctionList.selectable = false;
            m_timerFunctionList.autoSize = TextFieldAutoSize.LEFT;
            sprite.addChild(m_timerFunctionList);
        }
        
        private function processTimerFunctionList():void
        {
            m_timerFunctionList.text = TimerManager.getFunctionList();
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
            if (m_isDragging && !event.buttonDown)
                stopDragWindow();
        }

        // 开始移动窗口
        private function startDragWindow():void
        {
            if (m_isDragging)
                return;
            m_isDragging = true;
            this.startDrag();
        }

        // 停止移动窗口
        private function stopDragWindow():void
        {
            if (!m_isDragging)
                return;
            m_isDragging = false;
            this.stopDrag();
        }
    }
}

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.system.System;

class MovableSprite extends Sprite
{
    private var m_isDragging:Boolean;
    private var m_switch:Sprite = new Sprite;
    public var content:String;
    
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
        if (event.shiftKey)
        {
            System.setClipboard(content);
            return;
        }
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
        if (m_isDragging && !event.buttonDown)
            stopDragWindow();  
    }
    
    // 开始移动窗口
    private function startDragWindow():void 
    {
        if (m_isDragging)
            return;
        m_isDragging = true;
        this.startDrag();
    }
    
    // 停止移动窗口
    private function stopDragWindow():void 
    {
        if (!m_isDragging)
            return;
        m_isDragging = false;
        this.stopDrag();
    }
}
