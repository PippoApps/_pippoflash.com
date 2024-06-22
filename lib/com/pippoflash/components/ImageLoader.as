
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import com.pippoflash.components._cBase;
	import	com.pippoflash.utils.*;
	import com.pippoflash.motion.PFMover;
	//import com.pippoflash.net.SuperLoader;
	//import com.pippoflash.net.SuperLoaderObject;
	import com.pippoflash.net.SimpleQueueLoader;
	import com.pippoflash.net.QuickLoader;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	import com.pippoflash.visual.Rasterizer;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;
	import flash.geom.*;
	// FRAMEWORK 0.44
	public dynamic class ImageLoader extends _cBase {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable (name="0 - Interaction Type", type=String, defaultValue="NONE", enumeration="NONE,ONLOAD,FIXED")]
		public function set interactionType(s:String) {
			_interactionType = s;
		}
		[Inspectable (name="0 - Margin", type=Number, defaultValue=0)]
		public function set imageMargin(m:uint) {
			_imageMargin = m;
		}
		[Inspectable (name="0 - Resize", type=String, defaultValue="NORMAL", enumeration="NORMAL,STRETCH,CROP,CROP-RESIZE")]
		public function set resizeMode(s:String) {
			_resizeMode = s;
		}
		[Inspectable (name="0 - Align Horizontal", type=String, defaultValue="CENTER", enumeration="CENTER,LEFT,RIGHT")]
		public function set hAlign(s:String) {
			_hAlign = s;
		}
		[Inspectable (name="0 - Align Vertical", type=String, defaultValue="MIDDLE", enumeration="MIDDLE,TOP,BOTTOM")]
		public function set vAlign(s:String) {
			_vAlign = s;
		}
		[Inspectable (name="0 - Bg Class Link", type=String, defaultValue="NONE")]
		public function set bgClassLink(s:String) {
			_bgClassLink = s;
		}
		[Inspectable (name="0 - Anti Cache", type=Boolean, defaultValue=false)]
		public function set antiCache(a:Boolean) {
			_antiCache = a;
		}
		[Inspectable (name="0 - Target Image", type=String)]
		public function set targetImage(s:String) {
			_uri = s;
		}
		[Inspectable (name="0 - Fade in on load", type=Boolean, defaultValue=true)]
		public var _fadeInOnLoad:Boolean = true;
		[Inspectable (name="0 - Mask content to rectangle", type=Boolean, defaultValue=true)]
		public var _maskToRectangle:Boolean = true;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		public static const EVTGEN_VECTOR_LOADED_BEFORE_RASTERING:String = "onVectorLoadCompleteBeforeRaster"; // c:DisplayObhject - If a vector needs to be converted in a raster, this is called on general listener just before conversion
		protected static const EVTGEN_LOADING_PROCESS_COMPLETE:String = "onImageLoadComplete"; // (img:ImageLoader) - This is called on general listener when loading process is complete
		public static const EVT_LOAD_COMPLETE:String = "onImageLoadComplete"; // +Postfix - (img:ImageLoader)
		public static const EVT_IMAGE_ARRIVED:String = "onImageArrived"; // +Postfix - (img:ImageLoader) -  when image has been completely faded, or resized, or visible. Finished processing, etc.
		public static const VERBOSE:Boolean = false;
		// SETTINGS
		// This value, if set to true, will always keep loaded images in a cache. 
		// If these images are called again, images will just be returned as a duplicated bitmap data.
		// In this way, we do not have to keep more than one bitmapdata in memory
		private static var _generalPostProcessListener:*; // A listener on which call general events. Same listener for all instances.
		// USER DEFINABLE SWITCHES
		public static var _fadeInFrames:uint = 6;
		public static var _doNotReloadIfSameImage:Boolean = false; // Default, if I ask imageloader to load a url which has been already loaded, just abort
		public static var _useImageCaching:Boolean = false; // Caches in RAM ALL images BitmapData information, and on reload it retrieves bitmap from memory
		static public var _useImageCachingForUrls:Object = {}; // Only image sin this list will be cached
		static public var _useImageCacheAndRasterizeSwfs:Boolean = false; // If true, all SWFs will be rasterized and stored as bitmaps
		static public var _rasterizeAllSwfs:Boolean = false; // SWFs will always be rasterized
		static public var _rasterizeSwfsMaxZoom:Number = 2; // If SWFs must be rasterized, this is the max zoom ratio of rasterization
		static public var _removeFadesAndLoadersOnDevice:Boolean = true; // If true, on devices all fades will be instant and all loaders will be removed
		//static public const _rasterizer:Rasterizer = new Rasterizer("ImageLoader");
		public static var _timeout:uint = 30000; // If after N seconds loading didnt start, trigger an error
		protected static var _defaults:Object = {_bgClassLink:"NONE", _resizeMode:"NORMAL", _hAlign:"CENTER", vAlign:"MIDDLE", _interactionType:"NONE", _imageMargin:0, _antiCache:false, _uri:null};
		// STATIC
		public static var _imageCache:Object = new Object();
		// USER VARIABLES
		public var _imageMargin:uint = 0;
		public var _interactionType:String = "NONE"; // NONE, ONLOAD, FIXED
		public var _resizeMode:String = "NORMAL";
		public var _hAlign:String = "CENTER";
		public var _vAlign:String = "MIDDLE";
		public var _bgClassLink:String = "NONE";
		public var _antiCache:Boolean = false;
		// REFERENCES
		public var _interactiveSizer:MovieClip;
		public var _loader:Loader;
		//public var _SLObject:SuperLoaderObject;
		public var _SQLObject:SimpleQueueLoaderObject;
		public var _image:*;
		public var _bg:DisplayObject;
		// MARKERS
		private var _status:String = "IDLE"; // IDLE, QUEUED, LOADING, LOADED, ERROR
		private var _firstLoad:Boolean = true; // First time this component is used to load something
		// DATA HOLDERS
		public var _uri:String;
// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		//public static function destroyQueue() {
			//SimpleQueueLoader.reset();
			//SuperLoader.reset();
		//}
		public static function emptyCache():void {
			var b:Bitmap;
			for each (b in _imageCache) UMem.killBitmap(b);
			_imageCache = new Object();
		}
		public static function setListener(l:*):void { // Adds static general listener
			_generalPostProcessListener = l;
		}
		static public function activateCacheForUrl(uri:String, active:Boolean = true):void {
			if (active) _useImageCachingForUrls[uri] = true;
			else delete _useImageCachingForUrls[uri];
		}
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ImageLoader(par:Object=null) {
			super("ImageLoader", par);
		}
		protected override function initAfterVariables():void {
			super.initAfterVariables();
		}
		protected override function initialize():void {
			super.initialize(); /* CHECK WHY THIS WAS MISSING */
			renderBackground();
			createInteractiveSizer();
			if (UCode.exists(_uri)) loadImage(_uri);
			if (_fadeInOnLoad && _removeFadesAndLoadersOnDevice && USystem.isDevice()) {
				_fadeInOnLoad = false;
			}
		}
			private function renderBackground():void {
				if (_bgClassLink == "NONE" || _bgClassLink == "") return;
				_bg = UCode.getClassInstanceByName(_bgClassLink);
				addChildAt(_bg, 0);
				_bg.width = _w; _bg.height = _h;
			}
			private function updateBackground():void {
				if (_bg) {
					_bg.width = _w; _bg.height = _h;
				}
			}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public override function resize(w:Number, h:Number):void {
			super.resize(w, h);
			if (isLoaded()) setupImage(_image);
			updateBackground();
			updateInteractionVisible();
		}
		public function forceRelease():void { // Releases images from RAM also if use of cache is enabled
			resetImage(true);
			resetLoad();
			updateInteractionVisible();
			super.release();
		}
		public override function release():void {
			resetImage(false);
			resetLoad();
			updateInteractionVisible();
			super.release();
		}
		public override function cleanup():void {
			reset();
			super.cleanup();
		}
		public override function recycle(par:Object=null):void {
			super.update(par);
			initialize();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function getCachedImage(u:String):Bitmap {
			return _imageCache[u];					
		}
		public function loadImage(s:String, overrideCache:Boolean=false, forceReload:Boolean=false, cacheThisImage:Boolean=false):Boolean {
			// s - url of the image
			// overrideCache - if true an anticache number is added at the end of url (if not local)
			// forceRealod - if image was already loaded, with this it gets reloaded anyway
			if (cacheThisImage && !overrideCache) activateCacheForUrl(s, true); // Add to list of image caching
			// Check wether image is already loaded
			if (!forceReload && _doNotReloadIfSameImage) {
				if (s == _uri && isLoaded()) {
					if (_verbose) Debug.debug(_debugPrefix, "Image",s,"is already loaded.");
					completeLoadingProcess();
					return false;
				}
			}
			// Proceed loading
			setupLoad(s); // Reset is HERE
			if (useAndSetupImageInCache() && !overrideCache) return true; // This controls that I need to use cache, and image is already in cache
			//_SLObject = SuperLoader.loadFile(s, this, "", false, "img", _timeout);
			//_SQLObject = SimpleQueueLoader.loadFile(s, this, "", false, "img");
			_SQLObject = QuickLoader.loadFile(s, this, "", false, "img");
			//SimpleQueueLoader.loadFile(
			//SuperLoader.loadFile(
			return true;
		}
		//public function queueImage(s:String, priorityze:Boolean=false, anticache:Boolean=false, overrideCache:Boolean=false):Boolean {
			//setupLoad(s); // Reset is HERE
			//if (useAndSetupImageInCache() && !overrideCache) return false; // This controls that I need to use cache, and image is already in cache
			////_SLObject = SuperLoader.queueFile(s, this, priorityze, "", anticache, -1, "img", _timeout);
			//_SQLObject = SimpleQueueLoader.queueFile(s, this, false, "", false, "img");
			//QuickLoader.loadFile(s, this, "", false, "img");
			//return true;
		//}
		private function setStatus(s:String):void {
			_status = s;
		}
		public function loadTestImage(n:int=1):void {
			loadImage(UCode.getTestImageUrl(n));
		}
		public function setExternalImage(b:DisplayObject):void {
			setupImage(b);
		}
	// DATA
		public function borrowContent():* {
			restoreImageProperties();
			return _image;
		}
		public function restoreContent():void { // Restores previously released content, resizing, remasking, etc.
			if (isLoaded()) setupImage(_image);
		}
		public function releaseContent():DisplayObject { // Returns loaded content removing it from masks etc and resetting values
			// If no image is loaded returns null
			if (!_image) return null;
			// There is an image, just proceed
			restoreImageProperties();
			var c:DisplayObject = _image;
			UDisplay.removeClip(_image);
			_image = null;
			release();
			return c;
		}
		public function getContent():DisplayObject { // This returns loaded content, may it be a bitmap or a swf
			// Of course this works only after onLoadComplete is triggered.
			return _image;
		}
		public function getImageCoordinates():Object {
			return {x:_image.x, y:_image.y, w:_w, h:_h, scale:_image.scaleX};
		}
		public function getImageBoundaries():Rectangle { // Returns the real position of image
			return new Rectangle(_image.x, _image.y, _image.width, _image.height);
		}
	// MARKERS
		public function isLoaded() {
			return _status == "LOADED";
		}
		public function isError():Boolean {
			return _status == "ERROR";
		}
		public function isBitmap():Boolean {
			return _image is Bitmap;
		}
		public function uriIsSwf():Boolean {
			return _uri.split("?")[0].indexOf(".swf") != -1; // Part left of a ? contains ".swf"
		}
// RESET & HARAKIRI ///////////////////////////////////////////////////////////////////////////////////////
		public function reset() {
			resetImage();
			resetLoad();
			resetInteractiveSizer();
			resetBackground();
			scrollRect = null; // In case there was a scrollRect setup
		}
		public function resetLoad():void {
			UDisplay.removeClip(_loader);
			UDisplay.removeClip(_image);
			// If there is an _SQLObject it means a loading operation is in progress, therefore I kill while loading
			if (_SQLObject) {
				UMem.kill_SQLObject(_SQLObject); // SQLO kills himself when loading object is complete
				_SQLObject = null;
			}
			//if (_loader) UMem.kill_Loader(_loader);
			_loader = null;
			_image = null;
			//_uri = null;
			//_SQLObject = null;
			setStatus("IDLE");
		}
		private function resetImage(forceReset:Boolean=false):void {
			if (!_image) return;
			restoreImageProperties();
			UDisplay.removeClip(_image);
			if (!useCacheForImage() || forceReset) {
				// Killing of bitmap data from memory destroys also other instances and cached image. Therefore if it is cached it will be removed.
				UMem.killClip(_image);
				delete _imageCache[_uri];
			}
			_image = null;
			//_uri = null;
		}
		public function restoreImageProperties():void {
			_image.scaleX = _image.scaleY = 1;
			_image.y = _image.x = 0;
		}
		private function resetInteractiveSizer():void {
			if (_interactiveSizer) {
				Buttonizer.removeButton(_interactiveSizer);
				UDisplay.removeClip(_interactiveSizer);
				_interactiveSizer = null;
			}
		}
		private function resetBackground():void {
			if (_bg) {
				UDisplay.removeClip(_bg);
				_bg = null;
			}
		}
// LOADING ///////////////////////////////////////////////////////////////////////////////////
		//public function onLoadStart(s:SuperLoaderObject) {
			//_status = "QUEUED";
			//broadcastEvent("onImageLoadStart", this, s);
		//}
		//public function onLoadProgress(s:SuperLoaderObject) {
			//_status = "LOADING";
			//broadcastEvent("onImageLoadProgress", this, s);
		//}
		//public function onLoadInit(s:SuperLoaderObject) {
			//broadcastEvent("onImageLoadInit", this, s);
		//}
		//public function onLoadComplete(s:SuperLoaderObject) {
			//setStatus("LOADED");
			//setupLoadedImage(s._loader);
			//completeLoadingProcess();
		//}
		//public function onLoadError(s:SuperLoaderObject) {
			//if (_verbose) Debug.error(_debugPrefix, "Error loading image: " + _uri);
			//_status = "ERROR";
			//broadcastEvent("onImageLoadError", this, s);
		//}
		public function onLoadStart(s:SimpleQueueLoaderObject) {
			_status = "QUEUED";
			broadcastEvent("onImageLoadStart", this, s);
		}
		public function onLoadProgress(s:SimpleQueueLoaderObject) {
			_status = "LOADING";
			broadcastEvent("onImageLoadProgress", this, s);
		}
		public function onLoadInit(s:SimpleQueueLoaderObject) {
			broadcastEvent("onImageLoadInit", this, s);
		}
		public function onLoadComplete(s:SimpleQueueLoaderObject) {
			//if (s._url != _uri) {
				//Debug.debug(_debugPrefix, "LOAD NOT CORRECT");
				//return;
			//}
			setStatus("LOADED");
			setupLoadedImage(s._loader);
			completeLoadingProcess();
		}
		public function onLoadError(s:SimpleQueueLoaderObject, error:*="") {
			if (_verbose) Debug.error(_debugPrefix, "Error loading image: " + _uri, error);
			_status = "ERROR";
			broadcastEvent("onImageLoadError", this, error);
		}
// RENDERING - LOAD COMPLETE //////////////////////////////////////////////////////////////////////////////////////
		protected function completeLoadingProcess() {
			setStatus("LOADED");
			updateInteractionVisible();
			// General static event
			if (_generalPostProcessListener) UMethod.callMethodName(_generalPostProcessListener, EVTGEN_LOADING_PROCESS_COMPLETE, this);
			// reset load if necessary
			//resetLoad();
			// Broadcast event
			broadcastEvent(EVT_LOAD_COMPLETE, this);
			// Nullify objects that will recycle thmselves directly
			_loader = null;
			_SQLObject = null;
		}
		private function setupLoadedImage(loader:Loader) {
			// I arrived here, it means that image has been loaded form network and is not in cache
			_loader = loader;
			_loader.mouseEnabled = false; // Not sure why this...
			// Try to retrieve regular bitmap
			var bmp:Bitmap;
			try { // I have loaded a bitmap
				bmp = Bitmap(_loader.content);
			} catch (e:Error) {
				Debug.debug(_debugPrefix, "Loaded image is an SWF: " + _uri);
				if (_loader.content is MovieClip) (_loader.content as MovieClip).gotoAndStop(1); // Just stop movieclip execution
				// Here I do rasterize the loaded SWF....
				//UDisplay.removeClip(_loader.content); // To be removed here or Rasterizer will think this has a parent
				//_loader.content.parent = null;
				if (useCacheForImage() || rasterizeSwfs()) { // An SWF is rasterized if all SWFs need to be rasterised, or if the single SWF is added to image caching
					Debug.debug(_debugPrefix, "Rasterizing vector image.");
					var loadedContent:DisplayObject = _loader.content;
					_loader.unload(); // This is to avoid that the Loader object results as parent of loaded clip in Rasteriser
					// Broadcast a general event
					if (_generalPostProcessListener) UMethod.callMethodName(_generalPostProcessListener, EVTGEN_VECTOR_LOADED_BEFORE_RASTERING, loadedContent);
					// Rasterizes resets all image transformations (including height and width) therefore, I need to resize loaded image, then put it in an empty NON-RESIZED sprite, and the sprite will be sampled
					// First I resize loaded image to this component size
					if (!loadedContent) {
						throw new Error("Error setting up raster loaded content as swf. Interrupting flow for _uri " + _uri);
						return;
					}
					resizeImage(loadedContent, true);
					// Then I add it to an empty sprite so that Rasterizer thinks it's 1:1
					var nonResizedContainer:Sprite = new Sprite();
					nonResizedContainer.addChild(loadedContent);
					bmp = Rasterizer.convertToBitmap(nonResizedContainer, _rasterizeSwfsMaxZoom);
					// Cleanup leftovers for Garbage Collection
					nonResizedContainer.removeChild(loadedContent);
					nonResizedContainer = null;
					loadedContent = null;
				}
			}
			if (bmp) {
				bmp.smoothing = true;
				if (useCacheForImage()) setupLoadedImageCache(bmp);
				setupImage(bmp);
				//UExec.next(setupImage, bmp);
			}
			else { // It's an SWF that doesn't require caching
				setupImage(_loader.content);
				//UExec.next(setupImage, _loader.content);
			}
			// Reset loader
			//resetLoad();
		}
		public function setupImage(b:DisplayObject) {
			if (_image && _image != b) {
				if (_verbose) Debug.warning(_debugPrefix, "Setting an external image when there is already an image. Calling release() first.");
				release();
			}
			if (!resizeImage(b)) { // There was an error in resizing image
				Debug.error(_debugPrefix, "Error in setupImage().resizeImage() aborting.");
				return;
			}
			_image = b;
			addChild(_image);
			if (_maskToRectangle) scrollRect	= new Rectangle(0, 0, _w, _h);
			// Broadcast image arrived at the end of fade or immediately
			if (_fadeInOnLoad) PFMover.fadeInTotal(this, _fadeInFrames, broadcastImageArrived);
			else broadcastImageArrived();
		}
			private function broadcastImageArrived(c:ImageLoader = null):void { // Broadcasts that image is arrived and has been formatted and faded and visualized
				// Following frame to allow GPU image rendering
				UExec.next(broadcastEvent, EVT_IMAGE_ARRIVED, this);
			}
		private function resizeImage(b:DisplayObject, useBounds:Boolean = false):Boolean { // This is separate, because it's called BEFORE rasterization
			try {
				b.x = b.y = 0;
				var rect:Rectangle = new Rectangle(_imageMargin,_imageMargin,_w-(_imageMargin*2),_h-(_imageMargin*2));
				//if (_verbose) Debug.debug(_debugPrefix, "Image before resizing: " + b.getBounds(this));
				UDisplay.resizeSpriteTo(b, rect, _resizeMode, useBounds);
				if (_resizeMode != "STRETCH") UDisplay.alignSpriteTo(b, rect, _hAlign, _vAlign, useBounds);
			} catch (e:Error) {
				var s:String = "";
				s += name + "\n";
				if (this["parent"]) s += "parent: " + parent.name + "\n";
				s += _uri + "\n";
				s += "Image: " + b;
				s += "\n" + e.getStackTrace();
				Debug.error(_debugPrefix, e + "\nresizeImage error! Tracing debug elements: " + s);
				//throw new Error("resizeImage error " + s);
				return false;
			}
			return true;
			//if (_verbose) Debug.debug(_debugPrefix, "Image is resized: " + b.getBounds(this));
		}
// CACHING //////////////////////////////////////////////////////////////////////////////////////
		private function setupLoadedImageCache(bmp:Bitmap) {
			//if (_imageCache[_uri]) UMem.killBitmap(bmp); // ????? This bitmap might be still visible somewhere else
			if (!_imageCache[_uri]) _imageCache[_uri] = bmp;
		}
		private function useAndSetupImageInCache():Boolean {
			if (useCacheForImage() && UCode.exists(_imageCache[_uri])) { // Tells if image will ba taken from cache, and it iwll take it and position it.
				if (VERBOSE) Debug.debug(_debugPrefix, "Using cached BMP version for: " + _uri);
				var bmp:Bitmap = new Bitmap(_imageCache[_uri].bitmapData);
				bmp.smoothing = true;
				setupImage(bmp);
				completeLoadingProcess();
				return true;
			}
			return false; // Load image instead
		}
		protected function imageIsLoadedFromCache():Boolean { // Tells if image will ba taken from cache, but it will not actually eit.
			return _useImageCaching && UCode.exists(_imageCache[_uri]);
		}
		protected function useCacheForImage():Boolean { // If I need to use cache for stored _uri
			// If SWFs must all be cached, and _uri is an SWF,  _uri is added to cache list in setupLoad().
			return _useImageCaching || _useImageCachingForUrls[_uri];
		}
		protected function rasterizeSwfs():Boolean { // If ALL SWFs must be rasterized
			return _rasterizeAllSwfs;
		}
// BACKGROUND & INTERACTION ////////////////////////////////////////////////////////////////////////////////////
		private function createInteractiveSizer():void {
			_interactiveSizer = UDisplay.getSquareMovieClip(_w,_h);
			_interactiveSizer.alpha = 0;
			addChild(_interactiveSizer);
			Buttonizer.setupButton(_interactiveSizer, this, "Bg");
			updateInteractionVisible();
		}
		private function updateInteractionVisible():void {
			if (!_interactiveSizer) return;							
			_interactiveSizer.visible = (_interactionType == "FIXED"  || isLoaded() && _interactionType == "ONLOAD") && _interactionType != "NONE";
			addChild(_interactiveSizer);
			_interactiveSizer.width = _w; _interactiveSizer.height = _h;
		}
		public function onPressBg(c) {
			broadcastEvent("onImageLoaderPress", this);
		}
		public function onRollOverBg(c) {
			broadcastEvent("onImageLoaderRollOver", this);
		}
		public function onRollOutBg(c) {
			broadcastEvent("onImageLoaderRollOut", this);
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function setupLoad(s:String) {
			if (_firstLoad) resetLoad();
			else release();
			if (!s || (s && !s.length)) {
				Debug.error(_debugPrefix, "ERROR LOADING URI: " + s);
				throw new Error("ImageLoader URL not set or url too short: " + s);
				return;
			}
			setStatus("QUEUED");
			_uri = s;
			if (_useImageCacheAndRasterizeSwfs && uriIsSwf()) activateCacheForUrl(_uri);
			_firstLoad = false;
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
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