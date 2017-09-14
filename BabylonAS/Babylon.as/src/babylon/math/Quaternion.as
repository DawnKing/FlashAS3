package babylon.math {
    public class Quaternion {
        public var x: Number;
        public var y: Number;
        public var z: Number;
        public var w: Number;

        public function Quaternion(x: Number = 0, y: Number = 0, z: Number = 0, w: Number = 1) {
            this.x = x;
            this.y = y;
            this.z = z;
            this.w = w;
        }

        public function toString(): String {
            return "{X: " + this.x + " Y:" + this.y + " Z:" + this.z + " W:" + this.w + "}";
        }

        public function getClassName(): String {
            return "Quaternion";
        }

        public function getHashCode(): Number {
            var hash:Number = this.x || 0;
            hash = (hash * 397) ^ (this.y || 0);
            hash = (hash * 397) ^ (this.z || 0);
            hash = (hash * 397) ^ (this.w || 0);
            return hash;
        }

        public function asArray(): Vector.<Number> {
            return new <Number>[this.x, this.y, this.z, this.w];
        }

        public function equals(otherQuaternion: Quaternion): Boolean {
            return otherQuaternion && this.x === otherQuaternion.x && this.y === otherQuaternion.y && this.z === otherQuaternion.z && this.w === otherQuaternion.w;
        }

        public function clone(): Quaternion {
            return new Quaternion(this.x, this.y, this.z, this.w);
        }

        public function copyFrom(other: Quaternion): Quaternion {
            this.x = other.x;
            this.y = other.y;
            this.z = other.z;
            this.w = other.w;

            return this;
        }

        public function copyFromFloats(x: Number, y: Number, z: Number, w: Number): Quaternion {
            this.x = x;
            this.y = y;
            this.z = z;
            this.w = w;

            return this;
        }

        public function add(other: Quaternion): Quaternion {
            return new Quaternion(this.x + other.x, this.y + other.y, this.z + other.z, this.w + other.w);
        }

        public function subtract(other: Quaternion): Quaternion {
            return new Quaternion(this.x - other.x, this.y - other.y, this.z - other.z, this.w - other.w);
        }

        public function scale(value: Number): Quaternion {
            return new Quaternion(this.x * value, this.y * value, this.z * value, this.w * value);
        }

        public function multiply(q1: Quaternion): Quaternion {
            var result: Quaternion = new Quaternion(0, 0, 0, 1.0);

            this.multiplyToRef(q1, result);

            return result;
        }

        public function multiplyToRef(q1: Quaternion, result: Quaternion): Quaternion {
            var x: Number = this.x * q1.w + this.y * q1.z - this.z * q1.y + this.w * q1.x;
            var y: Number = -this.x * q1.z + this.y * q1.w + this.z * q1.x + this.w * q1.y;
            var z: Number = this.x * q1.y - this.y * q1.x + this.z * q1.w + this.w * q1.z;
            var w: Number = -this.x * q1.x - this.y * q1.y - this.z * q1.z + this.w * q1.w;
            result.copyFromFloats(x, y, z, w);

            return this;
        }

        public function multiplyInPlace(q1: Quaternion): Quaternion {
            this.multiplyToRef(q1, this);

            return this;
        }

        public function conjugateToRef(ref: Quaternion): Quaternion {
            ref.copyFromFloats(-this.x, -this.y, -this.z, this.w);
            return this;
        }

        public function conjugateInPlace(): Quaternion {
            this.x *= -1;
            this.y *= -1;
            this.z *= -1;
            return this;
        }

        public function conjugate(): Quaternion {
            var result: Quaternion = new Quaternion(-this.x, -this.y, -this.z, this.w);
            return result;
        }

        public function length(): Number {
            return Math.sqrt((this.x * this.x) + (this.y * this.y) + (this.z * this.z) + (this.w * this.w));
        }

        public function normalize(): Quaternion {
            var length: Number = 1.0 / this.length();
            this.x *= length;
            this.y *= length;
            this.z *= length;
            this.w *= length;

            return this;
        }

        public function toEulerAngles(order: String = "YZX"): Vector3 {
            var result: Vector3 = Vector3.Zero();

            this.toEulerAnglesToRef(result, order);

            return result;
        }

        public function toEulerAnglesToRef(result: Vector3, order: String = "YZX"): Quaternion {
            var heading: Number, attitude: Number, bank: Number;
            var x: Number = this.x, y: Number = this.y, z: Number = this.z, w: Number = this.w;

            switch (order) {
                case "YZX":
                    var test: Number = x * y + z * w;
                    if (test > 0.499) { // singularity at north pole
                        heading = 2 * Math.atan2(x, w);
                        attitude = Math.PI / 2;
                        bank = 0;
                    }
                    if (test < -0.499) { // singularity at south pole
                        heading = -2 * Math.atan2(x, w);
                        attitude = - Math.PI / 2;
                        bank = 0;
                    }
                    if (isNaN(heading)) {
                        var sqx: Number = x * x;
                        var sqy: Number = y * y;
                        var sqz: Number = z * z;
                        heading = Math.atan2(2 * y * w - 2 * x * z, 1 - 2 * sqy - 2 * sqz); // Heading
                        attitude = Math.asin(2 * test); // attitude
                        bank = Math.atan2(2 * x * w - 2 * y * z, 1 - 2 * sqx - 2 * sqz); // bank
                    }
                    break;
                default:
                    throw new Error("Euler order " + order + " not supported yet.");
            }

            result.y = heading;
            result.z = attitude;
            result.x = bank;

            return this;
        }

        public function toRotationMatrix(result: Matrix): Quaternion {
            var xx: Number = this.x * this.x;
            var yy: Number = this.y * this.y;
            var zz: Number = this.z * this.z;
            var xy: Number = this.x * this.y;
            var zw: Number = this.z * this.w;
            var zx: Number = this.z * this.x;
            var yw: Number = this.y * this.w;
            var yz: Number = this.y * this.z;
            var xw: Number = this.x * this.w;

            result.m[0] = 1.0 - (2.0 * (yy + zz));
            result.m[1] = 2.0 * (xy + zw);
            result.m[2] = 2.0 * (zx - yw);
            result.m[3] = 0;
            result.m[4] = 2.0 * (xy - zw);
            result.m[5] = 1.0 - (2.0 * (zz + xx));
            result.m[6] = 2.0 * (yz + xw);
            result.m[7] = 0;
            result.m[8] = 2.0 * (zx + yw);
            result.m[9] = 2.0 * (yz - xw);
            result.m[10] = 1.0 - (2.0 * (yy + xx));
            result.m[11] = 0;
            result.m[12] = 0;
            result.m[13] = 0;
            result.m[14] = 0;
            result.m[15] = 1.0;

            return this;
        }

        public function fromRotationMatrix(matrix: Matrix): Quaternion {
            Quaternion.FromRotationMatrixToRef(matrix, this);
            return this;
        }

        // Statics

        public static function FromRotationMatrix(matrix: Matrix): Quaternion {
            var result: Quaternion = new Quaternion();
            Quaternion.FromRotationMatrixToRef(matrix, result);
            return result;
        }

        public static function FromRotationMatrixToRef(matrix: Matrix, result: Quaternion): void {
            var data: Vector.<Number> = matrix.m;
            var m11: Number = data[0], m12: Number = data[4], m13: Number = data[8];
            var m21: Number = data[1], m22: Number = data[5], m23: Number = data[9];
            var m31: Number = data[2], m32: Number = data[6], m33: Number = data[10];
            var trace: Number = m11 + m22 + m33;
            var s: Number;

            if (trace > 0) {

                s = 0.5 / Math.sqrt(trace + 1.0);

                result.w = 0.25 / s;
                result.x = (m32 - m23) * s;
                result.y = (m13 - m31) * s;
                result.z = (m21 - m12) * s;
            } else if (m11 > m22 && m11 > m33) {

                s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33);

                result.w = (m32 - m23) / s;
                result.x = 0.25 * s;
                result.y = (m12 + m21) / s;
                result.z = (m13 + m31) / s;
            } else if (m22 > m33) {

                s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33);

                result.w = (m13 - m31) / s;
                result.x = (m12 + m21) / s;
                result.y = 0.25 * s;
                result.z = (m23 + m32) / s;
            } else {

                s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22);

                result.w = (m21 - m12) / s;
                result.x = (m13 + m31) / s;
                result.y = (m23 + m32) / s;
                result.z = 0.25 * s;
            }
        }

        public static function Inverse(q: Quaternion): Quaternion {
            return new Quaternion(-q.x, -q.y, -q.z, q.w);
        }

        public static function Identity(): Quaternion {
            return new Quaternion(0, 0, 0, 1);
        }

        public static function RotationAxis(axis: Vector3, angle: Number): Quaternion {
            return Quaternion.RotationAxisToRef(axis, angle, new Quaternion());
        }

        public static function RotationAxisToRef(axis: Vector3, angle: Number, result: Quaternion): Quaternion {
            var sin: Number = Math.sin(angle / 2);

            axis.normalize();

            result.w = Math.cos(angle / 2);
            result.x = axis.x * sin;
            result.y = axis.y * sin;
            result.z = axis.z * sin;

            return result;
        }

        public static function FromArray(array: Array, offset: Number = undefined): Quaternion {
            if (!offset) {
                offset = 0;
            }

            return new Quaternion(array[offset], array[offset + 1], array[offset + 2], array[offset + 3]);
        }

        public static function RotationYawPitchRoll(yaw: Number, pitch: Number, roll: Number): Quaternion {
            var q: Quaternion = new Quaternion();
            Quaternion.RotationYawPitchRollToRef(yaw, pitch, roll, q);
            return q;
        }

        public static function RotationYawPitchRollToRef(yaw: Number, pitch: Number, roll: Number, result: Quaternion): void {
            // Produces a quaternion from Euler angles in the z-y-x orientation (Tait-Bryan angles)
            var halfRoll: Number = roll * 0.5;
            var halfPitch: Number = pitch * 0.5;
            var halfYaw: Number = yaw * 0.5;

            var sinRoll: Number = Math.sin(halfRoll);
            var cosRoll: Number = Math.cos(halfRoll);
            var sinPitch: Number = Math.sin(halfPitch);
            var cosPitch: Number = Math.cos(halfPitch);
            var sinYaw: Number = Math.sin(halfYaw);
            var cosYaw: Number = Math.cos(halfYaw);

            result.x = (cosYaw * sinPitch * cosRoll) + (sinYaw * cosPitch * sinRoll);
            result.y = (sinYaw * cosPitch * cosRoll) - (cosYaw * sinPitch * sinRoll);
            result.z = (cosYaw * cosPitch * sinRoll) - (sinYaw * sinPitch * cosRoll);
            result.w = (cosYaw * cosPitch * cosRoll) + (sinYaw * sinPitch * sinRoll);
        }

        public static function RotationAlphaBetaGamma(alpha: Number, beta: Number, gamma: Number): Quaternion {
            var result: Quaternion = new Quaternion();
            Quaternion.RotationAlphaBetaGammaToRef(alpha, beta, gamma, result);
            return result;
        }

        public static function RotationAlphaBetaGammaToRef(alpha: Number, beta: Number, gamma: Number, result: Quaternion): void {
            // Produces a quaternion from Euler angles in the z-x-z orientation
            var halfGammaPlusAlpha: Number = (gamma + alpha) * 0.5;
            var halfGammaMinusAlpha: Number = (gamma - alpha) * 0.5;
            var halfBeta: Number = beta * 0.5;

            result.x = Math.cos(halfGammaMinusAlpha) * Math.sin(halfBeta);
            result.y = Math.sin(halfGammaMinusAlpha) * Math.sin(halfBeta);
            result.z = Math.sin(halfGammaPlusAlpha) * Math.cos(halfBeta);
            result.w = Math.cos(halfGammaPlusAlpha) * Math.cos(halfBeta);
        }

        public static function Slerp(left: Quaternion, right: Quaternion, amount: Number): Quaternion {
            var num2: Number;
            var num3: Number;
            var num: Number = amount;
            var num4: Number = (((left.x * right.x) + (left.y * right.y)) + (left.z * right.z)) + (left.w * right.w);
            var flag: Boolean = false;

            if (num4 < 0) {
                flag = true;
                num4 = -num4;
            }

            if (num4 > 0.999999) {
                num3 = 1 - num;
                num2 = flag ? -num : num;
            }
            else {
                var num5: Number = Math.acos(num4);
                var num6: Number = (1.0 / Math.sin(num5));
                num3 = (Math.sin((1.0 - num) * num5)) * num6;
                num2 = flag ? ((-Math.sin(num * num5)) * num6) : ((Math.sin(num * num5)) * num6);
            }

            return new Quaternion((num3 * left.x) + (num2 * right.x), (num3 * left.y) + (num2 * right.y), (num3 * left.z) + (num2 * right.z), (num3 * left.w) + (num2 * right.w));
        }
    }
}
