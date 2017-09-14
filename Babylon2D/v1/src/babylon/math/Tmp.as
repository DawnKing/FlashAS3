/**
 * Created by caijingxiao on 2016/10/17.
 */
package babylon.math {
    import flash.geom.Matrix3D;

    // Temporary pre-allocated objects for engine internal use
    // usage in any internal function :
    // var tmp = Tmp.Vector3[0];   <= gets access to the first pre-created Vector3
    // There's a Tmp array per object type : int, float, Vector2, Vector3, Vector4, Quaternion, Matrix
    public class Tmp {
        public static const COLOR3: Vector.<Color3> = new <Color3>[Color3.Black(), Color3.Black(), Color3.Black()];
        public static const VECTOR2: Vector.<Vector2> = new <Vector2>[Vector2.Zero(), Vector2.Zero(), Vector2.Zero()];  // 3 temp Vector2 at once should be enough
        public static const VECTOR3: Vector.<Vector3> = new <Vector3>[Vector3.Zero(), Vector3.Zero(), Vector3.Zero(),
            Vector3.Zero(), Vector3.Zero(), Vector3.Zero(), Vector3.Zero(), Vector3.Zero(), Vector3.Zero()];    // 9 temp Vector3 at once should be enough
        public static const VECTOR4: Vector.<Vector4> = new <Vector4>[Vector4.Zero(), Vector4.Zero(), Vector4.Zero()];  // 3 temp Vector4 at once should be enough
        public static const QUATERNION: Vector.<Quaternion> = new <Quaternion>[new Quaternion(0, 0, 0, 0)];                // 1 temp Quaternion at once should be enough
        public static const MATRIX: Vector.<Matrix> = new <Matrix>[Matrix.Zero(), Matrix.Zero(),
            Matrix.Zero(), Matrix.Zero(),
            Matrix.Zero(), Matrix.Zero(),
            Matrix.Zero(), Matrix.Zero()];                      // 6 temp Matrices at once should be enough

        public static const VECTOR_NUMBER: Vector.<Number> = new Vector.<Number>(4, true);
        public static const MATRIX3D: Matrix3D = new Matrix3D();
    }
}
