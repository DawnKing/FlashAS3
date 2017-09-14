 package
{
	import flash.system.Capabilities;

	public class Config
	{

		/**游戏帧率*/
		public static const GAME_FPS:int=60;
		/**res_host*/
		public static var resPath:String="http://cn.xy2.zy.xy.com/res/"; //"http://qa.cn.xy2.xy.com/"; //  "http://cn.xy2.cdn.xy.com/"//

		public function Config()
		{
		}

		public function getClientInfo():String
		{
			return Capabilities.isDebugger + "|" + Capabilities.language + "|" + Capabilities.version + "|" + Capabilities.screenResolutionX + "|" + Capabilities.screenResolutionY + "|" + Capabilities.os;
		}

		/**
		 * 获取版本路径
		 * @param shortPath
		 * @return
		 *
		 */
		public static function getVersionUrl(shortPath:String):String
		{
			return resPath + shortPath + "?v=1";
		}

	}
}
