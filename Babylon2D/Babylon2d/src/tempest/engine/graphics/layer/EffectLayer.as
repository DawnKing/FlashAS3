package tempest.engine.graphics.layer
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	import tempest.engine.graphics.animation.Animation;

	public class EffectLayer extends Sprite  
	{
		public function EffectLayer()
		{
			super();
			this.tabEnabled=this.tabChildren=this.mouseChildren=this.mouseEnabled=false;
		}

		public function addEffect(displayObject:DisplayObject):void
		{
			this.addChild(displayObject);
		}

		/**
		 * 清空容器
		 */
		public function dispose():void
		{
			while (this.numChildren > 0)
			{
				var displayObject:DisplayObject=this.getChildAt(0);
				if (displayObject is Animation)
				{
					Animation.free(Animation(displayObject));
				}
				else
				{
					this.removeChildAt(0);
				}
			}
		}
	}
}
