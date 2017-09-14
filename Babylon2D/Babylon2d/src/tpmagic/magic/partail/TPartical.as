package tpmagic.magic.partail
{
	import flash.geom.Point;
	
	import tempest.core.IAnimation;
	import tempest.core.IMagicScene;
	import tempest.core.IPartical;
	import tempest.core.ISceneCharacter;
	import tempest.data.map.Direction;
	import tempest.enum.AnimationType;
	import tempest.pool.IPoolsObject;
	import tempest.pool.ObjectPools;
	import tempest.template.MagicInfo;
	import tempest.utils.Geom;
	import tempest.utils.Random;
	
	import tpmagic.magic.shape.ParticalShape;
	import tpmagic.util.MagicHelper;

	public class TPartical implements IPartical, IPoolsObject
	{
		/***粒子显示对象*/
		public var partical:IAnimation=null;
		/***魔法信息*/
		public var magicInfo:MagicInfo=null;
		/**施法朝向*/
		public var dirction:int;
		/***粒子位置*/
		private var _position:Point=null;
		//////
		/**粒子发射的施法点*/
		public var castPoint:Point;
		/***目标点(原始引用点，用于追踪)*/
		public var targetPoint:Point=null;
		/***起点到终点距离*/
		public var distance:int=0;
		/**旋转角度*/
		public var rotation:int=0;
		/**旋转方向*/
		public var dir:int=0;
		/** * 身体偏移 */
		public var body_offset:int;
		/**受击者*/
		public var targeter:ISceneCharacter;
		/**粒子场景*/
		public var scene:IMagicScene;
		/**碰撞回调*/
		public var collisionCall:Function;
		/**真实碰撞回调*/
		public var onComplete:Function;
		/***粒子状态*/
		private var _disposed:Boolean;


		/**
		 *创建魔法粒子
		 * @param type  类型
		 * @param moudelID  模版ID
		 * @param position  位置
		 *
		 */
		public function TPartical(targeter:ISceneCharacter, magicInfo:MagicInfo, scene:IMagicScene, position:Point, direction:int)
		{
			reset(targeter, magicInfo, scene, position, direction);
		}

		/**
		 *
		 * @param magicInfo
		 * @param position
		 * @param hitFunction
		 * @param guid
		 *
		 */
		public function reset(... agrs):void
		{
			_disposed=false;
			this.targeter=agrs[0];
			this.magicInfo=agrs[1];
			this.scene=agrs[2];
			this.position=agrs[3];
			this.dirction=agrs[4];
			var effectId:String=magicInfo ? magicInfo.magic_effectid.toString() : "0";
			if (effectId != "0")
			{
				if (!magicInfo.is_magic_face) //过程面向
				{
					dirction=-1;
				}
				var packges:Object=MagicHelper.packges;
				var packId:String=(packges[effectId] || magicInfo.id.toString())
				partical=scene.createAnimation(effectId, position.x, position.y, packId, dirction);
				partical.type=AnimationType.Loop;
			}
		}

		/**
		 * 显示对象
		 * @return
		 *
		 */
		public function get ianimation():IAnimation
		{
			return partical;
		}

		/**
		 * 设置受击数据
		 * @param hitFuc
		 * @param magicInfo
		 * @param rotation
		 * @param renderPoint
		 * @param isTrack
		 * @param distanse
		 * @param isOffset
		 *
		 */
		public function initMagicData(targetP:Point, distance:int, rotation:int, body_offset:int, isTrack:Boolean, isOffset:Boolean):void
		{
			this.rotation=rotation;
			this.distance=distance;
			this.body_offset=body_offset;
			/*************************设置目标点***********************************/
			if (targetP)
			{
				if (isTrack)
				{
					this.targetPoint=targetP;
				}
				else
				{
					this.targetPoint=targetP.clone();
				}
			}
			else
			{
				this.targetPoint=null;
			}
			/*************************设置效果点***********************************/
			if (!isTrack && this.targetPoint)
			{
				if (isOffset)
				{
					this.targetPoint.y-=body_offset;
				}
			}
			/*************************计算距离***********************************/
			if (position)
			{
				if (distance > 0)
				{
					this.distance=distance;
				}
				else if (targetPoint)
				{
					this.distance=Geom.getDistance(position, targetPoint);
				}
			}
			/*************************角度***********************************/
			if (partical)
			{
				var scale:Number=NaN;
				if (isTrack)
				{ //追踪粒子不进行角度计算
					return;
				}
				if (magicInfo.is_rotation != 0) //朝向运动方向
				{
					if (magicInfo.render_rotation != 0) //不指向运动方向,使用指定朝向并有随机值
					{
						this.rotation=magicInfo.render_rotation + ((magicInfo.render_rondom_rotation != 0) ? Random.range(-magicInfo.render_rondom_rotation, magicInfo.render_rondom_rotation) : 0);
					}
					else
					{
						this.rotation=Geom.GetRotation(position, targetPoint);
					}
					partical.rotation=this.rotation;
				}
			}
		}

		/**
		 * 获取朝向
		 * @param isSwape
		 *
		 */
		public function getDir(isSwape:Boolean=false):int
		{
			if (!castPoint)
			{
				return 0;
			}
			if (!isSwape)
			{
				return Direction.getDirection(castPoint, position); //计算粒子朝向
			}
			else
			{
				return Direction.getDirection(position, castPoint); //计算粒子朝向
			}
		}

		/**
		 *设置粒子位置
		 * @param value
		 *
		 */
		public function set position(value:Point):void
		{
			_position=value;
			if (_position != null)
			{
				_pos_x=_position.x;
				_pos_y=_position.y;
				if (partical != null)
				{
					partical.setPosition(_pos_x, _pos_y);
				}
			}
		}

		/**
		 * 粒子显示
		 *
		 */
		public function show(duration:Number):void
		{
			if (partical)
			{
				scene.addEffect(partical);
				var magicShape:ParticalShape=ParticalShape.Get(magicInfo.swapValue);
				magicShape.emitter(this, duration); //粒子发射
			}
			else
			{
				onHit();
			}
		}

		/**
		 * 清理粒子显示
		 *
		 */
		private function clearPartical():void
		{
			if (!partical)
			{
				return;
			}
			scene.freeAnimation(partical);
			partical=null;
		}

		/**
		 *获取粒子位置
		 * @return
		 *
		 */
		public function get position():Point
		{
			return _position;
		}
		private var _pos_x:int;

		public function get pos_x():int
		{
			return _pos_x;
		}

		/**
		 *设置粒子坐标
		 * @param value
		 *
		 */
		public function set pos_x(value:int):void
		{
			if (_disposed)
			{
				return;
			}
			if (_pos_x != value)
			{
				_pos_x=value;
				if (_position != null)
				{
					_position.x=value;
				}
				if (partical)
				{
					partical.setPosition(value, pos_y);
				}
			}
		}
		private var _pos_y:int;

		public function get pos_y():int
		{
			return _pos_y;
		}

		public function set pos_y(value:int):void
		{
			if (_disposed)
			{
				return;
			}
			if (_pos_y != value)
			{
				_pos_y=value;
				if (_position != null)
				{
					_position.y=value;
				}
				if (partical)
				{
					partical.setPosition(pos_x, value);
				}
			}
		}

		/**
		 * 碰撞(粒子到达目标点)
		 *
		 */
		public function onHit():void
		{
			if (_disposed)
			{
				return;
			}
			var rotation:Number=0;
			if (magicInfo.hit_effect)
			{
				if (magicInfo.is_hit_rotation)
				{
					rotation=this.rotation;
				}
				var dir:int=!magicInfo.is_hit_face ? -1 : getDir();
				MagicHelper.addEffect(scene, magicInfo.hit_effect.toString(), targeter, new Point(pos_x, pos_y), rotation, dir, magicInfo.id.toString()); //碰撞光效加在粒子消失的地方
			}
			if (collisionCall != null)
			{
				collisionCall();
			}
			if (onComplete != null)
			{
				onComplete(true);
			}
			ObjectPools.free(this);
		}



		/**
		 *移除自身
		 *
		 */
		public function dispose():void
		{
			_disposed=true;
			_position=null;
			targetPoint=null;
			clearPartical();
			magicInfo=null;
			dirction=0;
			castPoint=null;
			distance=0;
			rotation=0;
			dir=0;
			body_offset=0
			targeter=null;
			scene=null;
			onComplete=null;
		}
	}
}
