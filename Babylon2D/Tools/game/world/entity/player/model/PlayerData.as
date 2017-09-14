/**
 * Created by caijingxiao on 2017/7/19.
 */
package game.world.entity.player.model
{
    import game.world.entity.base.model.FighterData;

    public class PlayerData extends FighterData
    {
        private var _weapon:int = -1;
        private var _weaponChanged:Boolean;

        /**队伍名字*/
        public var groupName:String="";
        /**罪恶值*/
        private var _evil:uint=0;

        public function PlayerData()
        {
            super();
        }

        override public function clear():void
        {
            _weapon = -1;
            super.clear();
        }

        public function get evil():uint
        {
            return _evil;
        }

        public function set evil(value:uint):void
        {
            _evil = value;
        }

        public function get weapon():int
        {
            return _weapon;
        }

        public function set weapon(value:int):void
        {
            if (_weapon == value)
                return;
            _weapon = value;
            _weaponChanged = true;
        }

        public function get weaponChanged():Boolean
        {
            return _weaponChanged;
        }

        override public function set status(value:int):void
        {
            super.status = value;
        }
    }
}
