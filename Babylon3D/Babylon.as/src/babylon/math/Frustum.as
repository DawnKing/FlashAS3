/**
 * Created by caijingxiao on 2016/10/24.
 */
package babylon.math {
    public class Frustum {
    public static function GetPlanes(transform: Matrix): Vector.<Plane> {
        var frustumPlanes: Vector.<Plane> = new <Plane>[];

        for (var index: int = 0; index < 6; index++) {
            frustumPlanes.push(new Plane(0, 0, 0, 0));
        }

        Frustum.GetPlanesToRef(transform, frustumPlanes);

        return frustumPlanes;
    }

    public static function GetPlanesToRef(transform: Matrix, frustumPlanes: Vector.<Plane>): void {
        // Near
        frustumPlanes[0].normal.x = transform.m[3] + transform.m[2];
        frustumPlanes[0].normal.y = transform.m[7] + transform.m[6];
        frustumPlanes[0].normal.z = transform.m[11] + transform.m[10];
        frustumPlanes[0].d = transform.m[15] + transform.m[14];
        frustumPlanes[0].normalize();

        // Far
        frustumPlanes[1].normal.x = transform.m[3] - transform.m[2];
        frustumPlanes[1].normal.y = transform.m[7] - transform.m[6];
        frustumPlanes[1].normal.z = transform.m[11] - transform.m[10];
        frustumPlanes[1].d = transform.m[15] - transform.m[14];
        frustumPlanes[1].normalize();

        // Left
        frustumPlanes[2].normal.x = transform.m[3] + transform.m[0];
        frustumPlanes[2].normal.y = transform.m[7] + transform.m[4];
        frustumPlanes[2].normal.z = transform.m[11] + transform.m[8];
        frustumPlanes[2].d = transform.m[15] + transform.m[12];
        frustumPlanes[2].normalize();

        // Right
        frustumPlanes[3].normal.x = transform.m[3] - transform.m[0];
        frustumPlanes[3].normal.y = transform.m[7] - transform.m[4];
        frustumPlanes[3].normal.z = transform.m[11] - transform.m[8];
        frustumPlanes[3].d = transform.m[15] - transform.m[12];
        frustumPlanes[3].normalize();

        // Top
        frustumPlanes[4].normal.x = transform.m[3] - transform.m[1];
        frustumPlanes[4].normal.y = transform.m[7] - transform.m[5];
        frustumPlanes[4].normal.z = transform.m[11] - transform.m[9];
        frustumPlanes[4].d = transform.m[15] - transform.m[13];
        frustumPlanes[4].normalize();

        // Bottom
        frustumPlanes[5].normal.x = transform.m[3] + transform.m[1];
        frustumPlanes[5].normal.y = transform.m[7] + transform.m[5];
        frustumPlanes[5].normal.z = transform.m[11] + transform.m[9];
        frustumPlanes[5].d = transform.m[15] + transform.m[13];
        frustumPlanes[5].normalize();
    }
    }
}
