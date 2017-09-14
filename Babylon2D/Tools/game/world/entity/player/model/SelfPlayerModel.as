/**
 * Created by caijingxiao on 2017/7/19.
 */
package game.world.entity.player.model
{
    import easiest.debug.Assert;

    import game.world.entity.base.model.EntityModel;
    import game.world.entity.player.controller.SelfPlayer;

    public class SelfPlayerModel
    {
        public static var guid:String;
        private static var _player:SelfPlayer;

        public static function getPlayer():SelfPlayer
        {
            if (_player == null)
            {
                _player = EntityModel.findEntity(guid) as SelfPlayer;
                Assert.assertNotNull1(_player);
            }
            return _player;
        }

        public static function clear():void
        {
            _player = null;
        }
    }
}
