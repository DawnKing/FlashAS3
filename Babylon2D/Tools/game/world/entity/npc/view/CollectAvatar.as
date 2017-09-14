/**
 * Created by caijingxiao on 2017/7/28.
 */
package game.world.entity.npc.view
{
    import easiest.managers.ObjectPool;

    import game.world.entity.base.model.EntityData;
    import game.world.entity.base.view.AvatarImage;
    import game.world.entity.base.view.EntityAvatar;
    import game.world.entity.base.view.IAvatarItem;

    public class CollectAvatar extends EntityAvatar
    {
        public function CollectAvatar(onMouseClick:Function)
        {
            super(onMouseClick);
        }

        override protected function initBody():IAvatarItem
        {
            return ObjectPool.get(AvatarImage) as AvatarImage;
        }

        override public function updateData(data:EntityData):void
        {
            if (data.bodyChanged)
            {
                _body.itemId = data.body;
                _body.updateItem(data, -1);
                AvatarImage(_body).onUpdate = onBodyUpdate;
            }
        }
    }
}
