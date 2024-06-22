/* _PippoFlashBaseNoDisplay - (c) Filippo Gregoretti - PippoFlash.com */
/* This class is the base for ALL (non-static) SIGNLETON classes, visual or non-visual*/


package com.pippoflash.framework {
// IMPORT FLASH /////////////////////////////////////////////////////////
	import flash.geom.*; import flash.display.*; import flash.events.*;
// IMPORT PIPPOFLASH /////////////////////////////////////////////////////
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.framework.interfaces.IPippoFlashBase;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public dynamic class _PippoFlashBaseNoDisplay implements IPippoFlashBase {
		// STATIC USER DEFINABLE //////////////////////////////////////////////////////
		public static var _debug:Boolean = true; // Main debug switch
		private var _verbose:Boolean = true;
		// STATIC SYSTEM 
		// STATIC REFERENCES
		// Public
		public static var _mainApp:_PippoFlashBase; // Reference to _mainApp - this should be _Application, but it would not work when this is used as a standalone plugin
		// public static var _mainApp					:_Application; // Reference to _mainApp
		public static var _ref:*; // Reference to the relevant Ref object () - defaults to Ref(), can be expanded
		public static var _config:*; // Stores a reference to a ConfigProj instance
		// Protected
		protected static var _instances:Array = []; // Stores all instances inherited from this class as a simple list
		protected static var _instancesById:Object = {}; // Stores intances by _configId
		protected static var _classes:Object = {}; // This has to be configured by extrended class using reference to the class
		// UTY - STATIC
		protected static var _b:Boolean;
		protected static var _xml:XML;
		protected static var _clip:MovieClip;
		protected static var _c:MovieClip;
		protected static var _sprite:Sprite;
		protected static var _counter:int = 0;
		protected static var _o:Object;
		protected static var _a:Array;
		protected static var _n:Number;
		protected static var _i:int;
		protected static var _s:String;
		protected static var _point:Point;
		protected static var _j:*;
		// DYNAMIC SYSTEM
		public var _debugPrefix:String = "_PippoFlashBase"; // Marks the ID of the item, good for initialization, text, and storage purposes
		protected var _pfId:String = "_PippoFlashBase";
		//protected var _listeners					:Array; // List of listeners for each instance
		//protected var _eventListeners				:Object;
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function _PippoFlashBaseNoDisplay(id:String, cl:Class=null) {
			_pfId = _debugPrefix = id;
			if (cl) addClassReference(id, cl);
			_instances.push(this);
			_instancesById[_debugPrefix] = this;
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function callOnAll(method:String, par:*=null):void {
			Debug.debug("_PippoFlashBaseNoDisplay", "Calling on all classes:",method+"()");
			// This calls on all instances one method with one parameter
// 			trace("CHIAMO SU TUTTIIIIIIIIIIIIIIIII",method,_instances);
// 			for each (var instance:_PippoFlashBase in _instances) {
// 				trace("proviamo se " + instance + " ha il metodo " + method + " : " + instance.hasOwnProperty(method));
// 			}
			if (par)							UCode.callMethodList(_instances, method, par);
			else								UCode.callMethodList(_instances, method);
		}
		public static function callOn				(id:String, method:String, par:*=null):void {
			// This calls a method in an instance indentified with init ID
			if (_instancesById[id]) {
				if (par)						UCode.callMethod(_instancesById[id], method, par);
				else							UCode.callMethod(_instancesById[id], method);
			}
			else								Debug.debug("_PippoFlashBase", "Cannot find instance",id,"can't call",method+"()");
		}
		public static function setInstanceXmlVariable		(node:XML):void { // Received from config as an xml variable
			var configVar						:* = node.@type == "Boolean" ? UCode.isTrue(node.toString()) : configVar;
			if (_instancesById[node.@instanceId]) {
				Debug.debug					(node.@instanceId, "Set XML variable " + node.@name + " (was "+_instancesById[node.@instanceId][node.@name]+") to " + node.toString());
				_instancesById[node.@instanceId][node.@name] = configVar;
				Debug.debug					(node.@instanceId, "Set var to: " + _instancesById[node.@instanceId][node.@name]);
			}
			else {
				Debug.error					("_PippoFlashBase", "Cannot set instance variable: " + node.toXMLString());
			}
		}
		public static function addClassReference		(id:String, cl:Class):void {
			_classes[id]						= cl;
		}
		public static function getClassById			(id:String):Class {
			if (!_classes[id])					Debug.error("_PippoFlashBase", "Class " + id + " is not set in _classes.");
			return							_classes[id];
		}
		public static function getInstanceStatic(id:String):* {
			return _instancesById[id];
		}
// FRAMEWORK METHODS  ///////////////////////////////////////////////////////////////////////////////////////
	// Calls a standard pippoflash method, i.e. "MainApp.quit", calls the function quit() in instance MainApp
		public function callPippoFlashMethod			(method:String):* {
			Debug.debug						(_debugPrefix, "Calling PippoFlash method:",method);
			var a							:Array = method.split(".");
			var instance						:_PippoFlashBase = getInstance(a[0]);
			UCode.callMethodAlert				(instance, a[1]);
		}
		public function getPippoFlashId				():String { // Returns the single static id
			return							_debugPrefix;
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
// OOP METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function getInstance(id:String):* {
			return _PippoFlashBase.getInstanceStatic(id);
		}
		
		public function get verbose():Boolean {
			return _verbose;
		}
		
		public function set verbose(value:Boolean):void {
			_verbose = value;
		}
		//public function callPrivateEvent				(mn:String, pars:Array):Boolean {
			//if (Boolean(this[mn])) {
				//if (pars.length == 1)				this[mn](pars[0]);
				//else if (pars.length == 0)			this[mn]();
				//else if (pars.length == 2)			this[mn](pars[0], pars[1]);
				//else if (pars.length == 3)			this[mn](pars[0], pars[1], pars[2]);
				//else if (pars.length == 4)			this[mn](pars[0], pars[1], pars[2], pars[3]);
				//else {
					//Debug.error			(_pfId, "Received event with more than maximum allowed 4 params. Calling it with 4.");
					//this[mn](pars[0], pars[1], pars[2], pars[3]);
				//}
				//return						true;
			//}
			//return							false;
		//}
// EVENTS ///////////////////////////////////////////////////////////////////////////////////////
		//public function resetListeners				():void {
			//_listeners							= [];
			//_eventListeners						= {};
		//}
		//public function broadcastEvent				(evt:String, ...rest):void {
			//for each (_j in _listeners)				UCode.broadcastEvent(_j, evt, rest);
			//for each (_j in _eventListeners[evt])		UCode.broadcastEvent(_j, evt, rest);
		//}
// GROUP LISTENERS MANAGEMENT //////////////////////////////////////////////////////////////////////////////////////
		//public function addListener					(listener:*):void {
			//if (_listeners.indexOf(listener) < 0)			_listeners.push(listener);
		//}
		//public function removeListener				(listener:*):void {
			//UCode.removeArrayItem				(_listeners, listener);
		//}
// SINGLE EVENT LISTENERS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		//public function addListenerTo				(evt:String, listener:*):void { // Adds a listener for a single event
			//if (!_eventListeners[evt])				_eventListeners[evt] = [];
			//if (_eventListeners[evt].indexOf(listener) == -1) _eventListeners[evt].push(listener);
		//}
		//public function removeListenerTo				(evt:String, listener:*):void {
			//if (_eventListeners[evt]) 				UCode.removeArrayItem(_eventListeners[evt], listener);
		//}
	}
}