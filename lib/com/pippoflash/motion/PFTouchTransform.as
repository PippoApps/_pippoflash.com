/* PFTouchTransform 1.4 - Added SWIPE action

-------- USAGE ----------
1 - Set viewport
2 - set image
WARNING - This cannot be reused. Somehow must be stored in UMem and another one has to be used. This needs debuging.





------- CHANGELOG ---------

1.5 - Updated pan limits in order to have it work also on coordinates not starting from 0,0 on stage in line 1110


1.4 - Added swipe gesture listeners
Awipe can be added vertical or horizontal, also a parameter to set swipe active only when image is totally zoomed out


1.3 - tunnel CLICK on single tap
Activating _dispatchClickOnTap & _hasSingleTap tunnels a MouseEvent.CLICK on _contentContent.
If _contentContent listens for MouseEvent.CLICK, it will be triggered.
If INSIDE _contentContent there are clickable buttons (i.e. the floating menu on Royal Atlantis SP masterplan).
Buttons must be made clickable with buttonsizer, or manually, but _contentContent MUST be made clickable with buttonizer, activating tunneling using "tunnel,onClick".


1.2 - rectangle positioning
The new flow for ver 1.2 should be as follows:
1 - viewport is automatically retrieved from stage, unless differently specified
2 - viewport is rel zoom 1
3 - we can store a predefined set of positions
4 - we can always go back to previous position, or to position 1
5 - minimum and maximum zoom can be set, or can be set from actual position


1.1a - Added controls for minimum and maximum zoom. Added methods (but not implemented) to manage default positions.

1.1 - 	Added working with clips with content not necessarily starting from 0:0. It can be also centered content.
		Added automatic recognition of Point and Rectangle as initial position
		Fixed "instant" in positioning, lead all the way to get bounds and adjust zoom
		Fixed several items
		Works pretty well for visualizing and scrolling images
		I am stuck positioning with oprecision on an entire rectangle, and I want to re-do it keeping 1 as full screen, but allowing a minimum zoom much smaller.
		I also want to position it NOT centered but 0:0

1.0 - 	Working well only with clips with content originating from 0:0.

*/

package com.pippoflash.motion {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.framework._PippoFlashBaseNoDisplayUMemDispatcher;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UExec;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UMem;
	import											com.pippoflash.utils.USystem;
	import											com.pippoflash.utils.UNumber;
	import											com.pippoflash.motion.PFMover;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	import 											org.gestouch.gestures.*;
	import 											org.gestouch.events.*;
	import 											org.gestouch.core.*;
	import 											org.gestouch.extensions.native.NativeDisplayListAdapter;

	
	public class PFTouchTransform extends _PippoFlashBaseNoDisplayUMemDispatcher {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		public var _resize:String = "NORMAL";
		public var _useSmooth:Boolean = true; // If motion smooths in or if is instant
		public var _hasZoom:Boolean = true; 
		public var _hasPan:Boolean = true;
		public var _hasRotation:Boolean = false;
		public var _hasSwipeH:Boolean = false; // If SWIPE is active - horizontal
		public var _hasSwipeV:Boolean = false; // If SWIPE is active - vertical
		public var _hasMomentum:Boolean = false; // If panning need to register also momentum
		public var _hasDoubleTap:Boolean = true; // Intercept double tap - IF THIS IS true, reset on double tap will NOT WORK
		public var _hasSingleTap:Boolean = false; // Intercept single tap (inhibits double tap)
		public var _doubleTapReset:Boolean = true; // Brings back to original position - _hasDoubleTap MUST be true
		public var _doubleTapFullSizeWhenLargerThan:Number = 0; // 0 to keep this off. When double tapping an image, if zooming is larger than this, it will go fullscreen. - _hasDoubleTap MUST be true
		public var _doubleTapBackFromFullScreen:Boolean = false; // 0 to keep this off. When double tapping an image, if zooming is larger than this, it will go fullscreen. - _hasDoubleTap MUST be true
		public var _hasMouseEvents:Boolean = true; // If activating Buttonizer events. EVT_TOUCH, EVT_UNTOUCH
		public var _dispatchClickOnTap:Boolean = false; // If tap dispatches a click event for mouse events underneath
		public var _multiplier:Number = 0.30; // Zeno's paradox multiplier
		public var _minimumStep:Number = 0.0004; // Below this step, everythig is arrived
		public var _jumpOnTopWhenTouched:Boolean = false; // Bring content on first row when interacted with - _hasSingleTap MUST be true
		public var _maximumZoomMultiplier:Number = 2;
		public var _boundsOutOfScreenOffset:Number = 0; // This adds or remove space on sides to allow scrolling out of images
		public var _adjustForDeviceBitmap:Boolean = false; // As soon as he renders an image, modifies slightly the zoom, trying to achieve downloading on the graphic card
		public var _allowSmoothingForBitmap:Boolean = true; // If it is a Bitmap, smoothing is turned to on
		public var _alwaysResetRotationOnRectangle:Boolean = true; // Everytime I set content within a rectangle, rotation is reset
		public var _forceReturnRotation:Boolean = false; // On release, rotation always goes back to 0 (rotation is allowed on dragging)
		public var _multiplyForceByZoom:Boolean = true; // This is needed to make strength and momentum always consistent independently from zoom
		public var _fixZoomForBitmapsOnDevice:Number = 1.001; // This fixes zoom when I am using bitmaps on devices, in order to transfer them immediately on GPU
		public var _maskViewport:Boolean = true; // If Viewport should be masked
		public var _verbose:Boolean = true;
		public var _contentZoomingFactor:Number = 1; // If viewer is zoomed, or is inside a zoomed clip, this must be modified in order to keep consistent panning with finger movement
		// MOMENTUM
		public var _minimumForce:Number; // If not populated in startup object, this retrieves default from constant
		public var _forceMultiplier:Number; // If not populated in startup object, this retrieves default from constant
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		private static const POINT_ZERO:Point = new Point(0,0);
		private static const RADIANS_MULT:Number = 180/Math.PI;
		private static const ZOOM_DIGITS_CHECKER:uint = 5; // To check zoo, it will compare only the first 5 digits (1.00182628 = 1.001)
		// MINIMUM CHANGE TO ACTIVATE GESTURE (to avoid glittering when hand is not moving on screen)
		private static const MINIMUM_STEPS:Object = {zoom:0.005, pan:0.8, rot:0.008}; // Minimum values to activate a rotation
		// FORCE TO THROW ITEMS
		private static const MINIMUM_FORCE:Number = 0.8; // This sets the minimum force required for momentum (force is distance)
		private static const FORCE_MULTIPLIER:Number = 30; // Multiplies distance to give momentum (multiplied zoom)
		// ZENO'S PARADOX
		private static const AVERAGE_ZENO_DISTANCE:Number = 1000; // An average distance to decide howmany zeno steps we should use
		private static const MIN_ZENO_STEPS:int = 50; // Smooth animation will be at least this value
		private static const BUFFER_ZENO_STEPS:int = 10; // These will be added to zeno's optimal motion
		// EVENTS - all events have only this as parameter
		public static const EVT_READY:String = "onViewerReady"; // Broadcasted when image is rendered
		public static const EVT_START:String = "onViewerGestureStart"; // Broadcasted when a gesture starts
		public static const EVT_CONTINUE:String = "onViewerGestureContinue"; // Broadcasted when a started gesture continues
		public static const EVT_COMPLETE:String = "onViewerGestureEnd"; // Broadcasted when gesture hand is removed from screen
		public static const EVT_CHANGING:String = "onViewerChanging"; // Broadcasted while motion is in progress - remember this may be changed to EVT_MOMENTUM
		public static const EVT_MOMENTUM:String = "onViewerChangingMomentum"; // When motion is in progress during momentum
		public static const EVT_CHANGED:String = "onViewerChanged"; // Broadcasted when motion is completed
		public static const EVT_SINGLE_TAP:String = "onViewerSingleTap";
		public static const EVT_DOUBLE_TAP:String = "onViewerDoubleTap";
		public static const EVT_SWIPE_UP:String = "onViewerSwipeUp";
		public static const EVT_SWIPE_DOWN:String = "onViewerSwipeDown";
		public static const EVT_SWIPE_RIGHT:String = "onViewerSwipeRight";
		public static const EVT_SWIPE_LEFT:String = "onViewerSwipeLeft";
		public static const EVT_CLICK:String = "onViewerClick";
		public static const EVT_TOUCH:String = "onViewerTouch";
		public static const EVT_UNTOUCH:String = "onViewerTouchUp";
		public static const EVT_RELEASED:String = "onViewerReleased"; // (When viewer is emptied with release())
		// DEBUGGERS
		private static const DEBUG_TARGET:Boolean = false; // Shows target clip
		private static const DEBUG_BOUNDS:Boolean = false; // Shows an overlay on image bounds
		// EVENT PROPERTIES
		private static const EVT_USE_CAPTURE:Boolean = false;
		private static const EVT_WEAK_REFERENCE:Boolean = true;
		private static const EVT_PRIORITY:int = 9;
		private static var _init:Boolean = true;
		private static var _mover:PFMover;
		// USER VARIABLES
		// SYSTEM
		private var _minimumZoom:Number;
		private var _maximumZoom:Number;
		private var _fullScreenZoom:Number; // Stores the zooming required to go fullscreen. Fullscreen status gets removed ONLY if zoom is <than this.
		private var _newZoom:Number; // this is just a utylity used to store proposed zoom
		private var _newMult:Number; // Another utility to calculate zoom
		private var _contentZoom:Number; // Content zooming
		private var _contentZoomMultiplier:Number; // Needed to retrieve _relZoom multiplying real zoom 
		private var _offsetX:Number; // Stores gesture force
		private var _offsetY:Number; // Stores gesture force
		private var _matrix:Matrix; // Transformation matrix
		private var _transformPoint:Point;
		private var _bounds:Rectangle; // Bouds of content
		private var _mainWindow:Rectangle; // Using it as a base
		private var _centerPoint:Point;
		private var _panLimits:Rectangle; // Rectangle with pan limits
		private var _mode:String; // Mode used for viewing images - NORM, VIEW
		// POSITIONS MANAGEMENT
		// Positions are basically objects with datas for content: {x:x, y:y, rotation:rotation, scale:scale}
		private var _originalPosition:Object; // Stores the original position in viewport. Always defaults to CROP-RESIZE.
		private var _previousPosition:Object; // Stores the last position before a new motion or gesture has initiated
		private var _positions:Object = {}; // Stores positions by name
		// MOTION - SMOOTH MOTION
		private var _actualPos:Point = new Point(0,0);
		private var _previousPos:Point; // When motion is registered
		private var _targetPos:Point; // Target X and Y position
		private var _targetZoom:Number;
		private var _targetRotation:Number;
		private var _actualRotation:Number; // Stores number of rotation, since the .rotation property is net reliable jumping over 180
		private var _moving:Boolean; // Moving moving moving
		private var _maxMoveFrames:int; // A Number of frames computed to stop motion eventually
		private var _movedFrames:int;
		// REFERENCES
		private var _parent:DisplayObjectContainer; // The parent containing _content and _realContent clips
		private var _realContent:Sprite; // This is the smoothed and moved one
		private var _content:Sprite;
		private var _contentContent:DisplayObject;
		private var _debugLayer:Sprite;
		private var _maskSprite:Sprite;
		// GESTURES
		private var _gesture:TransformGesture;
		private var _doubleTap:TapGesture;
		private var _singleTap:TapGesture;
		private var _swipeGesture:SwipeGesture;
 		// MARKERS
		private var _releasing:Boolean; // If an animation before releasing is started
		private var _isFullscreen:Boolean;
		private var _fullscreenZoom:Number; // Stores the zoom at fullscreen in order to understand if I am still at fullscreen
		private var _motionContinueEvent:String; // This can be EVT_CHANGING or EVT_MOMENTUM according to motion type
		private var _hasSwipe:Boolean; // This is marked true if _hasSwipeH or _hasSwipeV are true
		// INTERFACE MODE MARKERS
		// SMOOTH SCROLL
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		private static function initGestures():void {
			Gestouch.addDisplayListAdapter(flash.display.Bitmap, new NativeDisplayListAdapter());
			Gestouch.addDisplayListAdapter(flash.display.Sprite, new NativeDisplayListAdapter());
			Gestouch.addDisplayListAdapter(flash.display.MovieClip, new NativeDisplayListAdapter());
			Gestouch.addDisplayListAdapter(flash.display.Stage, new NativeDisplayListAdapter());
			Gestouch.addDisplayListAdapter(flash.text.TextField, new NativeDisplayListAdapter());
			_mover = new PFMover("PFTouchTransform");
			_init = false;
		}
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function PFTouchTransform						(parentClip:DisplayObjectContainer, initObj:Object=null) {
			super									("PFTouchTransform");
			if (_init)									initGestures();
			recycle									(parentClip, initObj);
		}
		public function recycle							(parentClip:DisplayObjectContainer, initObj:Object=null):void {
			_parent									= parentClip;
			UCode.setParameters							(this, initObj);
			if (!_minimumForce)							_minimumForce = MINIMUM_FORCE;
			if (!_forceMultiplier)							_forceMultiplier = FORCE_MULTIPLIER;
			init										();
		}
		protected function init								():void {
			if (isRendered())							release();
			_content									= new Sprite();
			_realContent								= new Sprite();	
			// MASK STUFF
			_maskSprite								= new Sprite();
			UDisplay.drawSquare							(_maskSprite, 100, 100, 0);
			_parent.addChild								(_maskSprite);
			_maskSprite.visible							= false;
			// /////////////
			_content.name								= _debugPrefix + "_content";
			_realContent.name							= _debugPrefix + "_realContent";
			if (DEBUG_BOUNDS) {
				_debugLayer							= new Sprite();
				UDisplay.drawRectangle					(_debugLayer, new Rectangle(-0,0,100,100), 0x0000ff);
				_debugLayer.alpha						= 0.5;
				Buttonizer.setClickThrough					(_debugLayer);
				_debugLayer.x							= 5000;
			}
			moveToTop									();
			setAverageDistance							(AVERAGE_ZENO_DISTANCE);
			setViewport								(UGlobal.stageRect);
			setReady									();
			if (_verbose) Debug.debug						(_debugPrefix, "Activated on",_parent+". Call methods to initiate.");
		}
		public override function cleanup						():void {
			// Calls release, and then makes it ready for a new instantiation.
			super.cleanup								(); // This also calls release
			_parent									= null;
		}
		public override function release						():void {
			// This is called to undo a render operation, and make the component ready again to render content
			// Be careful. Release does NOT dispose content bitmap, this must be done outside.
			if (!isRendered())							return;
			_mover.stopMotion							(_contentContent);
			var c										:DisplayObject = _contentContent;
			_matrix									= null;
			UDisplay.removeClip							(_realContent);
			UDisplay.removeClip							(_content);
			UDisplay.removeClip							(_contentContent);
			if (_debugLayer)								UDisplay.removeClip(_debugLayer);
			_contentContent								= null;
			_content.scaleX = _content.scaleY					= 1;
			if (_gesture) {
				_gesture.removeEventListener				(org.gestouch.events.GestureEvent.GESTURE_BEGAN, onGesturePanZoomSmoothStart);
				_gesture.removeEventListener				(org.gestouch.events.GestureEvent.GESTURE_CHANGED, onGesturePanZoomSmooth);
				_gesture.removeEventListener				(org.gestouch.events.GestureEvent.GESTURE_ENDED, onGestureEnded);
				_gesture.dispose							();
				_gesture								= null;
			}
			if (_doubleTap) {
				_doubleTap.removeEventListener				(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onDoubleTap);
				_doubleTap.dispose						();
				_doubleTap								= null;
			}
			if (_singleTap) {
				_singleTap.removeEventListener				(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSingleTap);
				_singleTap.dispose						();
				_singleTap								= null;
			}
			if (_swipeGesture) {
				_swipeGesture.removeEventListener			(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSwipe);
				_swipeGesture.enabled						= false;
				_swipeGesture.dispose						();
				_swipeGesture							= null;
			}
			if (_hasMouseEvents)							Buttonizer.removeButton(_content);
			// Cleanup variables
			_positions									= {};
			_previousPosition								= null;
			_originalPosition								= null;
			_isFullscreen								= false;
			_fullscreenZoom								= 1;
			super.release								();
			_releasing									= false;				
			if (_verbose) Debug.debug						(_debugPrefix, "Has been cleaned up, and is ready to be rendered again.");
			broadcastEvent								(EVT_RELEASED, c);
		}
		public function getBitmatAndRelease					():DisplayObject { // Releases without making bitmap invisible, and returns the bitmap
			var b										:DisplayObject = _contentContent;
			release									();
			return									b;
		}
		public function setProperties						(p:Object):void { // Sets variables. BE CAREFUL!!!!
			for (_s in p)								this[_s] = p[_s];
		}
// FRAMEWROK ///////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
	// SETTING CONTENT
	// initialRectangle is the initial position where content will be positioned. If startingPos is setup, image is moved from startingPos to initialRectangle
	// startingPos can be a Point or Rectangle, in that case ONLY x and y will be retrieved. Or an object {x, y, scaleX, scaleY, rotation, width, height, alpha}.
	// Be careful, ALL properties from an Object will be set in content.
		public function setContent							(c:DisplayObject, startingPos:Object=null, initialRectangle:Rectangle=null):void { // Sets content for free motion
			// This sets image completely visible, and that is minimum zoom
			// It allows all gestures, and lets image almost disappear from screen
			_mode									= "NORM";
			_resize									= "NORMAL";
			_hasZoom									= true;
			_hasPan									= true;
			_hasRotation								= true;
			setupContent								(c, startingPos, initialRectangle);
		}
		public function setContentViewImage					(c:DisplayObject, startingPos:Object=null, initialRectangle:Rectangle=null, hasRotation:Boolean=false):void { 
			// Sets content as image viewer. Only zoom and pan, never go out of screen.
			// It starts with the image completely visible, and that's the minimum zoom.
			_mode									= "BOUNDS";
			_resize									= "NORMAL";
			_hasZoom									= true;
			_hasPan									= true;
			_hasRotation = hasRotation; // This was previously always false. Now can be overwritten with a parameter.
			setupContent								(c, startingPos, initialRectangle);
		}
		public function setContentViewImageFull				(c:DisplayObject, startingPos:Object=null, initialRectangle:Rectangle=null):void { 
			// Sets content as image viewer. Only zoom and pan, never go out of screen.
			// It never shows an empty pixel. Image minimum zoom is filling all space.
			_mode									= "BOUNDS";
			_resize									= "CROP-RESIZE";
			_hasZoom									= true;
			_hasPan									= true;
			_hasRotation								= false;
			setupContent								(c, startingPos, initialRectangle);
		}
		public function setContentCustom						(c:DisplayObject, hasPan:Boolean=true, hasZoom:Boolean=true, hasRot:Boolean=true, startingPos:Object=null, initialRectangle:Rectangle=null, mode:String="NORM", align:String="NORMAL"):void {
			// Sets a content and positions image in it's original environment, zoom, directly
			setupContentCustom							(c, hasPan, hasZoom, hasRot, startingPos, initialRectangle, mode, align);
		}
	// SET INTERACTION
		public function setZoomActive						(a:Boolean):void {
			_hasZoom									= a;
		}
		public function setRotationActive						(a:Boolean):void {
			_hasRotation								= a;
		}
		public function setPanActive							(a:Boolean):void {
			_hasPan									= a;
		}
	// GETTERS
		// CHECKS
		public function isFullscreen							():Boolean {
			return									_isFullscreen;
		}
		// ZOOM
		public function getZoom							():Number { // The target zoom starting from 1 when image is positioned
			return									_targetZoom;
		}
		public function getRealZoom						():Number { // The real scaling factor of image
			return									_contentZoom;
		}
		public function getActualZoom						():Number { // the zoom of content at this precise moment - not REAL zoom. 
			return									_realContent.scaleX;
		}
		public function getActualRealZoom					():Number { // Real zoom of content at this precise moment
			return									_realContent.scaleX * _contentZoomMultiplier;
		}
		// CONTENTS AND ELEMENTS
		public function getTarget							():Sprite { // Returns the positioned target clip
			return									_content;
		}
		public function getContent							():* { // Returns the original content 
			return									_contentContent;
		}
		public function getSprite							():Sprite { // Returns the containing content (the one that moves)
			return									_realContent;
		}
		public function getMovedContent						():Sprite {
			return									_realContent;
		}
		// COORDINATES POINT POSITIONS
		public function getPos								():Point {
			return									_actualPos;
		}
		public function getPreviousPos						():Point { /* TO BE IMPLEMENTED */
			return									_previousPos;
		}
		public function getTargetPos						():Point {
			return									_targetPos;
		}
		public function getTopLeftPos						():Point {
			return									_content.getBounds(_parent).topLeft;
		}
		public function getActualTopLeftPos					():Point {
			return									_realContent.getBounds(_parent).topLeft;
		}
		public function hasContent							():Boolean {
			return									Boolean(_contentContent);
		}
	// SETTERS
		public function setActive							(a:Boolean):void { // If this is true, interaction is on, otherwise is off
			_content.visible								= a; // If content is invisible, interaction does not work
		}
		public function setIndex							(i:int):void { // Changes index in display list
			_parent.addChildAt							(_realContent, i);
			_parent.addChildAt							(_content, i+1);
			Debug.debug								(_debugPrefix, "Changed index to " + i + ". BE CAREFUL: I need 2 indexes, one also for the real draggable content.");
		}
		public function setAverageDistance					(d:int):void { // Sets the average number of zeno's steps based on a hypothetical distance, plus a buffer
			_maxMoveFrames							= getRequredSmoothSteps(d, _multiplier, _minimumStep) + BUFFER_ZENO_STEPS;
			if (_maxMoveFrames < MIN_ZENO_STEPS)			_maxMoveFrames = MIN_ZENO_STEPS;
		}
		public function setViewport							(r:Rectangle, mode:String="CROP-RESIZE", andMove:Boolean=true, withinLimits:Boolean=false, instant:Boolean=false):void { // Sets the viewport for draggin around
			_mainWindow								= r;
			_panLimits									= r.clone();
			_centerPoint								= new Point(r.width/2+r.x, r.height/2+r.y);
			if (andMove && isRendered())					fullscreen(mode, withinLimits, instant);
			if (_verbose) Debug.debug						(_debugPrefix, "Viewport set: " + r);
		}
	// POSITIONS
		public function previous							(withinLimits:Boolean=true, instant:Boolean=false):void { // Steps back to previous position
			if (_previousPosition) {
				setToPositionObject						(_previousPosition, withinLimits, instant);
			} else {
				Debug.error							(_debugPrefix, "_originalPosition not stored. I can't previous();");
			}
		}
		public function getActualPosition						():Object {
			return									{pos:_targetPos, zoom:_targetZoom, rotation:_targetRotation};
		}
		public function storeActualPosition					(posName:String):void { // Stores actual position with a name
			storePosition								(getActualPosition(), posName);
		}
		public function storePosition							(p:Object, posName:String):void { // Stores a named position checking integrity first
			if (checkPositionIntegrity(p)) {
				_positions[posName]						= p;
			} else {
				Debug.error							(_debugPrefix, "Position " + posName + " can't be stored since it's not well formed: " + Debug.object(p));
			}
		}
		public function setToPosition						(posName:String, withinLimits:Boolean=true, instant:Boolean=false):void {
			if (_positions[posName]) {
				setToPositionObject						(_positions[posName], withinLimits, instant);
			} else {
				Debug.error							(_debugPrefix, "Position " + posName + " not found. setToPosition() aborted.");
			}
		}
		public function setToPositionObject					(p:Object, withinLimits:Boolean=true, instant:Boolean=false):void {
			if (checkPositionIntegrity(p)) {
				setTargetPositionObject					(p, withinLimits, instant);
			} else {
				Debug.error							(_debugPrefix, _contentContent + " cannot setToPositionObject() since it's not well formed: " + Debug.object(p));
			}
		}
	// MOTIONS MANAGER
		public function setMinimumZoom						(z:Number):void {
			_minimumZoom								= z;
		}
		public function setMinimumZoomFromPos				():void {
			_minimumZoom								= _targetZoom;
			processSwipeActivation							();
		}
		public function setMaximumZoom						(z:Number):void {
			_maximumZoom								= z;
		}
		public function setMaximumZoomFromPos				():void {
			_maximumZoom								= _targetZoom;
		}
	// MOTION
		public function fullscreen							(mode:String="CROP-RESIZE", withinLimits:Boolean=true, instant:Boolean=false):void {
			setToRectangle								(UGlobal.stageRect, mode, withinLimits, instant);
			_isFullscreen								= true;
			_fullscreenZoom								= getZoom();
		}
		public function setToFullScreen						(mode:String="CROP-RESIZE", withinLimits:Boolean=true, instant:Boolean=false):void {
			fullscreen									(mode, withinLimits, instant);
		}
		public function fullWindow							(mode:String="CROP-RESIZE", withinLimits:Boolean=true, instant:Boolean=false):void {
			setToRectangle								(_mainWindow, mode, withinLimits, instant);
		}
		public function reset								(immediate:Boolean=false):void {
			resetPosition								(immediate);
		}
		public function alignLeft							(instant:Boolean):void {
			setTargetPosition								(_panLimits.right, NaN, NaN, NaN, true, instant);
		}
		public function alignRight							(instant:Boolean):void {
			setTargetPosition								(_panLimits.x, NaN, NaN, NaN, true, instant);
		}
		public function alignTop							(instant:Boolean):void {
			setTargetPosition								(NaN, _panLimits.bottom, NaN, NaN, true, instant);
		}
		public function alignBottom							(instant:Boolean):void {
			setTargetPosition								(NaN, _panLimits.y, NaN, NaN, true, instant);
		}
		public function rotateTo							(r:Number, withinLimits:Boolean=true, instant:Boolean=false):void {
			setTargetPosition								(_targetPos.x, _targetPos.y, _targetZoom, r, withinLimits, instant);
		}
		public function moveTo							(xx:Number, yy:Number, withinLimits:Boolean=true, instant:Boolean=false):void {
			setTargetPosition								(xx, yy, _targetZoom, _targetRotation, withinLimits, instant);
		}
		public function moveToPoint							(p:Point, withinLimits:Boolean=true, instant:Boolean=false):void {
			moveTo									(p.x, p.y, withinLimits, instant);
		}
		public function scaleTo							(ss:Number, withinLimits:Boolean=true, instant:Boolean=false):void {
			setTargetPosition								(_targetPos.x, _targetPos.y, ss, _targetRotation, withinLimits, instant);
		}
		public function moveToTop():void {
			_parent.addChild(_realContent);
			_parent.addChild(_content);
			if (_debugLayer) _parent.addChild(_debugLayer);
		}
		public function moveToDisplayListLevel(level:int):void { // Moves content to a certain level in display list
			
		}
		public function moveToBottom():void {
			if (_debugLayer) _parent.addChildAt(_debugLayer, 0);
			_parent.addChildAt(_content, 0);
			_parent.addChildAt(_realContent, 0);
		}
		public function setToMaximumZoom					(instant:Boolean=false):void {
			this.scaleTo								(_maximumZoom, true, instant);
		}
		public function setToRectangle						(r:Rectangle, mode:String="CROP-RESIZE", withinLimits:Boolean=false, instant:Boolean=false):void {
			storePreviousPosition							();
			if (_alwaysResetRotationOnRectangle)				_content.rotation = 0;
			_content.scaleX = _content.scaleY					= 1;
			UDisplay.resizeTo							(_content, r, mode, true);
			UDisplay.alignTo							(_content, r, null, null, true);
// 			var b										:Rectangle = _content.getBounds(_parent);
// 			_content.x									-= b.x;
// 			_content.y									-= b.y;
// 			updateTargetPos								();
			triggerHardMove								(instant, withinLimits);
			if (_alwaysResetRotationOnRectangle && isRendered())	rotateTo(0, withinLimits, instant);
		}
		public function zoomToRectangle						(r:Rectangle, mode:String="CROP-RESIZE", withinLimits:Boolean=false, instant:Boolean=false):void {
			// Gets a rectangle, and makes it occupy the entire viewport if possible. Since set to rectangle puts the image INSIDE the rectangle, this one has to desume a larger rectangle from the small one in order to apply correct zooming
			// _mainWindow - is the main occupation area rectangle
			// 1 - I find the percent to enlarge rectangle. This should always give percents on top of 100
			var hperc									:Number = UNumber.calculatePercent(_mainWindow.width, r.width); // Horizontal percent
			var vperc									:Number = UNumber.calculatePercent(_mainWindow.height, r.height); // Vertical percent
			var perc									:Number = hperc < vperc ? hperc : vperc; // I need to find the smallest percent to make sure it stays
// 			trace("FINESTRA",_mainWindow);
// 			trace("ZOOM A",r);
// 			trace("Precentuali (h v)",hperc,vperc);
			// 2 - I find the distances from border
			var top									:Number = r.y;
// 			var bottom									:Number = _mainWindow.height - (r.y + r.height);
			var left									:Number = r.x;
// 			var right									:Number = _mainWindow.width - (r.x + r.width);
			// I enlarge width and height in order to be the same
			var										largeRect:Rectangle = new Rectangle(0,0,0,0);
			largeRect.width								= UNumber.getPercent(_mainWindow.width, perc);
			largeRect.height								= UNumber.getPercent(_mainWindow.height, perc);
			largeRect.x									= -UNumber.getPercent(left, perc);
			largeRect.y									= -UNumber.getPercent(top, perc);
			setToRectangle								(largeRect, "CROP-RESIZE", true);
		}
	// SPECIAL
		public function fadeOutAndRelease					(time:Number=0.3):void {
			if (_releasing || time <=0)						return; // I am already animating to release content
			_mover.fade								(_contentContent, time, 0, onPropsAndReleaseComplete);
			_releasing									= true;
		}
		public function fadeIn								(time:Number=0.3, onComplete:Function=null, onCompletePar:*=null):void {
			if (_releasing || time <=0)						return; // I am already animating to release content
			_contentContent.alpha							= 0;
			_mover.fade									(_contentContent, time, 1, onComplete, onCompletePar);
			_releasing									= false;
		}
		public function fadeOutAndStore						(time:Number=0.3, callback:Function=null):void {
			if (_releasing || time <=0)						return; // I am already animating to release content
			_mover.fade								(_contentContent, time, 0, onPropsAndReleaseCompleteStore, callback);
			_releasing									= true;
		}
		private function onPropsAndReleaseComplete				(c:DisplayObject=null):void {
			_releasing									= false;
			release									();
		}
		private function onPropsAndReleaseCompleteStore			(callback:Function=null):void {
			_releasing									= false;
			if (Boolean(callback))						callback(_contentContent);
			UMem.storeInstance							(this);
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		private function setupContentCustom					(c:DisplayObject, hasPan:Boolean=true, hasZoom:Boolean=true, hasRot:Boolean=true,  startingPos:Object=null, initialRectangle:Rectangle=null, mode:String="NORM", align:String="NORMAL"):void {
			_hasPan									= hasPan;
			_hasZoom									= hasZoom;
			_hasRotation								= hasRot;
			_mode									= mode;
			_resize									= align;
			setupContent								(c, startingPos, initialRectangle);
		}
		private function setupContent						(c:DisplayObject, startingPos:Object=null, initialRectangle:Rectangle=null):void {
			// General content setup in any occasion.
			if (_contentContent)							release();
			c.scaleX = c.scaleY							= 1;
			c.x = c.y									= 1;
			if (_allowSmoothingForBitmap && c is Bitmap)		(c as Bitmap).smoothing = true;
			_contentContent								= c;
			_gesture									= new TransformGesture(_content);
			_gesture.addEventListener						(org.gestouch.events.GestureEvent.GESTURE_BEGAN, onGesturePanZoomSmoothStart, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
			_gesture.addEventListener						(org.gestouch.events.GestureEvent.GESTURE_CHANGED, onGesturePanZoomSmooth, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
			_gesture.addEventListener						(org.gestouch.events.GestureEvent.GESTURE_ENDED, onGestureEnded, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
			if (_hasSingleTap) {
				_singleTap								= new TapGesture(_content);
				_singleTap.addEventListener					(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSingleTap, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
				_singleTap.numTapsRequired				= 1;
			}
			if (_hasDoubleTap) {
				_doubleTap								= new TapGesture(_content);
				_doubleTap.addEventListener				(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onDoubleTap, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
				_doubleTap.maxTapDelay					= 500;
				_doubleTap.numTapsRequired				= 2;
				if (_hasSingleTap) {
					_singleTap.requireGestureToFail			(_doubleTap);
				}
			}
			// Swiping
			_hasSwipe									= _hasSwipeH || _hasSwipeV;
			if (_hasSwipe) {
				_swipeGesture							= new SwipeGesture(_content);
				_swipeGesture.addEventListener				(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSwipe);
			}
			if (_hasMouseEvents)							Buttonizer.setupButton(_content, this, "Content", "onClick,onPress,onRelease,onReleaseOutside");
			render									(startingPos, initialRectangle);
		}
		private function render							(startingPos:Object=null, initialRectangle:Rectangle=null):void {
			// Rendering of content after setup.
			_contentContent.scaleX = _contentContent.scaleY 		= 1;
			_contentContent.rotation = _contentContent.x = _contentContent.y = 0;
			_content.addChild							(_contentContent);
			// When rendered, content is always setup at fullscreen, and that will become relZoom = 1. 
			// Align and center to fullscreen.
			UDisplay.resizeSpriteTo						(_contentContent, _mainWindow, _resize, true);
			UDisplay.alignSpriteTo						(_contentContent, _mainWindow, null, null, true);
			var contentBounds							:Rectangle = _contentContent.getBounds(_content);
			_content.x = _realContent.x						= _centerPoint.x;
			_content.y = _realContent.y						= _centerPoint.y;
			// Content is centered, considering bounds, because clip may be already centered by itself
			_contentContent.x							-= _centerPoint.x;
			_contentContent.y							-= _centerPoint.y;
			_realContent.addChild							(_contentContent);
			// 1.1 - using freshly crated bounds insted of absolute positioning with x+width.
			UDisplay.drawRectangle						(_content, _contentContent.getBounds(_content), 0xff0000);
// 			_relZoom 									= 1;
			_contentZoom 								= _contentContent.scaleX;
			_contentZoomMultiplier						=  _contentZoom / 1;
			_minimumZoom								= 0;
			_fullscreenZoom								= 1;
			// Bitmap adjustment
			if (_contentContent is Bitmap && _contentZoom == 1 && USystem.isDevice()) {
				_minimumZoom							= 1.001;
			}
			_maximumZoom								= _maximumZoomMultiplier*100;
			_actualRotation								= _targetRotation = 0;
			_content.alpha								= DEBUG_TARGET ? 0.5 : 0;
			// Prepare properties for the initial position or it will be empty
			_targetPos									= new Point(_content.x, _content.y);
			_targetZoom								= 1;
			_originalPosition								= getActualPosition();
			// Setup eventually starting position
			if (startingPos) { // Starts from here the transformation
				// 1.1 - added auomatic recognition of Point and Rectangle (where properties are not enumerable)
				if (startingPos is Rectangle || startingPos is Point) startingPos = {y:startingPos.x, y:startingPos.y};
				// Rotation is not property of Point or Rectangle
				else if (startingPos.rotation) 				_actualRotation = startingPos.rotation; // Rotation is stored in actual rotation not in item rotation
				for (_s in startingPos)						_realContent[_s] = startingPos[_s];
			}
			// Complete all flow
			complete									();
			// Animate or setup - animate to full position or to initial rectangle
// 			return;
			var instant									:Boolean = !startingPos; // Animation is done ONLY if there is a starting position
			if (initialRectangle)							setToRectangle(initialRectangle, _resize, false, instant);
			else										resetPosition(instant);// apply zoom fix for devices
			if (_fixZoomForBitmapsOnDevice && USystem.isDevice() && _contentContent is Bitmap) {
				Debug.debug							(_debugPrefix, "Fixing devicce bitmap rendering on GPU, setting zoom at " + _fixZoomForBitmapsOnDevice);
				scaleTo								(_fixZoomForBitmapsOnDevice, false, true);
			}
			
			// TRy MASKING
			if (_maskViewport) {
				UDisplay.resizeToRect						(_maskSprite, _mainWindow);
				_contentContent.mask 					= _maskSprite;
			}
			
			
			
			
			Debug.debug								(_debugPrefix, "Content rendered " + _contentContent);
			broadcastEvent								(EVT_READY, this);
			
			
			/* DEBUG */
// 			DisplayObjectContainer(_contentContent).mouseEnabled = true;
// 			DisplayObjectContainer(_contentContent).mouseChildren = true;
// 			_content.mouseEnabled = false;
			
			
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function checkPositionIntegrity					(p:Object):Boolean { // Checks the integrity of a saved positions object
			return									(p.pos is Point && p.zoom != null && p.rotation != null);
		}
		private function storePreviousPosition					():void {
			_previousPosition								= getActualPosition();
		}
// MOVE ///////////////////////////////////////////////////////////////////////////////////////
		private function setTargetPositionObject				(p:Object, withinLimits:Boolean=true, instant:Boolean=false):void {
			setTargetPosition								(p.pos.x, p.pos.y, p.zoom, p.rotation, withinLimits, instant);
		}
		private function setTargetPosition						(xx:Number=NaN, yy:Number=NaN, ss:Number=NaN, rr:Number=NaN, withinLimits:Boolean=true, immediate:Boolean=false):void {
			storePreviousPosition							();
			_targetPos.x								= isNaN(xx) ? _targetPos.x : xx;
			_targetPos.y								= isNaN(yy) ? _targetPos.y : yy;
			_targetZoom								= isNaN(ss) ? _targetZoom : ss;
			_targetRotation								= isNaN(rr) ? _targetRotation : rr;
			updateTargetPos								();
			triggerHardMove								(immediate, withinLimits);
		}
		private function resetPosition						(instant:Boolean=false):void {
			setToPositionObject							(_originalPosition, false, instant);
		}
// 		private function setToFullscreen						(coverAll:Boolean=true, immediate:Boolean=false):void {
// 			// Fills the entire window area, if coverAll is on uses CROP-RESIZE otherwise it uses NORMAL
// 			storePreviousPosition							();
// 			const mode								:String = coverAll ? "CROP-RESIZE" : "NORMAL";
// 			UDisplay.resizeSpriteTo						(_content, _mainWindow, mode);
// 			UDisplay.alignSpriteTo						(_content, _mainWindow);
// 			triggerHardMove								(immediate);
// 		}
	// STATIC MOVE UTY
		private function alignRotation						():void { // Rotates _content to the closest way to not rotated and adjust _targetRotation
			var rotRest								:Number = _targetRotation%360;
			_targetRotation								= rotRest < 180 ? _targetRotation - rotRest : _targetRotation + (360-rotRest);
			_content.rotation								= _targetRotation;
		}
		private function triggerHardMove						(immediate:Boolean=false, withinLimits:Boolean=true):void {
			// To be called after each hard move by hand
			shutDownSwipeGesture						(); // Shut down swipe if active
			resetMotionEventName							(); // I reset motion progress event to the one without momentum
			adjustRelZoom								();
			updateBounds								();
			updatePosition								(immediate, withinLimits);
		}
		private function adjustRelZoom						():void { // Adjusts relative zoom according to  _content zooming
			_contentZoom								= _targetZoom * _contentZoomMultiplier;
		}
// 		private function checkTargetZoomDeviceBitmap			():void { // This tries to adjust lags for bitmaps
// 			if (_targetZoom == 1 && _adjustForDeviceBitmap && _contentContent is Bitmap) {
// 				_targetZoom							= 0.001;
// 			}
// 		}
// LISTENERS /////////////////////////////////////////////////////////////////////////////////////
		private function onGesturePanZoomSmoothStart			(e:org.gestouch.events.GestureEvent):void {
			shutDownSwipeGesture						(); // Shut down swipe if active
			stopSmoothMotion							();
			storePreviousPosition							();
			broadcastEvent								(EVT_START, this);
			resetMotionEventName							();
			onGesturePanZoomSmooth						(e);
		}
		private function resetMotionEventName():void {
			// Resets motion event to normal motion in progress (instead of memontum)
			_motionContinueEvent = EVT_CHANGING; // Reset motion progress event to the one without momtnum (it only changes if momentum is active and happening)
		}
		private function onGesturePanZoomSmooth(e:org.gestouch.events.GestureEvent):void { 
// 			if (_interactionOff)							return;
			_gesture = e.target as TransformGesture;
			if (_hasPan) pan();
			if (_hasZoom) zoom();
			if (_hasRotation) rotate();
			updatePosition();
			broadcastEvent(EVT_CONTINUE, this);
			onAllInteraction();
		}
			private function pan							(momentum:Boolean = false):void {
				//trace("panning");
				_offsetX								= _gesture.offsetX * _contentZoomingFactor;
				_offsetY								= _gesture.offsetY * _contentZoomingFactor;
				if (Math.abs(_offsetX) > MINIMUM_STEPS.pan || Math.abs(_offsetY) > MINIMUM_STEPS.pan) {
					_matrix							= _content.transform.matrix;
					_matrix.translate						(_offsetX, _offsetY);
					_content.transform.matrix				= _matrix;
				}
			}
			private function zoom							():void {
				if (_gesture.scale != 1 && Math.abs(_gesture.scale) > MINIMUM_STEPS.zoom) {
					_newMult							= _gesture.scale;
					_newZoom							= _content.scaleX * _gesture.scale;
					if (_newZoom > _maximumZoom)		_newMult = _maximumZoom / _content.scaleX;
					else if (_newZoom < _minimumZoom)		_newMult = _minimumZoom / _content.scaleX;
					refreshMatrix						();
					_matrix.translate						(-_transformPoint.x, -_transformPoint.y);
					_matrix.scale						(_newMult, _newMult);
					_matrix.translate						(_transformPoint.x, _transformPoint.y);
					_content.transform.matrix				= _matrix;
					adjustRelZoom						();
// 					_relZoom 							= _content.scaleX / _minimumZoom;
				}
			}
			private function rotate						():void {
				if (_gesture.rotation != 0 && Math.abs(_gesture.rotation) > MINIMUM_STEPS.rot) {
					refreshMatrix						();
					_matrix.translate						(-_transformPoint.x, -_transformPoint.y);
					_matrix.rotate						(_gesture.rotation);
					_matrix.translate						(_transformPoint.x, _transformPoint.y);
					_content.transform.matrix				= _matrix;
					_targetRotation						+= adjustGestureDegrees(_gesture.rotation*RADIANS_MULT);
				}
			}
				private function adjustGestureDegrees			(r:Number):Number {
					// Radians received from gesture can be messed up. Here I make so that -0.5 doesn't become +359.5. And the opposite.
					if (r > 300) {
						return						-(360-r);
					}
					else if (r < -300) {
						return						360+r;
					}
					// Rotation seems ok
					return							r;
				}
		private function onGestureEnded						(e:org.gestouch.events.GestureEvent):void {
			_gesture									= e.target as TransformGesture;
			if (_hasRotation && _forceReturnRotation && _targetRotation != 0) rotateTo(0);			
			if (_hasPan && _hasMomentum) 					panMomentum();
			updatePosition								();
			processSwipeActivation							();
			broadcastEvent								(EVT_COMPLETE, this);
			onAllInteraction();
		}
			private function panMomentum					():void {
				// This one works the LAST offestX and offsetY direction and computes a momentum force pan
				// Pan is calculated on real ipoiteusa
				const distance							:Number = Point.distance(POINT_ZERO, new Point(_offsetX, _offsetY));
				const force							:Number = _multiplyForceByZoom ? distance * getZoom() : distance;
				if (force > _minimumForce) { // Momentum is active, motion broadcast changes
					_motionContinueEvent					= EVT_MOMENTUM; // Update motion progress event to momentum
					const mult							:Number = _forceMultiplier;
					Debug.debug						(_debugPrefix, "Momentum force detected, multiplying by " + mult);
					_offsetX							*= mult;
					_offsetY							*= mult;
					_matrix							= _content.transform.matrix;
					_matrix.translate						(_offsetX, _offsetY);
					_content.transform.matrix				= _matrix;
				}
			}
	// SWIPE
		private function processSwipeActivation					():void { // SWIPE is only active when image cannot be panned, otherwise it interferes with panning
			if (_swipeGesture) {
				Debug.debug								(_debugPrefix, "Checking swipe activation: " + getZoom()  + " : " +  _minimumZoom);
				if (String(getZoom()).substr(0, ZOOM_DIGITS_CHECKER) == String(_minimumZoom).substr(0, ZOOM_DIGITS_CHECKER)) {
					Debug.debug							(_debugPrefix, "Aactivating swipe gestures...");
					_swipeGesture.enabled 					= true;
				}
				else 										shutDownSwipeGesture();
			}
		}
		private function shutDownSwipeGesture				():void {
			if (_swipeGesture && _swipeGesture.enabled) { // Swipe gesture is activated only at minimum zoom, therefore it is removed only if it exists
				Debug.debug							(_debugPrefix, "Deactivating swipe gesture...");
				_swipeGesture.enabled 					= false;
			}
		}
		private function onSwipe							(e:org.gestouch.events.GestureEvent):void {
			var evt									:String;
			if (_hasSwipeV && _swipeGesture.offsetX == 0) { // Horizontal swipe
				if (_swipeGesture.offsetY > 0) { // Swipe down
					evt								= EVT_SWIPE_UP;
				} else { // Swipe up
					evt								= EVT_SWIPE_DOWN;
				}
			}
			else if (_hasSwipeH && _swipeGesture.offsetY == 0) { // Vertical swipe
				if (_swipeGesture.offsetX > 0) { // Swipe right
					evt								= EVT_SWIPE_LEFT;
				} else { // Swipe left
					evt								= EVT_SWIPE_RIGHT;
				}
			}
			if (evt) broadcastEvent(evt, this);
			onAllInteraction();
		}
	// TAPS
		private function onDoubleTap						(e:org.gestouch.events.GestureEvent):void {
// 			trace("DOUBLE TAAAAAAAAAAAAPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP");
			if (!_isFullscreen && _doubleTapFullSizeWhenLargerThan > 0 && getZoom() > _doubleTapFullSizeWhenLargerThan) {
// 				if (_doubleTapBackFromFullScreen)			storePosition("PippoFlash:internal:BeforeFullscreen");
				setToFullScreen							();
// 				trace("METTE F FULL SCREEN");
			}
			else if (_isFullscreen && _doubleTapBackFromFullScreen) {
				previous								();
// 				trace("TORNO DA FULLSCREEN");
// 				setToPosition							("PippoFlash:internal:BeforeFullscreen");
			}
			else if (_doubleTapReset) {
// 				trace("RESETTO");
				reset									();
			}
			broadcastEvent								(EVT_DOUBLE_TAP, this);
			onAllInteraction();
		}
		private function onSingleTap						(e:org.gestouch.events.GestureEvent):void {
			if (_verbose)								Debug.debug(_debugPrefix, "Single tap event received.");
			// I can dispatch a CLICK event to _contentContent. 
			// If events are listened INSIDE _contentContent , then _contentContent  must be set as tunneling using Buttonizer with the event: "tunnel,onClick"
			if (_dispatchClickOnTap) {
				Debug.debug							(_debugPrefix, "Tunneling onClick event to content.");
				// Find the reliable stage poit
				const stagePoint							:Point = e.target.location;
				/* Uncomment this to debug stage point
				var s:Sprite = UDisplay.getSquareSprite(2,2,0xff0000);
				UGlobal.stage.addChild(s);
				s.x = stagePoint.x;
				s.y = stagePoint.y;
				*/
				// Find local coordinates acconrding to real content
				var p									:Point = _contentContent.globalToLocal(stagePoint);
				// Debug coordinates in content
				/* Uncomment this to debug coordinates within _contentContent
				var ss:Sprite = UDisplay.getSquareSprite(4,4,0x00ff00);
				(_contentContent as DisplayObjectContainer).addChild(ss);
				ss.x = p.x;
				ss.y = p.y;
				*/
				// Create mouse event, and set local coordinates (global ones will be computed once the event is dispatched)
				var ee:MouseEvent						= new MouseEvent("click");
				ee.localX 								= p.x;
				ee.localY 								= p.y;
				// Dispatch event from _contentContent
				MovieClip(_contentContent).dispatchEvent		(ee);
			}
			// Broadcast the normal event
			broadcastEvent								(EVT_SINGLE_TAP, this);
			onAllInteraction();
		}
		public function onClickContent						(c:Sprite):void {
			broadcastEvent								(EVT_CLICK, this);
			if (_jumpOnTopWhenTouched)					moveToTop();
			onAllInteraction();
		}
		public function onPressContent						(c:Sprite):void {
			broadcastEvent								(EVT_TOUCH, this);
			if (_jumpOnTopWhenTouched)					moveToTop();
			onAllInteraction();
		}
		public function onReleaseContent						(c:Sprite):void {
			broadcastEvent								(EVT_UNTOUCH, this);
			onAllInteraction();
		}
		public function onReleaseOutsideContent				(c:Sprite):void {
			onReleaseContent							(c);
			onAllInteraction();
		}
		private function onAllInteraction():void { // This has to be calle don eah interaction in order to reset screen saver count
			UGlobal.resetScreenSaverCount();
		}
// SMOOTH MOTION /////////////////////////////////////////////////////////////////////////////////////////////////////
		private function updatePosition						(immediate:Boolean=false, withinLimits:Boolean=true):void { // To be called after everytime we reposition original square (and _targetRotation);
			_isFullscreen								= getZoom() >= _fullscreenZoom;
// 			storePreviousPosition							();
			prepareTargetPos							();
			adjustPanLimits								(withinLimits);
			if (_useSmooth && !immediate)					startSmoothMotion();
			else	{
				completeSmoothMotion						();
			}
		}
		private function prepareTargetPos					():void { // Content is setup to target position, this records content properties once they are applied
			_targetPos									= new Point(_content.x, _content.y);
			_targetZoom								= _content.scaleX;
			/* _targetRotation IS UPDATED MANUALLY in gesture listener, SINCE _content.rotation is NOT RELIABLE */
		}			
		private function setToTargetPos						():void { // Sets target and content immediately to target position
			_content.scaleX = _content.scaleY					= _targetZoom;
			_content.x									= _targetPos.x;
			_content.y									= _targetPos.y;
			_content.rotation								= _actualRotation = _targetRotation;
			applyPositioning								();	
			updateBounds								();
		}
		private function updateTargetPos						():void { // Updates target clip (_content) to reflect new target positions
			_content.scaleX = _content.scaleY					= _targetZoom;
			_content.x									= _targetPos.x;
			_content.y									= _targetPos.y;
			_content.rotation								= _targetRotation;
			updateBounds								();
		}
		private function applyPositioning						():void { // Sets content immediately to target position
			_realContent.x								= _content.x;
			_realContent.y								= _content.y;
			_realContent.scaleY = _realContent.scaleX			= _content.scaleX;
			_realContent.rotation							= _actualRotation = _targetRotation;
			refreshActualPos								();
// 			_previousPos.x								= _content.x;
// 			_previousPos.y								= _content.y;
		}
		private function startSmoothMotion					():void { // Starts a smooth motion enterframe and count, or updates only count if enterframe is already active
			// setup target zoom
			_movedFrames								= 0;
			if (_moving)								return;
			_moving									= true;
			UExec.addEnterFrameListener					(smoothMoveFollow);
		}
		private function smoothMoveFollow					(e:Event=null):void { // To be called onEnterFrame, it smooth adjusts position closer to target
			if (++_movedFrames == _maxMoveFrames) {
				completeSmoothMotion						();
				return;
			}
			_realContent.scaleX = _realContent.scaleY			= _realContent.scaleX + ((_content.scaleX - _realContent.scaleX)*_multiplier);
			_realContent.x								+= (_content.x - _realContent.x) * _multiplier;
			_realContent.y								+= (_content.y - _realContent.y) * _multiplier;
			_actualRotation								+= (_targetRotation - _actualRotation) * _multiplier;
			_realContent.rotation							= _actualRotation;
			refreshActualPos								();
			broadcastEvent								(_motionContinueEvent, this);
		}
		private function stopSmoothMotion					():void { // This one just stop smooth motion and blocks image
			if (_moving) {
				if (_verbose) Debug.debug								(_debugPrefix, "Smooth motion interrupted.");
				UExec.removeEnterFrameListener					(smoothMoveFollow);
				_moving									= false;
				_content.x									= _realContent.x;
				_content.y									= _realContent.y;
				_content.scaleY = _content.scaleX					= _realContent.scaleX;
				_content.rotation								= _targetRotation = _actualRotation;
				updateBounds								();
			}
		}
		private function completeSmoothMotion					():void { // Terminates motion and moves everything in sync with target
			if (_verbose) Debug.debug								(_debugPrefix, "Smooth motion completed.");
			setToTargetPos								();
			UExec.removeEnterFrameListener					(smoothMoveFollow);
			_moving									= false;
			processSwipeActivation							();
			broadcastEvent								(EVT_CHANGED, this);
		}
// MOTION UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function getRequredSmoothSteps				(value:Number, mult:Number, minValue:Number=0.000009):int {
			// Calculates, with generosity, an average, abundant number of frames required to complete zeno's paradox motion
			if (mult >= 1 || mult < 0 || minValue >= value || value < 0) {
				Debug.error							(_debugPrefix, "getRequredSmoothSteps() error",value,mult,minValue);
				return								0;
			}				
			var result									:Number = value;
			var steps									= 0;
			while (result > minValue) {
				result 								-= result * mult;
				steps									++;
			}
			if (_verbose) Debug.debug								(_debugPrefix, "Required steps to smooth " + value + " in zeno's paradox, with multiplier of " + mult + " and minimum of " + minValue + " is: " + steps);
			return									steps;
		}
		private function refreshMatrix						():void { 
			// Refreshes matrix, before any motion applied to matrix
			_matrix									= _content.transform.matrix;
			_transformPoint 								= _matrix.transformPoint(_content.globalToLocal(_gesture.location));
		}
		private function refreshActualPos						():void {
			_actualPos.x								= _realContent.x;
			_actualPos.y								= _realContent.y;
		}
// LIMITS ///////////////////////////////////////////////////////////////////////////////////////
		private function adjustPanLimits						(withinLimits:Boolean=true):void {
			this["adjustPanLimits_"+_mode]					(withinLimits);
		}
		private function adjustPanLimits_NORM					(withinLimits:Boolean=true):void {
			adjustZoom								(withinLimits);
			// Checks if image moved outside of pan limits
			updateLimits_NORM							();
			setWithinLimits								(withinLimits);
		}
		private function adjustPanLimits_BOUNDS				(withinLimits:Boolean=true):void { 
			adjustZoom								(withinLimits);
			// Checks if image moved outside of pan limits
			updateLimits_BOUNDS							();
			setWithinLimits								(withinLimits);
		}
		private function adjustZoom						(withinLimits:Boolean=true):void {
			if (withinLimits) {
				if (_targetZoom < _minimumZoom) {
					_targetZoom							= _minimumZoom;
					updateTargetPos							();
				}
				else if (_targetZoom > _maximumZoom) {
					_targetZoom							= _maximumZoom;
					updateTargetPos							();
				}
			}
		}
		private function setWithinLimits						(withinLimits:Boolean=true):void {
// 			trace(_panLimits, _content.y);
			if (withinLimits && !_panLimits.contains(_targetPos.x, _targetPos.y)) {
				var offset								:int = 0;
				if (_targetPos.x > _panLimits.right) {
					_targetPos.x = _panLimits.right-offset;
				}
				else if (_targetPos.x < _panLimits.left)	{
					_targetPos.x = _panLimits.left+offset;
				}
				if (_targetPos.y > _panLimits.bottom) {
					_targetPos.y = _panLimits.bottom-offset;
				}
				else if (_targetPos.y < _panLimits.top) {
					_targetPos.y = _panLimits.top+offset;
				}
				updateTargetPos							();
			}
		}
		private function updateLimits						():void { 
			// Updates left, top, right and bottom drag limits according to zoom levels
			this["updateLimits_"+_mode]					();
		}
		private function updateLimits_NORM					():void { 
			/* FIX THIS */
			// Updates left, top, right and bottom drag limits according to zoom levels
			_panLimits									= _mainWindow.clone();
			if (_targetZoom > 1) {
				_panLimits.inflate						((_mainWindow.width*(_targetZoom-1))/2, (_mainWindow.height*(_targetZoom-1))/2);
			}
		}
		private function updateLimits_BOUNDS					():void { // All image will be always visible
			updateBounds								();
			_panLimits									= _mainWindow.clone();
			if (_bounds.height > _mainWindow.height) {
				_panLimits.y							= (-(_bounds.height - _mainWindow.height)) + _bounds.height/2;
				_panLimits.height						= (_bounds.height - _mainWindow.height);
			}
			else {
				_panLimits.y							= _bounds.height/2;
				_panLimits.height						= _mainWindow.height-_bounds.height;
			}
			if (_bounds.width > _mainWindow.width) {
				_panLimits.x							= (-(_bounds.width - _mainWindow.width)) + _bounds.width/2;
				_panLimits.width							= (_bounds.width - _mainWindow.width);
			}
			else {
				_panLimits.x							= _bounds.width/2;
				_panLimits.width							= _mainWindow.width-_bounds.width;
			}
			// ADDED IN VER 1.5
			var addOffset								:Boolean = true; // Set this to true to add window offsets to pan limits
			if (addOffset) {
				_panLimits.y							+= _mainWindow.y;
				_panLimits.x							+= _mainWindow.x;
			}
			// ////////////////////// - end of add
			// Add and remove offset if present
			if (_boundsOutOfScreenOffset != 0) {
				_panLimits.y							-= _boundsOutOfScreenOffset;
				_panLimits.x							-= _boundsOutOfScreenOffset;
				_panLimits.width							+= _boundsOutOfScreenOffset*2;
				_panLimits.height						+= _boundsOutOfScreenOffset*2;
			}
		}
		private function updateBounds						():void { // Updates bounds of target clip
			_bounds									= _content.getBounds(_parent);
			if (DEBUG_BOUNDS) {
				_debugLayer.x							= _bounds.x;
				_debugLayer.y							= _bounds.y;
				_debugLayer.width						= _bounds.width;
				_debugLayer.height						= _bounds.height;
			}
		}
// SCROLL FUNCTIONS ////////////////////////////////////////////////////////////////////////////////
	} // CLOSE CLASS ///////////////////////////////////////////////////////////////////////////////
}