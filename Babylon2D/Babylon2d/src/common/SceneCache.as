package common
{
    import com.adobe.utils.DictionaryUtil;

    import flash.system.System;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import flash.utils.setInterval;

    import tempest.engine.graphics.animation.AnimationSource;
    import tempest.engine.graphics.avatar.vo.AvatarPartSource;
    import tempest.engine.graphics.loader.LoaderUtil;
    import tempest.template.OffsetInfo;

    /**
	 * 场景资源缓存
	 * @author zhangyong
	 *
	 */
	public class SceneCache
	{
		/**地图路径*/
		public static var mapPath:String="maps/";
		/**地图路径*/
		public static var scenePath:String="scene/";
		/**纹理路径*/
		public static var binPath:String="model/bins/";
		/**特效纹理路径*/
		public static const direffect:String="animations/";
		/**模型路径*/
		public static const diravatar:String="avatars/";
		/***资源类型-部件*/
		public static var AVATAR:int=0;
		/***资源类型-动画*/
		public static var ANIMATION:int=1;
		/**部件释放超时时间*/
		public static var AVATAPART_TIMEOUT:int=30000;
		/**部件缓存*/
		private static var _avatarPartCache:Dictionary=null;
		/**特效缓存*/
		private static var _animationSourceCache:Dictionary=null;
		/**地图配置缓存*/
		public static var mapConfigCache:Dictionary=null;
		/**avatar偏移信息*/
		public static var offsets:Object;
		/**默认偏移信息*/
		public static var defaultOffset:OffsetInfo;

		public static function init(offsetStr:String=""):void
		{
			_avatarPartCache=new Dictionary();
			_animationSourceCache=new Dictionary();
			mapConfigCache=new Dictionary();
			offsets={};
			var prs:Array=offsetStr.split("\r\n");
			//添加自定义偏移规则
			var rItem:String;
			for each (rItem in prs)
			{
				if (rItem.indexOf("//") != -1) //跳过注释行
				{
					continue;
				}
				var $ritem:Array=rItem.split(" ");
				if ($ritem.length >= 6) //检测规则是否有效
				{
					var ao:OffsetInfo=new OffsetInfo($ritem);
					offsets[ao.resId]=ao;
				}
			}
			defaultOffset=offsets[-1];
		}

		/**
		 * 获取偏移信息
		 * @param resId
		 * @return
		 *
		 */
		public static function getOffsetInfo(resId:int):OffsetInfo
		{
			return offsets[resId] || defaultOffset;
		}

		/**
		 *自动释放部件内存
		 * @param num 每次自动释放的数量
		 *
		 */
		public static function autoOptimizeAvatar(num:int=1):void
		{
			var avatarPartSource:AvatarPartSource;
			var keys:Array=DictionaryUtil.getKeys(_avatarPartCache);
			var len:int=keys.length;
			var iter:int;
			var count:int=0;
			for (; iter != len; ++iter)
			{
				avatarPartSource=_avatarPartCache[keys[iter]];
				if (avatarPartSource.refCount <= 0)
				{
					count++;
					optimizeAvatar(avatarPartSource, false);
					if (count >= num)
					{
						break;
					}
				}
			}
			keys=null;
		}

		/**
		 *
		 *自动释放特效内存
		 */
		public static function autoOptimizeAnimation(num:int=1):void
		{
			var animationSource:AnimationSource;
			var keys:Array=DictionaryUtil.getKeys(_animationSourceCache);
			var len:int=keys.length;
			var iter:int;
			var count:int=0;
			for (; iter != len; ++iter)
			{
				animationSource=_animationSourceCache[keys[iter]];
				if (animationSource.refCount <= 0)
				{
					count++;
					optimizeAnimatoin(animationSource, false);
					if (count >= num)
					{
						break;
					}
				}
			}
			keys=null;
		}

		/**
		 * 清除所有部件缓存
		 * @param length
		 *
		 */
		public static function optimizeAllAvatar(igenorTime:Boolean=false):void
		{
			var keys:Array=DictionaryUtil.getKeys(_avatarPartCache);
			var len:int=keys.length;
			var iter:int;
			for (; iter != len; ++iter)
			{
				optimizeAvatar(_avatarPartCache[keys[iter]], igenorTime);
			}
			keys=null;
		}

		/**
		 *清除部件缓存
		 * @param aps
		 * @param removeFromLoader
		 *
		 */
		public static function optimizeAvatar(aps:AvatarPartSource, igenorTime:Boolean=false):void
		{
			if (aps.refCount <= 0 && (aps.isTimeout(igenorTime)))
			{
				//释放渲染内存
				aps.dispose();
				_avatarPartCache[aps.id]=null;
				delete _avatarPartCache[aps.id];
				LoaderUtil.avatarLoader.remove(aps.id);
			}
		}

		/**
		 *清除所有特效缓存
		 *
		 */
		public static function optimizeAllAnimation(igenorTime:Boolean=false):void
		{
			var keys:Array=DictionaryUtil.getKeys(_animationSourceCache);
			var len:int=keys.length;
			var iter:int;
			for (; iter != len; ++iter)
			{
				optimizeAnimatoin(_animationSourceCache[keys[iter]], igenorTime);
			}
			keys=null;
		}

		/**
		 * 清除特效缓存
		 * @param aps
		 * @param removeFromLoader
		 */
		public static function optimizeAnimatoin(aps:AnimationSource, igenorTime:Boolean=false):void
		{
			if (aps.refCount <= 0 && (aps.isTimeout(igenorTime)))
			{
				//释放渲染内存
				aps.dispose();
				_animationSourceCache[aps.id]=null;
				delete _animationSourceCache[aps.id];
				LoaderUtil.aniLoader.remove(aps.id);
			}
		}

		/**
		 * 指定完全的释放资源
		 *
		 */
		public static function absolutelyDispose(type:int, modelId:String, removeFromLoader:Boolean=false):void
		{
			var key:String;
			var keys:Array;
			var len:int;
			var iter:int;
			switch (type)
			{
				case AVATAR:
					keys=DictionaryUtil.getKeys(_avatarPartCache);
					len=keys.length;
					for (; iter != len; ++iter)
					{
						key=_avatarPartCache[keys[iter]];
						if (key.indexOf(modelId) != -1)
						{
							optimizeAvatar(_avatarPartCache[key]);
							break;
						}
					}
					keys=null;
					break;
				case ANIMATION:
					keys=DictionaryUtil.getKeys(_animationSourceCache);
					len=keys.length;
					for (; iter != len; ++iter)
					{
						key=_animationSourceCache[keys[iter]];
						if (key.indexOf(modelId) != -1)
						{
							optimizeAnimatoin(_animationSourceCache[key]);
							break;
						}
					}
					keys=null;
					break;
			}
		}

		/**
		 *动画是否已缓存
		 * @param path
		 * @return
		 *
		 */
		public static function hasAnimationCache(path:String):Boolean
		{
			return _animationSourceCache[path] != null;
		}

		/**
		 *获取动画缓存
		 * @param path
		 * @return
		 *
		 */
		public static function getAnimationCache(path:String):AnimationSource
		{
			return _animationSourceCache[path];
		}

		/**
		 *添加动画缓存
		 * @param aps
		 *
		 */
		public static function addAnimationtCache(aps:AnimationSource):void
		{
			_animationSourceCache[aps.id]=aps;
		}

		public static function get animationCache():Dictionary
		{
			return _animationSourceCache;
		}

		public static function get avatarPartCache():Dictionary
		{
			return _avatarPartCache;
		}

		/**
		 *添加角色部件缓存
		 * @param aps
		 *
		 */
		public static function addAvatarPartCache(aps:AvatarPartSource):void
		{
			_avatarPartCache[aps.id]=aps;
		}

		/**
		 *角色部件是否已缓存
		 * @param path
		 * @return
		 *
		 */
		public static function hasAvaterCache(path:String):Boolean
		{
			return _avatarPartCache[path] != null;
		}

		/**
		 *获取角色部件缓存
		 * @param path
		 * @return
		 *
		 */
		public static function getAvatarCache(path:String):AvatarPartSource
		{
			return _avatarPartCache[path];
		}
		/**UI存在时间*/
		public static var MAX_FREE_UITIME:uint=60000;
		/**纹理存在时间*/
		public static var MAX_FREE_TIME:uint=30000;
		/**回收间隔*/
		public static var MAX_FREE_INTERVAL:uint=10000;
		/**内存回收阀值*/
		public static var MAX_FREE_MEMERY:uint=300;
		/**单次GC最多数量(过多会卡，并且容易导致系统GC)*/
		public static var GC_COUNT_NUM:uint=50;
		/**纹理缓存*/
		private static var _spriteSources:Dictionary=new Dictionary(true);
		/**当前系统内存*/
		private static var _currentMem:uint;
		/**强制回收时触发*/
		public static var onCoercive:Function;
		public static var freeTimes:Object;
		private static var _uiGcTime:int;

		/**
		 * 回收内存，显存
		 *
		 */
		private static function freeAsset():void
		{
			//starling 纹理  显存可回收就回收
			optimizeTexture();
			//内存对象根据内存阀值决定是否回收
			_currentMem=System.totalMemory >> 20;
			if (_currentMem < MAX_FREE_MEMERY) //转化成M少于XXM不回收
			{
				return;
			}
			//displayobject位图
			optimizeAllAvatar();
			optimizeAllAnimation();
			//UI资源
			var cur:int=getTimer();
			if (!_uiGcTime)
			{
				_uiGcTime=cur;
			}
			if ((cur - _uiGcTime) > MAX_FREE_UITIME)
			{
				_uiGcTime=cur;
				App.asset.autoGc();
			}
		}

		/**
		 *  回收纹理
		 * @param isCoercive 是否强制回收
		 *
		 */
		public static function optimizeTexture(isCoercive:Boolean=false):void
		{
//			var spriteItem:SpriteSource=null;
//			var count:int=0;
//			var now:int = getTimer();
//			for each (spriteItem in _spriteSources)
//			{
//				if (count > GC_COUNT_NUM) //释放的数量够多了
//				{
//					return;
//				}
//				count++;
//				var id:String = spriteItem.id;
//				var freeTime:int=(freeTimes && freeTimes[id]) ? (freeTimes[id] || MAX_FREE_TIME) : MAX_FREE_TIME;
//				if (((now- spriteItem.lastTime) > freeTime))
//				{
//					spriteItem.dispose();
//					delete _spriteSources[id];
//				}
//			}
//			if (isCoercive && onCoercive != null)
//			{
//				onCoercive();
//			}
		}

		/**
		 * 获取avatarpart
		 * @param itemName
		 * @param type
		 * @return
		 *
		 */
		public static function GetAvatarItem(itemName:String, atMount:Boolean):*
		{
//			if (!itemName && itemName == "")
//			{
				return null;
//			}
//			var item:stempest.engine.graphics.avatar.AvatarPartSource=_spriteSources[itemName];
//			if (!item)
//			{
//				item=new stempest.engine.graphics.avatar.AvatarPartSource(itemName);
//				_spriteSources[itemName]=item;
//			}
//			if (!item.atMount && atMount)
//			{
//				item.atMount=true;
//			}
//			else if (item.atMount && !atMount)
//			{
//				item.atMount=false;
//			}
//			item.incr();
//			return item;
		}

		/**
		 * 获取特效部件
		 * @param id
		 * @param param2
		 * @param priority
		 * @return
		 *
		 */
		public static function GetEffectItem(itemName:String):*
		{
//			if (!itemName && itemName == "")
//			{
				return null;
//			}
//			var item:AnimationPartSource=_spriteSources[itemName];
//			if (!item)
//			{
//				item=new AnimationPartSource(itemName);
//				_spriteSources[itemName]=item;
//			}
//			item.incr();
//			return item;
		}


		/**
		 * 清理场景部件对象
		 *
		 */
		public static function clear(type:Class=null):void
		{
//			var spriteItem:SpriteSource=null;
//			for each (spriteItem in _spriteSources)
//			{
//				if (!type || spriteItem is type)
//				{
//					spriteItem.dispose();
//					_spriteSources[spriteItem.id]=null;
//					delete _spriteSources[spriteItem.id];
//				}
//			}
		}

		public static function get spriteSources():Dictionary
		{
			return _spriteSources;
		}
		setInterval(freeAsset, MAX_FREE_INTERVAL);
	}
}
