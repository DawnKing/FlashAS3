/**
     * Created by caijingxiao on 2016/10/21.
     */
package easiest.rendering.materials
{
    import easiest.debug.Assert;

    import flash.utils.Dictionary;

    public class Shader
    {
        public static var format:String;
        private var _shader2agal:Shader2AGAL;

        public function Shader(shaderName:String)
        {
            loadVertexShader(shaderName, function(vertexCode:String):void
            {
                loadFragmentShader(shaderName, function(fragmentCode:String):void
                {
                    prepareShader(vertexCode, fragmentCode);
                });
            });
        }

        public function loadVertexShader(vertex:Object, callback:Function):void
        {
            // Is in local store ?
            if (shaderStore[vertex + "VertexShader"])
            {
                callback(Shader.shaderStore[vertex + "VertexShader"]);
                return;
            }
            Assert.fail("not has " + vertex + " shader file");
        }

        public function loadFragmentShader(fragment:Object, callback:Function):void
        {
            // Is in local store ?
            if (shaderStore[fragment + "PixelShader"])
            {
                callback(shaderStore[fragment + "PixelShader"]);
                return;
            }
            Assert.fail("not has " + fragment + " shader file");
        }

        private function prepareShader(vertexSourceCode:String, fragmentSourceCode:String):void
        {
            _shader2agal = new Shader2AGAL(vertexSourceCode, fragmentSourceCode);
        }

        public function get vertexCode():String
        {
            return _shader2agal.agalVertexCode;
        }

        public function get fragmentCode():String
        {
            return _shader2agal.agalFragmentCode;
        }

        [Embed(source="shaders/sprite.batching8.vertex.fx",mimeType = "application/octet-stream")]
        private static var spriteBatchingVertex:Class;
        [Embed(source="shaders/sprite.batching8.fragment.fx",mimeType = "application/octet-stream")]
        private static var spriteBatchingFragment:Class;

        [Embed(source="shaders/filter.vertex.fx",mimeType = "application/octet-stream")]
        private static var filterVertex:Class;
        [Embed(source="shaders/filter.color.fragment.fx",mimeType = "application/octet-stream")]
        private static var filterColorVertex:Class;

        private static var _shaderStore:Dictionary;
        public static function get shaderStore():Dictionary
        {
            if (!_shaderStore)
            {
                _shaderStore = new Dictionary(true);

                _shaderStore["spriteBatchingVertexShader"] = new spriteBatchingVertex().toString();
                _shaderStore["spriteBatchingPixelShader"] = new spriteBatchingFragment().toString();

                _shaderStore["filterColorVertexShader"] = new filterVertex().toString();
                _shaderStore["filterColorPixelShader"] = new filterColorVertex().toString();
            }
            return _shaderStore;
        }

        private static var _includeShaderStore:Dictionary;
        public static function get includeShaderStore():Dictionary
        {
            if (!_includeShaderStore)
            {
                _includeShaderStore = new Dictionary(true);
            }
            return _includeShaderStore;
        }
    }
}

import easiest.debug.Assert;
import easiest.rendering.Engine;
import easiest.rendering.materials.Shader;

import flash.display3D.Context3DProgramType;
import flash.utils.Dictionary;

class Shader2AGAL
{
    public static const AGALOp:Array = ["mov", "add", "sub", "mul", "div", "rcp", "frc", "neg", "sin", "cos", "min", "max", "sqt", "rsq", "pow", "log", "exp", "nrm", "abs", "sat", "crs", "dp3", "dp4", "m33", "m44", "m34", "kil", "seg", "slt", "tex"];
    public static const AttributeDefine:Array = ["float", "vec2", "vec3", "vec4", "mat2", "mat3", "mat4"];
    public static const NUM_REG:RegExp = /\d+/;

    private var _agalVertexCode:String;
    private var _agalFragmentCode:String;

    private var _attributes:Dictionary = new Dictionary(true);  // attribute - int
    private var _constants:Dictionary = new Dictionary(true);   // constant - WebGLUniformLocation
    private var _temporary:Dictionary = new Dictionary(true);    // temporary - Temporary
    private var _varying:Dictionary = new Dictionary(true);    // varying - int
    private var _sampler2D:Dictionary = new Dictionary(true);   // sampler - int
    private var _samplerCube:Dictionary = new Dictionary(true);

    private var _vertexTempCache:Vector.<String> = new Vector.<String>(Engine.MaxTemporary, true);
    private var _fragmentTempCache:Vector.<String> = new Vector.<String>(Engine.MaxTemporary, true);
    private var _vertexConstantCache:Vector.<String> = new Vector.<String>(Engine.MaxVertexConstant, true);
    private var _fragmentConstantCache:Vector.<String> = new Vector.<String>(Engine.MaxFragmentConstant, true);

    public function Shader2AGAL(vertexCode:String, fragmentCode:String) {
        vertexCode = formatAGAL(vertexCode);
        fragmentCode = formatAGAL(fragmentCode);

        parseCode(Context3DProgramType.VERTEX, vertexCode);
        parseCode(Context3DProgramType.FRAGMENT, fragmentCode);

        _agalVertexCode = toAgal(Context3DProgramType.VERTEX, vertexCode, true);
        _agalFragmentCode = toAgal(Context3DProgramType.FRAGMENT, fragmentCode, true);

        if (Engine.debug)
        {
            trace("------------vertex----------");
            trace(_agalVertexCode);
            trace("------------fragment----------");
            trace(_agalFragmentCode);
            trace("----------WebGLProgram---------");
        }
    }

    private function formatAGAL(s:String):String {
        var result:String = "";
        var lines:Array = s.split(/\n/);

        for (var i:int = 0; i < lines.length; i++) {
            var line:String = lines[i];
            if (line.indexOf("//") != -1)
            {
                line = line.substring(0, line.indexOf("//"));
                if (line == "")
                    continue;
            }
            if (line.search(/\S/) == -1)
                continue;

            while (line.indexOf("\t") >= 0)
                line = line.replace("\t", "");
            while (line.substr(0, 1) == " ")
                line = line.replace(" ", "");

            result += line + "\n";
        }

        const reg:RegExp = /\t|\r|;/;

        i = 0;
        while (result.search(reg) != -1) {
            result = result.replace(reg, "");

            Assert.assertTrue1(i++ < 10000);
        }
        return result;
    }

    private function parseCode(programType:String, code:String):void {
        var attributeCount:int = 0, varyingCount:int = 0, samplerCount:int = 0;

        var lines:Array = code.split(/\n/);

        var end:int = lines.indexOf("void main(void) {");
        if (end == -1)
            end = lines.length;

        for (var i:int = 0; i < end; i++) {
            var line:String = lines[i];

            var keys:Array = line.split(" ");

            if (line.indexOf("attribute") != -1) {
                parseKey(keys, attributeCount++, _attributes);
            } else if (line.indexOf("uniform") != -1) {
                if (line.indexOf("sampler2D") != -1) {
                    parseKey(keys, samplerCount++, _sampler2D);
                    continue;
                }

                if (line.indexOf("samplerCube") != -1) {
                    parseKey(keys, samplerCount++, _samplerCube);
                    continue;
                }

                parseUniform(programType, keys);
            } else if (line.indexOf("varying") != -1) {
                parseKey(keys, varyingCount++, _varying);
            }
        }

        Assert.assertTrue1(attributeCount <= Engine.MaxAttribute);
        Assert.assertTrue1(varyingCount <= Engine.MaxVarying);
        Assert.assertTrue1(samplerCount <= Engine.MaxSampler);
    }

    private function parseKey(keys:Array, index:int, dic:Dictionary):void {
        var name:String = keys[keys.length - 1];

        dic[name] = index;
    }

    private function parseUniform(programType:String, keys:Array):void {
        var type:String = keys[1];
        var name:String = keys[2];

        var numComponents:int = getNumComponents(type);

        if (name.indexOf("[") != -1) {
            var nameList:Array = name.split(/\[|\]/);
            name = nameList[0];

            var numStr:String = nameList[1];

            Assert.assertTrue1(NUM_REG.test(numStr));

            var length:int = parseInt(numStr);
            numComponents *= length;
        }

        var cache:Vector.<String> = programType == Context3DProgramType.VERTEX ? _vertexConstantCache :_fragmentConstantCache;
        var registers:Vector.<String> = getRegisters(cache, numComponents, true);

        var regName:String = programType == Context3DProgramType.VERTEX ? "vc" :"fc";

        Assert.assertFalse("vertex或fragment已经存在此变量名", name in _constants);

        if (Engine.debug)
            trace("Register[" + name + "]:", registers);
        _constants[name] = new Uniform(regName, programType, type, registers);
    }

    private function getNumComponents(type:String):int {
        switch (type) {
            case "float":return 1;
            case "vec2":return 2;
            case "vec3":return 3;
            case "vec4":return 4;
            case "mat2":return 8;
            case "mat3":return 12;
            case "mat4":return 16;
        }
        Assert.fail();
        return 0;
    }

    public function getRegisters(cache:Vector.<String>, numComponents:int, isUseRegister:Boolean):Vector.<String> {
        var registers:Vector.<String> = new <String>[];

        if (numComponents < 4) {
            var useRegisterIndex:int = -1;
            var components:String = "";

            // use register component, push number and components
            // first find the used register
            for (var registerIndex:int = 0; registerIndex < cache.length; registerIndex++) {
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

            var comStr:String = "";
            var numCom:int = 0;
            for (var regIdx:int = 0; regIdx < 4; regIdx++) {
                var newRegCom:String = "xyzw".charAt(regIdx);
                if (components.indexOf(newRegCom) == -1) {
                    comStr += newRegCom;
                    if (++numCom == numComponents)
                        break;
                }
            }

            Assert.assertEquals("", comStr.length, numComponents);

            var regStr:String = useRegisterIndex + "." + comStr;

            if (isUseRegister) {
                if (cache[useRegisterIndex])
                    cache[useRegisterIndex] += comStr;
                else
                    cache[useRegisterIndex] = comStr;
            }


            registers.push(regStr);
        } else {
            // use vector register, push number
            var numRegisters:int = numComponents / 4;

            for (registerIndex = 0; registerIndex < cache.length; registerIndex++) {
                if (cache[registerIndex] == null) {
                    // The registers must be continuous
                    for (var i:int = 0; i < numRegisters; i++) {
                        useRegisterIndex = registerIndex+i;

                        Assert.assertFalse("寄存器已经被占用", cache[useRegisterIndex]);

                        regStr = useRegisterIndex.toString();

                        if (isUseRegister)
                            cache[useRegisterIndex] = regStr;

                        registers.push(regStr);
                    }
                    break;
                }
            }
        }

        var reg:RegExp = new RegExp("\d+|\d+.x|\d+.xy|\d+.xyz|\d+.xyzw|");
        for each (var s:String in registers) {
            Assert.assertTrue1(reg.test(s));
        }
        Assert.assertTrue("not enough register!", registers.length != 0);

        return registers;
    }

    public function getSource(sourceStr:String):String {
        var keys:Array = sourceStr.split(/\[|\]|\./);

        for (var i:int = 0; i < keys.length; i++) {
            var key:String = keys[i];
            if (key === "")
                continue;
            if (key.search(/[a-zA-Z]+/) == -1)
                continue;
            if (AGALOp.indexOf(key) != -1)
                continue;
            var source:String = key;
            var firstRegister:int = -1;
            var extraInfo:String = "";
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
                {
                    // AGAL不支持形如vc[index].x的格式，只能是vc[index]
                    // 格式化vc[index]为vc[vt0.x]
                    extraInfo = "." + _temporary[key].components;
                }
            } else if (key in _varying) {
                source = "v";
                firstRegister = _varying[key];
            } else if (key in _sampler2D) {
                source = "fs";
                firstRegister = _sampler2D[key];
                if (Shader.format)
                    extraInfo = "<2d,"+Shader.format+",mipnone,wrap>";
                else
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
                var offsetStr:String = sourceStr.substring(sourceStr.lastIndexOf("[")+1, sourceStr.lastIndexOf("]"));
                Assert.assertTrue1(NUM_REG.test(offsetStr));

                var offset:int = parseInt(offsetStr);
                source += (firstRegister + offset);
                key = key + "[" + offset + "]";
            } else if (sourceStr.search(/\[\S+\]/) != -1) {
                if (i == 0) {
                    if (sourceStr.search(/\d+/) != -1) {
                        // replace variable such as "mBones[matricesIndices.x+0]"
                        // to the "vc[matricesIndices.x+(0+firstRegister)]"
                        var registerOffsetStr:String = sourceStr.substring(sourceStr.search(/\d+/), sourceStr.lastIndexOf("]"));
                        Assert.assertTrue1(NUM_REG.test(registerOffsetStr));

                        var registerOffset:int = parseInt(registerOffsetStr);
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

    private function toAgal(programType:String, shaderCode:String, isMain:Boolean):String {
        var result:String = "";
        var lines:Array = shaderCode.split(/\n/);

        if (isMain) {
            var begin:int = lines.indexOf("void main(void) {") + 1;

            Assert.assertTrue1(begin > 0);

            var end:int = lines.lastIndexOf("}");
        } else {
            begin = 0;
            end = lines.length;
        }

        for (var i:int = begin; i < end; i++) {
            var line:String = lines[i];

            var keys:Array = line.split(/[^a-z0-9=]?\s|</i);

            // temp variable declaration
            if (AttributeDefine.indexOf(keys[0]) != -1) {
                parseTemporary(programType, keys);
                continue;
            }

            if (keys[0] == "delete") {
                deleteTemporary(programType, keys);
                continue;
            }

            var lineCode:String = line;

            for each (var key:String in keys) {
                if (key == "")
                    continue;

                var source:String = getSource(key);
                lineCode = lineCode.replace(key, source);
            }
            result += lineCode;
            if (i != end - 1)
                result += "\n";
        }

        return result;
    }

    private function parseTemporary(programType:String, keys:Array):void {
        var varType:String = keys[0];
        var name:String = keys[1];

        var isUseRegister:Boolean = name.indexOf("temp") == -1;
        var numComponents:int = getNumComponents(varType);
        var cache:Vector.<String> = programType == Context3DProgramType.VERTEX ? _vertexTempCache :_fragmentTempCache;
        var registers:Vector.<String> = getRegisters(cache, numComponents, isUseRegister);

        var regName:String = programType == Context3DProgramType.VERTEX ? "vt" :"ft";
        var temp:Uniform = new Uniform(regName, programType, varType, registers);

        if (name.indexOf("temp") == -1)
            Assert.assertFalse("vertex或fragment已经存在此变量名", name in _temporary);
        _temporary[name] = temp;
    }

    private function deleteTemporary(programType:String, keys:Array):void {
        var name:String = keys[1];

        var temp:Uniform = _temporary[name];
        var cache:Vector.<String> = programType == Context3DProgramType.VERTEX ? _vertexTempCache :_fragmentTempCache;

        var cacheStr:String = cache[temp.firstRegister];
        var compStr:String = temp.components;

        Assert.assertNotNull1(cacheStr);

        if (NUM_REG.test(cacheStr)) {
            cache[temp.firstRegister] = null;
        } else {
            for (var i:int = 0; i < compStr.length; i++) {
                var s:String = compStr.charAt(i);
                var index:int = cacheStr.indexOf(s);

                Assert.assertFalse1(index == -1);

                cacheStr = cacheStr.replace(s, "");
            }

            cache[temp.firstRegister] = cacheStr == "" ? null :cacheStr;
        }
    }

    public function getUniformLocation(uniform:String):Uniform {
        return _constants[uniform];
    }

    public function getSamplerIndex(uniform:String):int {
        if (uniform in _samplerCube)
            return _samplerCube[uniform];
        return uniform in _sampler2D ? _sampler2D[uniform] :-1;
    }

    public function getAttributeLocation(uniform:String):int {
        return uniform in _attributes ? _attributes[uniform] :-1;
    }

    public function getVaryLocation(uniform:String):int {
        return uniform in _varying ? _varying[uniform] :-1;
    }

    public function get agalVertexCode():String {
        return _agalVertexCode;
    }

    public function get agalFragmentCode():String {
        return _agalFragmentCode;
    }
}


class Uniform {
    private var _name:String;
    private var _programType:String;
    private var _variableType:String;
    private var _registers:Vector.<String>;

    private var _firstRegister:Number;
    private var _componentIndex:Vector.<int> = new Vector.<int>(4, true);
    private var _components:String = "xyzw";

    public function Uniform(name:String, programType:String, variableType:String, registers:Vector.<String>) {
        _name = name;
        _programType = programType;
        _variableType = variableType;
        _registers = registers;

        if (_registers[0].indexOf(".") != -1) {
            _firstRegister = parseFloat(_registers[0].substring(0, _registers[0].indexOf(".")));
        } else {
            _firstRegister = parseFloat(_registers[0]);
        }

        Assert.assertFalse1(isNaN(_firstRegister));

        var dotIndex:int = _registers[0].indexOf(".");
        if (dotIndex != -1) {
            _components = _registers[0].substr(dotIndex+1);

            _componentIndex = new <int>[];
            var comps:String = components;

            for (var i:int = 0; i < comps.length; i++) {
                var comIdx:int = "xyzw".indexOf(comps.charAt(i));

                Assert.assertFalse1(comIdx == -1);

                _componentIndex[i] = comIdx;
            }
        } else {
            _componentIndex[0] = 0;
            _componentIndex[1] = 1;
            _componentIndex[2] = 2;
            _componentIndex[3] = 3;
        }
    }

    public function get name():String {
        return _name;
    }

    public function get programType():String {
        return _programType;
    }

    public function get firstRegister():int {
        return _firstRegister;
    }

    public function get componentIndex():Vector.<int> {
        return _componentIndex;
    }

    public function get components():String {
        return _components;
    }

    public function get numRegisters():int {
        return _registers.length;
    }

    public function getRegister(index:int = 0):String {
        return _name + _registers[index];
    }

    public function get variableType():String
    {
        return _variableType;
    }
}