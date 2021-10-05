package com.pippoflash.framework.starling.app 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling.gui.elements.CompositeImageLoader;
	import com.pippoflash.framework.starling.gui.elements.ScrollBase;
	import com.pippoflash.framework.starling.gui.elements.StarlingContentBox;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UExec;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	/**
	 * Composites a larger image using a series of image, or displays a content in scrollable contentbox.
	 * @author Pippo Gregoretti
	 */
	public class ContentImageComposite extends _ContentBase 
	{
		//public static const EVT_TUNNEL_MediaItem:Class = MediaItem; // Use this to add events
		
		//public static const EVT_LOADED:String = "onMediaLoaded"; // When media has been correctly prepared (do not use this to show media, bbut just to count if media has been preloaded)
		//public static const EVT_READY:String = "onMediaReady"; // When video started playing or media is visible (and transition in started)
		//public static const EVT_ARRIVED:String = "onMediaArrived"; // When transition to appear is completed (or when instant view is active)
		//public static const EVT_LEFT:String = "onMediaLeft"; // Broadcasted when an mage has left with either hide(), fadeOut() or swipeOut();
		//public static const EVT_IMAGE_VIEWER_MOVED:String = "onImageViewerMoved"; // Image viewer has moved an image, pos object
		public static const EVT_PANNING:String = "onImageCompositePanning";
		public static const EVT_PANNED:String = "onImagePanned"; // Whenpan motion completes or when pan gesture is complete
		protected var _scrubEventInterval:Number = 0.1; // 0 sends scrub event at each scroll, otherwirse it sends events only at this interval
		protected var _contentBox:StarlingContentBox;
		protected var _compositeImage:CompositeImageLoader;
		protected var _scrollHoriz:ScrollBase;
		protected var _scrubbing:Boolean = false;
		protected var _panning:Boolean;
		protected var _panSeed:Number;
		protected var _baseUrl:String; // Used to check for unique ID
		protected var _broadcastPanningTimer:uint = 0;
		protected const BROADCAST_PANN_INT:uint = 100;
		
		
		public function ContentImageComposite(id:String="ContentImageComposite", cl:Class=null, listensToTouchEvents:Boolean=false, listensToSwipe:Boolean=true)
		{
			//if (!cl) cl = getDefinitionByName(getQualifiedClassName(this))
			super(id, cl);
			_compositeImage = new CompositeImageLoader(_size, id);
			_contentBox = new StarlingContentBox(_size, true, listensToTouchEvents, listensToSwipe);
			addChild(_contentBox);
			
			//_scrollHoriz = new ScrollBase(
			//addChild(_compositeImage);
			PippoFlashEventsMan.addInstanceListener(_compositeImage, this);
			PippoFlashEventsMan.addInstanceListener(_contentBox, this);
		}
		override public function release():void {
			_compositeImage.release(true);
			super.release();
		}
		
		override public function renderData(data:Object, andActivate:Boolean = true):void {
			// Renders data from XML formatted
		}
		override public function renderXml(xmlData:XML, andActivate:Boolean = true):void {
			// Renders XML converting it to a data object
			super.renderXml(xmlData, false);
			// Grab URL from XML Data
			const url = ProjConfig.instance.getLocationSrcUrl(xmlData);
			Debug.debug(_debugPrefix, "Base URL: " + url);
			_baseUrl = url;
			_compositeImage.loadImagesUntilFound(url);
			if (_scrollHoriz) {
				const showControls:Boolean = String(xmlData.@controls).length ? UCode.isTrue(xmlData.@controls) : true;
				_scrollHoriz.visible = showControls;
			}
		}
		
		
		public function createDefaultHorizontalScroller(size:Rectangle):void {
			_scrollHoriz = new ScrollBase(size, _instanceId + "H", null, {direction:"horizontal"});
			uDisplay.positionTo(_scrollHoriz, size);
			addHorizontalScroller(_scrollHoriz);
		}
		
		
		public function addHorizontalScroller(scroller:ScrollBase):void {
			_scrollHoriz = scroller;
			_contentBox.connectToScrollerHorizontal(_scrollHoriz);
			addChild(_scrollHoriz);
		}
		
		
		public function panImageX(ratio:Number, force:Number = 10):void {
			//trace("panImageX",ratio, force);
			if (!_contentBox.swiping) _contentBox.panToRatio(ratio, 0, force);
		}
		public function panImageXStep(step:int, force:Number = 10):void {
			_contentBox.panXToStepNum(step, force);
		}
		
		
		
		
		// CompositeImage LISTENERS
		public function onCompositeImageReady(ci:CompositeImageLoader):void {
			Debug.debug(_debugPrefix, "Composita image ready.");
			_contentBox.setPanX();
			_contentBox.setContent(_compositeImage);
			_contentBox.enterFromRight(10);
			setToActive();
		}
		
		
		// ContentBox listeners + scrubbing events
		public function onContentBoxPanX(c:StarlingContentBox):void { // This happens all the time box moves but not during swipe
			// This does nothing, since it is every pixel
			//trace("AAAAA");
			//trace("onContentBoxPanX");
			//trace(_contentBox.swiping, _contentBox.entering);
			if (!_contentBox.swiping && !_contentBox.entering) checkForBroadcastPanning();
		}
		public function onPanStart(c:StarlingContentBox):void {
			//trace("onPanStart");
			_panning = true;
		}
		public function onPanEnd(c:StarlingContentBox):void {
			_scrubbing = false;
			_panning = false;
			_panSeed = 0;
			//trace("onpanend");
			broadcastPanning();
			//broadcastPanComplete();
		}
		public function onPanSmoothMotionComplete(c:StarlingContentBox):void {
			//broadcastPanning();
			broadcastPanComplete();
		}
		//private function onPanX(c:StarlingContentBox):void {
			//trace("onPanX");
			//if (getTimer() > _broadcastPanningTimer) {
				////trace("1",_scrubbing);
				//if (_panning && !_scrubbing) {
					////trace("2");
					//_scrubbing = true;
					//_panSeed = Math.random();
					////trace("onpanX check");
					
					//checkForBroadcastPanning(_panSeed);
				//}
			//}
			//else {
				//trace("onPanX else");
				//broadcastPanning();
			//}
		//}
		public function onPanStepX(c:StarlingContentBox):void {
			//trace("onPanStepX");
			broadcastPanComplete(); // this only happens on one step (clicking on scrollbar)
		}
		private function checkForBroadcastPanning(seed:Number=NaN):void {
			//trace("check",isActive, getTimer(), _broadcastPanningTimer);
			if (isActive && getTimer() > _broadcastPanningTimer) {
				//trace("check ok");
				_broadcastPanningTimer = getTimer() + BROADCAST_PANN_INT;
				broadcastPanning();
				//UExec.time(_scrubEventInterval, checkForBroadcastPanning, _panSeed);
			}
		}
		private function broadcastPanning():void {
			if (isActive) {
				//trace("BROADCASTO");
				//trace("BROADCAST PANNING");
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PANNING, this);
			}
		}
		private function broadcastPanComplete():void {
			if (isActive) {
				//trace("BROADCASTO");
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PANNED, this);
			}
		}
		
		// GET SET
		public function get scrollHoriz():ScrollBase {
			return _scrollHoriz;
		}
		public function get contentBox():StarlingContentBox {
			return _contentBox;
		}
		public function get panX():Number {
			return _contentBox.targetPanX;
		}
		public function get panY():Number {
			return _contentBox.targetPanY;
		}
		public function get compositeImage():CompositeImageLoader {
			return _compositeImage;
		}
		
		public function get url():String 
		{
			return _baseUrl;
		}
		
		public function set scrubEventInterval(value:Number):void {
			_scrubEventInterval = value;
		}
		
	}

}