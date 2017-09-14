function TestSolidParticle(scene, maxCount) {
    var list = [];
    var gap = 8;
    var count = Math.ceil(Math.sqrt(maxCount));
    for (var i = 0; i < count; ++i) {
        for (var j = 0; j < count; ++j)	{
            if (list.length >= maxCount)
                break;

            // texture and material
            var url = "assets/buff.png";
            var mat = new BABYLON.StandardMaterial("mat1", scene);
            mat.backFaceCulling = true;
            var texture = new BABYLON.Texture(url, scene);
            texture.hasAlpha = true;
            texture.uOffset = 0.25;
            texture.vOffset = 0.5;
            texture.uScale = 0.25;
            texture.vScale = 0.5;
            mat.diffuseTexture = texture;

            var x = (i - (count - 1) / 2) * gap;
            var z = (j - (count - 1) / 2) * gap;

            var plane = BABYLON.Mesh.CreatePlane("plane", 5, scene);
            var sps = new BABYLON.SolidParticleSystem('SPS', scene);
            sps.addShape(plane, 1);
            var mesh = sps.buildMesh();
            mesh.useVertexColors = false;
            mesh.material = mat;
            mesh.position = new BABYLON.Vector3(x, 0, z);
            plane.dispose();  // free memory

            // init
            sps.initParticles = function() {
                // just recycle everything
                for (var p = 0; p < this.nbParticles; p++) {
                    var particle = this.particles[p];

                    particle.position.x = 0;
                    particle.position.y = 0;
                    particle.position.z = 0;

                    particle.rotation.x = 1/2 * Math.PI;

                    particle.texture = texture;
                    particle.frame = getRandomInt(0, 100);
                    particle.frameCycle = getRandomInt(5, 20);
                    particle.speed = getRandomInt(1, 10);

                    this.recycleParticle(particle);
                }
            };

            // recycle
            sps.recycleParticle = function(particle) {
                particle.texture.uOffset += 0.25;
            };

            sps.updateParticle = function(particle) {
                if (particle.frame % particle.frameCycle == 0)
                    this.recycleParticle(particle);

                particle.frame++;
                particle.rotation.y += 0.008 * particle.speed;
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
    scene.registerBeforeRender(function() {
        for (var i = 0; i < list.length; i++) {
            list[i].setParticles();
        }
    });
}

function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}