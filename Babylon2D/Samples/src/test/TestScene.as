/**
 * Created by caijingxiao on 2017/7/12.
 */
package test
{
    import easiest.managers.TimerManager;
    import easiest.rendering.Scene;

    import CharAvatar;

    public class TestScene
    {
        private static var _scene:Scene;
        private static var _count:int;
        private static var _charAvatar:Vector.<CharAvatar>;

        public static function testAddRemoveCharAvatar(scene:Scene, count:int):void
        {
            _scene = scene;
            _count = count;
            processAddCharAvatar();
        }

        private static function processAddCharAvatar():void
        {
            _charAvatar = Test.testCharAvatar(_scene, _count);
            TimerManager.add(processRemoveCharAvatar, _count * 100, 1);
        }

        private static function processRemoveCharAvatar():void
        {
            for (var i:int = 0; i < _charAvatar.length; i++)
            {
                var avatar:CharAvatar = _charAvatar[i];
                avatar.dispose();
            }

            TimerManager.add(processAddCharAvatar, _count * 100, 1);
        }
    }
}
