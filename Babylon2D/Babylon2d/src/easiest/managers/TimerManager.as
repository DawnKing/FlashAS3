package easiest.managers
{
    import easiest.core.Log;

    import flash.system.Security;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import easiest.utils.ObjectUtil;

	/**
	 * 计时器管理器，经过多少毫秒回调一次函数
	 * TimerManager.remove(updateServerTime);
	 * @author caijingxiao
	 * 
	 */
	public final class TimerManager
	{
        private static const CLASS_NAME:String = "TimerManager";
        private static var m_callbackList:Dictionary = new Dictionary(true);	// 回调函数列表
        
		public static function start():void
		{
            FrameManager.add(process, FrameManager.REAL_TIME);
		}	
        
		public static function dispose():void
		{
			stopTimer();
		}
        
		/**
		 * 增加定时器，会先执行callback，然后删除callback，注意不要在callback中再次add
		 * @param updateFunction 时间到回调函数
		 * @param interval 间隔时间（毫秒）
         * @param repeatCount (default = 0) — 指定重复次数。如果为 0，则计时器重复无限次数。如果不为 0，则将运行计时器，运行次数为指定的次数，然后停止。 
		 * @param keepRate 帧补偿
		 */
		public static function add(updateFunction:Function, interval:int, repeatCount:int = 0, keepRate:Boolean = false):void
		{
            if (updateFunction.prototype != null) // 闭包函数不为空，不允许使用闭包函数，会无限加入回调
                throw new Error("函数格式错误");
			// 删除旧的注册函数
            if (updateFunction in m_callbackList)
                remove(updateFunction);                                
            
            var timeData:TimeData = new TimeData;
            timeData.intervalTime = interval;
            timeData.nextTime = FrameManager.time + interval;
            timeData.callback = updateFunction;
            timeData.repeatCount = repeatCount;
            timeData.keepRate = keepRate;
            
            m_callbackList[updateFunction] = timeData;
		}
        
        public static function update(updateFunction:Function, interlval:int):void
        {
            var timeData:TimeData = m_callbackList[updateFunction];
            timeData.nextTime = FrameManager.time + interlval;
        }
        
        public static function contains(func:Function):Boolean
        {
            return func in m_callbackList;
        }
        
        /**
         * 移除定时更新器
         */
        public static function remove(updateFunction:Function):void
        {
            if (!(updateFunction in m_callbackList))
                return;
            delete m_callbackList[updateFunction];
        }
        
		private static function process():void
		{
            var currTime:int = FrameManager.time;
            
            for each (var timeStruct:TimeData in m_callbackList)
            {
                // 计时器的时间未到
                if (timeStruct.nextTime > currTime)                 
                    continue;
                var intervalTime:int = currTime - timeStruct.nextTime;
                
                while (intervalTime >= 0)
                {
                    intervalTime -= timeStruct.intervalTime;
                    
                    if (Security.sandboxType == Security.LOCAL_TRUSTED)
                    {
                        var time:uint = getTimer();
                        
                        timeStruct.callback();      
                        
                        time = getTimer()-time;
                        if (time > 2)
                            Log.debug3(new Date().toTimeString()+"单函数毫秒="+time+ObjectUtil.getFunctionDebugInfo(timeStruct.callback), CLASS_NAME);
                    }
                    else
                    {
                        timeStruct.callback();
                    }
                    // 会先执行callback，然后删除callback，注意不要在callback中再次add
                    if (timeStruct.repeatCount != 0)
                    {
                        timeStruct.repeatCount--;
                        if (timeStruct.repeatCount == 0)
                        {
                            remove(timeStruct.callback);
                            break;
                        }
                    }
                    timeStruct.nextTime = timeStruct.nextTime + timeStruct.intervalTime;
                    
                    if (!timeStruct.keepRate)
                        break;
                    // 保持帧率，如果剩余间隔时间小于指定的间隔时间（还没到时间），本次不执行
                    if (intervalTime < timeStruct.intervalTime)
                        break;
                }
            }
		}
        
		// 停止定时器
		private static function stopTimer():void
        {
            FrameManager.remove(process);
        }
        
        public static function getFunctionList():String
        {
            if (Security.sandboxType != Security.LOCAL_TRUSTED)
                return "";
            var result:String = "";
            var i:int = 0;
            for each (var timeStruct:TimeData in m_callbackList)
            {
                result += i++ % 8 == 0 && i != 0 ? "\n" : "  |  ";
                result += ObjectUtil.getFunctionDebugInfo(timeStruct.callback) + "  ";   
            }
            return result;
        }    
    }
}
internal class TimeData
{
	public var intervalTime:int;                          // 间隔多久触发
	public var nextTime:int;                              // 下一次触发时间
	public var callback:Function;                       // 时间触发回调函数
    public var repeatCount:int = 0;
	public var keepRate:Boolean;                  // 是否帧数补偿
}	