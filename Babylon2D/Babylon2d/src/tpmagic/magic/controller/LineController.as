package tpmagic.magic.controller
{
	import flash.geom.Point;

	import tempest.core.IMagicScene;
	import tempest.core.ISceneCharacter;
	import tempest.template.MagicInfo;
	import tempest.utils.Geom;

	import tpmagic.magic.core.IController;
	import tpmagic.magic.enum.ShapeType;
	import tpmagic.magic.partail.TPartical;

	/**
	 *线型粒子控制器
	 * @author zhangyong
	 *
	 */
	public class LineController extends BaseController implements IController
	{
		/**目标胸部偏移*/
		private var _targetOffset:int;

		/**
		 *
		 * @param index
		 * @param hitInfos
		 * @param renderPoint
		 * @param targetPoint
		 * @param magicInfo
		 *
		 */
		public override function runController(index:int, scene:IMagicScene, targeter:ISceneCharacter, renderPoint:Point, targetPoint:Point, magicInfo:MagicInfo, dir:int, renderTimes:int, onComplete:Function, onHit:Function):void
		{
			var _distance:int;
			if (magicInfo.elementType == ShapeType.SHAPE_TRACK_LINE && targeter && targeter.usable) //追踪
			{
				_targetOffset=targeter.bodyOffset;
				targetPoint=targeter.wpos.pixel;
			}
			else //直线
			{
				_distance=magicInfo.area_raidus * scene.tileWidth;
				targetPoint=getEndPoint(renderPoint, targetPoint, _distance);
			}
			var tp:TPartical=renderTPartical(targeter, magicInfo, scene, renderPoint, targetPoint, _targetOffset, true, 0, 0, dir);
			if (index >= renderTimes)
			{
				tp.onComplete=onComplete;
			}
			tp.collisionCall=onHit;
			tp.show(0);
		}

		/**
		 * 获取结束点(注意与Geom.getEndPoint()区别)
		 * 线性穿透使用
		 * @param beginPoint
		 * @param mousePoint
		 * @param distance
		 *
		 */
		public function getEndPoint(beginPoint:Point, mousePoint:Point, distance:Number):Point
		{
			var angle:Number=Geom.GetRotation(beginPoint, mousePoint) * Geom.RAD_RANGLE;
			return new Point(Math.cos(angle) * distance + beginPoint.x, Math.sin(angle) * distance + beginPoint.y);
		}

	}
}


