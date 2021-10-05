package com.pippoflash.components {
	
	import 											com.pippoflash.components.ImageLoader;
	import											com.pippoflash.utils.*;
	//import											com.pippoflash.net.SuperLoaderObject;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import											flash.net.*;
	import											flash.geom.*;
	
	
	public dynamic class ImageLoaderAdv extends ImageLoader{
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable (name="2.0 - Link to NO IMAGE class", type=String, defaultValue="PippoFlash_ImageLoaderAdv_LoaderAnimClass")]
		public var _link_noImage:String = "PippoFlash_ImageLoaderAdv_LoaderAnimClass";
		[Inspectable (name="2.1 - Link to LOAD IDLE class", type=String, defaultValue="PippoFlash_ImageLoaderAdv_LoaderAnimClass")]
		public var _link_loadIdle:String = "PippoFlash_ImageLoaderAdv_LoaderAnimClass";
		[Inspectable (name="2.2 - Link to LOAD ERROR class", type=String, defaultValue="PippoFlash_ImageLoaderAdv_LoaderAnimClass")]
		public var _link_loadError:String = "PippoFlash_ImageLoaderAdv_LoaderAnimClass";
		[Inspectable (name="2.3 - Link to LOADING class", type=String, defaultValue="PippoFlash_ImageLoaderAdv_LoaderAnimClass")]
		public var _link_loadingTool:String = "PippoFlash_ImageLoaderAdv_LoaderAnimClass";
		[Inspectable (name="2.4 - Attached position", type=String, defaultValue="CENTERED", enumeration="TOPLEFT,CENTERED,STRETCHED")]
		public var _link_positioningStyle:String = "CENTERED";
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		// SYSTEM
		public var _positionClassFunction					:Function = positionClass_CENTERED;
		// REFERENCES
		public var _attachedClass							:DisplayObject;
		// MARKERS
		// DATA HOLDERS
		public function ImageLoaderAdv					(par:Object=null) { // Here I invert ID and PAR since this has to remain compatible with other galleries
			super									(par);
// 			checkForInit								(initAfterVariables);
		}
		protected override function initAfterVariables			():void {
			super.initAfterVariables						(); 
			// Setup function to attach classes
			_positionClassFunction						= this["positionClass_"+_link_positioningStyle];
			// Attach the default no image class
			attachClass								(_link_noImage);
		}
		override protected function initialize():void {
			super.initialize();
			if (_removeFadesAndLoadersOnDevice && USystem.isDevice()) { // Reset all links if we are on device
				_link_loadError = _link_loadIdle = _link_loadingTool = _link_noImage = "";
			}
		}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////		
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
			_positionClassFunction						();
		}
		public override function release						():void {
			UDisplay.removeClip							(_attachedClass);
			super.release								();
		}
		public override function forceRelease					():void {
			UDisplay.removeClip							(_attachedClass);
			super.forceRelease							();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public override function loadImage					(s:String, overrideCache:Boolean=false, forceReload:Boolean=false, cacheThisImage:Boolean=false):Boolean {
			if (super.loadImage(s, overrideCache, forceReload)) {
				if (!imageIsLoadedFromCache())	attachClass(_link_loadIdle); // Image is from cache, I will not need to attach any loader class
				return true;
			}
			return									false;
		}
		//public override function queueImage					(s:String, priorityze:Boolean=false, anticache:Boolean=false, overrideCache:Boolean=false):Boolean  {
			//if (super.queueImage(s, priorityze, anticache, overrideCache)) {
				//attachClass							(_link_loadIdle);
				//return								true;
			//}
			//return									false;
		//}
// UTY //////////////////////////////////////////////////////////////////////////////////////////////////
		private function attachClass(s:String="") {
			if (isLoaded()) return;
			if (!s || s.length == 0) return;
			UDisplay.removeClip(_attachedClass);
			_attachedClass = UDisplay.addChild(this, UCode.getClassInstanceByName(s));
			if (UCode.exists(_interactiveSizer) && contains(_interactiveSizer)) swapChildren(_interactiveSizer, _attachedClass);
			_positionClassFunction();
		}
		private function positionClass_CENTERED				() {
			if (!_attachedClass)							return;
			_attachedClass.x							= _w/2;
			_attachedClass.y							= _h/2;
		}
		private function positionClass_STRETCHED				() {
			if (!_attachedClass)							return;
			_attachedClass.width							= _w;
			_attachedClass.height						= _h;
		}
		private function positionClass_TOPLEFT				() {
		}
 // LOADING ///////////////////////////////////////////////////////////////////////////////////
		//public override function onLoadStart(s:SuperLoaderObject) {
			//attachClass(_link_loadingTool);
			//if (_attachedClass) UCode.callMethod(_attachedClass, "reset");
			//super.onLoadStart(s);
		//}
		//public override function onLoadProgress(s:SuperLoaderObject) {
			//super.onLoadProgress(s);
			//if (_attachedClass) UCode.callMethod(_attachedClass, "setPercent", s._percent);
		//}
		//public override function onLoadInit(s:SuperLoaderObject) {
			//super.onLoadInit(s);
		//}
		//public override function onLoadComplete(s:SuperLoaderObject) {
			//super.onLoadComplete(s);
			//UDisplay.removeClip(_attachedClass);
		//}
		//public override function onLoadError(s:SuperLoaderObject) {
			//attachClass(_link_loadError);
			//super.onLoadError(s);
		//}
		public override function onLoadStart(s:SimpleQueueLoaderObject) {
			attachClass(_link_loadingTool);
			if (_attachedClass) UCode.callMethod(_attachedClass, "reset");
			super.onLoadStart(s);
		}
		public override function onLoadProgress(s:SimpleQueueLoaderObject) {
			super.onLoadProgress(s);
			if (_attachedClass) UCode.callMethod(_attachedClass, "setPercent", s._percent);
		}
		public override function onLoadInit(s:SimpleQueueLoaderObject) {
			super.onLoadInit(s);
		}
		public override function onLoadComplete(s:SimpleQueueLoaderObject) {
			super.onLoadComplete(s);
			UDisplay.removeClip(_attachedClass);
		}
		public override function onLoadError(s:SimpleQueueLoaderObject, error:*="") {
			attachClass(_link_loadError);
			super.onLoadError(s, error);
		}

// RENDER //////////////////////////////////////////////////////////////////////////////////////
		public override function setupImage(b:DisplayObject) {
			super.setupImage(b);
			UDisplay.removeClip(_attachedClass);
		}
	}
	
	
	
}