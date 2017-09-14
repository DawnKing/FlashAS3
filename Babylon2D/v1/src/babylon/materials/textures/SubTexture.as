/**
 * Created by caijingxiao on 2017/6/16.
 */
package babylon.materials.textures
{

    import easiest.core.Log;

    import flash.geom.Matrix;
    import flash.geom.Rectangle;

    public class SubTexture
    {
        private var _parent:Object;
        private var _ownsParent:Boolean;
        private var _region:Rectangle;
        private var _frame:Rectangle;
        private var _rotated:Boolean;
        private var _width:Number;
        private var _height:Number;
        private var _scale:Number;
        private var _transformationMatrix:Matrix;
        private var _transformationMatrixToRoot:Matrix;

        public function SubTexture(parent:Object, region:Rectangle=null,
                                   ownsParent:Boolean=false, frame:Rectangle=null,
                                   rotated:Boolean=false, scaleModifier:Number=1)
        {
            setTo(parent, region, ownsParent, frame, rotated, scaleModifier);
        }

        private function setTo(parent:Object, region:Rectangle=null,
                               ownsParent:Boolean=false, frame:Rectangle=null,
                               rotated:Boolean=false, scaleModifier:Number=1):void
        {
            if (_region == null) _region = new Rectangle();
            if (region) _region.copyFrom(region);
            else _region.setTo(0, 0, parent.width, parent.height);

            if (frame)
            {
                if (_frame) _frame.copyFrom(frame);
                else _frame = frame.clone();
            }
            else _frame = null;

            _parent = parent;
            _ownsParent = ownsParent;
            _rotated = rotated;
            _width  = (rotated ? _region.height : _region.width)  / scaleModifier;
            _height = (rotated ? _region.width  : _region.height) / scaleModifier;
            _scale = _parent.scale * scaleModifier;

            if (_frame && (_frame.x > 0 || _frame.y > 0 ||
                _frame.right < _width || _frame.bottom < _height))
            {
                Log.error("[Starling] Warning: frames inside the texture's region are unsupported.", this);
            }

            updateMatrices();
        }

        private function updateMatrices():void
        {
            if (_transformationMatrix) _transformationMatrix.identity();
            else _transformationMatrix = new Matrix();

            if (_transformationMatrixToRoot) _transformationMatrixToRoot.identity();
            else _transformationMatrixToRoot = new Matrix();

            if (_rotated)
            {
                _transformationMatrix.translate(0, -1);
                _transformationMatrix.rotate(Math.PI / 2.0);
            }

            _transformationMatrix.scale(_region.width  / _parent.width,
                _region.height / _parent.height);
            _transformationMatrix.translate(_region.x  / _parent.width,
                _region.y  / _parent.height);

            var texture:SubTexture = this;
            while (texture)
            {
                _transformationMatrixToRoot.concat(texture._transformationMatrix);
                texture = texture.parent as SubTexture;
            }
        }

        public function dispose():void
        {
            if (_ownsParent) _parent.dispose();
            super.dispose();
        }

        public function get parent():Object { return _parent; }

        public function get ownsParent():Boolean { return _ownsParent; }

        public function get rotated():Boolean { return _rotated; }

        public function get region():Rectangle { return _region; }

        public function get transformationMatrix():Matrix { return _transformationMatrix; }

        public function get transformationMatrixToRoot():Matrix { return _transformationMatrixToRoot; }

        public function get format():String { return _parent.format; }

        public function get width():Number { return _width; }

        public function get height():Number { return _height; }

        public function get nativeWidth():Number { return _width * _scale; }

        public function get nativeHeight():Number { return _height * _scale; }

        public function get mipMapping():Boolean { return _parent.mipMapping; }

        public function get premultipliedAlpha():Boolean { return _parent.premultipliedAlpha; }

        public function get scale():Number { return _scale; }

        public function get frame():Rectangle { return _frame; }
    }
}
