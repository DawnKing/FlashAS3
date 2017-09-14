package game.base
{
    import easiest.rendering.filters.*;
    import easiest.rendering.filters.ColorMatrixFilter;

    import flash.filters.GlowFilter;

	/**
	 * 滤镜
	 * @author zhangyong
	 *
	 */
	public class FilterEnum
	{ /**清除滤镜*/
		public static const FILTERNONE:int=0;
		/**白色滤镜*/
		public static const FILTERWHITE:int=1;
		/**红色滤镜*/
		public static const FILTERRED:int=2;
		/**绿色滤镜*/
		public static const FILTERGREEN:int=3;
		/**金色*/
		public static const FILTERGOLDEN:int=4;
		/**蓝色*/
		public static const FILTERBLUE:int=5;
		private static var _sgrayFilter:ColorMatrixFilter;

		/**s灰色滤镜*/
		public static function get sgrayFilter():ColorMatrixFilter
		{
			if (!_sgrayFilter)
			{
				_sgrayFilter=new ColorMatrixFilter(Vector.<Number>([0.3086, 0.6094, 0.082, 0, 0, 0.3086, 0.6094, 0.082, 0, 0, 0.3086, 0.6094, 0.082, 0, 0, 0, 0, 0, 1, 0]));
			}
			return _sgrayFilter;
		}

		private static var _sredFilter:ColorMatrixFilter;

		/**s击打红色效果*/
		public static function get sredFilter():ColorMatrixFilter
		{
			if (!_sredFilter)
			{
				_sredFilter=new ColorMatrixFilter(Vector.<Number>([1, 0, 0, 0, 200, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]));
			}
			return _sredFilter;
		}

		private static var _swhiteFilter:ColorMatrixFilter;

		/**s击打白色效果*/
		public static function get swhiteFilter():ColorMatrixFilter
		{
			if (!_swhiteFilter)
			{
				_swhiteFilter=new ColorMatrixFilter(Vector.<Number>([1.2, 0, 0, 0, 50.900000000000006, 0, 1.2, 0, 0, 50.900000000000006, 0, 0, 1.2, 0, 50.900000000000006, 0, 0, 0, 1, 0]));
			}
			return _swhiteFilter;
		}
		private static var _sgreenFilter:ColorMatrixFilter;

		/**s击打绿色效果*/
		public static function get sgreenFilter():ColorMatrixFilter
		{
			if (!_sgreenFilter)
			{
				_sgreenFilter=new ColorMatrixFilter(Vector.<Number>([-0.2905729319064281, 0.3362117866513358, 0.9543611452550924, 0, -35, 0.4278579244119142, 0.7325123078638986, -0.1603702322758129, 0, 100, -0.42821158929885533, 1.6525337270883256, -0.22432213778947024, 0, -35, 0, 0, 0, 1, 0]));
			}
			return _sgreenFilter;
		}

		private static var _sgoldenFilter:ColorMatrixFilter;

		/**s击打金色效果*/
		public static function get sgoldenFilter():ColorMatrixFilter
		{
			if (!_sgoldenFilter)
			{
				_sgoldenFilter=new ColorMatrixFilter(Vector.<Number>([1, 0, 0, 0, 160, 0, 1, 0, 0, 160, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]));
			}
			return _sgoldenFilter;
		}

		private static var _sblueFilter:ColorMatrixFilter;

		/**s击打蓝色效果*/
		public static function get sblueFilter():ColorMatrixFilter
		{
			if (!_sblueFilter)
			{
				_sblueFilter=new ColorMatrixFilter(Vector.<Number>([1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 160, 160, 0, 0, 0, 0, 1, 0]));
			}
			return _sblueFilter;
		}


		private static var _grayFilter:flash.filters.ColorMatrixFilter;

		/**灰色滤镜*/
		public static function get grayFilter():flash.filters.ColorMatrixFilter
		{
			if (!_grayFilter)
			{
				_grayFilter=new flash.filters.ColorMatrixFilter([0.3086, 0.6094, 0.082, 0, 0, 0.3086, 0.6094, 0.082, 0, 0, 0.3086, 0.6094, 0.082, 0, 0, 0, 0, 0, 1, 0]);
			}
			return _grayFilter;
		}

		private static var _redFilter:flash.filters.ColorMatrixFilter;

		/**击打红色效果*/
		public static function get redFilter():flash.filters.ColorMatrixFilter
		{
			if (!_redFilter)
			{
				_redFilter=new flash.filters.ColorMatrixFilter([1, 0, 0, 0, 200, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]);
			}
			return _redFilter;
		}

		private static var _whiteFilter:flash.filters.ColorMatrixFilter;

		/**击打白色效果*/
		public static function get whiteFilter():flash.filters.ColorMatrixFilter
		{
			if (!_whiteFilter)
			{
				_whiteFilter=new flash.filters.ColorMatrixFilter([1.2, 0, 0, 0, 50.900000000000006, 0, 1.2, 0, 0, 50.900000000000006, 0, 0, 1.2, 0, 50.900000000000006, 0, 0, 0, 1, 0]);
			}
			return _whiteFilter;
		}

		private static var _greenFilter:flash.filters.ColorMatrixFilter;

		/**击打白色效果*/
		public static function get greenFilter():flash.filters.ColorMatrixFilter
		{
			if (!_greenFilter)
			{
				_greenFilter=new flash.filters.ColorMatrixFilter([-0.2905729319064281, 0.3362117866513358, 0.9543611452550924, 0, -35, 0.4278579244119142, 0.7325123078638986, -0.1603702322758129, 0, 100, -0.42821158929885533, 1.6525337270883256, -0.22432213778947024, 0, -35, 0, 0, 0, 1, 0]);
			}
			return _greenFilter;
		}

		private static var _goldenFilter:flash.filters.ColorMatrixFilter;

		/**击打金色效果*/
		public static function get goldenFilter():flash.filters.ColorMatrixFilter
		{
			if (!_goldenFilter)
			{
				_goldenFilter=new flash.filters.ColorMatrixFilter([1, 0, 0, 0, 160, 0, 1, 0, 0, 160, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]);
			}
			return _goldenFilter;
		}

		private static var _blueFilter:flash.filters.ColorMatrixFilter;

		/**s击打蓝色效果*/
		public static function get blueFilter():flash.filters.ColorMatrixFilter
		{
			if (!_blueFilter)
			{
				_blueFilter=new flash.filters.ColorMatrixFilter([1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 160, 160, 0, 0, 0, 0, 1, 0]);
			}
			return _blueFilter;
		}

		private static var _BLACK:flash.filters.GlowFilter;

		/**黑色描边*/
		public static function get BLACK():flash.filters.GlowFilter
		{
			if (!_BLACK)
			{
				_BLACK=new GlowFilter(0x0, 0.8, 2, 2, 10, 1);
			}
			return _BLACK;
		}
	}
}
