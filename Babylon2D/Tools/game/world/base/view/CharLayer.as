/**
 * Created by caijingxiao on 2017/7/11.
 */
package game.world.base.view
{
    import easiest.managers.TimerManager;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;

    public class CharLayer extends SpriteContainer
    {
        public function CharLayer()
        {
            mouseEnabled = false;
            mouseChildren = true;

            TimerManager.add(sortDepth, 1000);
        }

        public function clear():void
        {
            removeChildren();
        }

        public function sortDepth():void
        {
            sortChildren(compare);
        }

        private function compare(a:SpriteObject, b:SpriteObject):int
        {
            return a.y < b.y ? -1 : 1;
        }
    }
}
