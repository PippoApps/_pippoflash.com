/* Gesturizer - 1.0 - Filippo Gregoretti - www.pippoflash.com
*/
package com.pippoflash.utils {
	
	import 									flash.events.*;
	import									flash.display.*;
	import									flash.ui.*;
	import									flash.utils.getTimer;
	import									flash.utils.Dictionary;
	import									flash.geom.Rectangle;
	import									com.pippoflash.framework.interfaces.*;
	import									com.pippoflash.framework._PippoFlashBaseStatic;
	import									com.pippoflash.framework._PippoFlashBase;
	import									com.pippoflash.framework.interfaces.*;
	import									com.pippoflash.framework.PippoFlashEventsMan;
	
	public class Gesturizer extends _PippoFlashBaseStatic {
		// CONSTANTS
		private static const EVT_SWIPE				:String = "s";
		private static const EVT_PAN				:String = "p";
		public static const EVT_BR_SWIPE:String = "onSwipe"; // Called on each direction
		public static const EVT_BR_SWIPE_RIGHT		:String = "onSwipeRight";
		public static const EVT_BR_SWIPE_LEFT		:String = "onSwipeLeft";
		public static const EVT_BR_SWIPE_UP			:String = "onSwipeUp";
		public static const EVT_BR_SWIPE_DOWN		:String = "onSwipeDown";
		public static const EVT_PAN_FULL			:String = "onPan";
		public static const EVT_ZOOM				:String = "onZoom";
		// STATIC SWITCHES
		public static var _verbose					:Boolean = true;
		public static var _debugPrefix				:String = "Gesturizer";
		public static var _eventUseCapture			:Boolean = true;
		public static var _eventPriority				:uint = 20; // Same as ContentBoxTouch
		public static var _eventWeakReference			:Boolean = true;
		// NEW SYSTEM
		private static var _buttonsData				:Dictionary; // Stores data associated to an InteractiveObject
		// MARKERS
		private static var _hasGestures				:Boolean; // If gestures are available
		private static var _swipeSupported			:Boolean; // It seems that if gestures are supported, swipe is always supported
		private static var _panSupported				:Boolean;
		private static var _zoomSupported				:Boolean;
		private static var _supportedGestures			:String = ""; // Stores the list of supported gestures
		private static var _init						:Boolean = true; // Needs init
		// STATIC LISTENERS
		static private var _onGestureGeneralMethod:Function; // Broadcasted on each gesture, no matter where
		// STATIC UTY
		private static var _d						:GesturizerItem;
		private static var _l						:*;
		private static var _o						:Object;
		private static var _a						:Array;
		private static var _s						:String;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init					():Boolean { // Returns also 
			if (_init) {
				_init								= false;
				_pfId								= "Gesturizer";
				_hasGestures						= Multitouch.supportsGestureEvents && Multitouch.supportedGestures; // If no gestures are supported, Vector is null
				if (_hasGestures) {
					_supportedGestures				= Multitouch.supportedGestures.join(",");
					_swipeSupported					= _supportedGestures.indexOf("gestureSwipe") != -1;
					_panSupported					= _supportedGestures.indexOf("gesturePan") != -1;
					_zoomSupported					= _supportedGestures.indexOf("gestureZoom") != -1;
					_buttonsData					= new Dictionary(false);
					log							("Gestures available: " + _supportedGestures);
					return						true;
				}
				else {
					log							("Sorry, gestures not available.");
					return						false;
				}
			}
			return							_hasGestures;
		}
// METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////
	// GENERAL METHOD
		static public function setGeneralOnGesture(clickMethod:Function=null):void { // Sets or remove a general click method that happens at each click
			_onGestureGeneralMethod = clickMethod;
		}
	// GESTURE METHODS
		public static function hasGestures				():Boolean {
			init								();
			return							_hasGestures;
		}
		/* BE CAREFUL, DIFFERENT GESTURES MUST SHARE THE SAME LISTENER, OR LAST LISTENER SET WILL OVERWRITE PREVIOUS */
		public static function addSwipe				(c:InteractiveObject, listener:*, evts:String="L,R,U,D", postfix:String=""):void {
			init								();
			if (_hasGestures && _swipeSupported) {
				Debug.debug					(_debugPrefix, "Adding SWIPE events " + evts + " for " + c);
				_d							= getCreateItem(c, listener, postfix);
				c.addEventListener				(TransformGestureEvent.GESTURE_SWIPE, onSwipe, _eventUseCapture, _eventPriority, _eventWeakReference);
				_d.addEvent					(EVT_SWIPE, {e:evts})
			}
			else {
				Debug.error					(_debugPrefix, "SWIPE gesture cannot be applied to " + c);
			}
		}
		public static function addPan				(c:InteractiveObject, listener:*, evts:String="FULL", postfix:String=""):void { // evts can be FULL, HORIZONTAL or VERTICAL
			init								();
			if (_hasGestures && _panSupported) {
				Debug.debug					(_debugPrefix, "Adding PAN events for " + c);
				_d							= getCreateItem(c, listener, postfix);
				// Here I must add normal panning methods
				var handler					:Function = evts.charAt(0) == "F" ? onPanFull : evts.charAt(0) == "H" ? onPanFull : onPanFull;
				c.addEventListener				(TransformGestureEvent.GESTURE_PAN, handler, _eventUseCapture, _eventPriority, _eventWeakReference);
			}
			else {
				Debug.error					(_debugPrefix, "PAN gesture cannot be applied to " + c);
			}
		}
		public static function addZoom				(c:InteractiveObject, listener:*, postfix:String=""):void {
			init								();
			if (_hasGestures && _zoomSupported) {
				Debug.debug					(_debugPrefix, "Adding ZOOM events for " + c);
				_d							= getCreateItem(c, listener, postfix);
				c.addEventListener				(TransformGestureEvent.GESTURE_ZOOM, onZoom, _eventUseCapture, _eventPriority, _eventWeakReference);
			}
			else {
				Debug.error					(_debugPrefix, "ZOOM gesture cannot be applied to " + c);
			}
		}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		private static function onPanFull				(e:TransformGestureEvent):void {
			if (_verbose)						Debug.debug(_debugPrefix, "PAN"+e);
			_d								= getCreateItem(InteractiveObject(e.currentTarget)); //_buttonsData[e.target as InteractiveObject];
			if (!_d) {
				error							("GesturizerItem not found for InteractiveObject " + e.currentTarget  + " : " + _buttonsData[e.target as InteractiveObject]);
				return;
			}
			_s								= _d.postfix;
			e.stopImmediatePropagation				();
			PippoFlashEventsMan.callListenerMethodName(_d.listener, EVT_PAN_FULL, e.currentTarget, e.offsetX, e.offsetY);
			processGeneralEvent();
		}
		private static function onZoom				(e:TransformGestureEvent):void {
			if (_verbose)						Debug.debug(_debugPrefix, "ZOOM"+e);
			_d								= getCreateItem(InteractiveObject(e.currentTarget)); //_buttonsData[e.target as InteractiveObject];
			if (!_d) {
				error							("GesturizerItem not found for InteractiveObject " + e.currentTarget  + " : " + _buttonsData[e.target as InteractiveObject]);
				return;
			}
			_s								= _d.postfix;
			// Handle event
			e.stopImmediatePropagation				();
			PippoFlashEventsMan.callListenerMethodName(_d.listener, EVT_ZOOM, e.currentTarget, (e.scaleX+e.scaleY)/2);
			processGeneralEvent();
		}
		private static function onSwipe				(e:TransformGestureEvent):void {
			if (_verbose)						Debug.debug(_debugPrefix, "SWIPE"+e);
			_d								= getCreateItem(InteractiveObject(e.currentTarget)); //_buttonsData[e.target as InteractiveObject];
			if (!_d) {
				error							("GesturizerItem not found for InteractiveObject " + e.currentTarget  + " : " + _buttonsData[e.target as InteractiveObject]);
				return;
			}
			_o								= _d.getEvent(EVT_SWIPE);
			var m							:Vector.<String> = new <String>[];
			_s								= _d.postfix;
			// Add broadcast for general swipe
			m.push(EVT_BR_SWIPE+_s);
			// Check for horizontal swipe
			if (e.offsetX == 1) {
				if (_o.e.indexOf("R") != -1) {
					m.push					(EVT_BR_SWIPE_RIGHT+_s);
				}
			}
			else if (e.offsetX == -1) {
				if (_o.e.indexOf("L") != -1) {
					m.push					(EVT_BR_SWIPE_LEFT+_s);
				}
			}
			// Check for verticall swipe
			if (e.offsetY == 1) {
				if (_o.e.indexOf("D") != -1) {
					m.push					(EVT_BR_SWIPE_DOWN+_s);
				}
			}
			else if (e.offsetY == -1) {
				if (_o.e.indexOf("U") != -1) {
					m.push					(EVT_BR_SWIPE_UP+_s);
				}
			}
			// Handle event
			e.stopImmediatePropagation				();
			// Broadcast methods
			//trace("FREGNA SWIPO " + m);
			PippoFlashEventsMan.callListenerMethodNames(_d.listener, m, e.currentTarget);
			processGeneralEvent();
		}
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
		private static function getCreateItem			(c:InteractiveObject, listener:*=null, postfix:String=null):GesturizerItem {
			if (_buttonsData[c])					return _buttonsData[c];
			else {
				var d 						:GesturizerItem = new GesturizerItem(c, listener, postfix);
				_buttonsData[c]					= d;
				return						d;
			}
		}
		private static function gestureSupported		(g:String):Boolean { // If a gesture is supported
			return							_supportedGestures.indexOf(g) != -1;
			
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
	import									flash.display.*;
	import									flash.events.*;
	import									com.pippoflash.framework.interfaces.*;
	class GesturizerItem {
		private var _c							:InteractiveObject;
		private var _l							:*;
		private var _e							:Object; // Stores a reference ot data for each event
		private var _p							:String; // Stores the postfix for all events
	// INIT ////////////////////////////////////////////////////////////////////////
		public function GesturizerItem				(c:InteractiveObject, l:*, p:String):void {
			_c								= c;
			_l								= l;
			_p								= p;
			_e								= {};
		}
	// METHODS ////////////////////////////////////////////////////////////////////////
		public function addEvent					(n:String, e:Object):void {
			_e[n]							= e;
		}
		public function getEvent					(n:String):Object {
			return							_e[n];
		}
		public function get postfix					():String {
			return							_p;
		}
		public function get listener					():* {
			return							_l;
		}
	// LISTENERS ////////////////////////////////////////////////////////////////////////
		
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