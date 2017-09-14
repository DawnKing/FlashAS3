package easiest.managers
{
    import easiest.core.IClear;
    import easiest.core.IDispose;
    import easiest.core.Log;

    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;

    /**
     * 对象资源池
     *
     * @author caijingxiao
     *
     */
    public final class ObjectPool
    {
        private static const _pools:Dictionary=new Dictionary();

        public static function get(def:Class):Object
        {
            var name:String = getQualifiedClassName(def);
            var pool:ObjectPool=_pools[name];
            if (!pool)
            {
                pool = new ObjectPool(def, 10, 10);
                _pools[name] = pool;
            }
            return pool.getObject();
        }

        public static function free(object:Object):void
        {
            var name:String = getQualifiedClassName(object);
            var pool:ObjectPool=_pools[name];
            if (!pool)
            {
                Log.error(name + "不存在缓存池", getQualifiedClassName(ObjectPool));
                return;
            }
            pool.disposeObject(object);
        }

        private var _initFunction:Function;
        private var _def:Class;
        private var _initValue:uint; // 资源池初始大小
        private var _growthValue:uint;  // 资源池每次动态增加的大小，如果为0，不动态增加
        private var _index:uint; // 资源池当前索引
        private var _pool:Vector.<Object>;

        public function ObjectPool(def:Class, initPoolSize:uint, growthValue:uint, initFunction:Function=null)
        {
            _def = def;
            _initValue = initPoolSize;
            _growthValue = growthValue;
            _initFunction = initFunction;

            _index = _initValue;
            var i:uint = _initValue;

            _pool = new Vector.<Object>(_initValue);
            while (--i >= 0)
            {
                _pool[i] = new _def();
                if (_initFunction != null)
                    _initFunction(_pool[i]);
            }
        }

        /**
         * 获取对象
         */
        public function getObject():Object
        {
            if (_index > 0)
            {
                var result:Object = _pool[--_index];
                _pool[_index] = null;
                return result;
            }

            if (_initValue == 1)   // 用于调试，只new不存对象，不缓存
                return new _def();

            if (_growthValue == 0) // 用于限制对象池的大小
                return null;

            var i:uint = _growthValue;
            while (--i >= 0)
            {
                var object:Object = new _def();
                _pool.unshift(object);
                if (_initFunction != null)
                    _initFunction(object);
            }
            _index = _growthValue;
            return getObject();
        }

        /**
         * 弃用对象
         */
        public function disposeObject(object:Object):void
        {
            if (object == null)
                throw new Error("对象不能为空");
            if (!(object is _def))
                throw new Error("错误的对象");
            if (_initValue == 1) // 用于调试，只new不存对象，不缓存
            {
                if (_index == 0)
                    _pool[_index++] = object;
                else if (object is IDispose)
                    IDispose(object).dispose();
                return;
            }

            if (object is IClear)
                IClear(object.clear());
            _pool[_index++] = object;

            if (_index > (_growthValue*2+_initValue) && totalSize > _initValue)
            {
                var i:uint = _growthValue;
                while (--i >= 0)
                {
                    var dis:Object = _pool.shift();
                    if (dis is IDispose)
                        IDispose(dis).dispose();
                }
                _index -= _growthValue;
            }
        }

        public function indexOf(object:Object, fromIndex:int=0):int
        {
            return _pool.indexOf(object, fromIndex);
        }

        /**
         * 资源池当前大小
         */
        public function get size():uint
        {
            return _index;
        }

        /**
         * 资源池的总大小
         */
        public function get totalSize():uint
        {
            return _pool.length;
        }

        public function hasObject():Boolean
        {
            return size > 0;
        }
    }
}
