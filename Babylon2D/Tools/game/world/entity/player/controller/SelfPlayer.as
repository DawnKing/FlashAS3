/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.player.controller
{
    import game.world.entity.player.model.PlayerData;
    import game.world.entity.player.view.SelfPlayerAvatar;

    public class SelfPlayer extends Player
    {
        public function SelfPlayer()
        {
            super();
        }

        override protected function initialize():void
        {
            _data = new PlayerData();
            _avatar = new SelfPlayerAvatar(onClick);
        }
    }
}
