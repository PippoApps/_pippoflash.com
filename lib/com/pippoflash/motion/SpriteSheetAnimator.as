/* - MCFPSPlayer 1.0 - Plays a timeline animation with a diffferent (or same) FPS, moving playhead according to elapsed time.
*/

package com.pippoflash.motion {
	import com.pippoflash.framework.interfaces.IPippoFlashEventListener;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import com.pippoflash.utils.*;
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMemDispatcher;
	import com.pippoflash.net.QuickLoader;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	import flash.geom.Rectangle;
	
	public class SpriteSheetAnimator extends _PippoFlashBaseNoDisplayUMemDispatcher {
	// CONSTANTS
		public static var MAKE_ARRAY_1_BASED:Boolean = false; // Since generated spritte sheet starts at 0, this is needed to sync frames (starting at 1). It just adds an empty slot to array.
	// SYSTEM
		private var _bmp:Bitmap;
		private var _bmpUrl:String;
		private var _json:Object;
		private var _jsonUrl:String;
		private var _frames:Vector.<Object>;
		private var _framesNum:uint; // Total number of frames
		private var _frameRendered:uint; // The actual frame rendered
		private var _scrollRect:Rectangle;
	// USER VARIABLES
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function SpriteSheetAnimator(id:String, bmpUrlOrBitmap:*, jsonUrlOrObject:*, listener:*, autoActivate:Boolean=true):void {
			super("SpriteSheetAnimator");
			recycle(id, bmpUrlOrBitmap, jsonUrlOrObject, listener, autoActivate);
		}
		public function recycle(id:String, bmpUrlOrBitmap:*, jsonUrlOrObject:*, listener:*, autoActivate:Boolean=true):void {
			_debugPrefix = _classId + "<" + id +">";
			if (bmpUrlOrBitmap is Bitmap) _bmp = bmpUrlOrBitmap;
			else if (bmpUrlOrBitmap is String) _bmpUrl = bmpUrlOrBitmap;
			else throw new Error(_debugPrefix + " - bmpUrlOrBitmap must be a string or a bitmap");
			if (UCode.isObject(jsonUrlOrObject)) _json = jsonUrlOrObject; // Everything is an object, so I use deep checking with UCode
			else if (jsonUrlOrObject is String) _jsonUrl = jsonUrlOrObject;
			else throw new Error(_debugPrefix + " - jsonUrlOrObject must be a string or an object");
			addListener(listener);
			if (autoActivate) activate();
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function activate():void {
			// Here, according to what I have, I start doing all activation
			// First check JSON
			loadJson();
		}
		public function getBitmap():Bitmap {
			return _bmp;
		}
		public function setToFrame(n:uint):Boolean {
			if (n < _framesNum) {
				if (n != _frameRendered) { // Render only if I have not already rendered
					_frameRendered = n;
					renderSetFrame();
				}
				return true;
			}
			// Frame is out of bounds. I set to last frame.
			Debug.error(_debugPrefix, "Frame is out of boundaries. Rendering last frame.");
			setToFrame(_framesNum - 1);
			return false;
		}
// FRAMEWORK METHODS ///////////////////////////////////////////////////////////////////////////////////////
		override public function cleanup():void {
			_bmpUrl = _jsonUrl = null;
			_json = null;
			_bmp = null;
			_scrollRect = null;
			_frames = null;
			_frameRendered = _framesNum = NaN;
			super.cleanup();
		}
// PREPARATION ///////////////////////////////////////////////////////////////////////////////////////
		private function loadJson():void {
			if (_jsonUrl) { // Load json before prepare
				QuickLoader.loadFile(_jsonUrl, this, "Json");
			}
			else prepareJson();
		}
		private function prepareJson():void { // This also calls loadBmp
			var a:Array = _json.frames;
			//trace("PREPARO JSON",a.length);
			if (MAKE_ARRAY_1_BASED && a.frame) a.unshift({}); // Set an empty object as frame 0 - ONLY IF FRAME IS AN ANIMATION FRAME (I might modify twice the same json)
			_framesNum = a.length;
			_frames = new Vector.<Object>(_framesNum);
			for (_i=0; _i < _framesNum; _i++) _frames[_i] = a[_i];
			loadBmp();
		}
		private function loadBmp():void {
			if (_bmpUrl) { // Load BMP before prepare
				QuickLoader.loadFile(_bmpUrl, this, "Bmp");
			}
			else prepareBmp();
		}
		private function prepareBmp():void {
			//trace("Preparo BMP");
			_bmp.smoothing = true;
			_scrollRect = new Rectangle();
			_bmp.scrollRect = _scrollRect;
			UExec.next(broadcastEvent, "onSpriteSheetReady", this);
			//broadcastEvent("onSpriteSheetReady", this);
		}
// LOADING LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onLoadCompleteJson(o:SimpleQueueLoaderObject):void {
			_json = JSON.parse(o.getContent());
			prepareJson();
		}
		public function onLoadCompleteBmp(o:SimpleQueueLoaderObject):void {
			_bmp = o.getContent() as Bitmap;
			prepareBmp();
		}
// RENDERING ///////////////////////////////////////////////////////////////////////////////////////
		private function renderSetFrame():void { // Renders the frame set in _frameRendered
			var o:Object = _frames[_frameRendered].frame; // Retrieve frame format
			//trace("Frame view: " + Debug.object(o));
			_scrollRect.x = o.x;
			_scrollRect.y = o.y;
			_scrollRect.width = o.w;
			_scrollRect.height = o.h;
			_bmp.scrollRect = _scrollRect;
		}
	}
}
