/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.zip.scene {
    import flash.events.MouseEvent;

    public class PointerInfoBase {
        public var type: int;
        public var event: MouseEvent;

        public function PointerInfoBase(type: int, event: MouseEvent) {
            this.type = type;
            this.event = event;
        }
    }
}
