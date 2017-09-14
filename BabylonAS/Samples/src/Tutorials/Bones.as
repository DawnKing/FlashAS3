/**
 * Created by caijingxiao on 2016/10/13.
 */
package Tutorials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.bones.Skeleton;
    import babylon.cameras.TargetCamera;
    import babylon.lights.Light;
    import babylon.lights.PointLight;
    import babylon.loading.SceneLoader;
    import babylon.materials.ShaderMaterial;
    import babylon.math.Color4;
    import babylon.math.Vector3;
    import babylon.mesh.AbstractMesh;
    import babylon.particles.ParticleSystem;

    import easiest.events.Stage3DEvent;

    import flash.display.Sprite;
    import flash.events.Event;

    [SWF(frameRate="60")]
    public class Bones extends Sprite {
        private var _engine:Engine;

        public function Bones() {
            // load the 3D engine
            _engine = new Engine(stage);
            _engine.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DCreated);
            _engine.init();
        }

        private function onContext3DCreated(event:Stage3DEvent): void {
            var scene: Scene = createScene();

            _engine.runRenderLoop(function(): void {
                scene.render();
            });

            stage.addEventListener(Event.RESIZE, function(event: Event):void {
                _engine.resize();
            });
        }

        // createScene function that creates and return the scene
        private function createScene(): Scene {
            var scene: Scene = new Scene(_engine);

            var camera: TargetCamera = new TargetCamera("camera1", new Vector3(0, 100, 100), scene);
            camera.setTarget(new Vector3(0, 0, 0));

            var light: Light = new PointLight('light1', new Vector3(0, 50, 50),scene);

            SceneLoader.ImportMesh("15_RootNode", "assets/", "box.babylon", scene, function (newMeshes2: Vector.<AbstractMesh>, particleSystem2: Vector.<ParticleSystem>, skeleton2: Vector.<Skeleton>): void {
                for (var i: int = 0; i < newMeshes2.length; i++) {
                    newMeshes2[i].position = new Vector3(-10, 0, 0);
                }
            });

            SceneLoader.ImportMesh("15_RootNode", "assets/", "box_move.babylon", scene, function (newMeshes2: Vector.<AbstractMesh>, particleSystem2: Vector.<ParticleSystem>, skeleton2: Vector.<Skeleton>): void {
                var material: ShaderMaterial = new ShaderMaterial("texture material", scene, "color", {});
                material.setColor4("color", new Color4(1, 0, 0, 1));

//                for each (var mesh: AbstractMesh in newMeshes2) {
//                    mesh.material = material;
//                }
            });

            return scene;
        }
    }
}
