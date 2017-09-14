/**
 * Created by caijingxiao on 2017/6/13.
 */
package babylon
{
    import babylon.materials.textures.BaseTexture;
    import babylon.sprites.Char2D;
    import babylon.sprites.EffectAnimation;
    import babylon.sprites.Map2D;
    import babylon.sprites.CharAnimation;
    import babylon.sprites.Sprite2D;

    public class Scene
    {
        public var textures: Vector.<BaseTexture> = new <BaseTexture>[];

        private var _engine:Engine;
        private var _sprites:Vector.<Sprite2D> = new <Sprite2D>[];
        private var _maps:Vector.<Map2D> = new <Map2D>[];
        private var _chars:Vector.<Char2D> = new <Char2D>[];
        private var _charAnimations:Vector.<CharAnimation> = new <CharAnimation>[];
        private var _effectAnimations:Vector.<EffectAnimation> = new <EffectAnimation>[];

        public function Scene(engine:Engine)
        {
            _engine = engine;

            _engine.scenes.push(this);
        }

        public function getEngine():Engine
        {
            return _engine;
        }

        public function addSprite2D(sprite: Sprite2D):void
        {
            _sprites.push(sprite);
        }

        public function addMap2D(map2d: Map2D):void
        {
            _maps.push(map2d);
        }

        public function addChar2D(sprite2d: Char2D):void
        {
            _chars.push(sprite2d);
        }

        public function render():void
        {
            _engine.clear(null, false, false);

            var index:int, len:int;

            len = _sprites.length;
            for (index = 0; index < len; index++)
            {
                _sprites[index].render();
            }

            len = _maps.length;
            for (index = 0; index < len; index++)
            {
                _maps[index].render();
            }

            len = _chars.length;
            for (index = 0; index < len; index++)
            {
                _chars[index].render();
            }

            len = _charAnimations.length;
            for (index = 0; index < len; index++)
            {
                _charAnimations[index].render();
            }

            len = _effectAnimations.length;
            for (index = 0; index < len; index++)
            {
                _effectAnimations[index].render();
            }
        }

        public function addCharAnimation(ani:CharAnimation):void
        {
            _charAnimations.push(ani);
        }

        public function addEffectAnimation(ani:EffectAnimation):void
        {
            _effectAnimations.push(ani);
        }
    }
}
