/**
 * Created by caijingxiao on 2016/11/29.
 */
package babylon.particles {
    import babylon.culling.BoundingInfo;
    import babylon.culling.BoundingSphere;
    import babylon.math.Color4;
    import babylon.math.Quaternion;
    import babylon.math.Vector3;
    import babylon.math.Vector4;

    public class SolidParticle {
        public var idx: int = 0;                         // particle global index
        public var color: Color4 = new Color4(1.0, 1.0, 1.0, 1.0);  // color
        public var position: Vector3 = Vector3.Zero();               // position
        public var rotation: Vector3 = Vector3.Zero();               // rotation
        public var rotationQuaternion: Quaternion;          // quaternion, will overwrite rotation
        public var scaling: Vector3 = new Vector3(1.0, 1.0, 1.0);    // scaling
        public var uvs: Vector4 = new Vector4(0.0, 0.0, 1.0, 1.0);   // uvs
        public var velocity: Vector3 = Vector3.Zero();               // velocity
        public var alive: Boolean = true;                            // alive
        public var isVisible: Boolean = true;                        // visibility
        public var _pos: int = 0;                        // index of this particle in the global "positions" array
        public var _model: ModelShape;                      // model shape reference
        public var shapeId: int = 0;                     // model shape id
        public var idxInShape: int = 0;                  // index of the particle in its shape id
        public var _modelBoundingInfo: BoundingInfo;        // reference to the shape model BoundingInfo object
        public var _boundingInfo: BoundingInfo;             // particle BoundingInfo
        public var _sps: SolidParticleSystem;               // reference to the SPS what the particle belongs to

        /**
         * Creates a Solid Particle object.
         * Don't create particles manually, use instead the Solid Particle System internal tools like _addParticle()
         * `particleIndex` (integer) is the particle index in the Solid Particle System pool. It's also the particle identifier.
         * `positionIndex` (integer) is the starting index of the particle vertices in the SPS "positions" array.
         *  `model` (ModelShape) is a reference to the model shape on what the particle is designed.
         * `shapeId` (integer) is the model shape identifier in the SPS.
         * `idxInShape` (integer) is the index of the particle in the current model (ex: the 10th box of addShape(box, 30))
         * `modelBoundingInfo` is the reference to the model BoundingInfo used for intersection computations.
         */
        public function SolidParticle(particleIndex: int, positionIndex: int, model: ModelShape, shapeId: int, idxInShape: int, sps: SolidParticleSystem, modelBoundingInfo: BoundingInfo = null) {
            this.idx = particleIndex;
            this._pos = positionIndex;
            this._model = model;
            this.shapeId = shapeId;
            this.idxInShape = idxInShape;
            this._sps = sps;
            if (modelBoundingInfo) {
                this._modelBoundingInfo = modelBoundingInfo;
                this._boundingInfo = new BoundingInfo(modelBoundingInfo.minimum, modelBoundingInfo.maximum);
            }
        }

        /**
         * legacy support, changed scale to scaling
         */
        public function get scale(): Vector3 {
            return this.scaling;
        }

        public function set scale(scale: Vector3): void {
            this.scaling = scale;
        }

        /**
         * legacy support, changed quaternion to rotationQuaternion
         */
        public function get quaternion(): Quaternion {
            return this.rotationQuaternion;
        }

        public function set quaternion(q: Quaternion): void {
            this.rotationQuaternion = q;
        }

        /**
         * Returns a Boolean. True if the particle intersects another particle or another mesh, else false.
         * The intersection is computed on the particle bounding sphere and Axis Aligned Bounding Box (AABB)
         * `target` is the object (solid particle or mesh) what the intersection is computed against.
         */
        public function intersectsMesh(target: Object): Boolean {
            if (!this._boundingInfo || !target._boundingInfo) {
                return false;
            }
            if (this._sps._bSphereOnly) {
                return BoundingSphere.Intersects(this._boundingInfo.boundingSphere, target._boundingInfo.boundingSphere);
            }
            return this._boundingInfo.intersects(target._boundingInfo, false);
        }
    }
}
