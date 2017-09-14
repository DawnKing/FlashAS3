package tpmagic.magic.core
{
	import flash.geom.Point;
	
	import tempest.core.ISceneCharacter;
	import tempest.template.MagicInfo;

	public interface IDamge
	{
		/**
		 * 血量变化 
		 * @param flag
		 * @param damage
		 * 
		 */		 
		function hpChange(flag:uint, damage:int=0):void;
		/**
		 * 死亡
		 *
		 */
		function onDead():void;

		/**
		 * 魔法释放 使用技能
		 * @param targeter
		 * @param effectPoint
		 * @param magicInfo
		 * @param leaveShadow
		 * @param isSound
		 */
		function casting(targeter:ISceneCharacter, effectPoint:Point, magicInfo:MagicInfo, leaveShadow:Boolean=false, isSound:Boolean=false):void;
		/**是否锁定*/
		function get isLock():Boolean;
		/**是否微击退*/
		function get littleBack():Boolean;
		/**受击动作几率*/
		function get injureRate():Number;

	}
}
