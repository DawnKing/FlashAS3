package tpmagic.magic.controller
{
	import flash.geom.Point;
	
	import tempest.core.IMagicScene;
	import tempest.core.ISceneCharacter;
	import tempest.template.MagicInfo;
	import tempest.utils.Geom;
	
	import tpmagic.magic.core.IController;
	import tpmagic.magic.partail.TPartical;

	/**
	 *十字对称粒子控制器
	 * @author zhangyong
	 *
	 */
	public class CrossController extends BaseController implements IController
	{

		/**
		 * 渲染控制器
		 *
		 */
		public override function runController(index:int, scene:IMagicScene, targeter:ISceneCharacter, renderPoint:Point, targetPoint:Point, magicInfo:MagicInfo, dir:int, renderTimes:int, onComplete:Function, onHit:Function):void
		{
			var distance:int=0;
			var temp_angle:int=0;
			var angle:int=0;
			var count:int=magicInfo.diffuse_num;
			distance=magicInfo.area_raidus * scene.tileWidth;
			temp_angle=360 / count;
			var var1:int=0;
			var var2:int=0;
			var render_muti_coordinate:Point=null;
			var single_angle:int;
			var rotation:int;
			var duration:Number=NaN;
			var speed:int=magicInfo.effect_movespeed;
			if (speed > 0 && distance > 0)
			{
				duration=distance / speed;
			}
			else
			{
				duration=0;
			}

			for (var i:int=0; i < count; i++)
			{
				single_angle=angle + temp_angle * i;
				rotation=single_angle * Geom.RAD_RANGLE;
				var1=targetPoint.x + distance * Math.cos(rotation);
				if (magicInfo.is_game_angle != 1)
				{
					var2=targetPoint.y + distance * Math.sin(rotation);
				}
				else
				{
					var2=targetPoint.y + distance * magicInfo.game_angle * Math.sin(rotation);
				}
				render_muti_coordinate=new Point(var1, var2);
				var tp:TPartical=renderTPartical(null, magicInfo, scene, renderPoint, render_muti_coordinate, 0, true, distance, rotation, dir);
				if ((i == (count - 1)) && index >= renderTimes)
				{
					tp.onComplete=onComplete;
				}
				tp.collisionCall=onHit;
				tp.show(duration);
			}
		}
	}
}


