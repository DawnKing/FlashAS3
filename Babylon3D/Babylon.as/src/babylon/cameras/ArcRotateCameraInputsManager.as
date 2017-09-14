/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.cameras {
    import babylon.cameras.inputs.ArcRotateCameraMouseWheelInput;
    import babylon.cameras.inputs.ArcRotateCameraPointersInput;

    public class ArcRotateCameraInputsManager extends CameraInputsManager {
        public function ArcRotateCameraInputsManager(camera: ArcRotateCamera) {
            super(camera);
        }

        public function addMouseWheel(): ArcRotateCameraInputsManager {
            this.add(new ArcRotateCameraMouseWheelInput());
            return this;
        }

        public function addPointers(): ArcRotateCameraInputsManager {
            this.add(new ArcRotateCameraPointersInput());
            return this;
        }

        public function addKeyboard(): ArcRotateCameraInputsManager {
//            this.add(new ArcRotateCameraKeyboardMoveInput());
            return this;
        }

        public function addGamepad(): ArcRotateCameraInputsManager {
//            this.add(new ArcRotateCameraGamepadInput());
            return this;
        }

        public function addVRDeviceOrientation(): ArcRotateCameraInputsManager {
//            this.add(new ArcRotateCameraVRDeviceOrientationInput());
            return this;
        }
    }
}
