/**
 * Created by caijingxiao on 2017/7/19.
 */
package easiest.rendering.sprites.atlas
{
    import easiest.core.Log;
    import easiest.debug.Assert;
    import easiest.rendering.materials.textures.SubTexture;
    import easiest.rendering.materials.textures.TextureAtlas;

    import flash.geom.Matrix;
    import flash.geom.Rectangle;

    import easiest.managers.load.BinManager;

    import tempest.enum.Status;

    public class AtfAnimation extends AtlasBase
    {
        private static const ROOT:String = "avatars/%d";
        private var _loading:Boolean;
        private var _subTexture:SubTexture;
        private var _textureIndex:int = -1;
        private var _itemId:int = -1;
        private var _textureName:String;
        private var _changed:Boolean;

        protected var _offsetX:Number = 0;
        protected var _offsetY:Number = 0;

        private var _horizontalFlip:Boolean;

        public function AtfAnimation()
        {
            super();
        }

        override public function clear():void
        {
            if (_subTexture)
            {
                _subTexture.clear();
                _subTexture = null;
            }
            _loading = false;
            _textureIndex = -1;
            _itemId = -1;
            _changed = false;
            _offsetX = 0;
            _offsetY = 0;
            _horizontalFlip = false;
            super.clear();
        }

        public function update(action:int, direction:int, mirror:Boolean, currentFrame:int):void
        {
            if (_loading)
                return;

            Assert.assertTrue1(_itemId >= 0);
            Assert.assertTrue1(action >= 0);
            Assert.assertTrue1(direction >= 0);
            Assert.assertTrue1(currentFrame >= 0);

            var textureIndex:int = TextureAtlas.getIndex(action, direction, currentFrame);
            if (_textureIndex == textureIndex)
                return;
            _textureIndex = textureIndex;
            var path:String = ROOT.replace("%d", _itemId);
            _textureName = Status.actionsMaps[_textureIndex];
            if (BinManager.hasIndexList(path))
            {
                // 跳过缺少的帧
                if (!BinManager.hasTexture(path, _textureName))
                    return;
            }
            _horizontalFlip = mirror;
            _changed = true;

            if (_atlas == null)
            {
                BinManager.loadBinId(path, _textureName, onUpdateTextureAtlas);
                _loading = true;
            }
            else
            {
                var newSubTexture:SubTexture = _atlas.getSubTexture(_textureIndex);
                if (newSubTexture == null)
                {
                    BinManager.loadBinId(path, _textureName, onUpdateTextureAtlas);
                    _loading = true;
                }
                else
                {
                    _subTexture = newSubTexture;
                }
            }
        }

        protected function onUpdateTextureAtlas(path:String, atlas:TextureAtlas):void
        {
            if (_itemId == -1)
                return;
            Assert.assertTrue("加载逻辑错误", path.indexOf(_itemId.toString()) != -1);

            _loading = false;
            if (atlas == null)
                return;

            setAtlas(atlas);
            _subTexture = _atlas.getSubTexture(_textureIndex);
            if (_subTexture == null)
            {
                Log.error("subTexture error " + TextureAtlas.decodeIndex(_textureIndex) + "   itemId:" + _itemId, this);
            }
        }

        override public function render(matrix:Matrix):void
        {
            if (_subTexture == null)
                return;

            var frame:Rectangle=_subTexture.frame;

            if (_horizontalFlip)
                _sprite.x=x + (frame.width + frame.x - subTexture.width) + _offsetX;
            else
                _sprite.x=x - frame.x + _offsetX;
            _sprite.y=y - frame.y + _offsetY;

            if (!_changed)
            {
                _sprite.render(matrix);
                return;
            }

            _sprite.horizontalFlip=_horizontalFlip;

            setSubTextureData(_subTexture);

            _sprite.render(matrix);
            _changed = false;
        }

        public function get itemId():int
        {
            return _itemId;
        }

        public function set itemId(value:int):void
        {
            if (_itemId == value)
                return;
            _itemId = value;
        }

        public function get subTexture():SubTexture
        {
            return _subTexture;
        }

        override public function toString():String
        {
            var str:String = super.toString();
            if (_loading == true)
                str += ", *loading";
            if (_itemId == -1)
                str += ", *itemId";
            else
                str += ", itemId:" + _itemId;
            if (_subTexture == null)
                str += ", *subTexture";
//            else
//                str += StringUtil.format(", subTexture:{0},{1}", _subTexture.width, _subTexture.height);
            if (_textureName == null)
                str += ", *textureName";
            else
                str += ", textureName:" + _textureName;
            return str;
        }
    }
}
