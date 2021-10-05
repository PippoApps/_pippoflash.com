/* _MainAppBaseAir - Is the main class for all export targets. This is extended by relevant MainApp classes for desktop or devices. */
/* Initialization 
*/

package framework {
// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import com.pippoflash.framework.*; 
	import com.pippoflash.utils.*; // PippoFlash
	import com.pippoflash.net.PreLoader;
	import com.pippoflash.motion.PFMover; 
	import com.pippoflash.media.PFVideo; // PippoFlash
	import com.pippoflash.net.QuickLoader; 
	import flash.display.*; import flash.events.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*; import flash.geom.*; import flash.external.*;// FLash
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public dynamic class _MainAppBaseAir extends _ApplicationAir {
		// DEBUG SWITCHES
		//private static const LOCATION_URL:String = "http://abbeyrd.slnmedia.com/locations/xml"<;
		// SATIC VARIABLES
		private static var _mainAppInstance:_MainAppBaseAir;
		// STATIC CONSTANTS //////////////////////////////////////////////////////////////////////////
		// MISC
		// INSTANCE CONSTANTS
		// EVENTS
		// EMBED VARIABLES
		// SYSTEM
		// MARKERS
		// DATA HOLDERS
		// REFERENCES
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function _MainAppBaseAir(pfId:String, projId:String, ver:String):void {
			super(pfId, projId, ver); // I hardcode MainApp because I use it to retrieve instance
			_mainAppInstance = this;
			addClassReference(_debugPrefix, _MainAppBaseAir);
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
			_stageAlign = StageAlign.TOP_LEFT;
			_stageScaleMode = StageScaleMode.NO_SCALE;
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
		static public function get instance():_MainAppBaseAir {
			return _mainAppInstance as _MainAppBaseAir;
		}
	// STARTING APPLICATION CHAIN
		override protected function init():void { // This is what is called after stage is available and all initialization is performed
			super.init();
			USystem.printFullReport();
			// Setup references
			/* HEre loadConfig can trigger start application. If I do not need a cofing file, I can just call it. */
			startApplication();
			//loadConfig(ProjConfig, false, _configUrl);
		}
		protected override function startApplication():void {
			super.startApplication();
			UExec.next(onApplicationStarted);
		}
		protected function onApplicationStarted():void {
			
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
