/**
 * Created by caijingxiao on 2016/10/21.
 */
package babylon.materials {
    import babylon.Engine;
    import babylon.materials.textures.BaseTexture;
    import babylon.materials.textures.WebGLTexture;
    import babylon.math.Color3;
    import babylon.math.Matrix;
    import babylon.math.Vector2;
    import babylon.math.Vector3;
    import babylon.zip.webgl.WebGLProgram;
    import babylon.zip.webgl.WebGLUniformLocation;

    import easiest.unit.asserts.assertTrue;

    import easiest.unit.asserts.fail;

    import flash.display3D.Context3DProgramType;
    import flash.utils.Dictionary;

    public class Effect {
        public var name: Object;
        public var defines: String;
        public var onCompiled: Function;    // function(effect: Effect): void
        public var onError: Function;   // function(effect: Effect, errors: String): void
        public var onBind: Function;    // function(effect: Effect): void

        private var _engine: Engine;
        private var _uniformsNames: Vector.<String>;
        private var _samplers: Vector.<String>;
        private var _isReady: Boolean = false;
        private var _compilationError: String = "";

        private var _attributesNames: Vector.<String>;
        private var _attributes: Vector.<int>;
        private var _uniforms: Vector.<WebGLUniformLocation> = new <WebGLUniformLocation>[];
        public var _key: String;
        private var _indexParameters: Object;

        private var _program: WebGLProgram;

        private var _numVertexRegisters: int = 0;
        private var _vertexConstants: Vector.<Number> = new Vector.<Number>(Engine.MAX_CONSTANTS_LENGTH, true);
        private var _numFragmentRegisters: int = 0;
        private var _fragmentConstants: Vector.<Number> = new Vector.<Number>(Engine.MAX_CONSTANTS_LENGTH, true);

        public function Effect(baseName: Object, attributesNames: Vector.<String>, uniformsNames: Vector.<String>, samplers: Vector.<String>, engine: Engine, defines: String = null, onCompiled: Function = null, onError: Function = null, indexParameters: Object = null) {
            this._engine = engine;
            this.name = baseName;
            this.defines = defines;
            this._uniformsNames = uniformsNames.concat(samplers);
            this._samplers = samplers;
            this._attributesNames = attributesNames;

            this.onError = onError;
            this.onCompiled = onCompiled;

            this._indexParameters = indexParameters;

            var vertexSource: String = baseName.hasOwnProperty("vertex") ? baseName.vertex : String(baseName);
            var fragmentSource: String = baseName.hasOwnProperty("fragment") ? baseName.fragment : String(baseName);

            this._loadVertexShader(vertexSource, function(vertexCode: String): void {
                this._processIncludes(vertexCode, function(vertexCodeWithIncludes: String): void {
                    this._loadFragmentShader(fragmentSource, function(fragmentCode: String): void {
                        this._processIncludes(fragmentCode, function(fragmentCodeWithIncludes: String): void {
                            this._prepareEffect(vertexCodeWithIncludes, fragmentCodeWithIncludes, attributesNames, defines);
                        });
                    });
                });
            });
        }

        public function isReady(): Boolean {
            return this._isReady;
        }

        public function getProgram(): WebGLProgram {//133
            return this._program;
        }

        public function getAttributesNames(): Vector.<String> {
            return this._attributesNames;
        }

        public function getAttributeLocation(index: int): int {
            return this._attributes[index];
        }

        public function getUniform(uniformName: String): WebGLUniformLocation {
            var index: int = this._uniformsNames.indexOf(uniformName);
            assertTrue("The uniformName must be in uniforms before createEffect() or implement in shader file", index != -1);
            return this._uniforms[index];
        }

        public function _loadVertexShader(vertex: Object, callback: Function): void {//172
            // Is in local store ?
            if (ShadersStore[vertex + "VertexShader"]) {
                callback(Effect.ShadersStore[vertex + "VertexShader"]);
                return;
            }
            fail();
        }

        public function _loadFragmentShader(fragment: Object, callback: Function): void {
            // Is in local store ?
            if (ShadersStore[fragment + "PixelShader"]) {
                callback(ShadersStore[fragment + "PixelShader"]);
                return;
            }
            fail();
        }

        private function _processIncludes(sourceCode: String, callback: Function): void {//242
            var regex: RegExp = /#include<(.+)>(\((.*)\))*(\[(.*)\])*/g;
            var match: Object = regex.exec(sourceCode);

            var returnValue: String = sourceCode.slice();

            while (match != null) {
                var includeFile: String = match[1];

                if (IncludesShadersStore[includeFile]) {
                    // Substitution
                    var includeContent: String = IncludesShadersStore[includeFile];
                    if (match[2]) {
                        var splits: Array = match[3].split(",");

                        for (var index: int = 0; index < splits.length; index += 2) {
                            var source: RegExp = new RegExp(splits[index], "g");
                            var dest: String = splits[index + 1];

                            includeContent = includeContent.replace(source, dest);
                        }
                    }

                    if (match[4]) {
                        var indexString: String = match[5];

                        if (indexString.indexOf("..") !== -1) {
                            var indexSplits: Array = indexString.split("..");
                            var minIndex: int = parseInt(indexSplits[0]);
                            var maxIndex: int = parseInt(indexSplits[1]);
                            var sourceIncludeContent: String = includeContent.slice(0);
                            includeContent = "";

                            if (isNaN(maxIndex)) {
                                maxIndex = this._indexParameters[indexSplits[1]];
                            }

                            for (var i: int = minIndex; i <= maxIndex; i++) {
                                includeContent += sourceIncludeContent.replace(/\{X\}/g, i) + "\n";
                            }
                        } else {
                            includeContent = includeContent.replace(/\{X\}/g, indexString);
                        }
                    }

                    // Replace
                    returnValue = returnValue.replace(match[0], includeContent);
                } else {
                    fail();
                }

                match = regex.exec(sourceCode);
            }

            callback(returnValue);
        }

        private function _prepareEffect(vertexSourceCode: String, fragmentSourceCode: String, attributesName: Vector.<String>, defines: String): void {//321
            var engine: Engine = this._engine;

            this._program = engine.createShaderProgram(vertexSourceCode, fragmentSourceCode, defines);

            this._uniforms = engine.getUniforms(this._program, this._uniformsNames);
            this._attributes = engine.getAttributes(this._program, attributesName);

            for (var index: int = 0; index < this._samplers.length; index++) {
                var sampler: WebGLUniformLocation = this.getUniform(this._samplers[index]);

                if (sampler == null) {
                    this._samplers.splice(index, 1);
                    index--;
                }
            }

            engine.bindSamplers(this);

            this._isReady = true;
            if (this.onCompiled) {
                this.onCompiled(this);
            }
        }

        public function get isSupported(): Boolean {
            return this._compilationError === "";
        }

        public function _bindTexture(channel: String, texture: WebGLTexture): void {
            this._engine._bindTexture(this._samplers.indexOf(channel), texture);
        }

        public function setTexture(channel: String, texture: BaseTexture): void {//379
            this._engine.setTexture(this._samplers.indexOf(channel), texture._texture);
        }

        public function setMatrices(uniformName: String, matrices: Vector.<Number>, isTranspose: Boolean): Effect {//578
            var uniform: WebGLUniformLocation = this.getUniform(uniformName);
            if (!uniform)
                return this;

            var m: Vector.<Number> = matrices;
            if (isTranspose) {
                m = new <Number>[];
                for (var i: int = 0; i < matrices.length; i+=16) {
                    var t: Vector.<Number> = Matrix.CacheTransposeMatrices(matrices.slice(i, i+16));
                    m = m.concat(t);
                }
            }

            setConstantsVector(uniform, m);
            setNumConstants(uniform);

            return this;
        }

        public function setMatrix(uniformName: String, matrix: Matrix, isTranspose: Boolean): Effect {//585
            var uniform: WebGLUniformLocation = this.getUniform(uniformName);
            if (!uniform)
                return this;

            var m: Vector.<Number> = matrix.m;
            // matrix is on the right
            if (isTranspose)
                m = Matrix.CacheTransposeMatrices(m);

            setConstantsVector(uniform, m);
            setNumConstants(uniform);

            return this;
        }

        public function setFloat(uniformName: String, value: Number): Effect {//606
            var uniform: WebGLUniformLocation = this.getUniform(uniformName);
            if (!uniform)
                return this;

            var constants: Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants : _fragmentConstants;
            var registerIndex: int = uniform.firstRegister * 4;
            var componentIndex: Vector.<int> = uniform.componentIndex;
            constants[registerIndex + componentIndex[0]] = value;

            setNumConstants(uniform);

            return this;
        }

        public function setVector2(uniformName: String, vector: Vector2): Effect {
            this.setFloat2(uniformName, vector.x, vector.y);
            return this;
        }

        public function setFloat2(uniformName: String, x: Number, y: Number): Effect {//637
            var uniform: WebGLUniformLocation = this.getUniform(uniformName);
            if (!uniform)
                return this;

            var constants: Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants : _fragmentConstants;
            var registerIndex: int = uniform.firstRegister * 4;
            var componentIndex: Vector.<int> = uniform.componentIndex;
            constants[registerIndex + componentIndex[0]] = x;
            constants[registerIndex + componentIndex[1]] = y;

            setNumConstants(uniform);

            return this;
        }

        public function setVector3(uniformName: String, vector: Vector3): Effect {
            this.setFloat3(uniformName, vector.x, vector.y, vector.z);
            return this;
        }

        public function setFloat3(uniformName: String, x: Number, y: Number, z: Number): Effect {
            var uniform: WebGLUniformLocation = this.getUniform(uniformName);
            if (!uniform)
                return this;

            var constants: Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants : _fragmentConstants;
            var registerIndex: int = uniform.firstRegister * 4;
            constants[registerIndex+0] = x;
            constants[registerIndex+1] = y;
            constants[registerIndex+2] = z;

            setNumConstants(uniform);

            return this;
        }

        public function setFloat4(uniformName: String, x: Number, y: Number, z: Number, w: Number): Effect {//665
            var uniform: WebGLUniformLocation = this.getUniform(uniformName);
            if (!uniform)
                return this;

            var constants: Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants : _fragmentConstants;
            var registerIndex: int = uniform.firstRegister * 4;
            constants[registerIndex+0] = x;
            constants[registerIndex+1] = y;
            constants[registerIndex+2] = z;
            constants[registerIndex+3] = w;

            setNumConstants(uniform);

            return this;
        }

        public function setColor3(uniformName: String, color3: Color3): Effect {
            this.setFloat3(uniformName, color3.r, color3.g, color3.b);
            return this;
        }

        public function setColor4(uniformName: String, color3: Color3, alpha: Number): Effect {
            this.setFloat4(uniformName, color3.r, color3.g, color3.b, alpha);
            return this;
        }

        private function setConstantsVector(uniform: WebGLUniformLocation, vector: Vector.<Number>): void {
            var constants: Vector.<Number> = uniform.programType == Context3DProgramType.VERTEX ? _vertexConstants : _fragmentConstants;
            var registerIndex: int = uniform.firstRegister * 4;
            var registerLength: int = registerIndex + uniform.numRegisters * 4;
            for (var i: int = registerIndex; i < registerLength; i++) {
                constants[i] = vector[i - registerIndex];
            }
        }

        private function setNumConstants(uniform: WebGLUniformLocation): void {
            // only first component is zero then add a new register
            if (uniform.componentIndex[0] != 0)
                return;
            if (uniform.programType == Context3DProgramType.VERTEX)
                this._numVertexRegisters += uniform.numRegisters;
            else
                this._numFragmentRegisters += uniform.numRegisters;
        }

        public function get numVertexRegisters(): int {
            return this._numVertexRegisters;
        }

        public function get vertexConstants(): Vector.<Number> {
            return this._vertexConstants;
        }

        public function get numFragmentRegisters(): int {
            return this._numFragmentRegisters;
        }

        public function get fragmentConstants(): Vector.<Number> {
            return this._fragmentConstants;
        }

        public function reset(): void {
            this._numVertexRegisters = 0;
            this._numFragmentRegisters = 0;
        }

        [Embed(source="../shaders/color.vertex.fx",mimeType = "application/octet-stream")]
        private static var colorVertex:Class;
        [Embed(source="../shaders/color.fragment.fx",mimeType = "application/octet-stream")]
        private static var colorFragment:Class;

        [Embed(source="../shaders/default.vertex.fx",mimeType = "application/octet-stream")]
        private static var defaultVertex:Class;
        [Embed(source="../shaders/default.fragment.fx",mimeType = "application/octet-stream")]
        private static var defaultFragment:Class;

        [Embed(source="../shaders/particles.vertex.fx",mimeType = "application/octet-stream")]
        private static var particlesVertex:Class;
        [Embed(source="../shaders/particles.fragment.fx",mimeType = "application/octet-stream")]
        private static var particlesFragment:Class;

        [Embed(source="../shaders/texture.vertex.fx",mimeType = "application/octet-stream")]
        private static var textureVertex:Class;
        [Embed(source="../shaders/texture.fragment.fx",mimeType = "application/octet-stream")]
        private static var textureFragment:Class;

        [Embed(source="../shaders/shadowMap.vertex.fx",mimeType = "application/octet-stream")]
        private static var shadowMapVertex:Class;
        [Embed(source="../shaders/shadowMap.fragment.fx",mimeType = "application/octet-stream")]
        private static var shadowMapFragment:Class;

        private static var _shadersStore:Dictionary;
        public static function get ShadersStore(): Dictionary {
            if (!_shadersStore) {
                _shadersStore = new Dictionary(true);
                _shadersStore["colorVertexShader"] = new colorVertex().toString();
                _shadersStore["colorPixelShader"] = new colorFragment().toString();

                _shadersStore["defaultVertexShader"] = new defaultVertex().toString();
                _shadersStore["defaultPixelShader"] = new defaultFragment().toString();

                _shadersStore["instancesDeclaration"] = new instancesDeclaration().toString();
                _shadersStore["instancesVertex"] = new instancesVertex().toString();

                _shadersStore["bonesDeclaration"] = new bonesDeclaration().toString();
                _shadersStore["bonesVertex"] = new bonesVertex().toString();

                _shadersStore["particlesVertexShader"] = new particlesVertex().toString();
                _shadersStore["particlesPixelShader"] = new particlesFragment().toString();

                _shadersStore["textureVertexShader"] = new textureVertex().toString();
                _shadersStore["texturePixelShader"] = new textureFragment().toString();

                _shadersStore["shadowMapVertexShader"] = new shadowMapVertex().toString();
                _shadersStore["shadowMapPixelShader"] = new shadowMapFragment().toString();
            }
            return _shadersStore;
        }

        [Embed(source="../shaders/include/instancesDeclaration.fx",mimeType = "application/octet-stream")]
        private static var instancesDeclaration:Class;
        [Embed(source="../shaders/include/instancesVertex.fx",mimeType = "application/octet-stream")]
        private static var instancesVertex:Class;

        [Embed(source="../shaders/include/bonesDeclaration.fx",mimeType = "application/octet-stream")]
        private static var bonesDeclaration:Class;
        [Embed(source="../shaders/include/bonesVertex.fx",mimeType = "application/octet-stream")]
        private static var bonesVertex:Class;

        [Embed(source="../shaders/include/lightFragmentDeclaration.fx",mimeType = "application/octet-stream")]
        private static var lightFragmentDeclaration:Class;
        [Embed(source="../shaders/include/lightsFragmentFunctions.fx",mimeType = "application/octet-stream")]
        private static var lightsFragmentFunctions:Class;
        [Embed(source="../shaders/include/lightFragment.fx",mimeType = "application/octet-stream")]
        private static var lightFragment:Class;

        [Embed(source="../shaders/include/shadowsFragmentFunctions.fx",mimeType = "application/octet-stream")]
        private static var shadowsFragmentFunctions:Class;

        private static var _includesShadersStore:Dictionary;
        public static function get IncludesShadersStore(): Dictionary {
            if (!_includesShadersStore) {
                _includesShadersStore = new Dictionary(true);
                _includesShadersStore["instancesDeclaration"] = new instancesDeclaration().toString();
                _includesShadersStore["instancesVertex"] = new instancesVertex().toString();

                _includesShadersStore["bonesDeclaration"] = new bonesDeclaration().toString();
                _includesShadersStore["bonesVertex"] = new bonesVertex().toString();

                _includesShadersStore["lightFragmentDeclaration"] = new lightFragmentDeclaration().toString();
                _includesShadersStore["lightsFragmentFunctions"] = new lightsFragmentFunctions().toString();
                _includesShadersStore["lightFragment"] = new lightFragment().toString();

                _includesShadersStore["shadowsFragmentFunctions"] = new shadowsFragmentFunctions().toString();
            }
            return _includesShadersStore;
        }
    }
}
