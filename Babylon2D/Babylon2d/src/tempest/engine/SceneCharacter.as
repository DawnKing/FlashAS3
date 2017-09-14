package tempest.engine
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import common.enum.FilterEnum;
	
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.animation.Tween;
	
	import tempest.core.IAnimation;
	import tempest.core.IAvatar;
	import tempest.core.IDisposable;
	import tempest.core.IMagicScene;
	import tempest.core.IPlayAction;
	import tempest.core.IRunable;
	import tempest.core.ISceneCharacter;
	import tempest.data.find.PathCutter;
	import tempest.data.find.TAstar;
	import tempest.data.map.Direction;
	import tempest.data.map.WorldPostion;
	import tempest.engine.graphics.animation.Animation;
	import tempest.engine.graphics.avatar.Avatar;
	import tempest.engine.graphics.avatar.AvatarPart;
	import tempest.engine.graphics.tagger.HeadFace;
	import tempest.enum.AvatarPartType;
	import tempest.enum.Status;
	import tempest.signals.SceneAction_Walk;
	import tempest.template.ActionConfig;
	import tempest.utils.Geom;

	/**
	 * 游戏精灵类
	 * @author zhangyong
	 *
	 */
	public class SceneCharacter implements IPlayAction, ISceneCharacter, IRunable
	{
		/**投影*/
		public static var shadow:BitmapData;
		/** 跳跃类型*/
		public var jumpType:Boolean=true;
		/**脚底阴影*/
		private var _shadow:Bitmap;
		/**死亡标识锁*/
		private var _dead_lock:Boolean=false;
		/**击飞锁*/
		private var _hit_lock:Boolean=false;

		private var _hitDistance:int;

		/**击退累计距离*/
		public function get hitDistance():int
		{
			return _hitDistance;
		}

		/***/
		public function set hitDistance(value:int):void
		{
			_hitDistance=value;
		}

		public function get sortOffset():int
		{
			return _sortOffset;
		}

		public function set sortOffset(value:int):void
		{
			_sortOffset=value;
		}

		/**
		 *
		 * @param type
		 * @param scene
		 * @param hpType
		 */
		public function SceneCharacter(type:int, scene:TScene)
		{
			this.type=type;
			_scene=scene;
			_wpos=new WorldPostion(scene ? scene.tileWidth : 48, scene ? scene.tileHeight : 24);
			_body=new Sprite();
			_body.mouseChildren=_body.mouseEnabled=_body.tabChildren=_body.tabEnabled=false;
			_headFace=new HeadFace(_fullName, 0xFFFFFF, "", null, null);
			_body.addChild(_headFace);
			_avatar=new Avatar(this);
			_body.mouseChildren=_body.mouseEnabled=false;
			useShadow=true;
			_body.addChild(_avatar);
		}

		/**
		 * 驱动
		 * @param nowTime
		 * @param diff
		 *
		 */
		public function run(nowTime:int, diff:int):void
		{
			runAvatar(nowTime, diff);
			if (scene)
			{
				runWalk(nowTime);
				checkShading();
			}
			if (_leaveShow) //留下残影
			{
				leaveshow();
			}
		}

		/**
		 * 停止驱动
		 *
		 */
		public function onStopRun():void
		{
			if (_avatar)
			{
				_avatar.removeAllItem();
			}
			if (_body.parent)
			{
				_body.parent.removeChild(_body);
			}
		}

		/**
		 * 是否显示阴影
		 * @return
		 */
		public function get isInMask():Boolean
		{
			return scene.mapConfig.isMask(wpos.tileX, wpos.tileY);
		}

		/**
		 * 检测是否处于阴影中
		 *
		 */
		public function checkShading():void
		{
			var a:Number=Math.min((isInMask) ? 0.5 : 1, opacity);
			if (_body.alpha != a)
				_body.alpha=a;
		}

		/**
		 *是否使用影子
		 * @param value
		 *
		 */
		public function set useShadow(value:Boolean):void
		{
			if (!value)
			{
				clearShadow();
			}
			else if (_shadow == null)
			{
				_shadow=new Bitmap(shadow);
				_shadow.x=-_shadow.width >> 1;
				_shadow.y=-_shadow.height >> 1;
				this._body.addChildAt(_shadow, 0);
			}
		}

		/**
		 * 清除投影
		 *
		 */
		public function clearShadow():void
		{
			if (_shadow && _shadow.parent)
			{
				_shadow.parent.removeChild(_shadow);
				_shadow=null;
			}
		}

		/**
		 *添加影子
		 * @param shadow
		 *
		 */
		public function addShadow(shadow:Bitmap):void
		{
			clearShadow();
			_shadow=shadow;
			_shadow.x=-_shadow.width >> 1;
			_shadow.y=-_shadow.height >> 1;
			this._body.addChildAt(shadow, 0);
		}

		/**
		 *更新头顶偏移
		 *
		 */
		public function updateHeadOffset():void
		{
			if (this._headFace)
			{
				if (center_y != 0 && headOffset != 0)
				{
					this._headFace.y=-headOffset;
				}
			}
		}
		///////////////////////////属性////////////////////////////////////
		/**是否被选中*/
		public var isSelected:Boolean=false;

		/**
		 * 角色朝向
		 * @return
		 */
		public function get dir():int
		{
			return _avatar.dir;
		}

		public function set dir(value:int):void
		{
			_avatar.dir=value;
		}
		private var _avatar:Avatar;

		public function get avatar():IAvatar
		{
			return _avatar;
		}

		/**
		 * 说话
		 * @param msg
		 */
		public function talk(talkText:String, maxWidth:int=140, talkDelay:int=3000, talkBgSkin:String="", sizeGrid:Array=null, TALKBULLUE_SPACE:int=4):void
		{
			this._headFace.setTalkText(talkText, maxWidth, talkDelay, talkBgSkin, sizeGrid, TALKBULLUE_SPACE);
		}

		public function get isOnMount():Boolean
		{
			return _avatar.isOnMount;
		}

		public function set isOnMount(value:Boolean):void
		{
			_avatar.isOnMount=value;
		}
		private var _selectEffect:Animation=null;

		/**
		 * 隐藏选中特效
		 */
		public function hideSelectEffect():void
		{
			if (_selectEffect)
			{
				Animation.free(this._selectEffect);
				this._selectEffect=null;
			}
		}

		/**
		 * 显示选中特效
		 * @param effect
		 */
		public function showSelectEffect(ani:IAnimation):void
		{
			var effect:Animation=ani as Animation;
			if (effect)
			{
				hideSelectEffect();
				_body.addChildAt(effect.body, 0);
				this._selectEffect=effect;
			}
		}


		public function dispose():void
		{
			if (!_usable)
			{
				return;
			}
			_usable=false;
			render=false;
			_effects=null;
			if (_body.parent)
			{
				_body.parent.removeChild(_body);
			}
			if (this.data is IDisposable)
			{
				IDisposable(this.data).dispose();
			}
			if (this._headFace)
			{
				this._headFace.dispose();
			}
			this._headFace=null;
			this.data=null;
			this.follower=null;
			this.master=null;
			this.removeAllEffect();
			clearShadow();
			hideWarnShape();
			setAvatarFilter(FilterEnum.FILTERNONE);
			if (_avatar)
			{
				_avatar.dispose();
				_avatar=null;
			}
			_leaveShow=false;
			deadLock=false;
		}

		/**
		 * 播放动作
		 * @param status
		 * @param dir
		 * @param apc
		 * @param onEffectFrame
		 * @param onCompleteFrame
		 * @param resetFrame
		 *
		 */
		public function playTo(status:int=-1, dir:int=-1, apc:ActionConfig=null, onEffectFrame:Function=null, onCompleteFrame:Function=null, resetFrame:Boolean=false):void
		{
			if (!usable)
			{
				return;
			}
			avatar.playTo(status, dir, apc, onEffectFrame, onCompleteFrame, resetFrame);
		}
		/**一组动作*/
		private var _actions:Array=[];
		/**关键帧回调*/
		private var _actionEffect:Function;
		/**动作索引*/
		private var _actionIndex:int;

		/**
		 * 播放多个动作
		 * @param actions
		 * @param onEffectFrame
		 *
		 */
		public function playActions(actions:Array, onEffectFrame:Function=null, onComplete:Function=null):void
		{
			if (!actions)
			{
				return;
			}
			if (!actions.length)
			{
				return;
			}
			if (actions.length == 1)
			{
				playTo(actions[0], -1, null, onEffectFrame);
			}
			else
			{
				_actions=actions;
				_actionEffect=onEffectFrame;
				_actionIndex=0;
				playAction();
			}
		}

		/**
		 * 播放动作
		 *
		 */
		private function playAction():void
		{
			if (_actions)
			{
				var currentAction:int=_actions[_actionIndex];
				_actionIndex++;
				if (_actionIndex >= _actions.length)
				{
					_actions=null;
				}
				App.timer.doFrameOnce(1, playTo, [currentAction, -1, null, onEffectFrame, playAction]);
			}
			else
			{
				_actionEffect=null;
			}
		}

		/**
		 * 播放关键帧
		 *
		 */
		private function onEffectFrame():void
		{
			if (_actionEffect != null)
			{
				_actionEffect();
			}
		}

		/*************************************************************************************************************************************************
		 * 场景移动
		 *************************************************************************************************************************************************/
		public function get status():int
		{
			return _avatar.getStatus();
		}

		/**
		 * 面向像素点
		 * @param p
		 * @param isNow 立刻面向
		 */
		public function faceToPixcel(targetPixcel:Point, isNow:Boolean=false):void
		{
			if (!wpos.pixel.equals(targetPixcel))
			{
				this.faceToTile(scene.mapConfig.Pixel2Tile(targetPixcel), isNow);
			}
		}

		/**
		 * 面向网格
		 * @param p
		 * @param isNow 立刻面向
		 */
		public function faceToTile(targetTile:Point, isNow:Boolean=false):void
		{
			if (!wpos.tile.equals(targetTile))
			{
				_avatar.dir=Direction.getDirection(wpos.tile, targetTile);
			}
		}

		/**
		 *面向角色
		 * @param sc
		 * @param isNow 立刻面向
		 *
		 */
		public function faceToSC(sc:SceneCharacter, isNow:Boolean=false):void
		{
			this.faceToTile(sc.wpos.tile, isNow);
		}

		/**
		 * 身体部件
		 */
		private var clothPart:AvatarPart;
		/////////////////////////////////////////////////////////
		/////////////////////////////////////////////////////////
		///////////////////////跳跃//////////////////////////
		private var _isJumpping:Boolean=false;

		/**是否跳跃*/
		public function get isJumpping():Boolean
		{
			return _isJumpping;
		}

		/**是否连跳*/
		private var isJumpAgain:Boolean=false;
		/**当前跳跃偏移*/
		private var _jumpOffset:Number=0;
		/***跳跃路径是否包含障碍*/
		public var hasBlock:Boolean;
		/**跳跃完毕回调*/
		private var jumpComplete:Function;
		private static const OFFSETCONST:int=-140;
		private static const OFFSETMOST:int=-220;
		/***高度*/
		private var offset:int=OFFSETCONST;
		private var _upObj:Object={y: 0};
		private var _downObj:Object={y: offset};
		private static const PIXEL_SPEED:Number=0.002;
		private static const HALF_PIXEL_SPEED:Number=0.001;
		private static const MONST_DURATION:Number=0.4;

		public function get jumpOffset():int
		{
			return _jumpOffset;
		}

		/**
		 * 开始跳跃
		 * @param hasBlock
		 *
		 */
		private function jumpBegin(hasBlock:Boolean):void
		{
			_jumpOffset=0;
			_isJumpping=true;
			_avatar.hideAvatarPart(AvatarPartType.WEAPON);
			_avatar.hideAvatarPart(AvatarPartType.WING);
			_avatar.hideAvatarPart(AvatarPartType.BOW);
			if (jumpType)
			{
				if (hasBlock)
				{
					_avatar.hideAvatarPart(AvatarPartType.MOUNT);
				}
				clothPart=avatar.getAvatarItem(AvatarPartType.CLOTH);
			}
		}

		/**
		 * 跳跃中
		 * @param offset 偏移
		 * @param hasBlock 是否有障碍
		 *
		 */
		public function jumpProgress(offset:Number, hasBlock:Boolean):void
		{
			_jumpOffset=offset;
			if (headLayer)
			{
				headLayer.y=(-headOffset + offset);
			}
			if (jumpType)
			{
				if (clothPart)
				{
					clothPart.updateOffset(offset);
				}
			}
			else
			{
				avatar.y=offset;
			}
		}

		/**
		 * 跳跃结束
		 *
		 */
		private function jumpEnd():void
		{
			jumpScale=1;
			offset=OFFSETCONST;
			_upObj.y=0;
			_downObj.y=offset;
			_jumpOffset=0;
			_isJumpping=false;
			isJumpAgain=false;
			updateHeadOffset();
			clothPart && clothPart.updateOffset(0);
			if (_avatar)
			{
				_avatar.y=0;
				_avatar.showAvatarPart(AvatarPartType.WEAPON);
				_avatar.showAvatarPart(AvatarPartType.WING);
				_avatar.showAvatarPart(AvatarPartType.BOW);
				_avatar.playTo(Status.STAND);
				if (jumpType)
				{
					_avatar.showAvatarPart(AvatarPartType.MOUNT);
				}
			}
			clothPart=null;
			if (jumpComplete != null)
			{
				jumpComplete();
				jumpComplete=null;
			}
		}

		/**
		 *  跳跃
		 * @param action 跳跃动作
		 * @param targetPoint 跳跃目标点
		 * @param jumpComplete 跳跃动作完毕
		 * @param isLeaveShadow 是否留下残影
		 *
		 */
		public function jump(action:int, targetPoint:Point, jumpComplete:Function=null, isLeaveShadow:Boolean=false):void
		{
			if (usable)
			{
				this.jumpComplete=jumpComplete;
				faceToPixcel(targetPoint, false);
				playTo(action);
				if (_isJumpping) //连跳
				{
					isJumpAgain=true;
					Juggler.instance.removeTweens(_downObj);
					Juggler.instance.removeTweens(_upObj);
					Juggler.instance.removeTweens(wpos);
					_upObj.y=_jumpOffset; //第二次上升起始高度
					offset=OFFSETCONST + _jumpOffset; //第二次上升终点高度
					if (offset < OFFSETMOST) //最大上升高度
					{
						offset=OFFSETMOST;
					}
					_downObj.y=offset; //第二次下降其实高度
					onStartJump(targetPoint);
				}
				else
				{
					onStartJump(targetPoint);
				}
			}
		}
		private var duartion:Number=0;
		private var half:Number=0;
		public var jumpScale:Number=1;

		/**
		 * 开始跳跃
		 * @param effect
		 *
		 */
		private function onStartJump(targetPoint:Point):void
		{
			jumpBegin(hasBlock);
			var distance:Number=Point.distance(wpos.pixel, targetPoint); //逻辑坐标距离
			if (distance < 300)
			{
				half=MONST_DURATION;
				duartion=MONST_DURATION * 2;
			}
			else
			{
				half=HALF_PIXEL_SPEED * distance;
				duartion=duartion=PIXEL_SPEED * distance;
			}
			half*=jumpScale;
			duartion*=jumpScale;
			var tween:Tween=Juggler.instance.tween(_upObj, half, {y: offset}) as Tween;
			tween.onUpdate=upChange;
			tween.onComplete=upComplete;
			tween.transition=Transitions.EASE_OUT;
			Juggler.instance.tween(this, duartion, {x: targetPoint.x, y: targetPoint.y});
		}

		/**
		 * 向上完毕
		 * @param gt
		 *
		 */
		private function upComplete():void
		{
			var tween:Tween=Juggler.instance.tween(_downObj, half, {y: 0}) as Tween;
			tween.onUpdate=downChange;
			tween.onComplete=downComplete;
			tween.transition=Transitions.EASE_IN;
		}

		/**
		 *向上改变
		 * @param gt
		 *
		 */
		private function upChange():void
		{
			jumpProgress(_upObj.y, false);
		}

		/**
		 * 下降改变
		 * @param ggt
		 *
		 */
		private function downChange():void
		{
			jumpProgress(_downObj.y, false);
		}

		/**
		 *下降完毕
		 * @param gt
		 *
		 */
		private function downComplete():void
		{
			jumpEnd();
			playTo(Status.STAND);
		}
		///////////////////////warnshape///////////////
		/**
		 * 显示提示圈
		 * @param riadus
		 *
		 */
		public function showWarnShape(riadus:int=150):void
		{
		}

		/**
		 * 隐藏提示圈
		 *
		 */
		public function hideWarnShape():void
		{
		}
		private var _walkSpeed:int=135;

		public function get walkSpeed():int
		{
			return _walkSpeed;
		}

		public function set walkSpeed(value:int):void
		{
			_walkSpeed=value;
		}

		public var walk_lastTime:int=0;
		private var _walkPath:Array=null;

		public function get walkPath():Array
		{
			return _walkPath;
		}
		public var walk_standDis:int=0;
		private var _walk_pathCutter:PathCutter;
		public var walk_targetP:Point=null;
		public var walk_fixP:Point=null;
		//
		public var onWalkThrough:Function;
		public var onWalkArrived:Function;
		public var onWalkUnable:Function;

		/**
		 * 是否目标点未变化
		 * @param targetP
		 * @param standDis
		 * @param speed
		 * @return
		 */
		public function isChanged(targetP:Point, standDis:int, speed:Number):Boolean
		{
			if (!this._walkPath || !this._walkPath.length || this.walk_targetP == null)
			{
				return true;
			}
			if (walk_standDis != standDis)
			{
				return true;
			}
			if (speed >= 0 && speed != _walkSpeed)
			{
				return true;
			}
			var isSamePlace:Boolean=(this.walk_targetP.x >> 0) != (targetP.x >> 0) || (this.walk_targetP.y >> 0) != (targetP.y >> 0);
			return isSamePlace;
		}

		/**
		 *一点是否在于角色指定距离内
		 * @param position
		 * @param distance
		 * @return
		 *
		 */
		public function inDistance(position:Point, distance:int):Boolean
		{
			return Point.distance(wpos.tile, position) <= distance;
		}

		////////////////////////////////////////////////////////////////////////////////////////////////////////
		/**
		 * 添加Avatar部件
		 * @param apd
		 */
		public function addAvatarPart(id:int, type:int):void
		{
			_avatar.addAvatarItem(id, type);
		}

		public function addEffect(ianimation:IAnimation, isBottom:Boolean=false):void
		{
			addEleEffect(ianimation, isBottom);
		}

		/**
		 * 根据类型移除部件
		 * @param type
		 */
		public function removeAvatarPartByType(type:int):void
		{
			_avatar.removeAvatarItem(type);
		}

		/**
		 * 部件驱动
		 * @param nowTime
		 * @param diff
		 *
		 */
		public function runAvatar(nowTime:int, diff:int):void
		{
			_avatar.run(nowTime, diff);
			if (_headFace)
			{
				this._headFace.run(nowTime, diff);
			}
		}
		///////////////////////////////////////////////////////////////////////////////
		/**跟随着*/
		public var follower:SceneCharacter=null;
		/**所属者*/
		public var master:SceneCharacter=null;
		/**是否留下阴影*/
		private var _leaveShow:Boolean=false;
		/**阴影存在时间*/
		private var _shadowDuration:Number;

		public function startShowShadow(duration:Number):void
		{
			_leaveShow=true;
			_shadowDuration=duration;
		}

		public function stopShowShadow():void
		{
			_leaveShow=false;
		}

		/**
		 * 留下残影
		 * @param e
		 *
		 */
		private function leaveshow():void
		{
			if (this.usable)
			{
				_avatar.leaveShadow(0, _shadowDuration);
			}
		}

		///////////////////////移动/////////
		public function runWalk(currentTime:int):void
		{
			var need_f:Number;
			var lastTime:Number;
			var currentStatus:int=_avatar.getStatus();
			//如果角色死亡 停止移动
			if (currentStatus == Status.DEAD)
			{
				clearWalk();
				return;
			}
			//没有路径点了
			if (!_walkPath)
			{
				if (currentStatus == Status.WALK)
				{
					playTo(Status.STAND);
				}
				return;
			}
			//var $speed:Number=MapConfig.TILE_WIDTH / (walkData.walk_speed * 0.001);
			//var dis_per_f:Number=$speed /( MapConfig.TILE_WIDTH * Config.GAME_FPS); //每帧x方向移动距离
			//推导得出
			var dis_per_f:Number=1000 / (_walkSpeed * Config.GAME_FPS); //每帧x方向移动距离
			var nowTime:int=currentTime; //当前时间
			if (lastTime != nowTime)
			{
				lastTime=walk_lastTime; //上次移动时间
				walk_lastTime=nowTime;
				if (lastTime != 0)
				{
					need_f=(nowTime - lastTime) * 0.001 * Config.GAME_FPS; //计算已经经过了多少帧
					dis_per_f=dis_per_f * need_f;
				}
			}
			stepDistance(dis_per_f);
			setPostion(_tx, _ty);
			if (currentStatus != Status.WALK)
			{
				playTo(Status.WALK);
			}
			var throughTile:Point;
			for each (throughTile in _throughTileArr)
			{
				if (isMainPlayer)
				{
					_walk_pathCutter.walkNext(throughTile.x, throughTile.y);
					scene.signal.walk.dispatch(SceneAction_Walk.THROUGH, throughTile);
				}
				if (onWalkThrough != null)
				{
					onWalkThrough(throughTile);
				}
			}
			if (!_walkPath.length)
			{
				if (isMainPlayer)
				{
					scene.signal.walk.dispatch(SceneAction_Walk.ARRIVED, throughTile);
				}
				clearWalk();
			}
		}
		/**当前帧移动后的位置*/
		private var _tx:Number=0;
		private var _ty:Number=0;
		/**当前行走经过的点*/
		private var _throughTileArr:Array=[];

		/**
		 * 步长计算
		 * @param char
		 * @param _d_per_f
		 * @return
		 */
		private function stepDistance(ssf:Number):void
		{
			var targetTile:Point;
			var throughTile:Point;
			var dis:Number;
			_tx=wpos.tileX;
			_ty=wpos.tileY;
			_throughTileArr.length=0;
			var pathArr:Array=_walkPath;
			while (true)
			{
				targetTile=pathArr[0]; //(walkData.walk_fixP == null) ? SceneUtil.Tile2Pixel(pathArr[0]) : walkData.walk_fixP;
				faceToTile(targetTile);
				dis=Geom.getDistance2(_tx, _ty, targetTile.x, targetTile.y);
				if (dis > ssf) //不足以到达
				{
					_tx+=(targetTile.x - _tx) * ssf / dis;
					_ty+=(targetTile.y - _ty) * ssf / dis;
					return;
				}
				if (dis == ssf) //刚好到达目标点
				{
					_tx=targetTile.x;
					_ty=targetTile.y;
					return;
				}
				if (walk_fixP == null)
				{
					throughTile=pathArr.shift();
					_throughTileArr.push(throughTile);
				}
				else
				{
					walk_fixP=null;
				}
				_tx=targetTile.x;
				_ty=targetTile.y;
				ssf-=dis;
				if (pathArr.length == 0)
				{
					return;
				}
			}
		}
		/**
		 *最少路径长度
		 */
		private static const LEAST_PATH:int=2;

		/**
		 * 停止移动
		 * @param char
		 * @param stand
		 */
		public function stopWalk(stand:Boolean=true):void
		{
			clearWalk();
			if (stand)
			{
				playTo(Status.STAND);
			}
		}

		/**
		 * 修正角色移动
		 * @param char
		 */
		public function reviseMove(tx:int, ty:int):void
		{
			setPostion(tx, ty);
			if (isMainPlayer)
			{
				if (walk_targetP && status == Status.WALK)
				{
					walk(walk_targetP, -1, 0);
				}
			}
			else
			{
				clearWalk();
			}
		}

		/**
		 * 清理移动数据
		 */
		public function clearWalk():void
		{
			if (onWalkArrived != null)
			{
				onWalkArrived(this);
			}
			this._walkPath=null;
			this.walk_targetP=null;
			this.walk_fixP=null;
			this.walk_lastTime=0;
			this.walk_standDis=0;
			if (this._walk_pathCutter)
			{
				this._walk_pathCutter.clear();
			}
			onWalkThrough=null;
			onWalkArrived=null;
			onWalkUnable=null;
		}

		/**
		 * 行走到指定地点
		 * @param walker 移动主角
		 * @param targetTile 目的网格
		 * @param speed 速度
		 * @param standDis 距离阙值
		 */
		public function walk(targetTile:Point, speed:Number=-1, standDis:int=0, onWalkArrived:Function=null, isShowTag:Boolean=false):void
		{
			if (!targetTile)
			{
				return;
			}
			//判断是否在阙值范围内
			var isInCircle:Boolean=(Point.distance(wpos.tile, targetTile) <= standDis);
			//判断是否在原地
			var isHere:Boolean=((wpos.tileX >> 0) == (targetTile.x >> 0) && (wpos.tileY >> 0) == (targetTile.y >> 0));
			if (isInCircle || isHere)
			{
				if (isInCircle)
					faceToPixcel(targetTile);
				if (isMainPlayer)
				{
					scene.signal.walk.dispatch(SceneAction_Walk.ARRIVED, targetTile);
				}
				if (onWalkArrived != null)
					onWalkArrived(targetTile);
				return;
			}
			//判断目标点是否合法
			if (scene.mapConfig.isBlock(targetTile.x, targetTile.y))
			{
				if (isMainPlayer)
				{
					scene.showMouseChar(targetTile, true);
					scene.signal.walk.dispatch(SceneAction_Walk.UNABLE, targetTile);
				}
				if (onWalkUnable != null)
					onWalkUnable(targetTile);
				return;
			}
			//路径重复
			if (!isChanged(targetTile, standDis, speed))
			{
				trace("路径重复，忽略");
				return;
			}
			var path:Array=TAstar.find(scene.mapConfig, wpos.tileX, wpos.tileY, targetTile.x, targetTile.y);
			if (path == null || path.length < LEAST_PATH) //未能搜索到有效路径
			{
				if (isMainPlayer)
				{
					scene.showMouseChar(targetTile, true);
					scene.signal.walk.dispatch(SceneAction_Walk.UNABLE, targetTile);
				}
				if (onWalkUnable != null)
				{
					onWalkUnable(targetTile);
				}
				return;
			}
			if (standDis != 0)
			{
				if (standDis > 0)
				{ //站立距离截取
					var len:int=path.length;
					var cutLen:int=Math.min(standDis, len - LEAST_PATH);
					if (cutLen > 0)
					{
						path.splice(len - cutLen, cutLen);
					}
				}
			}
			walk0(path, null, speed, standDis, onWalkArrived, isShowTag);
		}

		/**
		 * 移动
		 * @param walker
		 * @param path
		 * @param targetTile
		 * @param speed
		 * @param standDis
		 */
		public function walk0(path:Array, targetTile:Point=null, speed:Number=-1, standDis:int=0, onWalkArrived:Function=null, isShowTag:Boolean=false):void
		{
			if (path.length < LEAST_PATH) //一段路径至少包含起点和终点
			{
				return;
			}
			_hitDistance=0; //移动的时候把击退累计清除，因为服务器会矫正位置
			if (isMainPlayer) //主角发包处理
			{
				if (_walk_pathCutter == null)
				{
					_walk_pathCutter=new PathCutter(this);
				}
				_walk_pathCutter.cutMovePath(path); //路径分段
				_walk_pathCutter.walkNext(-1, -1);
			}
			if (speed >= 0)
			{
				_walkSpeed=speed;
			}
			var targetP:Point=null;
			if (targetTile != null)
			{
				targetP=targetTile;
				walk_targetP=targetTile;
			}
			else
			{
				targetP=path[path.length - 1].clone();
				walk_targetP=targetP;
			}
			this.onWalkArrived=onWalkArrived;
			walk_standDis=standDis;
			var currentP:Point=path.shift();
			//修正坐标  这里有待改善。。。。
			if (Math.abs(wpos.tileX - currentP.x) > 1 || Math.abs(wpos.tileY - currentP.y) > 1)
			{
				setPostion(currentP.x, currentP.y);
			}
			_walkPath=path;
			if (!targetP)
			{
				return;
			}
			//主角发送移动开始事件
			if (isMainPlayer)
			{
				scene.showMouseChar(targetP);
			}
		}

		public function set deadLock(value:Boolean):void
		{
			_dead_lock=value;
		}

		public function get deadLock():Boolean
		{
			return _dead_lock;
		}

		public function set hitLock(value:Boolean):void
		{
			_hit_lock=value;
		}

		public function get hitLock():Boolean
		{
			return _hit_lock;
		}

		public function get wpos():WorldPostion
		{
			return _wpos;
		}

		/**
		 * 设置滤镜
		 * @param type
		 *
		 */
		public function setAvatarFilter(type:int):void
		{
			switch (type)
			{
				case FilterEnum.FILTERWHITE:
					_avatar.setFilter(FilterEnum.whiteFilter);
					break;
				case FilterEnum.FILTERRED:
					_avatar.setFilter(FilterEnum.redFilter);
					break;
				case FilterEnum.FILTERGREEN:
					_avatar.setFilter(FilterEnum.greenFilter);
					break;
				case FilterEnum.FILTERGOLDEN:
					_avatar.setFilter(FilterEnum.goldenFilter);
					break;
				case FilterEnum.FILTERBLUE:
					_avatar.setFilter(FilterEnum.blueFilter);
					break;
				case FilterEnum.FILTERNONE:
					_avatar.setFilter(null);
					break;
			}
		}

		/**位置坐标*/
		protected var _wpos:WorldPostion;

		private var _id:uint;

		/**对象唯一标识*/
		public function get id():uint
		{
			return _id;
		}

		/**
		 * @private
		 */
		public function set id(value:uint):void
		{
			_id=value;
		}

		/**对象头顶层*/
		protected var _headFace:HeadFace;
		/**对象容器*/
		protected var _body:Sprite;
		/**是否主玩家*/
		protected var _isMainChar:Boolean;
		/**对象名字（headface）*/
		protected var _fullName:String="";
		/**掉落距离主角的距离*/
		public var distance:int;
		/**对象是否可用（是否已释放）*/
		protected var _usable:Boolean=true;
		/**对象是否被加入渲染*/
		public var render:Boolean=false;
		private var _data:Object;

		/**对象数据（组合方式）*/
		public function get data():Object
		{
			return _data;
		}

		/**
		 * @private
		 */
		public function set data(value:Object):void
		{
			_data=value;
		}

		/**对象类型*/
		public var type:int;
		/**额外控制透明度的属性*/
		public var opacity:Number=1;

		/**场景*/
		private var _scene:IMagicScene=null;

		/**场景*/
		public function get scene():IMagicScene
		{
			return _scene;
		}


		private var _lock:Boolean;

		public function get lock():Boolean
		{
			return _lock;
		}

		/**
		 * 设置对象渲染锁定
		 * @param value
		 *
		 */
		public function set lock(value:Boolean):void
		{
			_lock=value;
		}

		/**对象名字（headface）*/
		public function get fullName():String
		{
			return _fullName;
		}

		/**
		 * @private
		 */
		public function set fullName(value:String):void
		{
			_fullName=value;
		}

		/**排序偏移*/
		protected var _sortOffset:int;

		/**排序评分 */
		public function get sortScore():uint
		{
			return y + _sortOffset + (isMainPlayer ? 1 : 0);
		}


		/**
		 * 是英雄？
		 * @return
		 */
		public function get isMainPlayer():Boolean
		{
			return _isMainChar;
		}

		/**
		 * 是英雄？
		 * @return
		 */
		public function set isMainPlayer(value:Boolean):void
		{
			_isMainChar=value;
		}

		public function get isMouseHit():Boolean
		{
			if (this.isDead) //死亡后不可选中
			{
				return false;
			}
			return this.visible && _avatar.isMouseHit();
		}
		private var _visible:Boolean;
		private var _scaleX:Number;
		private var _scaleY:Number;

		public function set scaleX(value:Number):void
		{
			_scaleX=value;
			_body.scaleX=value;
		}

		public function get scaleX():Number
		{
			return _scaleX;
		}

		public function get scaleY():Number
		{
			return _scaleY;
		}

		public function set scaleY(value:Number):void
		{
			_scaleY=value;
			_body.scaleY=value;
		}

		public function set visible(value:Boolean):void
		{
			_visible=value;
			_body.visible=value;
		}

		public function get visible():Boolean
		{
			return _visible;
		}

		public function get parent():DisplayObjectContainer
		{
			return _body.parent;
		}

		protected var _isMouseOn:Boolean=false; //是否获取鼠标焦点

		/**
		 *获取/设置鼠标焦点事件
		 * @return
		 */
		public function get isMouseOn():Boolean
		{
			return _isMouseOn;
		}

		/**
		 *
		 * @param value
		 */
		public function set isMouseOn(value:Boolean):void
		{
			if (_isMouseOn != value)
			{
				_isMouseOn=value;
			}
		}

		/**
		 *
		 * @return
		 *
		 */
		public function get body():Sprite
		{
			return _body;
		}

		public function get headLayer():HeadFace
		{
			return _headFace;
		}

		public function get usable():Boolean
		{
			return _usable;
		}

		//////////////////////////////////////////////////////////////////////////////////
		public function get nickName():String
		{
			return _headFace.nickName;
		}

		public function get nickNameColor():uint
		{
			return _headFace.nickNameColor;
		}

		public function get customTitle():String
		{
			return _headFace.customTitle;
		}

		public function setCustomTitle(value:String):void
		{
			_headFace.setCustomTitle(value);
		}

		/**
		 * 设置血条值
		 * @param minValue
		 * @param maxValue
		 *
		 */
		public function setBar(minValue:int, maxValue:int):void
		{
			_headFace.setBar(minValue, maxValue);
		}

		public function get leftIco():DisplayObject
		{
			return _headFace.leftIco;
		}

		/**
		 * 设置左边图标
		 * @param value
		 *
		 */
		public function setLeftIco(value:DisplayObject):void
		{
			_headFace.setLeftIco(value);
		}

		public function get topIco():DisplayObject
		{
			return _headFace.topIco;
		}

		/**
		 * 设置头顶图标
		 * @param value
		 *
		 */
		public function setTopIco(value:DisplayObject):void
		{
			_headFace.setTopIco(value);
		}

		/**
		 * 获取/设置像素X坐标
		 * @return
		 */
		public function get x():Number
		{
			return wpos.pixelX;
		}

		public function set x(value:Number):void
		{
			_body.x=value;
			_wpos.pixelX=value;
		}

		/**
		 * 设置逻辑坐标
		 * @param tilex
		 * @param tiley
		 *
		 */
		public function setPostion(tilex:Number, tiley:Number):void
		{
			x=tilex * scene.tileWidth;
			y=tiley * scene.tileHeight;
		}

		/**
		 * 获取/设置像素Y坐标
		 * @return
		 */
		public function get y():Number
		{
			return wpos.pixelY;
		}

		public function set y(value:Number):void
		{
			wpos.pixelY=value;
			_body.y=value;
		}
		/**中心点x*/
		public var center_x:int=375;
		/**中心点y*/
		public var center_y:int=0;
		/**身体受击点*/
		private var _body_offset:int=55;

		/**
		 * 身体受击偏移x
		 */
		public function get bodyOffset():int
		{
			return _body_offset;
		}

		/**
		 * 身体受击偏移
		 * @private
		 */
		public function set bodyOffset(value:int):void
		{
			_body_offset=center_y - value;
		}
		/**
		 * 头顶偏移
		 */
		private var _head_offset:int=125;

		/**
		 * 头顶偏移
		 */
		public function get headOffset():int
		{
			return _head_offset;
		}

		/**
		 * 头顶偏移
		 * @private
		 */
		public function set headOffset(value:int):void
		{
			value=center_y - value;
			_head_offset=value > 0 ? value : 125; //默认偏移
		}
		/**
		 * 光效列表
		 * @default
		 */
		private var _effects:Dictionary=new Dictionary(true);

		/**
		 *添加状态表现光效
		 * @param effect 光效
		 * @param isLand是否地效
		 * @param isFoot是否添加到脚上
		 * @param isBody是否加到身体重心
		 * @param isHead是否加到头部
		 */
		public function addEleEffect(iani:IAnimation, isBottom:Boolean=false):void
		{
			if (!usable)
			{
				Animation.free(iani as Animation);
				iani=null;
				return;
			}
			var ani:Animation=iani as Animation;
			if (!ani || !ani.config)
			{
				return;
			}
			var $ani:Animation=_effects[iani.id];
			if ($ani)
			{
				removeEffect($ani);
			}
			var place:int=ani.config.body_place;
			if (place & 2)
			{ //身体位置
				ani.y=-bodyOffset;
			}
			else if (place & 4)
			{ //头顶位置
				ani.y=-headOffset;
			}
			ani.onDispose=onEffectDispose;
			_effects[ani.id]=ani;
			if (isBottom || (ani.config.around_place & 2))
			{
				this._body.addChildAt(ani.body, 0);
			}
			else
			{
				this._body.addChild(ani.body);
			}
		}

		/**
		 * 移除特效
		 * @param effect 光效
		 */
		public function removeEffect(ani:*):void
		{
			if (!ani)
			{
				return;
			}
			if (!usable)
			{
				return;
			}
			var _ani:Animation=((ani as Animation) || _effects[ani]);
			if (_ani)
			{
				Animation.free(_ani);
				_effects[id]=null;
				ani=null;
				delete _effects[id];
			}
		}

		/**
		 * 特效移除时回调
		 * @param ani
		 *
		 */
		private function onEffectDispose(ani:Animation):void
		{
			if (!usable)
			{
				return;
			}
			_effects[ani.id]=null;
			delete _effects[ani.id];
		}

		/**
		 *
		 *获得特效
		 */
		public function getEffect(id:String):Animation
		{
			return _effects[id];
		}


		public function get effects():Object
		{
			return _effects;
		}

		/**
		 *移除角色身上所有光效
		 *
		 */
		public function removeAllEffect():void
		{
			var ani:Animation=null;
			for each (ani in _effects)
			{
				removeEffect(ani);
			}
		}



		/**
		 * 是否已死亡
		 * @return
		 *
		 */
		public function get isDead():Boolean
		{
			return _avatar && (status == Status.DEAD);
		}


		public function get walkPathCutter():PathCutter
		{
			return _walk_pathCutter;
		}

		public function addAniLogo(group:String, id:String, isLeft:Boolean=false, sortId:int=0):void
		{

		}

		public function addImageLogo(group:String, id:String, isLeft:Boolean=false, isBody:Boolean=false, sortId:int=0, isNameLeft:Boolean=false, offsetX:int=0, offsetY:int=0, isBarLeft:Boolean=false):void
		{

		}

		public function deleteLogo(group:String, dispose:Boolean=true):Boolean
		{
			return false;
		}

		public function updateNameText(gropId:String, newName:String, sortId:int=0, newColor:uint=0xff0000):void
		{
			_headFace.setNickName(newName, newColor);
		}

		public function set iShowNum(value:Boolean):void
		{
			// TODO Auto Generated method stub
		}

		public function set isShowLogos(value:Boolean):void
		{
			_headFace.setBarVisible(value);
			showBar(value);
		}

		public function set isShowName(value:Boolean):void
		{
			_headFace.setNickNameVisible(value);
		}

		public function showBar(value:Boolean, isJingying:Boolean=false):void
		{
			headLayer.setBarType();
		}

		public function deleteAllImageLogo(isHead:Boolean=true, isLeft:Boolean=false, isBody:Boolean=false, isNameLeft:Boolean=false):void
		{

		}

		public function setBarSkin(barSkin:String):void
		{
			if (!headLayer)
			{
				return;
			}
			if (!headLayer.bar)
			{
				showBar(true);
			}
			headLayer.bar.skin=barSkin;
		}

	}
}
