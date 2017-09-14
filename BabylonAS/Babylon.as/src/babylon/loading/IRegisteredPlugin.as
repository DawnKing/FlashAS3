/**
 * Created by caijingxiao on 2016/11/4.
 */
package babylon.loading
{
    import babylon.Scene;
    import babylon.bones.Skeleton;
    import babylon.mesh.AbstractMesh;
    import babylon.particles.ParticleSystem;

    public interface IRegisteredPlugin
    {
        function get extensions(): String;
        function importMesh(meshesNames: Object, scene: Scene, data: Object, rootUrl: String, meshes: Vector.<AbstractMesh>, particleSystems: Vector.<ParticleSystem>, skeletons: Vector.<Skeleton>): Boolean;
    }
}
