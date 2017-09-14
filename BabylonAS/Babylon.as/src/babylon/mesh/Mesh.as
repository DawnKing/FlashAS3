/**
 * Created by caijingxiao on 2016/10/17.
 */
package babylon.mesh {

    import babylon.Engine;
    import babylon.Scene;
    import babylon.animations.Animation;
    import babylon.culling.BoundingBox;
    import babylon.culling.BoundingInfo;
    import babylon.materials.Effect;
    import babylon.materials.Material;
    import babylon.materials.MultiMaterial;
    import babylon.math.Matrix;
    import babylon.math.Quaternion;
    import babylon.math.Vector3;
    import babylon.tools.Tools;

    import easiest.unit.asserts.fail;

    import flash.display3D.IndexBuffer3D;

    public class Mesh extends AbstractMesh implements IGetSetVerticesData {
        // Consts
        public static const FRONTSIDE: int = 0;
        public static const BACKSIDE: int = 1;
        public static const DOUBLESIDE: int = 2;
        public static const DEFAULTSIDE: int = 0;
        public static const NO_CAP: int = 0;
        public static const CAP_START: int = 1;
        public static const CAP_END: int = 2;
        public static const CAP_ALL: int = 3;

        // Members

        // Private
        public var _geometry: Geometry;
        public var _delayInfo: Object;

        private var _visibleInstances: Object = {};

        private var _batchCache: _InstanceBatch = new _InstanceBatch();

        private var _renderIdForInstances: Vector.<Number> = new <Number>[];

        private var _sideOrientation: int = DEFAULTSIDE;
        private var _areNormalsFrozen: Boolean = false; // Will be used by ribbons mainly

        public function Mesh(name: String, scene: Scene) {
            super(name, scene);
        }

        override public function toString(fullDetails: Boolean = false): String {
            var ret: String = super.toString(fullDetails);
            ret += ", n vertices: " + this.getTotalVertices();
            ret += ", parent: " + (this._waitingParentId ? this._waitingParentId : (this.parent ? this.parent.name : "NONE"));

            return ret;
        }

        public function get geometry(): Geometry {//334
            return this._geometry;
        }

        override public function getVerticesData(kind: String, copyWhenShared: Boolean = false): Vector.<Number> {//366
            if (!this._geometry) {
                return null;
            }
            return this._geometry.getVerticesData(kind, copyWhenShared);
        }

        override public function getTotalVertices(): int {//341
            if (!this._geometry) {
                return 0;
            }
            return this._geometry.getTotalVertices();
        }

        override public function isVerticesDataPresent(kind: String): Boolean {//413
            if (!this._geometry) {
                if (this._delayInfo) {
                    return this._delayInfo.indexOf(kind) != -1;
                }
                return false;
            }
            return this._geometry.isVerticesDataPresent(kind);
        }

        public function getTotalIndices(): int {
            if (!this._geometry) {
                return 0;
            }
            return this._geometry.getTotalIndices();
        }

        override public function getIndices(copyWhenShared: Boolean = false): Vector.<uint> {//467
            if (!this._geometry) {
                return null;
            }
            return this._geometry.getIndices(copyWhenShared);
        }

        public function get sideOrientation(): int {
            return this._sideOrientation;
        }

        /**
         * Sets the mesh side orientation : BABYLON.Mesh.FRONTSIDE, BABYLON.Mesh.BACKSIDE, BABYLON.Mesh.DOUBLESIDE or BABYLON.Mesh.DEFAULTSIDE
         * tuto : http://doc.babylonjs.com/tutorials/Discover_Basic_Elements#side-orientation
         */
        public function set sideOrientation(sideO: int): void {
            this._sideOrientation = sideO;
        }

        /**
         * Boolean : true if the normals aren't to be recomputed on next mesh `positions` array update.
         * This property is pertinent only for updatable parametric shapes.
         */
        public function get areNormalsFrozen(): Boolean {//516
            return this._areNormalsFrozen;
        }

        /**
         * This function affects parametric shapes on vertex position update only : ribbons, tubes, etc.
         * It has no effect at all on other shapes.
         * It prevents the mesh normals from being recomputed on next `positions` array update.
         */
        public function freezeNormals(): void {//525
            this._areNormalsFrozen = true;
        }

        /**
         * This method recomputes and sets a new BoundingInfo to the mesh unless it is locked.
         * This means the mesh underlying bounding box and sphere are recomputed.
         */
        public function refreshBoundingInfo(): void {
            if (this._boundingInfo.isLocked) {
                return;
            }
            var data: Vector.<Number> = this.getVerticesData(VertexBuffer.PositionKind);

            if (data) {
                var extend: Object = Tools.ExtractMinAndMax(data, 0, this.getTotalVertices());
                this._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);
            }

            if (this.subMeshes) {
                for (var index: int = 0; index < this.subMeshes.length; index++) {
                    this.subMeshes[index].refreshBoundingInfo();
                }
            }

            this._updateBoundingInfo();
        }

        public function _createGlobalSubMesh(): SubMesh {//597
            var totalVertices: int = this.getTotalVertices();
            if (totalVertices == 0 || !this.getIndices()) {
                return null;
            }
            this.releaseSubMeshes();
            return new SubMesh(0, 0, totalVertices, 0, this.getTotalIndices(), this);
        }

        public function setVerticesData(kind: String, data: Vector.<Number>, updatable: Boolean = false, stride: Number = NaN): void {//658
            if (!this._geometry) {
                var vertexData: VertexData = new VertexData();
                vertexData.set(data, kind);

                var scene: Scene = this.getScene();

                new Geometry(Geometry.RandomId(), scene, vertexData, updatable, this);
            } else {
                this._geometry.setVerticesData(kind, data, updatable, stride);
            }
        }

        public function updateVerticesData(kind: String, data: Vector.<Number>, updateExtends: Boolean = false, makeItUnique: Boolean = false): void {//704
            if (!this._geometry) {
                return;
            }
            if (!makeItUnique) {
                this._geometry.updateVerticesData(kind, data, updateExtends);
            } else {
                this.makeGeometryUnique();
                this.updateVerticesData(kind, data, updateExtends, false);
            }
        }

        private function makeGeometryUnique(): void {
            if (!this._geometry) {
                return;
            }
            var oldGeometry: Geometry = this._geometry;

            var geometry: Geometry = this._geometry.copy(Geometry.RandomId());

            oldGeometry.releaseForMesh(this, true);
            geometry.applyToMesh(this);
        }

        public function setIndices(indices: Vector.<uint>, totalVertices: int = 0): void {//772
            if (!this._geometry) {
                var vertexData: VertexData = new VertexData();
                vertexData.indices = indices;

                var scene: Scene = this.getScene();

                new Geometry(Geometry.RandomId(), scene, vertexData, false, this);
            } else {
                this._geometry.setIndices(indices, totalVertices);
            }
        }

        public function _bind(subMesh: SubMesh, effect: Effect, fillMode: int): void {//797
            var engine: Engine = this.getScene().getEngine();

            // Wireframe
            var indexToBind: IndexBuffer3D;

            switch (fillMode) {
                case Material.PointFillMode:
                    indexToBind = null;
                    break;
                case Material.WireFrameFillMode:
                    indexToBind = subMesh.getLinesIndexBuffer(this.getIndices(), engine);
                    break;
                default:
                case Material.TriangleFillMode:
                    indexToBind = this._geometry.getIndexBuffer();
                    break;
            }

            // VBOs
            engine.bindBuffers(this._geometry.getVertexBuffers(), indexToBind, effect);
        }

        private function _draw(subMesh: SubMesh, fillMode: int): void {//824
            if (!this._geometry || !this._geometry.getVertexBuffers() || !this._geometry.getIndexBuffer()) {
                return;
            }

            var engine: Engine = this.getScene().getEngine();

            // Draw order
            switch (fillMode) {
                case Material.PointFillMode:
                    break;
                case Material.WireFrameFillMode:
                    break;

                default:
                    engine.draw(this._geometry.getIndexBuffer(), subMesh.indexStart, subMesh.indexCount / 3);
            }
        }

        public function _getInstancesRenderList(subMeshId: int): _InstanceBatch {//887
            var scene: Scene = this.getScene();
            this._batchCache.mustReturn = false;
            this._batchCache.renderSelf[subMeshId] = this.isEnabled() && this.isVisible;
            this._batchCache.visibleInstances[subMeshId] = null;

            if (this._visibleInstances) {
                var currentRenderId:int = scene.getRenderId();
                var defaultRenderId:int = (scene._isInIntermediateRendering() ? this._visibleInstances.intermediateDefaultRenderId : this._visibleInstances.defaultRenderId);
                this._batchCache.visibleInstances[subMeshId] = this._visibleInstances[currentRenderId];
                var selfRenderId:int = this._renderId;

                if (!this._batchCache.visibleInstances[subMeshId] && defaultRenderId) {
                    this._batchCache.visibleInstances[subMeshId] = this._visibleInstances[defaultRenderId];
                    currentRenderId = Math.max(defaultRenderId, currentRenderId);
                    selfRenderId = Math.max(this._visibleInstances.selfDefaultRenderId, currentRenderId);
                }

                if (this._batchCache.visibleInstances[subMeshId] && this._batchCache.visibleInstances[subMeshId].length) {
                    if (this._renderIdForInstances[subMeshId] === currentRenderId) {
                        this._batchCache.mustReturn = true;
                        return this._batchCache;
                    }

                    if (currentRenderId !== selfRenderId) {
                        this._batchCache.renderSelf[subMeshId] = false;
                    }

                }
                this._renderIdForInstances[subMeshId] = currentRenderId;
            }

            return this._batchCache;
        }

        public function _processRendering(subMesh: SubMesh, fillMode: int, batch: _InstanceBatch, onBeforeDraw: Function, effectiveMaterial: Material = null): void {//979
            if (batch.renderSelf[subMesh._id]) {
                // Draw
                if (onBeforeDraw) {
                    if (onBeforeDraw.length == 2)
                        onBeforeDraw(false, this.getWorldMatrix());
                    else
                        onBeforeDraw(false, this.getWorldMatrix(), effectiveMaterial);
                }

                this._draw(subMesh, fillMode);
            }

            if (batch.visibleInstances[subMesh._id]) {
                for (var instanceIndex: int = 0; instanceIndex < batch.visibleInstances[subMesh._id].length; instanceIndex++) {
                    var instance: Mesh = batch.visibleInstances[subMesh._id][instanceIndex];

                    // World
                    var world: Matrix = instance.getWorldMatrix();
                    if (onBeforeDraw) {
                        onBeforeDraw(true, world, effectiveMaterial);
                    }

                    // Draw
                    this._draw(subMesh, fillMode);
                }
            }
        }

        /**
         * Triggers the draw call for the mesh.
         * Usually, you don't need to call this method by your own because the mesh rendering is handled by the scene rendering manager.
         */
        public function render(subMesh: SubMesh, enableAlphaMode: Boolean): void {//1017
            var scene: Scene = this.getScene();

            // Managing instances
            var batch: _InstanceBatch = this._getInstancesRenderList(subMesh._id);

            if (batch.mustReturn) {
                return;
            }

            // Checking geometry state
            if (!this._geometry || !this._geometry.getVertexBuffers() || !this._geometry.getIndexBuffer()) {
                return;
            }

            var engine: Engine = scene.getEngine();
            var hardwareInstanceRendering:Boolean = (batch.visibleInstances[subMesh._id] !== null) && (batch.visibleInstances[subMesh._id] !== null);

            // Material
            var effectiveMaterial: Material = subMesh.getMaterial();
            if (!effectiveMaterial || !effectiveMaterial.isReady(this, hardwareInstanceRendering)) {
                return;
            }

            effectiveMaterial._preBind();
            var effect: Effect = effectiveMaterial.getEffect();

            // Outline - step 1

            // Bind
            var fillMode: int = scene.forcePointsCloud ? Material.PointFillMode : (scene.forceWireframe ? Material.WireFrameFillMode : effectiveMaterial.fillMode);
            this._bind(subMesh, effect, fillMode);

            var world: Matrix = this.getWorldMatrix();

            effectiveMaterial.bind(world, this);

            // Alpha mode
            if (enableAlphaMode) {
                engine.setAlphaMode(effectiveMaterial.alphaMode);
            }

            // Draw
            this._processRendering(subMesh, fillMode, batch, this._onBeforeDraw);

            // Unbind
            effectiveMaterial.unbind();

            // Outline - step 2

            // Overlay
        }

        public function _onBeforeDraw(isInstance: Boolean, world: Matrix, effectiveMaterial: Material): void {//1094
            if (isInstance) {
                effectiveMaterial.bindOnlyWorldMatrix(world);
            }
        }

        public function setMaterialByID(id: String): void {//1187
            var materials: Vector.<Material> = this.getScene().materials;
            var index: int;
            for (index = 0; index < materials.length; index++) {
                if (materials[index].id === id) {
                    this.material = materials[index];
                    return;
                }
            }

            // Multi
            var multiMaterials: Vector.<MultiMaterial> = this.getScene().multiMaterials;
            for (index = 0; index < multiMaterials.length; index++) {
                if (multiMaterials[index].id === id) {
                    this.material = multiMaterials[index];
                    return;
                }
            }
        }

        public function getAnimatables(): Array {//1210
            var results: Array = [];

            if (this.material) {
                results.push(this.material);
            }

            if (this.skeleton) {
                results.push(this.skeleton);
            }

            return results;
        }

        public function _resetPointsArrayCache(): void {//1289
            this._positions = null;
        }

        override public function dispose(doNotRecurse: Boolean = false): void {
            if (this._geometry) {
                this._geometry.releaseForMesh(this, true);
            }

            // Instances
//            if (this._instancesBuffer) {
//                this._instancesBuffer.dispose();
//                this._instancesBuffer = null;
//            }
//
//            while (this.instances.length) {
//                this.instances[0].dispose();
//            }
//
//            // Highlight layers.
//            var highlightLayers = this.getScene().highlightLayers;
//            for (var i: int = 0; i < highlightLayers.length; i++) {
//                var highlightLayer = highlightLayers[i];
//                if (highlightLayer) {
//                    highlightLayer.removeMesh(this);
//                    highlightLayer.removeExcludedMesh(this);
//                }
//            }

            super.dispose(doNotRecurse);
        }

        // Statics
        public static function Parse(parsedMesh: Object, scene: Scene): Mesh {//1735
            var mesh: Mesh = new Mesh(parsedMesh.name, scene);
            mesh.id = parsedMesh.id;

            mesh.position = Vector3.FromArray(parsedMesh.position);

            if (parsedMesh.rotationQuaternion) {
                mesh.rotationQuaternion = Quaternion.FromArray(parsedMesh.rotationQuaternion);
            } else if (parsedMesh.rotation) {
                mesh.rotation = Vector3.FromArray(parsedMesh.rotation);
            }

            mesh.scaling = Vector3.FromArray(parsedMesh.scaling);

//            if (parsedMesh.hasOwnProperty("localMatrix")) {
//                mesh.setPivotMatrix(Matrix.FromArray(parsedMesh.localMatrix));
//            } else if (parsedMesh.hasOwnProperty("pivotMatrix")) {
//                mesh.setPivotMatrix(Matrix.FromArray(parsedMesh.pivotMatrix));
//            }

            mesh.setEnabled(parsedMesh.isEnabled);
            mesh.isVisible = parsedMesh.isVisible;
            mesh.infiniteDistance = parsedMesh.infiniteDistance;

            mesh.showBoundingBox = parsedMesh.showBoundingBox;
            mesh.showSubMeshesBoundingBox = parsedMesh.showSubMeshesBoundingBox;

            if (parsedMesh.applyFog !== undefined) {
                mesh.applyFog = parsedMesh.applyFog;
            }

            if (parsedMesh.pickable !== undefined) {
                mesh.isPickable = parsedMesh.pickable;
            }

            if (parsedMesh.alphaIndex !== undefined) {
                mesh.alphaIndex = parsedMesh.alphaIndex;
            }

            mesh.receiveShadows = parsedMesh.receiveShadows;

            mesh.billboardMode = parsedMesh.billboardMode;

            if (parsedMesh.visibility !== undefined) {
                mesh.visibility = parsedMesh.visibility;
            }

            // freezeWorldMatrix

            // Parent
            if (parsedMesh.parentId) {
                mesh._waitingParentId = parsedMesh.parentId;
            }

            // Actions

            // Geometry
            mesh.hasVertexAlpha = parsedMesh.hasVertexAlpha;

            if (parsedMesh.delayLoadingFile) {
                fail();
            } else {
                Geometry.ImportGeometry(parsedMesh, mesh);
            }

            // Material
            if (parsedMesh.materialId) {
                mesh.setMaterialByID(parsedMesh.materialId);
            } else {
                mesh.material = null;
            }

            // Skeleton
            if (parsedMesh.skeletonId > -1) {
                mesh.skeleton = scene.getLastSkeletonByID(parsedMesh.skeletonId);
                if (parsedMesh.numBoneInfluencers) {
                    mesh.numBoneInfluencers = parsedMesh.numBoneInfluencers;
                }
            }

            // Animations
            if (parsedMesh.animations) {
                for (var animationIndex: int = 0; animationIndex < parsedMesh.animations.length; animationIndex++) {
                    var parsedAnimation: Object = parsedMesh.animations[animationIndex];

                    mesh.animations.push(Animation.Parse(parsedAnimation));
                }
                ParseAnimationRanges(mesh, parsedMesh, scene);
            }

            if (parsedMesh.autoAnimate) {
                scene.beginAnimation(mesh, parsedMesh.autoAnimateFrom, parsedMesh.autoAnimateTo, parsedMesh.autoAnimateLoop, parsedMesh.autoAnimateSpeed || 1.0);
            }

            // Layer Mask

            // Instances

            return mesh;
        }

        public static function CreateBox(name: String, size: int, scene: Scene, updatable: Boolean = false, sideOrientation: int = 0): Mesh {//200
            var options: Object = {
                size: size,
                sideOrientation: sideOrientation,
                updatable: updatable
            };

            return MeshBuilder.CreateBox(name, options, scene);
        }

        /**
         * Creates a sphere mesh.
         * Please consider using the same method from the MeshBuilder class instead.
         * The parameter `diameter` sets the diameter size (float) of the sphere (default 1).
         * The parameter `segments` sets the sphere number of horizontal stripes (positive integer, default 32).
         * You can also set the mesh side orientation with the values : BABYLON.Mesh.FRONTSIDE (default), BABYLON.Mesh.BACKSIDE or BABYLON.Mesh.DOUBLESIDE
         * Detail here : http://doc.babylonjs.com/tutorials/02._Discover_Basic_Elements#side-orientation
         * The mesh can be set to updatable with the boolean parameter `updatable` (default false) if its internal geometry is supposed to change once created.
         */
        public static function CreateSphere(name: String, segments: Number, diameter: int, scene: Scene = null, updatable: Boolean = false, sideOrientation: int = 0): Mesh {
            var options: Object = {
                segments: segments,
                diameterX: diameter,
                diameterY: diameter,
                diameterZ: diameter,
                sideOrientation: sideOrientation,
                updatable: updatable
            };

            return MeshBuilder.CreateSphere(name, options, scene);
        }

        /**
         * Creates a plane mesh.
         * Please consider using the same method from the MeshBuilder class instead.
         * The parameter `size` sets the size (float) of both sides of the plane at once (default 1).
         * You can also set the mesh side orientation with the values : BABYLON.Mesh.FRONTSIDE (default), BABYLON.Mesh.BACKSIDE or BABYLON.Mesh.DOUBLESIDE
         * Detail here : http://doc.babylonjs.com/tutorials/02._Discover_Basic_Elements#side-orientation
         * The mesh can be set to updatable with the boolean parameter `updatable` (default false) if its internal geometry is supposed to change once created.
         */
        public static function CreatePlane(name: String, size: Number, scene: Scene, updatable: Boolean  =false, sideOrientation: int = 0): Mesh {//2280
            var options: Object = {
                size: size,
                width: size,
                height: size,
                sideOrientation: sideOrientation,
                updatable: updatable
            };

            return MeshBuilder.CreatePlane(name, options, scene);
        }
        /**
         * Creates a ground mesh.
         * Please consider using the same method from the MeshBuilder class instead.
         * The parameters `width` and `height` (floats, default 1) set the width and height sizes of the ground.
         * The parameter `subdivisions` (positive integer) sets the number of subdivisions per side.
         * The mesh can be set to updatable with the boolean parameter `updatable` (default false) if its internal geometry is supposed to change once created.
         */
        public static function CreateGround(name: String, width: Number, height: Number, subdivisions: Number, scene: Scene, updatable: Boolean = false): Mesh {
            var options: Object = {
                width: width,
                height: height,
                subdivisions: subdivisions,
                updatable: updatable
            };

            return MeshBuilder.CreateGround(name, options, scene);
        }
        // Tools
        /**
         * Returns an object `{min:` Vector3`, max:` Vector3`}`
         * This min and max Vector3 are the minimum and maximum vectors of each mesh bounding box from the passed array, in the World system
         */
        public static function MinMax(meshes: Vector.<AbstractMesh>): Object {//2592
            var minVector: Vector3 = null;
            var maxVector: Vector3 = null;
            meshes.forEach(function (mesh: AbstractMesh, index: int, array: Vector.<AbstractMesh>): void {
                var boundingBox: BoundingBox = mesh.getBoundingInfo().boundingBox;
                if (!minVector) {
                    minVector = boundingBox.minimumWorld;
                    maxVector = boundingBox.maximumWorld;
                } else {
                    minVector.MinimizeInPlace(boundingBox.minimumWorld);
                    maxVector.MaximizeInPlace(boundingBox.maximumWorld);
                }
            });

            return {
                min: minVector,
                max: maxVector
            };
        }

        /**
         * Returns a Vector3, the center of the `{min:` Vector3`, max:` Vector3`}` or the center of MinMax vector3 computed from a mesh array.
         */
        public static function Center(meshesOrMinMaxVector: Object): Vector3 {
            var minMaxVector: Object = (meshesOrMinMaxVector is Vector) ? MinMax(Vector.<AbstractMesh>(meshesOrMinMaxVector)) : meshesOrMinMaxVector;
            return Vector3.Center(minMaxVector.min, minMaxVector.max);
        }
    }
}
