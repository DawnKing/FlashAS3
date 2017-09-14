package tpmagic.magic.controller
{
	import flash.geom.Point;
	
	import tempest.core.IMagicScene;
	import tempest.core.ISceneCharacter;
	import tempest.template.MagicInfo;
	import tempest.utils.Geom;
	import tempest.utils.Random;
	
	import tpmagic.magic.core.IController;
	import tpmagic.magic.enum.ShapeType;
	import tpmagic.magic.partail.TPartical;

	/**
	 *定点粒子控制器
	 * @author zhangyong
	 *
	 */
	public class PointController extends BaseController implements IController
	{

		/**
		 *
		 * @param index
		 * @param scene
		 * @param targeter
		 * @param renderPoint
		 * @param targetPoint
		 * @param magicInfo
		 * @param dir
		 * @param renderTimes
		 * @param onComplete
		 * @param onHit
		 */
		public override function runController(index:int, scene:IMagicScene, targeter:ISceneCharacter, renderPoint:Point, targetPoint:Point, magicInfo:MagicInfo, dir:int, renderTimes:int, onComplete:Function, onHit:Function):void
		{
			var _targetOffset:int;
			var angle:int=0;
			var distance:int=0;
			var mutiCoordinate:Point=null;
			var rotation:Number=NaN;
			var effect:Point=null;
			var isOffset:Boolean=true;
			if (targeter && targeter.usable)
			{
				if (magicInfo.elementType == ShapeType.SHAPE_TRACK_LINE)
				{
					targetPoint=targeter.wpos.pixel;
					_targetOffset=targeter.bodyOffset;
				}
				else
				{
					targetPoint=targeter.wpos.pixel.clone();
				}
			}
			distance=magicInfo.area_raidus * scene.tileWidth;
			if (distance != 0)
			{
				/////偏移特殊处理///
				isOffset=false;
				_targetOffset=0;
				///////////////////
				angle=magicInfo.render_angle + ((magicInfo.render_rondom_angle != 0) ? Random.range(-magicInfo.render_rondom_angle, magicInfo.render_rondom_angle) : 0);
				mutiCoordinate=new Point(targetPoint.x + distance * Math.cos(angle * Geom.RAD_RANGLE), targetPoint.y + distance * Math.sin(angle * Geom.RAD_RANGLE));
				renderPoint=mutiCoordinate;
			}
			if (!mutiCoordinate)
			{
				mutiCoordinate=targetPoint.clone();
			}
			var tp:TPartical=renderTPartical(targeter, magicInfo, scene, mutiCoordinate, targetPoint, _targetOffset, isOffset, 0, 0, dir);
			if (index >= renderTimes)
			{
				tp.onComplete=onComplete;
			}
			tp.collisionCall=onHit;
			tp.show(0);
		}
	}
}


