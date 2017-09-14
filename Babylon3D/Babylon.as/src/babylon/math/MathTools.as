/**
 * Created by caijingxiao on 2016/10/17.
 */
package babylon.math {
    public class MathTools {
        public static const SPACE_LOCAL: int = 0;
        public static const SPACE_WORLD: int = 1;

        public static const ToGammaSpace: Number = 1 / 2.2;
        public static const ToLinearSpace: Number = 2.2;
        public static const Epsilon: Number = 0.001;

        public static function WithinEpsilon(a: Number, b: Number, epsilon: Number = 1.401298E-45): Boolean {
            var num: Number = a - b;
            return -epsilon <= num && num <= epsilon;
        }

        public static function ToHex(i: Number): String {
            var str: String = i.toString(16);

            if (i <= 15) {
                return ("0" + str).toUpperCase();
            }

            return str.toUpperCase();
        }

        // Returns -1 when value is a negative number and
        // +1 when value is a positive number.
        public static function Sign(value: Number): Number {
            value = +value; // convert to a Number

            if (value === 0 || isNaN(value))
                return value;

            return value > 0 ? 1 : -1;
        }

        public static function Clamp(value: Number, min: Number = 0, max: Number = 1): Number {
            return Math.min(max, Math.max(min, value));
        }
    }
}
