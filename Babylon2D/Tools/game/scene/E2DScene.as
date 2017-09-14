package game.scene
{

    import easiest.managers.FrameManager;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;
    import easiest.rendering.sprites.text.E2DTextMgr;

    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;

    import game.base.Main;
    import game.scene.map.E2DMapLoader;
    import game.scene.map.E2DMapPart;
    import game.scene.map.E2DMapPartLayer;
    import game.world.base.view.CharLayer;
    import game.world.base.view.GameWorldLayer;
    import game.world.map.model.MapData;
    import game.world.map.model.MapModel;
    import game.world.map.view.MapCell;

    import tempest.core.IAnimation;
    import tempest.core.ICamera;
    import tempest.core.IFlyTextTagger;
    import tempest.core.IMagicScene;
    import tempest.core.IPartical;
    import tempest.core.ISceneCharacter;
    import tempest.data.find.TAstar;
    import tempest.data.map.MapConfig;
    import tempest.data.obj.GuidObjectTable;
    import tempest.manager.FPSMgr;
    import tempest.signals.SceneSignal;

    /**
	 * starling场景基类
	 * @author zhangyong
	 *
	 */
	public class E2DScene extends SpriteContainer implements IMagicScene
	{
		/**加载完成事件*/
		public static const ON_LOADED:String="ON_LOADED";
		/**加载错误事件*/
		public static const ON_ERROR:String="ON_ERROR";
		/**主玩家*/
		protected var _mainChar:ISceneCharacter;
		//////////////////////////////////////////////////////////////////////
		public var worldLoopCounter:uint=0; //世界循环次数
		/*地图数据容器*/
		protected var _mapLoader:E2DMapLoader;
		/**文本管理器*/
		public var textMgr:E2DTextMgr;
		/**说话文本管理器*/
		public var unitTalkTextMgr:E2DTextMgr;
		/*是否初始化*/
		protected var _inited:Boolean=false;
		/*正在下载*/
		protected var _isLoading:Boolean=false;
		//地图层
		protected var _bottomMapPartLayer:E2DMapPartLayer;
		//底层特效
		protected var _bottomEffectLayer:SpriteContainer;
		//底层特效排序标识
		protected var _bottomEffectLayerSortFlag:Boolean;
		//形象层
		protected var _avatarLayer:CharLayer;
		//顶层特效
		protected var _topEffectLayer:SpriteContainer;
		//顶层特效排序标识
		protected var _topEffectLayerSortFlag:Boolean;
		//hud层
		protected var _hudLayer:SpriteContainer;
		/*摄像机*/
		protected var _camera:E2DCamera;
		/*下次打雷时间戳*/
		protected var _nextThunderTime:int;
		/**/
		protected var _selectChar:ISceneCharacter;

		protected var _characters:Vector.<E2DSceneCharacter>=new Vector.<E2DSceneCharacter>();
		protected var _effects:Vector.<IAnimation>=new Vector.<IAnimation>();

		/**鼠标移动在avatar对象*/
		public var mouseOnAvatar:SpriteContainer;
		public var mapTagPartLayer:*;

		/**鼠标on*/
		public function get mouseOnChar():ISceneCharacter
		{
			return null;
//			return mouseOnAvatar ? mouseOnAvatar.sc : null;
		}

		/**当前选中对象*/
		public function get selectChar():ISceneCharacter
		{
			return _selectChar;
		}

		public function set selectChar(value:ISceneCharacter):void
		{
			_selectChar=value;
		}

		/**主角*/
		public function get mainChar():ISceneCharacter
		{
			return _mainChar;
		}

		/**
		 * @private
		 */
		public function set mainChar(value:ISceneCharacter):void
		{
			_mainChar=value;
		}

		/**
		 * 创建场景对象
		 * @param type
		 * @return
		 *
		 */
		public function createCharacter(type:int):ISceneCharacter
		{
			var char:ISceneCharacter=new E2DSceneCharacter(type, this);
			addCharacter(char);
			return char;
		}
		/**地图加载完毕回调*/
		protected var onComplete:Function;

		/**
		 * 场景构造
		 * @param dataTable 数据表
		 */
		public function E2DScene(dataTable:GuidObjectTable)
		{
			super();
			_sceneObjData=dataTable;
			//摄像机
			_camera=new E2DCamera(this, true, 0.1);
			//名字文本管理器
			textMgr=new E2DTextMgr(partWidth, partHeight);
			//说话文本管理器
			unitTalkTextMgr=new E2DTextMgr(partWidth, partHeight);
			//混合模式
			this.blendMode=BlendMode.NORMAL;
			initLayers();
			startRender();
		}

		/**
		 * 初始化所有地图层(第一次加载地图初始化一次就可以了)
		 */
		protected function initLayers():void
		{
			mouseChildren=true;
			mouseEnabled=false;
			//底层地图切片容器
			_bottomMapPartLayer=new E2DMapPartLayer(partWidth, partHeight);
			_bottomMapPartLayer.blendMode=BlendMode.NORMAL;
//            addChild(_bottomMapPartLayer);
			//底层特效容器
			_bottomEffectLayer=new SpriteContainer();
			_bottomEffectLayer.blendMode=BlendMode.NORMAL;
			_bottomEffectLayer.mouseChildren=false;
//            addChild(_bottomEffectLayer);
			//形象层
			_avatarLayer=new CharLayer();
			_avatarLayer.blendMode=BlendMode.NORMAL;
//			addChild(_avatarLayer);
//			顶特效容器
			_topEffectLayer=new SpriteContainer();
			_topEffectLayer.blendMode=BlendMode.NORMAL;
			_topEffectLayer.mouseChildren=false;
//            addChild(_topEffectLayer);
			//hud层
			_hudLayer=new SpriteContainer();
//            addChild(_hudLayer);
		}

		public function get inited():Boolean
		{
			return _inited;
		}

		public function get camera():ICamera
		{
			return _camera;
		}

		protected var _id:int;

		/**地图id*/
		/**
		 *
		 * @return
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 * 获得实体数据
		 * @return
		 *
		 */
		public function get mapConfig():MapConfig
		{
			if (!_mapLoader)
				return null;
			return _mapLoader.entryData;
		}

		/**
		 * 获得当前的地图加载器
		 * @return
		 *
		 */
		public function get mapLoader():E2DMapLoader
		{
			return _mapLoader;
		}

		protected static var _sceneObjData:GuidObjectTable;

		/**
		 * @private
		 */
		public function get objData():GuidObjectTable
		{
			return _sceneObjData;
		}

        public static function get guidObjectList():GuidObjectTable
        {
			return _sceneObjData;
        }

		protected var _enabled:Boolean;


		/**
		 * 启用场景交互
		 *
		 */
		public function enableInteractive():void
		{
			_enabled=true;
			_avatarLayer.mouseChildren=true;
			_bottomMapPartLayer.mouseChildren=true;
		}

		/**
		 * 禁用场景交互
		 *
		 */
		public function disableInteractive():void
		{
			_enabled=false;
			_avatarLayer.mouseChildren=false;
			_bottomMapPartLayer.mouseChildren=false;
		}

		/**
		 * 场景对象鼠标事件
		 * @param e
		 *
		 */
		protected function onAvatarTouch(e:Event):void
		{
			if (!_enabled)
			{
				return;
			}
			signal.interactive.dispatch(e, null);
		}

		/////////////////////////// 地图数据及素材数据加载开始 ////////////////////////
		/**
		 * 加载地图素材及逻辑数据
		 *
		 */
		public function load(newMapid:uint, rect:Rectangle, onComplete:Function, virTual:Boolean=false):void
		{
			if (_mapLoader) //说明地图没有清理
			{
				clearMapSurface();
			}
			this.onComplete=onComplete;
			_inited=false;
			_mapLoader=new E2DMapLoader(rect);
			_mapLoader.addEventListener(E2DMapLoader.MAPDATA_LOADED, onMapLoaded);
			_mapLoader.load(newMapid);
			_id=newMapid;
			_isLoading=true;
		}


		/**
		 * 地图数据加载完毕
		 *
		 */
		protected function onMapLoaded(event:Event):void
		{
			if (_bottomMapPartLayer) //动态设置瓷砖尺寸
			{
				_bottomMapPartLayer.setPartSize(_mapLoader.entryData.sliceWidth, _mapLoader.entryData.sliceHeight);

				MapModel.mapData.setPartSize(_mapLoader.entryData.sliceWidth, _mapLoader.entryData.sliceHeight);

			}
			TAstar.mapModel=_mapLoader.entryData;
			camera.setBounds(mapConfig.pxWidth, mapConfig.pxHeight);
			startRender();
			if (onComplete != null)
			{
				onComplete();
			}
		}

		/*初始化*/
		protected function init():void
		{
			_inited=true;
			//广播初始化完成事件
			dispatchEvent(new Event(ON_LOADED));
			//初始化地表
			initMapSurface();
			//充值标记
			_camera.restFlag();

			_bottomMapPartLayer.addEventListener(MouseEvent.CLICK, onSceneTouch);
		}

		private var TOUCHENDED:Boolean;
		private var _clickTime:int;

		private function onSceneTouch(event:MouseEvent):void
		{
			if (!_enabled)
			{
				return;
			}
//            if (mouseOnAvatar)
//            {
//                mouseOnAvatar.isMouseOver=false;
//                mouseOnAvatar=null;
//                //鼠标从对象移出
//                if (CursorConst.isShopCursor())
//                {
//                    return;
//                }
//                if (CursorConst.isSceneCursor())
//                {
//                    MouseUtil.showDefault();
//                }
//            }
			//得到鼠标点击了位于整个地图的像素点
//            sceneTouch=e.getTouch(this, TouchPhase.HOVER); //移动
//            if (sceneTouch)
//            {
//                updateCurMouse(sceneTouch);
//            }
//            sceneTouch=e.getTouch(this, TouchPhase.BEGAN); //开始点击
//            if (sceneTouch) //触发场景touch事件
//            {
			onSceneClick(event.shiftKey);
//                updateCurMouse(sceneTouch); //点击的时候重新更新一次鼠标位置，因为可能是场景在动
			_clickTime=getTimer();
//                TOUCHENDED=true;
//            }
//            sceneTouch=e.getTouch(this, TouchPhase.ENDED); //结束点击
//            if (sceneTouch) //触发场景touch事件
//            {
//                TOUCHENDED=false;
//                _clickTime=0
//            }
		}

		public function onSceneClick(shiftKey:Boolean=false):void
		{
//            if (shiftKey)
//            {
//                sceneTouch.globalX;
//                sceneTouch.globalY;
//                if (FightMgr.instance.useJumpSkill(_curMouse))
//                {
//                    FightMgr.instance.stopSpell();
//                    return;
//                }
//            }
//            updateCurMouse(sceneTouch); //更新鼠标位置，和手型
			moveToPixel(curMouse);
		}

		public function moveToPixel(targetPoint:Point):void
		{
			if (mapConfig == null)
				return;
			moveToLogic(mapConfig.Pixel2Tile(targetPoint))
		}

		private function moveToLogic(targetPoint:Point):void
		{
//            if (!FightMgr.instance.heroState())
//            {
//                return;
//            }
//            FightMgr.instance.initAssitWarnTimes();
//            FightMgr.instance.initMoveWarnTimes();
//            if (!MainCharWalkMgr.canMove())
//            {
//                return;
//            }
			//寻路并发包
			if (mainChar)
				mainChar.walk(targetPoint);
		}
		/**地图路径*/
		public static var scenePath:String="scene/";

		//初始化地表
		protected function initMapSurface():void
		{
//			var thum:Texture=_mapLoader.thum ? _mapLoader.thum : Texture.emptyTexture;
//			var thum:Texture;
//			if (!thum)
//				return;
			var urlFormat:String;
			var i:int=0;
			//地图层初始化
			var mapPath:String = scenePath + _id + "/";
			urlFormat=mapPath + "maps/{0}_{1}.bin";
			_bottomMapPartLayer.initMapPartLayer(0, 0, mapConfig.pxWidth, mapConfig.pxHeight, urlFormat, null, mapConfig.thumbScale);

			var mapData:MapData=MapModel.mapData;
			mapData.init(0, 0, mapConfig.pxWidth, mapConfig.pxHeight, _bottomMapPartLayer.partWidth, _bottomMapPartLayer.partHeight, urlFormat, mapPath);

			Main.inst.gameWorld.start();
		}

		/**
		 * 驱动
		 * @param now
		 * @param diff
		 *
		 */
		public function run(now:int, diff:int):void
		{
			var avgMs:int=FPSMgr.instance.avgFps;
			E2DMapPart.updateTasks(now, avgMs);
			MapCell.updateTasks(now, avgMs);

			//心态循环计数
			worldLoopCounter++;
			//底图更新
			drawBottomMapLayer(diff);
			//fps管理器
			FPSMgr.instance.update(diff);
			//如果处于下载状态
			if (_isLoading)
			{
				//获取地图mapid
				if (_mapLoader.isLoaded)
				{
					_isLoading=false;
					//初始化
					init();
				}
				else if (_mapLoader.isError)
				{
					_isLoading=false;
					//IO错误
					var event:Event=new Event(ON_ERROR);
					dispatchEvent(event);
				}
			}
			//在这里开始工作了
			if (_camera.isResize)
			{
//				scaleX=scaleY=_camera.z;
			}
			//更新底层特效
			drawEffect(_bottomEffectLayer, _bottomEffectLayerSortFlag, diff);
			_bottomEffectLayerSortFlag=false;
			//avatart更新
			drawAvatar(diff);
			//更新顶层特效
			drawEffect(_topEffectLayer, _topEffectLayerSortFlag, diff);
			_topEffectLayerSortFlag=false;
		}

		//绘制底层地图
		protected function drawBottomMapLayer(diff:int):void
		{
			if (!_inited || !mapConfig)
				return;
			//摄像头更新
			camera.run(0, 0);
			//地表层
			_bottomMapPartLayer.setViewPortByCamera(camera);
			_bottomMapPartLayer.update(worldLoopCounter);

			MapModel.mapData.setViewPort(camera.rect.x, camera.rect.y, camera.rect.width, camera.rect.height);
			GameWorldLayer.inst.x = -camera.rect.x;
            GameWorldLayer.inst.y = -camera.rect.y;
		}

		/**计算头顶位置偏移*/
		protected var offsetX:int, offsetXBody:int, offsetHeadY:int, offsetYLeft:int, offsetYBody:int, offsetBarLeftX:int, offsetNameLeftX:int, offsetNameLeftY:int;

		/**
		 * 循环绘制avatar
		 * @param sceneChar
		 *
		 */
		protected function updateLogo(sceneChar:E2DSceneCharacter):void
		{
		}

		/**
		 * 更新avatar对象
		 * @param diff 帧时差
		 *
		 */
		protected function drawAvatar(diff:uint):void
		{
			//影子id
			var shadowID:uint=0;
			var avatar:SpriteContainer;
			var display:SpriteObject;
			//循环心跳
			var iter:int=0;
			var pindex:int;
			var ipartical:IPartical;
			for (; iter < _avatarLayer.numChildren; iter++)
			{
				display=_avatarLayer.getChildAt(iter);
				avatar=display as SpriteContainer;
				if (!avatar)
					continue;
				if (!Object(avatar).sc.isMainPlayer)
					continue;
				//对象更新
                Object(avatar).sc.onViewUpdate(diff);
				//更新logo
				updateLogo(Object(avatar).sc);
				if (!avatar.visible)
					continue;
			}
			//avatar和影子排序
			_avatarLayer.sortChildren(onSortAvatar);
		}

		/**
		 * 绘制指定的特效层
		 * @param layer 层
		 * @param needSort 是否需要排序
		 * @param diff 帧时差
		 *
		 */
		protected function drawEffect(layer:SpriteContainer, needSort:Boolean, diff:int):void
		{
			var ani:IAnimation;
			var i:int=0;
			for (; i < layer.numChildren; i++)
			{
				ani=(layer.getChildAt(i) as IAnimation);
				if (ani)
				{
					ani.advanceTime(diff);
				}
			}
			//为了避免交替渲染，所以做排序，按照贴图类型排序
			if (needSort)
			{
//                layer.sortChildren(onSortEffect);
			}
		}


		/**
		 *  avatar形象排序
		 * @param displayLeft
		 * @param displayRight
		 * @return
		 *
		 */
		protected function onSortAvatar(displayLeft:Object, displayRight:Object):Number
		{
			return displayLeft.sc.sortScore - displayRight.sc.sortScore;
		}

		/**
		 * 特效排序
		 * @param displayLeft
		 * @param displayRight
		 * @return
		 *
		 */
		protected function onSortEffect(displayLeft:E2DAnimation, displayRight:E2DAnimation):Number
		{
			//为了避免交替渲染，所以做排序，按照贴图类型排序
			if (displayLeft.disposed)
			{
				return -1;
			}
			if (displayRight.disposed)
			{
				return 1;
			}
			return 0;
//			return int(displayLeft.coreImg.texture.flashTexture != displayRight.coreImg.texture.flashTexture);
		}

		/**
		 * 场景加入特效
		 *
		 */
		public function addEffect(ianimation:IAnimation, isBottom:Boolean=false):void
		{
			var ani:E2DAnimation=ianimation as E2DAnimation;
			if (!ani || !ani.config)
			{
				return;
			}
			if (isBottom || Boolean(ani.config.around_place & 2))
			{
				if (!_bottomEffectLayer || ani.parent == _bottomEffectLayer)
				{
					return;
				}
//				_bottomEffectLayer.addChild(ani.body);
				_bottomEffectLayerSortFlag=true;
			}
			else
			{
				if (!_topEffectLayer || ani.parent == _topEffectLayer)
				{
					return;
				}
//				_topEffectLayer.addChild(ani.body);
				_topEffectLayerSortFlag=true;
				var idx:int=_effects.indexOf(ani);
				if (idx == -1)
				{
					_effects.push(ani);
				}
			}
		}

		/**
		 * 场景移除特效
		 *
		 */
		public function removeEffect(iani:IAnimation):void
		{
			var ani:E2DAnimation=iani as E2DAnimation;
			if (!ani)
				return;
			var idx:int=_effects.indexOf(ani);
			if (idx != -1)
			{
				_effects.splice(idx, 1);
			}
			E2DAnimation.free(ani);
			iani=null;
		}

		/**
		 * 插入avatar
		 *
		 */
		public function addCharacter(isceneChar:ISceneCharacter):void
		{
			var sceneChar:E2DSceneCharacter=isceneChar as E2DSceneCharacter;
			if (!sceneChar)
			{
				return;
			}
			sceneChar.onAddToDisplay();
			if (!sceneChar.isMainPlayer)
			{
				(sceneChar.avatar as SpriteContainer).mouseChildren=true;
				(sceneChar.avatar as SpriteContainer).mouseEnabled=true;
				(sceneChar.avatar as SpriteContainer).addEventListener(MouseEvent.MOUSE_DOWN, onAvatarTouch);
			}
			_avatarLayer.addChild(sceneChar.avatar as SpriteContainer);
			if (_characters.indexOf(sceneChar) == -1)
			{
				_characters.push(sceneChar);
			}
		}

		/**
		 * 移除avatar
		 *
		 */
		public function removeCharacter(isceneChar:ISceneCharacter):void
		{
			var sceneChar:E2DSceneCharacter=isceneChar as E2DSceneCharacter;
			if (!sceneChar || !sceneChar.usable)
			{
				return;
			}
			var idx:int=_characters.indexOf(sceneChar);
			if (idx != -1)
			{
				_characters.splice(idx, 1);
			}
			(sceneChar.avatar as SpriteContainer).removeEventListener(MouseEvent.CLICK, onAvatarTouch);
			sceneChar.dispose();
		}

		/**
		 * 移除所以avatar
		 *
		 */
		public function removeAllSceneCharacter():void
		{
			var avatar:Object;
			while (_avatarLayer.numChildren)
			{
				avatar=_avatarLayer.removeChildAt(0, true) as Object;
				if (avatar)
				{
					removeCharacter(avatar.sc);
				}
			}
		}

		/**
		 * 释放
		 */
		override public function dispose():void
		{
			clear();
			if (textMgr)
			{
				textMgr.dispose();
				textMgr=null;
			}
			if (unitTalkTextMgr)
			{
				unitTalkTextMgr.dispose();
				unitTalkTextMgr=null;
			}
			_camera=null;
			if (_bottomMapPartLayer)
			{
				_bottomMapPartLayer.removeFromParent(true);
				_bottomMapPartLayer=null;
			}
			if (_bottomEffectLayer)
			{
				_bottomEffectLayer.removeFromParent(true);
				_bottomEffectLayer=null;
			}
			if (_avatarLayer)
			{
				_avatarLayer.removeFromParent(true);
				_avatarLayer=null;
			}
			if (_topEffectLayer)
			{
				_topEffectLayer.removeFromParent(true);
				_topEffectLayer=null;
			}
			_mainChar=null;
			TAstar.mapModel=null;
			super.dispose();
		}


		/**
		 * 清理地图相关
		 *
		 */
		protected function clearMapSurface():void
		{
			_camera.follow(null);
			_mainChar=null;
			//地图层
			_bottomMapPartLayer.clear();
		}

		/**
		 * 切换地图的时候会使用
		 *
		 */
		public function clear():void
		{
			clearMouse();
			stopRender();
			//加载器清理
			if (_mapLoader)
			{
				_mapLoader.clear();
				_mapLoader=null;
				_isLoading=false;
			}
			//清理地图地表相关
			clearMapSurface();
			//底层特效  Animation
			var effect:E2DAnimation;
			while (_bottomEffectLayer.numChildren)
			{
				effect=_bottomEffectLayer.removeChildAt(0) as E2DAnimation;
				E2DAnimation.free(effect);
				effect=null;
			}
			//顶层特效  Animation
			while (_topEffectLayer.numChildren)
			{
				effect=_topEffectLayer.removeChildAt(0) as E2DAnimation;
				E2DAnimation.free(effect);
				effect=null;
			}
			//名字
			textMgr.clear();
			//说话
			unitTalkTextMgr.clear();
		}

		///////////////////////////////////////事件///////////////////////////////////////////////////////////
		protected var _signal:SceneSignal=null;

		public function get signal():SceneSignal
		{
			return _signal||=new SceneSignal();
		}

		/**
		 * 显示场景鼠标点击光效
		 *
		 */
		public function showMouseChar(targetP:Point, isBlock:Boolean=false, isShowTag:Boolean=false):void
		{
		}

		/**
		 * 清除鼠标
		 *
		 */
		public function clearMouse():void
		{
		}


		public function get lock():Boolean
		{
			return false;
		}

		public function set lock(value:Boolean):void
		{
		}

		public function onStopRun():void
		{
		}

		public function gray(isGray:Boolean):void
		{
		}

		public function optizimeCharType(type:Class, isEnabled:Boolean):void
		{
		}

		public function get thumbBitmapData():BitmapData
		{
			return mapLoader.smBitmap.bitmapData;
		}

		protected var _tileHeight:int=24;

		public function get tileHeight():int
		{
			return _tileHeight;
		}

		protected var _tileWidth:int=48;

		public function get tileWidth():int
		{
			return _tileWidth;

		}

		protected var _partHeight:int=512;

		public function get partHeight():int
		{
			return _partHeight;
		}

		protected var _partWidth:int=512;

		public function get partWidth():int
		{
			return _partWidth;
		}

		public function setView(width:int, height:int):void
		{
			_camera.setView(width, height);
		}

//		public function get bubbleLayer():flash.display.Sprite
//		{
//			return _bubbleLayer;
//		}

		/**
		 * 停止驱动
		 *
		 */
		public function stopRender():void
		{
			FrameManager.remove(run);
		}

		/**
		 * 开始驱动
		 *
		 */
		public function startRender():void
		{
			FrameManager.add(run);
		}

		public function get hudLayer():*
		{
			return _hudLayer;
		}

		/**
		 * 创建特效
		 * @param effectId
		 * @param px
		 * @param py
		 * @param packId
		 * @param dir
		 * @return
		 *
		 */
		public function createAnimation(effectId:String, px:int, py:int, packId:String=null, dir:int=-1):IAnimation
		{
			var ani:E2DAnimation=new E2DAnimation();
			ani.init(packId, effectId);
			ani.setPosition(px, py);
			ani.dir=dir;
			return ani;
		}

		/**
		 * 释放特效
		 * @param ianimation
		 *
		 */
		public function freeAnimation(ianimation:IAnimation):void
		{
			E2DAnimation.free(ianimation as E2DAnimation);
		}

		public function enableWeather(value:Boolean):void
		{
			// TODO Auto Generated method stub

		}

		public function get flyTextTagger():IFlyTextTagger
		{
			// TODO Auto Generated method stub
			return null;
		}

		/**当前鼠标像素点*/
		protected var _curMouse:Point=new Point();

		public function get curMouse():Point
		{
			_curMouse.x=camera.rect.x + App.stage.mouseX;
			_curMouse.y=camera.rect.y + App.stage.mouseY;
			return _curMouse;
		}
	}
}
