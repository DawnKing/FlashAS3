package easiest.rendering.sprites.text
{
    import easiest.managers.TimerManager;
    import easiest.rendering.materials.textures.BitmapTexture;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.filters.GlowFilter;
    import flash.geom.Point;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;

    import tempest.data.find.TD;
    import tempest.utils.HtmlUtil;

    /**
	 * 文本管理器
	 * @author zhangyong
	 *
	 */
	public class E2DTextMgr
	{
        public static var inst:E2DTextMgr;

		private static var tf:TextFormat=new TextFormat("微软雅黑", 12);
		/*基础位图*/
		private var _baseBitmapData:BitmapData;
		private var _baseTexture:BitmapTexture;
		//位图数据发生改变
		private var _isBitmapDataChange:Boolean=false;
		/*绘制游标*/
		private var _drawCursor:Point=new Point(1, 1);
		private var _drawCursorHeight:int=0;
		private var _colorDic:Dictionary=new Dictionary();

		private var _textureWidth:Number=512;
		private var _textureHeight:Number=256;
		private var _initWidth:int;
		private var _initHeight:int;
		private const _minL:Number=256;
		private const _maxL:Number=2048;

//		private var _rect:Rectangle=new Rectangle();
		private var bgShape:Shape;
		private var bitmap:Bitmap;
		/**头顶文字管理类型*/
//		public var mgrtype:String;

		public function E2DTextMgr(w:int, h:int)
		{
			inst = this;
//			this.mgrtype=name;
			_textureWidth=_initWidth=w;
			_textureHeight=_initHeight=h;
			createdTexture(true);
			TimerManager.add(update, 1000);
		}

		private function createdTexture(up:Boolean):void
		{
//			if (!Starling.current.contextValid) //context丢失
//			{
//				return false;
//			}
			if (up)
			{
				if (_textureWidth <= _textureHeight && _textureWidth < _maxL)
				{
					_textureWidth=_textureWidth * 2;
				}
				else if (_textureHeight < _textureWidth && _textureHeight < _maxL)
				{
					_textureHeight=_textureHeight * 2;
				}
					//trace("[TextMgr]baseBitmapData 扩大画布当前 Width:", _textureWidth, "Height:", _textureHeight);
			}
			else
			{
				if (_textureWidth >= _textureHeight && _textureWidth > _minL)
				{
					_textureWidth=_textureWidth / 2;
				}
				else if (_textureHeight > _textureWidth && _textureHeight > _minL)
				{
					_textureHeight=_textureHeight / 2;
				}
					//trace("[TextMgr]baseBitmapData 缩小画布当前 Width:", _textureWidth, "Height:", _textureHeight);
			}
			if (_baseBitmapData)
			{
				_baseBitmapData.dispose();
				_baseBitmapData=null;
			}

//			if (_baseTexture)
//			{
//				_baseTexture.dispose();
//				_baseTexture=null;
//			}

			//创建贴图
			_baseBitmapData=new BitmapData(_textureWidth, _textureHeight, true, 0);

//			if (!Starling.current.contextValid) //context丢失
//			{
//				throw new Error("草泥马context3d半路上丢了。。。");
//			}
//			//获取贴图
//			_baseTexture=Texture.empty(_baseBitmapData.width, _baseBitmapData.height, true, false, false, 1, "bgra",false,false);
//			_baseTexture.root.onRestore=function():void
//			{
//				if (_baseTexture && _baseBitmapData)
//					_baseTexture.root.uploadBitmapData(_baseBitmapData);
//			};
			_baseTexture=new BitmapTexture(null);
		}


		private var _prevFullTime:int=0;

		/**
		 * 管理器心跳
		 *
		 */
		public function update(/*realCurrTime:uint, avgMs:int*/):void
		{
			//耗时
//			var ms:int=getTimer() - realCurrTime;
//			if (ms > (avgMs + 3)&&!_updateTexture)
//			{
//				//trace("[TextMgr] 主动退出，耗时ms:", ms, "> avgMs:", avgMs);
//				return;
//			}
			if (!_baseBitmapData) //释放了所有文字
			{
				return;
			}
			//画布已满需要重绘
			if (_drawCursor.y > (_baseBitmapData.height - 20)||_updateTexture)
			{
				var time:int=getTimer();
				var diff:int=time - _prevFullTime;
				if (diff < 0)
				{
					diff=int.MAX_VALUE - _prevFullTime + time;
				}

				if (diff < 2000)
				{
					//扩图
					createdTexture(true);
				}
				else if (diff > 20000||_updateTexture)
				{
					//缩图
					createdTexture(false);
				}

				//trace("[TextMgr]开始文本垃圾回收...");
				//清理位图
				_baseBitmapData.fillRect(_baseBitmapData.rect, 0);
				//回首前数量
				var prevCount:int, currentCount:int;
//				ms=getTimer();
				_drawCursor.x=1;
				_drawCursor.y=1;
				//重新绘制
				for each (var wordDic:Dictionary in _colorDic)
				{
					var textDataLen:uint=0;
					for each (var data:TextData in wordDic)
					{
						prevCount++;
						//有人引用则绘制到贴图里面
						if (data.refCounter)
						{
							draw(data);
							textDataLen++;
							currentCount++;
						}
						else
						{
							//没人引用这释放
							data.dispose();
							delete wordDic[data.text];
						}
					}

					//数量不存在，则移除
					if (textDataLen <= 0)
					{
						delete _colorDic[data.color];
					}

				}
				_updateTexture = false;
				_isBitmapDataChange=true;
				_prevFullTime=time;
					//trace("[TextMgr]回收完毕回收前" + prevCount + "个,回收后" + currentCount + "个.耗时:"+(getTimer() - ms));
			}

			if (_isBitmapDataChange)
			{
				_isBitmapDataChange=false;
//				ms=getTimer();
				//立即上传贴图
				_baseTexture.upload(_baseBitmapData);
				//trace("[TextMgr]素材有变,已上传至显卡.耗时:"+(getTimer() - ms));
			}
		}

		/**
		 * 获取文字贴图
		 * @param text
		 * @param color
		 * @param isBg 是否绘制背景
		 * @return
		 *
		 */
		public function createText(text:String, color:uint, isBg:Boolean=false):BitmapText
		{
			var textDic:Dictionary=_colorDic[color];
			if (!textDic)
			{
				textDic=new Dictionary();
				_colorDic[color]=textDic;
			}

			//如果存在，直接给贴图
			var data:TextData=textDic[text];
			if (data)
				return new BitmapText(data, _baseTexture);

			//不在则构建
			data=new TextData();
			data.text=text;
			data.color=color;
			data.isBg=isBg;
			draw(data);

			//位图改变标记
			_isBitmapDataChange=true;

			//放入字典
			textDic[text]=data;
			//返回贴图
			return new BitmapText(data, _baseTexture);
		}

		/**
		 * 绘制数据
		 * @param data
		 *
		 */
		private function draw(data:TextData):void
		{
			if (!_baseBitmapData)
			{
				createdTexture(false);
			}
			TD.TempTextField.autoSize=TextFieldAutoSize.LEFT;
			TD.TempTextField.filters=[BLACK];
			//开始准备绘制
			if (data.text.length > 10)
			{
				tf.leading=5;
				TD.TempTextField.multiline=true;
				TD.TempTextField.wordWrap=true;
				TD.TempTextField.width=200;
			}
			TD.TempTextField.htmlText=HtmlUtil.color(Hex2str(data.color), data.text); //html文本可以支持文字不同颜色
			TD.TempTextField.setTextFormat(tf);

			data.width=TD.TempTextField.textWidth + 8;
			data.height=TD.TempTextField.textHeight + 8;

			//游标y前进
			if ((_drawCursor.x + data.width) >= _baseBitmapData.width)
			{
				_drawCursor.x=1;
				_drawCursor.y+=_drawCursorHeight + 1;
				_drawCursorHeight=0;
			}

			TD.TemporaryMatrix.identity();
			TD.TemporaryMatrix.tx=_drawCursor.x + 3;
			TD.TemporaryMatrix.ty=_drawCursor.y + 3;
			if (data.isBg)
			{
				TD.TemporaryMatrix2.identity();
				TD.TemporaryMatrix2.tx=_drawCursor.x;
				TD.TemporaryMatrix2.ty=_drawCursor.y;
				//文字背景
				if (!bgShape)
				{
					bgShape=new Shape();
				}
				bgShape.graphics.clear();
				bgShape.graphics.beginFill(0x0, 0.4);
				bgShape.graphics.drawRoundRectComplex(0, 0, data.width, data.height, 4, 4, 4, 4);
				bgShape.graphics.endFill();
				bgShape.width=data.width;
				bgShape.height=data.height;
				_baseBitmapData.draw(bgShape, TD.TemporaryMatrix2);
			}
			//将文本画下来
			_baseBitmapData.draw(TD.TempTextField, TD.TemporaryMatrix);
//			_rect.x=_drawCursor.x;
//			_rect.y=_drawCursor.y;
//			_rect.width=data.width;
//			_rect.height=data.height;
			data.u = _drawCursor.x;
			data.v = _drawCursor.y;
			data.uvWidth = data.width;
			data.uvHeight = data.height;

			//游标x前进
			_drawCursor.x+=data.width + 2;
			_drawCursorHeight=Math.max(_drawCursorHeight, data.height);

            data.update(_baseTexture);
			//返回区域
//			return new SubTexture(_baseTexture, _rect);
		}

		/**
		 * 数字转字符串颜色
		 * @param value
		 * @return
		 *
		 */
		public static function Hex2str(value:uint):String
		{
			var v:String="000000000" + value.toString(16);
			return "#" + v.substr(v.length - 6);
		}

		/**
		 * 获取实际绘制的位图
		 * @return
		 *
		 */
		public function get baseBitmapData():Bitmap
		{
			if (!bitmap)
			{
				bitmap=new Bitmap(_baseBitmapData);
			}
			bitmap.bitmapData=_baseBitmapData;
			return bitmap;
		}

		/*清理*/
		public function clear():void
		{
			dispose();
		}

		public function dispose():void
		{
			if (_baseBitmapData)
			{
				_baseBitmapData.dispose();
				_baseBitmapData=null;
			}
			_drawCursor.x=0;
			_drawCursor.y=0;
			_drawCursorHeight=0;
			_textureWidth=_initWidth;
			_textureHeight=_initHeight;
//			if (_baseTexture)
//			{
//				_baseTexture.dispose();
//				_baseTexture=null;
//			}
			_colorDic=new Dictionary();
		}
		protected var _updateTexture:Boolean=false;

        private static var _BLACK:GlowFilter;

        /**黑色描边*/
        public static function get BLACK():GlowFilter
        {
            if (!_BLACK)
            {
                _BLACK=new GlowFilter(0x0, 0.8, 2, 2, 10, 1);
            }
            return _BLACK;
        }
	}
}
