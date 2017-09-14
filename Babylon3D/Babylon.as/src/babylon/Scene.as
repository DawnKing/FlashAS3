/**
 * Created by caijingxiao on 2016/10/13.
 */
package babylon {
    import babylon.animations.Animatable;
    import babylon.animations.Animation;
    import babylon.bones.Skeleton;
    import babylon.cameras.Camera;
    import babylon.debug.DebugLayer;
    import babylon.lights.Light;
    import babylon.lights.shadows.IShadowGenerator;
    import babylon.materials.Material;
    import babylon.materials.MultiMaterial;
    import babylon.materials.StandardMaterial;
    import babylon.materials.textures.BaseTexture;
    import babylon.materials.textures.RenderTargetTexture;
    import babylon.math.Color4;
    import babylon.math.Frustum;
    import babylon.math.Matrix;
    import babylon.math.Plane;
    import babylon.math.Vector2;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Geometry;
    import babylon.mesh.Mesh;
    import babylon.mesh.SubMesh;
    import babylon.particles.ParticleSystem;
    import babylon.postProcess.PostProcessManager;
    import babylon.rendering.RenderingManager;
    import babylon.tools.PerfCounter;
    import babylon.tools.SmartArray;
    import babylon.tools.Tools;
    import babylon.tools.observable.Observable;
    import babylon.tools.observable.Observer;
    import babylon.zip.scene.IDisposable;
    import babylon.zip.scene.PointerEventTypes;
    import babylon.zip.scene.PointerInfo;
    import babylon.zip.scene.PointerInfoPre;

    import easiest.unit.asserts.fail;

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;

    public class Scene {
        // Statics
        public static const MinDeltaTime: Number = 1.0;
        public static const MaxDeltaTime: Number = 1000.0;

        // Members
        public var autoClear: Boolean = true;
        public var clearColor: Color4 = new Color4(0.2, 0.2, 0.3, 1.0);

        public var forceWireframe: Boolean = false;
        public var forcePointsCloud: Boolean = false;
        public var forceShowBoundingBoxes: Boolean = false;
        public var clipPlane: Plane;
        public var animationsEnabled: Boolean = true;

        public var useRightHandedSystem: Boolean = false;

        // Metadata

        // Events

        /**
         * An event triggered before rendering the scene
         */
        public var onBeforeRenderObservable: Observable = new Observable();

        private var _onBeforeRenderObserver: Observer;
        public function set beforeRender(callback: Function): void {
            if (this._onBeforeRenderObserver) {
                this.onBeforeRenderObservable.remove(this._onBeforeRenderObserver);
            }
            this._onBeforeRenderObserver = this.onBeforeRenderObservable.add(callback);
        }

        /**
         * An event triggered after rendering the scene
         */
        public var onAfterRenderObservable: Observable = new Observable();

        private var _onAfterRenderObserver: Observer;
        public function set afterRender(callback: Function): void {
            if (this._onAfterRenderObserver) {
                this.onAfterRenderObservable.remove(this._onAfterRenderObserver);
            }
            this._onAfterRenderObserver = this.onAfterRenderObservable.add(callback);
        }

        // Animations

        // Pointers
        public var pointerDownPredicate: Function;  // (Mesh: AbstractMesh) => boolean;
        public var pointerUpPredicate: Function;  // (Mesh: AbstractMesh) => boolean;
        public var pointerMovePredicate: Function;  // (Mesh: AbstractMesh) => boolean;
        private var _onPointerMove: Function;  // (evt: PointerEvent) => void;
        private var _onPointerDown: Function;  // (evt: PointerEvent) => void;
        private var _onPointerUp: Function;  // (evt: PointerEvent) => void;

        /**
         * This observable event is triggered when any mouse event registered during Scene.attach() is called BEFORE the 3D engine to process anything (mesh/sprite picking for instance).
         * You have the possibility to skip the 3D Engine process and the call to onPointerObservable by setting PointerInfoBase.skipOnPointerObservable to true
         */
        public var onPrePointerObservable: Observable = new Observable();

        /**
         * Observable event triggered each time an input event is received from the rendering canvas
         */
        public var onPointerObservable: Observable = new Observable();

        public function  get unTranslatedPointer(): Vector2 {
            return new Vector2(this._unTranslatedPointerX, this._unTranslatedPointerY);
        }

        public var cameraToUseForPointers: Camera = null; // Define this parameter if you are using multiple cameras and you want to specify which one should be used for pointer position
        private var _pointerX: Number;
        private var _pointerY: Number;
        private var _unTranslatedPointerX: Number;
        private var _unTranslatedPointerY: Number;
        private var _startingPointerPosition: Vector2 = new Vector2(0, 0);
        // Mirror

        // Keyboard
        private var _onKeyDown: Function;   // (evt: Event) => void;
        private var _onKeyUp: Function; // (evt: Event) => void;

        // Fog

        // Lights
        /**
         * is shadow enabled on this scene.
         */
        public var shadowsEnabled: Boolean = true;
        /**
         * is light enabled on this scene.
         */
        public var lightsEnabled: Boolean = true;
        /**
         * All of the lights added to this scene.
         */
        public var lights: Vector.<Light> = new <Light>[];

        // Cameras
        public var cameras: Vector.<Camera> = new <Camera>[];
        public var activeCamera: Camera;

        // Meshes
        public var meshes: Vector.<AbstractMesh> = new <AbstractMesh>[];

        // Geometries
        private var _geometries: Vector.<Geometry> = new <Geometry>[];

        public var materials: Vector.<Material> = new <Material>[];
        public var multiMaterials: Vector.<MultiMaterial> = new <MultiMaterial>[];
        private var _defaultMaterial: StandardMaterial;

        public function get defaultMaterial(): StandardMaterial {//349
            if (!this._defaultMaterial) {
                this._defaultMaterial = new StandardMaterial("default material", this);
            }

            return this._defaultMaterial;
        }

        // Textures
        public var texturesEnabled: Boolean = true;
        public var textures: Vector.<BaseTexture> = new <BaseTexture>[];

        // Particles
        public var particlesEnabled: Boolean = true;
        public var particleSystems: Vector.<ParticleSystem> = new <ParticleSystem>[];

        // Sprites

        // Layers

        // Skeletons
        public var skeletonsEnabled: Boolean = true;
        public var skeletons: Vector.<Skeleton> = new <Skeleton>[];

        // Lens flares

        // Collisions

        // PostProcesses
        public var postProcessesEnabled: Boolean = true;
        public var postProcessManager: PostProcessManager;
//        public var postProcessRenderPipelineManager: PostProcessRenderPipelineManager;

        // Customs render targets
        public var renderTargetsEnabled: Boolean = true;
        public var dumpNextRenderTargets: Boolean = false;

        // Delay loading

        // Imported meshes
        public var importedMeshesFiles: Vector.<String> = new <String>[];

        // Probes

        // Database

        // Procedural textures

        // Sound Tracks

        // Simplification Queue

        // Private
        private var _engine: Engine;

        // Performance counters
//        private var _totalMeshesCounter: PerfCounter = new PerfCounter();
        private var _totalLightsCounter: PerfCounter = new PerfCounter();
//        private var _totalMaterialsCounter: PerfCounter = new PerfCounter();
//        private var _totalTexturesCounter: PerfCounter = new PerfCounter();
        private var _totalVertices: PerfCounter = new PerfCounter();
        public var _activeIndices: PerfCounter = new PerfCounter();
        public var _activeParticles: PerfCounter = new PerfCounter();
        private var _lastFrameDuration: PerfCounter = new PerfCounter();
        private var _evaluateActiveMeshesDuration: PerfCounter = new PerfCounter();
        private var _renderTargetsDuration: PerfCounter = new PerfCounter();
        public var _particlesDuration: PerfCounter = new PerfCounter();
        private var _renderDuration: PerfCounter = new PerfCounter();
//        public var _spritesDuration: PerfCounter = new PerfCounter();
        public var _activeBones: PerfCounter = new PerfCounter();

        private var _animationRatio: Number;

        private var _animationStartDate: Number;
        public var _cachedMaterial: Material;

        private var _renderId: int = 0;

        private var _intermediateRendering: Boolean = false;

        public var _toBeDisposed: Vector.<IDisposable> = new <IDisposable>[];
        private var _pendingData: Array = [];

        private var _activeMeshes: Vector.<Mesh> = new <Mesh>[];
        private var _processedMaterials: Vector.<Material> = new <Material>[];
        private var _renderTargets: Vector.<RenderTargetTexture> = new <RenderTargetTexture>[];
        public var _activeParticleSystems: Vector.<ParticleSystem> = new <ParticleSystem>[];
        private var _activeSkeletons: Vector.<Skeleton> = new <Skeleton>[];
        private var _softwareSkinnedMeshes: Vector.<Mesh> = new <Mesh>[];

        private var _renderingManager: RenderingManager;

        public var _activeAnimatables: Vector.<Animatable> = new <Animatable>[];

        private var _transformMatrix: Matrix = Matrix.Zero();

        private var _viewMatrix: Matrix;
        private var _projectionMatrix: Matrix;
        private var _frustumPlanes: Vector.<Plane>;

        public var _debugLayer: DebugLayer;

        private var _uniqueIdCounter: int = 0;

        public function Scene(engine: Engine) {
            _engine = engine;

            engine.scenes.push(this);

            this._renderingManager = new RenderingManager(this);

            this.postProcessManager = new PostProcessManager(this);

            this.attachControl();
        }

        // Properties
        public function get debugLayer(): DebugLayer {
            if (!this._debugLayer) {
                this._debugLayer = new DebugLayer(this);
            }
            return this._debugLayer;
        }

        public function getCachedMaterial(): Material {//655
            return this._cachedMaterial;
        }

        public function getEngine():Engine {//667
            return this._engine;
        }

        public function getTotalVertices(): int {//671
            return this._totalVertices.current;
        }

        public function get totalVerticesPerfCounter(): PerfCounter {//675
            return this._totalVertices;
        }

        public function getActiveIndices(): int {
            return this._activeIndices.current;
        }

        public function get totalActiveIndicesPerfCounter(): PerfCounter {
            return this._activeIndices;
        }

        public function getActiveParticles(): int {
            return this._activeParticles.current;
        }

//        public function get activeParticlesPerfCounter(): PerfCounter {
//            return this._activeParticles;
//        }

        public function getActiveBones(): int {
            return this._activeBones.current;
        }

        public function get activeBonesPerfCounter(): PerfCounter {
            return this._activeBones;
        }

        // Stats
        public function getLastFrameDuration(): Number {
            return this._lastFrameDuration.current;
        }

        public function get lastFramePerfCounter(): PerfCounter {
            return this._lastFrameDuration;
        }

        public function getEvaluateActiveMeshesDuration(): Number {
            return this._evaluateActiveMeshesDuration.current;
        }

        public function get evaluateActiveMeshesDurationPerfCounter(): PerfCounter {
            return this._evaluateActiveMeshesDuration;
        }

        public function getActiveMeshes(): Vector.<Mesh> {
            return this._activeMeshes;
        }

//        public function getRenderTargetsDuration(): Number {
//            return this._renderTargetsDuration.current;
//        }

        public function getRenderDuration(): Number {
            return this._renderDuration.current;
        }

        public function get renderDurationPerfCounter(): PerfCounter {
            return this._renderDuration;
        }

        public function getParticlesDuration(): Number {
            return this._particlesDuration.current;
        }

        public function get particlesDurationPerfCounter(): PerfCounter {
            return this._particlesDuration;
        }

//        public function getSpritesDuration(): Number {
//            return this._spritesDuration.current;
//        }
//
//        public function get spriteDuractionPerfCounter(): PerfCounter {
//            return this._spritesDuration;
//        }

        public function getAnimationRatio(): Number {
            return this._animationRatio;
        }

        public function getRenderId(): Number {
            return this._renderId;
        }

        public function incrementRenderId(): void {//760
            this._renderId++;
        }

        private function _updatePointerPosition(evt: MouseEvent): void {
            var canvasRect: Rectangle = new Rectangle();    // this._engine.getRenderingCanvasClientRect();

            this._pointerX = evt.stageX - canvasRect.left;
            this._pointerY = evt.stageY - canvasRect.top;

            this._unTranslatedPointerX = this._pointerX;
            this._unTranslatedPointerY = this._pointerY;

            if (this.cameraToUseForPointers) {
                this._pointerX = this._pointerX - this.cameraToUseForPointers.viewport.x * this._engine.getRenderWidth();
                this._pointerY = this._pointerY - this.cameraToUseForPointers.viewport.y * this._engine.getRenderHeight();
            }
        }

        // Pointers handling

        /**
         * Attach events to the canvas (To handle actionManagers triggers and raise onPointerMove, onPointerDown and onPointerUp
         * @param attachUp defines if you want to attach events to pointerup
         * @param attachDown defines if you want to attach events to pointerdown
         * @param attachMove defines if you want to attach events to pointermove
         */
        public function attachControl(attachUp: Boolean = true, attachDown: Boolean = true, attachMove: Boolean = true): void {
//            var spritePredicate = function (sprite: Sprite): Boolean {
//                return sprite.isPickable && sprite.actionManager && sprite.actionManager.hasPointerTriggers;
//            };

            var type: uint;
            var pip: PointerInfoPre;
            var pi: PointerInfo;

            this._onPointerMove = function (evt: MouseEvent): void {

                _updatePointerPosition(evt);

                // PreObservable support
                if (onPrePointerObservable.hasObservers()) {
                    type = evt.type === MouseEvent.MOUSE_WHEEL ? PointerEventTypes.POINTERWHEEL : PointerEventTypes.POINTERMOVE;
                    pip = new PointerInfoPre(type, evt, this._unTranslatedPointerX, this._unTranslatedPointerY);
                    onPrePointerObservable.notifyObservers(pi, type);
                    if (pip.skipOnPointerObservable) {
                        return;
                    }
                }

                if (!cameraToUseForPointers && !activeCamera) {
                    return;
                }

                var pickResult: Object = null;
//                var canvas = _engine.getRenderingCanvas();
//
//                if (!pointerMovePredicate) {
//                    pointerMovePredicate = function (mesh: AbstractMesh): Boolean { return mesh.isPickable && mesh.isVisible && mesh.isReady() && (constantlyUpdateMeshUnderPointer || mesh.actionManager !== null && mesh.actionManager !== undefined)};
//                }
//
//                // Meshes
//                var pickResult = pick(_unTranslatedPointerX, _unTranslatedPointerY, pointerMovePredicate, false, cameraToUseForPointers);
//
//                if (pickResult.hit && pickResult.pickedMesh) {
//                    setPointerOverSprite(null);
//
//                    setPointerOverMesh(pickResult.pickedMesh);
//
//                    if (_pointerOverMesh.actionManager && _pointerOverMesh.actionManager.hasPointerTriggers) {
//                        if (_pointerOverMesh.actionManager.hoverCursor) {
//                            canvas.style.cursor = _pointerOverMesh.actionManager.hoverCursor;
//                        } else {
//                            canvas.style.cursor = hoverCursor;
//                        }
//                    } else {
//                        canvas.style.cursor = "";
//                    }
//                } else {
//                    setPointerOverMesh(null);
//                    // Sprites
//                    pickResult = pickSprite(_unTranslatedPointerX, _unTranslatedPointerY, spritePredicate, false, cameraToUseForPointers);
//
//                    if (pickResult.hit && pickResult.pickedSprite) {
//                        setPointerOverSprite(pickResult.pickedSprite);
//                        if (_pointerOverSprite.actionManager && _pointerOverSprite.actionManager.hoverCursor) {
//                            canvas.style.cursor = _pointerOverSprite.actionManager.hoverCursor;
//                        } else {
//                            canvas.style.cursor = hoverCursor;
//                        }
//                    } else {
//                        setPointerOverSprite(null);
//                        // Restore pointer
//                        canvas.style.cursor = "";
//                    }
//                }

//                if (onPointerMove) {
//                    onPointerMove(evt, pickResult);
//                }

                if (onPointerObservable.hasObservers()) {
                    type = evt.type === MouseEvent.MOUSE_WHEEL ? PointerEventTypes.POINTERWHEEL : PointerEventTypes.POINTERMOVE;
                    pi = new PointerInfo(type, evt, pickResult);
                    onPointerObservable.notifyObservers(pi, type);
                }
            };

            var startingPointerTime: Number;

            this._onPointerDown = function (evt: MouseEvent): void {
                _updatePointerPosition(evt);

                // PreObservable support
                if (onPrePointerObservable.hasObservers()) {
                    type = PointerEventTypes.POINTERDOWN;
                    pip = new PointerInfoPre(type, evt, _unTranslatedPointerX, _unTranslatedPointerY);
                    onPrePointerObservable.notifyObservers(pi, type);
                    if (pip.skipOnPointerObservable) {
                        return;
                    }
                }

                if (!cameraToUseForPointers && !activeCamera) {
                    return;
                }

                _startingPointerPosition.x = _pointerX;
                _startingPointerPosition.y = _pointerY;
                startingPointerTime = new Date().getTime();

//                if (!pointerDownPredicate) {
//                    pointerDownPredicate = function (mesh: AbstractMesh): Boolean {
//                        return mesh.isPickable && mesh.isVisible && mesh.isReady() && (!mesh.actionManager || mesh.actionManager.hasPointerTriggers);
//                    };
//                }

                // Meshes
                this._pickedDownMesh = null;
                var pickResult: Object = null;
//                var pickResult = pick(_unTranslatedPointerX, _unTranslatedPointerY, pointerDownPredicate, false, cameraToUseForPointers);

//                if (pickResult.hit && pickResult.pickedMesh) {
//                    if (pickResult.pickedMesh.actionManager) {
//                        _pickedDownMesh = pickResult.pickedMesh;
//                        if (pickResult.pickedMesh.actionManager.hasPickTriggers) {
//                            switch (evt.button) {
//                                case 0:
//                                    pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnLeftPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
//                                    break;
//                                case 1:
//                                    pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnCenterPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
//                                    break;
//                                case 2:
//                                    pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnRightPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
//                                    break;
//                            }
//                            if (pickResult.pickedMesh.actionManager) {
//                                pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnPickDownTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
//                            }
//                        }
//
//                        if (pickResult.pickedMesh.actionManager && pickResult.pickedMesh.actionManager.hasSpecificTrigger(ActionManager.OnLongPressTrigger)) {
//                            var that = this;
//                            window.setTimeout(function () {
//                                var pickResult = that.pick(that._unTranslatedPointerX, that._unTranslatedPointerY,
//                                        (mesh: AbstractMesh): boolean mesh.isPickable && mesh.isVisible && mesh.isReady() && mesh.actionManager && mesh.actionManager.hasSpecificTrigger(ActionManager.OnLongPressTrigger),
//                                        false, that.cameraToUseForPointers);
//
//                                if (pickResult.hit && pickResult.pickedMesh) {
//                                    if (pickResult.pickedMesh.actionManager) {
//                                        if (that._startingPointerTime !== 0 && ((new Date().getTime() - that._startingPointerTime) > ActionManager.LongPressDelay) && (Math.abs(that._startingPointerPosition.x - that._pointerX) < ActionManager.DragMovementThreshold && Math.abs(that._startingPointerPosition.y - that._pointerY) < ActionManager.DragMovementThreshold)) {
//                                            that._startingPointerTime = 0;
//                                            pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnLongPressTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
//                                        }
//                                    }
//                                }
//                            }, ActionManager.LongPressDelay);
//                        }
//                    }
//                }

//                if (onPointerDown) {
//                    onPointerDown(evt, pickResult);
//                }

                if (onPointerObservable.hasObservers()) {
                    type = PointerEventTypes.POINTERDOWN;
                    pi = new PointerInfo(type, evt, pickResult);
                    onPointerObservable.notifyObservers(pi, type);
                }

                // Sprites
//                _pickedDownSprite = null;
//                if (spriteManagers.length > 0) {
//                    pickResult = pickSprite(_unTranslatedPointerX, _unTranslatedPointerY, spritePredicate, false, cameraToUseForPointers);
//
//                    if (pickResult.hit && pickResult.pickedSprite) {
//                        if (pickResult.pickedSprite.actionManager) {
//                            _pickedDownSprite = pickResult.pickedSprite;
//                            switch (evt.button) {
//                                case 0:
//                                    pickResult.pickedSprite.actionManager.processTrigger(ActionManager.OnLeftPickTrigger, ActionEvent.CreateNewFromSprite(pickResult.pickedSprite, this, evt));
//                                    break;
//                                case 1:
//                                    pickResult.pickedSprite.actionManager.processTrigger(ActionManager.OnCenterPickTrigger, ActionEvent.CreateNewFromSprite(pickResult.pickedSprite, this, evt));
//                                    break;
//                                case 2:
//                                    pickResult.pickedSprite.actionManager.processTrigger(ActionManager.OnRightPickTrigger, ActionEvent.CreateNewFromSprite(pickResult.pickedSprite, this, evt));
//                                    break;
//                            }
//                            if (pickResult.pickedSprite.actionManager) {
//                                pickResult.pickedSprite.actionManager.processTrigger(ActionManager.OnPickDownTrigger, ActionEvent.CreateNewFromSprite(pickResult.pickedSprite, this, evt));
//                            }
//                        }
//                    }
//                }
            };

            this._onPointerUp = function (evt: MouseEvent): void {
                _updatePointerPosition(evt);

                // PreObservable support
                if (onPrePointerObservable.hasObservers()) {
                    type = PointerEventTypes.POINTERUP;
                    pip = new PointerInfoPre(type, evt, _unTranslatedPointerX, _unTranslatedPointerY);
                    onPrePointerObservable.notifyObservers(pi, type);
                    if (pip.skipOnPointerObservable) {
                        return;
                    }
                }

                if (!cameraToUseForPointers && !activeCamera) {
                    return;
                }

//                if (!pointerUpPredicate) {
//                    pointerUpPredicate = function (mesh: AbstractMesh): Boolean {
//                        return mesh.isPickable && mesh.isVisible && mesh.isReady() && (!mesh.actionManager || (mesh.actionManager.hasPickTriggers || mesh.actionManager.hasSpecificTrigger(ActionManager.OnLongPressTrigger)));
//                    };
//                }

                // Meshes
                var pickResult: Object = null;
//                var pickResult = pick(_unTranslatedPointerX, _unTranslatedPointerY, pointerUpPredicate, false, cameraToUseForPointers);
//
//                if (pickResult.hit && pickResult.pickedMesh) {
//                    if (_pickedDownMesh != null && pickResult.pickedMesh == _pickedDownMesh) {
//                        if (onPointerPick) {
//                            onPointerPick(evt, pickResult);
//                        }
//                        if (onPointerObservable.hasObservers()) {
//                            type = PointerEventTypes.POINTERPICK;
//                            pi = new PointerInfo(type, evt, pickResult);
//                            onPointerObservable.notifyObservers(pi, type);
//                        }
//                    }
//                    if (pickResult.pickedMesh.actionManager) {
//                        pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnPickUpTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
//                        if (pickResult.pickedMesh.actionManager) {
//                            if (Math.abs(_startingPointerPosition.x - _pointerX) < ActionManager.DragMovementThreshold && Math.abs(_startingPointerPosition.y - _pointerY) < ActionManager.DragMovementThreshold) {
//                                pickResult.pickedMesh.actionManager.processTrigger(ActionManager.OnPickTrigger, ActionEvent.CreateNew(pickResult.pickedMesh, evt));
//                            }
//                        }
//                    }
//                }
//                if (_pickedDownMesh && _pickedDownMesh.actionManager && _pickedDownMesh !== pickResult.pickedMesh) {
//                    _pickedDownMesh.actionManager.processTrigger(ActionManager.OnPickOutTrigger, ActionEvent.CreateNew(_pickedDownMesh, evt));
//                }
//
//                if (onPointerUp) {
//                    onPointerUp(evt, pickResult);
//                }

                if (onPointerObservable.hasObservers()) {
                    type = PointerEventTypes.POINTERUP;
                    pi = new PointerInfo(type, evt, pickResult);
                    onPointerObservable.notifyObservers(pi, type);
                }

                startingPointerTime = 0;

                // Sprites
//                if (spriteManagers.length > 0) {
//                    pickResult = pickSprite(_unTranslatedPointerX, _unTranslatedPointerY, spritePredicate, false, cameraToUseForPointers);
//
//                    if (pickResult.hit && pickResult.pickedSprite) {
//                        if (pickResult.pickedSprite.actionManager) {
//                            pickResult.pickedSprite.actionManager.processTrigger(ActionManager.OnPickUpTrigger, ActionEvent.CreateNewFromSprite(pickResult.pickedSprite, this, evt));
//                            if (pickResult.pickedSprite.actionManager) {
//                                if (Math.abs(_startingPointerPosition.x - _pointerX) < ActionManager.DragMovementThreshold && Math.abs(_startingPointerPosition.y - _pointerY) < ActionManager.DragMovementThreshold) {
//                                    pickResult.pickedSprite.actionManager.processTrigger(ActionManager.OnPickTrigger, ActionEvent.CreateNewFromSprite(pickResult.pickedSprite, this, evt));
//                                }
//                            }
//                        }
//                    }
//                    if (_pickedDownSprite && _pickedDownSprite.actionManager && _pickedDownSprite !== pickResult.pickedSprite) {
//                        _pickedDownSprite.actionManager.processTrigger(ActionManager.OnPickOutTrigger, ActionEvent.CreateNewFromSprite(_pickedDownSprite, this, evt));
//                    }
//                }
            };

            this._onKeyDown = function (evt: Event): void {
//                if (actionManager) {
//                    actionManager.processTrigger(ActionManager.OnKeyDownTrigger, ActionEvent.CreateNewFromScene(this, evt));
//                }
            };

            this._onKeyUp = function (evt: Event): void {
//                if (actionManager) {
//                    actionManager.processTrigger(ActionManager.OnKeyUpTrigger, ActionEvent.CreateNewFromScene(this, evt));
//                }
            };


            var canvas: EventDispatcher = this._engine.getRenderingCanvas();
            if (attachMove) {
                canvas.addEventListener(MouseEvent.MOUSE_MOVE, this._onPointerMove, false);
                canvas.addEventListener(MouseEvent.MOUSE_WHEEL, this._onPointerMove, false);
            }

            if (attachDown) {
                canvas.addEventListener(MouseEvent.MOUSE_DOWN, this._onPointerDown, false);
            }

            if (attachUp) {
                canvas.addEventListener(MouseEvent.MOUSE_UP, this._onPointerUp, false);
            }

            canvas.addEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown, false);
            canvas.addEventListener(KeyboardEvent.KEY_UP, this._onKeyUp, false);
        }

        public function detachControl(): void {
            var canvas: EventDispatcher = this._engine.getRenderingCanvas();

            canvas.removeEventListener(MouseEvent.MOUSE_MOVE, this._onPointerMove);
            canvas.removeEventListener(MouseEvent.MOUSE_DOWN, this._onPointerDown);
            canvas.removeEventListener(MouseEvent.MOUSE_UP, this._onPointerUp, false);

            // Wheel
            canvas.removeEventListener(MouseEvent.MOUSE_WHEEL, this._onPointerMove);

            canvas.removeEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown);
            canvas.removeEventListener(KeyboardEvent.KEY_UP, this._onKeyUp);
        }

        public function resetCachedMaterial():void {//1059
            _cachedMaterial = null;
        }

        public function registerBeforeRender(func: Function): void {//1141
            this.onBeforeRenderObservable.add(func);
        }

        public function unregisterBeforeRender(func: Function): void {
            this.onBeforeRenderObservable.removeCallback(func);
        }

        public function registerAfterRender(func: Function): void {
            this.onAfterRenderObservable.add(func);
        }

        public function unregisterAfterRender(func: Function): void {
            this.onAfterRenderObservable.removeCallback(func);
        }

        public function _addPendingData(data: *): void {//1157
            this._pendingData.push(data);
        }

        public function _removePendingData(data: *): void {//1083
            var index: int = this._pendingData.indexOf(data);

            if (index != -1) {
                this._pendingData.splice(index, 1);
            }
        }

        public function beginAnimation(target: Object, from: int, to: int, loop: Boolean = false, speedRatio: Number = 1.0, onAnimationEnd: Function = null, animatable: Animatable = null): Animatable {
            this.stopAnimation(target);

            if (!animatable) {
                animatable = new Animatable(this, target, from, to, loop, speedRatio, onAnimationEnd);
            }

            // Local animations
            if (target.hasOwnProperty("animations")) {
                animatable.appendAnimations(target, target.animations);
            }

            // Children animations
            if (target.hasOwnProperty("getAnimatables")) {
                var animatables: Array = target.getAnimatables();
                for (var index: int = 0; index < animatables.length; index++) {
                    this.beginAnimation(animatables[index], from, to, loop, speedRatio, onAnimationEnd, animatable);
                }
            }

            animatable.reset();

            return animatable;
        }

        public function beginDirectAnimation(target: Object, animations: Vector.<Animation>, from: int, to: int, loop: Boolean = false, speedRatio: Number = NaN, onAnimationEnd: Function = null): Animatable {//1165
            if (isNaN(speedRatio)) {
                speedRatio = 1.0;
            }

            var animatable: Animatable = new Animatable(this, target, from, to, loop, speedRatio, onAnimationEnd, animations);

            return animatable;
        }

        public function getAnimatableByTarget(target: Object): Animatable {
            for (var index: int = 0; index < this._activeAnimatables.length; index++) {
                if (this._activeAnimatables[index].target === target) {
                    return this._activeAnimatables[index];
                }
            }

            return null;
        }

        public function stopAnimation(target: Object, animationName: String = null): void {//1195
            var animatable: Animatable = this.getAnimatableByTarget(target);

            if (animatable) {
                animatable.stop(animationName);
            }
        }

        private function _animate(): void {//1203
            if (!this.animationsEnabled || this._activeAnimatables.length === 0) {
                return;
            }

            if (!this._animationStartDate) {
                if (this._pendingData.length > 0) {
                    return;
                }

                this._animationStartDate = Tools.Now;
            }
            // Getting time
            var now: Number = Tools.Now;
            var delay: Number = now - this._animationStartDate;

            for (var index: int = 0; index < this._activeAnimatables.length; index++) {
                this._activeAnimatables[index]._animate(delay);
            }
        }

        public function getViewMatrix(): Matrix {//1225
            return this._viewMatrix;
        }

        public function getProjectionMatrix(): Matrix {
            return this._projectionMatrix;
        }

        public function getTransformMatrix(): Matrix {
            return this._transformMatrix;
        }

        public function setTransformMatrix(view: Matrix, projection: Matrix): void {//1237
            this._viewMatrix = view;
            this._projectionMatrix = projection;

            this._viewMatrix.multiplyToRef(this._projectionMatrix, this._transformMatrix);

            // Update frustum
            if (!this._frustumPlanes) {
                this._frustumPlanes = Frustum.GetPlanes(this._transformMatrix);
            } else {
                Frustum.GetPlanesToRef(this._transformMatrix, this._frustumPlanes);
            }
        }

        public function addMesh(newMesh: AbstractMesh):void {//1253
            newMesh.uniqueId = this._uniqueIdCounter;
            this.meshes.push(newMesh);
        }

        public function removeMesh(toRemove: AbstractMesh): int {
            var index: int = this.meshes.indexOf(toRemove);
            if (index !== -1) {
                // Remove from the scene if mesh found
                this.meshes.splice(index, 1);
            }
            //notify the collision coordinator
//        this.collisionCoordinator.onMeshRemoved(toRemove);
//
//        this.onMeshRemovedObservable.notifyObservers(toRemove);

            return index;
        }

        public function removeSkeleton(toRemove: Skeleton): int {//1355
            var index: int = this.skeletons.indexOf(toRemove);
            if (index !== -1) {
                this.skeletons.splice(index, 1);
            }

            return index;
        }

        public function removeLight(toRemove: Light): int {
            var index: int = this.lights.indexOf(toRemove);
            if (index != -1) {
                // Remove from the scene if mesh found
                this.lights.splice(index, 1);
            }
            return index;
        }

        public function addLight(newLight: Light): void {
            newLight.uniqueId = this._uniqueIdCounter++;
            this.lights.push(newLight);
        }

        public function addCamera(newCamera: Camera):void {//1405
            newCamera.uniqueId = this._uniqueIdCounter++;
            this.cameras.push(newCamera);
        }

        public function getMaterialByID(id: String): Material {//1464
            for (var index: int = 0; index < this.materials.length; index++) {
                if (this.materials[index].id === id) {
                    return this.materials[index];
                }
            }

            return null;
        }

        /**
         * get a light node using its ID
         */
        public function getLightByID(id: String): Light {
            for (var index: int = 0; index < this.lights.length; index++) {
                if (this.lights[index].id === id) {
                    return this.lights[index];
                }
            }

            return null;
        }

        public function getGeometryByID(id: String): Geometry {//1568
            for (var index: int = 0; index < this._geometries.length; index++) {
                if (this._geometries[index].id === id) {
                    return this._geometries[index];
                }
            }

            return null;
        }

        public function pushGeometry(geometry: Geometry, force: Boolean = false): Boolean {//1584
            if (!force && this.getGeometryByID(geometry.id)) {
                return false;
            }

            this._geometries.push(geometry);

            return true;
        }

        public function removeGeometry(geometry: Geometry): Boolean {//1604
            var index: int = this._geometries.indexOf(geometry);

            if (index > -1) {
                this._geometries.splice(index, 1);

                return true;
            }
            return false;
        }

        public function getMeshesByID(id: String): Vector.<AbstractMesh> {
            return this.meshes.filter(function (m: Mesh): Boolean {
                return m.id === id;
            })
        }

        public function getLastMeshByID(id: String): AbstractMesh {
            for (var index: int = this.meshes.length - 1; index >= 0; index--) {
                if (this.meshes[index].id === id) {
                    return this.meshes[index];
                }
            }

            return null;
        }

        /**
         * Get the first added mesh found of a given ID
         */
        public function getMeshByID(id: String): AbstractMesh {
            for (var index: int = 0; index < this.meshes.length; index++) {
                if (this.meshes[index].id === id) {
                    return this.meshes[index];
                }
            }

            return null;
        }

        public function getLastEntryByID(id: String): Node {
            var index: int;
            for (index = this.meshes.length - 1; index >= 0; index--) {
                if (this.meshes[index].id === id) {
                    return this.meshes[index];
                }
            }

            for (index = this.cameras.length - 1; index >= 0; index--) {
                if (this.cameras[index].id === id) {
                    return this.cameras[index];
                }
            }

            for (index = this.lights.length - 1; index >= 0; index--) {
                if (this.lights[index].id === id) {
                    return this.lights[index];
                }
            }

            return null;
        }

        public function getLastSkeletonByID(id: String): Skeleton {//1781
            for (var index: int = this.skeletons.length - 1; index >= 0; index--) {
                if (this.skeletons[index].id === id) {
                    return this.skeletons[index];
                }
            }

            return null;
        }

        private function _evaluateSubMesh(subMesh: SubMesh, mesh: AbstractMesh): void {//1815
            if (mesh.alwaysSelectAsActiveMesh || mesh.subMeshes.length === 1 || subMesh.isInFrustum(this._frustumPlanes)) {
                var material: Material = subMesh.getMaterial();

                if (material) {
                    // Render targets
                    if (material.getRenderTargetTextures) {
                        if (this._processedMaterials.indexOf(material) === -1) {
                            this._processedMaterials.push(material);

                            if (this._renderTargets.indexOf(material.getRenderTargetTextures()) === -1) {
                                this._renderTargets.push(material.getRenderTargetTextures());
                            }
                        }
                    }

                    // Dispatch
                    this._activeIndices.addCount(subMesh.indexCount, false);
                    this._renderingManager.dispatch(subMesh);
                }
            }
        }


        public function _isInIntermediateRendering(): Boolean {//1840
            return this._intermediateRendering;
        }

        private function _evaluateActiveMeshes(): void {//1844
            this.activeCamera._activeMeshes.length = 0;
            this._activeMeshes.length = 0;
            this._renderingManager.reset();
            this._processedMaterials.length = 0;
            this._activeParticleSystems.length = 0;
            this._activeSkeletons.length = 0;
            this._softwareSkinnedMeshes.length = 0;
//            this._boundingBoxRenderer.reset();
//            this._edgesRenderers.length = 0;

            // Meshes
            var meshes: Vector.<AbstractMesh>;
            var len: int;

            // Full scene traversal
            len = this.meshes.length;
            meshes = this.meshes;

            for (var meshIndex: int = 0; meshIndex < len; meshIndex++) {
                var mesh: AbstractMesh = meshes[meshIndex];

                if (mesh.isBlocked) {
                    continue;
                }

                this._totalVertices.addCount(mesh.getTotalVertices(), false);

                if (!mesh.isReady() || !mesh.isEnabled()) {
                    continue;
                }

                mesh.computeWorldMatrix();

                // Switch to current LOD
                var meshLOD: AbstractMesh = mesh.getLOD();

                if (!meshLOD) {
                    continue;
                }

                mesh._preActivate();

                if (mesh.alwaysSelectAsActiveMesh || mesh.isVisible && mesh.visibility > 0 && ((mesh.layerMask & this.activeCamera.layerMask) !== 0) && mesh.isInFrustum(this._frustumPlanes)) {
                    this._activeMeshes.push(mesh);
                    this.activeCamera._activeMeshes.push(mesh);
                    mesh._activate(this._renderId);

                    this._activeMesh(mesh, meshLOD);
                }
            }

            // Particle systems
            this._particlesDuration.beginMonitoring();
            if (this.particlesEnabled) {
                for (var particleIndex: int = 0; particleIndex < this.particleSystems.length; particleIndex++) {
                    var particleSystem: ParticleSystem = this.particleSystems[particleIndex];

                    if (!particleSystem.isStarted()) {
                        continue;
                    }

                    if (!particleSystem.emitter.position || (particleSystem.emitter && particleSystem.emitter.isEnabled())) {
                        this._activeParticleSystems.push(particleSystem);
                        particleSystem.animate();
                    }
                }
            }
            this._particlesDuration.endMonitoring(false);
        }

        private function _activeMesh(sourceMesh: AbstractMesh, mesh: AbstractMesh): void {//1928
            if (mesh.skeleton && this.skeletonsEnabled) {
                if (SmartArray.PushNoDuplicate(this._activeSkeletons, mesh.skeleton)) {
                    mesh.skeleton.prepare();
                }

                if (!mesh.computeBonesUsingShaders) {
                    fail();
                }
            }

            if (sourceMesh.showBoundingBox || this.forceShowBoundingBoxes) {
//                this._boundingBoxRenderer.renderList.push(sourceMesh.getBoundingInfo().boundingBox);
            }

            if (mesh && mesh.subMeshes) {
                var len: Number;
                var subMeshes: Vector.<SubMesh>;

                subMeshes = mesh.subMeshes;
                len = subMeshes.length;

                for (var subIndex: int = 0; subIndex < len; subIndex++) {
                    var subMesh: SubMesh = subMeshes[subIndex];

                    this._evaluateSubMesh(subMesh, mesh);
                }
            }
        }

        public function updateTransformMatrix(force: Boolean = false):void {//1970
            this.setTransformMatrix(this.activeCamera.getViewMatrix(), this.activeCamera.getProjectionMatrix(force));
        }

        private function _renderForCamera(camera: Camera): void {//1974
            var engine: Engine = this._engine;
            this.activeCamera = camera;

            if (!this.activeCamera)
                throw new Error("Active camera not set");

            // Viewport
            engine.setViewport(this.activeCamera.viewport);

            // Camera
            this.resetCachedMaterial();
            this._renderId++;
            this.updateTransformMatrix();

            // Meshes
            this._evaluateActiveMeshesDuration.beginMonitoring();
            this._evaluateActiveMeshes();
            this._evaluateActiveMeshesDuration.endMonitoring(false);

            // Software skinning

            // Render targets
            this._renderTargetsDuration.beginMonitoring();
            var needsRestoreFrameBuffer: Boolean = false;

//            var beforeRenderTargetDate: Number = Tools.Now;
            if (this.renderTargetsEnabled && this._renderTargets.length > 0) {
                this._intermediateRendering = true;
                Tools.StartPerformanceCounter("Render targets", this._renderTargets.length > 0);
                for (var renderIndex: int = 0; renderIndex < this._renderTargets.length; renderIndex++) {
                    var renderTarget: RenderTargetTexture = this._renderTargets[renderIndex];
                    if (renderTarget._shouldRender()) {
                        this._renderId++;
                        var hasSpecialRenderTargetCamera: Boolean = renderTarget.activeCamera && renderTarget.activeCamera !== this.activeCamera;
                        renderTarget.render(hasSpecialRenderTargetCamera, this.dumpNextRenderTargets);
                    }
                }
                Tools.EndPerformanceCounter("Render targets", this._renderTargets.length > 0);

                this._intermediateRendering = false;
                this._renderId++;

                needsRestoreFrameBuffer = true; // Restore back buffer
            }

            // Render HighlightLayer Texture
//            var stencilState = this._engine.getStencilBuffer();
//            var renderhighlights = false;
//            if (this.renderTargetsEnabled && this.highlightLayers && this.highlightLayers.length > 0) {
//                this._intermediateRendering = true;
//                for (let i = 0; i < this.highlightLayers.length; i++) {
//                    let highlightLayer = this.highlightLayers[i];
//
//                    if (highlightLayer.shouldRender() &&
//                            (!highlightLayer.camera ||
//                            (highlightLayer.camera.cameraRigMode === Camera.RIG_MODE_NONE && camera === highlightLayer.camera) ||
//                            (highlightLayer.camera.cameraRigMode !== Camera.RIG_MODE_NONE && highlightLayer.camera._rigCameras.indexOf(camera) > -1))) {
//
//                        renderhighlights = true;
//
//                        renderTarget = ((highlightLayer)._mainTexture);
//                        if (renderTarget._shouldRender()) {
//                            this._renderId++;
//                            renderTarget.render(false, false);
//                            needsRestoreFrameBuffer = true;
//                        }
//                    }
//                }
//
//                this._intermediateRendering = false;
//                this._renderId++;
//            }

            if (needsRestoreFrameBuffer) {
                engine.restoreDefaultFramebuffer(this.clearColor);
            }

            this._renderTargetsDuration.endMonitoring(false);

            // Prepare Frame
            this.postProcessManager._prepareFrame();

            this._renderDuration.beginMonitoring();

            // Backgrounds

            // Render

            // Activate HighlightLayer stencil

            this._renderingManager.render(null, null, true);

            // Restore HighlightLayer stencil

            // Bounding boxes

            // Edges

            // Lens flares

            // Foregrounds

            // Highlight Layer

            this._renderDuration.endMonitoring(false);

            // Finalize frame
            this.postProcessManager._finalizeFrame(camera.isIntermediate);

            // Update camera
            this.activeCamera._updateFromScene();

            // Reset some special arrays
            this._renderTargets.length = 0;
        }

        private function _processSubCameras(camera: Camera): void {//2134
            if (camera.cameraRigMode === Camera.RIG_MODE_NONE) {
                _renderForCamera(camera);
            }
        }

        public function render(): void {//2191
            this._lastFrameDuration.beginMonitoring();
            this._particlesDuration.fetchNewFrame();
//            this._spritesDuration.fetchNewFrame();
            this._activeParticles.fetchNewFrame();
            this._renderDuration.fetchNewFrame();
            this._renderTargetsDuration.fetchNewFrame();
            this._evaluateActiveMeshesDuration.fetchNewFrame();
            this._totalVertices.fetchNewFrame();
            this._activeIndices.fetchNewFrame();
            this._activeBones.fetchNewFrame();
            this.getEngine().drawCallsPerfCounter.fetchNewFrame();
//            this._meshesForIntersections.reset();
            this.resetCachedMaterial();

//            Tools.StartPerformanceCounter("Scene rendering");

            // Actions

            // Simplification Queue

            // Animations
            var deltaTime: Number = Math.max(MinDeltaTime, Math.min(this._engine.getDeltaTime(), MaxDeltaTime));
            this._animationRatio = deltaTime * (60.0 / 1000.0);
            this._animate();

            // Physics

            // Before render
            this.onBeforeRenderObservable.notifyObservers(this);

            // Customs render targets

            if (this.renderTargetsEnabled) {

                this._renderId++;
            }

            // Procedural textures

            // Clear
            _engine.clear(clearColor, autoClear || forceWireframe || forcePointsCloud, true, true);

            // Shadows
            if (this.shadowsEnabled) {
                for (var lightIndex: int = 0; lightIndex < this.lights.length; lightIndex++) {
                    var light: Light = this.lights[lightIndex];
                    var shadowGenerator: IShadowGenerator = light.getShadowGenerator();

                    if (light.isEnabled() && shadowGenerator && shadowGenerator.getShadowMap().getScene().textures.indexOf(shadowGenerator.getShadowMap()) !== -1) {
                        this._renderTargets.push(shadowGenerator.getShadowMap());
                    }
                }
            }

            // Depth renderer
//            if (this._depthRenderer) {
//                this._renderTargets.push(this._depthRenderer.getDepthMap());
//            }

            // RenderPipeline

            // Multi-cameras?
            _processSubCameras(activeCamera);

            // Intersection checks

            // Update the audio listener attached to the camera

            // After render
            this.onAfterRenderObservable.notifyObservers(this);


            // Cleaning

            if (this.dumpNextRenderTargets) {
                this.dumpNextRenderTargets = false;
            }

//            Tools.EndPerformanceCounter("Scene rendering");
            this._lastFrameDuration.endMonitoring();
//            this._totalMeshesCounter.addCount(this.meshes.length, true);
            this._totalLightsCounter.addCount(this.lights.length, true);
//            this._totalMaterialsCounter.addCount(this.materials.length, true);
//            this._totalTexturesCounter.addCount(this.textures.length, true);
            this._activeBones.addCount(0, true);
            this._activeIndices.addCount(0, true);
            this._activeParticles.addCount(0, true);
        }

        public function dispose(): void {
            this.beforeRender = null;
            this.afterRender = null;

            this.skeletons.length = 0;

//            this._boundingBoxRenderer.dispose();
//
//            if (this._depthRenderer) {
//                this._depthRenderer.dispose();
//            }

            // Debug layer
            if (this._debugLayer) {
                this._debugLayer.hide();
            }

            // Events
//            this.onDisposeObservable.notifyObservers(this);

//            this.onDisposeObservable.clear();
            this.onBeforeRenderObservable.clear();
            this.onAfterRenderObservable.clear();

            // Release lights
            while (this.lights.length) {
                this.lights[0].dispose();
            }

            // Post-processes
            this.postProcessManager.dispose();
        }
    }
}
