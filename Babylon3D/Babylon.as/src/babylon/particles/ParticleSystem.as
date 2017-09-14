/**
 * Created by caijingxiao on 2016/11/22.
 */
package babylon.particles {
    import babylon.Engine;
    import babylon.zip.scene.IDisposable;
    import babylon.Scene;
    import babylon.animations.Animation;
    import babylon.animations.IAnimatable;
    import babylon.materials.Effect;
    import babylon.materials.textures.Texture;
    import babylon.math.Color4;
    import babylon.math.Matrix;
    import babylon.math.Plane;
    import babylon.math.Vector3;
    import babylon.mesh.Buffer;
    import babylon.mesh.VertexBuffer;

    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.utils.Dictionary;

    public class ParticleSystem implements IDisposable, IAnimatable {

        // Statics
        public static const BLENDMODE_ONEONE: int = 0;
        public static const BLENDMODE_STANDARD: int = 1;

        // Members
        public var name: String;

        private var _animations: Vector.<Animation> = new <Animation>[];

        public var id: String;
        public var renderingGroupId: int = 0;
        public var emitter: Object = null;
        public var emitRate: Number = 10;
        public var manualEmitCount: int = -1;
        public var updateSpeed: Number = 0.01;
        public var targetStopDuration: Number = 0;
        public var disposeOnStop: Boolean = false;

        public var minEmitPower: Number = 1;
        public var maxEmitPower: Number = 1;

        public var minLifeTime: Number = 1;
        public var maxLifeTime: Number = 1;

        public var minSize: Number = 1;
        public var maxSize: Number = 1;
        public var minAngularSpeed: Number = 0;
        public var maxAngularSpeed: Number = 0;

        public var particleTexture: Texture;

        public var layerMask: Number = 0x0FFFFFFF;

        /**
         * An event triggered when the system is disposed.
         */
//    public var onDisposeObservable = new Observable<ParticleSystem>();
//
//    private var _onDisposeObserver: Observer<ParticleSystem>;
//    public function set onDispose(callback: () => void) {
//        if (this._onDisposeObserver) {
//            this.onDisposeObservable.remove(this._onDisposeObserver);
//        }
//        this._onDisposeObserver = this.onDisposeObservable.add(callback);
//    }

        public var updateFunction: Function;    // (particles: Particle[]) => void;

        public var blendMode: int = ParticleSystem.BLENDMODE_ONEONE;

        public var forceDepthWrite: Boolean = false;

        public var gravity: Vector3 = Vector3.Zero();
        public var direction1: Vector3 = new Vector3(0, 1.0, 0);
        public var direction2: Vector3 = new Vector3(0, 1.0, 0);
        public var minEmitBox: Vector3 = new Vector3(-0.5, -0.5, -0.5);
        public var maxEmitBox: Vector3 = new Vector3(0.5, 0.5, 0.5);
        public var color1: Color4 = new Color4(1.0, 1.0, 1.0, 1.0);
        public var color2: Color4 = new Color4(1.0, 1.0, 1.0, 1.0);
        public var colorDead: Color4 = new Color4(0, 0, 0, 1.0);
        public var textureMask: Color4 = new Color4(1.0, 1.0, 1.0, 1.0);
        public var startDirectionFunction: Function;    // (emitPower: Number, worldMatrix: Matrix, directionToUpdate: Vector3, particle: Particle) => void;
        public var startPositionFunction: Function; // (worldMatrix: Matrix, positionToUpdate: Vector3, particle: Particle) => void;

        private var particles: Vector.<Particle> = new <Particle>[];

        private var _capacity: Number;
        private var _scene: Scene;
        private var _stockParticles: Vector.<Particle> = new <Particle>[];
        private var _newPartsExcess: Number = 0;
        private var _vertexData: Vector.<Number>;
        private var _vertexBuffer: Buffer;
        private var _vertexBuffers: Dictionary = new Dictionary(true);  // { [key: String]: VertexBuffer } = {};
        private var _indexBuffer: IndexBuffer3D;
        private var _effect: Effect;
        private var _customEffect: Effect;
        private var _cachedDefines: String;

        private var _scaledColorStep: Color4 = new Color4(0, 0, 0, 0);
        private var _colorDiff: Color4 = new Color4(0, 0, 0, 0);
        private var _scaledDirection: Vector3 = Vector3.Zero();
        private var _scaledGravity: Vector3 = Vector3.Zero();
        private var _currentRenderId: int = -1;

        private var _alive: Boolean;
        private var _started: Boolean = false;
        private var _stopped: Boolean = false;
        private var _actualFrame: int = 0;
        private var _scaledUpdateSpeed: Number;

        public function ParticleSystem(name: String, capacity: Number, scene: Scene, customEffect: Effect = null) {
            this.name = name;
            this.id = name;
            this._capacity = capacity;

            this._scene = scene;

            this._customEffect = customEffect;

            scene.particleSystems.push(this);

            var indices: Vector.<uint> = new <uint>[];
            var index: int = 0;
            for (var count: int = 0; count < capacity; count++) {
                indices.push(index);
                indices.push(index + 1);
                indices.push(index + 2);
                indices.push(index);
                indices.push(index + 2);
                indices.push(index + 3);
                index += 4;
            }

            this._indexBuffer = scene.getEngine().createIndexBuffer(indices);

            // 11 floats per particle (x, y, z, r, g, b, a, angle, size, offsetX, offsetY) + 1 filler
            this._vertexData = new Vector.<Number>(capacity * 11 * 4, true);
            this._vertexBuffer = new Buffer(scene.getEngine(), this._vertexData, true, 11);

            var positions: VertexBuffer = this._vertexBuffer.createVertexBuffer(VertexBuffer.PositionKind, 0, Context3DVertexBufferFormat.FLOAT_3);
            var colors: VertexBuffer = this._vertexBuffer.createVertexBuffer(VertexBuffer.ColorKind, 3, Context3DVertexBufferFormat.FLOAT_4);
            var options: VertexBuffer = this._vertexBuffer.createVertexBuffer("options", 7, Context3DVertexBufferFormat.FLOAT_4);

            this._vertexBuffers[VertexBuffer.PositionKind] = positions;
            this._vertexBuffers[VertexBuffer.ColorKind] = colors;
            this._vertexBuffers["options"] = options;

            // Default behaviors
            this.startDirectionFunction = function(emitPower: Number, worldMatrix: Matrix, directionToUpdate: Vector3, particle: Particle): void {
                var randX: Number = randomNumber(direction1.x, direction2.x);
                var randY: Number = randomNumber(direction1.y, direction2.y);
                var randZ: Number = randomNumber(direction1.z, direction2.z);

                Vector3.TransformNormalFromFloatsToRef(randX * emitPower, randY * emitPower, randZ * emitPower, worldMatrix, directionToUpdate);
            };

            this.startPositionFunction = function(worldMatrix: Matrix, positionToUpdate: Vector3, particle: Particle): void {
                var randX: Number = randomNumber(minEmitBox.x, maxEmitBox.x);
                var randY: Number = randomNumber(minEmitBox.y, maxEmitBox.y);
                var randZ: Number = randomNumber(minEmitBox.z, maxEmitBox.z);

                Vector3.TransformCoordinatesFromFloatsToRef(randX, randY, randZ, worldMatrix, positionToUpdate);
            };

            this.updateFunction = function(particles: Vector.<Particle>): void {
                for (var index: int = 0; index < particles.length; index++) {
                    var particle: Particle = particles[index];
                    particle.age += _scaledUpdateSpeed;

                    if (particle.age >= particle.lifeTime) { // Recycle by swapping with last particle
                        recycleParticle(particle);
                        index--;
                    }
                    else {
                        particle.colorStep.scaleToRef(_scaledUpdateSpeed, _scaledColorStep);
                        particle.color.addInPlace(_scaledColorStep);

                        if (particle.color.a < 0)
                            particle.color.a = 0;

                        particle.angle += particle.angularSpeed * this._scaledUpdateSpeed;

                        particle.direction.scaleToRef(_scaledUpdateSpeed, _scaledDirection);
                        particle.position.addInPlace(_scaledDirection);

                        gravity.scaleToRef(_scaledUpdateSpeed, _scaledGravity);
                        particle.direction.addInPlace(_scaledGravity);
                    }
                }
            }
        }

        public function recycleParticle(particle: Particle): void {
            var lastParticle: Particle = this.particles.pop();

            if (lastParticle !== particle) {
                lastParticle.copyTo(particle);
                this._stockParticles.push(lastParticle);
            }
        }

        public function getCapacity(): Number {
            return this._capacity;
        }

        public function isAlive(): Boolean {
            return this._alive;
        }

        public function isStarted(): Boolean {
            return this._started;
        }

        public function start(): void {
            this._started = true;
            this._stopped = false;
            this._actualFrame = 0;
        }

        public function stop(): void {
            this._stopped = true;
        }

        public function _appendParticleVertex(index: Number, particle: Particle, offsetX: Number, offsetY: Number): void {
            var offset: int = index * 11;
            this._vertexData[offset] = particle.position.x;
            this._vertexData[offset + 1] = particle.position.y;
            this._vertexData[offset + 2] = particle.position.z;
            this._vertexData[offset + 3] = particle.color.r;
            this._vertexData[offset + 4] = particle.color.g;
            this._vertexData[offset + 5] = particle.color.b;
            this._vertexData[offset + 6] = particle.color.a;
            this._vertexData[offset + 7] = particle.angle;
            this._vertexData[offset + 8] = particle.size;
            this._vertexData[offset + 9] = offsetX;
            this._vertexData[offset + 10] = offsetY;
        }

        private function _update(newParticles: int): void {
            // Update current
            this._alive = this.particles.length > 0;

            this.updateFunction(this.particles);

            // Add new ones
            var worldMatrix: Matrix;

            if (this.emitter.position) {
                worldMatrix = this.emitter.getWorldMatrix();
            } else {
                worldMatrix = Matrix.Translation(this.emitter.x, this.emitter.y, this.emitter.z);
            }
            var particle: Particle;
            for (var index: int = 0; index < newParticles; index++) {
                if (this.particles.length === this._capacity) {
                    break;
                }

                if (this._stockParticles.length !== 0) {
                    particle = this._stockParticles.pop();
                    particle.age = 0;
                } else {
                    particle = new Particle();
                }
                this.particles.push(particle);

                var emitPower: Number = randomNumber(this.minEmitPower, this.maxEmitPower);

                this.startDirectionFunction(emitPower, worldMatrix, particle.direction, particle);

                particle.lifeTime = randomNumber(this.minLifeTime, this.maxLifeTime);

                particle.size = randomNumber(this.minSize, this.maxSize);
                particle.angularSpeed = randomNumber(this.minAngularSpeed, this.maxAngularSpeed);

                this.startPositionFunction(worldMatrix, particle.position, particle);

                var step: Number = randomNumber(0, 1.0);

                Color4.LerpToRef(this.color1, this.color2, step, particle.color);

                this.colorDead.subtractToRef(particle.color, this._colorDiff);
                this._colorDiff.scaleToRef(1.0 / particle.lifeTime, particle.colorStep);
            }
        }

        private function _getEffect(): Effect {
            if (this._customEffect) {
                return this._customEffect;
            }

            var defines: Object = [];

            if (this._scene.clipPlane) {
                defines.push("#define CLIPPLANE");
            }

            // Effect
            var join: String = defines.join("\n");
            if (this._cachedDefines !== join) {
                this._cachedDefines = join;

                this._effect = this._scene.getEngine().createEffect(
                        "particles",
                        new <String>[VertexBuffer.PositionKind, VertexBuffer.ColorKind, "options"],
                        new <String>["invView", "view", "projection", "vClipPlane", "textureMask", "vertexConst0", "vertexConst05", "fragmentConst1"],
                        new <String>["diffuseSampler"], join);
            }

            return this._effect;
        }

        public function animate(): void {
            if (!this._started)
                return;

            var effect: Effect = this._getEffect();

            // Check
            if (!this.emitter || !effect.isReady() || !this.particleTexture || !this.particleTexture.isReady())
                return;

            if (this._currentRenderId === this._scene.getRenderId()) {
                return;
            }

            this._currentRenderId = this._scene.getRenderId();

            this._scaledUpdateSpeed = this.updateSpeed * this._scene.getAnimationRatio();

            // determine the Number of particles we need to create
            var newParticles : int;

            if (this.manualEmitCount > -1) {
                newParticles = this.manualEmitCount;
                this._newPartsExcess = 0;
                this.manualEmitCount = 0;
            } else {
                newParticles = ((this.emitRate * this._scaledUpdateSpeed) >> 0);
                this._newPartsExcess += this.emitRate * this._scaledUpdateSpeed - newParticles;
            }

            if (this._newPartsExcess > 1.0) {
                newParticles += this._newPartsExcess >> 0;
                this._newPartsExcess -= this._newPartsExcess >> 0;
            }

            this._alive = false;

            if (!this._stopped) {
                this._actualFrame += this._scaledUpdateSpeed;

                if (this.targetStopDuration && this._actualFrame >= this.targetStopDuration)
                    this.stop();
            } else {
                newParticles = 0;
            }

            this._update(newParticles);

            // Stopped?
            if (this._stopped) {
                if (!this._alive) {
                    this._started = false;
                    if (this.disposeOnStop) {
                        this._scene._toBeDisposed.push(this);
                    }
                }
            }

            // Update VBO
            var offset: int = 0;
            for (var index: int = 0; index < this.particles.length; index++) {
                var particle: Particle = this.particles[index];

                this._appendParticleVertex(offset++, particle, 0, 0);
                this._appendParticleVertex(offset++, particle, 1, 0);
                this._appendParticleVertex(offset++, particle, 1, 1);
                this._appendParticleVertex(offset++, particle, 0, 1);
            }

            this._vertexBuffer.update(this._vertexData);
        }

        public function render(): uint {
            var effect: Effect = this._getEffect();

            // Check
            if (!this.emitter || !effect.isReady() || !this.particleTexture || !this.particleTexture.isReady() || !this.particles.length)
                return 0;

            var engine: Engine = this._scene.getEngine();

            // Render
            engine.enableEffect(effect);
            engine.setState(false);

            var viewMatrix: Matrix = this._scene.getViewMatrix();
            effect.setTexture("diffuseSampler", this.particleTexture);
            effect.setMatrix("view", viewMatrix, true);
            effect.setMatrix("projection", this._scene.getProjectionMatrix(), true);
            effect.setFloat4("textureMask", this.textureMask.r, this.textureMask.g, this.textureMask.b, this.textureMask.a);

            effect.setFloat("vertexConst0", 0);
            effect.setFloat("vertexConst05", 0.5);
            effect.setFloat("fragmentConst1", 1);

            if (this._scene.clipPlane) {
                var clipPlane: Plane = this._scene.clipPlane;
                var invView: Matrix = viewMatrix.clone();
                invView.invert();
                effect.setMatrix("invView", invView, true);
                effect.setFloat4("vClipPlane", clipPlane.normal.x, clipPlane.normal.y, clipPlane.normal.z, clipPlane.d);
            }

            // VBOs
            engine.bindBuffers(this._vertexBuffers, this._indexBuffer, effect);

            // Draw order
            if (this.blendMode === ParticleSystem.BLENDMODE_ONEONE) {
                engine.setAlphaMode(Engine.ALPHA_ONEONE);
            } else {
                engine.setAlphaMode(Engine.ALPHA_COMBINE);
            }

            if (this.forceDepthWrite) {
                engine.setDepthWrite(true);
            }

            engine.draw(this._indexBuffer, 0, this.particles.length * 2);
            engine.setAlphaMode(Engine.ALPHA_DISABLE);

            return this.particles.length;
        }

        public function dispose(): void {
            if (this._vertexBuffer) {
                this._vertexBuffer.dispose();
                this._vertexBuffer = null;
            }

            if (this._indexBuffer) {
                this._scene.getEngine()._releaseBuffer(this._indexBuffer);
                this._indexBuffer = null;
            }

            if (this.particleTexture) {
                this.particleTexture.dispose();
                this.particleTexture = null;
            }

            // Remove from scene
            var index: int = this._scene.particleSystems.indexOf(this);
            this._scene.particleSystems.splice(index, 1);

            // Callback
            //this.onDisposeObservable.notifyObservers(this);
            //this.onDisposeObservable.clear();
        }

        // Clone
        public function clone(name: String, newEmitter: Object): ParticleSystem {
            var result: ParticleSystem = new ParticleSystem(name, this._capacity, this._scene);

            //    Tools.DeepCopy(this, result, ["particles"]);

            if (newEmitter == null) {
                newEmitter = this.emitter;
            }

            result.emitter = newEmitter;
            if (this.particleTexture) {
                result.particleTexture = new Texture(this.particleTexture.url, this._scene);
            }

            result.start();

            return result;
        }

        public function serialize(): Object {
            var serializationObject: Object = {};

            serializationObject.name = this.name;
            serializationObject.id = this.id;

            // Emitter
            if (this.emitter.position) {
                serializationObject.emitterId = this.emitter.id;
            } else {
                serializationObject.emitter = this.emitter.asArray();
            }

            serializationObject.capacity = this.getCapacity();

            if (this.particleTexture) {
                serializationObject.textureName = this.particleTexture.name;
            }

            // Animations
            Animation.AppendSerializedAnimations(this, serializationObject);

            // Particle system
            serializationObject.minAngularSpeed = this.minAngularSpeed;
            serializationObject.maxAngularSpeed = this.maxAngularSpeed;
            serializationObject.minSize = this.minSize;
            serializationObject.maxSize = this.maxSize;
            serializationObject.minEmitPower = this.minEmitPower;
            serializationObject.maxEmitPower = this.maxEmitPower;
            serializationObject.minLifeTime = this.minLifeTime;
            serializationObject.maxLifeTime = this.maxLifeTime;
            serializationObject.emitRate = this.emitRate;
            serializationObject.minEmitBox = this.minEmitBox.asArray();
            serializationObject.maxEmitBox = this.maxEmitBox.asArray();
            serializationObject.gravity = this.gravity.asArray();
            serializationObject.direction1 = this.direction1.asArray();
            serializationObject.direction2 = this.direction2.asArray();
            serializationObject.color1 = this.color1.asArray();
            serializationObject.color2 = this.color2.asArray();
            serializationObject.colorDead = this.colorDead.asArray();
            serializationObject.updateSpeed = this.updateSpeed;
            serializationObject.targetStopDuration = this.targetStopDuration;
            serializationObject.textureMask = this.textureMask.asArray();
            serializationObject.blendMode = this.blendMode;

            return serializationObject;
        }

        public static function Parse(parsedParticleSystem: Object, scene: Scene, rootUrl: String): ParticleSystem {
            var name: String = parsedParticleSystem.name;
            var particleSystem: ParticleSystem = new ParticleSystem(name, parsedParticleSystem.capacity, scene);

            if (parsedParticleSystem.id) {
                particleSystem.id = parsedParticleSystem.id;
            }

            // Texture
            if (parsedParticleSystem.textureName) {
                particleSystem.particleTexture = new Texture(rootUrl + parsedParticleSystem.textureName, scene);
                particleSystem.particleTexture.name = parsedParticleSystem.textureName;
            }

            // Emitter
            if (parsedParticleSystem.emitterId) {
                particleSystem.emitter = scene.getLastMeshByID(parsedParticleSystem.emitterId);
            } else {
                particleSystem.emitter = Vector3.FromArray(parsedParticleSystem.emitter);
            }

            // Animations
            if (parsedParticleSystem.animations) {
                for (var animationIndex: int = 0; animationIndex < parsedParticleSystem.animations.length; animationIndex++) {
                    var parsedAnimation: Object = parsedParticleSystem.animations[animationIndex];
                    particleSystem._animations.push(Animation.Parse(parsedAnimation));
                }
            }

            if (parsedParticleSystem.autoAnimate) {
                scene.beginAnimation(particleSystem, parsedParticleSystem.autoAnimateFrom, parsedParticleSystem.autoAnimateTo, parsedParticleSystem.autoAnimateLoop, parsedParticleSystem.autoAnimateSpeed || 1.0);
            }

            // Particle system
            particleSystem.minAngularSpeed = parsedParticleSystem.minAngularSpeed;
            particleSystem.maxAngularSpeed = parsedParticleSystem.maxAngularSpeed;
            particleSystem.minSize = parsedParticleSystem.minSize;
            particleSystem.maxSize = parsedParticleSystem.maxSize;
            particleSystem.minLifeTime = parsedParticleSystem.minLifeTime;
            particleSystem.maxLifeTime = parsedParticleSystem.maxLifeTime;
            particleSystem.minEmitPower = parsedParticleSystem.minEmitPower;
            particleSystem.maxEmitPower = parsedParticleSystem.maxEmitPower;
            particleSystem.emitRate = parsedParticleSystem.emitRate;
            particleSystem.minEmitBox = Vector3.FromArray(parsedParticleSystem.minEmitBox);
            particleSystem.maxEmitBox = Vector3.FromArray(parsedParticleSystem.maxEmitBox);
            particleSystem.gravity = Vector3.FromArray(parsedParticleSystem.gravity);
            particleSystem.direction1 = Vector3.FromArray(parsedParticleSystem.direction1);
            particleSystem.direction2 = Vector3.FromArray(parsedParticleSystem.direction2);
            particleSystem.color1 = Color4.FromArray(parsedParticleSystem.color1);
            particleSystem.color2 = Color4.FromArray(parsedParticleSystem.color2);
            particleSystem.colorDead = Color4.FromArray(parsedParticleSystem.colorDead);
            particleSystem.updateSpeed = parsedParticleSystem.updateSpeed;
            particleSystem.targetStopDuration = parsedParticleSystem.targetStopDuration;
            particleSystem.textureMask = Color4.FromArray(parsedParticleSystem.textureMask);
            particleSystem.blendMode = parsedParticleSystem.blendMode;

            if (!parsedParticleSystem.preventAutoStart) {
                particleSystem.start();
            }

            return particleSystem;
        }

        public function get animations(): Vector.<Animation> {
            return _animations;
        }
    }
}

function randomNumber(min: Number, max: Number): Number {
    if (min === max) {
        return (min);
    }

    var random: Number = Math.random();

    return ((random * (max - min)) + min);
}