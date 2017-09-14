/**
 * Created by caijingxiao on 2016/10/26.
 */
package babylon.tools {
    import flash.utils.describeType;

    public class ObjectUtils {
        public static function keys(o: Object): Vector.<String> {
            var classInfo: XML = describeType(o);
            var properties: XMLList = classInfo..accessor.(@access != "writeonly") + classInfo..variable;
            var n: int = properties.length();
            var list: Vector.<String> = new <String>[];
            for (var i: int = 0; i < n; i++) {
                var prop: XML = properties[i];
                var p: String = prop.@name.toString();
                list.push(p);
            }
            return list;
        }
    }
}
