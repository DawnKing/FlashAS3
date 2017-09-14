/**
     * Created by caijingxiao on 2017/6/24.
     */
package easiest.rendering.sprites
{
    import easiest.utils.MatrixUtil;

    import flash.geom.Matrix;
    import flash.geom.Point;

    public class SpriteContainer extends SpriteObject
    {
        private var _mouseChildren:Boolean = false;
        private var _children:Vector.<SpriteObject> = new <SpriteObject>[];

        private static var sSortBuffer:Vector.<SpriteObject> = new <SpriteObject>[];
        private static var sHelperMatrix:Matrix = new Matrix();

        public function SpriteContainer()
        {
            super();
        }

        public override function dispose():void
        {
            for (var i:int=_children.length-1; i>=0; --i)
                _children[i].dispose();

            super.dispose();
        }

        /** Adds a child to the container. It will be at the frontmost position. */
        public function addChild(child:SpriteObject):SpriteObject
        {
            return addChildAt(child, _children.length);
        }

        /** Adds a child to the container at a certain index. */
        public function addChildAt(child:SpriteObject, index:int):SpriteObject
        {
            var numChildren:int = _children.length;

            if (index >= 0 && index <= numChildren)
            {
                if (child.parent == this)
                {
                    setChildIndex(child, index); // avoids dispatching events
                }
                else
                {
                    _children.insertAt(index, child);

                    child.removeFromParent();
                    child.setParent(this);
                }

                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }

        /** Removes a child from the container. If the object is not a child, the method returns
         *  <code>null</code>. If requested, the child will be disposed right away. */
        public function removeChild(child:SpriteObject, dispose:Boolean=false):SpriteObject
        {
            var childIndex:int = getChildIndex(child);
            if (childIndex != -1) return removeChildAt(childIndex, dispose);
            else return null;
        }

        /** Removes a child at a certain index. The index positions of any display objects above
         *  the child are decreased by 1. If requested, the child will be disposed right away. */
        public function removeChildAt(index:int, dispose:Boolean=false):SpriteObject
        {
            if (index >= 0 && index < _children.length)
            {
                var child:SpriteObject = _children[index];

                child.setParent(null);
                index = _children.indexOf(child); // index might have changed by event handler
                if (index >= 0) _children.removeAt(index);
                if (dispose) child.dispose();

                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }

        /** Removes a range of children from the container (endIndex included).
         *  If no arguments are given, all children will be removed. */
        public function removeChildren(beginIndex:int=0, endIndex:int=-1, dispose:Boolean=false):void
        {
            if (endIndex < 0 || endIndex >= numChildren)
                endIndex = numChildren - 1;

            for (var i:int=beginIndex; i<=endIndex; ++i)
                removeChildAt(beginIndex, dispose);
        }

        /** Returns a child object at a certain index. If you pass a negative index,
         *  '-1' will return the last child, '-2' the second to last child, etc. */
        public function getChildAt(index:int):SpriteObject
        {
            var numChildren:int = _children.length;

            if (index < 0)
                index = numChildren + index;

            if (index >= 0 && index < numChildren)
                return _children[index];
            else
                throw new RangeError("Invalid child index");
        }

        public function getChildByName(name:String):SpriteObject
        {
            var numChildren:int = _children.length;
            for (var i:int=0; i<numChildren; ++i)
                if (_children[i].name == name) return _children[i];

            return null;
        }

        /** Returns the index of a child within the container, or "-1" if it is not found. */
        public function getChildIndex(child:SpriteObject):int
        {
            return _children.indexOf(child);
        }

        /** Moves a child to a certain index. Children at and after the replaced position move up.*/
        public function setChildIndex(child:SpriteObject, index:int):void
        {
            var oldIndex:int = getChildIndex(child);
            if (oldIndex == index) return;
            if (oldIndex == -1) throw new ArgumentError("Not a child of this container");

            _children.removeAt(oldIndex);
            _children.insertAt(index, child);
        }

        /** Swaps the indexes of two children. */
        public function swapChildren(child1:SpriteObject, child2:SpriteObject):void
        {
            var index1:int = getChildIndex(child1);
            var index2:int = getChildIndex(child2);
            if (index1 == -1 || index2 == -1) throw new ArgumentError("Not a child of this container");
            swapChildrenAt(index1, index2);
        }

        /** Swaps the indexes of two children. */
        public function swapChildrenAt(index1:int, index2:int):void
        {
            var child1:SpriteObject = getChildAt(index1);
            var child2:SpriteObject = getChildAt(index2);
            _children[index1] = child2;
            _children[index2] = child1;
        }

        /** Sorts the children according to a given function (that works just like the sort function
         *  of the Vector class). */
        public function sortChildren(compareFunction:Function):void
        {
            sSortBuffer.length = _children.length;
            mergeSort(_children, compareFunction, 0, _children.length, sSortBuffer);
            sSortBuffer.length = 0;
        }

        /** Determines if a certain object is a child of the container (recursively). */
        public function contains(child:SpriteObject):Boolean
        {
            while (child)
            {
                if (child == this) return true;
                else child = child.parent;
            }
            return false;
        }

        /** @inheritDoc */
        public override function hitTest(point:Point):SpriteObject
        {
            if (!visible || !_mouseChildren)
                return null;

            var localX:Number = point.x;
            var localY:Number = point.y;
            sHelperMatrix.copyFrom(transformationMatrix);
            sHelperMatrix.invert();
            var localPoint:Point = MatrixUtil.transformCoords(sHelperMatrix, localX, localY);

            var numChildren:int = _children.length;
            var target:SpriteObject = null;
            for (var i:int = numChildren - 1; i >= 0; --i) // front to back!
            {
                var child:SpriteObject = _children[i];
                target = child.hitTest(localPoint);
                if (target)
                    return target;
            }

            return super.hitTest(localPoint);
        }

        public override function render(matrix:Matrix):void
        {
            var numChildren:int = _children.length;
            _globalTransformation.copyFrom(transformationMatrix);
            if (matrix)
                _globalTransformation.concat(matrix);
            for (var i:int=0; i<numChildren; ++i)
            {
                var child:SpriteObject = _children[i];
                child.render(_globalTransformation);
            }
        }

        /** The number of children of this container. */
        public function get numChildren():int { return _children.length; }

        private static function mergeSort(input:Vector.<SpriteObject>, compareFunc:Function,
                                          startIndex:int, length:int,
                                          buffer:Vector.<SpriteObject>):void
        {
            // This is a port of the C++ merge sort algorithm shown here:
            // http://www.cprogramming.com/tutorial/computersciencetheory/mergesort.html

            if (length > 1)
            {
                var i:int;
                var endIndex:int = startIndex + length;
                var halfLength:int = length / 2;
                var l:int = startIndex;              // current position in the left subvector
                var r:int = startIndex + halfLength; // current position in the right subvector

                // sort each subvector
                mergeSort(input, compareFunc, startIndex, halfLength, buffer);
                mergeSort(input, compareFunc, startIndex + halfLength, length - halfLength, buffer);

                // merge the vectors, using the buffer vector for temporary storage
                for (i = 0; i < length; i++)
                {
                    // Check to see if any elements remain in the left vector;
                    // if so, we check if there are any elements left in the right vector;
                    // if so, we compare them. Otherwise, we know that the merge must
                    // take the element from the left vector. */
                    if (l < startIndex + halfLength &&
                        (r == endIndex || compareFunc(input[l], input[r]) <= 0))
                    {
                        buffer[i] = input[l];
                        l++;
                    }
                    else
                    {
                        buffer[i] = input[r];
                        r++;
                    }
                }

                // copy the sorted subvector back to the input
                for(i = startIndex; i < endIndex; i++)
                    input[i] = buffer[int(i - startIndex)];
            }
        }

        public function get mouseChildren():Boolean
        {
            return _mouseChildren;
        }

        public function set mouseChildren(value:Boolean):void
        {
            _mouseChildren = value;
        }

        override internal function setTransformationChanged():void
        {
            super.setTransformationChanged();
            var numChildren:int = _children.length;
            for (var i:int=0; i<numChildren; ++i)
                _children[i]._parentTransformationChanged = true;
        }
    }
}
