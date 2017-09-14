/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.zip.scene {
    import babylon.math.Vector2;

    import flash.events.MouseEvent;

    /**
     * This class is used to store pointer related info for the onPrePointerObservable event.
     * Set the skipOnPointerObservable property to true if you want the engine to stop any process after this event is triggered, even not calling onPointerObservable
     */
    public class PointerInfoPre extends PointerInfoBase {
        public function PointerInfoPre(type: int, event: MouseEvent, localX: Number, localY: Number) {
            super(type, event);
            this.skipOnPointerObservable = false;
            this.localPosition = new Vector2(localX, localY);
        }

        public var localPosition: Vector2;
        public var skipOnPointerObservable: Boolean;
    }
}
