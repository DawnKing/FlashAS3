package tempest.engine.graphics.avatar.vo
{
	import flash.display.BitmapData;
	import flash.system.ApplicationDomain;
	import flash.utils.getTimer;
	
	import common.SceneCache;
	
	import org.assetloader.loaders.SWFLoader;
	
	import tempest.core.IDisposable;
	import tempest.engine.graphics.TPBitmap;
	import tempest.engine.graphics.loader.LoaderUtil;
	import tempest.enum.Status;
	import tempest.template.Action;
	import tempest.utils.ClassUtil;

	/**
	 * 部件资源
	 * @author zhangyong
	 *
	 */
	public class AvatarPartSource implements IDisposable
	{
		/***部件位图列表*/
		private var _bitmaps:Object={};
		/***索引*/
		private var _id:String;
		/***引用数量*/
		private var _refCount:int=0;
		/***分包包含动作*/
		private var _actions:Vector.<Action>=null;
		/***分包前缀*/
		private var _prefix:int;
		/***分包后缀*/
		private var _lastfix:int;
		/*** 真实高度*/
		public var height:int=750;
		/*** 真实宽度*/
		public var width:int=750;
		/*** 中心点偏移*/
		public var center_offset:int=425;
		/*** 身体受击点偏移*/
		public var body_offset:int=375;
		/*** 头顶偏移*/
		public var head_offset:int=350;
		/**方向初始化*/
		public var dirInits:Object={};
		/**是否已释放*/
		public var disposed:Boolean=false;
		/**是否可被释放*/
		public var canDispose:Boolean=true;

		public function get refCount():int
		{
			return _refCount;
		}

		public function get id():String
		{
			return _id;
		}

		public function AvatarPartSource(loader:SWFLoader, id:String)
		{
			frames={};
			_id=id;
			_prefix=LoaderUtil.getPartPrefix(_id);
			_lastfix=LoaderUtil.getPartLastfix(_id);
			initLoader(loader);
			disposed=false;
		}

		/**
		 * 创建所有的
		 *
		 */
		public function createAll():void
		{
			var domain:ApplicationDomain=loader.contentLoaderInfo.applicationDomain;
			if (!domain)
			{
				SceneCache.optimizeAvatar(this);
				return;
			}
			var $frameInfo:FrameInfo;
			var $framekey:String;
			var bitmapData:BitmapData;
			for ($framekey in frames)
			{
				if (!_bitmaps[$framekey])
				{
					$frameInfo=frames[$framekey];
					if (domain.hasDefinition($framekey))
					{
						bitmapData=ClassUtil.getInstanceByClass(domain.getDefinition($framekey) as Class);
						_bitmaps[$framekey]=new TPBitmap(bitmapData, $frameInfo.offsetX, $frameInfo.offsetY);
					}
				}
			}
		}

		/**
		 * 创建某个动作某个方向的所有帧
		 * @param status 动作
		 * @param dir 方向
		 *
		 */
		public function createDir(status:int, dir:int):void
		{
			if (!loader.contentLoaderInfo.applicationDomain)
			{
				SceneCache.optimizeAvatar(this);
				return;
			}
			var $frameInfo:FrameInfo;
			var $framekey:String;
			for ($framekey in frames)
			{
				$frameInfo=frames[$framekey];
				if ($frameInfo.status == status && $frameInfo.dir == dir)
				{
					if (!_bitmaps[$framekey])
					{
						get($frameInfo.status, $frameInfo.dir, $frameInfo.frame);
					}
				}
			}
		}
		/**部件资源*/
		private var loader:SWFLoader;
		/**部件帧信息*/
		private var frames:Object;

		/**
		 * 部件加载完毕
		 * @param loader
		 *
		 */
		public function initLoader(loader:SWFLoader):void
		{
			var domain:ApplicationDomain=loader.contentLoaderInfo.applicationDomain;
			if (!domain || !domain.hasDefinition("Info"))
			{
				SceneCache.optimizeAvatar(this);
				trace("资源错误，缺少Info.xml类：" + id);
				loader.destroy();
				loader=null;
				return;
			}
			this.loader=loader;
			var info:XML=new XML(ClassUtil.getInstanceByClass(domain.getDefinition("Info") as Class));
			height=parseInt(info.@height);
			width=parseInt(info.@width);
			center_offset=parseInt(info.@center_offset);
			if (info.hasOwnProperty("@body_offset"))
			{ //武器、坐骑其他部件不需要偏移
				body_offset=parseInt(info.@body_offset);
				head_offset=parseInt(info.@head_offset);
			}
			var actions:XMLList=null;
			if (info["frames"].hasOwnProperty("actions"))
			{
				actions=info["frames"]["actions"].elements("action");
			}
			else if (info.hasOwnProperty("actions"))
			{
				actions=info["actions"].elements("action");
			}
			if (actions)
			{
				var action:XML=null;
				for each (action in actions)
				{
					var status:int=parseInt(action.@status);
					var total:int=parseInt(action.@total);
					var interval:int=parseInt(action.@interval);
					var effect:int=parseInt(action.@effect);
					var faceCount:int=parseInt(action.@faceCount);
					var a:Action=new Action();
					a.init(status, total, interval, effect, faceCount);
					addAction(a);
				}
			}
			var frameList:XMLList=info["frames"].elements("frame");
			var frame:XML=null;
			for each (frame in frameList)
			{
				var bitmapData:BitmapData=null;
				var frameInfo:FrameInfo=new FrameInfo();
				frameInfo.key=frame.@id
				if (!frame.hasOwnProperty("@symbol"))
				{ //如果无symbol
					frameInfo.offsetX=parseInt(frame.@offset_x);
					frameInfo.offsetY=parseInt(frame.@offset_y);
				}
				else
				{ //指向其他动作
					frameInfo.symbol=frame.@symbol;
				}
				frameInfo.init();
				frames[frameInfo.key]=frameInfo;
			}
		}

		public function get actions():Vector.<Action>
		{
			return _actions;
		}

		public function get prefix():int
		{
			return _prefix;
		}

		public function get lastfix():int
		{
			return _lastfix;
		}

		/**
		 *添加动作信息
		 * @param status
		 * @param action
		 *
		 */
		public function addAction(action:Action):void
		{
			if (_actions == null)
			{
				_actions=new Vector.<Action>();
			}
			_actions.push(action);
		}

		/**
		 *获取当前状态位图
		 * @param status
		 * @param dir
		 * @param frame
		 * @return
		 *
		 */
		public function get(status:int, dir:int, frame:int):TPBitmap
		{
			if (!loader)
			{
				return null;
			}
			if (disposed)
			{
				return null;
			}
			var $dir:int=dir;
			var $status:int=status;
			var tp:TPBitmap=null;
			var key:String;
			if ($status == Status.DEAD)
			{
				//为了门徒特殊处理
				key=Status.DEAD + "-" + 2 + "-" + 0;
				if (frames[key])
				{
					$dir=2;
				}
				else
				{
					$dir=($dir > 4) ? 3 : 1;
				}
			}
			key=$status + "-" + $dir + "-" + frame;
			var frameInfo:FrameInfo=frames[key];
			///////////sysbol/////////////
			if (frameInfo && frameInfo.symbol)
			{
				key=frameInfo.symbol;
			}
			var keyYMI:String;
			/////////没有找到帧资源////////
			tp=_bitmaps[key];
			if (tp == null)
			{
				//////////创建某个方向所有帧//////////
				var dirKey:String=status + "_" + dir;
				if (!dirInits[dirKey])
				{
					dirInits[dirKey]=true;
					createDir(status, dir);
				}
				/////////////////////////////////////
				if ($dir > 4)
				{
					keyYMI=$status + "-" + (8 - $dir) + "-" + frame;
					tp=_bitmaps[keyYMI];
					if (tp && tp.bitmapData)
					{
						tp=tp.getYMI(width);
						_bitmaps[key]=tp;
						return tp;
					}
					else
					{
						tp=get($status, (8 - $dir), frame);
						if (tp)
						{
							if (!_bitmaps[key])
							{
								_bitmaps[key]=tp;
							}
							if (!frameInfo)
							{
								var __frameInfo:FrameInfo=new FrameInfo();
								__frameInfo.key=key;
								__frameInfo.offsetX=tp.offset_x;
								__frameInfo.offsetY=tp.offset_y;
								__frameInfo.init();
								frames[key]=__frameInfo;
							}
						}
					}
				}
			}
			else
			{
				return tp;
			}
			//////////创建面向的帧资源/////
			if (tp == null)
			{
				if (keyYMI)
				{ //要获取镜像的原始图
					key=keyYMI;
				}
				if (frameInfo)
				{
					var bitmapData:BitmapData=ClassUtil.getInstanceByClass(loader.contentLoaderInfo.applicationDomain.getDefinition(key) as Class);
					tp=new TPBitmap(bitmapData, frameInfo.offsetX, frameInfo.offsetY);
					_bitmaps[key]=tp;
					return null;
				}
			}
			return tp;
		}

		public function get bitmaps():Object
		{
			return _bitmaps;
		}

		private function needYMI(dir:int):Boolean
		{
			return dir > 4;
		}
		/**最后引用处理时间*/
		private var _lastTime:int;

		public function get lastTime():int
		{
			return _lastTime;
		}

		public function allocate():AvatarPartSource
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
			if (!canDispose)
			{ //不可被回收
				return false;
			}
			var freeTime:int=(SceneCache.freeTimes && SceneCache.freeTimes[id]) ? (SceneCache.freeTimes[id] || SceneCache.AVATAPART_TIMEOUT) : SceneCache.AVATAPART_TIMEOUT;
			return igenorTime || ((getTimer() - _lastTime) > freeTime);
		}

		public function release():void
		{
			_refCount--;
		}

		public function dispose():void
		{
			disposed=true;
			if (loader)
			{
				this.loader.destroy();
				this.loader=null;
			}
			this.frames=null;
			dirInits=null;
			var tp:TPBitmap;
			for each (tp in _bitmaps)
			{
				tp.dispose();
			}
			_bitmaps=null;
			_actions=null;
		}
	}
}

class FrameInfo
{
	public var key:String;
	public var offsetX:int;
	public var offsetY:int;
	public var symbol:String;
	public var status:int;
	public var dir:int;
	public var frame:int;

	public function init():void
	{
		var arr:Array=key.split("-");
		status=arr[0];
		dir=arr[1];
		frame=arr[2];
	}
}
