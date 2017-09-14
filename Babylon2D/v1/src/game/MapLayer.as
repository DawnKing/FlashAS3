/**
* Created by caijingxiao on 2017/6/19.
*/
package game
{
    import babylon.Scene;

    import flash.display.Stage;

    public class MapLayer
    {
        private static const Block_Offset:uint=1;
        private var _rowCount:uint=0;
        private var _colCount:uint=0;
        private var _maxColCount:uint;

        protected var _objs:Array = [];
        private var _scene:Scene;

        public static var x:Number = 0;
        public static var y:Number = 0;

        public function MapLayer(scene:Scene)
        {
            _scene = scene;
        }

        public function onResize(stage:Stage):void
        {
            this._maxColCount=Math.ceil(MapConfig.CUR_MAP_WIDTH / MapConfig.JPG_SIZE);
            this._rowCount=Math.ceil(stage.stageHeight / MapConfig.JPG_SIZE) + Block_Offset * 2;
            this._colCount=Math.ceil(stage.stageWidth / MapConfig.JPG_SIZE) + Block_Offset * 2;
            var maxIndex:uint = _rowCount * _colCount;
            var index:int = maxIndex - _objs.length;
            if (index > 0)
            {
                var i:int = 0;
                while (i < index)
                {
                    var mapBlock:MapBlock=new MapBlock(_scene);
                    addObj(mapBlock);
                    i++;
                }
            }
            this.refreshAllBlockIndex();
        }

        private function refreshAllBlockIndex():void
        {
            var xIndex:int = 0;
            var yIndex:int = 0;
            while (xIndex < this._rowCount)
            {
                yIndex = 0;
                while (yIndex < this._colCount)
                {
                    var mapBlock:MapBlock = _objs[xIndex * _colCount + yIndex] as MapBlock;
                    mapBlock.xIndex = xIndex;
                    mapBlock.yIndex = yIndex;
                    yIndex++;
                }
                xIndex++;
            }
        }

        public function render(posX:Number, posY:Number):void
        {
            var blockWidth:Number = MapConfig.JPG_SIZE;
            var startX:Number = Math.ceil(posX / blockWidth) - Block_Offset;
            var startY:Number = Math.ceil(posY / blockWidth) - Block_Offset;
            startX = startX > 0 ? startX : 0;
            startY = startY > 0 ? startY : 0;
            var x:int = 0;
            var y:int = 0;
            while (y < _rowCount)
            {
                var indexY: int = startY + y;
                var iterX:int = 0;
                while (iterX < _colCount)
                {
                    var indexX:int = startX + iterX;
                    var block:MapBlock = _objs[y * _colCount + iterX] as MapBlock;
                    if (iterX == 0)
                    {
                        x=indexY * _maxColCount;
                    }
                    block.x = blockWidth * indexX + MapLayer.x;
                    block.y = blockWidth * indexY + MapLayer.y;
                    block.imgIndex=x + indexX;
                    iterX++;
                }
                y++;
            }
        }

        public function addObj(mapBlock:MapBlock):void
        {
            _objs.push(mapBlock);
        }

        public function getRenderingBlockCnt():int
        {
            return this._rowCount * this._colCount;
        }
    }
}

import babylon.Scene;
import babylon.sprites.Map2D;

import easiest.managers.AssetData;
import easiest.managers.AssetManager;
import easiest.managers.AssetType;

import flash.display.BitmapData;

class MapConfig
{
    public static const CELL_WIDTH:int=48;
    public static const CELL_HEIGHT:int=24;
    public static const JPG_SIZE:uint=512;
    public static var CUR_MAP_WIDTH:uint = 4348;
    public static var CUR_MAP_HEIGHT:uint = 2390;
    public static var JPG_BLOCK_COUNT:uint = Math.ceil(CUR_MAP_WIDTH / JPG_SIZE) * Math.ceil(CUR_MAP_HEIGHT / JPG_SIZE);
    public static const HALF_CELL_WIDTH:int=CELL_WIDTH * 0.5;
    public static const HALF_CELL_HEIGHT:int=CELL_HEIGHT * 0.5;
}

class MapBlock
{
    private var _xIndex:int=0;
    private var _yIndex:int=0;
    private var _imgIndex:int = -1;

    private var _map2d:Map2D;
    private var _scene:Scene;

    public function MapBlock(scene:Scene)
    {
        super();
        _scene = scene;
    }

    public function get xIndex():int
    {
        return _xIndex;
    }

    public function set xIndex(index:int):void
    {
        _xIndex = index;
    }

    public function get yIndex():int
    {
        return this._yIndex;
    }

    public function set yIndex(index:int):void
    {
        this._yIndex = index;
    }

    public function set imgIndex(imgIndex:int):void
    {
        if (_imgIndex != imgIndex)
        {
            _imgIndex=imgIndex;
            if (_imgIndex >= 0 && _imgIndex < MapConfig.JPG_BLOCK_COUNT)
            {
                var x:int = imgIndex % (Math.ceil(MapConfig.CUR_MAP_WIDTH / MapConfig.JPG_SIZE));
                var y:int = imgIndex / (Math.ceil(MapConfig.CUR_MAP_WIDTH / MapConfig.JPG_SIZE));
                var url:String = "res/maps/" + y + "_" + x + ".png";

                AssetManager.load(url, onLoadMap, AssetType.BITMAP_DATA);
            }
        }
    }

    private function onLoadMap(asset:AssetData):void
    {
        if (asset.asset == null)
            return;
        _map2d = new Map2D(_scene);
        _scene.addMap2D(_map2d);
        _map2d.setTexture(asset.asset as BitmapData);
    }

    public function set x(value:Number):void
    {
        if (_map2d == null)
            return;
        _map2d.x = value;
    }

    public function set y(value:Number):void
    {
        if (_map2d == null)
            return;
        _map2d.y = value;
    }
}
