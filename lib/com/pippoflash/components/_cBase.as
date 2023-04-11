/* IMPORTANT - UMem usage.
	Components decide their own id. So they are taken with: UMem.getInstanceId. They can also be taken with getInstance(Class) though...
*/

package com.pippoflash.components {
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UDisplay;
	import com.pippoflash.utils.UMem;
	import com.pippoflash.framework.interfaces.IPippoFlashEventDispatcher;
	import com.pippoflash.framework.PippoFlashEventsMan;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.setTimeout;
	
	// Ready to be updated to framework 0.44 - Be carefulò to update all components!!!!
	
	
	public class _cBase extends MovieClip implements IPippoFlashEventDispatcher {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable (name="_cBase - ID for Group Commands", type=String, defaultValue="")]
		public function set _cBase_set_classGroup(s:String):void {
			if (s) addInstanceToGroup(s);
		}
		[Inspectable (name="_cBase - Automatic Listener", type=String, defaultValue="NONE", enumeration="NONE,stage,root,parent")]
		public function set _cBase_set_autoListener(s:String):void {
			if (s != "NONE") addListener(this[s]);
		}
		[Inspectable (name="_cBase - Events postfix", type=String, defaultValue="")]
		public function set _cBase_set_eventPostfix(s:String):void {
			_cBase_eventPostfix = s;
		}
		[Inspectable 							(name="_cBase - _parameter1", type=String)]
		public var _parameter1						:String;
		[Inspectable 							(name="_cBase - Link to mask class", type=String)]
		public var _maskLink						:String;
		[Inspectable 							(name="_cBase - Do not init?", type=Boolean, defaultValue=false)]
		public var _cBase_doNotInit					:Boolean = false;
		[Inspectable 							(name="_cBase - Add instance name to debug", type=Boolean, defaultValue=false)]
		public var _cBase_addName					:Boolean = false;
// VARIABLES ///////////////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		private static const BOX_NAME:String = "_cBase_extended_boundingBox";
		public static var _verbose:Boolean = true;
		// FRAMEWORK
		protected static var _config:*;
		protected static var _mainApp:*;
		protected static var _ref:*;
		// STATIC
		protected static var _statuses:Array = ["Startup","Initialized","Ready to recycle","Ready to render","Rendered"];	
		protected static var _defaults:Object;
		// SYSTEM
		public var _w:int; // The registered user width
		public var _h:int; // The registered user height
		protected var _debugPrefix:String = "_cBase";
		protected var _cBase_listenersList:Array = []; // The list of listeners
		public var _cBase_eventPostfix:String = ""; // The string to add in the end of events broadcasted (onPress = onPress[postfix])
		protected var _cBase_groupId:String = null;
		protected static var _cBase_classGroupsList:Array = []; // The group of instances who the object belongs
		private var _boundingBox:DisplayObject;
		// MARKERS
		protected var _cBase_initNow:Boolean;
		protected var _cStatus:uint = 0; // status of the component: 0 startup, 1 initialized, 2 received variables (ready to recycle), 3 ready to render, 4 rendered.... 
		// REFERENCES
		// UTY 
		protected static var _i:uint;
		protected static var _s:String;
		protected static var _a:Array;
		protected static var _o:Object;
		protected static var _n:Number;
		protected static var _b:Boolean;
		protected static var _c:MovieClip;
		protected static var _clip:*;
		protected static var _j:*;
		protected static var _counter:int = 0;
		protected static var _t:TextField;
		protected static var _node:XML;
// INIT ONCE /////////////////////////////////////////////////////////////////////////////////////////
		// Initialization here happens only on first component instantiation
		public function _cBase(id:String="", par:Object=null) {
			stop();
			_debugPrefix = id;
			if (this.hasOwnProperty(BOX_NAME)) _boundingBox = this[BOX_NAME];
// 			if (!UMem.hasClassId(id))				UMem.addManagedClass(id, UCode.getClassFromInstance(this));
			if (par) { // This means I am instantiated by actionscript, and not on stage, so I do not have to wait to grab component parameters and I can init right away
				_cBase_initNow = true;
			}
			initOnce(par);
		}
		private function initOnce(par:Object=null):void { // This initialization has to be done ONLY once, and IMMEDIATELY. Only here, in base
			UDisplay.roundPosition(this);
			UDisplay.roundSize(this);
			if (par) UCode.setParameters(this, par);
			init();
			// If parameters are present, I have initialized with actionscript, therefore I have all variables and can proceed to initialize. Otherwise, I have to wait to retrieve component parameters.
			checkForInit(par);
		}
		protected function init():void {
			// This can be overridden. Its called automatically at the beginning of the initialization process.
			// When overridden, super.init() has to be called FIRST.
			//trace("FREGNAAAAAAAAAAAAAA",width);
			initDimensions();
			_cStatus = 1;
			//trace("FREGNAAAAAAAAAAAAAA",width);
		}
			protected function initDimensions():void {
				_n = rotation;
				rotation = 0;
				_w = width = Math.round(width);
				_h = height = Math.round(height);
				x = Math.round(x);
				y = Math.round(y);
				scaleY = scaleX = 1;
				if (_boundingBox) { // This is needed in order to not mess up with sizes in code containing components
					_boundingBox.width = _w;
					_boundingBox.height = _h;
					_boundingBox = null;
				}
				rotation = _n;
			}
			private function checkForInit(par:Object=null):void {
				if (par) {
					initAfterVariables();
				}
				else {
					setTimeout(initAfterVariables, 1);
				}
			}
		protected function initAfterVariables():void { // This can be overridden. No need to be called. It gets called automatically depending on how I have been instantiated. Should be called last in the override.
			// This is launched ONLY ONCE - On the first and unique initialization
			_cStatus = 2;
			if (_cBase_addName) _debugPrefix += " - " + name;
			initialize();
		}
// INIT FROM FRAMEWORK ///////////////////////////////////////////////////////////////////////////////////////
		protected function onMainApp():void {
			// Called when _mainApp reference is defined NOT WHEN APPLICATION STARTS
		}
		protected function onConfig ():void {
			// Called when config is defined
		}
		protected function onRef ():void {
			// Called when reference is defined
		}
		protected function onApplicationStart ():void {
			// Called when startApplication is called on _Application
		}
// INIT and RE-INIT ///////////////////////////////////////////////////////////////////////////////////////
		protected function initialize ():void { // This is called EVERY TIME the component is initialized. It suppose a full re-rendering. Its called automatically on recycle.
			// This is launched EVERY TIME THE OCMPONENT IS USED OR RE-USED
			// It can be called super, after other things happen
			if (!isRecycled()) Debug.debug(_debugPrefix, "WARNING, initialize() is called but component is in status:",getStatus());
			_cStatus = 3;
			if (mask) { // Create and apply mask
				UDisplay.removeClip (mask);
				mask = null;
			}
			if (_maskLink) {
				mask = UDisplay.addChild(this, UCode.getInstance(_maskLink), {width:_w, height:_h});
			}
		}
// UPDATE ///////////////////////////////////////////////////////////////////////////////////////
		public function update(par:Object):void { // This is overridable, it means that we are updating cmponent on programmatically set values
			// This can update an already initialized or rendered component
			// This works similarly to recycle, but doesnt simulate instantiation. 
			UCode.setParametersForced(this, par);
			// In this baseclass I only init the references to width and height
			if (par.width || par.height) {
				initDimensions();
				if (par.width) _w = par.width;
				if (par.height) _h = par.height;
			}
		}
		public function resize(w:Number, h:Number):void {
			// This one only resizes component. Rendered or not, this has to work to resize it.
			// If this is not overridden, it will only change the values in memoryt, but nothing happens.
			_w = Math.round(w);
			_h = Math.round(h);
		}
		public function resizeH(h:Number):void { // This is just a shortcut, then calls resize();
			resize(_w, h);
		}
		public function resizeW(w:Number):void { // This is just a shortcut, then calls resize();
			resize(w, _h);
		}
		protected function complete():void { // Sets the component in rendered state
			_cStatus = 4;
		}
// RECYCLE ///////////////////////////////////////////////////////////////////////////////////////		
		public function release():void {
			// This is called to undo a render operation, and make the component ready again to render content
			_cStatus = 3;
		}
		public function cleanup():void {
			// This is called before a re-rendering of the component. It frees as much memory as possible, and leaves the component ready for another go.
			// This is called by UMem, once the component is stored for later use.
// 			resetDefaults						();
			release();
			_cStatus = 2;
		}
		public function recycle(par:Object=null):void { // this works like a virgin initialization
			// It need to have cleanup() called before
			update(par);
			initialize();
		}
// DISPOSE ///////////////////////////////////////////////////////////////////////////////////////
		public function harakiri():void {
			// This is destructive. Cleans up all memory. After this, object may not be re-usable.
			// This is used to completely free memory from used component.
			_cStatus = 0;
		}
// LISTENERS MANAGEMENT /////////////////////////////////////////////////////////////////////////
		public function addListener(listener:Object):void {
			// Adds a listener to the listener's chain
			for (var i:Number=0; i<_cBase_listenersList.length; i++) {
				if (_cBase_listenersList[i] == listener) return;
			}
			_cBase_listenersList.push(listener);
		}
		public function removeListener(listener:Object):void {
			// Remove a listener from the listener's chain
			for (var i:Number=0; i<_cBase_listenersList.length; i++) {
				if (_cBase_listenersList[i] == listener) {
					_cBase_listenersList.splice(i, 1);
					return;
				};
			}
		}
		public function removeAllListeners():void {
			_cBase_listenersList = new Array();
		}
		public function broadcastEvent(event:String, ... par):void {
			if (!_cBase_listenersList.length) return; // No listeners
			event += _cBase_eventPostfix;
			for (var i:Number=0; i<_cBase_listenersList.length; i++) {
				UCode.broadcastEvent(_cBase_listenersList[i], event, par);
			}
		}
		protected function broadcastEventNoisy(event:String, ... par):void {
			Debug.debug(_debugPrefix, "Broadcasting event: ", event, par);
			event += _cBase_eventPostfix;
			for (var i:Number=0; i<_cBase_listenersList.length; i++) {
				UCode.broadcastEvent(_cBase_listenersList[i], event, par);
			}
		}
		//public function callPrivateEvent(evt:String, pars:Array):Boolean {
			//// In order for this to work, this must be implemented in extensions
			//return pars.length ? PippoFlashEventsMan.callListenerMethodName(this, evt, pars) : PippoFlashEventsMan.callListenerMethodName(this, evt);
		//}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		public function getStatus():String {
			return _statuses[_cStatus];
		}
		public function isStartup():Boolean {
			return _cStatus == 0;
		}
		public function isInitialized():Boolean {
			return _cStatus == 1;
		}
		public function isRecycled():Boolean {
			return _cStatus == 2;
		}
		public function isReady():Boolean { // Ready to be rendered
			return _cStatus == 3;
		}
		public function isRendered():Boolean { // Rendered - Occupied with data and working
			return _cStatus == 4;
		}
		public function traceDebug():void {
			trace(_debugPrefix+">--------------------------------<DEBUG>-----------------");
			trace(name,_w,_h,width,height);
		}
		public function setVariables(par:Object):void {
			for (var s:String in par) this[s] = par[s];
		}
		public function setVariable(n:String, v:*):void {
			this[n] = v;
		}
		public static function setStaticVariables(obj:*, par:Object):void {
			var thisClass:Class = Object(obj).constructor as Class;
			for each (var s:String in par) thisClass[s] = par[s];
		}
// INTERNAL UTILITIES ///////////////////////////////////////////////////////////////////////////////////////
		protected function setAutoPost(id:String):void {
			// This sets the automatic post function based on instance name. If id is not good, nothing happens
			if (name.indexOf(id) == 0) _cBase_eventPostfix = name.substr(id.length);
		}
// GROUPS MANAGEMENT //////////////////////////////////////////////////////////////////////////
		public function addInstanceToGroup(g:String):void {
			if (_cBase_classGroupsList[g] == undefined) _cBase_classGroupsList[g] = new Array();
			_cBase_classGroupsList[g].push(this);
			_cBase_groupId = g;
		}
		public function callGroupMethod(group:String, method:String, ...rest):void {
			_a = _cBase_classGroupsList[group];
			_i = _a.length;
			for (var i:Number=0; i<_i; i++) {
				UCode.broadcastEvent(_a[i], method, rest);
			}
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function callInstancesGroupMethod(g:String, method:String, ...rest):void {
			var a:Array = _cBase_classGroupsList[g];
			for (var i:uint=0; i<a.length; i++) {
				UCode.broadcastEvent(a[i], method, rest);
			}
		}
		public static function setMainApp(mainApp:*):void {
			_mainApp = mainApp;
		}
		public static function setConfig(config:*):void {
			_config = config;
		}
		public static function setRef(ref:*):void {
			_ref = ref;
		}
	}
}
































