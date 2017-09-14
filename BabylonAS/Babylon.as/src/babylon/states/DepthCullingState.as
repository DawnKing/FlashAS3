/**
 * Created by caijingxiao on 2016/10/14.
 */
package babylon.states {
    import flash.display3D.Context3D;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DTriangleFace;

    public class DepthCullingState {

        private var _isDepthTestDirty:Boolean = false;
        private var _isDepthMaskDirty:Boolean = false;
        private var _isDepthFuncDirty:Boolean = false;
        private var _isCullFaceDirty:Boolean = false;
        private var _isCullDirty:Boolean = false;
        private var _isZOffsetDirty:Boolean = false;

        private var _depthTest:Boolean;
        private var _depthMask:Boolean;
        private var _depthFunc:String = Context3DCompareMode.LESS;
        private var _cull:Boolean;
        private var _cullFace:String;
        private var _zOffset:Number;

        public function DepthCullingState() {
            reset();
        }

        public function get isDirty():Boolean {
            return _isDepthFuncDirty || _isDepthTestDirty || _isDepthMaskDirty || _isCullFaceDirty || _isCullDirty || _isZOffsetDirty;
        }

        public function get zOffset():Number {
            return _zOffset;
        }

        public function set zOffset(value:Number): void {
            if (_zOffset === value) {
                return;
            }

            _zOffset = value;
            _isZOffsetDirty = true;
        }

        public function get cullFace():String {
            return _cullFace;
        }

        public function set cullFace(value:String): void {
            if (_cullFace === value) {
                return;
            }

            _cullFace = value;
            _isCullFaceDirty = true;
        }

        public function get cull():Boolean {
            return _cull;
        }

        public function set cull(value:Boolean): void {
            if (_cull === value) {
                return;
            }

            _cull = value;
            _isCullDirty = true;
        }

        public function get depthFunc():String {
            return _depthFunc;
        }

        public function set depthFunc(value:String): void {
            if (_depthFunc === value) {
                return;
            }

            _depthFunc = value;
            _isDepthFuncDirty = true;
        }

        public function get depthMask():Boolean {
            return _depthMask;
        }

        public function set depthMask(value:Boolean): void {
            if (_depthMask === value) {
                return;
            }

            _depthMask = value;
            _isDepthMaskDirty = true;
        }

        public function get depthTest():Boolean {
            return _depthTest;
        }

        public function set depthTest(value:Boolean): void {
            if (_depthTest === value) {
                return;
            }

            _depthTest = value;
            _isDepthTestDirty = true;
        }

        public function reset():void {
            _depthMask = true;
            _depthTest = true;
            _depthFunc = Context3DCompareMode.LESS;
            _cullFace = null;
            _cull = false;
            _zOffset = 0;

            _isDepthTestDirty = true;
            _isDepthMaskDirty = true;
            _isDepthFuncDirty = false;
            _isCullFaceDirty = false;
            _isCullDirty = false;
            _isZOffsetDirty = false;
        }

        public function apply(context3D:Context3D):void {

            if (!this.isDirty) {
                return;
            }

            // Cull
            if (this._isCullDirty) {
                if (!this.cull)
                    context3D.setCulling(Context3DTriangleFace.NONE);
                this._isCullDirty = false;
            }

            // Cull face
            if (this._isCullFaceDirty) {
                if (this.cull)
                    context3D.setCulling(this.cullFace);
                this._isCullFaceDirty = false;
            }

            // Depth mask
            if (this._isDepthMaskDirty) {
                if (this.depthMask)
                    context3D.setDepthTest(this.depthMask, Context3DCompareMode.NEVER);
                else
                    context3D.setDepthTest(this.depthMask, this.depthFunc);
                this._isDepthMaskDirty = false;
            }

            // Depth test
            if (this._isDepthTestDirty) {
                if (this.depthTest) {
                    context3D.setDepthTest(this.depthMask, this.depthFunc);
                } else {
                    context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
                }
                this._isDepthTestDirty = false;
            }

            // Depth func
            if (this._isDepthFuncDirty) {
                if (this.depthTest)
                    context3D.setDepthTest(this.depthMask, this.depthFunc);
                this._isDepthFuncDirty = false;
            }

//            // zOffset
//            if (_isZOffsetDirty) {
//                if (zOffset) {
//                    context3D.enable(context3D.POLYGON_OFFSET_FILL);
//                    context3D.polygonOffset(zOffset, 0);
//                } else {
//                    context3D.disable(context3D.POLYGON_OFFSET_FILL);
//                }
//
//                _isZOffsetDirty = false;
//            }
        }
    }
}
