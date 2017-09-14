package tempest.engine.graphics.avatar
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	
	import common.SceneCache;
	
	import tempest.loader.Handler;
	
	import tempest.engine.graphics.TPBitmap;
	import tempest.engine.graphics.avatar.vo.AvatarPartSource;
	import tempest.engine.graphics.loader.LoaderUtil;
	import tempest.enum.AvatarPartType;
	import tempest.enum.Status;
	import tempest.pool.IPoolsObject;

	/**
	 *
	 * @author zhangyong
	 */
	public class AvatarPart implements IPoolsObject
	{
		/**默认部件资源（黑影）*/
		public static var defaultAsset:AvatarPartSource;
		/**默认部件资源（坐骑黑影）*/
		public static var defaultHorseAsset:AvatarPartSource;
		/**部件加载完毕回调集合*/
		private var _urlLoadHandlers:Object={};
		/***中心点X3*/
		private var _center_x:int=0;
		/***中心点Y*/
		private var _center_y:int=0;
		/***部件位图*/
		private var _bitmap:Bitmap=null;
		/***深度排序*/
		private var _depth:int=0;
		/***是否可见*/
		private var _visible:Boolean=true;
		/**部件加载记录*/
		private var _packages:Object=null;
		/**所有引用的部件*/
		private var _sources:Object=null;
		/**是否已释放*/
		private var _disposed:Boolean=false;
		/***部件avatar*/
		private var _avatar:Avatar=null;
		/***初始部件的路径*/
		private var _path:String;
		/***初始id*/
		private var _id:uint;
		/*** 部件资源*/
		private var _tp:TPBitmap=null;
		/*** 当前部件垂直方向改变偏移*/
		private var _verticalChange:Number=0;
		/**是否主要部件*/
		private var _isCloth:Boolean;
		/**是否坐骑部件*/
		private var _isMount:Boolean;
		/**是否刀光*/
		private var _isEffect:Boolean;
		/**是否更新部件*/
		private var _updateNow:Boolean;
		/***部件类型*/
		private var _type:int;
		/***真实宽*/
		private var _width:int;
		/***真实高*/
		private var _height:int;

		public function get height():int
		{
			return _height;
		}

		public function get width():int
		{
			return _width;
		}

		public function get type():int
		{
			return _type;
		}

		public function get path():String
		{
			return _path;
		}

		public function get id():uint
		{
			return _id;
		}

		/**
		 * 设置真实宽高
		 * @return
		 *
		 */
		public function setSize(w:int, h:int):void
		{
			_width=w;
			_height=h;
		}

		public function AvatarPart(avatar:Avatar, id:int, type:int, path:String)
		{
			this._bitmap=new Bitmap();
			reset(avatar, id, type, path);
		}


		/* INTERFACE tempest.core.IPoolClient avatar:Avatar, id:int, type:int*/
		public function reset(... parm):void
		{
			_disposed=false;
			_avatar=parm[0];
			_id=parm[1];
			_type=parm[2];
			_path=parm[3];
			_packages={};
			_sources={};
			_urlLoadHandlers={};
			_isCloth=(_type == AvatarPartType.CLOTH);
			_isMount=(_type == AvatarPartType.MOUNT);
			_depth=AvatarPartType.getDepth(_type);
			_isEffect=(_type == AvatarPartType.EFFECT);
		}

		public function get bitmap():Bitmap
		{
			return _bitmap;
		}

		public function get depth():int
		{
			return _depth;
		}

		public function get avatar():Avatar
		{
			return _avatar;
		}

		public function set visible(value:Boolean):void
		{
			_visible=value;
			_bitmap.visible=value;
		}

		public function get visible():Boolean
		{
			return _visible;
		}

		public function get center_y():int
		{
			return _center_y;
		}

		public function set center_y(value:int):void
		{
			_center_y=value;
			if (this._avatar.sc)
			{
				if (_isCloth || this._avatar.sc.center_y == 0)
				{
					this._avatar.sc.center_y=_center_y;
					this._avatar.sc.updateHeadOffset();
				}
			}
		}

		/**
		 * 获取部件位图容器
		 * @return
		 *
		 */
		public function get tp():TPBitmap
		{
			return _tp;
		}

		/**
		 *更新部件
		 *
		 */
		public function update(diff:int):void
		{
			if (this.avatar && !this.avatar.visible)
			{ //整体不可见 
				return;
			}
			if (this.avatar.sc && !this.avatar.sc.visible)
			{ //角色不可见
				return;
			}
			if (this._disposed)
			{
				return;
			}
			/*****************************坐骑动作特殊处理******************************/
			var _status:int=this.avatar.getStatus();
			var dir:int=this.avatar.dir;
			if (_isMount)
			{
				if (_status == Status.JUMP)
				{
					_status=Status.WALK;
				}
				else if (_status != Status.WALK)
				{
					_status=Status.STAND;
				}
			}
			/*****************************刀光置特殊处理******************************/
			if (_isEffect)
			{
				switch (_status)
				{
					case Status.ATTACK:
					case Status.ATTACK2:
					case Status.ATTACK3:
						this.visible=true;
						break;
					default:
						this.visible=false;
						return;
						break;
				}
			}
			/*****************************膀排序位置特殊处理******************************/
			if (_type == AvatarPartType.WING)
			{
				var $dValue:int=AvatarPartType.depths[AvatarPartType.WING];
				if (dir > 1 && dir < 7)
				{ //特殊处理朝向
					if (this._depth != -$dValue)
					{
						this._depth=-$dValue;
						this._avatar.sortDepth(Array.NUMERIC);
						this._avatar.setChildIndex(bitmap, this._avatar.avatarParts.indexOf(this));
					}
				}
				else
				{
					if (this._depth != $dValue)
					{
						this._depth=$dValue;
						this._avatar.sortDepth(Array.NUMERIC);
						this._avatar.setChildIndex(bitmap, this._avatar.avatarParts.indexOf(this));
					}
				}
			}
			/******************************************************************************/
			var $aps:AvatarPartSource=_sources[_status];
			if ($aps)
			{
				checkAps($aps);
			}
			if (this._updateNow || this.avatar.updateNow)
			{
				if ($aps != null && !$aps.disposed)
				{ //只更新有效的部件 资源
					_tp=$aps.get(_status, dir, this.avatar.currentFrame);
				}
				else
				{
					_tp=null;
					if (_packages[_status] == null) //如果该动作所属分包未加载过
					{
						_packages[_status]=_status;
						var path:String=LoaderUtil.replaceUrl(this._path, _status);
						LoaderUtil.loadAvatarPart(path, getLoadHanlder(path));
					}
				}
				var $_center_x:int=_center_x;
				var $_center_y:int=_center_y;
				if (!_tp)
				{
					if (_isCloth) //使用黑影
					{
						if (_avatar.useDefaultAsset)
						{
							$_center_x=375;
							$_center_y=425;
							if (_center_y == 0)
							{
								center_y=425;
							}
							if (defaultHorseAsset && this.avatar.getAvatarItem(AvatarPartType.MOUNT))
							{
								_tp=defaultHorseAsset.get(_status, dir, this.avatar.currentFrame);
							}
							else if (defaultAsset)
							{
								_tp=defaultAsset.get(_status, dir, this.avatar.currentFrame);
							}
						}
					}
				}
				if (_tp)
				{
					_tp.updateBM(_bitmap, $_center_x, $_center_y, _verticalChange);
				}
				else
				{
					_bitmap.bitmapData=null;
				}
			}
			_updateNow=false;
		}

		/**
		 * 检查部件资源是否有效
		 *
		 */
		public function checkAps(aps:AvatarPartSource):void
		{
			if (aps.disposed)
			{
				var $res_package:int=aps.prefix;
				if (_packages[$res_package])
				{ //还缓存在分包前缀集合中
					_packages[$res_package]=null;
					delete _sources[$res_package];
				}
				if (_sources[$res_package])
				{ //还缓存在分包集合中
					_sources[$res_package]=null;
					delete _sources[$res_package];
				}
				if (_urlLoadHandlers[aps.id])
				{ //还缓存在回调集合中
					_urlLoadHandlers[aps.id]=null;
					delete _urlLoadHandlers[aps.id];
				}
			}
		}

		/***
		 * 获取加载回调函数
		 * @param path
		 * @return
		 *
		 */
		public function getLoadHanlder(path:String):Handler
		{
			var loadedHandler:Handler=_urlLoadHandlers[path];
			if (!loadedHandler)
			{
				loadedHandler=new Handler(onLoadedAvatarPart); //这里使用同一个hanlder，在删除的时候可以确保删除的是同一个
				_urlLoadHandlers[path]=loadedHandler;
			}
			return loadedHandler;
		}

		/**
		 *更新垂直方向偏移
		 * @param verticalChange
		 *
		 */
		public function updateOffset(verticalChange:Number):void
		{
			_verticalChange=verticalChange;
			if (_tp && _avatar)
			{
				_bitmap.y=_tp.offset_y - _avatar.sc.center_y + _verticalChange;
			}
		}

		/**
		 *添加部件缓存
		 * @param rvo
		 * @param isCache
		 * @return
		 *
		 */
		public function onLoadedAvatarPart(loader:*):void
		{
			if (_disposed || !loader)
			{
				return;
			}
			if (!avatar)
			{
				return;
			}
			var aps:AvatarPartSource=null;
			if (loader is Loader)
			{
				aps=SceneCache.getAvatarCache(loader.id);
				if (!aps)
				{
					aps=new AvatarPartSource(loader, loader.id);
					SceneCache.addAvatarPartCache(aps);
				}
			}
			else if (loader is AvatarPartSource) //直接使用缓存的
			{
				aps=loader as AvatarPartSource;
			}
			installPartSource(aps);
			if (avatar.loadedPartHandler != null) //部件安装完毕回调
			{
				avatar.loadedPartHandler();
			}
		}

		/**
		 *组装其他动作
		 * @param avatarPartSource
		 *
		 */
		public function installPartSource(avatarPartSource:AvatarPartSource):void
		{
			if (avatarPartSource == null)
			{
				return;
			}
			if (this._disposed)
			{
				return;
			}
			//保存部件引用
			var $aps:AvatarPartSource=avatarPartSource.allocate();
			if (this._avatar.createAll)
			{ //创建全部帧
				$aps.createAll();
			}
			var $part:int=$aps.prefix;
			_sources[$part]=$aps;
			if (_width == 0)
			{
				setSize($aps.width, $aps.height);
			}
			/////////////////////////////////////////////////
			if (_center_x == 0)
			{
				_center_x=$aps.width >> 1;
				center_y=$aps.center_offset;
			}
			if (_isCloth)
			{
				if (this._avatar.sc)
				{
					this._avatar.sc.center_x=_center_x;
					_center_x=_center_x;
					if ($part == 6 && this._avatar.sc.isOnMount)
					{ //坐骑的跳跃
						this._avatar.sc.bodyOffset=$aps.body_offset - 50;
						this._avatar.sc.headOffset=$aps.head_offset - 30;
					}
					else
					{
						this._avatar.sc.bodyOffset=$aps.body_offset;
						this._avatar.sc.headOffset=$aps.head_offset;
					}
					this._avatar.sc.updateHeadOffset();
				}
				//是否需要组装动作
				if (avatarPartSource.actions)
				{
					this._avatar.installPartAction(avatarPartSource.actions);
				}
			}
			this._avatar.updatePart(); //更新部件位置
			if (this.avatar.actionFrame)
			{
				update(this.avatar.actionFrame.interval);
			}
			_updateNow=true;
		}

		/**
		 * 是否与鼠标碰撞
		 * @return
		 */
		public function isMouseHit():Boolean
		{
			return _bitmap.bitmapData && ((_bitmap.bitmapData.getPixel32(_bitmap.mouseX, _bitmap.mouseY) >> 24) & 0xFF) > 0x66;
		}

		/**
		 * 释放
		 *
		 */
		public function dispose():void
		{
			this._disposed=true;
			this.visible=true;
			this._bitmap.bitmapData=null;
			this._avatar=null;
			this._verticalChange=0;
			this._center_x=0;
			this._center_y=0;
			this._path=null;
			this._packages=null;
			var key:String
			if (_urlLoadHandlers)
			{
				for (key in _urlLoadHandlers)
				{
					LoaderUtil.removeAvatarLoadComplete(key, _urlLoadHandlers[key]);
				}
			}
			this._urlLoadHandlers=null;
			for (key in _sources) //减去引用
			{
				_sources[key].release();
				delete _sources[key];
			}
		}
	}
}
