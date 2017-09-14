/**
 * Created by caijingxiao on 2017/7/17.
 */
package game.world.map.model
{
    public final class MapModel
    {
        private static var _mapData:MapData = new MapData();

        public static function get mapData():MapData
        {
            return _mapData;
        }
    }
}
