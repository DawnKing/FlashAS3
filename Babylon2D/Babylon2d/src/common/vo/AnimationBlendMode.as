package common.vo {
	import flash.display.BlendMode;

	public class AnimationBlendMode {
		/***该显示对象出现在背景前面。*/
		public static const NORMAL:int = 0;
		/***在显示对象原色和背景颜色中选择相对较暗的颜色（具有较小值的颜色）。*/
		public static const DARKEN:int = 1;
		/***将显示对象的原色值添加到它的背景颜色中，上限值为 0xFF。*/
		public static const ADD:int = 2;
		/***将显示对象的每个像素的 Alpha 值应用于背景。*/
		public static const ALPHA:int = 3;
		/***将显示对象的原色与背景颜色进行比较，然后从较亮的原色值中减去较暗的原色值。*/
		public static const DIFFERENCE:int = 4;
		/***根据显示对象的 Alpha 值擦除背景。*/
		public static const ERASE:int = 5;
		/***根据显示对象的暗度调整每个像素的颜色。*/
		public static const HARDLIGHT:int = 6;
		/***反转背景。*/
		public static const INVERT:int = 7;
		/***强制为该显示对象创建一个透明度组。*/
		public static const LAYER:int = 8;
		/***在显示对象原色和背景颜色中选择相对较亮的颜色（具有较大值的颜色）。*/
		public static const LIGHTEN:int = 9;
		/***将显示对象的原色值与背景颜色的原色值相乘，然后除以 0xFF 进行标准化，从而得到较暗的颜色。*/
		public static const MULTIPLY:int = 10;
		/***根据背景的暗度调整每个像素的颜色。*/
		public static const OVERLAY:int = 11;
		/***将显示对象颜色的补色（反色）与背景颜色的补色相乘，会产生漂白效果*/
		public static const SCREEN:int = 12;
		/***使用着色器来定义对象之间的混合。*/
		public static const SHADER:int = 13;
		/***从背景颜色的值中减去显示对象原色的值，下限值为 0*/
		public static const SUBTRACT:int = 14;

		/**
		 *获取混合模式字符串
		 * @param type
		 * @return
		 *
		 */
		public static function getBlendMode(type:int):String {
			switch (type) {
				case NORMAL:
					return BlendMode.NORMAL;
				case DARKEN:
					return BlendMode.DARKEN;
				case ADD:
					return BlendMode.ADD;
				case ALPHA:
					return BlendMode.ALPHA;
				case DIFFERENCE:
					return BlendMode.DIFFERENCE;
				case ERASE:
					return BlendMode.ERASE;
				case HARDLIGHT:
					return BlendMode.HARDLIGHT;
				case INVERT:
					return BlendMode.INVERT;
				case LAYER:
					return BlendMode.LAYER;
				case LIGHTEN:
					return BlendMode.LIGHTEN;
				case MULTIPLY:
					return BlendMode.MULTIPLY;
				case MULTIPLY:
					return BlendMode.OVERLAY;
				case SCREEN:
					return BlendMode.SCREEN;
				case SHADER:
					return BlendMode.SHADER;
				case SUBTRACT:
					return BlendMode.SUBTRACT;
				default:
					return BlendMode.NORMAL;
			}
		}
	}
}
