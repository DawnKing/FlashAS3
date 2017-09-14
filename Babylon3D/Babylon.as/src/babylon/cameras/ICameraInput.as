/**
 * Created by caijingxiao on 2016/12/1.
 */
package babylon.cameras {
    import flash.events.EventDispatcher;

    public interface ICameraInput {
        function set camera(value: Camera): void;
        function get camera(): Camera;
        function getTypeName(): String;
        function getSimpleName(): String;
        function attachControl(element: EventDispatcher, noPreventDefault: Boolean = false): void;
        function detachControl(element: EventDispatcher): void;
        function get checkInputs(): Function;
    }
}
