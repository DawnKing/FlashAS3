/**
 * Created by caijingxiao on 2017/7/17.
 */
package game.world.map.view
{
    import com.adobe.utils.StringUtil;

    import easiest.managers.FrameManager;

    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;

    import flash.events.MouseEvent;

    import flash.utils.Dictionary;

    import game.base.Main;
    import game.world.battle.controller.AttackMonsterProcess;

    import game.world.map.model.MapData;
    import game.world.map.model.MapModel;

    public class MapLayer extends SpriteContainer
    {
        /*地图切片*/
        private var _cells:Dictionary=new Dictionary();
        //是否所有素材都加载完毕
        protected var _isNoAction:Boolean=false;

        private var _mapData:MapData;

        public function MapLayer()
        {
            _mapData = MapModel.mapData;

            mouseEnabled = false;
            mouseChildren = true;
            this.addEventListener(MouseEvent.CLICK, onClickMap);
        }


        public function clear():void
        {
            for each (var cell:MapCell in _cells)
            {
                cell.close();
            }
            _cells = new Dictionary(true);
        }

        private function onClickMap(event:MouseEvent):void
        {
            AttackMonsterProcess.stop();
            Main.stScene.moveToPixel(Main.stScene.curMouse);
        }

        public function addCell(tx:int, ty:int, tpx:int, tpy:int, sysFrameFlag:uint):void
        {
            var src:MapCell=getMapPart(tx, ty);
            //空切片就不添加了，不理会
            if (src.status != MapCell.STATUS_IS_EMPTY_PART)
            {
                //不存在就添加个新的
                if (!getChildByName(src.name))
                {
                    addChild(src);
                }
                src.x=tpx;
                src.y=tpy;
                src.userTag=sysFrameFlag;
                //地图切块加载完成
                if (!src.isNoAction)
                    _isNoAction=false;
            }
        }

        public function getMapPart(x:int, y:int):MapCell
        {
            var key:uint=(x << 6) + y;
            var mapPart:MapCell=_cells[key];
            if (!mapPart)
            {
                //获取素材路径
                var url:String=StringUtil.format(_mapData.urlFormat, y, x);
                //构造地图切片
                mapPart=new MapCell(url, key, _mapData.partWidth, _mapData.partHeight);
                _cells[key]=mapPart;
            }
            mapPart.lastVisiTime=FrameManager.time;
            return mapPart;
        }

        public function removeCell(sysFrameFlag:uint):void
        {
            //没有击中的都移除掉
            for (var i:int=0; i < numChildren; i++)
            {
                var image:MapCell=getChildAt(i) as MapCell;
                if (image.userTag != sysFrameFlag)
                {
                    onChildRemove(removeChildAt(i));
                    i--;
                }
            }
        }

        protected function onChildRemove(target:SpriteObject):void
        {
            var mp:MapCell=target as MapCell;
            mp.removeTextureBuffer();
        }
    }
}
