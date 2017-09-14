/**
 * Created by caijingxiao on 2016/12/20.
 */
package babylon.lights.shadows {
    import babylon.materials.textures.RenderTargetTexture;

    public interface IShadowGenerator {
        function getShadowMap(): RenderTargetTexture;
        function dispose(): void;
    }
}
