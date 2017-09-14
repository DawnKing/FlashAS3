/**
 * Created by caijingxiao on 2017/1/12.
 */
package Tutorials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.ArcRotateCamera;
    import babylon.lights.PointLight;
    import babylon.lights.shadows.ShadowGenerator;
    import babylon.math.Vector3;
    import babylon.mesh.Mesh;

    import easiest.events.Stage3DEvent;

    import flash.display.Sprite;
    import flash.events.Event;

    [SWF(frameRate="60")]
    public class Shadow extends Sprite {
        private var _engine: Engine;

        public function Shadow() {
            _engine = new Engine(stage);
            _engine.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DCreated);
            _engine.init();
        }

        private function onContext3DCreated(event: Stage3DEvent):void {
            var scene: Scene = createScene();

            _engine.runRenderLoop(function():void {
                scene.render();
            });

            stage.addEventListener(Event.RESIZE, function(event: Event): void {
                _engine.resize();
            });
        }

        private function createScene(): Scene {
            var scene: Scene = new Scene(_engine);

            var camera: ArcRotateCamera = new ArcRotateCamera("Camera", 0, 0.8, 90, Vector3.Zero(), scene);
            camera.attachControl(this.stage, true);

            var light: PointLight = new PointLight("dir01", new Vector3(20, 40, 20), scene);
            light.intensity = 0.5;

            // Ground
            var ground: Mesh = Mesh.CreateGround('ground1', 100, 100, 2, scene);

            // Sphere
            var sphere: Mesh = Mesh.CreateSphere('sphere1', 16, 2, scene);

            // Shadows
            var shadowGenerator: ShadowGenerator = new ShadowGenerator(1024, light);
            shadowGenerator.getShadowMap().renderList.push(sphere);
            shadowGenerator.useVarianceShadowMap = true;

            ground.receiveShadows = true;

            // Animations
            var alpha: Number = 0;
            scene.registerBeforeRender(function (): void {
                sphere.rotation.x += 0.01;
                sphere.rotation.z += 0.02;

                sphere.position = new Vector3(Math.cos(alpha) * 30, 10, Math.sin(alpha) * 30);
                alpha += 0.01;
            });

            return scene;
        }
    }
}
