/**
 * Created by caijingxiao on 2016/10/13.
 */
package Tutorials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.ArcRotateCamera;
    import babylon.cameras.TargetCamera;
    import babylon.materials.textures.Texture;
    import babylon.math.Color4;
    import babylon.math.Vector3;
    import babylon.mesh.Mesh;
    import babylon.particles.ParticleSystem;

    import easiest.events.Stage3DEvent;

    import flash.display.Sprite;
    import flash.events.Event;

    [SWF(frameRate="60")]
    public class Particles extends Sprite {
        private var _engine: Engine;

        public function Particles() {
            // load the 3D engine
            _engine = new Engine(stage);
            _engine.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DCreated);
            _engine.init();
        }

        private function onContext3DCreated(event: Stage3DEvent):void {
            var scene:Scene = createScene();

            _engine.runRenderLoop(function(): void {
                scene.render();
            });

            stage.addEventListener(Event.RESIZE, function(event: Event): void {
                _engine.resize();
            });
        }

        // createScene function that creates and return the scene
        private function createScene(): Scene {
            var scene: Scene = new Scene(_engine);

//            var camera:TargetCamera = new TargetCamera("camera1", new Vector3(0, 5, 5), scene);
//
//            // target the camera to scene origin
//            camera.setTarget(Vector3.Zero());
            var camera: ArcRotateCamera = new ArcRotateCamera("camera1", 0, 0, 0, new Vector3(0, 0, 0), scene);
            camera.setPosition(new Vector3(0, 5, 5));
            camera.attachControl(this, true);

            // Emitters
            var emitter0: Object = Mesh.CreateBox("emitter0", 0.1, scene);
            emitter0.isVisible = false;

            // Particles
            var particleSystem: ParticleSystem = new ParticleSystem("particles", 100, scene);
            particleSystem.particleTexture = new Texture("assets/Flare.png", scene);
            particleSystem.minAngularSpeed = -0.5;
            particleSystem.maxAngularSpeed = 0.5;
            particleSystem.minSize = 0.1;
            particleSystem.maxSize = 0.5;
            particleSystem.minLifeTime = 0.5;
            particleSystem.maxLifeTime = 2.0;
            particleSystem.minEmitPower = 0.5;
            particleSystem.maxEmitPower = 4.0;
            particleSystem.emitter = emitter0;
            particleSystem.emitRate = 400;
            particleSystem.blendMode = ParticleSystem.BLENDMODE_ONEONE;
            particleSystem.minEmitBox = new Vector3(-0.5, 0, -0.5);
            particleSystem.maxEmitBox = new Vector3(0.5, 0, 0.5);
            particleSystem.direction1 = new Vector3(-1, 1, -1);
            particleSystem.direction2 = new Vector3(1, 1, 1);
            particleSystem.color1 = new Color4(1, 0, 0, 1);
            particleSystem.color2 = new Color4(0, 1, 1, 1);
            particleSystem.gravity = new Vector3(0, -2.0, 0);
            particleSystem.start();

            return scene;
        }
    }
}
