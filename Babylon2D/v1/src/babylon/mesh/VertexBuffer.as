package babylon.mesh {
    import babylon.Engine;

    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.VertexBuffer3D;

    public class VertexBuffer {
        private var _buffer: Buffer;
        private var _kind: String;
        private var _offset: Number;
        private var _size: String;
        private var _stride: int;
        private var _ownsBuffer: Boolean;

        public function VertexBuffer(engine: Engine, data: Object, kind: String, updatable: Boolean, postponeInternalCreation: Boolean = false,
                                     stride: int = 0, instanced: Boolean = false, offset: int = 0, size: String = null) {
            var format: String;
            if (!stride) {
                // Deduce stride from kind
                switch (kind) {
                    case PositionKind:
                        stride = 3;
                        format = Context3DVertexBufferFormat.FLOAT_3;
                        break;
                    case NormalKind:
                        stride = 3;
                        format = Context3DVertexBufferFormat.FLOAT_3;
                        break;
                    case UVKind:
                        stride = 2;
                        format = Context3DVertexBufferFormat.FLOAT_2;
                        break;
                    case ColorKind:
                        stride = 4;
                        format = Context3DVertexBufferFormat.FLOAT_4;
                        break;
                    case MatricesIndicesKind:
                        stride = 4;
                        format = Context3DVertexBufferFormat.FLOAT_4;
                        break;
                    case MatricesWeightsKind:
                        stride = 4;
                        format = Context3DVertexBufferFormat.FLOAT_4;
                        break;
                }
            }

            if (data is Buffer) {
                if (!stride) {
                    stride = data.getStrideSize();
                }
                this._buffer = data as Buffer;
                this._ownsBuffer = false;
            } else {

                if (kind == VertexBuffer.UVKind) {
                    // flash uv coordinate origin is on top-left, 3ds max is on bottom-left
                    var flashUVs: Vector.<Number> = new Vector.<Number>(data.length, true);
                    for (var i: int = 0; i < data.length; i+=2) {
                        flashUVs[i] = data[i];
                        flashUVs[i+1] = 1 - data[i+1];
                    }

                    data = flashUVs;
                }

                this._buffer = new Buffer(engine, data as Vector.<Number>, updatable, stride, postponeInternalCreation, instanced);
                this._ownsBuffer = true;
            }

            this._stride = stride;

            this._offset = !isNaN(offset) ? offset : 0;
            this._size = size ? size : format;

            this._kind = kind;
        }


        public function getKind(): String {
            return this._kind;
        }

        // Properties
        public function isUpdatable(): Boolean {
            return this._buffer.isUpdatable();
        }

        public function getData(): Vector.<Number> {
            return this._buffer.getData();
        }

        public function getBuffer(): VertexBuffer3D {
            return this._buffer.getBuffer();
        }

        public function getStrideSize(): int {
            return this._stride;
        }

        public function getOffset(): Number {
            return this._offset;
        }

        public function getSize(): String {
            return this._size;
        }

        public function getIsInstanced(): Boolean {
            return this._buffer.getIsInstanced();
        }

        public function create(data: Vector.<Number> = null): void {
            return this._buffer.create(data);
        }

        public function update(data: Vector.<Number>): void {
            return this._buffer.update(data);
        }

        public function updateDirectly(data: Vector.<Number>, offset: Number): void {
            return this._buffer.updateDirectly(data, offset);
        }

        public function dispose(): void {
            if (this._ownsBuffer) {
                this._buffer.dispose();
            }
        }

        // Enums
        public static const PositionKind: String = "position";
        public static const NormalKind: String = "normal";
        public static const UVKind: String = "uv";
        public static const UV2Kind: String = "uv2";

        public static const ColorKind: String = "color";

        public static const MatricesIndicesKind: String = "matricesIndices";
        public static const MatricesWeightsKind: String = "matricesWeights";
    }
}
