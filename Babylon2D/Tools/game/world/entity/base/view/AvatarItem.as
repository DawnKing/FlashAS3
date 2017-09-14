/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.base.view
{
    import common.SceneCache;

    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.rendering.sprites.atlas.AtfAnimation;

    import game.world.entity.base.model.EntityData;

    import tempest.template.OffsetInfo;

    public final class AvatarItem extends AtfAnimation implements IAvatarItem
    {
        private var _offsetInfo:OffsetInfo;

        public function AvatarItem()
        {
            mouseEnabled = true;
        }

        override public function dispose():void
        {
            super.dispose();
        }

        override public function clear():void
        {
            _offsetInfo = null;
            super.clear();
        }

        override public function set itemId(value:int):void
        {
            if (itemId == value)
                return;
            super.itemId = value;
            _offsetInfo = SceneCache.getOffsetInfo(itemId);
            _offsetY = -_offsetInfo.centerY;
        }

        public function updateItem(data:EntityData, frame:int):void
        {
            if (itemId == -1)
                return;

            update(data.status, data.avatarDirection, data.horizontalFlip, frame);
        }

        override protected function onUpdateTextureAtlas(path:String, atlas:TextureAtlas):void
        {
            super.onUpdateTextureAtlas(path, atlas);
            if (subTexture)
                _offsetX = -int(subTexture.frame.width / 2);
        }

        public function get itemHeight():uint
        {
            if (_offsetInfo)
                return _offsetInfo.headOffset;
            return 120;
        }
    }
}
