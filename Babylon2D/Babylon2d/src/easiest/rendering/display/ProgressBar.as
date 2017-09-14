/**
 * Created by caijingxiao on 2017/7/21.
 */
package easiest.rendering.display
{
    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.atlas.SpriteAtlas;

    public class ProgressBar extends SpriteContainer
    {
        private var _background:SpriteAtlas;
        private var _progress:SpriteAtlas;

        public var progressOffsetX:Number = 1;
        public var progressOffsetY:Number = 1;

        public function ProgressBar()
        {
            _background = new SpriteAtlas();
            _background.name = "background";
            addChild(_background);

            _progress = new SpriteAtlas();
            _progress.name = "progress";
            _progress.x = progressOffsetX;
            _progress.y = progressOffsetY;
            addChild(_progress);
        }

        public function setBackground(atlas:TextureAtlas, textureName:String):void
        {
            _background.setAtlas2(atlas, textureName);
        }

        public function setProgress(atlas:TextureAtlas, textureName:String):void
        {
            _progress.setAtlas2(atlas, textureName);
        }

        public function setTween(atlas:TextureAtlas, textureName:String):void
        {
        }

        public function set percent(value:Number):void
        {
            _progress.scaleX = value;
        }
    }
}
