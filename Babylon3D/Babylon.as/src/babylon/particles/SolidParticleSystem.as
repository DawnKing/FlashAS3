/**
 * Created by caijingxiao on 2016/11/29.
 */
package babylon.particles {
    import babylon.Scene;
    import babylon.cameras.TargetCamera;
    import babylon.culling.BoundingBox;
    import babylon.culling.BoundingInfo;
    import babylon.culling.BoundingSphere;
    import babylon.math.Color4;
    import babylon.math.Matrix;
    import babylon.math.Quaternion;
    import babylon.math.Tmp;
    import babylon.math.Vector3;
    import babylon.math.Vector4;
    import babylon.mesh.Mesh;
    import babylon.mesh.MeshBuilder;
    import babylon.mesh.VertexBuffer;
    import babylon.mesh.VertexData;

    public class SolidParticleSystem {
        // public members
        /**
         *  The SPS array of Solid Particle objects. Just access each particle as with Object classic array.
         *  Example : var p = SPS.particles[i];
         */
        public var particles: Vector.<SolidParticle> =  new <SolidParticle>[];
        /**
         * The SPS total Number of particles. Read only. Use SPS.counter instead if you need to set your own value.
         */
        public var nbParticles: int = 0;
        /**
         * If the particles must ever face the camera (default false). Useful for planar particles.
         */
        public var billboard: Boolean = false;
        /**
         * Recompute normals when adding a shape
         */
        public var recomputeNormals: Boolean = true;
        /**
         * This a counter ofr your own usage. It's not set by Object SPS functions.
         */
        public var counter: Number = 0;
        /**
         * The SPS name. This name is also given to the underlying mesh.
         */
        public var name: String;
        /**
         * The SPS mesh. It's a standard BJS Mesh, so all the methods from the Mesh class are avalaible.
         */
        public var mesh: Mesh;
        /**
         * This empty object is intended to store some SPS specific or temporary values in order to lower the Garbage Collector activity.
         * Please read : http://doc.babylonjs.com/overviews/Solid_Particle_System#garbage-collector-concerns
         */
        public var vars: Object = {};
        /**
         * This array is populated when the SPS is set as 'pickable'.
         * Each key of this array is a `faceId` value that you can get from a pickResult object.
         * Each element of this array is an object `{idx: int, faceId: int}`.
         * `idx` is the picked particle index in the `SPS.particles` array
         * `faceId` is the picked face index counted within this particle.
         * Please read : http://doc.babylonjs.com/overviews/Solid_Particle_System#pickable-particles
         */
        public var pickedParticles: Vector.<Object> = new <Object>[];  // { idx: Number; faceId: Number }[];

        // private members
        private var _scene: Scene;
        private var _positions: Vector.<Number> = new <Number>[];
        private var _indices: Vector.<uint> = new <uint>[];
        private var _normals: Vector.<Number> = new <Number>[];
        private var _colors: Vector.<Number> = new <Number>[];
        private var _uvs: Vector.<Number> = new <Number>[];
        private var _positions32: Vector.<Number>;
        private var _normals32: Vector.<Number>;           // updated normals for the VBO
        private var _fixedNormal32: Vector.<Number>;       // initial normal references
        private var _colors32: Vector.<Number>;
        private var _uvs32: Vector.<Number>;
        private var _index: Number = 0;  // indices index
        private var _updatable: Boolean = true;
        private var _pickable: Boolean = false;
        private var _isVisibilityBoxLocked: Boolean = false;
        private var _alwaysVisible: Boolean = false;
        private var _shapeCounter: Number = 0;
        private var _copy: SolidParticle = new SolidParticle(-1, -1, null, -1, -1, null);
        private var _shape: Vector.<Vector3>;
        private var _shapeUV: Vector.<Number>;
        private var _color: Color4 = new Color4(0, 0, 0, 0);
        private var _computeParticleColor: Boolean = true;
        private var _computeParticleTexture: Boolean = true;
        private var _computeParticleRotation: Boolean = true;
        private var _computeParticleVertex: Boolean = false;
        private var _computeBoundingBox: Boolean = false;
        private var _cam_axisZ: Vector3 = Vector3.Zero();
        private var _cam_axisY: Vector3 = Vector3.Zero();
        private var _cam_axisX: Vector3 = Vector3.Zero();
        private var _axisX: Vector3 = Vector3.X_AXIS;
        private var _camera: TargetCamera;
        private var _particle: SolidParticle;
        private var _camDir: Vector3 = Vector3.Zero();
        private var _rotMatrix: Matrix = new Matrix();
        private var _invertMatrix: Matrix = new Matrix();
        private var _rotated: Vector3 = Vector3.Zero();
        private var _quaternion: Quaternion = new Quaternion();
        private var _vertex: Vector3 = Vector3.Zero();
        private var _normal: Vector3 = Vector3.Zero();
        private var _yaw: Number = 0.0;
        private var _pitch: Number = 0.0;
        private var _roll: Number = 0.0;
        private var _halfroll: Number = 0.0;
        private var _halfpitch: Number = 0.0;
        private var _halfyaw: Number = 0.0;
        private var _sinRoll: Number = 0.0;
        private var _cosRoll: Number = 0.0;
        private var _sinPitch: Number = 0.0;
        private var _cosPitch: Number = 0.0;
        private var _sinYaw: Number = 0.0;
        private var _cosYaw: Number = 0.0;
        private var _w: Number = 0.0;
        private var _minimum: Vector3 = Tmp.VECTOR3[0];
        private var _maximum: Vector3 = Tmp.VECTOR3[1];
        private var _scale: Vector3 = Tmp.VECTOR3[2];
        private var _translation: Vector3 = Tmp.VECTOR3[3];
        private var _minBbox: Vector3 = Tmp.VECTOR3[4];
        private var _maxBbox: Vector3 = Tmp.VECTOR3[5];
        private var _particlesIntersect: Boolean = false;
        public var _bSphereOnly: Boolean = false;
        public var _bSphereRadiusFactor: Number = 1.0;

        /**
         * Creates a SPS (Solid Particle System) object.
         * `name` (String) is the SPS name, this will be the underlying mesh name.
         * `scene` (Scene) is the scene in which the SPS is added.
         * `updatable` (optional Boolean, default true) : if the SPS must be updatable or immutable.
         * `isPickable` (optional Boolean, default false) : if the solid particles must be pickable.
         * `particleIntersection` (optional Boolean, default false) : if the solid particle intersections must be computed.
         * `boundingSphereOnly` (optional Boolean, default false) : if the particle intersection must be computed only with the bounding sphere (no bounding box computation, so faster).
         * `bSphereRadiusFactor` (optional float, default 1.0) : a Number to multiply the boundind sphere radius by in order to reduce it for instance.
         *  Example : bSphereRadiusFactor = 1.0 / Math.sqrt(3.0) => the bounding sphere exactly matches a spherical mesh.
         */
        public function SolidParticleSystem(name: String, scene: Scene, options: Object = null) {
            this.name = name;
            this._scene = scene;
            this._camera = scene.activeCamera as TargetCamera;
            this._pickable = options ? options.isPickable : false;
            this._particlesIntersect = options ? options.particleIntersection : false;
            this._bSphereOnly= options ? options.boundingSphereOnly : false;
            this._bSphereRadiusFactor = (options && options.bSphereRadiusFactor) ? options.bSphereRadiusFactor : 1.0;
            if (options && options.updatable) {
                this._updatable = options.updatable;
            } else {
                this._updatable = true;
            }
            if (this._pickable) {
                this.pickedParticles = new <Object>[];
            }
        }

        /**
         * Builds the SPS underlying mesh. Returns a standard Mesh.
         * If no model shape was added to the SPS, the returned mesh is just a single triangular plane.
         */
        public function buildMesh(): Mesh {
            if (this.nbParticles === 0) {
                var triangle: Mesh = MeshBuilder.CreateDisc("", { radius: 1, tessellation: 3 }, this._scene);
                this.addShape(triangle, 1);
                triangle.dispose();
            }
            this._positions32 = this._positions.slice();
            this._uvs32 = this._uvs.slice();
            this._colors32 = this._colors.slice();
            if (this.recomputeNormals) {
                VertexData.ComputeNormals(this._positions32, this._indices, this._normals);
            }
            this._normals32 = this._normals.slice();
            this._fixedNormal32 = this._normals.slice();
            var vertexData: VertexData = new VertexData();
            vertexData.set(this._positions32, VertexBuffer.PositionKind);
            vertexData.indices = this._indices.slice();
            vertexData.set(this._normals32, VertexBuffer.NormalKind);
            if (this._uvs32) {
                vertexData.set(this._uvs32, VertexBuffer.UVKind);
            }
            if (this._colors32) {
                vertexData.set(this._colors32, VertexBuffer.ColorKind);
            }
            var mesh: Mesh = new Mesh(this.name, this._scene);
            vertexData.applyToMesh(mesh, this._updatable);
            this.mesh = mesh;
            this.mesh.isPickable = this._pickable;

            // free memory
            this._positions = null;
            this._normals = null;
            this._uvs = null;
            this._colors = null;

            if (!this._updatable) {
                this.particles.length = 0;
            }

            return mesh;
        }

        /**
         * Digests the mesh and generates as many solid particles in the system as wanted. Returns the SPS.
         * These particles will have the same geometry than the mesh parts and will be positioned at the same localisation than the mesh original places.
         * Thus the particles generated from `digest()` have their property `position` set yet.
         * `mesh` ( Mesh ) is the mesh to be digested
         * `facetNb` (optional integer, default 1) is the Number of mesh facets per particle, this parameter is overriden by the parameter `Number` if Object
         * `delta` (optional integer, default 0) is the random extra Number of facets per particle , each particle will have between `facetNb` and `facetNb + delta` facets
         * `Number` (optional positive integer) is the wanted Number of particles : each particle is built with `mesh_total_facets / Number` facets
         */
        public function digest(mesh: Mesh, options: Object = null): SolidParticleSystem {
            var size: Number = 1, number: Number, delta: Number = 0;

            if (options != null) {
                if (options.facetNb) {
                    size = options.facetNb;
                }
                if (options.number) {
                    number = options.number;
                }
                if (options.delta) {
                    delta = options.delta;
                }
            }
            var meshPos: Vector.<Number> = mesh.getVerticesData(VertexBuffer.PositionKind);
            var meshInd: Vector.<uint> = mesh.getIndices();
            var meshUV: Vector.<Number> = mesh.getVerticesData(VertexBuffer.UVKind);
            var meshCol: Vector.<Number> = mesh.getVerticesData(VertexBuffer.ColorKind);
            var meshNor: Vector.<Number> = mesh.getVerticesData(VertexBuffer.NormalKind);

            var f: Number = 0;                              // facet counter
            var totalFacets: Number = meshInd.length / 3;   // a facet is a triangle, so 3 indices
            // compute size from Number
            if (number) {
                number = (number > totalFacets) ? totalFacets : number;
                size = Math.round(totalFacets / number);
                delta = 0;
            } else {
                size = (size > totalFacets) ? totalFacets : size;
            }

            var facetPos: Vector.<Number> = new <Number>[];      // submesh positions
            var facetInd: Vector.<uint> = new <uint>[];      // submesh indices
            var facetUV: Vector.<Number> = new <Number>[];       // submesh UV
            var facetCol: Vector.<Number> = new <Number>[];      // submesh colors
            var barycenter: Vector3 = Tmp.VECTOR3[0];
            var sizeO: Number = size;

            while (f < totalFacets) {
                size = sizeO + Math.floor((1 + delta) * Math.random());
                if (f > totalFacets - size) {
                    size = totalFacets - f;
                }
                // reset temp arrays
                facetPos.length = 0;
                facetInd.length = 0;
                facetUV.length = 0;
                facetCol.length = 0;

                // iterate over "size" facets
                var fi: uint = 0;
                for (var j: int = f * 3; j < (f + size) * 3; j++) {
                    facetInd.push(fi);
                    var i: uint = meshInd[j];
                    facetPos.push(meshPos[i * 3], meshPos[i * 3 + 1], meshPos[i * 3 + 2]);
                    if (meshUV) {
                        facetUV.push(meshUV[i * 2], meshUV[i * 2 + 1]);
                    }
                    if (meshCol) {
                        facetCol.push(meshCol[i * 4], meshCol[i * 4 + 1], meshCol[i * 4 + 2], meshCol[i * 4 + 3]);
                    }
                    fi++;
                }

                // create a model shape for each single particle
                var idx: int = this.nbParticles;
                var shape: Vector.<Vector3> = this._posToShape(facetPos);
                var shapeUV: Vector.<Number> = this._uvsToShapeUV(facetUV);

                // compute the barycenter of the shape
                var v: int;
                for (v = 0; v < shape.length; v++) {
                    barycenter.addInPlace(shape[v]);
                }
                barycenter.scaleInPlace(1 / shape.length);

                // shift the shape from its barycenter to the origin
                for (v = 0; v < shape.length; v++) {
                    shape[v].subtractInPlace(barycenter);
                }
                var bInfo: BoundingInfo;
                if (this._particlesIntersect) {
                    bInfo = new BoundingInfo(barycenter, barycenter);
                }
                var modelShape: ModelShape = new ModelShape(this._shapeCounter, shape, shapeUV, null, null);

                // add the particle in the SPS
                this._meshBuilder(this._index, shape, this._positions, facetInd, this._indices, facetUV, this._uvs, facetCol, this._colors, meshNor, this._normals, idx, 0, null);
                this._addParticle(idx, this._positions.length, modelShape, this._shapeCounter, 0, bInfo);
                // initialize the particle position
                this.particles[this.nbParticles].position.addInPlace(barycenter);

                this._index += shape.length;
                idx++;
                this.nbParticles++;
                this._shapeCounter++;
                f += size;
            }
            return this;
        }

        //reset copy
        private function _resetCopy(): void {
            this._copy.position.x = 0;
            this._copy.position.y = 0;
            this._copy.position.z = 0;
            this._copy.rotation.x = 0;
            this._copy.rotation.y = 0;
            this._copy.rotation.z = 0;
            this._copy.rotationQuaternion = null;
            this._copy.scaling.x = 1;
            this._copy.scaling.y = 1;
            this._copy.scaling.z = 1;
            this._copy.uvs.x = 0;
            this._copy.uvs.y = 0;
            this._copy.uvs.z = 1;
            this._copy.uvs.w = 1;
            this._copy.color = null;
        }

        // _meshBuilder : inserts the shape model in the global SPS mesh
        private function _meshBuilder(p: int, shape: Vector.<Vector3>, positions: Vector.<Number>, meshInd: Vector.<uint>, indices: Vector.<uint>, meshUV: Vector.<Number>, uvs: Vector.<Number>, meshCol: Vector.<Number>, colors: Vector.<Number>, meshNor: Vector.<Number>, normals: Vector.<Number>, idx: int, idxInShape: int, options: Object): void {
            var i: int;
            var u: int = 0;
            var c: int = 0;
            var n: int = 0;

            this._resetCopy();
            if (options && options.positionFunction) {        // call to custom positionFunction
                options.positionFunction(this._copy, idx, idxInShape);
            }

            if (this._copy.rotationQuaternion) {
                this._quaternion.copyFrom(this._copy.rotationQuaternion);
            } else {
                this._yaw = this._copy.rotation.y;
                this._pitch = this._copy.rotation.x;
                this._roll = this._copy.rotation.z;
                this._quaternionRotationYPR();
            }
            this._quaternionToRotationMatrix();

            for (i = 0; i < shape.length; i++) {
                this._vertex.x = shape[i].x;
                this._vertex.y = shape[i].y;
                this._vertex.z = shape[i].z;

                if (options && options.vertexFunction) {
                    options.vertexFunction(this._copy, this._vertex, i);
                }

                this._vertex.x *= this._copy.scaling.x;
                this._vertex.y *= this._copy.scaling.y;
                this._vertex.z *= this._copy.scaling.z;

                Vector3.TransformCoordinatesToRef(this._vertex, this._rotMatrix, this._rotated);
                positions.push(this._copy.position.x + this._rotated.x, this._copy.position.y + this._rotated.y, this._copy.position.z + this._rotated.z);
                if (meshUV) {
                    uvs.push((this._copy.uvs.z - this._copy.uvs.x) * meshUV[u] + this._copy.uvs.x, (this._copy.uvs.w - this._copy.uvs.y) * meshUV[u + 1] + this._copy.uvs.y);
                    u += 2;
                }

                if (this._copy.color) {
                    this._color = this._copy.color;
                } else if (meshCol && !isNaN(meshCol[c])) {
                    this._color.r = meshCol[c];
                    this._color.g = meshCol[c + 1];
                    this._color.b = meshCol[c + 2];
                    this._color.a = meshCol[c + 3];
                } else {
                    this._color.r = 1;
                    this._color.g = 1;
                    this._color.b = 1;
                    this._color.a = 1;
                }
                colors.push(this._color.r, this._color.g, this._color.b, this._color.a);
                c += 4;

                if (!this.recomputeNormals && meshNor) {
                    this._normal.x = meshNor[n];
                    this._normal.y = meshNor[n + 1];
                    this._normal.z = meshNor[n + 2];
                    Vector3.TransformCoordinatesToRef(this._normal, this._rotMatrix, this._normal);
                    normals.push(this._normal.x, this._normal.y, this._normal.z);
                    n += 3;
                }

            }

            for (i = 0; i < meshInd.length; i++) {
                indices.push(p + meshInd[i]);
            }

            if (this._pickable) {
                var nbfaces: int = meshInd.length / 3;
                for (i = 0; i < nbfaces; i++) {
                    this.pickedParticles.push({ idx: idx, faceId: i });
                }
            }
        }

        // returns a shape array from positions array
        private function _posToShape(positions: Vector.<Number>): Vector.<Vector3> {
            var shape: Vector.<Vector3> = new <Vector3>[];
            for (var i: int = 0; i < positions.length; i += 3) {
                shape.push(new Vector3(positions[i], positions[i + 1], positions[i + 2]));
            }
            return shape;
        }

        // returns a shapeUV array from a Vector4 uvs
        private function _uvsToShapeUV(uvs: Vector.<Number>): Vector.<Number> {
            var shapeUV: Vector.<Number> = new <Number>[];
            if (uvs) {
                for (var i: int = 0; i < uvs.length; i++)
                    shapeUV.push(uvs[i]);
            }
            return shapeUV;
        }

        // adds a new particle object in the particles array
        private function _addParticle(idx: Number, idxpos: Number, model: ModelShape, shapeId: Number, idxInShape: Number, bInfo: BoundingInfo = null): void {
            this.particles.push(new SolidParticle(idx, idxpos, model, shapeId, idxInShape, this, bInfo));
        }

        /**
         * Adds some particles to the SPS from the model shape. Returns the shape id.
         * Please read the doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#create-an-immutable-sps
         * `mesh` is Object Mesh object that will be used as a model for the solid particles.
         * `nb` (positive integer) the Number of particles to be created from this model
         * `positionFunction` is an optional javascript function to called for each particle on SPS creation.
         * `vertexFunction` is an optional javascript function to called for each vertex of each particle on SPS creation
         */
        public function addShape(mesh: Mesh, nb: Number, options: Object = null): Number {
            var meshPos: Vector.<Number> = mesh.getVerticesData(VertexBuffer.PositionKind);
            var meshInd: Vector.<uint> = mesh.getIndices();
            var meshUV: Vector.<Number> = mesh.getVerticesData(VertexBuffer.UVKind);
            var meshCol: Vector.<Number> = mesh.getVerticesData(VertexBuffer.ColorKind);
            var meshNor: Vector.<Number> = mesh.getVerticesData(VertexBuffer.NormalKind);
            var bbInfo : BoundingInfo;
            if (this._particlesIntersect) {
                bbInfo = mesh.getBoundingInfo();
            }

            var shape: Vector.<Vector3> = this._posToShape(meshPos);
            var shapeUV: Vector.<Number> = this._uvsToShapeUV(meshUV);

            var posfunc: Function = options ? options.positionFunction : null;
            var vtxfunc: Function = options ? options.vertexFunction : null;

            var modelShape: ModelShape = new ModelShape(this._shapeCounter, shape, shapeUV, posfunc, vtxfunc);

            // particles
            var idx: int = this.nbParticles;
            for (var i: int = 0; i < nb; i++) {
                this._meshBuilder(this._index, shape, this._positions, meshInd, this._indices, meshUV, this._uvs, meshCol, this._colors, meshNor, this._normals, idx, i, options);
                if (this._updatable) {
                    this._addParticle(idx, this._positions.length, modelShape, this._shapeCounter, i, bbInfo);
                }
                this._index += shape.length;
                idx++;
            }
            this.nbParticles += nb;
            this._shapeCounter++;
            return this._shapeCounter - 1;
        }

        // rebuilds a particle back to its just built status : if needed, recomputes the custom positions and vertices
        private function _rebuildParticle(particle: SolidParticle): void {
            this._resetCopy();
            if (particle._model._positionFunction) {        // recall to stored custom positionFunction
                particle._model._positionFunction(this._copy, particle.idx, particle.idxInShape);
            }

            if (this._copy.rotationQuaternion) {
                this._quaternion.copyFrom(this._copy.rotationQuaternion);
            } else {
                this._yaw = this._copy.rotation.y;
                this._pitch = this._copy.rotation.x;
                this._roll = this._copy.rotation.z;
                this._quaternionRotationYPR();
            }
            this._quaternionToRotationMatrix();

            this._shape = particle._model._shape;
            for (var pt: int = 0; pt < this._shape.length; pt++) {
                this._vertex.x = this._shape[pt].x;
                this._vertex.y = this._shape[pt].y;
                this._vertex.z = this._shape[pt].z;

                if (particle._model._vertexFunction) {
                    particle._model._vertexFunction(this._copy, this._vertex, pt); // recall to stored vertexFunction
                }

                this._vertex.x *= this._copy.scaling.x;
                this._vertex.y *= this._copy.scaling.y;
                this._vertex.z *= this._copy.scaling.z;

                Vector3.TransformCoordinatesToRef(this._vertex, this._rotMatrix, this._rotated);

                this._positions32[particle._pos + pt * 3] = this._copy.position.x + this._rotated.x;
                this._positions32[particle._pos + pt * 3 + 1] = this._copy.position.y + this._rotated.y;
                this._positions32[particle._pos + pt * 3 + 2] = this._copy.position.z + this._rotated.z;
            }
            particle.position.x = 0.0;
            particle.position.y = 0.0;
            particle.position.z = 0.0;
            particle.rotation.x = 0.0;
            particle.rotation.y = 0.0;
            particle.rotation.z = 0.0;
            particle.rotationQuaternion = null;
            particle.scaling.x = 1.0;
            particle.scaling.y = 1.0;
            particle.scaling.z = 1.0;
        }

        /**
         * Rebuilds the whole mesh and updates the VBO : custom positions and vertices are recomputed if needed.
         */
        public function rebuildMesh(): void {
            for (var p: int = 0; p < this.particles.length; p++) {
                this._rebuildParticle(this.particles[p]);
            }
            this.mesh.updateVerticesData(VertexBuffer.PositionKind, this._positions32, false, false);
        }


        /**
         *  Sets all the particles : this method actually really updates the mesh according to the particle positions, rotations, colors, textures, etc.
         *  This method calls `updateParticle()` for each particle of the SPS.
         *  For an animated SPS, it is usually called within the render loop.
         * @param start The particle index in the particle array where to start to compute the particle property values _(default 0)_
         * @param end The particle index in the particle array where to stop to compute the particle property values _(default nbParticle - 1)_
         * @param update If the mesh must be finally updated on this call after all the particle computations _(default true)_
         */
        public function setParticles(start: Number = 0, end: Number = -1, update: Boolean = true): void {
            if (!this._updatable) {
                return;
            }

            end = end == -1 ? this.nbParticles - 1 : end;

            // custom beforeUpdate
            this.beforeUpdateParticles(start, end, update);

            this._cam_axisX.x = 1.0;
            this._cam_axisX.y = 0.0;
            this._cam_axisX.z = 0.0;

            this._cam_axisY.x = 0.0;
            this._cam_axisY.y = 1.0;
            this._cam_axisY.z = 0.0;

            this._cam_axisZ.x = 0.0;
            this._cam_axisZ.y = 0.0;
            this._cam_axisZ.z = 1.0;

            // if the particles will always face the camera
            if (this.billboard) {
                // compute the camera position and un-rotate it by the current mesh rotation
                if (this.mesh._worldMatrix.decompose(this._scale, this._quaternion, this._translation)) {
                    this._quaternionToRotationMatrix();
                    this._rotMatrix.invertToRef(this._invertMatrix);
                    this._camera._currentTarget.subtractToRef(this._camera.globalPosition, this._camDir);
                    Vector3.TransformCoordinatesToRef(this._camDir, this._invertMatrix, this._cam_axisZ);
                    this._cam_axisZ.normalize();
                    // set two orthogonal vectors (_cam_axisX and and _cam_axisY) to the rotated camDir axis (_cam_axisZ)
                    Vector3.CrossToRef(this._cam_axisZ, this._axisX, this._cam_axisY);
                    Vector3.CrossToRef(this._cam_axisY, this._cam_axisZ, this._cam_axisX);
                    this._cam_axisY.normalize();
                    this._cam_axisX.normalize();
                }
            }

            Matrix.IdentityToRef(this._rotMatrix);
            var idx: int = 0;
            var index: int = 0;
            var colidx: int = 0;
            var colorIndex: int = 0;
            var uvidx: int = 0;
            var uvIndex: int = 0;
            var pt: int = 0;

            if (this._computeBoundingBox) {
                Vector3.FromFloatsToRef(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE, this._minimum);
                Vector3.FromFloatsToRef(-Number.MAX_VALUE, -Number.MAX_VALUE, -Number.MAX_VALUE, this._maximum);
            }

            // particle loop
            end = (end > this.nbParticles - 1) ? this.nbParticles - 1 : end;
            for (var p: int = start; p <= end; p++) {
                this._particle = this.particles[p];
                this._shape = this._particle._model._shape;
                this._shapeUV = this._particle._model._shapeUV;

                // call to custom user function to update the particle properties
                this.updateParticle(this._particle);

                if (this._particle.isVisible) {

                    // particle rotation matrix
                    if (this.billboard) {
                        this._particle.rotation.x = 0.0;
                        this._particle.rotation.y = 0.0;
                    }
                    if (this._computeParticleRotation || this.billboard) {
                        if (this._particle.rotationQuaternion) {
                            this._quaternion.copyFrom(this._particle.rotationQuaternion);
                        } else {
                            this._yaw = this._particle.rotation.y;
                            this._pitch = this._particle.rotation.x;
                            this._roll = this._particle.rotation.z;
                            this._quaternionRotationYPR();
                        }
                        this._quaternionToRotationMatrix();
                    }

                    // particle vertex loop
                    for (pt = 0; pt < this._shape.length; pt++) {
                        idx = index + pt * 3;
                        colidx = colorIndex + pt * 4;
                        uvidx = uvIndex + pt * 2;

                        this._vertex.x = this._shape[pt].x;
                        this._vertex.y = this._shape[pt].y;
                        this._vertex.z = this._shape[pt].z;

                        if (this._computeParticleVertex) {
                            this.updateParticleVertex(this._particle, this._vertex, pt);
                        }

                        // positions
                        this._vertex.x *= this._particle.scaling.x;
                        this._vertex.y *= this._particle.scaling.y;
                        this._vertex.z *= this._particle.scaling.z;

                        this._w = (this._vertex.x * this._rotMatrix.m[3]) + (this._vertex.y * this._rotMatrix.m[7]) + (this._vertex.z * this._rotMatrix.m[11]) + this._rotMatrix.m[15];
                        this._rotated.x = ((this._vertex.x * this._rotMatrix.m[0]) + (this._vertex.y * this._rotMatrix.m[4]) + (this._vertex.z * this._rotMatrix.m[8]) + this._rotMatrix.m[12]) / this._w;
                        this._rotated.y = ((this._vertex.x * this._rotMatrix.m[1]) + (this._vertex.y * this._rotMatrix.m[5]) + (this._vertex.z * this._rotMatrix.m[9]) + this._rotMatrix.m[13]) / this._w;
                        this._rotated.z = ((this._vertex.x * this._rotMatrix.m[2]) + (this._vertex.y * this._rotMatrix.m[6]) + (this._vertex.z * this._rotMatrix.m[10]) + this._rotMatrix.m[14]) / this._w;

                        this._positions32[idx] = this._particle.position.x + this._cam_axisX.x * this._rotated.x + this._cam_axisY.x * this._rotated.y + this._cam_axisZ.x * this._rotated.z;
                        this._positions32[idx + 1] = this._particle.position.y + this._cam_axisX.y * this._rotated.x + this._cam_axisY.y * this._rotated.y + this._cam_axisZ.y * this._rotated.z;
                        this._positions32[idx + 2] = this._particle.position.z + this._cam_axisX.z * this._rotated.x + this._cam_axisY.z * this._rotated.y + this._cam_axisZ.z * this._rotated.z;

                        if (this._computeBoundingBox) {
                            if (this._positions32[idx] < this._minimum.x) {
                                this._minimum.x = this._positions32[idx];
                            }
                            if (this._positions32[idx] > this._maximum.x) {
                                this._maximum.x = this._positions32[idx];
                            }
                            if (this._positions32[idx + 1] < this._minimum.y) {
                                this._minimum.y = this._positions32[idx + 1];
                            }
                            if (this._positions32[idx + 1] > this._maximum.y) {
                                this._maximum.y = this._positions32[idx + 1];
                            }
                            if (this._positions32[idx + 2] < this._minimum.z) {
                                this._minimum.z = this._positions32[idx + 2];
                            }
                            if (this._positions32[idx + 2] > this._maximum.z) {
                                this._maximum.z = this._positions32[idx + 2];
                            }
                        }

                        // normals : if the particles can't be morphed then just rotate the normals, what if much more faster than ComputeNormals()
                        if (!this._computeParticleVertex) {
                            this._normal.x = this._fixedNormal32[idx];
                            this._normal.y = this._fixedNormal32[idx + 1];
                            this._normal.z = this._fixedNormal32[idx + 2];

                            this._w = (this._normal.x * this._rotMatrix.m[3]) + (this._normal.y * this._rotMatrix.m[7]) + (this._normal.z * this._rotMatrix.m[11]) + this._rotMatrix.m[15];
                            this._rotated.x = ((this._normal.x * this._rotMatrix.m[0]) + (this._normal.y * this._rotMatrix.m[4]) + (this._normal.z * this._rotMatrix.m[8]) + this._rotMatrix.m[12]) / this._w;
                            this._rotated.y = ((this._normal.x * this._rotMatrix.m[1]) + (this._normal.y * this._rotMatrix.m[5]) + (this._normal.z * this._rotMatrix.m[9]) + this._rotMatrix.m[13]) / this._w;
                            this._rotated.z = ((this._normal.x * this._rotMatrix.m[2]) + (this._normal.y * this._rotMatrix.m[6]) + (this._normal.z * this._rotMatrix.m[10]) + this._rotMatrix.m[14]) / this._w;

                            this._normals32[idx] = this._cam_axisX.x * this._rotated.x + this._cam_axisY.x * this._rotated.y + this._cam_axisZ.x * this._rotated.z;
                            this._normals32[idx + 1] = this._cam_axisX.y * this._rotated.x + this._cam_axisY.y * this._rotated.y + this._cam_axisZ.y * this._rotated.z;
                            this._normals32[idx + 2] = this._cam_axisX.z * this._rotated.x + this._cam_axisY.z * this._rotated.y + this._cam_axisZ.z * this._rotated.z;
                        }

                        if (this._computeParticleColor) {
                            this._colors32[colidx] = this._particle.color.r;
                            this._colors32[colidx + 1] = this._particle.color.g;
                            this._colors32[colidx + 2] = this._particle.color.b;
                            this._colors32[colidx + 3] = this._particle.color.a;
                        }

                        if (this._computeParticleTexture) {
                            this._uvs32[uvidx] = this._shapeUV[pt * 2] * (this._particle.uvs.z - this._particle.uvs.x) + this._particle.uvs.x;
                            this._uvs32[uvidx + 1] = this._shapeUV[pt * 2 + 1] * (this._particle.uvs.w - this._particle.uvs.y) + this._particle.uvs.y;
                        }
                    }
                }
                // particle not visible : scaled to zero and positioned to the camera position
                else {
                    for (pt = 0; pt < this._shape.length; pt++) {
                        idx = index + pt * 3;
                        colidx = colorIndex + pt * 4;
                        uvidx = uvIndex + pt * 2;
                        this._positions32[idx] = this._camera.position.x;
                        this._positions32[idx + 1] = this._camera.position.y;
                        this._positions32[idx + 2] = this._camera.position.z;
                        this._normals32[idx] = 0.0;
                        this._normals32[idx + 1] = 0.0;
                        this._normals32[idx + 2] = 0.0;
                        if (this._computeParticleColor) {
                            this._colors32[colidx] = this._particle.color.r;
                            this._colors32[colidx + 1] = this._particle.color.g;
                            this._colors32[colidx + 2] = this._particle.color.b;
                            this._colors32[colidx + 3] = this._particle.color.a;
                        }
                        if (this._computeParticleTexture) {
                            this._uvs32[uvidx] = this._shapeUV[pt * 2] * (this._particle.uvs.z - this._particle.uvs.x) + this._particle.uvs.x;
                            this._uvs32[uvidx + 1] = this._shapeUV[pt * 2 + 1] * (this._particle.uvs.w - this._particle.uvs.y) + this._particle.uvs.y;
                        }
                    }
                }

                // if the particle intersections must be computed : update the bbInfo
                if (this._particlesIntersect) {
                    var bInfo: BoundingInfo = this._particle._boundingInfo;
                    var bBox: BoundingBox = bInfo.boundingBox;
                    var bSphere: BoundingSphere = bInfo.boundingSphere;
                    if (!this._bSphereOnly) {
                        // place, scale and rotate the particle bbox within the SPS local system, then update it
                        for (var b: int = 0; b < bBox.vectors.length; b++) {
                            this._vertex.x = this._particle._modelBoundingInfo.boundingBox.vectors[b].x * this._particle.scaling.x;
                            this._vertex.y = this._particle._modelBoundingInfo.boundingBox.vectors[b].y * this._particle.scaling.y;
                            this._vertex.z = this._particle._modelBoundingInfo.boundingBox.vectors[b].z * this._particle.scaling.z;
                            this._w = (this._vertex.x * this._rotMatrix.m[3]) + (this._vertex.y * this._rotMatrix.m[7]) + (this._vertex.z * this._rotMatrix.m[11]) + this._rotMatrix.m[15];
                            this._rotated.x = ((this._vertex.x * this._rotMatrix.m[0]) + (this._vertex.y * this._rotMatrix.m[4]) + (this._vertex.z * this._rotMatrix.m[8]) + this._rotMatrix.m[12]) / this._w;
                            this._rotated.y = ((this._vertex.x * this._rotMatrix.m[1]) + (this._vertex.y * this._rotMatrix.m[5]) + (this._vertex.z * this._rotMatrix.m[9]) + this._rotMatrix.m[13]) / this._w;
                            this._rotated.z = ((this._vertex.x * this._rotMatrix.m[2]) + (this._vertex.y * this._rotMatrix.m[6]) + (this._vertex.z * this._rotMatrix.m[10]) + this._rotMatrix.m[14]) / this._w;
                            bBox.vectors[b].x = this._particle.position.x + this._cam_axisX.x * this._rotated.x + this._cam_axisY.x * this._rotated.y + this._cam_axisZ.x * this._rotated.z;
                            bBox.vectors[b].y = this._particle.position.y + this._cam_axisX.y * this._rotated.x + this._cam_axisY.y * this._rotated.y + this._cam_axisZ.y * this._rotated.z;
                            bBox.vectors[b].z = this._particle.position.z + this._cam_axisX.z * this._rotated.x + this._cam_axisY.z * this._rotated.y + this._cam_axisZ.z * this._rotated.z;
                        }
                        bBox._update(this.mesh._worldMatrix);
                    }
                    // place and scale the particle bouding sphere in the SPS local system, then update it
                    this._minBbox.x = this._particle._modelBoundingInfo.minimum.x * this._particle.scaling.x;
                    this._minBbox.y = this._particle._modelBoundingInfo.minimum.y * this._particle.scaling.y;
                    this._minBbox.z = this._particle._modelBoundingInfo.minimum.z * this._particle.scaling.z;
                    this._maxBbox.x = this._particle._modelBoundingInfo.maximum.x * this._particle.scaling.x;
                    this._maxBbox.y = this._particle._modelBoundingInfo.maximum.y * this._particle.scaling.y;
                    this._maxBbox.z = this._particle._modelBoundingInfo.maximum.z * this._particle.scaling.z;
                    bSphere.center.x = this._particle.position.x + (this._minBbox.x + this._maxBbox.x) * 0.5;
                    bSphere.center.y = this._particle.position.y + (this._minBbox.y + this._maxBbox.y) * 0.5;
                    bSphere.center.z = this._particle.position.z + (this._minBbox.z + this._maxBbox.z) * 0.5;
                    bSphere.radius = this._bSphereRadiusFactor * 0.5 * Math.sqrt((this._maxBbox.x - this._minBbox.x) * (this._maxBbox.x - this._minBbox.x) + (this._maxBbox.y - this._minBbox.y) * (this._maxBbox.y - this._minBbox.y) + (this._maxBbox.z - this._minBbox.z) * (this._maxBbox.z - this._minBbox.z));
                    bSphere._update(this.mesh._worldMatrix);
                }

                // increment indexes for the next particle
                index = idx + 3;
                colorIndex = colidx + 4;
                uvIndex = uvidx + 2;
            }

            // if the VBO must be updated
            if (update) {
                if (this._computeParticleColor) {
                    this.mesh.updateVerticesData(VertexBuffer.ColorKind, this._colors32, false, false);
                }
                if (this._computeParticleTexture) {
                    this.mesh.updateVerticesData(VertexBuffer.UVKind, this._uvs32, false, false);
                }
                this.mesh.updateVerticesData(VertexBuffer.PositionKind, this._positions32, false, false);
                if (!this.mesh.areNormalsFrozen) {
                    if (this._computeParticleVertex) {
                        // recompute the normals only if the particles can be morphed, update then also the normal reference array _fixedNormal32[]
                        VertexData.ComputeNormals(this._positions32, this._indices, this._normals32);
                        for (var i: int = 0; i < this._normals32.length; i++) {
                            this._fixedNormal32[i] = this._normals32[i];
                        }
                    }
                    this.mesh.updateVerticesData(VertexBuffer.NormalKind, this._normals32, false, false);
                }
            }
            if (this._computeBoundingBox) {
                this.mesh._boundingInfo = new BoundingInfo(this._minimum, this._maximum);
                this.mesh._boundingInfo.update(this.mesh._worldMatrix);
            }
            this.afterUpdateParticles(start, end, update);
        }

        private function _quaternionRotationYPR(): void {
            this._halfroll = this._roll * 0.5;
            this._halfpitch = this._pitch * 0.5;
            this._halfyaw = this._yaw * 0.5;
            this._sinRoll = Math.sin(this._halfroll);
            this._cosRoll = Math.cos(this._halfroll);
            this._sinPitch = Math.sin(this._halfpitch);
            this._cosPitch = Math.cos(this._halfpitch);
            this._sinYaw = Math.sin(this._halfyaw);
            this._cosYaw = Math.cos(this._halfyaw);
            this._quaternion.x = (this._cosYaw * this._sinPitch * this._cosRoll) + (this._sinYaw * this._cosPitch * this._sinRoll);
            this._quaternion.y = (this._sinYaw * this._cosPitch * this._cosRoll) - (this._cosYaw * this._sinPitch * this._sinRoll);
            this._quaternion.z = (this._cosYaw * this._cosPitch * this._sinRoll) - (this._sinYaw * this._sinPitch * this._cosRoll);
            this._quaternion.w = (this._cosYaw * this._cosPitch * this._cosRoll) + (this._sinYaw * this._sinPitch * this._sinRoll);
        }

        private function _quaternionToRotationMatrix(): void {
            this._rotMatrix.m[0] = 1.0 - (2.0 * (this._quaternion.y * this._quaternion.y + this._quaternion.z * this._quaternion.z));
            this._rotMatrix.m[1] = 2.0 * (this._quaternion.x * this._quaternion.y + this._quaternion.z * this._quaternion.w);
            this._rotMatrix.m[2] = 2.0 * (this._quaternion.z * this._quaternion.x - this._quaternion.y * this._quaternion.w);
            this._rotMatrix.m[3] = 0;
            this._rotMatrix.m[4] = 2.0 * (this._quaternion.x * this._quaternion.y - this._quaternion.z * this._quaternion.w);
            this._rotMatrix.m[5] = 1.0 - (2.0 * (this._quaternion.z * this._quaternion.z + this._quaternion.x * this._quaternion.x));
            this._rotMatrix.m[6] = 2.0 * (this._quaternion.y * this._quaternion.z + this._quaternion.x * this._quaternion.w);
            this._rotMatrix.m[7] = 0;
            this._rotMatrix.m[8] = 2.0 * (this._quaternion.z * this._quaternion.x + this._quaternion.y * this._quaternion.w);
            this._rotMatrix.m[9] = 2.0 * (this._quaternion.y * this._quaternion.z - this._quaternion.x * this._quaternion.w);
            this._rotMatrix.m[10] = 1.0 - (2.0 * (this._quaternion.y * this._quaternion.y + this._quaternion.x * this._quaternion.x));
            this._rotMatrix.m[11] = 0;
            this._rotMatrix.m[12] = 0;
            this._rotMatrix.m[13] = 0;
            this._rotMatrix.m[14] = 0;
            this._rotMatrix.m[15] = 1.0;
        }

        /**
         * Disposes the SPS
         */
        public function dispose(): void {
            this.mesh.dispose();
            this.vars = null;
            // drop references to internal big arrays for the GC
            this._positions = null;
            this._indices = null;
            this._normals = null;
            this._uvs = null;
            this._colors = null;
            this._positions32 = null;
            this._normals32 = null;
            this._fixedNormal32 = null;
            this._uvs32 = null;
            this._colors32 = null;
            this.pickedParticles = null;
        }

        /**
         * Visibilty helper : Recomputes the visible size according to the mesh bounding box
         * doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#sps-visibility
         */
        public function refreshVisibleSize(): void {
            if (!this._isVisibilityBoxLocked) {
                this.mesh.refreshBoundingInfo();
            }
        }

        /**
         * Visibility helper : Sets the size of a visibility box, this sets the underlying mesh bounding box.
         * @param size the size (float) of the visibility box
         * note : this doesn't lock the SPS mesh bounding box.
         * doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#sps-visibility
         */
        public function setVisibilityBox(size: Number): void {
            var vis: Number = size / 2;
            this.mesh._boundingInfo = new BoundingInfo(new Vector3(-vis, -vis, -vis), new Vector3(vis, vis, vis));
        }


        // getter and setter
        public function get isAlwaysVisible(): Boolean {
            return this._alwaysVisible;
        }

        /**
         * Sets the SPS as always visible or not
         * doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#sps-visibility
         */
        public function set isAlwaysVisible(val: Boolean): void {
            this._alwaysVisible = val;
            this.mesh.alwaysSelectAsActiveMesh = val;
        }

        /**
         * Sets the SPS visibility box as locked or not. This enables/disables the underlying mesh bounding box updates.
         * doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#sps-visibility
         */
        public function set isVisibilityBoxLocked(val: Boolean): void {
            this._isVisibilityBoxLocked = val;
            this.mesh.getBoundingInfo().isLocked = val;
        }

        public function get isVisibilityBoxLocked(): Boolean {
            return this._isVisibilityBoxLocked;
        }

        // Optimizer setters
        /**
         * Tells to `setParticles()` to compute the particle rotations or not.
         * Default value : true. The SPS is faster when it's set to false.
         * Note : the particle rotations aren't stored values, so setting `computeParticleRotation` to false will prevents the particle to rotate.
         */
        public function set computeParticleRotation(val: Boolean): void {
            this._computeParticleRotation = val;
        }
        /**
         * Tells to `setParticles()` to compute the particle colors or not.
         * Default value : true. The SPS is faster when it's set to false.
         * Note : the particle colors are stored values, so setting `computeParticleColor` to false will keep yet the last colors set.
         */
        public function set computeParticleColor(val: Boolean): void {
            this._computeParticleColor = val;
        }
        /**
         * Tells to `setParticles()` to compute the particle textures or not.
         * Default value : true. The SPS is faster when it's set to false.
         * Note : the particle textures are stored values, so setting `computeParticleTexture` to false will keep yet the last colors set.
         */
        public function set computeParticleTexture(val: Boolean): void {
            this._computeParticleTexture = val;
        }
        /**
         * Tells to `setParticles()` to call the vertex function for each vertex of each particle, or not.
         * Default value : false. The SPS is faster when it's set to false.
         * Note : the particle custom vertex positions aren't stored values.
         */
        public function set computeParticleVertex(val: Boolean): void {
            this._computeParticleVertex = val;
        }
        /**
         * Tells to `setParticles()` to compute or not the mesh bounding box when computing the particle positions.
         */
        public function set computeBoundingBox(val: Boolean): void {
            this._computeBoundingBox = val;
        }

        // getters
        public function get computeParticleRotation(): Boolean {
            return this._computeParticleRotation;
        }

        public function get computeParticleColor(): Boolean {
            return this._computeParticleColor;
        }

        public function get computeParticleTexture(): Boolean {
            return this._computeParticleTexture;
        }

        public function get computeParticleVertex(): Boolean {
            return this._computeParticleVertex;
        }

        public function get computeBoundingBox(): Boolean {
            return this._computeBoundingBox;
        }

        // =======================================================================
        // Particle behavior logic
        // these following methods may be overwritten by the user to fit his needs


        /**
         * This function does nothing. It may be overwritten to set all the particle first values.
         * The SPS doesn't call this function, you may have to call it by your own.
         * doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#particle-management
         */
        public var initParticles: Function;
//        public function initParticles(): void {
//        }

        /**
         * This function does nothing. It may be overwritten to recycle a particle.
         * The SPS doesn't call this function, you may have to call it by your own.
         * doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#particle-management
         */
        public var recycleParticle: Function;
//        public function recycleParticle(particle: SolidParticle): SolidParticle {
//            return particle;
//        }

        /**
         * Updates a particle : this function should  be overwritten by the user.
         * It is called on each particle by `setParticles()`. This is the place to code each particle behavior.
         * doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#particle-management
         * ex : just set a particle position or velocity and recycle conditions
         */
        public var updateParticle: Function;
//        public function updateParticle(particle: SolidParticle): SolidParticle {
//            return particle;
//        }

        /**
         * Updates a vertex of a particle : it can be overwritten by the user.
         * This will be called on each vertex particle by `setParticles()` if `computeParticleVertex` is set to true only.
         * @param particle the current particle
         * @param vertex the current index of the current particle
         * @param pt the index of the current vertex in the particle shape
         * doc : http://doc.babylonjs.com/overviews/Solid_Particle_System#update-each-particle-shape
         * ex : just set a vertex particle position
         */
        public function updateParticleVertex(particle: SolidParticle, vertex: Vector3, pt: Number): Vector3 {
            return vertex;
        }

        /**
         * This will be called before Object other treatment by `setParticles()` and will be passed three parameters.
         * This does nothing and may be overwritten by the user.
         * @param start the particle index in the particle array where to stop to iterate, same than the value passed to setParticle()
         * @param stop the particle index in the particle array where to stop to iterate, same than the value passed to setParticle()
         * @param update the Boolean update value actually passed to setParticles()
         */
        public function beforeUpdateParticles(start: Number = NaN, stop: Number = NaN, update: Boolean = false): void {
        }
        /**
         * This will be called  by `setParticles()` after all the other treatments and just before the actual mesh update.
         * This will be passed three parameters.
         * This does nothing and may be overwritten by the user.
         * @param start the particle index in the particle array where to stop to iterate, same than the value passed to setParticle()
         * @param stop the particle index in the particle array where to stop to iterate, same than the value passed to setParticle()
         * @param update the Boolean update value actually passed to setParticles()
         */
        public function afterUpdateParticles(start: Number = NaN, stop: Number = NaN, update: Boolean = false): void {
        }

        public function setUVMatrix(mat: Matrix): void {
            if (!this._uvs32)
                return;
            var uvs: Vector.<Number> = this._uvs32.slice();
            var vec: Vector3 = new Vector3(0, 0, 1);
            var v: Vector3 = new Vector3(0, 0, 0);
            for (var i: int = 0; i < uvs.length; i+=2) {
                vec.x = uvs[i];
                vec.y = uvs[i+1];
                vec.z = 1;

                Vector3.TransformCoordinatesToRef(vec, mat, v);

                uvs[i] = v.x;
                uvs[i+1] = v.y;
            }
            this.mesh.updateVerticesData(VertexBuffer.UVKind, uvs, false, false);
        }
    }
}
