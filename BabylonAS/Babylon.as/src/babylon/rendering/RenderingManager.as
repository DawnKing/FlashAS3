/**
 * Created by caijingxiao on 2016/10/18.
 */
package babylon.rendering {
    import babylon.Scene;
    import babylon.cameras.Camera;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.SubMesh;
    import babylon.particles.ParticleSystem;

    import flash.utils.Dictionary;

    public class RenderingManager {
        /**
         * The max id used for rendering groups (not included)
         */
        public static const MAX_RENDERINGGROUPS: int = 4;

        /**
         * The min id used for rendering groups (included)
         */
        public static const MIN_RENDERINGGROUPS: int = 0;

        private var _scene: Scene;
        private var _renderingGroups: Vector.<RenderingGroup> = new Vector.<RenderingGroup>(MAX_RENDERINGGROUPS, true);
        private var _depthStencilBufferAlreadyCleaned: Boolean;

        private var _currentIndex: int;
        private var _currentActiveMeshes: Vector.<AbstractMesh>;
        private var _currentRenderParticles: Boolean;

        private var _autoClearDepthStencil: Vector.<Boolean> = new Vector.<Boolean>(MAX_RENDERINGGROUPS, true);
        private var _customOpaqueSortCompareFn: Dictionary = new Dictionary(true);  // id - function(a: SubMesh, b: SubMesh): int
        private var _customAlphaTestSortCompareFn: Dictionary = new Dictionary(true);   // id - function(a: SubMesh, b: SubMesh): int
        private var _customTransparentSortCompareFn: Dictionary = new Dictionary(true); // id - function(a: SubMesh, b: SubMesh): int

        public function RenderingManager(scene: Scene) {
            this._scene = scene;

            for (var i: int = MIN_RENDERINGGROUPS; i < MAX_RENDERINGGROUPS; i++) {
                this._autoClearDepthStencil[i] = true;
            }
        }

        private function _renderParticles(index: int, activeMeshes: Vector.<AbstractMesh>): void {
            if (this._scene._activeParticleSystems.length == 0) {
                return;
            }

            // Particles
            var activeCamera: Camera = this._scene.activeCamera;
            this._scene._particlesDuration.beginMonitoring();
            for (var particleIndex: int = 0; particleIndex < this._scene._activeParticleSystems.length; particleIndex++) {
                var particleSystem: ParticleSystem = this._scene._activeParticleSystems[particleIndex];

                if (particleSystem.renderingGroupId != index) {
                    continue;
                }

                if ((activeCamera.layerMask & particleSystem.layerMask) == 0) {
                    continue;
                }

                this._clearDepthStencilBuffer();

                if (!particleSystem.emitter.position || !activeMeshes || activeMeshes.indexOf(particleSystem.emitter as AbstractMesh) != -1) {
                    this._scene._activeParticles.addCount(particleSystem.render(), false);
                }
            }
            this._scene._particlesDuration.endMonitoring(false);
        }

        private function _renderSpritesAndParticles(): void {
            if (this._currentRenderParticles) {
                this._renderParticles(this._currentIndex, this._currentActiveMeshes);
            }
        }

        public function render(customRenderFunction: Function, activeMeshes: Vector.<AbstractMesh>, renderParticles: Boolean): void {
            this._currentActiveMeshes = activeMeshes;
            this._currentRenderParticles = renderParticles;

            for (var index: int = MIN_RENDERINGGROUPS; index < MAX_RENDERINGGROUPS; index++) {
                this._depthStencilBufferAlreadyCleaned = index === MIN_RENDERINGGROUPS;
                var renderingGroup: RenderingGroup = this._renderingGroups[index];

                this._currentIndex = index;

                if (renderingGroup) {
                    if (this._autoClearDepthStencil[index]) {
                        this._clearDepthStencilBuffer();
                    }

                    if (!renderingGroup.onBeforeTransparentRendering) {
                        renderingGroup.onBeforeTransparentRendering = this._renderSpritesAndParticles;
                    }

                    renderingGroup.render(customRenderFunction);
                } else {
                    this._renderSpritesAndParticles();
                }
            }
        }

        private function _clearDepthStencilBuffer(): void {
            if (this._depthStencilBufferAlreadyCleaned) {
                return;
            }

            this._scene.getEngine().clear(null, false, true, true);
            this._depthStencilBufferAlreadyCleaned = true;
        }

        public function reset(): void {
            for (var index: int = MIN_RENDERINGGROUPS; index < MAX_RENDERINGGROUPS; index++) {
                var renderingGroup: RenderingGroup = this._renderingGroups[index];
                if (renderingGroup) {
                    renderingGroup.prepare();
                }
            }
        }

        public function dispatch(subMesh: SubMesh): void {
            var mesh: AbstractMesh = subMesh.getMesh();
            var renderingGroupId: int = mesh.renderingGroupId || 0;

            if (!(this._renderingGroups[renderingGroupId])) {
                this._renderingGroups[renderingGroupId] = new RenderingGroup(renderingGroupId, this._scene,
                        this._customOpaqueSortCompareFn[renderingGroupId],
                        this._customAlphaTestSortCompareFn[renderingGroupId],
                        this._customTransparentSortCompareFn[renderingGroupId]
                );
            }

            this._renderingGroups[renderingGroupId].dispatch(subMesh);
        }

        /**
         * Overrides the default sort function applied in the renderging group to prepare the meshes.
         * This allowed control for front to back rendering or reversly depending of the special needs.
         *
         * @param renderingGroupId The rendering group id corresponding to its index
         * @param opaqueSortCompareFn The opaque queue comparison function use to sort.
         * @param alphaTestSortCompareFn The alpha test queue comparison function use to sort.
         * @param transparentSortCompareFn The transparent queue comparison function use to sort.
         */
        public function setRenderingOrder(renderingGroupId: int,
                                          opaqueSortCompareFn: Function,  // (a: SubMesh, b: SubMesh) => number = null,
                                          alphaTestSortCompareFn: Function,   // (a: SubMesh, b: SubMesh) => number = null,
                                          transparentSortCompareFn: Function): void { // (a: SubMesh, b: SubMesh) => number = null) {

            this._customOpaqueSortCompareFn[renderingGroupId] = opaqueSortCompareFn;
            this._customAlphaTestSortCompareFn[renderingGroupId] = alphaTestSortCompareFn;
            this._customTransparentSortCompareFn[renderingGroupId] = transparentSortCompareFn;

            if (this._renderingGroups[renderingGroupId]) {
                var group: RenderingGroup = this._renderingGroups[renderingGroupId];
                group.opaqueSortCompareFn = this._customOpaqueSortCompareFn[renderingGroupId];
                group.alphaTestSortCompareFn = this._customAlphaTestSortCompareFn[renderingGroupId];
                group.transparentSortCompareFn = this._customTransparentSortCompareFn[renderingGroupId];
            }
        }

        /**
         * Specifies whether or not the stencil and depth buffer are cleared between two rendering groups.
         *
         * @param renderingGroupId The rendering group id corresponding to its index
         * @param autoClearDepthStencil Automatically clears depth and stencil between groups if true.
         * @param depth Automatically clears depth between groups if true and autoClear is true.
         * @param stencil Automatically clears stencil between groups if true and autoClear is true.
         */
        public function setRenderingAutoClearDepthStencil(renderingGroupId: int, autoClearDepthStencil: Boolean,
                                                          depth: Boolean = true,
                                                          stencil: Boolean = true): void {
            this._autoClearDepthStencil[renderingGroupId] = {
                autoClear: autoClearDepthStencil,
                depth: depth,
                stencil: stencil
            };
        }
    }
}
