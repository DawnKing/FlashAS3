/**
 * Created by caijingxiao on 2017/1/6.
 */
package babylon.postProcess {
    import babylon.Engine;
    import babylon.cameras.Camera;
    import babylon.materials.textures.Texture;

    public class PassPostProcess extends PostProcess {
        public function PassPostProcess(name: String, options: Object, camera: Camera, samplingMode: Number = Texture.NEAREST_SAMPLINGMODE, engine: Engine = null, reusable: Boolean = false) {
            super(name, "pass", null, null, options, camera, samplingMode, engine, reusable);
        }
    }
}
