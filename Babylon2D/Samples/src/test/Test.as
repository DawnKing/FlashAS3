/**
	 * Created by caijingxiao on 2017/6/29.
	 */
package test
{
    import easiest.managers.FrameManager;
    import easiest.managers.load.AssetData;
    import easiest.managers.load.AssetManager;
    import easiest.managers.load.AssetType;
    import easiest.rendering.Scene;
    import easiest.rendering.filters.ColorMatrixFilter;
    import easiest.rendering.sprites.PngProgressBar;
    import easiest.rendering.sprites.SkillEffect;
    import easiest.rendering.sprites.Sprite2D;
    import easiest.rendering.sprites.atlas.PngAnimation;
    import easiest.rendering.sprites.Weather;
    import easiest.rendering.sprites.WeatherParticle;
    import easiest.rendering.sprites.batch.Sprite2DBatching;
    import easiest.rendering.sprites.text.BitmapText;
    import easiest.rendering.sprites.text.E2DTextMgr;
    import easiest.utils.MathUtil;

    import flash.display.BitmapData;
    import flash.display.Stage;
    import flash.events.MouseEvent;

    import CharAvatar;
    import GamePath;
    import MapLayer;

    import starling.animation.Juggler;

    public class Test
	{
		private static var _mapLayer:MapLayer;
		private static var snow:Weather;
		private static var rain:Weather;
		private static var _stage:Stage;

		public static function testMap(scene:Scene, stage:Stage):void
		{
			_stage=stage;
			_mapLayer=new MapLayer();
			_mapLayer.onResize(stage);
			_mapLayer.renderMap(0, 0);
			scene.addChild(_mapLayer);

//			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			FrameManager.add(process);
		}

		private static function onMouseDown(event:MouseEvent):void
		{
			if (_mapLayer)
			{
//                if (Main.stScene)
//                {
//                        _mapLayer.renderMap(Main.stScene.camera.rect.x, Main.stScene.camera.rect.y);
//                        trace(Main.stScene.camera.rect.x, Main.stScene.camera.rect.y);

//                    _mapLayer.setViewPortByCamera(Main.stScene.camera);
//                }
//                else
//                {
				_mapLayer.setViewPort(event.stageX, event.stageY, _stage.stageWidth, _stage.stageHeight);
//                }
			}
		}

		private static function process(passedTime:Number):void
		{
			if (_mapLayer)
			{
				passedTime/=1000;
				_mapLayer.update(passedTime);
				Juggler.instance.advanceTime(passedTime);
			}
		}

		public static function onResize(stage:Stage):void
		{
			if (_mapLayer)
				_mapLayer.onResize(stage);
			if (snow)
				snow.play(["snow_far", "snow_far2", "snow_mid", "snow_nearly"]);
			if (rain)
				rain.play(["rain_far", "rain_mid2", "rain_mid", "rain_nearly"]);
		}

		public static function testCharAvatar(scene:Scene, count:int=50):Vector.<CharAvatar>
		{
			var result:Vector.<CharAvatar> = new <CharAvatar>[];
			const charTypeCount:int=10; // 职业
			var charList:Array=[];
			for (var c:int=0; c < charTypeCount; c++)
				charList.push(c);
			for (var i:int=0, k:int=0; i < count; i++, k++)
			{
				var charType:int=charList.length > 0 ? charList.pop() : MathUtil.getIntRandom(0, charTypeCount - 1);
				var avatar:CharAvatar=new CharAvatar(charType, i);
				avatar.x=int(k % 10) * 150 - 150 + 320;
				avatar.y=int(k / 10) * 150 - 150 + 240;
				avatar.direction=MathUtil.getIntRandom(0, 7);
				scene.addChild(avatar);
				result.push(avatar);
			}
			return result;
		}

		public static function testEffect(scene:Scene, count:int=30, offset:int = 200):void
		{
			for (var i:int=0; i < count; i++)
			{
				var eid:int=i % 30;
				var skill:SkillEffect=new SkillEffect(GamePath.Skill + eid);
				skill.totalFrame=8;
				skill.x=int(i % 6) * offset;
				skill.y=int(i / 6) * offset;
				scene.addChild(skill);

				var effect:SkillEffect=new SkillEffect(GamePath.Effect + eid);
				effect.totalFrame=8;
				effect.x=int(i % 6) * offset;
				effect.y=int(i / 6) * offset;
				scene.addChild(effect);
			}
		}

		public static function testWeather(scene:Scene, stage:Stage):void
		{
			snow=new Weather(GamePath.WeatherPath, 100);
			snow.onInit=function():WeatherParticle
			{
				var fromX:Number=MathUtil.getNumberRandom(0, Sprite2D.stage.stageWidth);
				var fromY:Number=MathUtil.getNumberRandom(0, -Sprite2D.stage.stageHeight);
				var speedX:Number=MathUtil.getNumberRandom(-0.1, 0.1);
				var speedY:Number=MathUtil.getNumberRandom(0.5, 2);
				return new WeatherParticle(stage, fromX, fromY, speedX, speedY, 0);
			};
			snow.play(["snow_far", "snow_far2", "snow_mid", "snow_nearly"]);
			scene.addWeather(snow);

			rain=new Weather(GamePath.WeatherPath, 500);
			rain.onInit=function(sprite:Sprite2D):WeatherParticle
			{
				if (Math.random() > 0.5)
				{
					var colorMatrix:ColorMatrixFilter=new ColorMatrixFilter();
					colorMatrix.tint(0xFFFF0000);
					sprite.filter=colorMatrix;
				}

				var line:int=Sprite2D.stage.stageHeight;
				var fromX:Number=MathUtil.getNumberRandom(line, line * 3);
				var fromY:Number=MathUtil.getNumberRandom(-line, -line * 3);
				var speedX:Number=MathUtil.getNumberRandom(-3, -6);
				var speedY:Number=MathUtil.getNumberRandom(6, 12);
				return new WeatherParticle(stage, fromX, fromY, speedX, speedY, 30 * MathUtil.Deg2Rad);
			};
			rain.play(["rain_far", "rain_mid2", "rain_mid", "rain_nearly"]);
			scene.addWeather(rain);
		}

		public static function testBatching():void
		{
			AssetManager.load(GamePath.Map + "0_0.png", onLoadComplete1, AssetType.BITMAP_DATA);

			function onLoadComplete1(asset:AssetData):void
			{
				if (asset.asset == null)
					return;
				var sprite:Sprite2D=new Sprite2D();
				sprite.x=0;
				sprite.y=0;
				sprite.width=512;
				sprite.height=512;
				sprite.setTexture(asset.asset as BitmapData);
				Sprite2DBatching.add(sprite);
			}

			AssetManager.load(GamePath.Map + "0_1.png", onLoadComplete2, AssetType.BITMAP_DATA);

			function onLoadComplete2(asset:AssetData):void
			{
				if (asset.asset == null)
					return;
				var sprite:Sprite2D=new Sprite2D();
				sprite.x=512;
				sprite.y=0;
				sprite.width=512;
				sprite.height=512;
				sprite.setTexture(asset.asset as BitmapData);
				Sprite2DBatching.add(sprite);
			}
		}

		public static function testSprite2D(scene:Scene):void
		{
			AssetManager.load(GamePath.Map + "0_0.atf", onLoadComplete, AssetType.BINARY);

			function onLoadComplete(asset:AssetData):void
			{
				if (asset.asset == null)
					return;
				var sprite:Sprite2D=new Sprite2D();
				sprite.x=100;
				sprite.y=100;
				sprite.width=512;
				sprite.height=512;
				sprite.setTexture(asset.asset);
				scene.addChild(sprite);
				sprite.pivotX = 100;

				var colorMatrix:ColorMatrixFilter=new ColorMatrixFilter();
				colorMatrix.tint(0xFFFF0000);

				sprite.mouseEnabled = true;
				sprite.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void
				{
					sprite.filter=colorMatrix;
				});
				sprite.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void
				{
					sprite.filter=null;
				});
				sprite.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void
				{
					trace("down");
				});
			}
		}

		public static function testAnimation(scene:Scene):void
		{
			var char:PngAnimation=new PngAnimation(GamePath.Char + 0);
			char.action=1;
			char.direction=5;
			char.totalFrame=10;
			scene.addChild(char);

			const charTypeCount:int=10; // 职业
			const charCount:int=1;

			var charAniList:Array=[0, 1];
			var charFrameList:Array=[10, 10];
			var charList:Array=[];
			for (var c:int=0; c < charTypeCount; c++)
				charList.push(c);
			for (var i:int=0, k:int=0; i < charCount; i++, k++)
			{
				var charType:int=charList.length > 0 ? charList.pop() : MathUtil.getIntRandom(0, charTypeCount - 1);
				var ani:PngAnimation=new PngAnimation(GamePath.Char + charType);
				ani.x=int(k % 20) * 95 - 250;
				ani.y=int(k / 20) * 95 - 180;
				var r:int=MathUtil.getIntRandom(0, charAniList.length - 1);
				ani.action=charAniList[r];
				ani.totalFrame=charFrameList[r];
				ani.direction=MathUtil.getIntRandom(0, 7);
				scene.addChild(ani);
			}
		}

		public static function testSpriteAtlas(scene:Scene):void
		{
			//    var sprite:SpriteAtlas = new SpriteAtlas(scene, Main.HpBar, "barbg");
			//	sprite.x = 100;
			//	sprite.y = 300;
			//    scene.addSpriteAtlas(sprite);
			//
			//    var sprite:SpriteAtlas = new SpriteAtlas(scene, Main.HpBar, "barred");
			//    sprite.x = 101;
			//    sprite.y = 301;
			//	sprite.scaleX = 0.5;
			//    scene.addSpriteAtlas(sprite);
			var bar:PngProgressBar=new PngProgressBar(GamePath.HpBar, "barred", "barbg");
			bar.x=100;
			bar.y=300;
			bar.percent=0.5;
			scene.addChild(bar);
		}

		public static function testText(scene:Scene, mgr:E2DTextMgr):void
		{
			var text:BitmapText=mgr.createText("我的名字非常的长", 0);
			scene.addChild(text);
		}
    }
}
