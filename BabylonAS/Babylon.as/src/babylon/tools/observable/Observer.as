/**
 * Created by caijingxiao on 2016/11/29.
 */
package babylon.tools.observable {
    public class Observer {
        public var callback: Function;
        public var mask: int;

        public function Observer(callback: Function, mask: int) {
            this.callback = callback;
            this.mask = mask;
        }
    }
}
