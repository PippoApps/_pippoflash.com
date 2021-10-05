package com.pippoflash.framework.starling 
{
	import com.pippoflash.motion.PFMover;
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	import com.pippoflash.utils.*;
	import starling.utils.Color;
	//import flash.net.NetConnection;
	//import flash.net.NetStream;
	import starling.display.Image;
	import starling.textures.Texture;
	import starling.assets.AssetManager;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import com.pippoflash.framework._ApplicationStarling;
	
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * This is the main to extend in order to run starling content.
	 * Starling activity happens inside this controlled by it's extension.
	 */
	public class _StarlingApp extends _StarlingBase {
		
		// STATIC
		private static var _instance:_StarlingApp;
		static private var _initialAssets:Array = []; // This adds initial assets to first queue
		// INITIALIZATION VARIABLES
		static protected var _assetsRoot:String = "_assets/"; // Assets loading root, this can be set as a static setter from main app
		// SYSTEM
		

		 
		// INIT
		public function _StarlingApp(id:String="_MainStarling", framerate:int=60) {
			super(id, _StarlingApp);
			Debug.debug(_debugPrefix, "Starling Application Initialized.");
			//_starling = new Starling(StarlingApp, UGlobal.stage);
			//_starling.start();
			Starling.current.nativeStage.frameRate = framerate;
			_instance = this;
			//UExec.next(initStarlingApp);
		}

		
		// STATIC GETTERS
		static public function get instance():_StarlingApp {
			return _instance;
		}
		static public function get contentScale():Number {
			return _instance.scale;
		}
		
		// START
		public function start():void { // This happens when all is ready
			// THIS IS CALLED FROM OUTSIDE WHEN STARLING CONTEXT IS READY
			// ADD ASSETS TO BE PRELOADED BEFORE CALLING THIS WITH super.start();
			Debug.debug(_debugPrefix, "Application START.");
			//trace(Starling.VERSION);
			//mainAssets.enqueueSingle("file.png", "file.png");
			
			//return;
			if (mainAssets.numQueuedAssets) UExec.next(loadInitialAssets, onIntialSetupReady, onAssetsLoadError, onAssetsLoadProgress);
			else UExec.next(onIntialSetupReady);
		}
		// INITIAL ASSETS PRELOAD
		// Call these to add any initial asset when instantiating instance
		protected static function addInitialAssets(assets:Array, useFullPathAsReference:Boolean=false, pathPrefix:String=""):void {
			for each (var a:String in assets) addInitialAsset(pathPrefix+a, useFullPathAsReference);
		}
		protected static function addInitialAsset(asset:String, useFullPathAsReference:Boolean=false):void {
			var a:String = _assetsRoot + asset;
			//Debug.debug("_StarlingBase", "Adding asset to preload: " + a);
			if (useFullPathAsReference) mainAssets.enqueueSingle(a, a);
			else mainAssets.enqueueSingle(_assetsRoot + asset);
		}
		// Load assets flow
		private function loadInitialAssets(sucessFunc:Function, errorFunc:Function, progressFunc:Function = null):void { // This will be calle donly once at startup automatically
			//return;
			Debug.debug("_StarlingApp", "Loading initial assets: " + mainAssets.numQueuedAssets);
			UExec.next(mainAssets.loadQueue, sucessFunc, errorFunc, progressFunc);
			//mainAssets.loadQueue(sucessFunc, errorFunc, progressFunc);
		}
		private function onAssetsLoadError(error:String):void {
			Debug.error("_StarlingBase", "Error loading asset: " + error);
		}
		private function onAssetsLoadProgress(ratio:Number):void {
			//Debug.debug("_StarlingBase", "Assets load progress: " + ratio);
		}
		
		
		// APP INITIALIZATION ///////////////////////////////////////////////////////////////////////////////////////
		protected function onIntialSetupReady():void { /* EXTEND THIS WHEN APP IS STARTED AND INITIAL ASSETS ARE LOADED */
			Debug.debug(_debugPrefix, "Inital setup ready.");
			// When in extension everything is ready, call onStarlingAppReady();
		}
		protected function onStarlingAppReady():void {
			_ApplicationStarling.instance.onStarlingAppReady();
		}
		
		
		
		// Bitmap fonts registration
		protected function registerBitmapFont(fontTexture:Class, fontXml:Class):void {
			var texture:Texture = Texture.fromEmbeddedAsset(fontTexture);
			var xml:XML = XML(new fontXml());
			var font:BitmapFont = new BitmapFont(texture, xml); 
			TextField.registerCompositor(font, font.name); 
			// Use this to register bitmap fonts.
			// You must embed files with absolute path, i.e:
			//[Embed(source="D:/Projects/HBReavis/_bin/_fonts/AvenirPlain_0.png")]
			//public static const FontTexture:Class;
			//[Embed(source="D:/Projects/HBReavis/_bin/_fonts/AvenirPlain.fnt", mimeType="application/octet-stream")]
			//public static const FontXml:Class;
			// Then call:
			// registerBitmapFont(FontTexture, FontXml);
			
		}
		

	}

}