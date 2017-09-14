/**
 * Created by caijingxiao on 2017/6/20.
 */
package babylon.sprites
{
    import babylon.Engine;
    import babylon.Scene;
    import babylon.mesh.Buffer;

    import flash.display3D.Context3DVertexBufferFormat;
    import flash.utils.Dictionary;

    public class Effect2D extends BaseSprite
    {
        public static const VertexQuad:String = "vertexQuad";
        public static const UVQuad:String = "uvQuad";

        public static var VertexBuffers:Dictionary = new Dictionary(true);   // vertex attribute - VertexBuffer

        public var width:Number = 0;
        public var height:Number = 0;

        public var u:Number = 0;
        public var v:Number = 0;
        public var uvWidth:Number = 0;
        public var uvHeight:Number = 0;

        public static function init(scene:Scene):void
        {
            var vertexData:Vector.<Number> = new <Number>[
                // 顶点0：坐标x,坐标y, u, v
                0,  0,  0,  0,
                1,  0,  1,  0,
                1, -1,  1,  1,
                0, -1,  0,  1
            ];

            // VBOs
            var buffer:Buffer = new Buffer(scene.getEngine(), vertexData, false, 4);
            VertexBuffers[VertexQuad] = buffer.createVertexBuffer(VertexQuad, 0, Context3DVertexBufferFormat.FLOAT_2, 2);
            VertexBuffers[UVQuad] = buffer.createVertexBuffer(UVQuad, 2, Context3DVertexBufferFormat.FLOAT_2, 2);
        }


        public function Effect2D(scene:Scene)
        {
            super(scene);

            var attributes: Vector.<String> = new <String>[VertexQuad, UVQuad];
            var uniforms: Vector.<String> = new <String>[
                "position", "widthHeight", "uvPosition", "uvWidthHeight",
                "vertexConst0", "vertexConst1"];
            var samplers: Vector.<String> = new <String>["diffuseSampler"];

            this._effect = scene.getEngine().createEffect("effect", attributes, uniforms, samplers, "");
        }

        override public function setTexture(tex:Object):void
        {
            super.setTexture(tex);

            uvWidth = uvWidth == 0 ? tex.width : uvWidth;
            uvHeight = uvHeight == 0 ? tex.height : uvHeight;
        }

        public function render():void
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

            // fragment

            // samplers
            _effect.setTexture("diffuseSampler", _spriteTexture);

            engine.draw(indexBuffer);

            engine.resetTextureCache();
        }
    }
}
