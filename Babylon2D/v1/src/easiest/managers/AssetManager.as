package easiest.managers
{
    import easiest.core.EasiestCore;
    import easiest.core.Log;
    import easiest.unit.Assert;

    import flash.utils.Dictionary;

    /**
	 * 资源管理器，管理资源的下载，缓存
	 * 下载失败AssetData的asset将为null
	 * @author caijingxiao
	 * 
	 */ 
	public final class AssetManager
	{
        private static const CLASS_NAME:String = "AssetManager";
        private static var DISPOSE_SOMETIMES_CACHE:int;
        public static const MAX_LIMIT:int = 5;	 // 限制同时最多下载，其余的进入等待下载队列

        private static const ASSET_LOADER_COUNT:int = 200;
        private static var m_assetLoaderPool:ObjectPool;
        
		private static var m_waitLoadList:Dictionary = new Dictionary(true);	// 等待加载的列表.key:url;    value: AssetLoader
        private static var m_loadingList:Dictionary = new Dictionary(true);	// 正在加载的列表.key:url;    value: AssetLoader
        private static var m_sometimesCacheList:Dictionary = new Dictionary(true);  // url - AssetLoader
        private static var m_alwaysCacheList:Dictionary = new Dictionary(true);
        
        // 记录信息，单位：字节
        private static var m_totalMemory:uint = 0; 
        private static var m_sometimesCacheMemory:uint = 0;
        private static var m_alwaysCacheMemory:uint = 0;
        
        private static var m_idleLoadList:Array = [];
        
        public static function start():void
        {
            m_assetLoaderPool = new ObjectPool(AssetLoader, ASSET_LOADER_COUNT, 10);
            AssetLoader.init(MAX_LIMIT);
            
            if (EasiestCore.isDebug)    // 缓存时间
                DISPOSE_SOMETIMES_CACHE = 1;
            else
                DISPOSE_SOMETIMES_CACHE = 60*1000;
            
            FrameManager.add(process, FrameManager.IDLE);
        }        
        
        private static function process():void
        {
            processCache();
            startNewLoad();
        }
        
		/**
		 * 加载资源
         * 注意，同一个url，同一个callback不可以多次加载，可以用hasLoading判断是否在加载中，或者dispose的时候要stop
		 * @param url 加载路径
		 * @param callback 加载完成回调函数，函数格式function(assetData:AssetData)，加载失败时，assetData.asset==null
		 * @param assetType 资源类型，如果为空，则根据文件后缀名判断类型。swf对应MovieClip，png、jpeg对应Bitmap。
         * @param cacheType 缓存类型
         * @param param 额外参数
         *
		 */
		public static function load(url:String, callback:Function, assetType:String, cacheType:int = AssetType.CACHE_SOMETIMES, param:Object = null):void
		{
            if (url == null)
                throw new Error("url不能为空");
			if (callback == null)
				throw new Error("callback不能为空");
            if (assetType == null || assetType == "")
                throw new Error("资源类型不能为空"+url+new Error().getStackTrace());

            Log.debug1(url);

			if (addLoading(url, callback))
                return;

            var asset:AssetLoader = getAssetLoaderCache(url);
            if (asset != null)
            {
                asset.cacheClear();
                
                if (asset.url != url)
                    throw new Error();
            }
            else
            {
                asset = m_assetLoaderPool.getObject() as AssetLoader;
                asset.url = url;
                asset.assetType = assetType;
                asset.cacheType = cacheType;
            }

            asset.param = param;
            asset.callbackList.push(callback);
            
            if (assetType == AssetType.SPRITE_SHEET && asset.callbackList.length > 1)
                throw new Error("序列帧应该只加载一次，其余的回调由SpriteAnimation管理"+url);
            
            m_waitLoadList[url] = asset;
		}
        
        private static function getAssetLoaderCache(url:String):AssetLoader
        {
            var asset:AssetLoader = m_sometimesCacheList[url];
            if (asset == null)
                asset = m_alwaysCacheList[url];
            if (asset == null)
                return null;
            return asset;
        }        
        
        private static function isCache(url:String):Boolean
        {
            if (url in m_sometimesCacheList)
                return true;
            return url in m_alwaysCacheList;
        }        
        
        public static function stop(url:String, callback:Function):Boolean
        {
            if (url == null || url == "")
                return false;
            if (url in m_waitLoadList)
                var assetLoader:AssetLoader = m_waitLoadList[url] as AssetLoader;
            
            if (url in m_loadingList)
            {
                if (assetLoader != null)
                    throw new Error("不可能同时存在于m_waitLoadList和m_loadingList");
                assetLoader = m_loadingList[url] as AssetLoader;
            }
            
            if (assetLoader == null)
                return false;
            if (!assetLoader.hasLoad(callback))
                return false;
            assetLoader.stop(callback);
            if (assetLoader.callbackList.length == 0)
            {
                delete m_waitLoadList[assetLoader.url];
                delete m_loadingList[assetLoader.url];
                if (!isCache(assetLoader.url))
                {
                    assetLoader.clear();
                    m_assetLoaderPool.disposeObject(assetLoader);
                }
            }
            return true;
        }
        
        public static function hasLoading(url:String, callback:Function):Boolean
        {
            if (AssetLoader.errorList.indexOf(url) != -1)
                return false;
            
            if (url in m_waitLoadList)
            {
                var asset:AssetLoader = m_waitLoadList[url] as AssetLoader;
                return asset.callbackList.indexOf(callback) != -1;
            }
            
            if (url in m_loadingList)
            {
                asset = m_loadingList[url] as AssetLoader;
                return asset.callbackList.indexOf(callback) != -1;
            }
            
            return false;
        }
        
        public static function hasCache(url:String):Boolean
        {
            var asset:AssetLoader = getAssetLoaderCache(url);
            return asset != null;
        }        
        
        public static function getCache(url:String):Object
        {
            var asset:AssetLoader = getAssetLoaderCache(url);
            if (asset == null)
                return null;
            return asset.cloneCache();
        }        
        
        private static function startNewLoad():void
        {
            for each (asset in m_waitLoadList) 
            {
                if (asset.url == null)
                    throw new Error();
            } 
            var loadCount:int = 0;  // 限制下载数量
            for each (asset in m_loadingList) 
            {
                loadCount++;
            }
            if (loadCount >= MAX_LIMIT)
                return;
            
            for each (var asset:AssetLoader in m_waitLoadList) 
            {
                delete m_waitLoadList[asset.url];
                m_loadingList[asset.url] = asset;
                
                if (asset.isCache)
                    asset.loadCache(onAssetLoaderComplete);
                else
                    asset.load(onAssetLoaderComplete);
                
                loadCount++;
                if (loadCount >= MAX_LIMIT)
                    return;
            } 
        }
        
        // 先判断是否正在加载这个资源，如果正在加载，直接返回
        private static function addLoading(url:String, callback:Function):Boolean
        {
            // 如果是错误的资源，不重复加载
            if (AssetLoader.errorList.indexOf(url) != -1)
            {
                // 直接回调，让外部处理错误逻辑
                var ret:AssetData = new AssetData;
                ret.url = url;
                callback(ret); 
                return true;
            }
            
            if (EasiestCore.isDebug)
            {
                checkSameCallback(m_waitLoadList, url, callback);
                checkSameCallback(m_loadingList, url, callback);
            }
            
            if (checkInLoadList(m_waitLoadList, url, callback))
                return true;
            
            return checkInLoadList(m_loadingList, url, callback);
        }
        
        private static function checkInLoadList(loadList:Dictionary, url:String, callback:Function):Boolean
        {
            if (url in loadList)
            {
                var asset:AssetLoader = loadList[url] as AssetLoader;
                if (asset.callbackList.indexOf(callback) != -1)
                    Log.error("重复加载"+url+new Error().getStackTrace(), CLASS_NAME);
                asset.callbackList.push(callback);
                return true;
            }            
            return false;
        }
        
        private static function checkSameCallback(loadList:Dictionary, url:String, callback:Function):void
        {
            for each (var asset:AssetLoader in loadList) 
            {
                if (asset.param == AssetType.SKIP_CHECK)
                    continue;
                for each (var cal:Function in asset.callbackList)
                {
                    if (cal == onIdleComplete)
                        continue;
                    if (cal == callback)
                        Log.error("同一个callback，有多个url再加载，极可能是逻辑错误，会导致图片替换的bug"+url, CLASS_NAME);
                }
            }            
        }
        
        private static function onAssetLoaderComplete(asset:AssetLoader):void
        {
            delete m_loadingList[asset.url];
            
            cacheHandler(asset);
        }
        
        private static function cacheHandler(assetLoader:AssetLoader):void
        {
            if (!assetLoader.hasCache())
            {
                assetLoader.clear();
                m_assetLoaderPool.disposeObject(assetLoader);
                return;
            }
            
            switch (assetLoader.cacheType)
            {
                case AssetType.CACHE_NONE:
                    assetLoader.clear();
                    m_assetLoaderPool.disposeObject(assetLoader);
                    return;
                case AssetType.CACHE_SOMETIMES:
                    if (!assetLoader.isCache)
                        m_sometimesCacheMemory += assetLoader.memory;
                    m_sometimesCacheList[assetLoader.url] = assetLoader;
                    assetLoader.timer = FrameManager.timer;
                    break;
                case AssetType.CACHE_ALWAYS:
                    if (!assetLoader.isCache)
                        m_alwaysCacheMemory += assetLoader.memory;
                    m_alwaysCacheList[assetLoader.url] = assetLoader;
                    break;
            }
            if (!assetLoader.isCache)
                m_totalMemory += assetLoader.memory;
        }
        
        private static function processCache():void
        {
            var time:int = FrameManager.timer - DISPOSE_SOMETIMES_CACHE; 
            for (var url:String in m_sometimesCacheList) 
            {
                var assetLoader:AssetLoader = m_sometimesCacheList[url];
                if (url != assetLoader.url)
                    throw new Error();
                if (assetLoader.timer > time || assetLoader.isLoading())
                    continue;
                if (url in m_waitLoadList)
                    continue;
                if (url in m_loadingList)
                    continue;
                
                delete m_sometimesCacheList[url];
                m_sometimesCacheMemory -= assetLoader.memory;
                
                assetLoader.clear();
                m_assetLoaderPool.disposeObject(assetLoader);
            }
        }
        
        public static function hasLoad():Boolean
        {
            for each (var asset:AssetLoader in m_waitLoadList)
            {
                if (asset)
                    return true;
            }
            return false;
        }        
        
        // 空闲下载：当前没有下载任何资源时下载
        public static function idleLoad(url:String, callback:Function, assetType:String, cacheType:int=0/*AssetType.CACHE_NONE*/):void
        {
            var data:IdleLoadData = new IdleLoadData;
            data.url = url;
            data.callback = callback;
            data.assetType = assetType;
            data.cache = cacheType;
            
            m_idleLoadList.push(data);
            FrameManager.add(processIdleLoad, FrameManager.IDLE);
        }        
        
        private static function processIdleLoad():void
        {
            if (hasLoad())
                return;
            var data:IdleLoadData = m_idleLoadList.shift();
            load(data.url, onIdleComplete, data.assetType, data.cache, data.callback);
            
            if (m_idleLoadList.length == 0)
                FrameManager.remove(processIdleLoad);
        }
        
        private static function onIdleComplete(asset:AssetData):void
        {
            var callback:Function = asset.param as Function;
            if (callback != null)
                callback(asset);
            
//            Log.debug1("空闲下载:url="+asset.url, CLASS_NAME);
        }
        
        public static function getMemoryInfo():String
        {
            var result:String = "";
            result += "Total:"+int(m_totalMemory/1024/1024)+"MB";
            result += "  Sometime:"+int(m_sometimesCacheMemory/1024)+"KB";
            result += "  Always:"+int(m_alwaysCacheMemory/1024)+"KB";
            return result;
        }
        
        public static function getLoadInfo():String
        {
            var result:String = "";
            result += " assetLoaderPool:" + m_assetLoaderPool.size + "/" + m_assetLoaderPool.totalSize;
            result += " " + AssetLoader.getLoadInfo();
            result += "\nalwaysCacheList："+getListInfo(m_alwaysCacheList);
            result +="\nsometimesCacheList："+getListInfo(m_sometimesCacheList);

            result += "\nloadingList："+getListInfo(m_loadingList);
            result += "\nwaitLoadList："+getListInfo(m_waitLoadList);
            return result;
        }
        
        private static function getListInfo(list:Dictionary):String
        {
            const LINE_COUNT:int = 10;
            var asset:AssetLoader;
            var i:int = 0;
            var result:String = "";
            for each (asset in list) 
            {
                result += i++ % LINE_COUNT == 0 && i != 0 ? "\n" : "  |  ";
                result += asset.url.slice(asset.url.lastIndexOf("/")+1);
            }
            return i+ result;
        }
        
        public static function processTest():void
        {
            AssetLoader.processTest();
            var assetLoader:AssetLoader, url:String;
            Assert.assertTrue1(m_assetLoaderPool.size >= 0);
            
            // 测试正在加载的AssetLoader
            for (url in m_waitLoadList) 
            {
                assetLoader = m_waitLoadList[url];
                Assert.assertEquals1(url, assetLoader.url);
                Assert.assertFalse1(url in m_loadingList);
            }
            
            var loadCount:int = 0;
            for (url in m_loadingList) 
            {
                loadCount++;
            }
            Assert.assertTrue1(loadCount <= MAX_LIMIT);
            
            // 测试没在加载的AssetLoader
            var assetLoaderList:Vector.<AssetLoader> = new Vector.<AssetLoader>;
            while (m_assetLoaderPool.size > 0)
            {
                assetLoader = m_assetLoaderPool.getObject() as AssetLoader;
                Assert.assertNotNull1(assetLoader);
                Assert.assertEquals1(assetLoader.callbackList.length, 0);
                Assert.assertEquals1(assetLoader.assetType, "");
                Assert.assertEquals1(assetLoader.cacheType, 0);
                Assert.assertFalse1(assetLoader.isLoading());

                Assert.assertNull1(assetLoader.onComplete);
                Assert.assertNull1(assetLoader.urlLoader);
                Assert.assertNull1(assetLoader.loader);
                Assert.assertNull1(assetLoader.assetData.asset);
                Assert.assertFalse1(assetLoader.hasCache());
                Assert.assertFalse1(assetLoader.isCache);
                
                assetLoaderList.push(assetLoader);
            }
            
            for each (assetLoader in assetLoaderList) 
            {
                m_assetLoaderPool.disposeObject(assetLoader);
            }
        }
    }
}

import easiest.core.Log;
import easiest.display.LoaderBytes;
import easiest.display.LoaderExtend;
import easiest.managers.AssetData;
import easiest.managers.AssetType;
import easiest.managers.ObjectPool;
import easiest.net.URLLoaderExtend;
import easiest.unit.Assert;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.LoaderInfo;
import flash.display.MovieClip;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.net.URLLoaderDataFormat;
import flash.system.System;
import flash.utils.ByteArray;

final class AssetLoader
{
    private static var m_errorList:Vector.<String> = new Vector.<String>;
    private static var m_urlLoaderPool:ObjectPool;
    private static var m_loaderPool:Vector.<LoaderExtend>;
    private static var m_loaderBytesPool:Vector.<LoaderBytes>;
    
    private var m_url:String;
    public var callbackList:Vector.<Function> = new Vector.<Function>;
    public var assetType:String = "";
    public var cacheType:int;
    public var memory:uint;
    public var timer:int;
    public var param:Object;
    
    private var m_onComplete:Function;
    private var m_urlLoader:URLLoaderExtend;
    private var m_loader:LoaderExtend;
    private var m_assetData:AssetData = new AssetData;
    private var m_cache:Object;
    private var m_isCache:Boolean = false;

    public function AssetLoader()
    {
    }
    
    public static function init(limit:int):void
    {
        m_urlLoaderPool = new ObjectPool(URLLoaderExtend, limit, 0);
        // 对用一个loader同一时间多次操作load和close极易出现加载错误。因此多放一些缓存，避免同一时间过多的操作
        m_loaderPool = new Vector.<LoaderExtend>();
        for (var i:int = 0; i < limit*2; i++) 
        {
            m_loaderPool.push(new LoaderExtend);
        }
        m_loaderBytesPool = new Vector.<LoaderBytes>;
        for (i = 0; i < limit*2; i++) 
        {
            m_loaderBytesPool.push(new LoaderBytes);
        }
    }
    
    public function clear():void
    {
        if (m_urlLoader != null || m_loader != null)
            throw new Error();
        
        m_url = null;
        callbackList.length = 0;
        assetType = "";
        cacheType = 0;
        memory = 0;
        timer = 0;
        m_isCache = false;
        param = null;

        m_onComplete = null;
        m_assetData.asset = null;
        
        if (m_cache != null)
        {
            if (m_cache is ByteArray)
                ByteArray(m_cache).clear();
            else if (m_cache is XML)
                System.disposeXML(m_cache as XML);
            m_cache = null;
        }
    }
    
    public function cacheClear():void
    {
        if (m_urlLoader != null || m_loader != null)
            throw new Error();
        
        callbackList.length = 0;
        m_isCache = true;
        param = null;
        
        m_onComplete = null;
        m_assetData.asset = null;
    }
    
    public static function get errorList():Vector.<String>
    {
        return m_errorList;
    }
    
    public function load(onComplete:Function):void
    {
        m_onComplete = onComplete;
        
        switch (assetType)
        {
            case AssetType.BITMAP:
            case AssetType.BITMAP_DATA:
            case AssetType.MOVIE_CLIP:
            case AssetType.SPRITE_SHEET:
                loaderHandler();
                break;
            case AssetType.XML:
            case AssetType.BINARY:
            case AssetType.TEXT:
            case AssetType.VARIABLES:
                urlLoaderHandler();
                break;
            default:
                Log.error("未处理的资源类型"+url, this);
                loadComplete();
        }
    }
    
    private function loaderHandler():void
    {
        if (m_loader != null)
            throw new Error;
        
        m_loader = m_loaderPool.shift();
        m_loader.unload();
        m_loader.close();
        m_loader.addEventListener(ErrorEvent.ERROR, onLoadError, false, 0, true);
        m_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete, false, 0, true);
        m_loader.loadURL(url);
    }
    
    private function loaderBytesHandler(bytes:ByteArray):void
    {
        removeLoader();
        
        m_loader = m_loaderBytesPool.shift();
        m_loader.unload();
        m_loader.close();
        m_loader.addEventListener(ErrorEvent.ERROR, onLoadError, false, 0, true);
        m_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete, false, 0, true);
        m_loader.loadBytes(bytes);
        m_loader.assetUrl = url;
    }
    
    private function removeLoaderEvent():void
    {
        m_loader.removeEventListener(ErrorEvent.ERROR, onLoadError);
        m_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
    }
    
    private function removeLoader(close:Boolean=false):void
    {
        if (m_loader == null)
            return;
        removeLoaderEvent();
        if (close)
            m_loader.close();
        m_loader.unload();
        if (m_loader is LoaderBytes)
            m_loaderBytesPool.push(m_loader);
        else
            m_loaderPool.push(m_loader);
        m_loader = null;
    }
    
    protected function onLoaderComplete(event:Event):void
    {
        removeLoaderEvent();
        var loaderInfo:LoaderInfo = m_loader.contentLoaderInfo;
        memory = loaderInfo.bytesTotal;
        
        m_assetData.stageWidth = loaderInfo.width;
        m_assetData.stageHeight = loaderInfo.height;
        
        switch (assetType)
        {
            case AssetType.BITMAP:
                var bitmap:Bitmap = loaderInfo.content as Bitmap;
                if (cacheType != AssetType.CACHE_NONE)
                    m_cache = bitmap.bitmapData;
                bitmapHandler(bitmap.bitmapData);
                break;
            case AssetType.BITMAP_DATA:
                bitmap = loaderInfo.content as Bitmap;
                if (cacheType != AssetType.CACHE_NONE)
                    m_cache = bitmap.bitmapData;
                bitmapDataHandler(bitmap.bitmapData);
                break;
            case AssetType.MOVIE_CLIP:
                if (cacheType != AssetType.CACHE_NONE)
                {
                    m_cache = new ByteArray;
                    loaderInfo.bytes.readBytes(ByteArray(m_cache));
                    loaderInfo.bytes.position = 0;
                }
                swfHandler(loaderInfo);
                break;
            case AssetType.SPRITE_SHEET:
//                byteArrayCacheHandler(loaderInfo.bytes);// 序列帧不需要缓存，由SpriteAnimation缓存
                spriteSheetHandler(loaderInfo);
                break;
            default:
                Log.error("未处理的资源类型onLoaderComplete"+m_urlLoader.url, this);
                loadComplete();
        }
    }

    private function bitmapHandler(bitmapData:BitmapData):void
    {
        while (callbackList.length != 0)
        {
            var bitmap:Bitmap = new Bitmap(bitmapData);
            assetCallback(bitmap, callbackList.shift());
        }
        
        loadComplete();
    }

    private function bitmapDataHandler(bitmapData:BitmapData):void
    {
        while (callbackList.length != 0)
        {
            assetCallback(bitmapData, callbackList.shift());
        }

        loadComplete();
    }
    
    private function swfHandler(loaderInfo:LoaderInfo):void
    {
        var movieClip:MovieClip = loaderInfo.content as MovieClip;
        
        assetCallback(movieClip, callbackList.shift());
        
        if (callbackList.length == 0)
        {
            loadComplete(); 
        }
        else
        {
            var clone:ByteArray = new ByteArray;
            loaderInfo.bytes.readBytes(clone);
            loaderInfo.bytes.position = 0;
            loaderBytesHandler(clone);
        }
    }
    
    private function spriteSheetHandler(loaderInfo:LoaderInfo):void
    {
        m_assetData.url = url;
        m_assetData.param = param;
        
        while (callbackList.length != 0)
        {
            var callback:Function = callbackList.shift();
            callback(m_assetData, loaderInfo);
        }
        
        loadComplete(); 
    }
    
    private function urlLoaderHandler():void
    {
        m_urlLoader = m_urlLoaderPool.getObject() as URLLoaderExtend;
        switch (assetType)
        {
            case AssetType.XML:
            case AssetType.BINARY:
                m_urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
                break;
            case AssetType.TEXT:
                m_urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
                break;
            case AssetType.VARIABLES:
                m_urlLoader.dataFormat = URLLoaderDataFormat.VARIABLES;
                break;
        }
        m_urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete, false, 0, true);
        m_urlLoader.addEventListener(ErrorEvent.ERROR, onLoadError, false, 0, true);
        m_urlLoader.loadURL(url);
    }
    
    private function removeUrlLoader(close:Boolean=false):void
    {
        if (m_urlLoader == null)
            return;
        m_urlLoader.removeEventListener(ErrorEvent.ERROR, onLoadError);
        m_urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
        if (close)
            m_urlLoader.close();
        m_urlLoaderPool.disposeObject(m_urlLoader);
        m_urlLoader = null;        
    }
    
    private function onUrlLoaderComplete(event:Event=null):void
    {
        memory = m_urlLoader.bytesTotal;
        
        switch (assetType)
        {
            case AssetType.XML:
                var xml:XML = new XML(m_urlLoader.data);
                xmlHandler(xml);
                break;
            case AssetType.BINARY:
                byteArrayHandler(m_urlLoader.data as ByteArray);
                break;
            case AssetType.TEXT:
            case AssetType.VARIABLES:
                dataHandler(m_urlLoader.data);
                break;
            default:
                Log.error("未处理的资源类型onUrlLoaderComplete"+m_urlLoader.url, this);
                loadComplete();
        }
    }
    
    private function xmlHandler(xml:XML):void
    {
        while (callbackList.length != 0)
        {
            assetCallback(xml, callbackList.shift());
        }
        
        loadComplete();
    }
    
    private function byteArrayHandler(byteArray:ByteArray):void
    {
        while (callbackList.length != 1)
        {
            var clone:ByteArray = new ByteArray();
            clone.writeBytes(byteArray);
            clone.position = 0;
            assetCallback(clone, callbackList.shift());
        }
        assetCallback(byteArray, callbackList.shift());
        
        loadComplete();
    }
    
    private function dataHandler(data:*):void
    {
        while (callbackList.length != 0)
        {
            assetCallback(data, callbackList.shift());
        }
        
        loadComplete();        
    }

    private function loadComplete():void
    {
        removeLoader();
        removeUrlLoader();
        m_onComplete(this);
    }
    
    public function loadCache(onComplete:Function):void
    {
        m_onComplete = onComplete;
        
        switch (assetType)
        {
            case AssetType.BITMAP:
                bitmapHandler(m_cache as BitmapData);
                break;
            case AssetType.BITMAP_DATA:
                bitmapDataHandler(m_cache as BitmapData);
                break;
            case AssetType.MOVIE_CLIP:
//            case AssetType.SPRITE_SHEET:// 序列帧不需要缓存，由SpriteAnimation缓存
                loaderBytesHandler(m_cache as ByteArray);
                break;
            default:
                Log.error("不支持的资源类型"+url, this);
                loadComplete();
        }
    }
    
    public function cloneCache():Object
    {
        var cache:Object;
        switch (assetType)
        {
            case AssetType.BITMAP:
                cache = new Bitmap(m_cache as BitmapData);
                break;
            case AssetType.BITMAP_DATA:
            case AssetType.XML:
            case AssetType.BINARY:
            case AssetType.TEXT:
            case AssetType.VARIABLES:
                cache = m_cache;
                break;
            default:
                Log.error("不能立即克隆的资源", this);
        }
        return cache;
    }
    
    public function stop(callback:Function):void
    {
        var index:int = callbackList.indexOf(callback);
        if (index == -1)
            throw new Error();
        callbackList.splice(index, 1);
        
        if (callbackList.length == 0)
        {
            removeLoader(true);    
            removeUrlLoader(true);
        }
    }
    
    private function assetCallback(asset:Object, callback:Function):void
    {
        m_assetData.url = url;
        m_assetData.asset = asset;
        m_assetData.param = param;
        
        callback(m_assetData);
    }
    
    protected function onLoadError(event:ErrorEvent):void
    {
        if (m_loader != null)
            removeLoaderEvent();
        
        if (m_errorList.indexOf(url) == -1)
            m_errorList.push(url);
        
        loadErrorHandler();
    }
    
    private function loadErrorHandler():void
    {
        for each (var callback:Function in callbackList) 
        {
            assetCallback(null, callback);
        }
        
        if (m_onComplete == null)   // assetCallback(null, null, callback);回调的函数逻辑已经stop了此url
            return;
        loadComplete();        
    }
    
    public function get assetData():AssetData
    {
        return m_assetData;
    }
    
    public function isLoading():Boolean
    {
        return m_urlLoader != null;
    }
    
    public function hasCache():Boolean
    {
        return m_cache != null;
    }
    
    public function hasLoad(callback:Function):Boolean
    {
        var index:int = callbackList.indexOf(callback);
        return index >= 0;
    }
    
    public function get isCache():Boolean
    {
        return m_isCache;
    }

    public function get url():String
    {
        return m_url;
    }

    public function set url(value:String):void
    {
        if (m_url != null)
            throw new Error();
        m_url = value;
    }

    public function get onComplete():Function
    {
        return m_onComplete;
    }

    public function get urlLoader():URLLoaderExtend
    {
        return m_urlLoader;
    }

    public function get loader():LoaderExtend
    {
        return m_loader;
    }
    
    private static const MAX_LIMIT:int = 10;
    public static function processTest():void
    {
        Assert.assertTrue1(m_urlLoaderPool.size >= 0);
        Assert.assertTrue1(m_urlLoaderPool.size <= MAX_LIMIT);
        Assert.assertTrue1(m_loaderPool.length <= MAX_LIMIT);
        Assert.assertTrue1(m_loaderBytesPool.length <= MAX_LIMIT);
    }
    
    public static function getLoadInfo():String
    {
        var result:String = "";
        result += "urlLoaderPool:"+m_urlLoaderPool.size+"/"+m_urlLoaderPool.totalSize;
        result += "  loaderPool:"+m_loaderPool.length+"/"+MAX_LIMIT;
        result += "  loaderBytesPool:"+m_loaderBytesPool.length+"/"+MAX_LIMIT;
        return result;
    }      
}

class IdleLoadData
{
    public var url:String;
    public var callback:Function;
    public var assetType:String;
    public var cache:int;
}