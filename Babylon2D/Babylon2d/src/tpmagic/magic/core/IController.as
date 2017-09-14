package tpmagic.magic.core
{
	import flash.geom.Point;
	
	import tempest.core.IMagicScene;
	import tempest.core.ISceneCharacter;
	import tempest.template.MagicInfo;

	public interface IController
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
		function runController(index:int, scene:IMagicScene, targeter:ISceneCharacter, renderPoint:Point, targetPoint:Point, magicInfo:MagicInfo, dir:int, renderTimes:int, onComplete:Function, onHit:Function):void;
	}
}


