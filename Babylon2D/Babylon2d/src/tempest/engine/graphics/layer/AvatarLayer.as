package tempest.engine.graphics.layer
{
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import tempest.core.IPartical;
	import tempest.core.IRunable;
	import tempest.core.ISceneCharacter;
	
	import tempest.engine.SceneCharacter;
	import tempest.engine.graphics.avatar.Avatar;

	/**
	 * 容器层
	 * @author
	 */
	public class AvatarLayer extends Sprite implements IRunable
	{
		/***排序延时*/
		public static const SORT_DELAY:int=500;
		/***帧频时间差*/
		private var timeOffset:int=0;
		/***是否需要排序*/
		private var needSort:Boolean=false;
		/***渲染间隔*/
		private var needRender:int=0;
		/*** 渲染的所有元素*/
		private var _chars:Array=null;

		public function AvatarLayer()
		{
			super();
			this.tabEnabled=this.tabChildren=this.mouseEnabled=this.mouseChildren=false;
			_chars=[];
		}

		/**
		 * 添加对象
		 * @param sceneChar
		 *
		 */
		public function addCharacter(sceneChar:SceneCharacter):void
		{
			this.addChild(sceneChar.body);
			_chars.push(sceneChar);
		}

		/**
		 * 删除对象
		 * @param sceneChar
		 *
		 */
		public function removeCharacter(sceneChar:ISceneCharacter):void
		{
			_chars.splice(_chars.indexOf(sceneChar), 1);
		}


		/**
		 *执行avatar
		 * @param diff
		 *
		 */
		public function run(nowTime:int, diff:int):void
		{
			timeOffset+=diff;
			needRender--;
			if (timeOffset > SORT_DELAY)
			{
				needSort=true;
				timeOffset=0;
			}
			///////////////////////////////////
			var iter:int=0;
			var char:SceneCharacter=null;
			var len:int=_chars.length;
			var avatar:Avatar;
			//循环心跳
			var pindex:int;
			var ipartical:IPartical;
			var rect:Rectangle;
			var rect2:Rectangle;
			for (; iter < len; ++iter)
			{
				char=_chars[iter] as SceneCharacter;
				if (char.lock)
				{
					continue;
				}
				if (char.render)
				{
					char.run(nowTime, diff);
				}
				else if (needRender <= 0)
				{ //控制指定帧数添加一个
					needRender=2;
					char.render=true;
					if (char.usable)
					{
						char.visible=true;
					}
				}
			}
			if (needSort)
			{
				needSort=false;
				sortDepth(diff);
			}
		}
		/***上一个索引*/
		private var preIndex:int=-1;
		/*** 当前索引*/
		private var currentIndex:int=0;

		/**
		 * 排序
		 * @param diff
		 *
		 */
		public function sortDepth(diff:uint):void
		{
			//priority 主角为-1 普通为0
			var len:int=_chars.length;
			var iter:int=0;
			var sc:SceneCharacter=null;
			_chars.sortOn(["sortScore", "x"], [Array.NUMERIC, Array.NUMERIC]);
			for (; iter != len; iter++)
			{
				sc=_chars[iter];
				if (!this.contains(sc.body))
				{
					continue;
				}
				if (preIndex == -1)
				{
					preIndex=this.getChildIndex(sc.body);
					continue;
				}
				currentIndex=this.getChildIndex(sc.body);
				if (currentIndex < preIndex)
				{
					this.setChildIndex(sc.body, Math.min(preIndex + 1, this.numChildren - 1));
					continue;
				}
				preIndex=currentIndex;
			}
		}

		/**
		 * 清理层
		 *
		 */
		public function dispose():void
		{
			removeChildren();
		}

		public function onStopRun():void
		{

		}

	}
}
