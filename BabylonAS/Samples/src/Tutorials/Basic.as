/**
 * Created by caijingxiao on 2016/10/13.
 */
package Tutorials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.TargetCamera;
    import babylon.materials.ShaderMaterial;
    import babylon.math.Color4;
    import babylon.math.Vector3;
    import babylon.mesh.Mesh;

    import easiest.events.Stage3DEvent;

    import flash.display.Sprite;
    import flash.events.Event;

    [SWF(frameRate="60")]
    public class Basic extends Sprite {
        private var _engine: Engine;
        private var _box: Mesh;

        public function Basic() {
            // load the 3D engine
            _engine = new Engine(stage);
            _engine.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DCreated);
            _engine.init();
        }

        private function onContext3DCreated(event: Stage3DEvent): void {
            var scene: Scene = createScene();

            _engine.runRenderLoop(function(): void {
                _box.rotation.y += 0.02;

                scene.render();
            });

            stage.addEventListener(Event.RESIZE, function(event: Event): void {
                _engine.resize();
            });
        }

        // createScene function that creates and return the scene
        private function createScene(): Scene {
            // Create a basic BJS Scene object
            var scene: Scene = new Scene(_engine);

            // Create a TargetCamera, and set its position to (x:0, y:5, z:10)
            var camera: TargetCamera = new TargetCamera("camera1", new Vector3(0, 5, 10), scene);

            // target the camera to scene origin
            camera.setTarget(Vector3.Zero());

            // Create a builtin shape
            _box = Mesh.CreateBox("mesh", 2, scene);

            var material: ShaderMaterial = new ShaderMaterial("color material", scene, "color", {});
            material.setColor4("color", new Color4(1, 0, 0, 1));
            _box.material = material;

            var box2: Mesh = Mesh.CreateBox("mesh", 2, scene);
            box2.material = material;
            box2.position = new Vector3(-5, 0, 0);

            return scene;
        }
    }
}
