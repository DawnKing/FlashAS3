/**
     * Created by caijingxiao on 2017/7/13.
     */
package easiest.rendering.context
{
    import easiest.rendering.Engine;
    import easiest.rendering.sprites.Sprite2D;
    import easiest.rendering.sprites.batch.Sprite2DBatching;

    import flash.display.BitmapData;

    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.VertexBuffer3D;
    import flash.display3D.textures.Texture;

    public class ConstantBatchContext extends DrawContext
    {
        private static var _fragmentConstants:Vector.<Number>;
        private static var _batchIndexBuffer:VertexBuffer3D;

        [Embed(source="empty1.atf", mimeType="application/octet-stream")]
        private static const ATF1:Class;
        [Embed(source="empty5.atf", mimeType="application/octet-stream")]
        private static const ATF5:Class;
        public static var emptyDxt1:Texture;
        public static var emptyDxt5:Texture;
        public static var emptyRGBA:Texture;

        public function ConstantBatchContext()
        {
            super();

            if (_fragmentConstants == null)
            {
                _fragmentConstants = new Vector.<Number>(Engine.MaxFragmentConstants, true);
                for (var i:int = 0; i < Sprite2DBatching.batchMaxCount; i++)
                {
                    _fragmentConstants[i] = i;
                }

                // 避免Error #3663: 取样器 1 绑定的纹理未定义。
                emptyRGBA = _engine.context3D.createTexture(1, 1, Context3DTextureFormat.BGRA, false);
                emptyRGBA.uploadFromBitmapData(new BitmapData(1, 1, true, 0xFF00FF00));

                emptyDxt1 = _engine.context3D.createTexture(4, 4, Context3DTextureFormat.COMPRESSED, false);
                emptyDxt1.uploadCompressedTextureFromByteArray(new ATF1(), 0);

                emptyDxt5 = _engine.context3D.createTexture(4, 4, Context3DTextureFormat.COMPRESSED_ALPHA, false);
                emptyDxt5.uploadCompressedTextureFromByteArray(new ATF5(), 0);
            }
        }

        override public function createVertexBuffer(numSprites:int):void
        {
            super.createVertexBuffer(numSprites);

            if (_batchIndexBuffer != null)
                return;
            // 合并渲染索引，指示起始寄存器
            var numVertices:int = numSprites * 4;
            var data:Vector.<Number> = new Vector.<Number>();
            for (var i:int = 0; i < numSprites; i++)
            {
                var batchIndex:int = i * Sprite2D.useRegisters + Sprite2DBatching.constantsOffset;
                data.push(batchIndex, batchIndex, batchIndex, batchIndex);
            }
            _batchIndexBuffer = _engine.createVertexBuffer(numVertices, 1, data);
        }

        override public function setContext2(format:String):void
        {
            _engine.setConstants(Context3DProgramType.FRAGMENT, 0, _fragmentConstants);
            _engine.setVertexBuffer(3, _batchIndexBuffer, 0, Context3DVertexBufferFormat.FLOAT_1);

            var emptyTexture:Texture;
            switch (format)
            {
                case Context3DTextureFormat.COMPRESSED:
                    emptyTexture = emptyDxt1;
                    break;
                case Context3DTextureFormat.COMPRESSED_ALPHA:
                    emptyTexture = emptyDxt5;
                    break;
                default:
                    emptyTexture = emptyRGBA;
                    break;
            }

            _engine.setTextures(emptyTexture);
            _engine.setProgram(getProgram("spriteBatching", format));
        }
    }
}
