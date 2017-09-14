package babylon.math {
    public class Viewport {
        public var x: Number;
        public var y: Number;
        public var width: Number;
        public var height: Number;

        public function Viewport(x: Number, y: Number, width: Number, height: Number) {
            this.x = x;
            this.y = y;
            this.width = width;
            this.height = height;
        }

        public function toGlobal(renderWidth: Number, renderHeight: Number): Viewport {
            return new Viewport(this.x * renderWidth, this.y * renderHeight, this.width * renderWidth, this.height * renderHeight);
        }
    }
}
