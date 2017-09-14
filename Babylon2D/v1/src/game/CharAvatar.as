/**
 * Created by caijingxiao on 2017/6/20.
 */
package game
{
    import babylon.Scene;
    import babylon.sprites.CharAnimation;

    import easiest.utils.MathUtil;

    public class CharAvatar
    {
        private var _id:int;
        private var _char:CharAnimation;
        private var _weapon:CharAnimation;
        private var _ride:CharAnimation;
        private var _wing:CharAnimation;
        private var _list:Vector.<CharAnimation> = new <CharAnimation>[];

        public function CharAvatar(id:int)
        {
            _id = id;

//            var charAniList:Array =   [0,  1,  2, 3,  4, 7, 8];
//            var charFrameList:Array = [10, 10, 8, 4, 10, 5, 7];
            var charAniList:Array =   [0,  1];
            var charFrameList:Array = [10, 10];

            var weaponAniList:Array = [0, 1, 2];
            var weaponFrame:Array   = [6, 6, 3];

            var rideAniList:Array   = [0, 1];
            var rideFrameList:Array = [6, 5];

            var wingAniList:Array   = [0];
            var wingFrameList:Array = [6];

            _wing = addComponent(Main.Wing, wingAniList, wingFrameList);
            _ride = addComponent(Main.Ride, rideAniList, rideFrameList);
            _weapon = addComponent(Main.Weapon, weaponAniList, weaponFrame);
            _char = addComponent(Main.Char, charAniList, charFrameList);

            x = 0;
            y = 0;
        }

        private function addComponent(url:String, aniList:Array, frameList:Array):CharAnimation
        {
            url += _id;
            var random:int = MathUtil.getIntRandom(0, aniList.length-1);
            var aniType:int = aniList[random];
            var totalFrame:int = frameList[random];

            var scene:Scene = Main.scene;
            var component:CharAnimation = new CharAnimation(scene, url);
            component.action = aniType;
            component.totalFrame = totalFrame;
            scene.addCharAnimation(component);
            _list.push(component);
            return component;
        }

        public function set direction(value:int):void
        {
            for each(var c:CharAnimation in _list)
            {
                c.direction = value;
            }
        }

        public function set x(value:Number):void
        {
            for each(var c:CharAnimation in _list)
            {
                c.x = value;
            }
            _weapon.x = value + 180;
            _ride.x = value + 170;
            _wing.x = value + 170;
        }

        public function set y(value:Number):void
        {
            for each(var c:CharAnimation in _list)
            {
                c.y = value;
            }
            _weapon.y = value + 110;
            _ride.y = value + 150;
            _wing.y = value + 120;
        }
    }
}
