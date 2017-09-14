/**
 * Created by caijingxiao on 2016/12/7.
 */
package babylon.materials {
    public class TextureMaterialDefines extends MaterialDefines {
        public var ALPHATEST: Boolean = false;
        public var VERTEXCOLOR: Boolean = false;
        public var VERTEXALPHA: Boolean = false;

        public function TextureMaterialDefines() {
            super();
            this.rebuild();
        }
    }
}
