/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.base.model
{
    import com.adobe.utils.StringUtil;

    import common.consts.SharedDef;

    import easiest.debug.Assert;

    import flash.geom.Point;

    import tempest.data.map.WorldPostion;

    import tempest.data.obj.GuidObject;
    import tempest.enum.Status;

    public class EntityData
    {
        private var _name:String;
        private var _x:Number;
        private var _y:Number;
        private var _positionChanged:Boolean;
        private var _direction:int = -1; // 8方向
        private var _avatarDirection:int = -1; // avatar方向，需要镜像
        private var _directionChanged:Boolean;
        private var _horizontalFlip:Boolean;
        private var _status:int = Status.STAND;
        private var _statusChanged:Boolean;
        private var _body:int = -1;
        private var _bodyChanged:Boolean;
        private var _textName:String;
        private var _nameColor:uint;

        private var _guid:String;
        private var _uguid:uint;
        private var _templateId:uint;
        private var _mapId:uint;

        public static var tileWidth:int = 48;
        public static var tileHeight:int = 24;
        public var worldPosition:WorldPostion = new WorldPostion(tileWidth, tileHeight);

        public function EntityData()
        {
        }

        public function clear():void
        {
            _name = null;
            _x = NaN;
            _y = NaN;
            _positionChanged = false;
            _direction = -1;
            _avatarDirection = -1;
            _directionChanged = false;
            _status = Status.STAND;
            _statusChanged = false;
            _body = -1;
            _bodyChanged = false;
            _textName = null;
        }

        public function complete():void
        {
            _positionChanged = false;
            _directionChanged = false;
            _statusChanged = false;
            _bodyChanged = false;
        }

        public function setPosition(x:Number, y:Number):void
        {
            if (_x == x && _y == y)
                return;
            _x = x;
            _y = y;
            _positionChanged = true;
        }

        public function get positionChanged():Boolean
        {
            return _positionChanged;
        }

        public function get name():String
        {
            return _name;
        }

        public function set name(value:String):void
        {
            _name = value;
            if (_textName == null)
                _textName = value;
        }

        public function get status():int
        {
            return _status;
        }

        public function set status(value:int):void
        {
            if (_status == value)
                return;
            _status = value;
            _statusChanged = true;
        }

        public function get statusChanged():Boolean
        {
            return _statusChanged;
        }

        public function get direction():int
        {
            return _direction;
        }

        public function set direction(value:int):void
        {
            if (_direction == value)
                return;
            Assert.assertTrue("方向应该在0-7之间", value >= 0 && value < 8);
            _direction = value;
            _directionChanged = true;

            if (_status != Status.DEAD)
            {
                _avatarDirection=((_direction > 4) ? (8 - _direction) : _direction);
            }
            else //死亡只有两个朝向
            {
                _avatarDirection=(_direction > 4) ? 3 : 1;
            }

            _horizontalFlip = _direction > 4;
        }

        public function get bodyChanged():Boolean
        {
            return _bodyChanged;
        }

        public function get body():int
        {
            return _body;
        }

        public function set body(value:int):void
        {
            if (_body == value)
                return;
            _body = value;
            _bodyChanged = true;
        }

        public function get directionChanged():Boolean
        {
            return _directionChanged;
        }

        public function get textName():String
        {
            return _textName;
        }

        public function set textName(value:String):void
        {
            _textName = value;
        }

        public function get nameColor():uint
        {
            return _nameColor;
        }

        public function set nameColor(value:uint):void
        {
            _nameColor = value;
        }

        public function get x():Number
        {
            return _x;
        }

        public function get y():Number
        {
            return _y;
        }

        public function get tile():Point
        {
            return worldPosition.tile;
        }

        public function get tileX():Number
        {
            return worldPosition.tileX;
        }

        public function get tileY():Number
        {
            return worldPosition.tileY;
        }

        public function getTileDir(tx:Number, ty:Number):int
        {
            return worldPosition.getTileDir(tx, ty);
        }

        public function init(guidObject:GuidObject):void
        {
            _guid = guidObject.guid;
            _uguid = guidObject.uguid;
            _templateId = guidObject.GetUInt16(SharedDef.UNIT_FIELD_UINT16_0, 0);
            _mapId = guidObject.GetUInt16(SharedDef.UNIT_FIELD_UINT16_1, 0);
        }

        public function get templateId():uint
        {
            return _templateId;
        }

        public function get guid():String
        {
            return _guid;
        }

        public function get avatarDirection():int
        {
            return _avatarDirection;
        }

        public function get horizontalFlip():Boolean
        {
            return _horizontalFlip;
        }

        private static const toStr:String = "  name:{0}, x:{1}, y:{2}\n" +
            "  dir:{3}, status:{4}, body: {5}\n" +
            "  guid:{6}, tpltId: {7}\n";
        private static const toStr2:String = "  wposX:{0}, wposY:{1}, wposTX:{2}, wposTY:{3}\n";
        public function toString():String
        {
            var str:String = StringUtil.format(toStr, _textName, _x, _y,
                _direction, _status, _body,
                _guid, _templateId);
            str += StringUtil.format(toStr2, worldPosition.pixelX, worldPosition.pixelY, worldPosition.tileX, worldPosition.tileY);
            return str;
        }

        public function get uguid():uint
        {
            return _uguid;
        }

        public function get mapId():uint
        {
            return _mapId;
        }
    }
}
