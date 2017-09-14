package tpmagic.magic.core
{
	import flash.geom.Point;
	
	import tempest.core.IMagicScene;
	import tempest.template.MagicInfo;

	public interface IMutiController
	{
		/**
		 * 渲染控制器
		 * @param index
		 * @param hitInfos
		 * @param renderPoint
		 * @param targetPoint
		 * @param magicInfo
		 * @param dir 释放者朝向
		 *
		 */
		function runMutiController(index:int, scene:IMagicScene, targets:Array, renderPoint:Point, targetPoint:Point, magicInfo:MagicInfo, dir:int, renderTimes:int, onComplete:Function, onHit:Function):void;
	}
}
