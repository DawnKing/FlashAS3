package tempest.engine.graphics.layer
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import org.assetloader.base.AssetType;
	import org.assetloader.base.Param;
	import org.assetloader.core.IAssetLoader;
	import org.assetloader.core.ILoader;
	import org.assetloader.loaders.ImageLoader;
	import org.assetloader.signals.ErrorSignal;
	import org.assetloader.signals.LoaderSignal;
	
	import tempest.core.IDisposable;
	import tempest.core.IRunable;
	import tempest.engine.TScene;
	import tempest.utils.Fun;

	/**
	 * 地图切片层
	 * @author zhangyong
	 *
	 */
	public class MapLayer extends Sprite implements IDisposable, IRunable
	{
		private static var ZERO_POINT:Point=new Point();
		public static var ZONE_PRE_X:int=1; //切片水平预加载
		public static var ZONE_PRE_Y:int=1; //切片垂直预加载
		/**
		 * 地图图片加载
		 * @default
		 */
		private var _updateTime:int=0;
		private var _scene:TScene;
		private var _current:Rectangle=new Rectangle();
		private var _last:Rectangle=new Rectangle();
		private var _fillZones:Object={};
		private var _waiting:Vector.<ILoader>=new Vector.<ILoader>();
		private var _loading:Vector.<ILoader>=new Vector.<ILoader>();
		private var _loaded:Object={};
		/**小地图是否加载完毕*/
		private var _maskMapInit:Boolean=false;

		/**
		 * 切片图
		 * @param actualWidth 实际宽
		 * @param actualHeight 实际高
		 * @param zoneWidth 切片宽
		 * @param zoneHeight 切片高
		 * @param pathBuilder
		 * @param pre_x
		 * @param pre_y
		 * @param loadDelay
		 */
		public function MapLayer(scene:TScene)
		{
			super();
			this._scene=scene;
			this.tabChildren=this.tabEnabled=this.mouseChildren=this.mouseEnabled=false;
		}
		/**缩略图块尺寸*/
		private var maskTileSize:Number;
		/**缩略图缩放比*/
		private var $scale:Number;

		/**
		 * 小地图马赛克
		 * @param bitmapData
		 *
		 */
		public function setSource(maskBitmap:BitmapData):void
		{
			_scene.thumbBitmapData=maskBitmap;
			maskTileSize=(_scene.partWidth * _scene.mapConfig.thumbScale) >> 0;
			$scale=_scene.partWidth / maskTileSize;
			_maskMapInit=true;
		}

		/**
		 * 检查切片
		 * @param nowTime
		 * @param diff
		 *
		 */
		public function run(nowTime:int, diff:int):void
		{
			if (!_maskMapInit)
			{
				return;
			}
			if (nowTime - _updateTime < 500)
				return;
			_updateTime=nowTime;
			var _clip:Rectangle=this._scene.camera.rect;
			var cx:int=(_clip.left + _clip.width * 0.5) / _scene.partWidth;
			var cy:int=(_clip.top + _clip.height * 0.5) / _scene.partHeight;
			//计算加载的开始点和结束点
			_current.left=Math.max(Math.ceil(_clip.left / _scene.partWidth) - 1 - ZONE_PRE_X, 0)
			_current.top=Math.max(Math.ceil(_clip.top / _scene.partHeight) - 1 - ZONE_PRE_Y, 0);
			_current.right=Math.min(Math.ceil(_clip.right / _scene.partWidth) - 1 + ZONE_PRE_X, Math.ceil(this._scene.mapConfig.pxWidth / _scene.partWidth) - 1);
			_current.bottom=Math.min(Math.ceil(_clip.bottom / _scene.partHeight) - 1 + ZONE_PRE_Y, Math.ceil(this._scene.mapConfig.pxHeight / _scene.partHeight) - 1);
			//判断是否变化
			if (_current.isEmpty() || _current.equals(_last))
			{
				return;
			}
			var _lastIsEmpty:Boolean=_last.isEmpty();
			var xx:int;
			var yy:int;
			var key:String;
			//计算隐藏的部分
			if (!_lastIsEmpty)
			{
				for (xx=_last.left; xx <= _last.right; xx++) //行
				{
					for (yy=_last.top; yy <= _last.bottom; yy++) //列
					{
						if (!_current.contains(xx, yy)) //减少
						{
							key=yy + "_" + xx;
							if (!_loaded[key] && _fillZones[key])
							{
								removeWaiting(key);
							}
						}
					}
				}
			}
			//计算新增的部分
			var adds:Array=[];
			for (xx=_current.left; xx <= _current.right; xx++) //行
			{
				for (yy=_current.top; yy <= _current.bottom; yy++) //列
				{
					if (_lastIsEmpty || !_last.contains(xx, yy))
					{
						//增加
						key=yy + "_" + xx;
						if (_fillZones[key])
						{
							continue;
						}
						adds.push({key: key, d: (xx - cx) * (xx - cx) + (yy - cy) * (yy - cy), x: xx, y: yy});
					}
				}
			}
			addBMPs(adds);
			//保存当前记录
			_last.left=_current.left;
			_last.top=_current.top;
			_last.right=_current.right;
			_last.bottom=_current.bottom;
		}
		private var _mapsLoader:IAssetLoader;

		public function get mapsLoader():IAssetLoader
		{
			if (!_mapsLoader)
			{
				_mapsLoader=App.loader.getOrCreate("scene.maps_" + getTimer());
				_mapsLoader.numConnections=1;
                _mapsLoader.failOnError=false;
                _mapsLoader.onChildError.add(onError);
				_mapsLoader.onChildComplete.add(onLoaded);
			}
			return _mapsLoader;
		}

		/**
		 * 添加切片加载
		 * @param bmps
		 *
		 */
		private function addBMPs(bmps:Array):void
		{
			bmps.sortOn("d", Array.NUMERIC);
			var l:int=bmps.length;
			for (var i:int=0; i != l; i++)
			{
				var loader:ILoader=mapsLoader.getLoader(bmps[i].key) || _mapsLoader.addLazy(bmps[i].key, "scene/" + _scene.id + "/maps/" + bmps[i].key + ".png", AssetType.IMAGE, new Param(Param.ON_DEMAND, true));
				_waiting.push(loader);
				_fillZones[bmps[i].key]=true;
				var tileBmd:BitmapData=new BitmapData(maskTileSize, maskTileSize);
				tileBmd.copyPixels(_scene.thumbBitmapData, new Rectangle(bmps[i].x * maskTileSize, bmps[i].y * maskTileSize, maskTileSize, maskTileSize), ZERO_POINT);
				var bitmap:Bitmap=new Bitmap(tileBmd);
				bitmap.scaleX=$scale;
				bitmap.scaleY=$scale;
				bitmap.x=bmps[i].x * _scene.partWidth;
				bitmap.y=bmps[i].y * _scene.partHeight;
				_tileAssets[bmps[i].key]=bitmap;
				this.addChild(bitmap);
			}
			loadNext();
		}

		/**
		 * 检测切片加载
		 *
		 */
		private function loadNext():void
		{
			var loader:ILoader;
			if (_waiting.length != 0)
			{
				if (_loading.length < 1)
				{
					loader=_waiting.shift();
					_loading.push(loader);
					loader.start();
				}
			}
		}

		/**
		 * 移除加载等待
		 * @param loader
		 *
		 */
		private function removeWaiting(key:String):void
		{
			var i:int=_waiting.length;
			var loader:ILoader;
			while (i--)
			{
				loader=_waiting[i];
				if (loader.id == key)
				{
					_fillZones[_waiting[i].id]=false;
					_waiting.splice(i, 1);
					break;
				}
			}
		}

		/**
		 * 移除加载
		 * @param loader
		 *
		 */
		private function removeLoading(loader:ILoader):void
		{
			if (loader)
			{
				var i:int=_loading.length;
				while (i--)
				{
					if (_loading[i] == loader)
					{
						loader.stop();
						_loading.splice(i, 1);
						_loaded[loader.id]=true;
						break;
					}
				}
			}
			loadNext();
		}

		private function onError(signal:ErrorSignal, loader:ILoader):void
		{
			removeLoading(loader);
		}
		private var _tileAssets:Object={};

		private function onLoaded(signal:LoaderSignal, loader:ImageLoader):void
		{
			removeLoading(loader);
			var tileBitmap:Bitmap=_tileAssets[loader.id];
			if (tileBitmap)
			{
				_loaded[loader.id]=loader.id;
				//释放缩略图
				tileBitmap.bitmapData.dispose();
				tileBitmap.bitmapData=null;
				tileBitmap.scaleX=1;
				tileBitmap.scaleY=1;
				//设置切片内容
				tileBitmap.bitmapData=loader.bitmap.bitmapData;
			}
		}

		/**
		 * 停止驱动
		 *
		 */
		public function onStopRun():void
		{
		}
		private var _lock:Boolean;

		public function get lock():Boolean
		{
			return _lock;
		}

		/**
		 * 设置对象渲染锁定
		 * @param value
		 *
		 */
		public function set lock(value:Boolean):void
		{
			_lock=value;
		}

		public function dispose():void
		{
			_maskMapInit=false;
			_mapsLoader && _mapsLoader.destroy();
			_last=new Rectangle();
			_fillZones={};
			_loaded={};
			_tileAssets={};
			var loader:ILoader;
			while (_loading.length > 0)
			{
				loader=_loading.pop();
				loader.stop();
				loader.destroy();
			}
			_waiting.length=0;
			Fun.removeAllChildren(this, true, true, true);
		}
	}
}
