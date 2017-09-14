/**
 * Created by caijingxiao on 2016/10/31.
 */
package babylon.zip.webgl {
    import easiest.unit.Assert;

    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;
    import flash.utils.Dictionary;

    public class WebGLProgram {
        public static const AGAL_OP: Array = ["mov", "add", "sub", "mul", "div", "rcp", "frc", "neg", "sin", "cos", "min", "max", "sqt", "rsq", "pow", "log", "exp", "nrm", "abs", "sat", "crs", "dp3", "dp4", "m33", "m44", "m34", "kil", "seg", "slt", "tex"];
        public static const GLSL_OP_ATTRIBUTES: Array = ["float", "vec2", "vec3", "vec4", "mat2", "mat3", "mat4"];
        public static const NUM_REG: RegExp = /\d+/;
        public static const FUNC_REG: RegExp = /\S+\([^\(]+\)/;

        public var program: Program3D;

        private var _agalVertexCode: String;
        private var _agalFragmentCode: String;

        private var _defines: Dictionary = new Dictionary(true);
        private var _func: Dictionary = new Dictionary(true);   // func name - DefineFunc

        private var _attributes: Dictionary = new Dictionary(true);  // attribute - int
        private var _constants: Dictionary = new Dictionary(true);   // constant - WebGLUniformLocation
        private var _temporary: Dictionary = new Dictionary(true);    // temporary - Temporary
        private var _varying: Dictionary = new Dictionary(true);    // varying - int
        private var _sampler2D: Dictionary = new Dictionary(true);   // sampler - int
        private var _samplerCube: Dictionary = new Dictionary(true);

        public var _vertexTempCache: Vector.<String> = new Vector.<String>(8, true);
        public var _fragmentTempCache: Vector.<String> = new Vector.<String>(8, true);
        public var _vertexConstantsCache: Vector.<String> = new Vector.<String>(128, true);
        public var _fragmentConstantsCache: Vector.<String> = new Vector.<String>(28, true);
//        public var _vertexTempCache: Vector.<String> = new Vector.<String>(26, true);
//        public var _fragmentTempCache: Vector.<String> = new Vector.<String>(26, true);
//        public var _vertexConstantsCache: Vector.<String> = new Vector.<String>(250, true);
//        public var _fragmentConstantsCache: Vector.<String> = new Vector.<String>(64, true);

        public function WebGLProgram(program: Program3D, vertexCode: String, fragmentCode: String, defines: String) {
            this.program = program;

            parseDefines(defines);

            vertexCode = formatAGAL(vertexCode);
            fragmentCode = formatAGAL(fragmentCode);

            vertexCode = parseDefine(vertexCode);
            fragmentCode = parseDefine(fragmentCode);

            parseCode(Context3DProgramType.VERTEX, vertexCode);
            parseCode(Context3DProgramType.FRAGMENT, fragmentCode);

            _agalVertexCode = toAgal(Context3DProgramType.VERTEX, vertexCode, true);
            _agalFragmentCode = toAgal(Context3DProgramType.FRAGMENT, fragmentCode, true);

            trace("------------vertex----------");
            trace(_agalVertexCode);
            trace("------------fragment----------");
            trace(_agalFragmentCode);
            trace("----------WebGLProgram---------");
        }

        private function parseDefines(defines: String): void {
            var lines: Array = defines.split(/\n/);

            for (var i: int = 0; i < lines.length; i++) {
                if (lines[i] === "")
                    continue;
                var keys: Array = lines[i].split(" ");
                _defines[keys[1]] = keys[2];
            }
        }

        private function formatAGAL(s: String): String {
            var result: String = "";
            var lines: Array = s.split(/\n/);

            for (var i: int = 0; i < lines.length; i++) {
                var line: String = lines[i];
                if (line.indexOf("//") != -1)
                    continue;
                if (line.search(/\S/) == -1)
                    continue;

                while (line.substr(0, 1) == " ")
                    line = line.replace(" ", "");

                result += line + "\n";
            }

            const reg: RegExp = /\t|\r|;/;

            i = 0;
            while (result.search(reg) != -1) {
                result = result.replace(reg, "");

                Assert.assertTrue1(i++ < 10000);
            }
            return result;
        }

        private function parseDefine(code: String): String {
            var result: String = "";
            var lines: Array = code.split(/\n/);

            var enterIf: Boolean;

            for (var i: int = 0; i < lines.length; i++) {
                var line: String = lines[i];

                if (line.indexOf("#ifndef") != -1) {
                    var defineList: Array = line.split(/\s/);

                    if (defineList[1] in _defines) {
                        i = findEndIf(lines, i+1);
                    } else {
                        enterIf = true;
                    }
                } else if (line.indexOf("#ifdef") != -1) {
                    defineList = line.split(/\s/);

                    if (!(defineList[1] in _defines)) {
                        i = findEndIf(lines, i+1);
                    } else {
                        enterIf = true;
                    }
                } else if (line.indexOf("if defined") != -1) {
                    defineList = line.split(/\(|\)/);

                    if (!(defineList[1] in _defines)) {
                        i = findEndIf(lines, i+1);
                    } else {
                        enterIf = true;
                    }
                } else if (line.indexOf("#if") != -1) {
                    var conditionalIndex: int = line.search(/\S/);
                    var conditionalStr: String = line.substr(conditionalIndex);
                    var conditionalList: Array = conditionalStr.split(" ");

                    if (conditionalList[1] in _defines) {
                        var operator: String = conditionalList[2];
                        switch (operator) {
                            case ">":
                                Assert.assertTrue1(NUM_REG.test(_defines[conditionalList[1]]) && NUM_REG.test(conditionalList[3]));

                                var c1: int = parseInt(_defines[conditionalList[1]]);
                                var c2: int = parseInt(conditionalList[3]);

                                if (c1 <= c2) {
                                    i = findEndIf(lines, i+1);
                                } else {
                                    enterIf = true;
                                }
                                break;
                            default:
                                Assert.fail();
                        }
                    } else {
                        i = findEndIf(lines, i+1);
                    }
                } else if (line.indexOf("#else") != -1) {
                    if (enterIf) {
                        i = findEndIf(lines, i+1);
                    } else {
                        enterIf = false;
                    }
                } else if (line.indexOf("#endif") != -1) {
                    var nextLine: String = lines[i+1];

                    if (nextLine.indexOf("else") == -1)
                        enterIf = false;
                } else {
                    result += line + "\n";
                }
            }

            return result;
        }

        private function findEndIf(lines: Array, index: int): int {
            var skip: int = 1;
            for (var i: int = index; i < lines.length; i++) {
                var line: String = lines[i];

                if (line.indexOf("#ifndef") != -1 || line.indexOf("#ifdef") != -1 || line.indexOf("#if") != -1)
                    skip++;
                if (line.indexOf("#endif") != -1)
                    skip--;
                if (line.indexOf("#else") != -1 && skip == 1)
                    skip--;

                if (skip == 0)
                    return i;
            }
            Assert.fail();
            return 0;
        }

        private function parseCode(programType: String, code: String): void {
            var attributeCount: int = 0, varyingCount: int = 0, samplerCount: int = 0;

            var lines: Array = code.split(/\n/);

            var end: int = lines.indexOf("void main(void) {");
            if (end == -1)
                end = lines.length;

            for (var i: int = 0; i < end; i++) {
                var line: String = lines[i];

                if (line.search(FUNC_REG) != -1) {
                    parseFunc(line, i, lines);
                }

                var keys: Array = line.split(" ");

                if (line.indexOf("attribute") != -1) {
                    parseKey(keys, attributeCount++, _attributes);
                } else if (line.indexOf("uniform") != -1) {
                    if (line.indexOf("sampler2D") != -1) {
                        parseKey(keys, samplerCount, _sampler2D);
                        continue;
                    }

                    if (line.indexOf("samplerCube") != -1) {
                        parseKey(keys, samplerCount, _samplerCube);
                        continue;
                    }

                    parseUniform(programType, keys);
                } else if (line.indexOf("varying") != -1) {
                    parseKey(keys, varyingCount++, _varying);
                }
            }

            Assert.assertTrue1(attributeCount <= 8);
            Assert.assertTrue1(varyingCount <= 8);
            Assert.assertTrue1(samplerCount <= 8);
        }

        private function getFuncParams(line: String): Array {
            var list: Array = line.split(/\(|\,|\)/);

            var funcName: String = list.shift();
            if (list[list.length-1].indexOf("{") != -1)
                list.pop();

            var params: Vector.<String> = new Vector.<String>(list.length, true);

            for (var i: int = 0; i < list.length; i++) {
                var sp: Array = list[i].split(/\s/);
                params[i] = sp[sp.length-1];
            }
            return [funcName, params];
        }

        private function parseFunc(line: String, index: int, lines: Array): void {
            var t: Array = getFuncParams(line);
            var funcName: String = t[0];
            var params: Vector.<String> = t[1];

            var code: String = "";
            var brace: int = 1;

            for (var i: int  = index + 1; i < lines.length; i++) {
                if (lines[i].indexOf("{") != -1)
                    brace++;
                if (lines[i].indexOf("}") != -1)
                    brace--;
                if (brace == 0)
                    break;
                code += lines[i] + "\n";
            }

            var func: DefineFunc = new DefineFunc();
            func.params = params;
            func.code = code;

            _func[funcName] = func;
        }

        private function parseKey(keys: Array, index: int, dic: Dictionary): void {
            var name: String = keys[keys.length - 1];

            dic[name] = index;
        }

        private function parseUniform(programType: String, keys: Array): void {
            var type: String = keys[1];
            var name: String = keys[2];

            var numComponents: int = getNumComponents(type);

            if (name.indexOf("[") != -1) {
                var nameList: Array = name.split(/\[|\]/);
                name = nameList[0];

                var numStr: String = nameList[1];
                if (numStr in _defines)
                    numStr = _defines[numStr];

                Assert.assertTrue1(NUM_REG.test(numStr));

                var length: int = parseInt(numStr);
                numComponents *= length;
            }

            var cache: Vector.<String> = programType == Context3DProgramType.VERTEX ? _vertexConstantsCache : _fragmentConstantsCache;
            var registers: Vector.<String> = getRegisters(cache, numComponents, true);

            var regName: String = programType == Context3DProgramType.VERTEX ? "vc" : "fc";

            Assert.assertFalse("", name in _constants);

            _constants[name] = new WebGLUniformLocation(regName, programType, type, registers);
        }

        private function getNumComponents(type: String): int {
            switch (type) {
                case "float": return 1;
                case "vec2": return 2;
                case "vec3": return 3;
                case "vec4": return 4;
                case "mat4": return 16;
            }
            Assert.fail();
            return 0;
        }

        public function getRegisters(cache: Vector.<String>, numComponents: int, isUseRegister: Boolean): Vector.<String> {
            var registers: Vector.<String> = new <String>[];

            if (numComponents < 4) {
                var useRegisterIndex: int = -1;
                var components: String = "";

                // use register component, push number and components
                // first find the used register
                for (var registerIndex: int = 0; registerIndex < cache.length; registerIndex++) {
                    if (cache[registerIndex] == null || !isNaN(parseFloat(cache[registerIndex])))
                        continue;

                    if (cache[registerIndex].length + numComponents > 4)
                        continue;

                    useRegisterIndex = registerIndex;
                    components = cache[registerIndex];
                    break;
                }

                // use new register
                if (useRegisterIndex == -1) {
                    for (registerIndex = 0; registerIndex < cache.length; registerIndex++) {
                        if (cache[registerIndex] == null) {
                            useRegisterIndex = registerIndex;
                            break;
                        }
                    }
                }

                var comStr: String = "";
                var numCom: int = 0;
                for (var regIdx: int = 0; regIdx < 4; regIdx++) {
                    var newRegCom: String = "xyzw".charAt(regIdx);
                    if (components.indexOf(newRegCom) == -1) {
                        comStr += newRegCom;
                        if (++numCom == numComponents)
                            break;
                    }
                }

                Assert.assertEquals("", comStr.length, numComponents);

                var regStr: String = useRegisterIndex + "." + comStr;

                if (isUseRegister) {
                    if (cache[useRegisterIndex])
                        cache[useRegisterIndex] += comStr;
                    else
                        cache[useRegisterIndex] = comStr;
                }


                registers.push(regStr);
            } else {
                // use vector register, push number
                var numRegisters: int = numComponents / 4;

                for (registerIndex = 0; registerIndex < cache.length; registerIndex++) {
                    if (cache[registerIndex] == null) {
                        // The registers must be continuous
                        for (var i: int = 0; i < numRegisters; i++) {
                            useRegisterIndex = registerIndex+i;

                            Assert.assertFalse("", cache[useRegisterIndex]);

                            regStr = useRegisterIndex.toString();

                            if (isUseRegister)
                                cache[useRegisterIndex] = regStr;

                            registers.push(regStr);
                        }
                        break;
                    }
                }
            }

            var reg: RegExp = new RegExp("\d+|\d+.x|\d+.xy|\d+.xyz|\d+.xyzw|");
            for each (var s: String in registers) {
                Assert.assertTrue1(reg.test(s));
            }
            Assert.assertTrue("not enough register!", registers.length != 0);

            return registers;
        }

        public function getSource(sourceStr: String): String {
            var keys: Array = sourceStr.split(/\[|\]|\./);

            for (var i: int = 0; i < keys.length; i++) {
                var key: String = keys[i];
                if (key === "")
                    continue;
                if (key.search(/[a-zA-Z]+/) == -1)
                    continue;
                if (AGAL_OP.indexOf(key) != -1)
                    continue;
                var source: String = key;
                var firstRegister: int = -1;
                var extraInfo: String = "";
                if (key in _attributes) {
                    source = "va";
                    firstRegister = _attributes[key];
                } else if (key in _constants) {
                    source = _constants[key].name;
                    firstRegister = _constants[key].firstRegister;

                    if (sourceStr.indexOf(".") == -1 && _constants[key].components.length != 4)
                        extraInfo = "." + _constants[key].components;
                } else if (key in _temporary) {
                    source = _temporary[key].name;
                    firstRegister = _temporary[key].firstRegister;

                    if (sourceStr.indexOf(".") == -1 && _temporary[key].components.length != 4)
                        extraInfo = "." + _temporary[key].components;
                } else if (key in _varying) {
                    source = "v";
                    firstRegister = _varying[key];
                } else if (key in _sampler2D) {
                    source = "fs";
                    firstRegister = _sampler2D[key];
                    extraInfo = "<2d,mipnone,wrap>";
                } else if (key in _samplerCube) {
                    source = "fs";
                    firstRegister = _samplerCube[key];
                    extraInfo = "<cube,mipnone,clamp>";
                }

                if (firstRegister == -1)
                    continue;

                if (sourceStr.search(/\[\d+\]/) != -1) {
                    // replace variable such as "influence[0]"
                    var offsetStr: String = sourceStr.substring(sourceStr.lastIndexOf("[")+1, sourceStr.lastIndexOf("]"));
                    Assert.assertTrue1(NUM_REG.test(offsetStr));

                    var offset: int = parseInt(offsetStr);
                    source += (firstRegister + offset);
                    key = key + "[" + offset + "]";
                } else if (sourceStr.search(/\[\S+\]/) != -1) {
                    if (i == 0) {
                        if (sourceStr.search(/\d+/) != -1) {
                            // replace variable such as "mBones[matricesIndices.x+0]"
                            // to the "vc[matricesIndices.x+(0+firstRegister)]"
                            var registerOffsetStr: String = sourceStr.substring(sourceStr.search(/\d+/), sourceStr.lastIndexOf("]"));
                            Assert.assertTrue1(NUM_REG.test(registerOffsetStr));

                            var registerOffset: int = parseInt(registerOffsetStr);
                            sourceStr = sourceStr.replace(/\d+/, firstRegister + registerOffset);
                        } else {
                            // replace variable such as "world[constantsOffset]"
                            // to the "vc[constantsOffset+firstRegister]"
                            sourceStr = sourceStr.replace(key, source);
                            sourceStr = sourceStr.replace("]", "+"+firstRegister+"]");
                        }
                    } else {
                        source += firstRegister + extraInfo;
                    }
                } else {
                    source += firstRegister + extraInfo;
                }

                sourceStr = sourceStr.replace(key, source);
            }

            return sourceStr;
        }

        private function toAgal(programType: String, shaderCode: String, isMain: Boolean): String {
            var result: String = "";
            var lines: Array = shaderCode.split(/\n/);

            if (isMain) {
                var begin: int = lines.indexOf("void main(void) {") + 1;

                Assert.assertTrue1(begin > 0);

                var end: int = lines.lastIndexOf("}");
            } else {
                begin = 0;
                end = lines.length;
            }

            for (var i: int = begin; i < end; i++) {
                var line: String = lines[i];

                if (CustomKey.isKey(line)) {
                    result += CustomKey.generate(line, programType, this);
                    continue;
                }

                if (line.search(FUNC_REG) != -1) {
                    result += funcCall(programType, line);
                    continue;
                }

                var keys: Array = line.split(/[^a-z0-9=]?\s|</i);

                // temp variable declaration
                if (GLSL_OP_ATTRIBUTES.indexOf(keys[0]) != -1) {
                    result += parseTemporary(programType, keys);
                    continue;
                }

                if (keys[0] == "delete") {
                    deleteTemporary(programType, keys);
                    continue;
                }

                var lineCode: String = line;

                for each (var key: String in keys) {
                    if (key == "")
                        continue;

                    var source: String = getSource(key);
                    lineCode = lineCode.replace(key, source);
                }
                result += lineCode;
                if (i != end - 1)
                    result += "\n";
            }

            return result;
        }

        private function funcCall(programType: String, funcCode: String): String {
            var t: Array = getFuncParams(funcCode);
            var funcName: String = t[0];
            var params: Vector.<String> = t[1];

            var func: DefineFunc = _func[funcName];

            var list: Array = func.code.split("\n");

            var shaderCode: String = "";
            for (var i: int = 0; i < list.length; i++) {
                var line: String = list[i];
                var keys: Array = line.split(/[^a-z0-9=]?\s|<|\./i);
                for each (var key: String in keys) {
                    if (key == "")
                        continue;
                    var index: int = func.params.indexOf(key);
                    if (index != -1) {
                        var sourceVar: String = params[index];
                        var source: String = getSource(sourceVar);
                        line = line.replace(new RegExp("\\b"+key+"\\b"), source);
                    }
                }
                shaderCode += line + "\n";
            }

            return toAgal(programType, shaderCode, false);
        }

        private function parseTemporary(programType: String, keys: Array): String {
            var varType: String = keys[0];
            var name: String = keys[1];

            var isUseRegister: Boolean = name.indexOf("temp") == -1;
            var numComponents: int = getNumComponents(varType);
            var cache: Vector.<String> = programType == Context3DProgramType.VERTEX ? _vertexTempCache : _fragmentTempCache;
            var registers: Vector.<String> = getRegisters(cache, numComponents, isUseRegister);

            var regName: String = programType == Context3DProgramType.VERTEX ? "vt" : "ft";
            var temp: Temporary = new Temporary(regName, programType, varType, registers);

            if (name.indexOf("temp") == -1)
                Assert.assertFalse1(name in _temporary);

            _temporary[name] = temp;

            var result: String = "";
            if (keys.length > 2 && keys[2] == "=") {
                var source: String = getSource(keys[3]);
                result += temp.equal(source);
            }

            return result;
        }

        private function deleteTemporary(programType: String, keys: Array): void {
            var name: String = keys[1];

            var temp: Temporary = _temporary[name];
            var cache: Vector.<String> = programType == Context3DProgramType.VERTEX ? _vertexTempCache : _fragmentTempCache;

            var cacheStr: String = cache[temp.firstRegister];
            var compStr: String = temp.components;

            Assert.assertNotNull1(cacheStr);

            if (NUM_REG.test(cacheStr)) {
                cache[temp.firstRegister] = null;
            } else {
                for (var i: int = 0; i < compStr.length; i++) {
                    var s: String = compStr.charAt(i);
                    var index: int = cacheStr.indexOf(s);

                    Assert.assertFalse1(index == -1);

                    cacheStr = cacheStr.replace(s, "");
                }

                cache[temp.firstRegister] = cacheStr == "" ? null : cacheStr;
            }
        }

        public function getUniformLocation(uniform: String): WebGLUniformLocation {
            return _constants[uniform];
        }

        public function getSamplerIndex(uniform: String): int {
            if (uniform in _samplerCube)
                return _samplerCube[uniform];
            return uniform in _sampler2D ? _sampler2D[uniform] : -1;
        }

        public function getAttribLocation(uniform: String): int {
            return uniform in _attributes ? _attributes[uniform] : -1;
        }

        public function getVaryLocation(uniform: String): int {
            return uniform in _varying ? _varying[uniform] : -1;
        }

        public function get agalVertexCode(): String {
            return _agalVertexCode;
        }

        public function get agalFragmentCode(): String {
            return _agalFragmentCode;
        }
    }
}

import babylon.zip.webgl.WebGLProgram;
import babylon.zip.webgl.WebGLUniformLocation;

import easiest.unit.Assert;

import flash.display3D.Context3DProgramType;

class Temporary extends WebGLUniformLocation{
    public function Temporary(name: String, programType: String, variableType: String, registers: Vector.<String>) {
        super(name, programType, variableType, registers);
    }

    public function equal(source: String): String {
        var result: String = "";

        switch (this._variableType) {
            case "float":
            case "vec2":
            case "vec3":
            case "vec4":
                result += "mov " + this.getRegister() + ", " + source + "\n";
                break;
            case "mat4":
                var numIndex: int;
                var numLastIndex: int = source.length;
                var rb: String = "";
                if (source.search(/\+/) != -1) {
                    // "vc[vc12.x+0]"
                    numIndex = source.search(/\+\d+/)+1;
                    numLastIndex = source.search(/]/);
                    rb = "]";
                } else {
                    // "vc12"
                    numIndex = source.search(/\d+/);
                }
                Assert.assertTrue1(numIndex != -1);

                var sourceRegister: String = source.substring(0, numIndex);
                var numStr: String = source.substring(numIndex, numLastIndex);
                Assert.assertTrue1(WebGLProgram.NUM_REG.test(numStr));

                var sourceIndex: int = parseInt(numStr);
                result += "mov " + this.getRegister(0) + "," + sourceRegister + sourceIndex + rb + "\n";
                result += "mov " + this.getRegister(1) + "," + sourceRegister + (sourceIndex+1) + rb + "\n";
                result += "mov " + this.getRegister(2) + "," + sourceRegister + (sourceIndex+2) + rb + "\n";
                result += "mov " + this.getRegister(3) + "," + sourceRegister + (sourceIndex+3) +rb + "\n";
                break;
            default:
                Assert.fail();
        }

        return result;
    }
}

class CustomKey {
    public static function isKey(line: String): Boolean {
        return line.indexOf("Transpose") != -1;
    }

    public static function generate(code: String, programType: String, webGLProgram: WebGLProgram): String {
        var keys: Array = code.split(/\(|\)|,/);

        switch (keys[0]) {
            case "Transpose":
                return generateTranspose(programType, webGLProgram, keys);
        }
        Assert.fail();
        return null;
    }

    public static function generateTranspose(programType: String, program: WebGLProgram, keys: Array): String {
        var matrixName: String = keys[1] as String;
        var matrix0: String = program.getSource(matrixName + "[0]");
        var matrix1: String = program.getSource(matrixName + "[1]");
        var matrix2: String = program.getSource(matrixName + "[2]");
        var matrix3: String = program.getSource(matrixName + "[3]");
        var result: String = "";

        var cache: Vector.<String> = programType == Context3DProgramType.VERTEX ? program._vertexTempCache : program._fragmentTempCache;
        var registers: Vector.<String> = program.getRegisters(cache, 1, false);
        var regName: String = programType == Context3DProgramType.VERTEX ? "vt" : "ft";
        var temp: Temporary = new Temporary(regName, programType, "float", registers);

        result += "mov " + temp.getRegister() + "," + matrix1 + ".x\n";
        result += "mov " + matrix1 + ".x," + matrix0 + ".y\n";
        result += "mov " + matrix0 + ".y," + temp.getRegister() + "\n";

        result += "mov " + temp.getRegister() + "," + matrix2 + ".x\n";
        result += "mov " + matrix2 + ".x," + matrix0 + ".z\n";
        result += "mov " + matrix0 + ".z," + temp.getRegister() + "\n";

        result += "mov " + temp.getRegister() + "," + matrix3 + ".x\n";
        result += "mov " + matrix3 + ".x," + matrix0 + ".w\n";
        result += "mov " + matrix0 + ".w," + temp.getRegister() + "\n";

        result += "mov " + temp.getRegister() + "," + matrix2 + ".y\n";
        result += "mov " + matrix2 + ".y," + matrix1 + ".z\n";
        result += "mov " + matrix1 + ".z," + temp.getRegister() + "\n";

        result += "mov " + temp.getRegister() + "," + matrix3 + ".y\n";
        result += "mov " + matrix3 + ".y," + matrix1 + ".w\n";
        result += "mov " + matrix1 + ".w," + temp.getRegister() + "\n";

        result += "mov " + temp.getRegister() + "," + matrix3 + ".z\n";
        result += "mov " + matrix3 + ".z," + matrix2 + ".w\n";
        result += "mov " + matrix2 + ".w," + temp.getRegister() + "\n";

        return result;
    }
}

class DefineFunc {
    public var params: Vector.<String>;
    public var code: String;
}

