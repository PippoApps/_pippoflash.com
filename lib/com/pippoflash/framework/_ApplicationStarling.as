/* _Application - Provides base functionalities for applications */
/* Usage

override initOnStage();  // Performs initialization when stage is available - FACULTATIVE

TO START THE APPLICATION
override init(); // Initializes the following frame after stage is available

*/

package com.pippoflash.framework {
	import com.pippoflash.net.SimpleQueueLoaderObject;
	import starling.display.Canvas;
// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import com.pippoflash.movieclips.loaders._LoaderBase;
	import starling.events.Event;
	import starling.core.Starling;
	import com.pippoflash.framework.starling.*;
	import com.pippoflash.utils.*;
	import starling.display.DisplayObject;
	import com.pippoflash.framework.prompt._Prompt;
	import flash.display3D.Context3DProfile;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public dynamic class _ApplicationStarling extends _ApplicationAir {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		static protected var SHOW_STARLING_STATS:Boolean = true;
		private var _starlingInitialized:Boolean = false;
		protected static var _starling:Starling;
		//private var _starlingReadyMethod:Function;
		private static var _instance:_ApplicationStarling;
		static private var _starlingShield:Canvas; // Shield to be added to loader to block clicks also in starling (regular loader only blocks them in DisplayList)
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function _ApplicationStarling(id:String="_ApplicationStarling", appId:String="PippoFlash Default App ID", appVer:String="0.00"):void {
			super(id, appId, appVer);
			// I internally use the UAir fake class, so that I can extend from this also from desktop apps. In the mainapp for air I will point this to the REAL UAir
			//_uAir								= UAirFake;
			_instance = this;
		}
		override protected function switchOffDebugSwitchesOnDeploy():void{
			super.switchOffDebugSwitchesOnDeploy();
		}


		/* FOR A STARLING APPLICATION, AFTER APPLICATION STARTED, WE MUST CALL initStarlingFeatures() and HANDLE STARLING INT IN THE CALLBACK readyMethod */
		
		// This has to be called after all initialization outside of starling happened
		protected function initStarlingFeatures(starlingClass:Class):void {
			_starlingInitialized = true;
			Debug.debug(_debugPrefix, "Initiated starling with app: " + starlingClass);
			//_starlingReadyMethod = readyMethod;
			//_starling = new Starling(starlingClass, UGlobal.stage, null, null, "auto", Context3DProfile.STANDARD);
			_starling = new Starling(starlingClass, UGlobal.stage);
			_starling.supportHighResolutions = true;
			setupStarlingDefaults();
			_starling.addEventListener(Event.ROOT_CREATED, onRootCreated);
			_starling.start();
			//return;
			//_uAir.addSleepListener(onAppGoesToSleep);
			//_uAir.addWakeListener(onAppGoesToSleep);
			
		}
				
		override public function setMainLoader(b:Boolean, t:String = "", sqlo:SimpleQueueLoaderObject = null, shield:Boolean = true, onComplete:Function = null):_LoaderBase {
			//if (_starling) _starling.stage.touchable = !b;
			if (_starling) {
				resizeShield();
				if (b) _starling.stage.addChild(_starlingShield);
				else _starlingShield.removeFromParent();
			}
			return super.setMainLoader(b, t, sqlo, shield, onComplete);
		}
				
		protected function setupStarlingDefaults():void { // Override this to setup antialias etc.
			_starling.antiAliasing = 8;
			_starling.skipUnchangedFrames = true;
			_Prompt._defaultContainer = _starling.nativeStage;
		}
		
		private function onRootCreated(event:starling.events.Event, root:_StarlingApp):void {
			Debug.debug(_debugPrefix, "Starling initialized: " + event);
			if (DEPLOY) SHOW_STARLING_STATS = false;
			_starling.showStats = SHOW_STARLING_STATS;
			Debug.warning(_debugPrefix, "Starling initialized with profile: " + _starling.profile);
			_starling.stage3D.context3D.ignoreResourceLimits = true;
 			//return;
			_starlingShield = new Canvas();
			_starlingShield.beginFill(0xff0000);
			_starlingShield.drawRectangle(0, 0, 100, 100);
			_starlingShield.alpha = 0;
			//return;
			_StarlingApp.instance.start(); // 'start' needs to be defined in the 'Game' class
			//if (_starlingReadyMethod) UExec.next(_starlingReadyMethod);
			//_starlingReadyMethod = null;
		}
		
		public function onStarlingAppReady():void { // Called by _StarlingApp once all starling setup is complete
			// This is where all logic starts
			/* CALL THIS TO START APPLICATION AFER ALL STARILING CONTENT IS SETUP */
		}
		
		
		
		
		// OVERRIDES ///////////////////////////////////////////////////////////////////////////////////////
		override public function resetScreenSaverCount():void { // Adds screensaver flow or Starglin Application and helpers
			super.resetScreenSaverCount();
			if (_hasScreensaver) {
				StarlingGesturizer.setGeneralOnGesture(onGeneralClickOrGesture);
			} 
		}
		
		
		
		
		
		
		
		
		
		
		
		
		override protected function onMainAppResize():void 
		{
			super.onMainAppResize();
			resizeShield();
		}
		private function resizeShield():void {
			if (_starlingShield) {
				_starlingShield.width = UGlobal.W;
				_starlingShield.height = UGlobal.H;
			}
		}
		
		
		static public  function get instance():_ApplicationStarling {
			return _instance;
		}
		static public  function get starlingInstance():Starling {
			return _starling;
		}
		static public function get skipUnchangedFrames():Boolean {
			return _starling.skipUnchangedFrames;
		}
		static public function set skipUnchangedFrames(skip:Boolean):void {
			_starling.skipUnchangedFrames = skip;
		}

// METHODS and Overrides ///////////////////////////////////////////////////////////////////////////////////////
// ///////////////////////////////////////////////////////////////////////////////////////
// UTY //////////////////////////////////////////////////////////////////////////////////
// ///////////////////////////////////////////////////////////////////////////////////////
// LOADER /////////////////////////////////////////////////////////////////////////////////////
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
// DEBUG LISTENERS  ///////////////////////////////////////////////////////////////////////////////////////
	}
}