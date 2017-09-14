/**
* Created by caijingxiao on 2017/6/19.
*/
package {
    import flash.display.Stage;
    import flash.geom.Rectangle;
    
    import easiest.core.Log;
    import easiest.rendering.sprites.SpriteContainer;
    
    import tempest.core.ICamera;

    public class MapLayer extends SpriteContainer
	{
		private static const Block_Offset:uint=1;
		private var _rowCount:uint=0;
		private var _colCount:uint=0;
		private var _maxColCount:uint;

		protected var _mapBlocks:Array=[];
        protected var _viewPort:Rectangle = new Rectangle();
        private var _isChanged:Boolean=false;

		public function MapLayer()
		{
		}

        public function onResize(stage:Stage):void
		{
			_maxColCount=Math.ceil(MapConfig.CUR_MAP_WIDTH / MapConfig.JPG_SIZE);
			_rowCount=Math.ceil(stage.stageHeight / MapConfig.JPG_SIZE) + Block_Offset * 2;
			_colCount=Math.ceil(stage.stageWidth / MapConfig.JPG_SIZE) + Block_Offset * 2;
			var maxIndex:uint=_rowCount * _colCount;
			var index:int=maxIndex - _mapBlocks.length;
			if (index > 0)
			{
				var i:int=0;
				while (i < index)
				{
					var mapBlock:MapBlock=new MapBlock(this);
					addObj(mapBlock);
					i++;
				}
			}
			refreshAllBlockIndex();
		}

		private function refreshAllBlockIndex():void
		{
			var xIndex:int=0;
			var yIndex:int=0;
			while (xIndex < _rowCount)
			{
				yIndex=0;
				while (yIndex < _colCount)
				{
					var mapBlock:MapBlock=_mapBlocks[xIndex * _colCount + yIndex] as MapBlock;
					mapBlock.xIndex=xIndex;
					mapBlock.yIndex=yIndex;
					yIndex++;
				}
				xIndex++;
			}
		}

		public function renderMap(posX:Number, posY:Number):void
		{
			var blockWidth:Number=MapConfig.JPG_SIZE;
			var startX:Number=Math.ceil(posX / blockWidth) - Block_Offset;
			var startY:Number=Math.ceil(posY / blockWidth) - Block_Offset;
			startX=startX > 0 ? startX : 0;
			startY=startY > 0 ? startY : 0;
			var x:int=0;
			var y:int=0;
			while (y < _rowCount)
			{
				var indexY:int=startY + y;
				var iterX:int=0;
				while (iterX < _colCount)
				{
					var indexX:int=startX + iterX;
					var block:MapBlock=_mapBlocks[y * _colCount + iterX] as MapBlock;
					if (iterX == 0)
					{
						x=indexY * _maxColCount;
					}
					block.x=blockWidth * iterX;
					block.y=blockWidth * y;
					block.imgIndex=x + indexX;
					iterX++;
				}
				y++;
			}
		}

		public function addObj(mapBlock:MapBlock):void
		{
			_mapBlocks.push(mapBlock);
		}

		public function getRenderingBlockCnt():int
		{
			return _rowCount * _colCount;
		}

        public function setViewPortByCamera(camera:ICamera):void
        {
            setViewPort(camera.rect.x, camera.rect.y, camera.rect.width, camera.rect.height);
        }

        private var _moveX:Number;
        private var _moveY:Number;

        public function setViewPort(pX:int, pY:int, pwidth:uint, pheight:uint):void
        {
            if (pwidth == _viewPort.width && pheight == _viewPort.height && pX == _viewPort.x && pY == _viewPort.y)
                return;

            _isChanged=true;
            _viewPort.x=pX;
            _viewPort.y=pY;
            _viewPort.width=pwidth;
            _viewPort.height=pheight;

            _moveX = x - _viewPort.x;
            _moveY = y - _viewPort.y;
        }

        public function update(diff:Number):void
        {
			if (!_isChanged)
				return;
            var speed:Number = 200 * diff;    // 根据时间算速度
            var maxSpeed:Number = Math.sqrt(_moveX*_moveX+_moveY*_moveY);  // 矢量最大速度
			var spdX:Number, spdY:Number;
            if (speed >= maxSpeed)
            {
                spdX = _moveX;
                spdY = _moveY;
            }
            else
            {
                var rate:Number = speed / maxSpeed;
                spdX = _moveX * rate;
                spdY = _moveY * rate;
            }

			_moveX -= spdX;
			_moveY -= spdY;
			if (_moveX == 0 && _moveY == 0)
				_isChanged = false;

            for each (var mapBlock:MapBlock in _mapBlocks)
            {
                mapBlock.x+=spdX;
                mapBlock.y+=spdY;
            }
        }

        public function clear():void
        {
            Log.log("clear", this);
        }

        public function setPartSize(sliceWidth:int, sliceHeight:int):void
        {
            Log.log("setPartSize", this);
        }

        public function initMapPartLayer(offsetx:int, offsety:int, pxWidth:int, pxHeight:int, urlFormat:String, thum:*, thumbScale:Number):void
        {
            Log.log("initMapPartLayer", this);
        }
	}
}

import easiest.managers.load.AssetData;
import easiest.managers.load.AssetManager;
import easiest.managers.load.AssetType;
import easiest.rendering.materials.textures.BaseTexture;
import easiest.rendering.sprites.Sprite2D;
import easiest.rendering.sprites.SpriteContainer;

import game.GamePath;

class MapConfig
{
	public static const CELL_WIDTH:int=48;
	public static const CELL_HEIGHT:int=24;
	public static const JPG_SIZE:uint=512;
	public static var CUR_MAP_WIDTH:uint=4348;
	public static var CUR_MAP_HEIGHT:uint=2390;
	public static var JPG_BLOCK_COUNT:uint=Math.ceil(CUR_MAP_WIDTH / JPG_SIZE) * Math.ceil(CUR_MAP_HEIGHT / JPG_SIZE);
	public static const HALF_CELL_WIDTH:int=CELL_WIDTH * 0.5;
	public static const HALF_CELL_HEIGHT:int=CELL_HEIGHT * 0.5;
}

class MapBlock
{
	private var _xIndex:int=0;
	private var _yIndex:int=0;
	private var _imgIndex:int=-1;

	private var _sprite:Sprite2D;

	public function MapBlock(parent:SpriteContainer)
	{
		super();

		_sprite=new Sprite2D();
		parent.addChild(_sprite);
	}

	public function get xIndex():int
	{
		return _xIndex;
	}

	public function set xIndex(index:int):void
	{
		_xIndex=index;
	}

	public function get yIndex():int
	{
		return _yIndex;
	}

	public function set yIndex(index:int):void
	{
		_yIndex=index;
	}

	public function set imgIndex(imgIndex:int):void
	{
		if (_imgIndex != imgIndex)
		{
			_imgIndex=imgIndex;
			if (_imgIndex >= 0 && _imgIndex < MapConfig.JPG_BLOCK_COUNT)
			{
				var x:int=imgIndex % (Math.ceil(MapConfig.CUR_MAP_WIDTH / MapConfig.JPG_SIZE));
				var y:int=imgIndex / (Math.ceil(MapConfig.CUR_MAP_WIDTH / MapConfig.JPG_SIZE));
				if (BaseTexture.useAtf)
				{
                    var url:String=GamePath.Map + y + "_" + x + BaseTexture.atf;
                    AssetManager.load(url, onLoadMap, AssetType.BINARY, AssetType.CACHE_NONE, AssetType.SKIP_CHECK);
				}
				else
				{
                    url=GamePath.Map + y + "_" + x + ".png";
                    AssetManager.load(url, onLoadMap, AssetType.BITMAP_DATA, AssetType.CACHE_NONE, AssetType.SKIP_CHECK);
				}
			}
		}
	}

	private function onLoadMap(asset:AssetData):void
	{
		if (asset.asset == null)
			return;

		_sprite.width=MapConfig.JPG_SIZE;
		_sprite.height=MapConfig.JPG_SIZE;
		_sprite.setTexture(asset.asset);
	}

    public function get x():Number
    {
		return _sprite ? _sprite.x : 0;
    }

	public function set x(value:Number):void
	{
		if (_sprite == null)
			return;
		_sprite.x=value;
	}

    public function get y():Number
    {
        return _sprite ? _sprite.y : 0;
    }

    public function set y(value:Number):void
	{
		if (_sprite == null)
			return;
		_sprite.y=value;
	}
}
