/**
 * Created by caijingxiao on 2017/7/28.
 */
package game.world.entity.base.view
{
    import easiest.core.IDispose;
    import easiest.rendering.filters.FragmentFilter;

    import game.world.entity.base.model.EntityData;

    public interface IAvatarItem extends IDispose
    {
        function set name(value:String):void;
        function set filter(value:FragmentFilter):void;
        function set itemId(value:int):void;
        function get itemHeight():uint;
        function updateItem(data:EntityData, frame:int):void;
    }
}
