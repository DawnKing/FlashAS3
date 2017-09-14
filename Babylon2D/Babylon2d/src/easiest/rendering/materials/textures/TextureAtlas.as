package  easiest.rendering.materials.textures
{
    import easiest.core.Log;
    import easiest.utils.StringUtil;

    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    public class TextureAtlas
    {
        private var _atlasTexture:BaseTexture;
        private var _subTextures:Dictionary;
        private var _subTextureNames:Vector.<String>;

        /** helper objects */
        private static var sNames:Vector.<String> = new <String>[];

        /** Create a texture atlas from a texture by parsing the regions from an XML file. */
        public function TextureAtlas(texture:BaseTexture, atlasXml:XML=null)
        {
            _subTextures = new Dictionary();
            _atlasTexture = texture;

            if (atlasXml)
                parseAtlasXml(atlasXml);
        }

        /** Disposes the atlas texture. */
        public function clear():void
        {
            _atlasTexture.clear(null);
        }

        /** This function is called by the constructor and will parse an XML in Starling's
         *  default atlas file format. Override this method to create custom parsing logic
         *  (e.g. to support a different file format). */
        protected function parseAtlasXml(atlasXml:XML):void
        {
            var scale:Number = _atlasTexture.scale;
            var region:Rectangle = new Rectangle();
            var frame:Rectangle  = new Rectangle();

            for each (var subTexture:XML in atlasXml.SubTexture)
            {
                var name:String        = StringUtil.clean(subTexture.@name);
                var x:Number           = parseFloat(subTexture.@x) / scale;
                var y:Number           = parseFloat(subTexture.@y) / scale;
                var width:Number       = parseFloat(subTexture.@width)  / scale;
                var height:Number      = parseFloat(subTexture.@height) / scale;
                var frameX:Number      = parseFloat(subTexture.@frameX) / scale;
                var frameY:Number      = parseFloat(subTexture.@frameY) / scale;
                var frameWidth:Number  = parseFloat(subTexture.@frameWidth)  / scale;
                var frameHeight:Number = parseFloat(subTexture.@frameHeight) / scale;
                var rotated:Boolean    = StringUtil.parseBoolean(subTexture.@rotated);

                region.setTo(x, y, width, height);
                frame.setTo(frameX, frameY, frameWidth, frameHeight);

                if (frameWidth > 0 && frameHeight > 0)
                    addRegion(name, region, frame, rotated);
                else
                    addRegion(name, region, null,  rotated);
            }
        }

        public function getSubTextureByName(name:String):SubTexture
        {
            return _subTextures[name];
        }


        public function getTexture(name:String):SubTexture
        {
            return _subTextures[name];
        }

        /** Returns all textures that start with a certain string, sorted alphabetically
         *  (especially useful for "MovieClip"). */
        public function getTextures(prefix:String="", result:Vector.<SubTexture>=null):Vector.<SubTexture>
        {
            if (result == null) result = new <SubTexture>[];

            for each (var name:String in getNames(prefix, sNames))
                result[result.length] = getTexture(name); // avoid 'push'

            sNames.length = 0;
            return result;
        }

        /** Returns all texture names that start with a certain string, sorted alphabetically. */
        public function getNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
        {
            var name:String;
            if (result == null) result = new <String>[];

            if (_subTextureNames == null)
            {
                // optimization: store sorted list of texture names
                _subTextureNames = new <String>[];
                for (name in _subTextures) _subTextureNames[_subTextureNames.length] = name;
                _subTextureNames.sort(Array.CASEINSENSITIVE);
            }

            for each (name in _subTextureNames)
                if (name.indexOf(prefix) == 0)
                    result[result.length] = name;

            return result;
        }

        /** Returns the region rectangle associated with a specific name, or <code>null</code>
         *  if no region with that name has been registered. */
        public function getRegion(action:int, direction:int = -1, frame:int = -1):Rectangle
        {
            var subTexture:SubTexture = getSubTexture(action, direction, frame);
            return subTexture ? subTexture.region : null;
        }

        /** Returns the frame rectangle of a specific region, or <code>null</code> if that region
         *  has no frame. */
        public function getFrame(action:int, direction:int = -1, frame:int = -1):Rectangle
        {
            var subTexture:SubTexture = getSubTexture(action, direction, frame);
            return subTexture ? subTexture.frame : null;
        }

        /** If true, the specified region in the atlas is rotated by 90 degrees (clockwise). The
         *  SubTexture is thus rotated counter-clockwise to cancel out that transformation. */
        public function getRotation(action:int, direction:int = -1, frame:int = -1):Boolean
        {
            var subTexture:SubTexture = getSubTexture(action, direction, frame);
            return subTexture ? subTexture.rotated : false;
        }

        /** Adds a named region for a SubTexture (described by rectangle with coordinates in
         *  points) with an optional frame. */
        public function addRegion(name:String, region:Rectangle, frame:Rectangle=null,
                                  rotated:Boolean=false):void
        {
            name = name.replace(".png", "");
            // 动作-方向-帧，#-#-#
            var list:Array = name.split("-");
            if (list.length == 3)
                addSubTexture3(list[0], list[1], list[2], new SubTexture(_atlasTexture, region, false, frame, rotated));
            else if (!isNaN(parseInt(list[0])))
                addSubTexture1(list[0], new SubTexture(_atlasTexture, region, false, frame, rotated));
            else
                addSubTextureByName(name, new SubTexture(_atlasTexture, region, false, frame, rotated));
        }

        private function addSubTextureByName(name:String, subTexture:SubTexture):void
        {
            _subTextures[name] = subTexture;
        }

        public function addSubTexture1(frame:int, subTexture:SubTexture):void
        {
            _subTextures[frame] = subTexture;
        }

        public function addSubTexture3(action:int, direction:int, frame:int, subTexture:SubTexture):void
        {
            var index:int = getIndex(action, direction, frame);
            if (index in _subTextures)
            {
                Log.error("超出范围", this);
            }
            _subTextures[index] = subTexture;
        }

        public static function getIndex(action:int, direction:int, frame:int):int
        {
           return (action << 16) | (direction << 8) | (frame);
        }

        public static function decodeIndex(index:int):String
        {
            return ((index & 0x00FF0000) >> 16) + "-" + ((index & 0x0000FF00) >> 8) + "-" + (index & 0x000000FF);
        }

        /** Retrieves a SubTexture by name. Returns <code>null</code> if it is not found. */
        public function getSubTexture(action:int, direction:int = -1, frame:int = -1):SubTexture
        {
            var index:int = direction == -1 ? action : getIndex(action, direction, frame);
            return _subTextures[index];
        }

        public function getSubTexture1(index:int):SubTexture
        {
            return _subTextures[index];
        }

        public function get texture():BaseTexture
        {
            return _atlasTexture;
        }
    }
}
