/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.cameras.inputs {
    import babylon.Engine;
    import babylon.cameras.ArcRotateCamera;
    import babylon.cameras.Camera;
    import babylon.cameras.ICameraInput;
    import babylon.tools.observable.EventState;
    import babylon.tools.observable.Observer;
    import babylon.zip.scene.PointerEventTypes;
    import babylon.zip.scene.PointerInfo;

    import flash.events.EventDispatcher;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

    public class ArcRotateCameraPointersInput implements ICameraInput {
        private var _camera: ArcRotateCamera;

        [Serialize]
        public var angularSensibilityX: Number = 1000.0;

        [Serialize]
        public var angularSensibilityY: Number = 1000.0;

        [Serialize]
        public var pinchPrecision: Number = 6.0;

        [Serialize]
        public var panningSensibility: Number = 50.0;

//        private var _isPanClick: Boolean = false;
        public var pinchInwards: Boolean = true;

        private var _pointerInput: Function;    // (p: PointerInfo, s: EventState) => void;
        private var _observer: Observer;
        private var _onKeyDown: Function;   // (e: KeyboardEvent) => Object;
        private var _onKeyUp: Function;   // (e: KeyboardEvent) => Object;
        private var _onMouseMove: Function;   // (e: MouseEvent) => Object;
        private var _onLostFocus: Function;   // (e: FocusEvent) => Object;

        public function attachControl(element: EventDispatcher, noPreventDefault: Boolean = false): void {
            var engine: Engine = this.camera.getEngine();
            var cacheSoloPointer: Object; // cache pointer object for better perf on camera rotation
            var pointA: Object, pointB: Object;
            var previousPinchDistance: Number = 0;

            this._pointerInput = function (p: PointerInfo, s: EventState): void {
                var evt: MouseEvent = p.event;

                if (p.type === PointerEventTypes.POINTERDOWN) {
                    // Manage panning with pan button click
//                    ._isPanClick = evt.button === .camera._panningMouseButton;

                    // manage pointers
                    cacheSoloPointer = { x: evt.localX, y: evt.localY, type: evt.type };
                    if (pointA === null) {
                        pointA = cacheSoloPointer;
                    }
                    else if (pointB === null) {
                        pointB = cacheSoloPointer;
                    }
                    if (!noPreventDefault) {
                        evt.preventDefault();
                    }
                } else if (p.type === PointerEventTypes.POINTERUP) {
                    cacheSoloPointer = null;
                    previousPinchDistance = 0;

                    //would be better to use pointers.remove(evt.pointerId) for multitouch gestures,
                    //but emptying completly pointers collection is required to fix a bug on iPhone :
                    //when changing orientation while pinching camera, one pointer stay pressed forever if we don't release all pointers
                    //will be ok to put back pointers.remove(evt.pointerId); when iPhone bug corrected
                    pointA = pointB = null;

                    if (!noPreventDefault) {
                        evt.preventDefault();
                    }
                } else if (p.type === PointerEventTypes.POINTERMOVE) {
                    if (!noPreventDefault) {
                        evt.preventDefault();
                    }

                    // One button down
                    if (pointA && pointB === null) {
                        if (panningSensibility !== 0 &&
                                ((evt.ctrlKey && _camera._useCtrlForPanning) ||
                                (!_camera._useCtrlForPanning))) {
                            _camera
                                    .inertialPanningX += -(evt.localX - cacheSoloPointer.x) / panningSensibility;
                            _camera
                                    .inertialPanningY += (evt.localY - cacheSoloPointer.y) / panningSensibility;
                        } else {
                            var offsetX: Number = evt.localX - cacheSoloPointer.x;
                            var offsetY: Number = evt.localY - cacheSoloPointer.y;
                            _camera.inertialAlphaOffset -= offsetX / angularSensibilityX;
                            _camera.inertialBetaOffset -= offsetY / angularSensibilityY;
                        }

                        cacheSoloPointer.x = evt.localX;
                        cacheSoloPointer.y = evt.localY;
                    }

                    // Two buttons down: pinch
                    else if (pointA && pointB) {
                        //if (noPreventDefault) { evt.preventDefault(); } //if pinch gesture, could be useful to force preventDefault to avoid html page scroll/zoom in some mobile browsers
//                        var ed = (pointA.pointerId === evt.pointerId) ? pointA : pointB;
                        var ed: Object = pointA;
                        ed.x = evt.localX;
                        ed.y = evt.localY;
                        var direction: int = pinchInwards ? 1 : -1;
                        var distX: Number = pointA.x - pointB.x;
                        var distY: Number = pointA.y - pointB.y;
                        var pinchSquaredDistance: Number = (distX * distX) + (distY * distY);
                        if (previousPinchDistance === 0) {
                            previousPinchDistance = pinchSquaredDistance;
                            return;
                        }

                        if (pinchSquaredDistance !== previousPinchDistance) {
                            _camera
                                    .inertialRadiusOffset += (pinchSquaredDistance - previousPinchDistance) /
                            (pinchPrecision *
                            ((angularSensibilityX + angularSensibilityY) / 2) *
                            direction);
                            previousPinchDistance = pinchSquaredDistance;
                        }
                    }
                }
            };

            this._observer = this._camera.getScene().onPointerObservable.add(this._pointerInput, PointerEventTypes.POINTERDOWN | PointerEventTypes.POINTERUP | PointerEventTypes.POINTERMOVE);

            this._onLostFocus = function (): void {
                //this._keys = [];
                pointA = pointB = undefined;
                previousPinchDistance = 0;
                cacheSoloPointer = null;
            };

            this._onMouseMove = function (evt: MouseEvent): void {
                if (!engine.isPointerLock) {
                    return;
                }

                var offsetX: Number = evt.movementX;
                var offsetY: Number = evt.movementY;

                _camera.inertialAlphaOffset -= offsetX / angularSensibilityX;
                _camera.inertialBetaOffset -= offsetY / angularSensibilityY;

                if (!noPreventDefault) {
                    evt.preventDefault();
                }
            };


            element.addEventListener(MouseEvent.MOUSE_MOVE, this._onMouseMove, false);

            if (this._onKeyDown)
                element.addEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown, false);
            if (this._onKeyUp)
                element.addEventListener(KeyboardEvent.KEY_UP, this._onKeyUp, false);

//            Tools.RegisterTopRootEvents([
//                { name: "blur", handler: this._onLostFocus }
//            ]);
        }

        public function detachControl(element: EventDispatcher): void {
            if (element && this._observer) {
                this.camera.getScene().onPointerObservable.remove(this._observer);
                this._observer = null;

                element.removeEventListener(MouseEvent.MOUSE_MOVE, this._onMouseMove);

                element.removeEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown);
                element.removeEventListener(KeyboardEvent.KEY_UP, this._onKeyUp);

                this.pinchInwards = true;

                this._onKeyDown = null;
                this._onKeyUp = null;
                this._onMouseMove = null;
                this._onLostFocus = null;
            }

//            Tools.UnregisterTopRootEvents([
//                { name: "blur", handler: this._onLostFocus }
//            ]);
        }

        public function getTypeName(): String {
            return "ArcRotateCameraPointersInput";
        }

        public function getSimpleName(): String {
            return "pointers";
        }

        public function set camera(value: Camera): void {
            this._camera = ArcRotateCamera(value);
        }

        public function get camera(): Camera {
            return this._camera;
        }

        public function get checkInputs(): Function {
            return null;
        }
    }
}
