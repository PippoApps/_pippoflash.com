package com.pippoflash.framework.starling.gui.elements 
{
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.UNumber;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import starling.display.Sprite;
	/**
	 * Base for scroll. Uses a line and centers everything vertically inside the square. Handle is always centered in visible area.
	 * @author Pippo Gregoretti
	 */
	public class ScrollBase extends _ElementBase 
	{
		public static const EVT_SCROLL_START:String = "onScrollStart";
		public static const EVT_SCROLL:String = "onScroll";
		public static const EVT_SCROLL_END:String = "onScrollEnd";
		public static const EVT_SCROLL_STEP:String = "onScrollStep"; // When scrolling is done clicking on bg
		protected static const PAN_SCROLL_SPEED:Number = 0.1;
		protected static const TAP_SCROLL_SPEED:Number = 0.3;
		protected var _handle:Sprite; // This stays always the same
		protected var _handleContent:DisplayObject; // this is created as a ball at startup, can then be changed at will
		protected var _bg:DisplayObject;
		protected var _bgLine:Canvas; // Draws a line in the 
		protected var _topTip:DisplayObject;
		protected var _bottomTip:DisplayObject
		protected var _direction:String; // Taken from settings
		protected var _iconShape:String; // Taken form settings
		protected var _scroll:Number; // 0 to 1
		protected var _targetPos:Number = 0;
		protected var _handlePos:Number = 0;
		protected var _active:Boolean = true; // If scroll is active or not
		protected var _fadeHandle:Boolean = true; // If handle should fade in out or not
		
		private static const DEFAULT_SETTINGS:Object = {
			iconShape:"round", // round, square
			lineColor:0xffffff,
			handleColor:0xff0000,
			direction:"vertical"
		}
		
		public function ScrollBase(size:Rectangle, id:String, cl:Class=null, settings:Object=null) {
			super(size, id, cl ? cl : ScrollBase, false);
			renderGui(settings);
			//addChild(uDisplay.getSquareCanvas(0xff0000, 300, 300));
		}
		
		// RENDERING
		override protected function renderGui(settings:Object=null):void {
			_settings = addDefaultsToSettings(DEFAULT_SETTINGS, settings);
			_direction = _settings.direction;
			_iconShape = _settings.iconShape;
			//if (vertical) _bgArea.x = -_size.width / 2;
			//else _bgArea.y = -_size.width / 2;
			renderBg();
			renderHandle();
			StarlingGesturizer.addTap(_bgArea, onTapBg);
		}
		
		
		protected function renderBg():void {
			if (vertical) {
				_bgLine = uDisplay.getSquareCanvas(_settings.lineColor, 1, _size.height);
				_bgLine.x = _size.width / 2;
			}
			else {
				_bgLine = uDisplay.getSquareCanvas(_settings.lineColor, _size.width, 1 / UGlobal.getContentScale());
				_bgLine.y = _size.height / 2;
			}
			addChild(_bgLine);
		}
		protected function renderHandle():void {
			_handle = new Sprite();
			if (vertical) _handle.x = _size.width / 2;
			else _handle.y = _size.height / 2;
			const handleDiameter:Number = vertical ? _size.width : _size.height;
			setHandle(uDisplay.getRoundCanvas(_settings.handleColor, vertical ? _size.width : _size.height, handleDiameter/2, handleDiameter/2));
			//uDisplay.alignTo(_handleContent, vertical ? new Rectangle(0, 0, _size.width, _size.width) : new Rectangle(0, 0, _size.height, _size.height));
			addChild(_handle);
			StarlingGesturizer.addPan(_handle, this["onPan_" + _direction], true);
			StarlingGesturizer.addPanStart(_handle, onPanStart);
			StarlingGesturizer.addPanEnd(_handle, onPanStop);
		}
		
		
		
		// METHODS
		public function addTopTip(tip:DisplayObject):void {
			_topTip = tip;
			addChild(_topTip);
			uDisplay.centerToItself(_topTip);
			if (vertical) _topTip.x += _size.width/2;
			else _topTip.y += _size.height/2;
			
			addChild(_handle);
		}
		
		
		public function addBottomTip(tip:DisplayObject):void {
			_bottomTip = tip;
			addChild(_bottomTip);
			uDisplay.centerToItself(_bottomTip);
			if (vertical) _bottomTip.x += _size.width/2;
			else _bottomTip.y += _size.height/2;
			if (vertical) _bottomTip.y += _size.height;
			else _bottomTip.x += _size.width;
			addChild(_handle);
		}
		
		public function setHandle(h:DisplayObject):void {
			if (_handleContent) {
				_handleContent.removeFromParent();
				_handleContent.dispose();
			}
			_handleContent = h;
			uDisplay.centerToItself(_handleContent);
			//_handleContent.x = -_handleContent.width / 2;
			//_handleContent.x = -_handleContent.width / 2;
			//uDisplay.alignTo(_handleContent, vertical ? new Rectangle(0, 0, _size.width, _size.width) : new Rectangle(0, 0, _size.height, _size.height));
			_handle.addChild(_handleContent);
		}
		/**
		 * Sets scroll 0 to 1
		 * @param	s
		 */
		public function setScrollValue(s:Number, immediate:Boolean=false, broadcast:Boolean = false):void {
			//mover.stopMotion(this);
			setScrollPx(vertical ? _size.height * s : _size.width * s, immediate, broadcast);
		}
		/**
		 * Sets scroll in pixels.
		 * @param	s
		 */
		public function setScrollPx(s:Number, immediate:Boolean=false, broadcast:Boolean=false):void {
			if (vertical) {
				_targetPos = UNumber.getRanged(s, _size.height, 0);
				_scroll = _targetPos / _size.height;
			} else {
				_targetPos = UNumber.getRanged(s, _size.width, 0);
				_scroll = _targetPos / _size.width;
			}
			//mover.stopMotion(this);
			if (immediate) handlePos = _targetPos;
			else mover.move(this, TAP_SCROLL_SPEED, {handlePos:_targetPos});
			//trace("SETTO SCROLL", _scroll, _targetPos);
			if (broadcast) broadcastScroll(_scroll);
		}
		/**
		 * Sets scroll as a step. Broadcasts a different event.
		 * @param	s
		 * @param	immediate
		 * @param	broadcast
		 */
		public function setScrollStepPx(s:Number, immediate:Boolean = false, broadcast:Boolean = false):void {
			setScrollPx(s, immediate, false);
			if (broadcast) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCROLL_STEP, this);
		}
		/**
		 * Moves scroll handle in time to a certain value. Does not change scroll value but only handle position.
		 * @param	scrollTo 0 to 1, where to position scroll.
		 * @param	time lenght of time required to move handle.
		 */
		public function scrollHandleInTime(scrollTo:Number, time:Number):void {
			scrollTo = UNumber.getRanged(scrollTo, 1, 0);
			mover.move(this, time, {handlePos:(vertical ? _size.height : _size.width)*scrollTo}, "Linear.easeOut");
		}
		public function stopHandle():void {
			mover.stopMotion(this);
		}
		// GET SET
		public function get vertical():Boolean {
			return _direction == "vertical";
		}
		
		public function get handlePos():Number 
		{
			return _handlePos;
		}
		/**
		 * scroll position between 0 and 1
		 */
		public function get scroll():Number 
		{
			return _scroll;
		}
		
		public function set handlePos(value:Number):void 
		{
			_handlePos = value;
			if (vertical) _handle.y = _handlePos;
			else _handle.x = _handlePos;
		}
		
		public function get active():Boolean 
		{
			return _active;
		}
		
		public function set active(value:Boolean):void 
		{
			_active = value;
			if (_handle) {
				if (_fadeHandle) {
					mover.fade(_handle, 0.2, value ? 1 : 0);
				}
				else {
					_handle.visible = value;
				}
			}
		}
		
		public function set fadeHandle(value:Boolean):void {
			_fadeHandle = value;
		}
		
		// PANNING
		private function onPanStart(c:DisplayObject):void {
			mover.stopMotion(this);
			setScrollPx(vertical ? c.y : c.x, true, false);
			trace("pan start",vertical, c.x);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCROLL_START, this);
			//_targetPos = _handlePos = vertical ? c.y : c.x;
		}
		private function onPanStop(c:DisplayObject):void {
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCROLL_END, this);
		}
		private function onPan_vertical(c:DisplayObject, coords:Point, force:Number, isEnd:Boolean):void {
			_targetPos = UNumber.getRanged(_targetPos + coords.y, _size.height, 0);
			mover.move(this, PAN_SCROLL_SPEED, {handlePos:_targetPos});
			broadcastScroll(_targetPos / _size.height);
		}
		private function onPan_horizontal(c:DisplayObject, coords:Point, force:Number, isEnd:Boolean):void {
			_targetPos = UNumber.getRanged(_targetPos + coords.x, _size.width, 0);
			mover.move(this, PAN_SCROLL_SPEED, {handlePos:_targetPos});
			broadcastScroll(_targetPos / _size.width);
		}
		private function broadcastScroll(s:Number):void {
			_scroll = s;
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCROLL, this);
		}
		
		
		private function onTapBg(c:DisplayObject):void {
			setScrollStepPx(vertical ? StarlingGesturizer.getTapGestureRelativeLocation(c).y : StarlingGesturizer.getTapGestureRelativeLocation(c).x, false, true);
		}
		
		
		
	}

}