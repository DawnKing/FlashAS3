package tempest.engine.graphics.animation
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.geom.Point;
	
	import common.SceneCache;
	import common.vo.AnimationBlendMode;
	
	import tempest.loader.Handler;
	
	import tempest.TPEngine;
	import tempest.core.IAnimation;
	import tempest.core.IRunable;
	import tempest.engine.graphics.TPBitmap;
	import tempest.engine.graphics.loader.LoaderUtil;
	import tempest.enum.AnimationType;
	import tempest.template.AnimationEntity;

	/**
	 * displayobject 特效
	 * @author zhangyong
	 *
	 */
	public class Animation implements IAnimation, IRunable
	{
		/**获取路径*/
		public static var getPath:Function;
		/**获取模版*/
		public static var getAniEntity:Function;
		/***编号*/
		public var guid:int=0;
		/***播放完毕回调*/
		public var onComplete:Function=null;
		/***播放回调*/
		public var onChange:Function=null;
		/***播放类型*/
		private var _type:int=0;


		public function get type():int
		{
			return _type;
		}

		/**
		 * @private
		 */
		public function set type(value:int):void
		{
			_type=value;
		}

		public function get parent():DisplayObjectContainer
		{
			return _body.parent;
		}

		private var _x:int;

		public function get x():int
		{
			return _x;
		}

		public function set x(value:int):void
		{
			_x=value;
		}

		private var _y:int;

		public function get y():int
		{
			return _y;
		}

		public function set y(value:int):void
		{
			_y=value;
		}

		private var _blendMode:String

		public function get blendMode():String
		{
			return _blendMode;
		}

		public function set blendMode(value:String):void
		{
			_blendMode=value;
			_body.blendMode=value;
		}

		private var _rotation:Number;

		public function get rotation():Number
		{
			return _rotation;
		}

		public function set rotation(value:Number):void
		{
			_rotation=value;
			_body.rotation=value;
		}

		private var _alpha:Number;

		public function get alpha():Number
		{
			return _alpha;
		}

		public function set alpha(value:Number):void
		{
			_alpha=value;
			_body.alpha=value;
		}

		private var _scaleX:Number=1;

		public function get scaleX():Number
		{
			return _scaleX;
		}

		public function set scaleX(value:Number):void
		{
			_scaleX=value;
			_body.scaleX=value;
		}

		private var _scaleY:Number=1;

		public function get scaleY():Number
		{
			return _scaleY;
		}

		public function set scaleY(value:Number):void
		{
			_scaleY=value;
			_body.scaleY=value;
		}

		private var _visible:Boolean=true;

		public function get visible():Boolean
		{
			return _visible;
		}

		public function set visible(value:Boolean):void
		{
			_visible=value;
			_body.visible=value;
		}

		public function set filters(value:Array):void
		{
			_body.filters=value;
		}

		//////////////////////////////////////////
		/***时间刻度*/
		private var timeOffset:int=0;
		/***是否已回收*/
		private var _disposed:Boolean=true;
		/***是否在播放*/
		private var _running:Boolean=false;
		/***添加位置*/
		private var _position:Point=null;
		/***编号*/
		private var _id:String;
		/**镜像id*/
		private var _mirrorId:String;
		/***位图*/
		private var _body:Bitmap=null;
		/***当前帧*/
		private var _currentFrame:int;
		/***总帧数*/
		private var _totalFrames:int;
		/***最大帧数*/
		private var _maxFrame:int;
		/***帧频*/
		public var interval:int=1000;
		/**配置*/
		private var _config:AnimationEntity;
		/**加载完毕回调*/
		private var onLoadedHandler:Handler;
		private var _dir:int;
		private var _prefix:int

		public function get dir():int
		{
			return _dir;
		}

		public function set dir(value:int):void
		{
			_dir=value;
		}

		/**
		 *
		 * @param id
		 * @param posX
		 * @param posY
		 * @param directory
		 * @param priority
		 *
		 */
		public function Animation(id:String, posX:Number=0, posY:Number=0)
		{
			_body=new Bitmap();
			this._id=id;
			this.setPosition(posX, posY);
			this.init();
		}


		public function advanceTime(diff:Number):void
		{
		}

		/**
		 * 更新
		 * @param nowTime
		 * @param diff
		 *
		 */
		public function run(nowTime:int, diff:int):void
		{
			timeOffset+=diff;
			var isComplete:Boolean;
			if (this._currentFrame >= this._maxFrame)
			{
				switch (this._type)
				{
					case AnimationType.OnceTODispose:
						free(this);
						return;
					case AnimationType.Once:
						this.timeOffset=0;
						this._currentFrame=_maxFrame;
						return;
				}
			}
			if (timeOffset > interval)
			{
				while (timeOffset > interval)
				{
					timeOffset-=(interval || timeOffset);
					if (this._currentFrame >= this._maxFrame)
					{
						if (this._type != AnimationType.Loop)
						{
							this.timeOffset=0;
							this._currentFrame=_maxFrame;
							isComplete=true;
							break;
						}
						else
						{
							this._currentFrame=0;
						}
					}
					else
					{
						_currentFrame++;
					}
					if (onChange != null)
					{
						this.onChange(this);
					}
					///////////////////////////////////////
					updateNow=true;
				}
			}
			this.updateDraw();
			if (isComplete)
			{
				if (onComplete != null)
				{
					this.onComplete(this);
				}
			}
		}

		/**
		 * 初始化特效
		 * @param directory
		 */
		private function init():void
		{
			play();
			_disposed=false;
			var entityId:int
			if (_id.indexOf("_") != -1)
			{
				entityId=parseInt(_id.substring(2, _id.length));
				_prefix=parseInt(_id.charAt(0));
			}
			else
			{
				entityId=int(_id);
			}
			_config=getAniEntity(entityId);
			if (config == null)
			{
				trace("沒有找到Animation配置文件 code:" + _id);
				return;
			}
			if (_config.height)
			{
				this.scaleX=this.scaleY=_config.height / 100;
			}
			this._type=config.kind;
			this.blendMode=AnimationBlendMode.getBlendMode(config.blend_mode);
			this._totalFrames=config.frameTotal;
			_maxFrame=_totalFrames - 1;
			this.interval=config.interval;
			if (_prefix > 4)
			{
				_mirrorId=(8 - _prefix) + "_" + _id.substr(2, _id.length);
				this._path=getPath(_mirrorId);
			}
			else
			{
				this._path=getPath(this._id);
			}
			onLoadedHandler=new Handler(onSourceLoaded, [this._path]);
			LoaderUtil.loadAnimation(this._path, onLoadedHandler);
		}

		public function setPosition(px:Number, py:Number):void
		{
			this.x=px;
			this.y=py;
		}

		/**
		 * 加载完毕
		 * @param url 路径
		 * @param swf 资源
		 *
		 */
		private function onSourceLoaded(url:String, loader:*):void
		{
			if (_disposed || !loader)
			{
				return;
			}
			var aps:AnimationSource=null;
			if (loader is Loader)
			{
				aps=SceneCache.getAnimationCache(url);
				if (!aps)
				{
					aps=new AnimationSource(loader, url);
					SceneCache.addAnimationtCache(aps);
				}
			}
			else if (loader is AnimationSource)
			{
				aps=loader;
			}
			if (_prefix > 4)
			{
				aps=SceneCache.getAnimationCache(getPath(_id));
				if (!aps)
				{
					aps=loader.cloneMirror(getPath(_id), config.width);
					SceneCache.addAnimationtCache(aps);
				}
			}
			this.source=aps;
		}

		public function get id():String
		{
			return _id;
		}

		public function get body():*
		{
			return _body;
		}

		public function get bodySource():BitmapData
		{
			return _body.bitmapData;
		}

		public function set bodySource(value:BitmapData):void
		{
			if (_body.bitmapData != value)
			{
				_body.bitmapData=value;
			}
		}

		public function get position():Point
		{
			return _position;
		}

		public function clone():Animation
		{
			return createAnimation(_id, x, y);
		}

		public function get disposed():Boolean
		{
			return _disposed;
		}
		/////////////////////////////////////////////////////////////////////////////////////////////////////
		public var updateNow:Boolean=true;
		private var _path:String;

		public function get path():String
		{
			return _path;
		}
		private var _source:AnimationSource;

		public function get source():AnimationSource
		{
			return _source;
		}

		public function set source(value:AnimationSource):void
		{
			if (value)
			{
				_source=value.allocate();
				this.updateNow=true;
				this.updateDraw();
			}
		}

		/**
		 * 更新显示
		 *
		 */
		private function updateDraw():void
		{
			if (!this.updateNow)
			{
				return;
			}
			if (_source)
			{
				var tp:TPBitmap=_source.get(this._currentFrame);
				if (tp)
				{
					tp.updateBM(_body, config.centerX, config.centerY); //更新偏移位置
					//更新世界位置
					_body.x+=x;
					_body.y+=y;
				}
			}
			this.updateNow=false;
		}

		public function reset(id:String, posX:Number=0, posY:Number=0):void
		{
			guid=0;
			_type=0;
			_prefix=0;
			_currentFrame=0;
			_totalFrames=0;
			_maxFrame=0;
			timeOffset=0;
			interval=10000;
			_running=false;
			_mirrorId=null;
			this.rotation=0;
			this._id=id;
			this.setPosition(posX, posY);
			this.init();
		}

		/**
		 *释放
		 *
		 */
		public function dispose():void
		{
			_disposed=true;
			stop();
			onComplete=null;
			onChange=null;
			this.alpha=1;
			this.visible=true;
			this.rotation=0;
			this.scaleX=this.scaleY=1;
			this.blendMode=BlendMode.NORMAL;
			this.body.x=0;
			this.body.y=0;
			this.body.filters=null;
			if (onLoadedHandler != null)
			{
				LoaderUtil.removeAniLoadComplete(this._path, onLoadedHandler);
				this.onLoadedHandler=null;
			}
			if (_body.bitmapData)
			{
				_body.bitmapData=null;
			}
			if (_source)
			{
				_source.release();
				_source=null;
			}
			if (_body.parent != null)
			{
				_body.parent.removeChild(_body);
			}
			if (_onDispose != null)
			{
				_onDispose(this);
				_onDispose=null;
			}
			this._dir=0;
		}
		private static var _animationPool:Vector.<Animation>=new Vector.<Animation>();

		/**
		 * 创建特效动画
		 * @param id
		 * @param sceneType
		 * @param posX
		 * @param posY
		 * @param directory
		 * @return
		 *
		 */
		public static function createAnimation(id:String, posX:Number=0, posY:Number=0):Animation
		{
			if (!id || id == "")
			{
				return null;
			}
			var animation:Animation;
			if (_animationPool.length > 0)
			{
				animation=_animationPool.shift();
				animation.reset(id, posX, posY);
			}
			else
			{
				animation=new Animation(id, posX, posY);
			}
			return animation;
		}

		public static function free(animation:Animation):void
		{
			if (!animation || animation.disposed)
			{
				return;
			}
			animation.dispose();
			//暂时屏蔽
			_animationPool.push(animation);
		}

		public function get currentFrame():int
		{
			return _currentFrame;
		}

		public function get totalFrame():int
		{
			return _totalFrames;
		}

		public function get config():AnimationEntity
		{
			return _config;
		}

		public function resetFrame():void
		{
			_currentFrame=0;
		}

		public function play():void
		{
			TPEngine.sceneRender.addIRunableRender(this);
		}

		public function stop():void
		{
			TPEngine.sceneRender.removeIRunableRender(this);
		}

		private var _onDispose:Function;

		public function set onDispose(value:Function):void
		{
			_onDispose=value;
		}

		public function onStopRun():void
		{

		}

	}
}
