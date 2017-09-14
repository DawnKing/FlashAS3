package common.vo
{
	import flash.utils.getTimer;

	public class ShakeVO
	{

		private var _offsetX:Number=0;

		private var _offsetY:Number=0;

		private var _shakeOffset:Number=0;

		private var _shakeFromX:Number=0;

		private var _shakeFromY:Number=0;

		private var _shakeToX:Number=0;

		private var _shakeToY:Number=0;

		private var _shakeStartTime:Number=0;

		private var _shakeEndTime:Number=0;

		private var _roundTime:Number=25;

		private var _isDown:Boolean;

		function ShakeVO()
		{
			super();
		}

		public function get offsetY():Number
		{
			return this._offsetY;
		}

		public function get offsetX():Number
		{
			return this._offsetX;
		}

		public function shake(param1:Number, param2:Number=5):void
		{
			this.stopShake();
			this._shakeOffset=param2;
			this._shakeFromX=0;
			this._shakeFromY=0;
			this._shakeToX=this._shakeOffset;
			this._shakeToY=this._shakeOffset;
			this._isDown=true;
			this._shakeStartTime=getTimer();
			if (param1 == -1)
			{
				this._shakeEndTime=-1;
			}
			else
			{
				this._shakeEndTime=this._shakeStartTime + param1;
			}
		}

		public function stopShake():void
		{
			this._shakeEndTime=getTimer();
			this.shakeOverHandler();
		}

		public function update():void
		{
			var curTime:int=getTimer();
			if (this._shakeEndTime != -1 && curTime >= this._shakeEndTime)
			{
				this.shakeOverHandler();
				return;
			}
			var _loc1_:Number=curTime - this._shakeStartTime;
			if (_loc1_ >= this._roundTime)
			{
				this._offsetY=this._shakeToY;
				this._shakeStartTime=getTimer();
				if (this._shakeToY == this._shakeOffset)
				{
					this._isDown=false;
				}
				else if (this._shakeToY == -this._shakeOffset)
				{
					this._isDown=true;
				}
				if (this._isDown)
				{
					this._shakeToY=this._shakeToY + this._shakeOffset;
				}
				else
				{
					this._shakeToY=this._shakeToY - this._shakeOffset;
				}
			}
			else
			{
				this._offsetY=this._shakeFromX + (this._shakeToY - this._shakeFromX) * _loc1_ / this._roundTime;
			}
		}

		private function shakeOverHandler():void
		{
			this._offsetX=0;
			this._offsetY=0;
		}
	}
}
