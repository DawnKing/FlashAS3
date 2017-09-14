package tempest.engine.graphics.layer {
	import flash.events.MouseEvent;
	
	import org.osflash.signals.natives.base.SignalSprite;
	
	import tempest.engine.SceneCharacter;
	import tempest.engine.TScene;

	/**
	 * 交互层
	 * @author 
	 */
	public class InteractiveLayer extends SignalSprite {
		private var _scene:TScene;

		public function InteractiveLayer(scene:TScene) {
			super();
			_scene = scene;
			this.tabEnabled = this.tabChildren = this.mouseChildren = false;
		}

		/**
		 * 设置响应区域
		 * @param w
		 * @param h
		 */
		public function setActiveArea(w:Number, h:Number):void {
			this.graphics.clear();
			this.graphics.beginFill(0x0, 0);
			this.graphics.drawRect(0, 0, w, h);
			this.graphics.endFill();
		}

		/**
		 * 启用交互层
		 */
		public function enableInteractive():void {
			this.signals.mouseMove.add(this.mousemoveHandler);
			this.signals.mouseDown.add(this.mousedownHandler);
			this.signals.mouseWheel.add(this.mousewheelHandler);
			this.signals.mouseOut.add(this.mouseoutHandler);
			this.signals.mouseUp.add(this.mouseupHandler);
		}

		/**
		 * 关闭交互层
		 */
		public function disableInteractive():void {
			this.signals.mouseMove.remove(this.mousemoveHandler);
			this.signals.mouseDown.remove(this.mousedownHandler);
			this.signals.mouseWheel.remove(this.mousewheelHandler);
			this.signals.mouseOut.remove(this.mouseoutHandler);
			this.signals.mouseUp.remove(this.mouseupHandler);
		}

		private function mousemoveHandler(e:MouseEvent):void {
			var element:SceneCharacter = this._scene.getMouseHit(e.localX, e.localY);
			this._scene.signal.interactive.dispatch(e, element);
		}

		private function mousedownHandler(e:MouseEvent):void {
			var element:SceneCharacter = this._scene.getMouseHit(e.localX, e.localY);
			this._scene.signal.interactive.dispatch(e, element);
		}

		private function mousewheelHandler(e:MouseEvent):void {
			this._scene.signal.interactive.dispatch(e,null);
		}

		private function mouseupHandler(e:MouseEvent):void {
			this._scene.signal.interactive.dispatch(e,null);
		}

		private function mouseoutHandler(e:MouseEvent):void {
			this._scene.signal.interactive.dispatch(e,null);
		}
	}
}
