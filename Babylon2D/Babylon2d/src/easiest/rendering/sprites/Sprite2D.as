/**
* Created by caijingxiao on 2017/6/21.
*/
package easiest.rendering.sprites
{
    import easiest.core.IClear;
    import easiest.debug.Assert;
    import easiest.rendering.Engine;
    import easiest.rendering.materials.textures.AtfData;
    import easiest.rendering.materials.textures.AtfTexture;
    import easiest.rendering.materials.textures.BaseTexture;
    import easiest.rendering.materials.textures.BitmapTexture;
    import easiest.rendering.sprites.batch.Sprite2DBatching;

    import flash.display.BitmapData;
    import flash.display.Stage;
    import flash.display3D.textures.Texture;
    import flash.geom.Matrix;
    import flash.utils.ByteArray;

    public class Sprite2D extends SpriteObject implements IClear
    {
        public static const useRegisters:int = 5;   // 一共用了多少寄存器
        private static var _stage:Stage;
        private static var _halfStageWidth:Number;
        private static var _halfStageHeight:Number;
        public static const vertexConstants:Vector.<Number> = new Vector.<Number>(Engine.MaxVertexConstants, true);

        public static function init(stage:Stage):void
        {
            if (Sprite2D.stage != null)
                return;
            Sprite2D.stage = stage;
            Sprite2DBatching.init();
        }

        public static function set stage(value:Stage):void
        {
            _stage = value;
            onResize(_stage);
        }

        public static function get stage():Stage
        {
            return _stage;
        }

        public static function onResize(stage:Stage):void
        {
            _halfStageWidth = stage.stageWidth / 2;
            _halfStageHeight = stage.stageHeight / 2;
        }

        private var _baseTexture:BaseTexture;
        private var _u:Number = 0;
        private var _v:Number = 0;
        private var _uvWidth:Number;
        private var _uvHeight:Number;
        private var _normalizeU:Number;
        private var _normalizeV:Number;
        private var _normalizeUVWidth:Number;
        private var _normalizeUVHeight:Number;
        private var _rotatedSprite:int; // 纹理集旋转了纹理
        private var _horizontalFlip:int;    // 8方向镜像

        private var _readying:Boolean = false;

        public function Sprite2D()
        {
            super();
        }

        override public function dispose():void
        {
            clear();
            super.dispose();
        }

        public function clear():void
        {
            if (_baseTexture)
            {
                _baseTexture.clear(onTextureUpdate);
                _baseTexture = null;
            }
            _u = 0;
            _v = 0;
            _uvWidth = NaN;
            _uvHeight = NaN;
            _normalizeU = NaN;
            _normalizeV = NaN;
            _normalizeUVWidth = NaN;
            _normalizeUVHeight = NaN;
            _readying = false;
        }

        public function setTexture(tex:Object):void
        {
            _readying = false;

            if (tex is BitmapData)
            {
                _baseTexture = new BitmapTexture(onTextureUpdate, BitmapData(tex));
            }
            else if (tex is ByteArray)
            {
                var atfData:AtfData = new AtfData(tex as ByteArray);
                _baseTexture = new AtfTexture(onTextureUpdate, atfData);
            }
            else if (tex is BitmapTexture || tex is AtfTexture)
            {
                _baseTexture = tex as BaseTexture;
                _baseTexture.addUpdate(onTextureUpdate);
            }
            else
            {
                throw new Error();
            }
        }

        private function onTextureUpdate(baseTexture:BaseTexture):void
        {
            if (isNaN(_uvWidth))
                _uvWidth = baseTexture.width;
            if (isNaN(_uvHeight))
                _uvHeight = baseTexture.height;
            // 把uv标准化在[0, 1]范围内
            _normalizeU = u / baseTexture.width;
            _normalizeV = v / baseTexture.height;
            _normalizeUVWidth = _uvWidth / baseTexture.width;
            _normalizeUVHeight = _uvHeight / baseTexture.height;

            _readying = baseTexture.ready;

            CONFIG::debug
            {
                Assert.assertTrue1(_normalizeU >= 0);
                Assert.assertTrue1(_normalizeV >= 0);
                Assert.assertTrue1(_normalizeUVWidth > 0);
                Assert.assertTrue1(_normalizeUVHeight > 0);
            }
        }

        override public function render(matrix:Matrix):void
        {
            if (!_readying)
                return;
            _globalTransformation.copyFrom(transformationMatrix);
            if (matrix)
                _globalTransformation.concat(matrix);
            Sprite2DBatching.add(this);
        }

        public function renderFilter():void
        {
            var constantsNumRegisters:int = setConstants(vertexConstants);
            _filter.draw(_baseTexture, vertexConstants, constantsNumRegisters);
        }

        public function setConstants(vertexConstants:Vector.<Number>, index:int = 0):int
        {
            var matrix:Matrix = _globalTransformation;

            // 顶点常量数据，必须和shader的声明顺序一致
//            var constantsNumRegisters:int = 0;

            vertexConstants[index++] = matrix.a;
            vertexConstants[index++] = matrix.c;
            vertexConstants[index++] = matrix.tx;
            vertexConstants[index++] = 0;
//            constantsNumRegisters++;    // 1

            vertexConstants[index++] = matrix.b;
            vertexConstants[index++] = matrix.d;
            vertexConstants[index++] = matrix.ty;
            vertexConstants[index++] = 0;
//            constantsNumRegisters++;    // 2

            vertexConstants[index++] = _width;
            vertexConstants[index++] = _height;
            vertexConstants[index++] = _halfStageWidth;
            vertexConstants[index++] = _halfStageHeight;
//            constantsNumRegisters++;    // 3

            vertexConstants[index++] = _normalizeU;
            vertexConstants[index++] = _normalizeV;
            vertexConstants[index++] = _normalizeUVWidth;
            vertexConstants[index++] = _normalizeUVHeight;
//            constantsNumRegisters++;    // 4

            vertexConstants[index++] = _rotatedSprite;
            vertexConstants[index++] = _horizontalFlip;
            vertexConstants[index++] = 0;   // 常量0
            vertexConstants[index] = 1;     // 常量1
//            constantsNumRegisters++;    // 5

            CONFIG::debug
            {
                Assert.assertEquals("寄存器数量有改变，需要调整shader代码", 5, useRegisters);
                Assert.assertFalse1(isNaN(matrix.a));
                Assert.assertFalse1(isNaN(matrix.b));
                Assert.assertFalse1(isNaN(matrix.c));
                Assert.assertFalse1(isNaN(matrix.d));
                Assert.assertFalse1(isNaN(matrix.tx));
                Assert.assertFalse1(isNaN(matrix.ty));
                Assert.assertFalse1(isNaN(_width));
                Assert.assertFalse1(isNaN(_height));
                Assert.assertFalse1(isNaN(_halfStageWidth));
                Assert.assertFalse1(isNaN(_halfStageHeight));
                Assert.assertFalse1(isNaN(_normalizeU));
                Assert.assertFalse1(isNaN(_normalizeV));
                Assert.assertFalse1(isNaN(_normalizeUVWidth));
                Assert.assertFalse1(isNaN(_normalizeUVHeight));
                Assert.assertFalse1(matrix.a == 0 && matrix.b == 0 && matrix.c == 0 && matrix.d == 0);
                Assert.assertTrue1(_width > 0);
                Assert.assertTrue1(_height > 0);
                Assert.assertTrue1(_halfStageWidth > 0);
                Assert.assertTrue1(_halfStageHeight > 0);
                Assert.assertTrue1(_normalizeU >= 0);
                Assert.assertTrue1(_normalizeV >= 0);
                Assert.assertTrue1(_normalizeUVWidth > 0);
                Assert.assertTrue1(_normalizeUVHeight > 0);
            }

            return 5;
        }

        public function get texture():Texture
        {
            return _baseTexture.texture;
        }

        public function get baseTexture():BaseTexture
        {
            return _baseTexture;
        }

        public function get u():Number
        {
            return _u;
        }

        public function set u(value:Number):void
        {
            Assert.assertFalse1(isNaN(value));

            if (_u == value)
                return;
            _u = value;
            if (_baseTexture)
                _normalizeU = value / _baseTexture.width;
        }

        public function get v():Number
        {
            return _v;
        }

        public function set v(value:Number):void
        {
            Assert.assertFalse1(isNaN(value));

            if (_v == value)
                return;
            _v = value;
            if (_baseTexture)
                _normalizeV = value / _baseTexture.height;
        }

        public function get uvWidth():Number
        {
            return _uvWidth;
        }

        public function set uvWidth(value:Number):void
        {
            if (_uvWidth == value)
                return;
            _uvWidth = value;
            if (_baseTexture)
                _normalizeUVWidth = value / _baseTexture.width;
        }

        public function get uvHeight():Number
        {
            return _uvHeight;
        }

        public function set uvHeight(value:Number):void
        {
            if (_uvHeight == value)
                return;
            _uvHeight = value;
            if (_baseTexture)
                _normalizeUVHeight = value / _baseTexture.height;
        }

        public function get rotatedSprite():Boolean
        {
            return _rotatedSprite == 1;
        }

        public function set rotatedSprite(value:Boolean):void
        {
            _rotatedSprite = value ? 1 : 0;
        }

        public function get horizontalFlip():Boolean
        {
            return _horizontalFlip == 1;
        }

        public function set horizontalFlip(value:Boolean):void
        {
            _horizontalFlip = value ? 1 : 0;
        }

        public function get ready():Boolean
        {
            return _readying;
        }

        override public function toString():String
        {
            var str:String = super.toString();
            if (ready == false)
                str += ", *ready";
            return str;
        }
    }
}
