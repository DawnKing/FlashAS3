/**
     * Created by caijingxiao on 2017/6/27.
     */
package easiest.rendering.filters
{
    import easiest.rendering.Engine;
    import easiest.rendering.context.DrawContext;
    import easiest.rendering.context.FilterContext;
    import easiest.rendering.materials.textures.BaseTexture;

    public class FragmentFilter
    {
        private static var _context:FilterContext = new FilterContext();

        public function FragmentFilter()
        {
        }

        public function dispose():void
        {
        }

        public function draw(baseTexture:BaseTexture, vertexConstants:Vector.<Number>, constantsNumRegisters:int):void
        {
            _context.setContext(baseTexture);
            bind();
            Engine.inst.draw(vertexConstants, constantsNumRegisters, DrawContext.indexBuffer);
        }

        protected function bind():void
        {
        }
    }
}
