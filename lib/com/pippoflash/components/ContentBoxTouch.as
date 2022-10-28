package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Debug;
// 	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.motion.PFMover;
	import											flash.display.*;
	import											flash.text.*;
	import	  										flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	/* WARNING - Touch od Sektop screen is active only if USystem.isDevice() or static FORCE_SWIPE_SCROLL == true */
	import com.pippoflash.utils.*;
	
	public class ContentBoxTouch extends _cBase {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
[Inspectable 									(name="1.7 - Broadcast Continuos V (onScrollingV)", defaultValue=false, type=Boolean)]
public var _broadcastContScrollV						:Boolean = false;
[Inspectable 									(name="1.8 - Broadcast Continuos H (onScrollingH)", defaultValue=false, type=Boolean)]
public var _broadcastContScrollH						:Boolean = false;
[Inspectable 									(name="1.1 - Link to HORIZONTAL ScrollBar", type=String)]
public var _scrollHorizLink							:String;
[Inspectable 									(name="1.0 - Link to VERTICAL ScrollBar", type=String)]
public var _scrollVertLink							:String;
[Inspectable 									(name="1.2 - Use mouse wheel", defaultValue=true, type=Boolean)]
public var _useMouseWheel							:Boolean = true;
[Inspectable 									(name="1.3 - Mouse-wheel step", defaultValue=10, type=Number)]
public var _mouseWheelStep						:Number = 10;   
[Inspectable 									(name="1.4 - Smooth Scroll", defaultValue=true, type=Boolean)]
public var _smoothScrollOn							:Boolean = true;
[Inspectable 									(name="1.5 - Cover BG (shield so that content doesnt click thru)", defaultValue=true, type=Boolean)]
public var _coverBg								:Boolean = true;
[Inspectable 									(name="1.6 - Auto Scroll", defaultValue=false, type=Boolean)]
public var _autoScroll								:Boolean = false;
[Inspectable 									(name="1.7 - Limit scroll to", type=String, defaultValue="ALL", enumeration="ALL,VERTICAL,HORIZONTAL")]
public var _limitScroll								:String = "ALL";
[Inspectable 									(name="1.8 - Use BlitMask", defaultValue=false, type=Boolean)]
public var _useBlitMask							:Boolean = false;
// USER VARUIABLES TO SET IN CODE
private var _containerZoomFactor:Number = 1; // If ContentBox is zoomed for some reason, this is needed to keep in sync pan gesture with internal motion (if this is 200%, factor should be 0.5)
/**
 * If ContentBox is zoomed for some reason, this is needed to keep in sync pan gesture with internal motion (if this is 200%, factor should be 0.5)
 */
public function set containerZoomFactor(value:Number):void {
	_containerZoomFactor = value;
}



// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
// 		public static var _scrollSpeed						:uint = 40; // Number of frames for smooth scrolling
		public static const EVENT_USE_CAPTURE				:Boolean = true; // If events work in the capture phase
		public static const EVENT_PRIORITY					:uint = 20; // Priority of events in the events chain - 0 is from ContentBox that may contain buttons activated with Buttonizer
		public static const EVENT_WEAK_REFERENCE				:Boolean = true; // Use weak references
		public static var FORCE_SWIPE_SCROLL				:Boolean = false;
		private static var _touchModeInit						:Boolean; // When true, multitouch mode has been already enabled
		private static var _verbose							:Boolean = false;
		public var _scrollTime								:Number = 0.5; // Seconds for scroling ease
		public var _scrollEase								:String = "Strong.easeOut";
		// USER VARIABLES
		public var _autoScrollMargin							:uint = 100; // Number of pixels to add to autoscroll when an object has to be set to visible automatically
		public var _mouseScrollMargin						:uint = 50; // The margin from sides to go with mouse to beginning or end of scroll
		// SYSTEM
		private var _rectangle								:Rectangle = new Rectangle();
		private var _realBounds							:Rectangle = new Rectangle(); // This to overcome horrible bug in dimensions with scrollRect set
// 		private var _blitMask								:BlitMask;
		// REFERENCES
		private var _content								:*;
		public var _scrollV								:MovieClip; // Reference to a PippoFlashScrollBar
		public var _scrollH								:MovieClip; // Reference to a PippoFlashScrollBar
		private var _scrollVfunc							:Function; // Accordin to the type of scroll, links to the correct function
		private var _scrollHfunc							:Function; // Accordin to the type of scroll, links to the correct function
		private var _bgClip								:MovieClip; // If activated, this will cover the BG (to block click thru, and listen mousewheel)
		private var _textField								:TextField; // The textfield used for setText();
		private var _mover								:PFMover = new PFMover(); // Each ContentBox has her own instance of Mover.
 		// MARKERS
		private var _boundaries							:Rectangle = new Rectangle();
		public var _scrollVperc								:Number = 0;
		public var _scrollHperc								:Number = 0;
		private var _latestScrollV							:Number = 0; // This one remains memorized and its not reset if I want to re-scroll after an update of content - DOESNT WORK NOW
		private var _latestScrollH							:Number = 0; // This one remains memorized and its not reset if I want to re-scroll after an update of content - DOESNT WORK NOW
		private var _useScrollRect							:Boolean; // Opposite of use BlitMask
		// TILES VIEWPORT - This can be activated and adds and reove tiles from content according to viewport.
		private var _useViewport							:Boolean; // This gets reset at each setContent. Must be set again calling activateTilesViewport.
		private var _tiles									:Vector.<Object>; // All tiles in _content
		private var _tilesViewportMargin						:int; // Howmany tiles show before and after viewport as margin
		private var _firstVisibleTile							:int; // The first visible tile in viewport
		private var _lastVisibleTile							:int; // The last visible tile in viewport
		private var _visibleTilesNum							:int; // The number of visible tiles to be activated (considering _tileHeight, margins and area)
		private var _tileHeight								:int; // Height of tile in pixels
		private var _applyViewportV							:Function = function():void {}; // This refers to dummy function if not defined. Can be apply
		private var _firstIterationV							:Boolean; // Marks if it is the first iteration
		// INTERFACE MODE MARKERS
		private var _isTouch								:Boolean;
		private var _isNormal								:Boolean;
		// SMOOTH SCROLL
		private var _targetVperc							:Number;
		private var _targetHperc							:Number;
		private var _targetH								:Number; // Target in pixels
		private var _targetV								:Number; // Target in pixels
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		private static function setToTouchMode():void {
			if (_touchModeInit) return;
			Debug.warning("ContentBoxTouch", "Setting ContentBoxTouch to touch events mode.");
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			_touchModeInit = true;
		}
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function ContentBoxTouch						(par:Object=null) {
			super									("ContentBoxTouch", par);
		}
		protected override function initialize					():void {
			//trace("INITIALIZEEEEEE FREGNAAAAAAAAAAAA");
			super.initialize								();
			if (FORCE_SWIPE_SCROLL || (USystem.isDevice())) {
				// Here I set local instance variables for touch
				//trace("CAZZOOOOOOOOOOOOOOOOO");
				_isTouch = true;
				_autoScroll = false;
				setToTouchMode							();
			}
			_isNormal									= !_isTouch;
			_scrollVfunc								= _smoothScrollOn ? smoothScrollV : doScrollV; // I set those here since stopping scroll I could remove them
			_scrollHfunc								= _smoothScrollOn ? smoothScrollH : doScrollH; // I set those here since stopping scroll I could remove them
			if (_verbose) Debug.debug(_debugPrefix, _isTouch ? "Touch capabilities detected: " + Multitouch.supportedGestures : "No touch capabilities available.");
			if (_isTouch)								activateSwipeScroll();
			// INITIALIZE
			_rectangle									= new Rectangle(0, 0, _w, _h);
			if (UCode.exists(_scrollVertLink))					_scrollV = setupScrollBarLink(_scrollVertLink, "Vertical");
			if (UCode.exists(_scrollHorizLink))				_scrollH = setupScrollBarLink(_scrollHorizLink, "Horizontal");
			if (_useMouseWheel)							addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			if (_coverBg)								renderBgCover();
		}
			private function renderBgCover					() {
				_bgClip								= UDisplay.addChild(this, UDisplay.getSquareClip({width:_w, height:_h, alpha:0})) as MovieClip;
			}
			private function setupScrollBarLink				(link:String, funcPost:String):MovieClip {
				var sb = this.parent[link];
				return								setupScrollBar(UCode.getPathFromString(this.parent, link), funcPost);
			}
				private function setupScrollBar				(sb:MovieClip, funcPost:String):MovieClip {
					sb._cBase_eventPostfix					= funcPost;
					sb.addListener						(this);
					return							sb;
				}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public override function update						(par:Object):void {
			super.update								(par);
			proceedWithUpdate							();
			if (_verbose)								Debug.debug(_debugPrefix, "updated to:",Debug.object(par));
		}
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
			proceedWithUpdate							();
			if (_verbose)								Debug.debug(_debugPrefix, "Resized to:",_rectangle);
		}
			private function proceedWithUpdate				():void {
				_rectangle								= new Rectangle(0, 0, _w, _h);
				if (hasContent())						setContent(_content);
			} 
		/**
		 * REMEMBER - to have touch scroll on desktop FORCE_SWIPE_SCROLL static var must be set to true.
		 * @param	c
		 * @param	userBounds
		 */
		public function setContent							(c:*, userBounds:Rectangle=null) {
			if (UCode.exists(_content))						releaseContent();
			_content									= c is Sprite || c is MovieClip ? c : UDisplay.wrapInNewSprite(c);
			_realBounds								= getFullBounds(_content);
			_content.x = 0; _content.y = 0;
			addChild									(_content);
			updateSize									(userBounds);
			resetScroll									();
			setAutoScrollActive							(_autoScroll);
			adjustScrollV();
			_useScrollRect = !_useBlitMask;
			if (_useScrollRect) _content.scrollRect = _rectangle;
			else _mover.setupBlitMask(_content, _rectangle.width, _rectangle.height);
			complete();
			if (_limitScroll != "ALL") {
				if (_limitScroll == "VERTICAL") blockScrollH();
				else blockScrollV();
			}
// 			if (_bgClip)									addChild(_bgClip);
		}
		public function setScrollBarV(sb:MovieClip):void {
			_scrollV = setupScrollBar(sb, "Vertical");
		}
		public function setScrollBarH(sb:MovieClip):void {
			_scrollH = setupScrollBar(sb, "Horizontal");
		}
		public override function release():void {
			stopScroll();
			resetScroll();
			if (!UCode.exists(_content)) return; // Prevent errors if content doesnt exist
			_content.scrollRect = null;
			_mover.destroyBlitMask(_content);
			UDisplay.removeClip(_content);
			_content = null;
			super.release();
			if (_useViewport) resetViewPortVariables();
		}
				private function resetViewPortVariables():void {
					_useViewport = false;
					_tiles = null;
					_applyViewportV = function():void {};
				}
				
// 		private var _useViewport							:Boolean; // This gets reset at each setContent. Must be set again calling activateTilesViewport.
// 		private var _tiles									:Vector.<Object>; // All tiles in _content
// 		private var _visibleTiles							:Vector.<Object>; // Only the visible tiles displayed by viewport
// 		private var _tilesViewportMargin						:int; // Howmany tiles show before and after viewport as margin
// 		private var _firstVisibleTile							:int; // The first visible tile in viewport
// 		private var _visibleTilesNum							:int; // The number of visible tiles to be activated (considering _tileHeight, margins and area)
// 		private var _tileHeight								:int; // Height of tile in pixels
		// This activates a VERTICAL viewport of tiles, so that on vertical scroll only the tiles required will be shown.
		public function activateTilesViewportV(tiles:Vector.<Object>, tileHeight:int, margin:int=5):void { // This needs to be called AFTER setContent.
			_tiles = tiles; // Link to the entire list of tiles visualized in _content
			_tileHeight = tileHeight; // Height of each tile
			if ((_tiles.length * _tileHeight) <= _h) return; // No need to set viewport if there is no vertical scroll
			_useViewport = true;
			_tilesViewportMargin = margin;
			_visibleTilesNum = Math.ceil(_h/_tileHeight) + _tilesViewportMargin*2;
			Debug.debug(_debugPrefix, "Activating viewport for " + _tiles.length + " tiles, high px:" + tileHeight + ", total visible:"+_visibleTilesNum);
			_lastVisibleTile = 0; // This makes sure at first iteration all clips are rmeoved or added
			_firstVisibleTile = _tiles.length;
			_firstIterationV = true; // This tells the method that it is a first iteration
			for each (var t:* in _tiles) _content.removeChild(t); // I remove them all to prepare first viewport
			_applyViewportV = applyViewportV;
			_applyViewportV(); // I run this once so to have tiles viewport applied
		}		
		public var releaseContent							:Function = release;
		public function stopScroll							():void { // This stops scroll forever
			_realBounds								= new Rectangle(0,0,0,0);
			resetScroll									();
			stopSmoothScroll								();
			setAutoScrollActive							(false);
// 			PFMover.removeMotion						(this);
			_mover.stopMotions							();
		}
		public function hasContent							():Boolean {
			return									Boolean(_content);
		}
		public function scrollToPerc							(perc:Number) {
			scrollToPercV								(perc);
		}
		public function setToPerc							(perc:Number):void {
			setToPercV									(perc);
		}
		public function setToV								(px:Number):void {
			setToPercV									(UCode.calculatePercent(px, _boundaries.y));
		}
		public function setToPercV							(perc:Number):void {
// 			setToPercV									(perc);
			doScrollV									(perc);
		}
		public function setToPercH							(perc:Number):void {
// 			setToPercV									(perc);
			doScrollH									(perc);
		}
		public function scrollSmallStepV						(down:Boolean):void {
			// Here I scroll 1 third of the total
// 			var step									:Number = 
			scrollToV									(down ? _targetV-_rectangle.height/2 : _targetV+_rectangle.height/2);
		}
		public function stepV								(step:Number) {
			_scrollVfunc								(_scrollVperc + step);
		}
		public function addToScrollV							(px:Number):void { // Adds pixels to actual scroll
			scrollToV(_targetV+px);
// 			var perc									:Number = UCode.calculatePercent(px, _boundaries.y); // Amount of percent to be added
// 			if (down)									scrollToV(_targetV-px);
// 			else										scrollToV(_targetV+px);
		}
		public function addToScrollH							(px:Number):void { // Adds pixels to actual scroll
			scrollToH(_targetH+px);
// 			var perc									:Number = UCode.calculatePercent(px, _boundaries.y); // Amount of percent to be added
// 			if (right)									scrollToH(_targetH-px);
// 			else										scrollToH(_targetH+px);
		}
		public function scrollToV							(px:Number) {
			scrollToPercV								(UCode.calculatePercent(px, _boundaries.y));
		}
		public function scrollToPercV						(perc:Number) {
			_scrollVfunc								(perc);
			_targetV									= Math.round(UCode.getPercent(_targetVperc, _boundaries.y));
		}
		public function stepH								(ahead:Boolean=true):void { // Steps +1 or -1 - moves the amount of content 1 step
			scrollToH									(_rectangle.x + (ahead ? _w : -_w));
		}
		public function scrollToH							(px:Number) {
			scrollToPercH								(UCode.calculatePercent(px, _boundaries.x));
		}
		public function scrollToPercH						(perc:Number) {
			_scrollHfunc								(perc);
// 			_targetH									= _rectangle.x;
			_targetH									= Math.round(UCode.getPercent(_targetHperc, _boundaries.x));
		}
		public function resetScroll							() {
			UCode.setParameters							(_rectangle, {x:0, y:0});
			_scrollVperc = _scrollHperc = _targetH = _targetV = _targetVperc = _targetHperc = _latestScrollH = 0;
			if (_scrollV)								_scrollV.scrollToTop();
			if (_scrollH)								_scrollH.scrollToTop();
		}
		public function updateSize							(userBounds:Rectangle=null) {
			if (userBounds)								_realBounds = userBounds;
// 			else										_realBounds= getFullBounds(_content);

			_boundaries								= new Rectangle(_realBounds.width-_w, _realBounds.height-_h, _w, _h);
			if (UCode.exists(_scrollV)) {
				_scrollV.setScrollSize						(_realBounds.height, _h);
				_scrollV.setEnabled						(_realBounds.height > _h);
			}
			if (UCode.exists(_scrollH)) {
				_scrollH.setScrollSize						(_realBounds.width, _w);
				_scrollH.setEnabled						(_realBounds.width > _w);
			}
		}
		public function getScrollH							():Number {
			return									_targetH;
		}
		public function getScrollV							():Number {
			return									_targetV;
		}
		public function hasVScroll							():Boolean {
			return									_realBounds.height > _h;
		}
		public function hasHScroll							():Boolean {
			return									_realBounds.width > _w;
		}
		public function scrollToTop							() {
			scrollToPerc								(0);
		}
		public function scrollToBottom						() {
			scrollToPerc								(100);
		}
		public function restoreScroll							() { // Scrolls again to the latest position
			if (UCode.exists(_latestScrollV))					scrollToPercV(_latestScrollV);
		}
		public function updateLastScroll						() {
			_latestScrollV								= _targetVperc;
		}
		public function scrollToShowContent					(c:DisplayObject, instant:Boolean=false, offset:Number=0) { // Scrolls to show the specified content
			// MAKE SURE CONTENT IS REALLY INSIDE CONTENT BOX, OR BEHAVIOUR WILL BE HORRIBLE!!!
			// This doesn't work well with tiles
			if (c.parent == _content) {
				Debug.debug							(_debugPrefix, "Restoring as visible scroll " + c);
				if (_rectangle.y > (c.y-_autoScrollMargin))			scrollToV(c.y-_autoScrollMargin); // Scroll up if object is on top of scroll area
				else if (c.y > ((_rectangle.y+_rectangle.height)-(c.height+_autoScrollMargin))) scrollToV((c.y-(_rectangle.height-c.height))+_autoScrollMargin); // Scroll down if object is below visible area
			}
			else {
				Debug.debug								(_debugPrefix, "Scrolling to see " + c + " using global coordinates.");
				var p										:Point = globalToLocal(_content.localToGlobal(new Point(c.x, c.y)));
				var cy									:Number = p.y;
				var px									:Number;
				if (_rectangle.y > (cy-_autoScrollMargin))			px = cy-_autoScrollMargin; // Scroll up if object is on top of scroll area
				else if (cy > ((_rectangle.y+_rectangle.height)-(c.height+_autoScrollMargin))) px = (cy-(_rectangle.height-c.height))+_autoScrollMargin; // Scroll down if object is below visible area
				if (instant)									setToV(px+offset);
				else										scrollToV(px+offset);
			}
		}
		public function setAutoScrollActive						(a:Boolean):void {
			if (a) {
				addEventListener(MouseEvent.MOUSE_MOVE, scrollOnMousePosition, false, 0, true);
			}
			else {
				removeEventListener(MouseEvent.MOUSE_MOVE, scrollOnMousePosition);
			}
		}
		public function blockScrollH							():void {
			_scrollHfunc								= UCode.dummyFunction
		}
		public function blockScrollV							():void {
			_scrollVfunc								= UCode.dummyFunction
		}
		private function startSmoothScroll					():void { // Starts broadcasting continuous scroll
			if (_broadcastContScrollV) {
				UExec.addEnterFrameListener				(broadcastContV);
			}
			if (_broadcastContScrollH) {
				UExec.addEnterFrameListener				(broadcastContH);
			}
		}
		private function stopSmoothScroll						(e:*=null):void {
			if (_broadcastContScrollV) {
				UExec.removeEnterFrameListener				(broadcastContV);
			}
			if (_broadcastContScrollH) {
				UExec.removeEnterFrameListener				(broadcastContH);
			}
			stopSmoothScrollH							();
			stopSmoothScrollV							();
			if (_useBlitMask)							_mover.deactivateBlitMask(_content);
		}
				private function broadcastContH				(e:Event):void {
					broadcastEvent						("onScrollContH", _scrollHperc);
				}
				private function broadcastContV				(e:Event):void {
					broadcastEvent						("onScrollContV", _scrollVperc);
				}
// SWIPE SCROLL ///////////////////////////////////////////////////////////////////////////////////////
		private var _lastTouchY							:int;
		private var _lastTouchX							:int;
		private var _stopTapPropagation						:Boolean; // This blocks propagation of tap events when I am sure user wants to scroll and not to tap
		private static const TAP_BLOCK_TIMEOUT				:uint = 200; // If user keeps pressed for longer than this, tap propagation is blocked
		private var _tapPropagationOffset						:uint;
// 		private var _mouseIsDown							:;
		private function activateSwipeScroll					():void {
			Debug.debug								(_debugPrefix, "Activating Touch Scroll with Tap prevention");
			this.addEventListener							(TouchEvent.TOUCH_BEGIN, onTouchBegin, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			this.addEventListener							(TouchEvent.TOUCH_MOVE, onTouchMove, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			this.addEventListener							(TouchEvent.TOUCH_END, onTouchEnd, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			// Click intercept functions - ALWAYS BLOCK
			this.addEventListener							(MouseEvent.MOUSE_DOWN, onEventInterceptAndProcess, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			this.addEventListener							(MouseEvent.MOUSE_UP, onEventInterceptAndProcess, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			this.addEventListener							(MouseEvent.MOUSE_OVER, onEventInterceptAndBlock, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			this.addEventListener							(MouseEvent.MOUSE_OUT, onEventInterceptAndBlock, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			this.addEventListener							(MouseEvent.CLICK, onEventInterceptAndProcess, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			// Click intercept functions - BLOCK ONLY IF DRAGGING
			this.addEventListener							(TouchEvent.TOUCH_TAP, onEventInterceptAndProcess, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
			this.addEventListener							(MouseEvent.MOUSE_UP, onEventInterceptAndProcess, EVENT_USE_CAPTURE, EVENT_PRIORITY, EVENT_WEAK_REFERENCE);
		}
		
			// EVENTS INTERCEPTION TO ALLOW DRAGGING WITHOUT INTERACTING
				private function onEventInterceptAndBlock(e:Event):void {
					// Events routed here are always stopped
					//if (e.type != TouchEvent.TOUCH_MOVE) Debug.debugDebugging(_debugPrefix, "BLOCKING ",e);
					if (e.type != TouchEvent.TOUCH_MOVE) Debug.debugDebugging(_debugPrefix, "Stopped propagation: " , e.type);
					e.stopImmediatePropagation();
					e.stopPropagation();
					e.preventDefault();
				}
				private function onEventInterceptAndProcess		(e:Event):void {
					// Events routed here are blocked ONLY if blocking switch is activated
					Debug.debugDebugging(_debugPrefix, "onEventInterceptAndProcess(), stop:",_stopTapPropagation,e.type);
					if (_stopTapPropagation) {
						// Block event and release switch
						onEventInterceptAndBlock(e);
						//_stopTapPropagation = false;
					}
				}
			// REAL MOTION EVENTS
				private function onTouchBegin(e:TouchEvent):void {
					_stopTapPropagation = false; // Here it gets set to false, since now it is not set to false whenever dragging is active
					if (e.isPrimaryTouchPoint) {
						_tapPropagationOffset = getTimer() + TAP_BLOCK_TIMEOUT;
						_lastTouchY = e.stageY;
						_lastTouchX = e.stageX;
						onEventInterceptAndBlock(e as Event);
					}
				}
				private function onTouchEnd(e:TouchEvent):void {
					//if (e.isPrimaryTouchPoint) onEventInterceptAndProcess(e as Event);
					if (e.isPrimaryTouchPoint) onEventInterceptAndBlock(e as Event);
				}
				private function onTouchMove(e:TouchEvent):void {
					if (e.isPrimaryTouchPoint) {
						// Perform scroll operations
						if (hasVScroll()) {
							addToScrollV				((_lastTouchY-e.stageY)*_containerZoomFactor);
							_lastTouchY				= e.stageY;
						}
						if (hasHScroll()) {
							addToScrollH				((_lastTouchX-e.stageX)*_containerZoomFactor);
							_lastTouchX				= e.stageX;
						}
						// Block event
						onEventInterceptAndBlock			(e as Event);
						// Update last touch
						if (!_stopTapPropagation && getTimer() > _tapPropagationOffset) {
							Debug.debug				(_debugPrefix, "Blocked TAP propagation.");
							_stopTapPropagation			= true;
						}
					}
				}
// LISTENERS /////////////////////////////////////////////////////////////////////////////////////
		public function onScrollVertical						(perc:Number) {
			_scrollVfunc									(perc);
		}
		public function onScrollHorizontal						(perc:Number) {
			_scrollHfunc									(perc);
		}	
		private function onMouseWheel						(e) {
			if (!hasVScroll())								return; // Inhibit scroll wheel if there is nothing to scroll
			scrollSmallStepV								(Boolean(Number(e.delta)>0));
// 			adjustScrollV								();
		}
		private function scrollOnMousePosition					(e:MouseEvent):void {
			if (hasVScroll())								onScrollVertical(UCode.calculatePercent(mouseY-_mouseScrollMargin, _h-_mouseScrollMargin*2));
			if (hasHScroll())								onScrollHorizontal(UCode.calculatePercent(mouseX-_mouseScrollMargin, _w-_mouseScrollMargin*2));
		}
// SCROLL FUNCTIONS ////////////////////////////////////////////////////////////////////////////////
	// NORMAL SCROLL
		private function doScrollV							(perc:Number) {
			if (!hasVScroll())							return;
			_targetVperc = _scrollVperc						= setInRange(perc);
			positionContentV								();
			broadcastV									();
		}
		private function doScrollH							(perc:Number) {
			if (!hasHScroll())							return;
			_targetHperc = _scrollHperc						= setInRange(perc);
			positionContentH								();
			broadcastH									();
		}
	// SMOOTH SCROLL
		private function smoothScrollV						(perc:Number) {
			if (!hasVScroll()) {
				stopSmoothScrollV						();
				return;
			}
			_targetVperc								= setInRange(perc);
			_latestScrollV								= _targetVperc; //UCode.getPercent(_boundaries.y, _targetVperc);
			activateSmoothScrolling						();
			adjustScrollV								();
			addEventListener							(Event.ENTER_FRAME, positionContentV, false, 0, true);
			broadcastV								();
		}
		private function stopSmoothScrollV						() {
			removeEventListener							(Event.ENTER_FRAME, positionContentV);
		}
		private function smoothScrollH						(perc:Number) {
			if (!hasHScroll()) {
				stopSmoothScrollH						();
				return;
			}
			_targetHperc								= setInRange(perc);
			_latestScrollH								= _targetHperc; //UCode.getPercent(_boundaries.y, _targetVperc);
			activateSmoothScrolling						();
			adjustScrollH								();
			addEventListener							(Event.ENTER_FRAME, positionContentH, false, 0, true);
			broadcastH								();
		}
		private function stopSmoothScrollH					() {
			removeEventListener							(Event.ENTER_FRAME, positionContentH);
		}
		private function activateSmoothScrolling					():void {
			/* Qui ho dovuto togliere il "pow" perch� TweenSockNano mi dava un errore. Cercava il "pow" sulla ContentBoxTouch. Forse � un rimasuglio di una vecchia cosa. */
// 		static public function slideIn							(c:*, p:Object, steps:uint=20, overwrite:Boolean=true, useFrames:Boolean=true) {
// 			doMoveCompatible							(c, {endPos:p, steps:steps, endMotionDirective:p.emd}, "Strong.easeOut", useFrames);
// 		}	
			startSmoothScroll							();
// 			PFMover.slideIn								(this, {_scrollVperc:_targetVperc, _scrollHperc:_targetHperc, onComplete:stopSmoothScroll}, _scrollSpeed);
			_mover.move								(this, _scrollTime, {_scrollVperc:_targetVperc, _scrollHperc:_targetHperc, onComplete:stopSmoothScroll}, _scrollEase);
			if (_useBlitMask)							_mover.activateBlitMask(_content);
			// (c:*, time:Number, vars:Object, ease:String="Quart.easeOut", emd:String=null, dir:String="to"):TweenN
// 			PFMover.slideIn							(this, {steps:_scrollSpeed, pow:_scrollPow, endPos:{_scrollVperc:_targetVperc, _scrollHperc:_targetHperc}, onComplete:stopSmoothScroll});
		}
	// UTY - Check Range
		private function setInRange(n:Number):Number {
			if (n > 100) return 100;
			else if (n < 0) return 0;
			else return n;
		}
		private function checkRangeH						() {
			if (_scrollHperc < 0)							_scrollHperc = 0;
			else if (_scrollHperc > 100)						_scrollHperc = 100;
		}
	// UTY - Position Content - in any situation, THESE are the methods to position content
		private function positionContentV						(e:Event=null) {
			_rectangle.y								= UCode.getPercent(_boundaries.y, _scrollVperc);
			_applyViewportV								();
			if (_content != null) {
				if (_useScrollRect)						_content.scrollRect = _rectangle;
				else 									_mover.scrollBlitMaskV(_content, _scrollVperc/100);
			}
		}
		private function positionContentH						(e:Event=null) {
			_rectangle.x								= UCode.getPercent(_boundaries.x, _scrollHperc);
			if (_content != null) {
				if (_useScrollRect)						_content.scrollRect = _rectangle;
				else 									_mover.scrollBlitMaskH(_content, _scrollHperc/100);
			}
		}
// 			_tiles										= tiles; // Link to the entire list of tiles visualized in _content
// 			_tileHeight									= tileHeight; // Height of each tile
// 			_tilesViewportMargin							= margin;
// 			_visibleTilesNum								= Math.ceil(_h/_tileHeight) + _tilesViewportMargin*2;
// 			_visibleTiles								new Vector.<Object>(_visibleTilesNum); // There can only be a maximum of visible tiles in the viewport (visible + margin)
// 			_visibleTilesNum								= NaN; // This is defined in the next applyTilesViewPort();
// 			_applyViewportV								= applyViewportV;
// 			_applyViewportV								(); // I run this once so to have tiles viewport applied
	// UTY - apply viewport for tiles
		private function applyViewportV						():void { // Called after positioning content in order to adjust tiles
			// Find the first visible tile
			var firstPos								:int = Math.floor(_rectangle.y / _tileHeight);
			if (firstPos > _tilesViewportMargin)				firstPos -= _tilesViewportMargin;
			else										firstPos = 0;
			if (firstPos == _firstVisibleTile)					return; // just break the function if I didnt move enough to change the viewport
			var lastPos									:int = firstPos + _visibleTilesNum;
			if (lastPos >= _tiles.length)						lastPos = _tiles.length-1;
			var i										:int;
			var t										:*;
			if (_firstIterationV) {
				// This is the first iteration, so I just loop thorugh all and set visible only the ones I need
				for (i=firstPos; i<=lastPos; i++) {
					_content.addChild					(_tiles[i]);
				}
				_firstIterationV							= false;
			}
			// Lets try a different algorythm, just remove all visible and scroll all
			else {
				for (i=_firstVisibleTile; i<=_lastVisibleTile; i++)	_content.removeChild(_tiles[i]);
				for (i=firstPos; i<=lastPos; i++)				_content.addChild(_tiles[i]);
			}
			
			
// 			// This is a second iteration, so I need to remove the last visible ones and add only the different ones
// 			else if (firstPos > _firstVisibleTile) {  // I scrolled up
// 				for (i=_firstVisibleTile; i<firstPos; i++) 			_content.removeChild(_tiles[i]);
// 				for (i=_lastVisibleTile+1; i<=lastPos; i++) 		_content.addChild(_tiles[i]);
// 			}
// 			else if (firstPos > _lastVisibleTile) {  // I just scrolled too much
// 				for (i=firstPos; i<_firstVisibleTile; i++) 			_content.addChild(_tiles[i]);
// 				for (i=lastPos+1; i<=_lastVisibleTile; i++) 		_content.removeChild(_tiles[i]);
// 			}
// 			trace(_content.numChildren);
			_firstVisibleTile								= firstPos;
			_lastVisibleTile								= lastPos;
		}
	// UTY - Ajust ScrollBar Position
		private function adjustScrollV						() {
			if (UCode.exists(_scrollV))						_scrollV.setScrollPosition(_targetVperc, false);
		}
		private function adjustScrollH						() {
			if (UCode.exists(_scrollH))						_scrollH.setScrollPosition(_targetHperc, false);
		}
	// UTY - Fucking solution to scrollrect problem
		private function getFullBounds 						(displayObject:DisplayObject):Rectangle {
			var bounds:Rectangle, transform:Transform, toGlobalMatrix:Matrix, currentMatrix:Matrix;
			transform 									= displayObject.transform;
			currentMatrix 								= transform.matrix;
			toGlobalMatrix 								= transform.concatenatedMatrix;
			toGlobalMatrix.invert							();
			transform.matrix 								= toGlobalMatrix;
			bounds 									= transform.pixelBounds.clone();
			transform.matrix 								= currentMatrix;
			return 									bounds;
		}
	// UTY - Broadcast scroll
		private function broadcastH							() {
			broadcastEvent								("onScrollH", _targetHperc);
		}
		private function broadcastV							() {
			broadcastEvent								("onScrollV", _targetVperc);
		}
		
	} // CLOSE CLASS ///////////////////////////////////////////////////////////////////////////////
}