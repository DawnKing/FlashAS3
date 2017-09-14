package game.scene.map
{
	import com.adobe.utils.StringUtil;

    import easiest.rendering.sprites.SpriteObject;

    import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	public class E2DMapPartLayer extends E2DMapLayer
	{
		//轮询检查地图切片时间间隔
		private static const INTERVAL_TIME:int=1000;
		//释放时间
		private static const EXPIRATION_TIME:uint=10000;
		/*地图切片*/
		private const _mapParts:Dictionary=new Dictionary();
		//路径格式
		private var _urlFormat:String;
		//缩略图
		private var thumbScale:Number;
		//最后一次检查地图切片时间
		private var _lastCheckMapPartTime:int;
		/*最后系统标记*/
		private var _lastSysFrameFlag:uint;
		//是否最优先
		private var _highestPriority:Boolean;
		//是否需要排序
		private var _needSort:Boolean=true;
		//是否所有素材都加载完毕
		protected var _isNoAction:Boolean=false;
		/**切片宽度*/
		public var partWidth:int;
		/**切片高度*/
		public var partHeight:int;

		/**
		 * 所有素材加载完毕
		 * @return
		 *
		 */
		public function get isNoAction():Boolean
		{
			return _isNoAction;
		}

		/**
		 * 路径格式
		 * @return
		 *
		 */
		public function get urlFormat():String
		{
			return _urlFormat;
		}

		/**
		 * 重载并增加素材下载完成条件
		 * @return
		 *
		 */
		override public function get isDrawComplete():Boolean
		{
			return super.isDrawComplete && _isNoAction;
		}

		public function E2DMapPartLayer(partWidth:int, partHeight:int)
		{
			super();
			setPartSize(partWidth, partHeight);
		}

		/**
		 * 设置尺寸
		 * @param partWidth
		 * @param partHeight
		 *
		 */
		public function setPartSize(partWidth:int, partHeight:int):void
		{
			this.partWidth=partWidth;
			this.partHeight=partHeight;
		}

		/**
		 * 初始化
		 * @param lx 层位置x
		 * @param lx 层位置y
		 * @param lw 层总宽度
		 * @param lh 层总高度
		 * @param urlFormat 下载mappart的url格式
		 * @param thumb 总缩略图
		 *
		 */
		public function initMapPartLayer(lx:int, ly:int, lw:uint, lh:uint, urlFormat:String, thumb:Object, thumbScale:Number):void
		{
			super.init(lx, ly, lw, lh, partWidth, partHeight);
			_urlFormat=urlFormat;
			this.thumbScale=thumbScale;
		}

		override public function update(sysFrameFlag:uint):void
		{
			//检查地图
			checkMapPart();
			super.update(sysFrameFlag);
		}

		private var t:uint;

		override protected function onBeforDraw(sysFrameFlag:uint):void
		{
			super.onBeforDraw(sysFrameFlag);

			//是否全部下载完毕
			_isNoAction=true;
			_lastSysFrameFlag=sysFrameFlag;
		}

		/**
		 * 每个格子循环到达时都触发
		 * @param tx 单元格子x
		 * @param ty 单元格子y
		 * @param tpx 新的格子坐标x
		 * @param tpy 新的格子坐标y
		 * @param sysFrameFlag 帧标记
		 *
		 */
		override protected function onCellEach(tx:int, ty:int, tpx:int, tpy:int, sysFrameFlag:uint):void
		{
			var src:E2DMapPart=getMapPart(tx, ty);
			//空切片就不添加了，不理会
			if (src.status != E2DMapPart.STATUS_IS_EMPTY_PART)
			{
				//不存在就添加个新的
				if (!getChildByName(src.name))
				{
					addChild(src);
					//添加以后才需要排序
					_needSort=true;
				}
				src.x=tpx;
				src.y=tpy;
				src.userTag=sysFrameFlag;
				//地图切块加载完成
				if (!src.isNoAction)
					_isNoAction=false;
			}
		}

		override protected function onChildRemove(target:SpriteObject):void
		{
			var mp:E2DMapPart=target as E2DMapPart;
			mp.removeTextureBuffer();
		}

		private static var _tempRect:Rectangle=new Rectangle();

		/**
		 * 获得地图切片
		 * @param x 切片x
		 * @param y 切片y
		 * @return
		 *
		 */
		public function getMapPart(x:int, y:int):E2DMapPart
		{
			var key:uint=(x << 6) + y;
			var mapPart:E2DMapPart=_mapParts[key];
			if (!mapPart)
			{
				_tempRect.x=x * partWidth * thumbScale;
				_tempRect.y=y * partHeight * thumbScale;
				_tempRect.width=partWidth * thumbScale;
				_tempRect.height=partHeight * thumbScale;
				//获取素材路径
				var url:String=StringUtil.format(_urlFormat, y, x);
				//构造地图切片
				mapPart=new E2DMapPart(url, key, partWidth, partHeight);
				_mapParts[key]=mapPart;
			}
			mapPart.lastVisiTime=getTimer();
			return mapPart;
		}

		//检测地图切片是否释放
		private function checkMapPart():void
		{
			//时间在检测间隔内，则退出
			if ((getTimer() - _lastCheckMapPartTime) < INTERVAL_TIME)
			{
				return;
			}
			//重置时间
			_lastCheckMapPartTime=getTimer();

			//开始检查
			for each (var mp:E2DMapPart in _mapParts)
			{
				//超过默认15秒过期时间，则释放
				if (mp.userTag == _lastSysFrameFlag)
				{
					mp.lastVisiTime=getTimer();
				}
				else if ((getTimer() - mp.lastVisiTime) > EXPIRATION_TIME)
				{
					delete _mapParts[mp.key];
					if (mp.parent)
					{
						onChildRemove(mp);
					}
					mp.close();
				}
			}
		}

		override public function clear():void
		{
			super.clear();
			_isInited=false;
			for each (var mp:E2DMapPart in _mapParts)
			{
				delete _mapParts[mp.key];
				mp.close();
			}
		}
	}
}
