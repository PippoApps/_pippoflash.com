/* PreLoader - ver 0.1 - Filippo Gregoretti - www.pippoflash.com - call init() before using
Helps preloading content. Loads all, images, text, anything and keps them in memory.
loadBmp("url"); // Keeps them in memory and returns the Bitmap object directly
loadText("url"); // Loads text and data and keeps them in memory
...

*/

package com.pippoflash.net {
	import com.pippoflash.framework.interfaces.IPippoFlashEventDispatcher;
	import com.pippoflash.framework._PippoFlashBaseStatic;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	import com.pippoflash.net.QuickLoader;
	import com.pippoflash.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.external.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;

	
	public class PreLoader extends _PippoFlashBaseStatic implements IPippoFlashEventDispatcher {
// VARIABLES ////////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		private static const VERBOSE:Boolean = true;
		private static const DELAY_NEXTLOAD_FRAMES:int = 1; // Set this to 0 to just load immediately
		private static const EXT_TO_TYPE:Object = {
			jpg:"bmp",
			png:"bmp",
			jpeg:"bmp",
			txt:"txt",
			xml:"txt",
			json:"txt",
			swf:"swf"
		};
		private static const LOADER_OBJECT:Object = {
			uri:null, // String with the full uri of resource, used also to retrieve it
			type:null // String with type: bmp, text
		};
		public static const EVT_LOADSTART:String = "onQueueLoadStart"; // queueID:String
		public static const EVT_LOADPROGRESS:String = "onQueueLoadProgress"; // progress:Number // 0 to 1
		public static const EVT_LOADERROR:String = "onQueueLoadError";
		public static const EVT_LOADCOMPLETE:String = "onQueueLoadComplete"; // queueID:String
		public static const EVT_LOADINTERRUPT:String = "onQueueLoadInterrupted"; // queueID:String
		public static const EVT_ITEMLOADSTART:String = "onItemLoadStart";
		public static const EVT_ITEMLOADPROGRESS:String = "onItemLoadProgress";
		public static const EVT_ITEMLOADERROR:String = "onItemLoadError";
		public static const EVT_ITEMLOADCOMPLETE:String = "onItemLoadComplete";
		// REFERENCES
		private static var _assets:Object;
		// DATA
		private static var _queue:Vector.<Object>; // Stores a QUEUE of loading OBJECTS
		private static var _processing:Object; // The Object actually processing
		private static var _loader:SimpleQueueLoaderObject; // The loader for the processing node
		private static var _total:uint; // Total number of files in queue
		private static var _elapsed:uint; // Files loaded since queue start, or elapsed with a load error
		private static var _loaded:uint; // Files successfully loaded
		private static var _errors:uint; // Number of errors in the last queue
		private static var _progress:Number; // Percent of loading
		private static var _queueId:String; // Marks the end of a queue, to make sure the right listener is listening
		// UTY
		private static var _a:Array;
		// MARKERS
		private static var _status:String = "IDLE"; // IDLE, LOADING
		// SWITCHES
		private static var _autostart:Boolean = false; // If queue should start as soon as one item is added
		static private var _smoothBitmaps:Boolean = true;
		static private var _forceFileStream:Boolean = false; // If files should all be loaded as a bytearray filestream
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init():void {
			if (_assets) {
				Debug.error(_debugPrefix, "Initialization called twice.");
				return;
			}
			_assets = {bmp:{}, txt:{}, swf:{}, gen:{}}; // gen are unrecognized files
			_total = 0;
			_queue = new Vector.<Object>();
			setId("PreLoader");
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		// queing
		public static function queueFile(uri:String, prioritize:Boolean=false):void { // Decides the type of file based on extension
			//trace("CARICO",uri  + " : " + getFileType(uri));
			PreLoader["queue_"+getFileType(uri)](uri, prioritize);
		}
		public static var queue_txt:Function = queueText;
		public static var queue_bmp:Function = queueBitmap;
		public static var queue_swf:Function = queueSwf;
		public static var queue_gen:Function = queue;
		public static function queueText(uri:String, prioritize:Boolean=false):void {
			addLoadingObject("txt", uri, prioritize);
		}
		public static function queueSwf(uri:String, prioritize:Boolean = false):void {
			addLoadingObject("swf", uri, prioritize);
		}
		public static function queueBitmap			(uri:String, prioritize:Boolean=false):void {
			addLoadingObject					("bmp", uri, prioritize);
		}
		public static function queue					(uri:String, prioritize:Boolean=false):void {
			addLoadingObject					("gen", uri, prioritize);
		}
		// Getting
		/**
		 * Returns a file of any kind related to the url it was loaded from.
		 * @param	uri Url of loaded file
		 * @param	nullify Return the instance and remove it from PreLoader. Otherwise keep the reference.
		 * @param	duplicate Return a duplicate of the Bitmap (works only for bitmaps - also nullify must be to false), and not the original file, but keep it in RAM.
		 * @return Any Object
		 */
		public static function getFile(uri:String, nullify:Boolean=true, duplicate:Boolean=false):* { 
			//trace("PRENDO URI ", uri  + " : " + getFileType(uri) + " : " + _forceFileStream);
			//trace(Debug.object(_assets.gen));
			var f:Function = PreLoader["get_" + getFileType(uri)];
			if (f == getBitmap) return f(uri, nullify, duplicate); // Use also duplicate if it is a bitmap
			else return f(uri, nullify);
		}
		public static var get_txt					:Function = getText;
		public static var get_bmp					:Function = getBitmap;
		public static var get_swf					:Function = getSwf;
		public static var get_gen					:Function = getGen;
		/**
		 * Returns a Bitmap related to the url it was loaded from.
		 * @param	uri Url of loaded file
		 * @param	nullify Return the instance and remove it from PreLoader. Otherwise keep the reference.
		 * @param	duplicate Return a duplicate of the Bitmap (also nullify must be to false), and not the original file, but keep it in RAM.
		 * @return Any Object
		 */
		public static function getBitmap(id:String, nullify:Boolean=true, duplicate:Boolean=false, hasSmoothing:Boolean=true):Bitmap {
			var b:Bitmap = _assets.bmp[id] as Bitmap;
			if (!b) {
				Debug.error(_debugPrefix, "Bitmap not found: " + id + ". Returning an empty bitmap.");
				b = new Bitmap(new BitmapData(100, 100, false, 0xff0000));
			}
			b.smoothing = hasSmoothing;
			if (nullify) delete _assets.bmp[id]; // Delete reference if is nullified
			else if (duplicate) { // Return a copy if is duplicate (and not nullified)
				Debug.debug(_debugPrefix, "Returning a Bitmap duplicate of " + id);
				var bb:Bitmap = new Bitmap((b as Bitmap).bitmapData.clone());
				bb.smoothing = hasSmoothing;
				return bb;
			}
			return b as Bitmap; // Return the original bitmap
		}
		public static function getText				(id:String, nullify:Boolean=true):String {
			var t								:String = _assets.txt[id];
			if (nullify)							delete _assets.txt[id];
			return							t;
		}
		public static function getSwf				(id:String, nullify:Boolean=true):MovieClip {
			var t								:MovieClip = _assets.swf[id];
			if (nullify)							delete _assets.swf[id];
			return							t;
		}
		public static function getGen				(id:String, nullify:Boolean=true):* {
			var t								:* = _assets.gen[id];
			if (nullify)							delete _assets.gen[id];
			return							t;
		}
		
		
		
		// List queing
		public static function queueBitmaps(uris:Vector.<String>, prioritize:Boolean=false):void {
			var autoStart:Boolean = _autostart; // Store value to set again later
			_autostart = false; // In order to block autostart on each call
			for each (var uri:String in uris) {
				queueBitmap(uri, prioritize);
			}
			_autostart = autoStart; // Set the value back
			if (_autostart) startQueue();
		}
		public static function queueFiles				(uris:Vector.<String>, prioritize:Boolean=false):void {
			var autoStart						:Boolean = _autostart; // Store value to set again later
			_autostart							= false; // In order to block autostart on each call
			for each (var uri:String in uris) {
				queueFile						(uri, prioritize);
			}
			_autostart							= autoStart; // Set the value back
			if (_autostart)						startQueue();
		}
		
		
		
		
		// General
		public static function startQueue(queueId:String = null):void {
			init();
			_queueId = queueId ? queueId : "Queue_" + Math.random();
			Debug.debug(_debugPrefix, "Starting queue ID " + _queueId);
			if (isIdle() && _queue.length) initiateQueueLoading();
		}
		static public function stopQueue():void {
			if (isLoading()) {
				
			}
		}
		public static function addListener(l:*):void {
			PippoFlashEventsMan.addStaticListener(PreLoader, l);
		}
		public static function removeListener(l:*):void {
			PippoFlashEventsMan.removeStaticListener(PreLoader, l);
		}
		
		
		
		// Checks
		static public function isLoading():Boolean {
			return _status == "LOADING";
		}
		static public function isIdle():Boolean {
			return _status == "IDLE";
		}
		

// QUEUE & LOADING ///////////////////////////////////////////////////////////////////////////////////////
		private static function initiateQueueLoading		():void {
			_errors							= 0;
			_elapsed							= 0;
			_loaded							= 0;
			Debug.debug						(_debugPrefix, "Starting PreLoad of " + _total + " files.");
			_status							= "LOADING";
			PippoFlashEventsMan.broadcastStaticEvent	(PreLoader, EVT_LOADSTART, _queueId);
			loadNextQueueItem					();
		}
		private static function loadNextQueueItem():void {
			_processing = _queue.shift();
			_loader = QuickLoader.loadFile(_processing.uri, PreLoader, "Item", false, "", null, _forceFileStream);
			if (VERBOSE) Debug.debug(_debugPrefix, "Loading item " + _loader._url);
		}
		private static function processCompletedLoad():void {
			var content:* = _loader.getContent();
			if (_smoothBitmaps && content is Bitmap) {
				Debug.debug(_debugPrefix, "Activating smoothing forb bmp: " + _loader._url);
				(content as Bitmap).smoothing = true;
			}
			//trace("Settu " + _processing.type + ", " +  _processing.uri + ", " + (content as ByteArray).bytesAvailable);
			_assets[_processing.type][_processing.uri]	= content;
			_loader.harakiri();
			_processing = null;
			_loader = null;
			_elapsed++;
			_progress = _elapsed / _total;
			PippoFlashEventsMan.broadcastStaticEvent(PreLoader, EVT_LOADPROGRESS, _progress);
			//trace("PROGRESSSS",_progress);
			if (_queue.length && isLoading()) {
				if (DELAY_NEXTLOAD_FRAMES) UExec.frame(DELAY_NEXTLOAD_FRAMES, loadNextQueueItem);
				else loadNextQueueItem();
			}
			else processQueueCompleted();
		}
		private static function processQueueCompleted():void {
			
			Debug.debug(_debugPrefix, "Completed queue. Total files:"+ _total + ". " + (_errors ? ("Loaded:"+_loaded+", Errors:"+_errors) : ("All files loaded successfully.")));
			_total = 0;
			_status = "IDLE";
			PippoFlashEventsMan.broadcastStaticEvent(PreLoader, EVT_LOADCOMPLETE, _queueId);
		}
// LOADER LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public static function onLoadStartItem(o:SimpleQueueLoaderObject):void {
			if (VERBOSE) Debug.debug(_debugPrefix, "Start load: " + o._url);
		}
		public static function onLoadCompleteItem(o:SimpleQueueLoaderObject):void {
			_loaded++;
			processCompletedLoad ();
		}
		public static function onLoadErrorItem			(o:SimpleQueueLoaderObject, err:*=null):void {
			Debug.error(_debugPrefix, "File couldn't be loaded: " + _processing.uri);
			_errors++;
			PippoFlashEventsMan.broadcastStaticEvent(PreLoader, EVT_LOADERROR, _queueId);
			processCompletedLoad();
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private static function addLoadingObject		(t:String, u:String, p:Boolean):void {
			if (VERBOSE) Debug.debug(_debugPrefix, "Queing " + t +" : " + u);
			var o								= {
				type:t,
				uri:u
			}
			if (!_assets)						init();
			if (p)								_queue.unshift(o);
			else								_queue.push(o);
			_total							++;
			if (_autostart)						startQueue();
		}
		private static function getFileType			(n:String):String {
			if (_forceFileStream) return "gen";
			_a								= n.split(".");
			var ext							:String = _a.pop();
			_a								= null;
			if (EXT_TO_TYPE[ext])				return EXT_TO_TYPE[ext];
			else								return "gen";
		}
		
		static public function set forceFileStream(value:Boolean):void {
			_forceFileStream = value;
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