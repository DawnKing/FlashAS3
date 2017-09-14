/**
 * Created by caijingxiao on 2017/6/23.
 */
package easiest.rendering.sprites.atlas
{
    import easiest.managers.load.AssetData;
    import easiest.managers.load.AssetManager;
    import easiest.managers.load.AssetType;
    import easiest.rendering.materials.textures.BaseTexture;
    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.rendering.sprites.*;

    import flash.utils.Dictionary;

    public class PngSpriteAtlas extends SpriteAtlas
    {
        protected static var _cache:Dictionary = new Dictionary(true);

        protected var _url:String;

        public function PngSpriteAtlas(url:String, textureName:String)
        {
            _url = url;
            this.textureName = textureName;

            if (_url == null)
                return;

            if (BaseTexture.useAtf)
                AssetManager.load(_url + BaseTexture.atf, onLoadImage, AssetType.BINARY);
            else
                AssetManager.load(_url + ".png", onLoadImage, AssetType.BITMAP_DATA);
        }

        public override function dispose():void
        {
            if (BaseTexture.useAtf)
                AssetManager.stop(_url + BaseTexture.atf, onLoadImage);
            else
                AssetManager.stop(_url + ".png", onLoadImage);
            AssetManager.stop(_url + ".xml", onLoadImage);
            super.dispose();
        }

        private function onLoadImage(assetData:AssetData):void
        {
            if (assetData.asset == null)
                return;

            _sprite = new Sprite2D();
            copyTo(_sprite);
            if (assetData.url in _cache)
            {
                _sprite.setTexture(_cache[assetData.url]);
            }
            else
            {
                _sprite.setTexture(assetData.asset);

                _cache[assetData.url] = _sprite.baseTexture;
            }

            AssetManager.load(_url + ".xml", onLoadXML, AssetType.XML);
        }

        private function onLoadXML(assetData:AssetData):void
        {
            if (_sprite == null || assetData.asset == null)
                return;

            _atlas = new TextureAtlas(_sprite.baseTexture, assetData.asset as XML);
        }
    }
}
