/**
 * Created by caijingxiao on 2016/10/17.
 */
package babylon {
    import babylon.animations.Animation;
    import babylon.animations.AnimationRange;
    import babylon.math.Matrix;
    import babylon.mesh.AbstractMesh;

    import flash.utils.Dictionary;

    public class Node {
        public var name: String;
        public var id: String;
        public var uniqueId: Number;
        public var state: String = "";

        public var animations: Vector.<Animation> = new <Animation>[];
        private var _ranges: Dictionary = new Dictionary(true); // { [name: String]: AnimationRange; } = {};

        public var onReady: Function;

//        private var _childrenFlag: int = -1;
        private var _isEnabled: Boolean = true;
        private var _isReady: Boolean = true;
        public var _currentRenderId: int = -1;
        private var _parentRenderId: int = -1;

        public var _waitingParentId: String;

        private var _scene: Scene;
        public var _cache: Object;

        private var _parentNode: Node;
        private var _children: Vector.<Node>;

        public function set parent(parent: Node): void {
            if (this._parentNode === parent) {
                return;
            }

            if (this._parentNode) {
                var index: int = this._parentNode._children.indexOf(this);
                if (index !== -1) {
                    this._parentNode._children.splice(index, 1);
                }
            }

            this._parentNode = parent;

            if (this._parentNode) {
                if (!this._parentNode._children) {
                    this._parentNode._children = new <Node>[];
                }
                this._parentNode._children.push(this);
            }
        }

        public function get parent(): Node {
            return this._parentNode;
        }

        /**
         * @constructor
         * @param name - the name and id to be given to this node
         * @param scene - the scene this node will be added to
         */
        public function Node(name: String, scene: Scene) {
            this.name = name;
            this.id = name;
            this._scene = scene;
            this._initCache();
        }

        public function getScene(): Scene {
            return this._scene;
        }

        public function getEngine(): Engine {
            return this._scene.getEngine();
        }

        // override it in derived class
        public function getWorldMatrix(): Matrix {
            return Matrix.Identity();
        }

        // override it in derived class if you add new variables to the cache
        // and call the parent class method
        public function _initCache(): void {
            this._cache = {};
            this._cache.parent = undefined;
        }

        public function updateCache(force: Boolean = false): void {
            if (!force && this.isSynchronized())
                return;

            this._cache.parent = this.parent;

            this._updateCache();
        }

        // override it in derived class if you add new variables to the cache
        // and call the parent class method if !ignoreParentClass
        public function _updateCache(ignoreParentClass: Boolean = false): void {
        }

        // override it in derived class if you add new variables to the cache
        public function _isSynchronized(): Boolean {
            return true;
        }

        public function _markSyncedWithParent(): void {
            this._parentRenderId = this.parent._currentRenderId;
        }

        public function isSynchronizedWithParent(): Boolean {
            if (!this.parent) {
                return true;
            }

            if (this._parentRenderId !== this.parent._currentRenderId) {
                return false;
            }

            return this.parent.isSynchronized();
        }

        public function isSynchronized(updateCache: Boolean = false): Boolean {
            var check: Boolean = this.hasNewParent();

            check = check || !this.isSynchronizedWithParent();

            check = check || !this._isSynchronized();

            if (updateCache)
                this.updateCache(true);

            return !check;
        }

        public function hasNewParent(update: Boolean = false): Boolean {
            if (this._cache.parent === this.parent)
                return false;

            if (update)
                this._cache.parent = this.parent;

            return true;
        }

        /**
         * Is this node ready to be used/rendered
         * @return {Boolean} is it ready
         */
        public function isReady(): Boolean {
            return this._isReady;
        }

        /**
         * Is this node enabled.
         * If the node has a parent and is enabled, the parent will be inspected as well.
         * @return {Boolean} whether this node (and its parent) is enabled.
         * @see setEnabled
         */
        public function isEnabled(): Boolean {
            if (!this._isEnabled) {
                return false;
            }

            if (this.parent) {
                return this.parent.isEnabled();
            }

            return true;
        }

        /**
         * Set the enabled state of this node.
         * @param {Boolean} value - the new enabled state
         * @see isEnabled
         */
        public function setEnabled(value: Boolean): void {
            this._isEnabled = value;
        }

        /**
         * Is this node a descendant of the given node.
         * The function will iterate up the hierarchy until the ancestor was found or no more parents defined.
         * @param ancestor - The parent node to inspect
         * @see parent
         */
        public function isDescendantOf(ancestor: Node): Boolean {
            if (this.parent) {
                if (this.parent === ancestor) {
                    return true;
                }

                return this.parent.isDescendantOf(ancestor);
            }
            return false;
        }

        /**
         * Evaluate the list of children and determine if they should be considered as descendants considering the given criterias
         * @param  results the result array containing the nodes matching the given criterias
         * @param {Boolean} directDescendantsOnly if true only direct descendants of 'this' will be considered, if false direct and also indirect (children of children, an so on in a recursive manner) descendants of 'this' will be considered.
         * @param predicate an optional predicate that will be called on every evaluated children, the predicate must return true for a given child to be part of the result, otherwise it will be ignored.
         */
        public function _getDescendants(results: Vector.<Node>, directDescendantsOnly: Boolean = false, predicate: Function = undefined): void {
            if (!this._children) {
                return;
            }

            for (var index: int = 0; index < this._children.length; index++) {
                var item: Node = this._children[index];

                if (!predicate || predicate(item)) {
                    results.push(item);
                }

                if (!directDescendantsOnly) {
                    item._getDescendants(results, false, predicate);
                }
            }
        }

        /**
         * Will return all nodes that have this node as ascendant.
         * @param {Boolean} directDescendantsOnly if true only direct descendants of 'this' will be considered, if false direct and also indirect (children of children, an so on in a recursive manner) descendants of 'this' will be considered.
         * @param predicate an optional predicate that will be called on every evaluated children, the predicate must return true for a given child to be part of the result, otherwise it will be ignored.
         * @return  all children nodes of all types.
         */
        public function getDescendants(directDescendantsOnly: Boolean = false, predicate: Function = undefined): Vector.<Node> {
            var results: Vector.<Node> = new <Node>[];

            this._getDescendants(results, directDescendantsOnly, predicate);

            return results;
        }

        /**
         * @param predicate an optional predicate that will be called on every evaluated children, the predicate must return true for a given child to be part of the result, otherwise it will be ignored.
         * @Deprecated, legacy support.
         * use getDecendants instead.
         */
        public function getChildren(predicate: Function = undefined): Vector.<Node> {
            return this.getDescendants(true, predicate);
        }

        /**
         * Get all child-meshes of this node.
         */
        public function getChildMeshes(directDecendantsOnly: Boolean = false, predicate: Function = undefined): Vector.<Node> {
            var results: Vector.<Node> = new <Node>[];
            this._getDescendants(results, directDecendantsOnly, function(node: Node): Boolean {
                return ((!predicate || predicate(node)) && (node is AbstractMesh));
            });
            return results;
        }

        public function _setReady(state: Boolean): void {
            if (state === this._isReady) {
                return;
            }

            if (!state) {
                this._isReady = false;
                return;
            }

            this._isReady = true;
            if (this.onReady) {
                this.onReady(this);
            }
        }

        public function getAnimationByName(name: String): Animation {
            for (var i: int = 0; i < this.animations.length; i++) {
                var animation: Animation = this.animations[i];

                if (animation.name === name) {
                    return animation;
                }
            }

            return null;
        }

        public function createAnimationRange(name: String, from: Number, to: Number): void {
            // check name not already in use
            if (!this._ranges[name]) {
                this._ranges[name] = new AnimationRange(name, from, to);
                for (var i: int = 0, nAnimations: int = this.animations.length; i < nAnimations; i++) {
                    if (this.animations[i]) {
                        this.animations[i].createRange(name, from, to);
                    }
                }
            }
        }

        public function deleteAnimationRange(name: String, deleteFrames: Boolean = true): void {
            for (var i: int = 0, nAnimations: int = this.animations.length; i < nAnimations; i++) {
                if (this.animations[i]) {
                    this.animations[i].deleteRange(name, deleteFrames);
                }
            }
            this._ranges[name] = undefined; // said much faster than 'delete this._range[name]'
        }

        public function getAnimationRange(name: String): AnimationRange {
            return this._ranges[name];
        }

        public function beginAnimation(name: String, loop: Boolean = false, speedRatio: Number = NaN, onAnimationEnd: Function = null): void {
            var range: AnimationRange = this.getAnimationRange(name);

            if (!range) {
                return;
            }

            this._scene.beginAnimation(this, range.from, range.to, loop, speedRatio, onAnimationEnd);
        }


        public function dispose(doNotRecurse: Boolean = false): void {
            this.parent = null;
        }

        public static function ParseAnimationRanges(node: Node, parsedNode: Object, scene: Scene): void {
            if (parsedNode.ranges) {
                for (var index: int = 0; index < parsedNode.ranges.length; index++) {
                    var data: Object = parsedNode.ranges[index];
                    node.createAnimationRange(data.name, data.from, data.to);
                }
            }
        }
    }
}
