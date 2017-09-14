package easiest.utils
{
    import flash.utils.ByteArray;

    public final class XMLUtil
    {
        /**
         * 脱根函数 
         * @param xml 数据源
         * @param rootCount 脱根数
         * @return 脱完根的xml
         */		
        public static function cutRoot(xml:XML, rootCount:uint = 2):XML
        {
            while(rootCount > 0)
            {
                xml = xml.children()[0];
                rootCount --;
            }
            return xml;
        }
        
        /**
         * 将二进制数据转化为XML 
         * @param byteArray 要转化的二进制数据
         * @return 转化后的的XML
         */
        public static function getXmlFromByteArray(byteArray:ByteArray):XML
        {
            var str:String = byteArray.readMultiByte(byteArray.length, "utf-8");                
            return XML(str);
        }
    }
}