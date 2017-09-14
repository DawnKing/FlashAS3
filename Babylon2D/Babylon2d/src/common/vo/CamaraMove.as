package common.vo
{
	import flash.utils.getTimer;

	public class CamaraMove
	{
		private var _fromX:Number=0;

		private var _fromY:Number=0;

		private var _toX:Number=0;

		private var _toY:Number=0;

		private var _durTime:Number=0;

		private var _startTime:Number=0;

		private var _x:Number;

		private var _y:Number;

		private var _isMoveOver:Boolean=true;

		public function get isMoveOver():Boolean
		{
			return this._isMoveOver;
		}

		public function get y():Number
		{
			return this._y;
		}

		public function get x():Number
		{
			return this._x;
		}

		public function stop():void
		{
			this._isMoveOver=true;
		}

		public function init(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number):void
		{
			this._fromX=param1;
			this._fromY=param2;
			this._toX=param3;
			this._toY=param4;
			this._durTime=param5;
			this._startTime=getTimer();
			this._isMoveOver=false;
		}

		public function update():void
		{
			var _loc1_:Number=getTimer() - this._startTime;
			if (_loc1_ > this._durTime)
			{
				this._x=this._toX;
				this._y=this._toY;
				this._isMoveOver=true;
				return;
			}
			var _loc2_:Number=_loc1_ / this._durTime;
			this._x=this._fromX + (this._toX - this._fromX) * _loc2_;
			this._y=this._fromY + (this._toY - this._fromY) * _loc2_;
		}
	}
}

