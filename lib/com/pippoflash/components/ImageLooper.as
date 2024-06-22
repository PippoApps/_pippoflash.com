/* ImageLooper 1.1 - Loads a list of images and lets you scroll them with wipe gestures.

1.1	Added custom alignment through horizontal and vertical alignment.

*/


package com.pippoflash.components {
	
	import com.pippoflash.components._cBase;
	import com.pippoflash.utils.*;
	import com.pippoflash.motion.PFMover;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import com.pippoflash.net.PreLoader;
	import org.gestouch.gestures.*;
	import org.gestouch.events.*;
	import org.gestouch.core.*;
	import org.gestouch.extensions.native.NativeDisplayListAdapter;
	
	import com.pippoflash.utils.*;
	import com.pippoflash.framework.PippoFlashEventsMan;

	
	public class ImageLooper extends _cBaseMasked {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="1.0 - Direction", type=String, defaultValue="HORIZONTAL", enumeration="HORIZONTAL,VERTICAL")]
		public var _direction								:String = "HORIZONTAL"; // Default comntent array to be copied into a vector
		[Inspectable 									(name="1.1 - Resize", type=String, defaultValue="CROP-RESIZE", enumeration="NONE,NORMAL,STRETCH,CROP,CROP-RESIZE")]
		public var _resize								:String = "CROP-RESIZE";
		[Inspectable 									(name="1.2 - Preload All", defaultValue=true, type=Boolean)]
		public var _preloadAll								:Boolean = true; // If ALL images should be loaded together, or just the next ones
		[Inspectable 									(name="1.3 - Preload Images Buffer", defaultValue=1, type=Number)]
		public var _slotVerticalOffset							:int = 1; // Number of images before and after displayed one to be loaded
		[Inspectable 									(name="1.4 - Cache SWFs as BitmapMatrix", defaultValue=false, type=Boolean)]
		public var _cacheSwfs								:Boolean = false; // If ALL images should be loaded together, or just the next ones
		[Inspectable 									(name="1.5 - Apply ScrollRect (if cropped, not visible)", defaultValue=true, type=Boolean)]
		public var _applyScrollRect							:Boolean = true; // If ALL images should be loaded together, or just the next ones
		[Inspectable 									(name="1.6 - Smooth bitmaps", defaultValue=true, type=Boolean)]
		public var _smoothBitmaps							:Boolean = true;
		[Inspectable 									(name="1.7 - Tap action active", defaultValue=true, type=Boolean)]
		public var _tapAction								:Boolean = true;
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
// 		private static const EVT_READY						;
// 		private static const EVT_MOVE						:String = "onImageLooperMove";
// 		private static const EVT_ARRIVE						:String = "onImageLooperArrive";
		private static var _pfMover							:PFMover;
		// USER VARIABLES
		// SYSTEM
		private var _gesture								:SwipeGesture;
		private var _singleTap								:TapGesture;
		// DATA
		private var _imageUrls								:Vector.<String>;
		private var _alignListV								:Vector.<String>;
		private var _alignListH								:Vector.<String>;
		private var _images								:Vector.<DisplayObject>;
		private var _rect									:Rectangle;
		private var _queueId								:String;
		// MOTION
		// REFERENCES
		private var _content								:Sprite;
 		// MARKERS
		private var _showingImage							:int;
		private var _isHoriz								:Boolean;
		// INTERFACE MODE MARKERS
		// SMOOTH SCROLL
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////		
		public function ImageLooper						(par:Object=null) {
			super									("ImageLooper", par);
			_queueId									= "ImageLooper: " + (name ? name : Math.random());
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			if (!_pfMover) {
				_pfMover 								= new PFMover("ImageLooper", "Strong.easeOut");
			}
			_rect										= new Rectangle(0, 0, _w, _h);
			_content									= new Sprite();
			_isHoriz									= _direction == "HORIZONTAL";
// 			PippoFlashEventsMan.init						();
			scrollRect									= _rect;
// 			Gesturizer.addSwipe							(this, this, "L,R");
// 		public static function addSwipe				(c:InteractiveObject, listener:*, evts:String="L,R,U,D", postfix:String=""):void {
			_gesture 									= new SwipeGesture(this);
			_gesture.addEventListener						(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSwipe);
			if (_tapAction) {
				_singleTap								= new TapGesture(this);
				_singleTap.addEventListener					(org.gestouch.events.GestureEvent.GESTURE_RECOGNIZED, onSingleTap, false, 1, true);
				_singleTap.numTapsRequired				= 1;
			}
		}
		public override function release						():void {
			for each (var b:* in _images) {
				_content.removeChild						(b);
				if (_cacheSwfs && (b is MovieClip || b is Sprite)) {
					UDisplay.cacheAsBitmapMatrix			(b, false);
				}
				b.scrollRect								= null;
				UMem.killClip							(b);
			}
			_images									= null;  
			_imageUrls									= null;
			removeChild								(_content);
			// This is called to undo a render operation, and make the component ready again to render content
			super.release								();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function renderImages						(imgList:Vector.<String>, renderFirst:int=0, alignListH:Vector.<String>=null, alignListV:Vector.<String>=null):void {
// 			restoreInteraction							();
			if (isRendered())							release();
			_imageUrls									= imgList;
			_images									= new Vector.<DisplayObject>(_imageUrls.length);
			_showingImage								= renderFirst;
// 			_rect.x									= renderFirst * _w;
			// Prepare default aligment lists
			_alignListH									= alignListH ? alignListH : new Vector.<String>(_imageUrls.length);
			_alignListV									= alignListV ? alignListV : new Vector.<String>(_imageUrls.length);
			PreLoader.init();
			PreLoader.addListener(this);
			PreLoader.queueFiles(_imageUrls);
			PreLoader.startQueue(_queueId);
// 			mask = null;
		}
		public function previous(broadcast:Boolean=false, doNotAnimate:Boolean=false):void { // Goes to previous image
			if (_showingImage == 0) {
				if (broadcast) broadcastEvent("onLooperSwipeLimit", false);
				return;
			}
			moveTo(--_showingImage, broadcast, doNotAnimate);
		}
		public function next(broadcast:Boolean=false, doNotAnimate:Boolean=false):void { // Goes to next image
			if (_showingImage == _images.length-1) {
				if (broadcast) broadcastEvent("onLooperSwipeLimit", true);
				return;
			}
			moveTo(++_showingImage, broadcast, doNotAnimate);
		}
		public function canSwipe(forward:Boolean):Boolean {
			return forward ? _showingImage < (_images.length-1) : _showingImage > 0;
		}
		public function swipe(forward:Boolean, broadcast:Boolean=false, doNotAnimate:Boolean=false):Boolean {
			if (canSwipe(forward)) {
				if (forward) next(broadcast, doNotAnimate);
				else previous(broadcast, doNotAnimate);
				return true;
			}
			return false;
		}
		public function showImage (n:int, broadcast:Boolean=false):void {
			if (n < 0 || n >= _images.length) Debug.error(_debugPrefix, "Image in showImage() out of index: " + n);
			else {
				_showingImage = n;
				moveTo(n, broadcast);
			}
		}
		public function getActiveImageUrl():String {
			return _imageUrls[_showingImage];
		}
		public function getIndex():uint {
			return _showingImage;
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		private function render							():void {
			Debug.debug						(_debugPrefix, "Rendering images...");
			for (var i:uint=0; i<_imageUrls.length; i++) {
				_images[i] = PreLoader.getFile(_imageUrls[i], false, false);
				if (_smoothBitmaps && _images[i] is Bitmap) (_images[i] as Bitmap).smoothing = true;						
				addLoadedImage							(i);
			}
			// Add content
			addChild									(_content);
			positionTo									(_showingImage);
			complete									();
		}
		private function addLoadedImage						(n:int):void { // Adds the loaded image and centers it
			var b										:* = _images[n];
			_content.addChild							(b);
			// Resize and align
			UDisplay.resizeSpriteTo						(b, _rect, _resize);
// 			UDisplay.centerToArea						(b, _rect.width, _rect.height);
			// Prepare alignment string with error prevention
			var alignH									:String = "CENTER";
			var alignV									:String = "MIDDLE";
			try {
				if (_alignListH[n])						alignH = _alignListH[n];
			}
			catch (e:Error) {
				Debug.error							(_debugPrefix, "WARNING: Vector defined for Horizontal alignment, but shorter than image list.\n",_imageUrls,_alignListV);
			}
			try {
				if (_alignListV[n])						alignV = _alignListV[n];
			}
			catch (e:Error) {
				Debug.error							(_debugPrefix, "WARNING: Vector defined for Vertical alignment, but shorter than image list.\n",_imageUrls,_alignListV);
			}
// 			trace("ALLINEO IMMAGINE " + n  + " : " +  alignH  + " : " + alignV);
// 			UDisplay.alignSpriteTo						(b, _rect, alignH, alignV);
			// Apply scrollrect if necessary
			if (_applyScrollRect && _resize.indexOf("CROP") == 0) { // Image has cropping
				b.x = b.y								= 0;
				var xo								:Number = (b.width - _w)/2;
				var yo								:Number = (b.height - _h)/2;
				// Setup fine alignment
				if (alignH == "LEFT") {
					xo								= 0;
				}
				else if (alignH == "RIGHT") {
					xo								= (b.width - _w);
				}
				if (alignV == "TOP") {
					yo								= 0;
				}
				else if (alignV == "BOTTOM") {
					yo								= (b.height - _h);
				}
				var mRect								:Rectangle = new Rectangle(xo, yo, _w/b.scaleX, _h/b.scaleX);
				b.scrollRect 							= mRect;
			}
			// Cache loaded SWF
			if (_cacheSwfs && (b is MovieClip || b is Sprite)) {
				UDisplay.cacheAsBitmapMatrix				(b);
			}
			else if (b is Bitmap) {
				b.smoothing							= true;
			}
// 			b.x										= _w*n;
// 			b.x = 300;
			if (_isHoriz) 								b.x += _w*n;
		}
// MOVE ///////////////////////////////////////////////////////////////////////////////////////
		private function positionTo							(step:int):void {
			if (_isHoriz) 								_content.x = -(_w*step);
		}
		private function moveTo							(step:int, broadcast:Boolean, doNotAnimate:Boolean=false):void {
			var										p:Object = {x:-(step*_w)};
			if (broadcast) {
				p.onComplete							= onMotionComplete;
				broadcastEvent							("onLooperMotionStart", _showingImage);
			}
			if (doNotAnimate) {
				Debug.debug							(_debugPrefix, "Setting without animation to slot " + step);
				_content.x								= p.x;
				if (broadcast)							UExec.next(onMotionComplete);
			} else {
				Debug.debug							(_debugPrefix, "Animating to slot " + step);
				_pfMover.move							(_content, 0.5, p);
			}
		}
		private function onMotionComplete					():void {
			broadcastEvent								("onLooperMotionComplete", _showingImage);
		}
// LISTENERS /////////////////////////////////////////////////////////////////////////////////////
		public function onQueueLoadStart						(id:String):void {
			if (id != _queueId)							return;
			Debug.debug								(_debugPrefix, "Start loading queue...");
			broadcastEvent								("onLooperLoadingStart", this);
		}
		public function onQueueLoadComplete					(id:String):void {
			if (id != _queueId)							return;
			Debug.debug								(_debugPrefix, "Complete loading queue...");
			PreLoader.removeListener						(this);
			render									();
			broadcastEvent								("onLooperLoadingComplete", this);
		}
		private function onSwipe							(e:org.gestouch.events.GestureEvent):void {
			if (_gesture.offsetX > 0)						onSwipeRight(this);
			else if (_gesture.offsetX < 0)					onSwipeLeft(this);
		}
		private function onSwipeRight						(c:ImageLooper):void {
			previous									(true);
		}
		private function onSwipeLeft						(c:ImageLooper):void {
			next										(true);
		}
		private function onSingleTap						(e:org.gestouch.events.GestureEvent):void {
			broadcastEvent								("onLooperTap");
		}
// SCROLL FUNCTIONS ////////////////////////////////////////////////////////////////////////////////
	} // CLOSE CLASS ///////////////////////////////////////////////////////////////////////////////
}