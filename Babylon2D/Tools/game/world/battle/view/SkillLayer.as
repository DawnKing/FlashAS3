/**
 * Created by caijingxiao on 2017/8/2.
 */
package game.world.battle.view
{
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;

    import flash.geom.Matrix;

    public class SkillLayer extends SpriteContainer
    {
        public function SkillLayer()
        {
            super();
        }

        override public function render(matrix:Matrix):void
        {
            if (numChildren == 0)
                return;
            super.render(matrix);
        }

        override public function removeChild(child:SpriteObject, dispose:Boolean = false):SpriteObject
        {
            return super.removeChild(child, dispose);
        }
    }
}
