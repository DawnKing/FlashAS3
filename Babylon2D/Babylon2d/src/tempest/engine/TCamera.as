package tempest.engine
{
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import tempest.core.ICamera;
	import tempest.core.ISceneCharacter;

	/**
	 * 游戏摄像机
	 * @author 
	 */
	public class TCamera implements ICamera
	{
		public var ease:Number=0.3; //缓动速度
		public var distRatio:Number=0.1; //移动阈值比例
		public var distX:int=100; //X移动阈值
		public var distY:int=60; //Y移动阈值
		public var follower:ISceneCharacter=null; //摄像机跟随对象
		private var _target:DisplayObject; //摄像机监视的视图对象
		private var _rect:Rectangle=new Rectangle(0, 0, 1000, 600); //可视区域矩形
		public var boundW:int; //真实宽
		public var boundH:int; //真实高
		public var scaling:Number=1; //缩放比
		public var useDist:Boolean=true;
		public var center_offsetX:int=0;
		public var center_offsetY:int=150;
		public var useEase:Boolean=true;

		/**
		 * 游戏摄像机
		 * @param targrt 摄像机监视的对象
		 * @param viewW 可视宽
		 * @param viewH 可视高
		 */
		public function TCamera(targrt:DisplayObject, width:int=1000, height:int=600)
		{
			this._target=targrt;
			this.boundW=targrt.width;
			this.boundH=targrt.height;
			_rect=new Rectangle(0, 0, width, height);
		}

		public function get x():int
		{
			return _rect.x;
		}

		public function set x(value:int):void
		{
			_rect.x=x;
			this.updateTarget();
		}

		public function get y():int
		{
			return _rect.y;
		}

		public function set y(value:int):void
		{
			_rect.y=y;
			this.updateTarget();
		}

		public function get rect():Rectangle
		{
			return _rect;
		}

		/**
		 * 设置可视区域尺寸
		 * @param w
		 * @param h
		 */
		public function setView(w:int, h:int):void
		{
			this.rect.width=w;
			this.rect.height=h;
		}

		/**
		 * 设置真实尺寸
		 * @param w
		 * @param h
		 */
		public function setBounds(w:int, h:int):void
		{
			this.boundW=w;
			this.boundH=h;
		}

		/**
		 * 角色是否可见
		 * @param char
		 * @return
		 */
		public function canSee(px:Number, py:Number):Boolean
		{
			return this.rect.contains(px, py);
		}

		/**
		 * 关注对象
		 * @param follow
		 * @param useTween
		 */
		public function follow(iScenecharacter:ISceneCharacter):void
		{
			this.follower=iScenecharacter;
			this._isShaking=false;
			this.run(0, 0);
		}

		/**
		 * 更新摄像机
		 * @param useTween 是否使用缓动
		 */
		public function run(nowTime:int, diff:int):void
		{
			if (_lock)
				return;
			if (follower == null)
				return;
			var fx:int=follower.x * scaling;
			var fy:int=follower.y * scaling;
			moveToPoint(fx, fy, 0);
		}

		/**
		 *摄像机焦点移动至某点
		 * @return
		 *
		 */
		public function moveToPoint(px:int, py:int, duration:uint, srcX:int=-1, srcY:int=-1):void
		{
			if (srcX == -1 || srcY == -1) //从当前位置移动
			{
				srcX=this.rect.x;
				srcY=this.rect.y;
			}
			var cx:int=this.rect.x + this.rect.width * 0.5 + center_offsetX;
			var cy:int=this.rect.y + this.rect.height * 0.5 + center_offsetY;
			var dx:int=Math.abs(px - cx);
			var dy:int=Math.abs(py - cy);
			var sx:int=this.rect.x;
			var sy:int=this.rect.y;
			if (this.useDist)
			{
				this.distX=this.rect.width * distRatio;
				this.distY=this.rect.height * distRatio;
				if (dx > distX)
				{
					dx-=distX;
					if (follower.x < cx)
						dx=-dx;
					sx+=(useEase) ? dx * ease : dx;
				}
				if (dy > distY)
				{
					dy-=distY;
					if (follower.y < cy)
						dy=-dy;
					sy+=(useEase) ? dy * ease : dy;
				}
			}
			else
			{
				if (px < cx)
					dx=-dx;
				sx+=(useEase) ? dx * ease : dx;
				if (py < cy)
					dy=-dy;
				sy+=(useEase) ? dy * ease : dy;
			}
			if (boundW < this.rect.width)
			{
				this.rect.x=-(this.rect.width - boundW) * 0.5;
			}
			else
			{
				this.rect.x=Math.min(Math.max(sx, 0), boundW - this.rect.width);
			}
			if (boundH < this.rect.height)
			{
				this.rect.y=-(this.rect.height - boundH) * 0.5;
			}
			else
			{
				this.rect.y=Math.min(Math.max(sy, 0), boundH - this.rect.height);
			}
			//震动
			if (_isShaking)
			{
				if (getTimer() > _shake_endTime)
				{
					_isShaking=false;
				}
				else
				{
					var r:Number=Math.random();
					if (_shake_direct % 2 == 0)
						r=-r;
					_shake_direct++;
					this.rect.y+=r * _shake_intensity;
					this.rect.x+=r * _shake_intensitx;
				}
			}
			this.updateTarget();
		}
		/**
		 *保证震动一上一下
		 */
		private var _shake_direct:Number;

		private function updateTarget():void
		{
			if (this._target)
			{
				var rect:Rectangle=this._target.scrollRect;
				if (rect && rect.equals(this.rect))
					return;
				this._target.scrollRect=this.rect;
			}
		}
		//==================================摄像机震动=============================================
		private var _isShaking:Boolean=false;
		private var _shake_endTime:Number=0;
		private var _shake_duration:Number=0;
		private var _shake_intensity:int=28;
		private var _shake_intensitx:int=14;
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
		 * 振动
		 * @param duration 振动持续时间 单位:秒
		 * @param intensity 振动强度  单位:像素
		 */
		public function shake(duration:uint=400, offset:int=6):void
		{
			if (!_canShake || _isShaking)
			{
				return;
			}
			_shake_duration=duration;
			_shake_intensity=30;
			_shake_intensitx=15;
			_shake_endTime=getTimer() + duration;
			_isShaking=true;
			_shake_direct=0;
		}
		private var _lock:Boolean=false; //是否锁定摄像机

		public function get lock():Boolean
		{
			// TODO Auto Generated method stub
			return _lock;
		}

		public function set lock(value:Boolean):void
		{
			// TODO Auto Generated method stub
			_lock=value;
		}

		public function onStopRun():void
		{
			// TODO Auto Generated method stub

		}

	}
}


