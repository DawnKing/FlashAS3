/**
 * Created by caijingxiao on 2016/10/26.
 */
package babylon.materials {
    import babylon.tools.ObjectUtils;

    public dynamic class MaterialDefines {
        protected var _keys: Vector.<String>;

        public function rebuild(): void {
            _keys = ObjectUtils.keys(this);
        }

        public function isEqual(other: MaterialDefines): Boolean {
            if (this._keys.length != other._keys.length) {
                return false;
            }

            for (var index: int = 0; index < this._keys.length; index++) {
                var prop: String = this._keys[index];

                if (this[prop] != other[prop]) {
                    return false;
                }
            }

            return true;
        }

        public function cloneTo(other: MaterialDefines): void {
            if (this._keys.length != other._keys.length) {
                other._keys = this._keys.slice();
            }

            for (var index: int = 0; index < this._keys.length; index++){
                var prop: String = this._keys[index];

                other[prop] = this[prop];
            }
        }

        public function reset(): void {
            for (var index: int = 0; index < this._keys.length; index++) {
                var prop: String = this._keys[index];

                if (this[prop] is int) {
                    this[prop] = 0;
                } else {
                    this[prop] = false;
                }
            }
        }

        public function toString(): String {
            var result: String = "";
            for (var index: int = 0; index < this._keys.length; index++) {
                var prop: String = this._keys[index];

                if (this[prop] is int && this[prop] != 0) {
                    result += "#define " + prop + " " + this[prop] + "\n";
                } else if (this[prop]) {
                    result += "#define " + prop + "\n";
                }
            }

            return result;
        }

        public function setKey(prop: String, value: *): void {
            this[prop] = value;
            if (this._keys.indexOf(prop) == -1)
                this._keys.push(prop);
        }
    }
}
