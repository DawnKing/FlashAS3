/**
 * Created by caijingxiao on 2016/10/18.
 */
package babylon.rendering {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.materials.Material;
    import babylon.math.Vector3;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.SubMesh;

    public class RenderingGroup {
        private var _scene: Scene;
        private var _opaqueSubMeshes: Vector.<SubMesh> = new <SubMesh>[];
        private var _transparentSubMeshes: Vector.<SubMesh> = new <SubMesh>[];
        private var _alphaTestSubMeshes: Vector.<SubMesh> = new <SubMesh>[];

        private var _opaqueSortCompareFn: Function;
        private var _alphaTestSortCompareFn: Function;
        private var _transparentSortCompareFn: Function;

        private var _renderOpaque: Function;
        private var _renderAlphaTest: Function;
        private var _renderTransparent: Function;

        public var onBeforeTransparentRendering: Function;

        public var index: int;

        /**
         * Set the opaque sort comparison function.
         * If null the sub meshes will be render in the order they were created
         */
        public function set opaqueSortCompareFn(value: Function): void {
            this._opaqueSortCompareFn = value;
            if (value) {
                this._renderOpaque = this.renderOpaqueSorted;
            }
            else {
                this._renderOpaque = RenderingGroup.renderUnsorted;
            }
        }

        /**
         * Set the alpha test sort comparison function.
         * If null the sub meshes will be render in the order they were created
         */
        public function set alphaTestSortCompareFn(value: Function): void {
            this._alphaTestSortCompareFn = value;
            if (value) {
                this._renderAlphaTest = this.renderAlphaTestSorted;
            }
            else {
                this._renderAlphaTest = RenderingGroup.renderUnsorted;
            }
        }

        /**
         * Set the transparent sort comparison function.
         * If null the sub meshes will be render in the order they were created
         */
        public function set transparentSortCompareFn(value: Function): void {
            if (value) {
                this._transparentSortCompareFn = value;
            }
            else {
                this._transparentSortCompareFn = RenderingGroup.defaultTransparentSortCompare;
            }
            this._renderTransparent = this.renderTransparentSorted;
        }

        /**
         * Creates a new rendering group.
         * @param index The rendering group index
         * @param scene the scene
         * @param opaqueSortCompareFn The opaque sort comparison function. If null no order is applied
         * @param alphaTestSortCompareFn The alpha test sort comparison function. If null no order is applied
         * @param transparentSortCompareFn The transparent sort comparison function. If null back to front + alpha index sort is applied
         */
        public function RenderingGroup(index: Number, scene: Scene,
                                       opaqueSortCompareFn: Function = null,
                                       alphaTestSortCompareFn: Function = null,
                                       transparentSortCompareFn: Function = null) {
            this.index = index;
            this._scene = scene;

            this.opaqueSortCompareFn = opaqueSortCompareFn;
            this.alphaTestSortCompareFn = alphaTestSortCompareFn;
            this.transparentSortCompareFn = transparentSortCompareFn;
        }

        /**
         * Render all the sub meshes contained in the group.
         * @param customRenderFunction Used to override the default render behaviour of the group.
         * @returns true if rendered some submeshes.
         */
        public function render(customRenderFunction: Function): void {
            if (customRenderFunction) {
                customRenderFunction(this._opaqueSubMeshes, this._alphaTestSubMeshes, this._transparentSubMeshes);
                return;
            }

            var engine: Engine = this._scene.getEngine();

            // Opaque
            if (this._opaqueSubMeshes.length !== 0) {
                this._renderOpaque(this._opaqueSubMeshes);
            }

            // Alpha test
            if (this._alphaTestSubMeshes.length !== 0) {
                engine.setAlphaTesting(true);
                this._renderAlphaTest(this._alphaTestSubMeshes);
                engine.setAlphaTesting(false);
            }

            if (this.onBeforeTransparentRendering) {
                this.onBeforeTransparentRendering();
            }

            // Transparent
            if (this._transparentSubMeshes.length !== 0) {
                this._renderTransparent(this._transparentSubMeshes);
                engine.setAlphaMode(Engine.ALPHA_DISABLE);
            }
        }

        /**
         * Renders the opaque submeshes in the order from the opaqueSortCompareFn.
         * @param subMeshes The submeshes to render
         */
        private function renderOpaqueSorted(subMeshes: Vector.<SubMesh>): void {
            return renderSorted(subMeshes, this._opaqueSortCompareFn, this._scene.activeCamera.globalPosition, false);
        }

        /**
         * Renders the opaque submeshes in the order from the alphatestSortCompareFn.
         * @param subMeshes The submeshes to render
         */
        private function renderAlphaTestSorted(subMeshes: Vector.<SubMesh>): void {
            return renderSorted(subMeshes, this._alphaTestSortCompareFn, this._scene.activeCamera.globalPosition, false);
        }

        /**
         * Renders the opaque submeshes in the order from the transparentSortCompareFn.
         * @param subMeshes The submeshes to render
         */
        private function renderTransparentSorted(subMeshes: Vector.<SubMesh>): void {
            return renderSorted(subMeshes, this._transparentSortCompareFn, this._scene.activeCamera.globalPosition, true);
        }

        /**
         * Renders the submeshes in a specified order.
         * @param subMeshes The submeshes to sort before render
         * @param sortCompareFn The comparison function use to sort
         * @param cameraPosition The camera position use to preprocess the submeshes to help sorting
         * @param transparent Specifies to activate blending if true
         */
        private static function renderSorted(subMeshes: Vector.<SubMesh>, sortCompareFn: Function, cameraPosition: Vector3, transparent: Boolean): void {
            var subIndex: int = 0;
            var subMesh: SubMesh;
            for (; subIndex < subMeshes.length; subIndex++) {
                subMesh = subMeshes[subIndex];
                subMesh._alphaIndex = subMesh.getMesh().alphaIndex;
                subMesh._distanceToCamera = subMesh.getBoundingInfo().boundingSphere.centerWorld.subtract(cameraPosition).length();
            }

            var sortedArray: Vector.<SubMesh> = subMeshes.slice(0, subMeshes.length);
            sortedArray.sort(sortCompareFn);

            for (subIndex = 0; subIndex < sortedArray.length; subIndex++) {
                subMesh = sortedArray[subIndex];
                subMesh.render(transparent);
            }
        }

        /**
         * Renders the submeshes in the order they were dispatched (no sort applied).
         * @param subMeshes The submeshes to render
         */
        private static function renderUnsorted(subMeshes: Vector.<SubMesh>): void {
            for (var subIndex: int = 0; subIndex < subMeshes.length; subIndex++) {
                var subMesh: SubMesh = subMeshes[subIndex];
                subMesh.render(false);
            }
        }

        /**
         * Build in function which can be applied to ensure meshes of a special queue (opaque, alpha test, transparent)
         * are rendered back to front if in the same alpha index.
         *
         * @param a The first submesh
         * @param b The second submesh
         * @returns The result of the comparison
         */
        public static function defaultTransparentSortCompare(a: SubMesh, b:SubMesh) : Number {
            // Alpha index first
            if (a._alphaIndex > b._alphaIndex) {
                return 1;
            }
            if (a._alphaIndex < b._alphaIndex) {
                return -1;
            }

            // Then distance to camera
            return RenderingGroup.backToFrontSortCompare(a, b);
        }

        /**
         * Build in function which can be applied to ensure meshes of a special queue (opaque, alpha test, transparent)
         * are rendered back to front.
         *
         * @param a The first submesh
         * @param b The second submesh
         * @returns The result of the comparison
         */
        public static function backToFrontSortCompare(a: SubMesh, b:SubMesh) : Number {
            // Then distance to camera
            if (a._distanceToCamera < b._distanceToCamera) {
                return 1;
            }
            if (a._distanceToCamera > b._distanceToCamera) {
                return -1;
            }

            return 0;
        }

        /**
         * Build in function which can be applied to ensure meshes of a special queue (opaque, alpha test, transparent)
         * are rendered front to back (prevent overdraw).
         *
         * @param a The first submesh
         * @param b The second submesh
         * @returns The result of the comparison
         */
        public static function frontToBackSortCompare(a: SubMesh, b:SubMesh) : Number {
            // Then distance to camera
            if (a._distanceToCamera < b._distanceToCamera) {
                return -1;
            }
            if (a._distanceToCamera > b._distanceToCamera) {
                return 1;
            }

            return 0;
        }

        /**
         * Resets the different lists of submeshes to prepare a new frame.
         */
        public function prepare(): void {
            this._opaqueSubMeshes.length = 0;
            this._transparentSubMeshes.length = 0;
            this._alphaTestSubMeshes.length = 0;
        }

        /**
         * Inserts the submesh in its correct queue depending on its material.
         * @param subMesh The submesh to dispatch
         */
        public function dispatch(subMesh: SubMesh): void {
            var material:Material = subMesh.getMaterial();
            var mesh: AbstractMesh = subMesh.getMesh();

            if (material.needAlphaBlending() || mesh.visibility < 1.0 || mesh.hasVertexAlpha) { // Transparent
                this._transparentSubMeshes.push(subMesh);
            } else if (material.needAlphaTesting()) { // Alpha test
                this._alphaTestSubMeshes.push(subMesh);
            } else {
                this._opaqueSubMeshes.push(subMesh); // Opaque
            }
        }
    }
}
