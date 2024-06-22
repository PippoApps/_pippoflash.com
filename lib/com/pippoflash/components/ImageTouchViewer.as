/* ImageTouchViewer - Allows image viewing using Gestouch library. 

_content creates a BG transparent, then ALL gestouch listeners will be on content, since otherwise it creates problems.


*/

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
// 	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.motion.PFTouchTransform;
	import											com.pippoflash.framework.interfaces.IPippoFlashEventListener;;
	
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
		[Inspectable (name="1.1 - Resize", type=String, defaultValue="NORMAL", enumeration="NONE,NORMAL,STRETCH,CROP,CROP-RESIZE")]
		public var _resize:String = "NORMAL";
		[Inspectable (name="1.2 - Smooth Motion", type=Boolean, defaultValue=true)]
		public var _useSmooth:Boolean = true;
		[Inspectable (name="1.3 - Bitmap - Adjust for device bitmap rendering", type=Boolean, defaultValue=true)]
		public var _adjustForDeviceBitmap:Boolean = true;
		[Inspectable (name="1.4 - Bitmap - Allow smoothing", type=Boolean, defaultValue=true)]
		public var _allowSmoothingForBitmap:Boolean = true;
// 		public var _boundsMargin							:int = 0; // This cannot be larger than half square
// 		private var _averageZenoDistance						:int = 2000; // Uses this to calculate an average number of zeno's steps - better more zeno's steps than less
// 		public var _hasZoom								:Boolean = true;
// 		public var _hasPan								:Boolean = true;
// 		public var _hasRotation							:Boolean = true;
// 		public var _hasSwipe								:Boolean = false;
// 		public var _hasMomentum							:Boolean = true; // If panning need to register also momentum
// 		public var _limitPan								:Boolean = true;
// 		public var _doubleTapReset							:Boolean = true;
// 		public var _multiplier								:Number = 0.12; // Zeno's paradox multiplier
// 		public var _minimumStep							:Number = 0.00009; // Below this step, everythig is arrived
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
// 		private static const POINT_ZERO						:Point = new Point(0,0);
// 		private static const RADIANS_MULT					:Number = 180/Math.PI;
// 		private static const MINIMUM_STEPS					:Object = {zoom:0.001, pan:0.5, rot:0.003}; // Minimum values to activate a rotation
// 		private static const MINIMUM_FORCE					:Number = 50; // This sets the minimum force required for momentum (force is distance)
// 		private static const FORCE_MULTIPLIER					:Number = 8; // Multiplies distance to give momentum
// 		private static const MAX_ZOOM_MULT					:int = 3; // Maximum 10 times bigger than the original display
// 		private static const MIN_ZENO_STEPS					:int = 50; // Smooth animation will be at least this value
// 		private static const BUFFER_ZENO_STEPS				:int = 10; // These will be added to zeno's optimal motion
// 		private static const EVT_START						:String = "onViewerGestureStart"; // Broadcasted when motion is completed
// 		private static const EVT_COMPLETE					:String = "onViewerGestureEnd"; // Broadcasted when motion is completed
// 		private static const EVT_CHANGING					:String = "onViewerChanging"; // Broadcasted while changing onViewerChanging(content:Sprite);
// 		private static const EVT_CHANGED					:String = "onViewerChanged"; // Broadcasted when motion is completed
// 		private static const DEBUG_TARGET					:Boolean = false; // Shows target clip
// 		private static const DEBUG_BOUNDS					:Boolean = false; // Shows an overlay on image bounds
// 		private static var _init								:Boolean;
		// USER VARIABLES
		// SYSTEM
// 		private var _minimumPosition						:Rectangle;
// 		private var _minimumZoom							:Number;
// 		private var _maximumZoom							:Number;
// 		private var _relZoom								:Number; // Zoom starting from 1 when image is initially resized
// 		private var _newZoom								:Number; // this is just a utylity used to store proposed zoom
// 		private var _newMult								:Number; // Another utility to calculate zoom
// 		private var _initialZoom							:Number; // Real iumage zoom when initially positioned
// 		private var _initialPos								:Point;
// 		private var _force								:Number; // Force of pan
// 		private var _direction								:Number; // Direction of pan
// 		private var _offsetX								:Number; // Stores gesture force
// 		private var _offsetY								:Number; // Stores gesture force
// 		private var _listenerFunc							:Function; // Populated according to what kind of actions are allowed
// 		private var _matrix								:Matrix; // Transformation matrix
// 		private var _transformPoint							:Point;
// 		private var _bounds								:Rectangle; // Bouds of content
// 		private var _bg									:Sprite; // Transparent BG to be below in content
// 		private var _mainWindow							:Rectangle; // Using it as a base
// 		private var _centerPoint							:Point;
// 		private var _panLimits								:Rectangle; // Rectangle with pan limits
// 		private var _mode								:String; // Mode used for viewing images - NORM, VIEW
		// DATA
		// MOTION - SMOOTH MOTION
// 		private var _originalPos							:Point; // When motion is registered
// 		private var _originalZoom							:Number; // When motion is registered
// 		private var _originalRotation							:Number; // When motion is registered
// 		private var _targetPos								:Point; // Target X and Y position
// 		private var _targetZoom							:Number;
// 		private var _targetRotation							:Number;
// 		private var _actualRotation							:Number; // Stores number of rotation, since the .rotation property is net reliable jumping over 180
// 		private var _highestDifference						:Number; // Stores the bigger motion difference to calculate zeno's paradox required steps
// 		private var _moving								:Boolean; // Moving moving moving
// 		private var _maxMoveFrames						:int; // A Number of frames computed to stop motion eventually
// 		private var _movedFrames							:int;
		// REFERENCES
		private var _pfTouchTransform:PFTouchTransform;
// 		private var _realContent							:Sprite; // This is the smoothed and moved one
// 		private var _content								:Sprite;
// 		private var _contentContent							:DisplayObject;
// 		private var _gesture								:TransformGesture;
// 		private var _doubleTap								:TapGesture;
// 		private var _debugLayer							:Sprite;
// 		private var _swipe								:SwipeGesture;
// 		private var _parent								:DisplayObjectContainer; // The parent containing _content and _realContent clips
 		// MARKERS
		// INTERFACE MODE MARKERS
		// SMOOTH SCROLL
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function ImageTouchViewer(par:Object=null) {
			super("ImageTouchViewer", par);
		}
		protected override function initAfterVariables():void {
			super.initAfterVariables();
			_pfTouchTransform = new PFTouchTransform(this, {_hasSingleTap:true});
			_pfTouchTransform.setViewport(new Rectangle(0, 0, _w, _h));
			_pfTouchTransform.setAverageDistance(Math.sqrt(_w*_h));
			_pfTouchTransform.setProperties({
				_adjustForDeviceBitmap:_adjustForDeviceBitmap,
				_allowSmoothingForBitmap:_allowSmoothingForBitmap
			});
		}
		public override function release():void {
			_pfTouchTransform.cleanup();
			super.release();
		}
		public function getBitmatAndRelease():DisplayObject {
			var b:DisplayObject = _pfTouchTransform.getBitmatAndRelease();
			release();
			return b;
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
	// Re-init with custom init object
		public function reInitViewer(initObj):void {
			
		}
	// SET CONTENT
		public function setContent(c:DisplayObject, initialPos:Object=null, par:Object=null):void { // Sets content for free motion
			// This sets image completely visible, and that is minimum zoom
			// It allows all gestures, and lets image almost disappear from screen
			_pfTouchTransform.cleanup();
			_pfTouchTransform.recycle(this, par);
			_pfTouchTransform.setContent(c, initialPos);
		}
		public function setContentViewImage(c:DisplayObject, initialPos:Object=null, par:Object=null):void { 
			// Sets content as image viewer. Only zoom and pan, never go out of screen.
			// It starts with the image completely visible, and that's the minimum zoom.
			_pfTouchTransform.cleanup();
			_pfTouchTransform.recycle(this, par);
			_pfTouchTransform.setContentViewImage(c, initialPos);
			_pfTouchTransform.setMinimumZoomFromPos();
		}
		/**
		 * Sets content as image viewer. Only zoom and pan, never go out of screen. It never shows an empty pixel. Image minimum zoom is filling all space.
		 * @param	c Object to be viewed
		 * @param	initialPos Object with initial positioning
		 * @param	par Parameter to recycle PFTouchTransform
		 */
		public function setContentViewImageFull(c:DisplayObject, initialPos:Object=null, par:Object=null):void { 
			_pfTouchTransform.cleanup();
			_pfTouchTransform.recycle(this, par);
			_pfTouchTransform.setContentViewImageFull(c, initialPos);
			_pfTouchTransform.setMinimumZoomFromPos();
		}
		public function setContentCustom(c:DisplayObject, hasPan:Boolean=true, hasZoom:Boolean=true, hasRot:Boolean=true, initPosition:Object=null, minimumWindow:Rectangle=null, mode:String="NORM", align:String="NORMAL"):void {
			_pfTouchTransform.setContentCustom(c, hasPan, hasZoom, hasRot, initPosition, minimumWindow, mode, align);
		}
		public function setLibraryDefaults(o:Object):void { // Sets a list of default variables to library
			_pfTouchTransform.setProperties(o);
			
// 		public var _useSmooth								:Boolean = true;
// 		public var _hasZoom								:Boolean = true;
// 		public var _hasPan								:Boolean = true;
// 		public var _hasRotation							:Boolean = true;
// 		public var _hasMomentum							:Boolean = true; // If panning need to register also momentum
// 		public var _hasDoubleTap							:Boolean = true;
// 		public var _hasSingleTap							:Boolean = true;
// 		public var _doubleTapReset							:Boolean = true; // Brings back to original position - _hasDoubleTap MUST be true
// 		public var _doubleTapFullSizeWhenLargerThan			:Number = 0; // 0 to keep this off. When double tapping an image, if zooming is larger than this, it will go fullscreen. - _hasDoubleTap MUST be true
// 		public var _doubleTapBackFromFullScreen				:Boolean = true; // 0 to keep this off. When double tapping an image, if zooming is larger than this, it will go fullscreen. - _hasDoubleTap MUST be true
// 		public var _hasMouseEvents							:Boolean = true; // If activating Buttonizer events. EVT_TOUCH, EVT_UNTOUCH
// 		public var _dispatchClickOnTap						:Boolean = false; // If tap dispatches a click event for mouse events underneath
// 		public var _limitPan								:Boolean = true;
// 		public var _multiplier								:Number = 0.15; // Zeno's paradox multiplier
// 		public var _minimumStep							:Number = 0.0001; // Below this step, everythig is arrived
// 		public var _jumpOnTopWhenTouched					:Boolean = true; // Bring content on first row when interacted with - _hasSingleTap MUST be true
// 		public var _maximumZoomMultiplier					:Number = 2;
// 		public var _boundsOutOfScreenOffset					:Number = 0; // This adds or remove space on sides to allow scrolling out of images
// 		public var _adjustForDeviceBitmap					:Boolean = true; // As soon as he renders an image, modifies slightly the zoom, trying to achieve downloading on the graphic card
// 		public var _allowSmoothingForBitmap					:Boolean = false; // If it is a Bitmap, smoothing is turned to on
// 		public var _alwaysResetRotationOnRectangle				:Boolean = true; // Everytime I set content within a rectangle, rotation is reset
// 		public var _multiplyForceByZoom						:Boolean = true; // This is needed to make strength and momentum always consistent independently from zoom
// 		public var _fixZoomForBitmapsOnDevice					:Number = 1.001; // This fixes zoom when I am using bitmaps on devices, in order to transfer them immediately on GPU
// 		public var _verbose								:Boolean = false;
		}
	// GETTERS
		public function getZoom():Number { // The zoom starting from 1 when image is initially positioned
			return _pfTouchTransform.getZoom();
		}
		public function getRealZoom():Number { // The real scaling factor of image
			return _pfTouchTransform.getRealZoom();
		}
		public function getTarget():Sprite {
			return _pfTouchTransform.getTarget();
		}
		public function getLibrary():PFTouchTransform {
			return _pfTouchTransform;
		}
		public function onViewerSingleTap(v:*):void {
// 			trace("CAZZOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",v,v is Array);
		}
		public function onViewerDoubleTap():void {
// 			trace("CAZZOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO DOUBLE!!!!");
		}
		
	// CONTENT CONTROL
		public function reset(immediate:Boolean=false):void {
			_pfTouchTransform.reset(immediate);
		}
		public function alignLeft(instant:Boolean):void {
			_pfTouchTransform.alignLeft(instant);
		}
		public function alignRight(instant:Boolean):void {
			_pfTouchTransform.alignRight(instant);
		}
		public function alignTop(instant:Boolean):void {
			_pfTouchTransform.alignTop(instant);
		}
		public function alignBottom(instant:Boolean):void {
			_pfTouchTransform.alignBottom(instant);
		}
		public function rotateTo(r:Number, withinLimits:Boolean=true, immediate:Boolean=false):void {
			_pfTouchTransform.rotateTo(r, withinLimits);
		}
		public function moveTo(xx:Number, yy:Number, withinLimits:Boolean=true, immediate:Boolean=false):void {
			_pfTouchTransform.moveTo(xx, yy, withinLimits);
		}
		public function scaleTo(ss:Number, withinLimits:Boolean=true, immediate:Boolean=false):void {
			_pfTouchTransform.scaleTo(ss, withinLimits);
		}
		public override function addListener(listener:Object) {
			_pfTouchTransform.addListener(listener as IPippoFlashEventListener);
		}
// SCROLL FUNCTIONS ////////////////////////////////////////////////////////////////////////////////
	} // CLOSE CLASS ///////////////////////////////////////////////////////////////////////////////
}