/**
	 * Created by caijingxiao on 2016/11/10.
	 */
package easiest.rendering.materials.textures
{
    import flash.display3D.textures.Texture;
    
    import easiest.rendering.Engine;

    public class AtfTexture extends BaseTexture
	{
		private var _format:String;

		public function AtfTexture(onUpdate:Function, atfData:AtfData)
		{
			super(onUpdate);

			if (atfData != null)
                upload(atfData);
		}

		public function upload(atfData:AtfData):void
		{
			_format = atfData.format;

			if (width != atfData.width || height != atfData.height)
			{
				if (texture != null)
					texture.dispose();

				var newTexture:Texture=Engine.inst.CreateAtfTexture(atfData);
				setTexture(newTexture, atfData.width, atfData.height);
			}
			else
			{
				texture.uploadCompressedTextureFromByteArray(atfData.data, 0);
				updateTexture(atfData.width, atfData.height);
			}
		}

        override public function get format():String
        {
            return _format;
        }
    }
}
