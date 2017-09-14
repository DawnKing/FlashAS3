/**
 * Created by caijingxiao on 2017/6/23.
 */
package easiest.rendering.sprites.text
{
    import easiest.rendering.materials.textures.BaseTexture;
    import easiest.rendering.materials.textures.BitmapTexture;
    import easiest.rendering.sprites.*;

    public class BitmapText extends Sprite2D
    {
        private var _textData:TextData;

        public function BitmapText(textData:TextData, texture:BaseTexture)
        {
            super();

            _textData = textData;
            textData.addListener(onUpdateTexture);
            setTextData(textData);
            setTexture(texture);
        }

        override public function dispose():void
        {
            _textData.removeListener(onUpdateTexture);
            _textData = null;
            super.dispose();
        }

        private function onUpdateTexture(baseTexture:BitmapTexture):void
        {
            setTexture(baseTexture);
        }

        private function setTextData(textData:TextData):void
        {
            width = textData.width;
            height = textData.height;
            u = textData.u;
            v = textData.v;
            uvWidth = textData.uvWidth;
            uvHeight = textData.uvHeight;
        }
    }
}
