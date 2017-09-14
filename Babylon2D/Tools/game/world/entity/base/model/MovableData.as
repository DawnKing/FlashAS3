/**
 * Created by caijingxiao on 2017/7/19.
 */
package game.world.entity.base.model
{
    import flash.geom.Point;

    public class MovableData extends EntityData
    {
        public var currentTile:Point;

        /**当前行走经过的点*/
        public var throughTileArr:Array=[];

        public function MovableData()
        {
            super();
        }

        override public function complete():void
        {
            super.complete();
        }
    }
}
