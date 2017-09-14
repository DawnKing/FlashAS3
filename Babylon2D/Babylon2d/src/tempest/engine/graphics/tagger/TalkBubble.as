package tempest.engine.graphics.tagger
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.setTimeout;

	/**
	 * 说话泡泡
	 * @author 
	 */
	public class TalkBubble extends Sprite
	{
		private static const MAX_WIDTH:int=180; //最大宽度
		private static const MAX_HEIGHT:int=400; //最大高度
		private static const MIN_WIDTH:int=100; //最小高度
		private static const MIN_HEIGHT:int=24; //最小高度
		private static const OFFSET:int=4; //文字距离背景便宜
		private static const ARROW:int=10; //箭头边长
		private static const BACK_ALPHA:Number=0.3; //背景透明度
		private var _tf:TextField;
		private var _text:String=" ";
		private var _container:DisplayObjectContainer;

		/**
		 * 说话泡泡
		 * @param container 容器
		 */
		public function TalkBubble(container:DisplayObjectContainer)
		{
			super();
			_container=container;
			this.mouseChildren=this.mouseEnabled=false;
			_tf=new TextField();
			_tf.autoSize=TextFieldAutoSize.LEFT;
			_tf.defaultTextFormat=new TextFormat("宋体", 12, 0xFFFFFF, null, null, null, null, null, null, null, null, null, 3);
			_tf.filters=[new GlowFilter(0x0, 1, 2, 2, 5, BitmapFilterQuality.LOW)];
			_tf.wordWrap=true;
			_tf.multiline=true;
			this.addChild(_tf);
		}

		protected function draw():void
		{
			_tf.width=10000;
			_tf.htmlText=_text;
			/*************************************************
			 *
			 * 兼容版本 10.3.183.5 重新创建TextField并设置字符串
			 *
			 * ***********************************************/
			if (Capabilities.version.split(" ")[1] == "10,3,183,5" && _text.length > 0)
			{
				_tf.parent.removeChild(_tf);
				_tf=copyTextField();
				this.addChild(_tf);
			}
			//
			var w:Number=Math.max(Math.min(_tf.textWidth + OFFSET * 2, MAX_WIDTH), MIN_WIDTH);
			_tf.width=w - OFFSET * 2;
			var h:Number=Math.max(Math.min(_tf.height + OFFSET * 2, MAX_HEIGHT), MIN_HEIGHT);
			//画背景框
			this.graphics.clear();
			this.graphics.beginFill(0x0, BACK_ALPHA);
			this.graphics.drawRoundRectComplex(-w * 0.5 + ARROW, -h - ARROW, w, h, 8, 8, 8, 8);
			//画三角	
			this.graphics.moveTo(0, 0);
			this.graphics.lineTo(0, -ARROW);
			this.graphics.lineTo(ARROW, -ARROW);
			this.graphics.lineTo(0, 0);
			this.graphics.endFill();
			//画外框
			//			this.graphics.lineStyle(1,0x0,0.4);
			//			this.graphics.drawRoundRectComplex(-w*0.5+ARROW,-h-ARROW,w,h,10,10,10,10);
			//			this.graphics.moveTo(0,0);
			//			this.graphics.lineTo(0,-ARROW);
			//			this.graphics.lineTo(ARROW,-ARROW);
			//			this.graphics.lineTo(0,0);
			//			this.graphics.endFill();
			//textField位置
			_tf.width=w - OFFSET * 2;
			_tf.height=h - OFFSET * 2;
			_tf.x=-w * 0.5 + OFFSET + ARROW;
			_tf.y=-h - ARROW + OFFSET;
		}

		private function copyTextField():TextField
		{
			var newText:TextField=new TextField();
			newText.autoSize=_tf.autoSize;
			newText.defaultTextFormat=_tf.defaultTextFormat;
			newText.filters=_tf.filters;
			newText.wordWrap=_tf.wordWrap;
			newText.multiline=_tf.multiline;
			newText.width=_tf.width;
			newText.height=_tf.height;
			newText.x=_tf.x;
			newText.y=_tf.y;
			newText.htmlText=_tf.htmlText;
			return newText;
		}

		/**
		 * 设置信息文本
		 * @param msg 信息文本
		 * @param elapseTime 持续时间 毫秒
		 * @param delay 延迟显示时间 毫秒
		 */
		public function setText(msg:String, elapseTime:uint=3000, delay:uint=0):void
		{
			if (msg != "")
			{
				_text=msg;
				this.draw();
				if (this._container)
				{
					this._container.addChild(this);
					setTimeout(remove, elapseTime);
				}
			}
		}

		private function remove():void
		{
			if (this.parent)
				this.parent.removeChild(this);
		}
	}
}
