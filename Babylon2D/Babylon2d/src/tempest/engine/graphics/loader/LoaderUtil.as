package tempest.engine.graphics.loader {
	import flash.utils.Dictionary;
	
	import common.SceneCache;
	
	import tempest.loader.Handler;
	
	import org.assetloader.base.Param;
	import org.assetloader.core.IAssetLoader;
	import org.assetloader.core.ILoader;
	import org.assetloader.loaders.SWFLoader;
	import org.assetloader.signals.ErrorSignal;
	import org.assetloader.signals.LoaderSignal;
	
	import tempest.engine.graphics.animation.AnimationSource;
	import tempest.engine.graphics.avatar.vo.AvatarPartSource;
	import tempest.utils.Func;

	/**
	 * 加载配置
	 * @author zhangyong
	 *
	 */
	public class LoaderUtil {
		/**等待列表*/
		private static var _waitingAniList:Dictionary;
		/**循环加载队列*/
		private static var _queueAni:Vector.<ILoader>;
		/**正在加载的加载器*/
		private static var _loadingAniList:Vector.<ILoader>;
		/**特效加载器*/
		private static var _aniLoader:IAssetLoader;

		public static function get aniLoader():IAssetLoader {
			if (!_aniLoader) {
				_aniLoader = App.loader.getOrCreate("scene.animation");
				_aniLoader.setParam(Param.LOADER_CONTEXT, "self");
				_aniLoader.onChildComplete.add(onAniLoaded);
				_aniLoader.onChildError.add(onAniLoadError);
				_aniLoader.numConnections = 1;
			}
			return _aniLoader;
		}
		init();

		private static function init():void {
			_waitingAniList = new Dictionary();
			_queueAni = new Vector.<ILoader>();
			_loadingAniList = new Vector.<ILoader>();
			////
			_waitingAvatarList = new Dictionary();
			_queueAvatar = new Vector.<ILoader>();
			_loadingAvatarList = new Vector.<ILoader>();
		}

		/**
		 *移除加载资源
		 * @param path  加载路径
		 * @param animationSource  等待队列回调加载资源
		 *
		 */
		private static function removeAniLoadPath(path:String, animationSource:AnimationSource = null):void {
			removeAniLoading(path);
			var waitingList:Vector.<Handler> = _waitingAniList[path];
			if (waitingList) {
				if (animationSource) {
					var handler:Handler;
					for each (handler in waitingList) {
						if (handler != null) {
							handler.executeWith([animationSource]);
						}
					}
				}
				waitingList = null;
				delete _waitingAniList[path];
			}
		}

		/**
		 *从加载队列移除
		 * @param path
		 *
		 */
		private static function removeAniLoading(path:String):void {
			var iloader:ILoader;
			for each (iloader in _loadingAniList) {
				if (iloader.id == path) {
					_loadingAniList.splice(_loadingAniList.indexOf(iloader), 1);
					break;
				}
			}
		}

		/**
		 *移除等待回调函数
		 * @param path
		 * @param onComplete
		 *
		 */
		public static function removeAniLoadComplete(path:String, onComplete:Handler):void {
			var waitingList:Vector.<Handler> = _waitingAniList[path];
			if (waitingList) {
				var index:int = waitingList.indexOf(onComplete);
				if (index != -1) {
					waitingList.splice(index, 1);
				}
			}
		}

		/**
		 * 特效加载错误
		 * @param signal
		 * @param loader
		 *
		 */
		private static function onAniLoadError(signal:ErrorSignal, loader:ILoader):void {
			removeAniLoadPath(loader.id);
			App.timer.doFrameOnce(1, loadAniNext, null, true, "检测特效加载");
		}

		/**
		 *
		 * @param signal
		 * @param loader
		 *
		 */
		private static function onAniLoaded(signal:LoaderSignal, loader:ILoader):void {
			var aps:AnimationSource = new AnimationSource(loader as SWFLoader, loader.id);
			SceneCache.addAnimationtCache(aps);
			removeAniLoadPath(loader.id, aps);
			//加载下一个
			App.timer.doFrameOnce(1, loadAniNext, null, true, "检测特效加载");
		}

		/**
		 *加载动画资源
		 * @param path  路径
		 * @param onComplete  加载完毕回调执行函数  回调参数为AnimationSource
		 * @param isCache  本次加载的资源是否缓存
		 *
		 */
		public static function loadAnimation(path:String, onComplete:Handler = null, priority:int = 0):void {
			var $path:String = path;
			var $onComplete:Handler = onComplete;
			var $loader:ILoader;
			if (SceneCache.hasAnimationCache($path)) {
				$onComplete && $onComplete.executeWith([SceneCache.getAnimationCache($path)]);
			} else if (aniLoader.hasAsset($path)) {
				$onComplete && $onComplete.executeWith([aniLoader.getLoader($path) as SWFLoader]);
			} else {
				if (_waitingAniList[$path] == null) {
					_waitingAniList[$path] = new Vector.<Handler>();
					if ($onComplete != null) {
						_waitingAniList[$path].push($onComplete);
					}
					//					var loader:TRslLoader = new TRslLoader($path, TRslType.RES, TPEngine.decode);
					//					loader.id = $path;
					//					loader.priority = priority;
					$loader = aniLoader.getLoader($path);
					if (!$loader) {
						$loader = aniLoader.addLazy($path, $path);
						$loader.setParam(Param.ON_DEMAND, true);
						$loader.setParam(Param.PRIORITY, priority);
					}
					if ((!$loader.invoked || $loader.stopped) && _queueAni.indexOf($loader) == -1) {
						_queueAni.push($loader);
					}
						//					_queue.push($loader);
						//					_queue.sortOn("priority", Array.DESCENDING); //降序排序
				} else if ($onComplete != null) {
					var vector:Vector.<Handler> = _waitingAniList[$path];
					if (vector.indexOf($onComplete) == -1) {
						vector.push($onComplete);
					}
				}
			}
			App.timer.doFrameOnce(1, loadAniNext, null, true, "检测特效加载");
		}

		/**
		 * 循环加载(设置加载数量为1则为串行)
		 *
		 */
		private static function loadAniNext():void {
			while (_queueAni.length != 0 && _loadingAniList.length <= 1) {
				var loader:ILoader = _queueAni.pop();
				loader.start();
				_loadingAniList.push(loader);
			}
		}

		///////////////////////////
		public static function get avatarLoader():IAssetLoader {
			if (!_avatarLoader) {
				_avatarLoader = App.loader.getOrCreate("scene.avatar");
				_avatarLoader.setParam(Param.LOADER_CONTEXT, "self");
				_avatarLoader.onChildComplete.add(onAvatarLoaded);
				_avatarLoader.onChildError.add(onAvatarLoadError);
				_avatarLoader.numConnections = 1;
			}
			return _avatarLoader;
		}
		/**等待加载列表*/
		private static var _waitingAvatarList:Dictionary;
		/**循环加载队列*/
		private static var _queueAvatar:Vector.<ILoader>;
		/**正在加载的加载器*/
		private static var _loadingAvatarList:Vector.<ILoader>;
		/**部件加载器*/
		private static var _avatarLoader:IAssetLoader;

		private static function onAvatarLoadError(signal:ErrorSignal, loader:ILoader):void {
			removeAvatarLoadPath(loader.id);
			App.timer.doFrameOnce(1, loadAvatarNext, null, true, "检测部件加载");
		}

		/**
		 *加载完毕
		 * @param signal
		 * @param loader
		 *
		 */
		private static function onAvatarLoaded(signal:LoaderSignal, loader:ILoader):void {
			var aps:AvatarPartSource = new AvatarPartSource(loader as SWFLoader, loader.id);
			SceneCache.addAvatarPartCache(aps);
			removeAvatarLoadPath(loader.id, aps);
			//加载下一个
			App.timer.doFrameOnce(1, loadAvatarNext, null, true, "检测部件加载");
		}

		/**
		 *加载角色部件资源
		 * @param path  路径
		 * @param onComplete  加载完毕回调执行函数  回调参数为AnimationSource
		 * 不传入onComplete则可以进行预加载
		 *
		 */
		public static function loadAvatarPart(path:String, onComplete:Handler = null, priority:int = 0):void {
			var $path:String = path;
			var $onComplete:Handler = onComplete;
			var $loader:ILoader;
			if (SceneCache.hasAvaterCache($path)) {
				$onComplete && $onComplete.executeWith([SceneCache.getAvatarCache($path)]);
			} else if (avatarLoader.hasAsset($path)) {
				$onComplete && $onComplete.executeWith([avatarLoader.getLoader($path) as SWFLoader]);
			} else {
				if (_waitingAvatarList[$path] == null) {
					_waitingAvatarList[$path] = new Vector.<Handler>();
					if ($onComplete != null) {
						_waitingAvatarList[$path].push($onComplete);
					}
					$loader = avatarLoader.getLoader($path);
					if (!$loader) {
						$loader = avatarLoader.addLazy($path, $path);
						$loader.setParam(Param.ON_DEMAND, true);
						$loader.setParam(Param.PRIORITY, priority);
					}
					if ((!$loader.invoked || $loader.stopped) && _queueAvatar.indexOf($loader) == -1) {
						_queueAvatar.push($loader);
					}
					App.timer.doFrameOnce(1, loadAvatarNext, null, true, "检测部件加载");
				} else if ($onComplete != null) {
					var vector:Vector.<Handler> = _waitingAvatarList[$path];
					if (vector.indexOf($onComplete) == -1) {
						vector.push($onComplete);
					}
				}
			}
		}

		/**
		 * 循环加载(设置加载数量为1则为串行)
		 *
		 */
		private static function loadAvatarNext():void {
			while (_queueAvatar.length != 0 && _loadingAvatarList.length <= 1) {
				var loader:ILoader = _queueAvatar.pop();
				loader.start();
				_loadingAvatarList.push(loader);
			}
		}

		/**
		 *移除加载资源
		 * @param path  加载路径
		 * @param avatarPartSource  等待队列回调加载资源
		 *
		 */
		public static function removeAvatarLoadPath(path:String, avatarPartSource:AvatarPartSource = null):void {
			removeAvatarLoading(path);
			var waitingList:Vector.<Handler> = _waitingAvatarList[path];
			if (waitingList) {
				if (avatarPartSource) {
					var handler:Handler;
					for each (handler in waitingList) {
						if (handler != null) {
							handler.executeWith([avatarPartSource]);
						}
					}
				}
				waitingList = null;
				delete _waitingAvatarList[path];
			}
		}

		/**
		 *从加载队列移除
		 * @param path
		 *
		 */
		private static function removeAvatarLoading(path:String):void {
			var iloader:ILoader;
			for each (iloader in _loadingAvatarList) {
				if (iloader.id == path) {
					_loadingAvatarList.splice(_loadingAvatarList.indexOf(iloader), 1);
					break;
				}
			}
		}

		/**
		 *移除等待回调函数
		 * @param path
		 * @param onComplete
		 *
		 */
		public static function removeAvatarLoadComplete(path:String, onComplete:Handler):void {
			var waitingList:Vector.<Handler> = _waitingAvatarList[path];
			if (waitingList) {
				var index:int = waitingList.indexOf(onComplete);
				if (index != -1) {
					waitingList.splice(index, 1);
				}
			}
		}
		//////////////////////////////////////////////
		/**
		 *字符分隔符
		 */
		private static const SPLIT_CHAR:String = "_";

		/**
		 * 获取部件其他资源加载路径
		 * @param oldUrl
		 * @return
		 *
		 */
		public static function replaceUrl(oldUrl:String, resPackge:int):String {
			var oldName:String = Func.getFileName(oldUrl, false);
			var newUrl:String = getNewUrl(oldName, resPackge);
			newUrl = Func.replaceFileName(oldUrl, newUrl);
			return newUrl;
		}

		/**
		 * 根据分包拼接新的名称
		 * @return
		 *
		 */
		private static function getNewUrl(oldUrl:String, resPackge:int):String {
			/////////过滤上次用过的前缀
			var index:int = oldUrl.indexOf(SPLIT_CHAR);
			if (index != -1 && index < 3) {
				oldUrl = oldUrl.substring(index + 1, oldUrl.length);
			}
			//////过滤上次用过的后缀
			if (resPackge == 6) //跳跃分包共用
			{
				var endfix:int = oldUrl.length - 2;
				if (oldUrl.charAt(endfix) == SPLIT_CHAR) {
					oldUrl = oldUrl.substring(0, endfix);
				}
			}
			////////拼接前缀
			if (resPackge != 0) {
				return resPackge + SPLIT_CHAR + oldUrl;
			} else {
				return oldUrl;
			}
		}

		/**
		 * 获取分包的前缀
		 * @return
		 *
		 */
		public static function getPartPrefix(path:String):int {
			var oldName:String = Func.getFileName(path, false);
			var index:int = oldName.indexOf(SPLIT_CHAR);
			if (index != -1 && index < 3) {
				return int(oldName.substring(0, index));
			}
			return 0;
		}

		/**
		 * 获取分包的后缀
		 * @return
		 *
		 */
		public static function getPartLastfix(path:String):int {
			var oldName:String = Func.getFileName(path, false);
			var endfix:int = oldName.length - 2;
			if (oldName.charAt(endfix) == SPLIT_CHAR) {
				return int(oldName.charAt(endfix + 1));
			}
			return -1;
		}
	}
}
