package game.scene
{
    import flash.geom.Point;
    import flash.utils.getTimer;

    import game.world.entity.base.controller.Entity;
    import game.world.entity.base.controller.UpdateEntityProcess;

    import game.world.entity.base.model.EntityModel;

    import tempest.core.IAnimation;
    import tempest.core.IAvatar;
    import tempest.core.IMagicScene;
    import tempest.core.ISceneCharacter;
    import tempest.data.find.PathCutter;
    import tempest.data.find.TAstar;
    import tempest.data.map.JumpPoint;
    import tempest.data.map.MapConfig;
    import tempest.data.map.WorldPostion;
    import tempest.enum.AvatarPartType;
    import tempest.enum.Status;
    import tempest.signals.SceneAction_Walk;
    import tempest.template.ActionConfig;
    import tempest.utils.Geom;

    /**
	 * starling场景角色对象（本身非显示对象，是一个包含了显示对象的数据对象）
	 * @author zhangyong
	 *
	 */
	public class E2DSceneCharacter implements ISceneCharacter
	{
		/**名字*/
		public static const NAME:String="name";
		public static var TALK:String="talk";
		public static var BUBBLE:String="bubble";
		public static const BAR_NAME:String="bar";
		public static const SHENJIA:String="shenjia";
		public static const FEIDAN:String="feidan";
		public static const FEIDAN_DJS:String="feidanDJS";
		public static const ZHANLIPIN:String="zhanlipin";
		/**纹理路径*/
		public static var binPath:String="model/bins/";
		/**特效纹理路径*/
		public static const direffect:String="animations/";
		/**模型路径*/
		public static const diravatar:String="avatars/";

		/**气泡*/
//		protected var _bubble:Bubble;
		public var filterLock:Boolean;
		/**血条*/
//		public var hpBar:SHpBar;
		/**对象id*/
		private var _id:uint;
		/**是否为主玩家*/
		private var _isMainPlayer:Boolean=false;
		private var _isShowBar:Boolean=false;
		private var _isShowName:Boolean=true;

		public var guid:String;
		/**是否显示名字*/
		public function get isShowName():Boolean
		{
			return _isShowName;
		}

		/**
		 * @private
		 */
		public function set isShowName(value:Boolean):void
		{
			_isShowName=value;
		}

		/***/
		private var _iShowNum:Boolean=true;

		/**是否在安全区，默认为不在安全区*/
		private var _isInSafeArea:Boolean=false;
		/**击退*/
		private var _hitDistance:int;
		/**logo布局失效*/
		private var _invalidLogoLayout:Boolean=false;
		/**是否显示头顶*/
		private var _isShowLogos:Boolean=false;

		/**是否显示血条*/
		public function get isShowBar():Boolean
		{
			return _isShowBar;
		}

		/**是否显示血条*/
		public function set isShowBar(value:Boolean):void
		{
			_isShowBar=value;
		}

		/**是否显示血量数字*/
		public function get iShowNum():Boolean
		{
			return _iShowNum;
		}

		/**是否显示头顶称号*/
		public function get isShowLogos():Boolean
		{
			return _isShowLogos;
		}

		/**是否显示头顶称号*/
		public function set isShowLogos(value:Boolean):void
		{
			_isShowLogos=value;
		}

		/**
		 * @private
		 */
		public function set iShowNum(value:Boolean):void
		{
			_iShowNum=value;
//			if (hpBar)
//			{
//				hpBar.showNum=value;
//				hpBar.resetNum();
//			}
		}

		/**击退累计距离*/
		public function get hitDistance():int
		{
			return _hitDistance;
		}

		/**
		 * @private
		 */
		public function set hitDistance(value:int):void
		{
			_hitDistance=value;
		}
		/**是否可以用，不可用说明被释放了*/
		private var _usable:Boolean=true;

		public function get usable():Boolean
		{
			return _usable;
		}

		public function set usable(value:Boolean):void
		{
			_usable=value;
		}

		/**排序偏移*/
		private var _sortOffset:int;

		public function get sortOffset():int
		{
			return _sortOffset;
		}

		public function set sortOffset(value:int):void
		{
			_sortOffset=value;
			_postionMoveFlag=true;
		}

		/**
		 * 当对象被加入到视图显示的时候触发
		 *
		 */
		public function onAddToDisplay():void
		{
			_postionMoveFlag=true;
		}

		protected var _avatar:TempAvatar;
		public var type:int;

		public function E2DSceneCharacter(type:int, scene:IMagicScene /*,cls:TPE*/)
		{
			this.type=type;
			this.scene=scene as E2DScene;
			_wpos=new WorldPostion(scene.tileWidth, scene.tileHeight);
			_avatar=new TempAvatar();
			_avatar.sc=this;
			visible=true;
//			logos=[];
		}
		////////////////////////////////////////////
		private var _scene:E2DScene;

		/**场景对象*/
		public function get scene():IMagicScene
		{
			return _scene;
		}

		/**
		 * @private
		 */
		public function set scene(value:IMagicScene):void
		{
			_scene=value as E2DScene;
		}
		/**
		 * 位置坐标
		 */
		private var _wpos:WorldPostion;
		private var _walkSpeed:int=135;

		public function get walkSpeed():int
		{
			return _walkSpeed;
		}

		public function set walkSpeed(value:int):void
		{
			_walkSpeed=value;
		}

		public function get walkPath():Array
		{
			return _walkPath;
		}
		private var _walkPath:Array=null;
		private var _walk_standDis:int=0;
		private var _walk_pathCutter:PathCutter;
		private var _walk_targetP:Point=null;
		private var _walk_fixP:Point=null;
		private var _walk_arrived:Function;

		/**
		 * 距离终点距离
		 * @return
		 *
		 */
		public function get fromEndPDis():Number
		{
			return _walk_targetP ? Point.distance(wpos.tile, _walk_targetP) : 0;
		}

		/**
		 * 是否目标点未变化
		 * @param targetP
		 * @param standDis
		 * @param speed
		 * @return
		 */
		public function isChanged(targetP:Point, standDis:int, speed:Number):Boolean
		{
			if (_walkPath == null || !_walkPath.length || !_walk_targetP)
			{
				return true;
			}
			if (_walk_standDis != standDis)
			{
				return true;
			}
			if (speed >= 0 && speed != _walkSpeed)
			{
				return true;
			}
			var isSamePlace:Boolean=(_walk_targetP.x >> 0) != (targetP.x >> 0) || (_walk_targetP.y >> 0) != (targetP.y >> 0);
			return isSamePlace;
		}

		public function inDistance(point:Point, distance:int):Boolean
		{
			return wpos.getDistance(point.x, point.y) <= distance;
		}
		/**
		 * 评估分数
		 * 规划		数字越大|  反向
		 *  预留  地表 死亡 | y*10  x*10
		 *  8bit  1bit 1bit |14bit  7bit
		 */
		public var sortScore:uint;
		/**处于透明层*/
		public var atTranLayer:Boolean=false;
		/**位置是否发生改变*/
		private var _postionMoveFlag:Boolean;

		public function set invalidLogoLayout(value:Boolean):void
		{
			_invalidLogoLayout=value;
		}

		/**
		 * 设置位置
		 */
		public function setPostion(x:Number, y:Number):void
		{
			wpos.tileX=x;
			wpos.tileY=y;
			_postionMoveFlag=true;
		}

		public function get status():int
		{
			return _avatar.status;
		}
		private var preDiff:int;
		private var preDiff2:int;

		public function runWalk(diff:int):void
		{
			var currentStatus:int=_avatar.status;
			//如果角色死亡 停止移动
			if (currentStatus == Status.DEAD)
			{
				clearWalk();
				return;
			}
			if (!scene.mapConfig)
			{
				return;
			}
			//没有路径点了
			if (!_walkPath || !_walkPath.length)
			{
				if (currentStatus == Status.WALK)
				{
					playTo(Status.STAND);
				}
				return;
			}
			var count:int=1;
			if (preDiff != 0)
			{
				count++;
			}
			if (preDiff2 != 0)
			{
				count++;
			}
			var dis_per_f:Number=((diff + preDiff + preDiff2) / count) / _walkSpeed;
			preDiff2=preDiff;
			preDiff=diff;
			stepDistance(dis_per_f);
			faceToTile(_currentTile);
			var oldX:Number=wpos.tileX;
			var oldY:Number=wpos.tileY;
			if (currentStatus != Status.WALK)
			{
				playTo(Status.WALK);
			}
			setPostion(_currentTile.x, _currentTile.y);
			var throughTile:Point;
			if (isMainPlayer)
			{
				var $isInSafe:Boolean=scene.mapConfig.isSafeArea(_currentTile.x, _currentTile.y);
				if (_isInSafeArea != $isInSafe)
				{
					_isInSafeArea=$isInSafe;
					scene.signal.isInSafeArea.dispatch($isInSafe);
				}
				if (oldX != _currentTile.x || oldY != _currentTile.y)
				{
					scene.signal.walk.dispatch(SceneAction_Walk.THROUGH, _currentTile);
				}
				for each (throughTile in _throughTileArr)
				{
					_walk_pathCutter.walkNext(throughTile.x, throughTile.y);
					if (_currentTile.x != throughTile.x || _currentTile.y != throughTile.y)
					{
						scene.signal.walk.dispatch(SceneAction_Walk.THROUGH, throughTile);
					}
				}
			}
			if (!_walkPath.length)
			{
				if (isMainPlayer)
				{
					scene.signal.walk.dispatch(SceneAction_Walk.ARRIVED, wpos.tile);
				}
				clearWalk();
			}
		}

		/**
		 * 清理移动数据
		 *
		 */
		public function clearWalk():void
		{
			if (_walk_arrived != null)
			{
				_walk_arrived(this);
				_walk_arrived=null;
			}
			if (isMainPlayer)
			{
				scene.clearMouse();
//				(scene as STScene).mapTagPartLayer.removeRoads();
			}
			preDiff=0;
			preDiff2=0;
			_walkPath=null;
			_walk_targetP=null;
			_walk_fixP=null;
			_walk_arrived=null;
			_walk_standDis=0;
			if (this._walk_pathCutter)
			{
				this._walk_pathCutter.clear();
			}
		}
		/**当前帧移动后的位置*/
		private var _currentTile:Point;
		/**当前行走经过的点*/
		private var _throughTileArr:Array=[];

		/**
		 * 步长计算
		 */
		private function stepDistance(ssf:Number):void
		{
			var targetTile:Point;
			var throughTile:Point;
			var dis:Number;
			_currentTile=wpos.tile.clone();
			_throughTileArr.length=0;
			var pathArr:Array=_walkPath;
			while (true)
			{
				targetTile=pathArr[0]; //(walkData.walk_fixP == null) ? SceneUtil.Tile2Pixel(pathArr[0]) : walkData.walk_fixP;
				dis=Point.distance(_currentTile, targetTile);
				if (dis > ssf) //不足以到达
				{
					_currentTile.x+=(targetTile.x - _currentTile.x) * ssf / dis;
					_currentTile.y+=(targetTile.y - _currentTile.y) * ssf / dis;
					return;
				}
				if (dis == ssf) //刚好到达目标点
				{
					_currentTile.x=targetTile.x;
					_currentTile.y=targetTile.y;
					return;
				}
				if (!_walk_fixP)
				{
					throughTile=pathArr.shift();
					_throughTileArr.push(throughTile);
				}
				else
				{
					_walk_fixP=null;
				}
				_currentTile.x=targetTile.x;
				_currentTile.y=targetTile.y;
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
		 */
		public function reviseMove(tx:int, ty:int):void
		{
			setPostion(tx, ty);
			if (isMainPlayer)
			{
				if (_walk_targetP && status == Status.WALK)
				{
					walk(_walk_targetP, -1, 0);
				}
			}
			else
			{
				clearWalk();
			}
		}

		/**
		 * 行走到指定地点
		 */
		public function walk(targetTile:Point, speed:Number=-1, standDis:int=0, onWalkArrived:Function=null, isShowTag:Boolean=false):void
		{
			if (!targetTile)
			{
				return;
			}
			var sceneMapData:MapConfig=scene.mapConfig;
			if (!sceneMapData || !TAstar.mapModel)
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
					faceToTile(targetTile);
				if (isMainPlayer)
				{
					scene.signal.walk.dispatch(SceneAction_Walk.ARRIVED, targetTile);
				}
				return;
			}
			//判断目标点是否合法
			if (isMainPlayer)
			{
				if (sceneMapData.isBlock(targetTile.x, targetTile.y))
				{
					scene.showMouseChar(targetTile, true);
					scene.signal.walk.dispatch(SceneAction_Walk.UNABLE, targetTile);
					return;
				}
			}
			//路径重复
			if (!isChanged(targetTile, standDis, speed))
			{
				trace("路径重复，忽略");
				return;
			}
			var path:Array;
			if (sceneMapData.hasBlockOnLine(wpos.tileX, wpos.tileY, targetTile.x, targetTile.y)) //如果两之间有障碍
			{
				if (sceneMapData.trunkPoints && sceneMapData.trunkPoints.length > 0)
				{
					path=sceneMapData.trukPath.find(wpos.tileX, wpos.tileY, targetTile.x, targetTile.y);
				}
				else
				{
					//干道寻路改变尝试次数，重新初始化回来
					TAstar.maxTry=15000;
					path=TAstar.find(sceneMapData, wpos.tileX, wpos.tileY, targetTile.x, targetTile.y);
				}
				if (standDis != 0) //站立距离截取
				{
					var len:int=path ? path.length : 0;
					var cutLen:int=Math.min(standDis, len - LEAST_PATH);
					if (cutLen > 0)
					{
						path.splice(len - cutLen, cutLen);
					}
				}
			}
			else
			{
				if (standDis != 0) //站立距离截取
				{
					var radian:Number=Geom.getTwoPointRadian(wpos.tile, targetTile);
					targetTile.x=targetTile.x + standDis * Math.cos(radian);
					targetTile.y=targetTile.y + standDis * Math.sin(radian);
				}
				path=[wpos.tile, targetTile];
			}
			if (isMainPlayer)
			{
				if (!path || path.length < LEAST_PATH) //未能搜索到有效路径
				{
					scene.showMouseChar(targetTile, true);
					scene.signal.walk.dispatch(SceneAction_Walk.UNABLE, targetTile);
					return;
				}
			}
			walk0(path, null, speed, standDis, onWalkArrived, isShowTag);
		}

		public function walk0(path:Array, targetTile:Point=null, speed:Number=-1, standDis:int=0, onWalkArrived:Function=null, isShowTag:Boolean=false):void
		{
			if (!scene.mapConfig)
			{
				return;
			}
			if (path.length < LEAST_PATH) //一段路径至少包含起点和终点
			{
				return;
			}
            if (guid)
                EntityModel.addMoveList(guid, path.slice(), -1, _walkSpeed);

			_hitDistance=0; //移动的时候把击退累计清除，因为服务器会矫正位置
			if (isMainPlayer) //主角发包处理
			{
				if (!_walk_pathCutter)
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
				_walk_targetP=targetTile;
			}
			else
			{
				targetP=path[path.length - 1].clone();
				_walk_targetP=targetP;
			}
			_walk_standDis=standDis;
			_walk_arrived=onWalkArrived;
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
				scene.showMouseChar(targetP, false, isShowTag);
				//主角发送移动开始事件
				scene.signal.walk.dispatch(SceneAction_Walk.READY, isShowTag);
			}
		}

		/**
		 * 视图心跳的更新
		 * @param diff
		 *
		 */
		public function onViewUpdate(diff:uint):void
		{
			onBeforeDraw();
			//发生渲染
			onDraw(diff);
		}

		protected function onBeforeDraw():void
		{
			if (isShowBar && _isShowLogos)
			{
//				if (hpBar)
//				{
//					hpBar.calculateValue();
//				}
			}
//			if (_warnShape)
//			{
//				_warnShape.x=wpos.pixelX - (_warnShape.width >> 1) - scene.camera.rect.x;
//				_warnShape.y=wpos.pixelY - (_warnShape.height >> 1) - scene.camera.rect.y;
//			}
		}

		/**
		 *
		 * @param diff
		 *
		 */
		public function onDraw(diff:uint):void
		{
			if (!usable)
			{
				return;
			}
			_avatar.x=_wpos.pixelX;
			_avatar.y=_wpos.pixelY;
			_avatar.direction=_wpos.toward;
//			_avatar.onDraw(diff);
//			_avatar.leaveShadow();
			//计算在相机中的位置
			avatar.x=wpos.pixelX - scene.camera.rect.x;
			avatar.y=wpos.pixelY - scene.camera.rect.y;
			///////////// 移动相关 ////////////////////
			runWalk(diff);
			if (_isShowLogos)
			{
				onDrawLogos(diff);
				if (_invalidLogoLayout) //布局管理
				{
					_invalidLogoLayout=false;
					logosLayout();
				}
			}
//			if (wpos.horizontalFlip)
//			{
//				if (avatar.scaleX > 0)
//				{
//					avatar.scaleX*=-1;
//				}
//			}
//			else if (avatar.scaleX < 0)
//			{
//				avatar.scaleX=Math.abs(avatar.scaleX);
//			}
			////////////排序
			if (_postionMoveFlag)
			{
				_postionMoveFlag=false;
				/////////////////// 深度排序评分 /////////////////
				//16位
				sortScore=wpos.pixelY + (isMainPlayer ? 1 : 0) + _sortOffset;
				//非掉落物品在上层
//				if (!_avatar.isDrop)
//				{
//					sortScore+=(1 << 17);
//				}
				//是否处于半透明层
				if (scene.mapConfig)
				{
					atTranLayer=scene.mapConfig.isMask(wpos.tileX, wpos.tileY);
					if (isMainPlayer) //是否处于跳跃点
					{
						var jp:JumpPoint=scene.mapConfig.isJump(wpos.tileX, wpos.tileY);
						if (jp && jp.targetPoint) //当前点是跳跃点
						{
							scene.signal.walk.dispatch(SceneAction_Walk.CROSSJUMP, jp);
						}
					}
				}
			}
		}

		/**logo图片，为了扁平化，提高性能，因此加在外部容器--有序，所以不用字典*/
//		public var logos:Array;

		/**
		 * logo重新布局
		 *
		 */
		protected function logosLayout():void
		{
//			logos.sortOn("type", Array.NUMERIC);
		}

		public function onDrawLogos(diff:uint):void
		{
//			var oani:OImageAni;
//			for each (var logo:DisplayObject in logos)
//			{
//				oani=logo as OImageAni;
//				if (oani)
//				{
//					oani.update(diff);
//				}
//			}
		}

		public function updateNameText(gropId:String, newName:String, sortId:int=0, newColor:uint=0xff0000):void
		{
			if (!gropId || !newName || !_usable)
			{
				return;
			}
//			if (gropId == BUBBLE)
//			{
//				_bubble||=new Bubble(_scene.bubbleLayer);
//				_bubble.show(newName, 5);
//				return;
//			}
//			if (!logos)
//			{
//				return;
//			}
//			var oTxt:OTextField=hasLogo(gropId) as OTextField;
//			//没有任何改变，则退出
//			if (oTxt && oTxt.data.text == newName && oTxt.data.color == newColor)
//			{
//				return;
//			}
			//先删掉以前的
			deleteLogo(gropId);
			//创建新的文本，并加入字段
//			switch (gropId)
//			{
//				case TALK:
//					oTxt=_scene.unitTalkTextMgr.createText(newName, newColor, true);
//					break;
//				default:
//					oTxt=_scene.textMgr.createText(newName, newColor, false);
//					break;
//			}
//			oTxt.name=gropId;
//			oTxt.type=sortId; //排序类型
//			logos.push(oTxt);
			_invalidLogoLayout=true;
		}
		public var sumBuffIconWidth:int;

		public function addImageLogo(group:String, id:String, isLeft:Boolean=false, isBody:Boolean=false, sortId:int=0, isNameLeft:Boolean=false, offsetX:int=0, offsetY:int=0, isBarLeft:Boolean=false):void
		{
			if (!group || !id)
			{
				return;
			}
//			if (!logos)
//			{
//				return;
//			}
//			var oimage:OImage=hasLogo(group) as OImage; //没有任何改变，则退出
//			if (oimage)
//			{
//				return;
//			}
//			var texture:Texture=_scene.sceneTextureAtlas.textureAtlas.getTexture(id + ".png");
//			if (!texture)
//			{
//				trace(id, "贴图不存在");
//				return;
//			}
//			oimage=new OImage(id, _scene);
//			oimage.name=group;
//			oimage.type+=sortId;
//			oimage.isLeft=isLeft;
//			oimage.isBody=isBody;
//			oimage.isNameLeft=isNameLeft;
//			oimage.offsetX=offsetX;
//			oimage.offsetY=offsetY;
//			oimage.isBarLeft=isBarLeft;
//			if (isBody)
//			{
//				sumBuffIconWidth+=oimage.width;
//				if (sumBuffIconWidth > 400)
//				{
//					sumBuffIconWidth=400;
//				}
//			}
//			logos.push(oimage);
			_invalidLogoLayout=true;
		}

		public function addAniLogo(group:String, id:String, isLeft:Boolean=false, sortId:int=0):void
		{
//			if (!id.length)
//			{
//				return;
//			}
//			if (!logos)
//			{
//				return;
//			}
//			var oimageAni:OImageAni=hasLogo(group) as OImageAni;
//			if (oimageAni) //没有任何改变，则退出
//			{
//				return;
//			}
//			var textures:Vector.<Texture>=_scene.sceneTextureAtlas.textureAtlas.getTextures(id);
//			if (!textures)
//			{
//				trace(id, "贴图不存在");
//				return;
//			}
//			oimageAni=new OImageAni(_scene, id, 120);
//			oimageAni.name=group;
//			oimageAni.type=10;
//			oimageAni.type+=sortId;
//			oimageAni.isLeft=isLeft;
//			logos.push(oimageAni);
//			_invalidLogoLayout=true;
		}

		/**
		 * 添加身价显示
		 */
		public function addImageShenjia(rank:int, shengjia:String, sortId:int=5):void
		{
//			if (!logos)
//			{
//				return;
//			}
//			var shenjia:OImageShenjia=hasLogo(SHENJIA) as OImageShenjia;
//			if (shenjia)
//			{
//				shenjia.reset(rank, shengjia, _scene.sceneTextureAtlas.textureAtlas);
//			}
//			else
//			{
//				shenjia=new OImageShenjia(rank, shengjia, _scene.sceneTextureAtlas.textureAtlas);
//				logos.push(shenjia);
//			}
//			shenjia.name=SHENJIA;
//			shenjia.type+=sortId;
//			shenjia.y=-2;
			_invalidLogoLayout=true;
		}

		public function talk(talkText:String, maxWidth:int=140, talkDelay:int=3000, talkBgSkin:String="", sizeGrid:Array=null, TALKBULLUE_SPACE:int=4):void
		{
			clearTalk();
			App.timer.doOnce(talkDelay, clearTalk);
			updateNameText(TALK, talkText, 2, 0xffffff);
		}

		/**
		 * 清楚说话
		 *
		 */
		public function clearTalk():void
		{
			deleteLogo(TALK);
		}

		public function showBar(value:Boolean, isJingying:Boolean=false):void
		{
			if (!usable)
			{
				_isShowBar=false;
				return;
			}
			if (this.isShowBar == value)
			{
				return;
			}
			_isShowBar=value;
			if (value)
			{
//				if (!hpBar)
//				{
//					if (iShowNum) //玩家
//					{
//						hpBar=new SHpBar(data as IHealth, _scene, iShowNum);
//					}
//					else if (isJingying) //精英怪,boss
//					{
//						hpBar=new SHpJingying(data as IHealth, _scene, iShowNum);
//					}
//					else //怪物
//					{
//						hpBar=new SHpMonster(data as IHealth, _scene, iShowNum);
//					}
//					hpBar.name=BAR_NAME;
//					hpBar.type=-1;
//					setBarSkin(EmbedAssetDef.HP_UnitRed);
//					logos.push(hpBar);
//					hpBar.init();
//				}
			}
			else
			{
				deleteLogo(BAR_NAME, false);
			}
			_invalidLogoLayout=true;
		}

		/**
		 * 设置血条皮肤类型
		 *
		 */
		public function setBarSkin(barSkin:String):void
		{
//			var barbg:Texture;
//			var bareffect:Texture;
//			var bar:Texture;
//			var textureAtlas:TextureAtlas=_scene.sceneTextureAtlas.textureAtlas;
//			if (hpBar)
//			{
//				if (hpBar is SHpJingying)
//				{
//					barbg=textureAtlas.getTexture(EmbedAssetDef.HP_Jingying3);
//					bareffect=textureAtlas.getTexture(EmbedAssetDef.HP_Jingying1);
//					bar=textureAtlas.getTexture(EmbedAssetDef.HP_Jingying2);
//				}
//				else if (hpBar is SHpMonster)
//				{
//					barbg=textureAtlas.getTexture(EmbedAssetDef.HP_Monster1);
//					bareffect=textureAtlas.getTexture(EmbedAssetDef.HP_Monster3);
//					bar=textureAtlas.getTexture(EmbedAssetDef.HP_Monster2);
//				}
//				else
//				{
//					barbg=textureAtlas.getTexture(EmbedAssetDef.HP_Backgroud);
//					bareffect=textureAtlas.getTexture(EmbedAssetDef.HP_EffectProgress);
//					bar=textureAtlas.getTexture(barSkin);
//				}
//				hpBar.setSkin(barbg, bareffect, bar);
//			}
		}

		/**
		 * 是否包含称号
		 * @param name
		 * @return
		 *
		 */
		public function hasLogo(name:String):*
		{
//			for each (var logo:DisplayObject in logos)
//			{
//				if (!logo)
//				{
//					continue;
//				}
//				if (logo.name == name)
//				{
//					return logo;
//				}
//			}
			return null;
		}

		public function deleteLogo(group:String, dispose:Boolean=true):Boolean
		{
//			var ds:DisplayObject=hasLogo(group) as DisplayObject;
//			if (!ds)
//			{
//				return false;
//			}
//			ds.removeFromParent(dispose);
//			logos.splice(logos.indexOf(ds), 1);
//			if (group == BAR_NAME)
//			{
//				hpBar=null;
//			}
//			if (ds.hasOwnProperty("isBody") && ds["isBody"])
//			{
//				sumBuffIconWidth-=ds.width;
//				if (sumBuffIconWidth < 0)
//				{
//					sumBuffIconWidth=0;
//				}
//			}
			return true;
		}

		/**
		 * 删除所有图片称号
		 *
		 */
		public function deleteAllImageLogo(isHead:Boolean=true, isLeft:Boolean=false, isBody:Boolean=false, isNameLeft:Boolean=false):void
		{
//			var logo:OImage;
//			var len:int=logos.length;
//			var iter:int=0;
//			while (iter < len)
//			{
//				logo=logos[iter] as OImage;
//				if (logo) //头顶的动画和图片称号
//				{
//					if (!isLeft && logo.isLeft) //是否把左边的也删除了 队长，阵营什么的。
//					{
//						iter++;
//						continue;
//					}
//					if (!isBody && logo.isBody) //身体bufficon
//					{
//						iter++;
//						continue;
//					}
//					if (!isNameLeft && logo.isNameLeft) //名字左边图标
//					{
//						iter++;
//						continue;
//					}
//					if (!isHead && !logo.isBody && !logo.isLeft && !logo.isNameLeft) //头顶title
//					{
//						iter++;
//						continue;
//					}
//					if (deleteLogo(logo.name)) //icon删除成功
//					{
//						len--;
//					}
//					else
//					{
//						iter++;
//					}
//				}
//				else
//				{
//					iter++;
//				}
//				if (iter > 100) //防止死循环
//				{
//					break;
//				}
//			}
		}

		/**
		 * 以人物为中心点，转换到指定的点
		 * @param x 目标x
		 * @param y 目标y
		 */
		public function turnPoint(x:Number, y:Number):void
		{
			var ang:Number=wpos.getAngle(x, y);
			wpos.toward=ang;
		}

		/**
		 * 调整到面对指定的点
		 * @param x 目标x
		 * @param y 目标y
		 */
		public function turnReversePoint(x:Number, y:Number):void
		{
			var ang:Number=wpos.getAngle(x, y);
			ang=ang > Math.PI ? ang - Math.PI : ang + Math.PI;
			wpos.toward=ang;
		}

		public function turnWorldObject(avatarObject:E2DSceneCharacter):void
		{
			turnPoint(avatarObject.wpos.tileX, avatarObject.wpos.tileY);
		}
		/*目标对象*/
		protected var _targetObject:E2DSceneCharacter;

		/**
		 * 目标对象，只读。如需设置，请调用setTarget函数。
		 */
		public function get targetObject():E2DSceneCharacter
		{
			return _targetObject;
		}

		/**
		 * 调整到面对目标
		 */
		public function turnTargetObject():void
		{
			if (!_targetObject)
				return;
			turnWorldObject(_targetObject);
		}

		public function get bodyOffset():int
		{
			return (avatar && avatar.offsetInfo) ? avatar.offsetInfo.bodyOffset : 50;
		}

		public function get headOffset():int
		{
			return (avatar && avatar.offsetInfo) ? avatar.offsetInfo.headOffset : 120;
		}

		public function get wpos():WorldPostion
		{
			return _wpos;
		}
		private var _hit_lock:Boolean;
		private var _dead_lock:Boolean;

		public function set deadLock(value:Boolean):void
		{
			_dead_lock=value;
		}

		public function set hitLock(value:Boolean):void
		{
			_hit_lock=value;
		}

		public function get deadLock():Boolean
		{
			return _dead_lock;
		}

		public function get hitLock():Boolean
		{
			return _hit_lock;
		}

		public function get x():Number
		{
			return _wpos.pixelX;
		}

		public function set x(value:Number):void
		{
			_wpos.pixelX=value;
		}

		public function set y(value:Number):void
		{
			_wpos.pixelY=value;
		}

		public function get y():Number
		{
			return _wpos.pixelY;
		}

//		protected var _filter:BitmapFilter;

		/**
		 * 设置avatar滤镜
		 * @param type
		 *
		 */
		public function setAvatarFilter(type:int):void
		{
//			if (!Version.supportsRelaxedTargetClearRequirement)
//			{
//				return;
//			}
//			if (filterLock) //锁定后不可以更改滤镜了
//			{
//				return;
//			}
//			if (!usable || !avatar || !avatar.usable)
//			{
//				return;
//			}
//			switch (type)
//			{
//				case FilterEnum.FILTERWHITE:
//					_filter=FilterEnum.whiteFilter;
//					_avatar.setFilter(FilterEnum.swhiteFilter);
//					break;
//				case FilterEnum.FILTERRED:
//					_filter=FilterEnum.redFilter;
//					_avatar.setFilter(FilterEnum.sredFilter);
//					break;
//				case FilterEnum.FILTERGREEN:
//					_filter=FilterEnum.greenFilter;
//					_avatar.setFilter(FilterEnum.sgreenFilter);
//					break;
//				case FilterEnum.FILTERGOLDEN:
//					_filter=FilterEnum.goldenFilter;
//					_avatar.setFilter(FilterEnum.sgoldenFilter);
//					break;
//				case FilterEnum.FILTERBLUE:
//					_filter=FilterEnum.blueFilter;
//					_avatar.setFilter(FilterEnum.sblueFilter);
//					break;
//				case FilterEnum.FILTERNONE:
//					_filter=null;
//					_avatar.setFilter(null);
//					break;
//			}
		}

		public function getFilter():*
		{
			return null;
		}

		public function get isMainPlayer():Boolean
		{
			return _isMainPlayer;
		}

		public function set isMainPlayer(value:Boolean):void
		{
			_isMainPlayer=value;
			if (_avatar)
			{
				_avatar.mouseEnabled=false;
				_avatar.mouseChildren=false;
//				_avatar.alpha=1;
//				_avatar.fadeAlpha=1;
			}
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
			if (dir != -1)
			{
				wpos.toward=dir;
			}
			if (status == Status.DEAD)
			{
				filterLock=false;
			}
			_avatar.playTo(status, dir, apc, onEffectFrame, onCompleteFrame, resetFrame);
		}

		public function get id():uint
		{
			return _id;
		}

		public function set id(value:uint):void
		{
			_id=value;
		}

		public function set scaleX(value:Number):void
		{
			if (!usable || !avatar || !avatar.usable)
			{
				return;
			}
			_avatar.scaleX=value;
		}

		public function get scaleX():Number
		{
			return avatar.scaleX;
		}

		public function set scaleY(value:Number):void
		{
			if (!usable || !avatar || !avatar.usable)
			{
				return;
			}
			avatar.scaleY=value;
		}

		public function get scaleY():Number
		{
			return avatar.scaleY;
		}

		/**一组动作*/
		private var _actions:Array=[];
		/**关键帧回调*/
		private var _actionEffect:Function;
		/**动作索引*/
		private var _actionIndex:int;

		/**
		 * 播放多个动作
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
				App.timer.doFrameOnce(1, playTo, [currentAction, -1, null, onEffect, playAction]);
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
		private function onEffect():void
		{
			if (_actionEffect != null)
			{
				_actionEffect();
			}
		}

		public function startShowShadow(duration:Number):void
		{
		}

		public function stopShowShadow():void
		{
		}
		private var _selectEffect:E2DAnimation=null;

		/**
		 * 隐藏选中特效
		 */
		public function hideSelectEffect():void
		{
			if (_selectEffect)
			{
				E2DAnimation.free(this._selectEffect);
				this._selectEffect=null;
			}
		}

		/**
		 * 显示选中特效
		 */
		public function showSelectEffect(ani:IAnimation):void
		{
			var effect:E2DAnimation=ani as E2DAnimation;
			if (effect)
			{
				hideSelectEffect();
				addEffect(effect);
				this._selectEffect=effect;
			}
		}

		private var _effects:Object={};

		/**
		 * 添加光效
		 */
		public function addEffect(ani:IAnimation, isBottom:Boolean=false):void
		{
			if (!usable)
			{
				E2DAnimation.free(ani as E2DAnimation);
				ani=null;
				return;
			}
			var $ani:E2DAnimation=_effects[ani.id]; //先移除
			if ($ani)
			{
				removeEffect($ani);
			}
			var animate:E2DAnimation=(ani as E2DAnimation);
//			animate.anhorTarget=this;
			animate.onDispose=onEffectDispose;
			effects[animate.id]=animate;
			scene.addEffect(ani, isBottom);
		}

		/**角色身上的所有光效*/
		public function get effects():Object
		{
			return _effects;
		}

		/**
		 * 特效移除时回调
		 * @param ani
		 *
		 */
		private function onEffectDispose(ani:E2DAnimation):void
		{
			if (!ani)
			{
				return;
			}
			effects[ani.id]=null;
			delete effects[ani.id];
		}

		/**
		 * 移除光效
		 * @param ani
		 *
		 */
		public function removeEffect(ani:*):void
		{
			if (!ani)
			{
				return;
			}
			var animate:IAnimation=((ani as E2DAnimation) || effects[ani]);
			_scene.removeEffect(animate);
		}

		/**
		 * 移除所有光效
		 *
		 */
		public function removeAllEffect():void
		{
			for (var key:String in _effects)
			{
				removeEffect(key);
			}
		}

		private var _data:Object;

		public function get data():Object
		{
			return _data;
		}

		public function set data(value:Object):void
		{
			_data=value;
		}

		/**
		 * 面向格子坐标
		 * @param targetTile
		 * @param isNow
		 *
		 */
		public function faceToTile(targetTile:Point, isNow:Boolean=true):void
		{
			if (!targetTile)
			{
				return;
			}
			wpos.toward=wpos.getTileDir(targetTile.x, targetTile.y);
//			_avatar.updateNow=true;
		}

		/**
		 *  面向像素坐标
		 * @param targetPixcel
		 * @param isNow
		 *
		 */
		public function faceToPixcel(targetPixcel:Point, isNow:Boolean=true):void
		{
			if (!targetPixcel)
			{
				return;
			}
			wpos.toward=wpos.getPixelDir(targetPixcel.x, targetPixcel.y);
//			_avatar.updateNow=true;
		}
		/////////////////////////////////////////////////////////
		/////////////////////////////////////////////////////////
		///////////////////////跳跃//////////////////////////
		protected var _downMouting:int=0;
		protected var _upMouting:int=0;

		/**下坐骑中*/
		public function get downMouting():Boolean
		{
			if (_downMouting == 0)
				return false;
			if (_downMouting < getTimer())
			{
				_downMouting=0;
				return false;
			}
			return true;
		}

		/**上坐骑中*/
		public function get upMouting():Boolean
		{
			if (_upMouting == 0)
				return false;
			if (_upMouting < getTimer())
			{
				_upMouting=0;
				return false;
			}
			return true;
		}
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
		/**缩放跳跃速度(默认1)*/
		public var jumpScale:Number=1;
		private var duartion:Number=0;
		private var half:Number=0;
		/***高度*/
		private var offset:int=OFFSETCONST;
		private var _upObj:Object={y: 0};
		private var _downObj:Object={y: offset};
		private static const OFFSETCONST:int=-140;
		private static const OFFSETMOST:int=-220;
		private static const PIXEL_SPEED:Number=0.002;
		private static const HALF_PIXEL_SPEED:Number=0.001;
		private static const MONST_DURATION:Number=0.4;

		public function jumpBegin(hasBlock:Boolean):void
		{
			_jumpOffset=0;
			_isJumpping=true;
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
			if (avatar)
			{
//				_avatar.updateNow=true;
			}
		}

		/**
		 * 跳跃结束
		 *
		 */
		public function jumpEnd():void
		{
			jumpScale=1;
			offset=OFFSETCONST;
			_upObj.y=0;
			_downObj.y=offset;
			_jumpOffset=0;
			_isJumpping=false;
			isJumpAgain=false;
			if (avatar)
			{
//				_avatar.isJumpLeaveShadow=false;
			}
			if (jumpComplete != null)
			{
				jumpComplete();
				jumpComplete=null;
			}
			_postionMoveFlag=true;
		}
		/**跳跃完毕回调*/
		private var jumpComplete:Function;

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
				if (!targetPoint.equals(wpos.pixel))
				{
					faceToPixcel(targetPoint, false);
				}
				playTo(action);
//				_avatar.isJumpLeaveShadow=isLeaveShadow; //是否留下残影
				if (_isJumpping) //连跳
				{
					isJumpAgain=true;
//					Starling.juggler.removeTweens(_downObj);
//					Starling.juggler.removeTweens(_upObj);
//					Starling.juggler.removeTweens(wpos);
					_upObj.y=jumpOffset; //第二次上升起始高度
					offset=OFFSETCONST + jumpOffset; //第二次上升终点高度
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

		/**
		 * 开始跳跃
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
//			var tween:Tween=Juggler.instance.tween(_upObj, half, {y: offset}) as Tween;
//			tween.transition=Transitions.EASE_OUT;
//			tween.onUpdate=upChange;
//			tween.onComplete=upComplete;
//			Juggler.instance.tween(wpos, duartion, {pixelX: targetPoint.x, pixelY: targetPoint.y});
		}

		/**
		 * 下马
		 *
		 */
		public function downMount():void
		{
			var sc:int=1;
			if (wpos.toward < 5 && wpos.toward > 0)
			{
				wpos.toward=2;
			}
			else
			{
				wpos.toward=6;
				sc=-1;
			}
//			_avatar.updateNow=true;
			_downMouting=getTimer() + 2000;
			jump(6, wpos.pixel, downMountComplete); //原地跳
//			var moutPart:AvatarPart=avatar.getAvatarItem(AvatarPartType.MOUNT);
//			if (moutPart)
//			{
//				moutPart.coreImg.alpha=1;
//				Juggler.instance.tween(moutPart.coreImg, 1, {alpha: 0});
//				var p:Point=new Point();
//				var angle:Number=Geom.getRotationByOrient(wpos.toward) * Geom.RAD_RANGLE;
//				var cos:Number=Math.cos(angle);
//				var ox:int=cos * MOUNT_OFFSET * sc;
//				var tween:Tween=Juggler.instance.tween(moutPart, 0.8, {offsetX: ox}) as Tween;
//			}
		}

		/**
		 * 下马完毕
		 *
		 */
		private function downMountComplete():void
		{
			avatar.removeAvatarItem(AvatarPartType.MOUNT);
			_downMouting=0;
		}

		/**上面冲出去的偏移*/
		private static const MOUNT_OFFSET:int=900;

		/**
		 * 上马
		 *
		 */
		public function upMount():void
		{
			var sc:int=1;
			if (wpos.toward < 5 && wpos.toward > 0)
			{
				wpos.toward=2;
			}
			else
			{
				wpos.toward=6;
				sc=-1;
			}
//			_avatar.updateNow=true;
			_upMouting=getTimer() + 2000;
			jump(6, wpos.pixel, upMountComplete); //原地跳
//			var moutPart:AvatarPart=avatar.getAvatarItem(AvatarPartType.MOUNT);
//			if (moutPart)
//			{
//				moutPart.coreImg.alpha=0;
//				Juggler.instance.tween(moutPart.coreImg, 1, {alpha: 1});
//				var angle:Number=Geom.getRotationByOrient(wpos.toward) * Geom.RAD_RANGLE;
//				var cos:Number=Math.cos(angle);
//				moutPart.offsetX=-cos * MOUNT_OFFSET * sc;
//				Juggler.instance.tween(moutPart, 0.8, {offsetX: 0});
//			}

		}

		/**
		 * 上马完毕
		 *
		 */
		private function upMountComplete():void
		{
			_upMouting=0;
		}

		/**
		 * 向上完毕
		 */
		private function upComplete():void
		{
//			var tween:Tween=Juggler.instance.tween(_downObj, half, {y: 0}) as Tween;
//			tween.onUpdate=downChange;
//			tween.onComplete=downComplete;
//			tween.transition=Transitions.EASE_IN;
		}

		/**
		 *向上改变
		 */
		private function upChange():void
		{
			jumpProgress(_upObj.y, false);
		}

		/**
		 * 下降改变
		 */
		private function downChange():void
		{
			jumpProgress(_downObj.y, false);
		}

		/**
		 *下降完毕
		 */
		private function downComplete():void
		{
			jumpEnd();
			playTo(Status.STAND);
		}

		private var _visible:Boolean=true;

		public function set visible(value:Boolean):void
		{
			_visible=value;
			if (_avatar)
			{
				_avatar.visible=value;
			}
		}

		public function get visible():Boolean
		{
			return _visible;
		}

		public function get mountOffset():int
		{
			return 0;
//			return !_avatar.atMount ? 0 : -30 - _avatar.mountOffset;
		}

		///////////////////////warnshape///////////////
//		private var _warnShape:Image;

		/**
		 * 显示提示圈
		 * @param riadus
		 *
		 */
		public function showWarnShape(riadus:int=150):void
		{
			hideWarnShape(); //如果有，先隐藏
			//
//			var texture:Texture=(scene as STScene).sceneTextureAtlas.textureAtlas.getTexture("warn.png");
//			_warnShape=Pools.mallocImage(texture);
//			_warnShape.readjustSize();
//			_warnShape.x=wpos.pixelX - (_warnShape.width >> 1) - scene.camera.rect.x;
//			_warnShape.y=wpos.pixelY - (_warnShape.height >> 1) - scene.camera.rect.y;
//			_warnShape.scale=riadus / texture.width;
//			_scene.mapTagPartLayer.addChild(_warnShape);
		}

		/**
		 * 隐藏提示圈
		 *
		 */
		public function hideWarnShape():void
		{
//			if (_warnShape)
//			{
//				Pools.freeImage(_warnShape);
//				_warnShape=null;
//			}
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

		/**
		 * 移动路径
		 * @return
		 *
		 */
		public function get walkPathCutter():PathCutter
		{
			return _walk_pathCutter;
		}

		/**
		 * 释放
		 *
		 */
		public function dispose():void
		{
			if (!usable)
			{
				return;
			}
//			_filter=null;
			usable=false;
			removeAllEffect();
			_effects=null;
			clearWalk();
			clearTalk();
			hideWarnShape();
			filterLock=false;
//			var logo:DisplayObject;
//			while (logos.length > 0)
//			{
//				logo=logos.pop();
//				logo.removeFromParent(true);
//			}
//			logos=null;
//			hpBar=null;
			atTranLayer=false;
			if (_avatar)
			{
				_avatar.dispose();
				_avatar=null;
			}
//			if (_bubble)
//			{
//				_bubble.dispose();
//				_bubble=null;
//			}
			data=null;
			scene=null;
			_throughTileArr=null;
			_isInSafeArea=false;
			this._upMouting=0;
			this._downMouting=0;

		}

		static public function Get(type:int, scene:IMagicScene):E2DSceneCharacter
		{
			return new E2DSceneCharacter(type, scene);
		}

		public function get avatar():IAvatar
		{
			return _avatar;
		}

		public function get bubble():*
		{
			return null;
		}

		public function get jumpOffset():int
		{
			return 0;
		}

	}
}

import easiest.rendering.sprites.SpriteContainer;

import game.scene.E2DSceneCharacter;

import tempest.core.IAvatar;
import tempest.template.ActionConfig;
import tempest.template.OffsetInfo;

class TPE
{
	static private var _instance:TPE;

	static public function getInstance():TPE
	{
		return _instance||=new TPE();
	}
}



class TempAvatar extends SpriteContainer implements IAvatar
{
    private var _status:int;
    public var sc:E2DSceneCharacter;
    public var direction:int;

    public function setClickRect(w:int = 145, h:int = 80):void
    {
    }

    public function addAvatarItem(id:int, type:int, path:String = null, sortRule:int = 16):void
    {
    }

    public function removeAvatarItem(type:int):void
    {
    }

    public function removeAllItem():void
    {
    }

    public function getAvatarItem(type:int):*
    {
        return null;
    }

    public function playTo(status:int = -1, dir:int = -1, apc:ActionConfig = null, onEffectFrame:Function = null, onCompleteFrame:Function = null, resetFrame:Boolean = false):void
    {
        _status = status;
    }

    public function get status():int
    {
        return _status;
    }

    public function get usable():Boolean
    {
        return false;
    }

    public function get offsetInfo():OffsetInfo
    {
        return null;
    }

    public function set intervalScale(value:Number):void
    {
    }

    public function set isShowShadow(value:Boolean):void
    {
    }

    public function get isShowShadow():Boolean
    {
        return false;
    }
}
