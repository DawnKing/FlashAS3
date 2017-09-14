/**
 * Created by caijingxiao on 2017/7/19.
 */
package game.world.entity.player.view
{
    import easiest.managers.ObjectPool;
    import easiest.rendering.materials.textures.TextureAtlas;

    import flash.utils.Dictionary;

    import game.base.EmbedAssetDef;

    import game.base.Main;
    import game.world.entity.base.model.EntityData;
    import game.world.entity.base.view.AvatarItem;
    import game.world.entity.base.view.FighterAvatar;
    import game.world.entity.player.model.PlayerData;

    public class PlayerAvatar extends FighterAvatar
    {
        private const WEAPON:String= "weapon";
        private var _items:Dictionary = new Dictionary(true);

        public function PlayerAvatar(onMouseClick:Function)
        {
            super(onMouseClick);
        }

        override public function clear():void
        {
            for each (var item:AvatarItem in _items)
            {
                ObjectPool.free(item);
            }
            _items = new Dictionary(true);
            super.clear();
        }

        override public function init(data:EntityData):void
        {
            super.init(data);
        }

        override protected function updateHpSkin():void
        {
            super.updateHpSkin();
            var atlas:TextureAtlas = Main.sceneAtlas;
            hpBar.setProgress(atlas, EmbedAssetDef.HP_PlayerGreen);
        }

        override public function update(data:EntityData, frame:int):void
        {
            super.update(data, frame);
            var playerData:PlayerData = data as PlayerData;
            updateItem(playerData.weaponChanged, playerData.weapon, WEAPON, data, frame);
        }

        private function updateItem(itemIdChanged:Boolean, itemId:int, type:String, data:EntityData, frame:int):void
        {
            var item:AvatarItem = _items[type];
            if (itemIdChanged)
            {
                if (itemId == 0)
                {
                    if (item != null)
                    {
                        removeChild(item);
                        ObjectPool.free(item);
                        delete _items[type];
                    }
                    return;
                }
                if (item == null)
                {
                    item = ObjectPool.get(AvatarItem) as AvatarItem;
                    _items[type] = item;
                    addChild(item);
                    item.name = type;
                }
                item.itemId = itemId;
            }
            if (item)
                item.updateItem(data, frame);
        }
    }
}
