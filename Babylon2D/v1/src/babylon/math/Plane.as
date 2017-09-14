package babylon.math {
    public class Plane {
        public var normal: Vector3;
        public var d: Number;

        public function Plane(a: Number, b: Number, c: Number, d: Number) {
            this.normal = new Vector3(a, b, c);
            this.d = d;
        }

        public function asArray(): Vector.<Number> {
            return new <Number>[this.normal.x, this.normal.y, this.normal.z, this.d];
        }

        // Methods
        public function clone(): Plane {
            return new Plane(this.normal.x, this.normal.y, this.normal.z, this.d);
        }

        public function getClassName(): String {
            return "Plane";
        }

        public function getHashCode(): Number {
            var hash: Number = this.normal.getHashCode();
            hash = (hash * 397) ^ (this.d || 0);
            return hash;
        }

        public function normalize(): Plane {
            var norm: Number = (Math.sqrt((this.normal.x * this.normal.x) + (this.normal.y * this.normal.y) + (this.normal.z * this.normal.z)));
            var magnitude: Number = 0;

            if (norm !== 0) {
                magnitude = 1.0 / norm;
            }

            this.normal.x *= magnitude;
            this.normal.y *= magnitude;
            this.normal.z *= magnitude;

            this.d *= magnitude;

            return this;
        }

        public function transform(transformation: Matrix): Plane {
            var transposedMatrix: Matrix = Matrix.Transpose(transformation);
            var x: Number = this.normal.x;
            var y: Number = this.normal.y;
            var z: Number = this.normal.z;
            var d: Number = this.d;

            var normalX: Number = (((x * transposedMatrix.m[0]) + (y * transposedMatrix.m[1])) + (z * transposedMatrix.m[2])) + (d * transposedMatrix.m[3]);
            var normalY: Number = (((x * transposedMatrix.m[4]) + (y * transposedMatrix.m[5])) + (z * transposedMatrix.m[6])) + (d * transposedMatrix.m[7]);
            var normalZ: Number = (((x * transposedMatrix.m[8]) + (y * transposedMatrix.m[9])) + (z * transposedMatrix.m[10])) + (d * transposedMatrix.m[11]);
            var finalD: Number = (((x * transposedMatrix.m[12]) + (y * transposedMatrix.m[13])) + (z * transposedMatrix.m[14])) + (d * transposedMatrix.m[15]);

            return new Plane(normalX, normalY, normalZ, finalD);
        }


        public function dotCoordinate(point: Vector3): Number {
            return ((((this.normal.x * point.x) + (this.normal.y * point.y)) + (this.normal.z * point.z)) + this.d);
        }

        public function copyFromPoints(point1: Vector3, point2: Vector3, point3: Vector3): Plane {
            var x1: Number = point2.x - point1.x;
            var y1: Number = point2.y - point1.y;
            var z1: Number = point2.z - point1.z;
            var x2: Number = point3.x - point1.x;
            var y2: Number = point3.y - point1.y;
            var z2: Number = point3.z - point1.z;
            var yz: Number = (y1 * z2) - (z1 * y2);
            var xz: Number = (z1 * x2) - (x1 * z2);
            var xy: Number = (x1 * y2) - (y1 * x2);
            var pyth: Number = (Math.sqrt((yz * yz) + (xz * xz) + (xy * xy)));
            var invPyth: Number;

            if (pyth !== 0) {
                invPyth = 1.0 / pyth;
            }
            else {
                invPyth = 0;
            }

            this.normal.x = yz * invPyth;
            this.normal.y = xz * invPyth;
            this.normal.z = xy * invPyth;
            this.d = -((this.normal.x * point1.x) + (this.normal.y * point1.y) + (this.normal.z * point1.z));

            return this;
        }

        public function isFrontFacingTo(direction: Vector3, epsilon: Number): Boolean {
            var dot: Number = Vector3.Dot(this.normal, direction);

            return (dot <= epsilon);
        }

        public function signedDistanceTo(point: Vector3): Number {
            return Vector3.Dot(point, this.normal) + this.d;
        }

        // Statics
        public static function FromArray(array: Vector.<Number>): Plane {
            return new Plane(array[0], array[1], array[2], array[3]);
        }

        public static function FromPoints(point1: Vector3, point2: Vector3, point3: Vector3): Plane {
            var result: Plane = new Plane(0, 0, 0, 0);

            result.copyFromPoints(point1, point2, point3);

            return result;
        }

        public static function FromPositionAndNormal(origin: Vector3, normal: Vector3): Plane {
            var result: Plane = new Plane(0, 0, 0, 0);
            normal.normalize();

            result.normal = normal;
            result.d = -(normal.x * origin.x + normal.y * origin.y + normal.z * origin.z);

            return result;
        }

        public static function SignedDistanceToPlaneFromPositionAndNormal(origin: Vector3, normal: Vector3, point: Vector3): Number {
            var d: Number = -(normal.x * origin.x + normal.y * origin.y + normal.z * origin.z);

            return Vector3.Dot(point, normal) + d;
        }
    }
}
