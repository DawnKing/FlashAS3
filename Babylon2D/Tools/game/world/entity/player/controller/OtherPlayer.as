/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.player.controller
{
    import game.world.entity.player.model.PlayerData;
    import game.world.entity.player.view.OtherPlayerAvatar;

    public final class OtherPlayer extends Player
    {
        public function OtherPlayer()
        {
            super();
        }

        override protected function initialize():void
        {
            _data = new PlayerData();
            _avatar = new OtherPlayerAvatar(onClick);
        }
    }
}
