/**
 * Created by caijingxiao on 2016/11/9.
 */
package babylon.tools {
    import babylon.Scene;
    import babylon.materials.textures.Texture;

    import flash.utils.describeType;

    public class SerializationHelper {

        public static function Parse(creationFunction: Function, source: Object, scene: Scene, rootUrl: String = null): Object {
            var destination: Object = creationFunction();

            var xDesc: XML = describeType(destination.constructor);
            var myClassName: String = xDesc.@name;
            var xMetas: XMLList = xDesc.factory..metadata;

            var xMetaParent: XML;
            var metaParents: Array =  [];
            for each(var xMeta:XML in xMetas) {
                xMetaParent = xMeta.parent();
                if (xMeta.@name.indexOf("__go_to") > -1) {
                    delete xMetaParent.children()[xMeta.childIndex()];
                }

                if (xMeta.@name != "Serialize")
                    continue;

                if (xMetaParent.name() == "factory") {
                    metaParents.push(xMeta);
                    continue;
                }

                var declaredBy: String =  xMetaParent.attribute("declaredBy");
                if (declaredBy && declaredBy != myClassName) {
                    continue;
                }

                metaParents.push(xMetaParent);
            }

            // Properties
            for each (var propertyDescriptor: XML in metaParents) {
                var property: String = propertyDescriptor.@name;
                var sourceProperty: Object = source[property];
                var propertyType: String = propertyDescriptor..@value;

                if (sourceProperty) {
                    switch (propertyType) {
                        case "":
                            destination[property] = sourceProperty;
                            break;
                        case "texture":
                            destination[property] = Texture.Parse(sourceProperty, scene, rootUrl);
                            break;
                        default:
                            throw new Error();
                    }
                }
            }
            
            return destination;
        }
    }
}
