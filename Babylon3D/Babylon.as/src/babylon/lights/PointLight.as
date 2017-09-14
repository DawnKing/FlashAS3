/**
 * Created by caijingxiao on 2016/12/27.
 */
package babylon.lights {
    import babylon.Scene;
    import babylon.cameras.Camera;
    import babylon.materials.Effect;
    import babylon.math.Matrix;
    import babylon.math.Vector3;
    import babylon.mesh.AbstractMesh;

    public class PointLight extends Light implements IShadowLight{

        private var _worldMatrix: Matrix;
        private var _transformedPosition: Vector3;

        [Serialize(type="vector3")]
        private var _position: Vector3;

        public function PointLight(name: String, position: Vector3, scene: Scene) {
            super(name, scene);

            this._position = position;
        }

        override public function getClassName(): String {
            return "PointLight";
        }

        override public function getAbsolutePosition(): Vector3 {
            return this.transformedPosition ? this.transformedPosition : this.position;
        }

        public function computeTransformedPosition(): Boolean {
            if (this.parent && this.parent.getWorldMatrix) {
                if (!this.transformedPosition) {
                    this._transformedPosition = Vector3.Zero();
                }

                Vector3.TransformCoordinatesToRef(this.position, this.parent.getWorldMatrix(), this.transformedPosition);

                return true;
            }

            return false;
        }

        override public function transferToEffect(effect: Effect, positionUniformName: String = null, uniformName1: String = null): void {
            if (this.parent && this.parent.getWorldMatrix) {
                this.computeTransformedPosition();

                effect.setFloat4(positionUniformName,
                        this.transformedPosition.x,
                        this.transformedPosition.y,
                        this.transformedPosition.z,
                        0);

                return;
            }

            effect.setFloat4(positionUniformName, this.position.x, this.position.y, this.position.z, 0);
        }

        public function needCube(): Boolean {
            return true;
        }

        public function supportsVSM(): Boolean {
            return false;
        }

        public function needRefreshPerFrame(): Boolean {
            return false;
        }

        public function getShadowDirection(faceIndex: int = -1): Vector3 {
            switch (faceIndex) {
                case 0:
                    return new Vector3(1, 0, 0);
                case 1:
                    return new Vector3(-1, 0, 0);
                case 2:
                    return new Vector3(0, -1, 0);
                case 3:
                    return new Vector3(0, 1, 0);
                case 4:
                    return new Vector3(0, 0, 1);
                case 5:
                    return new Vector3(0, 0, -1);
            }

            return Vector3.Zero();
        }

        public function setShadowProjectionMatrix(matrix: Matrix, viewMatrix: Matrix, renderList: Vector.<AbstractMesh>): void {
            var activeCamera: Camera = this.getScene().activeCamera;
            Matrix.PerspectiveFovLHToRef(Math.PI / 2, 1.0, activeCamera.minZ, activeCamera.maxZ, matrix);
        }

        override public function _getWorldMatrix(): Matrix {
            if (!this._worldMatrix) {
                this._worldMatrix = Matrix.Identity();
            }

            Matrix.TranslationToRef(this.position.x, this.position.y, this.position.z, this._worldMatrix);

            return this._worldMatrix;
        }

        override public function getTypeID(): Number {
            return 0;
        }

        public function get position(): Vector3 {
            return this._position;
        }

        public function get transformedPosition(): Vector3 {
            return this._transformedPosition;
        }
    }
}
