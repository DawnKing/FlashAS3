package game.scene.map
{
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;
    
    import tempest.core.ICamera;
	
	/**
	 * 地图分块显示区域
	 * @author qihei
	 *
	 */
	public class E2DMapLayer extends SpriteContainer
	{

		/**是否启用扁平化*/
		public var enableFlatten:Boolean=true;
		/**层总宽度*/
		protected var _layerRect:Rectangle=new Rectangle();
		/**层级视口区域*/
		protected var _viewPort:Rectangle;
		protected var offsetx:int;
		protected var offsety:int;

		public function get viewPort():Rectangle
		{
			return _viewPort;
		}
		/**单元格宽度和高度*/
		private var _cellWidth:uint;
		private var _cellHeight:uint;
		/*是否发生了改变*/
		private var _isChanged:Boolean=true;
		//最后完成时间
		private var _lastDrawCompleteTime:int;
		protected var _isInited:Boolean;

		public function get isInited():Boolean
		{
			return _isInited;
		}


		public function E2DMapLayer()
		{
			super();
			_viewPort=new Rectangle();
			_isInited=false;
		}

		protected function init(x:int, y:int, lw:uint, lh:uint, cellWidth:uint, cellHeight:uint):void
		{
			offsetx=x;
			offsety=y;
			_layerRect.width=lw;
			_layerRect.height=lh;
			_cellWidth=cellWidth;
			_cellHeight=cellHeight;
			_isChanged=true;
			//是否初始化
			_isInited=true;
		}

		/**
		 * 设置视口大小
		 */
		public function setViewPort(pX:int, pY:int, pwidth:uint, pheight:uint):void
		{
			if (pwidth == _viewPort.width && pheight == _viewPort.height && pX == _viewPort.x && pY == _viewPort.y)
				return;

			_isChanged=true;
			_viewPort.x=pX + offsetx;
			_viewPort.y=pY + offsety;
			_viewPort.width=pwidth;
			_viewPort.height=pheight;
		}

		/**
		 * 通过摄像机设置窗口位置
		 * @param camera
		 *
		 */
		public function setViewPortByCamera(camera:ICamera):void
		{
			setViewPort(camera.rect.x, camera.rect.y, camera.rect.width, camera.rect.height);
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
			_isChanged=true;
			_layerRect.x=newX;
			_layerRect.y=newY;
		}


		/**
		 * 强制失效
		 *
		 */
//		public function failure():void
//		{
//			_isChanged=true;
//		}

		/**
		 * 是否绘制完成
		 * @return
		 *
		 */
		public function get isDrawComplete():Boolean
		{
			return !_isChanged;
		}

		/*绘制底图*/
		public function update(sysFrameFlag:uint):void
		{
			//没有改变，并且所有都下载完毕，则不需要进入以下循环
			if (isDrawComplete)
			{
				return;
			}
			//绘制前
			onBeforDraw(sysFrameFlag);
			//1.得到窗口的起始索引位置
			var vLeft:int=-(_layerRect.left - _viewPort.left);
			var vTop:int=-(_layerRect.top - _viewPort.top);
			//2.定位在哪一个cell索引位置
			var vStartIndexX:int=int(vLeft / _cellWidth);
			var vStartIndexY:int=int(vTop / _cellHeight);
			//3.得出a端，绘图区域的前段的邻居
			var v_aWidth:int=vLeft % _cellWidth;
			var v_aHeight:int=vTop % _cellHeight;
			//4.得到层的索引宽度
			var l_idxWidth:int=_layerRect.width / _cellWidth;
			var l_idxHeight:int=_layerRect.height / _cellHeight;
			if (_layerRect.width % _cellWidth != 0)
				l_idxWidth++;
			if (_layerRect.height % _cellHeight != 0)
				l_idxHeight++;
			//5.得出偏移量
			l_idxWidth-=vStartIndexX;
			l_idxHeight-=vStartIndexY;
			//6.起始位置负数则跳过
			var scw:int=0;
			var sch:int=0;
			if (vStartIndexX < 0)
				scw=Math.abs(vStartIndexX);
			if (vStartIndexY < 0)
				sch=Math.abs(vStartIndexY);
			//7.结束位置超过就跳过
			var endIndexX:int=(_layerRect.right - _viewPort.right) / _cellWidth;
			var endIndexY:int=(_layerRect.bottom - _viewPort.bottom) / _cellHeight;
			if (endIndexX > 0)
				l_idxWidth-=endIndexX;
			if (endIndexY > 0)
				l_idxHeight-=endIndexY;

			/////////// 这个位置铺的是面对视口的铺装方式 ////////////
			var cw:int=scw;
			var ch:int=sch;
			while (ch < l_idxHeight)
			{
				while (cw < l_idxWidth)
				{
					var tx:int=vStartIndexX + cw;
					var ty:int=vStartIndexY + ch;
					var tpx:int=cw * _cellWidth - v_aWidth;
					var tpy:int=ch * _cellHeight - v_aHeight;
					onCellEach(tx, ty, tpx, tpy, sysFrameFlag);
					cw++; //列数自增
					tpx+=_cellWidth; //累积列宽的定位
				}

				ch++; //行数自增
				cw=scw; //列数归零	
			}

			//没有击中的都移除掉
			for (var i:int=0; i < numChildren; i++)
			{
				var image:E2DMapPart=getChildAt(i) as E2DMapPart;
				if (image.userTag != sysFrameFlag)
				{
					onChildRemove(removeChildAt(i));
					i--;
				}
			}

			onAtferDrow(sysFrameFlag);
			//最后完成渲染时间
			_lastDrawCompleteTime=getTimer();
		}

		//子被移除
		protected function onChildRemove(target:SpriteObject):void
		{

		}

		/**
		 * 绘制前
		 *
		 */
		protected function onBeforDraw(sysFrameFlag:uint):void
		{
			//重算了
			_isChanged=false;
		}

		/**
		 * 每个格子循环到达时都触发
		 * @param tx 单元格子x
		 * @param ty 单元格子y
		 * @param tpx 新的格子坐标x
		 * @param tpy 新的格子坐标y
		 * @param sysFrameFlag 帧标记
		 *
		 */
		protected function onCellEach(tx:int, ty:int, tpx:int, tpy:int, sysFrameFlag:uint):void
		{
			throw new Error("子类未实现");
		}

		protected function onAtferDrow(sysFrameFlag:uint):void
		{

		}


		//清理地图切片
		public function clear():void
		{
			while (numChildren)
				removeChildAt(0, true);
		}
	}
}
