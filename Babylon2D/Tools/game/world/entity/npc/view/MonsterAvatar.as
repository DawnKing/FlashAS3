/**
 * Created by caijingxiao on 2017/7/27.
 */
package game.world.entity.npc.view
{
    import easiest.rendering.materials.textures.TextureAtlas;

    import game.base.EmbedAssetDef;

    import game.base.Main;
    import game.world.entity.base.view.FighterAvatar;

    public class MonsterAvatar extends FighterAvatar
    {
        public function MonsterAvatar(onMouseClick:Function)
        {
            super(onMouseClick);
        }

        override protected function updateHpSkin():void
        {
            super.updateHpSkin();
            var atlas:TextureAtlas = Main.sceneAtlas;
            hpBar.setProgress(atlas, EmbedAssetDef.HP_UnitRed);
        }
    }
}
