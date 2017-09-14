package babylon.culling {
    import babylon.math.Matrix;
    import babylon.math.Plane;
    import babylon.math.Vector3;

    public class BoundingInfo {

        public var boundingBox: BoundingBox;
        public var boundingSphere: BoundingSphere;

        private var _isLocked: Boolean = false;

        public var minimum: Vector3;
        public var maximum: Vector3;

        public function BoundingInfo(minimum: Vector3, maximum: Vector3) {
            this.minimum = minimum;
            this.maximum = maximum;

            this.boundingBox = new BoundingBox(minimum, maximum);
            this.boundingSphere = new BoundingSphere(minimum, maximum);
        }

        public function get isLocked(): Boolean {
            return this._isLocked;
        }

        public function set isLocked(value: Boolean): void {
            this._isLocked = value;
        }

        // Methods
        public function update(world: Matrix): void {
            if (this._isLocked) {
                return;
            }
            this.boundingBox._update(world);
            this.boundingSphere._update(world);
        }

        public function isInFrustum(frustumPlanes: Vector.<Plane>): Boolean {
            if (!this.boundingSphere.isInFrustum(frustumPlanes))
                return false;

            return this.boundingBox.isInFrustum(frustumPlanes);
        }

        public function isCompletelyInFrustum(frustumPlanes: Vector.<Plane>): Boolean {
            return this.boundingBox.isCompletelyInFrustum(frustumPlanes);
        }

        public function _checkCollision(collider: Object): Boolean {
            return collider._canDoCollision(this.boundingSphere.centerWorld, this.boundingSphere.radiusWorld, this.boundingBox.minimumWorld, this.boundingBox.maximumWorld);
        }

        public function intersectsPoint(point: Vector3): Boolean {
            if (!this.boundingSphere.centerWorld) {
                return false;
            }

            if (!this.boundingSphere.intersectsPoint(point)) {
                return false;
            }

            if (!this.boundingBox.intersectsPoint(point)) {
                return false;
            }

            return true;
        }

        public function intersects(boundingInfo: BoundingInfo, precise: Boolean): Boolean {
            if (!this.boundingSphere.centerWorld || !boundingInfo.boundingSphere.centerWorld) {
                return false;
            }

            if (!BoundingSphere.Intersects(this.boundingSphere, boundingInfo.boundingSphere)) {
                return false;
            }

            if (!BoundingBox.Intersects(this.boundingBox, boundingInfo.boundingBox)) {
                return false;
            }

            if (!precise) {
                return true;
            }

            var box0: BoundingBox = this.boundingBox;
            var box1: BoundingBox = boundingInfo.boundingBox;

            if (!axisOverlap(box0.directions[0], box0, box1)) return false;
            if (!axisOverlap(box0.directions[1], box0, box1)) return false;
            if (!axisOverlap(box0.directions[2], box0, box1)) return false;
            if (!axisOverlap(box1.directions[0], box0, box1)) return false;
            if (!axisOverlap(box1.directions[1], box0, box1)) return false;
            if (!axisOverlap(box1.directions[2], box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[0], box1.directions[0]), box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[0], box1.directions[1]), box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[0], box1.directions[2]), box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[1], box1.directions[0]), box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[1], box1.directions[1]), box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[1], box1.directions[2]), box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[2], box1.directions[0]), box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[2], box1.directions[1]), box0, box1)) return false;
            if (!axisOverlap(Vector3.Cross(box0.directions[2], box1.directions[2]), box0, box1)) return false;

            return true;
        }

        public function computeBoxExtents(axis: Vector3, box: BoundingBox): Object {
            var p: Number = Vector3.Dot(box.center, axis);

            var r0: Number = Math.abs(Vector3.Dot(box.directions[0], axis)) * box.extendSize.x;
            var r1: Number = Math.abs(Vector3.Dot(box.directions[1], axis)) * box.extendSize.y;
            var r2: Number = Math.abs(Vector3.Dot(box.directions[2], axis)) * box.extendSize.z;

            var r: Number = r0 + r1 + r2;
            return {
                min: p - r,
                max: p + r
            };
        }

        public function extentsOverlap(min0: Number, max0: Number, min1: Number, max1: Number): Boolean {
            return !(min0 > max1 || min1 > max0);
        }

        public function axisOverlap(axis: Vector3, box0: BoundingBox, box1: BoundingBox): Boolean {
            var result0: Object = computeBoxExtents(axis, box0);
            var result1: Object = computeBoxExtents(axis, box1);

            return extentsOverlap(result0.min, result0.max, result1.min, result1.max);
        }
    }
}
