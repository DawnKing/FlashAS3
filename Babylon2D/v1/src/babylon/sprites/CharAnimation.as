/**
 * Created by caijingxiao on 2017/6/15.
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

    public class CharAnimation
    {
        private static const ImgMirror:Array = [0, 1, 2, 3, 4, 3, 2, 1];
        private static var _cache:Dictionary = new Dictionary(true);

        public var x:Number = 0;
        public var y:Number = 0;

        public var action:int;
        public var direction:int;
        public var totalFrame:int;

        private var _scene:Scene;
        private var _url:String;
        private var _char2D:Char2D;
        private var _atlas:TextureAtlas;
        private var _index:Number = 0;

        public function CharAnimation(scene:Scene, url:String)
        {
            _scene = scene;
            _url = url;

            AssetManager.load(_url + ".png", onLoadImage, AssetType.BITMAP_DATA);
        }

        private function onLoadImage(assetData:AssetData):void
        {
            if (assetData.asset == null)
                return;

            _char2D = new Char2D(_scene);
            if (assetData.url in _cache)
            {
                _char2D.setTexture(_cache[assetData.url]);
            }
            else
            {
                _char2D.setTexture(assetData.asset as BitmapData);

                _cache[assetData.url] = _char2D.texture;
            }

            AssetManager.load(_url + ".xml", onLoadXML, AssetType.XML);
        }

        private function onLoadXML(assetData:AssetData):void
        {
            if (assetData.asset == null)
                return;

            _atlas = new TextureAtlas(_char2D.texture, assetData.asset as XML);
        }

        public function render():void
        {
            if (_char2D == null || _atlas == null)
                return;

            var dir:int = direction;
            var index:int = int(_index);
            var mirror:Boolean = false;
            if (direction > 4)
            {
                dir = ImgMirror[direction];
                mirror = true;
            }
            var subTexture:SubTexture = _atlas.getSubTexture(action, dir, index);
            if (subTexture == null)
            {
                Log.error(_url + "subTexture error" + action + dir + index, this);
                return;
            }

            if (mirror)
                _char2D.x = x + (subTexture.frame.width + subTexture.frame.x - subTexture.width);
            else
                _char2D.x = x - subTexture.frame.x;
            _char2D.y = y - subTexture.frame.y;
            _char2D.width = subTexture.width;
            _char2D.height = subTexture.height;

            _char2D.u = subTexture.region.x;
            _char2D.v = subTexture.region.y;
            _char2D.uvWidth = subTexture.region.width;
            _char2D.uvHeight = subTexture.region.height;

            _char2D.render(_atlas.getRotation(action, dir, index), mirror);

            _index += 0.2;
            if (_index >= totalFrame)
                _index = 0;
        }
    }
}
