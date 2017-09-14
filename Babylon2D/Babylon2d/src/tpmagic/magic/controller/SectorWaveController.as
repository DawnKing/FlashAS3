package tpmagic.magic.controller
{
	import flash.geom.Point;
	
	import tempest.core.IMagicScene;
	import tempest.template.MagicInfo;
	
	import tpmagic.magic.partail.TPartical;

	/**
	 * 扇形多波控制器
	 * @author zhangyong
	 *
	 */
	public class SectorWaveController extends SectorController
	{
		/**临时变量3*/
		protected var tempVar3:int;

		/**
		 * 创建单个粒子
		 *
		 */
		protected override function createSinglePartical(index:int, scene:IMagicScene, renderPoint:Point, magicInfo:MagicInfo, dir:int, tempVar0:Number, onComplete:Function, onHit:Function):void
		{
			/**临时变量1*/
			var tempVar1:int=0;
			/**临时变量2*/
			var tempVar2:int=0;
			/**距离*/
			var distance:int=magicInfo.area_raidus * scene.tileWidth;
			var isGameAngle:Boolean=(magicInfo.is_game_angle != 0);
			tempVar3=distance * (index + 1);
			tempVar1=renderPoint.x + (tempVar3) * Math.cos(tempVar0);
			if (isGameAngle) //是否使用斜角计算
			{
				tempVar2=renderPoint.y + tempVar3 * magicInfo.game_angle * Math.sin(tempVar0);
			}
			else
			{
				tempVar2=renderPoint.y + tempVar3 * Math.sin(tempVar0);
			}
			var muti_coordinate:Point=new Point(tempVar1, tempVar2); //计算终点
			//起点和终点相同
			var duration:Number=0;
			var speed:int=magicInfo.effect_movespeed;
			if (speed > 0 && distance > 0)
			{
				duration=distance / speed;
			}
			var tp:TPartical=renderTPartical(null, magicInfo, scene, muti_coordinate, muti_coordinate, 0, false, ((isGameAngle) ? 0 : tempVar3), 0, dir);
			if (onComplete != null)
			{
				tp.onComplete=onComplete;
			}
			tp.collisionCall=onHit;
			tp.show(duration);
		}
	}
}
