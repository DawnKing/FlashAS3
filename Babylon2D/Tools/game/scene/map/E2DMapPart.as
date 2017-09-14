package game.scene.map
{
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.net.URLStream;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    
    import easiest.rendering.sprites.Sprite2D;


    /**
	 * 地图切片 （自己管理加载，注意与atfLoader区别）
	 * @author zhangyong
	 *
	 */
	public final class E2DMapPart extends Sprite2D
	{
		/**允许的最大耗时*/
		public static const MAX_FRAME_MS:uint=3;
		/**最大尝试下载次数*/
		private static const MAX_TRYCOUNT:uint=2;
		/**最大同时下载数量*/
		private static const MAX_DOWNLOAD_COUNT:uint=2;
		/**地图切片任务集中列表*/
		private static const _mapPartTasks:Vector.<E2DMapPart>=new Vector.<E2DMapPart>();
        public var userTag:uint;

		public function get atfBuffer():ByteArray
		{
			return _atfBuffer;
		}

		public static function get loadingCount():uint
		{
			var count:int=0;
			for (var i:int=0; i < _mapPartTasks.length; i++)
			{
				if (_mapPartTasks[i] && _mapPartTasks[i].status < STATUS_UNCOMPRESS)
					count++;
			}
			return count;
		}

		/**
		 * 添加任务
		 * @param mp
		 *
		 */
		private static function addTask(mp:E2DMapPart):void
		{
			//从任务列表移除
			mp.isNoAction=false;
			var idx:int=_mapPartTasks.indexOf(mp);
			if (idx >= 0)
				return;
			_mapPartTasks.splice(0, 0, mp);
		}

		/**
		 * 移除任务
		 * @param mp
		 *
		 */
		private static function removeTask(mp:E2DMapPart):void
		{
			//从任务列表移除
			var idx:int=_mapPartTasks.indexOf(mp);
			if (mp)
				mp.isNoAction=true;
			if (idx >= 0)
				_mapPartTasks.splice(idx, 1);
		}

		/**统计当前下载数*/
		private static var downloadCount:int;

		/**
		 * 清空加载数
		 *
		 */
		public static function clearCount():void
		{
			downloadCount=0;
		}


		/**
		 * MapPart任务调度心跳
		 *
		 */
		public static function updateTasks(realCurrTime:uint, avgMs:int):void
		{
			var goToNextFrame:Boolean=false;
			for (var i:int=0; i < _mapPartTasks.length; i++)
			{
				var ms:int=(getTimer() - realCurrTime);
				if (ms > (avgMs + MAX_FRAME_MS)) //耗时已经超过了3毫秒,就退出
				{
					return;
				}
				var mp:E2DMapPart=_mapPartTasks[i];
				if (!mp)
				{
					_mapPartTasks.splice(i, 1);
					i--;
					continue;
				}
				switch (mp.status)
				{
					case STATUS_CREATED: //状态-构造完毕
						mp.isNoAction=false;
						mp.donwload(); //下载 
						break;
					case STATUS_CLOSED: //状态-被关闭
						mp.isNoAction=true;
						_mapPartTasks.splice(i, 1);
						i--;
						break;
					case STATUS_DONWLOAD_BEGIN: //状态-开始下载
						break;
					case STATUS_DONWLOAD_ERROR_TRY: //状态-错误尝试
						mp.donwload(); //下载
						break;
					case STATUS_DONWLOAD_ERROR: //状态-完全错误
						mp.isNoAction=true;
						_mapPartTasks.splice(i, 1);
						i--;
						break;
					case STATUS_IS_EMPTY_PART: //状态-空切片
						mp.isNoAction=true;
						_mapPartTasks.splice(i, 1);
						i--;
						break;
					case STATUS_DONWLOAD_COMPLETE: //状态-下载完成
						mp.uncompress(); //解压
						break;
					case STATUS_UNCOMPRESS: //状态-解压
						//告一段落了，等待atf流被插入到贴图缓冲区，然后上传到显卡
						break;
					case STATUS_TEXTURE_READYED: //状态-准备插入到动态贴图缓冲区
						mp.insertTextureBuffer();
                        mp.isNoAction=true;
                        _mapPartTasks.splice(i, 1);
						break;
//					case STATUS_TEXTURE_INSERTED: //状态-插入到动态贴图缓冲区
//						//告一段落，等待atf上传到显卡之后的回调吧
//						break;
//					case STATUS_TEXTURE_UPDATED: //状态-插入到动态贴图缓冲区完成
//						break;
				}
			}
		}

		/**最后访问时间(过期可能被释放)*/
		public var lastVisiTime:int;
		/**尝试加载次数*/
		private var _tryCount:uint=0;
		/**loader*/
		private var _urlStream:URLStream;
		/**url地址*/
		private var _url:String;
		/**已下载完成的*/
		public var isNoAction:Boolean;
		/**atf缓冲区*/
		private var _atfBuffer:ByteArray;
		//地图标识key
		public var key:uint;
		//atf所在池的位置
		public var atfPos:int=-1;
		//是否支持透明
		public var supportAlpha:Boolean=false;
		//状态
		public var status:uint;
		/////////////////////////////////////////////
		//状态-构造完毕
		public static const STATUS_CREATED:uint=0;
		//状态-开始下载
		public static const STATUS_DONWLOAD_BEGIN:uint=1;
		//状态-被关闭
		public static const STATUS_CLOSED:uint=2;
		//状态-错误尝试
		public static const STATUS_DONWLOAD_ERROR_TRY:uint=3;
		//状态-完全错误
		public static const STATUS_DONWLOAD_ERROR:uint=4;
		//状态-空切片
		public static const STATUS_IS_EMPTY_PART:uint=5;
		//状态-下载完成
		public static const STATUS_DONWLOAD_COMPLETE:uint=6;
		//状态-解压
		public static const STATUS_UNCOMPRESS:uint=8;
		//状态-插入贴图缓冲区，准备好了
		public static const STATUS_TEXTURE_READYED:uint=9;
		//状态-动态贴图缓冲区，插入了
		public static const STATUS_TEXTURE_INSERTED:uint=10;
		//状态-动态缓冲区上传到显卡了
		public static const STATUS_TEXTURE_UPDATED:uint=11;


		/**
		 * 地图切片
		 * @param thumSubTexture 缩略图
		 * @param url url字符串
		 * @param pkey key
		 * @param pHighestPriority 是否高优先级
		 *
		 */
		public function E2DMapPart(url:String, pkey:uint, partW:int, partH:int)
		{
			super();
			_urlStream=new URLStream();
			_url=name=url;
			key=pkey;
			//高宽
			width=partW;
			height=partH;
			_tryCount=0;

			//状态-构造完毕
			status=STATUS_CREATED;
			addTask(this);

			mouseEnabled = true;
		}


		public function get url():String
		{
			return _url;
		}

		/**
		 * 下载
		 */
		private function donwload():void
		{
			if (downloadCount > MAX_DOWNLOAD_COUNT)
			{
				return;
			}
			downloadCount++;
			//状态-开始下载
			status=STATUS_DONWLOAD_BEGIN;
			_urlStream.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
			_urlStream.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
			_urlStream.load(new URLRequest(Object(Config).getVersionUrl(_url)));
		}

		private function onIOError(event:IOErrorEvent):void
		{
			if (status == STATUS_CLOSED)
				return;
			downloadCount--;
			_urlStream.removeEventListener(Event.COMPLETE, onComplete);
			_urlStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			trace("[MapPart]IOError:" + _url + "|" + event.text);
			if (_tryCount < MAX_TRYCOUNT)
			{
				//状态-错误尝试
				status=STATUS_DONWLOAD_ERROR_TRY;
				_tryCount++;
			}
			else
			{
				status=STATUS_DONWLOAD_ERROR; //状态-错误
			}
		}

		private function onComplete(e:Event):void
		{
			if (status == STATUS_CLOSED)
				return;
			downloadCount--;
			//状态-下载完成
			status=STATUS_DONWLOAD_COMPLETE;

			//全部读取
			if (_atfBuffer)
				_atfBuffer.clear();
			_urlStream.removeEventListener(Event.COMPLETE, onComplete);
			_urlStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			//判断是否全透明图层
			if (_urlStream.bytesAvailable <= 550)
			{
				//状态-空切片
				status=STATUS_IS_EMPTY_PART;
				//关闭了，不读取了
				if (_urlStream.connected)
					_urlStream.close();
			}
			else
			{
				//读取atf文件
				_atfBuffer=new ByteArray();
				_urlStream.readBytes(_atfBuffer, 0, _urlStream.bytesAvailable);
				_urlStream.close();
			}

		}

        //解压素材函数
        private function uncompress():void
        {
            try
            {
                //状态-解压完成
                status=STATUS_UNCOMPRESS;
                //解压
                _atfBuffer.uncompress();
                //检查是否支持透明
//                supportAlpha=DyncAtfTexture.isSupportAlpha(_atfBuffer);

                status=STATUS_TEXTURE_READYED;
            }
            catch (e:Error)
            {
                //状态-错误
                status=STATUS_DONWLOAD_ERROR;
            }
        }

		//开始插入到贴图缓冲区
		private function insertTextureBuffer():void
		{
			//状态-上传贴图开始
			status=STATUS_TEXTURE_INSERTED;
			setTexture(_atfBuffer);
            status = STATUS_TEXTURE_UPDATED;
		}

		//上传贴图完成
		public function uploadTextureComplete(dync:*, index:uint):void
		{
			if (status == STATUS_CLOSED)
				return;
			//通过动态贴图获得
			var coreIdx:int=dync.getCoreIndex(atfPos);
			//核心组合贴图序号不一致过滤掉
			if (coreIdx != index)
				return;

			//贴图存在并且不是缩略图，就释放，缩略图mappart对象自己释放
			if (texture)
				texture.dispose();
			//开始更新
			//插入完成
			status=STATUS_TEXTURE_UPDATED;
		}

		//从缓冲区移除
		public function removeTextureBuffer():void
		{
			atfPos=-1;
			//必须是已下载，解压，解密之后的状态才享受该服务
			if (status > STATUS_UNCOMPRESS)
			{
				status=STATUS_UNCOMPRESS;
				removeTask(this);
			}
		}

		public function close():void
		{
			//状态-完全关闭
			if (status == STATUS_DONWLOAD_BEGIN) //如果刚开始就被中断了，就没有加载错误和加载完毕了
			{
				downloadCount--;
			}
			status=STATUS_CLOSED;

			_urlStream.removeEventListener(Event.COMPLETE, onComplete);
			_urlStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			//连接关闭
			if (_urlStream.connected)
				_urlStream.close();
			//释放atf二进制数据
			if (_atfBuffer)
				_atfBuffer.clear();
			//释放贴图
//			if (texture)
//				texture.dispose();
			removeFromParent(true);
			//atf位置
			atfPos=-1;
			supportAlpha=false;
			//缩略图释放
			//移除任务
			removeTask(this);
		}
	}
}
