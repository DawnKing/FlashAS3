/**
 * Created by caijingxiao on 2017/6/20.
 */
package babylon.sprites
{
    import babylon.Scene;
    import babylon.materials.Effect;
    import babylon.materials.textures.Texture;

    import flash.display.BitmapData;
    import flash.display.Stage;
    import flash.display3D.Context3DBufferUsage;
    import flash.display3D.IndexBuffer3D;

    public class BaseSprite
    {
        public static var stage:Stage;
        public static var indexBuffer:IndexBuffer3D;

        public static function init(scene:Scene, stage:Stage):void
        {
            if (indexBuffer != null)
                return;

            BaseSprite.stage = stage;
            Map2D.init(scene, stage);
            Char2D.init(scene);
            Effect2D.init(scene);

            indexBuffer = scene.getEngine().createIndexBuffer(new <uint>[0, 1, 2, 0, 2, 3], Context3DBufferUsage.STATIC_DRAW);
        }

        public var x:Number = 0;
        public var y:Number = 0;

        protected var _scene:Scene;
        protected var _effect:Effect;
        protected var _spriteTexture:Texture;

        public function BaseSprite(scene:Scene)
        {
            _scene = scene;
        }

        public function setTexture(tex:Object):void
        {
            if (tex is BitmapData)
            {
                _spriteTexture = new Texture(BitmapData(tex), _scene);
            }
            else if (tex is Texture)
            {
                _spriteTexture = Texture(tex);
            }
        }

        public function get texture():Texture
        {
            return _spriteTexture;
        }
    }
}
