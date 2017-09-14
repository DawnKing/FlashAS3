/**
 * Created by caijingxiao on 2016/10/13.
 */
package Tutorials {
    import babylon.Engine;
    import babylon.Scene;
    import babylon.cameras.TargetCamera;
    import babylon.lights.Light;
    import babylon.lights.PointLight;
    import babylon.materials.StandardMaterial;
    import babylon.materials.textures.Texture;
    import babylon.math.Vector3;
    import babylon.mesh.Mesh;
    import babylon.particles.SolidParticle;
    import babylon.particles.SolidParticleSystem;

    import easiest.events.Stage3DEvent;

    import flash.display.Sprite;
    import flash.events.Event;

    [SWF(frameRate="60")]
    public class SolidParticles extends Sprite {
        private var _engine: Engine;

        public function SolidParticles() {
            // load the 3D engine
            _engine = new Engine(stage);
            _engine.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DCreated);
            _engine.init();
        }

        private function onContext3DCreated(event: Stage3DEvent): void {
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

            var camera: TargetCamera = new TargetCamera("camera1", new Vector3(0, 10, -10), scene);
            camera.setTarget(Vector3.Zero());

            var light: Light = new PointLight('light1', new Vector3(0, 1, 1),scene);

            // texture and material
            var url: String = "assets/buff.png";
            var mat: StandardMaterial = new StandardMaterial("mat1", scene);
            mat.backFaceCulling = true;
            var texture: Texture = new Texture(url, scene);
            texture.hasAlpha = true;
            texture.uOffset = 0.25;
            texture.vOffset = 0.5;
            texture.uScale = 0.25;
            texture.vScale = 0.5;
            mat.diffuseTexture = texture;

            // SPS creation
            var plane: Mesh = Mesh.CreatePlane("plane", 5, scene);
            var SPS: SolidParticleSystem = new SolidParticleSystem('SPS', scene);
            SPS.addShape(plane, 1);
            var mesh: Mesh = SPS.buildMesh();
            mesh.useVertexColors = false;
            mesh.material = mat;
            plane.dispose();  // free memory

            // init
            SPS.initParticles = function(): void {
                // just recycle everything
                for (var p: int = 0; p < this.nbParticles; p++) {
                    var particle: SolidParticle = this.particles[p] as SolidParticle;

                    particle.position.x = 0;
                    particle.position.y = 0;
                    particle.position.z = 0;

                    particle.rotation.x = 1/2 * Math.PI;
                    this.recycleParticle(this.particles[p]);
                }
            };

            // recycle
            SPS.recycleParticle = function(particle: SolidParticle): void {
                texture.uOffset += 0.25;
            };

            var frame: int = 0;
            // update : will be called by setParticles()
            SPS.updateParticle = function(particle: SolidParticle): void {
                if (frame++ % 10 == 0)
                    this.recycleParticle(particle);

                particle.rotation.y += 0.008;
            };


            // init all particle values and set them once to apply textures, colors, etc
            SPS.initParticles();
            SPS.setParticles();

            // Tuning : plane particles facing, so billboard and no rotation computation
            // colors not changing then, neither textures
            //SPS.billboard = true;
            //SPS.computeParticleRotation = false;
            SPS.computeParticleColor = false;
            SPS.computeParticleTexture = false;

            //scene.debugLayer.show();
            // animation
            scene.registerBeforeRender(function(): void {
                SPS.setParticles();
                // SPS.mesh.rotation.y += 0.01;
            });

            return scene;
        }
    }
}
