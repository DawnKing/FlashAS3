/**
     * Created by caijingxiao on 2017/6/22.
     */
package easiest.rendering.sprites
{
    import flash.display.BitmapData;
    import flash.utils.ByteArray;
    
    import easiest.core.Log;
    import easiest.debug.Assert;
    import easiest.managers.load.AssetData;
    import easiest.managers.load.AssetManager;
    import easiest.managers.load.AssetType;
    import easiest.rendering.materials.textures.AtfData;
    import easiest.rendering.materials.textures.AtfTexture;
    import easiest.rendering.materials.textures.BaseTexture;
    import easiest.rendering.materials.textures.BitmapTexture;
    import easiest.rendering.materials.textures.SubTexture;
    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.utils.MathUtil;

    public class Weather
    {
        private var _url:String;
        private var _atlas:TextureAtlas;
        private var _sprites:Vector.<Sprite2D>;
        private var _particles:Vector.<WeatherParticle>;
        private var _playList:Array;

        public var onInit:Function;

        public function Weather(url:String, num:int)
        {
            Assert.assertTrue1(num > 0);

            _url = url;
            _sprites = new Vector.<Sprite2D>(num, true);
            _particles = new Vector.<WeatherParticle>(num, true);

            if (BaseTexture.useAtf)
                AssetManager.load(_url + BaseTexture.atf, onLoadAtf, AssetType.BINARY);
            else
                AssetManager.load(_url + ".png", onLoadImage, AssetType.BITMAP_DATA);
        }

        private function onLoadAtf(assetData:AssetData):void
        {
            if (assetData.asset == null)
                return;

            var atfData:AtfData = new AtfData(assetData.asset as ByteArray);
            var texture:AtfTexture = new AtfTexture(null, atfData);
            onLoadTexture(texture);
        }

        private function onLoadImage(assetData:AssetData):void
        {
            if (assetData.asset == null)
                return;

            var texture:BitmapTexture = new BitmapTexture(null, assetData.asset as BitmapData);
            onLoadTexture(texture);
        }

        private function onLoadTexture(texture:BaseTexture):void
        {
            for (var i:int = 0; i < _sprites.length; i++)
            {
                _sprites[i] = new Sprite2D();
                _sprites[i].setTexture(texture);
            }

            AssetManager.load(_url + ".xml", onLoadXML, AssetType.XML);
        }

        private function onLoadXML(assetData:AssetData):void
        {
            if (assetData.asset == null)
                return;

            _atlas = new TextureAtlas(_sprites[0].baseTexture, assetData.asset as XML);

            if (_playList != null)
                run();
        }

        public function play(nameList:Array):void
        {
            _playList = nameList;
            if (_atlas == null)
                return;
            run();
        }

        private function run():void
        {
            Assert.assertNotNull1(onInit);

            for (var i:int = 0; i < _sprites.length; i++)
            {
                var name:String = _playList[MathUtil.getIntRandom(0, _playList.length-1)];
                var subTexture:SubTexture = _atlas.getSubTextureByName(name);
                if (subTexture == null)
                {
                    Log.error(_url + "subTexture error " + name, this);
                    continue;
                }

                if (onInit.length == 1)
                    _particles[i] = onInit(_sprites[i]);
                else
                    _particles[i] = onInit();

                _particles[i].init(_sprites[i]);
                _sprites[i].width = subTexture.width;
                _sprites[i].height = subTexture.height;
                _sprites[i].u = subTexture.region.x;
                _sprites[i].v = subTexture.region.y;
                _sprites[i].uvWidth = subTexture.region.width;
                _sprites[i].uvHeight = subTexture.region.height;
            }
        }

        public function render():void
        {
            if (_atlas == null)
                return;

            for (var i:int = 0; i < _sprites.length; i++)
            {
                if (_particles[i].update(_sprites[i]))
                    _sprites[i].render(null);
            }
        }
    }
}
