package easiest.utils
{
    import flash.utils.getQualifiedClassName;

    public final class NameUtil
    {
        /**
         *  Returns the name of the specified object's class,
         *  such as <code>"Button"</code>
         *
         *  <p>This string does not include the package name.
         *  If you need the package name as well, call the
         *  <code>getQualifiedClassName()</code> method in the flash.utils package.
         *  It will return a string such as <code>"mx.controls::Button"</code>.</p>
         *
         *  @param object The object.
         *
         *  @return The name of the specified object's class.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function getUnqualifiedClassName(object:Object):String
        {
            var name:String;
            if (object is String)
                name = object as String;
            else
                name = getQualifiedClassName(object);
            
            // If there is a package name, strip it off.
            var index:int = name.indexOf("::");
            if (index != -1)
                name = name.substr(index + 2);
            
            return name;
        }
    }
}