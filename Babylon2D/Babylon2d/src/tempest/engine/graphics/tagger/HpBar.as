package tempest.engine.graphics.tagger
{
	import morn.core.components.ProgressBar;
	
	import starling.animation.Juggler;

	/**
	 * 血条
	 * @author zhangyong
	 *
	 */
	public class HpBar extends ProgressBar
	{
		/**
		 *
		 * @param hpType （默认值 HpBar.BG_RED+HpBar.HPMASK_NORMAL）
		 * @param useDoubleEffect
		 *
		 */
		public function HpBar()
		{
			this.minusTweenEffect=true;
			super();
		}


		/**
		 * 文字位置
		 *
		 */
		protected override function changeLabelPoint():void
		{
			if (_barLabel)
			{
				_barLabel.x=(width - _barLabel.width) * 0.5;
				_barLabel.y=(height - _barLabel.height) * 0.5 - 1;
			}
		}

		protected override function changeValue():void
		{
			var oldValue:Number=_bar.width;
			var newValue:Number=width * _value;
			_duration=Math.min(Math.max(0.2, newValue / 40), 1.5);
			//进度条缓动
			//添加缓动或者减少缓动
			var isPlusEffect:Boolean=(plusTweenEffect && (newValue > oldValue));
			var isminusEffect:Boolean=(minusTweenEffect && (newValue < oldValue));
			if (isPlusEffect || isminusEffect)
			{
				Juggler.instance.tween(_bar, _duration / 2, {width: newValue});
			}
			else
			{
				_bar.width=newValue;
			}
		}
	}
}
