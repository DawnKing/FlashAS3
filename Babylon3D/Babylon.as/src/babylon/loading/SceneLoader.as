/**
 * Created by caijingxiao on 2016/11/4.
 */
package babylon.loading {
    import babylon.Scene;
    import babylon.bones.Skeleton;
    import babylon.loading.plugins.BabylonFileLoader;
    import babylon.mesh.AbstractMesh;
    import babylon.particles.ParticleSystem;
    import babylon.tools.Tools;

    import flash.utils.Dictionary;

    public class SceneLoader {

        public static const NO_LOGGING: int = 0;
        public static const MINIMAL_LOGGING: int = 1;
        public static const SUMMARY_LOGGING: int = 2;
        public static const DETAILED_LOGGING: int = 3;
        public static var loggingLevel: int = SceneLoader.NO_LOGGING;

        private static var _registeredPlugins: Dictionary = new Dictionary(true);   // string - IRegisteredPlugin

        private static function _getDefaultPlugin(): IRegisteredPlugin {
            if (!(".babylon" in _registeredPlugins))
                _registeredPlugins[".babylon"] = new BabylonFileLoader();
            return _registeredPlugins[".babylon"];
        }

        private static function _getPluginForExtension(extension: String): IRegisteredPlugin {
            var registeredPlugin: IRegisteredPlugin = _registeredPlugins[extension];
            if (registeredPlugin) {
                return registeredPlugin;
            }

            return _getDefaultPlugin();
        }

        private static function _getPluginForFilename(sceneFilename: Object): IRegisteredPlugin {//88
            if (sceneFilename.hasOwnProperty("name")) {
                sceneFilename = sceneFilename.name;
            }

            var dotPosition: int = sceneFilename.lastIndexOf(".");

            var queryStringPosition: int = sceneFilename.indexOf("?");

            if (queryStringPosition == -1) {
                queryStringPosition = sceneFilename.length;
            }

            var extension: String = (sceneFilename.substring(dotPosition, queryStringPosition)).toLowerCase();
            return _getPluginForExtension(extension);
        }

        public static function ImportMesh(meshesNames: Object, rootUrl: String, sceneFilename: String, scene: Scene, onSuccess: Function = null, progressCallBack:Function = null, onError: Function = null):void {//138
            var registeredPlugin: IRegisteredPlugin = _getPluginForFilename(sceneFilename);

            var loadingToken: * = {};
            scene._addPendingData(loadingToken);

            Tools.LoadFile(rootUrl + sceneFilename, importMeshFromData, progressCallBack);

            function importMeshFromData(data: *): void {
                var meshes: Vector.<AbstractMesh> = new <AbstractMesh>[];
                var particleSystems: Vector.<ParticleSystem> = new <ParticleSystem>[];
                var skeletons: Vector.<Skeleton> = new <Skeleton>[];

                if (!registeredPlugin.importMesh(meshesNames, scene, data, rootUrl, meshes, particleSystems, skeletons)) {
                    if (onError) {
                        onError();
                    }
                    scene._removePendingData(loadingToken);
                    return;
                }

                if (onSuccess) {
                    scene.importedMeshesFiles.push(rootUrl + sceneFilename);
                    onSuccess(meshes, particleSystems, skeletons);
                    scene._removePendingData(loadingToken);
                }
            }
        }
    }
}
