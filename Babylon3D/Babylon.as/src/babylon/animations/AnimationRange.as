/**
 * Created by caijingxiao on 2016/11/15.
 */
package babylon.animations {
    public class AnimationRange {
        public var name: String;
        public var from: int;
        public var to: int;

        public function AnimationRange(name: String, from: int, to: int) {
            this.name = name;
            this.from = from;
            this.to = to;
        }

        public function clone(): AnimationRange {
            return new AnimationRange(this.name, this.from, this.to);
        }
    }
}
