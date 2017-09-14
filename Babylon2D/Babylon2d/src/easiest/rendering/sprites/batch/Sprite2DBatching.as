/**
     * Created by caijingxiao on 2017/7/3.
     */
package easiest.rendering.sprites.batch
{
    import easiest.rendering.Engine;
    import easiest.rendering.context.ConstantBatchContext;
    import easiest.rendering.context.DrawContext;
    import easiest.rendering.sprites.*;

    import flash.display.BlendMode;

    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Program3D;
    import flash.display3D.textures.Texture;

    public class Sprite2DBatching
    {
//        public static var indexBuffer:IndexBuffer3D;
//        public static var vertexBuffer:VertexBuffer3D;

        public static const batchMaxCount:int = 8;
        public static const constantsOffset:int = batchMaxCount / 4;    // 常量占用的寄存器数量
        public static const vertexConstants:Vector.<Number> = new Vector.<Number>(Engine.MaxVertexConstants, true);

        private static var _context:ConstantBatchContext;

        public static function init():void
        {
            _context = new ConstantBatchContext();

            for (var i:int = 0; i < batchMaxCount; i++)
            {
                vertexConstants[i] = i;
            }
        }

        private static var _listDXT1:Vector.<Sprite2D> = new Vector.<Sprite2D>(1000, true);
        private static var _indexDXT1:int = 0;
        private static var _listDXT5:Vector.<Sprite2D> = new Vector.<Sprite2D>(1000, true);
        private static var _indexDXT5:int = 0;
        private static var _listRGBA:Vector.<Sprite2D> = new Vector.<Sprite2D>(1000, true);
        private static var _indexRGBA:int = 0;

        public static function clear():void
        {
            _indexDXT1 = 0;
            _indexDXT5 = 0;
            _indexRGBA = 0;
        }

        public static function add(sprite:Sprite2D):void
        {
            switch (sprite.baseTexture.format)
            {
                case Context3DTextureFormat.COMPRESSED_ALPHA:
                    addDXT5(sprite);
                    break;
                case Context3DTextureFormat.COMPRESSED:
                    addDXT1(sprite);
                    break;
                case Context3DTextureFormat.BGRA:
                    addRGBA(sprite);
                    break;
                default:
                    throw new Error();
            }
        }

        public static function addDXT1(sprite:Sprite2D):void
        {
            _listDXT1[_indexDXT1++] = sprite;
        }

        public static function addDXT5(sprite:Sprite2D):void
        {
            _listDXT5[_indexDXT5++] = sprite;
        }

        public static function addRGBA(sprite:Sprite2D):void
        {
            _listRGBA[_indexRGBA++] = sprite;
        }

        public static function render():void
        {
            if (_indexDXT1 != 0)
            {
                Engine.inst.setBlendMode(BlendMode.NORMAL);
                batchRender(_indexDXT1, _listDXT1, Context3DTextureFormat.COMPRESSED);
            }
            if (_indexDXT5 != 0)
            {
                Engine.inst.setBlendMode(BlendMode.ALPHA);
                batchRender(_indexDXT5, _listDXT5, Context3DTextureFormat.COMPRESSED_ALPHA);
            }
            if (_indexRGBA != 0)
            {
                batchRender(_indexRGBA, _listRGBA, Context3DTextureFormat.BGRA);
            }
        }

        private static function batchRender(count:int, list:Vector.<Sprite2D>, format:String):void
        {
            if (count == 0)
                return;

            var engine:Engine = Engine.inst;
            var index:int = 0;
            var contextChanged:Boolean = true;
            while (index < count)
            {
                var constantsNumRegisters:int = constantsOffset;
                var numTriangles:int = 0;
                var batchIndex:int = 0;
                var sprite:Sprite2D;

                if (contextChanged)
                {
                    _context.setContext2(format);
                }
                while (batchIndex < batchMaxCount && index < count)
                {
                    sprite = list[index++];
                    if (sprite.filter)
                        break;

                    var texture:Texture = sprite.texture;
                    var numRegisters:int = sprite.setConstants(vertexConstants, constantsNumRegisters * 4);
                    constantsNumRegisters += numRegisters;
                    engine.setTexture(batchIndex, texture);
                    batchIndex++;
                    numTriangles += 2;
                }

                if (numTriangles != 0)
                {
                    engine.draw(vertexConstants, constantsNumRegisters, DrawContext.indexBuffer, numTriangles);
                }
                if (sprite.filter)
                {
                    sprite.renderFilter();
                    contextChanged = true;
                }
            }
        }
    }
}

