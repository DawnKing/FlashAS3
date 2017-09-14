/**
 * Created by caijingxiao on 2016/11/30.
 */
package Tutorials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.ArcRotateCamera;
    import babylon.math.Vector3;

    import easiest.events.Stage3DEvent;

    import flash.display.Sprite;
    import flash.events.Event;

    [SWF(frameRate="60")]
    public class Test extends Sprite {
        private var _engine:Engine;

        public function Test() {
            // load the 3D engine
            _engine = new Engine(stage);
            _engine.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DCreated);
            _engine.init();
        }

        private function onContext3DCreated(event: Stage3DEvent): void {
            var scene: Scene = createScene();

            _engine.runRenderLoop(function():void {
                scene.render();
            });

            stage.addEventListener(Event.RESIZE, function(event: Event): void {
                _engine.resize();
            });
        }

        // createScene function that creates and return the scene
        private function createScene(): Scene {
            var scene: Scene = new Scene(_engine);

            var camera: ArcRotateCamera = new ArcRotateCamera("camera1", 0, 0, 0, new Vector3(0, 0, 0), scene);
            camera.setPosition(new Vector3(0, 5000, -1000));
            camera.attachControl(this, true);

            TestSolidParticles.test(scene, 300);

//            scene.debugLayer.show(true, null, this);

            return scene;
        }
    }
}
