package easiest.managers
{
    import easiest.core.IDispose;

    /**
     * 对象资源池
     * 
     * @author caijingxiao
     * 
     */
    public final class ObjectPool
    {
        private var m_initFunction:Function;   
        private var m_object:Class;
        private var m_initValue:uint; // 资源池初始大小
        private var m_growthValue:uint;  // 资源池每次动态增加的大小
        private var m_index:uint; // 资源池当前索引
        private var m_pool:Vector.<Object>;
        
        /**
         * 对象资源池
         * @param obj 对象
         * @param initPoolSize 资源池初始大小，如果为1，代表不缓存（测试用）
         * @param growthValue 当超出资源池初始大小，资源池每次动态增加的大小
         * @param initFunction 创建类时初始化回调，函数格式function(object:Object):void
         */
        public function ObjectPool(obj:Class, initPoolSize:uint, growthValue:uint, initFunction:Function=null)
        {
            m_object = obj;
            m_initValue = initPoolSize;
            m_growthValue = growthValue;
            m_initFunction = initFunction;
            
            m_index = m_initValue;
            var i:uint = m_initValue;
            
            m_pool = new Vector.<Object>(m_initValue);
            while (--i >= 0)
            {
                m_pool[i] = new m_object();
                if (m_initFunction != null)
                    m_initFunction(m_pool[i]);
            }
        }

        /**
         * 获取对象
         */
        public function getObject():Object
        {
            if (m_index > 0)
            {
                var result:Object = m_pool[--m_index];
                m_pool[m_index] = null;
                return result;
            }
            
            if (m_initValue == 1)   // 用于调试，只new不存对象，不缓存
                return new m_object();
            
            if (m_growthValue == 0) // 用于限制对象池的大小
                return null;
            
            var i:uint = m_growthValue;
            while (--i >= 0)
            {
                var object:Object = new m_object();
                m_pool.unshift(object);
                if (m_initFunction != null)
                    m_initFunction(object);
            }
            m_index = m_growthValue;
            return getObject();
        }
        
        /**
         * 弃用对象
         */
        public function disposeObject(object:Object):void
        {
            if (object == null)
                throw new Error("对象不能为空");
            if (!(object is m_object))
                throw new Error("错误的对象");
            if (m_initValue == 1) // 用于调试，只new不存对象，不缓存
            {
                if (m_index == 0)
                    m_pool[m_index++] = object;
                else if (object is IDispose)
                    IDispose(object).dispose();
                return;
            }
            
            m_pool[m_index++] = object;
            
            if (m_index > (m_growthValue*2+m_initValue) && totalSize > m_initValue)
            {
                var i:uint = m_growthValue;
                while (--i >= 0)
                {
                    var dis:Object = m_pool.shift();
                    if (dis is IDispose)
                        IDispose(dis).dispose();
                }
                m_index -= m_growthValue;
            }
        }
        
        public function indexOf(object:Object, fromIndex:int=0):int
        {
            return m_pool.indexOf(object, fromIndex);
        }
        
        /**
         * 资源池当前大小
         */
        public function get size():uint
        {
            return m_index;
        }
        
        /**
         * 资源池的总大小
         */
        public function get totalSize():uint
        {
            return m_pool.length;
        }
        
        public function hasObject():Boolean
        {
            return size > 0;
        }
    }
}