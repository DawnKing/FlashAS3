/**
 * Created by caijingxiao on 2017/7/21.
 */
package game.world.entity.base.controller
{
    import easiest.rendering.sprites.PngProgressBar;

    import tempest.core.IHealth;

    public class HpBar
    {
        /**是否显示血量数字*/
        public var showNum:Boolean;
        private var _bar:PngProgressBar;

        public function HpBar()
        {
        }
    }
}
