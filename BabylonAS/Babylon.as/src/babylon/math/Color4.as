/**
 * Created by caijingxiao on 2016/10/19.
 */
package babylon.math {
    public class Color4 {
        public var r: Number;
        public var g: Number;
        public var b: Number;
        public var a: Number;

        public function Color4(r: Number, g: Number, b: Number, a: Number) {
            this.r = r;
            this.g = g;
            this.b = b;
            this.a = a;
        }

        // Operators
        public function addInPlace(right: Color4): Color4 {
            this.r += right.r;
            this.g += right.g;
            this.b += right.b;
            this.a += right.a;

            return this;
        }

        public function asArray(): Vector.<Number> {
            var result: Vector.<Number> = new <Number>[];

            this.toArray(result, 0);

            return result;
        }

        public function toArray(array: Vector.<Number>, index: int = 0): Color4 {
            array[index] = this.r;
            array[index + 1] = this.g;
            array[index + 2] = this.b;
            array[index + 3] = this.a;

            return this;
        }

        public function add(right: Color4): Color4 {
            return new Color4(this.r + right.r, this.g + right.g, this.b + right.b, this.a + right.a);
        }

        public function subtract(right: Color4): Color4 {
            return new Color4(this.r - right.r, this.g - right.g, this.b - right.b, this.a - right.a);
        }

        public function subtractToRef(right: Color4, result: Color4): Color4 {
            result.r = this.r - right.r;
            result.g = this.g - right.g;
            result.b = this.b - right.b;
            result.a = this.a - right.a;

            return this;
        }

        public function scale(scale: Number): Color4 {
            return new Color4(this.r * scale, this.g * scale, this.b * scale, this.a * scale);
        }

        public function scaleToRef(scale: Number, result: Color4): Color4 {
            result.r = this.r * scale;
            result.g = this.g * scale;
            result.b = this.b * scale;
            result.a = this.a * scale;

            return this;
        }

        /**
         * Multipy an RGBA Color4 value by another and return a new Color4 object
         * @param color The Color4 (RGBA) value to multiply by
         * @returns A new Color4.
         */
        public function multiply(color: Color4): Color4 {
            return new Color4(this.r * color.r, this.g * color.g, this.b * color.b, this.a * color.a);
        }

        /**
         * Multipy an RGBA Color4 value by another and push the result in a reference value
         * @param color The Color4 (RGBA) value to multiply by
         * @param result The Color4 (RGBA) to fill the result in
         * @returns the result Color4.
         */
        public function multiplyToRef(color: Color4, result: Color4): Color4 {
            result.r = this.r * color.r;
            result.g = this.g * color.g;
            result.b = this.b * color.b;
            result.a = this.a * color.a;

            return result;
        }

        public function toString(): String {
            return "{R: " + this.r + " G:" + this.g + " B:" + this.b + " A:" + this.a + "}";
        }

        public function getClassName(): String {
            return "Color4";
        }

        public function getHashCode(): Number {
            var hash: Number = this.r || 0;
            hash = (hash * 397) ^ (this.g || 0);
            hash = (hash * 397) ^ (this.b || 0);
            hash = (hash * 397) ^ (this.a || 0);
            return hash;
        }

        public function clone(): Color4 {
            return new Color4(this.r, this.g, this.b, this.a);
        }

        public function copyFrom(source: Color4): Color4 {
            this.r = source.r;
            this.g = source.g;
            this.b = source.b;
            this.a = source.a;

            return this;
        }

        public function toHexString(): String {
            var intR: Number = (this.r * 255) | 0;
            var intG: Number = (this.g * 255) | 0;
            var intB: Number = (this.b * 255) | 0;
            var intA: Number = (this.a * 255) | 0;

            return "#" + MathTools.ToHex(intR) + MathTools.ToHex(intG) + MathTools.ToHex(intB) + MathTools.ToHex(intA);
        }

        // Statics
        public static function FromHexString(hex: String): Color4 {
            if (hex.substring(0, 1) !== "#" || hex.length !== 9) {
                //Tools.Warn("Color4.FromHexString must be called with a String like #FFFFFFFF");
                return new Color4(0, 0, 0, 0);
            }

            var r: int = parseInt(hex.substring(1, 3), 16);
            var g: int = parseInt(hex.substring(3, 5), 16);
            var b: int = parseInt(hex.substring(5, 7), 16);
            var a: int = parseInt(hex.substring(7, 9), 16);

            return Color4.FromInts(r, g, b, a);
        }

        public static function Lerp(left: Color4, right: Color4, amount: Number): Color4 {
            var result: Color4 = new Color4(0, 0, 0, 0);

            Color4.LerpToRef(left, right, amount, result);

            return result;
        }

        public static function LerpToRef(left: Color4, right: Color4, amount: Number, result: Color4): void {
            result.r = left.r + (right.r - left.r) * amount;
            result.g = left.g + (right.g - left.g) * amount;
            result.b = left.b + (right.b - left.b) * amount;
            result.a = left.a + (right.a - left.a) * amount;
        }

        public static function FromArray(array: Vector.<Number>, offset: Number = 0): Color4 {
            return new Color4(array[offset], array[offset + 1], array[offset + 2], array[offset + 3]);
        }

        public static function FromInts(r: Number, g: Number, b: Number, a: Number): Color4 {
            return new Color4(r / 255.0, g / 255.0, b / 255.0, a / 255.0);
        }

        public static function CheckColors4(colors: Vector.<Number>, count: Number): Vector.<Number> {
            // Check if color3 was used
            if (colors.length === count * 3) {
                var colors4: Vector.<Number> = new <Number>[];
                for (var index: int = 0; index < colors.length; index += 3) {
                    var newIndex: int = (index / 3) * 4;
                    colors4[newIndex] = colors[index];
                    colors4[newIndex + 1] = colors[index + 1];
                    colors4[newIndex + 2] = colors[index + 2];
                    colors4[newIndex + 3] = 1.0;
                }

                return colors4;
            }

            return colors;
        }
    }
}
