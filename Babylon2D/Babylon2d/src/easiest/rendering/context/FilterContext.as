/**
     * Created by caijingxiao on 2017/7/13.
     */
package easiest.rendering.context
{
    import easiest.rendering.materials.textures.BaseTexture;

    public class FilterContext extends DrawContext
    {
        public function FilterContext()
        {
            super();
        }

        override public function setContext(baseTexture:BaseTexture):void
        {
            _engine.setVertexBuffer(3, null);
            _engine.setTextures(null);
            _engine.setTexture(0, baseTexture.texture);
            _engine.setProgram(getProgram("filterColor", baseTexture.format));
        }
    }
}
