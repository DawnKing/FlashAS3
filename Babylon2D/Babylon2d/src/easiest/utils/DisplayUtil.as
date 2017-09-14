package easiest.utils
{
    import easiest.core.IDispose;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;

    public final class DisplayUtil
    {
        public static function addChild(child:SpriteObject, parent:SpriteContainer):void
        {
            if (parent == null || child == null)
                return;
            parent.addChild(child);	
        }
        
        public static function addChildAt(child:SpriteObject, parent:SpriteContainer, index:int):void
        {
            if (parent == null || child == null)
                return;
            parent.addChildAt(child, index);	
        }
        
        /**
         * 移除可显示对象
         */
        public static function removeChild(displayObject:SpriteObject):void
        {
            if (displayObject == null || displayObject.parent == null)
                return;
            displayObject.parent.removeChild(displayObject);
        }
        
        /**
         * 移除可显示对象容器
         */
        private static function removeChildren(container:SpriteContainer):void
        {            
            if (container == null)
                return;
            container.removeChildren();
            removeChild(container);
        }
        
        /**
         * 释放可显示对象
         */		
        private static function disposeChild(displayObject:SpriteObject):void
        {
            if(displayObject == null)
                return;
            removeChild(displayObject);
            if(displayObject is IDispose)
                IDispose(displayObject).dispose();
            displayObject = null;
        }

        /**
         * 释放可显示对象容器
         */
        public static function disposeChildren(container:SpriteContainer):void
        {
            if(container == null)
                return;
            while(container.numChildren > 0)
            {
                var displayObject:SpriteObject = container.getChildAt(0);
                disposeChild(displayObject);
            }
            removeChildren(container);
        }

        /**
         * 获取指定parent
         * @param object 显示对象
         * @param parentClass parent类
         * @return parent类
         */
        public static function getParent(object:SpriteObject, parentClass:Class):Object
        {
            if (object == null)
                return null;
            var p:SpriteContainer = object.parent;
            if (p == null)
                return null;
            while (!(p is parentClass))
            {
                p = p.parent;
                if (p == null)
                    break;
            }
            return p as parentClass;
        }
    }
}