package tpmagic.magic
{
	import flash.geom.Point;

	import starling.animation.Juggler;
	import starling.animation.Tween;

	import tempest.core.IMagicScene;
	import tempest.enum.Status;
	import tempest.pool.IPoolsObject;
	import tempest.pool.ObjectPools;
	import tempest.template.MagicInfo;
	import tempest.utils.Geom;
	import tempest.utils.Random;

	import tpmagic.magic.controller.BaseController;
	import tpmagic.magic.core.IMagic;
	import tpmagic.magic.enum.ControllerType;
	import tpmagic.magic.enum.SpellType;
	import tpmagic.util.MagicHelper;

	/**
	 * 技能魔法表现对象
	 * @author zhangyong
	 *
	 */
	public class BaseMagic implements IMagic, IPoolsObject
	{
		/**释放效果*/
		public static const CASTER_EFFECT:String="caster_effect";
		/**声音回调*/
		public static var soundCallBack:Function;
		/**发射点*/
		protected var _renderPoint:Point=null;
		/**目标点*/
		protected var _targetPoint:Point=null;
		/**施法者*/
		private var _caster:IMagicObject=null;
		/**目标*/
		private var _targeter:IMagicObject=null;
		/***当前发射次数*/
		private var _currentRenderTimes:int=0;
		/**魔法信息*/
		public var magicInfo:MagicInfo=null;
		/**场景*/
		public var scene:IMagicScene;
		/**释放技能完毕*/
		public var onCastComplete:Function;
		/**缓动对象*/
		private var _tween:Tween;
		/**发射次数*/
		private var _renderTimes:int;
		/**粒子创建控制器*/
		private var _controller:BaseController;
		/**是否播放声音*/
		private var isSound:Boolean;
		/**跳跃是否阴影*/
		private var _leaveShadow:Boolean;
		/**设置受击效果*/
		private var _hitInfos:Array;
		/**是否已释放*/
		private var _disposed:Boolean=false;


		/**
		 * 目标
		 * @param scene
		 * @param magicInfo
		 * @param caster
		 * @param targeter
		 * @param tragetP
		 * @param leaveShadow
		 * @param isSound
		 *
		 */
		public function BaseMagic(scene:IMagicScene, magicInfo:MagicInfo, caster:IMagicObject, targeter:IMagicObject, tragetP:Point=null, leaveShadow:Boolean=false, isSound:Boolean=false)
		{
			reset(scene, magicInfo, caster, targeter, tragetP, leaveShadow, isSound);
		}

		/**
		 *重置对象
		 * @param args
		 *
		 */
		public function reset(... args):void
		{
			this.scene=args[0];
			this.magicInfo=args[1];
			this._caster=args[2];
			this._targeter=args[3];
			this.targetPoint=args[4] || (_targeter ? _targeter.wpos.pixel : null);
			this._leaveShadow=args[5];
			this.isSound=args[6];
			this.renderPoint=_caster.wpos.pixel.clone();
			this._disposed=false;
		}


		/**
		 * 释放
		 *
		 */
		public function casting():void
		{
			if (this._disposed) //可能播放动作的时候把自身释放掉了
			{
				return;
			}
			if (!_caster || !_caster.usable)
			{
				onComplete();
				return;
			}
			casterEffect(_caster, magicInfo, _targetPoint, false);
			_controller=ControllerType.getController(magicInfo.controllerType);
			if (!magicInfo.emitter_delay)
			{
				onCasting();
			}
			else
			{
				App.timer.doOnce(magicInfo.emitter_delay * 1000, onCasting);
			}
		}

		/**
		 * 开始执行发射
		 *
		 */
		private function onCasting():void
		{
			if (this._disposed) //可能播放动作的时候把自身释放掉了
			{
				return;
			}
			casterEffect(_caster, magicInfo, _targetPoint, true); //关键帧的施法
			switch (magicInfo.spell_type)
			{
				case SpellType.SPELL_TPSPELL:
					setRenderTimes();
					if (magicInfo.attack_actions != Status.JUMP.toString())
					{
						_caster.playTo(magicInfo.actions[0]);
					}
					else
					{
						_caster.jump(Status.JUMP, _targetPoint, null, _leaveShadow);
					}
					if (this._disposed) //可能播放动作的时候把自身释放掉了
					{
						return;
					}
					App.timer.doLoop(magicInfo.effect_interval, renderController);
					break;
				case SpellType.SPELL_MOVESPACE: //闪现，冲锋
					_caster.stopWalk(false);
					if (magicInfo.swapValue != 0) //闪现
					{
						var _logicTarget:Point=scene.sceneMapData.Pixel2Tile(_targetPoint)
						_caster.setPostion(_logicTarget.x, _logicTarget.y);
						App.timer.doFrameOnce(3, spaceComplete); //保险一下，可能动作回调不会执行
					}
					else //冲锋
					{
						_caster.playTo(magicInfo.actions[0]);
						var dis:Number=Point.distance(_caster.wpos.pixel, _targetPoint);
						var duration:Number=dis / magicInfo.effect_movespeed;
						//
						_tween=Juggler.instance.tween(_caster, duration, {x: _targetPoint.x, y: _targetPoint.y}) as Tween;
						_tween.onComplete=moveComplete;
					}
					break;
			}
		}

		/**
		 * 闪现完毕
		 *
		 */
		private function moveComplete():void
		{
			var _logicTarget:Point=scene.mapConfig.Pixel2Tile(_targetPoint);
			_caster.setPostion(_logicTarget.x, _logicTarget.y);
			spaceComplete();
		}

		/**
		 * 闪现完毕
		 *
		 */
		private function spaceComplete():void
		{
			if (_disposed)
			{
				return;
			}
			_caster.playTo(Status.STAND);
			if (!_caster)
			{
				onComplete();
			}
			var effectID:String;
			var rotation:Number=0;
			if (magicInfo.hit_effect)
			{
				MagicHelper.addEffect(scene, magicInfo.hit_effect.toString(), _caster, _caster.wpos.pixel.clone(), rotation, -1, magicInfo.id.toString()); //碰撞光效加在粒子消失的地方
			}
			onComplete();
		}

		/**
		 * 发射粒子
		 *
		 */
		public function renderController():void
		{
			if (_disposed)
			{
				return;
			}
			if (_controller)
			{
				_currentRenderTimes++;
				if (_currentRenderTimes >= _renderTimes) //清理发射定时器
				{
					App.timer.clearTimer(renderController);
				}
				_controller.runController(_currentRenderTimes - 1, scene, _targeter, renderPoint, targetPoint, magicInfo, _caster.wpos.toward, _renderTimes - 1, onComplete, onHit);
			}
			else
			{
				onComplete();
			}
		}

		/**
		 * 受击表现(光效到达目标点)
		 *
		 */
		protected function onHit():void
		{

		}

		/**
		 * 能释放完成
		 * @param isHit 是否是碰撞导致的完成
		 *
		 */
		protected function onComplete(isHit:Boolean=false):void
		{
			if (_disposed)
			{
				return;
			}
			_disposed=true;
			if (_tween)
			{
				_tween=null;
			}
			App.timer.clearTimer(renderController);
			//主角的技能使用音效
			var soundStr:String=magicInfo.magicsound_id;
			if (isSound && soundCallBack != null && soundStr && soundStr.length > 4)
			{
				soundCallBack(soundStr);
			}
			if (_hitInfos) //如果结束前收到了受击效果
			{
				MagicHelper.hurtEffect(scene, magicInfo, _hitInfos);
			}
			if (onCastComplete != null)
			{
				var tempFuc:Function=onCastComplete;
				onCastComplete=null;
				tempFuc.call();
			}
			ObjectPools.free(this);
		}

		/**
		 * 设置受击效果
		 * @param hitInfos
		 *
		 */
		public function setHurts(hitInfos:Array):void
		{
			_hitInfos=hitInfos;
		}

		/**
		 *设置效果点
		 * @param value
		 *
		 */
		public function set targetPoint(value:Point):void
		{
			var offset_x:int=magicInfo.effect_offset_rondom_x;
			var offset_y:int=magicInfo.effect_offset_rondom_y;
			if ((offset_x != 0) || (offset_y != 0) || magicInfo.effect_offset_x != 0 || magicInfo.effect_offset_x != 0)
			{
				var newx:int=value.x + (magicInfo.effect_offset_x + ((offset_x != 0) ? Random.range(-offset_x, offset_x) : 0));
				var newy:int=value.y + (magicInfo.effect_offset_y + ((offset_y != 0) ? Random.range(-offset_y, offset_y) : 0));
				_targetPoint=new Point(newx, newy);
			}
			else
			{
				if (_targetPoint == null || !value.equals(_targetPoint))
					_targetPoint=value;
			}
		}

		public function get targetPoint():Point
		{
			return _targetPoint;
		}

		/**
		 *设置发射点
		 * @param value
		 *
		 */
		public function set renderPoint(value:Point):void
		{
			var offset_x:Number=magicInfo.render_offset_rondom_x;
			var offset_y:Number=magicInfo.render_offset_rondom_y;
			value.x+=(magicInfo.render_offset_x + ((offset_x != 0) ? Random.range(-offset_x, offset_x) : 0));
			value.y+=(magicInfo.render_offset_y + ((offset_y != 0) ? Random.range(-offset_y, offset_y) : 0));
			if (_caster && ControllerType.getRenderOffset(magicInfo.controllerType)) //发射偏移，从胸部打出去看起来正常一点
			{
				value.y-=_caster.bodyOffset;
			}
			if (_renderPoint == null || (value.x != _renderPoint.x && value.y != _renderPoint.y))
				_renderPoint=value;
		}

		public function get renderPoint():Point
		{
			return _renderPoint;
		}

		public function get disposed():Boolean
		{
			return _disposed;
		}

		/**
		 *施法效果
		 * @param caster
		 * @param magicInfo
		 * @param effectPoint
		 * @param onAction
		 */
		public function casterEffect(caster:ISceneCharacter, magicInfo:MagicInfo, effectPoint:Point, onAction:Boolean):void
		{
			if (!caster)
			{
				return;
			}
			if (!magicInfo)
			{
				return;
			}
			var effectID:String;
			var rotation:Number=0;
			var i:int=1;
			var end:int=2;
			if (onAction)
			{
				i=4;
				end=5;
			}
			for (; i <= end; i++)
			{
				effectID=magicInfo[CASTER_EFFECT + i].toString();
				if (effectID != "0")
				{
					if (magicInfo.is_cast_rotation)
					{
						rotation=Geom.GetRotation(caster.wpos.pixel, effectPoint);
					}
					var dir:int=magicInfo.is_cast_face ? caster.wpos.toward : -1;
					MagicHelper.addEffect(scene, effectID, caster, caster.wpos.pixel, rotation, dir, magicInfo.id.toString());
				}
				else
				{
					break;
				}
			}
		}

		/**
		 *获取施法重数
		 * @return
		 *
		 */
		protected function setRenderTimes():void
		{
			_renderTimes=magicInfo.effect_times;
		}


		/**
		 *释放
		 *
		 */
		public function dispose():void
		{
			_caster=null;
			_renderPoint=null;
			_targetPoint=null;
			_currentRenderTimes=0;
			_renderTimes=0;
			_controller=null;
			magicInfo=null;
			scene=null;
			isSound=false;
		}
	}
}
