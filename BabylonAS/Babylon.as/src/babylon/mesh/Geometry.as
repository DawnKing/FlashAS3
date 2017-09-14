/**
 * Created by caijingxiao on 2016/10/18.
 */
package babylon.mesh {
    import babylon.culling.BoundingInfo;
    import babylon.Engine;
    import babylon.Scene;
    import babylon.math.Color4;
    import babylon.math.Vector2;
    import babylon.math.Vector3;
    import babylon.tools.Tools;

    import easiest.unit.asserts.fail;

    import flash.display3D.IndexBuffer3D;
    import flash.utils.Dictionary;

    public class Geometry implements  IGetSetVerticesData {
        // Members
        public var id: String;
        public var delayLoadState: int = Engine.DELAYLOADSTATE_NONE;
        public var delayLoadingFile: String;
        public var onGeometryUpdated: Function; // (geometry: Geometry, kind: String = undefined) => void;

        // Private
        private var _scene: Scene;
        private var _engine: Engine;
        private var _meshes: Vector.<Mesh>;
        private var _totalVertices: Number = 0;
        private var _indices: Vector.<uint>;
        private var _vertexBuffers: Dictionary; // { [key: String]: VertexBuffer; };
        private var _isDisposed: Boolean = false;
        private var _extend: Object;    // { minimum: Vector3, maximum: Vector3 };
        private var _boundingBias: Vector2;
        public var _delayInfo: Object; //ANY
        private var _indexBuffer: IndexBuffer3D;
        public var _boundingInfo: BoundingInfo;
        public var _delayLoadingFunction: Function; // (any: any, geometry: Geometry) => void;
        public var _softwareSkinningRenderId: Number;

        /**
         *  The Bias Vector to apply on the bounding elements (box/sphere), the max extend is computed as v += v * bias.x + bias.y, the min is computed as v -= v * bias.x + bias.y
         * @returns The Bias Vector
         */
        public function get boundingBias(): Vector2 {
            return this._boundingBias;
        }

        public function set boundingBias(value: Vector2): void {
            if (this._boundingBias && this._boundingBias.equals(value)) {
                return;
            }

            this._boundingBias = value.clone();

            this.updateBoundingInfo(true, null);
        }

        public function Geometry(id: String, scene: Scene, vertexData: VertexData = undefined, updatable: Boolean = false, mesh: Mesh = undefined) {
            this.id = id;
            this._engine = scene.getEngine();
            this._meshes = new <Mesh>[];
            this._scene = scene;
            //Init vertex buffer cache
            this._vertexBuffers = new Dictionary(true);
            this._indices = new <uint>[];

            // vertexData
            if (vertexData) {
                this.setAllVerticesData(vertexData, updatable);
            }
            else {
                this._totalVertices = 0;
                this._indices = new <uint>[];
            }

            // applyToMesh
            if (mesh) {
                this.applyToMesh(mesh);
                mesh.computeWorldMatrix(true);
            }
        }

        public function get extend(): Object { // { minimum: Vector3, maximum: Vector3 }
            return this._extend;
        }

        public function getScene(): Scene {
            return this._scene;
        }

        public function getEngine(): Engine {
            return this._engine;
        }

        public function isReady(): Boolean {
            return this.delayLoadState === Engine.DELAYLOADSTATE_LOADED || this.delayLoadState === Engine.DELAYLOADSTATE_NONE;
        }

        public function setAllVerticesData(vertexData: VertexData, updatable: Boolean = false): void {
            vertexData.applyToGeometry(this, updatable);
            this.notifyUpdate();
        }

        public function setVerticesData(kind: String, data: Vector.<Number>, updatable: Boolean = false, stride: Number = NaN): void {
            var buffer: VertexBuffer = new VertexBuffer(this._engine, data, kind, updatable, this._meshes.length === 0, stride);

            this.setVerticesBuffer(buffer);
        }

        public function setVerticesBuffer(buffer: VertexBuffer): void {
            var kind: String = buffer.getKind();
            if (this._vertexBuffers[kind]) {
                this._vertexBuffers[kind].dispose();
            }

            this._vertexBuffers[kind] = buffer;

            if (kind === VertexBuffer.PositionKind) {
                var data: Vector.<Number> = buffer.getData();
                var stride: Number = buffer.getStrideSize();

                this._totalVertices = data.length / stride;

                this.updateExtend(data, stride);

                var meshes: Vector.<Mesh> = this._meshes;
                var numOfMeshes: int = meshes.length;

                for (var index: int = 0; index < numOfMeshes; index++) {
                    var mesh: Mesh = meshes[index];
                    mesh._resetPointsArrayCache();
                    mesh._boundingInfo = new BoundingInfo(this._extend.minimum, this._extend.maximum);
                    mesh._createGlobalSubMesh();
                    mesh.computeWorldMatrix(true);
                }
            }

            this.notifyUpdate(kind);
        }

        public function updateVerticesDataDirectly(kind: String, data: Vector.<Number>, offset: Number): void {
            var vertexBuffer: VertexBuffer = this.getVertexBuffer(kind);

            if (!vertexBuffer) {
                return;
            }

            vertexBuffer.updateDirectly(data, offset);
            this.notifyUpdate(kind);
        }

        public function updateVerticesData(kind: String, data: Vector.<Number>, updateExtends: Boolean = false, makeItUnique: Boolean = false): void {
            var vertexBuffer: VertexBuffer = this.getVertexBuffer(kind);

            if (!vertexBuffer) {
                return;
            }

            vertexBuffer.update(data);

            if (kind === VertexBuffer.PositionKind) {

                var stride: int = vertexBuffer.getStrideSize();
                this._totalVertices = data.length / stride;

                this.updateBoundingInfo(updateExtends, data);
            }
            this.notifyUpdate(kind);
        }

        private function updateBoundingInfo(updateExtends: Boolean, data: Vector.<Number>): void {
            if (updateExtends) {
                this.updateExtend(data);
            }

            var meshes: Vector.<Mesh> = this._meshes;
            var numOfMeshes: int = meshes.length;

            for (var index: int = 0; index < numOfMeshes; index++) {
                var mesh: Mesh = meshes[index];
                mesh._resetPointsArrayCache();
                if (updateExtends) {
                    mesh._boundingInfo = new BoundingInfo(this._extend.minimum, this._extend.maximum);

                    for (var subIndex: int = 0; subIndex < mesh.subMeshes.length; subIndex++) {
                        var subMesh: SubMesh = mesh.subMeshes[subIndex];

                        subMesh.refreshBoundingInfo();
                    }
                }
            }
        }

        public function getTotalVertices(): Number {
            if (!this.isReady()) {
                return 0;
            }

            return this._totalVertices;
        }

        public function getVerticesData(kind: String, copyWhenShared: Boolean = false): Vector.<Number> {
            var vertexBuffer: VertexBuffer = this.getVertexBuffer(kind);
            if (!vertexBuffer) {
                return null;
            }
            var orig: Vector.<Number> = vertexBuffer.getData();
            if (!copyWhenShared || this._meshes.length === 1) {
                return orig;
            } else {
                var len: int = orig.length;
                var copy: Vector.<Number> = new <Number>[];
                for (var i: int = 0; i < len; i++) {
                    copy.push(orig[i]);
                }
                return copy;
            }
        }

        public function getVertexBuffer(kind: String): VertexBuffer {
            if (!this.isReady()) {
                return null;
            }
            return this._vertexBuffers[kind];
        }

        public function getVertexBuffers(): Dictionary { // { [key: String]: VertexBuffer; }
            if (!this.isReady()) {
                return null;
            }
            return this._vertexBuffers;
        }

        public function isVerticesDataPresent(kind: String): Boolean {
            if (!this._vertexBuffers) {
                if (this._delayInfo) {
                    return this._delayInfo.indexOf(kind) !== -1;
                }
                return false;
            }
            return this._vertexBuffers[kind] !== undefined;
        }

        public function getVerticesDataKinds(): Vector.<String> {
            var result: Vector.<String> = new <String>[];
            var kind: String;
            if (!this._vertexBuffers && this._delayInfo) {
                for (kind in this._delayInfo) {
                    result.push(kind);
                }
            } else {
                for (kind in this._vertexBuffers) {
                    result.push(kind);
                }
            }

            return result;
        }

        public function setIndices(indices: Vector.<uint>, totalVertices: int = 0): void {
            if (this._indexBuffer) {
                this._engine._releaseBuffer(this._indexBuffer);
            }

            this._indices = indices;
            if (this._meshes.length !== 0 && this._indices) {
                this._indexBuffer = this._engine.createIndexBuffer(this._indices);
            }

            if (totalVertices != 0) {
                this._totalVertices = totalVertices;
            }

            var meshes: Vector.<Mesh> = this._meshes;
            var numOfMeshes: int = meshes.length;

            for (var index: int = 0; index < numOfMeshes; index++) {
                meshes[index]._createGlobalSubMesh();
            }
            this.notifyUpdate();
        }

        public function getTotalIndices(): Number {
            if (!this.isReady()) {
                return 0;
            }
            return this._indices.length;
        }

        public function getIndices(copyWhenShared: Boolean = false): Vector.<uint> {
            if (!this.isReady()) {
                return null;
            }
            var orig: Vector.<uint> = this._indices;
            if (!copyWhenShared || this._meshes.length === 1) {
                return orig;
            } else {
                var len: int = orig.length;
                var copy: Vector.<uint> = new Vector.<uint>;
                for (var i: int = 0; i < len; i++) {
                    copy.push(orig[i]);
                }
                return copy;
            }
        }

        public function getIndexBuffer(): IndexBuffer3D {
            if (!this.isReady()) {
                return null;
            }
            return this._indexBuffer;
        }

        public function releaseForMesh(mesh: Mesh, shouldDispose: Boolean = false): void {
            var meshes: Vector.<Mesh> = this._meshes;
            var index: int = meshes.indexOf(mesh);

            if (index === -1) {
                return;
            }

            for (var kind: String in this._vertexBuffers) {
                this._vertexBuffers[kind].dispose();
            }

            if (this._indexBuffer && this._engine._releaseBuffer(this._indexBuffer)) {
                this._indexBuffer = null;
            }

            meshes.splice(index, 1);

            mesh._geometry = null;

            if (meshes.length === 0 && shouldDispose) {
                this.dispose();
            }
        }

        public function applyToMesh(mesh: Mesh): void {
            if (mesh._geometry === this) {
                return;
            }

            var previousGeometry: Geometry = mesh._geometry;
            if (previousGeometry) {
                previousGeometry.releaseForMesh(mesh);
            }

            // must be done before setting vertexBuffers because of mesh._createGlobalSubMesh()
            mesh._geometry = this;

            this._scene.pushGeometry(this);

            this._meshes.push(mesh);

            if (this.isReady()) {
                this._applyToMesh(mesh);
            }
            else {
                mesh._boundingInfo = this._boundingInfo;
            }
        }

        private function updateExtend(data: Vector.<Number> = null, stride: int = 0): void {
            if (!data) {
                data = VertexBuffer(this._vertexBuffers[VertexBuffer.PositionKind]).getData();
            }

            this._extend = Tools.ExtractMinAndMax(data, 0, this._totalVertices, this.boundingBias, stride);
        }

        private function _applyToMesh(mesh: Mesh): void {//364
            var numOfMeshes: int = this._meshes.length;

            // vertexBuffers
            for (var kind: String in this._vertexBuffers) {
                if (numOfMeshes === 1) {
                    this._vertexBuffers[kind].create();
                }

                if (kind === VertexBuffer.PositionKind) {
                    mesh._resetPointsArrayCache();

                    if (!this._extend) {
                        this.updateExtend(this._vertexBuffers[kind].getData());
                    }
                    mesh._boundingInfo = new BoundingInfo(this._extend.minimum, this._extend.maximum);

                    mesh._createGlobalSubMesh();

                    //bounding info was just created again, world matrix should be applied again.
                    mesh._updateBoundingInfo();
                }
            }

            // indexBuffer
            if (numOfMeshes === 1 && this._indices && this._indices.length > 0) {
                this._indexBuffer = this._engine.createIndexBuffer(this._indices);
            }
//            if (this._indexBuffer) {
//                this._indexBuffer.references = numOfMeshes;
//            }
        }

        private function notifyUpdate(kind: String = null): void {//398
            if (this.onGeometryUpdated) {
                this.onGeometryUpdated(this, kind);
            }
        }

        /**
         * Invert the geometry to move from a right handed system to a left handed one.
         */
        public function toLeftHanded(): void {//446

            // Flip faces
            var tIndices: Vector.<uint> = this.getIndices(false);
            if (tIndices != null && tIndices.length > 0) {
                for (var i: int = 0; i < tIndices.length; i += 3) {
                    var tTemp: uint = tIndices[i + 0];
                    tIndices[i + 0] = tIndices[i + 2];
                    tIndices[i + 2] = tTemp;
                }
                this.setIndices(tIndices);
            }

            // Negate position.z
            var tPositions: Vector.<Number> = this.getVerticesData(VertexBuffer.PositionKind, false);
            if (tPositions != null && tPositions.length > 0) {
                for (i = 0; i < tPositions.length; i += 3) {
                    tPositions[i + 2] = -tPositions[i + 2];
                }
                this.setVerticesData(VertexBuffer.PositionKind, tPositions, false);
            }

            // Negate normal.z
            var tNormals: Vector.<Number> = this.getVerticesData(VertexBuffer.NormalKind, false);
            if (tNormals != null && tNormals.length > 0) {
                for (i = 0; i < tNormals.length; i += 3) {
                    tNormals[i + 2] = -tNormals[i + 2];
                }
                this.setVerticesData(VertexBuffer.NormalKind, tNormals, false);
            }
        }

        public function isDisposed(): Boolean {
            return this._isDisposed;
        }

        public function dispose(): void {
            var meshes: Vector.<Mesh> = this._meshes;
            var numOfMeshes: int = meshes.length;
            var index: Number;
            for (index = 0; index < numOfMeshes; index++) {
                this.releaseForMesh(meshes[index]);
            }
            this._meshes = new <Mesh>[];

            for (var kind: String in this._vertexBuffers) {
                this._vertexBuffers[kind].dispose();
            }
            this._vertexBuffers = new Dictionary(true);
            this._totalVertices = 0;

            if (this._indexBuffer) {
                this._engine._releaseBuffer(this._indexBuffer);
            }
            this._indexBuffer = null;
            this._indices = new <uint>[];

            this.delayLoadState = Engine.DELAYLOADSTATE_NONE;
            this.delayLoadingFile = null;
            this._delayLoadingFunction = null;
            this._delayInfo = [];

            this._boundingInfo = null;

            this._scene.removeGeometry(this);
            this._isDisposed = true;
        }

        public function copy(id: String): Geometry {
            var vertexData: VertexData = new VertexData();

            vertexData.indices = new <uint>[];

            var indices: Vector.<uint> = this.getIndices();
            for (var index: int = 0; index < indices.length; index++) {
                vertexData.indices.push(indices[index]);
            }

            var updatable: Boolean = false;
            var stopChecking: Boolean = false;
            var kind: String;
            for (kind in this._vertexBuffers) {
                // using slice() to make a copy of the array and not just reference it
//                var data: Vector.<Number> = this.getVerticesData(kind);
//                if (data instanceof Vector.<Number>) {
//                vertexData.set(new Vector.<Number>(data), kind);
//                } else {
//                vertexData.set(data.slice(0), kind);
//                }
                if (!stopChecking) {
                    updatable = this.getVertexBuffer(kind).isUpdatable();
                    stopChecking = !updatable;
                }
            }

            var geometry: Geometry = new Geometry(id, this._scene, vertexData, updatable, null);

            geometry.delayLoadState = this.delayLoadState;
            geometry.delayLoadingFile = this.delayLoadingFile;
            geometry._delayLoadingFunction = this._delayLoadingFunction;

            for (kind in this._delayInfo) {
                geometry._delayInfo = geometry._delayInfo || [];
                geometry._delayInfo.push(kind);
            }

            // Bounding info
            geometry._boundingInfo = new BoundingInfo(this._extend.minimum, this._extend.maximum);

            return geometry;
        }

        // Statics
        public static function ExtractFromMesh(mesh: Mesh, id: String): Geometry {
            var geometry: Geometry = mesh._geometry;

            if (!geometry) {
                return null;
            }

            return geometry.copy(id);
        }

        /**
         * You should now use Tools.RandomId(), this method is still here for legacy reasons.
         * Implementation from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript/2117523#answer-2117523
         * Be aware Math.random() could cause collisions, but:
         * "All but 6 of the 128 bits of the ID are randomly generated, which means that for any two ids, there's a 1 in 2^^122 (or 5.3x10^^36) chance they'll collide"
         */
        public static function RandomId(): String {
            return Tools.RandomId();
        }

        public static function ImportGeometry(parsedGeometry: Object, mesh: Mesh): void {
            var scene: Scene = mesh.getScene();

            // Geometry
            var geometryId: String = parsedGeometry.geometryId;
            if (geometryId) {
                var geometry: Geometry = scene.getGeometryByID(geometryId);
                if (geometry) {
                    geometry.applyToMesh(mesh);
                }
            } else if (parsedGeometry.positions && parsedGeometry.normals && parsedGeometry.indices) {
                mesh.setVerticesData(VertexBuffer.PositionKind, Vector.<Number>(parsedGeometry.positions), false);
                mesh.setVerticesData(VertexBuffer.NormalKind, Vector.<Number>(parsedGeometry.normals), false);

                if (parsedGeometry.uvs) {
                    mesh.setVerticesData(VertexBuffer.UVKind, Vector.<Number>(parsedGeometry.uvs), false);
                }

                if (parsedGeometry.colors) {
                    mesh.setVerticesData(VertexBuffer.ColorKind, Color4.CheckColors4(parsedGeometry.colors, parsedGeometry.positions.length / 3), false);
                }

                if (parsedGeometry.matricesIndices) {
                    if (!parsedGeometry.matricesIndices._isExpanded) {
                        var floatIndices: Vector.<Number> = new <Number>[];

                        for (var i: int = 0; i < parsedGeometry.matricesIndices.length; i++) {
                            var matricesIndex: Number = parsedGeometry.matricesIndices[i];

                            floatIndices.push(matricesIndex & 0x000000FF);
                            floatIndices.push((matricesIndex & 0x0000FF00) >> 8);
                            floatIndices.push((matricesIndex & 0x00FF0000) >> 16);
                            floatIndices.push(matricesIndex >> 24);
                        }
                        mesh.setVerticesData(VertexBuffer.MatricesIndicesKind, floatIndices, false);
                    } else {
                        delete parsedGeometry.matricesIndices._isExpanded;
                        mesh.setVerticesData(VertexBuffer.MatricesIndicesKind, parsedGeometry.matricesIndices, false);
                    }
                }

                if (parsedGeometry.matricesWeights) {
                    mesh.setVerticesData(VertexBuffer.MatricesWeightsKind, Vector.<Number>(parsedGeometry.matricesWeights), false);
                }

                mesh.setIndices(Vector.<uint>(parsedGeometry.indices));
            }

            // SubMeshes
            if (parsedGeometry.subMeshes) {
                mesh.subMeshes = new <SubMesh>[];
                for (var subIndex: int = 0; subIndex < parsedGeometry.subMeshes.length; subIndex++) {
                    var parsedSubMesh: Object = parsedGeometry.subMeshes[subIndex];

                    var subMesh: SubMesh = new SubMesh(parsedSubMesh.materialIndex, parsedSubMesh.verticesStart, parsedSubMesh.verticesCount, parsedSubMesh.indexStart, parsedSubMesh.indexCount, mesh);
                }
            }

            // Flat shading

            // Update
            mesh.computeWorldMatrix(true);

            // Octree
        }

        public static function Parse(parsedVertexData: Object, scene: Scene, rootUrl: String): Geometry {
            if (scene.getGeometryByID(parsedVertexData.id)) {
                return null; // null since geometry could be something else than a box...
            }

            var geometry: Geometry = new Geometry(parsedVertexData.id, scene);

//            Tags.AddTagsTo(geometry, parsedVertexData.tags);

            if (parsedVertexData.delayLoadingFile) {
                fail();

                geometry.delayLoadState = Engine.DELAYLOADSTATE_NOTLOADED;
                geometry.delayLoadingFile = rootUrl + parsedVertexData.delayLoadingFile;
                geometry._boundingInfo = new BoundingInfo(Vector3.FromArray(parsedVertexData.boundingBoxMinimum), Vector3.FromArray(parsedVertexData.boundingBoxMaximum));

                geometry._delayInfo = [];

                geometry._delayLoadingFunction = VertexData.ImportVertexData;
            } else {
                VertexData.ImportVertexData(parsedVertexData, geometry);
            }

            scene.pushGeometry(geometry, true);

            return geometry;
        }
    }
}
