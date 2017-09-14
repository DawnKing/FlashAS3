/**
 * Created by caijingxiao on 2017/6/13.
 */
package easiest.utils
{
    import easiest.managers.load.AssetData;
    import easiest.managers.load.AssetManager;
    import easiest.managers.load.AssetType;

    import flash.display.BitmapData;

    public class Tools
    {
        public static var BaseUrl: String = "";

        public static function Log(message: String): void {//859
            trace(message);
        }

        public static function Warn(message: String): void {//872
            trace(message);
        }

        public static function Error(message: String): void {
            trace(message);
        }

        public static function LoadImage(url: String, onLoad: Function): void {//321
            var loadUrl: String = Tools.BaseUrl + url;

            AssetManager.load(loadUrl, onComplete, AssetType.BITMAP_DATA);

            function onComplete(asset: AssetData): void {
                onLoad(asset.asset as BitmapData);
            }
        }
    }
}
