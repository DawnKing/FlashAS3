/**
 * Created by caijingxiao on 2017/7/17.
 */
package game.world.map.model
{
    import flash.geom.Rectangle;

    public class MapData
    {
        /**单元格宽度和高度*/
        private var _cellWidth:uint;
        private var _cellHeight:uint;
        /**层总宽度*/
        private var _layerRect:Rectangle=new Rectangle();
        /**层级视口区域*/
        private var _viewPort:Rectangle=new Rectangle();
        /*是否发生了改变*/
        private var _changed:Boolean=true;

        private var _offsetX:int;
        private var _offsetY:int;

        /**切片宽度*/
        private var _partWidth:int;
        /**切片高度*/
        private var _partHeight:int;
        //路径格式
        private var _urlFormat:String;
        private var _mapPath:String;

        public function init(x:int, y:int, lw:uint, lh:uint, cellWidth:uint, cellHeight:uint, urlFormat:String, mapPath:String):void
        {
            _offsetX=x;
            _offsetY=y;
            _layerRect.width=lw;
            _layerRect.height=lh;
            _cellWidth=cellWidth;
            _cellHeight=cellHeight;
            _urlFormat = urlFormat;
            _mapPath = mapPath;

            _changed=true;
        }

        public function setViewPort(pX:int, pY:int, pwidth:uint, pheight:uint):void
        {
            if (pwidth == _viewPort.width && pheight == _viewPort.height && pX == _viewPort.x && pY == _viewPort.y)
                return;

            _changed=true;
            _viewPort.x=pX + _offsetX;
            _viewPort.y=pY + _offsetY;
            _viewPort.width=pwidth;
            _viewPort.height=pheight;
        }

        public function setPartSize(partWidth:int, partHeight:int):void
        {
            _partWidth=partWidth;
            _partHeight=partHeight;
        }

        /**
         * 设置层级的坐标
         * @param newX 新位置x
         * @param newY 新位置y
         *
         */
        public function setLayerLocation(newX:int, newY:int):void
        {
            if (_layerRect.x == newX && _layerRect.y == newY)
                return;
            _changed=true;
            _layerRect.x=newX;
            _layerRect.y=newY;
        }

        public function get cellWidth():uint
        {
            return _cellWidth;
        }

        public function get cellHeight():uint
        {
            return _cellHeight;
        }

        public function get layerRect():Rectangle
        {
            return _layerRect;
        }

        public function get viewPort():Rectangle
        {
            return _viewPort;
        }

        public function get changed():Boolean
        {
            return _changed;
        }

        public function get urlFormat():String
        {
            return _urlFormat;
        }

        public function get partHeight():int
        {
            return _partHeight;
        }

        public function get partWidth():int
        {
            return _partWidth;
        }

        public function get mapPath():String
        {
            return _mapPath;
        }

        public function get thumbUrl():String
        {
            return Config.getVersionUrl(_mapPath + "thumb.jpg");
        }

        public function get backgroundUrl():String
        {
            return Config.getVersionUrl(_mapPath + "background.jpg");
        }
    }
}
