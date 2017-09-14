/**
 * Created by caijingxiao on 2017/7/18.
 */
package easiest.managers.load
{
    import easiest.core.Log;
    import easiest.debug.Assert;
    import easiest.managers.FrameManager;
    import easiest.managers.ObjectPool;
    import easiest.rendering.materials.textures.AtfData;
    import easiest.rendering.materials.textures.AtfTexture;
    import easiest.rendering.materials.textures.TextureAtlas;

    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;

    public class BinManager
    {
        private static const binPath:String = "model/bins/";

        private static var _uncompress:Vector.<BinData>;
        private static const _indexList:Dictionary = new Dictionary(true);   // 索引列表 url - textureName - sheetIndex
        private static const _sheetList:Dictionary = new Dictionary(true);  // 图表列表 url - TextureAtlas
        private static const _loading:Dictionary = new Dictionary(true);

        public static function init():void
        {
            _uncompress = new <BinData>[];
            FrameManager.add(process, FrameManager.IDLE);
        }

        // 回调函数格式function(atlas:TextureAtlas):void
        public static function loadBinId(path:String, textureName:String, onComplete:Function):void
        {
            Assert.assertTrue1(path != null && path != "");
            Assert.assertTrue1(textureName != null && textureName != "");

            if (addLoading(path, onComplete))
                return;
            var binData:BinIdData = ObjectPool.get(BinIdData) as BinIdData;
            _loading[path] = binData;
            binData.path = path;
            binData.add(onComplete);

            binData.textureName = textureName;
            // 索引文件名3101.bin
            binData.indexUrl = Config.getVersionUrl(binPath + path + ".bin");
            if (binData.indexUrl in _indexList)
            {
                Assert.assertTrue1(textureName in _indexList[binData.indexUrl]);
                // 纹理表名3101.#.bin
                binData.atlasUrl = getSheetUrl(binData);
                if (binData.atlasUrl == null)
                {
                    onLoadComplete(binData, null);  // 数据错误，错误回调
                    return;
                }
                if (binData.atlasUrl in _sheetList)
                {
                    onComplete(_sheetList[binData.atlasUrl]);
                    return;
                }

                AssetManager.load(binData.atlasUrl, onLoadBinComplete, AssetType.BINARY, AssetType.CACHE_NONE, binData);
                return;
            }

            binData.atlasUrl = textureName;
            AssetManager.load(binData.indexUrl, onLoadBinComplete, AssetType.BINARY, AssetType.CACHE_NONE, binData);
        }

        // 回调函数格式function(atlas:TextureAtlas):void
        public static function loadBin(path:String, onComplete:Function):void
        {
            if (addLoading(path, onComplete))
                return;
            var binData:BinData = ObjectPool.get(BinData) as BinData;
            _loading[path] = binData;
            binData.path = path;
            binData.add(onComplete);

            binData.atlasUrl = Config.getVersionUrl(path + ".bin");
            AssetManager.load(binData.atlasUrl, onLoadBinComplete, AssetType.BINARY, AssetType.CACHE_NONE, binData);
        }

        // 先判断是否正在加载这个资源，如果正在加载，直接返回
        private static function addLoading(url:String, callback:Function):Boolean
        {
            if (url in _loading)
            {
                _loading[url].add(callback);
                return true;
            }
            return false;
        }

        public static function hasIndexList(path:String):Boolean
        {
            return path in _indexList;
        }

        public static function hasTexture(path:String, textureName:String):Boolean
        {
            return textureName in _indexList[path];
        }

        private static function getSheetUrl(binData:BinIdData):String
        {
            if (!(binData.path in _indexList))
            {
                Log.error(binData.path + " not in indexList", getQualifiedClassName(BinManager));
                return null;
            }
            if (!(binData.textureName in _indexList[binData.path]))
            {
                Log.error(binData.textureName + " not in " + binData.path, getQualifiedClassName(BinManager));
                return null;
            }

            var index:int = _indexList[binData.path][binData.textureName];
            return Config.getVersionUrl(binPath + binData.path + "." + index + ".bin");
        }

        private static function onLoadBinComplete(assetData:AssetData):void
        {
            var binData:BinData = assetData.param as BinData;
            if (assetData.asset == null)
            {
                onLoadComplete(binData, null);
                return;
            }
            var data:ByteArray = assetData.asset as ByteArray;
            if (data.bytesAvailable < 10)
            {
                Log.error("纹理文件长度异常：", assetData.url);
                return;
            }
            if (data.readMultiByte(6, "gb2312") != DHPackType.NAME)
            {
                Log.error("纹理文件压缩格式错误,请重新打包：", assetData.url);
                return;
            }
            binData.bytes = data;
            _uncompress.push(binData);
        }

        public static function process():void
        {
            if (_uncompress.length == 0)
                return;
            var binData:BinData = _uncompress.pop();
            var binBytes:ByteArray = binData.bytes;

            var type:int=binBytes.readByte();
            if (type < DHPackType.INDEX || type > DHPackType.TPK)
            {
                Log.error("未知纹理文件类型：", binData.path);
                return;
            }
            var compress:int;
            if (binBytes.readByte() > 0)
            {
                compress=binBytes.readByte();
            }
            else
            {
                compress=binBytes.readBoolean() ? DHPackCompress.Deflate : DHPackCompress.None;
            }
            var encrypt:Boolean=binBytes.readBoolean();
            if (encrypt)
            {
            }
            var dataLen:int=binBytes.readUnsignedInt();
            if (binBytes.bytesAvailable != dataLen)
            {
                Log.error("纹理文件压缩异常，读取长度错误：", binData.path);
                return;
            }
            var fileBytes:ByteArray=new ByteArray();
            binBytes.readBytes(fileBytes, 0, binBytes.bytesAvailable);
            binBytes.clear();

            if (compress > 0)
            {
                if (compress == DHPackCompress.Deflate)
                    fileBytes.uncompress(CompressionAlgorithm.DEFLATE);
                else if (compress == DHPackCompress.Zlib)
                    fileBytes.uncompress(CompressionAlgorithm.ZLIB);
                else if (compress == DHPackCompress.Lzma)
                    fileBytes.uncompress(CompressionAlgorithm.LZMA);
                else
                    throw new Error("UnSupported CompressType:" + compress);
            }

            switch (type)
            {
                case DHPackType.INDEX:
                    var indexList:Dictionary = new Dictionary(true);
                    var n:int=fileBytes.readUnsignedShort();
                    var name:String;
                    var idx:int;
                    while (n--)
                    {
                        name=fileBytes.readUTF();
                        idx=fileBytes.readByte();
                        indexList[name]=idx;
                    }
                    _indexList[binData.path] = indexList;

                    binData.atlasUrl = getSheetUrl(binData as BinIdData);
                    if (binData.atlasUrl != null)
                        AssetManager.load(binData.atlasUrl, onLoadBinComplete, AssetType.BINARY, AssetType.CACHE_NONE, binData);
                    else
                        onLoadComplete(binData, null);// 数据错误，错误回调
                    break;
                case DHPackType.FILE:
                case DHPackType.TPK:
                    var atfBuffer:ByteArray=new ByteArray();
                    fileBytes.readBytes(atfBuffer, 0, fileBytes.readUnsignedInt());
                    var sheetConfig:ByteArray=new ByteArray();
                    fileBytes.readBytes(sheetConfig, 0, fileBytes.bytesAvailable);

                    var atfData:AtfData = new AtfData(atfBuffer);
                    var atfTexture:AtfTexture = new AtfTexture(null, atfData);
                    var atlas:TextureAtlas = new TextureAtlas(atfTexture, new XML(sheetConfig.toString()));

                    _sheetList[binData.path] = atlas;

                    onLoadComplete(binData, atlas);
                    break;
                default:
                    Log.error("未知纹理文件类型：", binData.path);
                    break;
            }
            fileBytes.clear();
        }

        private static function onLoadComplete(binData:BinData, atlas:TextureAtlas):void
        {
            binData.onComplete(atlas);
            delete _loading[binData.path];
            ObjectPool.free(binData);
        }
    }
}

import easiest.core.IClear;
import easiest.rendering.materials.textures.TextureAtlas;

import flash.utils.ByteArray;

class BinData implements IClear
{
    public var path:String;
    public var atlasUrl:String;

    public var bytes:ByteArray;
    private var _onComplete:Vector.<Function> = new <Function>[];

    public function add(onComplete:Function):void
    {
        _onComplete.push(onComplete);
    }

    public function onComplete(atlas:TextureAtlas):void
    {
        for (var i:int = 0; i < _onComplete.length; i++)
        {
            if (_onComplete[i].length == 2)
                _onComplete[i](path, atlas);
            else
                _onComplete[i](atlas);
        }
    }

    public function clear():void
    {
        path = null;
        atlasUrl = null;
        bytes = null;
        _onComplete.length = 0;
    }
}

class BinIdData extends BinData
{
    public var textureName:String;
    public var indexUrl:String;
}
