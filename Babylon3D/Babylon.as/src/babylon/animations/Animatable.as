/**
 * Created by caijingxiao on 2016/11/15.
 */
package babylon.animations {
    import babylon.Scene;

    public class Animatable {

        public var target: Object;
        public var fromFrame: int;
        public var toFrame: int;
        public var loopAnimation: Boolean;
        public var speedRatio: Number;
        public var onAnimationEnd: Function;
        public var animations: Vector.<Animation>;

        private var _localDelayOffset: Number;
        private var _pausedDelay: Number;
        private var _animations: Vector.<Animation> = new <Animation>[];
        private var _paused: Boolean = false;
        private var _scene: Scene;

        public var animationStarted: Boolean = false;

        public function Animatable(scene: Scene, target: Object, fromFrame: int = 0, toFrame: int = 100, loopAnimation: Boolean = false, speedRatio: Number = 1.0, onAnimationEnd: Function = null, animations: Vector.<Animation> = null) {
            this.target = target;
            this.fromFrame = fromFrame;
            this.toFrame = toFrame;
            this.loopAnimation = loopAnimation;
            this.speedRatio = speedRatio;
            this.onAnimationEnd = onAnimationEnd;
            this.animations = animations;

            if (animations) {
                this.appendAnimations(target, animations);
            }

            this._scene = scene;
            scene._activeAnimatables.push(this);
        }

        // Methods
        public function getAnimations(): Vector.<Animation> {
            return this._animations;
        }

        public function appendAnimations(target: Object, animations: Vector.<Animation>): void {
            for (var index: int = 0; index < animations.length; index++) {
                var animation: Animation = animations[index];

                animation._target = target;
                this._animations.push(animation);
            }
        }

        public function getAnimationByTargetProperty(property: String): Animation {
            var animations: Vector.<Animation> = this._animations;

            for (var index: int = 0; index < animations.length; index++) {
                if (animations[index].targetProperty === property) {
                    return animations[index];
                }
            }

            return null;
        }

        public function reset(): void {
            var animations: Vector.<Animation> = this._animations;

            for (var index: int = 0; index < animations.length; index++) {
                animations[index].reset();
            }

            this._localDelayOffset = NaN;
            this._pausedDelay = NaN;
        }

        public function enableBlending(blendingSpeed: Number): void {
            var animations: Vector.<Animation> = this._animations;

            for (var index: int = 0; index < animations.length; index++) {
                animations[index].enableBlending = true;
                animations[index].blendingSpeed = blendingSpeed;
            }
        }

        public function disableBlending(): void {
            var animations: Vector.<Animation> = this._animations;

            for (var index: int = 0; index < animations.length; index++) {
                animations[index].enableBlending = false;
            }
        }

        public function goToFrame(frame: int): void {
            var animations: Vector.<Animation> = this._animations;

            if (animations[0]){
                var fps: Number = animations[0].framePerSecond;
                var currentFrame: int = animations[0].currentFrame;
                var adjustTime: int = frame - currentFrame;
                var delay: Number = adjustTime * 1000 / fps;
                this._localDelayOffset -= delay;
            }

            for (var index: int = 0; index < animations.length; index++) {
                animations[index].goToFrame(frame);
            }
        }

        public function pause(): void {
            if (this._paused) {
                return;
            }
            this._paused = true;
        }

        public function restart(): void {
            this._paused = false;
        }

        public function stop(animationName: String = null): void {
            var index: int = this._scene._activeAnimatables.indexOf(this);

            if (index > -1) {
                var animations: Vector.<Animation> = this._animations;
                var numberOfAnimationsStopped: int = 0;
                for (index = animations.length - 1; index >= 0; index--) {
                    if (typeof animationName === "String" && animations[index].name != animationName) {
                        continue;
                    }
                    animations[index].reset();
                    animations.splice(index, 1);
                    numberOfAnimationsStopped++;
                }

                if (animations.length == numberOfAnimationsStopped) {
                    this._scene._activeAnimatables.splice(index, 1);

                    if (this.onAnimationEnd) {
                        this.onAnimationEnd();
                    }
                }
            }
        }

        public function _animate(delay: Number): Boolean {
            if (this._paused) {
                this.animationStarted = false;
                if (!this._pausedDelay) {
                    this._pausedDelay = delay;
                }
                return true;
            }

            if (!this._localDelayOffset) {
                this._localDelayOffset = delay;
            } else if (this._pausedDelay) {
                this._localDelayOffset += delay - this._pausedDelay;
                this._pausedDelay = NaN;
            }

            // Animating
            var running: Boolean = false;
            var animations: Vector.<Animation> = this._animations;
            var index: int;

            for (index = 0; index < animations.length; index++) {
                var animation: Animation = animations[index];
                var isRunning: Boolean = animation.animate(delay - this._localDelayOffset, this.fromFrame, this.toFrame, this.loopAnimation, this.speedRatio);
                running = running || isRunning;
            }

            this.animationStarted = running;

            if (!running) {
                // Remove from active animatables
                index = this._scene._activeAnimatables.indexOf(this);
                this._scene._activeAnimatables.splice(index, 1);
            }

            if (!running && this.onAnimationEnd) {
                this.onAnimationEnd();
                this.onAnimationEnd = null;
            }

            return running;
        }
    }
}
