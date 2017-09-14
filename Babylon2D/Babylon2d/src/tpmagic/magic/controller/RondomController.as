package tpmagic.magic.controller
{
	import flash.geom.Point;
	
	import tempest.core.IMagicScene;
	import tempest.core.ISceneCharacter;
	import tempest.template.MagicInfo;
	import tempest.utils.Geom;
	import tempest.utils.Random;
	
	import tpmagic.magic.core.IController;
	import tpmagic.magic.partail.TPartical;

	/**
	 *随机粒子控制器
	 * @author zhangyong
	 *
	 */
	public class RondomController extends BaseController implements IController
	{

		/**
		 * 渲染控制器
		 *
		 */
		public override function runController(index:int, scene:IMagicScene, targeter:ISceneCharacter, renderPoint:Point, targetPoint:Point, magicInfo:MagicInfo, dir:int, renderTimes:int, onComplete:Function, onHit:Function):void
		{
			var offset:int=0;
			var begin_position:Point=null;
			var duartion:Number=NaN;
			offset=magicInfo.area_raidus * scene.tileWidth;
			var count:int=magicInfo.diffuse_num;
			var iter:int=0;
			/////////改变量///////
			var var0:Number=NaN;
			var var1:int=0;
			var var2:int=0;
			var distance:int=0;
			var rotation:Number=NaN;
			var render_muti_coordinate:Point=null;
			for (; iter != count; iter++)
			{
				/*************************计算魔法粒子坐标*************************/
				var px:int=Random.range(-offset, offset);
				var py:int=Random.range(-offset, offset);
				if (magicInfo.is_game_angle)
				{
					py*=magicInfo.game_angle;
				}
				begin_position=new Point(targetPoint.x + px, targetPoint.y + py);
				/*************************角度*************************/
				rotation=magicInfo.render_angle + ((magicInfo.render_rondom_angle != 0) ? Random.range(-magicInfo.render_rondom_angle, magicInfo.render_rondom_angle) : 0);
				distance=(magicInfo.lifeSpan * (magicInfo.effect_movespeed + ((magicInfo.render_rondom_speed != 0) ? Random.range(-magicInfo.render_rondom_speed, magicInfo.render_rondom_speed) : 0)));
				var0=rotation * Geom.RAD_RANGLE;
				var1=begin_position.x + distance * Math.cos(var0);
				var2=begin_position.y + distance * Math.sin(var0);
				render_muti_coordinate=new Point(var1, var2);
				var tp:TPartical=renderTPartical(null, magicInfo, scene, begin_position, render_muti_coordinate, 0, false, distance, 0, dir);
				if ((iter == (count - 1)) && index >= renderTimes)
				{
					tp.onComplete=onComplete;
				}
				tp.collisionCall=onHit;
				tp.show(0);
			}
		}
	}
}


