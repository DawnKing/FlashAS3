/**
 * Created by caijingxiao on 2016/10/14.
 */
package babylon.states {
    import flash.display3D.Context3D;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DStencilAction;
    import flash.display3D.Context3DTriangleFace;

    public class StencilState {
        private var _isStencilTestDirty:Boolean = false;
        private var _isStencilMaskDirty:Boolean = false;
        private var _isStencilFuncDirty:Boolean = false;
        private var _isStencilOpDirty:Boolean = false;

        private var _stencilTest:Boolean;

        private var _stencilMask:Number;

        private var _stencilFunc:String;
        private var _stencilFuncRef:Number;
        private var _stencilFuncMask:Number;

        private var _stencilOpStencilFail:String;
        private var _stencilOpDepthFail:String;
        private var _stencilOpStencilDepthPass:String;

        public function get isDirty():Boolean {
            return _isStencilTestDirty || _isStencilMaskDirty || _isStencilFuncDirty || _isStencilOpDirty;
        }

        public function get stencilFunc():String {
            return _stencilFunc;
        }

        public function set stencilFunc(value:String): void {
            if (_stencilFunc === value) {
                return;
            }

            _stencilFunc = value;
            _isStencilFuncDirty = true;
        }

        public function get stencilFuncRef():Number {
            return _stencilFuncRef;
        }

        public function set stencilFuncRef(value:Number): void {
            if (_stencilFuncRef === value) {
                return;
            }

            _stencilFuncRef = value;
            _isStencilFuncDirty = true;
        }

        public function get stencilFuncMask():Number {
            return _stencilFuncMask;
        }

        public function set stencilFuncMask(value:Number): void {
            if (_stencilFuncMask === value) {
                return;
            }

            _stencilFuncMask = value;
            _isStencilFuncDirty = true;
        }

        public function get stencilOpStencilFail():String {
            return _stencilOpStencilFail;
        }

        public function set stencilOpStencilFail(value:String): void {
            if (_stencilOpStencilFail === value) {
                return;
            }

            _stencilOpStencilFail = value;
            _isStencilOpDirty = true;
        }

        public function get stencilOpDepthFail():String {
            return _stencilOpDepthFail;
        }

        public function set stencilOpDepthFail(value:String): void {
            if (_stencilOpDepthFail === value) {
                return;
            }

            _stencilOpDepthFail = value;
            _isStencilOpDirty = true;
        }

        public function get stencilOpStencilDepthPass():String {
            return _stencilOpStencilDepthPass;
        }

        public function set stencilOpStencilDepthPass(value:String): void {
            if (_stencilOpStencilDepthPass === value) {
                return;
            }

            _stencilOpStencilDepthPass = value;
            _isStencilOpDirty = true;
        }

        public function get stencilMask():Number {
            return _stencilMask;
        }

        public function set stencilMask(value:Number): void {
            if (_stencilMask === value) {
                return;
            }

            _stencilMask = value;
            _isStencilMaskDirty = true;
        }

        public function get stencilTest():Boolean {
            return _stencilTest;
        }

        public function set stencilTest(value:Boolean): void {
            if (_stencilTest === value) {
                return;
            }

            _stencilTest = value;
            _isStencilTestDirty = true;
        }

        public function StencilState() {
            reset();
        }

        public function reset():void {
            _stencilTest = false;
            _stencilMask = 0xFF;

            _stencilFunc = Context3DCompareMode.ALWAYS;
            _stencilFuncRef = 1;
            _stencilFuncMask = 0xFF;

            _stencilOpStencilFail = Context3DStencilAction.KEEP;
            _stencilOpDepthFail = Context3DStencilAction.KEEP;
            _stencilOpStencilDepthPass = Context3DStencilAction.SET;

            _isStencilTestDirty = true;
            _isStencilMaskDirty = true;
            _isStencilFuncDirty = true;
            _isStencilOpDirty = true;
        }

        public function apply(context3D:Context3D):void {
            if (!isDirty) {
                return;
            }

            var triangleFace:String = Context3DTriangleFace.FRONT_AND_BACK;

            // Stencil test
            if (_isStencilTestDirty) {
                if (stencilTest) {
//                    var triangleFace:String = contextEnableCulling ? glCullModeToContext3DTriangleFace(glCullMode, !frontFaceClockWise) : Context3DTriangleFace.FRONT_AND_BACK;
                    context3D.setStencilActions(triangleFace,
                            stencilFunc,
                            stencilOpStencilDepthPass,
                            stencilOpDepthFail,
                            stencilOpStencilFail);
                } else {
                    // Reset to default
                    context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                            Context3DCompareMode.ALWAYS,
                            Context3DStencilAction.KEEP,
                            Context3DStencilAction.KEEP,
                            Context3DStencilAction.KEEP);
                }
                _isStencilTestDirty = false;
            }

//            // Stencil mask
//            if (_isStencilMaskDirty) {
//                context3D.stencilMask(stencilMask);
//                _isStencilMaskDirty = false;
//            }

            // Stencil func
            if (_isStencilFuncDirty) {
                context3D.setStencilReferenceValue(stencilFuncRef, stencilFuncMask, stencilFuncMask);
                context3D.setStencilActions(triangleFace,
                        stencilFunc,
                        stencilOpStencilDepthPass,
                        stencilOpDepthFail,
                        stencilOpStencilFail);
                _isStencilFuncDirty = false;
            }

            // Stencil op
            if (_isStencilOpDirty) {
                context3D.setStencilActions(triangleFace,
                        stencilFunc,
                        stencilOpStencilDepthPass,
                        stencilOpDepthFail,
                        stencilOpStencilFail);
                _isStencilOpDirty = false;
            }
        }
    }
}
