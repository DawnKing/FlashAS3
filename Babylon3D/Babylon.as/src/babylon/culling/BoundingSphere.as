package babylon.culling {
    import babylon.math.MathTools;
    import babylon.math.Matrix;
    import babylon.math.Plane;
    import babylon.math.Vector3;

    public class BoundingSphere {

        public var center: Vector3;
        public var radius: Number;
        public var centerWorld: Vector3;
        public var radiusWorld: Number;

        private var _tempRadiusVector: Vector3 = Vector3.Zero();

        public var minimum: Vector3;
        public var maximum: Vector3;

        public function BoundingSphere(minimum: Vector3, maximum: Vector3) {
            this.minimum = minimum;
            this.maximum = maximum;
            var distance: Number = Vector3.Distance(minimum, maximum);

            this.center = Vector3.Lerp(minimum, maximum, 0.5);
            this.radius = distance * 0.5;

            this.centerWorld = Vector3.Zero();
            this._update(Matrix.Identity());
        }

        // Methods
        public function _update(world: Matrix): void {
            Vector3.TransformCoordinatesToRef(this.center, world, this.centerWorld);
            Vector3.TransformNormalFromFloatsToRef(1.0, 1.0, 1.0, world, this._tempRadiusVector);
            this.radiusWorld = Math.max(Math.abs(this._tempRadiusVector.x), Math.abs(this._tempRadiusVector.y), Math.abs(this._tempRadiusVector.z)) * this.radius;
        }

        public function isInFrustum(frustumPlanes: Vector.<Plane>): Boolean {
            for (var i: int = 0; i < 6; i++) {
                if (frustumPlanes[i].dotCoordinate(this.centerWorld) <= -this.radiusWorld)
                    return false;
            }

            return true;
        }

        public function intersectsPoint(point: Vector3): Boolean {
            var x: Number = this.centerWorld.x - point.x;
            var y: Number = this.centerWorld.y - point.y;
            var z: Number = this.centerWorld.z - point.z;

            var distance: Number = Math.sqrt((x * x) + (y * y) + (z * z));

            if (Math.abs(this.radiusWorld - distance) < MathTools.Epsilon)
                return false;

            return true;
        }

        // Statics
        public static function Intersects(sphere0: BoundingSphere, sphere1: BoundingSphere): Boolean {
            var x: Number = sphere0.centerWorld.x - sphere1.centerWorld.x;
            var y: Number = sphere0.centerWorld.y - sphere1.centerWorld.y;
            var z: Number = sphere0.centerWorld.z - sphere1.centerWorld.z;

            var distance: Number = Math.sqrt((x * x) + (y * y) + (z * z));

            if (sphere0.radiusWorld + sphere1.radiusWorld < distance)
                return false;

            return true;
        }

    }
}
