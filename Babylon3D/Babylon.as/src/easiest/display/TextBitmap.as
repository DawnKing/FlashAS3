package easiest.display
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.filters.BitmapFilter;
    import flash.filters.GlowFilter;
    import flash.text.TextField;
    import flash.text.TextFormat;
    
    import easiest.core.IDispose;
    
    /**
     * 注意，一定要不频繁换文本内容才可以使用此类，draw很耗性能
     * 位图文本（TextField 的位图实现类），在不频繁变换文本内容的时候使用此类
     * 截至SDK4.6，FLASH本身的文本显示效率仍然极差，在显示1000个TextField并做地图移动情况下，双核CPU负载已经高于80%，绘制成位图负载减低到20%
     *             
     * 如果要设置html语句，不要对本类设颜色，包括TextFormat和textColor
     *      textBitmap = new TextBitmap;
     *      textBitmap.textFormat = new TextFormat(FontStyleGlobe.STANDARD_CHINESE_TYPE_STYLE, 14);
     *      textBitmap.textField.textColor = ColorDefine.WHITE;
     *      textBitmap.addFilter(FontStyleGlobe.BLACK_GLOW_4);
     *      textBitmap.text = name;
     *      textBitmap.x = -textBitmap.width / 2;
     * @author caijingxiao
     * 
     */
    public class TextBitmap extends Bitmap implements IDispose
    {
        private var m_text:String = "";  // 文本
        private var m_textFormat:TextFormat = new TextFormat;   // 字符格式
        private var m_extraWidth:Number = 0.0;// 额外增加的宽度
        private var m_extraHeight:Number = 0.0;// 额外增加的高度
        private var m_filters:Array = [];    // 滤镜
        private var m_textWidth:Number = -1;    // 自定义文本宽
        private var m_textHeight:Number = -1; // 自定义文本高
        private var m_background:uint = 0x00000000; // 背景填充色

        private var m_textField:TextField;
       
        public function TextBitmap(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=false)
        {
            super(bitmapData, pixelSnapping, smoothing);

            m_textField = new TextField();
            m_textField.mouseEnabled = false;
        }
        
        public function dispose():void
        {
            if (this.bitmapData != null)
                this.bitmapData.dispose();
            m_textFormat = null;
            m_textField = null;
            m_filters = null;
        }
        
        private function updateText():void
        {
            m_textField.htmlText = text;
            
            m_textField.width = (m_textWidth == -1) ? m_textField.textWidth + m_extraWidth + 4 : m_textWidth;
            m_textField.height = (m_textHeight == -1) ? m_textField.textHeight + m_extraHeight + 4 : m_textHeight;
            
            var textBitmapData:BitmapData = drawBitmapData(m_textField);
            
            if (this.bitmapData != null)
                this.bitmapData.dispose();
            this.bitmapData = textBitmapData;
        }

        protected function drawBitmapData(m_textField:TextField):BitmapData
        {
            var textBitmapData:BitmapData = new BitmapData(m_textField.width, m_textField.height, true, background);
            textBitmapData.draw(m_textField);
            return textBitmapData;
        }
        
        /**
         * 加入图像滤镜效果
         */
        public function addFilter(filter:BitmapFilter):void
        {
            if (m_filters.indexOf(filter) != -1)
                return;
            m_filters.push(filter);
            if (filter is GlowFilter)
            {
                m_extraWidth = GlowFilter(filter).blurX;
                m_extraHeight = GlowFilter(filter).blurY;
            }
            m_textField.filters = m_filters;
        }
        
        public function setColor(color:uint):void
        {
            m_textFormat.color = color;
            m_textField.defaultTextFormat = m_textFormat;
            updateText();
        }

        /**
         * 字符格式
         * 如果要用html控制颜色，就不能在TextFormat中设置颜色
         */
        public function get textFormat():TextFormat
        {
            return m_textFormat;
        }
        /**
         * @private
         */
        public function set textFormat(value:TextFormat):void
        {
            m_textFormat = value;
            m_textField.defaultTextFormat = m_textFormat;
        }

        public function get text():String
        {
            return m_text;
        }

        /**
         * @private
         */
        public function set text(value:String):void
        {
            if (m_text == value)
                return;
            m_text = value;
            updateText();
        }

        /**
         * 用于填充位图图像区域的 32 位 ARGB 颜色值。默认值为 0x00000000。
         */
        public function get background():uint
        {
            return m_background;
        }

        /**
         * @private
         */
        public function set background(value:uint):void
        {
            if (m_background == value)
                return;
            m_background = value;
        }

        public function get textField():TextField
        {
            return m_textField;
        }
        
        public function set textWidth(value:Number):void
        {
            m_textWidth = value;
        }

        public function get textWidth():Number
        {
            return m_textWidth == -1 ? m_textField.width : m_textWidth;
        }
        
        public function set textHeight(value:Number):void
        {
            m_textHeight = value;
        }

        public function get textHeight():Number
        {
            return m_textHeight == -1 ? m_textField.height : m_textHeight;
        }

        override public function get width():Number
        {
            return (this.bitmapData == null) ? 0 : this.bitmapData.width;
        }

        override public function get height():Number
        {
            return (this.bitmapData == null) ? 0 : this.bitmapData.height;
        }

        public function set textColor(color:uint):void
        {
            m_textField.textColor = color;
        }
    }
}