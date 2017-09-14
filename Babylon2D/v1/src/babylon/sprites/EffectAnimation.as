/**
 * Created by caijingxiao on 2017/6/20.
 */
package babylon.sprites
{
    import babylon.Scene;
    import babylon.materials.textures.SubTexture;
    import babylon.materials.textures.TextureAtlas;

    import easiest.core.Log;
    import easiest.managers.AssetData;
    import easiest.managers.AssetManager;
    import easiest.managers.AssetType;

    import flash.display.BitmapData;
    import flash.utils.Dictionary;
    public class EffectAnimation
    {
        private static var _cache:Dictionary = new Dictionary(true);

        public var x:Number = 0;
        public var y:Number = 0;

        public var totalFrame:int;

        private var _scene:Scene;
        private var _url:String;
        private var _effect2D:Effect2D;
        private var _atlas:TextureAtlas;
        private var _index:Number = 0;

        public function EffectAnimation(scene:Scene, url:String)
        {
            _scene = scene;
            _url = url;

            AssetManager.load(_url + ".png", onLoadImage, AssetType.BITMAP_DATA);
        }

        private function onLoadImage(assetData:AssetData):void
        {
            if (assetData.asset == null)
                return;

            _effect2D = new Effect2D(_scene);
            if (assetData.url in _cache)
            {
                _effect2D.setTexture(_cache[assetData.url]);
            }
            else
            {
                _effect2D.setTexture(assetData.asset as BitmapData);

                _cache[assetData.url] = _effect2D.texture;
            }

            AssetManager.load(_url + ".xml", onLoadXML, AssetType.XML);
        }

        private function onLoadXML(assetData:AssetData):void
        {
            if (assetData.asset == null)
                return;

            _atlas = new TextureAtlas(_effect2D.texture, assetData.asset as XML);
        }

        public function render():void
        {
            if (_effect2D == null || _atlas == null)
                return;

            var index:int = int(_index);
            var subTexture:SubTexture = _atlas.getSubTexture(index);
            if (subTexture == null)
            {
                Log.error(_url + "subTexture error" + index, this);
                return;
            }

            _effect2D.x = x - subTexture.frame.x;
            _effect2D.y = y - subTexture.frame.y;
            _effect2D.width = subTexture.width;
            _effect2D.height = subTexture.height;

            _effect2D.u = subTexture.region.x;
            _effect2D.v = subTexture.region.y;
            _effect2D.uvWidth = subTexture.region.width;
            _effect2D.uvHeight = subTexture.region.height;

            _effect2D.render();

            _index += 0.2;
            if (_index >= totalFrame)
                _index = 0;
        }
    }
}
