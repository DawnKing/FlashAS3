/**
 * Created by caijingxiao on 2016/12/2.
 */
package babylon.tools {
    /**
     * This class is used to track a performance counter which is Number based.
     * The user has access to many properties which give statistics of different nature
     *
     * The implementer can track two kinds of Performance Counter: time and count
     * For time you can optionally call fetchNewFrame() to notify the start of a new frame to monitor, then call beginMonitoring() to start and endMonitoring() to record the lapsed time. endMonitoring takes a newFrame parameter for you to specify if the monitored time should be set for a new frame or accumulated to the current frame being monitored.
     * For count you first have to call fetchNewFrame() to notify the start of a new frame to monitor, then call addCount() how many time required to increment the count value you monitor.
     */
    public class PerfCounter {
        /**
         * Returns the smallest value ever
         */
        public function get min(): Number {
            return this._min;
        }

        /**
         * Returns the biggest value ever
         */
        public function get max(): Number {
            return this._max;
        }

        /**
         * Returns the average value since the performance counter is running
         */
        public function get average(): Number {
            return this._average;
        }

        /**
         * Returns the average value of the last second the counter was monitored
         */
        public function get lastSecAverage(): Number {
            return this._lastSecAverage;
        }

        /**
         * Returns the current value
         */
        public function get current(): Number {
            return this._current;
        }

        public function get total(): Number {
            return this._totalAccumulated;
        }

        public function PerfCounter() {
            this._startMonitoringTime = 0;
            this._min = 0;
            this._max = 0;
            this._average = 0;
            this._lastSecAverage = 0;
            this._current = 0;
            this._totalValueCount = 0;
            this._totalAccumulated = 0;
            this._lastSecAccumulated = 0;
            this._lastSecTime = 0;
            this._lastSecValueCount = 0;
        }

        /**
         * Call this method to start monitoring a new frame.
         * This scenario is typically used when you accumulate monitoring time many times for a single frame, you call this method at the start of the frame, then beginMonitoring to start recording and endMonitoring(false) to accumulated the recorded time to the PerfCounter or addCount() to accumulate a monitored count.
         */
        public function fetchNewFrame(): void {
            this._totalValueCount++;
            this._current = 0;
            this._lastSecValueCount++;
        }

        /**
         * Call this method to monitor a count of something (e.g. mesh drawn in viewport count)
         * @param newCount the count value to add to the monitored count
         * @param fetchResult true when it's the last time in the frame you add to the counter and you wish to update the statistics properties (min/max/average), false if you only want to update statistics.
         */
        public function addCount(newCount: Number, fetchResult: Boolean): void {
            this._current += newCount;
            if (fetchResult) {
                this._fetchResult();
            }
        }

        /**
         * Start monitoring this performance counter
         */
        public function beginMonitoring(): void {
            this._startMonitoringTime = Tools.Now;
        }

        /**
         * Compute the time lapsed since the previous beginMonitoring() call.
         * @param newFrame true by default to fetch the result and monitor a new frame, if false the time monitored will be added to the current frame counter
         */
        public function endMonitoring(newFrame: Boolean = true): void {
            if (newFrame) {
                this.fetchNewFrame();
            }

            var currentTime: Number = Tools.Now;
            this._current = currentTime - this._startMonitoringTime;

            if (newFrame) {
                this._fetchResult();
            }
        }

        private function _fetchResult(): void {
            this._totalAccumulated += this._current;
            this._lastSecAccumulated += this._current;

            // Min/Max update
            this._min = Math.min(this._min, this._current);
            this._max = Math.max(this._max, this._current);
            this._average = this._totalAccumulated / this._totalValueCount;

            // Reset last sec?
            var now: Number = Tools.Now;
            if ((now - this._lastSecTime) > 1000) {
                this._lastSecAverage = this._lastSecAccumulated / this._lastSecValueCount;
                this._lastSecTime = now;
                this._lastSecAccumulated = 0;
                this._lastSecValueCount = 0;
            }
        }

        private var _startMonitoringTime: Number;
        private var _min: Number;
        private var _max: Number;
        private var _average: Number;
        private var _current: Number;
        private var _totalValueCount: Number;
        private var _totalAccumulated: Number;
        private var _lastSecAverage: Number;
        private var _lastSecAccumulated: Number;
        private var _lastSecTime: Number;
        private var _lastSecValueCount: Number;
    }
}
