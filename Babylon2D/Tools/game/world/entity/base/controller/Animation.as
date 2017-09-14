/**
 * Created by caijingxiao on 2017/7/20.
 */
package game.world.entity.base.controller
{
    import game.world.entity.base.model.EntityData;

    import tempest.enum.Status;
    import tempest.template.Action;
    import tempest.template.ActionConfig;

    public class Animation
    {
        /**动作配置*/
        private var _actionFrame:Action;
        /**动作播放配置*/
        private var _apc:ActionConfig;

        /**最后一次绘制到现在的时间*/
        private var _runTime:int=0;
        /**动作姿态*/
        private var _intervalScale:Number=1;

        /**当前帧*/
        private var _currentFrame:int;

        /***播放完毕回调*/
        private var _onCompleteFrame:Function=null;
        private var _completeFrame:Boolean;
        private var _completeAction:int;
        /***关键帧回调*/
        private var _onEffectFrame:Function=null;
        private var _effectFrame:Boolean;
        private var _effectAction:int;

        private var _data:EntityData;

        public function Animation(data:EntityData)
        {
            _data = data;
        }

        public function dispose():void
        {
            _actionFrame=null;
            _onEffectFrame=null;
            _onCompleteFrame=null;
            _apc=null;
        }

        /**帧频缩放*/
        public function set intervalScale(value:Number):void
        {
            _intervalScale=value;
        }

        public function update(diff:uint):void
        {
            if (_actionFrame == null)
                return;
            //运行时间累计
            _runTime+=diff;
            //关键帧
            if (_effectFrame && this._onEffectFrame != null)
            {
                _effectFrame=false;
                this._onEffectFrame();
                this._onEffectFrame=null;
            }
            //最后一帧
            if (_completeFrame && this._onCompleteFrame)
            {
                _completeFrame=false;
                this._onCompleteFrame();
                this._onCompleteFrame=null;
            }
            var interval:int=_actionFrame.interval * _intervalScale;
            if (_runTime > interval)
            {
                while (_runTime >= interval)
                {
                    _runTime-=(interval || _runTime);
                    if (_currentFrame >= _actionFrame.total - 1) //播放完毕
                    {
                        if (_actionFrame.status == _completeAction)
                        {
                            _completeAction=-1;
                            _completeFrame=true;
                        }
                        //播放一次动作完毕
                        if (_apc.stay_atend && _apc.is_loop_once)
                        {
                            _currentFrame=_actionFrame.total - 1;
                        }
                        else //循环播放，或播放结束继续待机
                        {
                            _currentFrame=0;
                            if (_apc.is_loop_once)
                            {
                                _runTime=0;
                                _data.status=Status.STAND;
                                return;
                            }
                        }
                    }
                    else if (_actionFrame.total > 1)
                    {
                        _currentFrame++;
                        if (_actionFrame.status == _effectAction)
                        {
                            if (_onEffectFrame != null && (this._currentFrame >= this._actionFrame.effect))
                            {
                                _effectAction=-1;
                                _effectFrame=true;
                            }
                        }
                    }
                }
            }
        }

        public function play(apc:ActionConfig=null, onEffectFrame:Function=null, onCompleteFrame:Function=null):void
        {
            if (_onEffectFrame != null)
            {
                _onEffectFrame();
            }
            if (_onCompleteFrame != null)
            {
                _onCompleteFrame();
            }
            if (apc && apc.priority != 0 && apc.priority < _apc.priority)
            { //当前播放的动作优先级更高
                if (onEffectFrame != null)
                {
                    onEffectFrame();
                }
                if (onCompleteFrame != null)
                {
                    onCompleteFrame();
                }
                return;
            }

            _actionFrame=Status.exActions[_data.body + "-" + _data.status] || Status.actions[_data.status]; //取自定义模型
            _apc=Status.getActionConfig(_data.status);

            if (_apc.play_atbegin && _currentFrame != 0)
            {
                this._currentFrame=0;
            }
            var endFrame:int=this._actionFrame.total - 1;
            if (_apc.show_end && _currentFrame != endFrame)
            {
                _currentFrame=endFrame;
            }
            this._onEffectFrame=onEffectFrame;
            if (_onEffectFrame)
            {
                _effectAction=_data.status;
            }
            this._onCompleteFrame=onCompleteFrame;
            if (_onCompleteFrame)
            {
                _completeAction=_data.status;
            }
            ///////////////重置帧////////////////
            this._runTime=0;
        }

        public function get frame():int
        {
            return _currentFrame;
        }
    }
}

