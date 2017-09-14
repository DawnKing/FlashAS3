/**
	 * Created by caijingxiao on 2016/11/10.
	 */
package easiest.rendering.materials.textures
{
	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	
	import easiest.rendering.Engine;

	public class BitmapTexture extends BaseTexture
	{
		public function BitmapTexture(onUpdate:Function, bitmapData:BitmapData=null)
		{
			super(onUpdate);

			if (bitmapData != null)
				upload(bitmapData);
		}

		public function upload(bitmapData:BitmapData):void
		{
			if (width != bitmapData.width || height != bitmapData.height)
			{
				if (texture != null)
					texture.dispose();

				var newTexture:Texture=Engine.inst.CreateBitmapTexture(bitmapData);
				setTexture(newTexture, bitmapData.width, bitmapData.height);
			}
			else
			{
				texture.uploadFromBitmapData(bitmapData);
				updateTexture(bitmapData.width, bitmapData.height);
			}
		}

        override public function get format():String
        {
            return Context3DTextureFormat.BGRA;
        }
    }
}
