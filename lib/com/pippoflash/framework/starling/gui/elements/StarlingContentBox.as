package com.pippoflash.framework.starling.gui.elements 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling._StarlingBase;
	import com.pippoflash.utils.*;
	import com.pippoflash.motion.PFMover;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.gestouch.gestures.SwipeGesture;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import starling.display.Sprite;
	
	/**
	 * A content can be set in this box, and the content can be panned and launched on top or bottom.
	 * @author Pippo Gregoretti
	 */
	public class StarlingContentBox extends _StarlingBase 
	{
		public static const VERBOSE_DEBUG:Boolean = true;
		public static const STEP_DEFAULT_FRICTION:Number = 10; // Default friction (was force) to be applied to step motions
		private static const MOVING_PAN_TIME:Number = 0.3;
		public static const EVT_SWIPE_STEP:String = "onSwipeStep"; // When a swipe on entire page step is made
		public static const EVT_PAN_START:String = "onPanStart"; // this - when a finger pan motion starts
		public static const EVT_PAN_END:String = "onPanEnd"; // this - when a pan motion finishes removing finger
		public static const EVT_PAN_X:String = "onPanX"; // this - pan impulse with direction - everytime finger is moved
		public static const EVT_PAN_Y:String = "onPanY"; // this - pan impulse with direction - everytime finger is moved
		public static const EVT_PAN_STEP_X:String = "onPanStepX"; // this - panning on a step - when a tap on scrollbar is done
		public static const EVT_PAN_STEP_Y:String = "onPanStepY"; // this - panning on a step - when a tap on scrollbar is done
		public static const EVT_PANNING_X:String = "onContentBoxPanX"; // this  - every change at X value - full FPS motion
		public static const EVT_PANNING_Y:String = "onContentBoxPanY"; // this  - every change at Y value - full FPS motion
		public static const EVT_PAN_MOTION_COMPLETE:String = "onPanSmoothMotionComplete"; // this - when smooth pan moption is complete
		private var _size:Rectangle;
		private var _masked:Boolean;
		private var _myMask:Canvas; 
		private var _contentHolder:Sprite;
		private var _content:DisplayObject;
		private var _panBounds:Rectangle;
		private var _panBoundsReverse:Rectangle; // Same bounds but reverse (real negative number)
		private var _panMethod:Function;
		private var _xx:Number = 0;
		private var _yy:Number = 0;
		// Switches
		private var _broadcastEvents:Boolean; // If content box should broadcast events
		private var _doNotGoOutOfBounds:Boolean; // If true, image will never scroll out of bounds
		//private var _maxPan:Point; // Max pan X and Y
		//private var _minPan:Point; // Min pan X and Y
		private var _softBounds:Boolean = true; // If go over bounds when dragging
		// Scrollers connected
		private var _scrollHoriz:ScrollBase;
		private var _scrollVert:ScrollBase;
		private var _scrollingH:Boolean; // If I am scrolling with H scroller
		private var _scrollingV:Boolean; // If I am scrolling with V scroller
		private var _panning:Boolean; // If I am panning
		private var _swiping:Boolean; // If I am moving because of a swipe
		private var _entering:Boolean; // If I am performing the initial entering animation
		
		private static var _mover:PFMover = new PFMover("StarlingContentBox");
		
		// Scroll methods
		private var _panTarget:Point = new Point();
		private var _lastPanFriction:Number; // This is stored because it is useful to be retrieved in order to send the same impulse to another contentBox
		
		public function StarlingContentBox(size:Rectangle=null, masked:Boolean=false, listensToTouchEvents:Boolean=true, listensToSwipe:Boolean=false) {
			super("StarlingContentBox", StarlingContentBox, false);
			_mover = new PFMover(_instanceId);
			_panMethod = panXY;
			_masked = masked;
			_size = size ? size : UGlobal.getOriginalSizeRect();
			_contentHolder = new Sprite();
			addChild(_contentHolder);
			Debug.debug(_debugPrefix, "Setup on size ", _size);
			if (_masked) {
				_myMask = new Canvas();
				_myMask.beginFill(0xff0000);
				_myMask.drawRectangle(0, 0, _size.width, _size.height);
				addChild(_myMask);
				mask = _myMask;
			}
			if (listensToTouchEvents) {
				StarlingGesturizer.addPan(_contentHolder, onPan, true, true, 2);
				StarlingGesturizer.addPanStart(_contentHolder, onPanStart);
				StarlingGesturizer.addPanEnd(_contentHolder, onPanEnd);
			}
			if (listensToSwipe) StarlingGesturizer.addSwipe(_contentHolder, onSwipe, "L,R");
		}
		// CONTENT METHODS
		public function release():void {
			if (_content) {
				resetPan();
				_content.removeFromParent();
				_content = null;
			}
		}
		public function setContent(c:DisplayObject, bounds:Rectangle = null):void {
			Debug.debug(_debugPrefix, "setContent() bounds: " + bounds);
			release();
			_content = c;
			_contentHolder.addChild(c);
			_panBounds = bounds ? bounds : new Rectangle(0, 0, _content.width - _size.width, _content.height - _size.height);
			_panBoundsReverse = new Rectangle(0, 0, -_panBounds.width, -_panBounds.height);
			//Debug.scream(_debugPrefix, "BOUNDS:"+_panBounds,_content.width, _content.height);
		}
		public function updateScrollBounds(bounds:Rectangle = null):void {
			resetPan();
			setContent(_content, bounds);
		}
		
		// PANNING METHODS
		public function resetPan():void {
			setPan(0, 0);
		}
		public function stopPan():void {
			_panning = false;
			_swiping = false;
			setPan(_contentHolder.x, _contentHolder.y);
		}
		public function setPan(targX:Number, targY:Number):void { // Sets pan immediately
			_mover.stopMotions();
			//_mover.stopMotion(_contentHolder);
			_panTarget.x = targX;
			_panTarget.y = targY;
			xx = targX;
			yy = targY;
		}
		public function panTo(xx:Number, yy:Number, friction:Number = -1, withinBoundaries:Boolean = true):void {
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "panto()",arguments);
			if (isNaN(xx) || isNaN(yy) || isNaN(friction)) {
					Debug.error(_debugPrefix, "NN Intercepted in parameters. paTo() aborted.");
					//return;
			}
			if (friction < 0) friction = STEP_DEFAULT_FRICTION;
			//trace("PANNO A:",xx,yy);
			if (withinBoundaries) {
				xx = UNumber.getRanged(xx, _panBounds.x, _panBoundsReverse.width);
				yy = UNumber.getRanged(yy, _panBounds.y, _panBoundsReverse.height)
				//trace("BOUNDARIESSSSSSSSSS",_panBounds,xx,yy);
			}
				//_panTarget.x = UNumber.getRanged(xx, _panBounds.x, -_panBounds.width)
				//_panTarget.y = UNumber.getRanged(yy, _panBounds.y, -_panBounds.height)
				//
			//} else {
			if (_panTarget.x != xx) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PAN_X, this);
			if (_panTarget.y != yy) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PAN_Y, this);
			_panTarget.x = xx;
			_panTarget.y = yy;
			//}
			_panMethod(friction > 3 ? friction * 0.33 : friction);
		}
		public function panToRatio(xRatio:Number, yRatio:Number, friction:Number =-1, withinBoundaries:Boolean = true):void {
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "panToRatio()",arguments);
			xRatio = UNumber.getRanged01(xRatio);
			yRatio = UNumber.getRanged01(yRatio);
			panTo(-(_panBounds.width*xRatio), -(_panBounds.height*yRatio), friction, withinBoundaries);
		}
		public function enterFromRight(friction:Number = 1):void {
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "enterFromRight()", arguments);
			_entering = true;
			setPan(_size.width, _panTarget.y);
			panTo(0, _panTarget.y, friction);
		}
		/**
		 * Steps to the right the same amount (if possible) of box width
		 * ratio The amount of space to scroll. 0.5 = 50%
		 */
		public function stepXRight(ratio:Number=1, friction:Number=-1):void {
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "stepXRight()",arguments);
			panTo(xx - (_size.width*ratio), _panTarget.y, friction);
		}
		public function stepXLeft(ratio:Number=1, friction:Number=-1):void {
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "stepXLeft()",arguments);
			panTo(xx + (_size.width*ratio), _panTarget.y, friction);
		}
		/**
		 * Steps content horizontally, the amount of content width. If image is not at precise content width, next step will be reached.
		 */
		public function stepXContentWidth(left:Boolean=true):Boolean {
			//trace(_xx, _contentHolder.width, _size);
			// find positions
			//const mult:Number = _size.width / _contentHolder.width;
			//const steps:uint = Math.ceil(_contentHolder.width / _size.width);
			const positions:Vector.<Number> = xStepsScrollPositions;
			//for (var i:int = 0; i < steps; i++) {
				//positions[i] = -(_contentHolder.width * (i*mult));
				//if (positions[i] > _panBounds.width) positions[i] = -(_panBounds.width)
			//}
			// Going left, I Increase the number
			var targetX:Number; // Find traget X according to left or right
			if (left) { // Going left
				for (var i:int = 0; i < positions.length; i++) {
					if (_panTarget.x > positions[i]) {
						Debug.debug(_debugPrefix, "Stepping LEFT into position: ",i);
						panTo(positions[i], _yy);
						return true;
					}
				}
			} else { // Going right
				for (i = positions.length-1; i >= 0; i--) {
					if (_panTarget.x < positions[i]) {
						Debug.debug(_debugPrefix, "Stepping RIGHT into position: ",i);
						panTo(positions[i], _yy);
						return true;
					}
				}
			}
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "stepXContentWidth() not possible.", arguments);
			return false;
		}
		/**
		 * Pans to a step, considering viewport size x step. Does not consider entire largeness of content.
		 * @param	step
		 * @param	force
		 * @param	forceSwiping Will notify that image is swiping until motion is complete
		 */
		public function panXToStepNum(step:int, force:Number = 10, forceSwiping:Boolean=true):void {
			var availableSteps:uint = Math.ceil(_content.width / _size.width);
			step = UNumber.getRanged(step, availableSteps - 1, 0);
			stopPan();
			if (forceSwiping) _swiping = true;
			panTo(-(_size.width*step), _yy, force);
			
			
			//const positions:Vector.<Number> = xStepsScrollPositions;
			//step = UNumber.getRanged(step, positions.length - 1, 0);
			//stopPan();
			//panTo(positions[step], _yy, force);
		}
		
		
		///**
		 //* If content also listens to swipe gestures, pan will not feel natural. This simulates pan from a swipe gesture recived by something else.
		 //* @param	swipe
		 //*/
		//public function tunnelSwipeGesture(swipe:SwipeGesture, force:Number=2, swipeMultiplier:Number=100):void {
			////onPanStart();
			//onPan(_contentHolder, new Point(swipe.offsetX*swipeMultiplier, swipe.offsetY*swipeMultiplier), force, true);
			////onPanEnd();
		//}
		
		
		
		
		/**
		 * Sets pan to both vertical and horizontal.
		 */
		public function setPanXY():void {
			_panMethod = panXY;
		}
		/**
		 * Seta pan to horizontal only.
		 */
		public function setPanX():void {
			_panMethod = panX;
		}
		/**
		 * Sets pan to vertical only.
		 */
		public function setPanY():void {
			_panMethod = panY;
		}
		/**
		 * Swith off pan completely.
		 */
		public function setPanNone():void {
			Debug.warning(_debugPrefix, "PAN HAS BEEN SWITCHED OFF.");
			_panMethod = UCode.dummyFunction;
		}
		
		// SYSTEM METHODS
		public function connectToScrollerHorizontal(hScroll:ScrollBase):void {
			_scrollHoriz = hScroll;
			PippoFlashEventsMan.addInstanceListener(_scrollHoriz, this);
			PippoFlashEventsMan.addInstanceMethodListenerTo(_scrollHoriz, ScrollBase.EVT_SCROLL_START, onScrollStartH);
			PippoFlashEventsMan.addInstanceMethodListenerTo(_scrollHoriz, ScrollBase.EVT_SCROLL, onScrollH);
			PippoFlashEventsMan.addInstanceMethodListenerTo(_scrollHoriz, ScrollBase.EVT_SCROLL_END, onScrollEndH);
			PippoFlashEventsMan.addInstanceMethodListenerTo(_scrollHoriz, ScrollBase.EVT_SCROLL_STEP, onScrollStepH);
		}
		public function connectToScrollerVertical(vScroll:ScrollBase):void {
			_scrollVert = vScroll;
			PippoFlashEventsMan.addInstanceListener(_scrollVert, this);
			PippoFlashEventsMan.addInstanceMethodListenerTo(_scrollVert, ScrollBase.EVT_SCROLL_START, onScrollStartV);
			PippoFlashEventsMan.addInstanceMethodListenerTo(_scrollVert, ScrollBase.EVT_SCROLL, onScrollV);
			PippoFlashEventsMan.addInstanceMethodListenerTo(_scrollVert, ScrollBase.EVT_SCROLL_END, onScrollEndV);
			PippoFlashEventsMan.addInstanceMethodListenerTo(_scrollVert, ScrollBase.EVT_SCROLL_STEP, onScrollStepV);
		}
		
		
		
		
		// SCROLLER LISTENERS
		private function onScrollStartH(c:ScrollBase):void {
			_scrollingH = true;
			onPanStart();
		}
		private function onScrollH(c:ScrollBase):void {
			panToRatio(c.scroll, 0);
		}
		private function onScrollEndH(c:ScrollBase):void {
			//trace("end");
			_scrollingH = false;
			onPanEnd();
		}
		private function onScrollStepH(c:ScrollBase):void {
			_scrollingH = true;
			panToRatio(c.scroll, 0);
			if (_broadcastEvents) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PAN_STEP_X, this);
			_scrollingH = false;
		}
		
		// SCROLLER LISTENERS
		private function onScrollStartV(c:ScrollBase):void {
			_scrollingV = true;
			onPanStart();
		}
		private function onScrollV(c:ScrollBase):void {
			panToRatio(0, c.scroll);
		}
		private function onScrollEndV(c:ScrollBase):void {
			//trace("end");
			_scrollingV = false;
			onPanEnd();
		}
		private function onScrollStepV(c:ScrollBase):void {
			_scrollingV = true;
			panToRatio(0, c.scroll);
			if (_broadcastEvents) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PAN_STEP_X, this);
			_scrollingV = false;
		}
		
		
		
		
		// SWIPING
		private function onSwipe(c:DisplayObject, dir:String):void {
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "onSwipe()",arguments);
			if (_panning) stopPan();
			//_swiping = true;
			// Swiping is assigned only if swipe is successful, otherwise a swipe already in progress might be overwritten.
			// If I get to last swipe and continue swiping, canceling _swiping would reenable panning.
			const swipeSuccessful:Boolean = stepXContentWidth(dir == "L");
			if (swipeSuccessful) {
				_swiping = swipeSuccessful; 
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SWIPE_STEP, this);
			}
			//trace(targetXPositionStep);
		}
		
		
		
		// PANNING
		
		private function onPanStart(c:DisplayObject = null):void {
			if (_swiping) {
				if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "onPanStart() Aborted because swiping.", arguments);
				return;
			}
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "onPanStart()",arguments);
			stopPan();
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PAN_START, this);
		}
		private function onPan(c:DisplayObject, coords:Point, friction:Number, isEnd:Boolean):void {
			if (_swiping) {
				if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "onPan() Aborted because swiping.", arguments);
				return;
			}
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "onPan()",arguments);
			panTo(
				_panTarget.x + coords.x, 
				_panTarget.y + coords.y, 
				friction, 
				!(_softBounds && !isEnd)
			);
		}
		private function onPanEnd(c:DisplayObject=null):void {
			//if (_swiping) {
				//if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "panto() Aborted because swiping.", arguments);
				//return;
			//}
			if (VERBOSE_DEBUG) Debug.debug(_debugPrefix, "onPanEnd()",arguments);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PAN_END, this);
		}
		private function panXY(friction:Number = -1):void {
			if (friction < 0) friction = STEP_DEFAULT_FRICTION;
			_lastPanFriction = friction;
			_mover.move(this, MOVING_PAN_TIME*friction, {
				onComplete:onPanSmoothMotionComplete,
				xx:_panTarget.x, 
				yy:_panTarget.y
			});
		}
		private function panX(friction:Number=-1):void {
			if (friction < 0) friction = STEP_DEFAULT_FRICTION;
			_lastPanFriction = friction;
			_mover.move(this, MOVING_PAN_TIME*friction, {
				onComplete:onPanSmoothMotionComplete,
				xx:_panTarget.x
			});
		}
		private function panY(friction:Number = 1):void {
			if (friction < 0) friction = STEP_DEFAULT_FRICTION;
			_lastPanFriction = friction;
			_mover.move(this, MOVING_PAN_TIME * friction, {
				onComplete:onPanSmoothMotionComplete,
				yy:_panTarget.y
			});
		}
		// MOTION LISTENER
		private function onPanSmoothMotionComplete():void {
			_swiping = false;
			_panning = false;
			_entering = false;
			if (_broadcastEvents) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PAN_MOTION_COMPLETE, this);
		}
		
		
		
		// GET SET
		/**
		 * The step to which content is going (0, 1, 2) according to scrolled screens.
		 */
		public function get targetXPositionStep():uint {
			const positions:Vector.<Number> = xStepsScrollPositions;
			// Finds deltas and returns the smallest delta
			var step:uint = 0;
			var smallestDelta:Number = _content.width;
			const pos:Number = Math.abs(_panTarget.x);
			//trace(step, smallestDelta, "pos",pos);
			var delta:Number;
			for (var i:int = 0; i < positions.length; i++) {
				delta = Math.abs(Math.abs(positions[i]) - pos);
				//trace("cheack ",i,"pos now",pos,"checking pos:",Math.abs(positions[i]),"delta:",delta);
				if (delta < smallestDelta) {
					//trace("yeah", i);
					smallestDelta = delta;
					step = i;
				}
			}
			return step;
		}
		/**
		 * The positions available for scroll according to content size and page size. Scrolling one page of content.
		 */
		public function get xStepsScrollPositions():Vector.<Number> {
			const mult:Number = _size.width / _contentHolder.width;
			const steps:uint = Math.ceil(_contentHolder.width / _size.width);
			const positions = new Vector.<Number>(steps);
			for (var i:int = 0; i < steps; i++) {
				positions[i] = -(_contentHolder.width * (i*mult));
				if (positions[i] > _panBounds.width) positions[i] = -(_panBounds.width)
			}
			return positions;
		}
		
		
		
		
		public function get xx():Number {
			return _xx;
		}
		
		//private var _newXXValue:Number;
		public function set xx(value:Number):void {
			if (_doNotGoOutOfBounds) value = UNumber.getRanged(value, _panBounds.x, _panBoundsReverse.width);
			//_newXXValue = value;
			_xx = value;
			if (_scrollHoriz && !_scrollingH) _scrollHoriz.setScrollValue(panXRatio, true);
			if (_broadcastEvents && _contentHolder.x != _xx) {
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PANNING_X, this);
				//trace("broadcasto continuous moving.");
			}
			_contentHolder.x = _xx;
		}
		
		
		
		
		
		public function get yy():Number {
			return _yy;
		}
		
		public function set yy(value:Number):void {
			_yy = value;
			_contentHolder.y = _yy;
			if (_scrollVert && !_scrollingV) _scrollVert.setScrollValue(panYRatio, true);
			if (_broadcastEvents) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PANNING_Y, this);
		}
		
		public function set softBounds(value:Boolean):void 
		{
			//trace("SETTO SOFTBOUNDS",value);
			Debug.debug(_debugPrefix, "Set soft bounds to " + value);
			_softBounds = value;
		}
		
		public function set broadcastEvents(value:Boolean):void 
		{
			_broadcastEvents = value;
		}
		
		/**
		 * Get/set Pan X from 0 to 1
		 */
		public function get panXRatio():Number {
			return -_xx / _panBounds.width;
		}
		public function set panXRatio(xr:Number):void {
			xx = -(_panBounds.width * xr);
		}
		/**
		 * Get Pan Y from 0 to 1
		 */
		public function get panYRatio():Number {
			return -_yy / _panBounds.height;
		}
		public function set panYRatio(yr:Number):void {
			yy = -(_panBounds.height * yr);
		}
		/**
		 * Amount of X scroll in pixels
		 * @return
		 */
		public function get panXAmount():Number {
			return -_xx;
		}
		public function get targetPanX():Number {
			return -_panTarget.x;
		}
		
		public function get lastPanFriction():Number 
		{
			return _lastPanFriction;
		}
		
		public function get targetPanY():Number {
			return -_panTarget.y;
		}
		/**
		 * Image will never scroll out of bounds
		 */
		public function set doNotGoOutOfBounds(value:Boolean):void {
			Debug.debug(_debugPrefix, "Set never go out of bounds: ",value);
			_doNotGoOutOfBounds = value;
		}
		/**
		 * If content il vertically larger than space.
		 */
		public function get canScrollVertically():Boolean {
			return _content.height >  _size.height;
		}
		/**
		 * If content il vertically larger than space.
		 */
		public function get canScrollHorizontally():Boolean {
			return _content.width >  _size.width;
		}
		/**
		 * If moving through a swipe.
		 */
		 public function get swiping():Boolean 
		 {
			 return _swiping;
		 }

		 
		 
		 
		 
		 
		/**
		 * If performing the entering animation.
		 */ 
		public function get entering():Boolean 
		 {
			 return _entering;
		 }
	 
		 
	}

}