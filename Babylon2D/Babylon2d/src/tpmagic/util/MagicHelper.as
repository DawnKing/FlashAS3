package tpmagic.util
{
	import flash.geom.Point;
	
	import tempest.core.IAnimation;
	import tempest.core.IMagicScene;
	import tempest.core.ISceneCharacter;
	import tempest.template.MagicInfo;
	import tempest.utils.Geom;
	
	import tpmagic.magic.entity.HitInfo;
	import tpmagic.magic.enum.ShapeType;

	public class MagicHelper
	{
		public static var ZERO_POINT:Point=new Point(0, 0);
		public static var packges:Object;

		/**
		 * 初始化额外包配置
		 * @param packge
		 *
		 */
		public static function init(packge:String):void
		{
			packges={}
			var prs:Array=packge.split("\r\n");
			//添加自定义偏移规则
			var rItem:String;
			for each (rItem in prs)
			{
				if (rItem.indexOf("//") != -1) //跳过注释行
				{
					continue;
				}
				var ritem:Array=rItem.split(" ");
				if (ritem.length == 2) //检测规则是否有效
				{
					var arr:Array=ritem[1].split(",");
					for each (var id:int in arr)
					{
						packges[id]=ritem[0];
					}
				}
			}

		}

		/**
		 *给角色或着场景添加光效
		 * @param effectID  添加光效ID
		 * @param IMagicAvatar 添加光效的对象
		 * @param effectPoint  添加光效点
		 * @param rotation   添加光效偏移
		 *
		 */
		public static function addEffect(scene:IMagicScene, effectId:String, isceneCharacter:ISceneCharacter, effectPoint:Point, rotation:Number, dir:int, packId:String):void
		{
			var ani:IAnimation=null;
			var isBottom:Boolean;
			if (dir != -1)
			{
				isBottom=((dir > 6) || (dir < 2));
			}
			packId=(packges[effectId] || packId); //看看能不能取到特殊分包
			ani=scene.createAnimation(effectId, 0, 0, packId, dir);
			rotation*=Geom.RAD_RANGLE; //转化成弧度
			if (rotation != 0)
			{
				ani.rotation=rotation;
			}
			if (isceneCharacter && (ani.config.target_place & 1)) //角色
			{
				isceneCharacter.addEffect(ani, isBottom);
			}
			else if (effectPoint)
			{
				var offset:int;
				if (ani.config.body_place & 2)
				{
					offset=effectPoint.y - ((isceneCharacter) ? isceneCharacter.bodyOffset : 50);
				}
				else if (ani.config.body_place & 4)
				{
					offset=effectPoint.y - ((isceneCharacter) ? isceneCharacter.headOffset : 125);
				}
				else
				{
					offset=effectPoint.y;
				}
				ani.setPosition(effectPoint.x, offset);
				scene.addEffect(ani, isBottom);
			}
		}

		/**
		 * 受击效果
		 * @param scene
		 * @param s
		 *
		 */
		public static function hurtEffect(scene:IMagicScene, magicInfo:MagicInfo, hitInfos:Array):void
		{
			for each (var ht:HitInfo in hitInfos) //受击表现
			{
				if (ht.targeter && magicInfo.hurt_effect)
				{
					MagicHelper.addEffect(scene, magicInfo.hurt_effect.toString(), ht.targeter, null, 0, -1, magicInfo.id.toString()); //碰撞光效加在粒子消失的地方
				}
				ht.showDamageInfo();
				ht.hitBack();
				ht.onHurt();
			}
		}

		/**
		 *根据方向获取旋转角度
		 * @param orient
		 * @return
		 *
		 */
		public static function getRotationByOrient(orient:int):int
		{
			switch (orient)
			{
				case 0:
					return 270;
				case 1:
					return 315;
				case 2:
					return 0;
				case 3:
					return 45;
				case 4:
					return 90;
				case 5:
					return 135;
				case 6:
					return 180;
				case 7:
					return 225;
			}
			return 0;
		}

		/**
		 *计算最近的一点
		 * @param tile_p
		 * @param ordien
		 * @return
		 *
		 */
		public static function getPoint(tile_p:Point, ordien:int, distance:int=1):Point
		{
			switch (ordien)
			{
				case 0:
					tile_p.y+=distance;
					break;
				case 1:
					tile_p.y+=distance;
					tile_p.x-=distance;
					break;
				case 2:
					tile_p.x-=distance;
					break;
				case 3:
					tile_p.y-=distance;
					tile_p.x-=distance;
					break;
				case 4:
					tile_p.y-=distance;
					break;
				case 5:
					tile_p.y-=distance;
					tile_p.x+=distance;
					break;
				case 6:
					tile_p.x+=distance;
					break;
				case 7:
					tile_p.y+=distance;
					tile_p.x+=distance;
					break;
			}
			return tile_p;
		}

		/**
		 *转换受击对象为魔法点
		 * @param hurts
		 * @param hitFuc
		 * @param magicInfo
		 * @return
		 *
		 */
		public static function inithitInfos(hurts:Array, magicInfo:MagicInfo, renderPiexlPoint:Point, raidus:int):void
		{
			var hitInfo:HitInfo=null;
			var len:int=hurts.length;
			var oldPosition:Point;
			var i:int=0;
			switch (magicInfo.elementType)
			{
				case ShapeType.SHAPE_LINE: //线
				case ShapeType.SHAPE_LINK: //链
					i=0;
					for (; i != len; ++i)
					{
						hitInfo=hurts[i];
						if (hitInfo)
						{
							oldPosition=hitInfo.position;
//							hitInfo.position=null; //清除引用
							hitInfo.position=GetEndPoint(renderPiexlPoint, oldPosition, raidus);
						}
					}
					break;
				case ShapeType.SHAPE_TRACK_LINE:
					i=0;
					for (; i != len; ++i)
					{
						hitInfo=hurts[i];
						if (hitInfo && hitInfo.targeter)
						{
							oldPosition=hitInfo.position;
							hitInfo.position=new Point(oldPosition.x, oldPosition.y - hitInfo.targeter.bodyOffset);
						}
					}
					break;
			}
		}

		/**
		 *根据起始点、鼠标点击点和距离计算结束点
		 * @param beginPoint
		 *athor enger
		 */
		public static function GetEndPoint(beginPoint:Point, mousePoint:Point, distance:Number):Point
		{
			var angle:Number=Geom.GetRotation(beginPoint, mousePoint) * Geom.RAD_RANGLE;
			var p:Point=new Point(Math.cos(angle) * distance + beginPoint.x, Math.sin(angle) * distance + beginPoint.y);
			return p;
		}
		
		
	}
}
