/**
 * Created by caijingxiao on 2016/10/19.
 */
package babylon.mesh {
    public interface IGetSetVerticesData {
        function isVerticesDataPresent(kind: String): Boolean;
        function getVerticesData(kind: String, copyWhenShared: Boolean = false): Vector.<Number>;
        function getIndices(copyWhenShared: Boolean = false): Vector.<uint>;
        function setVerticesData(kind: String, data: Vector.<Number>, updatable: Boolean = false, stride: Number = NaN): void;
        function updateVerticesData(kind: String, data: Vector.<Number>, updateExtends: Boolean = false, makeItUnique: Boolean = false): void;
        function setIndices(indices: Vector.<uint>, totalVertices: int = 0): void;
    }
}
