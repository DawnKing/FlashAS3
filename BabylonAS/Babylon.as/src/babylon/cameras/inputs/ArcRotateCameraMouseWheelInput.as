/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.cameras.inputs {
    import babylon.cameras.ArcRotateCamera;
    import babylon.cameras.Camera;
    import babylon.cameras.ICameraInput;
    import babylon.tools.observable.EventState;
    import babylon.tools.observable.Observer;
    import babylon.zip.scene.PointerEventTypes;
    import babylon.zip.scene.PointerInfo;

    import flash.events.EventDispatcher;
    import flash.events.MouseEvent;

    public class ArcRotateCameraMouseWheelInput implements ICameraInput {
        private var _camera: ArcRotateCamera;

        private var _wheel: Function;   // (p: PointerInfo, s: EventState) => void;
        private var _observer: Observer;

        [Serialize]
        public var wheelPrecision: Number = 1.0;

        public function ArcRotateCameraMouseWheelInput() {
        }

        public function attachControl(element: EventDispatcher, noPreventDefault: Boolean = false): void {
            this._wheel = function (p: PointerInfo, s: EventState): void {
                //sanity check - this should be a PointerWheel event.
                if (p.type !== PointerEventTypes.POINTERWHEEL) return;
                var event: MouseEvent = p.event;
                var delta: Number = 0;
                if (event.delta) {
                    delta = event.delta / wheelPrecision;
                }

                if (delta)
                    _camera.inertialRadiusOffset += delta;

                if (event.preventDefault) {
                    if (!noPreventDefault) {
                        event.preventDefault();
                    }
                }
            };

            this._observer = this.camera.getScene().onPointerObservable.add(this._wheel, PointerEventTypes.POINTERWHEEL);
        }

        public function detachControl(element: EventDispatcher): void {
            if (this._observer && element) {
                this.camera.getScene().onPointerObservable.remove(this._observer);
                this._observer = null;
                this._wheel = null;
            }
        }

        public function set camera(value: Camera): void {
            this._camera = ArcRotateCamera(value);
        }

        public function get camera(): Camera {
            return this._camera;
        }

        public function getTypeName(): String {
            return "ArcRotateCameraMouseWheelInput";
        }

        public function getSimpleName(): String {
            return "mousewheel";
        }

        public function get checkInputs(): Function {
            return null;
        }
    }
}
