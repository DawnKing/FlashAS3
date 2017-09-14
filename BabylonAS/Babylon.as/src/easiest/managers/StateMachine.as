package easiest.managers
{
	import easiest.core.IDispose;

	import flash.utils.Dictionary;

	/*
	 m_fsm = new StateMachine(FighterStateDefine.STATE_STAND);

	 // 待机 -> 移动
	 m_fsm.add(FighterStateDefine.STATE_STAND,
	 FighterStateDefine.EVENT_MOVE_LOOP,
	 FighterStateDefine.STATE_MOVE).check(canMove).enter(changeToMove);

	 // 移动 -> 待机
	 m_fsm.add(FighterStateDefine.STATE_MOVE,
	 FighterStateDefine.EVENT_STAND,
	 FighterStateDefine.STATE_STAND).enter(changeToStand);

	 // 移动打断
	 m_fsm.add(FighterStateDefine.STATE_MOVE,
	 FighterStateDefine.EVENT_INTERRUPT,
	 FighterStateDefine.STATE_STAND);

	 // 后仰--->待机
	 m_fsm.add(FighterStateDefine.STATE_LEAN_BACK,
	 FighterStateDefine.EVENT_STAND,
	 FighterStateDefine.STATE_STAND).exit(changeToStand).enter(prepareAttack);
	 */
	public class StateMachine implements IDispose
	{
		public static const DEBUG:Boolean = false;

		private var _state:String;
		private var _transitions:Dictionary = new Dictionary();
		private var _eventQueue:Array = [];

		public function StateMachine(initState:String)
		{
			_state = initState;
		}
        
        public function dispose():void
        {
            _transitions = null;
            _eventQueue = null;
        }

		public function update():void
		{
			while (_eventQueue.length > 0)
			{
				var event:String = _eventQueue.shift();
				transitionTo(event);
			}
		}

		public function postEvent(event:String, from:String):void
		{
			_eventQueue.push(event);
			if (DEBUG)
				trace("postEvent", event, from);
		}
		
		public function transitionTo(event:String):void
        {
            var transition:Transition = findTransition(_state, event);

            if (transition)
                transition.transState()
        }
        
        // return transition for chaining call like below
        // .add().exit().enter()
        public function add(from:String, event:String, to:String):Transition
        {
			var transition:Transition = new Transition(from, event, to, this);
			_transitions[from + event] = transition;
			return transition;
		}
		
		private function findTransition(state:String, event:String):Transition
		{
			return _transitions[state + event];
		}

		public function get state():String
		{
			return _state;
		}

		public function resetState(state:String, from:String):void
		{
			_state = state;
			if (DEBUG)
				trace("resetState", state, from);
		}
	}
}

import easiest.managers.StateMachine;

class Transition
{
    private var _fromState:String;
	private var _event:String;
    private var _toState:String;
    private var _exitPrevious:Function;
    private var _enterNext:Function;
    private var _checkTransition:Function;
    private var _fsm:StateMachine;
    
    public function Transition(from:String, event:String, to:String, fsm:StateMachine)
    {
        _fromState = from;
		_event = event;
        _toState = to;
        _fsm = fsm;
    }
    
    public function exit(exitPrevious:Function):Transition
    {
        _exitPrevious = exitPrevious;
        return this;
    }
    
    public function enter(enterNext:Function):Transition
    {
        _enterNext = enterNext;
        return this;
    }
    
    public function check(checkTransition:Function):Transition
    {
        _checkTransition = checkTransition;
        return this;
    }
    
    public function transState():void
    {
        var transValid:Boolean = true;
        
        if (_checkTransition != null)
            transValid = _checkTransition();
        
        if (!transValid)
            return;
        
        if (_exitPrevious != null)
            _exitPrevious();

		if (StateMachine.DEBUG)
			trace(_fsm.state + " -> " + _toState);

		_fsm.resetState(_toState, "transState");
        
        if (_enterNext != null)
            _enterNext()
    }

	public function get fromState():String
	{
		return _fromState;
	}

	public function get event():String
	{
		return _event;
	}
}
