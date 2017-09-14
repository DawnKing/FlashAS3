/**
 * Created by caijingxiao on 2017/7/19.
 */
package game.world.entity.base.model
{
    public class FighterData extends MovableData
    {
        private var _hp:uint;
        private var _hpChanged:Boolean = true;
        private var _maxHp:uint;
        private var _maxHpChanged:Boolean = true;

        public function FighterData()
        {
            super();
        }

        override public function complete():void
        {
            super.complete();
            _hpChanged = false;
            _maxHpChanged = false;
        }

        public function get hpPercent():Number
        {
            return _hp / _maxHp;
        }

        public function get hp():uint
        {
            return _hp;
        }

        public function set hp(value:uint):void
        {
            if (_hp == value)
                return;
            _hp = value;
            _hpChanged = true;
        }

        public function get hpChanged():Boolean
        {
            return _hpChanged;
        }

        public function get maxHp():uint
        {
            return _maxHp;
        }

        public function set maxHp(value:uint):void
        {
            if (_maxHp == value)
                return;
            _maxHp = value;
            _maxHpChanged = true;
        }

        public function get maxHpChanged():Boolean
        {
            return _maxHpChanged;
        }
    }
}
