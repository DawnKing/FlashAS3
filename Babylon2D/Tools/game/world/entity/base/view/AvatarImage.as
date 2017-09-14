/**
 * Created by caijingxiao on 2017/7/28.
 */
package game.world.entity.base.view
{
    import easiest.managers.load.BinManager;
    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.rendering.sprites.atlas.SpriteAtlas;

    import game.world.entity.base.model.EntityData;
    import game.world.entity.npc.model.CollectData;

    public class AvatarImage extends SpriteAtlas implements IAvatarItem
    {
        public var onUpdate:Function;

        public function AvatarImage()
        {
            mouseEnabled = true;
        }

        public function set itemId(value:int):void
        {
            textureName = value.toString();
        }

        public function updateItem(data:EntityData, frame:int):void
        {
            var collectData:CollectData = data as CollectData;
            BinManager.loadBin(collectData.binPath, onComplete);
        }

        private function onComplete(atlas:TextureAtlas):void
        {
            setAtlas(atlas);
            updateSubTexture();
            onUpdate(-itemHeight);
            x = -width / 2;
            y = -height / 2;
        }

        public function get itemHeight():uint
        {
            return height;
        }
    }
}
