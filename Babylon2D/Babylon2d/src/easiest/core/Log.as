package easiest.core
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    import easiest.utils.NameUtil;
    
	/**
	 * 日志
	 * @author caijingxiao
	 * 
	 */
    public final class Log
    {
		/**
		 * 最大日志条数 
		 */
		public static var MAX_LOG_COUNT:int = 500;
        
		/**
		 * 日志更新
		 */
		public static var UPDATE:String = "Log.update";   
        
		/**
		 * 事件分发器
		 */
		public static var updateDispatcher:EventDispatcher = new EventDispatcher;	
        
		/**
		 * debug列表
		 */
		public static var listDebug:Vector.<String> = new Vector.<String>;
        
		/**
		 * 日志列表
		 */
		public static var listLog:Vector.<String> = new Vector.<String>;
        
		/**
		 * 错误列表
		 */
		public static var listError:Vector.<String> = new Vector.<String>;
        
		/**
		 * 网络列表
		 */
		public static var listNet:Vector.<String> = new Vector.<String>;
		
		/**
		 * 记录调试信息
		 */
		public static function debug(content:String, className:Object=null):void
		{
			if (listDebug.length >= MAX_LOG_COUNT)
				listDebug.pop();
			if (className != null)
				content += "   @" + NameUtil.getUnqualifiedClassName(className);
			listDebug.unshift(content);
			updateDispatcher.dispatchEvent(new Event(UPDATE));
		}
        
		/**
		 * 记录日志
		 */
		public static function log(content:String, className:Object=null):void
		{
			if (listLog.length >= MAX_LOG_COUNT)
				listLog.pop();
			if (className != null)
				content += "   @" + NameUtil.getUnqualifiedClassName(className);
			listLog.unshift(content);
            trace(content);
			updateDispatcher.dispatchEvent(new Event(UPDATE));
		}
        
		/**
		 * 记录错误
		 */
		public static function error(content:String, className:Object=null):void
		{
			if (listError.length >= MAX_LOG_COUNT)
				listError.pop();
			if (className != null)
				content += "   @" + NameUtil.getUnqualifiedClassName(className);
			listError.unshift(content);
            trace(content);
			updateDispatcher.dispatchEvent(new Event(UPDATE));
		}
        
		/**
		 * 记录网络协议
		 */
		public static function net(content:String, className:Object=null):void
		{
			if (listNet.length >= MAX_LOG_COUNT)
				listNet.pop();
			if (className != null)
				content += "   @" + NameUtil.getUnqualifiedClassName(className);
			listNet.unshift(content);
			updateDispatcher.dispatchEvent(new Event(UPDATE));
		}
        
        /**
         * 调试列表1
         */
        public static var listDebug1:Vector.<String> = new Vector.<String>;
        
        /**
         * 调试列表1
         */
        public static function debug1(content:String, className:Object=null):void
        {
            if(listDebug1.length >= MAX_LOG_COUNT)
                listDebug1.pop();
            if (className != null)
                content += "   @" + NameUtil.getUnqualifiedClassName(className);
            listDebug1.unshift(content);
            updateDispatcher.dispatchEvent(new Event(UPDATE));
        }
        
        /**
         * 调试列表2
         */
        public static var listDebug2:Vector.<String> = new Vector.<String>;
        
        /**
         * 调试列表2
         */
        public static function debug2(content:String, className:Object=null):void
        {
            if(listDebug2.length >= MAX_LOG_COUNT)
                listDebug2.pop();
            if (className != null)
                content += "   @" + NameUtil.getUnqualifiedClassName(className);
            listDebug2.unshift(content);
            updateDispatcher.dispatchEvent(new Event(UPDATE));
        }
        
        /**
         * 调试列表3
         */
        public static var listDebug3:Vector.<String> = new Vector.<String>;
        
        /**
         * 调试列表3
         */
        public static function debug3(content:String, className:Object=null):void
        {
            if(listDebug3.length >= MAX_LOG_COUNT)
                listDebug3.pop();
            if (className != null)
                content += "   @" + NameUtil.getUnqualifiedClassName(className);
            listDebug3.unshift(content);
            updateDispatcher.dispatchEvent(new Event(UPDATE));
        }
    }
}