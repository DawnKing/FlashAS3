package babylon.mesh {
    import babylon.Engine;
    import babylon.culling.BoundingInfo;
    import babylon.materials.Material;
    import babylon.materials.MultiMaterial;
    import babylon.math.Matrix;
    import babylon.math.Plane;
    import babylon.math.Vector3;

    import flash.display3D.IndexBuffer3D;

    public class SubMesh {
        public var linesIndexCount: Number;

        private var _mesh: AbstractMesh;
        private var _renderingMesh: Mesh;
        private var _boundingInfo: BoundingInfo;
        private var _linesIndexBuffer: IndexBuffer3D;
        public var _lastColliderWorldVertices: Vector.<Vector3>;
        public var _trianglePlanes: Vector.<Plane>;
        public var _lastColliderTransformMatrix: Matrix;

        public var _renderId: int = 0;
        public var _alphaIndex: Number;
        public var _distanceToCamera: Number;
        public var _id: Number;

        public var materialIndex: Number;
        public var verticesStart: Number;
        public var verticesCount: Number;
        public var indexStart: int;
        public var indexCount: Number;

        public function SubMesh(materialIndex: Number, verticesStart: Number, verticesCount: Number, indexStart: int, indexCount: Number, mesh: AbstractMesh, renderingMesh: Mesh = undefined, createBoundingBox: Boolean = true) {
            this.materialIndex = materialIndex;
            this.verticesStart = verticesStart;
            this.verticesCount = verticesCount;
            this.indexStart = indexStart;
            this.indexCount = indexCount;

            this._mesh = mesh;
            this._renderingMesh = renderingMesh || mesh as Mesh;
            mesh.subMeshes.push(this);

            this._trianglePlanes = new <Plane>[];

            this._id = mesh.subMeshes.length - 1;

            if (createBoundingBox) {
                this.refreshBoundingInfo();
                mesh.computeWorldMatrix(true);
            }
        }

        public function get IsGlobal(): Boolean {
            return (this.verticesStart === 0 && this.verticesCount == this._mesh.getTotalVertices());
        }

        public function getBoundingInfo(): BoundingInfo {
            if (this.IsGlobal) {
                return this._mesh.getBoundingInfo();
            }

            return this._boundingInfo;
        }

        public function getMesh(): AbstractMesh {
            return this._mesh;
        }

        public function getRenderingMesh(): Mesh {
            return this._renderingMesh;
        }

        public function getMaterial(): Material {
            var rootMaterial: Material = this._renderingMesh.material;

            if (rootMaterial && rootMaterial is MultiMaterial) {
                var multiMaterial: MultiMaterial = rootMaterial as MultiMaterial;
                return multiMaterial.getSubMaterial(this.materialIndex);
            }

            if (!rootMaterial) {
                return this._mesh.getScene().defaultMaterial;
            }

            return rootMaterial;
        }

        // Methods
        public function refreshBoundingInfo(): void {
            this._lastColliderWorldVertices = null;

            if (this.IsGlobal) {
                return;
            }
            var data: Vector.<Number> = this._renderingMesh.getVerticesData(VertexBuffer.PositionKind);

            if (!data) {
                this._boundingInfo = this._mesh._boundingInfo;
                return;
            }

            var indices: Vector.<uint> = this._renderingMesh.getIndices();
            var extend: Object =  { minimum: Vector3, maximum: Vector3 };

            //is this the only submesh?
            if (this.indexStart === 0 && this.indexCount === indices.length) {
                //the rendering mesh's bounding info can be used, it is the standard submesh for all indices.
                extend = { minimum: this._renderingMesh.getBoundingInfo().minimum.clone(), maximum: this._renderingMesh.getBoundingInfo().maximum.clone() };
            } else {
//                extend = Tools.ExtractMinAndMaxIndexed(data, indices, this.indexStart, this.indexCount, this._renderingMesh.geometry.boundingBias);
            }
            this._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);
        }

        public function _checkCollision(collider: Object): Boolean {
            return this.getBoundingInfo()._checkCollision(collider);
        }

        public function updateBoundingInfo(world: Matrix): void {
            if (!this.getBoundingInfo()) {
                this.refreshBoundingInfo();
            }
            this.getBoundingInfo().update(world);
        }

        public function isInFrustum(frustumPlanes: Vector.<Plane>): Boolean {
            return this.getBoundingInfo().isInFrustum(frustumPlanes);
        }

        public function isCompletelyInFrustum(frustumPlanes: Vector.<Plane>): Boolean {
            return this.getBoundingInfo().isCompletelyInFrustum(frustumPlanes);
        }

        public function render(enableAlphaMode: Boolean): void {
            this._renderingMesh.render(this, enableAlphaMode);
        }

        public function getLinesIndexBuffer(indices: Vector.<uint>, engine: Engine): IndexBuffer3D {
            if (!this._linesIndexBuffer) {
                var linesIndices: Vector.<uint> = new <uint>[];

                for (var index: int = this.indexStart; index < this.indexStart + this.indexCount; index += 3) {
                    linesIndices.push(indices[index], indices[index + 1],
                            indices[index + 1], indices[index + 2],
                            indices[index + 2], indices[index]);
                }

                this._linesIndexBuffer = engine.createIndexBuffer(linesIndices);
                this.linesIndexCount = linesIndices.length;
            }
            return this._linesIndexBuffer;
        }

        public function canIntersects(ray: Object): Boolean {
            return ray.intersectsBox(this.getBoundingInfo().boundingBox);
        }

        // Clone
        public function clone(newMesh: AbstractMesh, newRenderingMesh: Mesh = undefined): SubMesh {
            var result: SubMesh = new SubMesh(this.materialIndex, this.verticesStart, this.verticesCount, this.indexStart, this.indexCount, newMesh, newRenderingMesh, false);

            if (!this.IsGlobal) {
                result._boundingInfo = new BoundingInfo(this.getBoundingInfo().minimum, this.getBoundingInfo().maximum);
            }

            return result;
        }

        // Dispose
        public function dispose(): void {
            if (this._linesIndexBuffer) {
                this._mesh.getScene().getEngine()._releaseBuffer(this._linesIndexBuffer);
                this._linesIndexBuffer = null;
            }

            // Remove from mesh
            var index:int = this._mesh.subMeshes.indexOf(this);
            this._mesh.subMeshes.splice(index, 1);
        }

        // Statics
        public static function CreateFromIndices(materialIndex: Number, startIndex: Number, indexCount: Number, mesh: AbstractMesh, renderingMesh: Mesh = undefined): SubMesh {
            var minVertexIndex: Number = Number.MAX_VALUE;
            var maxVertexIndex: Number = -Number.MAX_VALUE;

            renderingMesh = renderingMesh || mesh as Mesh;
            var indices: Vector.<uint> = renderingMesh.getIndices();

            for (var index: int = startIndex; index < startIndex + indexCount; index++) {
                var vertexIndex: uint = indices[index];

                if (vertexIndex < minVertexIndex)
                    minVertexIndex = vertexIndex;
                if (vertexIndex > maxVertexIndex)
                    maxVertexIndex = vertexIndex;
            }

            return new SubMesh(materialIndex, minVertexIndex, maxVertexIndex - minVertexIndex + 1, startIndex, indexCount, mesh, renderingMesh);
        }
    }
}
