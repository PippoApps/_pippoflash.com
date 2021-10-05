package com.pippoflash.framework.starling.util 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.framework.starling._StarlingBase;
	import com.pippoflash.framework.starling._StarlingUDisplay;
	import com.pippoflash.motion.PFMover;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import com.pippoflash.utils.*;
	import starling.display.Sprite;
	import starling.utils.MathUtil;

	import org.gestouch.gestures.*;
	import org.gestouch.events.*;
	import org.gestouch.core.*;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class ImageViewer extends _StarlingBase 
	{
		public static const EVT_IMAGE_READY:String = "onImgReady";
		public static const EVT_MOTION_COMPLETE:String = "onImgMotionComplete"; // Sends a position object {}
		public static const EVT_MOVING:String = "onImgMoving"; // Not implemented yet
		public static const ZOOM_MULT:Number = 1.3;
		public static const JUMP_SPEED:Number = 1.2;
		public static const MAX_ZOOM:Number = 3;
		public static const MIN_ZOOM:Number = 0.5;
		private static const MINIMUM_STEPS:Object = {zoom:0.005, pan:0, rot:0.008}; // Minimum values to activate a gesture
		private static const EVT_USE_CAPTURE:Boolean = false;
		private static const EVT_WEAK_REFERENCE:Boolean = true;
		private static const EVT_PRIORITY:int = 9;
		private static const EVT_MOVING_TIME:Number = 0.1;
		
		// Static for ImageViewer
		static private var _mover:PFMover = new PFMover("ImageViewer"); // this deserves it's own static mover
		private var _rect:Rectangle;
		private var _center:Point;
		private var _imageId:String;
		private var _image:Image; 
		private var _content:DisplayObject;
		private var _resize:String;
		private var _status:uint = 0; // 0 = empty, 1 = loading, 2 = showing
		private var _interface:Sprite; // If interface elements are setup, this one is created
		private var _motionMarker:Quad; // Creates a motion marker so that image will slowly reach this motion marker
		private var _contentMask:Quad;
		private var _imageZoomer:Sprite; // Holds resized image so that  it will be scale 1
		//private var _debugPanMarker:Quad;
		// GESTURES - SWITCHES
		private var _hasZoom:Boolean = true; 
		private var _hasPan:Boolean = true;
		private var _hasRotation:Boolean = true;
		private var _hasSwipeH:Boolean = true; // If SWIPE is active - horizontal
		private var _hasSwipeV:Boolean = false; // If SWIPE is active - vertical
		private var _hasSwipe:Boolean = true; // Has any swipe, H or V
		private var _hasMomentum:Boolean = true; // If panning need to register also momentum
		private var _hasDoubleTap:Boolean = true; // Intercept double tap - IF THIS IS true, reset on double tap will NOT WORK
		private var _hasSingleTap:Boolean = false; // Intercept single tap (inhibits double tap)
		private var _doubleTapReset:Boolean = true; // Brings back to original position - _hasDoubleTap MUST be true
		// GESTURES - UTILITIES
		private var _offsetX:Number; // Stores gesture force
		private var _offsetY:Number; // Stores gesture force
		private var _matrix:Matrix; // Transformation matrix
		private var _transformPoint:Point;
		//private var _newMult:Number;
		//private var _newZoom:Number;
		private var _maximumZoom:Number = 4;
		private var _minimumZoom:Number = 1;
		private var _lastPositionObj:Object; // Stores the last objec image is jumped to
		// GESTURES
		private var _gesture:TransformGesture;
		private var _doubleTap:TapGesture;
		private var _singleTap:TapGesture;
		private var _swipeGesture:SwipeGesture;
		private var _tunnelEventsTarget:DisplayObject; // If set, tap and swipe events will be tunneled to this object events ill be tunneled
		private var _motionActive:Boolean; // If user marks motion as active or inactive
		// MARKERS
		private var _moving:Boolean;
		
		public function ImageViewer(rect:Rectangle, hasZoom:Boolean=true, hasPan:Boolean=true, hasRotation:Boolean=true, tunnelEventsTarget:DisplayObject=null, id:String="") 
		{
			super("ImageViewer" + id, ImageViewer, false);
			_rect = rect;
			_center = new Point(_rect.width / 2, _rect.height / 2);
			_resize = _StarlingUDisplay.RESIZE_FILL;
			_hasZoom = hasZoom;
			_hasPan = hasPan;
			_hasRotation = hasRotation;
			//if (mask) setMaskActive(true);
			_tunnelEventsTarget = tunnelEventsTarget;
			_imageZoomer = new Sprite();
			addChild(_imageZoomer);
			//_imageZoomer.alpha = 0.5;
		}
		
		
		public function setMaskActive(a:Boolean):void {
			if (a) {
				if (!mask) {
					var q:Quad = new Quad(_rect.width, _rect.height, 0xff0000);
					addChild(q);
					mask = q;
				}
			} else {
				if (mask) {
					mask.removeFromParent();
					mask.dispose();
					mask = null;
				}
			}
			
		}
		/**
		 * Releases and disposes everything, also texture. Don't use it if you plan to use a texture again.
		 */
		public function clear():void {
			if (!_content) return;
			if (_content) _content.removeFromParent();
			_content = null;
			if (_image) {
				// Image is also content so no remove from parent
				//_image.removeFromParent();
				_image.texture.dispose();
				_image.dispose();
				_image = null;
			}
			resetTransform(true);
		}
		/**
		 * Release content and no not destroy image object.
		 */
		public function clearImage(andClearTexture:Boolean=false):void { // destroys image without destroying texture
			if (!_content) return;
			resetTransform(true);
			if (_content) _content.removeFromParent();
			_content = null;
			if (_image) {
				if (andClearTexture) _image.texture.dispose();
				_image.dispose();
				_image = null;
			}
		}
		public function setMotionActive(a:Boolean):void {
			if (a) {
				if (!_interface) {
					_interface = new Sprite();
					addChild(_interface);
					_motionMarker = new Quad(_rect.width, _rect.height, 0x00ff00);
					_motionMarker.alpha = 0; 
					_interface.addChild(_motionMarker);
					//_debugPanMarker = new Quad(500, 500, 0x000000);
					//_debugPanMarker.alpha = 0.5;
					//_interface.addChild(_debugPanMarker);
					_gesture = new TransformGesture(_motionMarker);
					_gesture.addEventListener(org.gestouch.events.GestureEvent.GESTURE_BEGAN, onGesturePanZoomSmoothStart, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
					_gesture.addEventListener(org.gestouch.events.GestureEvent.GESTURE_CHANGED, onGesturePanZoomSmooth, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
					_gesture.addEventListener(org.gestouch.events.GestureEvent.GESTURE_ENDED, onGestureEnded, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
					if (_hasSingleTap) {
						_singleTap = new TapGesture(_motionMarker);
						_singleTap.addEventListener(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSingleTap, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
						_singleTap.numTapsRequired = 1;
					}
					if (_hasDoubleTap) {
						_doubleTap								= new TapGesture(_motionMarker);
						_doubleTap.addEventListener				(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onDoubleTap, EVT_USE_CAPTURE, EVT_PRIORITY, EVT_WEAK_REFERENCE);
						_doubleTap.maxTapDelay					= 500;
						_doubleTap.numTapsRequired				= 2;
						if (_hasSingleTap) {
							_singleTap.requireGestureToFail			(_doubleTap);
						}
					}
					//// Swiping
					_hasSwipe									= _hasSwipeH || _hasSwipeV;
					if (_hasSwipe) {
						_swipeGesture							= new SwipeGesture(_motionMarker);
						_swipeGesture.addEventListener				(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSwipe);
					}				
				}
			} else { // Deactivate
				// Nothing happens so far
			}
			_motionActive = a; // this controls if motion is registered or not
		}
		public function resetTransform(immediate:Boolean = false):void {
			if (_motionMarker) {
				_motionMarker.scale = 1;
				_motionMarker.x = _motionMarker.y = 0;
				_motionMarker.rotation = 0;
			}
			if (immediate) {
				if (PFMover.isMoving(_imageZoomer)) {
					_mover.stopMotion(_imageZoomer);
				}
				_imageZoomer.scale = 1;
				_imageZoomer.x = _imageZoomer.y = 0;
				//_imageZoomer.x = _center.x;
				//_imageZoomer.y = _center.y;
				_imageZoomer.rotation = 0;
			} else {
				jumpToMarker();
			}
		}
		public function loadImage(imagePath:String):void {
			_imageId = imagePath;
			if (_imageId.indexOf(".") != -1) { // Name has dots, most likely an extension (.jpg. .png, etc.)
				var a:Array = _imageId.split(".");
				a.pop();
				_imageId = a.join("."); // Ony the last dot is removed
			}
			if (_imageId.indexOf("/") != -1) { // Name has /, most likely a url
				var a:Array = _imageId.split("/");
				_imageId = a.pop(); // Removing all path from images
			}
			loadSingleAsset(imagePath, onImageLoaded, _imageId);
		}
		private function onImageLoaded(id:String):void {
			if (id != _imageId) {
				Debug.error(_debugPrefix, "Image " + id + " is loaded but I was rendring: " + _imageId + ", aborting redner.");
				return;
			}
			Debug.debug(_debugPrefix, "Image loaded " + _imageId);
			_image = new Image(mainAssets.getTexture(_imageId));
			//_imageZoomer.addChild(_image);
			setContent(_image);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_IMAGE_READY);
		}
		public function setImage(img:Image, rect:Rectangle = null):void {
			Debug.debug(_debugPrefix, "Setting external image in rectangle ", rect);
			_image = img;
			setContent(_image, rect);
		}
		private function setContent(c:DisplayObject, rect:Rectangle=null):void {
			if (_content) clear();
			else resetTransform(true);
			_content = c;
			_imageZoomer.addChild(_content);
			addChildAt(_imageZoomer, 0);
			//trace("SCALA ZOOMER",_imageZoomer.scale);
			uDisplay.alignAndResize(_content, _rect, _resize);
					//_debugPanMarker = new Quad(200,200,0x000000);
					//_debugPanMarker.beginFill(0x000000, 1);
					//_debugPanMarker.drawRectangle(0, 0, 300, 200);
					//_debugPanMarker.endFill();
					//_imageZoomer.addChild(new Quad(1000, 1000, 0xff0000));
					//_image.scale = 0.5;
			//_imageZoomer.addChild(_debugPanMarker);
			//trace("SCALA ZOOMER",_imageZoomer.scale);
			//
			//StarlingGesturizer.addTap(_motionMarker, onTapZoomer);
			Debug.debug(_debugPrefix, "Image correctly setup.");
		}
		//private function onTapZoomer(c:DisplayObject):void {
			//zoomTo(ZOOM_MULT, StarlingGesturizer.getTapLocation(c));
		//}
		
		
		// GESTURES LISTENERS
		private function onGesturePanZoomSmoothStart(e:org.gestouch.events.GestureEvent):void {
			if (!_motionActive) return;
			//shutDownSwipeGesture						(); // Shut down swipe if active
			//stopSmoothMotion							();
			// Stop moving content if moving
			if (PFMover.isMoving(_imageZoomer)) {
				_mover.stopMotion(_imageZoomer);
				// Reset content marker to _imageZoomer position (_imagezoomer is what I see, and since I stop it I need to work there
				uDisplay.setDisplayObjectProperties(_motionMarker, uDisplay.getDisplayObjectProperties(_imageZoomer));
			}
			// Stop all motions
			
			//storePreviousPosition							();
			//broadcastEvent								(EVT_START, this);
			//resetMotionEventName							();
			//refreshMatrix();
			_moving = true;
			if (EVT_MOVING_TIME) UExec.time(EVT_MOVING_TIME, checkForTimedMotionEvent);
			onGesturePanZoomSmooth(e);
				//_debugPanMarker.x = _transformPoint.x;
				//_debugPanMarker.y = _transformPoint.y;
		}
		private function resetMotionEventName():void {
			// Resets motion event to normal motion in progress (instead of memontum)
			//_motionContinueEvent = EVT_CHANGING; // Reset motion progress event to the one without momtnum (it only changes if momentum is active and happening)
		}
		private function onGesturePanZoomSmooth(e:org.gestouch.events.GestureEvent):void { 
			if (!_motionActive) return;
			_gesture = e.target as TransformGesture;
			refreshMatrix();
			if (_hasPan) pan();
			if (_hasZoom) zoom();
			//if (_hasRotation) rotate();
			//updatePosition();
			//broadcastEvent(EVT_CONTINUE, this);
			//onAllInteraction();
			_motionMarker.transformationMatrix = _matrix;
			jumpToMarker();
			if (EVT_MOVING_TIME == 0) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_MOVING, _lastPositionObj);
		}
		private function refreshMatrix():void {
			_matrix = _motionMarker.transformationMatrix;
			//_transformPoint = _matrix.transformPoint(_gesture.location);
			_transformPoint = _matrix.transformPoint(_motionMarker.globalToLocal(_gesture.location));
		}
			private function pan(momentum:Boolean = false):void {
				//trace(_gesture.offsetX);
				//_debugPanMarker.x = _transformPoint.x;
				//_debugPanMarker.y = _transformPoint.y;
				_motionMarker.x = _transformPoint.x;
				//_motionMarker.y = _transformPoint.y;
				
				_offsetX = _gesture.offsetX / contentScale; // I need to consider the whole content scale set in _StarlingApp
				_offsetY = _gesture.offsetY / contentScale;
				//_debugPanMarker.x += _gesture.offsetX;
				//trace(_offsetX);
				if (Math.abs(_offsetX) > MINIMUM_STEPS.pan || Math.abs(_offsetY) > MINIMUM_STEPS.pan) {
					_matrix.translate(_offsetX, _offsetY);
				}
			}
			//prv
			private function zoom():void {
				if (_gesture.scale != 1 && Math.abs(_gesture.scale) > MINIMUM_STEPS.zoom) {
					var newMult:Number = _gesture.scale;
					var newZoom:Number = _motionMarker.scale * _gesture.scale;
					if (newZoom > _maximumZoom) newMult = _maximumZoom / _motionMarker.scale;
					else if (newZoom < _minimumZoom) newMult = _minimumZoom / _motionMarker.scale;
					_matrix.translate(-_transformPoint.x, -_transformPoint.y);
					_matrix.scale (newMult, newMult);
					_matrix.translate(_transformPoint.x, _transformPoint.y);
				}
			}
			private function rotate						():void {
				//if (_gesture.rotation != 0 && Math.abs(_gesture.rotation) > MINIMUM_STEPS.rot) {
					//refreshMatrix						();
					//_matrix.translate						(-_transformPoint.x, -_transformPoint.y);
					//_matrix.rotate						(_gesture.rotation);
					//_matrix.translate						(_transformPoint.x, _transformPoint.y);
					//_content.transform.matrix				= _matrix;
					//_targetRotation						+= adjustGestureDegrees(_gesture.rotation*RADIANS_MULT);
				//}
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
			if (!_motionActive) return;
			onGesturePanZoomSmooth(e);
			//trace("ENDEEEEEEEEEEEEEDDDDDDDDDDDDDDDDDDDDD");
			Debug.debug(_debugPrefix, "Motion ended:",Debug.object(_lastPositionObj));
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_MOTION_COMPLETE, _lastPositionObj);
			_moving = false;
			//_gesture = e.target as TransformGesture;
			//if (_hasRotation && _forceReturnRotation && _targetRotation != 0) rotateTo(0);			
			//if (_hasPan && _hasMomentum) 					panMomentum();
			//updatePosition								();
			//processSwipeActivation							();
			//broadcastEvent								(EVT_COMPLETE, this);
			//onAllInteraction();
		}
		private function checkForTimedMotionEvent():void {
			if (_moving) {
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_MOVING, _lastPositionObj);
				UExec.time(EVT_MOVING_TIME, checkForTimedMotionEvent);
			}
		}
		
		
		
		
			private function panMomentum					():void {
				// This one works the LAST offestX and offsetY direction and computes a momentum force pan
				// Pan is calculated on real ipoiteusa
				//const distance							:Number = Point.distance(POINT_ZERO, new Point(_offsetX, _offsetY));
				//const force							:Number = _multiplyForceByZoom ? distance * getZoom() : distance;
				//if (force > _minimumForce) { // Momentum is active, motion broadcast changes
					//_motionContinueEvent					= EVT_MOMENTUM; // Update motion progress event to momentum
					//const mult							:Number = _forceMultiplier;
					//Debug.debug						(_debugPrefix, "Momentum force detected, multiplying by " + mult);
					//_offsetX							*= mult;
					//_offsetY							*= mult;
					//_matrix							= _content.transform.matrix;
					//_matrix.translate						(_offsetX, _offsetY);
					//_content.transform.matrix				= _matrix;
				//}
			}
	// SWIPE
		private function processSwipeActivation					():void { // SWIPE is only active when image cannot be panned, otherwise it interferes with panning
			//if (_swipeGesture) {
				//Debug.debug								(_debugPrefix, "Checking swipe activation: " + getZoom()  + " : " +  _minimumZoom);
				//if (String(getZoom()).substr(0, ZOOM_DIGITS_CHECKER) == String(_minimumZoom).substr(0, ZOOM_DIGITS_CHECKER)) {
					//Debug.debug							(_debugPrefix, "Aactivating swipe gestures...");
					//_swipeGesture.enabled 					= true;
				//}
				//else 										shutDownSwipeGesture();
			//}
		}
		private function shutDownSwipeGesture():void { // When sarting gesture, swipe must be shut down or it will be triggered panning
			//if (_swipeGesture && _swipeGesture.enabled) { // Swipe gesture is activated only at minimum zoom, therefore it is removed only if it exists
				//Debug.debug							(_debugPrefix, "Deactivating swipe gesture...");
				//_swipeGesture.enabled 					= false;
			//}
		}
		private function onSwipe							(e:org.gestouch.events.GestureEvent):void {
			if (!_motionActive) return;
			if (_tunnelEventsTarget) {
				//trace("Tunneling events!");
				StarlingGesturizer.tunnelEventTarget(_tunnelEventsTarget, e);
			}
			//var evt									:String;
			//if (_hasSwipeV && _swipeGesture.offsetX == 0) { // Horizontal swipe
				//if (_swipeGesture.offsetY > 0) { // Swipe down
					//evt								= EVT_SWIPE_UP;
				//} else { // Swipe up
					//evt								= EVT_SWIPE_DOWN;
				//}
			//}
			//else if (_hasSwipeH && _swipeGesture.offsetY == 0) { // Vertical swipe
				//if (_swipeGesture.offsetX > 0) { // Swipe right
					//evt								= EVT_SWIPE_LEFT;
				//} else { // Swipe left
					//evt								= EVT_SWIPE_RIGHT;
				//}
			//}
			//if (evt) broadcastEvent(evt, this);
			//onAllInteraction();
		}
	// TAPS
		private function onDoubleTap(e:org.gestouch.events.GestureEvent):void {
			Debug.debug(_debugPrefix, "Double TAP");
			if (!_motionActive) return;
			if (_doubleTapReset) {
				resetTransform();
			}
			//broadcastEvent(EVT_DOUBLE_TAP, this);
			//onAllInteraction();
		}
		private function onSingleTap(e:org.gestouch.events.GestureEvent):void {
			//Debug.debug(_debugPrefix, "Single TAP");
			if (!_motionActive) return;
			if (_tunnelEventsTarget) {
				//trace("Tunneling events!");
				StarlingGesturizer.tunnelEventTarget(_tunnelEventsTarget, e);
			}
			//broadcastEvent(EVT_SINGLE_TAP, this);
			//onAllInteraction();
		}		
		
		
		
		// MOTION AND TRANSFORM
		
		public function zoomTo(zoom:Number, globalPoint:Point):void {
			var localPoint:Point = _motionMarker.globalToLocal(globalPoint);
			var matrix:Matrix = _motionMarker.transformationMatrix;
			var newZoom:Number = _motionMarker.scale * zoom;
			if (newZoom < MIN_ZOOM) zoom = MIN_ZOOM / _motionMarker.scale;
			else if (newZoom > MAX_ZOOM) zoom = MAX_ZOOM / _motionMarker.scale;
			var p:Point = matrix.transformPoint(localPoint);
			matrix.translate(-p.x, -p.y);
			matrix.scale(zoom, zoom);
			matrix.translate(p.x, p.y);
			_motionMarker.transformationMatrix = matrix;
			jumpToMarker();
		}

		
		
		
		private function jumpToMarker():void {
			if (_motionMarker.x > 0) _motionMarker.x = 0;
			else if (_motionMarker.x < _rect.width - _motionMarker.width) _motionMarker.x = _rect.width - _motionMarker.width;
			if (_motionMarker.y > 0) _motionMarker.y = 0;
			else if (_motionMarker.y < _rect.height - _motionMarker.height) _motionMarker.y = _rect.height - _motionMarker.height;
			jumpToPosition({scale:_motionMarker.scale, x:_motionMarker.x, y:_motionMarker.y});
		}

		public function jumpToPosition(pos:Object):void { // to control image externally
			_lastPositionObj = pos;
			mover.move(_imageZoomer, JUMP_SPEED, pos, "Strong.easeOut", null, "to", false);
		}
		
		
		// ADD INTERFACE BUTTONS
		public function addButtonZoomIn(c:DisplayObject):void {
			addInterfaceElement(c);
			StarlingGesturizer.addTap(c, onZoomIn, 1);
		}
		public function addButtonZoomOut(c:DisplayObject):void {
			addInterfaceElement(c);
			StarlingGesturizer.addTap(c, onZoomOut, 1);
		}
		private function addInterfaceElement(c:DisplayObject):void {
			setMotionActive(true);
			_interface.addChild(c);
		}
		// INTERFACE LISTENERS
		private function onZoomIn(c:DisplayObject):void { // Defaults to false since false is not interpreted as param
			zoomTo(ZOOM_MULT, localToGlobal(_center));
		}
		private function onZoomOut(c:DisplayObject):void { // Defaults to false since false is not interpreted as param
			zoomTo(1/ZOOM_MULT, localToGlobal(_center));
		}
		
		// Getters
		/**
		 * If there is an image loaded.
		 */
		public function get active():Boolean { 
			return _status > 0;
		}
		/**
		 * Set resize mode using constants in _StarlingUDisplay.RESIZE_FILL;
		 */
		public function set resize(value:String):void 
		{
			_resize = value;
		}
		
	}

}