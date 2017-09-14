/**
 * Created by caijingxiao on 2017/6/15.
 */
package easiest.rendering.sprites.atlas
{
    import easiest.rendering.materials.textures.SubTexture;

    import flash.geom.Matrix;
    import flash.geom.Rectangle;

    public class PngAnimation extends PngSpriteAtlas
	{
		private static const ImgMirror:Array=[0, 1, 2, 3, 4, 3, 2, 1];

		public var action:int=-1;
		public var direction:int;
		public var totalFrame:int;

		private var _index:Number=0;

		public function PngAnimation(url:String)
		{
			super(url, null);
			_url=url;
		}

		override public function render(matrix:Matrix):void
		{
			if (_atlas == null)
				return;

			var index:int=int(_index);
			var subTexture:SubTexture;
			var horizontalFlip:Boolean=false;
			if (action == -1)
			{
				subTexture=_atlas.getSubTexture(index);
			}
			else
			{
				var dir:int=direction;
				if (direction > 4)
				{
					dir=ImgMirror[direction];
					horizontalFlip=true;
				}
				subTexture=_atlas.getSubTexture(action, dir, index);
			}

			if (subTexture == null)
			{
//                Log.error(_url + "subTexture error " + action + dir + index, this);
				return;
			}

			var frame:Rectangle=subTexture.frame;

			if (horizontalFlip)
				_sprite.x=x + (frame.width + frame.x - subTexture.width);
			else
				_sprite.x=x - frame.x;
			_sprite.y=y - frame.y;

            setSubTextureData(subTexture);

			if (action == -1)
			{
				_sprite.render(matrix);
			}
			else
			{
				_sprite.horizontalFlip=horizontalFlip;
				_sprite.render(matrix);
			}

			_index+=0.2;
			if (_index >= totalFrame)
				_index=0;
		}
	}
}
