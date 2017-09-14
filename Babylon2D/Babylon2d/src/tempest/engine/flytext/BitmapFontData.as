package tempest.engine.flytext
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * 图片字资源集
	 * @author zhangyong
	 *
	 */
	public class BitmapFontData 
	{
		/**数字*/
		protected var _clips:Vector.<BitmapData>;
		/**位图*/
		private var _bitmapData:BitmapData;

		public function BitmapFontData(clips:Vector.<BitmapData>)
		{
			_clips=clips;
		}

		/**
		 * 获取图片数字字
		 * @param word
		 * @return
		 *
		 */
		public function getWordBitmapData(word:String, leading:int):BitmapData
		{
			if (_clips == null || _clips.length <= 0)
			{
				return null;
			}
			if (word == null)
			{
				return null;
			}
			var bitmapArr:Array=[];
			var totalWidth:int=0;
			var totalHeight:int=0;
			var len:int=word.length;
			var char:String="";
			var bitmapData:BitmapData;
			var i:int=0;
			for (; i < len; i++)
			{
				char=word.charAt(i);
				switch (char)
				{
					case "-":
						bitmapData=_clips[0];
						break;
					case "+":
						bitmapData=_clips[1];
						break;
					default:
						bitmapData=_clips[parseInt(char) + 2];
						break;
				}
				if (bitmapData == null)
				{
					throw new Error("不支持的字符串：" + char);
				}
				bitmapArr.push(bitmapData);
				if (bitmapData.height > totalHeight)
				{
					totalHeight=bitmapData.height;
				}
				totalWidth+=bitmapData.width + leading;
			}
			totalWidth-=leading;
			_bitmapData=new BitmapData(totalWidth, totalHeight, true, 0xffffff);
			var drawX:Number=0;
			for each (var bmd:BitmapData in bitmapArr)
			{
				_bitmapData.copyPixels(bmd, new Rectangle(0, 0, bmd.width, bmd.height), new Point(drawX, 0));
				drawX+=bmd.width + leading;
			}
			return _bitmapData;
		}
	}
}

