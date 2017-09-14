package tempest.engine
{
    import common.SceneCache;
    import common.enum.FilterEnum;

    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import tempest.TPEngine;
    import tempest.core.IAnimation;
    import tempest.core.ICamera;
    import tempest.core.IFlyTextTagger;
    import tempest.core.IMagicScene;
    import tempest.core.ISceneCharacter;
    import tempest.data.map.MapConfig;
    import tempest.data.obj.GuidObject;
    import tempest.data.obj.GuidObjectTable;
    import tempest.engine.graphics.animation.Animation;
    import tempest.engine.graphics.layer.AvatarLayer;
    import tempest.engine.graphics.layer.EffectLayer;
    import tempest.engine.graphics.layer.InteractiveLayer;
    import tempest.engine.graphics.layer.MapLayer;
    import tempest.engine.graphics.loader.MapLoader;
    import tempest.enum.AnimationType;
    import tempest.signals.SceneSignal;

    /**
	 * 场景类
	 * @author
	 */
	public class TScene implements IMagicScene
	{
		/**场景容器*/
		public var container:Sprite;
		/**地图层*/
		public var mapLayer:MapLayer;
		/**背景效果层*/
		public var bgEffectLayer:EffectLayer;
		/**角色层*/
		public var avatarLayer:AvatarLayer;
		/**地效层*/
		public var earthLayer:EffectLayer;
		/**前景效果层*/
		public var fgEffectLayer:EffectLayer;
		/**交互层*/
		private var _interactiveLayer:InteractiveLayer;
		/**地图信息*/
		private var _mapData:MapConfig;
		/**场景对象数据*/
		private var _sceneObjData:GuidObjectTable;
		/**飘字管理*/
		private var _flyTextTagger:IFlyTextTagger=null;
		/**摄像机*/
		public var _sceneCamera:TCamera;
		/**鼠标点击特效id*/
		public var mouseCharId:String="20000";
		private var _mouseOnChar:SceneCharacter=null;

		/**鼠标on*/
		public function get mouseOnChar():ISceneCharacter
		{
			return _mouseOnChar;
		}

		/**地图数据*/
		public var data:Object=null;
		/**地图id*/
		private var _id:int=-1;
		/**是否虚拟场景*/
		public var is_virTual:Boolean=false;
		/**虚拟场景是否跟随,默认为false**/
		public var virTualIsFollow:Boolean=false;
		/**是否可用*/
		private var _runAble:Boolean=true;
		/**场景加载成功回调*/
		private var onComplete:Function;
		protected var _selectChar:ISceneCharacter;

		/**当前选中对象*/
		public function get selectChar():ISceneCharacter
		{
			return _selectChar;
		}

		public function set selectChar(value:ISceneCharacter):void
		{
			_selectChar=value;
		}

		protected var _mainChar:ISceneCharacter;

		/**/
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

		/**当前鼠标像素点*/
		protected var _curMouse:Point=new Point();

		/**
		 * 获取鼠标当前坐标
		 * @return
		 *
		 */
		public function get curMouse():Point
		{
			_curMouse.x=camera.rect.x + App.stage.mouseX;
			_curMouse.y=camera.rect.y + App.stage.mouseY;
			return _curMouse;
		}

		/**
		 * 创建场景对象
		 * @param type
		 * @return
		 *
		 */
		public function createCharacter(type:int):ISceneCharacter
		{
			var char:ISceneCharacter=new SceneCharacter(type, this);
			addCharacter(char);
			return char;
		}


		/**
		 * 场景类
		 * @param optimizeCd 自动回收资源间隔
		 *
		 */
		public function TScene(sceneType:int, stage:Stage, dataTable:GuidObjectTable, flyTextTagger:IFlyTextTagger)
		{
			super();
			_flyTextTagger=flyTextTagger;
			_flyTextTagger.scene=this;
			if (stage)
			{
				stage.addEventListener(Event.RESIZE, onResize);
			}
			this.addChildren();
			this._sceneObjData=dataTable;
		}

		/**地图id*/
		public function get id():int
		{
			return _id;
		}

		/**
		 * @private
		 */
		public function set id(value:int):void
		{
			_id=value;
		}

		/**交互层*/
		public function get interactiveLayer():InteractiveLayer
		{
			return _interactiveLayer;
		}

		/**
		 * @private
		 */
		public function set interactiveLayer(value:InteractiveLayer):void
		{
			_interactiveLayer=value;
		}

		/**场景对象数据*/
		public function get objData():GuidObjectTable
		{
			return _sceneObjData;
		}

		/**地图配置*/
		public function get mapConfig():MapConfig
		{
			return _mapData;
		}

		/**飘字管理*/
		public function get flyTextTagger():IFlyTextTagger
		{
			return _flyTextTagger;
		}

		/**
		 * @private
		 */
		public function set mapData(value:MapConfig):void
		{
			_mapData=value;
		}

		/**
		 * 创建层
		 *
		 */
		protected function addChildren():void
		{
			container=new Sprite();
			this.mapLayer=new MapLayer(this);
			container.addChild(mapLayer);
			this.bgEffectLayer=new EffectLayer();
			container.addChild(bgEffectLayer);
			this.avatarLayer=new AvatarLayer();
			container.addChild(avatarLayer);
			this.earthLayer=new EffectLayer();
			container.addChild(earthLayer);
			this.fgEffectLayer=new EffectLayer();
			container.addChild(fgEffectLayer);
			this.interactiveLayer=new InteractiveLayer(this);
			container.addChild(interactiveLayer);
			this._sceneCamera=new TCamera(this.container);
		}

		public function enableInteractive():void
		{
			this.interactiveLayer.enableInteractive();
		}

		public function disableInteractive():void
		{
			this.interactiveLayer.disableInteractive();
		}

		/**
		 * 加载地图素材及逻辑数据
		 * @param newMapid
		 * @param onComplete
		 * @param virTual 是否虚拟场景
		 */
		public function load(newMapid:uint, rect:Rectangle, onComplete:Function, virTual:Boolean=false):void
		{
			this.id=newMapid;
			//发出场景切换事件
			this.disableInteractive();
			this._runAble=false;
			stopRender();
			this.clear();
			this.onComplete=onComplete;
			this.is_virTual=virTual; //是否虚拟场景
			MapLoader.loadMapConfig(newMapid, "", this, is_virTual ? onVirTualComplete : onSceneComplete);
		}

		/**
		 * 场景加载完毕回调
		 * @param mapConfig
		 *
		 */
		protected function onSceneComplete(mapConfig:MapConfig):void
		{
			this._mapData=mapConfig;
			MapLoader.loadSmallMap(this);
			camera.setBounds(mapConfig.pxWidth, mapConfig.pxHeight);
			interactiveLayer.setActiveArea(mapConfig.pxWidth, mapConfig.pxHeight);
			this._runAble=true;
			startRender();
			enableInteractive();
			if (onComplete != null)
			{
				onComplete();
			}
		}

		/**
		 * 加载虚拟场景完毕
		 * @param mapConfig
		 *
		 */
		protected function onVirTualComplete(mapConfig:MapConfig):void
		{
			this._mapData=mapConfig;
			camera.setBounds(mapConfig.pxWidth, mapConfig.pxHeight);
			this._runAble=true;
			startRender();
			if (onComplete != null)
			{
				onComplete();
			}
		}

		/**
		 * 舞台大小改变
		 * @param e
		 *
		 */
		protected function onResize(e:Event):void
		{
			setWH(App.stage.stageWidth, App.stage.stageHeight);
		}

		/**
		 * 获取鼠标当前碰撞的场景对象
		 * @param mouseX
		 * @param mouseY
		 * @return
		 *
		 */
		public function getMouseHit(mouseX:Number, mouseY:Number):SceneCharacter
		{
			var hitElements:Array=getObjectsUnderPoint(mouseX, mouseY);
			hitElements.sortOn("sortScore", Array.NUMERIC);
			return hitElements.pop();
		}

		/**
		 * 获取当前鼠标位置下的对象
		 * @param mouseX
		 * @param mouseY
		 * @return
		 *
		 */
		public function getObjectsUnderPoint(mouseX:Number, mouseY:Number):Array
		{
			var tempArr:Array=[];
			var element:SceneCharacter;
			var i:int;
			var len:int=avatarLayer.numChildren;
			for (; i != len; ++i)
			{
				element=avatarLayer.getChildAt(i) as SceneCharacter;
				if (element && element.isMouseHit)
				{
					tempArr.push(element);
				}
			}
			return tempArr;
		}

		/**
		 * 渲染场景对象
		 * @param nowTime
		 * @param diff
		 *
		 */
		public function run(nowTime:int, diff:int):void
		{
			if (!_runAble)
			{
				return;
			}
			if (!is_virTual) //虚拟场景不渲染地图
			{
				mapLayer.run(nowTime, diff);
			}
			camera.run(nowTime, diff);
			avatarLayer.run(nowTime, diff);
		}

		/**
		 * 渲染停止时执行
		 *
		 */
		public function onStopRun():void
		{
		}

		/**
		 * 插入avatar
		 * @param avatar
		 *
		 */
		public function addCharacter(sceneChar:ISceneCharacter):void
		{
			var sc:SceneCharacter=sceneChar as SceneCharacter;
			if (!sc || !sc.usable)
			{
				return;
			}
			sc.visible=sc.isMainPlayer;
			avatarLayer.addCharacter(sc);
		}

		/**
		 * 移除avatar
		 * @param avatar
		 *
		 */
		public function removeCharacter(sceneChar:ISceneCharacter):void
		{
			var char:SceneCharacter=sceneChar as SceneCharacter;
			if (!char || !char.usable)
			{
				return;
			}
			avatarLayer.removeCharacter(char);
			char.dispose();
		}

		/**
		 *某点是否在视野中
		 * @param point
		 * @return
		 *
		 */
		public function sightContains(point:Point):Boolean
		{
			return this.camera.rect.contains(point.x, point.y);
		}

		/**
		 * 添加场景特效
		 * @param ani 动画
		 * @param fg 是否前景
		 */
		public function addEffect(iani:IAnimation, isBottom:Boolean=false):void
		{
			var ani:Animation=iani as Animation;
			if (!ani || !ani.config)
			{
				return;
			}
			if (isBottom || (ani.config.around_place & 2))
			{
				this.bgEffectLayer.addEffect(ani.body);
			}
			else
			{
				this.fgEffectLayer.addEffect(ani.body);
			}
		}

		/**
		 *添加地效
		 * @param displayObj
		 *
		 */
		public function addEarthEffect(ani:Animation):void
		{
			if (ani)
			{
				this.earthLayer.addChild(ani.body);
			}
		}

		/**
		 *移除地效
		 *
		 */
		public function removeEarthEffect(displayObj:DisplayObject):void
		{
			if (displayObj)
			{
				this.earthLayer.removeChild(displayObj);
			}
		}

		/**
		 * 移除场景特效
		 * @param ani 动画
		 */
		public function removeEffect(iani:IAnimation):void
		{
			if (!iani)
			{
				return;
			}
			Animation.free(iani as Animation);
			iani=null;
		}

		/**
		 *显示鼠标点击效果
		 * @param tileP
		 * @param error
		 *
		 */
		public function showMouseChar(tileP:Point, error:Boolean=false, isShowTag:Boolean=false):void
		{
			if (is_virTual)
			{
				return;
			}
			var mouseChar:Animation=Animation.createAnimation(mouseCharId);
			mouseChar.type=AnimationType.OnceTODispose;
			if (error)
			{
				mouseChar.filters=[FilterEnum.redFilter];
			}
			var p:Point=mapConfig.Tile2Pixel(tileP);
			mouseChar.setPosition(p.x, p.y);
			this.addEffect(mouseChar);
		}


		/**
		 * 清除鼠标
		 *
		 */
		public function clearMouse():void
		{

		}

		/**
		 * 清理场景
		 *
		 */
		public function dispose():void
		{
			this.mapLayer.dispose();
			this.bgEffectLayer.dispose();
			this.avatarLayer.dispose();
			this.earthLayer.dispose();
			this.fgEffectLayer.dispose();
			//切换场景强制回收(忽略时间命中)
			SceneCache.optimizeAllAvatar(true);
			SceneCache.optimizeAllAnimation(true);
			objData.dispose();
		}

		/**
		 * 初始化场景皮肤
		 *
		 */
		public function initTexture(sceneTextureAtlas:*):void
		{

		}


		/********************************************辅助类****************************************************/
		/**
		 * 屏幕震动
		 * @param duration 持续时间 单位:秒
		 * @param intensity 强度
		 */
		public function shake(duration:uint=300, offset:int=6):void
		{
			this.camera.shake(duration, offset);
		}

		/**
		 * 设置场景可视区域
		 * @param w
		 * @param h
		 *
		 */
		public function setWH(w:Number, h:Number):void
		{
			this.camera.setView(w, h);
		}
		///////////////////////////////////////事件///////////////////////////////////////////////////////////
		private var _signal:SceneSignal=null;

		public function get signal():SceneSignal
		{
			return _signal||=new SceneSignal();
		}
		private var _visible:Boolean;

		public function get visible():Boolean
		{
			return _visible;
		}

		/**场景是否可见*/
		public function set visible(value:Boolean):void
		{
			_visible=value;
			container.visible=value;
		}

		public function get camera():ICamera
		{
			return _sceneCamera;
		}

		public function gray(isGray:Boolean):void
		{
			// TODO Auto Generated method stub

		}

		public function optizimeCharType(type:Class, isEnabled:Boolean):void
		{
			// TODO Auto Generated method stub

		}

		public function clear():void
		{
			_mapData=null;
			_thumbBitmapData=null;
			this.mapLayer.dispose();
			this.bgEffectLayer.dispose();
			this.avatarLayer.dispose();
			this.earthLayer.dispose();
			this.fgEffectLayer.dispose();
			//切换场景强制回收(忽略时间命中)
			SceneCache.optimizeAllAvatar(true);
			SceneCache.optimizeAllAnimation(true);
			for each (var guidobj:GuidObject in objData.objs)
			{
				objData.ReleaseObject(guidobj);
			}
		}
		private var _thumbBitmapData:BitmapData;

		public function get thumbBitmapData():BitmapData
		{
			return _thumbBitmapData;
		}

		public function set thumbBitmapData(value:BitmapData):void
		{
			_thumbBitmapData=value;
		}

		public function enableWeather(value:Boolean):void
		{
			// TODO Auto Generated method stub

		}

		private var _partHeight:int=200;

		public function get partHeight():int
		{
			return mapConfig ? mapConfig.sliceHeight : _partHeight;
		}

		private var _partWidth:int=200;

		public function get partWidth():int
		{
			return mapConfig ? mapConfig.sliceWidth : _partWidth;
		}

		private var _tileHeight:int=24;

		public function get tileHeight():int
		{
			return mapConfig ? mapConfig.tileHeight : _tileHeight;
		}

		private var _tileWidth:int=48;

		public function get tileWidth():int
		{
			return mapConfig ? mapConfig.tileWidth : _tileWidth;
		}


		public function setView(width:int, height:int):void
		{
		}

		/**
		 * 停止驱动
		 *
		 */
		public function stopRender():void
		{
			TPEngine.sceneRender.removeIRunableRender(this);
		}

		/**
		 * 开始驱动
		 *
		 */
		public function startRender():void
		{
			TPEngine.sceneRender.addIRunableRender(this);
		}

		public function get hudLayer():*
		{
			return null;
		}

		/**
		 * 创建场景特效
		 * @param effectId
		 * @param px
		 * @param py
		 * @param packId
		 * @return
		 *
		 */
		public function createAnimation(effectId:String, px:int, py:int, packId:String=null, dir:int=-1):IAnimation
		{
			if (dir != -1) //过程面向
			{
				effectId=dir + "_" + effectId;
			}
			return Animation.createAnimation(effectId, px, py);
		}

		public function freeAnimation(ianimation:IAnimation):void
		{
			Animation.free(ianimation as Animation);
		}

	}
}
