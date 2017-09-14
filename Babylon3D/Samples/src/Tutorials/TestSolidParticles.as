/**
 * Created by caijingxiao on 2016/11/30.
 */
package Tutorials {
    import babylon.Scene;
    import babylon.materials.Material;
    import babylon.materials.TextureMaterial;
    import babylon.materials.textures.Texture;
    import babylon.math.Vector3;
    import babylon.mesh.Mesh;
    import babylon.particles.SolidParticle;
    import babylon.particles.SolidParticleSystem;

    import flash.utils.Dictionary;

    public class TestSolidParticles {
        public static var t: Dictionary = new Dictionary(true);


        /**
         1、upload vertex： scene.registerBeforeRender().solidParticleSystem.setParticles()
         2、set program：Mesh.render().effectiveMaterial._preBind();
         3、set vertex buffer： Mesh.render().this._bind(subMesh, effect, fillMode);
         4、set texture set constants： Mesh.render().effectiveMaterial.bind(world, this);
         */
        public static function test(scene: Scene, maxCount: int): void {
            var list: Array = [];
            var gap: int = 200;
            var count: int = Math.ceil(Math.sqrt(maxCount));
            for (var i: int = 0; i < count; ++i) {
                for (var j: int = 0; j < count; ++j)	{
                    if (list.length >= maxCount)
                        break;

                    // texture and material
                    var url: String = "assets/buff.png";
                    var mat: Material = new TextureMaterial("mat1", scene);
                    mat.backFaceCulling = true;
                    var texture: Texture = new Texture(url, scene);
                    texture.hasAlpha = true;
                    texture.uOffset = 0.25;
                    texture.vOffset = 0.5;
                    texture.uScale = 0.25;
                    texture.vScale = 0.5;
                    mat["diffuseTexture"] = texture;

                    var x: int = (i - (count - 1) / 2) * gap;
                    var z: int = (j - (count - 1) / 2) * gap;

                    var plane: Mesh = Mesh.CreatePlane("plane", 200, scene);
                    var sps: SolidParticleSystem = new SolidParticleSystem('SPS', scene);
                    sps.addShape(plane, 1);
                    var mesh: Mesh = sps.buildMesh();
//                    mesh.batching = true;
                    mesh.useVertexColors = false;
                    mesh.material = mat;
                    mesh.position = new Vector3(x, 0, z);
                    plane.dispose();  // free memory

                    // init
                    sps.initParticles = function(): void {
                        // just recycle everything
                        for (var p: int = 0; p < this.nbParticles; p++) {
                            var particle: SolidParticle = this.particles[p] as SolidParticle;

                            particle.position.x = 0;
                            particle.position.y = 0;
                            particle.position.z = 0;

                            particle.rotation.x = 1/2 * Math.PI;

                            t[particle] = {};
                            t[particle].texture = texture;
                            t[particle].frame = getRandomInt(0, 100);
                            t[particle].frameCycle = getRandomInt(5, 20);
                            t[particle].speed = getRandomInt(1, 10);

                            this.recycleParticle(particle);
                        }
                    };

                    // recycle
                    sps.recycleParticle = function(particle: SolidParticle): void {
                        var texture: Texture = particle._sps.mesh.material["diffuseTexture"];
                        texture.uOffset += 0.25;
                        if (texture.uOffset > 1)
                            texture.uOffset = 0;
                    };

                    sps.updateParticle = function(particle: SolidParticle): void {
                        if (t[particle].frame % t[particle].frameCycle == 0)
                            this.recycleParticle(particle);

                        t[particle].frame++;
                        particle.rotation.y += 0.008 * t[particle].speed;
                    };


                    // init all particle values and set them once to apply textures, colors, etc
                    sps.initParticles();
                    sps.setParticles();

                    // Tuning : plane particles facing, so billboard and no rotation computation
                    // colors not changing then, neither textures
                    //SPS.billboard = true;
                    //SPS.computeParticleRotation = false;
                    sps.computeParticleColor = false;
                    sps.computeParticleTexture = false;

                    list.push(sps);
                }
            }

            // animation
            scene.registerBeforeRender(function(): void {
                for (var i: int = 0; i < list.length; i++) {
                    var s: SolidParticleSystem = list[i];
                    s.setParticles();
//                    if (s.mesh.material is TextureMaterial)
//                        s.setUVMatrix(s.mesh.material["diffuseTexture"].getTextureMatrix());
                }
            });
        }
    }
}

function getRandomInt(min: int, max: int): int {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}