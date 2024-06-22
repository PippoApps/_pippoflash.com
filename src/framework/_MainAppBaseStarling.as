/* _MainAppBaseAir - Is the main class for all export targets. This is extended by relevant MainApp classes for desktop or devices. */
/* Initialization 
*/

package framework {
// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import com.pippoflash.framework.*; 
	import com.pippoflash.framework.starling.*;
	import com.pippoflash.utils.*; // PippoFlash
	import com.pippoflash.net.PreLoader;
	import com.pippoflash.motion.PFMover; 
	import com.pippoflash.media.PFVideo; // PippoFlash
	import com.pippoflash.net.QuickLoader; 
	import flash.events.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*; import flash.geom.*; import flash.external.*;// FLash
	import com.pippoflash.framework.starling.StarlingMain;
	import starling.display.Sprite;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public dynamic class _MainAppBaseStarling extends _ApplicationStarling {
		// DEBUG SWITCHES
		//private static const LOCATION_URL:String = "http://abbeyrd.slnmedia.com/locations/xml"<;
		// SATIC VARIABLES
		private static var _mainAppInstance:_MainAppBaseStarling;
		// STATIC CONSTANTS //////////////////////////////////////////////////////////////////////////
		// MISC
		// INSTANCE CONSTANTS
		// EVENTS
		// EMBED VARIABLES
		// SYSTEM
		private var _starlingMain:StarlingMain;
		// MARKERS
		// DATA HOLDERS
		// REFERENCES
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function _MainAppBaseStarling(pfId:String, projId:String, ver:String):void {
			super(pfId, projId, ver); // I hardcode MainApp because I use it to retrieve instance
			_mainAppInstance = this;
			addClassReference(_debugPrefix, _MainAppBaseStarling);
			//Security.allowDomain("*");
			//Security.allowInsecureDomain("*");
			// CONSTANTS
			// SWITCHES
			//DEPLOY = true; // Set this to true, and all will be shut down (console, debug, verbose, etc.)
			//DEBUG = true; // Leave this to true. Just set DEPLOY to true before sending out.
			//RENDER_QUALITY = 3; // It should be 4, but there are visual glitches in latest version of chrome and latest flash player
			//FORCE_TRACE = true; // Also in DEPLOY mode, traces events to console
			if (DEPLOY) { // Stuff to do on DEPLOY: switch off all debug switches
				/* CHANGE DEBUG FLAGS HERE */
			}
			//else { // Stuff to do when NOT in deploy (usually initializes dummy data etc.)
			//}
			// Setup initialization variables here - I use null to use values taken from host swf
			//_stageAlign = StageAlign.TOP_LEFT;
			//_stageScaleMode = StageScaleMode.NO_SCALE;
			//_stageAlign = null; // StageAlign.TOP_LEFT;
			//_stageScaleMode = null; // "StageScaleMode.SHOW_ALL";
			// Setup prompts behaviour
			UGlobal.setToolTipActive(false);
			
			// Setup list of classes for initialization. These _ProjBase extension classes get initialized one on each frame before init() is called. To avoid device freeze initializing too much in one frame.
			// Setup application switches
			//BLOCK_CONSOLE = false;
			//SHOW_REDRAW_REGIONS = false;
			// Choose shared object ID name (can be overridden by SharedObject name set in Config).
			// _sharedObjectId = "/PippoApps/BuncoBonko/mainnn/019"
			// Uncaught error handler (retrieved from previous constructor)
			//loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtError);
			// Setup original stage size to create perfect resizin
			UGlobal.setOriginalSize(new Rectangle(0, 0, 640, 480)); // 3840 x 2160
		}
		// GETTERS
		static public function get instance():_MainAppBaseStarling {
			return _mainAppInstance as _MainAppBaseStarling;
		}
		
		public function get starlingMain():StarlingMain 
		{
			return _starlingMain;
		}
	// STARTING APPLICATION CHAIN
		override protected function init():void { // This is what is called after stage is available and all initialization is performed
			super.init();
			//USystem.printFullReport();
			//// Setup references
			///* HEre loadConfig can trigger start application. If I do not need a cofing file, I can just call it. */
			startApplication();
			//loadConfig(ProjConfig, false, _configUrl);
		}
		protected override function startApplication():void {
			super.startApplication();
			UExec.next(onApplicationStarted);
		}
		protected function onApplicationStarted():void {
		}
		protected function initStarling(starlingClass:Class):void {
			_starlingMain = new StarlingMain(_debugPrefix);
			_starlingMain.init(starlingClass, onStarlingReady);
		}
		protected function onStarlingReady():void { // Extend this in main app to know when starling is ready and initialized
			Debug.warning(_debugPrefix, "Starling application initialized.");
		}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// GETTERS & CHECKS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// INTERNAL UTY ////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DEBUG  ///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	}
}
