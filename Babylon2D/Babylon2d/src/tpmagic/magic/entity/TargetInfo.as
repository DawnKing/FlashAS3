package tpmagic.magic.entity
{
	import flash.geom.Point;

	import tempest.core.ISceneCharacter;

	/**
	 * 目标信息
	 * @author zhangyong
	 *
	 */
	public class TargetInfo
	{
		/**目标玩家*/
		private var _targeter:ISceneCharacter;
		/**目标点*/
		private var _targetPoint:Point;

		public function TargetInfo(targeter:ISceneCharacter, targetPoint:Point)
		{
			_targeter=targeter;
			_targetPoint=targetPoint;
		}
	}
}
