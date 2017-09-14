/**
 * Created by caijingxiao on 2017/7/19.
 */
package game.world.entity.base.view
{
    import easiest.rendering.display.NumberImage;
    import easiest.rendering.display.ProgressBar;
    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.rendering.sprites.atlas.SpriteAtlas;

    import game.base.EmbedAssetDef;

    import game.base.Main;
    import game.world.entity.base.model.EntityData;
    import game.world.entity.base.model.FighterData;

    public class FighterAvatar extends EntityAvatar
    {
        public static const HP_BAR_X:int = -43;
        public static const HP_BAR_HEIGHT:int = 7;
        public static const HP_NUM:int = 15;
        public static var NumberList:Vector.<Vector.<SpriteAtlas>>;

        private var _hpBar:ProgressBar = new ProgressBar();
        private var _hpNum:NumberImage = new NumberImage();
        private var _slash:SpriteAtlas = new SpriteAtlas();
        private var _maxHpNum:NumberImage = new NumberImage();

        public function FighterAvatar(onMouseClick:Function)
        {
            super(onMouseClick);

            createHpBar();
            createHpNum();
        }

        override public function dispose():void
        {
            _hpBar.dispose();
            _hpBar = null;
            _hpNum.dispose();
            _hpNum = null;
            _slash.dispose();
            _slash = null;
            _maxHpNum.dispose();
            _maxHpNum = null;
            super.dispose();
        }

        override public function init(data:EntityData):void
        {
            super.init(data);

            _maxHpNum.x = _slash.width;
            var fighterData:FighterData = data as FighterData;
            updateHp(fighterData);

            updateHpBarPos();
            updateHpSkin();
        }

        protected function createHpBar():void
        {
            _hpBar.name = "hpBar";
            addChild(_hpBar);
            _hpBar.x = HP_BAR_X;
        }

        protected function createHpNum():void
        {
            _hpNum.name = "hp";
            _slash.name = "/";
            _maxHpNum.name = "maxHp";
            addChild(_hpNum);
            addChild(_slash);
            addChild(_maxHpNum);

            if (NumberList == null)
            {
                NumberList = new Vector.<Vector.<SpriteAtlas>>(12, true);
                for (var i:int = 0; i < 10; i++)
                {
                    var sprite:SpriteAtlas = new SpriteAtlas();
                    sprite.setAtlas2(Main.sceneAtlas, "num_songti1_" + i);
                    sprite.name = i.toString();
                    NumberList[i] = new <SpriteAtlas>[];
                    NumberList[i].push(sprite);
                }
            }

            _hpNum.setSource(NumberList);
            _slash.setAtlas2(Main.sceneAtlas, "num_songti_gang");
            _maxHpNum.setSource(NumberList);
        }

        private function updateHp(fighterData:FighterData):void
        {
            if (fighterData.hpChanged)
            {
                _hpNum.value = fighterData.hp;
                _hpNum.x = -_hpNum.width;
            }
            if (fighterData.maxHpChanged)
            {
                _maxHpNum.value = fighterData.maxHp;
            }
            _hpBar.percent = fighterData.hpPercent;
        }

        protected function updateHpSkin():void
        {
            var atlas:TextureAtlas = Main.sceneAtlas;
            hpBar.setBackground(atlas, EmbedAssetDef.HP_Backgroud);
            hpBar.setTween(atlas, EmbedAssetDef.HP_EffectProgress);
        }

        private function updateHpBarPos():void
        {
            _hpBar.y = -bodyHeight - HP_BAR_HEIGHT;
            _hpNum.y = _slash.y = _maxHpNum.y = _hpBar.y - HP_NUM;
        }

        override protected function onBodyUpdate(nameY:Number):void
        {
            updateHpBarPos();
            super.onBodyUpdate(_hpNum.y);
        }

        override public function updateData(data:EntityData):void
        {
            super.updateData(data);
            var fighterData:FighterData = data as FighterData;
            updateHp(fighterData);
        }

        override public function set x(value:Number):void
        {
            super.x = value;
        }

        override public function set y(value:Number):void
        {
            super.y = value;
        }

        public function get hpBar():ProgressBar
        {
            return _hpBar;
        }
    }
}
