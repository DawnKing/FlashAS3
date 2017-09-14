package babylon.math {
    public class Vector3 {
        public static const X_AXIS: Vector3 = new Vector3(1, 0, 0);
        public static const Y_AXIS: Vector3 = new Vector3(0, 1, 0);
        public static const Z_AXIS: Vector3 = new Vector3(0, 0, 1);

        public var x:Number;
        public var y:Number;
        public var z:Number;

        public function Vector3(x:Number, y:Number, z:Number) {
            this.x = x;
            this.y = y;
            this.z = z;
        }

        public function toString(): String {
            return "{X: " + this.x + " Y:" + this.y + " Z:" + this.z + "}";
        }

        public function getClassName(): String {
            return "Vector3";
        }

        public function getHashCode(): Number {
            var hash: Number = this.x || 0;
            hash = (hash * 397) ^ (this.y || 0);
            hash = (hash * 397) ^ (this.z || 0);
            return hash;
        }

        // Operators
        public function asArray(): Vector.<Number> {
            var result: Vector.<Number> = new <Number>[];

            this.toArray(result, 0);

            return result;
        }

        public function toArray(array: Vector.<Number>, index: Number = 0): Vector3 {
            array[index] = this.x;
            array[index + 1] = this.y;
            array[index + 2] = this.z;

            return this;
        }

        public function toQuaternion(): Quaternion {
            var result: Quaternion = new Quaternion(0, 0, 0, 1);

            var cosxPlusz: Number = Math.cos((this.x + this.z) * 0.5);
            var sinxPlusz: Number = Math.sin((this.x + this.z) * 0.5);
            var coszMinusx: Number = Math.cos((this.z - this.x) * 0.5);
            var sinzMinusx: Number = Math.sin((this.z - this.x) * 0.5);
            var cosy: Number = Math.cos(this.y * 0.5);
            var siny: Number = Math.sin(this.y * 0.5);

            result.x = coszMinusx * siny;
            result.y = -sinzMinusx * siny;
            result.z = sinxPlusz * cosy;
            result.w = cosxPlusz * cosy;

            return result;
        }

        public function addInPlace(otherVector: Vector3): Vector3 {
            this.x += otherVector.x;
            this.y += otherVector.y;
            this.z += otherVector.z;

            return this;
        }

        public function add(otherVector: Vector3): Vector3 {
            return new Vector3(this.x + otherVector.x, this.y + otherVector.y, this.z + otherVector.z);
        }

        public function addToRef(otherVector: Vector3, result: Vector3): Vector3 {
            result.x = this.x + otherVector.x;
            result.y = this.y + otherVector.y;
            result.z = this.z + otherVector.z;

            return this;
        }

        public function subtractInPlace(otherVector: Vector3): Vector3 {
            this.x -= otherVector.x;
            this.y -= otherVector.y;
            this.z -= otherVector.z;

            return this;
        }

        public function subtract(otherVector: Vector3): Vector3 {
            return new Vector3(this.x - otherVector.x, this.y - otherVector.y, this.z - otherVector.z);
        }

        public function subtractToRef(otherVector: Vector3, result: Vector3): Vector3 {
            result.x = this.x - otherVector.x;
            result.y = this.y - otherVector.y;
            result.z = this.z - otherVector.z;

            return this;
        }

        public function subtractFromFloats(x: Number, y: Number, z: Number): Vector3 {
            return new Vector3(this.x - x, this.y - y, this.z - z);
        }

        public function subtractFromFloatsToRef(x: Number, y: Number, z: Number, result: Vector3): Vector3 {
            result.x = this.x - x;
            result.y = this.y - y;
            result.z = this.z - z;

            return this;
        }

        public function negate(): Vector3 {
            return new Vector3(-this.x, -this.y, -this.z);
        }

        public function scaleInPlace(scale: Number): Vector3 {
            this.x *= scale;
            this.y *= scale;
            this.z *= scale;
            return this;
        }

        public function scale(scale: Number): Vector3 {
            return new Vector3(this.x * scale, this.y * scale, this.z * scale);
        }

        public function scaleToRef(scale: Number, result: Vector3): void {
            result.x = this.x * scale;
            result.y = this.y * scale;
            result.z = this.z * scale;
        }

        public function equals(otherVector: Vector3): Boolean {
            return otherVector && this.x === otherVector.x && this.y === otherVector.y && this.z === otherVector.z;
        }

        public function equalsWithEpsilon(otherVector: Vector3, epsilon: Number = MathTools.Epsilon): Boolean {
            return otherVector && MathTools.WithinEpsilon(this.x, otherVector.x, epsilon) && MathTools.WithinEpsilon(this.y, otherVector.y, epsilon) && MathTools.WithinEpsilon(this.z, otherVector.z, epsilon);
        }

        public function equalsToFloats(x: Number, y: Number, z: Number): Boolean {
            return this.x === x && this.y === y && this.z === z;
        }

        public function multiplyInPlace(otherVector: Vector3): Vector3 {
            this.x *= otherVector.x;
            this.y *= otherVector.y;
            this.z *= otherVector.z;

            return this;
        }

        public function multiply(otherVector: Vector3): Vector3 {
            return new Vector3(this.x * otherVector.x, this.y * otherVector.y, this.z * otherVector.z);
        }

        public function multiplyToRef(otherVector: Vector3, result: Vector3): Vector3 {
            result.x = this.x * otherVector.x;
            result.y = this.y * otherVector.y;
            result.z = this.z * otherVector.z;

            return this;
        }

        public function multiplyByFloats(x: Number, y: Number, z: Number): Vector3 {
            return new Vector3(this.x * x, this.y * y, this.z * z);
        }

        public function divide(otherVector: Vector3): Vector3 {
            return new Vector3(this.x / otherVector.x, this.y / otherVector.y, this.z / otherVector.z);
        }

        public function divideToRef(otherVector: Vector3, result: Vector3): Vector3 {
            result.x = this.x / otherVector.x;
            result.y = this.y / otherVector.y;
            result.z = this.z / otherVector.z;

            return this;
        }

        public function MinimizeInPlace(other: Vector3): Vector3 {
            if (other.x < this.x) this.x = other.x;
            if (other.y < this.y) this.y = other.y;
            if (other.z < this.z) this.z = other.z;

            return this;
        }

        public function MaximizeInPlace(other: Vector3): Vector3 {
            if (other.x > this.x) this.x = other.x;
            if (other.y > this.y) this.y = other.y;
            if (other.z > this.z) this.z = other.z;

            return this;
        }

        // Properties
        public function length(): Number {
            return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
        }

        public function lengthSquared(): Number {
            return (this.x * this.x + this.y * this.y + this.z * this.z);
        }

        // Methods
        public function normalize(): Vector3 {
            var len: Number = this.length();

            if (len === 0 || len === 1.0)
                return this;

            var num: Number = 1.0 / len;

            this.x *= num;
            this.y *= num;
            this.z *= num;

            return this;
        }

        public function clone(): Vector3 {
            return new Vector3(this.x, this.y, this.z);
        }

        public function copyFrom(source: Vector3): Vector3 {
            this.x = source.x;
            this.y = source.y;
            this.z = source.z;

            return this;
        }

        public function copyFromFloats(x: Number, y: Number, z: Number): Vector3 {
            this.x = x;
            this.y = y;
            this.z = z;

            return this;
        }

        // Statics
        public static function GetClipFactor(vector0: Vector3, vector1: Vector3, axis: Vector3, size: Number): Number {
            var d0: Number = Vector3.Dot(vector0, axis) - size;
            var d1: Number = Vector3.Dot(vector1, axis) - size;

            var s: Number = d0 / (d0 - d1);

            return s;
        }

        public static function FromArray(array: Array, offset: Number = undefined): Vector3 {
            if (!offset) {
                offset = 0;
            }

            return new Vector3(array[offset], array[offset + 1], array[offset + 2]);
        }

        public static function FromFloatArray(array: Vector.<Number>, offset: Number = undefined): Vector3 {
            if (!offset) {
                offset = 0;
            }

            return new Vector3(array[offset], array[offset + 1], array[offset + 2]);
        }

        public static function FromArrayToRef(array: Vector.<Number>, offset: Number, result: Vector3): void {
            result.x = array[offset];
            result.y = array[offset + 1];
            result.z = array[offset + 2];
        }

        public static function FromFloatArrayToRef(array: Vector.<Number>, offset: Number, result: Vector3): void {
            result.x = array[offset];
            result.y = array[offset + 1];
            result.z = array[offset + 2];
        }

        public static function FromFloatsToRef(x: Number, y: Number, z: Number, result: Vector3): void {
            result.x = x;
            result.y = y;
            result.z = z;
        }

        public static function Zero(): Vector3 {
            return new Vector3(0, 0, 0);
        }

        public static function Up(): Vector3 {
            return new Vector3(0, 1.0, 0);
        }

        public static function TransformCoordinates(vector: Vector3, transformation: Matrix): Vector3 {
            var result: Vector3 = Vector3.Zero();

            Vector3.TransformCoordinatesToRef(vector, transformation, result);

            return result;
        }

        public static function TransformCoordinatesToRef(vector: Vector3, transformation: Matrix, result: Vector3): void {
            var x: Number = (vector.x * transformation.m[0]) + (vector.y * transformation.m[4]) + (vector.z * transformation.m[8]) + transformation.m[12];
            var y: Number = (vector.x * transformation.m[1]) + (vector.y * transformation.m[5]) + (vector.z * transformation.m[9]) + transformation.m[13];
            var z: Number = (vector.x * transformation.m[2]) + (vector.y * transformation.m[6]) + (vector.z * transformation.m[10]) + transformation.m[14];
            var w: Number = (vector.x * transformation.m[3]) + (vector.y * transformation.m[7]) + (vector.z * transformation.m[11]) + transformation.m[15];

            result.x = x / w;
            result.y = y / w;
            result.z = z / w;
        }

        public static function TransformCoordinatesFromFloatsToRef(x: Number, y: Number, z: Number, transformation: Matrix, result: Vector3): void {
            var rx: Number = (x * transformation.m[0]) + (y * transformation.m[4]) + (z * transformation.m[8]) + transformation.m[12];
            var ry: Number = (x * transformation.m[1]) + (y * transformation.m[5]) + (z * transformation.m[9]) + transformation.m[13];
            var rz: Number = (x * transformation.m[2]) + (y * transformation.m[6]) + (z * transformation.m[10]) + transformation.m[14];
            var rw: Number = (x * transformation.m[3]) + (y * transformation.m[7]) + (z * transformation.m[11]) + transformation.m[15];

            result.x = rx / rw;
            result.y = ry / rw;
            result.z = rz / rw;
        }

        public static function TransformNormal(vector: Vector3, transformation: Matrix): Vector3 {
            var result: Vector3 = Vector3.Zero();

            Vector3.TransformNormalToRef(vector, transformation, result);

            return result;
        }

        public static function TransformNormalToRef(vector: Vector3, transformation: Matrix, result: Vector3): void {
            result.x = (vector.x * transformation.m[0]) + (vector.y * transformation.m[4]) + (vector.z * transformation.m[8]);
            result.y = (vector.x * transformation.m[1]) + (vector.y * transformation.m[5]) + (vector.z * transformation.m[9]);
            result.z = (vector.x * transformation.m[2]) + (vector.y * transformation.m[6]) + (vector.z * transformation.m[10]);
        }

        public static function TransformNormalFromFloatsToRef(x: Number, y: Number, z: Number, transformation: Matrix, result: Vector3): void {
            result.x = (x * transformation.m[0]) + (y * transformation.m[4]) + (z * transformation.m[8]);
            result.y = (x * transformation.m[1]) + (y * transformation.m[5]) + (z * transformation.m[9]);
            result.z = (x * transformation.m[2]) + (y * transformation.m[6]) + (z * transformation.m[10]);
        }

        public static function CatmullRom(value1: Vector3, value2: Vector3, value3: Vector3, value4: Vector3, amount: Number): Vector3 {
            var squared: Number = amount * amount;
            var cubed: Number = amount * squared;

            var x: Number = 0.5 * ((((2.0 * value2.x) + ((-value1.x + value3.x) * amount)) +
                    (((((2.0 * value1.x) - (5.0 * value2.x)) + (4.0 * value3.x)) - value4.x) * squared)) +
                    ((((-value1.x + (3.0 * value2.x)) - (3.0 * value3.x)) + value4.x) * cubed));

            var y: Number = 0.5 * ((((2.0 * value2.y) + ((-value1.y + value3.y) * amount)) +
                    (((((2.0 * value1.y) - (5.0 * value2.y)) + (4.0 * value3.y)) - value4.y) * squared)) +
                    ((((-value1.y + (3.0 * value2.y)) - (3.0 * value3.y)) + value4.y) * cubed));

            var z: Number = 0.5 * ((((2.0 * value2.z) + ((-value1.z + value3.z) * amount)) +
                    (((((2.0 * value1.z) - (5.0 * value2.z)) + (4.0 * value3.z)) - value4.z) * squared)) +
                    ((((-value1.z + (3.0 * value2.z)) - (3.0 * value3.z)) + value4.z) * cubed));

            return new Vector3(x, y, z);
        }

        public static function Clamp(value: Vector3, min: Vector3, max: Vector3): Vector3 {
            var x: Number = value.x;
            x = (x > max.x) ? max.x : x;
            x = (x < min.x) ? min.x : x;

            var y: Number = value.y;
            y = (y > max.y) ? max.y : y;
            y = (y < min.y) ? min.y : y;

            var z: Number = value.z;
            z = (z > max.z) ? max.z : z;
            z = (z < min.z) ? min.z : z;

            return new Vector3(x, y, z);
        }

        public static function Hermite(value1: Vector3, tangent1: Vector3, value2: Vector3, tangent2: Vector3, amount: Number): Vector3 {
            var squared: Number = amount * amount;
            var cubed: Number = amount * squared;
            var part1: Number = ((2.0 * cubed) - (3.0 * squared)) + 1.0;
            var part2: Number = (-2.0 * cubed) + (3.0 * squared);
            var part3: Number = (cubed - (2.0 * squared)) + amount;
            var part4: Number = cubed - squared;

            var x: Number = (((value1.x * part1) + (value2.x * part2)) + (tangent1.x * part3)) + (tangent2.x * part4);
            var y: Number = (((value1.y * part1) + (value2.y * part2)) + (tangent1.y * part3)) + (tangent2.y * part4);
            var z: Number = (((value1.z * part1) + (value2.z * part2)) + (tangent1.z * part3)) + (tangent2.z * part4);

            return new Vector3(x, y, z);
        }

        public static function Lerp(start: Vector3, end: Vector3, amount: Number): Vector3 {
            var result: Vector3 = new Vector3(0, 0, 0);

            Vector3.LerpToRef(start, end, amount, result);

            return result;
        }

        public static function LerpToRef(start: Vector3, end: Vector3, amount: Number, result: Vector3): void {
            result.x = start.x + ((end.x - start.x) * amount);
            result.y = start.y + ((end.y - start.y) * amount);
            result.z = start.z + ((end.z - start.z) * amount);
        }

        public static function Dot(a: Vector3, b: Vector3): Number {
            return (a.x * b.x + a.y * b.y + a.z * b.z);
        }
        public static function CrossToRef(left: Vector3, right: Vector3, result: Vector3): void {
            Tmp.VECTOR3[0].x = left.y * right.z - left.z * right.y;
            Tmp.VECTOR3[0].y = left.z * right.x - left.x * right.z;
            Tmp.VECTOR3[0].z = left.x * right.y - left.y * right.x;
            result.copyFrom(Tmp.VECTOR3[0]);
        }


        public static function Cross(left: Vector3, right: Vector3): Vector3 {
            var result: Vector3 = Vector3.Zero();

            Vector3.CrossToRef(left, right, result);

            return result;
        }

        public static function Normalize(vector: Vector3): Vector3 {
            var result: Vector3 = Vector3.Zero();
            Vector3.NormalizeToRef(vector, result);
            return result;
        }

        public static function NormalizeToRef(vector: Vector3, result: Vector3): void {
            result.copyFrom(vector);
            result.normalize();
        }

        private static var _viewportMatrixCache: Matrix;
        private static var  _matrixCache: Matrix;
        public static function Project(vector: Vector3, world: Matrix, transform: Matrix, viewport: Viewport): Vector3 {
            var cw: Number = viewport.width;
            var ch: Number = viewport.height;
            var cx: Number = viewport.x;
            var cy: Number = viewport.y;

            var viewportMatrix: Matrix = Vector3._viewportMatrixCache ? Vector3._viewportMatrixCache : (Vector3._viewportMatrixCache = new Matrix());

            Matrix.FromValuesToRef(
                    cw / 2.0, 0, 0, 0,
                    0, -ch / 2.0, 0, 0,
                    0, 0, 1, 0,
                    cx + cw / 2.0, ch / 2.0 + cy, 0, 1, viewportMatrix);

            var matrix: Matrix = Vector3._matrixCache ? Vector3._matrixCache : (Vector3._matrixCache = new Matrix());
            world.multiplyToRef(transform, matrix);
            matrix.multiplyToRef(viewportMatrix, matrix);

            return Vector3.TransformCoordinates(vector, matrix);
        }

        public static function UnprojectFromTransform(source: Vector3, viewportWidth: Number, viewportHeight: Number, world: Matrix, transform: Matrix): Vector3 {
            var matrix: Matrix = Vector3._matrixCache ? Vector3._matrixCache : (Vector3._matrixCache = new Matrix());
            world.multiplyToRef(transform, matrix);
            matrix.invert();
            source.x = source.x / viewportWidth * 2 - 1;
            source.y = -(source.y / viewportHeight * 2 - 1);
            var vector: Vector3 = Vector3.TransformCoordinates(source, matrix);
            var num: Number = source.x * matrix.m[3] + source.y * matrix.m[7] + source.z * matrix.m[11] + matrix.m[15];

            if (MathTools.WithinEpsilon(num, 1.0)) {
                vector = vector.scale(1.0 / num);
            }

            return vector;
        }

        public static function Unproject(source: Vector3, viewportWidth: Number, viewportHeight: Number, world: Matrix, view: Matrix, projection: Matrix): Vector3 {
            var matrix: Matrix = Vector3._matrixCache ? Vector3._matrixCache : (Vector3._matrixCache = new Matrix());
            world.multiplyToRef(view, matrix);
            matrix.multiplyToRef(projection, matrix);
            matrix.invert();
            var screenSource: Vector3 = new Vector3(source.x / viewportWidth * 2 - 1, -(source.y / viewportHeight * 2 - 1), source.z);
            var vector: Vector3 = Vector3.TransformCoordinates(screenSource, matrix);
            var num: Number = screenSource.x * matrix.m[3] + screenSource.y * matrix.m[7] + screenSource.z * matrix.m[11] + matrix.m[15];

            if (MathTools.WithinEpsilon(num, 1.0)) {
                vector = vector.scale(1.0 / num);
            }

            return vector;
        }

        public static function Minimize(left: Vector3, right: Vector3): Vector3 {
            var min: Vector3 = left.clone();
            min.MinimizeInPlace(right);
            return min;
        }

        public static function Maximize(left: Vector3, right: Vector3): Vector3 {
            var max: Vector3 = left.clone();
            max.MaximizeInPlace(right);
            return max;
        }

        public static function Distance(value1: Vector3, value2: Vector3): Number {
            return Math.sqrt(Vector3.DistanceSquared(value1, value2));
        }

        public static function DistanceSquared(value1: Vector3, value2: Vector3): Number {
            var x: Number = value1.x - value2.x;
            var y: Number = value1.y - value2.y;
            var z: Number = value1.z - value2.z;

            return (x * x) + (y * y) + (z * z);
        }

        public static function Center(value1: Vector3, value2: Vector3): Vector3 {
            var center: Vector3 = value1.add(value2);
            center.scaleInPlace(0.5);
            return center;
        }

        /**
         * Given three orthogonal normalized left-handed oriented Vector3 axis in space (target system),
         * RotationFromAxis() returns the rotation Euler angles (ex : rotation.x, rotation.y, rotation.z) to apply
         * to something in order to rotate it from its local system to the given target system.
         */
        public static function RotationFromAxis(axis1: Vector3, axis2: Vector3, axis3: Vector3): Vector3 {
            var rotation: Vector3 = Vector3.Zero();
            Vector3.RotationFromAxisToRef(axis1, axis2, axis3, rotation);
            return rotation;
        }

        /**
         * The same than RotationFromAxis but updates the passed ref Vector3 parameter.
         */
        public static function RotationFromAxisToRef(axis1: Vector3, axis2: Vector3, axis3: Vector3, ref: Vector3): void {
            var u: Vector3 = axis1.normalize();
            var w: Vector3 = axis3.normalize();

            // world axis
            var X: Vector3 = X_AXIS;
            var Y: Vector3 = Y_AXIS;

            // equation unknowns and vars
            var yaw: Number = 0.0;
            var pitch: Number = 0.0;
            var roll: Number = 0.0;
            var x: Number = 0.0;
            var y: Number = 0.0;
            var z: Number = 0.0;
            var t: Number = 0.0;
            var sign: Number = -1.0;
            var nbRevert: Number = 0;
            var cross: Vector3 = Tmp.VECTOR3[0];
            var dot: Number = 0.0;

            // step 1  : rotation around w
            // Rv3(u) = u1, and u1 belongs to plane xOz
            // Rv3(w) = w1 = w invariant
            var u1: Vector3 = Tmp.VECTOR3[1];
            if (MathTools.WithinEpsilon(w.z, 0, MathTools.Epsilon)) {
                z = 1.0;
            }
            else if (MathTools.WithinEpsilon(w.x, 0, MathTools.Epsilon)) {
                x = 1.0;
            }
            else {
                t = w.z / w.x;
                x = - t * Math.sqrt(1 / (1 + t * t));
                z = Math.sqrt(1 / (1 + t * t));
            }

            u1.x = x;
            u1.y = y;
            u1.z = z;
            u1.normalize();
            Vector3.CrossToRef(u, u1, cross);  // returns same direction as w (=local z) if positive angle : cross(source, image)
            cross.normalize();
            if (Vector3.Dot(w, cross) < 0) {
                sign = 1.0;
            }

            dot = Vector3.Dot(u, u1);
            dot = (Math.min(1.0, Math.max(-1.0, dot))); // to force dot to be in the range [-1, 1]
            roll = Math.acos(dot) * sign;

            if (Vector3.Dot(u1, X) < 0) { // checks X orientation
                roll = Math.PI + roll;
                u1 = u1.scaleInPlace(-1);
                nbRevert++;
            }

            // step 2 : rotate around u1
            // Ru1(w1) = Ru1(w) = w2, and w2 belongs to plane xOz
            // u1 is yet in xOz and invariant by Ru1, so after this step u1 and w2 will be in xOz
            var w2: Vector3 = Tmp.VECTOR3[2];
            var v2: Vector3 = Tmp.VECTOR3[3];
            x = 0.0;
            y = 0.0;
            z = 0.0;
            sign = -1.0;
            if (MathTools.WithinEpsilon(w.z, 0, MathTools.Epsilon)) {
                x = 1.0;
            }
            else {
                t = u1.z / u1.x;
                x = - t * Math.sqrt(1 / (1 + t * t));
                z = Math.sqrt(1 / (1 + t * t));
            }

            w2.x = x;
            w2.y = y;
            w2.z = z;
            w2.normalize();
            Vector3.CrossToRef(w2, u1, v2);   // v2 image of v1 through rotation around u1
            v2.normalize();
            Vector3.CrossToRef(w, w2, cross); // returns same direction as u1 (=local x) if positive angle : cross(source, image)
            cross.normalize();
            if (Vector3.Dot(u1, cross) < 0) {
                sign = 1.0;
            }

            dot = Vector3.Dot(w, w2);
            dot = (Math.min(1.0, Math.max(-1.0, dot))); // to force dot to be in the range [-1, 1]
            pitch = Math.acos(dot) * sign;
            if (Vector3.Dot(v2, Y) < 0) { // checks for Y orientation
                pitch = Math.PI + pitch;
                nbRevert++;
            }

            // step 3 : rotate around v2
            // Rv2(u1) = X, same as Rv2(w2) = Z, with X=(1,0,0) and Z=(0,0,1)
            sign = -1.0;
            Vector3.CrossToRef(X, u1, cross); // returns same direction as Y if positive angle : cross(source, image)
            cross.normalize();
            if (Vector3.Dot(cross, Y) < 0) {
                sign = 1.0;
            }
            dot = Vector3.Dot(u1, X);
            dot = (Math.min(1.0, Math.max(-1.0, dot))); // to force dot to be in the range [-1, 1]
            yaw = - Math.acos(dot) * sign;         // negative : plane zOx oriented clockwise
            if (dot < 0 && nbRevert < 2) {
                yaw = Math.PI + yaw;
            }

            ref.x = pitch;
            ref.y = yaw;
            ref.z = roll;
        }
    }
}
