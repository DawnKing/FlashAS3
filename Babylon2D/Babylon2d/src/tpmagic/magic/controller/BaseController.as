package tpmagic.magic.controller
{
	import flash.geom.Point;
	
	import tempest.core.IMagicScene;
	import tempest.core.ISceneCharacter;
	import tempest.pool.ObjectPools;
	import tempest.template.MagicInfo;
	import tempest.utils.Geom;
	
	import tpmagic.magic.enum.ShapeType;
	import tpmagic.magic.partail.TPartical;

	/**
	 * 粒子形状运算基类
	 * @author zhangyong
	 *
	 */
	public class BaseController
	{
		/**
		 * 渲染控制器
		 *
		 */
		public function runController(index:int, scene:IMagicScene, targeter:ISceneCharacter, renderPoint:Point, targetPoint:Point, magicInfo:MagicInfo, dir:int, renderTimes:int, onComplete:Function, onHit:Function):void
		{
			throw new Error("方法必须重写");
		}

		/**
		 *创建粒子
		 * @param magicInfo
		 * @param distance
		 * @param isTrack
		 * @param isOffset
		 * @param angel
		 * @param position 粒子起始点
		 * @param tPoint 粒子目标点
		 * @return
		 *
		 */
		protected function renderTPartical(targeter:ISceneCharacter, magicInfo:MagicInfo, scene:IMagicScene, renderPoint:Point, targetPoint:Point, bodyOffset:int=0, isOffset:Boolean=true, distance:int=0, rotation:int=0, dir:int=-1):TPartical
		{
			var tPartical:TPartical=ObjectPools.malloc(TPartical,targeter, magicInfo, scene, renderPoint.clone(), dir) as TPartical;
			var isTrackShape:Boolean=magicInfo.elementType == ShapeType.SHAPE_TRACK_LINE;
			tPartical.castPoint=renderPoint;
			tPartical.initMagicData(targetPoint, distance, rotation, bodyOffset, isTrackShape, isOffset);
			if (tPartical.partical)
			{
				if (tPartical.magicInfo.is_rotation) //重新定向
				{
					if (tPartical.position && tPartical.targetPoint)
					{
						tPartical.partical.rotation=Geom.GetRotation(tPartical.position, tPartical.targetPoint);
					}
				}
			}
			return tPartical;
		}
	}
}
