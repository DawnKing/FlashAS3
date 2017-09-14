/**
 * Created by caijingxiao on 2016/10/14.
 */
package babylon.states {
    import flash.display3D.Context3D;
    import flash.display3D.Context3DBlendFactor;

    public class AlphaCullingState {
        private var _isAlphaBlendDirty:Boolean = false;
        private var _isBlendFunctionParametersDirty:Boolean = false;
        private var _alphaBlend:Boolean = false;
        private var _sourceFactor:String;
        private var _destinationFactor:String;

        public function AlphaCullingState() {
            reset();
        }

        public function get isDirty():Boolean {
            return _isAlphaBlendDirty || _isBlendFunctionParametersDirty;
        }

        public function get alphaBlend():Boolean {
            return _alphaBlend;
        }

        public function set alphaBlend(value:Boolean): void {
            if (_alphaBlend === value) {
                return;
            }

            _alphaBlend = value;
            _isAlphaBlendDirty = true;
        }

        public function setAlphaBlendFunctionParameters(sourceFactor:String, destinationFactor:String):void {
            if (_sourceFactor === sourceFactor && _destinationFactor === destinationFactor)
                return;

            _sourceFactor = sourceFactor;
            _destinationFactor = destinationFactor;

            _isBlendFunctionParametersDirty = true;
        }

        public function reset():void {
            _alphaBlend = false;
            _sourceFactor = null;
            _destinationFactor = null;

            _isAlphaBlendDirty = true;
            _isBlendFunctionParametersDirty = false;
        }

        public function apply(context3D:Context3D):void {

            if (!isDirty) {
                return;
            }

            // Alpha blend
            if (_isAlphaBlendDirty) {
                if (_alphaBlend) {
                    context3D.setBlendFactors(_sourceFactor, _destinationFactor);
                } else {
                    context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO)
                }

                _isAlphaBlendDirty = false;
            }

            // Alpha function
            if (_isBlendFunctionParametersDirty) {
                context3D.setBlendFactors(_sourceFactor, _destinationFactor);
                _isBlendFunctionParametersDirty = false;
            }
        }
    }
}