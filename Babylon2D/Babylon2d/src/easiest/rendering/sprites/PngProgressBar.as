/**
    * Created by caijingxiao on 2017/6/23.
    */
package easiest.rendering.sprites
{
    import easiest.rendering.sprites.atlas.PngSpriteAtlas;

    import flash.geom.Matrix;

    public class PngProgressBar extends SpriteContainer
    {
        private var _background:PngSpriteAtlas;
        private var _progress:PngSpriteAtlas;

        public var offsetX:Number = 1;
        public var offsetY:Number = 1;

        public function PngProgressBar(url:String, name:String, bgName:String = null)
        {
            _progress = new PngSpriteAtlas(url, name);

            if (bgName != null)
            {
                _background = new PngSpriteAtlas(url, bgName);
                addChild(_background);
                _progress.x = offsetX;
                _progress.y = offsetY;
            }

            addChild(_progress);
        }

        public function set percent(value:Number):void
        {
            _progress.scaleX = value;
        }

        override public function render(matrix:Matrix):void
        {
            super.render(matrix);
        }
    }
}
