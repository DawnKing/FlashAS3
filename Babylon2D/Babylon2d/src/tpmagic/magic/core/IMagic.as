package tpmagic.magic.core
{

	/**
	 * 施法对象接口
	 * @author zhangyong
	 *
	 */
	public interface IMagic
	{

		/**
		 * 释放技能
		 *
		 */
		function casting():void;
		/**
		 *释放技能资源
		 *
		 */
		function dispose():void;
	}
}
