/**
 * Created by caijingxiao on 2016/12/29.
 */
package babylon.mesh {
    import babylon.Scene;
    import babylon.math.Matrix;
    import babylon.math.Tmp;
    import babylon.math.Vector2;
    import babylon.math.Vector3;
    import babylon.math.Vector4;

    public class GroundMesh extends Mesh {
        public var generateOctree: Boolean = false;

        private var _worldInverse: Matrix = new Matrix();
        private var _heightQuads: Vector.<Object>;

        public var _subdivisionsX: Number;
        public var _subdivisionsY: Number;
        public var _width: Number;
        public var _height: Number;
        public var _minX: Number;
        public var _maxX: Number;
        public var _minZ: Number;
        public var _maxZ: Number;

        public function GroundMesh(name: String, scene: Scene) {
            super(name, scene);
        }

        public function getClassName(): String {
            return "GroundMesh";
        }

        public function get subdivisions(): Number {
            return Math.min(this._subdivisionsX, this._subdivisionsY);
        }

        public function get subdivisionsX(): Number {
            return this._subdivisionsX;
        }

        public function get subdivisionsY(): Number {
            return this._subdivisionsY;
        }

        public function optimize(chunksCount: Number, octreeBlocksSize = 32): void {
            this._subdivisionsX = chunksCount;
            this._subdivisionsY = chunksCount;
//            this.subdivide(chunksCount);
//            this.createOrUpdateSubmeshesOctree(octreeBlocksSize);
        }

        /**
         * Returns a height (y) value in the Worl system :
         * the ground altitude at the coordinates (x, z) expressed in the World system.
         * Returns the ground y position if (x, z) are outside the ground surface.
         * Not pertinent if the ground is rotated.
         */
        public function getHeightAtCoordinates(x: Number, z: Number): Number {
            // express x and y in the ground local system
            x -= this.position.x;
            z -= this.position.z;
            x /= this.scaling.x;
            z /= this.scaling.z;
            if (x < this._minX || x > this._maxX || z < this._minZ || z > this._maxZ) {
                return this.position.y;
            }
            if (!this._heightQuads || this._heightQuads.length == 0) {
                this._initHeightQuads();
                this._computeHeightQuads();
            }
            var facet: Vector4 = this._getFacetAt(x, z);
            var y: Number = -(facet.x * x + facet.z * z + facet.w) / facet.y;
            // return y in the World system
            return y * this.scaling.y + this.position.y;
        }

        /**
         * Returns a normalized vector (Vector3) orthogonal to the ground
         * at the ground coordinates (x, z) expressed in the World system.
         * Returns Vector3(0, 1, 0) if (x, z) are outside the ground surface.
         * Not pertinent if the ground is rotated.
         */
        public function getNormalAtCoordinates(x: Number, z: Number): Vector3 {
            var normal: Vector3 = new Vector3(0, 1, 0);
            this.getNormalAtCoordinatesToRef(x, z, normal);
            return normal;
        }

        /**
         * Updates the Vector3 passed a reference with a normalized vector orthogonal to the ground
         * at the ground coordinates (x, z) expressed in the World system.
         * Doesn't uptade the reference Vector3 if (x, z) are outside the ground surface.
         * Not pertinent if the ground is rotated.
         */
        public function getNormalAtCoordinatesToRef(x: Number, z: Number, ref: Vector3): void {
            // express x and y in the ground local system
            x -= this.position.x;
            z -= this.position.z;
            x /= this.scaling.x;
            z /= this.scaling.z;
            if (x < this._minX || x > this._maxX || z < this._minZ || z > this._maxZ) {
                return;
            }
            if (!this._heightQuads || this._heightQuads.length == 0) {
                this._initHeightQuads();
                this._computeHeightQuads();
            }
            var facet: Vector4 = this._getFacetAt(x, z);
            ref.x = facet.x;
            ref.y = facet.y;
            ref.z = facet.z;
        }

        /**
         * Force the heights to be recomputed for getHeightAtCoordinates() or getNormalAtCoordinates()
         * if the ground has been updated.
         * This can be used in the render loop
         */
        public function updateCoordinateHeights(): void {
            if (!this._heightQuads || this._heightQuads.length == 0) {
                this._initHeightQuads();
            }
            this._computeHeightQuads();
        }

        // Returns the element "facet" from the heightQuads array relative to (x, z) local coordinates
        private function _getFacetAt(x: Number, z: Number): Vector4 {
            // retrieve col and row from x, z coordinates in the ground local system
            var subdivisionsX: Number = this._subdivisionsX;
            var subdivisionsY: Number = this._subdivisionsY;
            var col: Number = Math.floor((x + this._maxX) * this._subdivisionsX / this._width);
            var row: Number = Math.floor(-(z + this._maxZ) * this._subdivisionsY / this._height + this._subdivisionsY);
            var quad: Object = this._heightQuads[row * this._subdivisionsX + col];
            var facet: Vector4;
            if (z < quad.slope.x * x + quad.slope.y) {
                facet = quad.facet1;
            } else {
                facet = quad.facet2;
            }
            return facet;
        }

        //  Creates and populates the heightMap array with "facet" elements :
        // a quad is two triangular facets separated by a slope, so a "facet" element is 1 slope + 2 facets
        // slope : Vector2(c, h) = 2D diagonal line equation setting appart two triangular facets in a quad : z = cx + h
        // facet1 : Vector4(a, b, c, d) = first facet 3D plane equation : ax + by + cz + d = 0
        // facet2 :  Vector4(a, b, c, d) = second facet 3D plane equation : ax + by + cz + d = 0
        private function _initHeightQuads(): void {
            var subdivisionsX: Number = this._subdivisionsX;
            var subdivisionsY: Number = this._subdivisionsY;
            this._heightQuads = new <Object>[];
            for (var row: int = 0; row < subdivisionsY; row++) {
                for (var col: int = 0; col < subdivisionsX; col++) {
                    var quad: Object = { slope: Vector2.Zero(), facet1: new Vector4(0, 0, 0, 0), facet2: new Vector4(0, 0, 0, 0) };
                    this._heightQuads[row * subdivisionsX + col] = quad;
                }
            }
        }

        // Compute each quad element values and update the the heightMap array :
        // slope : Vector2(c, h) = 2D diagonal line equation setting appart two triangular facets in a quad : z = cx + h
        // facet1 : Vector4(a, b, c, d) = first facet 3D plane equation : ax + by + cz + d = 0
        // facet2 :  Vector4(a, b, c, d) = second facet 3D plane equation : ax + by + cz + d = 0
        private function _computeHeightQuads(): void {
            var positions: Vector.<Number> = this.getVerticesData(VertexBuffer.PositionKind);
            var v1: Vector3 = Tmp.VECTOR3[3];
            var v2: Vector3 = Tmp.VECTOR3[2];
            var v3: Vector3 = Tmp.VECTOR3[1];
            var v4: Vector3 = Tmp.VECTOR3[0];
            var v1v2: Vector3 = Tmp.VECTOR3[4];
            var v1v3: Vector3 = Tmp.VECTOR3[5];
            var v1v4: Vector3 = Tmp.VECTOR3[6];
            var norm1: Vector3 = Tmp.VECTOR3[7];
            var norm2: Vector3 = Tmp.VECTOR3[8];
            var i: int = 0;
            var j: int = 0;
            var k: int = 0;
            var cd: Number = 0;     // 2D slope coefficient : z = cd * x + h
            var h: Number = 0;
            var d1: Number = 0;     // facet plane equation : ax + by + cz + d = 0
            var d2: Number = 0;

            var subdivisionsX: Number = this._subdivisionsX;
            var subdivisionsY: Number = this._subdivisionsY;

            for (var row: int = 0; row < subdivisionsY; row++) {
                for (var col: int = 0; col < subdivisionsX; col++) {
                    i = col * 3;
                    j = row * (subdivisionsX + 1) * 3;
                    k = (row + 1) * (subdivisionsX + 1) * 3;
                    v1.x = positions[j + i];
                    v1.y = positions[j + i + 1];
                    v1.z = positions[j + i + 2];
                    v2.x = positions[j + i + 3];
                    v2.y = positions[j + i + 4];
                    v2.z = positions[j + i + 5];
                    v3.x = positions[k + i];
                    v3.y = positions[k + i + 1];
                    v3.z = positions[k + i + 2];
                    v4.x = positions[k + i + 3];
                    v4.y = positions[k + i + 4];
                    v4.z = positions[k + i + 5];

                    // 2D slope V1V4
                    cd = (v4.z - v1.z) / (v4.x - v1.x);
                    h = v1.z - cd * v1.x;             // v1 belongs to the slope

                    // facet equations :
                    // we compute each facet normal vector
                    // the equation of the facet plane is : norm.x * x + norm.y * y + norm.z * z + d = 0
                    // we compute the value d by applying the equation to v1 which belongs to the plane
                    // then we store the facet equation in a Vector4
                    v2.subtractToRef(v1, v1v2);
                    v3.subtractToRef(v1, v1v3);
                    v4.subtractToRef(v1, v1v4);
                    Vector3.CrossToRef(v1v4, v1v3, norm1);  // caution : CrossToRef uses the Tmp class
                    Vector3.CrossToRef(v1v2, v1v4, norm2);
                    norm1.normalize();
                    norm2.normalize();
                    d1 = -(norm1.x * v1.x + norm1.y * v1.y + norm1.z * v1.z);
                    d2 = -(norm2.x * v2.x + norm2.y * v2.y + norm2.z * v2.z);

                    var quad: Object = this._heightQuads[row * subdivisionsX + col];
                    quad.slope.copyFromFloats(cd, h);
                    quad.facet1.copyFromFloats(norm1.x, norm1.y, norm1.z, d1);
                    quad.facet2.copyFromFloats(norm2.x, norm2.y, norm2.z, d2);
                }
            }
        }
    }
}
