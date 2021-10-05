/* This class allows fine positioning of the image once loaded. It also allows for editing the image by dragging, zooming and rotating.
*/

package com.pippoflash.components {
	
	import 											com.pippoflash.components.ImageLoader;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.Buttonizer;
	//import											com.pippoflash.net.SuperLoader;
	//import											com.pippoflash.net.SuperLoaderObject;
	import											com.pippoflash.visual.PointerManager;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import											flash.net.*;
	import											flash.geom.*;
	import PippoFlash_ImageLoaderAdv_LoaderAnimClass;
	import PippoFlash_ImageLoaderAdv_LoadErrorClass;
	import PippoFlash_ImageLoaderAdv_LoadIdleClass;
	import PippoFlash_ImageLoaderAdv_NoImageClass;
	
	
	public dynamic class ImageLoaderAdvPos extends ImageLoaderAdv {
		[Inspectable 									(name="3.0 - Activate Drag", defaultValue=false, type=Boolean)]
		public var _activateDrag							:Boolean = false;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		private static var _handOpenCursor					:MovieClip;
		private static var _handCloseCursor					:MovieClip;
		private static var _stageFuncCalled					:Boolean;
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		// SYSTEM
		private var _minZoom								:Number; // Marks minimum zoom of image
		private var _maxZoom								:Number; // This gets calculated after retrieving _minZoom
		private var _diffZoom								:Number; // Calculated too
		private var _yMin								:Number; // Stores minimum y position
		private var _xMin									:Number; // Stores minimum x position
		// REFERENCES
		// MARKERS
		// DATA HOLDERS
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ImageLoaderAdvPos					(par:Object=null) {
			super									(par);
		}
		protected override function initAfterVariables				():void {
			_resizeMode								= "CROP-RESIZE";
			_interactionType								= "NONE";
			Buttonizer.setupButton						(this, this, "Me", "onPress,onRollOver,onRollOut,onRelease,onReleaseOutside");
			if (!_stageFuncCalled)							UGlobal.callOnStage(createHandCursors);
			super.initAfterVariables						(); 
		}
			private function createHandCursors				():void {
				if (_stageFuncCalled)						return;
				_stageFuncCalled							= true;
				_handOpenCursor							= UDisplay.addChild(UGlobal.stage, new Export_PippoFlash_Graph_HandOpen(), {visible:false});
				_handCloseCursor							= UDisplay.addChild(UGlobal.stage, new Export_PippoFlash_Graph_HandClose(), {visible:false});
			}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////		
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
		}
		public override function release						():void {
			super.release								();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
// 		public override function loadImage						(s:String) {
// 			super.loadImage								(s);
// 		}
// 		public override function queueImage					(s:String, priorityze:Boolean=false, anticache:Boolean=false)  {
// 			super.queueImage							(s, priorityze, anticache);
// 		}
		public function setZoomIncrement						(perc:Number):void { // This accepts percentage value, from 0 to 100, 0 = minZoom
			// This kind of shows zooming relative to center (to be refined)
			var lastWidth								:Number = _image.width; // Stor width to make changes centered
			_image.scaleX = _image.scaleY					= (_diffZoom * (perc/100)) + _minZoom;
			var diff									:Number = (lastWidth-_image.width)/2;
			_image.x += diff; _image.y += diff;
			_xMin										= -(_image.width - _w);
			_yMin									= -(_image.height - _h);
			setInBounds								();
		}
		public function onScroll							(perc:Number):void { // This is broadcasted from a scrollBar
			setZoomIncrement							(perc);
		}
		public function setInBounds							():void {
			if (_image.x > 0)								_image.x = 0;
			else if (_image.x < _xMin)						_image.x = _xMin;	
			if (_image.y > 0)								_image.y = 0;
			else if (_image.y < _yMin)						_image.y = _yMin;	
			trace										("ImageLoaderAdvPos x y sx sy:",_image.x, _image.y, _image.scaleX, _image.scaleY);
		}
		public function getImageScrollBounds					():Rectangle {
			// Return the scroll bounds for dragging or moving image
			return									new Rectangle(0,0,_w-_image.width,_h-_image.height);
		}
		public function setPositionAndScale					(xx:Number, yy:Number, scale:Number=1):void {
			if (scale <= 0) {
				Debug.debug							(_debugPrefix, "setPositionAndScale(); Scale has been set to 0, aborted.");
				return;
			}
			_image.x									= xx;
			_image.y									= yy;
			_image.scaleX = _image.scaleY					= scale;
			setInBounds								();
		}
		public function getScalePercent						():Number { // Returns the percent of scale to adjust eventually external scrollbars
			return									UCode.calculatePercent((_image.scaleX-_minZoom), _diffZoom);
		}
// UTY //////////////////////////////////////////////////////////////////////////////////////////////////
		private function setupEditingControls					():void {
			_minZoom									= _image.scaleX; // Here I mark the minimum available zoom
			_maxZoom									= _minZoom * 8;
			_diffZoom									= _maxZoom - _minZoom;
		}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onPressMe							(c:MovieClip=null) {
			if (_activateDrag && isLoaded()) {
				PointerManager.change						(_handCloseCursor);
				setDragActive							(true);
			}
			onPressBg									(c);
		}
		public function onReleaseMe							(c:MovieClip=null) {
			if (_activateDrag && isLoaded()) {
				setDragActive							(false);
				onRollOverMe							(c);
			}
		}
		public function onReleaseOutsideMe					(c:MovieClip=null) {
			onReleaseMe								(c);
			onRollOutMe								(c);
		}
		public function onRollOverMe							(c:MovieClip=null) {
			if (_activateDrag && isLoaded()) {
				setDragActive							(false);
				PointerManager.change						(_handOpenCursor);
			}
			onRollOverBg								(c);
		}
		public function onRollOutMe							(c:MovieClip=null) {
			if (_activateDrag && isLoaded()) {
				PointerManager.restore						();
			}
			onRollOutBg								(c);
		}
			private function setDragActive					(a:Boolean):void {
				if (a)									_image.startDrag(false, getImageScrollBounds());
				else									_image.stopDrag();
			}
// POST PROCESS ///////////////////////////////////////////////////////////////////////////////////
		protected override function completeLoadingProcess			() {
			super.completeLoadingProcess					();
			wrapImageInSprite							();
			setupEditingControls							();
			broadcastEvent								("onImageAdvPosPositioned");
		}
				private function wrapImageInSprite			():void {
					// It is needed to wrap the Bitmap in a Sprite or startDrag() will not work
					if (_image is Bitmap) {
						var s							:Sprite = new Sprite();
						s.scaleX = s.scaleY				= _image.scaleX;
						s.x 							= _image.x;
						s.y 							= _image.y;
						_image.scaleX = _image.scaleY		= 1;
						_image.x = _image.y				= 0;
						_image.parent.addChild			(s);
						s.addChild						(_image);
						_image						= s;
					}
				}
	}
	
	
	
}