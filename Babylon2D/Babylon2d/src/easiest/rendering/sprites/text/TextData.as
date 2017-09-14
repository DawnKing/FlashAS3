package easiest.rendering.sprites.text
{
    import easiest.rendering.materials.textures.BitmapTexture;

    /**
	 * 称号名字数据对象
	 * @author zhangyong
	 *
	 */
	public class TextData
	{
		/**文本内容*/
		public var text:String;
		/**颜色*/
		public var color:uint;
		/**是否绘制背景*/
		public var isBg:Boolean;
		/**宽度*/
		public var width:int;
		/**高度*/
		public var height:int;

		/**监听*/
		private var _listeners:Vector.<Function>=new Vector.<Function>();

        public var u:Number;
        public var v:Number;
        public var uvWidth:int;
        public var uvHeight:int;
		
		public function TextData()
		{
		}

		/**
		 * 引用计数器
		 */
		public function get refCounter():int
		{
			return _listeners.length;
		}

		/**
		 * 添加监听
		 * @param fun
		 *
		 */
		public function addListener(fun:Function):void
		{
			if (_listeners.indexOf(fun) == -1)
			{
				_listeners.push(fun);
			}
		}

		/**
		 *　移除监听
		 * @param fun
		 *
		 */
		public function removeListener(fun:Function):void
		{
			var idx:int=_listeners.indexOf(fun);
			if (idx != -1)
			{
				_listeners.splice(idx, 1);
			}
		}

		public function dispose():void
		{
			_listeners.length=0;
		}

        public function update(baseTexture:BitmapTexture):void
        {
            for (var i:int=0; i < _listeners.length; i++)
            {
                _listeners[i](baseTexture);
            }
        }
    }
}
