/* UAir - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Performs typical Air actions and utilities.

*/

package com.pippoflash.framework.air {

// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import com.pippoflash.utils.*; import com.pippoflash.framework._ApplicationAir; // PippoFlash
	import com.pippoflash.framework._Application; import com.pippoflash.framework.PippoFlashEventsMan;
	import flash.display.*; import flash.events.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*; import flash.geom.*; import flash.external.*;// FLash
	import flash.html.*; import flash.display.*; import flash.desktop.*; import flash.media.SoundMixer; // AIR
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public class UAir {
	// VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		// EVENTS
		public static const EVT_EXITING:String = "onApplicationExiting";
	
		// DEBUG SWITCHES
		private static var FORCE_FRAMERATE_LEVEL		:Boolean = false;
		private static var FORCE_FRAMERATE_LEVEL_MODE:String = "WORSE";
		// CONSTANTS
		private static var PLAYBACK_MODE			:String = "ambient"; // ambient, media, voice - http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/media/AudioPlaybackMode.html
		private static var REAL_PIXEL_DPI				:uint = 160; // When DPI is this, pixels ae 1:1
		private static var OPTIMAL_PIXEL_RATIO		:Number = 1.5; // This is the nexus one, 240 dpi, (240/160) = 1.5;
		public static var _verbose					:Boolean = true;
		public static var _debugPrefix				:String = "UAir";
		private static var NATIVE_WINDOW_OPTIONS		:Object = { // This is not a constant because options can be added at runtime
		};
		private static const FRAMERATE_CHECK_ACTIVE:Boolean = false; // If this is not needed, make sure is on false
		// REFERENCES
		private static var _nativeWindow				:NativeWindow; // The main NativeWindow associated to stage
		private static var _nativeApplication			:NativeApplication; // The main NativeWindow associated to stage
		private static var _applicationFile				:String; // Grabbed from AIR
		private static var _applicationName			:String; // Grabbed from AIR
		private static var _applicationVersion			:String; // Grabbed from AIR
		private static var _applicationId			:String; // Grabbed from AIR
		// FRAMERATE
		public static var _isShitFramerate				:Boolean; // This is accessed directly by _ApplicationAir
		public static var _framerateLevel				:String = "BEST"; // BEST, OK, WORSE - over 80% - over 50% - below
		private static var _debugTextField				:TextField;
		private static var _lastCheckTimer				:uint; // Stores last time it was checked
		private static var _averageFramerate			:Number;
		private static var _framesCounter				:uint;
		private static var _bestFramerate				:uint; // Stores original framerate
		private static const CHECK_FRAMERATE_FRAMES	:uint = 10; // Check framerate each frames
		private static const MIN_FRAMERATE			:uint = 10; // Below this, is shit framerate
		// DPI AND RATIO
		public static var _optimalScale				:Number = 1; // Stores the optimal scale - based on DPI, OPTIMAL_PIXEL_RATIO and REAL_PIXEL_DPI
		public static var _scaleMultiplier				:Number = 1; // this multiplies optimal scale according to resolution and dpi
		// AIR DEVICE ID
		private static var _macAddress				:String = "NO:MAC:ADDRESS";
		private static var _deviceId					:String; // IT is built by mac address (where available) + other settings taken from USystem (OS, version, etc.) - not language!
		// MARKERS
		private static var _fixAndroidBlackScreen		:Boolean; // This applies a fix on app wake up that turns all the screen black
		private static var _defaultStageQuality			:String; 
		static private var _awake:Boolean = true; // If application is awake or not. Defaults to true since on startup application is awake.
		// UTY
		private static var _s						:String;
		private static var _w						:NativeWindow;
		private static var _j						:*;
		private static var _x						:XML;
		private static var _node					:XML;
	// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init					(mainApp:_Application, newSize:Rectangle=null):void {
			Debug.debug(_debugPrefix, "Initializing UAir");
			// This has to be called by Air application elements to initiazlize to initialize this object
			addNativeWindowOptions("default", {maximizable:true, minimizable:false, resizable:false, transparent:false, systemChrome:"standard", type:"utility"});
			addNativeWindowOptions("minimal", {maximizable:true, minimizable:false, resizable:false, transparent:false, systemChrome:"none", type:"lightweight"});
			addNativeWindowOptions("full", {maximizable:true, minimizable:true, resizable:true, transparent:false, systemChrome:"standard", type:"normal"});
			// Create references
			_nativeWindow = UGlobal.stage.nativeWindow;
			_nativeApplication = NativeApplication.nativeApplication;
			// Set size and dimensions if anyà
			if (_nativeWindow && newSize) { // On device native window is not available
				Debug.debug(_debugPrefix, "Updating application size and position: " + newSize);
				_nativeWindow.x = newSize.x;
				_nativeWindow.y = newSize.y;
				_nativeWindow.width = newSize.width;
				_nativeWindow.height = newSize.height;
			}
			// Grab application data
			var descriptor:XML = _nativeApplication.applicationDescriptor;
			var ns:Namespace = descriptor.namespace();
			_applicationFile = descriptor.ns::filename[0];
			_applicationName = descriptor.ns::name[0];
			_applicationVersion = descriptor.ns::versionNumber[0];
			_applicationId = _nativeApplication.applicationID;
			// Setup variables
			_bestFramerate = UGlobal.stage.frameRate;
			// Setup debug things
			if (mainApp.isDebug()) {
				// Create debug text field
				_debugTextField = new TextField();
				_debugTextField.y = UGlobal._sh - 10;
				_debugTextField.border = true;
				UText.setTextFormat(_debugTextField, {bold:true, font:"_sans", color:0xff0000});
				UText.makeTextFieldAutoSize(_debugTextField);
				_debugTextField.wordWrap = false;
				_debugTextField.multiline = false;
			}
			// Setup ACTIVE INACTIVE listeners
			addSleepListener(onApplicationInactive);
			addWakeListener(onApplicationActive);
			_nativeApplication.addEventListener(Event.EXITING, onApplicationExiting);
			_nativeApplication.executeInBackground = false;
			//trace("NATIVE WINDOW");
			//trace(_nativeWindow);
			//trace(NativeApplication);
			//trace(UGlobal.stage);
			if (NativeWindow.isSupported) { // NativeWindow is supported only on desktop
				_nativeWindow.addEventListener(Event.CLOSING, onApplicationClosing);
				_nativeWindow.addEventListener(Event.CLOSE, onApplicationClosed);
			}
// 			_nativeApplication.addEventListener		(Event.ACTIVATE, onApplicationActive);
// 			_nativeApplication.addEventListener		(Event.DEACTIVATE, onApplicationInactive);
			// AUDIO MODE
			if (SoundMixer.audioPlaybackMode) {
				SoundMixer.audioPlaybackMode = PLAYBACK_MODE;
			}
			// DPI AND OPTIMAL SCALE
			var myRatio:Number = uint(USystem.getDPI()) / REAL_PIXEL_DPI;
			Debug.debug						(_debugPrefix, "DPI: " + USystem.getDPI() + ", Ratio is:" + myRatio);
			if (myRatio > OPTIMAL_PIXEL_RATIO) {
				_optimalScale = myRatio/OPTIMAL_PIXEL_RATIO;
				Debug.debug(_debugPrefix, "Ratio is higher than optimal. Optimal scale is:"+_optimalScale);
			}
			// Set scale multiplier according to resolution
			// Multiply optimal scale according to device resolution (BETA - now this is handmade here, but it will be set in config)
			if (USystem.isDevice()) { // Resolution optimazer is used only on devices
				var res:Point = USystem.getResolution();
				Debug.debug(_debugPrefix, "Device resolution:",res);
				// find ipad 3
				if ((res.x >= 2048 || res.y >= 2048) && (res.x >= 1536 || res.y >= 1536)) { // Found an IPad 3 - 
					Debug.debug(_debugPrefix, "I am runnin on an IPAD3 or similar...");
					_scaleMultiplier = 2;
				}
				else if ((res.x >= 1024 || res.y >= 1024) && (res.x >= 768 || res.y >= 768)) {
					Debug.debug(_debugPrefix, "I am runnin on an IPAD2 or similar...");
					_scaleMultiplier = 1.1;
				}
			}
			Debug.debug(_debugPrefix, "Optimal scale is:", _optimalScale, ". Multiplier is:",_scaleMultiplier);
			_optimalScale *= _scaleMultiplier;
			if (_scaleMultiplier != 1) Debug.debug(_debugPrefix, "Final Optimal scale is:",_optimalScale);
			// Create device unique id
// 			createDeviceUniqueId				();
			// Set to active
			setToSleep(false);
		}
		
		
		
				// Creates a device unique ID starting from MAC ADDRESS if available
// 				private static function createDeviceUniqueId():void { 
// 					if (NetworkInfo.isSupported) {
// 						var network:NetworkInfo 	= NetworkInfo.networkInfo;
// 						for each (var object:NetworkInterface in network.findInterfaces()) {
// 						}
// 					}
// 				}
	// PERFORMANCE ///////////////////////////////////////////////////////////////////////////////////////
		public static function setToSleep				(sleep:Boolean):void {
			if (sleep) {
				if (FRAMERATE_CHECK_ACTIVE)		setFrameRatecheckActive(false);
			}
			else {
				if (FRAMERATE_CHECK_ACTIVE)		setFrameRatecheckActive(true);
			}
		}
			public static function setFrameRatecheckActive(a:Boolean, traceFramerateSeconds:uint=0):void {
				if (FORCE_FRAMERATE_LEVEL) {
					_framerateLevel				= FORCE_FRAMERATE_LEVEL_MODE;
					_isShitFramerate				= _framerateLevel == "WORSE";
					return;
				}
				if (a) {
					resetFrameRateCheck();
					UExec.addEnterFrameListener(onEnterFrame);
				}
				else {
					UExec.removeEnterFrameListener(onEnterFrame);
				}
				if (traceFramerateSeconds) traceAverageFramerate(traceFramerateSeconds);
			}
			public function get averageFramerate():Number {
				return _averageFramerate;
			}
			private static function onEnterFrame		(e:Event):void {
				_framesCounter					++;
				// trace(1);
				if (_framesCounter == CHECK_FRAMERATE_FRAMES) {
					var time					:uint = getTimer() - _lastCheckTimer;
					_averageFramerate			= (_framesCounter*1000) / ((getTimer() - _lastCheckTimer));
					var ratio					:Number = _averageFramerate/_bestFramerate;
					_framerateLevel				= ratio > 0.8 ? "BEST" : ratio > 0.5 ? "OK" : "WORSE";
					_isShitFramerate				= _framerateLevel == "WORSE";
					resetFrameRateCheck			();
					if (UGlobal.isDebug) {
						UGlobal.stage.addChild(_debugTextField);
						_debugTextField.text = _framerateLevel + ":" + _averageFramerate;
						
					//trace(_framerateLevel + ":" + _averageFramerate);
					}
				}
			}
				private static function resetFrameRateCheck():void {
					_lastCheckTimer				= getTimer();
					_framesCounter				= 0;
				}
				static private function traceAverageFramerate(secs:uint = 0):void {
					Debug.debug(_debugPrefix, "Average framerate: " + _averageFramerate);
					if (secs) UExec.time(secs, traceAverageFramerate, secs);
				}
	// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		public static function addNativeWindowOptions		(id:String, options:Object):void {
			// this adds a style of NativeWindow to be used in getNativeWindow or getHtmlWindow
			// {maximizable:false, minimizable:false, resizable:false, transparent:false, systemChrome:"standard,none,alternate", type:"normal,utility,lightweight"}
			_j								= new NativeWindowInitOptions();
			UCode.setParameters					(_j, options);
			NATIVE_WINDOW_OPTIONS[id]			= _j;
		}
		public static function getActiveWindow			():NativeWindow {
			return							_nativeWindow;
		}
		public static function getApplication():NativeApplication {
			return _nativeApplication;
		}
		public static function getId					():String {
			if (_nativeApplication) return							_nativeApplication.applicationID;
			else {
				Debug.error(_debugPrefix, "getId() cannot return id, because _bativeApplication is not defined");
				return "Dummy_Application_ID";
			}
		}
	// CLIPBOARD ///////////////////////////////////////////////////////////////////////////////////////
		public static function copyTextToClipboard		(t:String):void {
			Clipboard.generalClipboard.clear			(); 
			Clipboard.generalClipboard.setData		(ClipboardFormats.TEXT_FORMAT, t, false); 
		}
		public static function readTextFromClipboard		():* {
			if (Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT)){ 
				return 						Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT); 
			}
			else								return "";
		}
	// SLEEP AND AWAKE ///////////////////////////////////////////////////////////////////////////////////////
		public static function setToKeepAwake(keepAwake:Boolean=true):void {
			try {
				if (keepAwake) {
					NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
					Debug.warning(_debugPrefix, "Application is set to stay always awake.");
					//_nativeApplication.systemIdleMode 	= SystemIdleMode.KEEP_AWAKE;
					addSleepListener(onKeepAwakeApplicationSleep);
					addWakeListener(onKeepAwakeApplicationWake);
				} else {
					NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
					Debug.warning(_debugPrefix, "Application removed keep awake.");
					//_nativeApplication.systemIdleMode 	= SystemIdleMode.KEEP_AWAKE;
					removeSleepListener(onKeepAwakeApplicationSleep);
					removeWakeListener(onKeepAwakeApplicationWake);
				}
			}
			catch (e:Error) {
				Debug.error(_debugPrefix, "Cannot setToKeepAwake() " + e);
			}
		}
		//  LISTENERS FOR KEEP AWAKE STATE
		static private function onKeepAwakeApplicationSleep(e:Event):void {
			Debug.debug(_debugPrefix, "Removig keep awake.");
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
		}
		static private function onKeepAwakeApplicationWake(e:Event):void {
			Debug.debug(_debugPrefix, "Activating keep awake.");
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
		}
		
		
		
		public static function fixAndroidBlackScreen():void {
			// This fixes an annoying bug of android, that when a device goes in sleep mode, when the app returns alive the screen is black
			// Fix is applied by changing render mode of screen when device is reactivated
			_fixAndroidBlackScreen = true;
		}
		public static function addSleepListener(f:Function):void {
			_nativeApplication.addEventListener(Event.DEACTIVATE, f);
		}
		public static function removeSleepListener(f:Function):void {
			_nativeApplication.removeEventListener(Event.DEACTIVATE, f);
		}
		public static function addWakeListener(f:Function):void {
			_nativeApplication.addEventListener(Event.ACTIVATE, f);
		}
		public static function removeWakeListener(f:Function):void {
			_nativeApplication.removeEventListener(Event.ACTIVATE, f);
		}
		// INTERNAL LISTENERS FOR APPLICATION STATE
		private static function onApplicationActive(e:Event):void {
			Debug.debug(_debugPrefix, "Application ACTIVE");
			_awake = true;
			if (_fixAndroidBlackScreen) {
				Debug.debug(_debugPrefix, "Setting stage quality to " + _defaultStageQuality);
				UGlobal.stage.quality = _defaultStageQuality;
			}
		}
		private static function onApplicationInactive(e:Event):void {
			Debug.debug(_debugPrefix, "Application SLEEP");
			_awake = false;
			if (_fixAndroidBlackScreen) {
				_defaultStageQuality = UGlobal.stage.quality;
				var q:String = _defaultStageQuality == StageQuality.LOW ? StageQuality.MEDIUM : StageQuality.LOW;
				Debug.debug(_debugPrefix, "Setting stage quality to " + q);
				UGlobal.stage.quality = q;
			}
			if (USystem.isIOS()) {
				Debug.warning(_debugPrefix, "Application went in background on iOS, if a NetStream is active app will crash wehn restored. Remember to set and restore app position on startup.");
			}
		}
		static private function onApplicationClosing(e:Event):void {
			Debug.debug(_debugPrefix, "CLOSING");
		}
		static private function onApplicationClosed(e:Event):void {
			Debug.debug(_debugPrefix, "CLOSED");
		}
		static private function onApplicationExiting(e:Event):void {
			Debug.debug(_debugPrefix, "EXITING");
			PippoFlashEventsMan.broadcastStaticEvent(UAir, EVT_EXITING);
		}
	// APPLICATION ///////////////////////////////////////////////////////////////////////////////////////
		public static function quit					():void { // Just brutally quits the application
			Debug.debug(_debugPrefix, "Quit application.");
			_nativeApplication.exit					();
		}
		public static function getApplicationDescription		():Object {
			return							{FILE:_applicationFile, NAME:_applicationName, VERSION:_applicationVersion};
		}
		static public function getApplicationVersion():String {
			return _applicationVersion;
		}
	// SIE, RATIO AND DPI ///////////////////////////////////////////////////////////////////////////////////////
		public static function getOptimalScale():Number {
			return _optimalScale;
		}
		static public function getOptimalScaleRelativeToUGlobal():Number {   
			return UGlobal.getContentScale() * _optimalScale;
		}
	// UNIQUE IDs ///////////////////////////////////////////////////////////////////////////////////////
		public static function getMacAddress			(n:uint=0, traceInfo:Boolean=false):String {
			var vNetworkInterfaces:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces();
			if (vNetworkInterfaces.length) {
				if (traceInfo) {
					for each (var networkInterface:NetworkInterface in vNetworkInterfaces) {
					    trace(networkInterface.name  + " : " + networkInterface.displayName + " : " + networkInterface.hardwareAddress);
					}
				}
				return						vNetworkInterfaces[n].hardwareAddress;
			}
			return							"NoNetworkInterfaceFound_"+Math.random();
		}
	// WINDOWS ///////////////////////////////////////////////////////////////////////////////////////	
		private static var _htmlListeners:Array = []; // Stores the listeners for HTMLs
		public static function getNativeWindow(pars:Object=null, options:String="default", listener:*=null):NativeWindow {
			// options can be a string with some predefined IDs of window options, or
			_w = new NativeWindow(NATIVE_WINDOW_OPTIONS[options]);
			UCode.setParameters(_w, pars);
			_w.stage.align = "TL";
			_w.stage.scaleMode = "noScale";
			return _w;
		}
		public static function getHtmlWindow			(pars:Object=null, options:String="default", listener:*=null):NativeWindow { // returns a window with on depth 0 has as child and HTMLLoader object
// 			_j								= new HTMLLoader();
			_j								= HTMLLoader.createRootWindow(false, NATIVE_WINDOW_OPTIONS[options], true);
// 			_w								= _j.stage.nativeWindow;
// 			UCode.setParameters					(_w, pars);
// 			_j.width							= _w.stage.stageWidth;
// 			_j.height							= _w.stage.stageHeight;
// 			_w.stage.addChildAt					(_j, 0);
			var u								:String = "http://www.facebook.com/login.php?api_key=61557b5a6dcded9da8a6a85a53ad24b5&next=http://www.facebook.com/connect/login_success.html&cancel_url=http://www.facebook.com/connect/login_failure.html&display=popup&session_key_only=true&fbconnect=true&req_perms=read_stream,publish_stream,read_mailbox,offline_access&connect_display=popup&nochrome=true&return_session=true&v=1.0";
// 			var u								:String = "https://www.facebook.com/dialog/oauth?client_id=152901114768593&redirect_uri=http://www.facebook.com/connect/login_success.html&connect_display=popup&nochrome=true";
// 			_j.load							(new URLRequest(u));
			_j.addEventListener					(Event.COMPLETE, onHtmlEvent, false, 0, true);
			_j.addEventListener					(Event.LOCATION_CHANGE, onHtmlEvent, false, 0, true);
			return							_w;
		}
		public static function onHtmlEvent				(e:Event):void {
			trace(e);
			trace(e.target.location);
			if (e.target.location.indexOf("http://www.facebook.com/connect/login_success.html") == 0) trace("SUCCESSSSSSSSSSSSSSSSSSSSSS");
			else if (e.target.location.indexOf("http://www.facebook.com/connect/login_failure.html") == 0) trace("FAILUREEEEEEEEEEEEEEEEEEEEEEEEEEE");
			
		}
		public static function addHtmlListener			(listener:*):void {
			if (_htmlListeners.indexOf(listener) == -1)	_htmlListeners.push(listener);
		}
		public static function removeHtmlListener		(listener:*):void {
			UCode.removeArrayItem				(_htmlListeners, listener);
		}
		// 	addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):
	// MENU ///////////////////////////////////////////////////////////////////////////////////////
		private static var _menuNode				:XML; // Stores the XML complete menu node
		private static var _menuSection				:String; // Stores the selected menu section name
		private static var _menuListeners				:Array = []; // Stores the listeners for MENUs
		private static var _myNativeMenu				:NativeMenu;
		public static function setMenuContent			(menu:XML, section:String="ALL"):void { // This sets the menu content
			_menuNode							= menu;
			setMenuSection						(section);
			/* Renders a menu XML node formatted:
				<SYSTEMMENU>
					<ALL><!-- These will always be visible. Duplicates from other nodes will be added -->
						<GROUP label="ArabGames" id="SystemMain"><!-- id="SystemMain" means that on Mac, this will be added to the application menu. -->
							<ITEM label="Visit www.ArabGames.com" data="website" /> 
							<ITEM label="Quit ArabGames" data="quit" /> 
							<ITEM label="Log Out" action="data" />
						</GROUP>
						<GROUP label="About Me">
							<ITEM label="My Game Info" data="playerInfo" /> 
						</GROUP>
					</ALL>
					<LOBBY>
					</LOBBY>
					<GAME>
						<GROUP label="Game Table">
							<ITEM label="Leave Table" data="leave" /> 
						</GROUP>
					</GAME>
				</SYSTEMMENU>
			*/
		}
		public static function setMenuSection			(section:String):void { // Sets a section MENU from content
			if (_menuNode == null) 				Debug.debug(_debugPrefix, "ERROR - Cen't set menu section. Menu content is not defined.");
			else if (!_menuNode[section])			Debug.debug(_debugPrefix, "ERROR - Cen't set menu section:",section,". Section name has not been found.");
			else if (section != _menuSection) { // Seems like menu went through, and it wasn't set before
				_menuSection					= section;
				renderMenuNode					(_menuNode[_menuSection][0]);
			}
		}
		public static function renderMenuNode			(node:XML):void { // Renders directly a menu node
			if (!NativeMenu.isSupported) { // Native Menu is not supported
				Debug.debug					(_debugPrefix, "ERROR - Can't set native menu. AIR profile doesn't support it on this device.");
				return;
			}
			// Native menu is supported, proceed.
			_myNativeMenu						= new NativeMenu();
			renderMenuNodeRecursive				(_myNativeMenu, node);
			// Apply menu to window or application depending on OS
			if (NativeWindow.supportsMenu) {
				Debug.debug					(_debugPrefix, "MENU - Setting NativeWindow menu.");
				_nativeWindow.menu				= _myNativeMenu;
			}
			if (NativeApplication.supportsMenu) {
				Debug.debug					(_debugPrefix, "MENU - Setting NativeApplication menu.");
				_nativeApplication.menu			= _myNativeMenu;
			}
			/* Renders a menu XML node formatted:
				<GAME>
					<GROUP txt="Game Table">
						<ITEM txt="Leave Table" action="leave" /> 
					</GROUP>
				</GAME>
			*/
		}
				private static function renderMenuNodeRecursive(parentMenu:NativeMenu, node:XML):void {
					for each (var item:XML in node.children()) {
						if (item.name() == "GROUP") {
							Debug.debug			(_debugPrefix, "Adding Menu",item.@label);
							var menuGroup			:NativeMenu = new NativeMenu();
							parentMenu.addSubmenu	(menuGroup, item.@label);
							renderMenuNodeRecursive	(menuGroup, item);
						}
						else if (item.name() == "ITEM") {
							Debug.debug			(_debugPrefix, "Adding Item",item.@label);
							var menuItem			:NativeMenuItem = new NativeMenuItem(item.@label);
							menuItem.data			= item;
							menuItem.addEventListener	(Event.SELECT, onMenuItemPressed, false, 0, true);
							parentMenu.addItem		(menuItem);
						}
					}
				}
		// PROCESS MENU CALL -------------------------------------------------------------------
		// CALL A FUNCTION IN LISTENERS: <ITEM type="function" target="listener" id="callId" data="now" /> --- Calls: listener.onNativeMenuSelected_callId("now");
		// CALL A FUNCTION IN LISTENERS: <ITEM type="function" target="listener" data="now" /> --- Calls: listener.onNativeMenuSelected(xmlItemNode); - If id is not specified, generic func is called. If data is not specified, all node is sent as param
		// CALL A FUNCTION IN Uair: <ITEM type="function" id="quit" data="now" /> --- Calls: UAir.quit("now"); - if data isnot specified, no function parameters are sent
		// OPEN A LINK: <ITEM type="link" target="_blank" url="http://......" /> --- Opens a link node... basically sends all the link to UCode.processLinkNode()
		// CALL A JAVASCRIPT: <ITEM url="http://www.pippolfash.com" type="javascript" func="jsRegister" params="param1,param2,param3" /> --- Calls a JS in the page: UCode.processLinkNode()
				public static function onMenuItemPressed	(e:Event):void {
					var menuNode					:XML = e.target.data is XMLList ? e.target.data[0] : e.target.data;
					var hasData					:Boolean = UXml.hasFullAttribute(menuNode, "data");
					if (menuNode.@type.toLowerCase() == "function") { // Call function in listeners
						if (UXml.hasFullAttribute(menuNode, "target") && menuNode.@target.toLowerCase() == "listener") { // Call a function in LISTENERS
							var funcId				:String = UXml.hasFullAttribute(menuNode, "id") ? "_"+menuNode.@id : ""; // Define the correct func ID, or just call a generic function
							if (hasData) 			UCode.callGroupMethod(_menuListeners, "onNativeMenuSelected"+funcId, menuNode.@data);
							else					UCode.callGroupMethod(_menuListeners, "onNativeMenuSelected"+funcId, menuNode);
						} else { // Calling a function in UAir
							if (hasData) 			UCode.callMethod(UAir, menuNode.@id, menuNode.@data);
							else					UCode.callMethod(UAir, menuNode.@id);
						}
					}
					if (menuNode.@type.toLowerCase() == "link" || menuNode.@type.toLowerCase() == "javascript") { // Call LINK in UCode
						UCode.processLinkNode		(menuNode);
					}
				}
		public static function addMenuListener			(listener:*):void {
			if (_menuListeners.indexOf(listener) == -1)	_menuListeners.push(listener);
		}
		
		static public function get nativeWindow():Object 
		{
			return _nativeWindow;
		}
		
		static public function get applicationVersion():String 
		{
			return _applicationVersion;
		}
		
		static public function get applicationId():String 
		{
			return _applicationId;
		}
		/**
		 * If Application is awake and not in background.
		 */
		static public function get awake():Boolean 
		{
			return _awake;
		}
		
		public static function removeMenuListener		(listener:*):void {
			UCode.removeArrayItem				(_menuListeners, listener);
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