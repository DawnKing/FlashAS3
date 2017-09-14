package easiest.debug
{
    import easiest.core.Log;

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;

    public class LogWindow extends Sprite
    {
        public var btnError:Sprite;
        public var btnLog:Sprite;
        public var btnLan:Sprite;
        public var btnCopy:Sprite;
        public var btnBattle:Sprite;
        public var btnLoad:Sprite;
        public var btnProfile:Sprite;
        public var txtLogInfo:TextField;
        private var m_debugListIndex:int;
        private var m_state:String = "Error";
        
        public function LogWindow()
        {
            this.y = 100;
            initUi();
            addEventListen();
            addMessage();
            
            showErrorContent();
        }
		
        public function dispose():void
        {
            removeMessage();
        }
        
        public function initUi():void
        {
            btnError= initButton( "错误", 8, 4);
            btnLog= initButton( "日志", btnError.x+btnError.width+4, 4);
            btnLan= initButton( "网络", btnLog.x+btnLog.width+4, 4);
            
            btnLoad= initButton( "加载1", btnLan.x+btnLan.width+20, 4);
            btnBattle= initButton("战斗2", btnLoad.x+btnLoad.width+4, 4);
            btnProfile= initButton("性能3", btnBattle.x+btnBattle.width+4, 4);
            btnCopy= initButton( "复制", btnProfile.x+btnProfile.width+50, 4);
            
            txtLogInfo= new TextField;
            txtLogInfo.multiline= true;
            txtLogInfo.wordWrap= true;
            txtLogInfo.type= TextFieldType.INPUT;
            txtLogInfo.y= btnError.y+btnError.height;
            txtLogInfo.width= 400;
            txtLogInfo.height= 500;
            var format:TextFormat= new TextFormat;
            format.color= 0xeeeeee;
            txtLogInfo.defaultTextFormat= format;
            addChild(txtLogInfo);
            
            this.graphics.beginFill(0, 0.5);
            this.graphics.drawRect(-4, 0, this.width+8, this.height);
            this.graphics.endFill();
        }
        
        private function initButton(text:String, x0:Number, y0:Number):Sprite
        {
            var btnText:TextField= new TextField;
            btnText.autoSize= TextFieldAutoSize.LEFT;
            btnText.text = text;
            btnText.selectable= false;
            btnText.mouseEnabled= false;
            
            var btnBg:Sprite= new Sprite;
            btnBg.graphics.beginFill(0x666666, 0.9);
            btnBg.graphics.lineStyle(0, 0, 0.5);
            btnBg.graphics.drawRect(0, 0, 50, 16);
            btnBg.graphics.endFill();
            
            btnText.x= (btnBg.width-btnText.textWidth)/2;
            btnText.y= -2;
            
            btnBg.x= x0;
            btnBg.y= y0;
            
            addChild( btnBg);
            btnBg.addChild( btnText);
            
            return btnBg;
        }
        
        protected function addEventListen():void
        {
            btnError.addEventListener(MouseEvent.CLICK, onClickErrorPage, false, 0, true);
            btnLan.addEventListener(MouseEvent.CLICK, onClickLanPage, false, 0, true);
            btnLog.addEventListener(MouseEvent.CLICK, onClickLogPage, false, 0, true);
			
            btnLoad.addEventListener(MouseEvent.CLICK, onClickDebugBtn, false, 0, true);
			btnBattle.addEventListener(MouseEvent.CLICK, onClickDebugBtn, false, 0, true);
            btnProfile.addEventListener(MouseEvent.CLICK, onClickDebugBtn, false, 0, true);
            
            btnCopy.addEventListener(MouseEvent.CLICK, onClickCopy, false, 0, true);
        }
        
        private function addMessage():void
        {
			Log.updateDispatcher.addEventListener(Log.UPDATE, logUpdateHandler, false, 0, true);
        }
        
        private function removeMessage():void
        {
			Log.updateDispatcher.removeEventListener(Log.UPDATE, logUpdateHandler);
        }
        
        protected function onClickErrorPage(event:MouseEvent):void
        {
            m_state = "Error";
            
            showErrorContent();
        }
        
        protected function onClickLanPage(event:MouseEvent):void
        {
            m_state = "Lan";
            
            showLanContent();
        }
        
        protected function onClickLogPage(event:MouseEvent):void
        {
            m_state = "Log";
            
            showLogContent();
        }
        
        private function onClickDebugBtn(evt:MouseEvent):void
        {
            m_state = "Debug";
            
            if (evt.currentTarget == btnLoad)
                m_debugListIndex = 1;
            else if (evt.currentTarget == btnBattle)
                m_debugListIndex = 2;
            else if (evt.currentTarget == btnProfile)
                m_debugListIndex = 3;
            
            showDebugListContent();
        }
        
        private function logUpdateHandler(event:Event):void
        {
            switch(m_state)
            {
                case "Error":
                    showErrorContent();
                    break;
                case "Log":
                    showLogContent();
                    break;
                case "Lan":
                    showLanContent();
                    break;
                case "Debug":
                    showDebugListContent();
                    break;
            }
        }
        
        private function showErrorContent():void
        {
            var list:Vector.<String> = Log.listError;
            
            setTextInfo(list);
        }
        
        private function showLogContent():void
        {
            var list:Vector.<String> = Log.listLog;
            
            setTextInfo(list);
        }
        
        private function showLanContent():void
        {
            var list:Vector.<String> = Log.listNet;
            
            setTextInfo(list);
        }
        
        private function showDebugListContent():void
        {
            var list:Vector.<String>;
            switch(m_debugListIndex)
            {
                case 0: list = Log.listDebug; break;
                case 1: list = Log.listDebug1; break;
                case 2: list = Log.listDebug2; break;
                case 3: list = Log.listDebug3; break;
            }
            setTextInfo(list);
        }
        
        private function setTextInfo(list:Vector.<String>):void
        {
            if (list == null)
                return;
            
            var result:String="";
            
            for(var i:int=0; i<list.length; i++)
            {
                var text:String = list[i];
                
                result += text + "\n";
            }
            
            txtLogInfo.text = result;
        }
        
        protected function onClickCopy(event:MouseEvent):void
        {
            System.setClipboard(txtLogInfo.text);
        }
		
		public function updatePosition():void
		{
			this.x = 15.45;
			this.y = 25;
		}
    }
}