package tempest.engine.flytext
{
	import flash.display.Sprite;
	
	import tempest.core.IMagicScene;
	import tempest.engine.TScene;
	import tempest.flytext.core.IFlyText;
	import tempest.flytext.vo.FlyTextData;
	import tempest.pool.IPoolsObject;

	/**
	 * 飘字基类
	 * @author zhangyong
	 *
	 */
	public class BaseFlyText extends Sprite implements IFlyText, IPoolsObject
	{
		public var rotate:Number;
		public var scene:TScene;

		public function BaseFlyText(scene:IMagicScene)
		{
			this.scene=scene as TScene;
			this.mouseChildren=this.mouseEnabled=false;
		}

		private var _endPositionx1:int;
		private var _endPositiony1:int;
		private var _endPositionx2:int;
		private var _endPositiony2:int;

		public function calutePostion(flyTextData:FlyTextData):void
		{
			this.x=flyTextData.pixel_x;
			this.y=flyTextData.pixel_y /*- flyTextData.head_offset*/; //定位到受击对象的头顶
			if (!isNaN(rotate))
			{
				var cng:Number=Math.cos(rotate);
				var sng:Number=Math.sin(rotate);
				_endPositionx1=x + 200 * cng;
				_endPositiony1=y + 200 * sng;
				_endPositionx2=x + 280 * cng;
				_endPositiony2=y + 280 * sng;
			}
		}

		public function show():void
		{
			(scene as TScene).fgEffectLayer.addChild(this);
		}

		public function initText(content:String, rotation:int, flag:int, isAffectMainChar:Boolean, isFromPet:Boolean, leading:int):void
		{
			throw new Error("必须重写");
		}

		public function apendText(flag:int, content:String):void
		{
			throw new Error("必须重写");
		}

		public function dispose():void
		{
			throw new Error("必须重写");
		}
		
		public function reset(...args):void
		{
			throw new Error("必须重写");
		}
		
		public function calutePostionBody(flyTextData:FlyTextData, index:int):void
		{
			
		}
		
		public function calutePostionHead(flyTextData:FlyTextData, index:int):void
		{
			
		}
		
		public function calutePostionOrigin(flyTextData:FlyTextData, index:int):void
		{
			
		}
		
		public function get endPositionx1():int
		{
			return _endPositionx1;
		}
		
		public function get endPositionx2():int
		{
			return _endPositionx2;
		}
		
		public function get endPositiony1():int
		{
			return _endPositiony1;
		}
		
		public function get endPositiony2():int
		{
			return _endPositiony2;
		}
		
		public function free():void
		{
			// TODO Auto Generated method stub
			
		}
		
		public function onChange():void
		{
			
		}
		
	}
}
