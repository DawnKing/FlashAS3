package
{
    import babylon.Engine;
    import babylon.Scene;
    import babylon.events.Stage3DEvent;
    import babylon.sprites.BaseSprite;
    import babylon.sprites.Char2D;
    import babylon.sprites.EffectAnimation;
    import babylon.sprites.Map2D;
    import babylon.sprites.Sprite2D;
    import babylon.tools.Stats;

    import easiest.core.EasiestCore;
    import easiest.managers.AssetData;
    import easiest.managers.AssetManager;
    import easiest.managers.AssetType;
    import easiest.utils.MathUtil;

    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;

    import game.CharAvatar;
    import game.MapLayer;

    public class Main extends Sprite
    {
        public static const Res:String = "res/";
        public static const Map:String = Res + "maps/";
        public static const Char:String = Res + "char/char.";
        public static const Weapon:String = Res + "weapon/weapon.";
        public static const Ride:String = Res + "ride/ride.";
        public static const Wing:String = Res + "Wing/wing.";
        public static const Skill:String = Res + "skill/skill.";
        public static const Effect:String = Res + "effect/effect.";

        private var _engine:Engine;
        public static var scene:Scene;

        private var _mapLayer:MapLayer;

        public function Main()
        {
            this.addChild(new Stats());
//            this.addChild(new LogWindow());
            EasiestCore.start(stage);

            _engine = new Engine(stage);
            _engine.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DCreated);
            _engine.init();

            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        private function onKeyDown(event:KeyboardEvent):void
        {
            switch (event.keyCode)
            {
                case Keyboard.UP:
                    MapLayer.y += 10;
                    break;
                case Keyboard.DOWN:
                    MapLayer.y -= 10;
                    break;
                case Keyboard.LEFT:
                    MapLayer.x += 10;
                    break;
                case Keyboard.RIGHT:
                    MapLayer.x -= 10;
                    break;
            }
        }

        private function onContext3DCreated(event:Stage3DEvent):void
        {
            scene = new Scene(_engine);
            _engine.runRenderLoop(function():void
            {
                if (_mapLayer != null)
                    _mapLayer.render(MapLayer.x, MapLayer.y);

                scene.render();
            });

            BaseSprite.init(scene, stage);

//            Sprite2D.init(scene, stage);
//            TestSprite2D(scene);
//            TestMap2D(scene);
//            TestChar2D(scene);
//            TestCharAnimation(scene);

            _mapLayer = new MapLayer(scene);
            _mapLayer.onResize(stage);

            const charTypeCount:int = 10;   // 职业
            const charCount:int = 50;

            var charList:Array = [];for (var c:int = 0; c < charTypeCount; c++) charList.push(c);
            for (var i:int = 0, k:int = 0; i < charCount; i++, k++)
            {
                var charType:int = charList.length > 0 ? charList.pop() : MathUtil.getIntRandom(0, charTypeCount-1);
                var avatar:CharAvatar = new CharAvatar(charType);
                avatar.x = int(k % 10) * 150 - 150;
                avatar.y = int(k / 10) * 150 - 150;
                avatar.direction = MathUtil.getIntRandom(0, 7);
            }

            var effectCount:int = 10;
            for (i = 0; i < effectCount; i++)
            {
                var skill:EffectAnimation = new EffectAnimation(scene, Skill + i);
                skill.totalFrame = 8;
                skill.x = int(i % 4) * 400;
                skill.y = int(i / 4) * 300;
                scene.addEffectAnimation(skill);

                var effect:EffectAnimation = new EffectAnimation(scene, Effect + i);
                effect.totalFrame = 8;
                effect.x = int(i % 4) * 500;
                effect.y = int(i / 4) * 400;
                scene.addEffectAnimation(effect);
            }
        }
    }
}

import babylon.Scene;
import babylon.sprites.Char2D;
import babylon.sprites.CharAnimation;
import babylon.sprites.Map2D;
import babylon.sprites.Sprite2D;

import easiest.managers.AssetData;
import easiest.managers.AssetManager;
import easiest.managers.AssetType;

import easiest.utils.MathUtil;

import flash.display.BitmapData;

function TestSprite2D(scene:Scene):void
{
    AssetManager.load(Main.Map + "0_0.png", onLoadComplete, AssetType.BITMAP_DATA);

    function onLoadComplete(asset:AssetData):void
    {
        if (asset.asset == null)
            return;
        var sprite:Sprite2D = new Sprite2D(scene);
        sprite.width = 512;
        sprite.height = 512;
        sprite.setTexture(asset.asset as BitmapData);
        scene.addSprite2D(sprite);
    }
}

function TestMap2D(scene:Scene):void
{
    AssetManager.load("res/maps/0_0.png", onLoadComplete, AssetType.BITMAP_DATA);

    function onLoadComplete(asset:AssetData):void
    {
        if (asset.asset == null)
            return;
        var map2d:Map2D = new Map2D(scene);
        map2d.setTexture(asset.asset as BitmapData);
        scene.addMap2D(map2d);
    }
}

function TestChar2D(scene:Scene):void
{
    AssetManager.load("res/299999.0.png", onLoadComplete, AssetType.BITMAP_DATA);

    function onLoadComplete(asset:AssetData):void
    {
        if (asset.asset == null)
            return;
        var char2D:Char2D = new Char2D(scene);
        char2D.x = 300;
        char2D.y = 100;
        char2D.width = 500;
        char2D.height = 500;
        char2D.setTexture(asset.asset as BitmapData);
        scene.addChar2D(char2D);
    }

}

function TestCharAnimation(scene:Scene):void
{
//            var char:CharAnimation = new CharAnimation(scene, Char + 0);
//            char.aniType = 8;
//            char.direction = 5;
//            char.totalFrame = 7;
//            scene.addCharAnimation(char);

    const charTypeCount:int = 10;   // 职业
    const charCount:int = 50;

    var charAniList:Array =   [0,  1];
    var charFrameList:Array = [10, 10];
    var charList:Array = [];for (var c:int = 0; c < charTypeCount; c++) charList.push(c);
    for (var i:int = 0, k:int = 0; i < charCount; i++, k++)
    {
        var charType:int = charList.length > 0 ? charList.pop() : MathUtil.getIntRandom(0, charTypeCount-1);
        var ani:CharAnimation = new CharAnimation(scene, "res/char/299999." + charType);
        ani.x = int(k % 20) * 95 - 250;
        ani.y = int(k / 20) * 95 - 180;
        var r:int = MathUtil.getIntRandom(0, charAniList.length-1);
        ani.action = charAniList[r];
        ani.totalFrame = charFrameList[r];
        ani.direction = MathUtil.getIntRandom(0, 7);
        scene.addCharAnimation(ani);
    }
}