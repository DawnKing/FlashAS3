/**
 * Created by caijingxiao on 2016/12/2.
 */
package babylon.debug {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.Camera;
    import babylon.math.Matrix;
    import babylon.math.Vector3;
    import babylon.math.Viewport;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Mesh;
    import babylon.tools.Tools;

    import easiest.managers.FrameManager;

    import easiest.unit.asserts.fail;

    import flash.display.DisplayObjectContainer;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextLineMetrics;

    public class DebugLayer {
        private var _scene: Scene;
        private var _camera: Camera;
        private var _transformationMatrix: Matrix = Matrix.Identity();
        private var _enabled: Boolean = false;
        private var _labelsEnabled: Boolean = false;
        private var _displayStatistics: Boolean = true;
        private var _displayTree: Boolean = false;
        private var _displayLogs: Boolean = false;
        private var _globalDiv: Sprite;
        private var _statsDiv: DivElement;
//        private var _optionsDiv: Sprite;
//        private var _logDiv: Sprite;
//        private var _treeDiv: Sprite;
        private var _treeSubsetDiv: Sprite;
        private var _drawingContext: Sprite;
        private var _rootElement: DisplayObjectContainer;

//        private var _skeletonViewers: Vector.<SkeletonViewer> = new <SkeletonViewer>[];

        public var _syncPositions: Function;    // () => void;
        private var _syncData: Function;    // () => void;
        private var _syncUI: Function;    // () => void;
        private var _onCanvasClick: Function;   // (evt: MouseEvent) => void;

        private var _ratio: Number;

        private var _identityMatrix: Matrix = Matrix.Identity();

        private var _showUI: Boolean;
        private var _needToRefreshMeshesTree: Boolean;

        public var shouldDisplayLabel: Function;    // (node: Node) => Boolean;
        public var shouldDisplayAxis: Function;    // (mesh: Mesh) => Boolean;

        public var axisRatio: Number = 0.02;

        public var accentColor: String = "orange";

        public var customStatsFunction: Function;    // () => String;

        private var _canvasRect: Rectangle;

        public function DebugLayer(scene: Scene) {
            this._scene = scene;

            this._syncPositions = function (): void {
                var engine: Engine = _scene.getEngine();
                _canvasRect = engine.getRenderingCanvasClientRect();

                if (_showUI) {
                    _statsDiv.x = _canvasRect.width - 410;
                    _statsDiv.y = _canvasRect.height - 250;
                    _statsDiv.setSize(400, 240);

//                    _optionsDiv.x = 0;
//                    _optionsDiv.y = 10;
//                    _optionsDiv.width = 200;
//                    _optionsDiv.height = _canvasRect.height - 225;
//
//                    _logDiv.x = 0;
//                    _logDiv.y = _canvasRect.height - 170;
//                    _logDiv.width = 600;
//                    _logDiv.height = 160;
//
//                    _treeDiv.x = _canvasRect.width - 310;
//                    _treeDiv.y = 10;
//                    _treeDiv.width = 300;
//                    _treeDiv.height = _canvasRect.height - 340;
                }

                _globalDiv.x = 0;
                _globalDiv.y = 0;
            };

            this._onCanvasClick = function (evt: MouseEvent): void {
            };

            this._syncUI = function (): void {
                if (_showUI) {
                    if (_displayStatistics) {
                        _displayStats();
                    }

                    if (_displayTree) {
                        if (_needToRefreshMeshesTree) {
                            _needToRefreshMeshesTree = false;
                            _refreshMeshesTreeContent();
                        }
                    }
                }
            };

            this._syncData = function (): void {
                if (_labelsEnabled || !_showUI) {

                    _camera.getViewMatrix().multiplyToRef(_camera.getProjectionMatrix(), _transformationMatrix);

                    _drawingContext.removeChildren();

                    var engine: Engine = _scene.getEngine();
                    var viewport: Viewport = _camera.viewport;
                    var globalViewport: Viewport = viewport.toGlobal(engine.getRenderWidth(), engine.getRenderHeight());

                    // Meshes
                    var meshes: Vector.<Mesh> = _camera.getActiveMeshes();
                    var index: int;
                    var projectedPosition: Vector3;
                    for (index = 0; index < meshes.length; index++) {
                        var mesh: Mesh = meshes[index];

                        var position: Vector3 = mesh.getBoundingInfo().boundingSphere.center;
                        projectedPosition = Vector3.Project(position, mesh.getWorldMatrix(), _transformationMatrix, globalViewport);
                        if (mesh.renderOverlay || shouldDisplayAxis && shouldDisplayAxis(mesh)) {
                            _renderAxis(projectedPosition, mesh, globalViewport);
                        }

                        if (!shouldDisplayLabel || shouldDisplayLabel(mesh)) {
                            _renderLabel(mesh.name, projectedPosition, 12,
                                    function (): void { mesh.renderOverlay = !mesh.renderOverlay },
                                    function (): String { return mesh.renderOverlay ? 'red' : 'black' });
                        }
                    }

                    // Cameras
                    var cameras: Vector.<Camera> = _scene.cameras;
                    for (index = 0; index < cameras.length; index++) {
                        var camera: Camera = cameras[index];

                        if (camera === _camera) {
                            continue;
                        }

                        projectedPosition = Vector3.Project(Vector3.Zero(), camera.getWorldMatrix(), _transformationMatrix, globalViewport);

                        if (!shouldDisplayLabel || shouldDisplayLabel(camera)) {
                            _renderLabel(camera.name, projectedPosition, 12,
                                    function (): void {
                                        _camera.detachControl(engine.getRenderingCanvas());
                                        _camera = camera;
                                        _camera.attachControl(engine.getRenderingCanvas());
                                    },
                                    function (): String { return "purple"; });
                        }
                    }

                    // Lights
                }
            }
        }

        private function _refreshMeshesTreeContent(): void {
            while (this._treeSubsetDiv.numChildren) {
                this._treeSubsetDiv.removeChild(this._treeSubsetDiv.getChildAt(0));
            }

            // Add meshes
            var sortedArray: Vector.<AbstractMesh> = this._scene.meshes.slice(0, this._scene.meshes.length);

            sortedArray.sort(function (a: AbstractMesh, b: AbstractMesh): int {
                if (a.name === b.name) {
                    return 0;
                }

                return (a.name > b.name) ? 1 : -1;
            });

            for (var index: int = 0; index < sortedArray.length; index++) {
                var mesh: AbstractMesh = sortedArray[index];

                if (!mesh.isEnabled()) {
                    continue;
                }

                this._generateAdvancedCheckBox(this._treeSubsetDiv, mesh.name, mesh.getTotalVertices() + " verts", mesh.isVisible, function (element, m: AbstractMesh): void {
                    m.isVisible = element.checked;
                }, mesh);
            }
        }

        private function _renderSingleAxis(zero: Vector3, unit: Vector3, unitText: Vector3, label: String, color: uint): void {
            var shape: Shape = new Shape();
            shape.graphics.lineStyle(4, color);
            shape.graphics.moveTo(zero.x, zero.y);
            shape.graphics.lineTo(unit.x, unit.y);

            this._drawingContext.addChild(shape);

            var text: TextField = new TextField();
            text.textColor = color;
            text.x = unitText.x;
            text.y = unitText.y;
            text.autoSize = TextFieldAutoSize.CENTER;
            text.text = label;

            this._drawingContext.addChild(text);
        }

        private function _renderAxis(projectedPosition: Vector3, mesh: Mesh, globalViewport: Viewport): void {
            var position: Vector3 = mesh.getBoundingInfo().boundingSphere.center;
            var worldMatrix: Matrix = mesh.getWorldMatrix();

            var unprojectedVector: Vector3 = Vector3.UnprojectFromTransform(projectedPosition.add(new Vector3(_canvasRect.width * this.axisRatio, 0, 0)), globalViewport.width, globalViewport.height, worldMatrix, this._transformationMatrix);
            var unit: int = (unprojectedVector.subtract(position)).length();

            var xAxis: Vector3 = Vector3.Project(position.add(new Vector3(unit, 0, 0)), worldMatrix, this._transformationMatrix, globalViewport);
            var xAxisText: Vector3 = Vector3.Project(position.add(new Vector3(unit * 1.5, 0, 0)), worldMatrix, this._transformationMatrix, globalViewport);

            this._renderSingleAxis(projectedPosition, xAxis, xAxisText, "x", 0xFF0000);

            var yAxis: Vector3 = Vector3.Project(position.add(new Vector3(0, unit, 0)), worldMatrix, this._transformationMatrix, globalViewport);
            var yAxisText: Vector3 = Vector3.Project(position.add(new Vector3(0, unit * 1.5, 0)), worldMatrix, this._transformationMatrix, globalViewport);

            this._renderSingleAxis(projectedPosition, yAxis, yAxisText, "y", 0x00FF00);

            var zAxis: Vector3 = Vector3.Project(position.add(new Vector3(0, 0, unit)), worldMatrix, this._transformationMatrix, globalViewport);
            var zAxisText: Vector3 = Vector3.Project(position.add(new Vector3(0, 0, unit * 1.5)), worldMatrix, this._transformationMatrix, globalViewport);

            this._renderSingleAxis(projectedPosition, zAxis, zAxisText, "z", 0x0000FF);
        }

        private function _renderLabel(label: String, projectedPosition: Vector3, labelOffset: Number, onClick: Function, getFillStyle: Function): void {
            if (projectedPosition.z > 0 && projectedPosition.z < 1.0) {
                var text: TextField = new TextField();
                text.text = label;
                var textMetrics: TextLineMetrics = text.getLineMetrics(0);
                var centerX: Number = projectedPosition.x - textMetrics.width / 2;
                var centerY: Number = projectedPosition.y;

                if (this._showUI && this._isClickInsideRect(this._canvasRect.left * this._ratio + centerX - 5, this._canvasRect.top * this._ratio + centerY - labelOffset - 12, textMetrics.width + 10, 17)) {
                    onClick();
                }

                fail();
            }
        }

        private function _isClickInsideRect(x: Number, y: Number, width: Number, height: Number): Boolean {

            return true;
        }

        public function isVisible(): Boolean {
            return this._enabled;
        }
        public function hide(): void {
            if (!this._enabled) {
                return;
            }

            this._enabled = false;

            var engine: Engine = this._scene.getEngine();

            this._scene.unregisterBeforeRender(this._syncData);
            this._scene.unregisterAfterRender(this._syncUI);
            this._rootElement.removeChild(this._globalDiv);

            this._scene.forceShowBoundingBoxes = false;
            this._scene.forceWireframe = false;

//            StandardMaterial.DiffuseTextureEnabled = true;
//            StandardMaterial.AmbientTextureEnabled = true;
//            StandardMaterial.SpecularTextureEnabled = true;
//            StandardMaterial.EmissiveTextureEnabled = true;
//            StandardMaterial.BumpTextureEnabled = true;
//            StandardMaterial.OpacityTextureEnabled = true;
//            StandardMaterial.ReflectionTextureEnabled = true;
//            StandardMaterial.LightmapTextureEnabled = true;
//            StandardMaterial.RefractionTextureEnabled = true;
//            StandardMaterial.ColorGradingTextureEnabled = true;

//            this._scene.shadowsEnabled = true;
            this._scene.particlesEnabled = true;
//            this._scene.postProcessesEnabled = true;
//            this._scene.collisionsEnabled = true;
//            this._scene.lightsEnabled = true;
            this._scene.texturesEnabled = true;
//            this._scene.lensFlaresEnabled = true;
//            this._scene.proceduralTexturesEnabled = true;
            this._scene.renderTargetsEnabled = true;
//            this._scene.probesEnabled = true;

            engine.getRenderingCanvas().removeEventListener(MouseEvent.CLICK, this._onCanvasClick);

            this._clearSkeletonViewers();
        }

        private function _clearSkeletonViewers(): void {
//        for (var index = 0; index < this._skeletonViewers.length; index++) {
//            this._skeletonViewers[index].dispose();
//        }
//
//        this._skeletonViewers = [];
        }

        public function show(showUI: Boolean = true, camera: Camera = null, rootElement: DisplayObjectContainer = null): void {
            if (this._enabled) {
                return;
            }

            this._enabled = true;

            if (camera) {
                this._camera = camera;
            } else {
                this._camera = this._scene.activeCamera;
            }

            this._showUI = showUI;

            var engine: Engine = this._scene.getEngine();

            this._globalDiv = new Sprite();

            this._rootElement = rootElement;

            this._rootElement.addChild(this._globalDiv);

            this._generateDOMElements();

            engine.getRenderingCanvas().addEventListener(MouseEvent.CLICK, this._onCanvasClick);

            this._syncPositions();
            this._scene.registerBeforeRender(this._syncData);
            this._scene.registerAfterRender(this._syncUI);
        }

        private function _clearLabels(): void {
            this._drawingContext.removeChildren();

            for (var index: int = 0; index < this._scene.meshes.length; index++) {
                var mesh: AbstractMesh = this._scene.meshes[index];
                mesh.renderOverlay = false;
            }
        }

        private function _generateheader(root: Sprite, text: String): void {
        }

        private function _generateTexBox(root: Sprite, title: String, color: String): void {
        }

        private function _generateAdvancedCheckBox(root: Sprite, leftTitle: String, rightTitle: String, initialState: Boolean, task: Function, tag: Object = null): void {
        }

        private function _generateCheckBox(root: Sprite, title: String, initialState: Boolean, task: Function, tag: Object = null): void {
        }

        private function _generateButton(root: Sprite, title: String, task: Function, tag: Object = null): void {
        }

        private function _generateRadio(root: Sprite, title: String, name: String, initialState: Boolean, task: Function, tag: Object = null): void {
        }

        private function _generateDOMElements(): void {
            this._globalDiv.name = "DebugLayer";

            // Drawing canvas
            this._drawingContext = new Sprite();
            this._drawingContext.name = "DebugLayerDrawingCanvas";
            this._globalDiv.addChild(this._drawingContext);

            if (this._showUI) {
                // Stats
                this._statsDiv = new DivElement();
                this._statsDiv.name = "DebugLayerStats";

                var text: TextField = new TextField();
                text.name = "txt1";
                text.autoSize = TextFieldAutoSize.LEFT;
                this._statsDiv.addChild(text);

                text = new TextField();
                text.name = "txt2";
                text.autoSize = TextFieldAutoSize.LEFT;
                text.x = 200;
                this._statsDiv.addChild(text);

                text = new TextField();
                text.name = "txt3";
                text.autoSize = TextFieldAutoSize.LEFT;
                text.y = 200;
                this._statsDiv.addChild(text);

                this._globalDiv.addChild(this._statsDiv);
            }
        }

        private function _displayStats(): void {
            var scene: Scene = this._scene;
            var engine: Engine = scene.getEngine();
            var glInfo: String = engine.getGlInfo();

            TextField(this._statsDiv.getChildByName("txt1")).text = "Babylon.js v" + Engine.Version + " - " + Tools.Format(engine.getFps(), 0) + " fps\n\n"
                    + "Count\n"
                    + "Total meshes: " + scene.meshes.length + "\n"
                    + "Total lights: " + NaN + "\n"
                    + "Total vertices: " + scene.getTotalVertices() + "\n"
                    + "Total materials: " + scene.materials.length + "\n"
                    + "Total textures: " + scene.textures.length + "\n"
                    + "Active meshes: " + scene.getActiveMeshes().length + "\n"
                    + "Active indices: " + scene.getActiveIndices() + "\n"
                    + "Active bones: " + scene.getActiveBones() + "\n"
                    + "Active particles: " + scene.getActiveParticles() + "\n"
                    + "Draw calls: " + engine.drawCalls + "\n\n";

            TextField(this._statsDiv.getChildByName("txt2")).text = "Duration\n"
                    + "Meshes selection: " + Tools.Format(scene.getEvaluateActiveMeshesDuration()) + " ms\n"
                    + "Render Targets: " + NaN + " ms\n"
                    + "Particles: " + Tools.Format(scene.getParticlesDuration()) + " ms\n"
                    + "Sprites: " + NaN + " ms\n\n"
                    + "Render: " + Tools.Format(scene.getRenderDuration()) + " ms\n"
                    + "Frame: " + Tools.Format(scene.getLastFrameDuration()) + " ms\n"
                    + "Potential FPS: " + Tools.Format(1000.0 / scene.getLastFrameDuration(), 0) + "\n"
                    + "Resolution: " + engine.getRenderWidth() + "x" + engine.getRenderHeight() + "\n\n";

            TextField(this._statsDiv.getChildByName("txt3")).text = "Info\n"
                    + glInfo + "\n"
                    + "Mem: " + getRamString(System.totalMemory) + "\n"
                    + "Score: " + FrameManager.frameScore + "\n";
        }

        private function getRamString(ram:Number):String {
            var ram_unit:String = 'B';

            if (ram > 1048576) {
                ram /= 1048576;
                ram_unit = 'M';
            } else if (ram > 1024) {
                ram /= 1024;
                ram_unit = 'K';
            }

            return ram.toFixed(1) + ram_unit;
        }
    }
}

import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;

class DivElement extends Sprite {
    private var _mask: Shape;

    public function DivElement() {
        _mask = new Shape();
        this.addChild(_mask);
        this.mask = _mask;

        this.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel, false, 0, true);
    }

    private function onWheel(event: MouseEvent): void {
        event.stopImmediatePropagation();

        for (var i: int = 0; i < this.numChildren; i++) {
            var child: DisplayObject = this.getChildAt(i);
            if (child != this._mask)
                child.y += event.delta;
        }
    }

    public function setSize(width: Number, height: Number): void {
        this.graphics.clear();
        this.graphics.beginFill(0xFFFFFF, 0.5);
        this.graphics.drawRect(0, 0, width, height);
        this.graphics.endFill();

        _mask.graphics.clear();
        _mask.graphics.beginFill(0);
        _mask.graphics.drawRect(0, 0, width, height);
        _mask.graphics.endFill();
    }
}
