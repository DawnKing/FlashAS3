package tpmagic.magic.enum
{
	import tpmagic.magic.controller.BaseController;
	import tpmagic.magic.controller.CrossController;
	import tpmagic.magic.controller.LineController;
	import tpmagic.magic.controller.PointController;
	import tpmagic.magic.controller.RondomController;
	import tpmagic.magic.controller.SectorController;
	import tpmagic.magic.controller.SectorWaveController;

	public class ControllerType
	{
		/**十字形*/
		public static const CONTROLLER_CROSS:int=3;
		/**线形*/
		public static const CONTROLLER_LINE:int=5;
		/**点形*/
		public static const CONTROLLER_POINT:int=6;
		/**随机形*/
		public static const CONTROLLER_RONDOM:int=7;
		/**扇形*/
		public static const CONTROLLER_SECTOR:int=8;
		/**波浪扇形*/
		public static const CONTROLLER_WAVE_SECTOR:int=9;
		/**所有控制器*/
		private static var _contolls:Object;

		init();

		static private function init():void
		{
			_contolls={};
			_contolls[CONTROLLER_CROSS]=new CrossController();
//			_contolls[CONTROLLER_DIFFUSE]=new DiffuseController();
			_contolls[CONTROLLER_LINE]=new LineController();
			_contolls[CONTROLLER_POINT]=new PointController();
			_contolls[CONTROLLER_RONDOM]=new RondomController();
			_contolls[CONTROLLER_SECTOR]=new SectorController();
//			_contolls[CONTROLLER_BRIDGE]=new BridgeController();
			_contolls[CONTROLLER_WAVE_SECTOR]=new SectorWaveController();

		}

		/**
		 * 根据发射类型获取是否需要发射偏移
		 * @param type
		 * @return
		 *
		 */
		public static function getRenderOffset(type:int):Boolean
		{
			switch (type)
			{
				case CONTROLLER_CROSS:
				case CONTROLLER_POINT:
				case CONTROLLER_RONDOM:
				case CONTROLLER_SECTOR:
				case CONTROLLER_WAVE_SECTOR:
					return false;
			}
			return true;
		}

		/**
		 *获取魔法控制器
		 * @return
		 *
		 */
		public static function getController(controllerType:int):BaseController
		{
			return _contolls[controllerType];
		}
	}
}


