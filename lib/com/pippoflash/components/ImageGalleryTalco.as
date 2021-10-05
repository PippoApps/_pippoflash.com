/* ContainerMenuBar - Is a base class for all Navigation interface item menus.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components.ImageLoaderAdv;
	import 											com.pippoflash.components.ContainerSmooth;
	import 											com.pippoflash.components.ContentBox;
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.net.SuperLoader;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UXml;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UMem;
	import											com.pippoflash.motion.PFMover;
	import											com.pippoflash.motion.Animator;
	import 											com.greensock.TweenLite;
// 	import 											com.greensock.easing.*;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;

	
	public class ImageGalleryTalco extends _cBaseImageGallery {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="SB - Class for ScrollBar Graphics", type=String, defaultValue="")]
		public var _linkScrollBarGraphics						:String = "";
		[Inspectable 									(name="GUI - Link for button left", type=String, defaultValue="ImageGalleryTalco_ButtonLeft")]
		public var _linkButtonLeft							:String = "ImageGalleryTalco_ButtonLeft";
		[Inspectable 									(name="GUI - Link for button Right", type=String, defaultValue="ImageGalleryTalco_ButtonRight")]
		public var _linkButtonRight							:String = "ImageGalleryTalco_ButtonRight";
		[Inspectable 									(name="SB - Use ScrollBar", type=Boolean, defaultValue=false)]
		public var _useScrollBar							:Boolean = false; // This decides a frame of the icon to go
		[Inspectable 									(name="UX - Auto Scroll", type=Boolean, defaultValue=false)]
		public var _useAutoScroll							:Boolean = false; // This decides a frame of the icon to go
		[Inspectable 									(name="GUI - Use Buttons", type=Boolean, defaultValue=true)]
		public var _useButtons								:Boolean = true; // This decides a frame of the icon to go
		[Inspectable 									(name="GUI - Images width (0 same as height)", type=Number, defaultValue=0)]
		public var _imgWidth								:Number = 0;
		[Inspectable 									(name="GUI - Side margin", type=Number, defaultValue=60)]
		public var _sideMargin								:Number = 60;
		[Inspectable 									(name="SYS - container for zoomed image", type=String, defaultValue="parent", enumeration="parent,stage")]
		public var _userZoomContainerString					:String = "parent";
		[Inspectable 									(name="SYS - zoomed image type", type=String, defaultValue="NORMAL", enumeration="CROP-RESIZE,NORMAL")]
		public var _zoomType								:String = "NORMAL";
		// USER VARIABLES MODIFIABLE VIA XML
		private var _enlargeScale							:Number = 0.1; // The scale to add to gallery photos on rollover
		private var _enlargeFrames							:uint = 4; // The number of frames required to enlarge images
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		private static var _imageLoaderParams					:Object = {width:100, width:100, _imageMargin:0, _interactionType:"FIXED", _resizeMode:"CROP-RESIZE", _bgClassLink:"NONE"};
		private static var _imageLoaderZoomParams				:Object = {_cBase_eventPostfix:"Large", width:400, width:400, _imageMargin:0, _interactionType:"FIXED", _resizeMode:"STRETCH"};
		private static var _verticalMaskOffset					:uint = 100; // This is the vertical margin applied to container mask, so that things are not cutout completely
		public static var _cb								:ContentBox;
		public static var _img								:ImageLoaderAdv;
		public static var _bmp								:Bitmap;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		private var _shield								:DisplayObject;
		private var _leftButton								:*;
		private var _rightButton							:*;
		private var _imgs									:Array;
		private var _container								:ContainerSmooth;
		private var _contentBox							:ContentBox;
		private var _marginLeft								:Sprite;
		private var _marginRight							:Sprite;
		private var _contentBoxesZoomed						:Array = []; // This contains the main large contentboxes. I need 3 because of scrolling reasons
		private var _imageLoadersZoomed						:Array = []; // This contains the main large imageloaders.
		private var _containerForZoomed						:DisplayObjectContainer;
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		private var _defaultThumbWidth						:uint;
		private var _zoomCoordinates						:Rectangle;
		private var _galleryTotalWidth						:Number;
		// MARKERS ////////////////////////////////////////////////////////////////////////
		private var _targetImgNum							:uint;
		private var _selectedImage							:ImageLoaderAdv;
		private var _selectedImageNum						:uint; // Selected image num according to _imageLoaders, without taking account of margins!!!
		private var _selectedZoomBox						:ContentBox;
		private var _zoomed								:Boolean;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ImageGalleryTalco						(par:Object=null) {
			super									("ImageGalleryTalco", par);
			_shield									= UCode.getInstance("com.pippoflash.components.assets.common.BgSquare");
		}
		protected override function initAfterVariables				():void {
			// Inizialize once for this component
			_imageLoaderParams.height						= _h;
			_contentBox								= new ContentBox({_autoScroll:_useAutoScroll, _coverBg:true, width:_w, height:_h+_verticalMaskOffset*2, y:-_verticalMaskOffset});
			_container									= new ContainerSmooth({_direction:"HORIZONTAL", _intMargin:0, _extMargin:0, _useAreaBg:true, width:_w, height:_h, _alignV:"TOP", _alignH:"LEFT"});
			addChild									(_contentBox);
			_imageLoaderParams._link_loadingTool = _imageLoaderParams._link_loadError = _imageLoaderParams._link_loadIdle = _imageLoaderParams._link_noImage = _linkImageLoaderAnim;
			_imageLoaderZoomParams._link_loadingTool = _imageLoaderZoomParams._link_loadError = _imageLoaderZoomParams._link_loadIdle = _imageLoaderZoomParams._link_noImage = _linkImageLoaderAnim;
// 			// Rollover
// 			_rollOver									= UDisplay.addChild(this, UCode.getInstance(_linkRollOver));
// 			Buttonizer.setClickThrough						(_rollOver);
			// Left and right buttons
// 			if (_useButtons) {
				_leftButton								= UCode.getInstance(_linkButtonLeft);
				_rightButton							= UCode.getInstance(_linkButtonRight);
				Buttonizer.setupButton					(_leftButton, this, "Left", "onPress");
				Buttonizer.setupButton					(_rightButton, this, "Right", "onPress");
// 			}
			// Enlarge content boxes and image loaders
			for (_i=0; _i<3; _i++) {
				_contentBoxesZoomed[_i] 					= new ContentBox({name:"GalleryContent"+_i, _autoScroll:true, _coverBg:false, width:100, height:100}); // Creates 3 content boxes for zoomed images (need 3 because )
				_imageLoadersZoomed[_i] 					= new ImageLoaderAdv(_imageLoaderZoomParams); // Creates 3 image loaders for zoomed images (need 3 because )
			}
			// Margin
			_marginLeft									= UDisplay.getSquareSprite(_sideMargin, 10, 0x000000);
			_marginRight								= UDisplay.getSquareSprite(_sideMargin, 10, 0x000000);
			_marginLeft.alpha = _marginRight.alpha				= 0;
			super.initAfterVariables						();
		}
		protected override function initialize					():void {
			super.initialize								();
			setButtonsToGallery							();
// 			_rollOver.height								= _h;
// 			_rollOver.visible								= false;
			// Resize contentBox
// 			_contentBox.releaseContent						();
		}
// COMMON METHODS ///////////////////////////////////////////////////////////////////////////////////////
// 		public override function harakiri						():void {
// 			_container.harakiri							();
// 		}
		public override function update						(par:Object):void {
			super.update								(par);
			if (par._zoomType)						updateZoomStuff();
// 			if (par.width || par.height)						resize(par.width, par.height);
		}
		public override function resize						(w:Number, h:Number):void {
// 			w = w ? w : _w; w = h ? h : _h;
			if (isSelected())								setTimeout(selectImage, 300, _imageLoaders[_selectedImageNum]);
			returnToGallery								(false);
			super.resize								(w, h);
			_imageLoaderParams.height = _imageLoaderParams._h 	= h;
			_contentBox.resize							(_w, _h+_verticalMaskOffset*2);
			_contentBox.y								= -_verticalMaskOffset;
			finalize									();
		}
		public override function release						():void {
// 			ImageLoaderAdv.destroyQueue					();
// 			ImageLoaderAdv.emptyCache						();
// 			_imageLoaders[0].destroyQueue					();
			returnToGallery								(false);
			_contentBox.release							();
			_container.release							();
			super.release								();
			SuperLoader.reset							();
			
		}	private function updateZoomStuff					():void {
				for each (_imageLoader in _imageLoadersZoomed) 	_imageLoader.update({_resizeMode:_zoomType});
			}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function scrollToPhoto							(n:int):void {
			_targetImgNum								= (UCode.setRange(n, 0, _imageLoaders.length-1));
			_contentBox.scrollToH							(_imageLoaders[_targetImgNum].x);
		}
		public function returnToGallery						(broadcast:Boolean=false):void { // This, if I am in zoom mode, returns to normal gallery
			if (!_zoomed)								return;
			for (_i=0; _i<3; _i++) {
				_cb									= _contentBoxesZoomed[_i];
				_img									= _imageLoadersZoomed[_i];
				_cb.visible								= false;
				_cb.releaseContent						();
				_img.visible								= false;
				_img.release							();
				_cb.y									= UGlobal._y;
				_cb.x									= UGlobal._x;
			}
			for each (_img in _imageLoaders) {
				_img.restoreContent						();
			}
			_zoomed									= false;
			_selectedZoomBox							= null;
			_selectedImage								= null;
			setButtonsToGallery							();
			if (broadcast)								broadcastEvent("onPhotoBackToGallery", this);
			UDisplay.removeClip							(_shield);
		}
		public function setZoomCoordinates					(rect:Rectangle):void {
			_zoomCoordinates							= rect;
			UDisplay.resizeToRect							(_shield, rect);
		}
		public function setZoomContainer						(c:DisplayObjectContainer, rect:Rectangle):void {
			_containerForZoomed							= c;
			setZoomCoordinates							(rect);
		}
		// CHECKS
		public function isSelected							():Boolean { // If gallery image is seleccted or not
			return									_zoomed;
		}
// RENDER ///////////////////////////////////////////////////////////////////////////////////////
		protected override function renderGallery				(xx:XML):void { // Called automatically by renderXml
			super.renderGallery							(xx);
			_targetImgNum								= 0;
			_container.x = _container.y = _galleryTotalWidth		= 0;
			if (UXml.hasAttribute(xx, "autoScroll"))				_useAutoScroll = UCode.isTrue(xx.@autoScroll);
			if (UXml.hasAttribute(xx, "buttons"))				_useButtons = UCode.isTrue(xx.@buttons);
			if (UXml.hasAttribute(xx, "sideMargins"))				_marginLeft.width = _marginRight.width = Number(xx.@sideMargins);
			if (UXml.hasAttribute(xx, "enlargeScale"))			_enlargeScale = Number(xx.@enlargeScale);
			if (UXml.hasAttribute(xx, "enlargeFrames"))			_enlargeFrames = Number(xx.@enlargeFrames);
			_contentBox.update							({_autoScroll:_useAutoScroll});
			createImageLoaders							();
			startLoadingProcess							();
			// Add margins	
			_imgs.unshift								(_marginLeft);
			_imgs.push									(_marginRight);
			_container.setup								(_imgs);
			finalize									();
		}
			protected function createImageLoaders				() {
				_defaultThumbWidth						= uint(_xml.@tw);
				_imageLoaderParams.x						= 0;
				_imgs									= new Array();
				for each (_node in _xml.IMG) {
					_imageLoaderParams.width = _imageLoaderParams._w = UXml.hasFullAttribute(_node, "tw") ? uint(_node.@tw) : _defaultThumbWidth;
					_imageLoaderParams._interactionType		= UXml.hasFullAttribute(_node, "u") ? "ONLOAD" : "NONE";
					_imageLoader						= UMem.getInstance(ImageLoaderAdv, _imageLoaderParams); 
					_imageLoader.addListener				(this);
					_imageLoaders.push					(_imageLoader);
					_imgs.push							(_imageLoader);
					_imageLoaderParams.x					+= _imageLoaderParams.width;
				}
				_galleryTotalWidth						= _imageLoaderParams.x;
			}
			protected function startLoadingProcess				():void {
				// They are separated onot to mess up loading with array ceration
				for (var i:uint=0; i<_imageLoaders.length; i++) {
					_imageLoaders[i].queueImage				(_xml.IMG[i].@t);
				}
			}
			private function finalize						():void {
				// This checks if there is something to scroll, and if there isn't, it centers the content box
				if (_galleryTotalWidth > _w) {
					_container.offset						(0, _verticalMaskOffset);
					_contentBox.setContent(_container);
				}
				else {
					_contentBox.release					();
					_container.offset						(0, 0);
					UDisplay.centerToArea				(_container, _w, _h);
					addChild							(_container);
// 					_container.y 						= -_verticalMaskOffset;					
				}
				setButtonsToGallery						();
			}
			
// SELECTION ///////////////////////////////////////////////////////////////////////////////////////
		private function selectImage							(c:ImageLoaderAdv):void {
			// This is the selection coming from gallery click
			stopAllContentBoxes							();
			_zoomed									= true;
			_selectedImage								= c;
			_selectedImageNum							= _imageLoaders.indexOf(c);
			_selectedZoomBox							= prepareZoomContentBox(_selectedImageNum);
			_containerForZoomed.addChild					(_shield);
			_containerForZoomed.addChild					(_selectedZoomBox);
			_selectedZoomBox.visible						= true;
			
			updateZoomStuff								();
			setButtonsToZoomed							();
			broadcastEvent								("onPhotoZoomed", _xml.IMG[_selectedImageNum]);
		}
		private function reSelectImage						():void {
			selectImage								(_selectedImage);
		}
			private function prepareZoomContentBox				(imageNum:uint):ContentBox {
				checkForContainerZoom					();
				var cb								:ContentBox = UCode.swapLastArray(_contentBoxesZoomed);
				cb.release								();
				cb.resize								(_zoomCoordinates.width, _zoomCoordinates.height);
				cb.y = UGlobal._y; cb.x = UGlobal._x;
				var img								:ImageLoaderAdv = UCode.swapLastArray(_imageLoadersZoomed);
				img.release								();
				img.addListener							(this);
				var bmp								:Bitmap = _imageLoaders[imageNum].borrowContent();
				bmp.x = bmp.y = 0;
				UDisplay.resizeSpriteTo					(bmp, _zoomCoordinates, _zoomType);
				if (hasFullZoom()) {
					img.resize							(bmp.width, bmp.height);
				}
				else {
					UDisplay.alignSpriteTo					(bmp, _zoomCoordinates);
					img.y = 0;
					img.resize							(_zoomCoordinates.width, _zoomCoordinates.height);
				}
				if (UXml.hasAttribute(_xml.IMG[imageNum], "u")) 	img.loadImage(_xml.IMG[imageNum].@u);
				var s									:Sprite = UDisplay.wrapInNewSprite(bmp);
				bmp.y = img.y = 0;
				s.addChild								(img);
				cb.setContent							(s);
				cb.visible = img.visible						= true;
				cb.x									= 0;
				return								cb;
			}
			private function stopAllContentBoxes				():void {
				for each (_cb in _contentBoxesZoomed) {
					_cb.stopScroll						();
					PFMover.removeMotion				(_cb);
				}
			}
			private function checkForContainerZoom				():void {
				if (!_containerForZoomed) 					_containerForZoomed = _userZoomContainerString == "parent" ? parent : UGlobal.stage;
				if (!_zoomCoordinates)						_zoomCoordinates = UGlobal.getStageRect();
			}
				private function hasFullZoom					():Boolean {
					return							_zoomType == "CROP-RESIZE";
				}
			private function setButtonsToZoomed				():void {
				_containerForZoomed.addChild				(_leftButton);
				_containerForZoomed.addChild				(_rightButton);
				_leftButton.y = _rightButton.y 				= _zoomCoordinates.height/2;
				_rightButton.x							= _zoomCoordinates.width;
				_leftButton.visible = _rightButton.visible			= true;
			}
			private function setButtonsToGallery				():void {
				addChild(_leftButton); addChild(_rightButton);
				_leftButton.y = _rightButton.y				= _h/2;
				_rightButton.x							= _w;
				_leftButton.visible = _rightButton.visible			= _useButtons && _contentBox.hasHScroll();
			}
		private function scrollToNextLargePhoto					():void {
			if (_selectedImageNum >= _imageLoaders.length-1 || !_imageLoaders[_selectedImageNum+1].isLoaded()) return;
			scrollToLargePhoto							(_selectedImageNum+1, true);
		}		
		private function scrollToPreviousLargePhoto				():void {
			if (_selectedImageNum <= 0 || !_imageLoaders[_selectedImageNum-1].isLoaded()) return;
			scrollToLargePhoto							(_selectedImageNum-1, false);
		}
			private function scrollToLargePhoto				(n:uint, next:Boolean=true):void {
				_selectedImageNum						= n;
// 				var steps:uint = 10, pow:uint=2;
				var tweenTime							:Number = 0.5;
				// Remove old photo
				_selectedZoomBox.x						= 0;
				TweenLite.to							(_selectedZoomBox, tweenTime, {x:next ? -_zoomCoordinates.width : _zoomCoordinates.width});
// 				PFMover.slideIn						(_selectedZoomBox, {steps:steps, pow:pow, endPos:{x:next ? -_zoomCoordinates.width : _zoomCoordinates.width}});
				_selectedZoomBox						= prepareZoomContentBox(_selectedImageNum);
				_selectedZoomBox.x						= next ? _zoomCoordinates.width : -_zoomCoordinates.width;
				_containerForZoomed.addChild				(_selectedZoomBox);
				TweenLite.to							(_selectedZoomBox, tweenTime, {x:0});
// 				PFMover.slideIn						(_selectedZoomBox, {steps:steps, pow:pow, endPos:{x:0}});
				setButtonsToZoomed						();
				_leftButton.visible						= _selectedImageNum > 0;
				_rightButton.visible						= _selectedImageNum < _imageLoaders.length-1;
				broadcastEvent							("onPhotoZoomed", _xml.IMG[_selectedImageNum]);
			}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function scrollToNextVisiblePhoto					():void {
			if (isSelected())								scrollToNextLargePhoto();
			var step									= (_contentBox.getScrollH() + _w);
			var length									= _imgs.length;
			for (var i:int=length-1; i>=0; i--) {
				if (_imgs[i].x<=step) {
					_contentBox.scrollToH					(i >= length-2 ? _imgs[length-1].x+UCode.getWidth(_imgs[length-1]) : (_imgs[i+1].x-_w) + _sideMargin);
					return;
				}
			}
		}
		private function scrollToPreviousVisiblePhoto				():void {
			if (isSelected())								scrollToPreviousLargePhoto();
			var step									= _contentBox.getScrollH();
			var length									= _imgs.length;
			for (var i:int=0; i<length; i++) {
				if (_imgs[i].x>=step) {
					_contentBox.scrollToH					(i < 3 ? _imgs[0].x : _imgs[i-1].x - _sideMargin);
					return;
				}
			}
		}
			
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public var onImageLoadStart						:Function = UCode.dummyFunction; // Dont trace method not found
		public var onImageLoadProgress					:Function = UCode.dummyFunction; // Dont trace method not found
		public var onImageLoadInit						:Function = UCode.dummyFunction; // Dont trace method not found
		public function onImageLoadComplete				(c:ImageLoaderAdv):void {
			_bitmaps[_imageLoaders.indexOf(c)]			= c.getContent();
		}
		public function onPressLeft						(c:MovieClip=null) {
			scrollToPreviousVisiblePhoto					();
		}
		public function onPressRight						(c:MovieClip=null) {
			scrollToNextVisiblePhoto					();
		}
		public function onImageLoaderRollOver				(c:ImageLoaderAdv):void {
			_container.highlightClip						(c, _enlargeScale, _enlargeFrames, 0.2);
		}
		public function onImageLoaderRollOut				(c:ImageLoaderAdv):void {
			_container.resetHighlightClip					(24, 0.5);
		}
		public function onImageLoaderPress				(c:ImageLoaderAdv):void {
			selectImage							(c);
		}
	// LARGE IMAGES
		public var onImageLoadStartLarge					:Function = UCode.dummyFunction; // Dont trace method not found
		public var onImageLoadProgressLarge				:Function = UCode.dummyFunction; // Dont trace method not found
		public var onImageLoadInitLarge					:Function = UCode.dummyFunction; // Dont trace method not found
		public var onImageLoaderRollOutLarge				:Function = UCode.dummyFunction; // Dont trace method not found
		public var onImageLoaderRollOverLarge				:Function = UCode.dummyFunction; // Dont trace method not found
		public function onImageLoadCompleteLarge			(c:ImageLoaderAdv):void {
			var cb								:ContentBox = _contentBoxesZoomed[_imageLoadersZoomed.indexOf(c)];
			var bmp								:Bitmap = c.getContent();
			PFMover.removeMotion					(bmp);
			bmp.alpha 								= 1;
		}
		public function onImageLoaderPressLarge			(c:ImageLoaderAdv):void {
			returnToGallery							(true);
		}
	}
}