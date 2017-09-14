/**
 * Created by caijingxiao on 2016/11/29.
 */
package babylon.particles {
    import babylon.math.Vector3;

    public class ModelShape {
        public var shapeID: Number;
        public var _shape: Vector.<Vector3>;
        public var _shapeUV: Vector.<Number>;
        public var _positionFunction: Function; // (particle: SolidParticle, i: Number, s: Number) => void;
        public var _vertexFunction: Function;   // (particle: SolidParticle, vertex: Vector3, i: Number) => void;

        /**
         * Creates a ModelShape object. This is an internal simplified reference to a mesh used as for a model to replicate particles from by the SPS.
         * SPS internal tool, don't use it manually.
         */
        public function ModelShape(id: Number, shape: Vector.<Vector3>, shapeUV: Vector.<Number>, posFunction: Function, vtxFunction: Function) {
            this.shapeID = id;
            this._shape = shape;
            this._shapeUV = shapeUV;
            this._positionFunction = posFunction;
            this._vertexFunction = vtxFunction;
        }
    }
}
