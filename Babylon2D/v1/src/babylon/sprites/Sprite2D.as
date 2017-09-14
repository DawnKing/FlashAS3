/**
 * Created by caijingxiao on 2017/6/21.
 */
package babylon.sprites
{
    import babylon.Scene;
    import babylon.materials.Effect;
    import babylon.materials.textures.Texture;

    import easiest.unit.Assert;

    import flash.display.BitmapData;
    import flash.display.Stage;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DBufferUsage;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;

    public class Sprite2D
    {
        public static const VertexQuad:String = "vertexQuad";
        public static const UVQuad:String = "uvQuad";
        public static const RotatedUVQuad:String = "rotatedUVQuad";

        public static var stage:Stage;
        public static var context3D:Context3D;
        public static var indexBuffer:IndexBuffer3D;

        private static const constants:Vector.<Number> = new Vector.<Number>(128 * 4, true);

        public var x:Number = 0;
        public var y:Number = 0;
        public var width:Number = 0;
        public var height:Number = 0;

        public var u:Number = 0;
        public var v:Number = 0;
        public var uvWidth:Number = 0;
        public var uvHeight:Number = 0;

        protected var _scene:Scene;
        protected var _spriteTexture:Texture;

        public static function init(scene:Scene, stage:Stage):void
        {
            if (indexBuffer != null)
                return;

            Sprite2D.stage = stage;

            indexBuffer = scene.getEngine().createIndexBuffer(new <uint>[0, 1, 2, 0, 2, 3], Context3DBufferUsage.STATIC_DRAW);

            var vertexData:Vector.<Number> = new <Number>[
                // 顶点0：坐标x,坐标y, u, v, 旋转过的纹理uv
                0,  0,  0,  0,     1,  0,
                1,  0,  1,  0,     1,  1,
                1, -1,  1,  1,     0,  1,
                0, -1,  0,  1,     0,  0
            ];

            // VBOs
            context3D = scene.getEngine().context3D;
            var buffer:VertexBuffer3D = context3D.createVertexBuffer(4, 6);
            buffer.uploadFromVector(vertexData, 0, 4);

            context3D.setVertexBufferAt(0, buffer, 0, Context3DVertexBufferFormat.FLOAT_2);
            context3D.setVertexBufferAt(1, buffer, 2, Context3DVertexBufferFormat.FLOAT_2);
            context3D.setVertexBufferAt(2, buffer, 3, Context3DVertexBufferFormat.FLOAT_2);

            var attributes: Vector.<String> = new <String>[VertexQuad, UVQuad, RotatedUVQuad];
            var uniforms: Vector.<String> = new <String>[
                "position", "widthHeight", "uvPosition", "uvWidthHeight",
                "vertexConst0", "vertexConst1",
                "rotated", "mirror"];
            var samplers: Vector.<String> = new <String>["diffuseSampler"];

            var effect:Effect = scene.getEngine().createEffect("sprite", attributes, uniforms, samplers, "");
            context3D.setProgram(effect.getProgram().program);
        }

        public function Sprite2D(scene:Scene)
        {
            _scene = scene;
        }

        public function setTexture(tex:Object):void
        {
            if (tex is BitmapData)
            {
                _spriteTexture = new Texture(BitmapData(tex), _scene);
            }
            else if (tex is Texture)
            {
                _spriteTexture = Texture(tex);
            }

            Assert.assertTrue1(width != 0);
            Assert.assertTrue1(height != 0);

            uvWidth = uvWidth == 0 ? tex.width : uvWidth;
            uvHeight = uvHeight == 0 ? tex.height : uvHeight;
        }

        public function render(rotated:Boolean = false, mirror:Boolean = false):void
        {
            if (!_spriteTexture.isReady())
                return;

            var index:int = 0;
            // vertex
            // 把坐标标准化在[-1, 1]范围内
            var normalizeX:Number = x / stage.stageWidth * 2 - 1;
            var normalizeY:Number = -(y / stage.stageHeight * 2 - 1);
            var normalizeWidth:Number = width / stage.stageWidth * 2;
            var normalizeHeight:Number = height / stage.stageHeight * 2;

            constants[index++] = normalizeX;
            constants[index++] = normalizeY;
            constants[index++] = normalizeWidth;
            constants[index++] = normalizeHeight;

            var normalizeU:Number = u / _spriteTexture.width;
            var normalizeV:Number = v / _spriteTexture.height;
            var normalizeUVWidth:Number = uvWidth / _spriteTexture.width;
            var normalizeUVHeight:Number = uvHeight / _spriteTexture.height;

            constants[index++] = normalizeU;
            constants[index++] = normalizeV;
            constants[index++] = normalizeUVWidth;
            constants[index++] = normalizeUVHeight;

            constants[index++] = 0; // vertexConst0
            constants[index++] = 1; // vertexConst1
            constants[index++] = rotated ? 1 : 0;
            constants[index++] = mirror ? 1 : 0;

            context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, constants, 3);
            // samplers
            context3D.setTextureAt(0, _spriteTexture._texture.flashTexture);

            context3D.drawTriangles(indexBuffer);
        }
    }
}
