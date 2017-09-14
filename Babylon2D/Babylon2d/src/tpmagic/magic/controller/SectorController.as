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
	 * 扇形控制器
	 * @author zhangyong
	 *
	 */
	public class SectorController extends BaseController implements IController
	{

		/**
		 * 渲染控制器
		 *
		 */
		public override function runController(index:int, scene:IMagicScene, targeter:ISceneCharacter, renderPoint:Point, targetPoint:Point, magicInfo:MagicInfo, dir:int, renderTimes:int, onComplete:Function, onHit:Function):void
		{
			/**总角度*/
			var totalAngle:int=Geom.GetRotation(renderPoint, targetPoint);
			/**发射数量*/
			var count:int=magicInfo.diffuse_num;
			//
			var iter:int=0;
			var tempVar0:Number;
			/**单个角度*/
			var singleAngle:int=0;
			/**间隔角度*/
			var diffAngle:int=0;
			/**起始角度*/
			var startAngle:int=0;
			/**结束角度*/
			var endAngle:int=0;
			/**递增角度*/
			var otherAngle:int=0;
			/**是否发射的最后一个粒子*/
			var isLast:Boolean;
			for (; iter != count; iter++)
			{
				/////////改变量///////
				/*************************角度***********************************/
				singleAngle=magicInfo.diffuse_angle + ((magicInfo.render_rondom_angle != 0) ? Random.range(-magicInfo.render_rondom_angle, magicInfo.render_rondom_angle) : 0); //间隔角度+随机间隔角度
				diffAngle=((magicInfo.diffuse_num - 1) >> 1) * singleAngle;
				startAngle=(totalAngle - diffAngle) + (magicInfo.render_angle + Random.range(-magicInfo.render_rondom_angle, magicInfo.render_rondom_angle)); //开始角度+加偏移角度+偏移角度随机值
				endAngle=totalAngle + diffAngle; //结束角度
				otherAngle=startAngle + singleAngle * iter;
				tempVar0=otherAngle * Geom.RAD_RANGLE;
				isLast=((iter == (count - 1)) && index >= renderTimes);
				createSinglePartical(index, scene, renderPoint, magicInfo, dir, tempVar0, (isLast ? onComplete : null), onHit);
			}
		}

		/**
		 * 创建单个粒子
		 *
		 */
		protected function createSinglePartical(index:int, scene:IMagicScene, renderPoint:Point, magicInfo:MagicInfo, dir:int, tempVar0:Number, onComplete:Function, onHit:Function):void
		{
			/**临时变量1*/
			var tempVar1:int=0;
			/**临时变量2*/
			var tempVar2:int=0;
			/**距离*/
			var distance:int=magicInfo.area_raidus * scene.tileWidth;
			var isGameAngle:Boolean=(magicInfo.is_game_angle != 0);
			tempVar1=renderPoint.x + (distance) * Math.cos(tempVar0);
			if (isGameAngle) //是否使用斜角计算
			{
				tempVar2=renderPoint.y + distance * magicInfo.game_angle * Math.sin(tempVar0);
			}
			else
			{
				tempVar2=renderPoint.y + distance * Math.sin(tempVar0);
			}
			var muti_coordinate:Point=new Point(tempVar1, tempVar2); //计算终点
			var duration:Number=0;
			var speed:int=magicInfo.effect_movespeed;
			if (speed > 0 && distance > 0)
			{
				duration=distance / speed;
			}
			var tp:TPartical=renderTPartical(null, magicInfo, scene, renderPoint, muti_coordinate, 0, false, ((isGameAngle) ? 0 : distance), 0, dir);
			if (onComplete != null)
			{
				tp.onComplete=onComplete;
			}
			tp.collisionCall=onHit;
			tp.show(duration);
		}
	}
}
