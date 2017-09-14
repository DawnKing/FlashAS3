/**
	 * Created by caijingxiao on 2017/6/13.
	 */
package easiest.rendering
{
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.Stage;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
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
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.system.Capabilities;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    
    import easiest.core.Log;
    import easiest.debug.Assert;
    import easiest.rendering.materials.AGALMiniAssembler;
    import easiest.rendering.materials.Shader;
    import easiest.rendering.materials.textures.AtfData;
    import easiest.rendering.sprites.batch.Sprite2DBatching;

    public class Engine extends EventDispatcher
    {
        public static var debug:Boolean=false;
        // AGAL2: Standard, Flash player 14, SWF version 25，totalGPUMemory需要的版本SWF version 32,fp21
        public static const MaxAttribute:int=8;
        public static const MaxFragmentConstant:int=64;
        public static const MaxVertexConstant:int=250;
        public static const MaxTemporary:int=26;
        public static const MaxVarying:int=10;
        public static const MaxSampler:int=16;
        public static const MaxFragmentConstants:int=MaxFragmentConstant * 4;
        public static const MaxVertexConstants:int=MaxVertexConstant * 4;

        public static var inst:Engine;

        public static var gpuMem:Number;
        public static var drawcall:int;

        private var _stage:Stage;
        private var _stage3D:Stage3D;
        private var _context3D:Context3D;

        // cache
        private var _compiledShader:Dictionary=new Dictionary(true);
        private var _textureCache:Vector.<TextureBase> = new Vector.<TextureBase>(Sprite2DBatching.batchMaxCount, true);

        public function Engine(stage:Stage)
        {
            Assert.assertNull1(inst);
            inst=this;

            stage.scaleMode=StageScaleMode.NO_SCALE;
            stage.align=StageAlign.TOP_LEFT;

            _stage=stage;
            _stage3D=_stage.stage3Ds[0];

            _stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 10, true);
            _stage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 10, true);

            Log.log("runtimeVersion:  " + Capabilities.version, this);

            requestContext3D(_stage3D, "auto", "auto");
        }

        private function onStage3DError(event:ErrorEvent):void
        {
            if (event.errorID == 3702)
            {
                var mode:String = Capabilities.playerType == "Desktop" ? "renderMode" : "wmode";
                stopWithFatalError(_stage, "Context3D not available! Possible reasons: wrong " + mode +
                    " or missing device support.");
            }
            else
                stopWithFatalError(_stage, "Stage3D error: " + event.text);
        }

        private function onContextCreated(event:Event):void
        {
            _context3D=_stage3D.context3D;
            Log.log(_context3D.driverInfo, this);

            CONFIG::debug
            {
                _context3D.enableErrorChecking=true;
            }

            _context3D.configureBackBuffer(_stage.stageWidth, _stage.stageHeight, 0);
            _context3D.setCulling(Context3DTriangleFace.BACK);
            _context3D.setDepthTest(true, Context3DCompareMode.ALWAYS);

			dispatchEvent(new Event(Event.CONTEXT3D_CREATE));
        }

        public function onResize():void
        {
            if (_context3D != null)
                _context3D.configureBackBuffer(_stage.stageWidth, _stage.stageHeight, 0);
        }

        public function beginFrame():void
        {
            drawcall=0;
            _context3D.clear(1, 1, 1);
        }

        public function endFrame():void
        {
            _context3D.present();

            if (_context3D.hasOwnProperty("totalGPUMemory"))
            {
                gpuMem=_context3D.totalGPUMemory;
            }
        }

        public function createIndexBuffer(numIndices:int, data:Vector.<uint>):IndexBuffer3D
        {
            var indexBuffer:IndexBuffer3D;
            indexBuffer = _context3D.createIndexBuffer(numIndices);
            indexBuffer.uploadFromVector(data, 0, numIndices);
            return indexBuffer;
        }

        public function createVertexBuffer(numVertices:int, data32PerVertex:int, data:Vector.<Number>):VertexBuffer3D
        {
            var vertexBuffer:VertexBuffer3D;
            vertexBuffer = _context3D.createVertexBuffer(numVertices, data32PerVertex);
            vertexBuffer.uploadFromVector(data, 0, numVertices);
            return vertexBuffer;
        }

        public function setVertexBuffer(index:int, buffer:VertexBuffer3D, bufferOffset:int = 0, format:String = "float4"):void
        {
            _context3D.setVertexBufferAt(index, buffer, bufferOffset, format);
        }

        public function createProgram(shaderName:String, format:String):Program3D
        {
            var cacheName:String = shaderName + format;
            if (_compiledShader[cacheName])
                return _compiledShader[cacheName];

            switch (format)
            {
                case Context3DTextureFormat.COMPRESSED:
                    Shader.format = "dxt1";
                    break;
                case Context3DTextureFormat.COMPRESSED_ALPHA:
                    Shader.format = "dxt5";
                    break;
                case Context3DTextureFormat.BGRA:
                    Shader.format = "rgba";
                    break;
            }

            var shader:Shader=new Shader(shaderName);
            var program3d:Program3D=_context3D.createProgram();
            var vertexByteCode:ByteArray=new AGALMiniAssembler(debug).assemble(Context3DProgramType.VERTEX, shader.vertexCode, 2);
            var fragmentByteCode:ByteArray=new AGALMiniAssembler(debug).assemble(Context3DProgramType.FRAGMENT, shader.fragmentCode, 2);
            program3d.upload(vertexByteCode, fragmentByteCode);
            _compiledShader[cacheName]=program3d;
            return program3d;
        }

        public function setProgram(program:Program3D):void
        {
            _context3D.setProgram(program);
        }

        public function setVBO(vbo:Function):void
        {
            vbo();
        }

        public function setTexture(i:int, texture:Texture):void
        {
            if (_textureCache[i] == texture)
                return;
            _context3D.setTextureAt(i, texture);
            _textureCache[i] = texture;
        }

        public function setTextures(texture:Texture):void
        {
            for (var i:int = 0; i < Sprite2DBatching.batchMaxCount; i++)
            {
                setTexture(i, texture);
            }
        }

        public function setConstants(programType:String, firstRegister:int, data:Vector.<Number>, numRegisters:int=-1):void
        {
            _context3D.setProgramConstantsFromVector(programType, firstRegister, data, numRegisters);
        }

        public function draw(vertexConstants:Vector.<Number>, constantsNumRegisters:int, indexBuffer:IndexBuffer3D, numTriangles:int = -1):void
        {
            _context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, vertexConstants, constantsNumRegisters);
            _context3D.drawTriangles(indexBuffer, 0, numTriangles);

            drawcall++;
        }

        public function setBlendMode(mode:String):void
        {
            var sourceFactor:String=Context3DBlendFactor.ONE;
            var destinationFactor:String=Context3DBlendFactor.ZERO;
            switch (mode)
            {
                case BlendMode.NORMAL:
                    sourceFactor=Context3DBlendFactor.ONE;
                    destinationFactor=Context3DBlendFactor.ZERO;
                    break;
                case BlendMode.ALPHA:
                    sourceFactor=Context3DBlendFactor.SOURCE_ALPHA;
                    destinationFactor=Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
                    break;
                case BlendMode.ADD:
                    sourceFactor=Context3DBlendFactor.ONE;
                    destinationFactor=Context3DBlendFactor.ONE;
                    break;
                default:
                    Assert.fail();
            }
            _context3D.setBlendFactors(sourceFactor, destinationFactor);
        }

        public function CreateBitmapTexture(bitmapData:BitmapData):Texture
        {
            if (_context3D == null)
            {
                Log.error("context is null", this);
                return null;
            }
            Assert.assertNotNull1(bitmapData);

            var texture:Texture=_context3D.createTexture(bitmapData.width, bitmapData.height, Context3DTextureFormat.BGRA, false);
            texture.uploadFromBitmapData(bitmapData);
            return texture;
        }

        public function CreateAtfTexture(atfData:AtfData):Texture
        {
            if (_context3D == null)
            {
                Log.error("context is null", this);
                return null;
            }
            var texture:Texture=_context3D.createTexture(atfData.width, atfData.height, atfData.format, false);
            texture.uploadCompressedTextureFromByteArray(atfData.data, 0);
            return texture;
        }

        public function get ready():Boolean
        {
            if (_context3D == null)
            {
                Log.error("context3d is null", this);
                return false;
            }
            return true;
        }

        public function get context3D():Context3D
        {
            return _context3D;
        }
    }
}

import flash.display.Shape;
import flash.display.Stage;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DRenderMode;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.utils.setTimeout;

function requestContext3D(stage3D:Stage3D, renderMode:String, profile:Object):void
{
    var profiles:Array;
    var currentProfile:String;

    if (profile == "auto")
        profiles=["standardExtended", "standard", "standardConstrained", "baselineExtended", "baseline", "baselineConstrained"];
    else if (profile is String)
        profiles=[profile as String];
    else if (profile is Array)
        profiles=profile as Array;
    else
        throw new ArgumentError("Profile must be of type 'String' or 'Array'");

    stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreated, false, 100);
    stage3D.addEventListener(ErrorEvent.ERROR, onError, false, 100);

    requestNextProfile();

    function requestNextProfile():void
    {
        currentProfile=profiles.shift();

        try
        {
			stage3D.requestContext3D(renderMode, currentProfile);
        }
        catch (error:Error)
        {
            if (profiles.length != 0)
                setTimeout(requestNextProfile, 1);
            else
                throw error;
        }
    }

    function onCreated(event:Event):void
    {
        var context:Context3D=stage3D.context3D;

        if (renderMode == Context3DRenderMode.AUTO && profiles.length != 0 && context.driverInfo.indexOf("Software") != -1)
        {
            onError(event);
        }
        else
        {
            onFinished();
        }
    }

    function onError(event:Event):void
    {
        if (profiles.length != 0)
        {
            event.stopImmediatePropagation();
            setTimeout(requestNextProfile, 1);
        }
        else
            onFinished();
    }

    function onFinished():void
    {
        stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onCreated);
        stage3D.removeEventListener(ErrorEvent.ERROR, onError);
    }
}

function stopWithFatalError(stage:Stage, message:String):void
{
    var background:Shape = new Shape();
    background.graphics.beginFill(0x0, 0.8);
    background.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
    background.graphics.endFill();

    var textField:TextField = new TextField();
    var textFormat:TextFormat = new TextFormat("Verdana", 14, 0xFFFFFF);
    textFormat.align = TextFormatAlign.CENTER;
    textField.defaultTextFormat = textFormat;
    textField.wordWrap = true;
    textField.width = stage.stageWidth * 0.75;
    textField.autoSize = TextFieldAutoSize.CENTER;
    textField.text = message;
    textField.x = (stage.stageWidth  - textField.width)  / 2;
    textField.y = (stage.stageHeight - textField.height) / 2;
    textField.background = true;
    textField.backgroundColor = 0x550000;

    stage.addChild(background);
    stage.addChild(textField);

    trace("[Starling]", message);
}