/**
 * Created by caijingxiao on 2016/10/19.
 */
package babylon.mesh {
    import babylon.math.Color4;
    import babylon.math.Matrix;
    import babylon.math.Vector2;
    import babylon.math.Vector3;
    import babylon.math.Vector4;

    public class VertexData {
        public var positions: Vector.<Number>;
        public var normals: Vector.<Number>;
        public var uvs: Vector.<Number>;

        public var colors: Vector.<Number>;
        public var matricesIndices: Vector.<Number>;
        public var matricesWeights: Vector.<Number>;

        public var indices: Vector.<uint>;

        public function set(data: Vector.<Number>, kind: String): void {
            switch (kind) {
                case VertexBuffer.PositionKind:
                    this.positions = data;
                    break;
                case VertexBuffer.NormalKind:
                    this.normals = data;
                    break;
                case VertexBuffer.UVKind:
                    this.uvs = data;
                    break;
                case VertexBuffer.ColorKind:
                    this.colors = data;
                    break;
                case VertexBuffer.MatricesIndicesKind:
                    this.matricesIndices = data;
                    break;
                case VertexBuffer.MatricesWeightsKind:
                    this.matricesWeights = data;
                    break;
            }
        }

        public function applyToMesh(mesh: Mesh, updatable: Boolean = false): void {
            this._applyTo(mesh, updatable);
        }

        public function applyToGeometry(geometry: Geometry, updatable: Boolean = false): void {
            this._applyTo(geometry, updatable);
        }

        public function updateMesh(mesh: Mesh, updateExtends: Boolean = false, makeItUnique: Boolean = false): void {
            this._update(mesh);
        }

        public function updateGeometry(geometry: Geometry, updateExtends: Boolean = false, makeItUnique: Boolean = false): void {
            this._update(geometry);
        }

        private function _applyTo(meshOrGeometry: IGetSetVerticesData, updatable: Boolean = false): void {
            if (this.positions) {
                meshOrGeometry.setVerticesData(VertexBuffer.PositionKind, this.positions, updatable);
            }

            if (this.normals) {
                meshOrGeometry.setVerticesData(VertexBuffer.NormalKind, this.normals, updatable);
            }

            if (this.uvs) {
                meshOrGeometry.setVerticesData(VertexBuffer.UVKind, this.uvs, updatable);
            }

            if (this.colors) {
                meshOrGeometry.setVerticesData(VertexBuffer.ColorKind, this.colors, updatable);
            }

            if (this.matricesIndices) {
                meshOrGeometry.setVerticesData(VertexBuffer.MatricesIndicesKind, this.matricesIndices, updatable);
            }

            if (this.matricesWeights) {
                meshOrGeometry.setVerticesData(VertexBuffer.MatricesWeightsKind, this.matricesWeights, updatable);
            }

            if (this.indices) {
                meshOrGeometry.setIndices(this.indices);
            }
        }

        private function _update(meshOrGeometry: IGetSetVerticesData, updateExtends: Boolean = false, makeItUnique: Boolean = false): void {
            if (this.positions) {
                meshOrGeometry.updateVerticesData(VertexBuffer.PositionKind, this.positions, updateExtends, makeItUnique);
            }

            if (this.normals) {
                meshOrGeometry.updateVerticesData(VertexBuffer.NormalKind, this.normals, updateExtends, makeItUnique);
            }

            if (this.uvs) {
                meshOrGeometry.updateVerticesData(VertexBuffer.UVKind, this.uvs, updateExtends, makeItUnique);
            }

            if (this.colors) {
                meshOrGeometry.updateVerticesData(VertexBuffer.ColorKind, this.colors, updateExtends, makeItUnique);
            }

            if (this.matricesIndices) {
                meshOrGeometry.updateVerticesData(VertexBuffer.MatricesIndicesKind, this.matricesIndices, updateExtends);
            }

            if (this.matricesWeights) {
                meshOrGeometry.updateVerticesData(VertexBuffer.MatricesWeightsKind, this.matricesWeights, updateExtends);
            }

            if (this.indices) {
                meshOrGeometry.setIndices(this.indices);
            }
        }

        public function transform(matrix: Matrix): void {
            var transformed: Vector3 = Vector3.Zero();
            var index: Number;
            if (this.positions) {
                var position: Vector3 = Vector3.Zero();

                for (index = 0; index < this.positions.length; index += 3) {
                    Vector3.FromArrayToRef(this.positions, index, position);

                    Vector3.TransformCoordinatesToRef(position, matrix, transformed);
                    this.positions[index] = transformed.x;
                    this.positions[index + 1] = transformed.y;
                    this.positions[index + 2] = transformed.z;
                }
            }

            if (this.normals) {
                var normal: Vector3 = Vector3.Zero();

                for (index = 0; index < this.normals.length; index += 3) {
                    Vector3.FromArrayToRef(this.normals, index, normal);

                    Vector3.TransformNormalToRef(normal, matrix, transformed);
                    this.normals[index] = transformed.x;
                    this.normals[index + 1] = transformed.y;
                    this.normals[index + 2] = transformed.z;
                }
            }
        }

        // Statics
        public static function ExtractFromMesh(mesh: Mesh, copyWhenShared: Boolean = false): VertexData {
            return VertexData._ExtractFrom(mesh, copyWhenShared);
        }

        public static function ExtractFromGeometry(geometry: Geometry, copyWhenShared: Boolean = false): VertexData {
            return VertexData._ExtractFrom(geometry, copyWhenShared);
        }

        private static function _ExtractFrom(meshOrGeometry: IGetSetVerticesData, copyWhenShared: Boolean = false): VertexData {
            var result: VertexData = new VertexData();

            if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.PositionKind)) {
                result.positions = meshOrGeometry.getVerticesData(VertexBuffer.PositionKind, copyWhenShared);
            }

            if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.NormalKind)) {
                result.normals = meshOrGeometry.getVerticesData(VertexBuffer.NormalKind, copyWhenShared);
            }

            if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.UVKind)) {
                result.uvs = meshOrGeometry.getVerticesData(VertexBuffer.UVKind, copyWhenShared);
            }

            if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.ColorKind)) {
                result.colors = meshOrGeometry.getVerticesData(VertexBuffer.ColorKind, copyWhenShared);
            }

            if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.MatricesIndicesKind)) {
                result.matricesIndices = meshOrGeometry.getVerticesData(VertexBuffer.MatricesIndicesKind, copyWhenShared);
            }

            if (meshOrGeometry.isVerticesDataPresent(VertexBuffer.MatricesWeightsKind)) {
                result.matricesWeights = meshOrGeometry.getVerticesData(VertexBuffer.MatricesWeightsKind, copyWhenShared);
            }

            result.indices = meshOrGeometry.getIndices(copyWhenShared);

            return result;
        }

        public static function CreateBox(options: Object): VertexData {
            var normalsSource: Array = [
                new Vector3(0, 0, 1),
                new Vector3(0, 0, -1),
                new Vector3(1, 0, 0),
                new Vector3(-1, 0, 0),
                new Vector3(0, 1, 0),
                new Vector3(0, -1, 0)
            ];

            var indices: Vector.<uint> = new <uint>[];
            var positions: Vector.<Number> = new <Number>[];
            var normals: Vector.<Number> = new <Number>[];
            var uvs: Vector.<Number> = new <Number>[];

            var width: int = options.width || options.size || 1;
            var height: int = options.height || options.size || 1;
            var depth: int = options.depth || options.size || 1;
            var sideOrientation: int = (options.sideOrientation === 0) ? 0 : options.sideOrientation || Mesh.DEFAULTSIDE;
            var faceUV: Vector.<Vector4> = new Vector.<Vector4>(6, true);
            var faceColors: Vector.<Color4> = options.faceColors;
            var colors: Vector.<Number> = new <Number>[];

            // default face colors and UV if undefined
            for (var f: int = 0; f < 6; f++) {
                if (faceUV[f] == null) {
                    faceUV[f] = new Vector4(0, 0, 1, 1);
                }
                if (faceColors && faceColors[f] == null) {
                    faceColors[f] = new Color4(1, 1, 1, 1);
                }
            }

            var scaleVector: Vector3 = new Vector3(width / 2, height / 2, depth / 2);

            // Create each face in turn.
            for (var index: int = 0; index < normalsSource.length; index++) {
                var normal: Vector3 = normalsSource[index];

                // Get two vectors perpendicular to the face normal and to each other.
                var side1: Vector3 = new Vector3(normal.y, normal.z, normal.x);
                var side2: Vector3 = Vector3.Cross(normal, side1);

                // Six indices (two triangles) per face.
                var verticesLength: int = positions.length / 3;
                indices.push(verticesLength);
                indices.push(verticesLength + 1);
                indices.push(verticesLength + 2);

                indices.push(verticesLength);
                indices.push(verticesLength + 2);
                indices.push(verticesLength + 3);

                // Four vertices per face.
                var vertex: Vector3 = normal.subtract(side1).subtract(side2).multiply(scaleVector);
                positions.push(vertex.x, vertex.y, vertex.z);
                normals.push(normal.x, normal.y, normal.z);
                uvs.push(faceUV[index].z, faceUV[index].w);
                if (faceColors) {
                    colors.push(faceColors[index].r, faceColors[index].g, faceColors[index].b, faceColors[index].a);
                }

                vertex = normal.subtract(side1).add(side2).multiply(scaleVector);
                positions.push(vertex.x, vertex.y, vertex.z);
                normals.push(normal.x, normal.y, normal.z);
                uvs.push(faceUV[index].x, faceUV[index].w);
                if (faceColors) {
                    colors.push(faceColors[index].r, faceColors[index].g, faceColors[index].b, faceColors[index].a);
                }

                vertex = normal.add(side1).add(side2).multiply(scaleVector);
                positions.push(vertex.x, vertex.y, vertex.z);
                normals.push(normal.x, normal.y, normal.z);
                uvs.push(faceUV[index].x, faceUV[index].y);
                if (faceColors) {
                    colors.push(faceColors[index].r, faceColors[index].g, faceColors[index].b, faceColors[index].a);
                }

                vertex = normal.add(side1).subtract(side2).multiply(scaleVector);
                positions.push(vertex.x, vertex.y, vertex.z);
                normals.push(normal.x, normal.y, normal.z);
                uvs.push(faceUV[index].z, faceUV[index].y);
                if (faceColors) {
                    colors.push(faceColors[index].r, faceColors[index].g, faceColors[index].b, faceColors[index].a);
                }
            }

            // sides
            VertexData._ComputeSides(sideOrientation, positions, indices, normals, uvs);

            // Result
            var vertexData: VertexData = new VertexData();

            vertexData.indices = indices;
            vertexData.positions = positions;
            vertexData.normals = normals;
            vertexData.uvs = uvs;

            if (faceColors) {
                var totalColors: Vector.<Number> = (sideOrientation === Mesh.DOUBLESIDE) ? colors.concat(colors) : colors;
                vertexData.colors = totalColors;
            }

            return vertexData;
        }

        public static function CreateSphere(options: Object): VertexData {
            var segments: Number = options.segments || 32;
            var diameterX: Number = options.diameterX || options.diameter || 1;
            var diameterY: Number = options.diameterY || options.diameter || 1;
            var diameterZ: Number = options.diameterZ || options.diameter || 1;
            var arc: Number = (options.arc <= 0 || options.arc > 1) ? 1.0 : options.arc || 1.0;
            var slice: Number = (options.slice <= 0) ? 1.0 : options.slice || 1.0;
            var sideOrientation: int = (options.sideOrientation === 0) ? 0 : options.sideOrientation || Mesh.DEFAULTSIDE;

            var radius: Vector3 = new Vector3(diameterX / 2, diameterY / 2, diameterZ / 2);

            var totalZRotationSteps: int = 2 + segments;
            var totalYRotationSteps: int = 2 * totalZRotationSteps;

            var indices: Vector.<uint> = new <uint>[];
            var positions: Vector.<Number> = new <Number>[];
            var normals: Vector.<Number> = new <Number>[];
            var uvs: Vector.<Number> = new <Number>[];

            for (var zRotationStep: int = 0; zRotationStep <= totalZRotationSteps; zRotationStep++) {
                var normalizedZ: Number = zRotationStep / totalZRotationSteps;
                var angleZ: Number = normalizedZ * Math.PI * slice;

                for (var yRotationStep: int = 0; yRotationStep <= totalYRotationSteps; yRotationStep++) {
                    var normalizedY: Number = yRotationStep / totalYRotationSteps;

                    var angleY: Number = normalizedY * Math.PI * 2 * arc;

                    var rotationZ: Matrix = Matrix.RotationZ(-angleZ);
                    var rotationY: Matrix = Matrix.RotationY(angleY);
                    var afterRotZ: Vector3 = Vector3.TransformCoordinates(Vector3.Up(), rotationZ);
                    var complete: Vector3 = Vector3.TransformCoordinates(afterRotZ, rotationY);

                    var vertex: Vector3 = complete.multiply(radius);
                    var normal: Vector3 = complete.divide(radius).normalize();

                    positions.push(vertex.x, vertex.y, vertex.z);
                    normals.push(normal.x, normal.y, normal.z);
                    uvs.push(normalizedY, normalizedZ);
                }

                if (zRotationStep > 0) {
                    var verticesCount: int = positions.length / 3;
                    for (var firstIndex: int = verticesCount - 2 * (totalYRotationSteps + 1); (firstIndex + totalYRotationSteps + 2) < verticesCount; firstIndex++) {
                        indices.push((firstIndex));
                        indices.push((firstIndex + 1));
                        indices.push(firstIndex + totalYRotationSteps + 1);

                        indices.push((firstIndex + totalYRotationSteps + 1));
                        indices.push((firstIndex + 1));
                        indices.push((firstIndex + totalYRotationSteps + 2));
                    }
                }
            }

            // Sides
            VertexData._ComputeSides(sideOrientation, positions, indices, normals, uvs);

            // Result
            var vertexData: VertexData = new VertexData();

            vertexData.indices = indices;
            vertexData.positions = positions;
            vertexData.normals = normals;
            vertexData.uvs = uvs;

            return vertexData;
        }

        // Cylinder and cone
        public static function CreateCylinder(options: Object): VertexData {
            var height: Number = options.height || 2;
            var diameterTop: Number = (options.diameterTop === 0) ? 0 : options.diameterTop || options.diameter || 1;
            var diameterBottom: Number = options.diameterBottom || options.diameter || 1;
            var tessellation: Number = options.tessellation || 24;
            var subdivisions: Number = options.subdivisions || 1;
            var hasRings: Boolean = options.hasRings;
            var enclose: Boolean = options.enclose;
            var arc: Number = (options.arc <= 0 || options.arc > 1) ? 1.0 : options.arc || 1.0;
            var sideOrientation: Number = (options.sideOrientation === 0) ? 0 : options.sideOrientation || Mesh.DEFAULTSIDE;
            var faceUV: Vector.<Vector4>;// = options.faceUV || new Array<Vector4>(3);
            var faceColors: Vector.<Color4> = options.faceColors;

            // default face colors and UV if undefined
            var quadNb: Number = (arc !== 1 && enclose) ? 2 : 0;
            var ringNb: Number = (hasRings) ? subdivisions : 1;
            var surfaceNb: Number = 2 + (1 + quadNb) * ringNb;
            var f: Number;
            for (f = 0; f < surfaceNb; f++) {
                if (faceColors && faceColors[f] === undefined) {
                    faceColors[f] = new Color4(1, 1, 1, 1);
                }
            }
            for (f = 0; f < surfaceNb; f++) {
                if (faceUV && faceUV[f] === undefined) {
                    faceUV[f] = new Vector4(0, 0, 1, 1);
                }
            }

            var indices: Vector.<uint> = new <uint>[];
            var positions: Vector.<Number> = new <Number>[];
            var normals: Vector.<Number> = new <Number>[];
            var uvs: Vector.<Number> = new <Number>[];
            var colors: Vector.<Number> = new <Number>[];

            var angle_step: Number = Math.PI * 2 * arc / tessellation;
            var angle: Number;
            var h: Number;
            var radius: Number;
            var tan: Number = (diameterBottom - diameterTop) / 2 / height;
            var ringVertex: Vector3 = Vector3.Zero();
            var ringNormal: Vector3 = Vector3.Zero();
            var ringFirstVertex: Vector3 = Vector3.Zero();
            var ringFirstNormal: Vector3 = Vector3.Zero();
            var quadNormal: Vector3 = Vector3.Zero();
            var Y: Vector3 = Vector3.Y_AXIS;

            // positions, normals, uvs
            var i: Number;
            var j: Number;
            var r: Number;
            var ringIdx: Number = 1;
            var s: Number = 1;      // surface index
            var cs: Number = 0;
            var v: Number = 0;

            for (i = 0; i <= subdivisions; i++) {
                h = i / subdivisions;
                radius = (h * (diameterTop - diameterBottom) + diameterBottom) / 2;
                ringIdx = (hasRings && i !== 0 && i !== subdivisions) ? 2 : 1;
                for (r = 0; r < ringIdx; r++) {
                    if (hasRings) {
                        s += r;
                    }
                    if (enclose) {
                        s += 2 * r;
                    }
                    for (j = 0; j <= tessellation; j++) {
                        angle = j * angle_step;

                        // position
                        ringVertex.x = Math.cos(-angle) * radius;
                        ringVertex.y = -height / 2 + h * height;
                        ringVertex.z = Math.sin(-angle) * radius;

                        // normal
                        if (diameterTop === 0 && i === subdivisions) {
                            // if no top cap, reuse former normals
                            ringNormal.x = normals[normals.length - (tessellation + 1) * 3];
                            ringNormal.y = normals[normals.length - (tessellation + 1) * 3 + 1];
                            ringNormal.z = normals[normals.length - (tessellation + 1) * 3 + 2];
                        }
                        else {
                            ringNormal.x = ringVertex.x;
                            ringNormal.z = ringVertex.z;
                            ringNormal.y = Math.sqrt(ringNormal.x * ringNormal.x + ringNormal.z * ringNormal.z) * tan;
                            ringNormal.normalize();
                        }

                        // keep first ring vertex values for enclose
                        if (j === 0) {
                            ringFirstVertex.copyFrom(ringVertex);
                            ringFirstNormal.copyFrom(ringNormal);
                        }

                        positions.push(ringVertex.x, ringVertex.y, ringVertex.z);
                        normals.push(ringNormal.x, ringNormal.y, ringNormal.z);
                        if (hasRings) {
                            v = (cs !== s) ? faceUV[s].y : faceUV[s].w;
                        } else {
                            v = faceUV[s].y + (faceUV[s].w - faceUV[s].y) * h;
                        }
                        uvs.push(faceUV[s].x + (faceUV[s].z - faceUV[s].x) * j / tessellation, v);
                        if (faceColors) {
                            colors.push(faceColors[s].r, faceColors[s].g, faceColors[s].b, faceColors[s].a);
                        }
                    }

                    // if enclose, add four vertices and their dedicated normals
                    if (arc !== 1 && enclose) {
                        positions.push(ringVertex.x, ringVertex.y, ringVertex.z);
                        positions.push(0, ringVertex.y, 0);
                        positions.push(0, ringVertex.y, 0);
                        positions.push(ringFirstVertex.x, ringFirstVertex.y, ringFirstVertex.z);
                        Vector3.CrossToRef(Y, ringNormal, quadNormal);
                        quadNormal.normalize();
                        normals.push(quadNormal.x, quadNormal.y, quadNormal.z, quadNormal.x, quadNormal.y, quadNormal.z);
                        Vector3.CrossToRef(ringFirstNormal, Y, quadNormal);
                        quadNormal.normalize();
                        normals.push(quadNormal.x, quadNormal.y, quadNormal.z, quadNormal.x, quadNormal.y, quadNormal.z);
                        if (hasRings) {
                            v = (cs !== s) ? faceUV[s + 1].y : faceUV[s + 1].w;
                        } else {
                            v = faceUV[s + 1].y + (faceUV[s + 1].w - faceUV[s + 1].y) * h;
                        }
                        uvs.push(faceUV[s + 1].x, v);
                        uvs.push(faceUV[s + 1].z, v);
                        if (hasRings) {
                            v = (cs !== s) ? faceUV[s + 2].y : faceUV[s + 2].w;
                        } else {
                            v = faceUV[s + 2].y + (faceUV[s + 2].w - faceUV[s + 2].y) * h;
                        }
                        uvs.push(faceUV[s + 2].x, v);
                        uvs.push(faceUV[s + 2].z, v);
                        if (faceColors) {
                            colors.push(faceColors[s + 1].r, faceColors[s + 1].g, faceColors[s + 1].b, faceColors[s + 1].a);
                            colors.push(faceColors[s + 1].r, faceColors[s + 1].g, faceColors[s + 1].b, faceColors[s + 1].a);
                            colors.push(faceColors[s + 2].r, faceColors[s + 2].g, faceColors[s + 2].b, faceColors[s + 2].a);
                            colors.push(faceColors[s + 2].r, faceColors[s + 2].g, faceColors[s + 2].b, faceColors[s + 2].a);
                        }
                    }
                    if (cs !== s) {
                        cs = s;
                    }

                }

            }

            // indices
            var e: Number = (arc !== 1 && enclose) ? tessellation + 4 : tessellation;     // correction of Number of iteration if enclose
            i = 0;
            for (s = 0; s < subdivisions; s++) {
                for (j = 0; j < tessellation; j++) {
                    var i0: uint = i * (e + 1) + j;
                    var i1: uint = (i + 1) * (e + 1) + j;
                    var i2: uint = i * (e + 1) + (j + 1);
                    var i3: uint = (i + 1) * (e + 1) + (j + 1);
                    indices.push(i0, i1, i2);
                    indices.push(i3, i2, i1);
                }
                if (arc !== 1 && enclose) {      // if enclose, add two quads
                    indices.push(i0 + 2, i1 + 2, i2 + 2);
                    indices.push(i3 + 2, i2 + 2, i1 + 2);
                    indices.push(i0 + 4, i1 + 4, i2 + 4);
                    indices.push(i3 + 4, i2 + 4, i1 + 4);
                }
                i = (hasRings) ? (i + 2) : (i + 1);
            }

            // Caps
            function createCylinderCap(isTop: Boolean): void {
                var radius: Number = isTop ? diameterTop / 2 : diameterBottom / 2;
                if (radius === 0) {
                    return;
                }

                // Cap positions, normals & uvs
                var angle: Number;
                var circleVector: Vector3;
                var i: Number;
                var u: Vector4 = (isTop) ? faceUV[surfaceNb - 1] : faceUV[0];
                var c: Color4;
                if (faceColors) {
                    c = (isTop) ? faceColors[surfaceNb - 1] : faceColors[0];
                }
                // cap center
                var vbase: Number = positions.length / 3;
                var offset: Number = isTop ? height / 2 : -height / 2;
                var center: Vector3 = new Vector3(0, offset, 0);
                positions.push(center.x, center.y, center.z);
                normals.push(0, isTop ? 1 : -1, 0);
                uvs.push(u.x + (u.z - u.x) * 0.5, u.y + (u.w - u.y) * 0.5);
                if (faceColors) {
                    colors.push(c.r, c.g, c.b, c.a);
                }

                var textureScale: Vector2 = new Vector2(0.5, 0.5);
                for (i = 0; i <= tessellation; i++) {
                    angle = Math.PI * 2 * i * arc / tessellation;
                    var cos: Number = Math.cos(-angle);
                    var sin: Number = Math.sin(-angle);
                    circleVector = new Vector3(cos * radius, offset, sin * radius);
                    var textureCoordinate: Vector2 = new Vector2(cos * textureScale.x + 0.5, sin * textureScale.y + 0.5);
                    positions.push(circleVector.x, circleVector.y, circleVector.z);
                    normals.push(0, isTop ? 1 : -1, 0);
                    uvs.push(u.x + (u.z - u.x) * textureCoordinate.x, u.y + (u.w - u.y) * textureCoordinate.y);
                    if (faceColors) {
                        colors.push(c.r, c.g, c.b, c.a);
                    }
                }
                // Cap indices
                for (i = 0; i < tessellation; i++) {
                    if (!isTop) {
                        indices.push(vbase);
                        indices.push(vbase + (i + 1));
                        indices.push(vbase + (i + 2));
                    }
                    else {
                        indices.push(vbase);
                        indices.push(vbase + (i + 2));
                        indices.push(vbase + (i + 1));
                    }
                }
            }

            // add caps to geometry
            createCylinderCap(false);
            createCylinderCap(true);

            // Sides
            VertexData._ComputeSides(sideOrientation, positions, indices, normals, uvs);

            var vertexData: VertexData = new VertexData();

            vertexData.indices = indices;
            vertexData.positions = positions;
            vertexData.normals = normals;
            vertexData.uvs = uvs;
            if (faceColors) {
                vertexData.colors = colors;
            }

            return vertexData;
        }

        public static function CreateTorus(options: Object): VertexData {
            var indices: Vector.<uint> = new <uint>[];
            var positions: Vector.<Number> = new <Number>[];
            var normals: Vector.<Number> = new <Number>[];
            var uvs: Vector.<Number> = new <Number>[];

            var diameter: Number = options.diameter || 1;
            var thickness: Number = options.thickness || 0.5;
            var tessellation: Number = options.tessellation || 16;
            var sideOrientation: int = (options.sideOrientation === 0) ? 0 : options.sideOrientation || Mesh.DEFAULTSIDE;

            var stride: int = tessellation + 1;

            for (var i: int = 0; i <= tessellation; i++) {
                var u: Number = i / tessellation;

                var outerAngle: Number = i * Math.PI * 2.0 / tessellation - Math.PI / 2.0;

                var transform: Matrix = Matrix.Translation(diameter / 2.0, 0, 0).multiply(Matrix.RotationY(outerAngle));

                for (var j: int = 0; j <= tessellation; j++) {
                    var v: Number = 1 - j / tessellation;

                    var innerAngle: Number = j * Math.PI * 2.0 / tessellation + Math.PI;
                    var dx: Number = Math.cos(innerAngle);
                    var dy: Number = Math.sin(innerAngle);

                    // Create a vertex.
                    var normal: Vector3 = new Vector3(dx, dy, 0);
                    var position: Vector3 = normal.scale(thickness / 2);
                    var textureCoordinate: Vector2 = new Vector2(u, v);

                    position = Vector3.TransformCoordinates(position, transform);
                    normal = Vector3.TransformNormal(normal, transform);

                    positions.push(position.x, position.y, position.z);
                    normals.push(normal.x, normal.y, normal.z);
                    uvs.push(textureCoordinate.x, textureCoordinate.y);

                    // And create indices for two triangles.
                    var nextI: int = (i + 1) % stride;
                    var nextJ: int = (j + 1) % stride;

                    indices.push(i * stride + j);
                    indices.push(i * stride + nextJ);
                    indices.push(nextI * stride + j);

                    indices.push(i * stride + nextJ);
                    indices.push(nextI * stride + nextJ);
                    indices.push(nextI * stride + j);
                }
            }

            // Sides
            VertexData._ComputeSides(sideOrientation, positions, indices, normals, uvs);

            // Result
            var vertexData: VertexData = new VertexData();


            vertexData.indices = indices;
            vertexData.positions = positions;
            vertexData.normals = normals;
            vertexData.uvs = uvs;

            return vertexData;
        }

        public static function CreateLineSystem(options: Object): VertexData {
            var indices: Vector.<uint> = new <uint>[];
            var positions: Vector.<Number> = new <Number>[];
            var lines: Array = options.lines;
            var idx: int = 0;

            for (var l: int = 0; l < lines.length; l++) {
                var points: Array = lines[l];
                for (var index: int = 0; index < points.length; index++) {
                    positions.push(points[index].x, points[index].y, points[index].z);

                    if (index > 0) {
                        indices.push(idx - 1);
                        indices.push(idx);
                    }
                    idx++;
                }
            }
            var vertexData: VertexData = new VertexData();
            vertexData.indices = indices;
            vertexData.positions = positions;
            return vertexData;
        }

        public static function CreateDashedLines(options: Object): VertexData {
            var dashSize: int = options.dashSize || 3;
            var gapSize: int = options.gapSize || 1;
            var dashNb: Number = options.dashNb || 200;
            var points: Array = options.points;

            var positions: Vector.<Number> = new <Number>[];
            var indices: Vector.<uint> = new <uint>[];

            var curvect: Vector3 = Vector3.Zero();
            var lg: Number = 0;
            var nb: Number = 0;
            var shft: Number = 0;
            var dashshft: Number = 0;
            var curshft: Number = 0;
            var idx: int = 0;
            var i: int = 0;
            for (i = 0; i < points.length - 1; i++) {
                points[i + 1].subtractToRef(points[i], curvect);
                lg += curvect.length();
            }
            shft = lg / dashNb;
            dashshft = dashSize * shft / (dashSize + gapSize);
            for (i = 0; i < points.length - 1; i++) {
                points[i + 1].subtractToRef(points[i], curvect);
                nb = Math.floor(curvect.length() / shft);
                curvect.normalize();
                for (var j: int = 0; j < nb; j++) {
                    curshft = shft * j;
                    positions.push(points[i].x + curshft * curvect.x, points[i].y + curshft * curvect.y, points[i].z + curshft * curvect.z);
                    positions.push(points[i].x + (curshft + dashshft) * curvect.x, points[i].y + (curshft + dashshft) * curvect.y, points[i].z + (curshft + dashshft) * curvect.z);
                    indices.push(idx, idx + 1);
                    idx += 2;
                }
            }

            // Result
            var vertexData: VertexData = new VertexData();
            vertexData.positions = positions;
            vertexData.indices = indices;

            return vertexData;
        }

        public static function CreateGround(options: Object): VertexData {//1183
            var indices: Vector.<uint> = new <uint>[];
            var positions: Vector.<Number> = new <Number>[];
            var normals: Vector.<Number> = new <Number>[];
            var uvs: Vector.<Number> = new <Number>[];
            var row: Number, col: Number;

            var width: Number = options.width || 1;
            var height: Number = options.height || 1;
            var subdivisionsX: Number = options.subdivisionsX || options.subdivisions || 1;
            var subdivisionsY: Number = options.subdivisionsY || options.subdivisions || 1;

            for (row = 0; row <= subdivisionsY; row++) {
                for (col = 0; col <= subdivisionsX; col++) {
                    var position: Vector3 = new Vector3((col * width) / subdivisionsX - (width / 2.0), 0, ((subdivisionsY - row) * height) / subdivisionsY - (height / 2.0));
                    var normal: Vector3 = new Vector3(0, 1.0, 0);

                    positions.push(position.x, position.y, position.z);
                    normals.push(normal.x, normal.y, normal.z);
                    uvs.push(col / subdivisionsX, 1.0 - row / subdivisionsX);
                }
            }

            for (row = 0; row < subdivisionsY; row++) {
                for (col = 0; col < subdivisionsX; col++) {
                    indices.push(col + 1 + (row + 1) * (subdivisionsX + 1));
                    indices.push(col + 1 + row * (subdivisionsX + 1));
                    indices.push(col + row * (subdivisionsX + 1));

                    indices.push(col + (row + 1) * (subdivisionsX + 1));
                    indices.push(col + 1 + (row + 1) * (subdivisionsX + 1));
                    indices.push(col + row * (subdivisionsX + 1));
                }
            }

            // Result
            var vertexData: VertexData = new VertexData();

            vertexData.indices = indices;
            vertexData.positions = positions;
            vertexData.normals = normals;
            vertexData.uvs = uvs;

            return vertexData;
        }

        public static function CreatePlane(options: Object): VertexData {
            var indices: Vector.<uint> = new Vector.<uint>(6, true);
            var positions: Vector.<Number> = new <Number>[];
            var normals: Vector.<Number> = new <Number>[];
            var uvs: Vector.<Number> = new <Number>[];

            var width: Number = options.width || options.size || 1;
            var height: Number = options.height || options.size || 1;
            var sideOrientation: int = (options.sideOrientation === 0) ? 0 : options.sideOrientation || Mesh.DEFAULTSIDE;

            // Vertices
            var halfWidth: Number = width / 2.0;
            var halfHeight: Number = height / 2.0;

            positions.push(-halfWidth, -halfHeight, 0);
            normals.push(0, 0, -1.0);
            uvs.push(0.0, 0.0);

            positions.push(halfWidth, -halfHeight, 0);
            normals.push(0, 0, -1.0);
            uvs.push(1.0, 0.0);

            positions.push(halfWidth, halfHeight, 0);
            normals.push(0, 0, -1.0);
            uvs.push(1.0, 1.0);

            positions.push(-halfWidth, halfHeight, 0);
            normals.push(0, 0, -1.0);
            uvs.push(0.0, 1.0);

            // Indices
            indices[0] = 0;
            indices[1] = 1;
            indices[2] = 2;

            indices[3] = 0;
            indices[4] = 2;
            indices[5] = 3;

            // Sides
            VertexData._ComputeSides(sideOrientation, positions, indices, normals, uvs);

            // Result
            var vertexData: VertexData = new VertexData();

            vertexData.indices = indices;
            vertexData.positions = positions;
            vertexData.normals = normals;
            vertexData.uvs = uvs;

            return vertexData;
        }

        public static function CreateDisc(options: Object): VertexData {
            var positions: Vector.<Number> = new <Number>[];
            var indices: Vector.<uint> = new <uint>[];
            var normals: Vector.<Number> = new <Number>[];
            var uvs: Vector.<Number> = new <Number>[];

            var radius: Number = options.radius || 0.5;
            var tessellation: int = options.tessellation || 64;
            var arc: Number = (options.arc <= 0 || options.arc > 1) ? 1.0 : options.arc || 1.0;
            var sideOrientation: int = (options.sideOrientation === 0) ? 0 : options.sideOrientation || Mesh.DEFAULTSIDE;

            // positions and uvs
            positions.push(0, 0, 0);    // disc center first
            uvs.push(0.5, 0.5);

            var theta: Number = Math.PI * 2 * arc;
            var step: Number = theta / tessellation;
            for (var a: int = 0; a < theta; a += step) {
                var x: Number = Math.cos(a);
                var y: Number = Math.sin(a);
                var u: Number = (x + 1) / 2;
                var v: Number = (1 - y) / 2;
                positions.push(radius * x, radius * y, 0);
                uvs.push(u, v);
            }
            if (arc === 1) {
                positions.push(positions[3], positions[4], positions[5]); // close the circle
                uvs.push(uvs[2], uvs[3]);
            }

            //indices
            var vertexNb: int = positions.length / 3;
            for (var i: int = 1; i < vertexNb - 1; i++) {
                indices.push(i + 1, 0, i);
            }

            // result
            VertexData.ComputeNormals(positions, indices, normals);
            VertexData._ComputeSides(sideOrientation, positions, indices, normals, uvs);

            var vertexData: VertexData = new VertexData();

            vertexData.indices = indices;
            vertexData.positions = positions;
            vertexData.normals = normals;
            vertexData.uvs = uvs;

            return vertexData;
        }


        // Tools
        /**
         * @param {Object} positions (Number[] or Float32Array)
         * @param {Object} indices   (Number[] or Uint16Array)
         * @param {Object} normals   (Number[] or Float32Array)
         */
        public static function ComputeNormals(positions: Object, indices: Object, normals: Object): void {//1965
            var index: int = 0;

            var p1p2x: Number = 0.0;
            var p1p2y: Number = 0.0;
            var p1p2z: Number = 0.0;
            var p3p2x: Number = 0.0;
            var p3p2y: Number = 0.0;
            var p3p2z: Number = 0.0;
            var faceNormalx: Number = 0.0;
            var faceNormaly: Number = 0.0;
            var faceNormalz: Number= 0.0;

            var length: Number = 0.0;

            var i1: int = 0;
            var i2: int = 0;
            var i3: int = 0;

            for (index = 0; index < positions.length; index++) {
                normals[index] = 0.0;
            }

            // indice triplet = 1 face
            var nbFaces: int = indices.length / 3;
            for (index = 0; index < nbFaces; index++) {
                i1 = indices[index * 3];            // get the indexes of each vertex of the face
                i2 = indices[index * 3 + 1];
                i3 = indices[index * 3 + 2];

                p1p2x = positions[i1 * 3] - positions[i2 * 3];          // compute two vectors per face
                p1p2y = positions[i1 * 3 + 1] - positions[i2 * 3 + 1];
                p1p2z = positions[i1 * 3 + 2] - positions[i2 * 3 + 2];

                p3p2x = positions[i3 * 3] - positions[i2 * 3];
                p3p2y = positions[i3 * 3 + 1] - positions[i2 * 3 + 1];
                p3p2z = positions[i3 * 3 + 2] - positions[i2 * 3 + 2];

                faceNormalx = p1p2y * p3p2z - p1p2z * p3p2y;            // compute the face normal with cross product
                faceNormaly = p1p2z * p3p2x - p1p2x * p3p2z;
                faceNormalz = p1p2x * p3p2y - p1p2y * p3p2x;

                length = Math.sqrt(faceNormalx * faceNormalx + faceNormaly * faceNormaly + faceNormalz * faceNormalz);
                length = (length === 0) ? 1.0 : length;
                faceNormalx /= length;                                  // normalize this normal
                faceNormaly /= length;
                faceNormalz /= length;

                normals[i1 * 3] += faceNormalx;                         // accumulate all the normals per face
                normals[i1 * 3 + 1] += faceNormaly;
                normals[i1 * 3 + 2] += faceNormalz;
                normals[i2 * 3] += faceNormalx;
                normals[i2 * 3 + 1] += faceNormaly;
                normals[i2 * 3 + 2] += faceNormalz;
                normals[i3 * 3] += faceNormalx;
                normals[i3 * 3 + 1] += faceNormaly;
                normals[i3 * 3 + 2] += faceNormalz;
            }

            // last normalization of each normal
            for (index = 0; index < normals.length / 3; index++) {
                faceNormalx = normals[index * 3];
                faceNormaly = normals[index * 3 + 1];
                faceNormalz = normals[index * 3 + 2];

                length = Math.sqrt(faceNormalx * faceNormalx + faceNormaly * faceNormaly + faceNormalz * faceNormalz);
                length = (length === 0) ? 1.0 : length;
                faceNormalx /= length;
                faceNormaly /= length;
                faceNormalz /= length;

                normals[index * 3] = faceNormalx;
                normals[index * 3 + 1] = faceNormaly;
                normals[index * 3 + 2] = faceNormalz;
            }
        }

        private static function _ComputeSides(sideOrientation: Number, positions: Vector.<Number>, indices: Vector.<uint>, normals: Vector.<Number>, uvs: Vector.<Number>): void {
            var li: Number = indices.length;
            var ln: Number = normals.length;
            var i: Number;
            var n: Number;
            sideOrientation = sideOrientation || Mesh.DEFAULTSIDE;

            switch (sideOrientation) {

                case Mesh.FRONTSIDE:
                    // nothing changed
                    break;

                case Mesh.BACKSIDE:
                    var tmp: Number;
                    // indices
                    for (i = 0; i < li; i += 3) {
                        tmp = indices[i];
                        indices[i] = indices[i + 2];
                        indices[i + 2] = tmp;
                    }
                    // normals
                    for (n = 0; n < ln; n++) {
                        normals[n] = -normals[n];
                    }
                    break;

                case Mesh.DOUBLESIDE:
                    // positions
                    var lp: Number = positions.length;
                    var l: Number = lp / 3;
                    for (var p: int = 0; p < lp; p++) {
                        positions[lp + p] = positions[p];
                    }
                    // indices
                    for (i = 0; i < li; i += 3) {
                        indices[i + li] = indices[i + 2] + l;
                        indices[i + 1 + li] = indices[i + 1] + l;
                        indices[i + 2 + li] = indices[i] + l;
                    }
                    // normals
                    for (n = 0; n < ln; n++) {
                        normals[ln + n] = -normals[n];
                    }

                    // uvs
                    var lu: Number = uvs.length;
                    for (var u: Number = 0; u < lu; u++) {
                        uvs[u + lu] = uvs[u];
                    }
                    break;
            }
        }

        public static function ImportVertexData(parsedVertexData: Object, geometry: Geometry): void {
            var vertexData: VertexData = new VertexData();

            // positions
            var positions: Vector.<Number> = parsedVertexData.positions;
            if (positions) {
                vertexData.set(positions, VertexBuffer.PositionKind);
            }

            // normals
            var normals: Vector.<Number> = parsedVertexData.normals;
            if (normals) {
                vertexData.set(normals, VertexBuffer.NormalKind);
            }

            // uvs
            var uvs: Vector.<Number> = parsedVertexData.uvs;
            if (uvs) {
                vertexData.set(uvs, VertexBuffer.UVKind);
            }

            // colors
            var colors: Vector.<Number> = parsedVertexData.colors;
            if (colors) {
                vertexData.set(Color4.CheckColors4(colors, positions.length / 3), VertexBuffer.ColorKind);
            }

            // matricesIndices
            var matricesIndices: Vector.<Number> = parsedVertexData.matricesIndices;
            if (matricesIndices) {
                vertexData.set(matricesIndices, VertexBuffer.MatricesIndicesKind);
            }

            // matricesWeights
            var matricesWeights: Vector.<Number> = parsedVertexData.matricesWeights;
            if (matricesWeights) {
                vertexData.set(matricesWeights, VertexBuffer.MatricesWeightsKind);
            }

            // indices
            var indices: Vector.<uint> = parsedVertexData.indices;
            if (indices) {
                vertexData.indices = indices;
            }

            geometry.setAllVerticesData(vertexData, parsedVertexData.updatable);
        }
    }
}
