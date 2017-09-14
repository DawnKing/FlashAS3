/**
 * Created by caijingxiao on 2016/10/13.
 */
package babylon.tools {
    import babylon.math.Vector2;
    import babylon.math.Vector3;

    import easiest.managers.AssetData;
    import easiest.managers.AssetManager;
    import easiest.managers.AssetType;
    import easiest.managers.FrameManager;

    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;

    public class Tools {
        public static var BaseUrl: String = "";

        public static function GetExponentOfTwo(value: Number, max: Number): Number {
            var count: int = 1;

            do {
                count *= 2;
            } while (count < value);

            if (count > max)
                count = max;

            return count;
        }

        public static function ExtractMinAndMax(positions: Vector.<Number>, start: int, count: int, bias: Vector2 = null, stride: int = 0): Object {//161
            var minimum: Vector3 = new Vector3(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE);
            var maximum: Vector3 = new Vector3(Number.MIN_VALUE, Number.MIN_VALUE, Number.MIN_VALUE);

            if (stride == 0) {
                stride = 3;
            }

            for (var index: int = start; index < start + count; index++) {
                var current: Vector3 = new Vector3(positions[index * stride], positions[index * stride + 1], positions[index * stride + 2]);

                minimum = Vector3.Minimize(current, minimum);
                maximum = Vector3.Maximize(current, maximum);
            }

            if (bias) {
                minimum.x -= minimum.x * bias.x + bias.y;
                minimum.y -= minimum.y * bias.x + bias.y;
                minimum.z -= minimum.z * bias.x + bias.y;
                maximum.x += maximum.x * bias.x + bias.y;
                maximum.y += maximum.y * bias.x + bias.y;
                maximum.z += maximum.z * bias.x + bias.y;
            }

            return {
                minimum: minimum,
                maximum: maximum
            };
        }

        public static function LoadImage(url: String, onLoad: Function): void {//321
            var loadUrl: String = Tools.BaseUrl + url;

            AssetManager.load(loadUrl, onComplete, AssetType.BITMAP_DATA);

            function onComplete(asset: AssetData): void {
                onLoad(asset.asset as BitmapData);
            }
        }

        public static function LoadFile(url: String, callback: Function, progressCallback: Function = null, onError: Function = null):void {//389
            var loadUrl: String = Tools.BaseUrl + url;

            var loader: URLLoader = new URLLoader();
            loader.dataFormat = URLLoaderDataFormat.TEXT;

            loader.addEventListener(Event.COMPLETE, onComplete);
            if (progressCallback)
                loader.addEventListener(ProgressEvent.PROGRESS, progressCallback);
            if (onError)
                loader.addEventListener(IOErrorEvent.IO_ERROR, onError);

            function onComplete(event: Event): void {
                loader.removeEventListener(Event.COMPLETE, onComplete);
                if (progressCallback)
                    loader.removeEventListener(ProgressEvent.PROGRESS, progressCallback);
                if (onError)
                    loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);

                callback(loader.data);
            }

            loader.load(new URLRequest(loadUrl));

//            AssetManager.load(loadUrl, onComplete, AssetType.TEXT, AssetType.CACHE_SOMETIMES, progressCallback);
//
//            function onComplete(asset: AssetData): void {
//                callback(asset.asset);
//            }
        }

        // Misc.
        public static function Format(value: Number, decimals: int = 2): String {
            return value.toFixed(decimals);
        }

        public static function RandomId(): String {//807
            return null;
        }

        public static function Log(message: String): void {//859
            trace(message);
        }

        public static function Warn(message: String): void {//872
            trace(message);
        }

        public static function Error(message: String): void {
            trace(message);
        }

        public static function StartPerformanceCounter(s: String, b: Boolean): void {

        }

        public static function EndPerformanceCounter(s: String, b: Boolean): void {

        }

        public static function get Now(): Number {
            return FrameManager.timer;
        }
    }
}
