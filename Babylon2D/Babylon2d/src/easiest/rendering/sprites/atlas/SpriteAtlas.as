/**
 * Created by caijingxiao on 2017/6/23.
 */
package easiest.rendering.sprites.atlas
{
    import easiest.core.Log;
    import easiest.rendering.materials.textures.SubTexture;
    import easiest.rendering.materials.textures.TextureAtlas;

    import flash.geom.Matrix;
    import flash.geom.Rectangle;

    public class SpriteAtlas extends AtlasBase
    {
        private var _textureName:String;
        private var _subTexture:SubTexture;

        public function SpriteAtlas()
        {
            super();
        }

        public function setAtlas2(atlas:TextureAtlas, textureName:String):void
        {
            setAtlas(atlas);
            this.textureName = textureName;
        }

        override public function render(matrix:Matrix):void
        {
            if (_subTexture == null)
                return;

            _sprite.render(matrix);
        }

        override public function set x(value:Number):void
        {
            super.x = value;
            if (_subTexture)
            {
                _sprite.x = x - _subTexture.frame.x;
            }
        }

        override public function set y(value:Number):void
        {
            super.y = value;
            if (_subTexture)
            {
                _sprite.y = y - _subTexture.frame.y;
            }
        }

        public function set textureName(value:String):void
        {
            if (_textureName == value)
                return;
            _textureName = value;
            updateSubTexture();
        }

        protected function updateSubTexture():void
        {
            if (_atlas == null || _textureName == null || _textureName == "")
                return;
            _subTexture = _atlas.getSubTextureByName(_textureName);
            if (_subTexture == null)
            {
                Log.error("subTexture error " + _textureName, this);
                return;
            }
            var frame:Rectangle = _subTexture.frame;
            _sprite.x = x - frame.x;
            _sprite.y = y - frame.y;
            setSubTextureData(_subTexture);
        }

        public function get textureName():String
        {
            return _textureName;
        }

        override public function toString():String
        {
            var str:String = super.toString();
            if (_subTexture == null)
                str += ", *subTexture";
            if (_textureName == null || _textureName == "")
                str += ", *textureName";
            return str;
        }
    }
}
