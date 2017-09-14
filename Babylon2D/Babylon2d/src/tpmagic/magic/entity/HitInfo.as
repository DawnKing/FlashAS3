package tpmagic.magic.entity
{
	import flash.geom.Point;
	
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.animation.Tween;
	
	import tempest.core.IHealth;
	import tempest.core.IHitInfo;
	import tempest.core.ISceneCharacter;
	import tempest.data.map.MapConfig;
	import tempest.enum.Status;
	import tempest.flytext.vo.FlyTextData;
	import tempest.pool.IPoolsObject;
	import tempest.pool.ObjectPools;
	import tempest.utils.Geom;
	
	import tpmagic.magic.core.IDamge;


	/**
	 * 目标打击信息
	 * @author zhangyong
	 *
	 */
	public class HitInfo implements IHitInfo, IPoolsObject
	{
		/*** 是否死亡*/
		public var isDead:Boolean;
		/***是否怪物*/
		public var isMonster:Boolean;
		/**来自玩家的打击*/
		public var isFromHero:Boolean;
		/**玩家被打击*/
		public var isAfterHero:Boolean;
		/**锁定，不播动作，不击退，不击飞*/
		private var _isLock:Boolean;
		///////////////////////////////////
		/***目标guid*/
		public var guid:String;
		/***坐标*/
		private var _position:Point=null;
		/***释放者像素坐标 */
		public var casterPoint:Point=null;
		/*** 对象 */
		public var targeter:ISceneCharacter;
		/**是否已释放*/
		private var _disposed:Boolean;
		/**是否微击退*/
		private var _littleBack:Boolean;
		/**伤害信息*/
		public var damages:Vector.<FlyTextData>;
		/**角度*/
		private var angle:Number;

		public function set position(value:Point):void
		{
			_position=value;
		}

		public function get position():Point
		{
			return _position;
		}

		public function HitInfo(targeter:ISceneCharacter, targetPoint:Point)
		{
			reset(targeter, targetPoint);
		}

		public function reset(... parms):void
		{
			this.targeter=parms[0];
			this.position=parms[1];
			_isLock=false;
			_littleBack=false;
			if (targeter)
			{
				var idamage:IDamge=targeter.data as IDamge;
				_isLock=idamage.isLock;
				_littleBack=idamage.littleBack;
			}
			isDead=false;
			isMonster=false;
			isFromHero=false;
			isAfterHero=false;
			_disposed=false;

		}

		/**
		 * 添加伤害信息
		 * @param damageInfo
		 *
		 */
		public function addDamageInfo(damageInfo:FlyTextData):void
		{
			if (!damages)
			{
				damages=new Vector.<FlyTextData>();
			}
			damages.push(damageInfo);
		}

		/**
		 * 显示伤害信息
		 * @param isAction
		 *
		 */
		public function showDamageInfo(isMuti:Boolean=false):void
		{
			if (!damages)
			{
				return;
			}
			if (!damages.length)
			{
				return;
			}
			if (!targeter || !targeter.usable)
			{
				return;
			}
			var len:int=damages.length;
			for (var i:int=0; i < len; i++)
			{
				var damageInfo:FlyTextData=damages[i];
				var idamage:IDamge=targeter.data as IDamge;
				if (idamage) //扣血显示
				{
					idamage.hpChange(damageInfo.flag, damageInfo.damage);
				}
				//飘字
				targeter.scene.flyTextTagger.addFlyText(casterPoint, targeter, damageInfo);
			}
		}

		/**
		 * 击退
		 *
		 */
		public function hitBack():void
		{
			if (_isLock)
			{
				return;
			}
			if (!_littleBack && !isFromHero)
			{
				return;
			}
			if (!targeter || !targeter.usable)
			{
				return;
			}
			if (targeter.hitDistance < BACKMX) //微击退
			{
				var mapData:MapConfig=targeter.scene.mapConfig;
				if (!mapData)
				{
					return;
				}
				angle=Geom.getTwoPointRadian(casterPoint, targeter.wpos.pixel) + Math.PI;
				var _shakeX:Number=targeter.wpos.pixel.x + BACK * Math.cos(angle);
				var _shakeY:Number=targeter.wpos.pixel.y + BACK * Math.sin(angle);
				var tx:int=(_shakeX / mapData.tileWidth) >> 0;
				var ty:int=(_shakeY / mapData.tileHeight) >> 0
				if (mapData.isBlock(tx, ty)) //击退点是掩码
				{
					return;
				}
				targeter.hitDistance+=BACK;
				Juggler.instance.tween(targeter, BACK_DUARTION, {x: _shakeX, y: _shakeY});
			}
		}

		public function get disposed():Boolean
		{
			return _disposed;
		}

		/**
		 * 受击效果
		 *
		 */
		public function onHurt():void
		{
			if (targeter == null || !targeter.usable)
			{
				onHitComplete();
				return;
			}
			if (targeter.hitLock) //已经在击飞了
			{
				return;
			}
			_oldScaleX=targeter.scaleX;
			_oldScaleY=targeter.scaleY;
			var ihealth:IHealth=targeter.data as IHealth;
			if (ihealth.health > 0) //实际上还没死
			{
				isDead=false;
			}
			if (isDead && !_isLock) //死亡击飞
			{
				var endX:Number;
				var endY:Number;
				targeter.hitLock=true;
				targeter.deadLock=true;
				targeter.stopWalk(false);
				hurtAction(Status.BEATEN);
				angle=Geom.getTwoPointRadian(casterPoint, targeter.wpos.pixel) + Math.PI;
				var cng:Number=Math.cos(angle);
				var sng:Number=Math.sin(angle);
				endX=targeter.x + DISTANCE * cng;
				endY=targeter.y + DISTANCE * sng;
				_upObj={};
				_upObj.s=1;
				_upObj.y=0;
				_upTween=Juggler.instance.tween(_upObj, HALF, {s: SCALE, y: OFFSET}) as Tween; //开始向上
				_upTween.transition=Transitions.EASE_OUT;
				_upTween.onUpdate=upChange;
				_upTween.onComplete=upComplete;
				////
				_hitBackTween=Juggler.instance.tween(targeter, DUARTION, {x: endX, y: endY}) as Tween;
				_hitBackTween.transition=Transitions.EASE_OUT;
			}
			else //普通受击
			{
				onHitComplete();
			}
		}

		private var _oldX:Number;
		private var _oldY:Number;
		private var _oldScaleX:Number;
		private var _oldScaleY:Number;

		/**
		 * 死亡表现
		 * @param isDirect
		 *
		 */
		private function onHitComplete():void
		{
			if (disposed)
			{
				return;
			}
			if (_hitBackTween)
			{
				_hitBackTween=null;
			}
			if (targeter)
			{
				var ihealth:IHealth=targeter.data as IHealth;
				var idamage:IDamge=targeter.data as IDamge;
				if (idamage && !_isLock && (Math.random() < idamage.injureRate)) //暴击了播受击动作
				{
					hurtAction(Status.BEATEN);
				}
				if (ihealth && targeter.usable)
				{
					if (_downpTween)
					{
						targeter.scaleX=targeter.scaleY=1;
						_downpTween=null;
					}
					targeter.deadLock=false;
					targeter.hitLock=false;
					if (isDead && idamage)
					{
						idamage.onDead();
					}
				}
			}
			ObjectPools.free(this);
		}

		/**
		 *受击动作
		 * Status.INJURE 播一帧并停止
		 *
		 */
		private function hurtAction(status:int):void
		{
			if (!targeter.usable)
			{
				return;
			}
			if (casterPoint)
			{
				targeter.faceToPixcel(casterPoint, true);
			}
			targeter.playTo(status);
		}
		public static const BeKnock_Distance:int=200;
		/***抛物线高度*/
		private static const OFFSET:int=-140;
		/***抛出距离*/
		private static const DISTANCE:int=300;
		/***抛空缩放*/
		private static const SCALE:Number=1.2;
		/***抛出垂直运动单向时间*/
		private static var HALF:Number=.25;
		/**抛出水平运动时间**/
		private static var DUARTION:Number=.5;
		/**击退距离*/
		private static var BACK:int=10;
		/**最远击退50pixcl*/
		private static var BACKMX:int=100;
		/**抛出水平运动时间**/
		private static var BACK_DUARTION:Number=0.01;

		private var _upObj:Object;
		private var _downObj:Object;
		private var _upTween:Tween;
		private var _downpTween:Tween;
		private var _hitBackTween:Tween;

		/**
		 * 向上结束
		 * @param gt
		 *
		 */
		private function upComplete():void
		{
			if (_upTween)
			{
				_upTween=null;
			}
			_downObj={};
			_downObj.s=SCALE;
			_downObj.y=OFFSET;
			_downpTween=Juggler.instance.tween(_downObj, HALF, {s: 1, y: 0}) as Tween;
			_downpTween.transition=Transitions.EASE_IN;
			_downpTween.onComplete=onHitComplete;
			_downpTween.onUpdate=downChange;
		}

		/**
		 *向上改变
		 * @param gt
		 *
		 */
		private function upChange():void
		{
			targeter.scaleX=_oldScaleX * _upObj.s
			targeter.scaleY=_oldScaleY * _upObj.s;
			targeter.jumpProgress(_upObj.y, true);
		}

		/**
		 *向下改变
		 * @param gt
		 *
		 */
		private function downChange():void
		{
			if (_disposed)
			{
				return;
			}
			targeter.scaleX=_oldScaleX * _upObj.s
			targeter.scaleY=_oldScaleY * _upObj.s;
			targeter.jumpProgress(_downObj.y, true);
		}

		/**是否击退（服务器击退到指定偏移）*/
		public var isBeatback:Boolean
		/**总伤害*/
		private var _totalDamage:int;

		/**
		 * 获取总伤害值（可能会有正负相抵）
		 * @return
		 *
		 */
		public function get totalDamage():int
		{
			return _totalDamage;
		}

		public function dispose():void
		{
			_disposed=true;
			guid=null;
			targeter=null;
			position=null;
			casterPoint=null;
			isDead=false;
			isMonster=false;
			_littleBack=false;
			_isLock=false;
			isFromHero=false;
			isAfterHero=false;
		}

		/**
		 * 批量回收不用的打击信息
		 * @param hitInfos
		 *
		 */
		public static function frees(hitInfos:Vector.<HitInfo>):void
		{
			var hitInfo:HitInfo;
			while (hitInfos.length)
			{
				hitInfo=hitInfos.pop();
				var targeter:ISceneCharacter=hitInfo.targeter;
				if (hitInfo.isDead && targeter)
				{
					targeter.deadLock=false;
					targeter.hitLock=false;
					var idamage:IDamge=(targeter.data as IDamge);
					if (idamage)
					{
						idamage.onDead();
					}
				}
				ObjectPools.free(hitInfo);
			}
		}
	}
}
