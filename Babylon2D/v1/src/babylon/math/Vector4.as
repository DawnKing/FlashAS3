package babylon.math {
    public class Vector4 {
        public var x: Number;
        public var y: Number;
        public var z: Number;
        public var w: Number;

        public function Vector4(x: Number, y: Number, z: Number, w: Number) {
            this.x = x;
            this.y = y;
            this.z = z;
            this.w = w;
        }

        public function toString(): String {
            return "{X: " + this.x + " Y:" + this.y + " Z:" + this.z + "W:" + this.w + "}";
        }

        public function getClassName(): String {
            return "Vector4";
        }

        public function getHashCode(): Number {
            var hash: Number = this.x || 0;
            hash = (hash * 397) ^ (this.y || 0);
            hash = (hash * 397) ^ (this.z || 0);
            hash = (hash * 397) ^ (this.w || 0);
            return hash;
        }

        // Operators
        public function asArray(): Vector.<Number> {
            var result:Vector.<Number> = new <Number>[];

            this.toArray(result, 0);

            return result;
        }

        public function toArray(array: Vector.<Number>, index: int = 0): Vector4 {
            array[index] = this.x;
            array[index + 1] = this.y;
            array[index + 2] = this.z;
            array[index + 3] = this.w;

            return this;
        }

        public function addInPlace(otherVector: Vector4): Vector4 {
            this.x += otherVector.x;
            this.y += otherVector.y;
            this.z += otherVector.z;
            this.w += otherVector.w;

            return this;
        }

        public function add(otherVector: Vector4): Vector4 {
            return new Vector4(this.x + otherVector.x, this.y + otherVector.y, this.z + otherVector.z, this.w + otherVector.w);
        }

        public function addToRef(otherVector: Vector4, result: Vector4): Vector4 {
            result.x = this.x + otherVector.x;
            result.y = this.y + otherVector.y;
            result.z = this.z + otherVector.z;
            result.w = this.w + otherVector.w;

            return this;
        }

        public function subtractInPlace(otherVector: Vector4): Vector4 {
            this.x -= otherVector.x;
            this.y -= otherVector.y;
            this.z -= otherVector.z;
            this.w -= otherVector.w;

            return this;
        }

        public function subtract(otherVector: Vector4): Vector4 {
            return new Vector4(this.x - otherVector.x, this.y - otherVector.y, this.z - otherVector.z, this.w - otherVector.w);
        }

        public function subtractToRef(otherVector: Vector4, result: Vector4): Vector4 {
            result.x = this.x - otherVector.x;
            result.y = this.y - otherVector.y;
            result.z = this.z - otherVector.z;
            result.w = this.w - otherVector.w;

            return this;
        }

        public function subtractFromFloats(x: Number, y: Number, z: Number, w: Number): Vector4 {
            return new Vector4(this.x - x, this.y - y, this.z - z, this.w - w);
        }

        public function subtractFromFloatsToRef(x: Number, y: Number, z: Number, w: Number, result: Vector4): Vector4 {
            result.x = this.x - x;
            result.y = this.y - y;
            result.z = this.z - z;
            result.w = this.w - w;

            return this;
        }

        public function negate(): Vector4 {
            return new Vector4(-this.x, -this.y, -this.z, -this.w);
        }

        public function scaleInPlace(scale: Number): Vector4 {
            this.x *= scale;
            this.y *= scale;
            this.z *= scale;
            this.w *= scale;
            return this;
        }

        public function scale(scale: Number): Vector4 {
            return new Vector4(this.x * scale, this.y * scale, this.z * scale, this.w * scale);
        }

        public function scaleToRef(scale: Number, result: Vector4): void {
            result.x = this.x * scale;
            result.y = this.y * scale;
            result.z = this.z * scale;
            result.w = this.w * scale;
        }

        public function equals(otherVector: Vector4): Boolean {
            return otherVector && this.x === otherVector.x && this.y === otherVector.y && this.z === otherVector.z && this.w === otherVector.w;
        }

        public function equalsWithEpsilon(otherVector: Vector4, epsilon: Number = MathTools.Epsilon): Boolean {
            return otherVector
                    && MathTools.WithinEpsilon(this.x, otherVector.x, epsilon)
                    && MathTools.WithinEpsilon(this.y, otherVector.y, epsilon)
                    && MathTools.WithinEpsilon(this.z, otherVector.z, epsilon)
                    && MathTools.WithinEpsilon(this.w, otherVector.w, epsilon);
        }

        public function equalsToFloats(x: Number, y: Number, z: Number, w: Number): Boolean {
            return this.x === x && this.y === y && this.z === z && this.w === w;
        }

        public function multiplyInPlace(otherVector: Vector4): Vector4 {
            this.x *= otherVector.x;
            this.y *= otherVector.y;
            this.z *= otherVector.z;
            this.w *= otherVector.w;

            return this;
        }

        public function multiply(otherVector: Vector4): Vector4 {
            return new Vector4(this.x * otherVector.x, this.y * otherVector.y, this.z * otherVector.z, this.w * otherVector.w);
        }

        public function multiplyToRef(otherVector: Vector4, result: Vector4): Vector4 {
            result.x = this.x * otherVector.x;
            result.y = this.y * otherVector.y;
            result.z = this.z * otherVector.z;
            result.w = this.w * otherVector.w;

            return this;
        }

        public function multiplyByFloats(x: Number, y: Number, z: Number, w: Number): Vector4 {
            return new Vector4(this.x * x, this.y * y, this.z * z, this.w * w);
        }

        public function divide(otherVector: Vector4): Vector4 {
            return new Vector4(this.x / otherVector.x, this.y / otherVector.y, this.z / otherVector.z, this.w / otherVector.w);
        }

        public function divideToRef(otherVector: Vector4, result: Vector4): Vector4 {
            result.x = this.x / otherVector.x;
            result.y = this.y / otherVector.y;
            result.z = this.z / otherVector.z;
            result.w = this.w / otherVector.w;

            return this;
        }

        public function MinimizeInPlace(other: Vector4): Vector4 {
            if (other.x < this.x) this.x = other.x;
            if (other.y < this.y) this.y = other.y;
            if (other.z < this.z) this.z = other.z;
            if (other.w < this.w) this.w = other.w;

            return this;
        }

        public function MaximizeInPlace(other: Vector4): Vector4 {
            if (other.x > this.x) this.x = other.x;
            if (other.y > this.y) this.y = other.y;
            if (other.z > this.z) this.z = other.z;
            if (other.w > this.w) this.w = other.w;

            return this;
        }

        // Properties
        public function length(): Number {
            return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
        }

        public function lengthSquared(): Number {
            return (this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
        }

        // Methods
        public function normalize(): Vector4 {
            var len: Number = this.length();

            if (len === 0)
                return this;

            var num: Number = 1.0 / len;

            this.x *= num;
            this.y *= num;
            this.z *= num;
            this.w *= num;

            return this;
        }

        public function toVector3(): Vector3 {
            return new Vector3(this.x, this.y, this.z);
        }

        public function clone(): Vector4 {
            return new Vector4(this.x, this.y, this.z, this.w);
        }

        public function copyFrom(source: Vector4): Vector4 {
            this.x = source.x;
            this.y = source.y;
            this.z = source.z;
            this.w = source.w;

            return this;
        }

        public function copyFromFloats(x: Number, y: Number, z: Number, w: Number): Vector4 {
            this.x = x;
            this.y = y;
            this.z = z;
            this.w = w;

            return this;
        }

        // Statics
        public static function FromArray(array: Vector.<Number>, offset: Number = undefined): Vector4 {
            if (!offset) {
                offset = 0;
            }

            return new Vector4(array[offset], array[offset + 1], array[offset + 2], array[offset + 3]);
        }

        public static function FromArrayToRef(array: Vector.<Number>, offset: Number, result: Vector4): void {
            result.x = array[offset];
            result.y = array[offset + 1];
            result.z = array[offset + 2];
            result.w = array[offset + 3];
        }

        public static function FromFloatArrayToRef(array: Vector.<Number>, offset: Number, result: Vector4): void {
            result.x = array[offset];
            result.y = array[offset + 1];
            result.z = array[offset + 2];
            result.w = array[offset + 3];
        }

        public static function FromFloatsToRef(x: Number, y: Number, z: Number, w: Number, result: Vector4): void {
            result.x = x;
            result.y = y;
            result.z = z;
            result.w = w;
        }

        public static function Zero(): Vector4 {
            return new Vector4(0, 0, 0, 0);
        }

        public static function Normalize(vector: Vector4): Vector4 {
            var result: Vector4 = Vector4.Zero();
            Vector4.NormalizeToRef(vector, result);
            return result;
        }

        public static function NormalizeToRef(vector: Vector4, result: Vector4): void {
            result.copyFrom(vector);
            result.normalize();
        }

        public static function Minimize(left: Vector4, right: Vector4): Vector4 {
            var min: Vector4 = left.clone();
            min.MinimizeInPlace(right);
            return min;
        }

        public static function Maximize(left: Vector4, right: Vector4): Vector4 {
            var max: Vector4 = left.clone();
            max.MaximizeInPlace(right);
            return max;
        }

        public static function Distance(value1: Vector4, value2: Vector4): Number {
            return Math.sqrt(Vector4.DistanceSquared(value1, value2));
        }

        public static function DistanceSquared(value1: Vector4, value2: Vector4): Number {
            var x: Number = value1.x - value2.x;
            var y: Number = value1.y - value2.y;
            var z: Number = value1.z - value2.z;
            var w: Number = value1.w - value2.w;

            return (x * x) + (y * y) + (z * z) + (w * w);
        }

        public static function Center(value1: Vector4, value2: Vector4): Vector4 {
            var center: Vector4 = value1.add(value2);
            center.scaleInPlace(0.5);
            return center;
        }
    }
}
