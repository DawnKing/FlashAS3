/**
 * Created by caijingxiao on 2016/11/16.
 */
package babylon.tools {
    public class SmartArray {
        public static function PushNoDuplicate(vector: Object, value: Object): Boolean {
            var index: int = vector.indexOf(value);
            if (index != -1) {
                return false;
            }
            vector.push(value);
            return true;
        }
    }
}
