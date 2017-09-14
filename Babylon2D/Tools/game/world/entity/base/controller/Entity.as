/**
 * Created by caijingxiao on 2017/7/18.
 */
package game.world.entity.base.controller
{
    import avmplus.getQualifiedClassName;

    import common.consts.ColorConst;
    import common.consts.SharedDef;

    import easiest.core.IClear;
    import easiest.debug.PrintAllDisplayObject;
    import easiest.managers.FrameManager;

    import flash.events.Event;

    import game.world.entity.base.model.EntityData;
    import game.world.entity.base.model.EntityModel;
    import game.world.entity.base.model.EntityMove;
    import game.world.entity.base.view.EntityAvatar;

    import tempest.data.obj.GuidObject;

    public class Entity implements IClear
    {
        protected var _data:EntityData;
        protected var _avatar:EntityAvatar;
        private var _animation:Animation;

        public function Entity()
        {
            initialize();
            _animation = new Animation(_data);
        }

        public function clear():void
        {
            _data.clear();
            _avatar.clear();
        }

        protected function initialize():void
        {
            throw new Error();
        }

        public function initData(guidObject:GuidObject):void
        {
            _data.init(guidObject);
            _data.direction = 0;

            setName(guidObject);

            var move:EntityMove = EntityModel.getMove(guid);
            if (move == null)
                return;
            EntityModel.removeMove(guid);
            if (move.pathList.length != 0)
            {
                data.worldPosition.tileX = move.pathList[0].x;
                data.worldPosition.tileY = move.pathList[0].y;
            }
            if (move.direction != -1)
                data.direction = move.direction;
            _avatar.x = data.worldPosition.pixelX;
            _avatar.y = data.worldPosition.pixelY;
            data.setPosition(data.worldPosition.pixelX, data.worldPosition.pixelY);
        }

        protected function setName(guidObject:GuidObject):void
        {
            var name:String=guidObject.GetStr(SharedDef.BINLOG_STRING_FIELD_NAME);
            data.name=name.substring(name.lastIndexOf(",") + 1, name.length);
            data.nameColor = ColorConst.white3;
        }

        public function initAvatar():void
        {
            _avatar.init(_data);
        }

        protected function onClick(event:Event):void
        {
        }

        public function get guid():String
        {
            return _data.guid;
        }

        public function get data():EntityData
        {
            return _data;
        }

        public function get avatar():EntityAvatar
        {
            return _avatar;
        }

        public function update():void
        {
            _animation.update(FrameManager.deltaTime);
            _avatar.update(_data, _animation.frame);
        }

        public function updateData():void
        {
            if (_data.bodyChanged || _data.statusChanged)
            {
                _animation.play();
            }
            _avatar.updateData(_data);

            _data.complete();
        }

        public function toString():String
        {
            return getQualifiedClassName(this) + "\n" +
                getQualifiedClassName(data) + "\n" +
                data.toString() + "\n" +
                PrintAllDisplayObject.getSpriteObjectInfo(avatar);
        }
    }
}
