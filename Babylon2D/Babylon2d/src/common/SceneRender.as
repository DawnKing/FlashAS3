package common
{
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import tempest.core.IRunable;

	/**
	 * 场景渲染器
	 * @author 
	 */
	public class SceneRender
	{
		/**渲染器状态*/
		private var _isRendering:Boolean=false;
		/**最后执行时间*/
		private var _lastTime:int=0;
		/***avatar列表*/
		private var _runables:Dictionary=new Dictionary(true);

		public function SceneRender()
		{
		}

		/**
		 * 开始渲染
		 * @param refresh
		 */
		public function startRender(updateNow:Boolean=false):void
		{
			if (updateNow)
				this.render();
			if (!_isRendering)
			{
				App.timer.doFrameLoop(1, render, null, true, -1, null, "SceneRender.render");
				this._isRendering=true;
			}
		}

		/**
		 * 添加驱动对象
		 * @param iRunable
		 * @param status
		 * @param direction
		 *
		 */
		public function addIRunableRender(iRunable:IRunable):void
		{
			if (iRunable)
			{
				if (!_runables[iRunable])
				{
					_runables[iRunable]=iRunable;
				}
			}
		}

		/**
		 *移除界面avatar渲染
		 *
		 */
		public function removeIRunableRender(iRunable:IRunable):void
		{
			if (iRunable)
			{
				iRunable.onStopRun();
				if (_runables[iRunable])
				{
					_runables[iRunable]=null;
					delete _runables[iRunable];
				}
			}
		}

		public function get runables():Dictionary
		{
			return _runables;
		}

		/**
		 * 停止渲染
		 * @param refresh
		 */
		public function stopRender():void
		{
			if (_isRendering)
			{
				_lastTime=0;
				App.timer.clearTimer(render);
				this._isRendering=false;
			}
		}
		/**当前时间*/
		private var _nowTime:int;
		/**时间差*/
		private var diff:uint=0;

		/**
		 * 渲染
		 * @param e
		 */
		protected function render():void
		{
			_nowTime=getTimer();
			diff=0;
			if (_lastTime != 0)
			{
				diff=_nowTime - _lastTime;
			}
			_lastTime=_nowTime;
			var irunable:IRunable;
			for each (irunable in _runables)
			{
				irunable.run(_nowTime, diff);
			}
		}
	}
}
