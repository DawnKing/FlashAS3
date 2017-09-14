package easiest.display
{
    import easiest.core.IDispose;
    import easiest.core.Log;

    import flash.display.Loader;
    import flash.events.ErrorEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;

	/**
	 * 除了一些特殊情况，否者不使用此类，统一使用AssetManager
     * 复用loader的时候需要注意：
     * 1、loadBytes之后不能马上close
     * 2、load也会出现不能马上close的情况（小概率）
	 * @author caijingxiao
	 * 
	 */
    public class LoaderExtend extends Loader implements IDispose
    {
		private static var m_md5UrlFunc:Function;	//加载地址转换函数
		
		public var assetUrl:String;
		
		private var m_errorCount:int=0;	// 加载错误次数
		
		private var m_md5Url:String;
        private var m_request:URLRequest = new URLRequest;
		
		
		public static function setMd5UrlFunc(func:Function):void
		{
			m_md5UrlFunc = func;
		}
                
        public function LoaderExtend()
        {
        	super();
            
            this.mouseChildren = false;
            this.mouseEnabled = false;
            
            this.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError, false, 0, true);
        }
        
        public function dispose():void
        {
            this.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
            m_request = null;
            stop();
        }
        
        public function stop():void
        {
            if (content != null)
                this.unloadAndStop(false);
            else
                close();
        }
        
        override public function close():void
        {
            try
            {
                super.close();
            }
            catch (error:Error)
            {
            }
        }
		
		public function loadURL(url:String):void
		{
            assetUrl = url;
			m_md5Url = md5Url(assetUrl);
            m_request.url = m_md5Url;
			load(m_request);
		}
		
		private function md5Url(url:String):String
		{
			if (m_md5UrlFunc != null)
				return m_md5UrlFunc(url, this);
			return url;
		}
        
        private function onLoadError(event:IOErrorEvent):void
        {
        	m_errorCount++;
            
        	if (m_errorCount > 2)
        	{
                m_errorCount = 0;
				Log.error(event.text+"加载错误:url="+assetUrl+" md5Url="+m_md5Url, this);
                this.close();
                
                if (this.hasEventListener(ErrorEvent.ERROR))
        		    this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
        		return;
        	}	
            
            var saveUrl:String = m_request.url; // 保存原有url，后面不带?v=
            loadURL(m_request.url + "?v=" + m_errorCount);
            m_request.url = saveUrl;
        }
    }
}