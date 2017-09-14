package easiest.net
{
    import flash.events.ErrorEvent;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    
    import easiest.core.IDispose;
    import easiest.core.Log;
    
    /**
     * 加载出错
     */
    [Event(name="error", type="flash.events.ErrorEvent")]
	/**
     * 除了一些特殊情况，否者不使用此类，统一使用AssetManager
	 * @author caijingxiao
	 * 
	 */	
    public class URLLoaderExtend extends URLLoader implements IDispose
    {
		private static var m_md5UrlFunc:Function;	//加载地址转换函数
		
        private var m_errorCount:int = 0;	// 错误次数
		
		private var m_url:String;
		private var m_md5Url:String;
        private var m_urlRequest:URLRequest = new URLRequest;
		
		public static function setMd5UrlFunc(func:Function):void
		{
			m_md5UrlFunc = func;
		}
		
        public function URLLoaderExtend()
        {
        	super();
            
            this.addEventListener(IOErrorEvent.IO_ERROR, onLoadError, false, 0, true);
            this.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, true);  
        }
		
        public function dispose():void
        {
            this.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
            this.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);  
            
			close();
            m_urlRequest = null;
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
			m_url = url;
			m_md5Url= md5Url(m_url);
            m_urlRequest.url = m_md5Url;

			load(m_urlRequest);
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
			
			if (m_errorCount > 1)// 如果下载失败，换一个版本号重新下载一次
            {
                m_errorCount = 0;
            	Log.error("加载错误:url=" + m_url + " md5Url=" + m_md5Url, this);
                this.close();
                
                if (this.hasEventListener(ErrorEvent.ERROR))
                    this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
            	return;
            }	
            
			var saveUrl:String = m_urlRequest.url; // 保存原有url，后面不带?v=
			loadURL(m_urlRequest.url + "?v=" + m_errorCount);
            m_urlRequest.url = saveUrl;
        }      
        
        private function onSecurityError(event:SecurityErrorEvent):void
        {
			Log.error(event.text+"加载载安全沙箱错误:"+event.errorID, this);
            this.close();
        }
        
		public function get url():String
		{
			return m_url;
		}
    }
}