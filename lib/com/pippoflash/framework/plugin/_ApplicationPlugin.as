/* _Plugin - Provides base functionalities for all simple plugins */

package com.pippoflash.framework.plugin {
	import com.pippoflash.framework._Application;
	import com.pippoflash.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.profiler.*;
	// Plugins are ALWAYS SWF files, therefore do not need to externd _ApplicationAir
	public dynamic class _ApplicationPlugin extends _Application {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// SETUP CONSTANTS TO BE MODIFIED IN MAINAPP
// 		protected var _plugin						:*;
// 		protected var _hostApp					:*; // Link to the host _mainApp
		// NON-STATIC SWITCHES - MODIFIABLE VIA CONFIG - SET IN MAINAPP (DEFAULTS ONLY HERE)
		// USER VARIABLES
 		protected var _pluginId:String;
		protected var _pluginVersion:String;
		// HTML VARIABLES - FLASHVARS HAVE TO BE PUBLIC
		// REFERENCES
		protected var _parentApp:MovieClip; // This is the parent app that holds me
		//protected var _pluginApp:_ApplicationPlugin; // This is a reference to THIS
// 		protected var _ref						:*; // Overwritten by host
// 		protected var _mainApp					:*; // Overwritten by host
		// STAGE INSTANCES
		// REFERENCE LISTS
		// MARKERS
		protected var _standAlone:Boolean = true; // By default is standalone. It becomes not standalone when initAsExternalPlugin is called.
		protected var _active:Boolean; // Marks if plugin is active and visible, of it is idle
		protected var _isReady:Boolean; // Marks if the plugin has already been initialized
		// DATA HOLDERS
		// STATIC UTY
		// FRAMEWORK
// 		protected var _uSound					:USound; // Reference to the container USound class
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function _ApplicationPlugin(id:String = "_ApplicationPlugin", appId:String="Name of Application", ver:String = "0.0.0"):void {
			super(id, appId, ver);
			// Proceed registering
			Debug.debug(_debugPrefix, "Initializing Plugin", id,ver);
			//UGlobal.registerNewPlugin(id, this);
			_pluginVersion = ver;
			_pluginId = id;
			//_plugin = this;
			visible = false;
			// Setup references for plugin stuff. These DO NOT EXTEND PippoFlashBase, therefore they hold their own references.
			_PippoFlashBaseNoDisplayPlugin._mainApp = this;
			_PippoFlashBaseNoDisplayUMemPlugin._mainApp = this;
			_PippoFlashBasePlugin._mainApp = this;
			_PippoFlashBaseUMemPlugin._mainApp = this;
			// Setup application name prefix
			//_PippoFlashBasePlugin._idPrefix = id; // This ID is used in _PippoFlashBase  as prefix for
		}
		public function setAsExternalPlugin(hostApp:MovieClip):void {
			Debug.debug(_debugPrefix, "Setting plugin interface as production external plugin...");
			_parentApp = hostApp;
			_standAlone = false;
			DEPLOY = true;
			DEBUG = false;
		}
		public static function get instance():_Application { // Returns the static reference stored in plugin base
			return _PippoFlashBasePlugin._mainApp;
		}
		//override public function getInstance(id:String):* { // This is a plugin. Application is an instance of PippoFlashBase, but all plugin elements are instances of _PippoFlashBasePlugin.
			//// Prompts and other things end up in general _PippoFlashBase instances list
			//var instance:* = super.getInstance(id);
			//if (instance) return instance;
			//else return _PippoFlashBasePlugin.getInstanceStatic(id);
		//}
		//override protected function initOnStage(e:Event = null):void {
			//super.initOnStage(e);
		//}
		//protected function initOnStage(e:Event=null):void { // Once stage is available to application, this initialization is performed
			//_standAlone						= parent == stage;
// 			_mainApp							= this;
// 			_config							= {};
// 			_PippoFlashBaseUMemPlugin._config		= _config;
// 			_PippoFlashBaseUMemPlugin._mainApp	= _mainApp;
			//if (_standAlone)					UExec.next(initStandAlone);
			//else								UExec.next(initPlugin);
		//}
		// The init functions, are used before registration, only on stage
			// Called after stage ONLY in stand-alone mode
			//protected function initStandAlone():void {
				//Debug.debug(_debugPrefix, "Initializing in StandAlone...");
				//_mainApp = this;
				//_config = {};
				//initCommon();
				//UGlobal.addResizeListener		(onResize);
				//_uGlobal						= UGlobal;
				//Debug.debug					(_debugPrefix, "Initializing in Stand-Alone mode...");
				//startPluginStandalone			();
			//}
			// Called as initialization when stage is available, still waiting for registration in host application
			// Initialization common for both standalone and plugin
	// The initOn funcions, are collOnAll and are called after registration
		// Called with callOnAll on stand alone initialization
		//public function initOnStandAlone			():void {
			//Debug.debug						(_debugPrefix, "callOnAll().initOnStandAlone() Initializing on stand alone...");
		//}
		// Called with callOnAll after plugin is registered in container mainapp
		//public function initOnRegister				():void {
			//Debug.debug						(_debugPrefix, "callOnAll().initOnRegister() Initializing after registration...");
		//}
// REGISTERING APP ///////////////////////////////////////////////////////////////////////////////////////
		//public function register(uGlobal:Class):void {
			//Debug.debug						(_debugPrefix, "Plugin registered on " + _uGlobal.mainApp);
			//UGlobal.setupAsPlugin				(_uGlobal); // I setup internal UGlobal - NO
			//_standAlone						= false;
// 			trace("cAPPIRE PERCHE' QUI DA ERRORE");
// 			trace(broadcastEvent);
// 			trace(_listeners);
			//this["broadcastEvent"]				("onPluginRegistered");
			//startPlugin							();
		//}
		//public function getUGLobal				():Class {
			//return							UGlobal;
		//}
// STARTUP ///////////////////////////////////////////////////////////////////////////////////////
		//protected function startPluginStandalone		():void { // Called only when plugin is started in standalone
			//Debug.debug						(_debugPrefix, "Starting in Stand-Alone mode...");
			//// Here I call an internal function
			//this["callOnAll"]					("initOnStandAlone");
			//// Here the plugin starts up, being in standalone, pluginIsReady is called
			//broadcastEvent						("onPluginStarted");
		//}
				//public override function callOnAll	(method:String, par:*=null):void {
					//super.callOnAll				(method, par);
				//}
//
		//protected function startPlugin				():void { // Called only when plugin is started as PLUGIN
			//// Here I call an internal function
			//callOnAll							("initOnRegister");
			//// Here the plugin starts up, it may be in standalone or it may be in normal
			//broadcastEvent						("onPluginStarted");
		//}
		//protected function pluginIsReady			():void {
			//// This is called when everything is ready in the plugin and container can start using it.
			///* THIS MUST BE CALLED WHEN ALL INITIALIZATION IS DONE WITHIN THE PLUGIN */
			//setMainLoader						(false);
			//setActive							(true);
			//_isReady							= true;
//// 			onResize							();
			//visible							= true; // This can be overridden anywhere
			//// Proceed broadcasting
			//broadcastEvent						("onPluginReady");
		//}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		//public override function broadcastEvent		(evt:String, ...rest):void {
			//for each (var j:* in _listeners)			UCode.broadcastEvent(j, evt, rest);
			//for each (var jj:* in _eventListeners[evt]) UCode.broadcastEvent(jj, evt, rest);
		//}
	// CHECKS
		//public function isStandAlone				():Boolean { // If the plugin is testing independently
			//return							_standAlone;
		//}
		//public var isStandalone					:Function = isStandAlone;
		//public function isPlugin					():Boolean { // If the plugin is loaded and registered as a plugin
			//return							!_standAlone;
		//}
		//public function isActive():Boolean {
			//return _active;
		//}
		//public function isReady():Boolean {
			//return _isReady;
		//}
	//// METHODS
		//public function setActive(active:Boolean):void {
			//_active = active;
		//}
	// MainApp not available stuff
		//public function setMainLoader				(v:Boolean, txt:String=null):void {
			//broadcastEvent						("onPluginSetLoader", v, txt);
		//}
	// FRAMEWORK
		//public function onResize					():void { // Called by host app when stage is resized, or by UGlobal in standalone. Also when plugin is ready and initialized.
			//Debug.debug						(_debugPrefix, "Resizing...");
		//}
		//public function getUGlobal					():* {
			//return							UGlobal;
		//}
	// FRAMEWORK ELEMENTS - HOST APPLICATION WHN PLUGIN, INTERNAL WEHN STANDALONE
// 		public function get uGlobal				():* {
// 			trace("MI CHIEDONO QUI DI DARE UGLOBAL, NMA SEMBRA CI SIA UN ERRORE!!!");
// 			trace("UGLobal", UGlobal);
// 			trace("UGlobal.getHostFrameworkItem",UGlobal.getHostFrameworkItem);
// 			return							UGlobal.getHostFrameworkItem("UGlobal");
// 		}
		//public function get uSound():* {
			//return UGlobal.getHostFrameworkItem("USound");
		//}
		//public function get uLoader():* {
			//return UGlobal.getHostFrameworkItem("ULoader");
		//}
		//public function get uMem():* {
			//return UGlobal.getHostFrameworkItem("UMem");
		//}
		//public function get uSystem():* {
			//return UGlobal.getHostFrameworkItem("USystem");
		//}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		//protected function onStatusChange				():void {
			//// Called each time a status, as active or not, is changed
		//}
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