/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.cameras {
    import babylon.tools.Tools;

    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;

    public class CameraInputsManager {
        public var attached: Dictionary;
        public var attachedElement: EventDispatcher;
        public var noPreventDefault: Boolean;
        private var camera: Camera;
        private var _checkInputs: Vector.<Function>;  // () => void;

        public function CameraInputsManager(camera: Camera) {
            this.attached = new Dictionary(true);
            this.camera = camera;
            this._checkInputs = new <Function>[];
        }

        public function add(input: ICameraInput): void {
            var type: String = input.getSimpleName();
            if (this.attached[type]) {
                Tools.Warn("camera input of type " + type + " already exists on camera");
                return;
            }

            this.attached[type] = input;

            input.camera = this.camera;

            //for checkInputs, we are dynamically creating a function
            //the goal is to avoid the performance penalty of looping for inputs in the render loop
            if (input.checkInputs) {
                this._checkInputs = this._addCheckInputs(input.checkInputs);
            }

            if (this.attachedElement) {
                input.attachControl(this.attachedElement);
            }
        }

        public function remove(inputToRemove: ICameraInput): void {
            for (var cam: String in this.attached) {
                var input: ICameraInput = this.attached[cam];
                if (input === inputToRemove) {
                    input.detachControl(this.attachedElement);
                    delete this.attached[cam];
                    this.rebuildInputCheck();
                }
            }
        }

        public function removeByType(inputType: String): void {
            for (var cam: String in this.attached) {
                var input: ICameraInput = this.attached[cam];
                if (input.getTypeName() === inputType) {
                    input.detachControl(this.attachedElement);
                    delete this.attached[cam];
                    this.rebuildInputCheck();
                }
            }
        }

        private function _addCheckInputs(fn: Function): Vector.<Function> {
            this._checkInputs.push(fn);
            return this._checkInputs;
        }

        public function attachInput(input: ICameraInput): void {
            input.attachControl(this.attachedElement, this.noPreventDefault);
        }

        public function attachElement(element: EventDispatcher, noPreventDefault: Boolean = false): void {
            if (this.attachedElement) {
                return;
            }

            noPreventDefault = Camera.ForceAttachControlToAlwaysPreventDefault ? false : noPreventDefault;
            this.attachedElement = element;
            this.noPreventDefault = noPreventDefault;

            for (var cam: String in this.attached) {
                var input: ICameraInput = this.attached[cam];
                this.attached[cam].attachControl(element, noPreventDefault);
            }
        }

        public function detachElement(element: EventDispatcher): void {
            if (this.attachedElement !== element) {
                return;
            }

            for (var cam: String in this.attached) {
                var input: ICameraInput = this.attached[cam];
                this.attached[cam].detachControl(element);
            }

            this.attachedElement = null;
        }

        public function rebuildInputCheck(): void {
            this._checkInputs.length = 0;

            for (var cam: String in this.attached) {
                var input: ICameraInput = this.attached[cam];
                if (input.checkInputs) {
                    this._checkInputs = this._addCheckInputs(input.checkInputs);
                }
            }
        }

        public function clear(): void {
            if (this.attachedElement) {
                this.detachElement(this.attachedElement);
            }
            this.attached = new Dictionary(true);
            this.attachedElement = null;
            this._checkInputs.length = 0
        }

        public function serialize(serializedCamera: Object): void {
//            var inputs: Object = {};
//            for (var cam: String in this.attached) {
//                var input: ICameraInput = this.attached[cam];
//                var res = SerializationHelper.Serialize(input);
//                inputs[input.getTypeName()] = res;
//            }
//
//            serializedCamera.inputsmgr = inputs;
        }

        public function parse(parsedCamera): void {
//            var parsedInputs = parsedCamera.inputsmgr;
//            if (parsedInputs) {
//                this.clear();
//
//                for (var n in parsedInputs) {
//                    var construct = CameraInputTypes[n];
//                    if (construct) {
//                        var parsedinput = parsedInputs[n];
//                        var input = SerializationHelper.Parse(() => { return new construct() }, parsedinput, null);
//                        this.add(input as any);
//                    }
//                }
//            } else {
//                //2016-03-08 this part is for managing backward compatibility
//                for (var n in this.attached) {
//                    var construct = CameraInputTypes[this.attached[n].getTypeName()];
//                    if (construct) {
//                        var input = SerializationHelper.Parse(() => { return new construct() }, parsedCamera, null);
//                    this.remove(this.attached[n]);
//                    this.add(input as any);
//                }
//            }
        }

        public function checkInputs(): void {
            for (var i: int = 0; i < this._checkInputs.length; i++) {
                this._checkInputs[i]();
            }
        }
    }
}
