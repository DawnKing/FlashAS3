package easiest.display
{
    /**
     * 大量复用Loader的情况下，一会load一会loadBytes极易出现加载错误的情况
     * 因此分开来使用
     * @author caijingxiao
     * 
     */
    public final class LoaderBytes extends LoaderExtend
    {
        public function LoaderBytes()
        {
            super();
        }
    }
}