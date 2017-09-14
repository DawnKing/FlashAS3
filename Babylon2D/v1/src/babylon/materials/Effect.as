/**
 * Created by caijingxiao on 2016/10/21.
 */
package babylon.materials
{
    import babylon.Engine;
    import babylon.materials.textures.BaseTexture;
    import babylon.materials.textures.WebGLTexture;
    import babylon.math.Color3;
    import babylon.math.Matrix;
    import babylon.math.Vector2;
    import babylon.math.Vector3;
    import babylon.zip.webgl.WebGLProgram;
    import babylon.zip.webgl.WebGLUniformLocation;

    import easiest.unit.Assert;

    import flash.display3D.Context3DProgramType;
    import flash.utils.Dictionary;

    public class Effect
    {
        public var name:Object;
        public var defines:String;
        public var onCompiled:Function;    // function(effect:Effect):void
        public var onError:Function;   // function(effect:Effect, errors:String):void
        public var onBind:Function;    // function(effect:Effect):void

        private var _engine:Engine;
        private var _uniformsNames:Vector.<String>;
        private var _samplers:Vector.<String>;
        private var _isReady:Boolean = false;

        private var _attributesNames:Vector.<String>;
        private var _attributes:Vector.<int>;
        private var _uniforms:Vector.<WebGLUniformLocation> = new <WebGLUniformLocation>[];
        public var _key:String;
        private var _indexParameters:Object;

        private var _program:WebGLProgram;

        private var _numVertexRegisters:int = 0;
        private var _vertexConstants:Vector.<Number> = new Vector.<Number>(Engine.MAX_CONSTANTS_LENGTH, true);
        private var _numFragmentRegisters:int = 0;
        private var _fragmentConstants:Vector.<Number> = new Vector.<Number>(Engine.MAX_CONSTANTS_LENGTH, true);

        public function Effect(baseName:Object, attributesNames:Vector.<String>, uniformsNames:Vector.<String>, samplers:Vector.<String>, engine:Engine, defines:String = null, onCompiled:Function = null, onError:Function = null, indexParameters:Object = null)
        {
            _engine = engine;
            name = baseName;
            this.defines = defines;
            _uniformsNames = uniformsNames.concat(samplers);
            _samplers = samplers;
            _attributesNames = attributesNames;

            this.onError = onError;
            this.onCompiled = onCompiled;

            _indexParameters = indexParameters;

            var vertexSource:String = baseName.hasOwnProperty("vertex") ? baseName.vertex :String(baseName);
            var fragmentSource:String = baseName.hasOwnProperty("fragment") ? baseName.fragment :String(baseName);

            _loadVertexShader(vertexSource, function(vertexCode:String):void
            {
                _processIncludes(vertexCode, function(vertexCodeWithIncludes:String):void
                {
                    _loadFragmentShader(fragmentSource, function(fragmentCode:String):void
                    {
                        _processIncludes(fragmentCode, function(fragmentCodeWithIncludes:String):void
                        {
                            _prepareEffect(vertexCodeWithIncludes, fragmentCodeWithIncludes, attributesNames, defines);
                        });
                    });
                });
            });
        }

        public function isReady():Boolean
        {
            return _isReady;
        }

        public function getProgram():WebGLProgram
        {
            return _program;
        }

        public function getAttributesNames():Vector.<String>
        {
            return _attributesNames;
        }

        public function getAttributeLocation(index:int):int
        {
            return _attributes[index];
        }

        public function getUniform(uniformName:String):WebGLUniformLocation
        {
            var index:int = _uniformsNames.indexOf(uniformName);
            CONFIG::debug
            {
                Assert.assertTrue("The uniformName must be in uniforms before createEffect() or implement in shader file", index != -1);
            }
            return this._uniforms[index];
        }

        public function _loadVertexShader(vertex:Object, callback:Function):void
        {
            // Is in local store ?
            if (shaderStore[vertex + "VertexShader"])
            {
                callback(Effect.shaderStore[vertex + "VertexShader"]);
                return;
            }
            Assert.fail("not has " + vertex + " shader file");
        }

        public function _loadFragmentShader(fragment:Object, callback:Function):void
        {
            // Is in local store ?
            if (shaderStore[fragment + "PixelShader"])
            {
                callback(shaderStore[fragment + "PixelShader"]);
                return;
            }
            Assert.fail("not has " + fragment + " shader file");
        }

        private function _processIncludes(sourceCode:String, callback:Function):void
        {
            var regex:RegExp = /#include<(.+)>(\((.*)\))*(\[(.*)\])*/g;
            var match:Object = regex.exec(sourceCode);

            var returnValue:String = sourceCode.slice();

            while (match != null)
            {
                var includeFile:String = match[1];

                if (includeShaderStore[includeFile])
                {
                    // Substitution
                    var includeContent:String = includeShaderStore[includeFile];
                    if (match[2]) {
                        var splits:Array = match[3].split(",");

                        for (var index:int = 0; index < splits.length; index += 2)
                        {
                            var source:RegExp = new RegExp(splits[index], "g");
                            var dest:String = splits[index + 1];

                            includeContent = includeContent.replace(source, dest);
                        }
                    }

                    if (match[4])
                    {
                        var indexString:String = match[5];

                        if (indexString.indexOf("..") !== -1) {
                            var indexSplits:Array = indexString.split("..");
                            var minIndex:int = parseInt(indexSplits[0]);
                            var maxIndex:int = parseInt(indexSplits[1]);
                            var sourceIncludeContent:String = includeContent.slice(0);
                            includeContent = "";

                            if (isNaN(maxIndex))
                            {
                                maxIndex = this._indexParameters[indexSplits[1]];
                            }

                            for (var i:int = minIndex; i <= maxIndex; i++)
                            {
                                includeContent += sourceIncludeContent.replace(/\{X\}/g, i) + "\n";
                            }
                        }
                        else
                        {
                            includeContent = includeContent.replace(/\{X\}/g, indexString);
                        }
                    }

                    // Replace
                    returnValue = returnValue.replace(match[0], includeContent);
                }
                else
                {
                    Assert.fail();
                }

                match = regex.exec(sourceCode);
            }

            callback(returnValue);
        }

        private function _prepareEffect(vertexSourceCode:String, fragmentSourceCode:String, attributesName:Vector.<String>, defines:String):void
        {
            var engine:Engine = this._engine;

            _program = engine.createShaderProgram(vertexSourceCode, fragmentSourceCode, defines);

            _uniforms = engine.getUniforms(this._program, this._uniformsNames);
            _attributes = engine.getAttributes(this._program, attributesName);

            for (var index:int = 0; index < _samplers.length; index++)
            {
                var sampler:WebGLUniformLocation = getUniform(_samplers[index]);

                if (sampler == null)
                {
                    _samplers.splice(index, 1);
                    index--;
                }
            }

            engine.bindSamplers(this);

            _isReady = true;
            if (onCompiled)
            {
                onCompiled(this);
            }
        }

        public function _bindTexture(channel:String, texture:WebGLTexture):void
        {
            _engine._bindTexture(_samplers.indexOf(channel), texture);
        }

        public function setTexture(channel:String, texture:BaseTexture):void
        {
            _engine.setTexture(_samplers.indexOf(channel), texture._texture);
        }

        public function setMatrices(uniformName:String, matrices:Vector.<Number>, isTranspose:Boolean):Effect
        {
            var uniform:WebGLUniformLocation = getUniform(uniformName);
            if (!uniform)
                return this;

            var m:Vector.<Number> = matrices;
            if (isTranspose)
            {
                m = new <Number>[];
                for (var i:int = 0; i < matrices.length; i+=16)
                {
                    var t:Vector.<Number> = Matrix.CacheTransposeMatrices(matrices.slice(i, i+16));
                    m = m.concat(t);
                }
            }

            setConstantsVector(uniform, m);
            setNumConstants(uniform);

            return this;
        }

        public function setMatrix(uniformName:String, matrix:Matrix, isTranspose:Boolean):Effect
        {
            var uniform:WebGLUniformLocation = getUniform(uniformName);
            if (!uniform)
                return this;

            var m:Vector.<Number> = matrix.m;
            // matrix is on the right
            if (isTranspose)
                m = Matrix.CacheTransposeMatrices(m);

            setConstantsVector(uniform, m);
            setNumConstants(uniform);

            return this;
        }

        public function setFloat(uniformName:String, value:Number):Effect
        {
            var uniform:WebGLUniformLocation = getUniform(uniformName);
            if (!uniform)
                return this;

            var constants:Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants :_fragmentConstants;
            var registerIndex:int = uniform.firstRegister * 4;
            var componentIndex:Vector.<int> = uniform.componentIndex;
            constants[registerIndex + componentIndex[0]] = value;

            setNumConstants(uniform);
            return this;
        }

        public function setVector2(uniformName:String, vector:Vector2):Effect
        {
            setFloat2(uniformName, vector.x, vector.y);
            return this;
        }

        public function setFloat2(uniformName:String, x:Number, y:Number):Effect
        {
            var uniform:WebGLUniformLocation = getUniform(uniformName);
            if (!uniform)
                return this;

            var constants:Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants :_fragmentConstants;
            var registerIndex:int = uniform.firstRegister * 4;
            var componentIndex:Vector.<int> = uniform.componentIndex;
            constants[registerIndex + componentIndex[0]] = x;
            constants[registerIndex + componentIndex[1]] = y;

            setNumConstants(uniform);
            return this;
        }

        public function setVector3(uniformName:String, vector:Vector3):Effect
        {
            setFloat3(uniformName, vector.x, vector.y, vector.z);
            return this;
        }

        public function setFloat3(uniformName:String, x:Number, y:Number, z:Number):Effect
        {
            var uniform:WebGLUniformLocation = getUniform(uniformName);
            if (!uniform)
                return this;

            var constants:Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants :_fragmentConstants;
            var registerIndex:int = uniform.firstRegister * 4;
            constants[registerIndex + 0] = x;
            constants[registerIndex + 1] = y;
            constants[registerIndex + 2] = z;

            setNumConstants(uniform);
            return this;
        }

        public function setFloat4(uniformName:String, x:Number, y:Number, z:Number, w:Number):Effect
        {
            var uniform:WebGLUniformLocation = getUniform(uniformName);
            if (!uniform)
                return this;

            var constants:Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants :_fragmentConstants;
            var registerIndex:int = uniform.firstRegister * 4;
            constants[registerIndex+0] = x;
            constants[registerIndex+1] = y;
            constants[registerIndex+2] = z;
            constants[registerIndex+3] = w;

            setNumConstants(uniform);
            return this;
        }

        public function setColor3(uniformName:String, color3:Color3):Effect
        {
            setFloat3(uniformName, color3.r, color3.g, color3.b);
            return this;
        }

        public function setColor4(uniformName:String, color3:Color3, alpha:Number):Effect
        {
            setFloat4(uniformName, color3.r, color3.g, color3.b, alpha);
            return this;
        }

        private function setConstantsVector(uniform:WebGLUniformLocation, vector:Vector.<Number>):void
        {
            var constants:Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants :_fragmentConstants;
            var registerIndex:int = uniform.firstRegister * 4;
            var registerLength:int = registerIndex + uniform.numRegisters * 4;
            for (var i:int = registerIndex; i < registerLength; i++)
            {
                constants[i] = vector[i - registerIndex];
            }
        }

        private function setNumConstants(uniform:WebGLUniformLocation):void
        {
            // only first component is zero then add a new register
            if (uniform.componentIndex[0] != 0)
                return;
            if (uniform.programType == Context3DProgramType.VERTEX)
                _numVertexRegisters += uniform.numRegisters;
            else
                _numFragmentRegisters += uniform.numRegisters;
        }

        public function get numVertexRegisters():int
        {
            return _numVertexRegisters;
        }

        public function get vertexConstants():Vector.<Number>
        {
            return _vertexConstants;
        }

        public function get numFragmentRegisters():int
        {
            return _numFragmentRegisters;
        }

        public function get fragmentConstants():Vector.<Number>
        {
            return _fragmentConstants;
        }

        public function reset():void {
            _numVertexRegisters = 0;
            _numFragmentRegisters = 0;
        }

        [Embed(source="../shaders/sprite.vertex.fx",mimeType = "application/octet-stream")]
        private static var spriteVertex:Class;
        [Embed(source="../shaders/sprite.fragment.fx",mimeType = "application/octet-stream")]
        private static var spriteFragment:Class;

        [Embed(source="../shaders/map.vertex.fx",mimeType = "application/octet-stream")]
        private static var mapVertex:Class;
        [Embed(source="../shaders/map.fragment.fx",mimeType = "application/octet-stream")]
        private static var mapFragment:Class;

        [Embed(source="../shaders/char.vertex.fx",mimeType = "application/octet-stream")]
        private static var charVertex:Class;
        [Embed(source="../shaders/char.fragment.fx",mimeType = "application/octet-stream")]
        private static var charFragment:Class;

        [Embed(source="../shaders/effect.vertex.fx",mimeType = "application/octet-stream")]
        private static var effectVertex:Class;
        [Embed(source="../shaders/effect.fragment.fx",mimeType = "application/octet-stream")]
        private static var effectFragment:Class;

        private static var _shaderStore:Dictionary;
        public static function get shaderStore():Dictionary
        {
            if (!_shaderStore)
            {
                _shaderStore = new Dictionary(true);

                _shaderStore["spriteVertexShader"] = new spriteVertex().toString();
                _shaderStore["spritePixelShader"] = new spriteFragment().toString();

                _shaderStore["mapVertexShader"] = new mapVertex().toString();
                _shaderStore["mapPixelShader"] = new mapFragment().toString();

                _shaderStore["charVertexShader"] = new charVertex().toString();
                _shaderStore["charPixelShader"] = new charFragment().toString();

                _shaderStore["effectVertexShader"] = new effectVertex().toString();
                _shaderStore["effectPixelShader"] = new effectFragment().toString();
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
