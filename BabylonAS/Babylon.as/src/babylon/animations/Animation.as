/**
 * Created by caijingxiao on 2016/11/15.
 */
package babylon.animations {
    import babylon.Node;
    import babylon.math.Color3;
    import babylon.math.Matrix;
    import babylon.math.Quaternion;
    import babylon.math.Size;
    import babylon.math.Vector2;
    import babylon.math.Vector3;
    import babylon.tools.ObjectUtils;

    public class Animation {
        public var name: String;
        public var targetProperty: String;
        public var framePerSecond: int;
        public var dataType: int;
        public var loopMode: int;
        public var enableBlending: Boolean;

        private var _keys: Vector.<Object>; //Array<{frame:Number, value: Object}>;
        private var _offsetsCache: Object = {};
        private var _highLimitsCache: Object = {};
        private var _stopped: Boolean = false;
        public var _target: Object;
        private var _blendingFactor: Number = 0;
        private var _easingFunction: IEasingFunction;

        // The set of event that will be linked to this animation
        private var _events: Vector.<AnimationEvent> = new <AnimationEvent>[];

        public var targetPropertyPath: Array;
        public var currentFrame: Number;

        public var allowMatricesInterpolation: Boolean = false;

        public var blendingSpeed: Number = 0.01;
        private var _originalBlendValue: Object;

        private var _ranges: Object = {};   // { [name: String]: AnimationRange; }

        public static function _PrepareAnimation(name: String, targetProperty: String, framePerSecond: Number, totalFrame: Number,
                                                 from: Object, to: Object, loopMode: Number = NaN, easingFunction: EasingFunction = null): Animation {
            var dataType: int = -1;

            if (!isNaN(parseFloat(String(from))) && isFinite(parseFloat(String(from)))) {
                dataType = ANIMATIONTYPE_FLOAT;
            } else if (from is Quaternion) {
                dataType = ANIMATIONTYPE_QUATERNION;
            } else if (from is Vector3) {
                dataType = ANIMATIONTYPE_VECTOR3;
            } else if (from is Vector2) {
                dataType = ANIMATIONTYPE_VECTOR2;
            } else if (from is Color3) {
                dataType = ANIMATIONTYPE_COLOR3;
            } else if (from is Size) {
                dataType = ANIMATIONTYPE_SIZE;
            }

            if (dataType == -1) {
                return null;
            }

            var animation: Animation = new Animation(name, targetProperty, framePerSecond, dataType, loopMode);

            var keys: Vector.<Object> = new <Object>[{ frame: 0, value: from }, { frame: totalFrame, value: to }];
            animation.setKeys(keys);

            if (easingFunction !== null) {
                animation.setEasingFunction(easingFunction);
            }

            return animation;
        }

        public static function CreateAndStartAnimation(name: String, node: Node, targetProperty: String,
                                                       framePerSecond: Number, totalFrame: Number,
                                                       from: Object, to: Object, loopMode: Number = NaN, easingFunction: EasingFunction = null, onAnimationEnd: Function = null): Animatable {

            var animation: Animation = Animation._PrepareAnimation(name, targetProperty, framePerSecond, totalFrame, from, to, loopMode, easingFunction);

            return node.getScene().beginDirectAnimation(node, new <Animation>[animation], 0, totalFrame, (animation.loopMode === 1), 1.0, onAnimationEnd);
        }

        public static function CreateMergeAndStartAnimation(name: String, node: Node, targetProperty: String,
                                                            framePerSecond: Number, totalFrame: Number,
                                                            from: Object, to: Object, loopMode: Number = NaN, easingFunction: EasingFunction = null, onAnimationEnd: Function = null): Animatable {

            var animation: Animation = Animation._PrepareAnimation(name, targetProperty, framePerSecond, totalFrame, from, to, loopMode, easingFunction);

            node.animations.push(animation);

            return node.getScene().beginAnimation(node, 0, totalFrame, (animation.loopMode === 1), 1.0, onAnimationEnd);
        }

        public function Animation(name: String, targetProperty: String, framePerSecond: int, dataType: int, loopMode: int = -1, enableBlending: Boolean = false) {
            this.name = name;
            this.targetProperty = targetProperty;
            this.framePerSecond = framePerSecond;
            this.loopMode = loopMode;
            this.enableBlending = enableBlending;

            this.targetPropertyPath = targetProperty.split(".");
            this.dataType = dataType;
            this.loopMode = loopMode === -1 ? ANIMATIONLOOPMODE_CYCLE : loopMode;
        }

        // Methods
        /**
         * @param {Boolean} fullDetails - support for multiple levels of logging within scene loading
         */
        public function toString(fullDetails : Boolean = false) : String {
            var ret: String = "Name: " + this.name + ", property: " + this.targetProperty;
            ret += ", datatype: " + (["Float", "Vector3", "Quaternion", "Matrix", "Color3", "Vector2"])[this.dataType];
            ret += ", nKeys: " + (this._keys ? this._keys.length : "none");
            ret += ", nRanges: " + (this._ranges ? ObjectUtils.keys(this._ranges).length : "none");
            if (fullDetails) {
                ret += ", Ranges: {";
                var first: Boolean = true;
                for (var name: String in this._ranges) {
                    if (first) {
                        ret += ", ";
                        first = false;
                    }
                    ret += name;
                }
                ret += "}";
            }
            return ret;
        }

        /**
         * Add an event to this animation.
         */
        public function addEvent(event: AnimationEvent): void {
            this._events.push(event);
        }

        /**
         * Remove all events found at the given frame
         * @param frame
         */
        public function removeEvents(frame: Number): void {
            for (var index: int = 0; index < this._events.length; index++) {
                if (this._events[index].frame === frame) {
                    this._events.splice(index, 1);
                    index--;
                }
            }
        }

        public function createRange(name: String, from: Number, to: Number): void {
// check name not already in use; could happen for bones after serialized
            if (!this._ranges[name]) {
                this._ranges[name] = new AnimationRange(name, from, to);
            }
        }

        public function deleteRange(name: String, deleteFrames: Boolean = true): void {
            if (this._ranges[name]) {
                if (deleteFrames) {
                    var from: int = this._ranges[name].from;
                    var to: int = this._ranges[name].to;

                    // this loop MUST go high to low for multiple splices to work
                    for (var key: int = this._keys.length - 1; key >= 0; key--) {
                        if (this._keys[key].frame >= from && this._keys[key].frame <= to) {
                            this._keys.splice(key, 1);
                        }
                    }
                }
                this._ranges[name] = undefined; // said much faster than 'delete this._range[name]'
            }
        }

        public function getRange(name: String): AnimationRange {
            return this._ranges[name];
        }

        public function reset(): void {
            this._offsetsCache = {};
            this._highLimitsCache = {};
            this.currentFrame = 0;
            this._blendingFactor = 0;
            this._originalBlendValue = null;
        }

        public function isStopped(): Boolean {
            return this._stopped;
        }

        public function getKeys(): Vector.<Object> {// Array<{ frame: Number, value: Object }>
            return this._keys;
        }

        public function getHighestFrame(): int {
            var ret: int = 0;

            for (var key: int = 0, nKeys: int = this._keys.length; key < nKeys; key++) {
                if (ret < this._keys[key].frame) {
                    ret = this._keys[key].frame;
                }
            }
            return ret;
        }

        public function getEasingFunction(): IEasingFunction {
            return this._easingFunction;
        }

        public function setEasingFunction(easingFunction: EasingFunction): void {
            this._easingFunction = easingFunction;
        }

        public function floatInterpolateFunction(startValue: Number, endValue: Number, gradient: Number): Number {
            return startValue + (endValue - startValue) * gradient;
        }

        public function quaternionInterpolateFunction(startValue: Quaternion, endValue: Quaternion, gradient: Number): Quaternion {
            return Quaternion.Slerp(startValue, endValue, gradient);
        }

        public function vector3InterpolateFunction(startValue: Vector3, endValue: Vector3, gradient: Number): Vector3 {
            return Vector3.Lerp(startValue, endValue, gradient);
        }

        public function vector2InterpolateFunction(startValue: Vector2, endValue: Vector2, gradient: Number): Vector2 {
            return Vector2.Lerp(startValue, endValue, gradient);
        }

        public function sizeInterpolateFunction(startValue: Size, endValue: Size, gradient: Number): Size {
            return Size.Lerp(startValue, endValue, gradient);
        }

        public function color3InterpolateFunction(startValue: Color3, endValue: Color3, gradient: Number): Color3 {
            return Color3.Lerp(startValue, endValue, gradient);
        }

        public function matrixInterpolateFunction(startValue: Matrix, endValue: Matrix, gradient: Number): Matrix {
            return Matrix.Lerp(startValue, endValue, gradient);
        }

        public function clone(): Animation {
            var clone: Animation = new Animation(this.name, this.targetPropertyPath.join("."), this.framePerSecond, this.dataType, this.loopMode);

            if (this._keys) {
                clone.setKeys(this._keys);
            }

            if (this._ranges) {
                clone._ranges = {};
                for (var name: String in this._ranges) {
                    clone._ranges[name] = this._ranges[name].clone();
                }
            }

            return clone;
        }

        public function setKeys(values: Vector.<Object> ): void {
            this._keys = values.slice(0);
            this._offsetsCache = {};
            this._highLimitsCache = {};
        }

        private function _getKeyValue(value: Object): Object {
            if (value is Function) {
                return Function(value)();
            }

            return value;
        }

        private function _interpolate(currentFrame: int, repeatCount: int, loopMode: int, offsetValue: Object = null, highLimitValue: Object = null): Object {
            if (loopMode === ANIMATIONLOOPMODE_CONSTANT && repeatCount > 0) {
                return highLimitValue.clone ? highLimitValue.clone() : highLimitValue;
            }

            this.currentFrame = currentFrame;

            // Try to get a hash to find the right key
            var startKey: Number = Math.max(0, Math.min(this._keys.length - 1, Math.floor(this._keys.length * (currentFrame - this._keys[0].frame) / (this._keys[this._keys.length - 1].frame - this._keys[0].frame)) - 1));

            if (this._keys[startKey].frame >= currentFrame) {
                while (startKey - 1 >= 0 && this._keys[startKey].frame >= currentFrame) {
                    startKey--;
                }
            }

            for (var key: int = startKey; key < this._keys.length; key++) {
                if (this._keys[key + 1].frame >= currentFrame) {

                    var startValue: Object = this._getKeyValue(this._keys[key].value);
                    var endValue: Object = this._getKeyValue(this._keys[key + 1].value);

                    // gradient : percent of currentFrame between the frame inf and the frame sup
                    var gradient: Number = (currentFrame - this._keys[key].frame) / (this._keys[key + 1].frame - this._keys[key].frame);

                    // check for easingFunction and correction of gradient
                    if (this._easingFunction != null) {
                        gradient = this._easingFunction.ease(gradient);
                    }

                    switch (this.dataType) {
                        // Float
                        case Animation.ANIMATIONTYPE_FLOAT:
                            switch (loopMode) {
                                case Animation.ANIMATIONLOOPMODE_CYCLE:
                                case Animation.ANIMATIONLOOPMODE_CONSTANT:
                                    return this.floatInterpolateFunction(Number(startValue), Number(endValue), gradient);
                                case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                    return Number(offsetValue) * repeatCount + this.floatInterpolateFunction(Number(startValue), Number(endValue), gradient);
                            }
                            break;
                        // Quaternion
                        case Animation.ANIMATIONTYPE_QUATERNION:
                            var quaternion: Quaternion = null;
                            switch (loopMode) {
                                case Animation.ANIMATIONLOOPMODE_CYCLE:
                                case Animation.ANIMATIONLOOPMODE_CONSTANT:
                                    quaternion = this.quaternionInterpolateFunction(Quaternion(startValue), Quaternion(endValue), gradient);
                                    break;
                                case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                    quaternion = this.quaternionInterpolateFunction(Quaternion(startValue), Quaternion(endValue), gradient).add(offsetValue.scale(repeatCount));
                                    break;
                            }

                            return quaternion;
                        // Vector3
                        case Animation.ANIMATIONTYPE_VECTOR3:
                            switch (loopMode) {
                                case Animation.ANIMATIONLOOPMODE_CYCLE:
                                case Animation.ANIMATIONLOOPMODE_CONSTANT:
                                    return this.vector3InterpolateFunction(Vector3(startValue), Vector3(endValue), gradient);
                                case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                    return this.vector3InterpolateFunction(Vector3(startValue), Vector3(endValue), gradient).add(offsetValue.scale(repeatCount));
                            }
                            break;
                        // Vector2
                        case Animation.ANIMATIONTYPE_VECTOR2:
                            switch (loopMode) {
                                case Animation.ANIMATIONLOOPMODE_CYCLE:
                                case Animation.ANIMATIONLOOPMODE_CONSTANT:
                                    return this.vector2InterpolateFunction(Vector2(startValue), Vector2(endValue), gradient);
                                case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                    return this.vector2InterpolateFunction(Vector2(startValue), Vector2(endValue), gradient).add(offsetValue.scale(repeatCount));
                            }
                            break;
                        // Size
                        case Animation.ANIMATIONTYPE_SIZE:
                            switch (loopMode) {
                                case Animation.ANIMATIONLOOPMODE_CYCLE:
                                case Animation.ANIMATIONLOOPMODE_CONSTANT:
                                    return this.sizeInterpolateFunction(Size(startValue), Size(endValue), gradient);
                                case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                    return this.sizeInterpolateFunction(Size(startValue), Size(endValue), gradient).add(offsetValue.scale(repeatCount));
                            }
                            break;
                        // Color3
                        case Animation.ANIMATIONTYPE_COLOR3:
                            switch (loopMode) {
                                case Animation.ANIMATIONLOOPMODE_CYCLE:
                                case Animation.ANIMATIONLOOPMODE_CONSTANT:
                                    return this.color3InterpolateFunction(Color3(startValue), Color3(endValue), gradient);
                                case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                    return this.color3InterpolateFunction(Color3(startValue), Color3(endValue), gradient).add(offsetValue.scale(repeatCount));
                            }
                            break;
                        // Matrix
                        case Animation.ANIMATIONTYPE_MATRIX:
                            switch (loopMode) {
                                case Animation.ANIMATIONLOOPMODE_CYCLE:
                                case Animation.ANIMATIONLOOPMODE_CONSTANT:
                                    if (this.allowMatricesInterpolation) {
                                        return this.matrixInterpolateFunction(Matrix(startValue), Matrix(endValue), gradient);
                                    }
                                    return startValue;
                                case Animation.ANIMATIONLOOPMODE_RELATIVE:
                                    return startValue;
                            }
                            break;
                    }
                    break;
                }
            }
            return this._getKeyValue(this._keys[this._keys.length - 1].value);
        }

        public function setValue(currentValue: Object): void {
            // Set value
            var path: Object;
            var destination: Object;

            if (this.targetPropertyPath.length > 1) {
                var property: Object = this._target[this.targetPropertyPath[0]];

                for (var index: int = 1; index < this.targetPropertyPath.length - 1; index++) {
                    property = property[this.targetPropertyPath[index]];
                }

                path = this.targetPropertyPath[this.targetPropertyPath.length - 1];
                destination = property;
            } else {
                path = this.targetPropertyPath[0];
                destination = this._target;
            }

            // Blending
            if (this.enableBlending && this._blendingFactor <= 1.0) {
                if (!this._originalBlendValue) {
                    if (destination[path].clone) {
                        this._originalBlendValue = destination[path].clone();
                    } else {
                        this._originalBlendValue = destination[path];
                    }
                }

                if (this._originalBlendValue.prototype) { // Complex value

                    if (this._originalBlendValue.hasOwnProperty("Lerp")) { // Lerp supported
                        destination[path] = this._originalBlendValue.construtor.prototype.Lerp(currentValue, this._originalBlendValue, this._blendingFactor);
                    } else { // Blending not supported
                        destination[path] = currentValue;
                    }

                } else if (this._originalBlendValue.m) { // Matrix
                    destination[path] = Matrix.Lerp(Matrix(this._originalBlendValue), Matrix(currentValue), this._blendingFactor);
                } else { // Direct value
                    destination[path] = Number(this._originalBlendValue) * (1.0 - this._blendingFactor) + this._blendingFactor * Number(currentValue);
                }
                this._blendingFactor += this.blendingSpeed;
            } else {
                destination[path] = currentValue;
            }

            if (this._target.markAsDirty) {
                if ( this._target.markAsDirty.length == 1)
                    this._target.markAsDirty(this.targetProperty);
                else
                    this._target.markAsDirty();
            }
        }

        public function goToFrame(frame: Number): void {
            if (frame < this._keys[0].frame) {
                frame = this._keys[0].frame;
            } else if (frame > this._keys[this._keys.length - 1].frame) {
                frame = this._keys[this._keys.length - 1].frame;
            }

            var currentValue: Object = this._interpolate(frame, 0, this.loopMode);

            this.setValue(currentValue);
        }

        public function animate(delay: Number, from: int, to: int, loop: Boolean, speedRatio: Number): Boolean {
            if (!this.targetPropertyPath || this.targetPropertyPath.length < 1) {
                this._stopped = true;
                return false;
            }
            var returnValue: Boolean = true;

            // Adding a start key at frame 0 if missing
            if (this._keys[0].frame !== 0) {
                var newKey: Object = { frame: 0, value: this._keys[0].value };
                this._keys.splice(0, 0, newKey);
            }

            // Check limits
            if (from < this._keys[0].frame || from > this._keys[this._keys.length - 1].frame) {
                from = this._keys[0].frame;
            }
            if (to < this._keys[0].frame || to > this._keys[this._keys.length - 1].frame) {
                to = this._keys[this._keys.length - 1].frame;
            }

            // to and from cannot be the same key
            if (from === to) {
                from++;
            }

            // Compute ratio
            var range: int = to - from;
            var offsetValue: Object;
            // ratio represents the frame delta between from and to
            var ratio: Number = delay * (this.framePerSecond * speedRatio) / 1000.0;
            var highLimitValue: Number = 0;

            if (ratio > range && !loop) { // If we are out of range and not looping get back to caller
                returnValue = false;
                highLimitValue = this._getKeyValue(this._keys[this._keys.length - 1].value) as Number;
            } else {
                // Get max value if required

                if (this.loopMode !== Animation.ANIMATIONLOOPMODE_CYCLE) {

                    var keyOffset: String = to.toString() + from.toString();
                    if (!this._offsetsCache[keyOffset]) {
                        var fromValue: Object = this._interpolate(from, 0, Animation.ANIMATIONLOOPMODE_CYCLE);
                        var toValue: Object = this._interpolate(to, 0, Animation.ANIMATIONLOOPMODE_CYCLE);
                        switch (this.dataType) {
                            // Float
                            case Animation.ANIMATIONTYPE_FLOAT:
                                this._offsetsCache[keyOffset] = Number(toValue) - Number(fromValue);
                                break;
                            // Quaternion
                            case Animation.ANIMATIONTYPE_QUATERNION:
                                this._offsetsCache[keyOffset] = toValue.subtract(fromValue);
                                break;
                            // Vector3
                            case Animation.ANIMATIONTYPE_VECTOR3:
                                this._offsetsCache[keyOffset] = toValue.subtract(fromValue);
                                break;
                            // Vector2
                            case Animation.ANIMATIONTYPE_VECTOR2:
                                this._offsetsCache[keyOffset] = toValue.subtract(fromValue);
                                break;
                            // Size
                            case Animation.ANIMATIONTYPE_SIZE:
                                this._offsetsCache[keyOffset] = toValue.subtract(fromValue);
                                break;
                            // Color3
                            case Animation.ANIMATIONTYPE_COLOR3:
                                this._offsetsCache[keyOffset] = toValue.subtract(fromValue);
                                break;
                            default:
                                break;
                        }

                        this._highLimitsCache[keyOffset] = toValue;
                    }

                    highLimitValue = this._highLimitsCache[keyOffset];
                    offsetValue = this._offsetsCache[keyOffset];
                }
            }

            if (offsetValue === null) {
                switch (this.dataType) {
                    // Float
                    case Animation.ANIMATIONTYPE_FLOAT:
                        offsetValue = 0;
                        break;
                    // Quaternion
                    case Animation.ANIMATIONTYPE_QUATERNION:
                        offsetValue = new Quaternion(0, 0, 0, 0);
                        break;
                    // Vector3
                    case Animation.ANIMATIONTYPE_VECTOR3:
                        offsetValue = Vector3.Zero();
                        break;
                    // Vector2
                    case Animation.ANIMATIONTYPE_VECTOR2:
                        offsetValue = Vector2.Zero();
                        break;
                    // Size
                    case Animation.ANIMATIONTYPE_SIZE:
                        offsetValue = Size.Zero();
                        break;
                    // Color3
                    case Animation.ANIMATIONTYPE_COLOR3:
                        offsetValue = Color3.Black();
                }
            }

            // Compute value
            var repeatCount: int = (ratio / range) >> 0;
            var currentFrame: int = returnValue ? from + ratio % range : to;
            var currentValue: Object = this._interpolate(currentFrame, repeatCount, this.loopMode, offsetValue, highLimitValue);

            // Set value
            this.setValue(currentValue);
            // Check events
            for (var index: int = 0; index < this._events.length; index++) {
                if (currentFrame >= this._events[index].frame) {
                    var event: AnimationEvent = this._events[index];
                    if (!event.isDone) {
                        // If event should be done only once, remove it.
                        if (event.onlyOnce) {
                            this._events.splice(index, 1);
                            index--;
                        }
                        event.isDone = true;
                        event.action();
                    } // Don't do Objectthing if the event has already be done.
                } else if (this._events[index].isDone && !this._events[index].onlyOnce) {
                    // reset event, the animation is looping
                    this._events[index].isDone = false;
                }
            }
            if (!returnValue) {
                this._stopped = true;
            }

            return returnValue;
        }

        public function serialize(): Object {
            var serializationObject: Object = {};

            serializationObject.name = this.name;
            serializationObject.property = this.targetProperty;
            serializationObject.framePerSecond = this.framePerSecond;
            serializationObject.dataType = this.dataType;
            serializationObject.loopBehavior = this.loopMode;

            var dataType: int = this.dataType;
            serializationObject.keys = [];
            var keys: Vector.<Object> = this.getKeys();
            for (var index: int = 0; index < keys.length; index++) {
                var animationKey: Object = keys[index];

                var key: Object = {};
                key.frame = animationKey.frame;

                switch (dataType) {
                    case Animation.ANIMATIONTYPE_FLOAT:
                        key.values = [animationKey.value];
                        break;
                    case Animation.ANIMATIONTYPE_QUATERNION:
                    case Animation.ANIMATIONTYPE_MATRIX:
                    case Animation.ANIMATIONTYPE_VECTOR3:
                    case Animation.ANIMATIONTYPE_COLOR3:
                        key.values = animationKey.value.asArray();
                        break;
                }

                serializationObject.keys.push(key);
            }

            serializationObject.ranges = [];
            for (var name: String in this._ranges) {
                var range: Object = {};
                range.name = name;
                range.from = this._ranges[name].from;
                range.to = this._ranges[name].to;
                serializationObject.ranges.push(range);
            }

            return serializationObject;
        }

// Statics
        public static const ANIMATIONTYPE_FLOAT: int = 0;
        public static const ANIMATIONTYPE_VECTOR3: int = 1;
        public static const ANIMATIONTYPE_QUATERNION: int = 2;
        public static const ANIMATIONTYPE_MATRIX: int = 3;
        public static const ANIMATIONTYPE_COLOR3: int = 4;
        public static const ANIMATIONTYPE_VECTOR2: int = 5;
        public static const ANIMATIONTYPE_SIZE: int = 6;
        public static const ANIMATIONLOOPMODE_RELATIVE: int = 0;
        public static const ANIMATIONLOOPMODE_CYCLE: int = 1;
        public static const ANIMATIONLOOPMODE_CONSTANT: int = 2;


        public static function Parse(parsedAnimation: Object): Animation {
            var animation: Animation = new Animation(parsedAnimation.name, parsedAnimation.property, parsedAnimation.framePerSecond, parsedAnimation.dataType, parsedAnimation.loopBehavior);

            var dataType: int = parsedAnimation.dataType;
            var keys: Vector.<Object> = new <Object>[]; // Array<{ frame: Number, value: Object }> = [];
            var data: Object;
            var index: int;

            for (index = 0; index < parsedAnimation.keys.length; index++) {
                var key: Object = parsedAnimation.keys[index];


                switch (dataType) {
                    case Animation.ANIMATIONTYPE_FLOAT:
                        data = key.values[0];
                        break;
                    case Animation.ANIMATIONTYPE_QUATERNION:
                        data = Quaternion.FromArray(key.values);
                        break;
                    case Animation.ANIMATIONTYPE_MATRIX:
                        data = Matrix.FromArray(Vector.<Number>(key.values));
                        break;
                    case Animation.ANIMATIONTYPE_COLOR3:
                        data = Color3.FromArray(key.values);
                        break;
                    case Animation.ANIMATIONTYPE_VECTOR3:
                    default:
                        data = Vector3.FromArray(key.values);
                        break;
                }

                keys.push({
                    frame: key.frame,
                    value: data
                });
            }

            animation.setKeys(keys);

            if (parsedAnimation.ranges) {
                for (index = 0; index < parsedAnimation.ranges.length; index++) {
                    data = parsedAnimation.ranges[index];
                    animation.createRange(data.name, data.from, data.to);
                }
            }

            return animation;
        }

        public static function AppendSerializedAnimations(source: IAnimatable, destination: Object): void {
            if (source.animations) {
                destination.animations = [];
                for (var animationIndex: int = 0; animationIndex < source.animations.length; animationIndex++) {
                    var animation: Animation = source.animations[animationIndex];

                    destination.animations.push(animation.serialize());
                }
            }
        }
    }
}
