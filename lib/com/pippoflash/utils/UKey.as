/* KeyUtils - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
0.1 - 12 dec 2009

Default listener object: {l:Listener, s:Array, p:String};
	s - sequence of keys: ["CTRL","C","O"] - Means you have to press CTRL C and O. Sequences MUST be the same letter as in Keiboard Class
	
addListener(obj);
	Calls onKeyPress(keyboardEvent) on obj.
	
addSequenceListener(obj, ["C", "CONTROL"], "CtrlC");
	Calls onKeyPressCtrlC() on obj.
	
	
USING CONTROL IN A SEQUENCE BOTHERS!!!! - I HAVE TO DEBUG THIS!!!!	
	
	
*/

package com.pippoflash.utils {

	import									flash.ui.Keyboard;
	import									flash.display.*;
	import									flash.events.*;
	import									flash.utils.*;
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.UGlobal;
	
	public class UKey {
		public static const _debugPrefix				:String = "UKey";
		public static var _listeners					:Array = new Array(); // this contains direct references to listeners
		public static var _sequenceListeners			:Dictionary = new Dictionary(true); // this contains vectors with strings related to postfix for each listener
		public static var _initFunction				:Function = firstTimeInit;
		public static var _pressedKeys				:Array = new Array(); // Stores true or false for each keycode pressed
		// UTY
		public static var _list;						// Reference to a listener
		public static var _i						:int;
		public static var _s						:String;
		public static var _o						:Object;
		public static var _j;
		public static var _b						:Boolean;
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		
// DUMMIES //////////////////////////////////////////////////////////////////////////////
// GENERAL //////////////////////////////////////////////////////////////////////////////
		private static function firstTimeInit				() {
			_initFunction						= UCode.dummyFunction;
			setActive							(true);
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function reset					() {
			_listeners							= new Array();
			_sequenceListeners					= new Dictionary(true);
			setActive							(false);
			_pressedKeys						= new Array();
		}
		public static function setActive				(a:Boolean) {
			setKeyListenerActive					(a);
		}
		public static function addListener				(list:*) {
			_initFunction						();
			_listeners.push						(list);
		}
		public static function removeListener			(list:*) {
			_i								= _listeners.indexOf(list);
			if (_i > -1)							_listeners.splice(_i, 1);
		}
		public static function addSequenceListener		(list:*, seq:Array, post:String) {
			_initFunction						();
			// Triggers onSeqPress[post]() when sequence defined in array is launched
			var o								:Object = {l:list, p:post, s:new Array()};
			for each (_s in seq)					o.s.push(_s.length == 1 ? _s.charCodeAt(0) : Keyboard[_s]);
			// Sequence may contain keyvcode, or special character
			if (!_sequenceListeners[list])			_sequenceListeners[list] = {};
			_sequenceListeners[list][post] 			= o;
		}
		public static function removeSequenceListener	(list:*, post:String=null) {
			if (_sequenceListeners[list]) { 
				if (post) { // I can delete a single post sequence, or the entire listener
					delete					_sequenceListeners[list][post];
				}
				else {
					delete					_sequenceListeners[list];
				}
			}
		}
// KEYBOARD LISTENING ////////////////////////////////////////////////////////////////////////////////
		public static function setKeyListenerActive		(a:Boolean) {
			if (a)	{
				UGlobal.stage.addEventListener		(KeyboardEvent.KEY_DOWN, onPippoFlashKeyDown);
				UGlobal.stage.addEventListener		(KeyboardEvent.KEY_UP, onPippoFlashKeyUp);
			}
			else	{
				UGlobal.stage.removeEventListener	(KeyboardEvent.KEY_DOWN, onPippoFlashKeyDown);
				UGlobal.stage.removeEventListener	(KeyboardEvent.KEY_UP, onPippoFlashKeyUp);
			}
		}
		public static function onPippoFlashKeyDown		(e:KeyboardEvent) {
			_pressedKeys[e.keyCode]				= true;
			for each (_list in _listeners)				UCode.callMethod(_list, "onKeyPress", e);
			// CHECK FOR SEQUENCE LISTENERS
			for each (_o in _sequenceListeners) { // Loop in all objects
				// Loop in all posts
				for (_s in _o) {
					if (sequenceIsPressed(_o[_s].s))	UCode.callMethod(_o[_s].l, "onKeyPress"+_o[_s].p);
				}
			}
		}
		public static function sequenceIsPressed		(s:Array):Boolean {
			for each (_j in s) {
				if (!_pressedKeys[_j])				return false;
			}
			return							true;
		}
		public static function onPippoFlashKeyUp			(e:KeyboardEvent) {
			_pressedKeys[e.keyCode]				= false;
		}
// KEY CODES ///////////////////////////////////////////////////////////////////////////////////////		
		public static function isReturn				(e:KeyboardEvent) {
			return							e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.NUMPAD_ENTER;
		}
		public static function isEsc					(e:KeyboardEvent) {
			return							e.keyCode == 27;
		}
		public static function isTab					(e:KeyboardEvent) {
			return							e.keyCode == 9;
		}
// GARBAGE COLLECTION ///////////////////////////////////////////////////////////////////////////////
	}
}

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