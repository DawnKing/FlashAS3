/**
 * Created by caijingxiao on 2017/7/22.
 */
package easiest.rendering.sprites.atlas
{
    import easiest.core.IClear;
    import easiest.rendering.filters.FragmentFilter;
    import easiest.rendering.materials.textures.SubTexture;
    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.rendering.sprites.Sprite2D;
    import easiest.rendering.sprites.SpriteObject;

    import flash.geom.Rectangle;

    public class AtlasBase extends SpriteObject implements IClear
    {
        protected var _atlas:TextureAtlas;
        protected var _sprite:Sprite2D;

        public function AtlasBase()
        {
            super();
        }

        public override function dispose():void
        {
            clear();
            if (_sprite)
            {
                _sprite.dispose();
                _sprite=null;
            }
            super.dispose();
        }

        public function clear():void
        {
            if (_atlas)
            {
                _atlas.clear();
                _atlas = null;
            }
            if (_sprite)
                _sprite.clear();
        }

        protected function setAtlas(atlas:TextureAtlas):void
        {
            if (_atlas == atlas)
                return;
            _atlas = atlas;
            if (!_sprite)
            {
                _sprite = new Sprite2D();
                copyTo(_sprite);
            }
            _sprite.setTexture(_atlas.texture);
        }

        override protected function containsPoint(mouseX:Number, mouseY:Number):Boolean
        {
            if (_sprite == null)
                return false;
            return mouseX > _sprite.x && mouseX < _sprite.x + _sprite.width &&
                mouseY > _sprite.y && mouseY < _sprite.y + _sprite.height;
        }

        protected function setSubTextureData(subTexture:SubTexture):void
        {
            _sprite.width = subTexture.width;
            _sprite.height = subTexture.height;

            var region:Rectangle = subTexture.region;
            _sprite.u = region.x;
            _sprite.v = region.y;
            _sprite.uvWidth = region.width;
            _sprite.uvHeight = region.height;
            _sprite.rotatedSprite = subTexture.rotated;
        }

        public function get atlas():TextureAtlas
        {
            return _atlas;
        }

        override public function get width():Number
        {
            if (_sprite)
                return _sprite.width;
            return super.width;
        }

        override public function get height():Number
        {
            if (_sprite)
                return _sprite.height;
            return super.height;
        }

        override public function get filter():FragmentFilter
        {
            if (_sprite)
                return _sprite.filter;
            return super.filter;
        }

        override public function set filter(value:FragmentFilter):void
        {
            super.filter = value;
            if (_sprite)
                _sprite.filter = value;
        }

        override public function set name(value:String):void
        {
            super.name = value;
            if (_sprite)
                _sprite.name = value;
        }

        override public function set pivotX(value:Number):void
        {
            super.pivotX = value;
            if (_sprite)
                _sprite.pivotX = value;
        }

        override public function set pivotY(value:Number):void
        {
            super.pivotY = value;
            if (_sprite)
                _sprite.pivotY = value;
        }

        override public function set scaleX(value:Number):void
        {
            super.scaleX = value;
            if (_sprite)
                _sprite.scaleX = value;
        }

        override public function set scaleY(value:Number):void
        {
            super.scaleY = value;
            if (_sprite)
                _sprite.scaleY = value;
        }

        override public function toString():String
        {
            var str:String = super.toString();
            if (atlas == null)
                str += ", *atlas";
            return str;
        }
    }
}
