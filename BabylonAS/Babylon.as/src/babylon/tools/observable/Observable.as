/**
 * Created by caijingxiao on 2016/11/29.
 */
package babylon.tools.observable {
    public class Observable {
        private var _observers: Vector.<Observer> = new <Observer>[];

        private var _eventState: EventState;

        public function Observable() {
            this._eventState = new EventState(0);
        }

        /**
         * Create a new Observer with the specified callback
         * @param callback the callback that will be executed for that Observer
         * @param mask the mask used to filter observers
         * @param insertFirst if true the callback will be inserted at the first position, hence executed before the others ones. If false (default behavior) the callback will be inserted at the last position, executed after all the others already present.
         */
        public function add(callback: Function, mask: Number = -1, insertFirst: Boolean = false): Observer {
            if (!callback) {
                return null;
            }

            var observer: Observer = new Observer(callback, mask);

            if (insertFirst) {
                this._observers.unshift(observer);
            } else {
                this._observers.push(observer);
            }

            return observer;
        }

        /**
         * Remove an Observer from the Observable object
         * @param observer the instance of the Observer to remove. If it doesn't belong to this Observable, false will be returned.
         */
        public function remove(observer: Observer): Boolean {
            var index: int = this._observers.indexOf(observer);

            if (index !== -1) {

                this._observers.splice(index, 1);
                return true;
            }

            return false;
        }


        /**
         * Remove a callback from the Observable object
         * @param callback the callback to remove. If it doesn't belong to this Observable, false will be returned.
         */
        public function removeCallback(callback: Function): Boolean {

            for (var index: int = 0; index < this._observers.length; index++) {
                if (this._observers[index].callback === callback) {
                    this._observers.splice(index, 1);
                    return true;
                }
            }

            return false;
        }

        /**
         * Notify all Observers by calling their respective callback with the given data
         * Will return true if all observers were executed, false if an observer set skipNextObservers to true, then prevent the subsequent ones to execute
         * @param eventData
         * @param mask
         */
        public function notifyObservers(eventData: Object, mask: Number = -1): Boolean {
            var state: EventState = this._eventState;
            state.mask = mask;
            state.skipNextObservers = false;

            for each (var obs: Object in this._observers) {
                if (obs.mask & mask) {
                    if (obs.callback.length == 1)
                        obs.callback(eventData);
                    else
                        obs.callback(eventData, state);
                }
                if (state.skipNextObservers) {
                    return false;
                }
            }
            return true;
        }

        /**
         * return true is the Observable has at least one Observer registered
         */
        public function hasObservers(): Boolean {
            return this._observers.length > 0;
        }

        /**
         * Clear the list of observers
         */
        public function clear(): void {
            this._observers.length = 0;
        }

        /**
         * Clone the current observable
         */
        public function clone(): Observable {
            var result: Observable = new Observable();

            result._observers = this._observers.slice(0);

            return result;
        }
    }
}
