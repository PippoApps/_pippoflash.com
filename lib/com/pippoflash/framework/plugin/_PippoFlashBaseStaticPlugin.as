/* _PippoFlashBaseStatic - (c) Filippo Gregoretti - PippoFlash.com */
/* This class is the base for ALL STATIC PippoFlash framework classes */


package com.pippoflash.framework.plugin {
// IMPORT FLASH /////////////////////////////////////////////////////////
	import flash.geom.*; import flash.display.*; import flash.events.*;
// IMPORT PIPPOFLASH /////////////////////////////////////////////////////
	import com.pippoflash.utils.*; import com.pippoflash.framework.interfaces.IPippoFlashEventDispatcher;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public class _PippoFlashBaseStaticPlugin implements IPippoFlashEventDispatcher {
		// STATIC USER DEFINABLE //////////////////////////////////////////////////////
		protected static var _mainApp				:*; // Reference to _mainApp - this should be _Application, but it would not work when this is used as a standalone plugin
		protected static var _ref					:*; // Reference to the relevant Ref object () - defaults to Ref(), can be expanded
		protected static var _config					:*; // Stores a reference to a ConfigProj instance
		// SYSTEM
		protected static var _pfId					:String = "_PippoFlashBaseStaticPlugin";
		protected static var _debugPrefix				:String = "_PippoFlashBaseStaticPlugin";
		// STATIC UTY
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function _PippoFlashBaseStaticPlugin(id:String=null) {
// 			Debug.error						(id, "Instantiation of _PippoFlashBaseStatic not allowed!!!!! : ", id);
		}
	// ADD METHODS TO RESPECT INTERFACES
		public function callPrivateEvent				(m:String, p:Array):Boolean {
			// THIS IS HERE ONLY TO FOOL INTERFACES
			return							false;
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		protected static function log					(...rest):void {
			Debug.debug						(_pfId, rest.join(" "));						
		}
		protected static function error				(...rest):void {
			Debug.error						(_pfId, rest.join(" "));						
		}
		protected static function setId				(id:String):void {
			_pfId = _debugPrefix					= id; 
		}
// EVENTS ///////////////////////////////////////////////////////////////////////////////////////
// 		public function resetListeners				():void {
// 			_listeners							= [];
// 			_eventListeners						= {};
// 		}
// 		public function broadcastEvent				(evt:String, ...rest):void {
// 			// events will be broadcasted with internal caller, so that also private functions can be added
// 			for each (_pf in _listeners)				UCode.broadcastEvent(_j, evt, rest);
// 			for each (_pf in _eventListeners[evt])		UCode.broadcastEvent(_j, evt, rest);
// 		}
// GROUP LISTENERS MANAGEMENT //////////////////////////////////////////////////////////////////////////////////////
// 		public static function addListener				(listener:*):void {
// 			if (_listeners.indexOf(listener) < 0)		_listeners.push(listener);
// 		}
// 		public static function removeListener			(listener:*):void {
// 			UCode.removeArrayItem				(_listeners, listener);
// 		}
// SINGLE EVENT LISTENERS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
// 		public function addListenerTo				(evt:String, listener:*):void { // Adds a listener for a single event
// 			if (!_eventListeners[evt])				_eventListeners[evt] = [];
// 			if (_eventListeners[evt].indexOf(listener) == -1) _eventListeners[evt].push(listener);
// 		}
// 		public function removeListenerTo				(evt:String, listener:*):void {
// 			if (_eventListeners[evt]) 				UCode.removeArrayItem(_eventListeners[evt], listener);
// 		}
	}
}