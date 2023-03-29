/* _Application - Provides base functionalities for applications */
/* Initialization - How to get into the initialization chain.
	Initialization is performed in several steps. First initialization is automatic, and happens when stage is available. After that, there is a pre-initialization phase.
	1 - At frame 0, the function onInit0() is called on all singleton classes.
	2 - Setting the number of frames to use for initialization on INIT_FRAMES, on each frame the functions onInit1(), onInit2(), etc. are called
	3 - After the pre-initialization phase, the function init() is called on _mainApp, which calls super.init(), and performs the rest of initialization there. Like loading config, loading backgrounds, etc.
			3a - onResize() is called here
			3b - If config is loaded, onConfig() is called on this phase.
			3c - application is made visible here too.
	4 - After MainApp has done its initialization, it has to call the startApplication(), where the application really starts
	5 - onMainApp() is called on all classes. Initialization is done.
*/


package com.pippoflash.framework {
	import com.pippoflash.framework.interfaces.*;
	import com.pippoflash.framework.Config;
	import com.pippoflash.framework.prompt._Prompt;
	import com.pippoflash.framework._PippoFlashBaseUMem;
	import com.pippoflash.components._cBase;
	import com.pippoflash.utils.*;
	import com.pippoflash.movieclips.loaders._LoaderBase;
	import com.pippoflash.string.JsonMan;
	import com.pippoflash.motion.Animator;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	import com.pippoflash.net.QuickLoader;
	import flash.system.Capabilities;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.profiler.*;

	// PROJECT IMPORT
// 	import									AS3.*;
	
	public dynamic class _Application extends _PippoFlashBase {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// SETUP CONSTANTS TO BE MODIFIED IN MAINAPP
		protected static const INIT_FRAMES:uint = 3; // This is the number of frames it takes to initialize the application. Each frame calls on all classes: onInit1, onInit2, onInit3, etc. At the end it calls onMainApp. Needed to distribute initialization amongst multiple frames not to burden too much initially
		private static const SO_VAR_NAME_APP_RUN_BEFORE:String = "___PippoAppHasAlreadyRunBefore"; // Variable used to mark in SharedObject whether App has run before (isFirstRun());
		protected static var CONFIG_LOAD_TEXT:String = "loading config...";
		protected static var _stageAlign:String = StageAlign.TOP_LEFT; // Use values from StageAlign (T,B,L,R,TR,TL,BR,BL) - or "" vor centre align
		protected static var _stageScaleMode:String = StageScaleMode.NO_SCALE; // This is the only way to trigger esize events from stage
		protected static var _resizeDelay:uint = 500; // Delay to trigger resize mothods on resize (to avoid continuous resize when dragging browser window size)
		static private var _firstResize:Boolean = true; // this marks that it is the first resize we received from UGLobal
		static protected var _originalStageSize:Rectangle; // Stores the original size of stage to calculate resized position
		//private static var _application:_Application; // Link to the singleton. Retrieved with _Application.getInstance();
		// NON-STATIC SWITCHES - MODIFIABLE VIA CONFIG - SET IN MAINAPP (DEFAULTS ONLY HERE)
		public var DEBUG:Boolean = true;
		public var BLOCK_CONSOLE:Boolean = false;
		public var DEPLOY:Boolean = false; // If set this to TRUE, everything is shut down (DEBUG, CONSOLE, etc.)
		public var FORCE_TRACE:Boolean = false; // If this is set to true, also in DEPLOY mode trace actions will be executed
		public var SHOW_REDRAW_REGIONS:Boolean = false;
		public var RENDER_QUALITY:Number = -1; 	// If -1 quality is not set, and keeps app (or host app) default. Otherwise uses this.
		public var MANAGE_UNCAUGHT_ERRORS:Boolean = true; // This routes errors to _promptOk if available, otherwise throws them again.
		// 0:low, 1:medium, 2:high, 3:best, 4:8x8, 5:8x8linear, 6:16x16, 7:16x16linear
		// SYSTEM
		private var _sharedObject:SharedObject;
		protected var _sharedObjectId:String; // This is populated by default
		private var _settings:Object; // This is activated with activateMainSettings;
		static private var _mainApplication:_Application; // This is the MAIN application. It is setup only once. Since loaded plugins work in same application domain, this can be instantiated only once.
		private var _sessionId:String; // Initializes a session ID with system and date/time
		// SYSTEM - EXTERNAL LIBRARIES
		protected var _externalLibraries:Vector.<MovieClip>; // Stores all instances of loaded external libraries
		protected var _externalLibrariesByUrl:Object; // Stores all instances of loaded external libraries connected to their url (to see if they have already beel loaded)
		protected var _externalLibrariesDefinitions:Object; // Stores all definitions as strings, and points them to reference the loaded ExternalLibrary which has been stored.
		protected var _externalLibrariesClasses:Object; // Stores all definitions as strings, linking them to the same class. It is populated ONLY at the first request.
		// USER VARIABLES
		protected var _applicationId:String;
		protected var _applicationVersion:String;
		// HTML VARIABLES - FLASHVARS HAVE TO BE PUBLIC
		public var _configUrl:String = "config.xml";
		public var _language:String = "en"; // This is taken from flashvars, but default is stored here.
		public var _noNetworkTitle:String = "<b>NO NETWORK</b>"; // This can be overwritten by handshake
		public var _noNetworkMessage:String = "[pre_GAMENAME] requires an internet connection. Network access not detetcted. Please check your network and try again."; // This can be overwritten by handhsake
		public var _noNetworkLocale:Object = { // calling updateNoNetworkMessage() title and messagge wil be overwritten by the ones in the list below
			defaultLanguage:"it",
			en:{title:"<b>NO NETWORK</b>", text:"[pre_GAMENAME] requires an internet connection. Network access not detetcted. Please check your network and try again."},
			it:{title:"<b>RETE ASSENTE</b>", text:"[pre_GAMENAME] per funzionare ha bisogno di una connessione a Internet. Controlla lo stato della tua connessione e prova di nuovo."},
			es:{title:"<b>CONECTION ASENTE</b>", text:"Para jugar a [pre_GAMENAME] necesitas estar conectado a internet. Activa la conexion antes de volver a intentarlo. Gracias"}
		};
		// REFERENCES
		private var _instance:_Application;
		private function get instance():_Application {return _instance;}
		// STAGE INSTANCES
		// SCREEN SAVER
		protected var _hasScreensaver:Boolean; // If screensaver is active or not
		private var _screenSaverTimeout:int; // Timeout in milliseconds
		private var _screenSaverTimer:Timer; // The timer for screensaver
		// MARKERS
		private var _initialized:Boolean = false;
		private var _status:String = "IDLE"; // This marks the status of the application (always starts with IDLE) - can be anything, from number to string
		protected var _isDesktopVersion:Boolean = true; // If this application (regardless of where it is running) is designed for desktop or devices. This must be set in final extension. Defaults desktop version.
		// STATIC MARKERS FOR NON-SINGLETON SITUATIONS
		private static var FIRST_INIT:Boolean = true; // Marks if this is the first initialization, or I am initialized again by a loaded plugin
		// DATA HOLDERS
		// STATIC UTY
		// MARKERS
		private var _firstRun:Boolean = true; // Marks if this is the first run of application
// INIT //////////////////////////////////////////////////////////////////////////////////

		public function _Application(id:String="_Application", appId:String="PippoFlash Default App ID", appVer:String="0.00"):void {
			super(id);
			_instance = this;
			visible = false;
			if (FIRST_INIT) {
				_mainApp = this;
				UGlobal.init(this);
				_PippoFlashBaseUMem._mainApp = this;
				_PippoFlashBaseNoDisplay._mainApp = this;
				_PippoFlashBaseNoDisplayUMem._mainApp = this;
				_cBase.setMainApp(this);
				_mainApplication = this; // This is the host application that loads all others
				FIRST_INIT = false;
			}
			_applicationId = appId;
			_applicationVersion = appVer;
			_sharedObjectId = "/PippoApps"; // CAREFUL - THIS IS OVERRIDDEN BY SO ID IN CONFIG
			Debug.debug(_debugPrefix, _applicationId, _applicationVersion);
			//_application = this;
			if (MANAGE_UNCAUGHT_ERRORS) handleUncaughtErrors();
			// Add stage event listener
			addEventListener(Event.ADDED_TO_STAGE, initOnStage); // Initialize ONLY when stage is available
			// Setup error handler
			this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		}



		private function onUncaughtError(e : UncaughtErrorEvent) : void
		{
			trace("UNCAUGHT ERROR------------------------------------------------------------------------------");
			trace(e.toString());
			trace(e.error.toString());
		}





		protected function handleUncaughtErrors():void {
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		}
		private function uncaughtErrorHandler(e:UncaughtErrorEvent):void {
			Debug.error(_debugPrefix, "Uncaught error event detected:", e);
			var t:String = e + "\n"; 
            if (e.error is Error) {
                var error:Error = e.error as Error;
				t +=  "\nError: " + (e.error as Error).name +  " - " + (e.error as Error).message;
				//Debug.error(_debugPrefix, e + "\nType Error: " + (e.error as Error).name + "- " + (e.error as Error).message);
                // do something with the error
            }
            else if (e.error is ErrorEvent) {
                var errorEvent:ErrorEvent = e.error as ErrorEvent;
                // do something with the error
				t +=  "\nErrorEvent: " +  (e.error as ErrorEvent).type + " - " + (e.error as ErrorEvent).target;
				//Debug.error(_debugPrefix, e + "\nType ErrorEvent: " + (e.error as ErrorEvent).type + "- " + (e.error as ErrorEvent).target);
            }
            else {
                // a non-Error, non-ErrorEvent type was thrown and uncaught
				t += (e.error as Error).name + " - " + (e.error as Error).message;
				//Debug.error(_debugPrefix, "Type unknown: " + (e.error as Error).name + "- " + (e.error as Error).message);
            }
			t += "\nPlease see console hitting keys C-O-N together.";
			// Prompt or report in trace
			Debug.error(_debugPrefix, t + "\n" + (e.error as Error).getStackTrace());
			if (!promptOk(t, "UNCAUGHT ERROR DETECTED")) {
				Debug.error(_debugPrefix, "PROMPT OK NOT AVAILABLE, PLEASE LOOK INTO ERROR:\n" + t);
			}
		}
			protected final function setRef(ref:Ref):void { // Has to be called by MainApp to setup the correct reference to Ref object, or extender Ref
				_ref = ref;
				_PippoFlashBaseUMem._ref = ref;
				_PippoFlashBaseNoDisplayUMem._ref	= ref;
				_cBase.setRef(ref);
				callOnAll("onRefReady");
			}
		protected function initOnStage(e:Event=null):void { // Once stage is available to application, this initialization is performed
			initCommonFeatures();
			initSwfFeatures();
			completeCommonInit();
		}
			protected final function initCommonFeatures():void {
				removeEventListener(Event.ADDED_TO_STAGE, initOnStage); // TO INVESTIGATE WHY THIS EVENT IS FIRED TWICE IF I DO NOT REMOVE IT
				// Setup system constants
				if (DEPLOY) {
					BLOCK_CONSOLE = !FORCE_TRACE; // Console is blocked in deploy, but if FORCE_TRACE is true console is not blocked.
					DEBUG = false;
					SHOW_REDRAW_REGIONS = false;
				}
				// Setup flags
				if (hasOwnProperty("_txtDebugVersion")) {
					this["_txtDebugVersion"].text 	= _applicationId + " - " + _applicationVersion;
					this["_txtDebugVersion"].visible 	= !DEPLOY;
				}
				showRedrawRegions(SHOW_REDRAW_REGIONS, 0xffffff);
				// Proceed with init
				JsonMan.init();
				if (RENDER_QUALITY >= 0 && RENDER_QUALITY <= 7) UGlobal._renderQuality = RENDER_QUALITY;
				UGlobal.addResizeListener(onMainAppResize);
				UGlobal.setup(this, _resizeDelay, _stageAlign, _stageScaleMode, _originalStageSize);
				UGlobal.setupSystemClass(_PippoFlashBase);
			}
			protected final function initSwfFeatures		():void {
				UCode.setListFlashVars			(this, "_configUrl,_noNetworkMessage,_noNetworkTitle,_language");
			}
			protected function completeCommonInit		():void {
				// Check if reference is not set
				if (!_ref)						_ref = new Ref();
				// This initialization happens BEFORE loading config.
				// Initialization calls onInit0, and then eventually other numbered onInitN
				// After that, checks for single class initialization with a list od IDs, on which to call initClass()
				// After all this, it calls init() in MainApp
				callOnAll						("onInit0"); // start calling immediate initialization
				var initFrame					:uint = 1; // Call next frame the last init() method
				// If init frames are set, initialization is distributed amongst several frames.
				if (INIT_FRAMES) { // I have to distribute initialization amongst multiple frames
					for (var i:uint=1; i<=INIT_FRAMES; i++) {
						UExec.frame			(i, callOnAll, "onInit"+String(i));
						initFrame				= i+1;
					}
				}
// 				
				// Check for classes initialization list
				//if (INIT_CLASSES) {
					//for (var ii:uint=0; ii<INIT_CLASSES.length; ii++) {
						//var c					:IPippoFlashBase = getInstance(INIT_CLASSES[ii]);
						//if (c) {
							//UExec.frame		(initFrame, initSingleClass, c);
							//initFrame			+= 1;
						//}
						//else {
							//Debug.error		(_debugPrefix, "During Class initialization in INIT_CLASSES, I have not found this instance: " + INIT_CLASSES[ii]);
						//}
					//}
				//}
				// Launch final init method
				UExec.frame					(initFrame, init);
			}
					private function initSingleClass	(c:_PippoFlashBase):void {
						Debug.debug			(_debugPrefix, "Calling initClass() on " + c);
						UCode.callMethod		(c, "initClass");
					}
		protected function init():void {
			// This has to be always overridden. In this I have to put the loadConfig, or call directly startApplication
			// This super.init() should be called first of all in the overridden init() function. 
			_Prompt.init();
			//onMainAppResize(true);
			const d:Date = new Date();
			_sessionId = Capabilities.os.split(" ").join("-") + "_" + (Capabilities.supports64BitProcesses ? "64" : "32") + "_" + d.getTime();
			Debug.debug(_debugPrefix, "Initialized session " + _sessionId);
			_initialized = true;
		}
		protected function startApplication():void {
			// If a config needs to be loaded
			initializeSharedObject();
			if (_config) _config.loadPreferences();
			Debug.debug(_debugPrefix, "Starting Application. Calling onMainApp() on all PippoFlash singletons.");
			callOnAll("onMainApp");
		}
// LAST APPLICATION POSITION ///////////////////////////////////////////////////////////////////////////////////////
		public function checkLastApplicationPosition():* {
			return getSharedObject("_pippoAppsApplicationLastPosition");
		}
		public function setLastApplicationPosition(pos:*):void {
			setSharedObject("_pippoAppsApplicationLastPosition", pos);
		}
		public function deleteLastApplicatonPosition():void {
			setLastApplicationPosition(null);
		}
// REFERENCING SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		public function setReference				(varName:String, ref:*):void {
			if (_ref.hasOwnProperty("setReference"))	_ref.setReference(varName, ref);
			else								_ref[varName] = ref;
		}
		public function getReference				(varName:String):* {
			if (_ref.hasOwnProperty("getReference"))	_ref.getReference(varName);
			else								return _ref[varName];
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function get instance():_Application {
			return _mainApplication;
		}
		
		public function get sessionId():String 
		{
			return _sessionId;
		}
		
		public function get applicationId():String 
		{
			return _applicationId;
		}
		
// SCREENSAVER ///////////////////////////////////////////////////////////////////////////////////////
	/**
	 * Call this once to setup screensaver.
	 * @param	timeout milliseconds to elapse screensaver
	 */
		protected function setupScreensaver(timeout:int):void {
			Debug.debug(_debugPrefix, "Activating screensaver.");
			_hasScreensaver = true;
			_screenSaverTimeout = timeout;
			_screenSaverTimer = new Timer(_screenSaverTimeout, 1);
			_screenSaverTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onScreensaverTimerElapsed);
			resetScreenSaverCount();
		}
		/**
		 * Call this to reset screensaver count time.
		 */
		public function resetScreenSaverCount():void {
			if (_hasScreensaver) {
				//Debug.debug(_debugPrefix, "Resetting screen saver count. Will trigger in seconds: " + _screenSaverTimeout/1000);
				_screenSaverTimer.reset();
				_screenSaverTimer.start();
				Buttonizer.setGeneralOnClick(onGeneralClickOrGesture);
				Gesturizer.setGeneralOnGesture(onGeneralClickOrGesture);
			} 
			//else Debug.error(_debugPrefix, "resetScreenSaverCount() called but screen saver is not active.");
		}
		protected function onGeneralClickOrGesture():void {
			if (_hasScreensaver) resetScreenSaverCount();
		}
		private function onScreensaverTimerElapsed(e:TimerEvent):void {
			Debug.debug(_debugPrefix, "Screensaver timer elapsed.");
			activateScreensaver();
		}
		private function onStageClickListener():void {
			Debug.debug(_debugPrefix, "Clicked on stage... Removing scrensaver.");
			UGlobal.setStageShield(false);
			removeScreensaver();
		}
		// SCREENSAVER EVENTS
		/**
		 * Extend this when screensaver has to show.
		 */
		protected function activateScreensaver():void { /// Extend this to activate screensaver
			UGlobal.setStageShield(true, onStageClickListener);
			Debug.debug(_debugPrefix, "Activating Screensaver.");
		}
		/**
		 * Extend this to remove screensaver.
		 * @param	reactivate if screensaver has to be reactivated
		 */
		protected function removeScreensaver(reactivate:Boolean=true):void { // Extend this to remove screensaver
			Debug.debug(_debugPrefix, "Removing Screensaver.");
			if (reactivate) resetScreenSaverCount();
		}





// STAGE MASK ///////////////////////////////////////////////////////////////////////////////////////
// 		public  function setStageMask				(v:Boolean=true):void {
// 			if (!_stageSystemMask) {
// 				_stageSystemMask				= UGlobal.stage.addChild(UDisplay.getSquareMovieClip(UGlobal._sw, UGlobal._sh));
// 				_stageSystemMask.visible			= false;
// 				setStageMask					();
// 			}
// 			_stageSystemMask.visible				= v;
// 			mask								= v ? _stageSystemMask : null;
// 		}
// THROTTLE MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
// 		protected function onThrottleEvent			(e:Event):void {
// 			
// 		}
// CONFIG LOADER ///////////////////////////////////////////////////////////////////////////////////////
		protected function createConfig				(projConfig:Class=null, anticache:Boolean=false):void { // Creates config without triggering load (this happens when loading handshake first, a config is useful)
			if (!projConfig)						projConfig = Config;
			_config							= new projConfig(null, onConfigLoaded, onConfigError, anticache, _language); // I just create the config, but do not load it
			_ref.setReference					("_config", _config);
			_cBase.setConfig						(_config);
			_PippoFlashBaseUMem._config			= _config;
			_PippoFlashBaseNoDisplay._config			= _config;
			_PippoFlashBaseNoDisplayUMem._config		= _config;
			UGlobal.setupSystemClass				(_PippoFlashBase); // I set this AFTER creating config so that it will available to all plugins
		}
		protected function loadConfig(projConfig:Class=null, anticache:Boolean=false, u:String=null, preKeys:Object=null):void {
			//setMainLoader(true, CONFIG_LOAD_TEXT);
			if (u) _configUrl = u;
			if (!_config) createConfig(projConfig, anticache);
			if (preKeys) _config.setPreKeywords(preKeys);
			_config.load(_configUrl, onConfigLoaded, onConfigError, anticache, _language);
		}
		protected function onConfigLoaded(o:Object):void {
			//setMainLoader(false);
			// Manage Application Node
			if (_config._application) {
				// Setup main SHARED OBJECT
				if (UXml.hasFullAttribute(_config._application, "sharedObjectName")) {
					// If attribute does not exist (backwards compatible) or atrribute is true, initiazlize SO
					if (!UXml.hasFullAttribute(_config._application, "initializeSharedObjectOnLoad") || UXml.isTrue(_config._application, "initializeSharedObjectOnLoad")) {
						_sharedObjectId = _config._application.@sharedObjectName;
						if (UCode.isTrue(_config._application.@addVersionNumber)) {
							_sharedObjectId += "/" + (_applicationVersion.split(".").join("_").split(" ").join("_"));
						}
					}
				}
			}
			// Call config loaded
			callOnAll("onConfig"); // This notifies to all instances that config has been loaded and parsed
			UExec.next(startApplication);
		}
		protected function onConfigError				():void {
			promptOk(_noNetworkMessage, _noNetworkTitle, _config.reload);
		}
//  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SYSTEM UTY /////////////////////////////////////////////////////////////////////////////////////////////////////
		public function updateNoNetworkMessage		():void { // This updates the no network message according to default languages locale
			var lan							:String = _noNetworkLocale[_language] ? _language : _noNetworkLocale.defaultLanguage; // If there is no language node, I will use default language
			// If Config has been already created, text will go through a substitute keywords process
			if (!_config)						Debug.error(_debugPrefix, "ATTENTION: updateNoNetworkMessage() Cannot substitute keywords since _config has not yet been created.");
			_noNetworkTitle					= _config ? _config.substitutePreKeywords(_noNetworkLocale[lan].title) : _noNetworkLocale[lan].title;
			_noNetworkMessage					= _config ? _config.substitutePreKeywords(_noNetworkLocale[lan].text) : _noNetworkLocale[lan].text;
		}
// PROMPTS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		public function prompt					(id:String, par:Object=null):_Prompt {
			if (getInstance(id)) {
				getInstance(id).prompt			(par);
				return						getInstance(id) as _Prompt;
			}
			else								Debug.debug(_debugPrefix, "Prompt",id,"requested but doesnt exist");
			return							null;
		}
		public function promptOk(msg:String, tit:String=null, func:Function=null, buttOk:String="OK", promptId:String="Ok"):_Prompt {
			Debug.debug(_debugPrefix, "Prompting:",msg);
			var o:Object = {_txt:msg};
			if (tit) o._txtTitle = tit;
			if (Boolean(func)) o._funcOk = func;
			if (buttOk) o._buttOk = buttOk;
			return prompt(promptId, o);
		}
		public function promptOkLong(msg:String, tit:String=null, func:Function=null, buttOk:String=null):_Prompt {
			return promptOk(msg, tit, func, buttOk, "OkLong");
		}
		public function promptConfirm(msg:String, tit:String=null, funcOk:Function=null, funcCancel:Function=null, buttOk:String=null, buttCancel:String=null):_Prompt {
			// This prompts for a confirm, setting text, and eventually title, ok function, cancel function, and the text for the 2 buttons
			_o								= {_txt:msg};
			if (tit)							_o._txtTitle = tit;
			if (Boolean(funcOk))					_o._funcOk = funcOk;
			if (Boolean(funcCancel))				_o._funcCancel = funcCancel;
			if (buttOk)							_o._buttOk = buttOk;
			if (buttCancel)						_o._buttCancel = buttCancel;
			return							prompt("Confirm", _o);
		}
		public function clearAllPrompts				(group:String=null):void {
			_Prompt.clearAllPrompts				(group);
		};
		// Process config xml prompt
		public function processConfigPrompt(id:String, params:Object=null, substituteAttributes:Object=null, textKeywords:Object=null):_Prompt {
			// params is the normal extra params object I would send to a prompt
			// substituteAttributes will substitute prompt xml node attributes with key/string stored in the object
			// textKeywords stores an object that will substitute words in BOTH title and text
			if (substituteAttributes && substituteAttributes.id) id = substituteAttributes.id;
			if (_config.getPrompt(id)) {
				var node						:XML = _config.getPrompt(id);
				Debug.debug					(_debugPrefix, "Processing prompt: " + id, Debug.object(params));
				if (substituteAttributes) {
					Debug.debug				(_debugPrefix, "Substituting attirbutes:",Debug.object(substituteAttributes));
					for (var s:String in substituteAttributes) {
						node.@[s]		= substituteAttributes[s];
					}
				}
				return						processXmlPrompt(node, params, textKeywords);
			}
			else {
				Debug.error					(_debugPrefix, "CONFIG PROMPT NOT FOUND: " + id);
				return null;
			}
		}
		public function createConfigPromptObject		(id:String, params:Object=null, substituteAttributes:Object=null, textKeywords:Object=null):Object {
			/* BY NOW I JUST DUPLICATED PREVIOS METHOD TO RETURN A FORMATTED OBJECT */
			// params is the base used to render popup. Properties are overwriteen with stuff taken from config. CONFIG PARAMS HAVE PRIORITY
			// substituteAttributes will substitute prompt xml node attributes with key/string stored in the object
			// textKeywords stores an object that will substitute words in BOTH title and text
			if (substituteAttributes && substituteAttributes.id) id = substituteAttributes.id;
			if (_config.getPrompt(id)) {
				var node						:XML = _config.getPrompt(id);
				Debug.debug					(_debugPrefix, "Processing prompt: " + id, Debug.object(params));
				if (substituteAttributes) {
					Debug.debug				(_debugPrefix, "Substituting attirbutes:",Debug.object(substituteAttributes));
					for (var s:String in substituteAttributes) {
						node.@[s]		= substituteAttributes[s];
					}
				}
				return						createXmlPromptObject(node, params, textKeywords);
			}
			else {
				Debug.error					(_debugPrefix, "CONFIG PROMPT NOT FOUND: " + id);
				return null;
			}
		}
		// Processes an XML node for PROMPT
		public function processXmlPrompt				(xml:XML, params:Object=null, textKeywords:Object=null):_Prompt {
			// Prompt the popup
			return							prompt(xml.@type, createXmlPromptObject(xml, params, textKeywords));
			// Control the 
		}
		public function createXmlPromptObject			(xml:XML, params:Object=null, textKeywords:Object=null):Object {
			/* Instructions for XML prompt node
				Example node: 
					<promptBecomeFan mode="action" type="Ok" _buttOk="SI" funcOk="showSubscribedTableDetails" listenerOk="MainApp" _buttCancel="Cancel" funcCancel="onCancel" listenerCancel="MainApp" funcPopup="onPopup" funcPopupListener="MainApp">
						<TITLE><![CDATA[DIVENTA FAN]]></TITLE>
						<TEXT><![CDATA[<font size='20' color='#F6DFA9'>e ricevi subito in regalo</font><br/><font size='30' color='#F6DFA9'><b>10P€</b></font>]]></TEXT>
					</promptBecomeFan>
			
				type="Ok"							// Is the ID of prompt to be called
				_buttOk="OK"						// Is the text to be set in _buttOk. All variables starting with "_" will be directly set in the prompt data object.
				funcOk="nameOfFunction"				// Name of the function to call on ok as string
				listenerOk="MainApp"					// PippoFlash ID of the singleton class where to call the function
				funcPopup							// Function to be triggered as the popup is opened - THIS DOESNT USER PARAMETERS BY NOW
				listenerPopup						// Listener to be triggered on popup
				// All functions which start with func... MUST have a listener... associated to find the real function.
				// Node MUST have a TITLE and TEXT children
				// textKeywords stores an object that will substitute words in BOTH title and text
			*/
			// mode="replace" - replace visible popup and discards it 
			// mode="replaceAll" - replaces visible popup and removes all others from the list
			// mode="override" - replaces visible popup and puts the replaced one first
			// block="true" - A popup which wants to block others coming. Skips override and replace.
			Debug.debug(_debugPrefix, "Processing XML prompt: " + xml.toXMLString());
			// Create prompt parameters. If params is defined it gets used as a base.
			// XML parameters OVERWRITE eventual parameters in params object
			// Params object is also sent as functions par object
			var o:Object = params ? UCode.duplicateObject(params) : {}; // Add the popup node to prompts
			o._popupNode = xml;
			// Set variables. Start with "_". Or functions.
			var attNamesList:XMLList 				= xml.@*;
			var att							:XML;
			var attName						:String;
			for (var i:int = 0; i < attNamesList.length(); i++) {
				att							= attNamesList[i];
				attName						= String(att.name());
				if (attName.charAt(0) == "_")		o[attName] = String(att);
				else if (attName.indexOf("func") == 0) { // I have found a function. Now I have to setup function AND listener.
					// Special functions first, then normal popup functions
					if (attName == "funcPopup") { // Function to be called on popup
						var listener:* = getInstance(xml.attribute("listenerPopup"));
						if (!listener) {
							Debug.error(_debugPrefix, "Listener for funcPopup not found on xml prompt:",xml);
						}
						else {
							listener[String(att)]	();
						}
					}
					else {
						var funcId:String = attName.substr(4); // Find what function is it (Ok, Cancel, etc.)
// 						trace("QUI C'è un errore");
// 						trace(o, funcId, "listener"+funcId, xml);
// 						trace(xml.attribute("listener"+funcId));
// 						trace(getInstance(xml.attribute("listener"+funcId)));
						var list:Object = getInstance(xml.attribute("listener" + funcId));
						if (list) o["_func" + funcId] = list[String(att)]; // Find the function
						else Debug.error(_debugPrefix, "Prompt XML error: Cannot create " + funcId + ". Listener not found: " + xml.attribute("listener" + funcId));
					}
				}
			}
			if (UXml.hasAttribute(xml, "timeout")) o._timeout = uint(xml.@timeout)*1000; // From config I take seconds
			if (UXml.hasAttribute(xml, "mode")) o._mode = String(xml.@mode); // From config I take popup mode (override, replace, replaceAll)
			o._promptId = xml.name();
			// Setup title and txt
			o._txtTitle = xml.TITLE[0].toString();
			o._txt = xml.TEXT[0].toString();
			if (textKeywords) {
				o._txtTitle = UText.insertParams(o._txtTitle, textKeywords);
				o._txt = UText.insertParams(o._txt, textKeywords);
			}
			// This has to be adjusted
			// o._par							= params; // These are parameters sent by function
			// Check for parameters insertion
			if (params) {
				o._txtTitle = UText.insertParams(o._txtTitle, params);
				o._txt = UText.insertParams(o._txt, params);
			}
			return o;
		}
// STAGE VIEW MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
	// Here are methods used to position elements on stage, root, directly on the bottom, such as Stage3D, or StageWebView, stuff that has to be on root.
		private var _stageViewElement				:*;
		public function setStageViewElement			(e:*, andKill:Boolean=false, fadeIn:Boolean=false):void {
			if (_stageViewElement)				removeStageViewElement(andKill);
			_stageViewElement					= e;
			UGlobal.root.addChildAt				(_stageViewElement, 0);
			UGlobal.confirmStageProperties			();
			if (fadeIn) {
				_stageViewElement.alpha			= 0;
				Animator.fadeIn				(_stageViewElement);
			}
		}
		public function removeStageViewElement		(andKill:Boolean=false):void {
			if (_stageViewElement) {
				UGlobal.root.removeChild			(_stageViewElement);
				if (andKill)					UMem.killClip(_stageViewElement);
				_stageViewElement				= null;
			}
		}
// ACTIONS ///////////////////////////////////////////////////////////////////////////////////////
		public function processConfigAction			(action:String):void {
			Debug.debug						(_debugPrefix, "Processing config action: " + action);
			var node							:XML = _config._actions[action][0];
			getInstance(node.@listener)			[String(node.@func)]();
		}
// JSON ///////////////////////////////////////////////////////////////////////////////////////
		public function encodeJson				(o:Object):String {
			return							JsonMan.encode(o);
		}
		public function decodeJson				(o:Object):Object {
			return							JsonMan.decode(o);
		}
// STATUS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		public function setStatus					(s:*):void {
			callOnAll							("closeStatus_"+_status);
			_status							= s;
			callOnAll							("openStatus_"+_status);
		}
		public function getStatus					():* {
			return							_status;
		}
		public function isInitialized					():Boolean {
			return							_initialized;
		}
// SHARED OBJECT MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		public function setSharedObject(varName:String, value:*):void {
			Debug.debug(_debugPrefix, "Saving shared object",varName,typeof value);
			initializeSharedObject();
			_sharedObject.data[varName] = value;
			_sharedObject.flush();
		}
		public function getSharedObject(varName:String):* {
			initializeSharedObject();
			return _sharedObject.data[varName];
		}
			protected function initializeSharedObject(sharedObjectId:String=null):void {
				if (_sharedObject) {
					if (!sharedObjectId || _sharedObjectId == sharedObjectId) return; 
					else {
						_sharedObject.removeEventListener(NetStatusEvent.NET_STATUS, onSOStatus);
						_sharedObject.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, onSOAsyncError);
						_sharedObject = null;
					}
				}
				if (sharedObjectId) Debug.debug(_debugPrefix, "Request to init SO: " + sharedObjectId);
				if (sharedObjectId) _sharedObjectId = sharedObjectId;
				Debug.debug(_debugPrefix, "Initializing shared object:",_sharedObjectId);
				_sharedObject = SharedObject.getLocal(_sharedObjectId, "/");
				_sharedObject.addEventListener(NetStatusEvent.NET_STATUS, onSOStatus);
				_sharedObject.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onSOAsyncError);
			}
		public function clearSharedObject():void { // This clears the application shared object
			initializeSharedObject();
			_sharedObject.clear();
		}
		private function onSOAsyncError				(e:AsyncErrorEvent):void {
			Debug.error(_debugPrefix, "ShareObject ASync error: " + e);
		}
		private function onSOStatus				(e:NetStatusEvent):void {
			Debug.error(_debugPrefix, "ShareObject NetStatus: " + e);
		}
// EXTERNAL LIBRARIES ///////////////////////////////////////////////////////////////////////////////////////
	/* How to work with external libraries
		- EL must be exported using com.pippoflash.ExternalLibrary as base class.
		- EL are loaded and deposited. All definition names are stored in a list. 
		- Loading a new EL with same definition names will overwrite the ones already loaded.
		- Once EL is loaded, classes can be accessed singularly, or can be processed automatically.
				- _mainApp.processExternalLibrarySounds(libUrl, USoundList);
						All sounds (marked as sounds internally in te libary) are automatically added to USound. 
						They are added to DEFAULT list, or another list if specified.
	*/
		public function loadExternalLibrary			(libUrl:String, loadingText:String=null):SimpleQueueLoaderObject {
			if (_externalLibrariesByUrl && _externalLibrariesByUrl[libUrl]) {
				Debug.error					(_debugPrefix, "Library",libUrl,"is already loaded, broadcasting loading complete...");
				broadcastEvent					("onLoadCompleteExternalLibrary", _externalLibrariesByUrl[libUrl]);
			}
			setMainLoader						(true, loadingText ? loadingText : "loading external library");
			var sq							:SimpleQueueLoaderObject = ULoader.connectLoader(QuickLoader.loadFile(libUrl, this, "ExternalLibraryPrivate"));
			return							sq;
		}
		public function processExternalLibrarySounds	(libUrl:String, group:String=null):void { // libUrl is the loaded library, group is the USound list group
			// public static function addSoundToList			(classId:String, soundId:String, listId:String="DEFAULT", soundInstance:*=null):Boolean {
			var lib							:MovieClip = _externalLibrariesByUrl[libUrl];
			var sounds						:Object = lib.getSoundClasses();
			Debug.debug						(_debugPrefix, "Adding ALL library sounds to USound:",Debug.object(sounds));
			var sound							:*; // This is an instance of the main sound class, it can'b be typized
			for (var id:String in sounds) {
				sound						= new sounds[id];
				USound.addSoundToList			(id, id, group, sound);
			}
		}
				public function onLoadCompleteExternalLibraryPrivate(o:SimpleQueueLoaderObject):void {
					setMainLoader				(false);
					if (o.getContent().isPippoFlashLibrary) {
						var lib				:MovieClip = processLoadedLibrary(o);
						broadcastEvent			("onLoadCompleteExternalLibrary", lib);
					}
					else {
						Debug.error			(_debugPrefix, "Externally loaded library is NOT a PippoFlash ExternalLibrary.");
						onLoadErrorExternalLibraryPrivate(o);
					}
				}
					private function processLoadedLibrary(o:SimpleQueueLoaderObject):MovieClip {
						var lib				:MovieClip = o.getContent();
						Debug.debug			(_debugPrefix, "Loaded successfully external library.",lib.getInfo());
						// Process internal libraries management
						if (!_externalLibraries) {
							_externalLibraries	= new Vector.<MovieClip>;
							_externalLibrariesByUrl = {};
							_externalLibrariesDefinitions = {};
							_externalLibrariesClasses = {};
						}
						_externalLibraries.push	(lib);
						_externalLibrariesByUrl[lib.getUrl()] = lib;
						var definitions			:* = lib.getDefinitions(); // Her eI have to use a * because it doesn't see a Vector from a loaded swf as a vector
						for each (var def:String in definitions) {
							_externalLibrariesDefinitions[def] = lib;
						}
						
						// Process USound internal management
						return				lib;
					}
				public function onLoadErrorExternalLibraryPrivate(o:SimpleQueueLoaderObject):void {
					
					setMainLoader				(false);
					broadcastEvent				("onLoadErrorExternalLibrary", o);
				}
// ///////////////////////////////////////////////////////////////////////////////////////
// UTY //////////////////////////////////////////////////////////////////////////////////
// ///////////////////////////////////////////////////////////////////////////////////////
	// METHODS CHECKS
		public function isIdle						():Boolean {
			return							_status == "IDLE";
		}
		public function getVersion					():String {
			return							_applicationVersion;
		}
		public function getApplicationDescriptor			():String {
			return							_applicationId + " " + _applicationVersion;
		}
		public function getAppId():String { // If it is an AIR app it will return AIR ID, otherwise the descriptor
			return _applicationId;
		}
		public function isDebug():Boolean {
			return DEBUG;
		}
		public function isDeploy():Boolean {
			return DEPLOY
		}
		public function getLanguage():String {
			return _language;
		}
		public function isRoot():Boolean { // If this is root movieclip
			return this == UGlobal.root;
		}
		public function getMainApplication():_Application { // If this is a plugin app, main application is the container. Otherwise is the same application.
			return _mainApplication;
		}
		public function isPlugin():Boolean { // If I am a plugin or a main application
			return _mainApplication != this;
		}
		public function isRunningOnDesktop():Boolean { // Doesn't matter which version, if this instance of app is running on a desktop computer
			return USystem.isRunningOnDesktop();
		}
		public function isDesktopVersion():Boolean { // If extension is MainDesktop
			return _isDesktopVersion;
		}
		public function isDeviceVersion():Boolean { // If extension is MainDevice
			return !_isDesktopVersion;
		}
	// FIRST RUN INFO
		public function isFirstRun():Boolean {
			//if (_sharedObject) { // This can only be used if ahsred object is set (remember to upgrade version number)
				var hasRunBefore:Boolean = getSharedObject(SO_VAR_NAME_APP_RUN_BEFORE);
				setSharedObject(SO_VAR_NAME_APP_RUN_BEFORE, true);
				return !hasRunBefore;
			//}
			//Debug.error(_debugPrefix, "isFirstRun() queried, but is ids not possible if initSharedObject() is not called before.");
		}
	// ALL FRAMERATE FUNCTIONS ARE OVERRIDDEN BY APPLICATION AIR
		public function isShitFramerate				():Boolean { // not OK or BEST
			return							false;
		}
		public function isGoodFramerate			():Boolean { // OK or BEST
			return							true;
		}
		public function isWorseFramerate			():Boolean { // WORSE
			return							false;
		}
		public function isOkFramerate				():Boolean { // OK
			return							false;
		}
		public function isBestFramerate				():Boolean { // BEST
			return							false;
		}
		public function getFramerate				():Number {
			return							UGlobal.stage.frameRate;
		}
		public function getFramerateLevel			():String {
			return							"BEST";
		}
		// The varibale MUST be set in extension or will default to desktop version
	// RESIZE LISTENER
		protected function onMainAppResize():void {
			// This first resize is called directly by application. UGlobal calls it only on real resize, and without any parameter.
			Debug.debug(_debugPrefix, "Main app is resizing" +(_firstResize ? " for the first time." : "."));
			callOnAll("onResize", _firstResize);
			_firstResize = false;
		}
		protected function onStageSizeReceived():void {
			
		}
// LOADER /////////////////////////////////////////////////////////////////////////////////////
		public function setMainLoader(b:Boolean, t:String="", sqlo:SimpleQueueLoaderObject=null, shield:Boolean=true, onComplete:Function=null):_LoaderBase {
			// If SQLO is defined, main loader will be connected to it
			//return;
			var loader:_LoaderBase = ULoader.setLoader(b, t, shield, onComplete);
			Buttonizer.setupButton(loader, {});
			if (sqlo) ULoader.connectLoader(sqlo);
			return loader;
		}
		public function setMainLoaderId(id:String, sqlo:SimpleQueueLoaderObject=null, shield:Boolean=true):void { // Triggers a loder witth caption taken from config vocabulary
			setMainLoader(true, _config.getWord(id), sqlo, shield);
		}
// PREFERENCES ///////////////////////////////////////////////////////////////////////////////////////
// 	// Preferences work like settings, and ARE stored in a local shared object
// 		protected function activatePreferences			(pref:XML=null):void { // Needs to be called only once and activates the whole preferences flow
// 			if (!_preferences) { // this method must be called only once
// 				_preferences					= {};
// 				if (pref)						setPreferencesDefault(pref);
// 			}
// 			
// 		}
// 		protected function setPreferencesDefault		(pref:XML):void { // Sets preferences default from an XML node
// 			Debug.debug						(_debugPrefix, "Setting up preferences default\n", pref.toXMLString());
// 		}
// 		
// SETTINGS ///////////////////////////////////////////////////////////////////////////////////////
	// Settings are NOT stored in a local shared object
	// Settings are activated by extended app. Have to activate cookies storage of settings.
	// In order to make setings work, I can use the listener, or override the onSettingUpdated method.
	// METHODS
		public function activateMainSettings			(obj:Object):void {
			// this sets main settings defaults and broadcasts all values. Do NOT call this before listeners have been initialized or buttons will not work.
			_settings							= UCode.duplicateObject(obj);
			for (var id:String in _settings)			updateMainSetting( id, _settings[id]);
		}
		public function getMainSetting				(id:String):* { // Get one setting
			return							_settings[id];
		}
		public function getMainSettings				():Object { // Get all settings
			return							_settings;
		}
		public function toggleMainSetting			(id:String, value:*=null):void { 
			// It changes settings values for an application. If value is not specified, it is toggled (Only for Booleans, others are unaffected).
			if (!_settings) {
				Debug.error					(_debugPrefix, "Cannot update setting",id,"since settings have not yet been initialized.");
				return;
			}
			var changed						:Boolean = true;
			if (value == null) {
				Debug.debug					(_debugPrefix, "Toggling setting",id,"with value not specified. Is it boolean?",_settings[id] is Boolean);
				if (_settings[id] is Boolean) {
					_settings[id]				= !_settings[id];
				}
				else {
					Debug.error				(_debugPrefix, "Can't toggle setting",id,"because it is not a boolean!");
					changed					= false;
				}
			}
			else {
				Debug.debug					(_debugPrefix, "Updating setting",id,"with value:",value);
				_settings[id]					= value;
			}
			updateMainSetting					(id, _settings[id]);
		}
	// UTY
				private function updateMainSetting	(id:String, value:*):void {
					// Sends broadcasts general for main settings, and a single broadcast for each setting id
					broadcastEvent				("onMainSettingChanged", id, value);
					broadcastEvent				("onMainSettingChanged_"+id, value);
					onSettingUpdated			(id, value); // Calling function that should be overridden in order to work
				}
	// OVERRIDABLE
		protected function onSettingUpdated			(id:String, value:*):void {
			/* OVERRIDE THIS IN MainApp TO USE ACTUAL SETTINGS */
		}
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