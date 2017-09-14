package tempest.engine.graphics {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import tempest.core.IDisposable;

	public class TPBitmap implements IDisposable {
		public var bitmapData:BitmapData;
		/**
		 *
		 */
		public var offset_x:int;
		/**
		 *
		 */
		public var offset_y:int;

		public function TPBitmap(bitmapData:BitmapData = null, offsetX:int = 0, offsetY:int = 0):void {
			this.bitmapData = bitmapData;
			this.offset_x = offsetX;
			this.offset_y = offsetY;
		}

		/**
		 * 获取Y轴镜像
		 * @param w 图像原始宽
		 * @return 返回Y轴镜像
		 */
		public function getYMI(w:int):TPBitmap {
			var bd:BitmapData = new BitmapData(this.bitmapData.width, this.bitmapData.height, this.bitmapData.transparent, 0x0);
			bd.draw(this.bitmapData, new Matrix(-1, 0, 0, 1, bd.width));
			return new TPBitmap(bd, w - offset_x - bd.width, offset_y);
		}

		public function draw(bd:BitmapData):void {
			bd.draw(bitmapData, new Matrix(1, 0, 0, 1, offset_x, offset_y));
		}

		public function drawYMI(bd:BitmapData):void {
			bd.draw(bitmapData, new Matrix(-1, 0, 0, 1, bd.width - offset_x, offset_y));
		}

		public function updateBM(bm:Bitmap, rpX:int = 0, rpY:int = 0, _verticalChange:Number = 0):void {
			if (bm.bitmapData == this.bitmapData) {
				return;
			}
			bm.x = offset_x - rpX;
			bm.y = offset_y - rpY + _verticalChange;
			bm.bitmapData = this.bitmapData;
		}

		/**
		 * 前 
		 * @param bm
		 * @param rpX
		 * @param rpY
		 * @param _verticalChange
		 * @param dir
		 * 
		 */		
		public function updateBM4(bm:Bitmap, rpX:int = 0, rpY:int = 0, _verticalChange:Number = 0, dir:int = 0):void {
			if (bm.bitmapData == this.bitmapData) {
				return;
			}
			switch (dir) {
				case 0:
					rpY += offset_dis;
					break;
				case 1:
					rpY += offset_dis;
					rpX -= offset_dis;
					break;
				case 2:
					rpX -= offset_dis;
					break;
				case 3:
					rpY -= offset_dis;
					rpX -= offset_dis;
					break;
				case 4:
					rpY -= offset_dis;
					break;
				case 5:
					rpY -= offset_dis;
					rpX += offset_dis;
					break;
				case 6:
					rpX += offset_dis;
					break;
				case 7:
					rpY += offset_dis;
					rpX += offset_dis;
					break;
			}
			bm.x = offset_x - rpX;
			bm.y = offset_y - rpY + _verticalChange;
			bm.bitmapData = this.bitmapData;
		}
		/**
		 * 后 
		 * @param bm
		 * @param rpX
		 * @param rpY
		 * @param _verticalChange
		 * @param dir
		 * 
		 */		
		public function updateBM5(bm:Bitmap, rpX:int = 0, rpY:int = 0, _verticalChange:Number = 0, dir:int = 0):void{
			if (bm.bitmapData == this.bitmapData) {
				return;
			}
			switch (dir) {
				case 0:
					rpY += offset_dis;
					break;
				case 1:
					rpY += offset_dis;
					rpX -= offset_dis;
					break;
				case 2:
					rpX -= offset_dis;
					break;
				case 3:
					rpY -= offset_dis;
					rpX -= offset_dis;
					break;
				case 4:
					rpY -= offset_dis;
					break;
				case 5:
					rpY -= offset_dis;
					rpX += offset_dis;
					break;
				case 6:
					rpX += offset_dis;
					break;
				case 7:
					rpY += offset_dis;
					rpX += offset_dis;
					break;
			}
			bm.x = offset_x - rpX;
			bm.y = offset_y - rpY + _verticalChange;
			bm.bitmapData = this.bitmapData;
		}
		public var offset_dis:int = 20;

		/**
		 * 右 
		 * @param bm
		 * @param rpX
		 * @param rpY
		 * @param _verticalChange
		 * @param dir
		 * 
		 */	    
		public function updateBM2(bm:Bitmap, rpX:int = 0, rpY:int = 0, _verticalChange:Number = 0, dir:int = 0):void {
			if (bm.bitmapData == this.bitmapData) {
				return;
			}
			switch (dir) {
				case 0:
					rpX -= offset_dis;
					break;
				case 1:
					rpY -= offset_dis * 0.6;
					rpX -= offset_dis * 0.6;
					break;
				case 2:
					rpY -= offset_dis * 0.5;
					break;
				case 3:
					rpY -= offset_dis * 0.6;
					rpX += offset_dis * 0.6;
					break;
				case 4:
					rpX += offset_dis;
					break;
				case 5:
					rpY += offset_dis * 0.6;
					rpX += offset_dis * 0.6;
					break;
				case 6:
					rpY += offset_dis * 0.5;
					break;
				case 7:
					rpY += offset_dis * 0.6;
					rpX -= offset_dis * 0.6;
					break;
			}
			bm.x = offset_x - rpX;
			bm.y = offset_y - rpY + _verticalChange;
			bm.bitmapData = this.bitmapData;
		}

		/**
		 * 左 
		 * @param bm
		 * @param rpX
		 * @param rpY
		 * @param _verticalChange
		 * @param dir
		 * 
		 */		
		public function updateBM3(bm:Bitmap, rpX:int = 0, rpY:int = 0, _verticalChange:Number = 0, dir:int = 0):void {
			if (bm.bitmapData == this.bitmapData) {
				return;
			}
			switch (dir) {
				case 0:
					rpX += offset_dis;
					break;
				case 1:
					rpY += offset_dis * 0.6;
					rpX += offset_dis * 0.6;
					break;
				case 2:
					rpY += offset_dis * 0.5;
					break;
				case 3:
					rpY += offset_dis * 0.6;
					rpX -= offset_dis * 0.6;
					break;
				case 4:
					rpX -= offset_dis;
					break;
				case 5:
					rpY -= offset_dis * 0.6;
					rpX -= offset_dis * 0.6;
					break;
				case 6:
					rpY -= offset_dis * 0.5;
					break;
				case 7:
					rpY -= offset_dis * 0.6;
					rpX += offset_dis * 0.6;
					break;
			}
			bm.x = offset_x - rpX;
			bm.y = offset_y - rpY + _verticalChange;
			bm.bitmapData = this.bitmapData;
		}

		public function getRect():Rectangle {
			if (bitmapData)
				return new Rectangle(offset_x, offset_y, bitmapData.width, bitmapData.height);
			return null;
		}

		public function dispose():void {
			if (this.bitmapData) {
				this.bitmapData.dispose();
				this.bitmapData = null;
			}
		}

		public function clone():TPBitmap {
			return new TPBitmap(bitmapData.clone(), offset_x, offset_y);
		}
	}
}
