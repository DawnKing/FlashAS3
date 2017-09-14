package game.scene.map
{
	import flash.utils.getTimer;
	
	import tempest.utils.Random;


	public class Shock
	{
		/*地震偏移X*/
		public var offsetX:int;
		/*地震偏移Y*/
		public var offsetY:int;
		/*振幅*/
		public var offset:int=15;
		/*是否震动中*/
		private var _isRunning:Boolean=false;
		/*开始时间*/
		private var _startTime:int;
		/*持续时间*/
		private var _duration:int;
		/*结束时间*/
		private var _overTime:int;

		/**
		 * 震动开始
		 * @param duration 持续时间 单位/ms
		 *
		 */
		public function start(duration:int, offset:int=15):void
		{
			_isRunning=true;
			//时间计算
			_startTime=getTimer();
			_duration=duration;
			_overTime=_startTime + _duration;
			this.offsetY=this.offsetX=this.offset=offset;
		}

		private var _index:int;

		/**
		 * 震动更新心态
		 * @param diff 时间差
		 *
		 */
		public function update():Boolean
		{
			if (!_isRunning)
				return false;
			_index++;
			if (_index > 1)
			{
				offsetX=tempest.utils.Random.range(0, offset); //Math.abs(offsetX) - 1;
				offsetY=tempest.utils.Random.range(0, offset); //Math.abs(offsetY) - 1;
				_index=0;
			}
			offsetX*=-1;
			offsetY*=-1;
			if (getTimer() > _overTime)
			{
				stop();
			}
			return true;
		}

		/**
		 * 结束
		 *
		 */
		public function stop():void
		{
			_isRunning=false;
			offsetX=0;
			offsetY=0;
		}

		public function get isShocking():Boolean
		{
			return _isRunning
		}
	}
}
