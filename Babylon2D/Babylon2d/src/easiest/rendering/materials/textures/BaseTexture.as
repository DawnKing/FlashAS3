/**
     * Created by caijingxiao on 2016/11/9.
     */
package easiest.rendering.materials.textures
{
    import easiest.core.IClear;

    import flash.display3D.textures.Texture;

    public class BaseTexture
    {
        public static var useAtf:Boolean = true;
        public static var atf:String = ".atf";

        public var scale:Number = 1;

        private var _texture:Texture;
        private var _width:Number = 0;
        private var _height:Number = 0;
        private var _onUpdate:Vector.<Function> = new <Function>[];

        public function BaseTexture(onUpdate:Function = null)
        {
            if (onUpdate)
                _onUpdate.push(onUpdate);
        }

        public function clear(onUpdate:Function):void
        {
            if (onUpdate)
                removeUpdate(onUpdate);
        }

        public function addUpdate(func:Function):void
        {
            if (_onUpdate.indexOf(func) == -1)
                _onUpdate.push(func);
            if (_texture != null)
                func(this);
        }

        public function removeUpdate(value:Function):void
        {
            var index:int = _onUpdate.indexOf(value);
            if (index != -1)
                _onUpdate.splice(index, 1);
        }

        public function setTexture(texture:Texture, width:Number, height:Number):void
        {
            _texture = texture;
            updateTexture(width, height);
        }

        public function updateTexture(width:Number, height:Number):void
        {
            _width = width;
            _height = height;
            for each (var func:Function in _onUpdate)
            {
                func(this);
            }
        }

        public function get ready():Boolean
        {
            return _texture != null;
        }

        public function get width():Number
        {
            return _width;
        }

        public function get height():Number
        {
            return _height;
        }

        public function get texture():Texture
        {
            return _texture;
        }

        public function get format():String
        {
            throw new Error();
        }
    }
}
