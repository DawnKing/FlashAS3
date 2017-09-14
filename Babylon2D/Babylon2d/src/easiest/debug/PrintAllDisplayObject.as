package easiest.debug
{
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;

    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    
    import easiest.core.EasiestCore;
    import easiest.utils.NameUtil;

    public final class PrintAllDisplayObject
    {
        public static function getStageInfo():String
        {
            var info:Array = getDisplayObjectInfo(EasiestCore.stage);
            return "count="+info[0]+"\n"+info[1];
        }        
        
        public static function getDisplayObjectInfo(container:DisplayObjectContainer, layer:int=0):Array
        {
            var count:int = 0;
            var root:String = "["+NameUtil.getUnqualifiedClassName(container)+"]%s";
            var leaf:Array = [];
            for (var i:int = 0; i < container.numChildren; i++) 
            {
                var display:DisplayObject = container.getChildAt(i);
                count++;
                root += "  "+NameUtil.getUnqualifiedClassName(display);
                
                if (display is DisplayObjectContainer)
                {
                    var info:Array = getDisplayObjectInfo(display as DisplayObjectContainer, layer+1);
                    count += info[0];
                    leaf.push(info[1]);
                }
            }
            
            root = root.replace("%s", count);
            
            var space:String = getSpace(layer);
            
            for (var j:int = 0; j < leaf.length; j++) 
            {
                root += "\n"+space+j+leaf[j];
            }
            
            return [count, root];
        }
        
        private static function getSpace(layer:int):String
        {
            var result:String = "";
            for (var i:int = 0; i < layer; i++) 
            {
                result += "-";
            }
            return result;
        }

        public static function getSpriteObjectInfo(container:SpriteContainer, layer:int=0):String
        {
            var space:String = getSpace(layer);
            var result:String = space + NameUtil.getUnqualifiedClassName(container) + container.toString() + "\n";
            space += "-";
            for (var i:int = 0; i < container.numChildren; i++)
            {
                var display:SpriteObject = container.getChildAt(i);
                if (display is SpriteContainer)
                {
                    result += getSpriteObjectInfo(display as SpriteContainer, layer + 1);
                }
                else
                {
                    result += space + NameUtil.getUnqualifiedClassName(display) + display.toString() + "\n";
                }
            }

            return result;
        }
    }
}