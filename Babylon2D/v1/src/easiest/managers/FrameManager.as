package easiest.managers
{
    import easiest.core.Log;
    import easiest.unit.Assert;
    import easiest.utils.ObjectUtil;

    import flash.display.Stage;
    import flash.events.Event;
    import flash.system.Security;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;

    /**
     * 帧运算管理器
     * 负责管理所有注册对象的enterFrame函数，对每帧一定要计算的和卡的时候可以跳帧的进行区分处理
     * 使用方法FrameManager.add(process);
     * 
     * @author caijingxiao
     * 
     */
    public final class FrameManager
    {
        private static const CLASS_NAME:String = "FrameManager";
        public static const REAL_TIME:int = 5;
        public static const HIGH:int = 4;
        public static const ABOVE_NORMAL:int = 3;
        public static const NORMAL:int = 2;
        public static const BELOW_NORMAL:int = 1;
        public static const IDLE:int = 0;
        
        public static var frameRate:int = 1;    // 帧速度
        private static var _isInterpolation:Boolean = false;  // 帧补偿中

        private static var _fps:int; // 帧/秒 Frames Per Second
        private static var _spf:Number;// 秒/帧 Second Per Frames
        private static var _processList:Vector.<Dictionary> = new Vector.<Dictionary>(6, true);  // 处理函数列表
        private static var _priorityTime:Vector.<int> = new Vector.<int>(6, true); // 优先级时间，用于跳帧处理
        
        private static var _lastFrameTimestamp:int = 0; // 上一帧启动 Flash 运行时虚拟计算机以来经过的毫秒数
        private static var _timer:Number = 0.0;  // 启动FrameManager以来经过的毫秒数
        private static var _currentFrameTime:uint;    // 当前帧所用的总时间，从退出上一帧开始计算，直到当前帧所有计算完
        private static var _serverTime:uint = 0;	// 服务器时间
        
        // 计算分数
        private static const SAMPLE_COUNT:int = 10; // 间隔几帧计算帧分数
        private static var _frameCount:uint;    // 计算总帧数
        private static var _frameScore:int;    // 帧分数
        private static var _frameAvgScoreIndex: int = 0;
        private static var _frameAvgScore:Vector.<int> = new Vector.<int>(SAMPLE_COUNT, true); // 平均帧分数
        private static var _lastScoreTime:int;

        private static var _isDebug:Boolean;
        
        public static function start(stage:Stage):void
        {
            if (_fps != 0)
                return;
            _fps = stage.frameRate;
            _spf = 1000 / _fps;

            const LOWEST:int = 24;  // 至少保证不低于多少帧数
            for (var i:int = 0; i < 6; i++)
            {
                _processList[i] = new Dictionary;
                _priorityTime[i] = 1000 / (LOWEST - i * LOWEST / 6);
            }
            stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            
            _frameCount = 0;
            add(processFrameCount, REAL_TIME);
            
            _isDebug = Security.sandboxType == Security.LOCAL_TRUSTED;
        }
        
        /**
         * 注册每帧运行函数
         * 由于使用Dictionary，所以先加入的函数并不一定会先运行
         * @param processFunction 处理函数，函数格式Function(passedTime:int)，passedTime表示上一帧到当前帧所经过的毫秒数
         * @param priority 优先级，默认为FrameManager.NORMAL
         * 
         */
        public static function add(processFunction:Function, priority:int=NORMAL):void
        {
            if (processFunction.prototype != null) // 闭包函数不为空，不允许使用闭包函数，会无限加入回调
                throw new Error("函数格式错误");
            if (_processList[priority][processFunction] == undefined)
                _processList[priority][processFunction] = processFunction;
        }
        
        /**
         * 移除每帧运行函数
         * @param processFunction 处理函数
         */
        public static function remove(processFunction:Function) : void
        {
            for (var i:int = 0; i < _processList.length; i++)
            {
                if (_processList[i][processFunction] != undefined)
                {
                    delete _processList[i][processFunction];
                    break;
                }
            }
        }
        
        // 进入帧时候触发事件        
        private static function onEnterFrame(event:Event):void
        {
            var now:int = getTimer();
            var passedTime:int = now - _lastFrameTimestamp;    // 上一帧到当前帧所经过的时间

            _timer += passedTime * frameRate;
            Assert.assertEquals1(_timer, now);

            _serverTime += passedTime;
            _frameCount++;

            var funRepeatTime:int = getFunctionRepeatTime(now);
            funRepeatTime *= frameRate;

            var processTime:Number = passedTime / funRepeatTime;
            _isInterpolation = false;
            for (var i:int = 0; i < funRepeatTime; i++) 
            {
                process(passedTime, processTime, funRepeatTime);
                _isInterpolation = funRepeatTime > 1;
            }

            // 经过process后的时间
            _currentFrameTime = getTimer() - _lastFrameTimestamp;
            
            _lastFrameTimestamp = now;
            
            if (_isDebug)
            {
                passedTime = getTimer() - now;
                if (passedTime > 40)
                {
                    var str:String = new Date().toTimeString()+"帧毫秒="+passedTime+" "+funRepeatTime;
                    str += getFunctionList();
                    Log.debug3(str, CLASS_NAME);
                }
            }
        }
        
        private static function process(passedTime:int, processTime:Number, funRepeatTime:int):void
        {
            // 实时每帧都运行
            for each (callback in _processList[REAL_TIME])
            {
                if (_isDebug)
                {
                    var time:uint = getTimer();
                    
                    callbackHandler(callback, processTime);
                    
                    time = getTimer()-time;
                    if (time > 4)
                        Log.debug3(new Date().toTimeString()+"r单函数毫秒="+time+ObjectUtil.getFunctionDebugInfo(callback), CLASS_NAME);
                }
                else
                {
                    callbackHandler(callback, processTime);
                }
            }

            for (var i:int = HIGH; i >= IDLE; --i)
            {
                if (passedTime > _priorityTime[i]) // 跳帧处理
                {
                    if (funRepeatTime <= 1) // funRepeatTime>1 表示帧补偿，帧补偿时不跳帧
                        continue;
                }
                for each (var callback:Function in _processList[i])
                {
                    if (_isDebug)
                    {
                        time = getTimer();
                        
                        callbackHandler(callback, processTime);
                        
                        time = getTimer()-time;
                        if (time > 4)
                            Log.debug3(new Date().toTimeString()+"单函数毫秒="+time+ObjectUtil.getFunctionDebugInfo(callback), CLASS_NAME);
                    }
                    else
                    {
                        callbackHandler(callback, processTime);
                    }
                }
            }
        }
        
        private static function callbackHandler(callback:Function, passedTime:Number):void
        {
            if (callback.length == 0)
                callback();
            else
                callback(passedTime);                
        }
        
        /**
         * 包含回调函数
         */
        public static function contains(processFunction:Function):Boolean
        {
            for (var i:int = 0; i < _processList.length; i++)
            {
                if (_processList[i][processFunction] != undefined)
                    return true;
            }
            return false;
        }

        private static function processFrameCount():void
        {
            if (_isInterpolation)
                return;
            // 实时计算当前流畅度，返回一个分数0-100
            if (_frameCount % SAMPLE_COUNT != 0)
                return;

            _frameScore = _spf / ((_timer - _lastScoreTime) / SAMPLE_COUNT) * 100;
            if (_lastScoreTime == 0)
                _frameScore = 100;
            _lastScoreTime = _timer;

            _frameAvgScore[_frameAvgScoreIndex++] = _frameScore;
            if (_frameAvgScoreIndex >= SAMPLE_COUNT)
                _frameAvgScoreIndex = 0;
        }

        // 计算补偿帧数 (当屏幕最小化，flash会自动降低帧数运行在2帧和8帧--播放背景音乐时，当移动什么需要24帧计算的函数就自己进行补偿)
        private static function getFunctionRepeatTime(currTime:int):int
        {
            if (_lastFrameTimestamp == 0)
                return 1;

            var delayTime:int = currTime - _lastFrameTimestamp;         // 上一次渲染到现在的时间
            if (delayTime <= 100 || delayTime >= 1000)// >=1000 避免恢复时补偿计算量过大
                return 1;
            
            return Math.floor(delayTime * _fps / 1000);  // 要取下限值，如果取四舍五入或者上限值相当于加速了
        }

        /**
         * 启动FrameManager以来经过的毫秒数
         */
        public static function get timer():Number
        {
            return _timer;
        }
        
        public static function get currentFrameTime():uint
        {
            return _currentFrameTime;
        }
        
        // 同步服务器时间
        public static function setServerTime(time:uint):void
        {
            _serverTime = time;
        }
        
        public static function get serverTime():Number
        {
            return _serverTime;
        }

        // 性能分数0-100
        public static function get frameScore():int
        {
            var avgScore:int = 0;
            for each (var score:int in _frameAvgScore)
            {
                avgScore += score;
            }
            return Math.min(_frameScore, avgScore / SAMPLE_COUNT);
        }

        public static function get frameCount():uint
        {
            return _frameCount;
        }
        
        //-----------------------------------------------------------------------------------------
        // DEBUG
        //-----------------------------------------------------------------------------------------
        public static function getFunctionList():String
        {
            if (!_isDebug)
                return "";
            var result:String = "";
            var i:int = 0;
            for (var j:int = REAL_TIME; j >= IDLE; --j) 
            {
                for each (var callback:Function in _processList[j])
                {
                    result += i++ % 8 == 0 && i != 0 ? "\n" : "  |  ";
                    result += ObjectUtil.getFunctionDebugInfo(callback)+ "  ";   
                }
            }
            return result;
        }      
    }
}
