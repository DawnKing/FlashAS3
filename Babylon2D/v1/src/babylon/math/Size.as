/**
 * Created by caijingxiao on 2016/11/15.
 */
package babylon.math {
    public class Size {
        public var width: Number;
        public var height: Number;

        public function Size(width: Number, height: Number) {
            this.width = width;
            this.height = height;
        }

        public function toString(): String {
            return "{W: "+ this.width + ", H: "+ this.height + "}";
        }

        public function getClassName(): String {
            return "Size";
        }

        public function getHashCode(): Number {
            var hash: Number = this.width || 0;
            hash = (hash * 397) ^ (this.height || 0);
            return hash;
        }

        public function copyFrom(src: Size): void {
            this.width = src.width;
            this.height = src.height;
        }

        public function copyFromFloats(width: Number, height: Number): void {
            this.width = width;
            this.height = height;
        }

        public function multiplyByFloats(w: Number, h: Number): Size {
            return new Size(this.width * w, this.height * h);
        }

        public function clone(): Size {
            return new Size(this.width, this.height);
        }

        public function equals(other: Size): Boolean {
            if (!other) {
                return false;
            }

            return (this.width === other.width) && (this.height === other.height);
        }

        public function get surface(): Number {
            return this.width * this.height;
        }

        public static function Zero(): Size {
            return new Size(0, 0);
        }

        public function add(otherSize: Size): Size {
            var r: Size = new Size(this.width + otherSize.width, this.height + otherSize.height);
            return r;
        }

        public function substract(otherSize: Size): Size {
            var r: Size = new Size(this.width - otherSize.width, this.height - otherSize.height);
            return r;
        }

        public static function Lerp(start: Size, end: Size, amount: Number): Size {
            var w: Number = start.width + ((end.width - start.width) * amount);
            var h: Number = start.height + ((end.height - start.height) * amount);

            return new Size(w, h);
        }

    }
}
