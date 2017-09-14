package babylon {
    import babylon.cameras.Camera;
    import babylon.materials.Effect;
    import babylon.materials.textures.WebGLTexture;
    import babylon.math.Color4;
    import babylon.math.Matrix;
    import babylon.math.Tmp;
    import babylon.math.Viewport;
    import babylon.mesh.VertexBuffer;
    import babylon.states.AlphaCullingState;
    import babylon.states.DepthCullingState;
    import babylon.states.StencilState;
    import babylon.tools.PerfCounter;
    import babylon.tools.Tools;
    import babylon.zip.EngineCapabilities;
    import babylon.zip.webgl.WebGLProgram;
    import babylon.zip.webgl.WebGLUniformLocation;

    import com.adobe.utils.AGALMiniAssembler;

    import easiest.core.EasiestCore;
    import easiest.events.Stage3DEvent;
    import easiest.unit.asserts.assertEquals;

    import flash.display.BitmapData;
    import flash.display.Stage;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DClearMask;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Context3DTriangleFace;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
    import flash.display3D.textures.CubeTexture;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    [Event(name = "ViewportUpdated", type="easiest.events.Stage3DEvent")]
    [Event(name = "Context3DCreated", type="easiest.events.Stage3DEvent")]
    [Event(name = "Context3DDisposed", type="easiest.events.Stage3DEvent")]
    [Event(name = "Context3DRecreated", type="easiest.events.Stage3DEvent")]

    public class Engine extends EventDispatcher {
        public static var debug: Boolean = true;

        public static const MAX_VERTEX_BUFFER: int = 8;
        public static const MAX_TEXTURE: int = 8;
        public static const MAX_CONSTANTS: int = 128;
        public static const MAX_CONSTANTS_LENGTH: int = MAX_CONSTANTS * 4;

        // Const statics
        public static const ALPHA_DISABLE: int = 0;
        public static const ALPHA_ADD: int = 1;
        public static const ALPHA_COMBINE: int = 2;
        public static const ALPHA_SUBTRACT: int = 3;
        public static const ALPHA_MULTIPLY: int = 4;
        public static const ALPHA_MAXIMIZED: int = 5;
        public static const ALPHA_ONEONE: int = 6;

        public static const DELAYLOADSTATE_NONE: int = 0;
        public static const DELAYLOADSTATE_LOADED: int = 1;
        public static const DELAYLOADSTATE_LOADING: int = 2;
        public static const DELAYLOADSTATE_NOTLOADED: int = 4;

        public static const TEXTUREFORMAT_ALPHA: int = 0;
        public static const TEXTUREFORMAT_LUMINANCE: int = 1;
        public static const TEXTUREFORMAT_LUMINANCE_ALPHA: int = 2;
        public static const TEXTUREFORMAT_RGB: int = 4;
        public static const TEXTUREFORMAT_RGBA: int = 5;

        public static const TEXTURETYPE_UNSIGNED_INT: int = 0;
        public static const TEXTURETYPE_FLOAT: int = 1;
        public static const TEXTURETYPE_HALF_FLOAT: int = 2;

        private var _stage:Stage;
        private var _stage3D:Stage3D;

        // Public members
        public var isPointerLock: Boolean = false;
        public var cullBackFaces: Boolean = true;
        public var renderEvenInBackground:Boolean = true;

        public var scenes:Vector.<Scene> = new <Scene>[];

        // Private Members
        public var _context3D:Context3D;

        private var _caps: EngineCapabilities = new EngineCapabilities();

        private var _isStencilEnable: Boolean;

        private var _alphaTest: Boolean;

        public var _drawCalls: PerfCounter = new PerfCounter();

        private var _renderingQueueLaunched:Boolean = false;
        private var _activeRenderLoops:Array = [];

        // FPS
        private static const FPS_RANGE: int = 60;
        private var _fpsIndex: int = 0;
        private var previousFramesDuration: Vector.<Number> = new Vector.<Number>(FPS_RANGE, true);
        private var fps: int = 60;
        private var deltaTime: Number = 0;

        // States
        private var _depthCullingState:DepthCullingState = new DepthCullingState();
        private var _stencilState:StencilState = new StencilState();
        private var _alphaState:AlphaCullingState = new AlphaCullingState();
        private var _alphaMode: int = ALPHA_DISABLE;

        // Cache
        private var _loadedTexturesCache: Vector.<WebGLTexture> = new <WebGLTexture>[];

        private var _compiledEffects: Object = {};

        private var _currentEffect: Effect;
        private var _programChanged: Boolean = true;
        private var _currentProgram: WebGLProgram;

        private var _cachedViewport: Viewport = new Viewport(0, 0, 1, 1);
        private var _cachedVertexBuffers: Object;
        private var _cachedIndexBuffer: IndexBuffer3D;
        private var _cachedEffectForVertexBuffers: Effect;

        private var _usedTexture: Vector.<Boolean> = new Vector.<Boolean>(MAX_TEXTURE, true);
        private var _usedTextureCache: Vector.<Object> = new Vector.<Object>(MAX_TEXTURE, true);

        private var _usedVertexBuffer: Vector.<Boolean> = new Vector.<Boolean>(MAX_VERTEX_BUFFER, true);
        private var _usedVertexBufferCache: Vector.<Object> = new Vector.<Object>(MAX_VERTEX_BUFFER, true);

        private var _cacheContext3D: Dictionary = new Dictionary(true);

        public var _antiAlias: int = 2;
        public var _enableDepthAndStencil: Boolean = true;
        private var _cacheBackBuffer: Object = {width:0,height:0,antiAlias:0,enableDepthAndStencil:true};

        public function Engine(stage:Stage) {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.stageFocusRect = false;

            EasiestCore.start(stage, true);

            _stage = stage;
            _stage3D = _stage.stage3Ds[0];
        }

        public function init():void {
            // whatever happens, be sure this has highest priority
            _stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate, false, int.MAX_VALUE, false);
            _stage3D.requestContext3DMatchingProfiles(Context3DProfiles.getMatchingProfiles());
        }

        private function onContext3DUpdate(event:Event):void {
            if (!_stage3D.context3D)
                throw new Error("Rendering webgl lost!");

            var hadContext:Boolean = (_context3D != null);
            _context3D = _stage3D.context3D;
            _context3D.enableErrorChecking = true;

            // Dispatch the appropriate event depending on whether webgl was
            // created for the first time or recreated after a device loss.
            if(hadContext) {
                if(hasEventListener(Stage3DEvent.CONTEXT3D_RECREATED))
                    dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_RECREATED));
            } else if(hasEventListener(Stage3DEvent.CONTEXT3D_CREATED)) {
                dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_CREATED));

                setViewport(this._cachedViewport);
            }

            Tools.Log("Babylon.as engine (v" + Version + ") launched");
        }

        public static function get Version():String {//381
            return "2.5.-beta";
        }

        public function getGlInfo(): String {//696
            return this._context3D.driverInfo;
        }

        /**
         * Returns true if the stencil buffer has been enabled through the creation option of the context.
         */
        public function get isStencilEnable(): Boolean {
            return this._isStencilEnable;
        }

        public function resetTextureCache(): void {
//            for (var index = 0; index < this._maxTextureChannels; index++) {
//                this._activeTexturesCache[index] = null;
//            }
            for (i = 0; i < this._usedTexture.length; i++) {
                this._usedTexture[i] = false;
            }

            for (var i: int = 0; i < this._usedVertexBuffer.length; i++) {
                this._usedVertexBuffer[i] = false;
            }
        }

        public function getAspectRatio(camera: Camera): Number {//704
            var viewport: Viewport = camera.viewport;
            return (this.getRenderWidth() * viewport.width) / (this.getRenderHeight() * viewport.height);
        }

        public function getRenderWidth(): Number {
            return this._stage.stageWidth;
        }

        public function getRenderHeight(): Number {
            return this._stage.stageHeight;
        }

        public function getRenderingCanvas(): Stage {//725
            return this._stage;
        }

        public function getRenderingCanvasClientRect(): Rectangle {//725
            return new Rectangle(0, 0, this._stage.stageWidth, this._stage.stageHeight);
        }

        public function getCaps(): EngineCapabilities {
            return this._caps;
        }

        public function get drawCalls(): Number {
            return this._drawCalls.current;
        }

        public function get drawCallsPerfCounter(): PerfCounter {//754
            return this._drawCalls;
        }

        public function setDepthFunctionToLessOrEqual(): void {
            this._depthCullingState.depthFunc = Context3DCompareMode.LESS_EQUAL;
        }

        public function _renderLoop(event: Event):void {//860
            var shouldRender:Boolean = true;
            if (!renderEvenInBackground) {
                shouldRender = false;
            }

            if (shouldRender) {
                // Start new frame
                beginFrame();

                for (var index:int = 0; index < _activeRenderLoops.length; index++) {
                    var renderFunction:Function = _activeRenderLoops[index];

                    renderFunction();
                }

                // Present
                endFrame();
            }
        }

        public function runRenderLoop(renderFunction:Function):void {//896
            if (_activeRenderLoops.indexOf(renderFunction) != -1) {
                return;
            }

            _activeRenderLoops.push(renderFunction);

            if (!_renderingQueueLaunched) {
                _renderingQueueLaunched = true;
                _stage.addEventListener(Event.ENTER_FRAME, _renderLoop);
            }
        }

        public function clear(color: Color4, backBuffer: Boolean, depth: Boolean, stencil: Boolean = false):void {//924
            applyStates();

            var mode:int = 0;
            if (backBuffer) {
                mode |= Context3DClearMask.COLOR;
            }
            if (depth) {
                mode |= Context3DClearMask.DEPTH;
            }
            if (stencil) {
                mode |= Context3DClearMask.STENCIL;
            }

            if (color) {
                this._context3D.clear(
                        color.r, color.g, color.b, color.a,
                        1.0,    // depth
                        0,      // stencil
                        mode);  // mask
            } else {
                this._context3D.clear(
                        0, 0, 0, 0, // color
                        1.0,    // depth
                        0,      // stencil
                        mode);  // mask
            }
        }

        public function setViewport(viewport:Viewport, requiredWidth: Number = NaN, requiredHeight: Number = NaN):void {//973
            var width: Number = requiredWidth || this.getRenderWidth();
            var height: Number = requiredHeight || this.getRenderHeight();

            width *= viewport.width;
            height *= viewport.height;

            if (width == this._cacheBackBuffer.width && height == this._cacheBackBuffer.height &&
                    this._antiAlias === this._cacheBackBuffer.antiAlias && this._enableDepthAndStencil == this._cacheBackBuffer.enableDepthAndStencil)
                return;

            this._cacheBackBuffer.width = width;
            this._cacheBackBuffer.height = height;
            this._cacheBackBuffer.antiAlias = this._antiAlias;
            this._cacheBackBuffer.enableDepthAndStencil = this._enableDepthAndStencil;

            this._cachedViewport = viewport;

            this._context3D.configureBackBuffer(width, height, _antiAlias, _enableDepthAndStencil);
        }

        private function beginFrame():void {//998
            this._measureFps();

            resetTextureCache();
        }

        private function endFrame():void {//1002
            this._context3D.present();
        }

        public function resize(): void {
            this.setSize(_stage.stageWidth, _stage.stageHeight);

            for (var index: int = 0; index < this.scenes.length; index++) {
                var scene: Scene = this.scenes[index];
                if (scene._debugLayer && scene.debugLayer.isVisible()) {
                    scene.debugLayer._syncPositions();
                }
            }
        }

        public function setSize(width: Number, height: Number): void {
            this.setViewport(this._cachedViewport, width, height);

            for (var index: int = 0; index < this.scenes.length; index++) {
                var scene: Scene = this.scenes[index];

                for (var camIndex: int = 0; camIndex < scene.cameras.length; camIndex++) {
                    var cam: Camera = scene.cameras[camIndex];

                    cam._currentRenderId = 0;
                }
            }
        }

        public function bindFramebuffer(texture: WebGLTexture, faceIndex: Number = NaN, requiredWidth: Number = NaN, requiredHeight: Number = NaN): void {
            this.bindUnboundFramebuffer(texture);
            var gl: Context3D = this._context3D;
            if (texture.flashTexture is CubeTexture) {
                gl.setRenderToTexture(texture.flashTexture, texture.enableDepthAndStencil, _antiAlias, faceIndex);
            } else {
                gl.setRenderToTexture(texture.flashTexture, texture.enableDepthAndStencil);
            }

            this.setViewport(this._cachedViewport, requiredWidth || texture._width, requiredHeight || texture._height);

            this.wipeCaches();
        }

        private function bindUnboundFramebuffer(framebuffer: WebGLTexture): void {
            if (framebuffer == null) {
                this._context3D.setRenderToBackBuffer();
            }
        }

        public function unBindFramebuffer(): void {
            this.bindUnboundFramebuffer(null);
        }

        public function restoreDefaultFramebuffer(color: Color4): void {
            this.clear(color, true, true, true);

            this.bindUnboundFramebuffer(null);

            this.setViewport(this._cachedViewport);

            this.wipeCaches();
        }

        public function createVertexBuffer(vertices: Vector.<Number>, strideSize: int): VertexBuffer3D {// 1178
            var numVertices: int = vertices.length / strideSize;
            var vertexBuffer:VertexBuffer3D = this._context3D.createVertexBuffer(numVertices, strideSize);

            vertexBuffer.uploadFromVector(vertices, 0, numVertices);

            return vertexBuffer;
        }

        public function updateDynamicVertexBuffer(vertexBuffer: VertexBuffer3D, vertices: Vector.<Number>, startVertex: int, strideSize: int): void {// 1207
            var numVertices: int = vertices.length / strideSize;
            vertexBuffer.uploadFromVector(vertices, startVertex, numVertices);
        }

        public function createIndexBuffer(indices: Vector.<uint>): IndexBuffer3D {//1236
            var numIndices: int = indices.length;
            var indexBuffer: IndexBuffer3D = this._context3D.createIndexBuffer(numIndices);

            // flash vertex rendering order is clockwise, 3ds max is anticlockwise
            var flashIndices: Vector.<uint> = new Vector.<uint>(indices.length, true);
            for (var i: int = 0; i < indices.length; i += 3) {
                flashIndices[i] = indices[i+2];
                flashIndices[i+1] = indices[i+1];
                flashIndices[i+2] = indices[i];
            }

            indexBuffer.uploadFromVector(flashIndices, 0, numIndices);

            return indexBuffer;
        }

        private function vertexAttribPointer(buffer: VertexBuffer3D, index: int, format: String, offset: int): void {//1284
            this._usedVertexBuffer[index] = true;

            var pointer: Object = this._usedVertexBufferCache[index];

            var changed: Boolean = false;
            if (!pointer) {
                changed = true;
                this._usedVertexBufferCache[index] = { index: index, format: format, offset: offset, buffer: buffer };
            } else {
                if (pointer.buffer != buffer) { pointer.buffer = buffer; changed = true; }
                if (pointer.format != format) { pointer.format = format; changed = true; }
                if (pointer.offset != offset) { pointer.offset = offset; changed = true; }
            }

            if (changed) {
                this._context3D.setVertexBufferAt(index, buffer, offset, format);
            }
        }

        public function bindBuffers(vertexBuffers: Dictionary, indexBuffer: IndexBuffer3D, effect: Effect): void {//1351
            this._cachedVertexBuffers = vertexBuffers;
            this._cachedEffectForVertexBuffers = effect;

            var attributes: Vector.<String> = effect.getAttributesNames();

            for (var index: int = 0; index < attributes.length; index++) {
                var order: int = effect.getAttributeLocation(index);

                if (order >= 0) {
                    var vertexBuffer: VertexBuffer = vertexBuffers[attributes[index]];

                    var buffer: VertexBuffer3D = vertexBuffer.getBuffer();
                    this.vertexAttribPointer(buffer, order, vertexBuffer.getSize(), vertexBuffer.getOffset());
                }
            }

            this._cachedIndexBuffer = indexBuffer;
        }

        public function _releaseBuffer(buffer: Object): Boolean {//1411
            buffer.dispose();
            return true;
        }

        public function applyStates():void {//1478
            _depthCullingState.apply(_context3D);
            _stencilState.apply(_context3D);
            _alphaState.apply(_context3D);
        }

        public function draw(indexBuffer: IndexBuffer3D, firstIndex: int = 0, numTriangles: int = -1): void {//1484
            // To render and display a scene (after getting a Context3D object), the following steps are typical:
            // 1.Configure the main display buffer attributes by calling configureBackBuffer().

            // 2.Create and initialize your rendering resources, include:
            // * Vertex and index buffers defining the scene geometry
            for (var i: int = 0; i < this._usedVertexBuffer.length; i++) {
                if (!this._usedVertexBuffer[i] && this._usedVertexBufferCache[i] != null) {
                    this._usedVertexBufferCache[i] = null;
                    this._context3D.setVertexBufferAt(i, null);
                }
            }

            // * Vertex and pixel programs(shaders) for rendering the scene
            if (_programChanged) {
                this._context3D.setProgram(_currentProgram.program);
                _programChanged = false;
            }

            // * Textures
            for (i = 0; i < this._usedTexture.length; i++) {
                if (!this._usedTexture[i] && this._usedTextureCache[i] != null) {
                    this._usedTextureCache[i] = null;
                    this._context3D.setTextureAt(i, null);
                }
            }

            // * Constants
            this._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, this._currentEffect.vertexConstants, this._currentEffect.numVertexRegisters);
            this._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, this._currentEffect.fragmentConstants, this._currentEffect.numFragmentRegisters);
            this._currentEffect.reset();

            // 3.Render a frame:
            // * Set the render state as appropriate for an object or collection of objects in the scene.
            this.applyStates();

            this._drawCalls.addCount(1, false);

            // * Call the drawTriangles() method to render a set of triangles.
            this._context3D.drawTriangles(indexBuffer, firstIndex, numTriangles);

            // * Change the rendering state for the next group of objects.
            // * Call drawTriangles() to draw the triangles defining the objects.
            // * Repeat until the scene is entirely rendered.
            // * Call the present() method to display the rendered scene on the stage.
        }

        public function createEffect(baseName: Object, attributesNames: Vector.<String>, uniformsNames: Vector.<String>, samplers: Vector.<String>, defines: String,
                                     onCompiled: Function = null, onError: Function = null, indexParameters: Object = null): Effect {//1536
            var vertex: String = baseName.hasOwnProperty("vertex") ? baseName.vertex : String(baseName);
            var fragment: String = baseName.hasOwnProperty("fragment") ? baseName.fragment : String(baseName);

            var name: String = vertex + "+" + fragment + "@" + defines;
            if (this._compiledEffects[name]) {
                return this._compiledEffects[name];
            }

            var effect: Effect = new Effect(baseName, attributesNames, uniformsNames, samplers, this, defines, onCompiled, onError, indexParameters);
            effect._key = name;
            this._compiledEffects[name] = effect;

            return effect;
        }

        public function createShaderProgram(vertexCode: String, fragmentCode: String, defines: String): WebGLProgram {//1566
            var program3d: Program3D = this._context3D.createProgram();

            var program: WebGLProgram = new WebGLProgram(program3d, vertexCode, fragmentCode, defines);

            var version: int = defines.indexOf("SHADOW") != -1 ? 2 : 1;

            var vertexByteCode: ByteArray = new AGALMiniAssembler(debug).assemble(Context3DProgramType.VERTEX, program.agalVertexCode, version);
            var fragmentByteCode: ByteArray = new AGALMiniAssembler(debug).assemble(Context3DProgramType.FRAGMENT, program.agalFragmentCode, version);
            program3d.upload(vertexByteCode, fragmentByteCode);

            return program;
        }

        public function getUniforms(shaderProgram: WebGLProgram, uniformsNames: Vector.<String>): Vector.<WebGLUniformLocation> {//1593
            var results: Vector.<WebGLUniformLocation> = new Vector.<WebGLUniformLocation>(uniformsNames.length, true);

            for (var index:int = 0; index < uniformsNames.length; index++) {
                var name: String = uniformsNames[index];

                var location: WebGLUniformLocation = shaderProgram.getUniformLocation(name);

                if (location == null) {
                    var sampler: int = shaderProgram.getSamplerIndex(name);
                    if (sampler != -1) {
                        location = new WebGLUniformLocation(name, Context3DProgramType.FRAGMENT, "fs", new <String>[sampler.toString()]);
                    }
                }

//                if (location == null) {
//                    var attrib: int = shaderProgram.getAttribLocation(name);
//                    if (attrib != -1) {
//                        location = new WebGLUniformLocation(name, Context3DProgramType.VERTEX, "va", new <String>[attrib.toString()]);
//                    }
//                }
//
//                if (location == null) {
//                    var vary: int = shaderProgram.getVaryLocation(name);
//                    if (vary != -1) {
//                        location = new WebGLUniformLocation(name, null, "v", new <String>[vary.toString()]);
//                    }
//                }

                results[index] = location;
            }

            return results;
        }

        public function getAttributes(shaderProgram: WebGLProgram, attributesNames: Vector.<String>): Vector.<int> {
            var results: Vector.<int> = new Vector.<int>(attributesNames.length, true);

            for (var index: int = 0; index < attributesNames.length; index++) {
                results[index] = shaderProgram.getAttribLocation(attributesNames[index]);
            }

            return results;
        }

        public function enableEffect(effect: Effect): void {//1617
            // Use program
            this.setProgram(effect.getProgram());

            this._currentEffect = effect;

            if (effect.onBind) {
                effect.onBind(effect);
            }
        }

        public function setMatrices(uniform: WebGLUniformLocation, matrices: Vector.<Number>, isTranspose: Boolean): void {
            if (!uniform)
                return;

            var m: Vector.<Number> = matrices;
            if (isTranspose) {
                m = new <Number>[];
                for (var i: int = 0; i < matrices.length; i+=16) {
                    var t: Vector.<Number> = Matrix.CacheTransposeMatrices(matrices.slice(i, i+16));
                    m = m.concat(t);
                }
            }

            this._context3D.setProgramConstantsFromVector(uniform.programType, uniform.firstRegister, m, uniform.numRegisters);
        }

        public function setMatrix(uniform: WebGLUniformLocation, matrix: Matrix, isTranspose: Boolean): void {
            if (!uniform)
                return;

            Tmp.MATRIX3D.rawData = matrix.m;
            this._context3D.setProgramConstantsFromMatrix(uniform.programType, uniform.firstRegister, Tmp.MATRIX3D, isTranspose);

//            var m: Vector.<Number> = matrix.m;
//            // matrix is on the right
//            if (isTranspose)
//                m = Matrix.CacheTransposeMatrices(m);
//            this._context3D.setProgramConstantsFromVector(uniform.programType, uniform.firstRegister, m, uniform.numRegisters);
        }

        public function setFloat(uniform: WebGLUniformLocation, x: Number): void {//1755
            if (!uniform)
                return;
            Tmp.VECTOR_NUMBER[0] = x;
            this._context3D.setProgramConstantsFromVector(uniform.programType, uniform.firstRegister, Tmp.VECTOR_NUMBER, uniform.numRegisters);
        }

        public function setFloat2(uniform: WebGLUniformLocation, x: Number, y: Number): void {//1755
            if (!uniform)
                return;
            Tmp.VECTOR_NUMBER[0] = x;
            Tmp.VECTOR_NUMBER[1] = y;
            this._context3D.setProgramConstantsFromVector(uniform.programType, uniform.firstRegister, Tmp.VECTOR_NUMBER, uniform.numRegisters);
        }

        public function setFloat3(uniform: WebGLUniformLocation, x: Number, y: Number, z: Number): void {
            if (!uniform)
                return;
            Tmp.VECTOR_NUMBER[0] = x;
            Tmp.VECTOR_NUMBER[1] = y;
            Tmp.VECTOR_NUMBER[2] = z;
            this._context3D.setProgramConstantsFromVector(uniform.programType, uniform.firstRegister, Tmp.VECTOR_NUMBER, uniform.numRegisters);
        }

        public function setFloat4(uniform: WebGLUniformLocation, x: Number, y: Number, z: Number, w: Number): void {//1776
            if (!uniform)
                return;
            Tmp.VECTOR_NUMBER[0] = x;
            Tmp.VECTOR_NUMBER[1] = y;
            Tmp.VECTOR_NUMBER[2] = z;
            Tmp.VECTOR_NUMBER[3] = w;
            this._context3D.setProgramConstantsFromVector(uniform.programType, uniform.firstRegister, Tmp.VECTOR_NUMBER, uniform.numRegisters);
        }

        public function setState(culling: Boolean, zOffset: Number = 0, force: Boolean = false, reverseSide: Boolean = false): void {//1798
            // culling
            var showSide: String = reverseSide ? Context3DTriangleFace.FRONT : Context3DTriangleFace.BACK;
            var hideSide: String = reverseSide ? Context3DTriangleFace.BACK : Context3DTriangleFace.FRONT;
            var cullFace: String = this.cullBackFaces ? showSide : hideSide;

            if (this._depthCullingState.cull !== culling || force || this._depthCullingState.cullFace !== cullFace) {
                if (culling) {
                    this._depthCullingState.cullFace = cullFace;
                    this._depthCullingState.cull = true;
                } else {
                    this._depthCullingState.cull = false;
                }
            }

            // Z offset
            this._depthCullingState.zOffset = zOffset;
        }

        public function setDepthBuffer(enable: Boolean): void {
            this._depthCullingState.depthTest = enable;
        }

        public function setDepthWrite(enable: Boolean): void {//1825
            this._depthCullingState.depthMask = enable;
        }

        public function setAlphaMode(mode: int, noDepthWriteChange: Boolean = false): void {//1833
            if (this._alphaMode === mode) {
                return;
            }

            switch (mode) {
                case ALPHA_DISABLE:
                    this._alphaState.alphaBlend = false;
                    break;
                case ALPHA_COMBINE:
                    this._alphaState.setAlphaBlendFunctionParameters(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
                    this._alphaState.alphaBlend = true;
                    break;
                case ALPHA_ONEONE:
                    this._alphaState.setAlphaBlendFunctionParameters(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
                    this._alphaState.alphaBlend = true;
                    break;
                case ALPHA_ADD:
                    this._alphaState.setAlphaBlendFunctionParameters(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE);
                    this._alphaState.alphaBlend = true;
                    break;
                case ALPHA_SUBTRACT:
                    this._alphaState.setAlphaBlendFunctionParameters(Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR);
                    this._alphaState.alphaBlend = true;
                    break;
                case ALPHA_MULTIPLY:
                    this._alphaState.setAlphaBlendFunctionParameters(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ZERO);
                    this._alphaState.alphaBlend = true;
                    break;
                case ALPHA_MAXIMIZED:
                    this._alphaState.setAlphaBlendFunctionParameters(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR);
                    this._alphaState.alphaBlend = true;
                    break;
            }
            if (!noDepthWriteChange) {
                this.setDepthWrite(mode === ALPHA_DISABLE);
            }
            this._alphaMode = mode;
        }

        public function setAlphaTesting(enable: Boolean): void {//1877
            this._alphaTest = enable;
        }

        public function getAlphaTesting(): Boolean {//1881
            return this._alphaTest;
        }

        // Textures
        public function wipeCaches(): void {
            this.resetTextureCache();
            this._currentEffect = null;

            this._stencilState.reset();
            this._depthCullingState.reset();
            this.setDepthFunctionToLessOrEqual();
            this._alphaState.reset();

            this._cachedVertexBuffers = null;
            this._cachedIndexBuffer = null;
            this._cachedEffectForVertexBuffers = null;
        }

        public function createTexture(url: String): WebGLTexture {
            if (url in _cacheContext3D)
                return _cacheContext3D[url];

            var texture: WebGLTexture = new WebGLTexture();
            _cacheContext3D[url] = texture;

            var onLoad: Function = function (img: BitmapData) : void {
                prepareWebGLTexture(texture, _context3D, img);
            };

            Tools.LoadImage(url, onLoad);

            return texture;
        }

        public function updateTextureSamplingMode(samplingMode: int, texture: WebGLTexture): void {
            _cacheContext3D["filters"] = getSamplingParameters(samplingMode, texture.generateMipMaps);
        }

        public function _releaseTexture(texture: WebGLTexture): void {
            texture.bitmapData.dispose();

            var index: int = this._loadedTexturesCache.indexOf(texture);
            if (index !== -1) {
                this._loadedTexturesCache.splice(index, 1);
            }
        }

        private function setProgram(program: WebGLProgram): void {//2692
            if (this._currentProgram != program) {
                _programChanged = true;
                this._currentProgram = program;
            }
        }

        public function bindSamplers(effect: Effect): void {//2699
            this.setProgram(effect.getProgram());

            this._currentEffect = null;
        }

        public function _bindTexture(channel: int, texture: WebGLTexture): void {
            setTexture(channel, texture);
        }

        public function setTexture(channel: int, texture: WebGLTexture): void {//2745
            if (channel < 0) {
                return;
            }

            this._usedTexture[channel] = true;

            var pointer: Object = this._usedTextureCache[channel];

            var changed: Boolean = false;
            if (!pointer) {
                changed = true;
                this._usedTextureCache[channel] = { channel: channel, texture: texture};
            } else {
                if (pointer.channel != channel) { pointer.channel = channel; changed = true; }
                if (pointer.texture != texture) { pointer.texture = texture; changed = true; }
            }

            if (changed) {
                this._context3D.setTextureAt(channel, texture.flashTexture);
            }
        }

        public function createRenderTargetTexture(size: Object, options: Object): WebGLTexture {
            var generateMipMaps: Boolean = false;
            var generateDepthBuffer: Boolean = false;

            if (options) {
                generateMipMaps = options.hasOwnProperty("generateMipMaps") ? options.generateMipMaps : generateMipMaps;
                generateDepthBuffer = options.hasOwnProperty("generateDepthBuffer") ? options.generateDepthBuffer : true;
            }

            var gl: Context3D = this._context3D;

            var width: Number = size.hasOwnProperty("width") ? size.width : Number(size);
            var height: Number = size.hasOwnProperty("height") ? size.height : Number(size);

            var texture: WebGLTexture = new WebGLTexture();
            texture.flashTexture = gl.createTexture(width, height, Context3DTextureFormat.BGRA, true);

            texture._width = width;
            texture._height = height;
            texture.isReady = true;
            texture.generateMipMaps = generateMipMaps;
            texture.enableDepthAndStencil = generateDepthBuffer;

            this._loadedTexturesCache.push(texture);

            return texture;
        }

        public function createRenderTargetCubeTexture(size: Number, options: Object = null): WebGLTexture {
            var gl: Context3D = this._context3D;

            var texture: WebGLTexture = new WebGLTexture();
            texture.flashTexture = gl.createCubeTexture(size, Context3DTextureFormat.BGRA, true);

            var generateMipMaps: Boolean = true;
            var generateDepthBuffer: Boolean = true;

            if (options) {
                generateMipMaps = options.hasOwnProperty("generateMipMaps") ? options.generateMipMaps : generateMipMaps;
                generateDepthBuffer = options.hasOwnProperty("generateDepthBuffer") ? options.generateDepthBuffer : true;
            }

            texture.generateMipMaps = generateMipMaps;
            texture.enableDepthAndStencil = generateDepthBuffer;

            texture._width = size;
            texture._height = size;
            texture.isReady = true;

            this._loadedTexturesCache.push(texture);

            return texture;
        }

        public function getDeltaTime(): Number {//3106
            return this.deltaTime;
        }

        private var oldPreviousFramesDuration: Vector.<Number> = new <Number>[];
        private function _measureFps(): void {//3026
            CONFIG::debug {
                oldPreviousFramesDuration.push(Tools.Now);
                var length: int = oldPreviousFramesDuration.length;

                if (length >= 2) {
                    this.deltaTime = oldPreviousFramesDuration[length - 1] - oldPreviousFramesDuration[length - 2];
                }

                if (length >= FPS_RANGE) {

                    if (length > FPS_RANGE) {
                        oldPreviousFramesDuration.splice(0, 1);
                        length = oldPreviousFramesDuration.length;
                    }

                    sum = 0;
                    for (id = 0; id < length - 1; id++) {
                        sum += oldPreviousFramesDuration[id + 1] - oldPreviousFramesDuration[id];
                    }

                    fps = 1000.0 / (sum / (length - 1));
                }
            }

            this.previousFramesDuration[_fpsIndex++] = Tools.Now;

            CONFIG::debug {
                if (length >= 2)
                    assertEquals(this.deltaTime, this.previousFramesDuration[(_fpsIndex - 1 + FPS_RANGE) % FPS_RANGE] - this.previousFramesDuration[(_fpsIndex - 2 + FPS_RANGE) % FPS_RANGE]);
            }
            this.deltaTime = this.previousFramesDuration[(_fpsIndex - 1 + FPS_RANGE) % FPS_RANGE] - this.previousFramesDuration[(_fpsIndex - 2 + FPS_RANGE) % FPS_RANGE];

            if (_fpsIndex >= FPS_RANGE) {
                _fpsIndex = 0;
            }

            var sum: Number = 0;
            for (var id: int = 0; id < FPS_RANGE - 1; id++) {
                sum += this.previousFramesDuration[(id + 1 + _fpsIndex) % FPS_RANGE] - this.previousFramesDuration[(id + _fpsIndex) % FPS_RANGE];
            }

            CONFIG::debug {
                if (length >= FPS_RANGE)
                    assertEquals(this.fps, int(1000.0 / (sum / (FPS_RANGE - 1))));
            }
            this.fps = 1000.0 / (sum / (FPS_RANGE - 1));
        }

        // FPS
        public function getFps(): Number {//3049
            return this.fps;
        }
    }
}

import babylon.materials.textures.Texture;
import babylon.materials.textures.WebGLTexture;

import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.Context3DTextureFormat;
import flash.system.Capabilities;

function prepareWebGLTexture(texture: WebGLTexture, gl: Context3D, img: BitmapData): void {//60
    texture.bitmapData = img;
    texture.flashTexture = gl.createTexture(img.width, img.height, Context3DTextureFormat.BGRA, false);
    Object(texture.flashTexture).uploadFromBitmapData(img);
}

function getSamplingParameters(samplingMode: int, generateMipMaps: Boolean): Object {
    var tex: String = Context3DTextureFilter.NEAREST;
    var mip: String = Context3DMipFilter.MIPNONE;
    if (samplingMode === Texture.BILINEAR_SAMPLINGMODE) {
        tex = Context3DTextureFilter.LINEAR;
        if (generateMipMaps) {
            mip = Context3DMipFilter.MIPLINEAR;
        } else {
            mip = Context3DTextureFilter.LINEAR;
        }
    } else if (samplingMode === Texture.TRILINEAR_SAMPLINGMODE) {
        tex = Context3DTextureFilter.LINEAR;
        if (generateMipMaps) {
            mip = Context3DMipFilter.MIPLINEAR;
        } else {
            mip = Context3DTextureFilter.LINEAR;
        }
    } else if (samplingMode === Texture.NEAREST_SAMPLINGMODE) {
        tex = Context3DTextureFilter.NEAREST;
        if (generateMipMaps) {
            mip = Context3DMipFilter.MIPNEAREST;
        } else {
            mip = Context3DTextureFilter.NEAREST;
        }
    }

    return {
        mip: mip,
        tex: tex
    }
}

class Context3DProfile {
    public static const BASELINE:String = "baseline";
    public static const BASELINE_CONSTRAINED:String = "baselineConstrained";
    public static const BASELINE_EXTENDED:String = "baselineExtended";
    public static const STANDARD:String = "standard";
    public static const STANDARD_CONSTRAINED:String = "standardConstrained";
    public static const STANDARD_EXTENDED:String = "standardExtended";

    public var value:String;
    public var versionAvailableFrom:Number;
    public var priority:int;

    public function Context3DProfile(value:String, versionAvailableFrom:Number, priority:int) {
        this.priority = priority;
        this.versionAvailableFrom = versionAvailableFrom;
        this.value = value;
    }

    public function isAvailable():Boolean {
        return versionAvailableFrom <= Context3DProfiles.getVersion();
    }

    public function toString():String {
        return value;
    }
}

class Context3DProfiles {
    public static const BASELINE:Context3DProfile = new Context3DProfile("baseline", 11.4, 4);

    public static const BASELINE_CONSTRAINED:Context3DProfile = new Context3DProfile("baselineConstrained", 11.4, 10);

    public static const BASELINE_EXTENDED:Context3DProfile = new Context3DProfile("baselineExtended", 11.8, 3);

    public static const STANDARD:Context3DProfile = new Context3DProfile("standard", 14.0, 2);

    public static const STANDARD_CONSTRAINED:Context3DProfile = new Context3DProfile("standardConstrained", 16.0, 3);

    public static const STANDARD_EXTENDED:Context3DProfile = new Context3DProfile("standardExtended", 17.0, 1);

    public static const PROFILES_LIST:Vector.<Context3DProfile> = new <Context3DProfile>
            [
                STANDARD_EXTENDED, STANDARD, STANDARD_CONSTRAINED,
                BASELINE_EXTENDED, BASELINE, BASELINE_CONSTRAINED
            ];

    private static var playerVersion:int = -1;

    public function Context3DProfiles() {

    }

    public static function getMatchingProfiles():Vector.<String> {
        var i:int;

        var version:Number = getVersion();

        var availableProfiles:Vector.<Context3DProfile> = new Vector.<Context3DProfile>();

        for (i = 0; i < PROFILES_LIST.length; i++) {
            if (PROFILES_LIST[i].versionAvailableFrom <= version) {
                availableProfiles.push(PROFILES_LIST[i]);
            }
        }

        availableProfiles.sort(prioritySort);

        var profilesList:Vector.<String> = new Vector.<String>(availableProfiles.length, true);
        for (i = 0; i < availableProfiles.length; i++) {
            profilesList[i] = availableProfiles[i].value;
        }

        return profilesList;
    }

    private static function prioritySort(a:Context3DProfile, b:Context3DProfile):Number {
        var aPriority:Number = a.priority;
        var bPriority:Number = b.priority;

        if (aPriority > bPriority) {
            return 1;
        } else if (aPriority < bPriority) {
            return -1;
        }
        else
            return 0;
    }

    public static function getVersion():Number {
        if (playerVersion == -1) {
            var version:String = Capabilities.version;
            var versionParts:Array = version.split(" ")[1].split(",");

            var mainVersion:Number = int(versionParts[0]);
            var secondVersion:Number = Number(versionParts[1]) / 100;

            playerVersion = mainVersion + secondVersion;
        }

        return playerVersion;
    }
}
