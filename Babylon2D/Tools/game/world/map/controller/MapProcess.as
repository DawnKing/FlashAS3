/**
 * Created by caijingxiao on 2017/7/17.
 */
package game.world.map.controller
{
    import easiest.managers.FrameManager;

    import game.world.map.model.MapData;
    import game.world.map.view.MapLayer;
    import game.world.base.controller.BaseProcess;

    public class MapProcess extends BaseProcess
    {
        private var _mapLayer:MapLayer;
        private var _mapData:MapData;

        public function MapProcess(mapLayer:MapLayer, mapData:MapData)
        {
            super(null);
            _mapLayer = mapLayer;
            _mapData = mapData;
        }

        override public function isProcess():Boolean
        {
            return _mapData.changed;
        }

        override public function process():void
        {
            var sysFrameFlag:uint = FrameManager.frameCount;
            //1.得到窗口的起始索引位置
            var vLeft:int=-(_mapData.layerRect.left - _mapData.viewPort.left);
            var vTop:int=-(_mapData.layerRect.top - _mapData.viewPort.top);
            //2.定位在哪一个cell索引位置
            var vStartIndexX:int=int(vLeft / _mapData.cellWidth);
            var vStartIndexY:int=int(vTop / _mapData.cellHeight);
            //3.得出a端，绘图区域的前段的邻居
            var v_aWidth:int=vLeft % _mapData.cellWidth;
            var v_aHeight:int=vTop % _mapData.cellHeight;
            //4.得到层的索引宽度
            var l_idxWidth:int=_mapData.layerRect.width / _mapData.cellWidth;
            var l_idxHeight:int=_mapData.layerRect.height / _mapData.cellHeight;
            if (_mapData.layerRect.width % _mapData.cellWidth != 0)
                l_idxWidth++;
            if (_mapData.layerRect.height % _mapData.cellHeight != 0)
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
            var endIndexX:int=(_mapData.layerRect.right - _mapData.viewPort.right) / _mapData.cellWidth;
            var endIndexY:int=(_mapData.layerRect.bottom - _mapData.viewPort.bottom) / _mapData.cellHeight;
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
//                    var tpx:int=cw * _mapData.cellWidth - v_aWidth;
//                    var tpy:int=ch * _mapData.cellHeight - v_aHeight;
                    var tpx:int=tx * _mapData.cellWidth;
                    var tpy:int=ty * _mapData.cellHeight;
                    _mapLayer.addCell(tx, ty, tpx, tpy, sysFrameFlag);
                    cw++; //列数自增
                    tpx+=_mapData.cellWidth; //累积列宽的定位
                }

                ch++; //行数自增
                cw=scw; //列数归零
            }

            _mapLayer.removeCell(sysFrameFlag);
        }
    }
}
