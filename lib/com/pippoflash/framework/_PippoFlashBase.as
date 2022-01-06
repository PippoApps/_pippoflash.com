/* _PippoFlashBase - (c) Filippo Gregoretti - PippoFlash.com */
/* This class is the base for ALL (non-static) SIGNLETON classes, visual or non-visual*/


package com.pippoflash.framework {
// IMPORT FLASH /////////////////////////////////////////////////////////
	import flash.geom.*; import flash.display.*; import flash.events.*;
// IMPORT PIPPOFLASH /////////////////////////////////////////////////////
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UMethod;
	import com.pippoflash.utils.UDisplay;
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.framework.interfaces.IPippoFlashBase;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public dynamic class _PippoFlashBase extends MovieClip implements IPippoFlashBase {
		// STATIC USER DEFINABLE //////////////////////////////////////////////////////
		public static var _debug:Boolean = true; // Main debug switch
		// STATIC SYSTEM 
		// STATIC REFERENCES
		// Public
		public static var _mainApp:MovieClip; // Reference to _mainApp - this should be _Application, but it would not work when this is used as a standalone plugin
		public static var _ref:*; // Reference to the relevant Ref object () - defaults to Ref(), can be expanded
		public static var _config:*; // Stores a reference to a ConfigProj instance
		static private var _mover:PFMover = new PFMover("MainMover");
		// Protected
// 		protected static var _instances				:Array = []; // Stores all instances inherited from this class as a simple list
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
		public var _debugPrefix:String; // Marks the ID of the item, good for initialization, text, and storage purposes
		//protected var _instance:Object; // This is this, but needs to be casted as Object
		protected var _pfId:String;
		protected var _listeners:Array; // List of listeners for each instance
		protected var _eventListeners:Object;
		protected var _childrenObj:Object; // This gets populated eventually with populateChildrenObj();
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function _PippoFlashBase(id:String, cl:Class=null) {
			if (_instancesById[id]) {
				Debug.error(id, "FRAMEWORK ERROR -------->>>>> This singleton class has been instantiated twice. Aborting instantiation. App will probably fail.");
				return;
			}
			/* in final class put something like this to follow OOP */
			//static public function get instance():_MainAppBase {
				//return _instance as _MainAppBase;
			//}
			//_instance = this;
			_pfId = _debugPrefix = id;
			registerInstance(this, id, cl);
			resetListeners();
			if (_mainApp && _mainApp.isInitialized()) { // This means class is instantiated AFTER mainapp is initialized. Therefore there is NO onConfig etc...
				onInstantiation();
			}
		}
		protected function onInstantiation():void {
			// Override this for instantiation of class when app is already initialized
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function registerInstance(instance:MovieClip, id:String, cl:Class=null):void {
			Debug.debug("_PippoFlashBase", "Adding Singleton Instance " + id + (cl ? " of class: " + cl : ""));
			_instances.push(instance);
			_instancesById[id] = instance;
			if (cl) addClassReference(id, cl);
		}
		public static function callOnAll(method:String, par:*=null):void {
			Debug.debug("_PippoFlashBase", "Calling on all classes:",method+"()");
			if (par) {
				for (var i:uint=0; i<_instances.length; i++) {
					UCode.callMethod(_instances[i], method, par);
				}
			}
			else {
				for (var ii:uint=0; ii<_instances.length; ii++) {
					UCode.callMethod(_instances[ii], method);
				}
			}
		}
		public static function callOn(id:String, method:String, par:*=null):void {
			// This calls a method in an instance indentified with init ID
			if (_instancesById[id]) {
				if (par) UCode.callMethod(_instancesById[id], method, par);
				else UCode.callMethod(_instancesById[id], method);
			}
			else Debug.debug("_PippoFlashBase", "Cannot find instance",id,"can't call",method+"()");
		}
		public static function setInstanceXmlVariable(node:XML):void { // Received from config as an xml variable
			var configVar:* = node.@type == "Boolean" ? UCode.isTrue(node.toString()) : configVar;
			if (_instancesById[node.@instanceId]) {
				Debug.debug(node.@instanceId, "Set XML variable " + node.@name + " (was "+_instancesById[node.@instanceId][node.@name]+") to " + node.toString());
				_instancesById[node.@instanceId][node.@name] = configVar;
				Debug.debug(node.@instanceId, "Set var to: " + _instancesById[node.@instanceId][node.@name]);
			}
			else {
				Debug.error("_PippoFlashBase", "Cannot set instance variable: " + node.toXMLString());
			}
		}
		public static function addClassReference(id:String, cl:Class):void {
			_classes[id] = cl;
		}
		public static function getClassById(id:String):Class {
			if (!_classes[id]) Debug.error("_PippoFlashBase", "Class " + id + " is not set in _classes.");
			return _classes[id];
		}
		public static function getInstanceStatic(id:String):* { // This should return ONLY _PippoFlashBase, but since instances can be added from loaded SWFs, this would trigger a conversion error
			if (_instancesById[id]) return _instancesById[id];
			else return _PippoFlashBaseNoDisplay.getInstanceStatic(id);
		}
		public static function setInstanceStatic(id:String, instance:MovieClip):void {
			_instancesById[id] = instance;
		}
		//public static function get instance():MovieClip {
			//return _instance;
		//}
// FRAMEWORK METHODS  ///////////////////////////////////////////////////////////////////////////////////////
		public static function callPippoFlashInstanceMethod(idAndMethod:String = "MainApp.methodName", pars:Array = null):void {
			Debug.debug("_PippoFlashBase", "Calling instance method: " + idAndMethod);
			var el:Array = idAndMethod.split(".");
			const instance:* = getInstanceStatic(el[0]);
			//trace(instance, el[0]);
			if (instance) {
				UMethod.callMethodNameWithParamsArray(instance, el[1], pars ? pars : []);
			} else Debug.error("_PippoFlashBase", "callPippoFlashInstanceMethod() cannot find " + idAndMethod);
		}
	// Calls a standard pippoflash method, i.e. "MainApp.quit", calls the function quit() in instance MainApp
		public function callPippoFlashMethod(method:String):* {
			Debug.debug(_debugPrefix, "Calling PippoFlash method:",method);
			var a:Array = method.split(".");
			var instance:MovieClip = getInstance(a[0]);
			UCode.callMethodAlert(instance, a[1]);
		}
		public function getPippoFlashId():String { // Returns the single static id
			return _pfId;
		}
		public var getClassId:Function = getPippoFlashId;
// UTY ///////////////////////////////////////////////////////////////////////////////////////
// OOP METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// PF INSTANCES
		public function getInstance(id:String):* { // This should return ONLY _PippoFlashBase, but since instances can be added from loaded SWFs, this would trigger a conversion error
			return getInstanceStatic(id);
		}
		public function setInstance(id:String, instance:*):void {
			_instancesById[id] = instance;
		}
		protected function setupClipsArray(a:Array, prefix:String, n:uint, targ:DisplayObjectContainer=null):void {
			// Utility that prepares local array without targeting visual elements in abstract class
			targ = targ ? targ : this;
			var c:DisplayObject;
			for (var i:uint=0; i<n; i++) {
				c = targ[prefix+String(i)];
 				if (c) a[i] = c;
				else Debug.error(_debugPrefix, "Cannot find " + prefix+String(i) + " in " + (targ ? targ : _debugPrefix)+ ". Aborting setupClipsArray().");
			}
		}
		public function callObjectMethod(o:Object):void { // This uses a standard PippoFlash object to call a method
			PippoFlashEventsMan.callMethodParams(getInstance(o.target), o.action, o.pars);
		}
		public function callInstanceMethod(instanceName:String, method:String, ...rest):void {
			PippoFlashEventsMan.callMethodParams(getInstance(instanceName), method, rest);
		}
// OOP abstract Class DisplayObjectContainer UTY ///////////////////////////////////////////////////////////////////////////////////////
		protected function populateChildrenObj():void {
			_childrenObj = UDisplay.getChildrenObj(this);
		}
		protected function getSprite(id:String):Sprite {
			return _childrenObj[id] as Sprite;
		}
		protected function getMovieClip(id:String):MovieClip {
			return _childrenObj[id] as MovieClip;
		}
		protected function getChild(id:String):DisplayObject {
			return _childrenObj[id] as DisplayObject;
		}
// EVENTS ///////////////////////////////////////////////////////////////////////////////////////
		public function resetListeners():void {
			_listeners = [];
			_eventListeners = {};
		}
		public function broadcastEvent(evt:String, ...rest):void {
			for each (_j in _listeners) UCode.broadcastEvent(_j, evt, rest);
			for each (_j in _eventListeners[evt]) UCode.broadcastEvent(_j, evt, rest);
		}
// DisplayObject SETUP ///////////////////////////////////////////////////////////////////////////////////////
		/**
		 * Sets up display object direct variable reference from Objects placed directly on stage. It does "_varName:ClassName = this["_varNameClip"]" for each object in list. WARNING: class with variables must be dynamic or this will throw an error.
		 * @param	displayObjectNames The list of variables names. Display object name must be like variable name + postfix.
		 * @param	postfix Postfix to be added to each variable name in order to retrieve DisplayObject.
		 */
		protected function setupDisplayObjectsList(displayObjectNames:Vector.<String>, postfix:String = "Clip"):void {
			/* WARNING - extension class must be dynamic or this will throw an error. Will not find property. */
			for each (var varName:String in displayObjectNames) {
				this[varName] = this[varName + postfix];
				if (!this[varName]) throw new Error("DisplayObject " + varName + postfix + " not found in " + this + " ("+this.name+")");
			}
		}
// GROUP LISTENERS MANAGEMENT //////////////////////////////////////////////////////////////////////////////////////
		public function addListener(listener:*):void {
			if (_listeners.indexOf(listener) < 0) _listeners.push(listener);
		}
		public function removeListener(listener:*):void {
			UCode.removeArrayItem(_listeners, listener);
		}
// SINGLE EVENT LISTENERS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		public function addListenerTo(evt:String, listener:*):void { // Adds a listener for a single event
			if (!_eventListeners[evt]) _eventListeners[evt] = [];
			if (_eventListeners[evt].indexOf(listener) == -1) _eventListeners[evt].push(listener);
		}
		
		static public function get mover():PFMover 
		{
			return _mover;
		}
		
		public function removeListenerTo(evt:String, listener:*):void {
			if (_eventListeners[evt]) UCode.removeArrayItem(_eventListeners[evt], listener);
		}
	}
}