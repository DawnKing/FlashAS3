package game.scene
{
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import game.scene.map.Shock;
	
	import tempest.core.ICamera;
	import tempest.core.ISceneCharacter;
	import tempest.data.find.MathUtil;
	import tempest.data.map.WorldPostion;

	/**
	 * 地图场景摄像机
	 * @author 林碧致
	 *
	 */
	public class E2DCamera implements ICamera
	{
		/*查看范围扩充*/
		public static const LOGIC_INNER_LOOK:int=4;

		/**
		 * 摄像头跟随模式
		 */
		private static const MODE_FOLLOW:uint=0;

		/**
		 * 手动模式
		 */
		private static const MODE_MANUAL:uint=1;

		/**
		 * 移动模式 （缓动）
		 */
		private static const MODE_MOVE:uint=2;


		/*地震*/
		private var _earthShock:Shock=new Shock();
		/*摄像头跟随模式*/
		private var _mode:uint=MODE_MANUAL;
		/*场景对象*/
		private var _scene:E2DScene;
		/*所跟随的对象*/
		private var _followPostion:WorldPostion;

		/**
		 * 手动坐标x和手动坐标y
		 */
		private var _manualX:uint;
		private var _manualY:uint;

		private var _rect:Rectangle;
		private var _bw:int;
		private var _bh:int;

		/**
		 * 是否碍于边缘及地图大小被修正
		 */
		public var isCorrection:Boolean;
		/**是否使用缓动*/
		public var useEase:Boolean;
		/**是否使用缓动*/
		public var easeSpeed:Number;

		/*逻辑左值，右值，上值，下值*/
		public var logicLeft:int;
		public var logicRight:int;
		public var logicTop:int;
		public var logicBottom:int;

		/*视野内逻辑左值，右值，上值，下值*/
		private var look_logicLeft:int;
		private var look_logicRight:int;
		private var look_logicTop:int;
		private var look_logicBottom:int;

		/**
		 * 摄像头的位置x，y,z
		 */
		private var _x:int;
		private var _y:int;
		private var _z:Number=1.0;
		/**窗口大小标记*/
		private var _sizeFlag:uint;
		/**
		 * 视线范围中央点x，y
		 */
		public var centerPointX:uint;
		public var centerPointY:uint;


		/**
		 * 场景对应的摄像机
		 * @param scene
		 *
		 */
		public function E2DCamera(scene:E2DScene, useEase:Boolean, easeSpeed:Number)
		{
			_scene=scene;
			this.useEase=useEase;
			this.easeSpeed=easeSpeed;
			_rect=new Rectangle();
		}

		/**
		 * 镜头产生移动
		 * @return
		 *
		 */
		public function get isResize():Boolean
		{
			return _sizeFlag >= _scene.worldLoopCounter;
		}

		/**
		 * z轴，1表示正常比例，0-0.999之间表示镜头拉远，1.0-2.0表示镜头拉近
		 * @return
		 *
		 */
		public function get z():Number
		{
			return _z;
		}

		public function set z(value:Number):void
		{
			if (_z == value)
				return;
			_z=value;
			_sizeFlag=_scene.worldLoopCounter;
		}

		/**
		 * 摄像机区域
		 * @return
		 *
		 */
		public function get rect():Rectangle
		{
			return _rect;
		}

		private var _canShake:Boolean=true;

		/**
		 * 是否可以振动
		 * @return
		 */
		public function get canShake():Boolean
		{
			return _canShake;
		}

		/**
		 * 启动振动
		 */
		public function enableShake():void
		{
			_canShake=true;
		}

		/**
		 * 禁用振动
		 */
		public function disableShake():void
		{
			_canShake=false;
		}
		/**
		 * 是否启用滤镜
		 */
		public var enableFilter:Boolean=true;

		/**
		 * 设置摄像机可视大小
		 * @param newWidth 新高
		 * @param newHeight 新宽
		 *
		 */
		public function setView(width:int, height:int):void
		{
			if (width > 0 && height > 0)
			{
				_rect.width=width;
				_rect.height=height;
			}
		}

		/**
		 * 设置边界
		 * @param width
		 * @param height
		 *
		 */
		public function setBounds(width:int, height:int):void
		{
			if (width > 0 && height > 0)
			{
				_bw=width;
				_bh=height;
			}
		}

		/**
		 * 切换到跟随模式
		 * @param wo 跟随的对象
		 *
		 */
		public function follow(value:ISceneCharacter):void
		{
			if (!value)
			{
				_followPostion=null;
				return;
			}
			_mode=MODE_FOLLOW;
			_followPostion=value.wpos;
		}

		/**
		 * 摄像头位置的定位中心点位置
		 * @param newX 新的x
		 * @param newY 新的y
		 *
		 */
		public function setLeftTopLocation(newX:int, newY:int):void
		{
			_mode=MODE_MANUAL;
			_manualX=centerPointX + newX;
			_manualY=centerPointY + newY;
			__location(_manualX, _manualY);
		}

		public function setCenterLocation(newX:int, newY:int):void
		{
			_mode=MODE_MANUAL;
			_manualX=newX;
			_manualY=newY;
			__location(_manualX, _manualY);
		}


		private var _targetX:int;
		private var _targetY:int;

		/*内部函数，设置位置*/
		private function __location(newX:int, newY:int):void
		{
			_targetX=newX;
			_targetY=newY;
			if (!_x)
			{
				_x=newX;
				_y=newY;
			}
			_x=useEase ? (_x + (_targetX - _x) * easeSpeed) : _targetX;
			_y=useEase ? (_y + (_targetY - _y) * easeSpeed) : _targetY;

			//震动效果
			if (_canShake && _earthShock.update())
			{
				_x+=_earthShock.offsetX;
				_y+=_earthShock.offsetY;
			}

			//得出视口的大小
			var rw:uint=Math.min(_rect.width, _bw) / _z;
			var rh:uint=Math.min(_rect.height, _bh) / _z;
			//判断窗口是否发生改变
			if (rw != _rect.width || rh != _rect.height)
				_sizeFlag=_scene.worldLoopCounter;
			centerPointX=Math.round(_rect.width / 2);
			centerPointY=Math.round(_rect.height / 2) + 85;

			//设置窗口大小
			_rect.x=_x - centerPointX;
			_rect.y=_y - centerPointY;
			_rect.width=rw;
			_rect.height=rh;
			//修正
			isCorrection=false;
			//控制画面不得超过地图区域
			if (_rect.x < 0)
			{
				_rect.x=0;
				isCorrection=true;
			}
			if (_rect.y < 0)
			{
				_rect.y=0;
				isCorrection=true;
			}
			if (_rect.width > _bw)
			{
				_rect.x=-(_rect.width - _bw) / 2;
				isCorrection=true;
			}
			else if (_rect.right > _bw)
			{
				_rect.x=_bw - _rect.width;
				isCorrection=true;
			}

			if (_rect.height > _bh)
			{
				_rect.y=-(_rect.height - _bh) / 2;
				isCorrection=true;
			}
			else if (_rect.bottom > _bh)
			{
				_rect.y=_bh - _rect.height;
				isCorrection=true;
			}
		}

		/**
		 * 更新摄像机
		 * @param diff 时差
		 * @param width 摄像机宽度
		 * @param height 摄像机高度
		 *
		 */
		public function run(nowTime:int, diff:int):void
		{
			if (lock)
			{
				return;
			}
			switch (_mode)
			{
				//跟随模式
				case MODE_FOLLOW:
					updateModeFollow();
					break;
				//移动模式
				case MODE_MOVE:
					updateModeMove();
					break;
				//手动模式,直接调用location设置位置
				case MODE_MANUAL:
					__location(_manualX, _manualY);
					break;
			}

			//逻辑坐标范围
			logicLeft=_rect.left / _scene.tileWidth;
			logicRight=_rect.right / _scene.tileWidth;
			logicTop=_rect.top / _scene.tileHeight;
			logicBottom=_rect.bottom / _scene.tileHeight;

			//更新逻辑范围，用于lookIn函数
			look_logicLeft=logicLeft - LOGIC_INNER_LOOK;
			look_logicRight=logicRight + LOGIC_INNER_LOOK;
			look_logicTop=logicTop - LOGIC_INNER_LOOK;
			look_logicBottom=logicBottom + LOGIC_INNER_LOOK;
		}

		/*移动模式下的x，y*/
		private var _moveSrcX:int;
		private var _moveSrcY:int;
		private var _moveDstX:int;
		private var _moveDstY:int;
		/*时长*/
		private var _move_duration:int;

		/*移动朝向*/
		private var _move_toward:Number;
		/*移动的启动时间*/
		private var _move_StartTime:int;
		/*移动的结束时间*/
		private var _move_endTime:int;

		/**
		 * 移动模式
		 *
		 */
		public function updateModeMove():void
		{
			if (_move_endTime < getTimer())
			{
				__location(_moveDstX, _moveDstY);
				return;
			}

			//移动量
			var pi:Number=(getTimer() - _move_StartTime) / _move_duration;
			var x:int=_moveSrcX + ((_moveDstX - _moveSrcX) * pi);
			var y:int=_moveSrcY + ((_moveDstY - _moveSrcY) * pi);

			//设置摄像头位置
			__location(x, y);
		}

		/**
		 * 移动到指定的世界对象
		 * @param wo 世界对象
		 * @param duration 时长
		 *
		 */
		public function moveToWorldObject(pos:WorldPostion, duration:uint):void
		{
			moveToPoint(pos.pixelX, pos.pixelY, duration);
		}

		/**
		 * 移动到指定的位置
		 * @param dstX 目标x 像素单位
		 * @param dstY 目标y 像素单位
		 * @param duration 时长
		 * @param srcX 目标x
		 * @param srcY 目标y
		 *
		 */
		public function moveToPoint(dstX:int, dstY:int, duration:uint, srcX:int=-1, srcY:int=-1):void
		{
			if (srcX == -1 || srcY == -1) //从当前位置移动
			{
				srcX=_x;
				srcY=_y;
			}

			/*记录位置*/
			_moveSrcX=srcX;
			_moveSrcY=srcY;

			_moveDstX=dstX;
			_moveDstY=dstY;

			_move_duration=duration;

			//获得角度
			_move_toward=MathUtil.getAngle(srcX, srcY, dstX, dstY);
			//获得距离
			var distance:Number=MathUtil.getDistance(srcX, srcY, dstX, dstY);
			//启动时间
			_move_StartTime=getTimer();
			//获取停止时间
			_move_endTime=_move_StartTime + duration;
			//设置为移动模式
			_mode=MODE_MOVE;
		}

		/**
		 * 更新跟随模式
		 *
		 */
		private function updateModeFollow():void
		{
			if (!_followPostion)
				return;
			//通过主玩家的实际坐标位置，得到屏幕中央偏移及格子中央偏移			
			var srX:int=_followPostion.tileX * _scene.tileWidth;
			var srY:int=_followPostion.tileY * _scene.tileHeight;
			//设置窗口位置
			__location(srX, srY);
		}

		/**
		 *  是否存在于摄像头里（区域碰撞检测）
		 * @param postionX
		 * @param postionY
		 * @return
		 *
		 */
		public function canSee(tx:Number, ty:Number):Boolean
		{
			return !(look_logicLeft > tx || look_logicRight < tx || look_logicTop > ty || look_logicBottom < ty);
		}


		/**
		 * 屏幕震动
		 * @param duration 持续时间，默认500ms
		 *
		 */
		public function shake(duration:uint=230, offset:int=25):void
		{
			_earthShock.start(duration, offset);
		}


		/**
		 * 停止屏幕震动
		 *
		 */
		public function shockStop():void
		{
			_earthShock.stop();
		}

		/**
		 * 重置标记
		 *
		 */
		public function restFlag():void
		{
			_x=0;
			_y=0;
			_sizeFlag=_scene.worldLoopCounter;
		}

		private var _lock:Boolean;

		public function get lock():Boolean
		{
			return _lock;
		}

		public function set lock(value:Boolean):void
		{
			_lock=value;
		}

		/**
		 * 从心跳移除时执行
		 *
		 */
		public function onStopRun():void
		{
		}

	}
}
