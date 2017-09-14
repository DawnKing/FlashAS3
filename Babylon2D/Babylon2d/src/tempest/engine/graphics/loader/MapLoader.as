package tempest.engine.graphics.loader
{
	import flash.display.Bitmap;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import common.SceneCache;
	
	import org.assetloader.base.AssetType;
	import org.assetloader.core.IAssetLoader;
	import org.assetloader.signals.LoaderSignal;
	
	import tempest.data.map.MapConfig;
	import tempest.engine.TScene;

	/**
	 * 地图加载，小地图，地图配置
	 * @author zhangyong
	 *
	 */
	public class MapLoader
	{
		private static var _mapInfoLoader:IAssetLoader;
		private static var _mapthumbLoader:IAssetLoader;

		public static function get mapInfoLoader():IAssetLoader
		{
			if (!_mapInfoLoader)
			{
				_mapInfoLoader=App.loader.getOrCreate("scene.info");
				_mapInfoLoader.numConnections=1;
			}
			return _mapInfoLoader;
		}

		public static function get mapthumbLoader():IAssetLoader
		{
			if (!_mapthumbLoader)
			{
				_mapthumbLoader=App.loader.getOrCreate("scene.thumb");
				_mapthumbLoader.numConnections=1;
			}
			return _mapthumbLoader;
		}

		/**
		 * 加载地图配置文件
		 * @param mapId
		 * @param url
		 * @param scene
		 * @param onComplete
		 * @param onProgress
		 */
		public static function loadMapConfig(resId:int, url:String, scene:TScene, onComplete:Function=null, onProgress:Function=null, onError:Function=null):void
		{
			var $scene:TScene=scene;
			var $mapConfig:MapConfig=new MapConfig();
			var $onComplete:Function=onComplete;
			var $onProgress:Function=onProgress;
			var $onError:Function=onError;
			var id:String="maps/" + resId + ".txt";
			var new_onProgress:Function=function(progress:Number):void
			{
				$onProgress && $onProgress(progress);
			}
			var new_onError:Function=function():void
			{
				$onError && $onError(url);
			}
			var new_onComplete:Function=function(signal:LoaderSignal, data:*):void
			{
				mapInfoLoader.stop();
				try
				{
					$mapConfig.anlyData(data[id])
				}
				catch (e:Error)
				{
					$onError(e.message);
					return;
				}
				//////////////////////////////////////
				if (!($onComplete == null))
				{
					$onComplete.call(scene, $mapConfig);
				}
			}
			//停止加载器
			mapthumbLoader.stop();
			mapInfoLoader.stop();
			if (mapInfoLoader.hasAsset(id))
			{ //已经缓存资源
				new_onComplete(null, mapInfoLoader.data);
			}
			else
			{
				mapInfoLoader.onComplete.addOnce(new_onComplete);
				mapInfoLoader.onProgress.add(new_onProgress);
				if (mapInfoLoader.hasLoader(id))
				{
					mapInfoLoader.remove(id);
				}
				mapInfoLoader.addLazy(id, id, AssetType.TEXT)
				mapInfoLoader.start();
			}
		}

		/**
		 * 加载小地图
		 * @param scene
		 */
		public static function loadSmallMap(scene:TScene):void
		{
			var $scene:TScene=scene;
			var t:int=getTimer();
			var thumbPath:String=SceneCache.scenePath + scene.id + "/thumb.jpg";
			var new_onComplete:Function=function(signal:LoaderSignal, data:Dictionary):void
			{
				var bmp:Bitmap=data[thumbPath];
				if (bmp)
				{
					$scene.mapLayer.setSource(bmp.bitmapData);
				}
				mapthumbLoader.stop();
			}
			mapthumbLoader.stop();
			if (mapthumbLoader.hasAsset(thumbPath))
			{ //已经缓存资源
				new_onComplete(null, _mapthumbLoader.data);
			}
			else
			{
				mapthumbLoader.onComplete.addOnce(new_onComplete);
				if (mapthumbLoader.hasLoader(thumbPath))
				{
					mapthumbLoader.remove(thumbPath);
				}
				mapthumbLoader.addLazy(thumbPath, thumbPath, AssetType.IMAGE)
				mapthumbLoader.start();
			}
		}
	}
}
