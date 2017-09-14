/**
 * Created by caijingxiao on 2016/10/19.
 */
package babylon.math {
    public class Vector2 {
        public var x: Number;
        public var y: Number;
        public function Vector2(x: Number, y: Number) {
            this.x = x;
            this.y = y;
        }

        public function toString(): String {
            return "{X: " + this.x + " Y:" + this.y + "}";
        }

        public function getClassName(): String {
            return "Vector2";
        }

        public function getHashCode(): Number {
            var hash: Number = this.x || 0;
            hash = (hash * 397) ^ (this.y || 0);
            return hash;
        }

        // Operators
        public function toArray(array: Vector.<Number>, index: Number = 0): Vector2 {
            array[index] = this.x;
            array[index + 1] = this.y;

            return this;
        }

        public function asArray(): Vector.<Number> {
            var result: Vector.<Number> = new <Number>[];

            this.toArray(result, 0);

            return result;
        }

        public function copyFrom(source: Vector2): Vector2 {
            this.x = source.x;
            this.y = source.y;

            return this;
        }

        public function copyFromFloats(x: Number, y: Number): Vector2 {
            this.x = x;
            this.y = y;

            return this;
        }

        public function add(otherVector: Vector2): Vector2 {
            return new Vector2(this.x + otherVector.x, this.y + otherVector.y);
        }

        public function addToRef(otherVector: Vector2, result: Vector2): Vector2 {
            result.x = this.x + otherVector.x;
            result.y = this.y + otherVector.y;

            return this;
        }

        public function addInPlace(otherVector: Vector2): Vector2 {
            this.x += otherVector.x;
            this.y += otherVector.y;

            return this;
        }

        public function addVector3(otherVector: Vector3): Vector2 {
            return new Vector2(this.x + otherVector.x, this.y + otherVector.y);
        }

        public function subtract(otherVector: Vector2): Vector2 {
            return new Vector2(this.x - otherVector.x, this.y - otherVector.y);
        }

        public function subtractToRef(otherVector: Vector2, result: Vector2): Vector2 {
            result.x = this.x - otherVector.x;
            result.y = this.y - otherVector.y;

            return this;
        }

        public function subtractInPlace(otherVector: Vector2): Vector2 {
            this.x -= otherVector.x;
            this.y -= otherVector.y;

            return this;
        }

        public function multiplyInPlace(otherVector: Vector2): Vector2 {
            this.x *= otherVector.x;
            this.y *= otherVector.y;

            return this;
        }

        public function multiply(otherVector: Vector2): Vector2 {
            return new Vector2(this.x * otherVector.x, this.y * otherVector.y);
        }

        public function multiplyToRef(otherVector: Vector2, result: Vector2): Vector2 {
            result.x = this.x * otherVector.x;
            result.y = this.y * otherVector.y;

            return this;
        }

        public function multiplyByFloats(x: Number, y: Number): Vector2 {
            return new Vector2(this.x * x, this.y * y);
        }

        public function divide(otherVector: Vector2): Vector2 {
            return new Vector2(this.x / otherVector.x, this.y / otherVector.y);
        }

        public function divideToRef(otherVector: Vector2, result: Vector2): Vector2 {
            result.x = this.x / otherVector.x;
            result.y = this.y / otherVector.y;

            return this;
        }

        public function negate(): Vector2 {
            return new Vector2(-this.x, -this.y);
        }

        public function scaleInPlace(scale: Number): Vector2 {
            this.x *= scale;
            this.y *= scale;
            return this;
        }

        public function scale(scale: Number): Vector2 {
            return new Vector2(this.x * scale, this.y * scale);
        }

        public function equals(otherVector: Vector2): Boolean {
            return otherVector && this.x === otherVector.x && this.y === otherVector.y;
        }

        public function equalsWithEpsilon(otherVector: Vector2, epsilon: Number = MathTools.Epsilon): Boolean {
            return otherVector && MathTools.WithinEpsilon(this.x, otherVector.x, epsilon) && MathTools.WithinEpsilon(this.y, otherVector.y, epsilon);
        }

        // Properties
        public function length(): Number {
            return Math.sqrt(this.x * this.x + this.y * this.y);
        }

        public function lengthSquared(): Number {
            return (this.x * this.x + this.y * this.y);
        }

        // Methods
        public function normalize(): Vector2 {
            var len: Number = this.length();

            if (len === 0)
                return this;

            var num: Number = 1.0 / len;

            this.x *= num;
            this.y *= num;

            return this;
        }

        public function clone(): Vector2 {
            return new Vector2(this.x, this.y);
        }

        // Statics
        public static function Zero(): Vector2 {
            return new Vector2(0, 0);
        }

        public static function FromArray(array: Vector.<Number>, offset: Number = 0): Vector2 {
            return new Vector2(array[offset], array[offset + 1]);
        }

        public static function FromArrayToRef(array: Vector.<Number>, offset: Number, result: Vector2): void {
            result.x = array[offset];
            result.y = array[offset + 1];
        }

        public static function CatmullRom(value1: Vector2, value2: Vector2, value3: Vector2, value4: Vector2, amount: Number): Vector2 {
            var squared: Number = amount * amount;
            var cubed: Number = amount * squared;

            var x: Number = 0.5 * ((((2.0 * value2.x) + ((-value1.x + value3.x) * amount)) +
                    (((((2.0 * value1.x) - (5.0 * value2.x)) + (4.0 * value3.x)) - value4.x) * squared)) +
                    ((((-value1.x + (3.0 * value2.x)) - (3.0 * value3.x)) + value4.x) * cubed));

            var y: Number = 0.5 * ((((2.0 * value2.y) + ((-value1.y + value3.y) * amount)) +
                    (((((2.0 * value1.y) - (5.0 * value2.y)) + (4.0 * value3.y)) - value4.y) * squared)) +
                    ((((-value1.y + (3.0 * value2.y)) - (3.0 * value3.y)) + value4.y) * cubed));

            return new Vector2(x, y);
        }

        public static function Clamp(value: Vector2, min: Vector2, max: Vector2): Vector2 {
            var x: Number = value.x;
            x = (x > max.x) ? max.x : x;
            x = (x < min.x) ? min.x : x;

            var y: Number = value.y;
            y = (y > max.y) ? max.y : y;
            y = (y < min.y) ? min.y : y;

            return new Vector2(x, y);
        }

        public static function Hermite(value1: Vector2, tangent1: Vector2, value2: Vector2, tangent2: Vector2, amount: Number): Vector2 {
            var squared: Number = amount * amount;
            var cubed: Number = amount * squared;
            var part1: Number = ((2.0 * cubed) - (3.0 * squared)) + 1.0;
            var part2: Number = (-2.0 * cubed) + (3.0 * squared);
            var part3: Number = (cubed - (2.0 * squared)) + amount;
            var part4: Number = cubed - squared;

            var x: Number = (((value1.x * part1) + (value2.x * part2)) + (tangent1.x * part3)) + (tangent2.x * part4);
            var y: Number = (((value1.y * part1) + (value2.y * part2)) + (tangent1.y * part3)) + (tangent2.y * part4);

            return new Vector2(x, y);
        }

        public static function Lerp(start: Vector2, end: Vector2, amount: Number): Vector2 {
            var x: Number = start.x + ((end.x - start.x) * amount);
            var y: Number = start.y + ((end.y - start.y) * amount);

            return new Vector2(x, y);
        }


        public static function Dot(left: Vector2, right: Vector2): Number {
            return left.x * right.x + left.y * right.y;
        }

        public static function Normalize(vector: Vector2): Vector2 {
            var newVector: Vector2 = vector.clone();
            newVector.normalize();
            return newVector;
        }

        public static function Minimize(left: Vector2, right: Vector2): Vector2 {
            var x: Number = (left.x < right.x) ? left.x : right.x;
            var y: Number = (left.y < right.y) ? left.y : right.y;

            return new Vector2(x, y);
        }

        public static function Maximize(left: Vector2, right: Vector2): Vector2 {
            var x: Number = (left.x > right.x) ? left.x : right.x;
            var y: Number = (left.y > right.y) ? left.y : right.y;

            return new Vector2(x, y);
        }

        public static function Transform(vector: Vector2, transformation: Matrix): Vector2 {
            var r: Vector2 = Vector2.Zero();
            Vector2.TransformToRef(vector, transformation, r);
            return r;
        }

        public static function TransformToRef(vector: Vector2, transformation: Matrix, result: Vector2): void {
            var x: Number = (vector.x * transformation.m[0]) + (vector.y * transformation.m[4]) + transformation.m[12];
            var y: Number = (vector.x * transformation.m[1]) + (vector.y * transformation.m[5]) + transformation.m[13];

            result.x = x;
            result.y = y;
        }

        public static function PointInTriangle(p: Vector2, p0: Vector2, p1: Vector2, p2: Vector2): Boolean {
            var a: Number = 1 / 2 * (-p1.y * p2.x + p0.y * (-p1.x + p2.x) + p0.x * (p1.y - p2.y) + p1.x * p2.y);
            var sign: int = a < 0 ? -1 : 1;
            var s: Number = (p0.y * p2.x - p0.x * p2.y + (p2.y - p0.y) * p.x + (p0.x - p2.x) * p.y) * sign;
            var t: Number = (p0.x * p1.y - p0.y * p1.x + (p0.y - p1.y) * p.x + (p1.x - p0.x) * p.y) * sign;

            return s > 0 && t > 0 && (s + t) < 2 * a * sign;
        }

        public static function Distance(value1: Vector2, value2: Vector2): Number {
            return Math.sqrt(Vector2.DistanceSquared(value1, value2));
        }

        public static function DistanceSquared(value1: Vector2, value2: Vector2): Number {
            var x: Number = value1.x - value2.x;
            var y: Number = value1.y - value2.y;

            return (x * x) + (y * y);
        }

        public static function Center(value1: Vector2, value2: Vector2): Vector2 {
            var center: Vector2 = value1.add(value2);
            center.scaleInPlace(0.5);
            return center;
        }

        public static function DistanceOfPointFromSegment(p: Vector2, segA: Vector2, segB: Vector2): Number {
            var l2: Number = Vector2.DistanceSquared(segA, segB);
            if (l2 === 0.0) {
                return Vector2.Distance(p, segA);
            }
            var v: Vector2 = segB.subtract(segA);
            var t: Number = Math.max(0, Math.min(1, Vector2.Dot(p.subtract(segA), v) / l2));
            var proj: Vector2 = segA.add(v.multiplyByFloats(t, t));
            return Vector2.Distance(p, proj);
        }
    }
}
