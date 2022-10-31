/* _Application - Provides base functionalities for applications */
/* Usage

override initOnStage();  // Performs initialization when stage is available - FACULTATIVE

TO START THE APPLICATION
override init(); // Initializes the following frame after stage is available

*/

package com.pippoflash.framework {
// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import com.pippoflash.framework.*; import com.pippoflash.framework.air.*; import com.pippoflash.utils.*; import com.pippoflash.smartfox.SmartFoxMan; import com.pippoflash.net.QuickLoader; // PippoFlash
	import flash.display.*; import flash.events.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*; import flash.geom.*; import flash.external.*;// FLash
	import flash.profiler.*;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	//import flash.events.FullScreenEvent;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public dynamic class _ApplicationAir extends _Application {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC - DEBUG SWITCHES
		protected static var USE_AIR				:Boolean = false; // To work in AIR, in class that extends, set this to true. NOT HERE - IN EXTENDED MAINAPP - This defaults to fals ein order to manage to export also for SWF
		//static protected var TRIGGER_ERROR_IS_UAIRFAKE_ON_DEVICE:Boolean = false;
		protected static var GRAB_LANGUAGE_FROM_DEVICE:Boolean = true; // Tells the application to grab language from a device (if false, uses default language set in _Application)
		protected var FULLSCREEN:Boolean = false; // If app goes fullscreen
		protected var FULLSCREEN_DRAG_AND_CLICK:Boolean = false; // If before going fullscreen we have to tap on screen
		protected var SWITCH_TO_DEBUG_RESOLUTION:Boolean = false;
		//protected var DEBUG_RESOLUTION:Rectangle = new Rectangle(0, 0, 1920, 1080); // 1080
		//protected var DEBUG_RESOLUTION:Rectangle = new Rectangle(0, 0, 960, 540); // 1080 50%
		//protected var DEBUG_RESOLUTION:Rectangle = new Rectangle(0, 0, 2048, 1536); // IPAD3
		protected var DEBUG_RESOLUTION:Rectangle = new Rectangle(0, 0, 1024, 768); // IPAD3 50%
 		// STATIC CONSTANTS
		// SYSTEM
		// USER VARIABLES
		// HTML VARIABLES - FLASHVARS HAVE TO BE PUBLIC
		protected var _handshakeUrl					:String = "handshake.xml";
		// REFERENCES
		public var _uAir							:*; // Reference to UAir or UAirFake - I have to set it manually, to override compiler errors
		// STAGE INSTANCES
		// REFERENCE LISTS
		// MARKERS
		// DATA HOLDERS
		private var _handshake					:XML;
		// STATIC UTY
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function _ApplicationAir(id:String="_ApplicationAir", appId:String="PippoFlash Default App ID", appVer:String="0.00"):void {
			super(id, appId, appVer);
			// I internally use the UAir fake class, so that I can extend from this also from desktop apps. In the mainapp for air I will point this to the REAL UAir
			_uAir = UAirFake; // This is to be able to run projects also on Flash Player
		}
		protected override function initOnStage(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, initOnStage);
			initOnStageAIR();
		}
		private function initOnStageAIR():void {
			// Here initialization is according to FULLSCREEN status
			if (USystem.isDesktop() && FULLSCREEN && USE_AIR) {
				if (FULLSCREEN_DRAG_AND_CLICK) {
					createFullScreenDragScreen();
					return;
				}
				UExec.time(5, onFullScreenSafeTimeExpired);
				stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
				//UExec.time(0.5, stage.addEventListener, Event.RESIZE, onFullScreen);
				UGlobal.setFullScreen(true, stage);
				//UExec.time(0.5, UGlobal.setFullScreen, true, stage);
			} else {
				if (FULLSCREEN) Debug.warning(_debugPrefix, "Project is not running with USE_AIR, or is on device therefore fullscreencannot be activated.");
				initOnAIRScreenSetupComplete();
			}
		}	
				private var _fullScreenDragSprite:Sprite;
				private function createFullScreenDragScreen():void {
					_fullScreenDragSprite = UDisplay.getSquareSprite(stage.stageWidth, stage.stageHeight, 0xffffff);
					var txt:TextField = new TextField();
					txt.width = stage.stageWidth;
					txt.height = stage.stageHeight;
					txt.text = "Drag on target screen\nand tap to set fullscreen.";
					txt.scaleY = txt.scaleX = 5;
					//_fullScreenDragSprite.txt = txt;
					_fullScreenDragSprite.addChild(txt);
					stage.addChild(_fullScreenDragSprite);
					Buttonizer.setupButton(_fullScreenDragSprite, this, "StartupFullScreen");
					//_fullScreenDragSprite
				}
				public function onClickStartupFullScreen(c:Sprite):void {
					Debug.debug(_debugPrefix, "Setting at fullscreen.");
					FULLSCREEN_DRAG_AND_CLICK = false;
					Buttonizer.removeButton(_fullScreenDragSprite);
					stage.removeChild(_fullScreenDragSprite);
					_fullScreenDragSprite = null;
					initOnStageAIR();
				}
		private function onFullScreen(e:FullScreenEvent):void {
			Debug.debug("Fullscreen activated.");
			//return;
			UExec.removeMethod(onFullScreenSafeTimeExpired, "onFullScreenSafeTimeExpired");
			stage.removeEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			UExec.next(initOnAIRScreenSetupComplete);
		}
		private function onFullScreenSafeTimeExpired():void { // Checks whether fullscreen has not been activated
			Debug.debug(_debugPrefix, "Checking for fullscreen: " + UGlobal.isFullScreen(stage));
			if (UGlobal.isFullScreen(stage)) return;
			Debug.error(_debugPrefix, "FULLSCREEN ACTIVATION TIMED OUT, PROCEEDING WITHOUT FULLSCREEN.");
			initOnAIRScreenSetupComplete();
		}
		private function initOnAIRScreenSetupComplete():void {
			// We are using an AIR project
			if (USE_AIR) {
				initCommonFeatures();
				initAirFeatures();
				completeCommonInit();
			}
			// This is an SWF project in browser
			else {
				super.initOnStage();
			}
			_applicationId = _uAir.getId(); // If UAirFake this returns the same app ID, otherwise taken from app descriptor
		}
			protected function initAirFeatures():void {
				Debug.debug(_debugPrefix, "Initializing AIR only features.");
				// Setup debug resolution if necessary
				if (isDebug() && SWITCH_TO_DEBUG_RESOLUTION) {
					Debug.warning(_debugPrefix, "Switching to debug resolution: " + DEBUG_RESOLUTION);
					//_originalStageSize = DEBUG_RESOLUTION.clone();;
					//UGlobal.setOriginalSize(DEBUG_RESOLUTION);
					_uAir.init(this, DEBUG_RESOLUTION);
				}
				else _uAir.init(this);
				// Proceed
				USystem.report();
				// Grab language from USystem
				if (GRAB_LANGUAGE_FROM_DEVICE) {
					Debug.debug(_debugPrefix, "Setting locale language from device system. Default language is " + _language + ", system language is " + USystem.getLanguage(), true);
					_language = USystem.getLanguage();
				}
			}
			override protected function startApplication():void {
				super.startApplication();
				/* WARNING THIS IS HERE BECAUSE FOR SOME REASONS IT DOESNT CALL initAirFeaturs (on DESKTOP) */
				_uAir.addSleepListener(onApplicationSleep);
				_uAir.addWakeListener(onApplicationRestore);
			}
// METHODS and Overrides ///////////////////////////////////////////////////////////////////////////////////////
		public override function getAppId():String { // If it is an AIR app it will return AIR ID, otherwise the descriptor
			return USE_AIR ? _uAir.getId() : super.getAppId();
		}
		// This should always be overridden with this:
		//public override function ():UAirFake {
			//return _uAir as UAirFake;
		//}
		public function getUAir():UAirFake {
			return _uAir as UAirFake;
		}
		public function get uAir():UAirFake {
			return _uAir;
		}
// APPLICATION SLEEP IN BACKGROUND AND RESTORE - OVERRIDE THESE
		protected function onApplicationSleep(e:Event):void {
			// Called whan application sleeps
		}
		protected function onApplicationRestore(e:Event):void {
			// Called when application is restored
		}
// HANDSHAKE ///////////////////////////////////////////////////////////////////////////////////////
	// Handshake is optional. It can be called or skipped.
		protected function handshake				(path:String=null):void {
			_handshakeUrl						= path ? path : _handshakeUrl;
			Debug.debug						(_debugPrefix, "Loading handshake file:", _handshakeUrl);
			QuickLoader.loadFile					(_handshakeUrl, this, "Handshake");
		}
				public function onLoadErrorHandshake(o:*=null):void {
					Debug.error				(_debugPrefix, "Error loading handshake:", Debug.object(o));
					setMainLoader				(false);
					updateNoNetworkMessage		();
					promptOk					(_noNetworkMessage, _noNetworkTitle, retryHandshake);
				}
					private function retryHandshake():void { // This has to be èpostpone o avoid endless loops
						setMainLoader			(true);
						UExec.frame			(5, handshake);
					}
				public function onLoadCompleteHandshake(o:SimpleQueueLoaderObject):void {
					Debug.debug				(_debugPrefix, "Handshake loaded successfully.");
					_handshake				= UXml.getLoaderXML(o);
					onHandshake				();
				}
					protected function onHandshake	():void { // This analyzes handshake
						// Perform handshake analisys - before working on language, I check if handshake has to perform checks or not
						var defaultLang			:String = _handshake.VOCABULARY.@defaultLocale;
						var vocabulary			:XML = _handshake.VOCABULARY[_language][0];
						if (!vocabulary) {
							Debug.error		(_debugPrefix, "Vocabulary for " + _language + " not found! Reverting to default: " + defaultLang);
							vocabulary			= _handshake.VOCABULARY[defaultLang][0];
						}
						// Prepare check for application update
						var applicationExpired	:Boolean = false;
						// First check the FORCE_UPDATE way, then eventually the application version way
						if (UCode.isTrue(_handshake.SETTINGS.CHECK_FORCE_UPDATE.toString())) {
							Debug.debug		(_debugPrefix, "Checking if update is forced:",USystem.getDeviceType(),_handshake.SETTINGS.FORCE_UPDATE[USystem.getDeviceType()]);
							if (UCode.isTrue(String(_handshake.SETTINGS.FORCE_UPDATE[USystem.getDeviceType()]))) {
								Debug.error	(_debugPrefix, "Update is forced in this app for this device. Node is:",String(_handshake.SETTINGS.FORCE_UPDATE[USystem.getDeviceType()]));
								applicationExpired = true;
							}
						}
						// Check the application version way
						if (UCode.isTrue(_handshake.SETTINGS.CHECK_LATEST_VERSION.toString())) {
							// First find the ID of device in order to check version. 
							// IDs check against system type and device type. Device type first!
							var devType		:String = USystem.getDeviceType();
							var verNode		:XML = _handshake.SETTINGS.LATEST_VERSION_BY_DEVICE[devType][0];
							if (!verNode) {
								devType		= USystem.getSystemType();
								verNode		= _handshake.SETTINGS.LATEST_VERSION_BY_DEVICE[devType][0];
							}
							if (!verNode)		verNode = _handshake.SETTINGS.LATEST_VERSION[0];
							Debug.debug		(_debugPrefix, "Version node checked: " + verNode.toXMLString());
							var version		:String = String(verNode);
							if (version == _applicationVersion) {
								Debug.debug	(_debugPrefix, "Handshake Application Version is OK.");
							}
							else {
								Debug.error	(_debugPrefix, "Handshake application wrong. Actual is " + _applicationVersion + " while latest is " + verNode.toXMLString());
								applicationExpired = true;
							}
						}
						// Launch application update process
						if (applicationExpired) {
							processXmlPrompt	(vocabulary[_handshake.SETTINGS.PROMPT_IF_WRONG_VERSION[0].toString()][0]);
							setMainLoader		(false); // Just in case
							return;
						}
						// Proceed with application
						onHandshakeOk			();
					}
					protected function onHandshakeOk():void { // This is just to be overridden once handshake is loaded
					}
		// HANDSHAKE CALLBACKS
		public function onDownloadLatestApplicationAndQuit	():void {
			// Grabs download link from HANDSHAKE.SETTINGS.LATEST_VERSION_LINKS[ID]
			var node							:XML = _handshake.SETTINGS.LATEST_VERSION_LINKS[USystem.getDeviceType()][0];
			var link							:String = node ? node : _handshake.SETTINGS.LATEST_VERSION_LINKS.DEFAULT;
			// Here I have to download the latest app according to version of device
			Debug.debug						(_debugPrefix, "Downloading latest application: " + link);
			UCode.getBlankUrl					(link);
			UExec.next						(_uAir.quit); // If I quit now, the open URL commend is not invoked. Therefore I quite next frame.
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function quit						():void {
			_uAir.quit							();
		}
// ///////////////////////////////////////////////////////////////////////////////////////
// UTY //////////////////////////////////////////////////////////////////////////////////
// ///////////////////////////////////////////////////////////////////////////////////////
		public override function isShitFramerate		():Boolean { // WORSE and below
			return							_uAir._isShitFramerate;
		}
		public override function isGoodFramerate		():Boolean { // OK or BEST, just NOT shit
			return							!_uAir._isShitFramerate;
		}
		public override function isWorseFramerate		():Boolean { // WORSE
			return							_uAir._framerateLevel == "WORSE";
		}
		public override function isOkFramerate			():Boolean { // OK
			return							_uAir._framerateLevel == "OK";
		}
		public override function isBestFramerate		():Boolean { // BEST
			return							_uAir._framerateLevel == "BEST";
		}
		public override function getFramerate			():Number {
			return							_uAir._averageFramerate;
		}
		public override function getFramerateLevel		():String {
			return							_uAir._framerateLevel;
		}
		public function isLandscape					():Boolean {
			return							UGlobal._sw > UGlobal._sh;
		}
		public function isPortrait					():Boolean {
			return							UGlobal._sw < UGlobal._sh;
		}
// LOADER /////////////////////////////////////////////////////////////////////////////////////
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
// DEBUG LISTENERS  ///////////////////////////////////////////////////////////////////////////////////////
	}
}