/**
 * Created by caijingxiao on 2017/6/24.
 */
package easiest.rendering.sprites
{
    import easiest.rendering.filters.FragmentFilter;
    import easiest.utils.MathUtil;
    import easiest.utils.MatrixUtil;
    import easiest.utils.StringUtil;

    import flash.events.EventDispatcher;
    import flash.geom.Matrix;
    import flash.geom.Point;

    public class SpriteObject extends EventDispatcher
    {
        private var _x:Number;
        private var _y:Number;
        private var _pivotX:Number;
        private var _pivotY:Number;
        private var _scaleX:Number;
        private var _scaleY:Number;
        private var _skewX:Number;
        private var _skewY:Number;
        private var _rotation:Number;
        private var _alpha:Number;
        private var _visible:Boolean;
        private var _transformationMatrix:Matrix;
        private var _transformationChanged:Boolean;
        private var _mouseEnabled:Boolean;
        private var _blendMode:String;
        private var _name:String;

        protected var _width:Number=0;
        protected var _height:Number=0;
        protected var _globalTransformation:Matrix;

        /** @private */ internal var _parent:SpriteContainer;
        /** @private */ internal var _parentTransformationChanged:Boolean;
        /** @private */ internal var _hasVisibleArea:Boolean;
        /** @private */ internal var _filter:FragmentFilter;

        public function SpriteObject()
        {
            super();
            _x = _y = _pivotX = _pivotY = _rotation = _skewX = _skewY = 0.0;
            _scaleX = _scaleY = _alpha = 1.0;
            _visible = _hasVisibleArea = true;
            _mouseEnabled = false;
            _transformationMatrix = new Matrix();
            _globalTransformation = new Matrix();
        }

        public function dispose():void
        {
            if (_filter)
            {
                _filter.dispose();
                _filter = null;
            }
            if (_parent)
            {
                _parent.removeChild(this);
                _parent = null;
            }
        }

        public function removeFromParent(dispose:Boolean=false):void
        {
            if (_parent) _parent.removeChild(this, dispose);
            else if (dispose) this.dispose();
        }

        public function hitTest(point:Point):SpriteObject
        {
            if (!_visible || !_mouseEnabled) return null;

            if (containsPoint(point.x, point.y))
                return this;
            return null;
        }

        protected function containsPoint(mouseX:Number, mouseY:Number):Boolean
        {
            return mouseX > x && mouseX < x + width && mouseY > y && mouseY < y + height;
        }

        public function render(matrix:Matrix):void
        {
            throw new Error();
        }

        /** @private */
        public function setParent(value:SpriteContainer):void
        {
            // check for a recursion
            var ancestor:SpriteObject = value;
            while (ancestor != this && ancestor != null)
                ancestor = ancestor._parent;

            if (ancestor == this)
                throw new ArgumentError("An object cannot be added as a child to itself or one " +
                    "of its children (or children's children, etc.)");
            else
                _parent = value;
        }

        public function setRequiresRedraw():void
        {
            _hasVisibleArea = _alpha  != 0.0 && _visible &&
                _scaleX != 0.0 && _scaleY != 0.0;
        }

        /** @private */
        internal function setTransformationChanged():void
        {
            _transformationChanged = true;
            setRequiresRedraw();
        }

        internal function updateTransformationMatrices(
            x:Number, y:Number, pivotX:Number, pivotY:Number, scaleX:Number, scaleY:Number,
            skewX:Number, skewY:Number, rotation:Number, out:Matrix):void
        {
            if (skewX == 0.0 && skewY == 0.0)
            {
                // optimization: no skewing / rotation simplifies the matrix math

                if (rotation == 0.0)
                {
                    out.setTo(scaleX, 0.0, 0.0, scaleY,
                        x - pivotX * scaleX, y - pivotY * scaleY);
                }
                else
                {
                    var cos:Number = Math.cos(rotation);
                    var sin:Number = Math.sin(rotation);
                    var a:Number   = scaleX *  cos;
                    var b:Number   = scaleX *  sin;
                    var c:Number   = scaleY * -sin;
                    var d:Number   = scaleY *  cos;
                    var tx:Number  = x - pivotX * a - pivotY * c;
                    var ty:Number  = y - pivotX * b - pivotY * d;

                    out.setTo(a, b, c, d, tx, ty);
                }
            }
            else
            {
                out.identity();
                out.scale(scaleX, scaleY);
                MatrixUtil.skew(out, skewX, skewY);
                out.rotate(rotation);
                out.translate(x, y);

                if (pivotX != 0.0 || pivotY != 0.0)
                {
                    // prepend pivot transformation
                    out.tx = x - out.a * pivotX - out.c * pivotY;
                    out.ty = y - out.b * pivotX - out.d * pivotY;
                }
            }
        }

        public function get transformationMatrix():Matrix
        {
            if (_transformationChanged)
            {
                _transformationChanged = false;

                updateTransformationMatrices(
                    _x, _y, _pivotX, _pivotY, _scaleX, _scaleY, _skewX, _skewY, _rotation,
                    _transformationMatrix);
            }
            return _transformationMatrix;
        }

        public function get width():Number { return _width }
        public function set width(value:Number):void
        {
            _width = value;
        }

        public function get height():Number { return _height }
        public function set height(value:Number):void
        {
            _height = value;
        }

        /** The x coordinate of the object relative to the local coordinates of the parent. */
        public function get x():Number { return _x; }
        public function set x(value:Number):void
        {
            if (_x != value)
            {
                _x = value;
                setTransformationChanged();
            }
        }

        public function get y():Number { return _y; }
        public function set y(value:Number):void
        {
            if (_y != value)
            {
                _y = value;
                setTransformationChanged();
            }
        }

        /** The x coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotX():Number { return _pivotX; }
        public function set pivotX(value:Number):void
        {
            if (_pivotX != value)
            {
                _pivotX = value;
                setTransformationChanged();
            }
        }

        /** The y coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotY():Number { return _pivotY; }
        public function set pivotY(value:Number):void
        {
            if (_pivotY != value)
            {
                _pivotY = value;
                setTransformationChanged();
            }
        }

        public function get scaleX():Number { return _scaleX; }
        public function set scaleX(value:Number):void
        {
            if (_scaleX != value)
            {
                _scaleX = value;
                setTransformationChanged();
            }
        }

        public function get scaleY():Number { return _scaleY; }
        public function set scaleY(value:Number):void
        {
            if (_scaleY != value)
            {
                _scaleY = value;
                setTransformationChanged();
            }
        }

        public function get scale():Number { return scaleX; }
        public function set scale(value:Number):void { scaleX = scaleY = value; }

        /** The horizontal skew angle in radians. */
        public function get skewX():Number { return _skewX; }
        public function set skewX(value:Number):void
        {
            value = MathUtil.normalizeAngle(value);

            if (_skewX != value)
            {
                _skewX = value;
                setTransformationChanged();
            }
        }

        /** The vertical skew angle in radians. */
        public function get skewY():Number { return _skewY; }
        public function set skewY(value:Number):void
        {
            value = MathUtil.normalizeAngle(value);

            if (_skewY != value)
            {
                _skewY = value;
                setTransformationChanged();
            }
        }

        /** The rotation of the object in radians. (In Starling, all angles are measured
         *  in radians.) */
        public function get rotation():Number { return _rotation; }
        public function set rotation(value:Number):void
        {
            value = MathUtil.normalizeAngle(value);

            if (_rotation != value)
            {
                _rotation = value;
                setTransformationChanged();
            }
        }

        internal function get isRotated():Boolean
        {
            return _rotation != 0.0 || _skewX != 0.0 || _skewY != 0.0;
        }

        /** The opacity of the object. 0 = transparent, 1 = opaque. @default 1 */
        public function get alpha():Number { return _alpha; }
        public function set alpha(value:Number):void
        {
            if (value != _alpha)
            {
                _alpha = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
                setRequiresRedraw();
            }
        }

        public function get visible():Boolean { return _visible; }
        public function set visible(value:Boolean):void
        {
            if (value != _visible)
            {
                _visible = value;
            }
        }

        public function get mouseEnabled():Boolean { return _mouseEnabled; }
        public function set mouseEnabled(value:Boolean):void { _mouseEnabled = value; }

        public function get blendMode():String { return _blendMode; }
        public function set blendMode(value:String):void
        {
            if (value != _blendMode)
            {
                _blendMode = value;
                setRequiresRedraw();
            }
        }

        /** The name of the display object (default: null). Used by 'getChildByName()' of
         *  display object containers. */
        public function get name():String { return _name; }
        public function set name(value:String):void { _name = value; }

        public function get filter():FragmentFilter { return _filter; }
        public function set filter(value:FragmentFilter):void
        {
            if (value != _filter)
            {
                _filter = value;
                setRequiresRedraw();
            }
        }

        public function get parent():SpriteContainer { return _parent; }

        public function copyTo(object:SpriteObject):void
        {
            object.name = name;
            object.pivotX = pivotX;
            object.pivotY = pivotY;
            object.scaleX = scaleX;
            object.scaleY = scaleY;
        }

        private static const toStr:String = " name:{0}, x:{1}, y:{2}, width:{3}, height:{4}";
        override public function toString():String
        {
            var str:String = StringUtil.format(toStr, name, x, y, width, height);
            if (rotation != 0)
                str += ", rotation:" + rotation;
            if (scaleX != 1)
                str += ", scaleX:" + scaleX;
            if (scaleY != 1)
                str += ", scaleY:" + scaleY;
            if (alpha != 1)
                str += ", alpha:" + alpha;
            if (pivotX != 0)
                str += ", pivotX:" + pivotX;
            if (pivotY != 0)
                str += ", pivotY:" + pivotY;
            if (filter != null)
                str += ", filter:" + filter;
            return str;
        }
    }
}
