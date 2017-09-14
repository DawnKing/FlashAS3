package babylon.math {
    public class Matrix {
        private static var _tempQuaternion:Quaternion = new Quaternion();
        private static var _xAxis:Vector3 = Vector3.Zero();
        private static var _yAxis:Vector3 = Vector3.Zero();
        private static var _zAxis:Vector3 = Vector3.Zero();

        public var m:Vector.<Number> = new Vector.<Number>(16);

        // Properties
        public function isIdentity(): Boolean {
            if (this.m[0] !== 1.0 || this.m[5] !== 1.0 || this.m[10] !== 1.0 || this.m[15] !== 1.0)
                return false;

            if (this.m[1] !== 0.0 || this.m[2] !== 0.0 || this.m[3] !== 0.0 ||
                    this.m[4] !== 0.0 || this.m[6] !== 0.0 || this.m[7] !== 0.0 ||
                    this.m[8] !== 0.0 || this.m[9] !== 0.0 || this.m[11] !== 0.0 ||
                    this.m[12] !== 0.0 || this.m[13] !== 0.0 || this.m[14] !== 0.0)
                return false;

            return true;
        }

        public function determinant(): Number {
            var temp1: Number = (this.m[10] * this.m[15]) - (this.m[11] * this.m[14]);
            var temp2: Number = (this.m[9] * this.m[15]) - (this.m[11] * this.m[13]);
            var temp3: Number = (this.m[9] * this.m[14]) - (this.m[10] * this.m[13]);
            var temp4: Number = (this.m[8] * this.m[15]) - (this.m[11] * this.m[12]);
            var temp5: Number = (this.m[8] * this.m[14]) - (this.m[10] * this.m[12]);
            var temp6: Number = (this.m[8] * this.m[13]) - (this.m[9] * this.m[12]);

            return ((((this.m[0] * (((this.m[5] * temp1) - (this.m[6] * temp2)) + (this.m[7] * temp3))) - (this.m[1] * (((this.m[4] * temp1) -
            (this.m[6] * temp4)) + (this.m[7] * temp5)))) + (this.m[2] * (((this.m[4] * temp2) - (this.m[5] * temp4)) + (this.m[7] * temp6)))) -
            (this.m[3] * (((this.m[4] * temp3) - (this.m[5] * temp5)) + (this.m[6] * temp6))));
        }

        // Methods
        public function toArray(): Vector.<Number> {
            return this.m;
        }

        public function asArray(): Vector.<Number> {
            return this.toArray();
        }

        public function invert(): Matrix {
            this.invertToRef(this);

            return this;
        }

        public function reset(): Matrix {
            for (var index: int = 0; index < 16; index++) {
                this.m[index] = 0;
            }

            return this;
        }

        public function add(other: Matrix): Matrix {
            var result: Matrix = new Matrix();

            this.addToRef(other, result);

            return result;
        }

        public function addToRef(other: Matrix, result: Matrix): Matrix {
            for (var index: int = 0; index < 16; index++) {
                result.m[index] = this.m[index] + other.m[index];
            }

            return this;
        }

        public function addToSelf(other: Matrix): Matrix {
            for (var index: int = 0; index < 16; index++) {
                this.m[index] += other.m[index];
            }

            return this;
        }

        public function invertToRef(other: Matrix): Matrix {
            var l1: Number = this.m[0];
            var l2: Number = this.m[1];
            var l3: Number = this.m[2];
            var l4: Number = this.m[3];
            var l5: Number = this.m[4];
            var l6: Number = this.m[5];
            var l7: Number = this.m[6];
            var l8: Number = this.m[7];
            var l9: Number = this.m[8];
            var l10: Number = this.m[9];
            var l11: Number = this.m[10];
            var l12: Number = this.m[11];
            var l13: Number = this.m[12];
            var l14: Number = this.m[13];
            var l15: Number = this.m[14];
            var l16: Number = this.m[15];
            var l17: Number = (l11 * l16) - (l12 * l15);
            var l18: Number = (l10 * l16) - (l12 * l14);
            var l19: Number = (l10 * l15) - (l11 * l14);
            var l20: Number = (l9 * l16) - (l12 * l13);
            var l21: Number = (l9 * l15) - (l11 * l13);
            var l22: Number = (l9 * l14) - (l10 * l13);
            var l23: Number = ((l6 * l17) - (l7 * l18)) + (l8 * l19);
            var l24: Number = -(((l5 * l17) - (l7 * l20)) + (l8 * l21));
            var l25: Number = ((l5 * l18) - (l6 * l20)) + (l8 * l22);
            var l26: Number = -(((l5 * l19) - (l6 * l21)) + (l7 * l22));
            var l27: Number = 1.0 / ((((l1 * l23) + (l2 * l24)) + (l3 * l25)) + (l4 * l26));
            var l28: Number = (l7 * l16) - (l8 * l15);
            var l29: Number = (l6 * l16) - (l8 * l14);
            var l30: Number = (l6 * l15) - (l7 * l14);
            var l31: Number = (l5 * l16) - (l8 * l13);
            var l32: Number = (l5 * l15) - (l7 * l13);
            var l33: Number = (l5 * l14) - (l6 * l13);
            var l34: Number = (l7 * l12) - (l8 * l11);
            var l35: Number = (l6 * l12) - (l8 * l10);
            var l36: Number = (l6 * l11) - (l7 * l10);
            var l37: Number = (l5 * l12) - (l8 * l9);
            var l38: Number = (l5 * l11) - (l7 * l9);
            var l39: Number = (l5 * l10) - (l6 * l9);

            other.m[0] = l23 * l27;
            other.m[4] = l24 * l27;
            other.m[8] = l25 * l27;
            other.m[12] = l26 * l27;
            other.m[1] = -(((l2 * l17) - (l3 * l18)) + (l4 * l19)) * l27;
            other.m[5] = (((l1 * l17) - (l3 * l20)) + (l4 * l21)) * l27;
            other.m[9] = -(((l1 * l18) - (l2 * l20)) + (l4 * l22)) * l27;
            other.m[13] = (((l1 * l19) - (l2 * l21)) + (l3 * l22)) * l27;
            other.m[2] = (((l2 * l28) - (l3 * l29)) + (l4 * l30)) * l27;
            other.m[6] = -(((l1 * l28) - (l3 * l31)) + (l4 * l32)) * l27;
            other.m[10] = (((l1 * l29) - (l2 * l31)) + (l4 * l33)) * l27;
            other.m[14] = -(((l1 * l30) - (l2 * l32)) + (l3 * l33)) * l27;
            other.m[3] = -(((l2 * l34) - (l3 * l35)) + (l4 * l36)) * l27;
            other.m[7] = (((l1 * l34) - (l3 * l37)) + (l4 * l38)) * l27;
            other.m[11] = -(((l1 * l35) - (l2 * l37)) + (l4 * l39)) * l27;
            other.m[15] = (((l1 * l36) - (l2 * l38)) + (l3 * l39)) * l27;

            return this;
        }

        public function setTranslation(vector3: Vector3): Matrix {
            this.m[12] = vector3.x;
            this.m[13] = vector3.y;
            this.m[14] = vector3.z;

            return this;
        }

        public function getTranslation(): Vector3 {
            return new Vector3(this.m[12], this.m[13], this.m[14]);
        }

        public function multiply(other: Matrix): Matrix {
            var result: Matrix = new Matrix();

            this.multiplyToRef(other, result);

            return result;
        }

        public function copyFrom(other: Matrix): Matrix {
            for (var index: int = 0; index < 16; index++) {
                this.m[index] = other.m[index];
            }

            return this;
        }

        public function copyToArray(array: Vector.<Number>, offset: Number = 0): Matrix {
            for (var index: int = 0; index < 16; index++) {
                array[offset + index] = this.m[index];
            }

            return this;
        }

        public function multiplyToRef(other: Matrix, result: Matrix): Matrix {
            this.multiplyToArray(other, result.m, 0);

            return this;
        }

        public function multiplyToArray(other: Matrix, result: Vector.<Number>, offset: Number): Matrix {
            var tm0: Number = this.m[0];
            var tm1: Number = this.m[1];
            var tm2: Number = this.m[2];
            var tm3: Number = this.m[3];
            var tm4: Number = this.m[4];
            var tm5: Number = this.m[5];
            var tm6: Number = this.m[6];
            var tm7: Number = this.m[7];
            var tm8: Number = this.m[8];
            var tm9: Number = this.m[9];
            var tm10: Number = this.m[10];
            var tm11: Number = this.m[11];
            var tm12: Number = this.m[12];
            var tm13: Number = this.m[13];
            var tm14: Number = this.m[14];
            var tm15: Number = this.m[15];

            var om0: Number = other.m[0];
            var om1: Number = other.m[1];
            var om2: Number = other.m[2];
            var om3: Number = other.m[3];
            var om4: Number = other.m[4];
            var om5: Number = other.m[5];
            var om6: Number = other.m[6];
            var om7: Number = other.m[7];
            var om8: Number = other.m[8];
            var om9: Number = other.m[9];
            var om10: Number = other.m[10];
            var om11: Number = other.m[11];
            var om12: Number = other.m[12];
            var om13: Number = other.m[13];
            var om14: Number = other.m[14];
            var om15: Number = other.m[15];

            result[offset] = tm0 * om0 + tm1 * om4 + tm2 * om8 + tm3 * om12;
            result[offset + 1] = tm0 * om1 + tm1 * om5 + tm2 * om9 + tm3 * om13;
            result[offset + 2] = tm0 * om2 + tm1 * om6 + tm2 * om10 + tm3 * om14;
            result[offset + 3] = tm0 * om3 + tm1 * om7 + tm2 * om11 + tm3 * om15;

            result[offset + 4] = tm4 * om0 + tm5 * om4 + tm6 * om8 + tm7 * om12;
            result[offset + 5] = tm4 * om1 + tm5 * om5 + tm6 * om9 + tm7 * om13;
            result[offset + 6] = tm4 * om2 + tm5 * om6 + tm6 * om10 + tm7 * om14;
            result[offset + 7] = tm4 * om3 + tm5 * om7 + tm6 * om11 + tm7 * om15;

            result[offset + 8] = tm8 * om0 + tm9 * om4 + tm10 * om8 + tm11 * om12;
            result[offset + 9] = tm8 * om1 + tm9 * om5 + tm10 * om9 + tm11 * om13;
            result[offset + 10] = tm8 * om2 + tm9 * om6 + tm10 * om10 + tm11 * om14;
            result[offset + 11] = tm8 * om3 + tm9 * om7 + tm10 * om11 + tm11 * om15;

            result[offset + 12] = tm12 * om0 + tm13 * om4 + tm14 * om8 + tm15 * om12;
            result[offset + 13] = tm12 * om1 + tm13 * om5 + tm14 * om9 + tm15 * om13;
            result[offset + 14] = tm12 * om2 + tm13 * om6 + tm14 * om10 + tm15 * om14;
            result[offset + 15] = tm12 * om3 + tm13 * om7 + tm14 * om11 + tm15 * om15;

            return this;
        }

        public function equals(value: Matrix): Boolean {
            return value &&
                    (this.m[0] === value.m[0] && this.m[1] === value.m[1] && this.m[2] === value.m[2] && this.m[3] === value.m[3] &&
                    this.m[4] === value.m[4] && this.m[5] === value.m[5] && this.m[6] === value.m[6] && this.m[7] === value.m[7] &&
                    this.m[8] === value.m[8] && this.m[9] === value.m[9] && this.m[10] === value.m[10] && this.m[11] === value.m[11] &&
                    this.m[12] === value.m[12] && this.m[13] === value.m[13] && this.m[14] === value.m[14] && this.m[15] === value.m[15]);
        }

        public function clone(): Matrix {
            return Matrix.FromValues(this.m[0], this.m[1], this.m[2], this.m[3],
                    this.m[4], this.m[5], this.m[6], this.m[7],
                    this.m[8], this.m[9], this.m[10], this.m[11],
                    this.m[12], this.m[13], this.m[14], this.m[15]);
        }

        public function getClassName(): String {
            return "Matrix";
        }

        public function getHashCode(): Number {
            var hash: Number = this.m[0] || 0;
            for (var i: int = 1; i < 16; i++) {
                hash = (hash * 397) ^ (this.m[i] || 0);
            }
            return hash;
        }

        public function decompose(scale: Vector3, rotation: Quaternion, translation: Vector3): Boolean {
            translation.x = this.m[12];
            translation.y = this.m[13];
            translation.z = this.m[14];

            var xs: Number = MathTools.Sign(this.m[0] * this.m[1] * this.m[2] * this.m[3]) < 0 ? -1 : 1;
            var ys: Number = MathTools.Sign(this.m[4] * this.m[5] * this.m[6] * this.m[7]) < 0 ? -1 : 1;
            var zs: Number = MathTools.Sign(this.m[8] * this.m[9] * this.m[10] * this.m[11]) < 0 ? -1 : 1;

            scale.x = xs * Math.sqrt(this.m[0] * this.m[0] + this.m[1] * this.m[1] + this.m[2] * this.m[2]);
            scale.y = ys * Math.sqrt(this.m[4] * this.m[4] + this.m[5] * this.m[5] + this.m[6] * this.m[6]);
            scale.z = zs * Math.sqrt(this.m[8] * this.m[8] + this.m[9] * this.m[9] + this.m[10] * this.m[10]);

            if (scale.x === 0 || scale.y === 0 || scale.z === 0) {
                rotation.x = 0;
                rotation.y = 0;
                rotation.z = 0;
                rotation.w = 1;
                return false;
            }

            Matrix.FromValuesToRef(
                    this.m[0] / scale.x, this.m[1] / scale.x, this.m[2] / scale.x, 0,
                    this.m[4] / scale.y, this.m[5] / scale.y, this.m[6] / scale.y, 0,
                    this.m[8] / scale.z, this.m[9] / scale.z, this.m[10] / scale.z, 0,
                    0, 0, 0, 1, Tmp.MATRIX[0]);

            Quaternion.FromRotationMatrixToRef(Tmp.MATRIX[0], rotation);

            return true;
        }

        // Statics
        public static function FromArray(array: Vector.<Number>, offset: Number = undefined): Matrix {
            var result: Matrix = new Matrix();

            if (!offset) {
                offset = 0;
            }

            Matrix.FromArrayToRef(array, offset, result);

            return result;
        }

        public static function FromArrayToRef(array: Vector.<Number>, offset: Number, result: Matrix): void {
            for (var index: int = 0; index < 16; index++) {
                result.m[index] = array[index + offset];
            }
        }

        public static function FromFloatArrayToRef(array: Vector.<Number>, offset: Number, scale: Number, result: Matrix): void {
            for (var index: int = 0; index < 16; index++) {
                result.m[index] = array[index + offset] * scale;
            }
        }

        public static function FromValuesToRef(initialM11: Number, initialM12: Number, initialM13: Number, initialM14: Number,
                                               initialM21: Number, initialM22: Number, initialM23: Number, initialM24: Number,
                                               initialM31: Number, initialM32: Number, initialM33: Number, initialM34: Number,
                                               initialM41: Number, initialM42: Number, initialM43: Number, initialM44: Number, result: Matrix): void {

            result.m[0] = initialM11;
            result.m[1] = initialM12;
            result.m[2] = initialM13;
            result.m[3] = initialM14;
            result.m[4] = initialM21;
            result.m[5] = initialM22;
            result.m[6] = initialM23;
            result.m[7] = initialM24;
            result.m[8] = initialM31;
            result.m[9] = initialM32;
            result.m[10] = initialM33;
            result.m[11] = initialM34;
            result.m[12] = initialM41;
            result.m[13] = initialM42;
            result.m[14] = initialM43;
            result.m[15] = initialM44;
        }

        public function getRow(index: Number): Vector4 {
            if (index < 0 || index > 3) {
                return null;
            }

            var i: int = index * 4;
            return new Vector4(this.m[i + 0], this.m[i + 1], this.m[i + 2], this.m[i + 3]);
        }

        public function setRow(index: Number, row: Vector4): Matrix {
            if (index < 0 || index > 3) {
                return this;
            }

            var i: int = index * 4;
            this.m[i + 0] = row.x;
            this.m[i + 1] = row.y;
            this.m[i + 2] = row.z;
            this.m[i + 3] = row.w;

            return this;
        }

        public static function FromValues(initialM11: Number, initialM12: Number, initialM13: Number, initialM14: Number,
                                          initialM21: Number, initialM22: Number, initialM23: Number, initialM24: Number,
                                          initialM31: Number, initialM32: Number, initialM33: Number, initialM34: Number,
                                          initialM41: Number, initialM42: Number, initialM43: Number, initialM44: Number): Matrix {

            var result: Matrix = new Matrix();

            result.m[0] = initialM11;
            result.m[1] = initialM12;
            result.m[2] = initialM13;
            result.m[3] = initialM14;
            result.m[4] = initialM21;
            result.m[5] = initialM22;
            result.m[6] = initialM23;
            result.m[7] = initialM24;
            result.m[8] = initialM31;
            result.m[9] = initialM32;
            result.m[10] = initialM33;
            result.m[11] = initialM34;
            result.m[12] = initialM41;
            result.m[13] = initialM42;
            result.m[14] = initialM43;
            result.m[15] = initialM44;

            return result;
        }

        public static function Compose(scale: Vector3, rotation: Quaternion, translation: Vector3): Matrix {
            var result: Matrix = Matrix.FromValues(scale.x, 0, 0, 0,
                    0, scale.y, 0, 0,
                    0, 0, scale.z, 0,
                    0, 0, 0, 1);

            var rotationMatrix: Matrix = Matrix.Identity();
            rotation.toRotationMatrix(rotationMatrix);
            result = result.multiply(rotationMatrix);

            result.setTranslation(translation);

            return result;
        }

        public static function Identity(): Matrix {
            return Matrix.FromValues(1.0, 0, 0, 0,
                    0, 1.0, 0, 0,
                    0, 0, 1.0, 0,
                    0, 0, 0, 1.0);
        }

        public static function IdentityToRef(result: Matrix): void {
            Matrix.FromValuesToRef(1.0, 0, 0, 0,
                    0, 1.0, 0, 0,
                    0, 0, 1.0, 0,
                    0, 0, 0, 1.0, result);
        }

        public static function Zero(): Matrix {
            return Matrix.FromValues(0, 0, 0, 0,
                    0, 0, 0, 0,
                    0, 0, 0, 0,
                    0, 0, 0, 0);
        }

        public static function RotationX(angle: Number): Matrix {
            var result: Matrix = new Matrix();

            Matrix.RotationXToRef(angle, result);

            return result;
        }

        public static function Invert(source: Matrix): Matrix {
            var result: Matrix = new Matrix();

            source.invertToRef(result);

            return result;
        }

        public static function RotationXToRef(angle: Number, result: Matrix): void {
            var s: Number = Math.sin(angle);
            var c: Number = Math.cos(angle);

            result.m[0] = 1.0;
            result.m[15] = 1.0;

            result.m[5] = c;
            result.m[10] = c;
            result.m[9] = -s;
            result.m[6] = s;

            result.m[1] = 0;
            result.m[2] = 0;
            result.m[3] = 0;
            result.m[4] = 0;
            result.m[7] = 0;
            result.m[8] = 0;
            result.m[11] = 0;
            result.m[12] = 0;
            result.m[13] = 0;
            result.m[14] = 0;
        }

        public static function RotationY(angle: Number): Matrix {
            var result: Matrix = new Matrix();

            Matrix.RotationYToRef(angle, result);

            return result;
        }

        public static function RotationYToRef(angle: Number, result: Matrix): void {
            var s: Number = Math.sin(angle);
            var c: Number = Math.cos(angle);

            result.m[5] = 1.0;
            result.m[15] = 1.0;

            result.m[0] = c;
            result.m[2] = -s;
            result.m[8] = s;
            result.m[10] = c;

            result.m[1] = 0;
            result.m[3] = 0;
            result.m[4] = 0;
            result.m[6] = 0;
            result.m[7] = 0;
            result.m[9] = 0;
            result.m[11] = 0;
            result.m[12] = 0;
            result.m[13] = 0;
            result.m[14] = 0;
        }

        public static function RotationZ(angle: Number): Matrix {
            var result: Matrix = new Matrix();

            Matrix.RotationZToRef(angle, result);

            return result;
        }

        public static function RotationZToRef(angle: Number, result: Matrix): void {
            var s: Number = Math.sin(angle);
            var c: Number = Math.cos(angle);

            result.m[10] = 1.0;
            result.m[15] = 1.0;

            result.m[0] = c;
            result.m[1] = s;
            result.m[4] = -s;
            result.m[5] = c;

            result.m[2] = 0;
            result.m[3] = 0;
            result.m[6] = 0;
            result.m[7] = 0;
            result.m[8] = 0;
            result.m[9] = 0;
            result.m[11] = 0;
            result.m[12] = 0;
            result.m[13] = 0;
            result.m[14] = 0;
        }

        public static function RotationAxis(axis: Vector3, angle: Number): Matrix {
            var result: Matrix = Matrix.Zero();
            Matrix.RotationAxisToRef(axis, angle, result);
            return result;
        }

        public static function RotationAxisToRef(axis: Vector3, angle: Number, result: Matrix): void {
            var s: Number = Math.sin(-angle);
            var c: Number = Math.cos(-angle);
            var c1: Number = 1 - c;

            axis.normalize();

            result.m[0] = (axis.x * axis.x) * c1 + c;
            result.m[1] = (axis.x * axis.y) * c1 - (axis.z * s);
            result.m[2] = (axis.x * axis.z) * c1 + (axis.y * s);
            result.m[3] = 0.0;

            result.m[4] = (axis.y * axis.x) * c1 + (axis.z * s);
            result.m[5] = (axis.y * axis.y) * c1 + c;
            result.m[6] = (axis.y * axis.z) * c1 - (axis.x * s);
            result.m[7] = 0.0;

            result.m[8] = (axis.z * axis.x) * c1 - (axis.y * s);
            result.m[9] = (axis.z * axis.y) * c1 + (axis.x * s);
            result.m[10] = (axis.z * axis.z) * c1 + c;
            result.m[11] = 0.0;

            result.m[15] = 1.0;
        }

        public static function RotationYawPitchRoll(yaw: Number, pitch: Number, roll: Number): Matrix {
            var result: Matrix = new Matrix();

            Matrix.RotationYawPitchRollToRef(yaw, pitch, roll, result);

            return result;
        }

        public static function RotationYawPitchRollToRef(yaw: Number, pitch: Number, roll: Number, result: Matrix): void {
            Quaternion.RotationYawPitchRollToRef(yaw, pitch, roll, _tempQuaternion);

            _tempQuaternion.toRotationMatrix(result);
        }

        public static function Scaling(x: Number, y: Number, z: Number): Matrix {
            var result: Matrix = Matrix.Zero();

            Matrix.ScalingToRef(x, y, z, result);

            return result;
        }

        public static function ScalingToRef(x: Number, y: Number, z: Number, result: Matrix): void {
            result.m[0] = x;
            result.m[1] = 0;
            result.m[2] = 0;
            result.m[3] = 0;
            result.m[4] = 0;
            result.m[5] = y;
            result.m[6] = 0;
            result.m[7] = 0;
            result.m[8] = 0;
            result.m[9] = 0;
            result.m[10] = z;
            result.m[11] = 0;
            result.m[12] = 0;
            result.m[13] = 0;
            result.m[14] = 0;
            result.m[15] = 1.0;
        }

        public static function Translation(x: Number, y: Number, z: Number): Matrix {
            var result: Matrix = Matrix.Identity();

            Matrix.TranslationToRef(x, y, z, result);

            return result;
        }

        public static function TranslationToRef(x: Number, y: Number, z: Number, result: Matrix): void {
            Matrix.FromValuesToRef(1.0, 0, 0, 0,
                    0, 1.0, 0, 0,
                    0, 0, 1.0, 0,
                    x, y, z, 1.0, result);
        }

        public static function Lerp(startValue: Matrix, endValue: Matrix, gradient: Number): Matrix {
            var result: Matrix = Matrix.Zero();

            for (var index: int = 0; index < 16; index++) {
                result.m[index] = startValue.m[index] * (1.0 - gradient) + endValue.m[index] * gradient;
            }

            return result;
        }

        public static function DecomposeLerp(startValue: Matrix, endValue: Matrix, gradient: Number): Matrix {
            var startScale: Vector3 = new Vector3(0, 0, 0);
            var startRotation: Quaternion = new Quaternion();
            var startTranslation: Vector3 = new Vector3(0, 0, 0);
            startValue.decompose(startScale, startRotation, startTranslation);

            var endScale: Vector3 = new Vector3(0, 0, 0);
            var endRotation: Quaternion = new Quaternion();
            var endTranslation: Vector3 = new Vector3(0, 0, 0);
            endValue.decompose(endScale, endRotation, endTranslation);

            var resultScale: Vector3 = Vector3.Lerp(startScale, endScale, gradient);
            var resultRotation: Quaternion = Quaternion.Slerp(startRotation, endRotation, gradient);
            var resultTranslation: Vector3 = Vector3.Lerp(startTranslation, endTranslation, gradient);

            return Matrix.Compose(resultScale, resultRotation, resultTranslation);
        }

        public static function LookAtLH(eye: Vector3, target: Vector3, up: Vector3): Matrix {
            var result: Matrix = Matrix.Zero();

            Matrix.LookAtLHToRef(eye, target, up, result);

            return result;
        }

        public static function LookAtLHToRef(eye: Vector3, target: Vector3, up: Vector3, result: Matrix): void {
            // Z axis
            target.subtractToRef(eye, _zAxis);
            _zAxis.normalize();

            // X axis
            Vector3.CrossToRef(up, _zAxis, _xAxis);

            if (_xAxis.lengthSquared() === 0) {
                _xAxis.x = 1.0;
            } else {
                _xAxis.normalize();
            }

            // Y axis
            Vector3.CrossToRef(_zAxis, _xAxis, _yAxis);
            _yAxis.normalize();

            // Eye angles
            var ex: Number = -Vector3.Dot(_xAxis, eye);
            var ey: Number = -Vector3.Dot(_yAxis, eye);
            var ez: Number = -Vector3.Dot(_zAxis, eye);

            return Matrix.FromValuesToRef(_xAxis.x, _yAxis.x, _zAxis.x, 0,
                    _xAxis.y, _yAxis.y, _zAxis.y, 0,
                    _xAxis.z, _yAxis.z, _zAxis.z, 0,
                    ex, ey, ez, 1, result);
        }

        public static function LookAtRH(eye: Vector3, target: Vector3, up: Vector3): Matrix {
            var result: Matrix = Matrix.Zero();

            Matrix.LookAtRHToRef(eye, target, up, result);

            return result;
        }

        public static function LookAtRHToRef(eye: Vector3, target: Vector3, up: Vector3, result: Matrix): void {
            // Z axis
            eye.subtractToRef(target, _zAxis);
            _zAxis.normalize();

            // X axis
            Vector3.CrossToRef(up, _zAxis, _xAxis);

            if (_xAxis.lengthSquared() === 0) {
                _xAxis.x = 1.0;
            } else {
                _xAxis.normalize();
            }

            // Y axis
            Vector3.CrossToRef(_zAxis, _xAxis, _yAxis);
            _yAxis.normalize();

            // Eye angles
            var ex: Number = -Vector3.Dot(_xAxis, eye);
            var ey: Number = -Vector3.Dot(_yAxis, eye);
            var ez: Number = -Vector3.Dot(_zAxis, eye);

            return Matrix.FromValuesToRef(_xAxis.x, _yAxis.x, _zAxis.x, 0,
                    _xAxis.y, _yAxis.y, _zAxis.y, 0,
                    _xAxis.z, _yAxis.z, _zAxis.z, 0,
                    ex, ey, ez, 1, result);
        }

        public static function OrthoLH(width: Number, height: Number, znear: Number, zfar: Number): Matrix {
            var matrix: Matrix = Matrix.Zero();

            Matrix.OrthoLHToRef(width, height, znear, zfar, matrix);

            return matrix;
        }

        public static function OrthoLHToRef(width: Number, height: Number, znear: Number, zfar: Number, result: Matrix): void {
            var n: Number = znear;
            var f: Number = zfar;

            var a: Number = 2.0 / width;
            var b: Number = 2.0 / height;
            var c: Number = 2.0 / (f - n);
            var d: Number = -(f + n)/(f - n);

            FromValuesToRef(
                    a, 0, 0, 0,
                    0, b, 0, 0,
                    0, 0, c, 0,
                    0, 0, d, 1,
                    result
            );
        }

        public static function OrthoOffCenterLH(left: Number, right: Number, bottom: Number, top: Number, znear: Number, zfar: Number): Matrix {
            var matrix: Matrix = Matrix.Zero();

            Matrix.OrthoOffCenterLHToRef(left, right, bottom, top, znear, zfar, matrix);

            return matrix;
        }

        public static function OrthoOffCenterLHToRef(left: Number, right: Number, bottom: Number, top: Number, znear: Number, zfar: Number, result: Matrix): void {
            var n: Number = znear;
            var f: Number = zfar;

            var a: Number = 2.0 / (right - left);
            var b: Number = 2.0 / (top - bottom);
            var c: Number = 2.0 / (f - n);
            var d: Number = -(f + n)/(f - n);
            var i0: Number = (left + right) / (left - right);
            var i1: Number = (top + bottom) / (bottom - top);

            FromValuesToRef(
                    a, 0, 0, 0,
                    0, b, 0, 0,
                    0, 0, c, 0,
                    i0, i1, d, 1,
                    result
            );
        }

        public static function OrthoOffCenterRH(left: Number, right: Number, bottom: Number, top: Number, znear: Number, zfar: Number): Matrix {
            var matrix: Matrix = Matrix.Zero();

            Matrix.OrthoOffCenterRHToRef(left, right, bottom, top, znear, zfar, matrix);

            return matrix;
        }

        public static function OrthoOffCenterRHToRef(left: Number, right: Number, bottom: Number, top: Number, znear: Number, zfar: Number, result: Matrix): void {
            Matrix.OrthoOffCenterLHToRef(left, right, bottom, top, znear, zfar, result);
            result.m[10] *= -1.0;
        }

        public static function PerspectiveLH(width: Number, height: Number, znear: Number, zfar: Number): Matrix {
            var matrix: Matrix = Matrix.Zero();

            var n: Number = znear;
            var f: Number = zfar;

            var a: Number = 2.0 * n / width;
            var b: Number = 2.0 * n / height;
            var c: Number = (f + n)/(f - n);
            var d: Number = -2.0 * f * n/(f - n);

            FromValuesToRef(
                    a, 0, 0, 0,
                    0, b, 0, 0,
                    0, 0, c, 1,
                    0, 0, d, 0,
                    matrix
            );

            return matrix;
        }

        public static function PerspectiveFovLH(fov: Number, aspect: Number, znear: Number, zfar: Number): Matrix {
            var matrix: Matrix = Matrix.Zero();

            Matrix.PerspectiveFovLHToRef(fov, aspect, znear, zfar, matrix);

            return matrix;
        }

        public static function PerspectiveFovLHToRef(fov: Number, aspect: Number, znear: Number, zfar: Number, result: Matrix, isVerticalFovFixed: Boolean = true): void {
            var tan: Number = 1.0 / (Math.tan(fov * 0.5));

            if (isVerticalFovFixed) {
                result.m[0] = tan / aspect;
            }
            else {
                result.m[0] = tan;
            }

            result.m[1] = result.m[2] = result.m[3] = 0.0;

            if (isVerticalFovFixed) {
                result.m[5] = tan;
            }
            else {
                result.m[5] = tan * aspect;
            }

            result.m[4] = result.m[6] = result.m[7] = 0.0;
            result.m[8] = result.m[9] = 0.0;
            result.m[10] = zfar / (zfar - znear);
            result.m[11] = 1.0;
            result.m[12] = result.m[13] = result.m[15] = 0.0;
            result.m[14] = -(znear * zfar) / (zfar - znear);

            // TODO: new code has bug
//            var n: Number = znear;
//            var f: Number = zfar;
//
//            var t: Number = 1.0 / (Math.tan(fov * 0.5));
//            var a: Number = isVerticalFovFixed ? (t / aspect) : t;
//            var b: Number = isVerticalFovFixed ? t : (t * aspect);
//            var c: Number = (f + n)/(f - n);
//            var d: Number = -2.0 * f * n/(f - n);
//
//            FromValuesToRef(
//                    a, 0, 0, 0,
//                    0, b, 0, 0,
//                    0, 0, c, 1,
//                    0, 0, d, 0,
//                    result
//            );
        }

        public static function PerspectiveFovRH(fov: Number, aspect: Number, znear: Number, zfar: Number): Matrix {
            var matrix: Matrix = Matrix.Zero();

            Matrix.PerspectiveFovRHToRef(fov, aspect, znear, zfar, matrix);

            return matrix;
        }

        public static function PerspectiveFovRHToRef(fov: Number, aspect: Number, znear: Number, zfar: Number, result: Matrix, isVerticalFovFixed: Boolean = true): void {
            //alternatively this could be expressed as:
            //    m = PerspectiveFovLHToRef
            //    m[10] *= -1.0;
            //    m[11] *= -1.0;

            var n: Number = znear;
            var f: Number = zfar;

            var t: Number = 1.0 / (Math.tan(fov * 0.5));
            var a: Number = isVerticalFovFixed ? (t / aspect) : t;
            var b: Number = isVerticalFovFixed ? t : (t * aspect);
            var c: Number = -(f + n)/(f - n);
            var d: Number = -2*f*n/(f - n);

            FromValuesToRef(
                    a, 0, 0, 0,
                    0, b, 0, 0,
                    0, 0, c,-1,
                    0, 0, d, 0,
                    result
            );
        }

        public static function PerspectiveFovWebVRToRef(fov: Object, znear: Number, zfar: Number, result: Matrix): void {
            //left handed
            var upTan: Number = Math.tan(fov.upDegrees * Math.PI / 180.0);
            var downTan: Number = Math.tan(fov.downDegrees * Math.PI / 180.0);
            var leftTan: Number = Math.tan(fov.leftDegrees * Math.PI / 180.0);
            var rightTan: Number = Math.tan(fov.rightDegrees * Math.PI / 180.0);
            var xScale: Number = 2.0 / (leftTan + rightTan);
            var yScale: Number = 2.0 / (upTan + downTan);
            result.m[0] = xScale;
            result.m[1] = result.m[2] = result.m[3] = result.m[4] = 0.0;
            result.m[5] = yScale;
            result.m[6] = result.m[7] =  0.0;
            result.m[8] = ((leftTan - rightTan) * xScale * 0.5);
            result.m[9] = -((upTan - downTan) * yScale * 0.5);
            result.m[10] = -(znear + zfar) / (zfar - znear);
            // result.m[10] = -zfar / (znear - zfar);
            result.m[11] = 1.0;
            result.m[12] = result.m[13] = result.m[15] = 0.0;
            result.m[14] = -(2.0 * zfar * znear) / (zfar - znear);
            // result.m[14] = (znear * zfar) / (znear - zfar);
        }

        public static function GetFinalMatrix(viewport: Viewport, world: Matrix, view: Matrix, projection: Matrix, zmin: Number, zmax: Number): Matrix {
            var cw: Number = viewport.width;
            var ch: Number = viewport.height;
            var cx: Number = viewport.x;
            var cy: Number = viewport.y;

            var viewportMatrix: Matrix = Matrix.FromValues(cw / 2.0, 0, 0, 0,
                    0, -ch / 2.0, 0, 0,
                    0, 0, zmax - zmin, 0,
                    cx + cw / 2.0, ch / 2.0 + cy, zmin, 1);

            return world.multiply(view).multiply(projection).multiply(viewportMatrix);
        }

        public static function GetAsMatrix2x2(matrix: Matrix): Vector.<Number> {
            return new <Number>[
                matrix.m[0], matrix.m[1],
                matrix.m[4], matrix.m[5]
            ];
        }

        public static function GetAsMatrix3x3(matrix: Matrix): Vector.<Number> {
            return new <Number>[
                matrix.m[0], matrix.m[1], matrix.m[2],
                matrix.m[4], matrix.m[5], matrix.m[6],
                matrix.m[8], matrix.m[9], matrix.m[10]
            ];
        }

        public static function Transpose(matrix: Matrix): Matrix {
            var result: Matrix = new Matrix();

            result.m[0] = matrix.m[0];
            result.m[1] = matrix.m[4];
            result.m[2] = matrix.m[8];
            result.m[3] = matrix.m[12];

            result.m[4] = matrix.m[1];
            result.m[5] = matrix.m[5];
            result.m[6] = matrix.m[9];
            result.m[7] = matrix.m[13];

            result.m[8] = matrix.m[2];
            result.m[9] = matrix.m[6];
            result.m[10] = matrix.m[10];
            result.m[11] = matrix.m[14];

            result.m[12] = matrix.m[3];
            result.m[13] = matrix.m[7];
            result.m[14] = matrix.m[11];
            result.m[15] = matrix.m[15];

            return result;
        }

        private static var _cacheTranspose: Vector.<Number> = new Vector.<Number>(16, true);
        public static function CacheTransposeMatrices(m: Vector.<Number>): Vector.<Number> {
            _cacheTranspose[0] = m[0];
            _cacheTranspose[1] = m[4];
            _cacheTranspose[2] = m[8];
            _cacheTranspose[3] = m[12];

            _cacheTranspose[4] = m[1];
            _cacheTranspose[5] = m[5];
            _cacheTranspose[6] = m[9];
            _cacheTranspose[7] = m[13];

            _cacheTranspose[8] = m[2];
            _cacheTranspose[9] = m[6];
            _cacheTranspose[10] = m[10];
            _cacheTranspose[11] = m[14];

            _cacheTranspose[12] = m[3];
            _cacheTranspose[13] = m[7];
            _cacheTranspose[14] = m[11];
            _cacheTranspose[15] = m[15];

            return _cacheTranspose;
        }

        public static function Reflection(plane: Plane): Matrix {
            var matrix: Matrix = new Matrix();

            Matrix.ReflectionToRef(plane, matrix);

            return matrix;
        }

        public static function ReflectionToRef(plane: Plane, result: Matrix): void {
            plane.normalize();
            var x: Number = plane.normal.x;
            var y: Number = plane.normal.y;
            var z: Number = plane.normal.z;
            var temp: Number = -2 * x;
            var temp2: Number = -2 * y;
            var temp3: Number = -2 * z;
            result.m[0] = (temp * x) + 1;
            result.m[1] = temp2 * x;
            result.m[2] = temp3 * x;
            result.m[3] = 0.0;
            result.m[4] = temp * y;
            result.m[5] = (temp2 * y) + 1;
            result.m[6] = temp3 * y;
            result.m[7] = 0.0;
            result.m[8] = temp * z;
            result.m[9] = temp2 * z;
            result.m[10] = (temp3 * z) + 1;
            result.m[11] = 0.0;
            result.m[12] = temp * plane.d;
            result.m[13] = temp2 * plane.d;
            result.m[14] = temp3 * plane.d;
            result.m[15] = 1.0;
        }
    }
}
