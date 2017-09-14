package tempest.engine.graphics.avatar
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import common.enum.AvatarEnum;
	
	import starling.animation.Juggler;
	import starling.animation.Tween;
	
	import tempest.core.IAvatar;
	import tempest.core.IDisposable;
	import tempest.core.IPlayAction;
	import tempest.core.IRunable;
	import tempest.engine.SceneCharacter;
	import tempest.engine.graphics.loader.LoaderUtil;
	import tempest.enum.AvatarPartType;
	import tempest.enum.Status;
	import tempest.pool.ObjectPools;
	import tempest.template.Action;
	import tempest.template.ActionConfig;
	import tempest.template.OffsetInfo;

	public class Avatar extends Sprite implements IDisposable, IRunable, IPlayAction, IAvatar
	{
		/***方向*/
		private var _dir:int=0;
		/***动作状态*/
		private var _status:int=0;
		/***关键帧回调*/
		private var _onEffectFrame:Function=null;
		/***播放关键帧*/
		public var _playEffectFrame:Boolean=false;
		/***播放完毕回调*/
		private var _onCompleteFrame:Function=null;
		/**动作播放完毕*/
		public var _playCompleteFrame:Boolean=false;
		private var _completeAction:int;
		/***是否可用*/
		private var _usable:Boolean=true;
		/***动作播放配置*/
		protected var _apc:ActionConfig=null;
		/***角色*/
		public var sc:SceneCharacter=null;
		/***部件*/
		public var avatarParts:Array=null;
		/***当前帧*/
		public var currentFrame:int=0;
		/***当前动作信息*/
		public var actionFrame:Action=null;
		/***动作集合*/
		public var actions:Object=null;
		/***是否显示阴影*/
		private var _useShadow:Boolean;
		/***更新*/
		public var updateNow:Boolean=false;
		/**是否可使用默认资源*/
		public var useDefaultAsset:Boolean=true;
		/**是否加载完毕创建全部帧*/
		public var createAll:Boolean=false;
		/**动作播放速度缩放*/
		private var _intervalScale:Number=1;

		/**帧频缩放*/
		public function set intervalScale(value:Number):void
		{
			_intervalScale=value;
		}
		private var _isShowShadow:Boolean=true;

		/**显示脚底阴影*/
		public function set isShowShadow(value:Boolean):void
		{
			_isShowShadow=value;
		}

		public function get isShowShadow():Boolean
		{
			return _isShowShadow;
		}
		/**模型碰撞矩形*/
		private var _rect:Rectangle;

		public function Avatar(char:SceneCharacter, useDefaultAsset:Boolean=true, createAll:Boolean=false)
		{
			super();
			this.mouseChildren=this.mouseEnabled=false;
			avatarParts=[];
			actions={}
			this.sc=char;
			this.useDefaultAsset=useDefaultAsset;
			this.createAll=createAll;
			status=Status.STAND;
		}

		/**
		 *添加动作信息
		 * @param status
		 * @param action
		 *
		 */
		public function addAction(action:Action):void
		{
			var status:int=action.status;
			if (actions[status])
			{
				actions[status]=null;
				delete actions[status];
			}
			actions[status]=action;
			if (this.actionFrame.status == status)
			{ //覆盖默认动作
				this.actionFrame=action;
			}
		}
		private var _isOnMount:Boolean=false;

		public function get isOnMount():Boolean
		{
			return _isOnMount;
		}

		public function set isOnMount(value:Boolean):void
		{
			_isOnMount=value;
		}

		public function getStatus():int
		{
			return _status;
		}

		public function get dir():int
		{
			return _dir;
		}

		/**
		 * 设置方向
		 * @param value
		 *
		 */
		public function set dir(value:int):void
		{
			value=validateDir(value);
			if (_dir != value)
			{
				_dir=value;
				if (sc)
				{
					sc.wpos.toward=value;
				}
				updateNow=true;
			}
		}

		/**
		 * 角色碰撞矩形
		 * @return
		 *
		 */
		public function get rect():Rectangle
		{
			if (!_rect)
			{
				_rect=new Rectangle(0, 0, AvatarEnum.RECTW, AvatarEnum.RECTH);
			}
			_rect.x=sc.wpos.pixelX - (AvatarEnum.RECTW >> 1);
			_rect.y=sc.wpos.pixelY - AvatarEnum.RECTH;
			return _rect;
		}

		/**
		 *检测方向
		 * @param value
		 * @return
		 *
		 */
		public function validateDir(value:int):int
		{
			if (value < 0)
			{
				value=value % 8 + 8;
			}
			else if (value > 7)
			{
				value%=8;
			}
			return value;
		}

		/**
		 *是否鼠标碰撞
		 * @return
		 *
		 */
		public function isMouseHit():Boolean
		{
			if (!this.visible)
				return false;
			var len:int=avatarParts.length;
			for (var i:int=0; i < len; i++)
			{
				if (avatarParts[i].isMouseHit())
					return true;
			}
			return false;
		}
		/**武器刀光是否可用*/
		public var wepaonEffectEnabled:Boolean=false;

		/**
		 * 播放动作
		 * @param status 动作
		 * @param dir 方向
		 * @param apc 播放条件
		 * @param onEffectFrame 关键帧回调
		 * @param onCompleteFrame 动作播放完毕回调
		 *
		 */
		public function playTo(status:int=-1, dir:int=-1, apc:ActionConfig=null, onEffectFrame:Function=null, onCompleteFrame:Function=null, resetFrame:Boolean=false):void
		{
			if (!_usable)
			{
				return;
			}
			//关键帧
			if (this._onEffectFrame != null)
			{
				this._onEffectFrame();
				this._onEffectFrame=null;
			}
			this._onEffectFrame=onEffectFrame;
			//最后一帧
			if (this._onCompleteFrame != null)
			{
				this._onCompleteFrame();
				this._onCompleteFrame=null;
			}
			this._onCompleteFrame=onCompleteFrame;
			if (_onCompleteFrame)
			{
				_completeAction=status;
			}
			var $dir:int=dir;
			if (apc && apc.priority != 0 && apc.priority < _apc.priority)
			{ //当前播放的动作优先级更高
				if (onEffectFrame != null)
				{
					onEffectFrame();
				}
				if (onCompleteFrame != null)
				{
					onCompleteFrame();
				}
				return;
			}
			var change:Boolean=false;
			if (status != -1 && this._status != status)
			{
				this.status=status;
				change=true;
			}
			if (apc)
			{
				_apc=apc;
			}
			if ($dir != -1)
			{
				this.dir=$dir;
				change=true;
			}
			if (_apc.play_atbegin && currentFrame != 0)
			{
				this.currentFrame=0;
				change=true;
			}
			var endFrame:int=this.actionFrame.total - 1;
			if (_apc.show_end && currentFrame != endFrame)
			{
				currentFrame=endFrame;
				change=true;
			}
			///////////////重置帧////////////////
			if (change)
			{
				this._timeOffet=0;
				this.updateNow=true;
			}
		}
		/**累计时间*/
		private var _timeOffet:int;

		/**
		 *播放
		 */
		public function run(nowTime:int, diff:int):void
		{
			if (!_usable)
			{
				return;
			}
			//播放关键帧回调
			if (this._playEffectFrame)
			{
				this._playEffectFrame=false;
				if (this._onEffectFrame != null)
				{
					this._onEffectFrame();
					this._onEffectFrame=null;
				}
			}
			//播放最后一帧回调
			if (this._playCompleteFrame)
			{
				this._playCompleteFrame=false;
				if (this._onCompleteFrame != null)
				{
					this._onCompleteFrame();
					this._onCompleteFrame=null;
				}
			}
			_timeOffet+=diff;
			var interval:int=actionFrame.interval * _intervalScale;
			if (_timeOffet > interval)
			{
				while (_timeOffet >= interval)
				{
					_timeOffet-=(interval || _timeOffet);
					if (currentFrame >= actionFrame.total - 1)
					{
						if (actionFrame.status == _completeAction)
						{
							_completeAction=-1;
							_playCompleteFrame=true;
						}
						//播放一次动作完毕
						if (_apc.stay_atend && _apc.is_loop_once)
						{
							currentFrame=actionFrame.total - 1;
						}
						else
						{
							currentFrame=0;
							if (_apc.is_loop_once)
							{
								_timeOffet=0;
								this.status=Status.STAND;
								return;
							}
						}
					}
					else if (actionFrame.total > 1)
					{
						currentFrame++;
					}
					if (this.currentFrame == actionFrame.effect)
					{
						_playEffectFrame=true;
					}
					this.updateNow=true;
				}
			}
			update(diff);
		}

		/**
		 * 停止run
		 *
		 */
		public function onStopRun():void
		{
			removeAllItem();
			if (this.parent)
			{
				this.parent.removeChild(this);
			}
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

		/**
		 * 获取部件阴影
		 * @param display
		 * @return
		 *
		 */
		public function getCopyAvatar(rect:Rectangle, matrix:Matrix, filter:BitmapFilter):BitmapData
		{
			var bitmapData:BitmapData=null;
			if (!rect.isEmpty())
			{
				bitmapData=new BitmapData(rect.width, rect.height, true, 0xffffff);
				bitmapData.lock();
				bitmapData.draw(this, matrix);
				bitmapData.applyFilter(bitmapData, bitmapData.rect, AvatarPartType.ZERO_POINT, filter);
				bitmapData.unlock();
			}
			return bitmapData;
		}

		/**
		 *克隆角色影子
		 * @param verticalChange
		 *
		 */
		public function leaveShadow(verticalChange:int, duartion:Number):void
		{
			if (this.sc)
			{
				var rect:Rectangle=getRect(this);
				var bitmap:Bitmap=new Bitmap(this.getCopyAvatar(rect, new Matrix(1, 0, 0, 1, -rect.x, -rect.y), AvatarPartType.ALPHA_BLACK_BLURFILTERFILTER));
				bitmap.x=this.sc.x + rect.x;
				bitmap.y=-verticalChange + this.sc.y + rect.y;
//				this.sc.scene.bgEffectLayer.addChild(bitmap);
				var tween:Tween=Juggler.instance.tween(bitmap, duartion, {alpha: 0}) as Tween;
				tween.onCompleteArgs=[bitmap];
				tween.onComplete=onShadowEnd;
			}
		}

		private function onShadowEnd(target:Bitmap):void
		{
			if (target.parent)
			{
				target.parent.removeChild(target);
			}
			(target).bitmapData.dispose();
		}

		/**
		 *渲染更新
		 *
		 */
		public function update(diff:int):void
		{
			if (!this.visible || (this.sc && this.sc.visible == false))
			{
				return;
			}
			if (!this.updateNow)
				return;
			var len:int=avatarParts.length;
			var i:int=0;
			for (; i < len; i++)
			{
				avatarParts[i].update(diff);
			}
			updateNow=false;
		}

		/**
		 * 设置滤镜
		 * @param value
		 *
		 */
		public function setFilter(value:ColorMatrixFilter):void
		{
			var len:int=avatarParts.length;
			var i:int=0;
			for (; i < len; i++)
			{
				var apt:AvatarPart=avatarParts[i];
				if (apt && apt.type != AvatarPartType.EFFECT)
				{
					apt.bitmap.filters=value ? [value] : null;
				}
			}
		}

		/**
		 * 添加部件
		 * @param	apd
		 */
		public function addAvatarItem(id:int, type:int, path:String=null, sortRule:int=Array.NUMERIC):void
		{
			removeAvatarItem(type);
			var ap:AvatarPart=ObjectPools.malloc(AvatarPart, this, id, type, path) as AvatarPart;
			avatarParts.push(ap);
			sortDepth(sortRule);
			this.addChildAt(ap.bitmap, avatarParts.indexOf(ap));
			LoaderUtil.loadAvatarPart(path, ap.getLoadHanlder(path));
		}
		/**部件加载完毕*/
		public var loadedPartHandler:Function;

		/**
		 *部件排序
		 *
		 */
		public function sortDepth(sortRule:int):void
		{
			avatarParts.sortOn("depth", sortRule);
		}


		/**
		 *获取指定类型部件
		 * @param type
		 * @return
		 *
		 */
		public function getAvatarItem(type:int):*
		{
			var ap:AvatarPart;
			var iter:int;
			var len:int=avatarParts.length;
			for (; iter != len; iter++)
			{
				ap=avatarParts[iter];
				if (ap.type == type)
				{
					return ap;
				}
			}
			return null;
		}

		/**
		 *隐藏部件
		 * @param _arg1
		 *
		 */
		public function showAvatarPart(type:int):void
		{
			var ap:AvatarPart=getAvatarItem(type);
			if (ap)
			{
				ap.visible=true;
			}
		}

		/**
		 * 显示部件
		 * @param _arg1
		 *
		 */
		public function hideAvatarPart(type:int):void
		{
			var ap:AvatarPart=getAvatarItem(type);
			if (ap)
			{
				ap.visible=false;
			}
		}

		/**
		 *移除所有部件
		 *
		 */
		public function removeAllItem():void
		{
			while (avatarParts.length > 0)
			{
				var ap:AvatarPart=avatarParts[0];
				this.removeChild(ap.bitmap);
				var partPath:String=ap.path;
				LoaderUtil.removeAvatarLoadComplete(partPath, ap.getLoadHanlder(partPath));
				avatarParts.splice(0, 1);
				ObjectPools.free(ap);
			}
		}

		/**
		 * 通过类型移除部件
		 * @param	type
		 */
		public function removeAvatarItem(type:int):void
		{
			var len:int=avatarParts.length;
			var i:int=0
			for (; i < len; i++)
			{
				if (avatarParts[i].type == type)
				{
					var ap:AvatarPart=avatarParts[i];
					this.removeChild(ap.bitmap);
					LoaderUtil.removeAvatarLoadComplete(ap.path, ap.getLoadHanlder(ap.path));
					avatarParts.splice(i, 1);
					ObjectPools.free(ap);
					this.updateNow=true;
					break;
				}
			}
			updatePart();
		}

		/**
		 *更新部件位置
		 */
		public function updatePart():void
		{
			if (sc)
			{ //如果是骑乘状态,其他部件高度随坐骑高度变化
				var mountPart:AvatarPart=getAvatarItem(AvatarPartType.MOUNT);
				var bodyPart:AvatarPart=getAvatarItem(AvatarPartType.CLOTH);
				var temp_center_y:int;
				if (mountPart && mountPart.center_y > 0)
				{
					var bdh:int=(bodyPart && bodyPart.height != 0) ? bodyPart.height : 760
					temp_center_y=mountPart.center_y - (bodyPart ? ((mountPart.height - bdh) / 2) : 0); //坐骑外框可能与角色不通   
				}
				else if (bodyPart)
				{
					temp_center_y=(bodyPart.center_y != 0) ? bodyPart.center_y : 425;
				}
				if (temp_center_y > 0)
				{
					var ap:AvatarPart;
					var iter:int;
					var len:int=avatarParts.length;
					for (; iter != len; iter++)
					{
						ap=avatarParts[iter];
						//把其他的高度也重置
						if (ap.type != AvatarPartType.MOUNT)
						{
							ap.center_y=temp_center_y;
						}
					}
					this.updateNow=true;
				}
			}
		}

		/**
		 * 组装动作信息
		 * @param actions
		 *
		 */
		public function installPartAction($actions:Vector.<Action>):void
		{
			if ($actions == null)
				return;
			var len:int=$actions.length;
			var i:int=0;
			for (i; i != len; ++i)
			{
				addAction($actions[i]);
			}
		}

		/**
		 *根据状态获取动作信息
		 * @param status
		 * @return
		 *
		 */
		public function getAction(status:int):Action
		{
			var action:Action=actions[status];
			if (action == null)
			{
				action=Status.actions[status];
			}
			return action;
		}

		public function get apc():ActionConfig
		{
			return _apc;
		}

		/**
		 *释放
		 *
		 */
		public function dispose():void
		{
			_usable=false;
			this._onEffectFrame=null;
			this.sc=null;
			this._apc=null;
			this.actionFrame=null;
			this.removeAllItem();
			this.loadedPartHandler=null;
			actions=null;
		}

		public function get offsetInfo():OffsetInfo
		{
			// TODO Auto Generated method stub
			return null;
		}

		public function get status():int
		{
			return _status;
		}

		public function set status(value:int):void
		{
			_status=value;
			actionFrame=getAction(_status);
			_apc=Status.getActionConfig(_status);
		}

		public function get usable():Boolean
		{
			return _usable;
		}

		public function setClickRect(w:int=145, h:int=80):void
		{
			// TODO Auto Generated method stub

		}

	}
}
