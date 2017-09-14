/**
 * Created by caijingxiao on 2016/10/26.
 */
package babylon.mesh {
    import babylon.Scene;
    import babylon.math.Vector3;

    public class MeshBuilder {

        private static function updateSideOrientation(orientation: Number, scene: Scene): Number {
            if (orientation == Mesh.DOUBLESIDE) {
                return Mesh.DOUBLESIDE;
            }

            if (isNaN(orientation)) {
                return Mesh.FRONTSIDE;
            }

            return orientation;
        }

        public static function CreateBox(name: String, options: Object, scene: Scene): Mesh {
            var box: Mesh = new Mesh(name, scene);

            options.sideOrientation = updateSideOrientation(options.sideOrientation, scene);
            box.sideOrientation = options.sideOrientation;

            var vertexData: VertexData = VertexData.CreateBox(options);

            vertexData.applyToMesh(box, options.updatable);

            return box;
        }

        /**
         * Creates a sphere mesh.
         * tuto : http://doc.babylonjs.com/tutorials/Mesh_CreateXXX_Methods_With_Options_Parameter#sphere
         * The parameter `diameter` sets the diameter size (float) of the sphere (default 1).
         * You can set some different sphere dimensions, for instance to build an ellipsoid, by using the parameters `diameterX`, `diameterY` and `diameterZ` (all by default have the same value than `diameter`).
         * The parameter `segments` sets the sphere number of horizontal stripes (positive integer, default 32).
         * You can create an unclosed sphere with the parameter `arc` (positive float, default 1), valued between 0 and 1, what is the ratio of the circumference (latitude) : 2 x PI x ratio
         * You can create an unclosed sphere on its height with the parameter `slice` (positive float, default1), valued between 0 and 1, what is the height ratio (longitude).
         * You can also set the mesh side orientation with the values : BABYLON.Mesh.FRONTSIDE (default), BABYLON.Mesh.BACKSIDE or BABYLON.Mesh.DOUBLESIDE
         * Detail here : http://doc.babylonjs.com/tutorials/02._Discover_Basic_Elements#side-orientation
         * The mesh can be set to updatable with the boolean parameter `updatable` (default false) if its internal geometry is supposed to change once created.
         */
        public static function CreateSphere(name: String, options: Object, scene: Scene): Mesh {
            var sphere: Mesh = new Mesh(name, scene);

            options.sideOrientation = updateSideOrientation(options.sideOrientation, scene);
            sphere.sideOrientation = options.sideOrientation;

            var vertexData: VertexData = VertexData.CreateSphere(options);

            vertexData.applyToMesh(sphere, options.updatable);

            return sphere;
        }

        /**
         * Creates a plane polygonal mesh.  By default, this is a disc.
         * tuto : http://doc.babylonjs.com/tutorials/Mesh_CreateXXX_Methods_With_Options_Parameter#disc
         * The parameter `radius` sets the radius size (float) of the polygon (default 0.5).
         * The parameter `tessellation` sets the number of polygon sides (positive integer, default 64). So a tessellation valued to 3 will build a triangle, to 4 a square, etc.
         * You can create an unclosed polygon with the parameter `arc` (positive float, default 1), valued between 0 and 1, what is the ratio of the circumference : 2 x PI x ratio
         * You can also set the mesh side orientation with the values : BABYLON.Mesh.FRONTSIDE (default), BABYLON.Mesh.BACKSIDE or BABYLON.Mesh.DOUBLESIDE
         * Detail here : http://doc.babylonjs.com/tutorials/02._Discover_Basic_Elements#side-orientation
         * The mesh can be set to updatable with the boolean parameter `updatable` (default false) if its internal geometry is supposed to change once created.
         */
        public static function CreateDisc(name: String, options: Object, scene: Scene): Mesh {//72
            var disc: Mesh = new Mesh(name, scene);

            options.sideOrientation = updateSideOrientation(options.sideOrientation, scene);
            disc.sideOrientation = options.sideOrientation;

            var vertexData: VertexData = VertexData.CreateDisc(options);

            vertexData.applyToMesh(disc, options.updatable);

            return disc;
        }
        /**
         * Creates a plane mesh.
         * tuto : http://doc.babylonjs.com/tutorials/Mesh_CreateXXX_Methods_With_Options_Parameter#plane
         * The parameter `size` sets the size (float) of both sides of the plane at once (default 1).
         * You can set some different plane dimensions by using the parameters `width` and `height` (both by default have the same value than `size`).
         * The parameter `sourcePlane` is a Plane instance. It builds a mesh plane from a Math plane.
         * You can also set the mesh side orientation with the values : BABYLON.Mesh.FRONTSIDE (default), BABYLON.Mesh.BACKSIDE or BABYLON.Mesh.DOUBLESIDE
         * Detail here : http://doc.babylonjs.com/tutorials/02._Discover_Basic_Elements#side-orientation
         * The mesh can be set to updatable with the boolean parameter `updatable` (default false) if its internal geometry is supposed to change once created.
         */
        public static function CreatePlane(name: String, options: Object, scene: Scene): Mesh {//593
            var plane: Mesh = new Mesh(name, scene);

            options.sideOrientation = updateSideOrientation(options.sideOrientation, scene);
            plane.sideOrientation = options.sideOrientation;

            var vertexData: VertexData = VertexData.CreatePlane(options);

            vertexData.applyToMesh(plane, options.updatable);

            if (options.sourcePlane) {
                plane.translate(options.sourcePlane.normal, options.sourcePlane.d);

                var product: Number = Math.acos(Vector3.Dot(options.sourcePlane.normal, Vector3.Z_AXIS));
                var vectorProduct: Vector3 = Vector3.Cross(Vector3.Z_AXIS, options.sourcePlane.normal);

                plane.rotate(vectorProduct, product);
            }

            return plane;
        }

        /**
         * Creates a ground mesh.
         * tuto : http://doc.babylonjs.com/tutorials/Mesh_CreateXXX_Methods_With_Options_Parameter#plane
         * The parameters `width` and `height` (floats, default 1) set the width and height sizes of the ground.
         * The parameter `subdivisions` (positive integer) sets the number of subdivisions per side.
         * The mesh can be set to updatable with the boolean parameter `updatable` (default false) if its internal geometry is supposed to change once created.
         */
        public static function CreateGround(name: String, options: Object, scene: Scene): Mesh {
            var ground: GroundMesh = new GroundMesh(name, scene);
            ground._setReady(false);
            ground._subdivisionsX = options.subdivisionsX || options.subdivisions || 1;
            ground._subdivisionsY = options.subdivisionsY || options.subdivisions || 1;
            ground._width = options.width || 1;
            ground._height = options.height || 1;
            ground._maxX = ground._width / 2;
            ground._maxZ = ground._height / 2;
            ground._minX = -ground._maxX;
            ground._minZ = -ground._maxZ;

            var vertexData: VertexData = VertexData.CreateGround(options);

            vertexData.applyToMesh(ground, options.updatable);

            ground._setReady(true);

            return ground;
        }
    }
}
