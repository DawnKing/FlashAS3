package tpmagic.magic.core
{
	import tpmagic.magic.partail.TPartical;

	public interface IEmitter
	{
		/**
		 *释放粒子
		 * @param tPartical
		 * @param magicPoint
		 * @param targetPoint
		 *
		 */
		function emitter(tp:TPartical, duration:Number):void;
		/**
		 * 运动完毕
		 * @param tPartical
		 * 
		 */		
		function onComplete(tPartical:TPartical):void;
		/**
		 * 释放
		 * 
		 */		
		function dispose():void;
	}
}
