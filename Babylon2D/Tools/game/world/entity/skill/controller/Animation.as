/**
 * Created by caijingxiao on 2017/8/1.
 */
package game.world.entity.skill.controller
{
    import tempest.enum.AnimationType;
    import tempest.template.AnimationEntity;

    public class Animation
    {
        /***时间刻度*/
        private var timeOffset:int=0;
        private var _type:int=0;
        /***当前帧*/
        private var _currentFrame:int;
        /***当前帧*/
        private var _maxFrame:int;
        /**配置*/
        private var _config:AnimationEntity;
        /***播放回调*/
        public var onChange:Function=null;

        public function Animation()
        {
        }

        public function update(diff:uint):void
        {
            var isComplete:Boolean;
            timeOffset+=diff;
            if (_type != AnimationType.Loop && this._currentFrame >= _maxFrame)
            {
                switch (this._type)
                {
                    case AnimationType.OnceTODispose:
//                        clear(this);
                        return;
                    case AnimationType.Once:
                        this.timeOffset=0;
                        this._currentFrame=_maxFrame;
                        return;
                }
            }
            while (timeOffset > _config.interval)
            {
                timeOffset-=(_config.interval || timeOffset);
                if (this._currentFrame >= _maxFrame)
                {
                    if (this._type != AnimationType.Loop)
                    {
                        this.timeOffset=0;
                        this._currentFrame=_maxFrame;
                        isComplete=true;
                        break;
                    }
                    else
                    {
                        this._currentFrame=0;
                    }
                }
                else
                {
                    _currentFrame++;
                }
                if (onChange != null)
                {
                    this.onChange(this);
                }
            }
        }

        public function get frame():int
        {
            return _currentFrame;
        }
    }
}
