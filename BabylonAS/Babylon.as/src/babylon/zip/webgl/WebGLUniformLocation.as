/**
 * Created by caijingxiao on 2016/10/31.
 */
package babylon.zip.webgl {
    import easiest.unit.asserts.assertFalse;

    public class WebGLUniformLocation {
        private var _name: String;
        private var _programType: String;
        protected var _variableType: String;
        private var _registers: Vector.<String>;

        private var _firstRegister: Number;
        private var _componentIndex: Vector.<int> = new Vector.<int>(4, true);
        private var _components: String = "xyzw";

        public function WebGLUniformLocation(name: String, programType: String, variableType: String, registers: Vector.<String>) {
            this._name = name;
            this._programType = programType;
            this._variableType = variableType;
            this._registers = registers;

            if (this._registers[0].indexOf(".") != -1) {
                this._firstRegister = parseFloat(this._registers[0].substring(0, this._registers[0].indexOf(".")));
            } else {
                this._firstRegister = parseFloat(this._registers[0]);
            }

            assertFalse(isNaN(this._firstRegister));

            var dotIndex: int = this._registers[0].indexOf(".");
            if (dotIndex != -1) {
                this._components = this._registers[0].substr(dotIndex+1);

                this._componentIndex = new <int>[];
                var comps: String = components;

                for (var i: int = 0; i < comps.length; i++) {
                    var comIdx: int = "xyzw".indexOf(comps.charAt(i));

                    assertFalse(comIdx == -1);

                    this._componentIndex[i] = comIdx;
                }
            } else {
                this._componentIndex[0] = 0;
                this._componentIndex[1] = 1;
                this._componentIndex[2] = 2;
                this._componentIndex[3] = 3;
            }
        }

        public function get name(): String {
            return this._name;
        }

        public function get programType(): String {
            return this._programType;
        }

        public function get firstRegister(): int {
            return this._firstRegister;
        }

        public function get componentIndex(): Vector.<int> {
            return this._componentIndex;
        }

        public function get components(): String {
            return this._components;
        }

        public function get numRegisters(): int {
            return this._registers.length;
        }

        public function getRegister(index: int = 0): String {
            return this._name + this._registers[index];
        }
    }
}
