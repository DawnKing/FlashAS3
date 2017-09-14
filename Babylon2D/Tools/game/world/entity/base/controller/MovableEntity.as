/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.base.controller
{
    import flash.geom.Point;

    import game.world.entity.base.model.EntityMove;
    import game.world.entity.base.model.MovableData;

    import tempest.enum.Status;

    public class MovableEntity extends Entity
    {
        public function MovableEntity()
        {
            super();
        }

        public function get movableData():MovableData
        {
            return _data as MovableData;
        }

        public function updateMove(diff:Number, move:EntityMove):void
        {
            var data:MovableData = movableData;
            if (move.pathList.length == 0)
            {
                if (data.status == Status.WALK)
                    data.status = Status.STAND;
                return;
            }

            var ssf:Number = diff / move.speed;
            stepDistance(data, ssf, move);
            faceToTile(data.currentTile.x, data.currentTile.y);
            if (data.status != Status.WALK)
            {
                data.status = Status.WALK;
            }
            setPosition(data.currentTile.x, data.currentTile.y);
        }

        public function setPosition(x:Number, y:Number):void
        {
            movableData.worldPosition.tileX=x;
            movableData.worldPosition.tileY=y;
            movableData.setPosition(movableData.worldPosition.pixelX, movableData.worldPosition.pixelY);
        }

        public function faceToTile1(point:Point):void
        {
            movableData.direction=movableData.worldPosition.getTileDir(point.x, point.y);
        }

        public function faceToTile(x:Number, y:Number):void
        {
            movableData.direction=movableData.worldPosition.getTileDir(x, y);
        }

        private function stepDistance(data:MovableData, ssf:Number, move:EntityMove):void
        {
            var targetTile:Point;
            var throughTile:Point;
            var dis:Number;
            data.currentTile = data.worldPosition.tile.clone();
            data.throughTileArr.length=0;
            var pathArr:Array=move.pathList;
            while (true)
            {
                targetTile=pathArr[0];
                dis=Point.distance(data.currentTile, targetTile);
                if (dis > ssf) //不足以到达
                {
                    data.currentTile.x+=(targetTile.x - data.currentTile.x) * ssf / dis;
                    data.currentTile.y+=(targetTile.y - data.currentTile.y) * ssf / dis;
                    return;
                }
                if (dis == ssf) //刚好到达目标点
                {
                    data.currentTile.x=targetTile.x;
                    data.currentTile.y=targetTile.y;
                    return;
                }
                throughTile=pathArr.shift();
                data.throughTileArr.push(throughTile);
                data.currentTile.x=targetTile.x;
                data.currentTile.y=targetTile.y;
                ssf-=dis;
                if (pathArr.length == 0)
                {
                    return;
                }
            }
        }

        override public function update():void
        {
            // 先设坐标，avatar里面需要设置偏移
            if (movableData.positionChanged)
            {
                _avatar.x = movableData.worldPosition.pixelX;
                _avatar.y = movableData.worldPosition.pixelY;
            }
            super.update();
        }

        public function inDistance(point:Point, distance:int):Boolean
        {
            var result:Number = movableData.worldPosition.getDistance(point.x, point.y);
            return result <= distance;
        }
    }
}
