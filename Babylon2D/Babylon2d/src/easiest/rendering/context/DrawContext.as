/**
 * Created by caijingxiao on 2017/7/13.
 */
package easiest.rendering.context
{
    import easiest.debug.Assert;
    import easiest.rendering.Engine;
    import easiest.rendering.materials.textures.BaseTexture;
    import easiest.rendering.sprites.batch.Sprite2DBatching;

    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
    import flash.utils.Dictionary;

    public class DrawContext
    {
        public static var indexBuffer:IndexBuffer3D;
        protected var _engine:Engine;
        protected var _program:Dictionary = new Dictionary(true);

        public function DrawContext()
        {
            _engine = Engine.inst;
            createIndexBuffer(Sprite2DBatching.batchMaxCount);
            createVertexBuffer(Sprite2DBatching.batchMaxCount);
        }

        public function createIndexBuffer(numSprites:int):void
        {
            if (indexBuffer != null)
                return;
            var numIndices:int = numSprites * 6;
            var data:Vector.<uint> = new Vector.<uint>();
            for (var i:int = 0, index:int = 0; i < numSprites; i++)
            {
                data[index++] = 4 * i + 0;
                data[index++] = 4 * i + 1;
                data[index++] = 4 * i + 2;
                data[index++] = 4 * i + 0;
                data[index++] = 4 * i + 2;
                data[index++] = 4 * i + 3;
            }

            Assert.assertEquals1(numIndices, index);

            indexBuffer = _engine.createIndexBuffer(numIndices, data);
        }

        public function createVertexBuffer(numSprites:int):void
        {
            var numVertices:int = numSprites * 4;
            var vertexData:Vector.<Number> = new <Number>[
                // 后台缓存区的坐标范围为[-1, 1]，以左上角(0, 0)点为中心点，向右x递增，向下y递增
                // UV坐标的范围为[0, 1]，以左上角(0, 0)点为中心点，向右x递增，向下y递增
                // 坐标x,坐标y, u, v, 旋转过的纹理uv
                0,  0,  0,  0,     1,  0,  // 顶点0，左上
                1,  0,  1,  0,     1,  1,  // 顶点1，右上
                1,  1,  1,  1,     0,  1,  // 顶点2，右下
                0,  1,  0,  1,     0,  0   // 顶点3，左下
            ];

            var data:Vector.<Number> = new Vector.<Number>();
            for (var i:int = 0; i < numSprites; i++)
            {
                data = data.concat(vertexData.slice());
            }

            var vertexBuffer:VertexBuffer3D = _engine.createVertexBuffer(numVertices, 6, data);

            _engine.setVertexBuffer(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
            _engine.setVertexBuffer(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
            _engine.setVertexBuffer(2, vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_2);
        }

        public function setContext(baseTexture:BaseTexture):void
        {
        }

        public function setContext2(format:String):void
        {
        }

        public function getProgram(shaderName:String, format:String):Program3D
        {
            if (format in _program)
            {
                return _program[format];
            }
            _program[format] = _engine.createProgram(shaderName, format);
            return _program[format];
        }
    }
}
