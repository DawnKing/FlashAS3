/**
	 * Created by caijingxiao on 2017/6/13.
	 */
package easiest.rendering
{
    import easiest.managers.FrameManager;
    import easiest.rendering.sprites.SpriteContainer;
    import easiest.rendering.sprites.SpriteObject;
    import easiest.rendering.sprites.Weather;
    import easiest.rendering.sprites.batch.Sprite2DBatching;

    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class Scene
	{
		public static var mouseX:Number=0;
		public static var mouseY:Number=0;

		public static var useChar:Boolean = true;
		public static var useEffect:Boolean = true;
        public static var useWeather:Boolean = true;

		private var _engine:Engine;
		private var _root:SpriteContainer=new SpriteContainer();
		private var _weather:Vector.<Weather>=new <Weather>[];

		// mouse event
		private static const sMouseOver:MouseEvent=new MouseEvent(MouseEvent.MOUSE_OVER);
		private static const sMouseOut:MouseEvent=new MouseEvent(MouseEvent.MOUSE_OUT);
		private static const sPoint:Point = new Point;
		private var _mouseObject:SpriteObject;

		public function Scene(engine:Engine, stage:Stage)
		{
			_engine=engine;

			_root.mouseEnabled=true;
			_root.mouseChildren=true;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseHandler);
			stage.addEventListener(MouseEvent.CLICK, onMouseHandler);

			FrameManager.add(process);
		}

        public function addChild(child:SpriteObject):void
        {
            _root.addChild(child);
        }

        public function addWeather(weather:Weather):void
        {
            _weather.push(weather);
        }

        private function process():void
        {
			_engine.beginFrame();
			render();
			_engine.endFrame();
        }

        public function render():void
        {
            if (!_engine.ready)
                return;

            Sprite2DBatching.clear();
            _root.render(null);
            Sprite2DBatching.render();

            var index:int, len:int;

            if (useWeather && _weather.length != 0)
            {
                Sprite2DBatching.clear();
//                _engine.setBlendMode(BlendMode.ADD);
                len=_weather.length;
                for (index=0; index < len; index++)
                {
                    _weather[index].render();
                }
                Sprite2DBatching.render();
            }
        }

		private function onMouseHandler(event:MouseEvent):void
		{
            sPoint.x = event.stageX;
			sPoint.y = event.stageY;
			var hit:SpriteObject=_root.hitTest(sPoint);
			if (hit == null)
				return;
			dispatchEvent(hit, event);
		}

		private function dispatchEvent(target:SpriteObject, event:MouseEvent):void
		{
			while (target)
			{
				if (target.hasEventListener(event.type))
					target.dispatchEvent(event);
				target=target.parent;
			}
		}

		private function onMouseMove(event:MouseEvent):void
		{
			mouseX=event.stageX;
			mouseY=event.stageY;

            sPoint.x = event.stageX;
            sPoint.y = event.stageY;
			var hit:SpriteObject=_root.hitTest(sPoint);
			if (hit == null)
			{
				if (_mouseObject != null)
				{
					dispatchEvent(_mouseObject, sMouseOut);
					_mouseObject=null;
				}
				return;
			}

			if (hit != _mouseObject)
			{
				dispatchEvent(_mouseObject, sMouseOut);
				_mouseObject=hit;
				dispatchEvent(_mouseObject, sMouseOver);
			}

			dispatchEvent(_mouseObject, event);
		}
	}
}
