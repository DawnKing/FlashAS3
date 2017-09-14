/**
 * Created by caijingxiao on 2016/11/10.
 */
package babylon.materials {
    import babylon.Scene;
    import babylon.mesh.AbstractMesh;

    public class MultiMaterial extends Material {
        public var subMaterials: Vector.<Material> = new <Material>[];

        public function MultiMaterial(name: String, scene: Scene) {
            super(name, scene, true);

            scene.multiMaterials.push(this);
        }

        // Properties
        public function getSubMaterial(index: int): Material {
            if (index < 0 || index >= this.subMaterials.length) {
                return this.getScene().defaultMaterial;
            }

            return this.subMaterials[index];
        }

        // Methods
        override public function isReady(mesh: AbstractMesh = null, useInstances: Boolean = false): Boolean {
            for (var index: int = 0; index < this.subMaterials.length; index++) {
                var subMaterial: Material = this.subMaterials[index];
                if (subMaterial) {
                    if (!this.subMaterials[index].isReady(mesh)) {
                        return false;
                    }
                }
            }

            return true;
        }
    }
}
