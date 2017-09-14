package babylon.mesh {
    import babylon.Engine;

    import flash.display3D.VertexBuffer3D;

    public class Buffer {
        private var _engine: Engine;
        private var _buffer: VertexBuffer3D;
        private var _data: Vector.<Number>;
        private var _updatable: Boolean;
        private var _strideSize: Number;
        private var _instanced: Boolean;

        public function Buffer(engine: Engine, data: Vector.<Number>, updatable: Boolean, stride: Number, postponeInternalCreation: Boolean = false, instanced: Boolean = false) {
            this._engine = engine;

            this._updatable = updatable;

            this._data = data;

            this._strideSize = stride;

            if (!postponeInternalCreation) { // by default
                this.create();
            }

            this._instanced = instanced;
        }

        public function createVertexBuffer(kind: String, offset: int, size: String, stride: int = 0): VertexBuffer {
            // a lot of these parameters are ignored as they are overriden by the buffer
            return new VertexBuffer(this._engine, this, kind, this._updatable, true, stride ? stride : this._strideSize, this._instanced, offset, size);
        }

        // Properties
        public function isUpdatable(): Boolean {
            return this._updatable;
        }

        public function getData(): Vector.<Number> {
            return this._data;
        }

        public function getBuffer(): VertexBuffer3D {
            return this._buffer;
        }

        public function getStrideSize(): Number {
            return this._strideSize;
        }

        public function getIsInstanced(): Boolean {
            return this._instanced;
        }

        // Methods
        public function create(data: Vector.<Number> = null): void {
            if (!data && this._buffer) {
                return; // nothing to do
            }

            data = data || this._data;

            if (!this._buffer) { // create buffer
                if (this._updatable) {
                    this._buffer = this._engine.createVertexBuffer(data, this._strideSize);
                    this._data = data;
                } else {
                    this._buffer = this._engine.createVertexBuffer(data, this._strideSize);
                }
            } else if (this._updatable) { // update buffer
                this._engine.updateDynamicVertexBuffer(this._buffer, data, 0, this._strideSize);
                this._data = data;
            }
        }

        public function update(data: Vector.<Number>): void {
            this.create(data);
        }

        public function updateDirectly(data: Vector.<Number>, offset: Number, vertexCount: Number = undefined): void {
            if (!this._buffer) {
                return;
            }

            if (this._updatable) { // update buffer
                this._engine.updateDynamicVertexBuffer(this._buffer, data, offset, (vertexCount ? vertexCount * this.getStrideSize() : undefined));
                this._data = null;
            }
        }

        public function dispose(): void {
            if (!this._buffer) {
                return;
            }
            if (this._engine._releaseBuffer(this._buffer)) {
                this._buffer = null;
            }
        }
    }
}
