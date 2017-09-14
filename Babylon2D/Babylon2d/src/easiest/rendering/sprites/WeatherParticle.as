/**
     * Created by caijingxiao on 2017/6/23.
     */
package easiest.rendering.sprites
{
    import flash.display.Stage;

    public class WeatherParticle
    {
        private var _stageWidth:Number = 0;
        private var _stageHeight:Number = 0;

        private var _fromX:Number = 0;
        private var _fromY:Number = 0;
        private var _rotation:Number = 0;
        private var _speedX:Number = 0;
        private var _speedY:Number = 0;

        public function WeatherParticle(stage:Stage, fromX:Number, fromY:Number, speedX:Number, speedY:Number, rotation:Number)
        {
            _stageWidth = stage.stageWidth;
            _stageHeight = stage.stageHeight;
            _fromX = fromX;
            _fromY = fromY;
            _speedX = speedX;
            _speedY = speedY;
            _rotation = rotation;
        }

        public function init(sprite:Sprite2D):void
        {
            sprite.x = _fromX;
            sprite.y = _fromY;
            sprite.rotation = _rotation;
        }

        public function update(sprite:Sprite2D):Boolean
        {
            var y:Number = sprite.y;
            if (y > _stageHeight)
            {
                init(sprite);
                return false;
            }
            var x:Number = sprite.x;
            x += _speedX;
            y += _speedY;
            sprite.x = x;
            sprite.y = y;
            return x > 0 && x < _stageWidth && y > 0;
        }
    }
}
