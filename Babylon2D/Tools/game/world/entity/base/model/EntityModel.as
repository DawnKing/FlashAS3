/**
 * Created by caijingxiao on 2017/7/19.
 */
package game.world.entity.base.model
{
    import avmplus.getQualifiedClassName;

    import easiest.core.Log;
    import easiest.debug.Assert;
    import easiest.managers.ObjectPool;

    import flash.utils.Dictionary;

    import game.world.entity.base.controller.Entity;
    import game.world.entity.base.controller.MovableEntity;
    import game.world.entity.base.controller.MoveEntityProcess;
    import game.world.entity.player.controller.SelfPlayer;

    public class EntityModel
    {
        private static var _entities:Dictionary = new Dictionary(true);
        private static var _moves:Dictionary = new Dictionary(true);

        public static function containers(guid:String):Boolean
        {
            return guid in _entities;
        }

        public static function clear():void
        {
            for each (var entity:Entity in _entities)
            {
                ObjectPool.free(entity);
            }

            for each (var move:EntityMove in _moves)
            {
                ObjectPool.free(move);
            }

            _entities = new Dictionary(true);
            _moves = new Dictionary(true);
        }

        public static function addEntity(entity:Entity):void
        {
            Assert.assertFalse("创建对象时已经存在对象", containers(entity.guid));
            _entities[entity.guid] = entity;
        }

        public static function removeEntity(guid:String):void
        {
            var entity:Entity = _entities[guid];
            ObjectPool.free(entity);
            delete _entities[guid];
        }

        public static function getEntity(guid:String):Entity
        {
            return _entities[guid];
        }

        public static function getEntityByUGuid(uguid:uint):Entity
        {
            for each (var entity:Entity in _entities)
            {
                if (entity.data.uguid == uguid)
                    return entity;
            }
            return null;
        }

        public static function findEntity(guid:String):Entity
        {
            for (var key:String in _entities)
            {
                if (key.indexOf(guid) != -1)
                    return _entities[key];
            }
            return null;
        }

        public static function getMovableEntity(guid:String):MovableEntity
        {
            return _entities[guid] as MovableEntity;
        }

        public static function addMoveList(guid:String, pathList:Array, direction:int, speed:int):void
        {
            if (direction > 7)
            {
                Log.error("方向错误", getQualifiedClassName(EntityModel));
                direction = 7;
            }
            var move:EntityMove;
            if (guid in _moves)
            {
                move = _moves[guid];
            }
            else
            {
                move = ObjectPool.get(EntityMove) as EntityMove;
                _moves[guid] = move;
            }
            move.setPathList(pathList, direction, speed);

            MoveEntityProcess.addEvent(guid);
        }

        public static function removeMove(guid:String):void
        {
            var move:EntityMove = _moves[guid];
            if (move == null)
                return;
            ObjectPool.free(move);
            delete _moves[guid];

            MoveEntityProcess.removeEvent(guid)
        }

        public static function getMove(guid:String):EntityMove
        {
            return _moves[guid];
        }

        public static function update():void
        {
            for each (var entity:Entity in _entities)
            {
                entity.update();
            }
        }

        public static function get entities():Dictionary
        {
            return _entities;
        }
    }
}
