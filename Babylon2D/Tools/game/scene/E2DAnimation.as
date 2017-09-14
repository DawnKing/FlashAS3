package game.scene
{
    import easiest.managers.FrameManager;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.atlas.PngAnimation;

    import flash.display.BlendMode;

    import game.world.base.view.GameWorldLayer;

    import tempest.core.IAnimation;
    import tempest.core.IMagicScene;
    import tempest.core.IRunable;
    import tempest.core.ISceneCharacter;
    import tempest.enum.AnimationType;
    import tempest.template.AnimationEntity;

    /**
	 * 动画
	 * @author zhangyong
	 *
	 */
	public class E2DAnimation implements IAnimation, IRunable
	{
		/*** 优先级高*/
		public static const priority_heigth:int=2;
		/*** 优先级一般*/
		public static const priority_normal:int=1;
		/*** 优先级低*/
		public static const priority_low:int=0;
		/**获取模版*/
		public static var getAniEntity:Function;
		/***加载优先级(数字越大优先级越大)*/
		public var priority:int=1;
		/***播放完毕回调*/
		public var onComplete:Function=null;
		/***播放回调*/
		public var onChange:Function=null;
		private var _type:int=0;

		/***播放类型*/
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

        public function get parent():SpriteContainer
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
//            _body.alpha=value;
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

        /**帧频*/
		private var _interval:int;
		/**缩放宽度*/
		public var sceleWidth:int;
		//////////////////////////////////////////
		/***时间刻度*/
		private var timeOffset:int=0;
		/**纹理部件*/
//		private var _aps:AnimationPartSource;
		/**核心贴图*/
		private var _body:PngAnimation;
		/**场景*/
		private var _scene:IMagicScene;
		/**是否被使用*/
		private var _disposed:Boolean=false;
		/***编号*/
		private var _id:String;
		/***当前帧*/
		private var _currentFrame:int;
		/***当前帧*/
		private var _maxFrame:int;
		/**配置*/
		private var _config:AnimationEntity;

		private var _dir:int;

		public function get dir():int
		{
			return _dir;
		}

		public function set dir(value:int):void
		{
			_dir=value;
		}
		/**偏移*/
		private var offset:int;
		/**特效跟随对象*/
		private var _anhorTarget:ISceneCharacter;
		/**所属特效包id*/
		public var packId:String;

		/**特效添加目标*/
		public function get anhorTarget():ISceneCharacter
		{
			return _anhorTarget;
		}

		/**
		 * @private
		 */
		public function set anhorTarget(value:ISceneCharacter):void
		{
			_anhorTarget=value;
			if (_anhorTarget && _config)
			{
				var place:int=_config.body_place;
				if (place & 2)
				{ //身体位置
					offset=anhorTarget.bodyOffset;
				}
				else if (place & 4)
				{ //头顶位置
					offset=anhorTarget.headOffset;
				}
			}
			else
			{
				offset=0;
			}
		}

		public function get body():*
		{
			return _body;
		}

		private static var effectIndex:int=0;

		/**
		 * 初始化动画
		 * @param magicid 技能表现id
		 * @param id id
		 * @param sceneType  场景类型
		 *
		 */
		public function init(packId:String, id:String):void
		{
			effectIndex++;
			effectIndex%=30;
			_body=new PngAnimation("http://cdn.cn.nx.xy.local/teste2d/effect/effect.0");
			_body.totalFrame=8;
            _body.pivotX = 125;
            _body.pivotY = 100;
			GameWorldLayer.inst.skillLayer.addChild(_body);

			this.packId=packId;
			this._id=id;
			this._scene=App.iscene;
//			this._aps=SceneCache.GetEffectItem(packId);
//			this._disposed=false;
//			if (!_body)
//			{
//				this._body=Pools.mallocImage(Texture.emptyTexture);
//				_body.touchable=false;
//			}
			this.visible=true;
			_config=getAniEntity(id);
			if (_config == null)
			{
				trace("沒有找到Animation配置文件 code:" + id);
				return;
			}
			if (_config.height)
			{
				scaleX=scaleY=config.height / 100;
			}
			_maxFrame=_config.frameTotal - 1;
			_interval=_config.interval;
			_type=_config.kind;
			blendMode=(config.blend_mode == 2) ? BlendMode.SCREEN : BlendMode.NORMAL;
			play();
		}

		/**
		 * 更新
		 * @param nowTime
		 * @param diff
		 *
		 */
		public function run(nowTime:int, diff:int):void
		{
			if (_disposed || !_scene)
			{
				return;
			}
            var isComplete:Boolean;
            timeOffset+=diff;
            if (_type != AnimationType.Loop && this._currentFrame >= _maxFrame)
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
            while (timeOffset > config.interval)
            {
                timeOffset-=(config.interval || timeOffset);
                if (this._currentFrame >= _maxFrame)
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
            }
			/////////////// 输出到屏幕 ////////////////////////////////
			updateDraw();
			if (isComplete)
			{
				if (onComplete != null)
				{
					this.onComplete(this);
				}
			}
		}

		public function advanceTime(diff:Number):void
		{

		}

		/**
		 * 设置像素坐标
		 * @param px
		 * @param py
		 *
		 */
		public function setPosition(px:Number, py:Number):void
		{
			this.x=px;
			this.y=py;
		}

		private var _tx:int;
		private var _ty:int;

		/**
		 * 更新纹理
		 *
		 */
		protected function updateDraw():void
		{
			if (!visible)
			{
				return;
			}
			//计算获得屏幕的位置
			if (anhorTarget)
			{
				_tx=anhorTarget.wpos.pixelX ;
				_ty=anhorTarget.wpos.pixelY - offset;
				if (!anhorTarget.usable) //特效目标被回收了，把特效也回收掉
				{
					free(this);
					return;
				}
				if (_config.shadow_place != 0) //处理朝向跟随角色的特效
				{
					dir=_anhorTarget.wpos.toward;
				}
//				_body.visible=anhorTarget.visible; //跟被添加的对象一起隐藏
			}
			else if (this.config.shadow_place)
			{
				_tx=x - config.centerX;
				_ty=y - config.centerY;
			}
			else
			{
				_tx=x;
				_ty=y;
			}
			//设置中心点
			_body.x=_tx;
			_body.y=_ty;
		}

		/**
		 * 特效id
		 * @return
		 *
		 */
		public function get id():String
		{
			return _id;
		}

		public function get disposed():Boolean
		{
			return _disposed;
		}

        public function dispose():void
        {
            _disposed=true;
            stop();
            sceleWidth=0;
            blendMode=BlendMode.NORMAL;
            _scene=null;
            setPosition(0, 0);
            priority=1;
            _type=0;
            _interval=0;
            rotation=0;
            _scaleX=_scaleY=1;
            _dir=0;
            alpha=1;
            offset=0;
            _currentFrame=0;
            _maxFrame=0;
            timeOffset=0;
            anhorTarget=null;
            onComplete=null;
            onChange=null;
            _id=null;
            packId=null;
            this.visible=true;
            _config=null;
//            if (_aps)
//            {
//                _aps.decr();
//                _aps=null;
//            }
            if (_onDispose != null)
            {
                _onDispose(this);
                _onDispose=null;
            }
            if (_body)
            {
//                _body.texture=Texture.emptyTexture;
//                Pools.freeImage(_body);
				_body.dispose();
                _body=null;
            }
        }

		/**动画池*/
		private static var _pool:Vector.<E2DAnimation>=new Vector.<E2DAnimation>();

		/**
		 * @param packId  所属资源包id
		 * @param name 资源名字
		 * @param pscene 场景
		 * @param autoFree 是否播完自动回收
		 * @return 特效
		 *
		 */
		public static function Get(packId:String, id:String):E2DAnimation
		{
			if (!id || !id.length || !packId || !packId.length)
			{
				return null;
			}
			var effect:E2DAnimation;
			if (_pool.length > 0)
			{
				effect=_pool.pop();
			}
			if (!effect)
			{
				effect=new E2DAnimation();
			}
			effect.init(packId, id);
			return effect;
		}

		/**
		 * 回收特效
		 * @param effect
		 *
		 */
		public static function free(effect:E2DAnimation):void
		{
			if (!effect || effect.disposed)
			{
				return;
			}
			effect.dispose();
			_pool.push(effect);
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
			FrameManager.add(run);
		}

		public function stop():void
		{
			FrameManager.remove(run);
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
