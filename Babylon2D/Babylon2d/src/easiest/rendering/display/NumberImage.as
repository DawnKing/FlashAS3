package easiest.rendering.display
{
    import easiest.debug.Assert;
    import easiest.rendering.materials.textures.TextureAtlas;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.atlas.SpriteAtlas;

    /**
     * 数字图片
     *
     * @author caijingxiao
     *
     */
    public final class NumberImage extends SpriteContainer
    {
        private var _numberList:Vector.<Vector.<SpriteAtlas>>; // 图片数组
        private var _gap:int = 0;  // 数字间隔
        private var _value:int; // 显示的数字
        private var _sign:int = 0;// 数字符号

        public function NumberImage()
        {
            super();

            this.mouseChildren = false;
            this.mouseEnabled = false;
        }

        override public function dispose():void
        {
            removeNum();
            super.dispose();
        }

        /**
         * 加载数字图片，图片格式，0123456789+-
         */
        public function setSource(numberList:Vector.<Vector.<SpriteAtlas>> = null):void
        {
            if (_numberList)
            {
                removeChildren();
            }
            _numberList = numberList;
        }

        /**
         * 显示的数字
         */
        public function get value():int
        {
            return _value;
        }

        /**
         * @private
         */
        public function set value(value:int):void
        {
            if (_value == value)
                return;
            _value = value;
            changeNum(_value);
            setImagePosition();
        }

        // 改变数字
        private function changeNum(val:int):void
        {
            if (numChildren > 0)
                removeNum();

            var changeValue:int = Math.abs(val);

            var spriteList:Vector.<SpriteAtlas> = new Vector.<SpriteAtlas>;
            var numSprite:SpriteAtlas;
            if (changeValue == 0)
            {
                spriteList.push(getNum(0));
            }
            else
            {
                while (changeValue != 0)
                {
                    var num:int = changeValue % 10;
                    numSprite = getNum(num);
                    // 如果当前已经有相同数字，复制相同数字
                    if (spriteList.indexOf(numSprite) != -1)
                    {
                        var newSprite:SpriteAtlas = new SpriteAtlas();
                        newSprite.name = num.toString();
                        newSprite.setAtlas2(numSprite.atlas, numSprite.textureName);
                        numSprite = newSprite;
                    }
                    spriteList.push(numSprite);
                    changeValue /= 10;
                }
            }

            for (var j:int = spriteList.length-1; j >= 0; j--)
            {
                addChild(spriteList[j]);
            }
        }

        private function removeNum():void
        {
            for (var i:int = 0; i < numChildren; i++)
            {
                var child:SpriteAtlas = getChildAt(i) as SpriteAtlas;
                var index:int = parseInt(child.name);
                _numberList[index].push(child);

                Assert.assertTrue("内存泄漏", _numberList[index].length < 100);
            }
            removeChildren();
        }

        private function getNum(i:int):SpriteAtlas
        {
            var list:Vector.<SpriteAtlas> = _numberList[i];
            if (list.length > 1)
                return list.shift();

            var source:SpriteAtlas = list[0];
            var newSprite:SpriteAtlas = new SpriteAtlas();
            newSprite.name = i.toString();
            newSprite.setAtlas2(source.atlas, source.textureName);
            return newSprite;
        }

        /**
         * 数字符号，0表示不显示符号，小于0表示负号，大于0表示正号
         */
        public function get sign():int
        {
            return _sign;
        }

        /**
         * @private
         */
        public function set sign(value:int):void
        {
            if (_sign == value)
                return;
            _sign = value;
            changeSign();
            setImagePosition();
        }


        // 改变符号
        private function changeSign():void
        {
            if (_numberList == null)
                return;
            if (sign > 0)
            {
                if (!contains(getNum(10)))
                {
                    addChildAt(getNum(10), 0);
                }

                if (contains(getNum(11)))
                    removeChild(getNum(11));
            }
            else if (sign < 0)
            {
                if (!contains(getNum(11)))
                {
                    addChildAt(getNum(11), 0);
                }

                if (contains(getNum(10)))
                    removeChild(getNum(10));
            }
            else    // 不显示正负号
            {
                if (contains(getNum(10)))
                    removeChild(getNum(10));

                if (contains(getNum(11)))
                    removeChild(getNum(11));
            }
        }

        /**
         * 布局元素之间的水平空间（以像素为单位）。请注意，仅会在布局元素之间应用该间隙，这样如果只有一个元素，则该间隙不会对布局有任何影响。
         */
        public function get gap():int
        {
            return _gap;
        }

        /**
         * @private
         */
        public function set gap(value:int):void
        {
            if (_gap == value)
                return;
            _gap = value;
            setImagePosition();
        }

        private function setImagePosition():void
        {
            var width:Number = 0;
            var preSprite:SpriteAtlas = null;
            for (var i:int = 0; i < numChildren; i++)
            {
                var sprite:SpriteAtlas = getChildAt(i) as SpriteAtlas;
                if (preSprite != null)
                    sprite.x = preSprite.x + preSprite.width + _gap;
                else
                    sprite.x = 0;   // 第一个位置重置
                preSprite = sprite;
                width += sprite.width;
            }
            super.width = width;
        }

        public function get numberList():Vector.<Vector.<SpriteAtlas>>
        {
            return _numberList;
        }
    }
}