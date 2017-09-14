/**
 * Created by caijingxiao on 2016/2/19.
 */
package easiest.core
{
    import easiest.managers.load.AssetManager;
    import easiest.managers.FrameManager;
    import easiest.managers.KeyboardManager;
    import easiest.managers.TimerManager;

    import flash.display.Stage;

    public final class EasiestCore
    {
        private static const CLASS_NAME:String = "EasiestCore";
        public static const EASIEST_VERSION:String = "201707072";
        public static var VERSION:String = "?t=";         // 文件URL后跟随的版本号 例如 http://www.abc.cn/config.xml?t=0718;
        private static var m_spf:Number;// 秒/帧 Second Per Frames
        private static var m_fps:int;      // 游戏运行帧数的设定
        private static var m_stage:Stage;
        private static var m_stageWidth:int = 1920; // 舞台宽度
        private static var m_stageHeight:int = 1080;    // 舞台高度
        private static var m_isDebug:Boolean = true;   // 是否是debug版本

        public static var PATH:String = "assets/";
        public static var LANGUAGE:String = "zh_CN";

        public static const MIN_WIDTH:int  = 1366;  // 游戏的最小宽度
        public static const MIN_HEIGHT:int = 768;   // 游戏的最小高度

        public static function start(sg:Stage, isDebug:Boolean = true):void
        {
            if (isDebug && m_stage)
                throw new Error("不能重复创建EasiestCore");
            Log.log(EASIEST_VERSION, CLASS_NAME);

            m_isDebug = isDebug;
            m_stage = sg;
            setStageSize();

            m_fps = m_stage.frameRate;
            m_spf = 1000 / m_fps;
            FrameManager.start(m_stage);
            TimerManager.start();
            AssetManager.start();
            KeyboardManager.start(m_stage);

            if (isDebug)
                Log.MAX_LOG_COUNT = 200;
        }

        public static function get isDebug():Boolean
        {
            return m_isDebug;
        }

        public static function setStageSize():void
        {
            m_stageWidth = Math.max(MIN_WIDTH, m_stage.stageWidth);
            m_stageHeight = Math.max(MIN_HEIGHT, m_stage.stageHeight);
        }

        public static function get stage():Stage
        {
            return m_stage;
        }

        public static function get frameRate():int
        {
            return m_fps;
        }

        public static function get spf():Number
        {
            return m_spf;
        }

        public static function get stageWidth():int
        {
            return m_stageWidth;
        }

        public static function get stageHeight():int
        {
            return m_stageHeight;
        }
    }
}