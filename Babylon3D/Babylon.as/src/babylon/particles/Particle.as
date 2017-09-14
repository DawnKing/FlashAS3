/**
 * Created by caijingxiao on 2016/11/22.
 */
package babylon.particles {
    import babylon.math.Color4;
    import babylon.math.Vector3;

    public class Particle {
        public var position: Vector3 = Vector3.Zero();
        public var direction: Vector3 = Vector3.Zero();
        public var color: Color4 = new Color4(0, 0, 0, 0);
        public var colorStep: Color4 = new Color4(0, 0, 0, 0);
        public var lifeTime: Number = 1.0;
        public var age: Number = 0;
        public var size: Number = 0;
        public var angle: Number = 0;
        public var angularSpeed: Number = 0;

        public function copyTo(other: Particle): void {
            other.position.copyFrom(this.position);
            other.direction.copyFrom(this.direction);
            other.color.copyFrom(this.color);
            other.colorStep.copyFrom(this.colorStep);
            other.lifeTime = this.lifeTime;
            other.age = this.age;
            other.size = this.size;
            other.angle = this.angle;
            other.angularSpeed = this.angularSpeed;
        }
    }
}
