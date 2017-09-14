/**
 * Created by caijingxiao on 2017/7/17.
 */
package game.world.base.view
{
    import easiest.rendering.sprites.SpriteContainer;

    import game.world.base.view.CharLayer;
    import game.world.battle.view.SkillLayer;

    import game.world.map.view.MapLayer;

    public class GameWorldLayer extends SpriteContainer
    {
        private static var _instance:GameWorldLayer;
        public static function get inst():GameWorldLayer { if (_instance == null) _instance = new GameWorldLayer(); return _instance; }

        private var _mapLayer:MapLayer;
        private var _charLayer:CharLayer;
        private var _skillLayer:SkillLayer;

        public function GameWorldLayer()
        {
            mouseEnabled = false;
            mouseChildren = true;
        }

        public function init():void
        {
            _mapLayer = new MapLayer();
            _charLayer = new CharLayer();
            _skillLayer = new SkillLayer();

            addChild(_mapLayer);
            addChild(_charLayer);
            addChild(_skillLayer);
        }

        public function clear():void
        {
            _mapLayer.clear();
            _charLayer.clear();
        }

        public function get mapLayer():MapLayer
        {
            return _mapLayer;
        }

        public function get charLayer():CharLayer
        {
            return _charLayer;
        }

        public function get skillLayer():SkillLayer
        {
            return _skillLayer;
        }
    }
}
