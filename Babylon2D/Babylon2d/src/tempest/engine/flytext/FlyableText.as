package tempest.engine.flytext
{
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import tempest.core.IMagicScene;
	import tempest.flytext.FlyTextTagger;
	import tempest.flytext.vo.FlyFlagConfig;
	import tempest.pool.ObjectPools;

	/**
	 * 文本字
	 * @author zhangyong
	 *
	 */
	public class FlyableText extends BaseFlyText
	{
		private var _textFormat:TextFormat
		private var _body:TextField=new TextField();
		private static var filterArr:Array=[new GlowFilter(3591)];

		public function FlyableText(scene:IMagicScene, content:String, flag:int, rotation:int, isAffectMainChar:Boolean, isFromPet:Boolean, leading:int)
		{
			super(scene);
			_textFormat=new TextFormat();
			_textFormat.kerning=true;
			_textFormat.letterSpacing=-1;
			_body.autoSize=TextFieldAutoSize.CENTER;
			_body.selectable=false;
			this.mouseEnabled=this.mouseChildren=false;
			initText(content, flag, rotation, isAffectMainChar, isFromPet, leading);
			_body.filters=filterArr;
			this.addChild(_body);
		}

		/**
		 *初始化，重新初始化文本
		 * @param flyTextData
		 *
		 */
		public override function initText(content:String, flag:int, rotation:int, isAffectMainChar:Boolean, isFromPet:Boolean, leading:int):void
		{
			_textFormat.font="宋体";
			var flagConfig:FlyFlagConfig=(scene.flyTextTagger as FlyTextTagger).flagConfigs[flag];
			_textFormat.size=flagConfig.bodySize;
			_textFormat.color=flagConfig.getColor(isAffectMainChar);
			_body.defaultTextFormat=_textFormat;
			_body.text=content;
			_body.x=-(_body.width >> 1);
			_body.y=-(_body.height);
		}

		public override function reset(... args):void
		{
			initText(args[1], args[2], args[3], args[4], args[5], args[6]);
		}

		public override function dispose():void
		{
			this.x=0;
			this.y=0;
			this.alpha=1;
			this.scaleX=1;
			this.scaleY=1;
			_body.text="";
			if (this.parent != null)
				this.parent.removeChild(this);
		}

		public function get bodyWidth():Number
		{
			return _body.width;
		}

		public function get bodyHeight():Number
		{
			return _body.height;
		}

		/**
		 *创建飞行文字池对象
		 * @param flyTextData
		 * @return
		 *
		 */
		public static function createFlyableText(flyTextTagger:FlyTextTagger, content:String, flag:int, rotation:int, isAffectMainChar:Boolean, isFromPet:Boolean, leading:int):FlyableText
		{
			return ObjectPools.malloc(FlyableText, [flyTextTagger, content, flag, rotation, isAffectMainChar, isFromPet, leading]) as FlyableText;
		}

	 
		public override function free():void
		{
			ObjectPools.free(this);
		}
	}
}
