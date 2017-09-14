/**
 * Created by caijingxiao on 2017/1/11.
 */
package babylon.lights {
    import babylon.Scene;
    import babylon.lights.shadows.IShadowGenerator;
    import babylon.math.Matrix;
    import babylon.math.Vector3;
    import babylon.mesh.AbstractMesh;

    public interface IShadowLight {
//        function set id(value: String): void;
//        function get id(): String;
//        function set position(value: Vector3): void;
        function get position(): Vector3;
//        function set transformedPosition(value: Vector3): void;
        function get transformedPosition(): Vector3;
//        function set name(value: String): void;
//        function get name(): String;

        function computeTransformedPosition(): Boolean;
        function getScene(): Scene;

        function setShadowProjectionMatrix(matrix: Matrix, viewMatrix: Matrix, renderList: Vector.<AbstractMesh>): void;

        function supportsVSM(): Boolean;
        function needRefreshPerFrame(): Boolean;
        function needCube(): Boolean;

        function getShadowDirection(faceIndex: int = -1): Vector3;

//        function set _shadowGenerator(value: IShadowGenerator): void;
//        function get _shadowGenerator(): IShadowGenerator;
    }
}
