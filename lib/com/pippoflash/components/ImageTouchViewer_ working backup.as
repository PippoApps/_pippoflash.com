/* ImageTouchViewer - Allows image viewing using Gestouch library. 

_content creates a BG transparent, then ALL gestouch listeners will be on content, since otherwise it creates problems.


*/

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
// 	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.Buttonizer;
// 	import											com.pippoflash.motion.PFMover;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
// 	import flash.ui.Multitouch;
// 	import flash.ui.MultitouchInputMode;
// 	import com.pippoflash.net.PreLoader;
	import org.gestouch.gestures.*;
	import org.gestouch.events.*;
	import org.gestouch.core.*;
	import org.gestouch.extensions.native.NativeDisplayListAdapter;
// 	import org.gestouch.gestures.SwipeGesture;
// 	import org.gestouch.gestures.SwipeGestureDirection;
	
	import com.pippoflash.utils.*;
	import com.pippoflash.framework.PippoFlashEventsMan;

	
	public class ImageTouchViewer extends _cBaseMasked {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="1.1 - Resize", type=String, defaultValue="NORMAL", enumeration="NONE,NORMAL,STRETCH,CROP,CROP-RESIZE")]
		public var _resize								:String = "NORMAL";
		[Inspectable 									(name="1.2 - Smooth Motion", type=Boolean, defaultValue=true)]
		public var _useSmooth								:Boolean = true;
		[Inspectable 									(name="1.3 - Visibility margins (0 is external side, 10 is 10 pixels white space border)", type=Number, defaultValue=0)]
// 		public var _boundsMargin							:int = 0; // This cannot be larger than half square
// 		private var _averageZenoDistance						:int = 2000; // Uses this to calculate an average number of zeno's steps - better more zeno's steps than less
		public var _hasZoom								:Boolean = true;
		public var _hasPan								:Boolean = true;
		public var _hasRotation							:Boolean = true;
// 		public var _hasSwipe								:Boolean = false;
		public var _hasMomentum							:Boolean = true; // If panning need to register also momentum
		public var _limitPan								:Boolean = true;
		public var _doubleTapReset							:Boolean = true;
		public var _multiplier								:Number = 0.12; // Zeno's paradox multiplier
		public var _minimumStep							:Number = 0.00009; // Below this step, everythig is arrived
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		private static const POINT_ZERO						:Point = new Point(0,0);
		private static const RADIANS_MULT					:Number = 180/Math.PI;
		private static const MINIMUM_STEPS					:Object = {zoom:0.001, pan:0.5, rot:0.003}; // Minimum values to activate a rotation
		private static const MINIMUM_FORCE					:Number = 50; // This sets the minimum force required for momentum (force is distance)
		private static const FORCE_MULTIPLIER					:Number = 8; // Multiplies distance to give momentum
		private static const MAX_ZOOM_MULT					:int = 3; // Maximum 10 times bigger than the original display
		private static const MIN_ZENO_STEPS					:int = 50; // Smooth animation will be at least this value
		private static const BUFFER_ZENO_STEPS				:int = 10; // These will be added to zeno's optimal motion
		private static const EVT_START						:String = "onViewerGestureStart"; // Broadcasted when motion is completed
		private static const EVT_COMPLETE					:String = "onViewerGestureEnd"; // Broadcasted when motion is completed
		private static const EVT_CHANGING					:String = "onViewerChanging"; // Broadcasted while changing onViewerChanging(content:Sprite);
		private static const EVT_CHANGED					:String = "onViewerChanged"; // Broadcasted when motion is completed
		private static const DEBUG_TARGET					:Boolean = false; // Shows target clip
		private static const DEBUG_BOUNDS					:Boolean = false; // Shows an overlay on image bounds
		private static var _init								:Boolean;
		// USER VARIABLES
		// SYSTEM
		private var _minimumPosition						:Rectangle;
		private var _minimumZoom							:Number;
		private var _maximumZoom							:Number;
		private var _relZoom								:Number; // Zoom starting from 1 when image is initially resized
		private var _newZoom								:Number; // this is just a utylity used to store proposed zoom
		private var _newMult								:Number; // Another utility to calculate zoom
		private var _initialZoom							:Number; // Real iumage zoom when initially positioned
		private var _initialPos								:Point;
		private var _force								:Number; // Force of pan
		private var _direction								:Number; // Direction of pan
		private var _offsetX								:Number; // Stores gesture force
		private var _offsetY								:Number; // Stores gesture force
// 		private var _listenerFunc							:Function; // Populated according to what kind of actions are allowed
		private var _matrix								:Matrix; // Transformation matrix
		private var _transformPoint							:Point;
		private var _bounds								:Rectangle; // Bouds of content
		private var _bg									:Sprite; // Transparent BG to be below in content
		private var _mainWindow							:Rectangle; // Using it as a base
		private var _centerPoint							:Point;
		private var _panLimits								:Rectangle; // Rectangle with pan limits
		private var _mode								:String; // Mode used for viewing images - NORM, VIEW
		// DATA
		// MOTION - SMOOTH MOTION
		private var _originalPos							:Point; // When motion is registered
		private var _originalZoom							:Number; // When motion is registered
		private var _originalRotation							:Number; // When motion is registered
		private var _targetPos								:Point; // Target X and Y position
		private var _targetZoom							:Number;
		private var _targetRotation							:Number;
		private var _actualRotation							:Number; // Stores number of rotation, since the .rotation property is net reliable jumping over 180
		private var _highestDifference						:Number; // Stores the bigger motion difference to calculate zeno's paradox required steps
		private var _moving								:Boolean; // Moving moving moving
		private var _maxMoveFrames						:int; // A Number of frames computed to stop motion eventually
		private var _movedFrames							:int;
		// REFERENCES
		private var _realContent							:Sprite; // This is the smoothed and moved one
		private var _content								:Sprite;
		private var _contentContent							:DisplayObject;
		private var _gesture								:TransformGesture;
		private var _doubleTap							:TapGesture;
		private var _debugLayer							:Sprite;
// 		private var _swipe								:SwipeGesture;
		private var _parent								:DisplayObjectContainer; // The parent containing _content and _realContent clips
 		// MARKERS
		// INTERFACE MODE MARKERS
		// SMOOTH SCROLL
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		private static function initGestures					():void {
			Gestouch.addDisplayListAdapter					(flash.display.Bitmap, new NativeDisplayListAdapter());
			Gestouch.addDisplayListAdapter					(flash.display.Sprite, new NativeDisplayListAdapter());
			Gestouch.addDisplayListAdapter					(flash.display.MovieClip, new NativeDisplayListAdapter());
			Gestouch.addDisplayListAdapter					(flash.display.Stage, new NativeDisplayListAdapter());
			_init										= false;
		}
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function ImageTouchViewer					(par:Object=null) {
			super									("ImageTouchViewer", par);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			_parent									= this;
			_content									= new Sprite();
			_realContent								= new Sprite();	
			_parent.addChild								(_realContent);
			_parent.addChild								(_content);
// 			_bg										= UDisplay.getSquareSprite(_w, _h, 0xff0000);
// 			_bg.alpha									= 0;
// 			_content.addChild							(_bg);
// 			_listenerFunc								= onGesturePanZoomSmooth;
			// Prepare Zeno's paradox number of steps
			_maxMoveFrames							= getRequredSmoothSteps(_w > _h ? _w : _h, _multiplier, _minimumStep) + BUFFER_ZENO_STEPS;
			if (_maxMoveFrames < MIN_ZENO_STEPS)			_maxMoveFrames = MIN_ZENO_STEPS;
			_mainWindow								= new Rectangle(0, 0, _w, _h);
			_panLimits									= _mainWindow.clone();
			_centerPoint								= new Point(_w/2,_h/2);
			if (DEBUG_BOUNDS) {
				_debugLayer							= new Sprite();
				UDisplay.drawRectangle					(_debugLayer, new Rectangle(-0,0,100,100), 0x0000ff);
				_debugLayer.alpha						= 0.5;
				_parent.addChild							(_debugLayer);
				Buttonizer.setClickThrough					(_debugLayer);
			}
			if (_init)									initGestures();
		}
		
		public override function release						():void {
			// Be careful. Release does NOT dispose content.
			resetPosition								();
			_matrix									= null;
			UDisplay.removeClip							(_contentContent);
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
				_doubleTap.removeEventListener				(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onDoubleTab);
				_doubleTap.dispose						();
				_doubleTap								= null;
			}
// 			if (_swipe) {
// 				_swipe.removeEventListener					(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSwipe);
// 				_swipe.dispose							();
// 				_swipe								= null;
// 			}
			// This is called to undo a render operation, and make the component ready again to render content
			super.release								();		}// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setContent							(c:DisplayObject):void { // Sets content for free motion
			// This sets image completely visible, and that is minimum zoom
			// It allows all gestures, and lets image almost disappear from screen
			_mode									= "NORM";
			_resize									= "NORMAL";
			_hasZoom									= true;
			_hasPan									= true;
			_hasRotation								= true;
			_limitPan									= true;
			setupContent								(c);
		}
		public function setContentViewImage					(c:DisplayObject):void { 
			// Sets content as image viewer. Only zoom and pan, never go out of screen.
			// It starts with the image completely visible, and that's the minimum zoom.
			_mode									= "VIEW";
			_resize									= "NORMAL";
			_hasZoom									= true;
			_hasPan									= true;
			_hasRotation								= false;
			_limitPan									= true;
			setupContent								(c);
		}
		public function setContentViewImageFull				(c:DisplayObject):void { 
			// Sets content as image viewer. Only zoom and pan, never go out of screen.
			// It never shows an empty pixel. Image minimum zoom is filling all space.
			_mode									= "VIEW";
			_resize									= "CROP-RESIZE";
			_hasZoom									= true;
			_hasPan									= true;
			_hasRotation								= false;
			_limitPan									= true;
			setupContent								(c);
		}
		public function setContentCustom						(c:DisplayObject, hasPan:Boolean=true, hasZoom:Boolean=true, hasRot:Boolean=true, startPosition:Rectangle=null, mode:String="NORM", align:String="NORMAL"):void {
			// Sets a content and positions image in it's original environment, zoom, directly
			setupContentCustom							(c, hasPan, hasZoom, hasRot, startPosition, mode, align);
		}
		public function getZoom							():Number { // The zoom starting from 1 when image is initially positioned
			return									_relZoom;
		}
		public function getRealZoom						():Number { // The real scaling factor of image
			return									_content.scaleX;
		}
		public function reset								():void {
			// This resets image at his original position
			if (isRendered()) {
				resetPosition							();
			}
			else {
				Debug.error							(_debugPrefix, "Cannot call reset(). ImageViewer is not rendered.");
			}
		}
// 		public function slideTo								(nx:Number, ny:Number, scale:Number, ):void {
// 			
// 		}
		public function rotateTo							(r:Number, withinLimits:Boolean=true):void {
			setTargetPosition								(_targetPos.x, _targetPos.y, _targetZoom, r, withinLimits);
			
		}
		public function moveTo							(xx:Number, yy:Number, withinLimits:Boolean=true):void {
			setTargetPosition								(xx, yy, _targetZoom, _targetRotation, withinLimits);
		}
		public function scaleTo							(ss:Number, withinLimits:Boolean=true):void {
			setTargetPosition								(_targetPos.x, _targetPos.y, ss, _targetRotation, withinLimits);
		}
		private function setTargetPosition						(xx:Number, yy:Number, ss:Number, rr:Number, withinLimits:Boolean=true):void {
			_targetPos.x								= xx;
			_targetPos.y								= yy;
			_targetZoom								= ss;
			_targetRotation								= rr;
			updateTargetPos								();
// 			if (withinLimits)								adjustPanLimits();
			updatePosition								();
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		private function setupContentCustom					(c:DisplayObject, hasPan:Boolean=true, hasZoom:Boolean=true, hasRot:Boolean=true, startPosition:Rectangle=null, mode:String="NORM", align:String="NORMAL"):void {
			if (startPosition)								_mainWindow = startPosition.clone();
			_hasPan									= hasPan;
			_hasZoom									= hasZoom;
			_hasRotation								= hasRot;
			_mode									= mode;
			_resize									= align;
			setupContent								(c);
		}
		private function setupContent						(c:DisplayObject):void {
			// This is a normal setup content, uses window as minimum zoom
			if (_contentContent)							release();
			c.scaleX = c.scaleY							= 1;
			c.x = c.y									= 1;
			_contentContent								= c;
// 			trace("MI CHIAMANO IL CONTENT",_contentContent,_contentContent.width,_contentContent.height);
// 			_matrix									= _content.transform.matrix;
			_gesture									= new TransformGesture(_content);
			_gesture.addEventListener						(org.gestouch.events.GestureEvent.GESTURE_BEGAN, onGesturePanZoomSmoothStart);
			_gesture.addEventListener						(org.gestouch.events.GestureEvent.GESTURE_CHANGED, onGesturePanZoomSmooth);
			_gesture.addEventListener						(org.gestouch.events.GestureEvent.GESTURE_ENDED, onGestureEnded);
			if (_doubleTapReset) {
				_doubleTap								= new TapGesture(_content);
				_doubleTap.addEventListener				(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onDoubleTab);
				_doubleTap.maxTapDelay					= 300;
				_doubleTap.numTapsRequired				= 2;
			}
// 			if (_hasSwipe) {
// 				_swipe 								= new SwipeGesture(_content);
// 				_swipe.addEventListener					(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSwipe);
// 			}
			render									();
		}
		private function render							():void {
// 			trace("VEDIAMO SE TO CAZZO DE CONTENT E' GIA' LARGO",_content.width,_content.height);
			_content.addChild							(_contentContent);
			UDisplay.resizeSpriteTo						(_contentContent, _mainWindow, _resize);
			UDisplay.alignSpriteTo						(_contentContent, _mainWindow);
// 			trace("CONTENT RESIZZATO",_contentContent,_contentContent.width,_contentContent.height);
			_content.x = _realContent.x						= _w/2;
			_content.y = _realContent.y						= _h/2;
			_contentContent.x							-= _content.x;
			_contentContent.y							-= _content.y;
			_realContent.addChild							(_contentContent);
			UDisplay.drawRectangle						(_content, new Rectangle(_contentContent.x, _contentContent.y, _contentContent.width, _contentContent.height), 0xff0000);
			_minimumZoom = _initialZoom = _relZoom = 1;
			_maximumZoom								= MAX_ZOOM_MULT;
			_initialPos									= new Point(_content.x, _content.y);
			_actualRotation								= _targetRotation = 0;
			_content.alpha								= DEBUG_TARGET ? 0.5 : 0;
			resetPosition								();
			complete									();
// 			if (DEBUG_BOUNDS) {
				scaleTo								(1.3, true);
// 				rotateTo								(120, true);
// 				moveTo								(0, 700, false);
// 				adjustPanLimits_BOUNDS					();
// 			}
		}
// MOVE ///////////////////////////////////////////////////////////////////////////////////////
		private function resetPosition						():void {
			_relZoom									= 1;
			_content.x									= _initialPos.x;
			_content.y									= _initialPos.y;
			_content.scaleX = _content.scaleY					= _initialZoom;
			_content.rotation								= 0;
			var rotRest								:Number = _targetRotation%360;
			_targetRotation								= rotRest < 180 ? _targetRotation - rotRest : _targetRotation + (360-rotRest);
// 			_panLimits									= new Rectangle(_w/2,_h/2,1,1);
			updatePosition								();
		}
// LISTENERS /////////////////////////////////////////////////////////////////////////////////////
		private function onGesturePanZoomSmoothStart			(e:org.gestouch.events.GestureEvent):void {
			stopSmoothMotion							();
			broadcastEvent								(EVT_START);
			onGesturePanZoomSmooth						(e);
		}
		private function onGesturePanZoomSmooth				(e:org.gestouch.events.GestureEvent):void { 
			_gesture									= e.target as TransformGesture;
			if (_hasPan)								pan();
			if (_hasZoom)								zoom();
			if (_hasRotation)								rotate();
// 			if (_limitPan)								adjustPanLimits();
			updatePosition								();
		}
			private function pan							(momentum:Boolean=false):void {
				_offsetX								= _gesture.offsetX;
				_offsetY								= _gesture.offsetY;
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
					_relZoom 							= _content.scaleX / _minimumZoom;
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
			broadcastEvent								(EVT_COMPLETE);
			_gesture									= e.target as TransformGesture;
			if (_hasPan && _hasMomentum) 					panMomentum();
			updatePosition								();
		}
			private function panMomentum					():void {
				// This one works the LAST offestX and offsetY direction and computes a momentum force pan
				if (Math.abs(_offsetX) > MINIMUM_STEPS.pan || Math.abs(_offsetY) > MINIMUM_STEPS.pan) {
					_force							= Point.distance(POINT_ZERO, new Point(_offsetX, _offsetY));
					_direction							= UDisplay.getAngle(_offsetX, _offsetY);
						if (_force > MINIMUM_FORCE) {
							_offsetX					*= FORCE_MULTIPLIER;
							_offsetY					*= FORCE_MULTIPLIER;
						}
					_matrix							= _content.transform.matrix;
					_matrix.translate						(_offsetX, _offsetY);
					_content.transform.matrix				= _matrix;
				}
			}
		private function onDoubleTab						(e:org.gestouch.events.GestureEvent):void {
			reset										();
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
// SMOOTH MOTION /////////////////////////////////////////////////////////////////////////////////////////////////////
		private function updatePosition						():void { // To be called after everytime we reposition original square (and _targetRotation);
			prepareTargetPos							();
			adjustPanLimits								();
			if (_useSmooth)								startSmoothMotion();
			else	{
				completeSmoothMotion						();
			}
		}
// 		private function activateSmoothMotionFunc				():void {
// 			prepareTargetPos							();
// 			startSmoothMotion							();
// 		}
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
		}
		private function updateTargetPos						():void { // Updates target clip (_content) to reflect new target positions
			_content.scaleX = _content.scaleY					= _targetZoom;
			_content.x									= _targetPos.x;
			_content.y									= _targetPos.y;
			_content.rotation								= _targetRotation;
		}
		private function applyPositioning						():void { // Sets content immediately to target position
			_realContent.x								= _content.x;
			_realContent.y								= _content.y;
			_realContent.scaleY = _realContent.scaleX			= _content.scaleX;
			_realContent.rotation							= _actualRotation = _targetRotation;
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
				stopSmoothMotion						();
				return;
			}
			_realContent.scaleX = _realContent.scaleY			= _realContent.scaleX + ((_content.scaleX - _realContent.scaleX)*_multiplier);
			_realContent.x								+= (_content.x - _realContent.x) * _multiplier;
			_realContent.y								+= (_content.y - _realContent.y) * _multiplier;
			_actualRotation								+= (_targetRotation - _actualRotation) * _multiplier;
			_realContent.rotation							= _actualRotation;
			broadcastEvent								(EVT_CHANGING);
// 			if (DEBUG_BOUNDS) 							updateLimits_BOUNDS();
// 				_bounds									= _content.getRect(this);
// 				UDisplay.drawRectangle					(_debugLayer, _bounds, 0x0000ff);
// 			}
		}
		private function stopSmoothMotion					():void { // This one just stop smooth motion and blocks image
			if (_moving) {
				Debug.debug								(_debugPrefix, "Smooth motion interrupted.");
				UExec.removeEnterFrameListener					(smoothMoveFollow);
				_moving									= false;
				_content.x									= _realContent.x;
				_content.y									= _realContent.y;
				_content.scaleY = _content.scaleX					= _realContent.scaleX;
				_content.rotation								= _targetRotation = _actualRotation;
			}
		}
		private function completeSmoothMotion					():void { // Terminates motion and moves everything in sync with target
			Debug.debug								(_debugPrefix, "Smooth motion completed.");
			setToTargetPos								();
			UExec.removeEnterFrameListener					(smoothMoveFollow);
			_moving									= false;
			broadcastEvent								(EVT_CHANGED);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
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
			Debug.debug								(_debugPrefix, "Required steps to smooth " + value + " in zeno's paradox, with multiplier of " + mult + " and minimum of " + minValue + " is: " + steps);
			return									steps;
		}
		private function refreshMatrix						():void { 
			// Refreshes matrix, before any motion applied to matrix
			_matrix									= _content.transform.matrix;
			_transformPoint 								= _matrix.transformPoint(_content.globalToLocal(_gesture.location));
		}
// LIMITS ///////////////////////////////////////////////////////////////////////////////////////
		private function adjustPanLimits						():void {
			this["adjustPanLimits_"+_mode]					();
		}
		private function adjustPanLimits_NORM					():void {
			adjustZoom								();
			// Checks if image moved outside of pan limits
			updateLimits_NORM							();
			setWithinLimits								();
		}
		private function adjustPanLimits_VIEW					():void { 
			adjustZoom								();
			// Checks if image moved outside of pan limits
// 			if (_relZoom >= 1) {
				updateLimits_VIEW						();
				setWithinLimits							();
// 			}
// 			else {
// 				if (_content.x != _centerPoint.x)				_content.x = _centerPoint.x;					
// 				if (_content.y != _centerPoint.y)				_content.y = _centerPoint.y;					
// 			}
			
			
			
		}
		private function adjustPanLimits_BOUNDS				():void { 
			adjustZoom								();
			// Checks if image moved outside of pan limits
			updateLimits_BOUNDS							();
			setWithinLimits								();
		}
		private function adjustZoom						():void {
			if (_targetZoom < _minimumZoom) {
				_targetZoom							= _minimumZoom;
				updateTargetPos							();
			}
			else if (_targetZoom > _maximumZoom) {
				_targetZoom							= _maximumZoom;
				updateTargetPos							();
			}
		}
		private function setWithinLimits						():void {
			if (!_panLimits.contains(_targetPos.x, _targetPos.y)) {
				var offset								:int = 0;
				if (_targetPos.x > _panLimits.right) {
// 					trace("TROPPO OLTRE DESTRAAAAAAAAA");
					_targetPos.x = _panLimits.right-offset;
				}
				else if (_targetPos.x < _panLimits.left)	{
// 					trace("TROPPO OLTRE SX");
					_targetPos.x = _panLimits.left+offset;
				}
				if (_targetPos.y > _panLimits.bottom) {
// 					trace("TROPPO BOTTOM");
					_targetPos.y = _panLimits.bottom-offset;
				}
				else if (_targetPos.y < _panLimits.top) {
// 					trace("TROPPO TOP");
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
			if (_relZoom > 1) {
				_panLimits.inflate						((_w*(_relZoom-1))/2, (_h*(_relZoom-1))/2);
			}
		}
		private function updateLimits_VIEW					():void { 
			updateLimits_BOUNDS							();
			// Image is not rotated, it must always occupy all area
// 			if (
// 			if (_relZoom > 1) {
// 				_panLimits								= new Rectangle(_centerPoint.x,_centerPoint.y,0,0);
// 				_panLimits.inflate						((_w*(_relZoom-1))/2, (_h*(_relZoom-1))/2);
// 				trace(_panLimits);
// 			}
		}
		private function updateLimits_BOUNDS					():void { // All image will be always visible
			_bounds									= _content.getBounds(this);
			_panLimits									= _mainWindow.clone();
			if (_bounds.height > _h) {
				_panLimits.y							= (-(_bounds.height - _h)) + _bounds.height/2;
				_panLimits.height						= (_bounds.height - _h);
			}
			else {
				_panLimits.y							= _bounds.height/2;
				_panLimits.height						= _h-_bounds.height;
			}
			if (_bounds.width > _w) {
				_panLimits.x							= (-(_bounds.width - _w)) + _bounds.width/2;
				_panLimits.width							= (_bounds.width - _w);
			}
			else {
				_panLimits.x							= _bounds.width/2;
				_panLimits.width							= _w-_bounds.width;
			}
// 			if (_bounds.top
			
			
			if (DEBUG_BOUNDS) {
				_debugLayer.x							= _bounds.x;
				_debugLayer.y							= _bounds.y;
				_debugLayer.width						= _bounds.width;
				_debugLayer.height						= _bounds.height;
// 				UDisplay.drawRectangle					(_debugLayer, _bounds, 0x0000ff);
			}
		}
// SCROLL FUNCTIONS ////////////////////////////////////////////////////////////////////////////////
	} // CLOSE CLASS ///////////////////////////////////////////////////////////////////////////////
}