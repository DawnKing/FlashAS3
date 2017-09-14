/**
 * Created by caijingxiao on 2016/11/29.
 */
package babylon.tools.observable {
    /**
     * A class serves as a medium between the observable and its observers
     */
    public class EventState {
        /**
         * If the callback of a given Observer set skipNextObservers to true the following observers will be ignored
         */
        public function EventState(mask: int, skipNextObservers: Boolean = false) {
            this.initalize(mask, skipNextObservers);
        }

        public function initalize(mask: int, skipNextObservers: Boolean = false): EventState {
            this.mask = mask;
            this.skipNextObservers = skipNextObservers;
            return this;
        }

        /**
         * An Observer can set this property to true to prevent subsequent observers of being notified
         */
        public var skipNextObservers: Boolean;

        /**
         * Get the mask value that were used to trigger the event corresponding to this EventState object
         */
        public var mask: Number;
    }
}
