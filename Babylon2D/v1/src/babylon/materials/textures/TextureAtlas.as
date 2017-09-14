
package  babylon.materials.textures
{
    import babylon.tools.StringUtil;

    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    public class TextureAtlas
    {
        private var _atlasTexture:Object;
        private var _subTextures:Dictionary;

        /** Create a texture atlas from a texture by parsing the regions from an XML file. */
        public function TextureAtlas(texture:Texture, atlasXml:XML=null)
        {
            _subTextures = new Dictionary();
            _atlasTexture = texture;

            if (atlasXml)
                parseAtlasXml(atlasXml);
        }

        /** Disposes the atlas texture. */
        public function dispose():void
        {
            _atlasTexture.dispose();
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

        /** Retrieves a SubTexture by name. Returns <code>null</code> if it is not found. */
        public function getSubTexture(action:int, direction:int = -1, frame:int = -1):SubTexture
        {
            if (direction == -1)
                return _subTextures[action];
            return _subTextures[action][direction][frame];
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
            else
                addSubTexture1(list[0], new SubTexture(_atlasTexture, region, false, frame, rotated));
        }

        public function addSubTexture1(frame:int, subTexture:SubTexture):void
        {
            _subTextures[frame] = subTexture;
        }

        public function addSubTexture3(action:int, direction:int, frame:int, subTexture:SubTexture):void
        {
            var actions:Dictionary, directions:Dictionary;

            if (!(action in _subTextures))
                _subTextures[action] = new Dictionary(true);
            actions = _subTextures[action];

            if (!(direction in actions))
                actions[direction] = new Dictionary(true);
            directions = actions[direction];

            directions[frame] = subTexture;
        }
    }
}
