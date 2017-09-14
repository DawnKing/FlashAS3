/**
 * Created by caijingxiao on 2017/7/20.
 */
package game.world.entity.base.model
{
    public class EntityMove
    {
        private var _pathList:Array = [];
        private var _direction:int;
        private var _speed:int;

        public function setPathList(pathList:Array, direction:int, speed:int):void
        {
            _pathList = pathList;
            _direction = direction;
            _speed = speed;
        }

        public function get pathList():Array
        {
            return _pathList;
        }

        public function get direction():int
        {
            return _direction;
        }

        public function get speed():int
        {
            return _speed;
        }
    }
}
