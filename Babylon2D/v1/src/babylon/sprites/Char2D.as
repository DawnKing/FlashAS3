/**
    * Created by caijingxiao on 2017/6/16.
    */
package babylon.sprites
{
    import babylon.Engine;
    import babylon.Scene;
    import babylon.mesh.Buffer;

    import flash.display3D.Context3DVertexBufferFormat;
    import flash.utils.Dictionary;

    public class Char2D extends BaseSprite
    {
        public static const VertexQuad:String = "vertexQuad";
        public static const UVQuad:String = "uvQuad";
        public static const RotatedUVQuad:String = "rotatedUVQuad";

        public static var VertexBuffers:Dictionary = new Dictionary(true);   // vertex attribute - VertexBuffer

        public var width:Number = 0;
        public var height:Number = 0;

        public var u:Number = 0;
        public var v:Number = 0;
        public var uvWidth:Number = 0;
        public var uvHeight:Number = 0;

        public static function init(scene:Scene):void
        {
            // 后台缓存区坐标系为标准笛卡尔坐标系，x和y的范围都是[-1, 1]，以（0， 0）点为中心点
            // uv坐标为左上角（0， 0）点，x向右递增，y向下递增
            // 顶点数据为在笛卡尔坐标系的第四象限中四边形的顶点值，分为正常位置数据和旋转后的位置数据
            var vertexData:Vector.<Number> = new <Number>[
                // 顶点0：坐标x,坐标y, u, v, 旋转过的纹理uv
                0,  0,  0,  0,     1,  0,
                1,  0,  1,  0,     1,  1,
                1, -1,  1,  1,     0,  1,
                0, -1,  0,  1,     0,  0
            ];

            // VBOs
            var buffer:Buffer = new Buffer(scene.getEngine(), vertexData, false, 6);
            VertexBuffers[VertexQuad] = buffer.createVertexBuffer(VertexQuad, 0, Context3DVertexBufferFormat.FLOAT_2, 2);
            VertexBuffers[UVQuad] = buffer.createVertexBuffer(UVQuad, 2, Context3DVertexBufferFormat.FLOAT_2, 2);
            VertexBuffers[RotatedUVQuad] = buffer.createVertexBuffer(RotatedUVQuad, 4, Context3DVertexBufferFormat.FLOAT_2, 2);
        }

        public function Char2D(scene:Scene)
        {
            super(scene);

            var attributes: Vector.<String> = new <String>[VertexQuad, UVQuad, RotatedUVQuad];
            var uniforms: Vector.<String> = new <String>[
                "position", "widthHeight", "uvPosition", "uvWidthHeight",
                "vertexConst0", "vertexConst1",
                "rotated", "mirror"];
            var samplers: Vector.<String> = new <String>["diffuseSampler"];

            this._effect = scene.getEngine().createEffect("char", attributes, uniforms, samplers, "");
        }

        override public function setTexture(tex:Object):void
        {
            super.setTexture(tex);

            uvWidth = uvWidth == 0 ? tex.width : uvWidth;
            uvHeight = uvHeight == 0 ? tex.height : uvHeight;
        }

        public function render(rotated:Boolean = false, mirror:Boolean = false):void
        {
            if (!_spriteTexture.isReady())
                return;

            var engine:Engine = _scene.getEngine();

            engine.enableEffect(_effect);
            // VBOs
            engine.bindBuffers(VertexBuffers, _effect);

            // vertex
            // 把坐标标准化在[-1, 1]范围内
            var normalizeX:Number = x / stage.stageWidth * 2 - 1;
            var normalizeY:Number = -(y / stage.stageHeight * 2 - 1);
            var normalizeWidth:Number = width / stage.stageWidth * 2;
            var normalizeHeight:Number = height / stage.stageHeight * 2;

            _effect.setFloat2("position", normalizeX, normalizeY);
            _effect.setFloat2("widthHeight", normalizeWidth, normalizeHeight);

            var normalizeU:Number = u / _spriteTexture.width;
            var normalizeV:Number = v / _spriteTexture.height;
            var normalizeUVWidth:Number = uvWidth / _spriteTexture.width;
            var normalizeUVHeight:Number = uvHeight / _spriteTexture.height;
            _effect.setFloat2("uvPosition", normalizeU, normalizeV);
            _effect.setFloat2("uvWidthHeight", normalizeUVWidth, normalizeUVHeight);

            _effect.setFloat("vertexConst0", 0);
            _effect.setFloat("vertexConst1", 1);
            _effect.setFloat("rotated", rotated ? 1 : 0);
            _effect.setFloat("mirror", mirror ? 1 : 0);

            // fragment

            // samplers
            _effect.setTexture("diffuseSampler", _spriteTexture);

            engine.draw(indexBuffer);

            engine.resetTextureCache();
        }
    }
}
