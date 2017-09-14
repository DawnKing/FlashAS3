package babylon.tools
{
    import babylon.Engine;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.getTimer;

    public class Stats extends Sprite
    {
        private static const DIAGRAM_HEIGHT:uint = 60;
        private static const DIAGRAM_WIDTH:uint = 80;
        private static const CYCLE:int = 10;
        
        private var _fps:TextField;
        private var _cpuMem:TextField;
        private var _gpuMem:TextField;
        private var _drawcall:TextField;

        private var _cycleIndex:int = 0;
        private var _cycleTimer:int;

        public var drawcall:int;

        public function Stats()
        {
            this.addEventListener(Event.ADDED_TO_STAGE,init);
            
            this.mouseChildren = false;
            this.mouseEnabled = false;
        }
        
        public function init(e:Event):void
        {
            var bitmap:Bitmap;
            this.removeEventListener(Event.ADDED_TO_STAGE,init);
            
            _fps = new TextField();
            _fps.defaultTextFormat = new TextFormat("Tahoma", 12, 16711680);
            _fps.autoSize = TextFieldAutoSize.LEFT;
            _fps.text = "FPS:" + Number(stage.frameRate).toFixed(2);
            addChild(_fps);
            
            _cpuMem = new TextField();
            _cpuMem.defaultTextFormat = new TextFormat("Tahoma", 12, 65280);
            _cpuMem.autoSize = TextFieldAutoSize.LEFT;
            _cpuMem.text = "CM:" + byteToString(System.totalMemory);
            _cpuMem.y = _fps.y + 12;
            addChild(_cpuMem);

            _gpuMem = new TextField();
            _gpuMem.defaultTextFormat = new TextFormat("Tahoma", 12, 65280);
            _gpuMem.autoSize = TextFieldAutoSize.LEFT;
            _gpuMem.text = "GM:" + byteToString(System.totalMemory);
            _gpuMem.y = _cpuMem.y + 12;
            addChild(_gpuMem);

            _drawcall = new TextField();
            _drawcall.defaultTextFormat = new TextFormat("Tahoma", 12, 65280);
            _drawcall.autoSize = TextFieldAutoSize.LEFT;
            _drawcall.text = "DW:" + Engine.drawcall;
            _drawcall.y = _gpuMem.y + 12;
            addChild(_drawcall);
            
            var background:BitmapData = new BitmapData(DIAGRAM_WIDTH,DIAGRAM_HEIGHT,true,0xAA000000);
            bitmap = new Bitmap(background);
            addChildAt(bitmap,0);
            
            addEventListener(Event.ENTER_FRAME,onEnterFrame);
            _cycleTimer = getTimer();
        }
        
        private function onEnterFrame(e:Event):void
        {
            if (this.stage == null)
            {
                this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
                return;
            }
            // 帧率
            _cycleIndex++;
            if (_cycleIndex >= CYCLE)
            {
                _cycleIndex = 0;
                _fps.text = "FPS: " + Number(1000 * CYCLE / (getTimer() - _cycleTimer)).toFixed(2);
                _cycleTimer = getTimer();
            }
            
            // 内存
            _cpuMem.text = "CM: " + byteToString(System.totalMemory);
            _gpuMem.text = "GM: " + byteToString(Engine.gpuMem);

            _drawcall.text = "DW:" + Engine.drawcall;
        }
        
        private function byteToString(byte:uint):String
        {
            var byteStr:String = null;
            if (byte < 1024)
            {
                byteStr = String(byte) + "b";
            }
            else if (byte < 10240)
            {
                byteStr = Number(byte / 1024).toFixed(2) + "kb";
            }
            else if (byte < 102400)
            {
                byteStr = Number(byte / 1024).toFixed(1) + "kb";
            }
            else if (byte < 1048576)
            {
                byteStr = Math.round(byte / 1024) + "kb";
            }
            else if (byte < 10485760)
            {
                byteStr = Number(byte / 1048576).toFixed(2) + "mb";
            }
            else if (byte < 104857600)
            {
                byteStr = Number(byte / 1048576).toFixed(1) + "mb";
            }
            else
            {
                byteStr = Math.round(byte / 1048576) + "mb";
            }
            return byteStr;
        }
    }
    
}