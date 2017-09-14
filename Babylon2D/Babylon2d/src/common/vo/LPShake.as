package common.vo
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import common.math.CMath;

	public class LPShake
	{
		private var _shakeDir:int=160;

		private var _amplitude:Number=20;

		private var _frequency:Number=0.5;

		private var _duration:Number=0.4;

		private var _leftTime:Number=0;

		private var _preTime:Number=0;

		private var _preAngle:int=0;

		private var _offsetX:Number=0;

		private var _offsetY:Number=0;

		function LPShake()
		{
			super();
		}

		public function get offsetX():Number
		{
			return this._offsetX;
		}

		public function get offsetY():Number
		{
			return this._offsetY;
		}

		public function get shaking():Boolean
		{
			return this._leftTime > 0;
		}

		public function shake(param1:Number=0.4, param2:Number=20, param3:Number=0.5, param4:int=0, param5:int=160):void
		{
			this._shakeDir=CMath.clampi(param5, 0, 360);
			this._amplitude=CMath.max(param2, 0.0);
			this._frequency=0.01 + 0.02 * (1 - CMath.clamp(param3, 0, 1));
			this._duration=CMath.max(param1, 0.0);
			this._leftTime=this._duration;
			this._preTime=currentTimef;
			this._offsetX=0;
			this._offsetY=0;
			if (param4 < 0)
			{
				param4=CMath.randomi(0, 360);
			}
			param4=CMath.clampi(param4, 0, 360);
			param4=CMath.exp(0.5) == 0 ? param4 : param4 > 180 ? param4 - 180 : 180 - param4;
			this._preAngle=param4;
		}

		public function stopShake():void
		{
			this._leftTime=0;
		}

		public function update():void
		{
			if (!this.shaking)
			{
				return;
			}
			var _loc1_:Number=currentTimef - this._preTime;
			if (_loc1_ < this._frequency || this._leftTime <= 0)
			{
				return;
			}
			var _loc2_:Number=this._leftTime / this._duration;
			var _loc3_:int=CMath.randomi(-this._shakeDir / 2, this._shakeDir / 2);
			_loc3_=_loc3_ * _loc2_;
			var _loc4_:int=180 + this._preAngle + _loc3_;
			_loc4_=_loc4_ % 360;
			var _loc5_:Number=CMath.angleToRadian(_loc4_);
			_loc2_=_loc2_ * _loc2_ * _loc2_;
			var _loc6_:Number=this._amplitude * _loc2_ * CMath.random(0.5, 1.1);
			var _loc7_:Point=polarToCartesian(_loc5_, _loc6_);
			this._offsetX=_loc7_.x;
			this._offsetY=_loc7_.y;
			this._preAngle=(180 + this._preAngle) % 360;
			this._leftTime=this._leftTime - _loc1_;
			this._preTime=currentTimef;
		}
		
		public static function polarToCartesian(param1:Number, param2:Number) : Point
		{
			var _loc3_:Matrix = new Matrix();
			_loc3_.rotate(param1);
			_loc3_.scale(param2,param2);
			return _loc3_.transformPoint(CMath.AxisX);
		}
		
		public static function get currentTimef() : Number
		{
			return getTimer() * 0.001;
		}
	}
}
