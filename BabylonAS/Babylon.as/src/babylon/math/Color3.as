package babylon.math {
    public class Color3 {
        public var r:Number;
        public var g:Number;
        public var b:Number;

        public function Color3(r:Number = 0, g:Number = 0, b:Number = 0) {
            this.r = r;
            this.g = g;
            this.b = b;
        }

        public function toString():String {
            return "{R: " + this.r + " G:" + this.g + " B:" + this.b + "}";
        }

        public function getClassName():String {
            return "Color3";
        }

        public function getHashCode():Number {
            var hash:Number = this.r || 0;
            hash = (hash * 397) ^ (this.g || 0);
            hash = (hash * 397) ^ (this.b || 0);
            return hash;
        }

        // Operators
        public function toArray(array:Vector.<Number>, index:int = 0): Color3 {
            array[index] = this.r;
            array[index + 1] = this.g;
            array[index + 2] = this.b;

            return this;
        }

        public function toColor4(alpha:Number = 1): Color4 {
            return new Color4(this.r, this.g, this.b, alpha);
        }

        public function asArray():Vector.<Number> {
            var result:Vector.<Number> = new <Number>[];

            toArray(result, 0);

            return result;
        }

        public function toLuminance():Number {
            return this.r * 0.3 + this.g * 0.59 + this.b * 0.11;
        }

        public function multiply(otherColor: Color3): Color3 {
            return new Color3(this.r * otherColor.r, this.g * otherColor.g, this.b * otherColor.b);
        }

        public function multiplyToRef(otherColor: Color3, result: Color3): Color3 {
            result.r = this.r * otherColor.r;
            result.g = this.g * otherColor.g;
            result.b = this.b * otherColor.b;

            return this;
        }

        public function equals(otherColor: Color3):Boolean {
            return otherColor && this.r === otherColor.r && this.g === otherColor.g && this.b === otherColor.b;
        }

        public function equalsFloats(r:Number, g:Number, b:Number):Boolean {
            return this.r === r && this.g === g && this.b === b;
        }

        public function scale(scale:Number): Color3 {
            return new Color3(this.r * scale, this.g * scale, this.b * scale);
        }

        public function scaleToRef(scale:Number, result: Color3): Color3 {
            result.r = this.r * scale;
            result.g = this.g * scale;
            result.b = this.b * scale;

            return this;
        }

        public function add(otherColor: Color3): Color3 {
            return new Color3(this.r + otherColor.r, this.g + otherColor.g, this.b + otherColor.b);
        }

        public function addToRef(otherColor: Color3, result: Color3): Color3 {
            result.r = this.r + otherColor.r;
            result.g = this.g + otherColor.g;
            result.b = this.b + otherColor.b;

            return this;
        }

        public function subtract(otherColor: Color3): Color3 {
            return new Color3(this.r - otherColor.r, this.g - otherColor.g, this.b - otherColor.b);
        }

        public function subtractToRef(otherColor: Color3, result: Color3): Color3 {
            result.r = this.r - otherColor.r;
            result.g = this.g - otherColor.g;
            result.b = this.b - otherColor.b;

            return this;
        }

        public function clone(): Color3 {
            return new Color3(this.r, this.g, this.b);
        }

        public function copyFrom(source: Color3): Color3 {
            this.r = source.r;
            this.g = source.g;
            this.b = source.b;

            return this;
        }

        public function copyFromFloats(r:Number, g:Number, b:Number): Color3 {
            this.r = r;
            this.g = g;
            this.b = b;

            return this;
        }

        public function toHexString():String {
            var intR:uint = (this.r * 255) | 0;
            var intG:uint = (this.g * 255) | 0;
            var intB:uint = (this.b * 255) | 0;

            return "#" + intR.toString(16) + intG.toString(16) + intB.toString(16);
        }

//        public function toLinearSpace():Color3 {
//            var convertedColor:Color3 = new Color3();
//            toLinearSpaceToRef(convertedColor);
//            return convertedColor;
//        }

//    public function toLinearSpaceToRef(convertedColor:Color3):Color3 {
//        convertedColor.r = Math.pow(r, ToLinearSpace);
//        convertedColor.g = Math.pow(g, ToLinearSpace);
//        convertedColor.b = Math.pow(b, ToLinearSpace);
//
//        return this;
//    }

//        public function toGammaSpace():Color3 {
//            var convertedColor:Color3 = new Color3();
//            toGammaSpaceToRef(convertedColor);
//            return convertedColor;
//        }

//    public function toGammaSpaceToRef(convertedColor:Color3):Color3 {
//        convertedColor.r = Math.pow(r, ToGammaSpace);
//        convertedColor.g = Math.pow(g, ToGammaSpace);
//        convertedColor.b = Math.pow(b, ToGammaSpace);
//
//        return this;
//    }

        // Statics
        public static function FromHexString(hex:String):Color3 {
            if (hex.substring(0, 1) !== "#" || hex.length !== 7) {
                //Tools.Warn("Color3.FromHexString must be called with a string like #FFFFFF");
                return new Color3(0, 0, 0);
            }

            var r:uint = parseInt(hex.substring(1, 3), 16);
            var g:uint = parseInt(hex.substring(3, 5), 16);
            var b:uint = parseInt(hex.substring(5, 7), 16);

            return Color3.FromInts(r, g, b);
        }

        public static function FromArray(array:Vector.<Number>, offset:Number = 0):Color3 {
            return new Color3(array[offset], array[offset + 1], array[offset + 2]);
        }

        public static function FromInts(r:Number, g:Number, b:Number):Color3 {
            return new Color3(r / 255.0, g / 255.0, b / 255.0);
        }

        public static function Lerp(start:Color3, end:Color3, amount:Number):Color3 {
            var r:Number = start.r + ((end.r - start.r) * amount);
            var g:Number = start.g + ((end.g - start.g) * amount);
            var b:Number = start.b + ((end.b - start.b) * amount);

            return new Color3(r, g, b);
        }

        public static function Red():Color3 { return new Color3(1, 0, 0); }
        public static function Green():Color3 { return new Color3(0, 1, 0); }
        public static function Blue():Color3 { return new Color3(0, 0, 1); }
        public static function Black():Color3 { return new Color3(0, 0, 0); }
        public static function White():Color3 { return new Color3(1, 1, 1); }
        public static function Purple():Color3 { return new Color3(0.5, 0, 0.5); }
        public static function Magenta():Color3 { return new Color3(1, 0, 1); }
        public static function Yellow():Color3 { return new Color3(1, 1, 0); }
        public static function Gray():Color3 { return new Color3(0.5, 0.5, 0.5); }
    }
}
