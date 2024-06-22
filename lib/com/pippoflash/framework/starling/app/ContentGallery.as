package com.pippoflash.framework.starling.app 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.UMem;
	import flash.geom.Rectangle;
	import starling.display.Image;
	import com.pippoflash.framework.starling.gui.elements.MediaItem;
	import com.pippoflash.framework.starling.util.ImageViewer;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * ABSTRACT class MUST be extended. This class load an entire gallery and prepares the files.
	 * In order to use it, ContentSwiper or other extensions must be used.
	 */
	public class ContentGallery extends _ContentBase 
	{
		public static const EVT_GALLERY_READY:String = "onGalleryReady";
		public static const EVT_IMAGE_INDEX_CHANGE:String = "onImgIndexChange"; // Index of image changed
		public static const EVT_IMAGE_VIEWER_MOVED:String = "onImageViewerMoved"; // Image viewer has moved an image
		public static const EVT_NEW_CONTENT_ARRIVED:String = "onGalleryContentArrived"; // Content has arrived. Either video or gallery viewer activated.
		//public static const EVT_MEDIA_ARRIVED:String = "onMediaArrived";
		private var _steps:uint;
		private var _readySteps:uint; // Conunts howmany MediaItems are ready
		protected var _currentStep:uint;
		//private var _dataSteps:Vector.<Object>; // Stores a single data step: {url:"", type:"img"}
		//private var _currentDataStep:Object;
		private var _rendered:Boolean;
		protected var _images:Vector.<MediaItem>;
		private var _imageUrls:Array;
		protected var _firstRender:Boolean;
		protected var _activeMedia:MediaItem;
		protected var _newMedia:MediaItem;
		protected var _transitioning:Boolean;
		protected var _preloadAll:Boolean;
		//protected var _rect:Rectangle;
		
		public function ContentGallery(id:String="ContentGallery", cl:Class=null) {
			super(id, cl);
			UMem.addClass(MediaItem);
		}
		
		public function renderImages(imageUrls:Array, preloadAll:Boolean=false):void {
			_imageUrls = imageUrls;
			_preloadAll = preloadAll;
			//_rect = rect ? rect : UGlobal.getOriginalSizeRect();
			Debug.debug(_debugPrefix, "Rendering images " + (_preloadAll ? "with full preload." : "loading one by one when needed."));
			if (isActive) release();
			prepareImages();
		}
		
		override public function release():void {
			for each (var item:MediaItem in _images) {
				UMem.storeInstance(item);
				item.removeAllListeners();
			}
			_images = null;
			_rendered = false;
			_activeMedia = null;
			_newMedia = null;
			super.release();
		}
		
		
		override public function renderData(data:Object, andActivate:Boolean = true):void {
			// Renders data from XML formatted
		}
		override public function renderXml(xmlData:XML, andActivate:Boolean = true):void {
			// Renders XML converting it to a data object
			super.renderXml(xmlData, false);
			// convert XML into gallery data
			const preloadAll:Boolean = UCode.isTrue(String(xmlData.@preloadAll));
			const imageUrls:Array = ProjConfig.instance.getLocationSrcUrlList(xmlData.ITEM);
			Debug.debug(_debugPrefix, "URLS:", imageUrls);
			renderImages(imageUrls, preloadAll);
		}
		
		// PREPARE MEDIA
		protected function prepareImages():void {
			_firstRender = true;
			_steps = _imageUrls.length;
			_readySteps = 0;
			_images = new Vector.<com.pippoflash.framework.starling.gui.elements.MediaItem>(_steps);
			_currentStep = NaN; // so that first show 0 does not return thinking it is showing already
			var img:MediaItem;
			for (var i:int = 0; i < _steps; i++) {
				//new MediaItem(
				img = UMem.getInstance(MediaItem, _imageUrls[i], null, _size, !_preloadAll);
				_images[i] = img;
				PippoFlashEventsMan.addInstanceListener(img, this);
				//if (img.imageViewer) PippoFlashEventsMan.addInstanceListener(img.imageViewer, this);
			}
			// If they do not get preloaded, let's activate first image
			if (!_preloadAll) activateGallery();
		}
		public function onMediaLoaded(m:MediaItem):void {
			if (_preloadAll) {
				_readySteps++;
				Debug.debug(_debugPrefix, "Loaded items " + _readySteps + " of " + _steps);
				if (_readySteps == _steps) activateGallery();
			}
		}
		private function activateGallery():void {
			_firstRender = true;
			setToStep(0);
		}
		
		// METHODS TO NAVIGATE IMAGES
		public function next():void {
			if (_steps == 1) return;
			if (_currentStep == _steps - 1) setToStep(0, true);
			else setToStep(_currentStep + 1, true);
		}
		public function previous():void {
			if (_steps == 1) return;
			if (_currentStep == 0) setToStep(_steps-1, false);
			else setToStep(_currentStep - 1, false);
		}
		public function setToStepAutoDirection(index:int):void {
			if (_currentStep == index) return; // We are already showing this image
			setToStep(index, index > _currentStep);
		}
		public function setToStep(index:int, forward:Boolean=true):void {
			//if (_currentStep == index && !_firstRender) return; // We are already showing this image
			if (index < 0) index = 0;
			else if (index > (_steps - 1)) index = _steps - 1;
			_transitioning = true;
			_currentStep = index;
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_IMAGE_INDEX_CHANGE, _currentStep);
			// first image is shown instantly, second one is skipped
			if (_firstRender) _images[_currentStep].show();
			else showImage(forward);
		}
		
		public function moveImageViewer(pos:Object):void {
			_images[_currentStep].moveImageViewer(pos);
		}
		
		
		
		// IMAGE SHOWING
		protected function showImage(forward:Boolean=true):void { // this one can be overridden
			_images[_currentStep].fadeIn();
		}

		// Media is ready and started transitioning
		public function onMediaReady(item:MediaItem):void {
			_newMedia = item;
			addChild(_newMedia);
			//_activeMedia = _newMedia;
			if (_firstRender) { // first render new media is just displayed
				setToActive();
				//PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_GALLERY_READY, this);
			}
			_firstRender = false;
		}
		public function onMediaArrived(arrivedItem:MediaItem):void {
			// One of the media arrived
			Debug.debug(_debugPrefix, "Arrived",arrivedItem);
			for each (var item:MediaItem in _images) {
				if (item != arrivedItem && item != _newMedia && !isActiveMediaItem(item) && !item.moving) {
					item.deactivate();
					removeChild(item);
				}
			}
			if (isActiveMediaItem(arrivedItem)) {
				Debug.debug(_debugPrefix, "This is MediaItem I was expecting: " + arrivedItem);
				_activeMedia = arrivedItem;
				onSelectedMediaArrived();
			}
			_transitioning = false;
		}
		protected function onSelectedMediaArrived():void { // When selected media arrived and not an overlaying one (motions could be concurrent)
			// Extend this to have actions happen when currently selected media arrived
			//PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_IMAGE_INDEX_CHANGE, _currentStep);
			_activeMedia.activateImageViewer(true, true, false, this);// , "_assets/gallery/Beaches1.jpg");
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_NEW_CONTENT_ARRIVED);
		}
		public function onImageViewerMoved(pos:Object):void {
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_IMAGE_VIEWER_MOVED, pos);
		}
		
		// CHECKS
		public function isActiveIndex(index:uint):Boolean {
			return _currentStep == index;
		}
		public function isActiveMediaItem(item:MediaItem):Boolean {
			return activeMedia == item;
		}
		public function isActiveUrl(url:String):Boolean {
			return _imageUrls[_currentStep] == url;
		}
		
		
		// GETTERS
		public function get currentStep():uint {
			return _currentStep;
		}
		public function get activeMedia():MediaItem {
			return _images[_currentStep];
		}
		
	}
}
