/* Gesturizer - 1.0 - Filippo Gregoretti - www.pippoflash.com
*/
package com.pippoflash.framework.starling {
	import com.pippoflash.framework._ApplicationStarling;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.UMem;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import org.gestouch.events.GestureEvent;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import org.gestouch.gestures.*;
	import org.gestouch.core.Gestouch; 
	import org.gestouch.input.NativeInputAdapter;
	import org.gestouch.extensions.starling.StarlingDisplayListAdapter;
	import org.gestouch.extensions.starling.StarlingTouchHitTester;
	import com.pippoflash.utils.Debug;
	import flash.utils.getTimer;
	import starling.display.Stage;
	import starling.events.TouchEvent;
	
	public class StarlingGesturizer {
		// STATIC SWITCHES
		//static public var USE_DEBUG_SWIPE_INSTEAD_OF_TAP_IN_DEBUG:Boolean = false; // sometimes testing in Animate tap events are not recorded and i is annoying when debugging. Having this on, odebugging makes it so that taps are converted to swipes.
		public static var _verbose:Boolean = true;
		public static var _eventUseCapture:Boolean = false; // Setting this to true events do not work
		public static var _eventPriority:uint = 0; // Same as ContentBoxTouch
		public static var _eventWeakReference:Boolean = false;
		private static var _debugPrefix:String = "StarlingGesturizer";
		static private var _active:Boolean = true;
		// NEW SYSTEM
		private static var _buttonsData:Dictionary; // Stores data associated to an InteractiveObject
		private static var _referenceSquare:Canvas; // A reference square used to defined target objects coordinate system form stage coordinate system
		static private var _referenceBounds:Rectangle;
		//static private var _lastUsedEvent:GestureEvent; // If I need to access last received event
		// MARKERS
		private static var _hasGestures:Boolean; // If gestures are available
		//private static var _swipeSupported			:Boolean; // It seems that if gestures are supported, swipe is always supported
		//private static var _panSupported				:Boolean;
		//private static var _zoomSupported				:Boolean;
		//private static var _supportedGestures			:String = ""; // Stores the list of supported gestures
		private static var _init:Boolean = true; // Needs init
		// STATIC LISTENERS
		static private var _onGestureGeneralMethod:Function; // Broadcasted on each gesture, no matter where
		// STATIC UTY
		//private static var _d:GesturizerItem;
		//private static var _l:*;
		//private static var _o:Object;
		//private static var _a:Array;
		//private static var _s:String;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init():Boolean { // Returns also 
			if (_init) {
				_init = false;
				//_pfId = "StarlingGesturizer";
				_hasGestures = true; // If no gestures are supported, Vector is null
				if (_hasGestures) {
					//_supportedGestures = Multitouch.supportedGestures.join(",");
					//_swipeSupported = _supportedGestures.indexOf("gestureSwipe") != -1;
					//_panSupported = _supportedGestures.indexOf("gesturePan") != -1;
					//_zoomSupported = _supportedGestures.indexOf("gestureZoom") != -1;
					_buttonsData = new Dictionary(false);
					_referenceSquare = new Canvas();
					_referenceSquare.beginFill(0);
					_referenceSquare.drawRectangle(0, 0, 1, 1);
					_referenceSquare.endFill();
					_referenceSquare.touchable = false;
					_referenceBounds = new Rectangle(0, 0, 100, 100);
					// Initialize gesturizer
					Gestouch.inputAdapter ||= new NativeInputAdapter(UGlobal.stage);
					Gestouch.addDisplayListAdapter(DisplayObject, new StarlingDisplayListAdapter());
					//Gestouch.addDisplayListAdapter(Stage, new StarlingDisplayListAdapter());
					Gestouch.addTouchHitTester(new StarlingTouchHitTester(_StarlingBase.starlingCore), -1);
					//Gestouch.addTouchHitTester(new StarlingTouchHitTester(_StarlingBase.starlingApp.stage), -1);
					
					UMem.addClass(GesturizerItem);
					//log							("Gestures available: " + _supportedGestures);
					return true;
				}
				else {
					//log("Sorry, gestures not available.");
					return false;
				}
			}
			return _hasGestures;
		}
// METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////
	// GENERAL METHOD
		static public function setGeneralOnGesture(clickMethod:Function=null):void { // Sets or remove a general click method that happens at each click
			_onGestureGeneralMethod = clickMethod;
		}
		static public function setInputActive(active:Boolean):void {
			_active = active;
		}
		static public function isActive():Boolean {
			return _active;
		}
		static public function checkInputBlocked():Boolean {
			if (!_active) {
				Debug.warning(_debugPrefix, "Gesture blocked. Gentures have been set to inactive.");
				return true;
			}
			return false;
		}
		static public function tunnelEventTarget(target:DisplayObject, e:GestureEvent):void { // Other elements can tunnel gestures to registered elements
			if (String(e.target) == "[object TapGesture]") {
				onTap(e, target);
			} else if (String(e.target) == "[object SwipeGesture]") {
				onSwipe(e, target);
			}
		}
	// GESTURE METHODS
		public static function hasGestures():Boolean {
			return init();
		}
		//static public function getLastEvent():GestureEvent {
			//return _lastUsedEvent;
		//}
		static public function getGesture(c:DisplayObject, id:String):Gesture {
			return getCreateItem(c).getGesture(id);
		}
		static public function getTapGesture(c:DisplayObject):TapGesture {
			return (getGesture(c, "tap") as TapGesture);
		}
		/**
		 * Returns the point gesture location relative to the target obect (Gesture.location returns location relative to Stage)
		 * @param	c The DisplayObject for which tap event occurred
		 * @return
		 */
		static public function getTapGestureRelativeLocation(c:DisplayObject):Point {
			//var g:TapGesture = getTapGesture(c);
			//var p:Point = new Point();
			return c.globalToLocal(getTapGesture(c).location);
		}
		static public function getSwipeGesture(c:DisplayObject):SwipeGesture {
			return (getGesture(c, "swipe") as SwipeGesture);
		}
		/**
		 * Returns a point with location of TapGesture in GLOBAL coordinates space
		 * @param	c	The display object with attached event
		 */
		static public function getTapLocation(c:DisplayObject):Point {
			return getTapGesture(c).location;
		}
		// REMOVE GESTURES ///////////////////////////////////////////////////////////////////////////////////////
		static public function removeGestures(c:DisplayObject):void {
			if (hasItemGestures(c)) {
				removeTap(c);
				removeSwipe(c);
			}
		}
		static public function removeTap(c:DisplayObject):void {
			var g:TapGesture = getTapGesture(c);
			if (g) {
				g.removeEventListener(GestureEvent.GESTURE_RECOGNIZED, onTap, _eventUseCapture);
				getItem(c).removeEvent("tap");
			}
		}
		static public function removeSwipe(c:DisplayObject):void {
			var g:SwipeGesture = getSwipeGesture(c);
			if (g) {
				g.removeEventListener(GestureEvent.GESTURE_RECOGNIZED, onSwipe, _eventUseCapture);
				getItem(c).removeEvent("swipe");
			}
		}
		static public function removePan(c:DisplayObject):void {
			/* TBD */
		}
		
		// TAP ///////////////////////////////////////////////////////////////////////////////////////
		static public function addTap(c:DisplayObject, method:Function, taps:uint = 1, param:Object=null, useSwipeIfDebug:Boolean=false):TapGesture {
			init();
			//if (UGlobal.isDebug && useSwipeIfDebug && USE_DEBUG_SWIPE_INSTEAD_OF_TAP_IN_DEBUG) {
				//Debug.warning(_debugPrefix, "Debug mode: adding swipe gesture to test in standalone flash player.");
				//addSwipe(c, method, "L,R,U,D", true);
				//return;
			//}
			var gesture:TapGesture = new TapGesture(c);
			gesture.numTapsRequired = taps;
			gesture.addEventListener(GestureEvent.GESTURE_RECOGNIZED, onTap, _eventUseCapture, _eventPriority, _eventWeakReference);
			getCreateItem(c).setEvent("tap", method, gesture, param);
			return gesture;
			// If debug add swipe on tap
		}
		static public function onTap(e:GestureEvent, targetObj:DisplayObject=null):void {
			//_lastUsedEvent = e;
			//trace("TAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP",e,e is TapGesture);
			if (checkInputBlocked()) return;
			processGeneralEvent();
			getCreateItem((e.target as TapGesture).target as DisplayObject).triggerEvent("tap");
		}
		
		
		// SWIPE ///////////////////////////////////////////////////////////////////////////////////////
		public static function addSwipe(c:DisplayObject, method:Function, evts:String="L,R,U,D", isDebugTap:Boolean=false):SwipeGesture {
			init();
			var gesture:SwipeGesture = new SwipeGesture(c);
			gesture.addEventListener(GestureEvent.GESTURE_RECOGNIZED, onSwipe, _eventUseCapture, _eventPriority, _eventWeakReference);
			// evtId is needed only to set tap_swipe event to debug on debug flash player which doesnt always recognize tap vents
			getCreateItem(c).setEvent("swipe", method, gesture, evts, isDebugTap);
			return gesture;
		}
		static private function onSwipe(e:GestureEvent, targetObj:DisplayObject=null):void {
			//_lastUsedEvent = e;
			// Detect direction
			//trace("1");
			if (checkInputBlocked()) return;
			//trace("2");
			//trace((e.target as SwipeGesture).target );
			var d:String;
			if ((e.target as SwipeGesture).offsetX > 0) d = "R";
			else if ((e.target as SwipeGesture).offsetX < 0) d = "L";
			else if ((e.target as SwipeGesture).offsetY > 0) d = "D";
			else if ((e.target as SwipeGesture).offsetY < 0) d = "U";
			//var obj:DisplayObject = targetObj ? targetObj : 
			processGeneralEvent();
			getCreateItem(targetObj ? targetObj : (e.target as SwipeGesture).target as DisplayObject).triggerEvent("swipe", d);
		}
		
		// PAN ///////////////////////////////////////////////////////////////////////////////////////
		/**
		 * Adds pan gesture. Params: (_c, _coordinates, force, isEnd, [params]);
		 * @param	c
		 * @param	method
		 * @param	relativeCoordinates
		 * @param	addForceOnEnd
		 * @param	forceMultiplier
		 * @param	param
		 */
		static public function addPan(c:DisplayObject, method:Function, relativeCoordinates:Boolean=true, addForceOnEnd:Boolean=false, forceMultiplier:Number=0.8, param:*=null):PanGesture {
			init();
			const gesture:PanGesture = new PanGesture(c);
			//gesture.numTapsRequired = taps;
			//gesture.addEventListener(GestureEvent.GESTURE_BEGAN, onPanStart, _eventUseCapture, _eventPriority, _eventWeakReference);
			gesture.addEventListener(GestureEvent.GESTURE_CHANGED, onPanMove, _eventUseCapture, _eventPriority, _eventWeakReference);
			gesture.addEventListener(GestureEvent.GESTURE_ENDED, onPanEnd, _eventUseCapture, _eventPriority, _eventWeakReference);
			//gesture.addEventListener(GestureEvent.GESTURE_STATE_CHANGE, onPanTouch, _eventUseCapture, _eventPriority, _eventWeakReference);
			c.addEventListener(TouchEvent.TOUCH, onPanTouch);
			//const touchStartGesture:TransformGesture = new TransformGesture(c);
			//touchStartGesture.addEventListener(GestureEvent.GESTURE_BEGAN, onPanTouch, _eventUseCapture, _eventPriority, _eventWeakReference);
			var item:GesturizerItem = getCreateItem(c);
			item.setEvent("pan", method, gesture, param);
			item.forceMultiplier = forceMultiplier;
			item.relativeCoords = relativeCoordinates;
			item.panning = false;
			if (addForceOnEnd) { // Initialize force calculator
				item.addForceOnEnd = true;
				item.lastGestureTime = getTimer();
			}
			return gesture;
			//trace("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",c,getItem(c));
		}
		static public function addPanStart(c:DisplayObject, panStartMethod:Function):Boolean {
			var item:GesturizerItem = getItem(c);
			if (item) {
				item.onPanStart =  panStartMethod;
				return true;
			}
			Debug.error(_debugPrefix, "addPanStart() error. addPan() must be called before for:", c);
			return false;
		}
		static public function addPanEnd(c:DisplayObject, panEndMethod:Function):Boolean {
			var item:GesturizerItem = getItem(c);
			if (item) {
				item.onPanEnd =  panEndMethod;
				return true;
			}
			Debug.error(_debugPrefix, "addPanEnd() error. addPan() must be called before for:", c);
			return false;
		}
		static private function onPanTouch(e:TouchEvent):void {
			const c:DisplayObject = e.currentTarget as DisplayObject;
			if (!e.getTouch(c)) return;
			//trace("onPanTouch", e.target, e.getTouch(c).phase);
			if (e.getTouch(c).phase == "began") {
				_StarlingBase.starlingApp.stage.addChild(_referenceSquare);
				//var c:DisplayObject = (e.target as PanGesture).target as DisplayObject;
				//trace(c);
				getItem(c).pannedParent = c.parent;
				getItem(c).panning = true;
				if (getItem(c).onPanStart) getItem(c).onPanStart(c);
				else processGeneralEvent();
			}
			//const c:DisplayObject = (e.target as PanGesture).target as DisplayObject;
			//trace("onPanTouch",getItem(c).panning);
			//if (!getItem(c).panning) trace("DAJE");
			
		}
		static private function onPanStart(e:GestureEvent):void {
			_StarlingBase.starlingApp.stage.addChild(_referenceSquare);
			const c:DisplayObject = (e.target as PanGesture).target as DisplayObject;
			//getItem(c).panning = true;
			if (getItem(c).onPanStart) getItem(c).onPanStart(c);
			processGeneralEvent();
		}
		static private function onPanMove(e:GestureEvent, eventType:String="pan"):void {
			const c:DisplayObject = (e.target as PanGesture).target as DisplayObject;
			//trace("PANNING",getItem(c).panning);
			//trace("EVENTOOOOOOOOO",eventType);
			if (getItem(c).panning) getItem(c).triggerEvent(eventType);
			processGeneralEvent();
		}
		static private function onPanEnd(e:GestureEvent):void {
			//trace("PAN END");
			const c:DisplayObject = (e.target as PanGesture).target as DisplayObject;
			onPanMove(e, "panEnd");
			getItem(c).panning = false;
			if (getItem(c).onPanEnd) getItem(c).onPanEnd(c);
			_StarlingBase.starlingApp.stage.removeChild(_referenceSquare);
			processGeneralEvent();
		}
		
		
		
		
		
		//static public function onTap(e:GestureEvent, targetObj:DisplayObject=null):void {
			////_lastUsedEvent = e;
			////trace("TAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP",e,e is TapGesture);
			//if (checkInputBlocked()) return;
			//getCreateItem((e.target as TapGesture).target as DisplayObject).triggerEvent("tap");
		//}
		
		
		
		
		//public static function addPan				(c:InteractiveObject, listener:*, evts:String="FULL", postfix:String=""):void { // evts can be FULL, HORIZONTAL or VERTICAL
			//init								();
			//if (_hasGestures && _panSupported) {
				//Debug.debug					(_debugPrefix, "Adding PAN events for " + c);
				//_d							= getCreateItem(c, listener, postfix);
				//// Here I must add normal panning methods
				//var handler					:Function = evts.charAt(0) == "F" ? onPanFull : evts.charAt(0) == "H" ? onPanFull : onPanFull;
				//c.addEventListener				(TransformGestureEvent.GESTURE_PAN, handler, _eventUseCapture, _eventPriority, _eventWeakReference);
			//}
			//else {
				//Debug.error					(_debugPrefix, "PAN gesture cannot be applied to " + c);
			//}
		//}
		//public static function addZoom				(c:InteractiveObject, listener:*, postfix:String=""):void {
			//init								();
			//if (_hasGestures && _zoomSupported) {
				//Debug.debug					(_debugPrefix, "Adding ZOOM events for " + c);
				//_d							= getCreateItem(c, listener, postfix);
				//c.addEventListener				(TransformGestureEvent.GESTURE_ZOOM, onZoom, _eventUseCapture, _eventPriority, _eventWeakReference);
			//}
			//else {
				//Debug.error					(_debugPrefix, "ZOOM gesture cannot be applied to " + c);
			//}
		//}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		//private static function onPanFull				(e:TransformGestureEvent):void {
			//if (_verbose)						Debug.debug(_debugPrefix, "PAN"+e);
			//_d								= getCreateItem(InteractiveObject(e.currentTarget)); //_buttonsData[e.target as InteractiveObject];
			//if (!_d) {
				//error							("GesturizerItem not found for InteractiveObject " + e.currentTarget  + " : " + _buttonsData[e.target as InteractiveObject]);
				//return;
			//}
			//_s								= _d.postfix;
			//e.stopImmediatePropagation				();
			//PippoFlashEventsMan.callListenerMethodName(_d.listener, EVT_PAN_FULL, e.currentTarget, e.offsetX, e.offsetY);
			//processGeneralEvent();
		//}
		//private static function onZoom				(e:TransformGestureEvent):void {
			//if (_verbose)						Debug.debug(_debugPrefix, "ZOOM"+e);
			//_d								= getCreateItem(InteractiveObject(e.currentTarget)); //_buttonsData[e.target as InteractiveObject];
			//if (!_d) {
				//error							("GesturizerItem not found for InteractiveObject " + e.currentTarget  + " : " + _buttonsData[e.target as InteractiveObject]);
				//return;
			//}
			//_s								= _d.postfix;
			//// Handle event
			//e.stopImmediatePropagation				();
			//PippoFlashEventsMan.callListenerMethodName(_d.listener, EVT_ZOOM, e.currentTarget, (e.scaleX+e.scaleY)/2);
			//processGeneralEvent();
		//}
		//private static function onSwipe				(e:TransformGestureEvent):void {
			//if (_verbose)						Debug.debug(_debugPrefix, "SWIPE"+e);
			//_d								= getCreateItem(InteractiveObject(e.currentTarget)); //_buttonsData[e.target as InteractiveObject];
			//if (!_d) {
				//error							("GesturizerItem not found for InteractiveObject " + e.currentTarget  + " : " + _buttonsData[e.target as InteractiveObject]);
				//return;
			//}
			//_o								= _d.getEvent(EVT_SWIPE);
			//var m							:Vector.<String> = new <String>[];
			//_s								= _d.postfix;
			//// Add broadcast for general swipe
			//m.push(EVT_BR_SWIPE+_s);
			//// Check for horizontal swipe
			//if (e.offsetX == 1) {
				//if (_o.e.indexOf("R") != -1) {
					//m.push					(EVT_BR_SWIPE_RIGHT+_s);
				//}
			//}
			//else if (e.offsetX == -1) {
				//if (_o.e.indexOf("L") != -1) {
					//m.push					(EVT_BR_SWIPE_LEFT+_s);
				//}
			//}
			//// Check for verticall swipe
			//if (e.offsetY == 1) {
				//if (_o.e.indexOf("D") != -1) {
					//m.push					(EVT_BR_SWIPE_DOWN+_s);
				//}
			//}
			//else if (e.offsetY == -1) {
				//if (_o.e.indexOf("U") != -1) {
					//m.push					(EVT_BR_SWIPE_UP+_s);
				//}
			//}
			//// Handle event
			//e.stopImmediatePropagation				();
			//// Broadcast methods
			////trace("FREGNA SWIPO " + m);
			//PippoFlashEventsMan.callListenerMethodNames(_d.listener, m, e.currentTarget);
			//processGeneralEvent();
		//}
			// General event
		private static function processGeneralEvent():void { // OThis processes the general gesture event
			if (_onGestureGeneralMethod) {
				var m:Function = _onGestureGeneralMethod; // This has to be nullified before calling it, or if I set it again it might be nullified
				_onGestureGeneralMethod = null;
				m();
			}
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		// Used to retrieve object data. If listener is defined, then it can be instantiated.
		private static function getCreateItem(c:DisplayObject):GesturizerItem {
			if (_buttonsData[c]) return _buttonsData[c];
			else {
				var d:GesturizerItem = new GesturizerItem(c);
				_buttonsData[c] = d;
				return d;
			}
		}
		static private function getItem(c:DisplayObject):GesturizerItem {
			return _buttonsData[c];
		}
		
		static public function get referenceSquare():Canvas {
			return _referenceSquare;
		}
		
		static private function hasItemGestures(c:DisplayObject):Boolean {
			return Boolean(_buttonsData[c]);
		}
		
	}
	
	
	
	
}

//  ///////////////////////////////////////////////////////////////////////////////////////
//  ///////////////////////////////////////////////////////////////////////////////////////
//  ///////////////////////////////////////////////////////////////////////////////////////
// This is the object created to store in _buttonsData
//  ///////////////////////////////////////////////////////////////////////////////////////
//  ///////////////////////////////////////////////////////////////////////////////////////
//  ///////////////////////////////////////////////////////////////////////////////////////
	//import									flash.display.*;
	//import									flash.events.*;
	//import									com.pippoflash.framework.interfaces.*;
	import flash.display3D.textures.RectangleTexture;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.display.DisplayObject;
	import org.gestouch.gestures.*;
	import org.gestouch.events.GestureEvent;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import flash.utils.getTimer;
	import com.pippoflash.utils.UNumber;

	dynamic class GesturizerItem {
		private static const DEFAULT_FORCE_MULTIPLIER:Number = 0.8; // Distance/time/force
		private static const MAX_FORCE:Number = 80; // Max force to multiply actual distance for
		static private var _g:Object;   // Utility
		//static private var _specificInits:Object; // Stores specific initialization methods for each event
		private var _c :DisplayObject;
		private var _boundsMultiplier:Rectangle; // Some gestures require this to multiply bounds
		private var _relativeCoords:Boolean; // If relative coordinates are necessary
		private var _coordinates:Point; // When there is need of a coordinates point
		private var _gestures:Object = {}; // Stores an object for each gesture: {method:Function, gesture:Gesture}
		private var _extraParameters:Object = {}; // Stores extra parameters to be used in special occasions
		//private var _lastGestureTime:int; // Stores getTimer() if necessary.
	// INIT ////////////////////////////////////////////////////////////////////////
		public function GesturizerItem(c:DisplayObject):void {
			recycle(c);
		}
		public function recycle(c:DisplayObject):void {
			_c = c;
		}
		public function cleanup():void {
			
		}
	// METHODS ////////////////////////////////////////////////////////////////////////
		public function setEvent(n:String, method:Function, gesture:Gesture, par:Object=null, isDebugTap:Boolean=false):void {
			var g:Object = {m:method, g:gesture, par:par};
			if (isDebugTap) g.isDebugTap = true;
			if (n == "pan") _specificEventInit_pan(g); // CReates rectangle to be used as reference for motion
			_gestures[n] = g;
		}
		private function _specificEventInit_pan(g:Object):void {
			_boundsMultiplier = new Rectangle(); // CReates rectangle to be used as reference for motion
			_coordinates = new Point();
			this.forceMultiplier = DEFAULT_FORCE_MULTIPLIER;
		}
		private function _specificEventInit_pancomplex(g:Object):void {
			_specificEventInit_pan(g);
		}
		
		
		public function removeEvent(n:String):void {
			var g:Object = _gestures[n];
			if (g) {
				g.method = null;
				g.gesture = null;
				g.par = null;
				_gestures[n] = null;
			}
		}
		public function triggerEvent(n:String, par:Object = null):void {
			//trace("triggero",n);
			this["triggerEvent_" + n](par);
		}
		public function getGesture(id:String):Gesture { // Returns geture event for "tap", "swipe", etc
			return _gestures[id] ? _gestures[id].g : null;
		}
		private function triggerEvent_swipe(direction:String):void {
			_g = _gestures["swipe"];
			//trace("triggero swipeeeeeeeeeeeeeeee",Debug.object(_g));
			if (_g) {
				if (_g.isDebugTap) _g.m(_c);
				else if (_g.par.indexOf(direction) != -1) _g.m(_c, direction);
			}
			_g = null;
		}
		private function triggerEvent_tap(par:Object=null):void {
			_g = _gestures["tap"];
			var g:TapGesture = _g.g;
			//trace("LOCATION",g.location, g.target, g.target.width / g.target.scaleX, g.state);
			if (_g) {
				if (par) _g.m(_c, par);
				else _g.m(_c);
			}
			_g = null;
		}
		
		
		private function triggerEvent_pan(par:Object=null):void {
			//_g = _gestures["pan"];
			//trace("PANNNNNN");
			var g:PanGesture = _gestures["pan"].g;
			//trace("LOCATION",g.location, g.target, g.target.width / g.target.scaleX, g.state);
			_coordinates.x = g.offsetX;
			_coordinates.y = g.offsetY;
			if (_relativeCoords) {
				/* This one triggered an error ONCE!!!  A starling internal error. Therefore I put it in a try catch. */
				try {
					StarlingGesturizer.referenceSquare.getBounds(this.pannedParent, _boundsMultiplier);
					_coordinates.x *= _boundsMultiplier.width;
					_coordinates.y *= _boundsMultiplier.height;
				} 
				catch (e:Error) {
					Debug.error("GesturizerItem", "Error in StarlingGesturizer.triggerEvent_pan()");
				}
			} 
			if (this.addForceOnEnd) {
				//_lastGestureTime = getTimer();
				this.panTime = getTimer() - this.lastGestureTime;
				this.lastGestureTime = getTimer();
				//triggerEvent_panEnd(par);
				const speedX:Number = Math.abs(_coordinates.x) / (this.panTime / 1000);
				//trace("speedX", speedX);
			}
			if (!_triggerPanEvent(par)) Debug.error("GesturizerItem", "Error in triggerEvent_pan()");
		}
		private function triggerEvent_panEnd(par:Object=null):void {
			//_g = _gestures["pan"];
			//trace("panend");
			// Pan end doesn't store offset. It only triggers an end motion.
			// therefore I have to use latest motin coordinates store in _coordinates since that was the last pan detected
			if (this.addForceOnEnd) { // Trigger last pan with momentum
				const g:PanGesture = _gestures["pan"].g;
				//const elapsedTime:Number = this.panTime;
				//trace("Adding end with elapsed time: " + elapsedTime);
				//trace("Distance: " + _coordinates.x);
				//const speedX:Number = Math.abs(_coordinates.x) / (this.panTime/1000);
				//const speedY:Number = Math.abs(_coordinates.y) / (this.panTime/1000);
				const forceX:Number = UNumber.getRanged(Math.abs(_coordinates.x / this.panTime)*this.forceMultiplier, MAX_FORCE, 1);
				const forceY:Number = UNumber.getRanged(Math.abs(_coordinates.y / this.panTime)*this.forceMultiplier, MAX_FORCE, 1);
				_coordinates.x *= forceX;
				_coordinates.y *= forceY;
				//trace(_coordinates);
				//trace("speedX", speedX);
			} //else triggerEvent_pan(par);
			if (!_triggerPanEvent(par, forceX > forceY ? forceX : forceY, true)) Debug.error("GesturizerItem", "Error in triggerEvent_panEnd()");
		}
		private function _triggerPanEvent(par:Object = null, force:Number = 1, isEnd:Boolean = false):Boolean {
			// Error checking
			if (isNaN(_coordinates.x) || isNaN(_coordinates.y) || isNaN(force)) {
				Debug.error("GesturizerItem", "Error in pan coordinates. something is NAN: _copordinates, force: " + _coordinates, force);
				return false;
			}
			if (par) _gestures["pan"].m(_c, _coordinates, force,  isEnd, par);
			else _gestures["pan"].m(_c, _coordinates, force, isEnd);
			return true;
		}
	// GETTERS/SETTERS ////////////////////////////////////////////////////////////////////////
		public function get target():DisplayObject 
		{
			return _c;
		}
		
		public function get relativeCoords():Boolean 
		{
			return _relativeCoords;
		}
		
		public function set relativeCoords(value:Boolean):void {
			_relativeCoords = value;
		}
	
		// SWIPE!!! [TransformGestureEvent type="gestureSwipe" bubbles=true cancelable=false phase="all" localX=470 localY=192 stageX=470 stageY=192 scaleX=1 scaleY=1 rotation=0 offsetX=1 offsetY=0 ctrlKey=false altKey=false shiftKey=false commandKey=false controlKey=false]

// 		private var _;
	}



// Handling gesture events

// There are three different kinds of gesture events: GestureEvent (from which the other two types of gesture events inherit), PressAndTapGestureEvent, and TransformGestureEvent. Below are the event types supported by each gesture event:

// GestureEvent.GESTURE_TWO_FINGER_TAP: Indicates a gesture defined by tapping with two fingers.
// PressAndTapGestureEvent.GESTURE_PRESS_AND_TAP: Indicates a gesture defined by a user touching the screen with one finger, then tapping with another. This is a Windows convention which can be used for invoking context menus.
// TransformGestureEvent.GESTURE_PAN: Indicates a gesture to pan content that may be too big to fit on a small screen.
// TransformGestureEvent.GESTURE_ROTATE: Indicates a gesture defined by two touch points rotating around each other in order to rotate content.
// TransformGestureEvent.GESTURE_SWIPE: Indicates a gesture defined by the quick movement of a touch point in order to scroll a list, delete an item from a list, etc.
// TransformGestureEvent.GESTURE_ZOOM: Indicates a gesture defined by two touch points moving either toward or away from each other to zoom content in or out.
// Gesture event properties
// The GestureEvent class has many of the same properties found in MouseEvent, but PressAndTapGestureEvent and TransformGestureEvent add several properties specific to certain types of gestures.

// PressAndTapGestureEvent contains the following properties:

// tapLocalX and tapLocalY indicating the horizontal or vertical coordinate at which the event occurred relative to the containing interactive object.
// tapStageX and tapStageY indicate the horizontal or vertical coordinate at which the tap touch occurred in global Stage coordinates.
// TransformGestureEvent contains the following properties:

// offsetX and offsetY indicate the horizontal or vertical translation of the display object since the previous gesture event.
// scaleX and scaleY indicate the horizontal or vertical scale of the display object since the previous gesture event.
// rotation indicates the current rotation angle, in degrees, of the display object along the z-axis since the previous gesture event.


/* ________________________________________________________
All AS files and libraries included in the domain com.pippoflash.*
Are open.source libraries developed by Filippo Gregoretti, and are therefore not copyrightable.
They can be used in commercial projects but must be left free for re-distribution and usage.
They go with all MovieClips included in the .fla or .xfl document, in the folders:
- PippoFlash.com - Framework

- PippoFlash.com - Components
All movieclips and assets within those folders in the source flash document (fla or xfl) 
are open source anc dan be used in commercial projects, but cannot be copyrighted.
__________________________________________________________ */