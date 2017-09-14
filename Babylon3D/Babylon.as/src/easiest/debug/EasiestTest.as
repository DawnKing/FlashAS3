package easiest.debug
{
    import easiest.managers.AssetManager;
    import easiest.managers.FrameManager;

    public final class EasiestTest
    {
        public function EasiestTest()
        {
            
        }
        public static function start():void
        {
            FrameManager.add(processTest, FrameManager.REAL_TIME);
        }
        
        private static function processTest():void
        {
            AssetManager.processTest();
        }
    }
}