/**
 * Created by caijingxiao on 2016/11/15.
 */
package babylon.animations {
    public class AnimationEvent {
        public var isDone: Boolean = false;

        public var frame: int;
        public var action: Function;
        public var onlyOnce: Boolean;

        public function AnimationEvent(frame: int, action: Function, onlyOnce: Boolean = false) {
            this.frame = frame;
            this.action = action;
            this.onlyOnce = onlyOnce;
        }
    }
}
