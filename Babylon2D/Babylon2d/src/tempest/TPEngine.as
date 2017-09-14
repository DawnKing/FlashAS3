package tempest
{
	import flash.display.Stage;
	
	import common.SceneRender;
	import tempest.core.IMagicScene;

	/**
	 *
	 * @author zhangyong
	 *
	 */
	public class TPEngine
	{
		/**舞台*/
		private static var _stage:Stage;
		/**帧率*/
		private static var _fps:Number;
		/**马达*/
		protected static var _sceneRender:SceneRender;

		public static function get sceneRender():SceneRender
		{
			return _sceneRender;
		}


		/**
		 * 初始化
		 * @param stage 舞台
		 * @param fps 帧频
		 */
		public static function init(stage:Stage, fps:Number=-1):void
		{
			_stage=stage;
			_fps=_stage.frameRate;
			if (fps >= 0)
			{
				_fps=fps;
				_stage.frameRate=_fps;
			}
			if (!_sceneRender)
			{
				_sceneRender=new SceneRender();
			}
			startEngine();
		}

		/**
		 * 引擎发动
		 *
		 */
		public static function startEngine():void
		{
			_sceneRender.startRender(true);
		}

		/**
		 * 引擎停止
		 *
		 */
		public static function stopEngine():void
		{
			_sceneRender.stopRender();
		}

		/**
		 * 获取舞台
		 * @return
		 */
		public static function get stage():Stage
		{
			return _stage;
		}

		/**
		 * 获取/设置帧频
		 * @return
		 */
		public static function get fps():Number
		{
			return _fps;
		}

		/**
		 * 设置驱动帧率
		 * @param value
		 *
		 */
		public static function set fps(value:Number):void
		{
			if (_fps >= 0)
			{
				_fps=value;
				_stage.frameRate=_fps;
			}
		}
	}
}


