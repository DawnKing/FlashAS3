/**
 * Created by caijingxiao on 2017/6/13.
 */
package babylon
{
    import babylon.events.Stage3DEvent;
    import babylon.materials.Effect;
    import babylon.materials.textures.WebGLTexture;
    import babylon.math.Color4;
    import babylon.mesh.VertexBuffer;
    import babylon.zip.webgl.WebGLProgram;
    import babylon.zip.webgl.WebGLUniformLocation;

    import com.adobe.utils.AGALMiniAssembler;

    import easiest.core.Log;

    import flash.display.BitmapData;
    import flash.display.Stage;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Context3DTriangleFace;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    [Event(name = "ViewportUpdated", type="babylon.events.Stage3DEvent")]
    [Event(name = "Context3DCreated", type="babylon.events.Stage3DEvent")]
    [Event(name = "Context3DDisposed", type="babylon.events.Stage3DEvent")]
    [Event(name = "Context3DRecreated", type="babylon.events.Stage3DEvent")]

    public class Engine extends EventDispatcher
    {
        public static var debug: Boolean = true;
        public static const MAX_VERTEX_BUFFER: int = 8;
        public static const MAX_TEXTURE: int = 8;
        public static const MAX_CONSTANTS: int = 128;
        public static const MAX_CONSTANTS_LENGTH: int = MAX_CONSTANTS * 4;

        public static var gpuMem:Number;
        public static var drawcall:int;

        private var _stage:Stage;
        private var _stage3D:Stage3D;
        private var _context3D:Context3D;

        // scenes
        internal var scenes:Vector.<Scene> = new <Scene>[];

        // rendering
        private var _renderingQueueLaunched:Boolean = false;
        private var _activeRenderLoops:Vector.<Function> = new <Function>[];

        // rendering resources
        private var _usedVertexBuffer: Vector.<Boolean> = new Vector.<Boolean>(MAX_VERTEX_BUFFER, true);
        private var _usedVertexBufferCache: Vector.<Object> = new Vector.<Object>(MAX_VERTEX_BUFFER, true);

        private var _usedTexture: Vector.<Boolean> = new Vector.<Boolean>(MAX_TEXTURE, true);
        private var _usedTextureCache: Vector.<Object> = new Vector.<Object>(MAX_TEXTURE, true);

        private var _compiledEffects:Dictionary = new Dictionary(true);

        private var _currentEffect: Effect;
        private var _programChanged: Boolean = true;
        private var _currentProgram: WebGLProgram;

        // rendering caches
        private var _cachedVertexBuffers:Dictionary;
        private var _cachedEffectForVertexBuffers:Effect;

        private var _cacheContext3D: Dictionary = new Dictionary(true);

        public function Engine(stage:Stage)
        {
            stage.frameRate = 60;
            stage.quality = StageQuality.HIGH;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.stageFocusRect = false;
            stage.tabChildren = false;

            _stage = stage;
            _stage3D = _stage.stage3Ds[0];
        }

        public function init():void
        {
            // whatever happens, be sure this has highest priority
            _stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate, false, int.MAX_VALUE, false);
            _stage3D.requestContext3DMatchingProfiles(Context3DProfiles.getMatchingProfiles());
        }

        private function onContext3DUpdate(event:Event):void
        {
            if (!_stage3D.context3D)
                throw new Error("Rendering webgl lost!");

            var hadContext:Boolean = (_context3D != null);
            _context3D = _stage3D.context3D;
            _context3D.enableErrorChecking = true;

            _context3D.configureBackBuffer(_stage.stageWidth, _stage.stageHeight, 0);
            _context3D.setCulling(Context3DTriangleFace.BACK);
            _context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
            _context3D.setDepthTest(true, Context3DCompareMode.ALWAYS);

            Log.log(_context3D.driverInfo, this);

            // Dispatch the appropriate event depending on whether webgl was
            // created for the first time or recreated after a device loss.
            if (hadContext)
            {
                if (hasEventListener(Stage3DEvent.CONTEXT3D_RECREATED))
                    dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_RECREATED));
            }
            else if (hasEventListener(Stage3DEvent.CONTEXT3D_CREATED))
            {
                dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_CREATED));
            }
        }

        public function _releaseBuffer(buffer: Object): Boolean {
            buffer.dispose();
            return true;
        }

        public function _renderLoop(event: Event):void {
            var shouldRender:Boolean = true;

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

            gpuMem = _context3D.totalGPUMemory;
        }

        public function runRenderLoop(renderFunction:Function):void {
            if (_activeRenderLoops.indexOf(renderFunction) != -1) {
                return;
            }

            _activeRenderLoops.push(renderFunction);

            if (!_renderingQueueLaunched) {
                _renderingQueueLaunched = true;
                _stage.addEventListener(Event.ENTER_FRAME, _renderLoop);
            }
        }

        public function clear(color: Color4, backBuffer: Boolean, depth: Boolean, stencil: Boolean = false):void {
            this._context3D.clear(1, 1, 1);
//            applyStates();

//            if (color) {
//                this._context3D.clear(
//                        color.r, color.g, color.b, color.a,
//                        1.0,    // depth
//                        0,      // stencil
//                        mode);  // mask
//            } else {
//                this._context3D.clear(
//                        0, 0, 0, 0, // color
//                        1.0,    // depth
//                        0,      // stencil
//                        mode);  // mask
//            }
        }

        public function resetTextureCache(): void {
//            for (var index = 0; index < this._maxTextureChannels; index++) {
//                this._activeTexturesCache[index] = null;
//            }
            for (i = 0; i < this._usedTexture.length; i++) {
                _usedTexture[i] = false;
            }

            for (var i: int = 0; i < this._usedVertexBuffer.length; i++) {
                _usedVertexBuffer[i] = false;
            }
        }

        private function beginFrame():void {
//            this._measureFps();

            drawcall = 0;

            resetTextureCache();
        }

        private function endFrame():void {
            _context3D.present();
        }

        public function createIndexBuffer(indices:Vector.<uint>, bufferUsage:String):IndexBuffer3D {
            var numIndices:int = indices.length;
            var indexBuffer:IndexBuffer3D = this._context3D.createIndexBuffer(numIndices, bufferUsage);
            indexBuffer.uploadFromVector(indices, 0, numIndices);
            return indexBuffer;
        }

        public function createVertexBuffer(vertices:Vector.<Number>, dataPerVertex:int, bufferUsage:String):VertexBuffer3D {
            var numVertices: int = vertices.length / dataPerVertex;
            var vertexBuffer:VertexBuffer3D = this._context3D.createVertexBuffer(numVertices, dataPerVertex, bufferUsage);
            vertexBuffer.uploadFromVector(vertices, 0, numVertices);
            return vertexBuffer;
        }

        public function createEffect(baseName:String, attributesNames:Vector.<String>, uniformsNames:Vector.<String>, samplers:Vector.<String>, defines:String,
                                     onCompiled:Function = null, onError:Function = null, indexParameters:Object = null):Effect
        {
            var vertex: String = baseName;
            var fragment: String = baseName;

            var name: String = vertex + "+" + fragment + "@" + defines;
            if (_compiledEffects[name])
                return _compiledEffects[name];

            var effect: Effect = new Effect(baseName, attributesNames, uniformsNames, samplers, this, defines, onCompiled, onError, indexParameters);
            effect._key = name;
            _compiledEffects[name] = effect;

            return effect;
        }

        public function createShaderProgram(vertexCode:String, fragmentCode:String, defines:String):WebGLProgram {
            var program3d:Program3D = this._context3D.createProgram();

            var program:WebGLProgram = new WebGLProgram(program3d, vertexCode, fragmentCode, defines);

            var vertexByteCode:ByteArray = new AGALMiniAssembler(debug).assemble(Context3DProgramType.VERTEX, program.agalVertexCode);
            var fragmentByteCode:ByteArray = new AGALMiniAssembler(debug).assemble(Context3DProgramType.FRAGMENT, program.agalFragmentCode);
            program3d.upload(vertexByteCode, fragmentByteCode);

            return program;
        }

        public function getUniforms(shaderProgram: WebGLProgram, uniformsNames: Vector.<String>): Vector.<WebGLUniformLocation> {
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

        public function bindSamplers(effect: Effect): void {
            this.setProgram(effect.getProgram());
            this._currentEffect = null;
        }

        private function setProgram(program: WebGLProgram): void {
            if (this._currentProgram != program) {
                _programChanged = true;
                this._currentProgram = program;
            }
        }

        public function enableEffect(effect: Effect): void {
            // Use program
            this.setProgram(effect.getProgram());

            this._currentEffect = effect;

            if (effect.onBind) {
                effect.onBind(effect);
            }
        }

        public function bindBuffers(vertexBuffers: Dictionary, effect: Effect):void {
            this._cachedVertexBuffers = vertexBuffers;
            this._cachedEffectForVertexBuffers = effect;

            var attributes: Vector.<String> = effect.getAttributesNames();

            for (var index: int = 0; index < attributes.length; index++) {
                var order: int = effect.getAttributeLocation(index);

                if (order >= 0) {
                    var vertexBuffer:VertexBuffer = vertexBuffers[attributes[index]];

                    var buffer: VertexBuffer3D = vertexBuffer.getBuffer();
                    vertexAttribPointer(buffer, order, vertexBuffer.getSize(), vertexBuffer.getOffset());
                }
            }
        }

        private function vertexAttribPointer(buffer: VertexBuffer3D, index: int, format: String, offset: int):void {
            this._usedVertexBuffer[index] = true;

            var pointer: Object = this._usedVertexBufferCache[index];

            var changed: Boolean = false;
            if (!pointer)
            {
                changed = true;
                this._usedVertexBufferCache[index] = { index: index, format: format, offset: offset, buffer: buffer };
            }
            else
            {
                if (pointer.buffer != buffer) { pointer.buffer = buffer; changed = true; }
                if (pointer.format != format) { pointer.format = format; changed = true; }
                if (pointer.offset != offset) { pointer.offset = offset; changed = true; }
            }

            if (changed)
            {
                this._context3D.setVertexBufferAt(index, buffer, offset, format);
            }
        }

        public function draw(indexBuffer: IndexBuffer3D, firstIndex: int = 0, numTriangles: int = -1): void {//1484
            // To render and display a scene (after getting a Context3D object), the following steps are typical:
            // 1.Configure the main display buffer attributes by calling configureBackBuffer().

            // 2.Create and initialize your rendering resources, include:
            // * Vertex and index buffers defining the scene geometry
            for (var i: int = 0; i < this._usedVertexBuffer.length; i++) {
                if (!_usedVertexBuffer[i] && _usedVertexBufferCache[i] != null) {
                    _usedVertexBufferCache[i] = null;
                    _context3D.setVertexBufferAt(i, null);
                }
            }

            // * Vertex and pixel programs(shaders) for rendering the scene
            if (_programChanged) {
                _context3D.setProgram(_currentProgram.program);
                _programChanged = false;
            }

            // * Textures
            for (i = 0; i < this._usedTexture.length; i++) {
                if (!_usedTexture[i] && _usedTextureCache[i] != null) {
                    _usedTextureCache[i] = null;
                    _context3D.setTextureAt(i, null);
                }
            }

            // * Constants
            _context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _currentEffect.vertexConstants, _currentEffect.numVertexRegisters);
            _context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _currentEffect.fragmentConstants, _currentEffect.numFragmentRegisters);
            _currentEffect.reset();

            // 3.Render a frame:
            // * Set the render state as appropriate for an object or collection of objects in the scene.
//            this.applyStates();

//            this._drawCalls.addCount(1, false);

            // * Call the drawTriangles() method to render a set of triangles.
            _context3D.drawTriangles(indexBuffer, firstIndex, numTriangles);

            drawcall++;

            // * Change the rendering state for the next group of objects.
            // * Call drawTriangles() to draw the triangles defining the objects.
            // * Repeat until the scene is entirely rendered.
            // * Call the present() method to display the rendered scene on the stage.
        }

        public function createTexture(tex: BitmapData): WebGLTexture {
            var texture: WebGLTexture = new WebGLTexture();

            texture.bitmapData = tex;
            texture.flashTexture = _context3D.createTexture(tex.width, tex.height, Context3DTextureFormat.BGRA, false);
            Object(texture.flashTexture).uploadFromBitmapData(tex);

            return texture;
        }

        public function updateTextureSamplingMode(samplingMode: int, texture: WebGLTexture): void {
            _cacheContext3D["filters"] = getSamplingParameters(samplingMode, texture.generateMipMaps);
        }

        public function _bindTexture(channel: int, texture: WebGLTexture): void {
            setTexture(channel, texture);
        }

        public function setTexture(channel: int, texture: WebGLTexture): void {
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

        public function get context3D():Context3D
        {
            return _context3D;
        }
    }
}

import babylon.materials.textures.Texture;

import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.system.Capabilities;

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
