/**
 * Created by caijingxiao on 2016/12/20.
 */
package babylon.lights {
    import babylon.Node;
    import babylon.Scene;
    import babylon.lights.shadows.IShadowGenerator;
    import babylon.materials.Effect;
    import babylon.math.Color3;
    import babylon.math.Matrix;
    import babylon.math.Vector3;
    import babylon.mesh.AbstractMesh;

    public class Light extends Node {
        //lightmapMode Consts
        public static const LIGHTMAP_DEFAULT: int = 0;
        public static const LIGHTMAP_SPECULAR: int = 1;
        public static const LIGHTMAP_SHADOWSONLY: int = 2;

        [Serialize(type="color3")]
        public var diffuse: Color3 = new Color3(1.0, 1.0, 1.0);

        [Serialize(type="color3")]
        public var specular: Color3 = new Color3(1.0, 1.0, 1.0);

        [Serialize]
        public var intensity: Number = 1.0;

        [Serialize]
        public var range: Number = Number.MAX_VALUE;

        [Serialize]
        public var includeOnlyWithLayerMask: Number = 0;

        public var includedOnlyMeshes: Vector.<AbstractMesh> = new <AbstractMesh>[];
        public var excludedMeshes: Vector.<AbstractMesh> = new <AbstractMesh>[];

        [Serialize]
        public var excludeWithLayerMask: Number = 0;

        [Serialize]
        public var lightmapMode: int = 0;

        // PBR Properties.
        [Serialize]
        public var radius: Number = 0.00001;

        public var _shadowGenerator: IShadowGenerator;
        private var _parentedWorldMatrix: Matrix;
        public var _excludedMeshesIds: Vector.<String> = new <String>[];
        public var _includedOnlyMeshesIds: Vector.<String> = new <String>[];

        public function Light(name: String, scene: Scene) {
            super(name, scene);

            scene.addLight(this);
        }

        public function getClassName(): String {
            return "Light";
        }

        /**
         * @param {Boolean} fullDetails - support for multiple levels of logging within scene loading
         */
        public function toString(fullDetails : Boolean = false) : String {
            var ret: String = "Name: " + this.name;
            ret += ", type: " + (["Point", "Directional", "Spot", "Hemispheric"])[this.getTypeID()];
            if (this.animations){
                for (var i: int = 0; i < this.animations.length; i++){
                    ret += ", animation[0]: " + this.animations[i].toString(fullDetails);
                }
            }
            if (fullDetails){
            }
            return ret;
        }

        public function getShadowGenerator(): IShadowGenerator {
            return this._shadowGenerator;
        }

        public function getAbsolutePosition(): Vector3 {
            return Vector3.Zero();
        }

        public function transferToEffect(effect: Effect, uniformName0: String = null, uniformName1: String = null): void {
        }

        public function _getWorldMatrix(): Matrix {
            return Matrix.Identity();
        }

        public function canAffectMesh(mesh: AbstractMesh): Boolean {
            if (!mesh) {
                return true;
            }

            if (this.includedOnlyMeshes.length > 0 && this.includedOnlyMeshes.indexOf(mesh) === -1) {
                return false;
            }

            if (this.excludedMeshes.length > 0 && this.excludedMeshes.indexOf(mesh) !== -1) {
                return false;
            }

            if (this.includeOnlyWithLayerMask !== 0 && (this.includeOnlyWithLayerMask & mesh.layerMask) === 0) {
                return false;
            }

            if (this.excludeWithLayerMask !== 0 && this.excludeWithLayerMask & mesh.layerMask) {
                return false;
            }

            return true;
        }

        override public function getWorldMatrix(): Matrix {
            this._currentRenderId = this.getScene().getRenderId();

            var worldMatrix: Matrix = this._getWorldMatrix();

            if (this.parent && this.parent.getWorldMatrix) {
                if (!this._parentedWorldMatrix) {
                    this._parentedWorldMatrix = Matrix.Identity();
                }

                worldMatrix.multiplyToRef(this.parent.getWorldMatrix(), this._parentedWorldMatrix);

                this._markSyncedWithParent();

                return this._parentedWorldMatrix;
            }

            return worldMatrix;
        }

        override public function dispose(doNotRecurse: Boolean = false): void {
            if (this._shadowGenerator) {
                this._shadowGenerator.dispose();
                this._shadowGenerator = null;
            }

            // Animations
            this.getScene().stopAnimation(this);

            // Remove from scene
            this.getScene().removeLight(this);

            super.dispose(doNotRecurse);
        }

        public function getTypeID(): Number {
            return 0;
        }

//        public function clone(name: String): Light {
//            return SerializationHelper.Clone(Light.GetConstructorFromName(this.getTypeID(), name, this.getScene()), this);
//        }
//
//        public function serialize(): Object {
//            var serializationObject: Object = SerializationHelper.Serialize(this);
//
//            // Type
//            serializationObject.type = this.getTypeID();
//
//            // Parent
//            if (this.parent) {
//                serializationObject.parentId = this.parent.id;
//            }
//
//            // Inclusion / exclusions
//            if (this.excludedMeshes.length > 0) {
//                serializationObject.excludedMeshesIds = [];
//                this.excludedMeshes.forEach((mesh: AbstractMesh) => {
//                    serializationObject.excludedMeshesIds.push(mesh.id);
//                });
//            }
//
//            if (this.includedOnlyMeshes.length > 0) {
//                serializationObject.includedOnlyMeshesIds = [];
//                this.includedOnlyMeshes.forEach((mesh: AbstractMesh) => {
//                    serializationObject.includedOnlyMeshesIds.push(mesh.id);
//                });
//            }
//
//            // Animations
//            Animation.AppendSerializedAnimations(this, serializationObject);
//            serializationObject.ranges = this.serializeAnimationRanges();
//
//            return serializationObject;
//        }
//
//        private static function GetConstructorFromName(type: Number, name: String, scene: Scene): () => Light {
//            switch (type) {
//                case 0:
//                    return () => new PointLight(name, Vector3.Zero(), scene);
//                case 1:
//                    return () => new DirectionalLight(name, Vector3.Zero(), scene);
//                case 2:
//                    return () => new SpotLight(name, Vector3.Zero(), Vector3.Zero(), 0, 0, scene);
//                case 3:
//                    return () => new HemisphericLight(name, Vector3.Zero(), scene);
//            }
//        }
//
//        public static function Parse(parsedLight: Object, scene: Scene): Light {
//            var light = SerializationHelper.Parse(Light.GetConstructorFromName(parsedLight.type, parsedLight.name, scene), parsedLight, scene);
//
//            // Inclusion / exclusions
//            if (parsedLight.excludedMeshesIds) {
//                light._excludedMeshesIds = parsedLight.excludedMeshesIds;
//            }
//
//            if (parsedLight.includedOnlyMeshesIds) {
//                light._includedOnlyMeshesIds = parsedLight.includedOnlyMeshesIds;
//            }
//
//            // Parent
//            if (parsedLight.parentId) {
//                light._waitingParentId = parsedLight.parentId;
//            }
//
//            // Animations
//            if (parsedLight.animations) {
//                for (var animationIndex = 0; animationIndex < parsedLight.animations.length; animationIndex++) {
//                    var parsedAnimation = parsedLight.animations[animationIndex];
//
//                    light.animations.push(Animation.Parse(parsedAnimation));
//                }
//                Node.ParseAnimationRanges(light, parsedLight, scene);
//            }
//
//            if (parsedLight.autoAnimate) {
//                scene.beginAnimation(light, parsedLight.autoAnimateFrom, parsedLight.autoAnimateTo, parsedLight.autoAnimateLoop, parsedLight.autoAnimateSpeed || 1.0);
//            }
//
//            return light;
//        }
    }
}
