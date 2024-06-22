/* _PippoFlashBasePlugin - (c) Filippo Gregoretti - PippoFlash.com */
/* This class is the base for ALL (non-static) SIGNLETON classes, visual or non-visual*/


package com.pippoflash.framework.plugin {
// IMPORT FLASH /////////////////////////////////////////////////////////
	import flash.geom.*; import flash.display.*; import flash.events.*;
// IMPORT PIPPOFLASH /////////////////////////////////////////////////////
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UMethod;
	import com.pippoflash.utils.UDisplay;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework._PippoFlashBase;
	
	import com.pippoflash.framework.interfaces.IPippoFlashBase;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public dynamic class _PippoFlashBasePlugin extends MovieClip implements IPippoFlashBase {
		// STATIC USER DEFINABLE //////////////////////////////////////////////////////
		public static var _debug:Boolean = true; // Main debug switch
		// STATIC SYSTEM 
		// STATIC REFERENCES
		// Public
		public static var _mainApp:*; // Reference to _mainApp - this should be _Application, but it would not work when this is used as a standalone plugin
		public static var _ref:*; // Reference to the relevant Ref object () - defaults to Ref(), can be expanded
		public static var _config:*; // Stores a reference to a ConfigProj instance
		//public static var _idPrefix:String=""; // This is retrieved by 
		// Following references are used only for plugin. getInstance though returns all _PippoFlashBase tunneled things.
		protected static var _instance:MovieClip;
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
		protected var _pfId:String;
		protected var _listeners:Array; // List of listeners for each instance
		protected var _eventListeners:Object;
		protected var _childrenObj:Object; // This gets populated eventually with populateChildrenObj();
// INIT //////////////////////////////////////////////////////////////////////////////////////////
			
			
			
			
			
			
			
			
			
		public function _PippoFlashBasePlugin(id:String, cl:Class = null) {
			// Modify immediately creation ID
			//id = _Application.instance.getPippoFlashId() + id;
			// Check for singleton error
			if (getInstanceStatic(id)) {
				Debug.error(id, "FRAMEWORK ERROR -------->>>>> This singleton class has been instantiated twice. Aborting instantiation. App will probably fail.");
				return;
			}
			_instance = this;
			_pfId = _debugPrefix = id;
			registerInstance(this, id, cl); // This tunnel to _PippoFlashBase one with plugin app id as prefix
			resetListeners();
			if (_mainApp && _mainApp.isInitialized()) { // This means class is instantiated AFTER mainapp is initialized. Therefore there is NO onConfig etc...
				onInstantiation();
			}
		}
		protected function onInstantiation():void {
			// Override this for instantiation of class when app is already initialized
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// NMost of these static methods rely on the same static methods in _PippoFlashBase
		static public function registerInstance(instance:MovieClip, id:String, cl:Class=null):void {
			_PippoFlashBase.registerInstance(instance, id, cl);
		}
		// callOnAll calls ONLY on 
		public static function callOnAll(method:String, par:*= null):void {
			_PippoFlashBase.callOnAll(method, par);
		}
		public static function callOn(id:String, method:String, par:*= null):void {
			_PippoFlashBase.callOn(id, method, par);
		}
		public static function setInstanceXmlVariable(node:XML):void { // Received from config as an xml variable
			_PippoFlashBase.setInstanceXmlVariable(node);
		}
		public static function getInstanceStatic(id:String):* { // This should return ONLY _PippoFlashBase, but since instances can be added from loaded SWFs, this would trigger a conversion error
			return _PippoFlashBase.getInstanceStatic(id);
		}
		public static function setInstanceStatic(id:String, instance:*):void {
			_PippoFlashBase.setInstanceStatic(id, instance);
		}
		public static function get instance():MovieClip {
			return _instance;
		}
// FRAMEWORK METHODS  ///////////////////////////////////////////////////////////////////////////////////////
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
		public function getInstance(id:String):MovieClip { // This should return ONLY _PippoFlashBase, but since instances can be added from loaded SWFs, this would trigger a conversion error
			return _PippoFlashBase.getInstanceStatic(id);
		}
		public function setInstance(id:String, instance:*):void {
			setInstanceStatic(id, instance);
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
		public function removeListenerTo(evt:String, listener:*):void {
			if (_eventListeners[evt]) UCode.removeArrayItem(_eventListeners[evt], listener);
		}
	}
}