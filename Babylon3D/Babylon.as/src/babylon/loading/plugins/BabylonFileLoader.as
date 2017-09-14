/**
 * Created by caijingxiao on 2016/11/4.
 */
package babylon.loading.plugins
{
    import babylon.Scene;
    import babylon.bones.Skeleton;
    import babylon.loading.IRegisteredPlugin;
    import babylon.loading.SceneLoader;
    import babylon.materials.Material;
    import babylon.mesh.AbstractMesh;
    import babylon.mesh.Geometry;
    import babylon.mesh.Mesh;
    import babylon.particles.ParticleSystem;
    import babylon.tools.Tools;

    import easiest.unit.asserts.fail;

    public class BabylonFileLoader implements IRegisteredPlugin
    {
        public function BabylonFileLoader()
        {
        }

        public function get extensions(): String {
            return ".babylon";
        }

        private function parseMaterialById(id: String, parsedData: Object, scene: Scene, rootUrl: String): Material {
            for (var index: int = 0, cache: int = parsedData.materials.length; index < cache; index++) {
                var parsedMaterial: Object = parsedData.materials[index];
                if (parsedMaterial.id === id) {
                    return Material.Parse(parsedMaterial, scene, rootUrl);
                }
            }
            return null;
        }

        private function isDescendantOf(mesh: Object, names: Object, hierarchyIds: Vector.<int>): Boolean {
            names = (names is Array) ? names : [names];
            for (var i: String in names) {
                if (mesh.name == names[i]) {
                    hierarchyIds.push(mesh.id);
                    return true;
                }
            }
            if (mesh.parentId && hierarchyIds.indexOf(mesh.parentId) != -1) {
                hierarchyIds.push(mesh.id);
                return true;
            }
            return false;
        }

        private function logOperation(operation: String, producer: Object): String {
            return operation + " of " + (producer ? producer.file + " from " + producer.name + " version: " + producer.version + ", exporter version: " + producer.exporter_version : "unknown");
        }

        public function importMesh(meshesNames: Object, scene: Scene, data: Object, rootUrl: String, meshes: Vector.<AbstractMesh>, particleSystems: Vector.<ParticleSystem>, skeletons: Vector.<Skeleton>): Boolean {
            var parsedData: Object = JSON.parse(String(data));
            var log:String = "";
            var fullDetails: Boolean = SceneLoader.loggingLevel === SceneLoader.DETAILED_LOGGING;

            var loadedSkeletonsIds: Vector.<int> = new <int>[];
            var loadedMaterialsIds: Vector.<int> = new <int>[];
            var hierarchyIds: Vector.<int> = new <int>[];
            var index: int;
            var cache: int;
            for (index = 0, cache = parsedData.meshes.length; index < cache; index++) {
                var parsedMesh: Object = parsedData.meshes[index];

                if (!meshesNames || isDescendantOf(parsedMesh, meshesNames, hierarchyIds)) {
                    if (meshesNames is Array) {
                        // Remove found mesh name from list.
                        delete meshesNames[meshesNames.indexOf(parsedMesh.name)];
                    }

                    //Geometry?
                    if (parsedMesh.geometryId) {
                        //does the file contain geometries?
                        if (parsedData.geometries) {
                            //find the correct geometry and add it to the scene
                            var found: Boolean = false;
                            var geometryTypeList: Array = ["boxes", "spheres", "cylinders", "toruses", "grounds", "planes", "torusKnots", "vertexData"];
                            geometryTypeList.forEach(function (geometryType: String): void {
                                if (found || !parsedData.geometries[geometryType] || !(parsedData.geometries[geometryType] is Array)) {
                                    fail();
                                } else {
                                    parsedData.geometries[geometryType].forEach(function (parsedGeometryData: Object): void {
                                        if (parsedGeometryData.id === parsedMesh.geometryId) {
                                            switch (geometryType) {
//                                                case "boxes":
//                                                    Geometry.Primitives.Box.Parse(parsedGeometryData, scene);
//                                                    break;
//                                                case "spheres":
//                                                    Geometry.Primitives.Sphere.Parse(parsedGeometryData, scene);
//                                                    break;
//                                                case "cylinders":
//                                                    Geometry.Primitives.Cylinder.Parse(parsedGeometryData, scene);
//                                                    break;
//                                                case "toruses":
//                                                    Geometry.Primitives.Torus.Parse(parsedGeometryData, scene);
//                                                    break;
//                                                case "grounds":
//                                                    Geometry.Primitives.Ground.Parse(parsedGeometryData, scene);
//                                                    break;
//                                                case "planes":
//                                                    Geometry.Primitives.Plane.Parse(parsedGeometryData, scene);
//                                                    break;
//                                                case "torusKnots":
//                                                    Geometry.Primitives.TorusKnot.Parse(parsedGeometryData, scene);
//                                                    break;
                                                case "vertexData":
                                                    Geometry.Parse(parsedGeometryData, scene, rootUrl);
                                                    break;
                                            }
                                            found = true;
                                        }
                                    });
                                }
                            });
                            if (!found) {
                                Tools.Warn("Geometry not found for mesh " + parsedMesh.id);
                            }
                        }
                    }

                    // Material ?
                    if (parsedMesh.materialId) {
                        var materialFound: Boolean = (loadedMaterialsIds.indexOf(parsedMesh.materialId) !== -1);
                        if (!materialFound && parsedData.multiMaterials) {
                            for (var multiMatIndex: int = 0, multiMatCache: int = parsedData.multiMaterials.length; multiMatIndex < multiMatCache; multiMatIndex++) {
                                var parsedMultiMaterial: Object = parsedData.multiMaterials[multiMatIndex];
                                if (parsedMultiMaterial.id === parsedMesh.materialId) {
                                    for (var matIndex: int = 0, matCache: int = parsedMultiMaterial.materials.length; matIndex < matCache; matIndex++) {
                                        var subMatId: String = parsedMultiMaterial.materials[matIndex];
                                        loadedMaterialsIds.push(subMatId);
                                        var mat: Material = parseMaterialById(subMatId, parsedData, scene, rootUrl);
                                        log += "\n\tMaterial " + mat.toString(fullDetails);
                                    }
                                    loadedMaterialsIds.push(parsedMultiMaterial.id);
                                    var mmat: Material = Material.ParseMultiMaterial(parsedMultiMaterial, scene);
                                    materialFound = true;
                                    log += "\n\tMulti-Material " + mmat.toString(fullDetails);
                                    break;
                                }
                            }
                        }

                        if (!materialFound) {
                            loadedMaterialsIds.push(parsedMesh.materialId);
                            mat = parseMaterialById(parsedMesh.materialId, parsedData, scene, rootUrl);
                            if (!mat) {
                                Tools.Warn("Material not found for mesh " + parsedMesh.id);
                            } else {
                                log += "\n\tMaterial " + mat.toString(fullDetails);
                            }
                        }
                    }

                    // Skeleton ?
                    if (parsedMesh.skeletonId > -1 && scene.skeletons) {
                        var skeletonAlreadyLoaded: Boolean = (loadedSkeletonsIds.indexOf(parsedMesh.skeletonId) > -1);
                        if (!skeletonAlreadyLoaded) {
                            for (var skeletonIndex: int = 0, skeletonCache: int = parsedData.skeletons.length; skeletonIndex < skeletonCache; skeletonIndex++) {
                                var parsedSkeleton: Object = parsedData.skeletons[skeletonIndex];
                                if (parsedSkeleton.id === parsedMesh.skeletonId) {
                                    var skeleton: Skeleton = Skeleton.Parse(parsedSkeleton, scene);
                                    skeletons.push(skeleton);
                                    loadedSkeletonsIds.push(parsedSkeleton.id);
                                    log += "\n\tSkeleton " + skeleton.toString(fullDetails);
                                }
                            }
                        }
                    }

                    var mesh: Mesh = Mesh.Parse(parsedMesh, scene);
                    meshes.push(mesh);
                    log += "\n\tMesh " + mesh.toString(fullDetails);
                }
            }

            // Connecting parents
            var currentMesh: AbstractMesh;
            for (index = 0, cache = scene.meshes.length; index < cache; index++) {
                currentMesh = scene.meshes[index];
                if (currentMesh._waitingParentId) {
                    currentMesh.parent = scene.getLastEntryByID(currentMesh._waitingParentId);
                    currentMesh._waitingParentId = undefined;
                }
            }

            // freeze and compute world matrix application
            for (index = 0, cache = scene.meshes.length; index < cache; index++) {
                currentMesh = scene.meshes[index];
                if (currentMesh._waitingFreezeWorldMatrix) {
                    fail();
//                    currentMesh.freezeWorldMatrix();
//                    currentMesh._waitingFreezeWorldMatrix = undefined;
                } else {
                    currentMesh.computeWorldMatrix(true);
                }
            }

            // Particles
            if (parsedData.particleSystems) {
                for (index = 0, cache = parsedData.particleSystems.length; index < cache; index++) {
                    var parsedParticleSystem: Object = parsedData.particleSystems[index];
                    if (hierarchyIds.indexOf(parsedParticleSystem.emitterId) !== -1) {
                        particleSystems.push(ParticleSystem.Parse(parsedParticleSystem, scene, rootUrl));
                    }
                }
            }

            if (log !== null && SceneLoader.loggingLevel !== SceneLoader.NO_LOGGING) {
                Tools.Log(logOperation("importMesh", parsedData ? parsedData.producer : "Unknown") + (SceneLoader.loggingLevel !== SceneLoader.MINIMAL_LOGGING ? log : ""));
            }
            return true;
        }
    }
}
