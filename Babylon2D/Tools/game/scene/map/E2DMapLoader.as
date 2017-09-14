package game.scene.map
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import tempest.data.map.MapConfig;


	/**
	 * 地图加载器
	 * @author
	 *
	 */
	public class E2DMapLoader extends EventDispatcher
	{
		public static const MAPDATA_LOADED:String="mapdata_loaded";
		//是否已经加载
		private var _isLoaded:Boolean=false;
		//正在加载
		private var _isLoading:Boolean=false;
		private var _isSmallLoaded:Boolean=false;
		private var _isEntryData:Boolean=false;
		/*出错了*/
		private var _isError:Boolean=false;

		public function get smBitmap():Bitmap
		{
			return _smBitmap;
		}

		/**是否加载器出错*/
		public function get isError():Boolean
		{
			return _isError;
		}

		/**是否完成*/
		public function get isLoaded():Boolean
		{
			return _isLoaded;
		}

		/**
		 * 地图数据实体
		 */
		public var entryData:MapConfig;
		/**
		 * 缩略位图
		 */
//		public var thum:Texture;

		/*小位图*/
		private var _smBitmap:Bitmap;
		private var _sbmp:BitmapData;
		private var _smallUrl:String;
		/**
		 * 地图编号
		 */
		public var mapid:uint;
		/*小地图素材进度*/
		private var _smallProgress:uint;
		/*逻辑数据进度*/
		private var _entryDataProgress:uint;
		/*smallJPG*/
		private var _smallLoader:Loader=new Loader();
		/*数据流*/
		private var _dataLoader:URLLoader=new URLLoader();
		/*尝试次数*/
		private var _tryBitmapCount:uint=0;
		private var _tryDataCount:uint=0;

		/**
		 * 最大尝试次数
		 */
		public var maxTryCount:uint=3;
		/**
		 * 进度 单位/百分比
		 */
		public var progress:uint;

		private var rect:Rectangle;

		public function E2DMapLoader(rect:Rectangle=null)
		{
			this.rect=rect;
			//加载缩略图
			_smallLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSmallBitmapComplete, false, 0, true);
			_smallLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onSmallProgress, false, 0, true);
			_smallLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onSmallIOError, false, 0, true);

			//加载数据
			_dataLoader.addEventListener(IOErrorEvent.IO_ERROR, onDataIOError, false, 0, true);
			_dataLoader.addEventListener(ProgressEvent.PROGRESS, onEntryDataProgress, false, 0, true);
			_dataLoader.addEventListener(Event.COMPLETE, onEntryDataComplete, false, 0, true);
		}

		/**
		 * 开始加载
		 * @param newMapid
		 *
		 */
		public function load(newMapid:int):void
		{
			mapid=newMapid;
			if (_isLoaded)
			{
				trace("MapLoader:MapLoader was loaded befor");
			}
			else if (!_isLoading)
			{
				_isLoading=true;
				//连接小位图
				if (!_isSmallLoaded)
					loadSmallBimap();
				//加载数据
				if (!_isEntryData)
					loadeData();
			}
		}
		
		/**地图路径*/
		public static var mapPath:String="maps/";
		/**地图路径*/
		public static var scenePath:String="scene/";
		/*加载小位图*/
		private function loadSmallBimap(str:String=""):void
		{
			_smallUrl=Object(Config).getVersionUrl(scenePath + mapid + "/thumb.jpg" + str);
			_smallLoader.load(new URLRequest(_smallUrl));
		}

		/*加载数据*/
		private function loadeData():void
		{
			var url:String="";
			url=Object(Config).getVersionUrl(mapPath + mapid + ".txt");
			_dataLoader.load(new URLRequest(url));
		}

		private function onSmallProgress(e:ProgressEvent):void
		{
			_smallProgress=e.bytesLoaded * 100 / e.bytesTotal;
			onMapLoaderProgress();
		}

		private function onEntryDataProgress(e:ProgressEvent):void
		{
			_entryDataProgress=e.bytesLoaded * 100 / e.bytesTotal;
			onMapLoaderProgress();
		}

		private function onMapLoaderProgress():void
		{
			progress=_smallProgress / 2 + _entryDataProgress / 2;
		}

		private function onSmallIOError(event:IOErrorEvent):void
		{
			_tryBitmapCount++;
			if (_tryBitmapCount >= maxTryCount)
			{
				_isError=true;
				return;
			}
			//重试
			loadSmallBimap();

			trace("地图缩略图加载失败..重试ing[" + _smallUrl + "]");
		}

		private function onDataIOError(event:IOErrorEvent):void
		{
			_tryDataCount++;
			if (_tryDataCount >= maxTryCount)
			{
				_isError=true;
				return;
			}
			loadeData(); //重试
			trace("地图数据加载失败..id:" + mapid);
		}

		/**
		 * 小地图位图加载完毕
		 * @param e
		 *
		 */
		private function onSmallBitmapComplete(e:Event):void
		{
			_isSmallLoaded=true;
			_smBitmap=(e.target as LoaderInfo).content as Bitmap;
			enableStarlingThum();
		}

		/**
		 * 显示缩略图
		 *
		 */
		public function enableStarlingThum():void
		{
//			if (Starling.current && Starling.current.contextValid)
//			{
				if (_smBitmap)
				{
					if (_smBitmap.bitmapData.width == 0 || _smBitmap.bitmapData.height == 0)
					{
						_isError=true;
						throw(new Error("加载的小地图宽高为0"));
					}
					else
					{
						try
						{
							if (rect) //还要切一下
							{
								_sbmp=new BitmapData(rect.width, rect.height, false);
								_sbmp.copyPixels(_smBitmap.bitmapData, rect, new Point());
//								thum=Texture.fromBitmapData(_sbmp, false);
							}
							else
							{
//								thum=Texture.fromBitmap(_smBitmap, false);
							}
//							thum.root.restorePriority=9;
						}
						catch (e:Error)
						{
							//重新加载试看看
							loadSmallBimap("?ver=" + Math.random());
						}

					}
					checkComlete();
				}
//			}
//			else
//			{
//				setTimeout(enableStarlingThum, 500);
//			}
		}

		/**
		 * 地图数据加载完毕
		 * @param e
		 *
		 */
		private function onEntryDataComplete(e:Event):void
		{
			_isEntryData=true;
			entryData=new MapConfig();
			entryData.anlyData((e.target as URLLoader).data);
			_dataLoader.close();
			checkComlete();
		}

		/**
		 * 检查地图配置，小地图是否全部加载完毕
		 *
		 */
		private function checkComlete():void
		{
			if (!_isSmallLoaded || !_isEntryData)
				return;
			//完成
			_isLoaded=true;
			//加载缩略图
			if (_smallLoader)
			{
				_smallLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSmallBitmapComplete);
				_smallLoader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onSmallProgress);
				_smallLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onSmallIOError);
			}
			//加载数据
			if (_dataLoader)
			{
				_dataLoader.removeEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
				_dataLoader.removeEventListener(ProgressEvent.PROGRESS, onEntryDataProgress);
				_dataLoader.removeEventListener(Event.COMPLETE, onEntryDataComplete);
			}
//			this.dispatchEventWith(MAPDATA_LOADED);
			this.dispatchEvent(new Event(MAPDATA_LOADED));
		}

		/**
		 * MapLoader释放
		 *
		 */
		public function clear():void
		{
			if (_smallLoader)
			{
				_smallLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSmallBitmapComplete);
				_smallLoader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onSmallProgress);
				_smallLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onSmallIOError);
				_smallLoader.unloadAndStop(false);
			}
			if (_dataLoader)
			{
				_dataLoader.removeEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
				_dataLoader.removeEventListener(ProgressEvent.PROGRESS, onEntryDataProgress);
				_dataLoader.removeEventListener(Event.COMPLETE, onEntryDataComplete);
				try
				{
					_dataLoader.close();
				}
				catch (e:*)
				{
				}
			}
			if (_sbmp)
			{
				_sbmp.dispose();
				_sbmp=null;
			}
			if (_smBitmap)
			{
				_smBitmap.bitmapData.dispose();
				_smBitmap=null;
			}
			_smallLoader=null;
			_dataLoader=null;
//			if (thum)
//			{
//				//纹理释放
//				thum.dispose();
//				thum=null;
//			}
			entryData=null;
		}
	}
}
