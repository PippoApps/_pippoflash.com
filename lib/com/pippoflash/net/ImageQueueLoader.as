/* Static class to centralize image loading management.
*/

package com.pippoflash.net { 
	
// 	import											com.pippoflash.utils.UCode;
// 	import											com.pippoflash.utils.Buttonizer;
// 	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.net.SimpleQueueLoader;
	import											com.pippoflash.net.SimpleQueueLoaderObject;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import											flash.net.*;
	import											flash.geom.*;
	
	public dynamic class ImageQueueLoader {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		private static const USE_BITMAP_CACHE					:Boolean = true; // Uses internal bitmap cache ALWAYS
		private static const MAXIMUM_CACHED_IMAGES			:uint = 10; // Maximum cached images
		private static const LOAD_TIMEOUT					:uint = 100000; // Timeout for loading process
		private static const VERBOSE							:Boolean = false;
		private static const VERBOSE_PROGRESS					:Boolean = false;
		// STATIC
		private static var _imageLoaderInstances				:Array = new Array();
		// SETTINGS
		private var _debugPrefix							:String = "ILoader";
		// USER VARIABLES
		// REFERENCES
		private var _imageCache							:Object = new Object();
		// MARKERS
		private var _status								:String = "IDLE"; // IDLE, QUEUED, LOADING, LOADED, ERROR
		private var _counter								:uint = 0;
		private var _totalCounter							:uint = 0;
		// DATA HOLDERS
// STATIC ///////////////////////////////////////////////////////////////////////////////////////
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ImageQueueLoader						(id:String=null):void {
			if (id)									_debugPrefix += ":"+id;
			_imageLoaderInstances.push						(this);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function load								(u:String, func:Function, priority:Boolean=false):ImageLoaderObject { // Loads an image
			if (imageIsInCache(u)) { // This controls that I need to use cache, and image is already in cache
				if (VERBOSE)							Debug.debug(_debugPrefix, "Cache:",u);
				func									(getCachedImage(u));
			} else {
				forceLoad								(u, func, priority);
			}
			return									getCachedImage(u);
		}
		public function forceLoad							(u:String, func:Function, priority:Boolean=false):void { // Its forced to load an image even if its cached already
			if (_imageCache[u] && VERBOSE)					Debug.debug(_debugPrefix, u, "is loading already.");
			else {
				_imageCache[u] 							= new ImageLoaderObject(this, u, func, priority, _totalCounter++); // {u:s, f:func, slo:SuperLoader.queueFile(s, ImageLoader, priority, "", false, -1, "img", LOAD_TIMEOUT)};
				_counter								++;
				if (VERBOSE)							Debug.debug(_debugPrefix, "Added:",u, ", remaining:",_counter);
			}
		}
		public function dispose								(u:String):void {
			_imageCache[u].harakiri						();
		}
		public function getCachedObject						(u:String):ImageLoaderObject {
			return									_imageCache[u];
		}
		public function getCachedImage						(u:String):ImageLoaderObject {
			return									_imageCache[u];
		}
		public function imageIsInCache						(u:String):Boolean {
			return									Boolean(_imageCache[u]) ? _imageCache[u].isLoaded() : false;
		}
		public function reset								():void {
			_counter									= 0;
			_totalCounter								= 0;
			for (var s:String in _imageCache)					_imageCache[s].harakiri();	
		}
		// LOAD METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function loadListID							(u:String, idList:Array, func, priority:Boolean=false):void {
			for each (var id:String in idList)					load(UText.insertParams(u, {ID:id}), func, priority);
		}
		public function loadList								(a:Array, func, priority:Boolean=false):void {
			for each (var u:String in a)						load(u, func, priority);
		}
// LOADING ///////////////////////////////////////////////////////////////////////////////////
		public function onLoadStart							(s:SimpleQueueLoaderObject) {
			if (VERBOSE)								Debug.debug(_debugPrefix, "Start:",s._url);
			getObjectBySLO								(s).setToStart();
		}
		public function onLoadProgress						(s:SimpleQueueLoaderObject) {
			if (VERBOSE_PROGRESS)						Debug.debug(_debugPrefix, "Progress:",s._percent,s._url);
			getObjectBySLO								(s).setToProgress();
		}
		public function onLoadInit							(s:SimpleQueueLoaderObject) {
// 			getObjectBySLO								(s).setToInit();
		}
		public function onLoadComplete						(s:SimpleQueueLoaderObject) {
			if (VERBOSE)								Debug.debug(_debugPrefix, "Complete:",s._url);
			getObjectBySLO								(s).setToComplete();
			checkQueueOnFileComplete						();
		}
		public function onLoadError							(s:SimpleQueueLoaderObject) {
			Debug.debug								(_debugPrefix, "Error Loading:",s._url);
			getObjectBySLO								(s).setToError();
			checkQueueOnFileComplete						();
		}
		public function onQueueComplete						():void {
			if (VERBOSE)								Debug.debug(_debugPrefix, "All Images in QUEUE have been loaded.");
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function getObjectBySLO						(o:SimpleQueueLoaderObject):ImageLoaderObject {
			return									_imageCache[o._url];
		}
		private function checkQueueOnFileComplete				():void {
			if (--_counter == 0)							onQueueComplete();
		}
	}
}
// /////////////////////////////////////////////////////////////////////////////////////////
// HELPER CLASSES ///////////////////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////
/* This is the object created for each image in queue */
	dynamic class ImageLoaderObject {
		// IMPORTS
		import										com.pippoflash.net.ImageQueueLoader;
		import										com.pippoflash.net.SimpleQueueLoader;
		import										com.pippoflash.net.SimpleQueueLoaderObject;
		import										flash.display.*;
		// VARIABLES
		public var _url									:String;
		public var _status								:String = "q"; // q = queued, s = start, p = progress, i = init, c = complete, e = error
		public var _img									:*; // Could be a Bitmap or an SWF
		public var _id									:uint;
		private var _slo									:SimpleQueueLoaderObject;
		private var _f									:Function; // the feedback function
		
// METHODS /////////////////////////////////////////////////////////
		public function ImageLoaderObject						(imageQueueLoader:ImageQueueLoader, u:String, f:Function, p:Boolean, id:uint):void {
			_url = u; _f = f; _id = id;
			_slo										= SimpleQueueLoader.queueFile(u, imageQueueLoader, p, "", true, "img");
		}
		public function getImage							():DisplayObject {
			return									_img;
		}
		public function harakiri								():void {
// 			trace("harakiri image loader object",_slo);
// 			_slo.harakiri(); _f = null; _slo = null;
		}
		public function getObject							():SimpleQueueLoaderObject {
			return									_slo;
		}
		public function isLoaded							():Boolean {
			return									_status == "c";
		}
		public var isComplete								:Function = isLoaded;;
		public function isProgress							():Boolean {
			return									_status == "p";
		}
		public function isError								():Boolean {
			return									_status == "e";
		}
		public function getProgress							():Number {
			return									isProgress() ? _slo._percent : isComplete() ? 100 : 0;
		}
		public function getStatus							():String {
			return									"ImgLoadObj> "+_id+" is in status:"+_status;
		}
// UTY //////////////////////////////////////////////////////////////
		public function setToStart							() {
			_status									= "s";
			callFeedback								();
		}
		public function setToProgress						() {
			_status									= "p";
			callFeedback								();
		}
// 		public function setToInit							() {
// 			_status									= "i";
// 			callFeedback								();
// 		}
		public function setToComplete						() {
// 			trace("IMAGELOADER sembra che sono complete", _slo, _slo.getContent());
			_status									= "c";
			_img										= _slo.getContent();
			callFeedback								();
// 			harakiri									();
		}
		public function setToError							() {
			_status									= "e";
			callFeedback								();
// 			harakiri									();
		}
		private function callFeedback						():void {
			_f										(this);
		}
	}
