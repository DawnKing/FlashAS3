package tempest.engine.graphics.animation
{
	import flash.display.BitmapData;
	import flash.system.ApplicationDomain;
	import flash.utils.getTimer;
	
	import common.SceneCache;
	
	import org.assetloader.loaders.SWFLoader;
	
	import tempest.core.IDisposable;
	import tempest.engine.graphics.TPBitmap;
	import tempest.utils.ClassUtil;

	/**
	 * 特效部件资源
	 * @author zhangyong
	 *
	 */
	public class AnimationSource implements IDisposable
	{
		/***动画位图列表*/
		private var bitmaps:Array=[];
		/***索引*/
		private var _id:String;
		/***引用数量*/
		private var _refCount:int=0;

		public function get id():String
		{
			return _id;
		}

		public function AnimationSource(loader:SWFLoader, id:String)
		{
			_id=id;
			if (loader)
			{
				var domain:ApplicationDomain=loader.contentLoaderInfo.applicationDomain;
				if (!domain || !domain.hasDefinition("Info"))
				{
					trace("资源错误，缺少Info.xml类：" + id);
					SceneCache.optimizeAnimatoin(this);
					loader.destroy();
					loader=null;
					return;
				}
				var info:XML=new XML(ClassUtil.getInstanceByClass(domain.getDefinition("Info") as Class));
				var frames:XMLList=info["frames"].elements("frame");
				for each (var frame:XML in frames)
				{
					var __id:String=frame.@id;
					var offsetX:int=parseInt(frame.@offset_x);
					var offsetY:int=parseInt(frame.@offset_y);
					var bitmapData:BitmapData=ClassUtil.getInstanceByClass(domain.getDefinition(__id) as Class);
					add(parseInt(__id), new TPBitmap(bitmapData, offsetX, offsetY));
				}
				//卸载资源
				loader.destroy();
				loader=null;
			}
		}

		public function add(id:int, bm:TPBitmap):void
		{
			bitmaps[id]=bm;
		}

		public function get(frame:int):TPBitmap
		{
			return bitmaps[frame];
		}
		/**最后引用处理时间*/
		private var _lastTime:int;

		public function get lastTime():int
		{
			return _lastTime;
		}

		public function allocate():AnimationSource
		{
			_refCount++;
			_lastTime=getTimer();
			return this;
		}

		/**
		 * 是否可释放
		 *
		 */
		public function isTimeout(igenorTime:Boolean):Boolean
		{
			var freeTime:int=(SceneCache.freeTimes && SceneCache.freeTimes[id]) ? (SceneCache.freeTimes[id] || SceneCache.AVATAPART_TIMEOUT) : SceneCache.AVATAPART_TIMEOUT;
			return ((getTimer() - _lastTime) > freeTime);
		}

		/**
		 *引用数量
		 * @return
		 *
		 */
		public function get refCount():int
		{
			return _refCount;
		}

		public function release():void
		{
			_refCount--;
			_lastTime=getTimer();
		}

		public function dispose():void
		{
			var bitmap:TPBitmap;
			for each (bitmap in bitmaps)
			{
				bitmap.dispose();
			}
		}

		/**
		 * 获取特效镜像资源
		 * @param path
		 * @param w
		 * @return
		 *
		 */
		public function cloneMirror(path:String, w:int):AnimationSource
		{
			var animationSource:AnimationSource=new AnimationSource(null, path);
			var len:int=bitmaps.length;
			var i:int=0;
			var _tp:TPBitmap;
			for (; i != len; i++)
			{
				_tp=bitmaps[i];
				if (_tp)
				{
					animationSource.add(i, (bitmaps[i] as TPBitmap).getYMI(w));
				}
			}
			return animationSource;
		}
	}
}
