/**
 * Created by caijingxiao on 2017/1/10.
 */
package babylon.postProcess {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.materials.Effect;
    import babylon.materials.textures.WebGLTexture;
    import babylon.mesh.VertexBuffer;

    import flash.display3D.IndexBuffer3D;

    import flash.utils.Dictionary;

    public class PostProcessManager {
        private var _scene: Scene;
        private var _indexBuffer: IndexBuffer3D;
        private var _vertexBuffers: Dictionary = new Dictionary(true);  // { [key: string]: VertexBuffer } = {};

        public function PostProcessManager(scene: Scene) {
            this._scene = scene;
        }

        private function _prepareBuffers(): void {
            if (this._vertexBuffers[VertexBuffer.PositionKind]) {
                return;
            }

            // VBO
            var vertices: Vector.<Number> = new <Number>[];
            vertices.push(1, 1);
            vertices.push(-1, 1);
            vertices.push(-1, -1);
            vertices.push(1, -1);

            this._vertexBuffers[VertexBuffer.PositionKind] = new VertexBuffer(this._scene.getEngine(), vertices, VertexBuffer.PositionKind, false, false, 2);

            // Indices
            var indices: Vector.<uint> = new <uint>[];
            indices.push(0);
            indices.push(1);
            indices.push(2);

            indices.push(0);
            indices.push(2);
            indices.push(3);

            this._indexBuffer = this._scene.getEngine().createIndexBuffer(indices);
        }

        // Methods
        public function _prepareFrame(sourceTexture: WebGLTexture = null): Boolean {
            var postProcesses: Vector.<PostProcess> = this._scene.activeCamera._postProcesses;

            if (postProcesses.length === 0 || !this._scene.postProcessesEnabled) {
                return false;
            }

            postProcesses[0].activate(this._scene.activeCamera, sourceTexture);
            return true;
        }

        public function directRender(postProcesses: Vector.<PostProcess>, targetTexture: WebGLTexture = null): void {
            var engine: Engine = this._scene.getEngine();

            for (var index: int = 0; index < postProcesses.length; index++) {
                if (index < postProcesses.length - 1) {
                    postProcesses[index + 1].activate(this._scene.activeCamera, targetTexture);
                } else {
                    if (targetTexture) {
                        engine.bindFramebuffer(targetTexture);
                    } else {
                        engine.restoreDefaultFramebuffer(this._scene.clearColor);
                    }
                }

                var pp: PostProcess = postProcesses[index];
                var effect: Effect = pp.apply();

                if (effect) {
                    pp.onBeforeRenderObservable.notifyObservers(effect);

                    // VBOs
                    this._prepareBuffers();
                    engine.bindBuffers(this._vertexBuffers, this._indexBuffer, effect);

                    // Draw order
                    engine.draw(this._indexBuffer, 0, 2);

                    pp.onAfterRenderObservable.notifyObservers(effect);
                }
            }

            // Restore depth buffer
            engine.setDepthBuffer(true);
            engine.setDepthWrite(true);
        }

        public function _finalizeFrame(doNotPresent: Boolean = false, targetTexture: WebGLTexture = null, faceIndex: Number = NaN, postProcesses: Vector.<PostProcess> = null): void {
            postProcesses = postProcesses || this._scene.activeCamera._postProcesses;
            if (postProcesses.length === 0 || !this._scene.postProcessesEnabled) {
                return;
            }
            var engine: Engine = this._scene.getEngine();

            for (var index: int = 0, len: int = postProcesses.length; index < len; index++) {
                if (index < len - 1) {
                    postProcesses[index + 1].activate(this._scene.activeCamera, targetTexture);
                } else {
                    if (targetTexture) {
                        engine.bindFramebuffer(targetTexture, faceIndex);
                    } else {
                        engine.restoreDefaultFramebuffer(this._scene.clearColor);
                    }
                }

                if (doNotPresent) {
                    break;
                }

                var pp: PostProcess = postProcesses[index];
                var effect: Effect = pp.apply();

                if (effect) {
                    pp.onBeforeRenderObservable.notifyObservers(effect);

                    // VBOs
                    this._prepareBuffers();
                    engine.bindBuffers(this._vertexBuffers, this._indexBuffer, effect);

                    // Draw order
                    engine.draw(this._indexBuffer, 0, 2);

                    pp.onAfterRenderObservable.notifyObservers(effect);
                }
            }

            // Restore depth buffer
            engine.setDepthBuffer(true);
            engine.setDepthWrite(true);
        }

        public function dispose(): void {
            var buffer: VertexBuffer = this._vertexBuffers[VertexBuffer.PositionKind];
            if (buffer) {
                buffer.dispose();
                this._vertexBuffers[VertexBuffer.PositionKind] = null;
            }

            if (this._indexBuffer) {
                this._scene.getEngine()._releaseBuffer(this._indexBuffer);
                this._indexBuffer = null;
            }
        }
    }
}
