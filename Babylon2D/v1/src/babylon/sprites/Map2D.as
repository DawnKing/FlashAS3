/**
 * Created by caijingxiao on 2017/6/16.
 */
package babylon.sprites
{
    import babylon.Engine;
    import babylon.Scene;
    import babylon.materials.Effect;
    import babylon.materials.textures.Texture;
    import babylon.mesh.Buffer;
    import babylon.mesh.VertexBuffer;

    import flash.display.BitmapData;

    import flash.display.Stage;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.utils.Dictionary;

    public class Map2D extends BaseSprite
    {
        private static const JPG_SIZE:uint = 512;
        private static const VertexPosition:String = "vertexPosition";

        private static var _vertexBuffers:Dictionary = new Dictionary(true);   // vertex attribute - VertexBuffer

        public static function init(scene:Scene, stage:Stage):void
        {
            var w:Number = JPG_SIZE / stage.stageWidth * 2; // 后台缓存区的范围为[-1, 1]
            var h:Number = JPG_SIZE / stage.stageHeight * 2;
            // 顶点数据为在后台缓存区中的顶点坐标，原点为（0, 0）
            var vertexData:Vector.<Number> = new <Number>[
                // 顶点0：坐标x,坐标y, u, v
                0,  0,  0,  0,
                 w,  0,  1,  0,
                 w, -h,  1,  1,
                0, -h,  0,  1
            ];

            // VBOs
            var buffer:Buffer = new Buffer(scene.getEngine(), vertexData, false, 4);
            _vertexBuffers[VertexPosition] = buffer.createVertexBuffer(VertexPosition, 0, Context3DVertexBufferFormat.FLOAT_2, 2);
            _vertexBuffers[VertexBuffer.UVKind] = buffer.createVertexBuffer(VertexBuffer.UVKind, 2, Context3DVertexBufferFormat.FLOAT_2, 2);
        }

        public function Map2D(scene:Scene)
        {
            super(scene);

            var attributes: Vector.<String> = new <String>[VertexPosition, VertexBuffer.UVKind];
            var uniforms: Vector.<String> = new <String>[
                "position", "vertexConst0", "vertexConst1"];
            var samplers: Vector.<String> = new <String>["diffuseSampler"];

            this._effect = scene.getEngine().createEffect("map", attributes, uniforms, samplers, "");
        }

        public function render():void
        {
            if (!_spriteTexture.isReady())
                return;

            var engine:Engine = _scene.getEngine();

            engine.enableEffect(_effect);
            // VBOs
            engine.bindBuffers(_vertexBuffers, _effect);

            // vertex
            var normalizeX:Number = x / BaseSprite.stage.stageWidth * 2 - 1;
            var normalizeY:Number = -(y / BaseSprite.stage.stageHeight * 2 - 1);
            _effect.setFloat2("position", normalizeX, normalizeY);
            _effect.setFloat("vertexConst0", 0);
            _effect.setFloat("vertexConst1", 1);

            // fragment
            // samplers
            _effect.setTexture("diffuseSampler", _spriteTexture);

            engine.draw(BaseSprite.indexBuffer);

            engine.resetTextureCache();
        }
    }
}
