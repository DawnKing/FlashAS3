package tempest.engine.flytext
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import tempest.core.IMagicScene;
	import tempest.flytext.FlyTextTagger;
	import tempest.pool.IPoolsObject;
	import tempest.pool.ObjectPools;

	/**
	 * 图片字
	 * @author zhangyong
	 *
	 */
	public class FlyTImageText extends BaseFlyText
	{
		private var textBitmap:Bitmap;
		private var bitmapDataArray:Vector.<BitmapData>;
		private var _leading:int;
		private var isFromHero:Boolean;
		private var isFromPet:Boolean;
		private var flag:int;

		public function FlyTImageText(scene:IMagicScene, content:String, flag:int, rotation:int, isFromHero:Boolean, isFromPet:Boolean, leading:int)
		{
			bitmapDataArray=new Vector.<BitmapData>();
			super(scene);
			initText(content, flag, rotation, isFromHero, isFromPet, leading);
		}

		/**
		 * 设置文本
		 * @param value
		 *
		 */
		public override function initText(content:String, flag:int, rotation:int, isAffectMainChar:Boolean, isFromPet:Boolean, leading:int):void
		{
			rotate=rotation;
			this.flag=flag;
			this.isFromHero=isAffectMainChar;
			this.isFromPet=isFromPet;
			this._leading=leading;
			getHead();
			setImageText(content);
		}

		public override function reset(... args):void
		{
			//TODO Auto-generated method stub
			initText(args[1], args[2], args[3], args[4], args[5], args[6]);
		}

		public override function dispose():void
		{
			//TODO Auto-generated method stub
			this.x=0;
			this.y=0;
			totalWidth=0;
			totalheight=0;
			resetBitmap();
		}

		/**
		 * 释放零时位图
		 *
		 */
		private function resetBitmap():void
		{
			if (titleBitmapdata)
			{
				titleBitmapdata=null;
			}
			if (textBitmap)
			{
				if (textBitmap.bitmapData)
				{
					textBitmap.bitmapData.dispose();
				}
				textBitmap.bitmapData=null;
			}
			bitmapDataArray.length=0;
		}
		private var totalWidth:Number=0;
		private var totalheight:Number=0;
		private var titleBitmapdata:BitmapData;

		/**
		 * 文字
		 *
		 */
		public function getHead():void
		{
			var skin:String;
			var flyTextTagger:FlyTextTagger=scene.flyTextTagger as FlyTextTagger;
			if (isFromPet) //宠物特殊处理
			{
				skin="zise";
				_leading=-1;
				titleBitmapdata=flyTextTagger.flyImageFont["pet"];
				if (titleBitmapdata.height > totalheight)
				{
					totalheight=titleBitmapdata.height;
				}
				if (totalWidth == 0)
				{
					totalWidth+=titleBitmapdata.width;
				}
				else
				{
					totalWidth+=titleBitmapdata.width + _leading;
				}
				bitmapDataArray.push(titleBitmapdata);
			}
			else
			{
				skin=flyTextTagger.getHeadSkin2(flag, isFromHero);
				if (!skin || skin.length == 0)
				{
					return;
				}
				titleBitmapdata=flyTextTagger.flyImageFont[skin];
				if (titleBitmapdata)
				{
					if (titleBitmapdata.height > totalheight)
					{
						totalheight=titleBitmapdata.height;
					}
					if (totalWidth == 0)
					{
						totalWidth+=titleBitmapdata.width;
					}
					else
					{
						totalWidth+=titleBitmapdata.width + _leading;
					}
					bitmapDataArray.push(titleBitmapdata);
				}
			}
		}

		/**
		 * 获取字体图片并绘制到textBitmap.bitmapData上
		 * @param str
		 * @param leading
		 *
		 */
		private function setImageText(num:String):void
		{
			if (num && num.length > 0) //拼接伤害数字
			{
				var flyTextTagger:FlyTextTagger=scene.flyTextTagger as FlyTextTagger;
				var color:String=flyTextTagger.getFlyTextColor(flag, isFromHero);
				///////////////////数字/////////////////
				var bitmapFont:Object=flyTextTagger.flyImageFont[color]; //获取字体资源
				if (!bitmapFont)
				{
					throw new Error("未注册的字体资源类型：" + color + " flag:" + flag);
				}
				var bitmapData:BitmapData=bitmapFont.getWordBitmapData(num, 0 /*_leading*/);
				if (!bitmapData)
				{
					throw new Error("找不到位图文字：" + num + " flag:" + flag);
				}
				if (bitmapData.height > totalheight)
				{
					totalheight=bitmapData.height;
				}
				if (totalWidth == 0)
				{
					totalWidth+=bitmapData.width;
				}
				else
				{
					totalWidth+=bitmapData.width + _leading;
				}
				bitmapDataArray.push(bitmapData);
			}
			//绘图
			if (totalWidth > 0 && totalheight > 0)
			{
				if (!textBitmap)
				{
					textBitmap=new Bitmap();
					this.addChild(textBitmap);
				}
				textBitmap.bitmapData=new BitmapData(totalWidth, totalheight, true, 0xFFFFFF);
				var drawX:Number=0;
				textBitmap.bitmapData.lock();
				var j:int=0;
				var len:int=bitmapDataArray.length;
				var bmDt:BitmapData=null;
				for (; j != len; ++j)
				{
					bmDt=bitmapDataArray[j];
					textBitmap.bitmapData.copyPixels(bmDt, new Rectangle(0, 0, bmDt.width, bmDt.height), new Point(drawX, (totalheight - bmDt.height) / 2));
					drawX+=bmDt.width + _leading;
				}
				textBitmap.bitmapData.unlock();
				textBitmap.x=-(textBitmap.width >> 1);
				textBitmap.y=-textBitmap.height;
			}
		}

		/**
		 *创建飞行文字池对象
		 * @param flyTextData
		 * @return
		 *
		 */
		public static function malloc(scene:IMagicScene, content:String, flag:int, rotation:int, isAffectMainChar:Boolean, isFromPet:Boolean, leading:int):FlyTImageText
		{
			return ObjectPools.malloc(FlyTImageText, scene, content, flag, rotation, isAffectMainChar, isFromPet, leading) as FlyTImageText;
		}

		/**
		 *回收
		 * @param flyableText
		 *
		 */
		public static function free(flyableText:IPoolsObject):void
		{
			ObjectPools.free(flyableText);
		}
	}
}
