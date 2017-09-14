/**
 * Created by caijingxiao on 2017/6/30.
 */
package {
    public class GamePath
    {
        public static var Res:String="http://cdn.cn.nx.xy.local/teste2d/";
        public static function get Map():String { return Res + "maps/"}
        public static function get Char():String { return Res + "char/char."}
        public static function get Weapon():String { return Res + "weapon/weapon."}
        public static function get Ride():String { return Res + "ride/ride."}
        public static function get Wing():String { return Res + "wing/wing."}
        public static function get Skill():String { return Res + "skill/skill."}
        public static function get Effect():String { return Res + "effect/effect."}

        public static function get Battle():String { return Res + "battle/"}
        public static function get WeatherPath():String { return Battle + "weather"}
        public static function get HpBar():String { return Battle + "hpbar"}
    }
}
