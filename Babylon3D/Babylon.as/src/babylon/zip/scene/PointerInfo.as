/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.zip.scene {
    import flash.events.MouseEvent;

    public class PointerInfo extends PointerInfoBase {
        public var pickInfo: Object;

        public function PointerInfo(type: int, event: MouseEvent, pickInfo: Object) {
            super(type, event);
            this.pickInfo = pickInfo;
        }
    }
}
