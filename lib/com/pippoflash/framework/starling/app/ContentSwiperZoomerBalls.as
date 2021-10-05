package com.pippoflash.framework.starling.app 
{
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.framework.starling.app.ContentSwiper;
	import com.pippoflash.framework.starling.PFVideoStarling;
	import com.pippoflash.framework.starling.gui.elements.MediaItem;
	import com.pippoflash.utils.UGlobal;
	import starling._MainStarling;
	import starling.display.Image;
	import starling.textures.Texture;
	import com.pippoflash.framework.starling.gui.elements.NavigatorBalls;
	import com.pippoflash.framework.starling._StarlingUDisplay;
	import flash.geom.Rectangle;
	import org.gestouch.gestures.*;
	import org.gestouch.events.*;
	import org.gestouch.core.*;
	import com.pippoflash.utils.Debug;
	
	public class ContentSwiperZoomerBalls extends ContentSwiper 
	{
		private var _navigator:NavigatorBalls;
		//private var _imgOverlay:MediaItem;
		public function ContentSwiperZoomerBalls()
		{
			super("ContentSwiperZoomerBalls", ContentSwiperZoomerBalls);
			_navigator = new NavigatorBalls(0xffffff, 0xffffff, 8, 30, 48, "RIGHT", "move");
			_navigator.y = 200;
			_navigator.x = UGlobal.getOriginalSizeRect().width - 100;
			PippoFlashEventsMan.addInstanceMethodListenerTo(_navigator, NavigatorBalls.EVT_SELECTED, onNavigatorSelected);
			addChild(_navigator);
			//_imgOverlay = new MediaItem(null, "img", null, false, "Txt");
			//PippoFlashEventsMan.addInstanceMethodListenerTo(_imgOverlay, MediaItem.EVT_LOADED, onOverlayLoaded);
			//PippoFlashEventsMan.addInstanceMethodListenerTo(_imgOverlay, MediaItem.EVT_READY, onOverlayReady);
			//_imgOverlay.hAlign = _StarlingUDisplay.HALIGN_CENTER;
			//_imgOverlay.vAlign = _StarlingUDisplay.VALIGN_MIDDLE;
			//_imgOverlay.fill = _StarlingUDisplay.RESIZE_FILL;
			//_imgOverlay.touchable = false;	
		}
		private function onNavigatorSelected(index:uint):void {
			setToStep(index, index > _currentStep);
		}
		override public function setToStep(index:int, forward:Boolean = true):void {
			if (_activeMedia && !isActiveMediaItem(_activeMedia)) _activeMedia.deactivateImageViewer();
			super.setToStep(index, forward);
			_navigator.setSelected(index);
			//removeOverlay();
		}
		override public function renderImages(imageUrls:Array, preloadAll:Boolean=true):void {
			_navigator.setSteps(imageUrls.length);
			super.renderImages(imageUrls, preloadAll);
		}
		override public function onMediaReady(item:MediaItem):void {
			super.onMediaReady(item);
			addChild(_navigator);
		}
		override protected function onSelectedMediaArrived():void {
			//_imgOverlay.cleanup();
			//_imgOverlay.renderUrl(_activeMedia.url);
			//return;
			//Debug.debug(_debugPrefix, "ATTIVO IMAGE VIEWER", _activeMedia);
			//_activeMedia.activateImageViewer(true, true, false, this);// , "_assets/gallery/Beaches1.jpg");
			super.onSelectedMediaArrived();
		}
		
		override public function activate():void 
		{
			super.activate();
		}
		
		
		override public function release():void {
			//_imgOverlay.cleanup();
			super.release();
		}
		
		
		
		// TXT OVERLAY
		//private function onOverlayLoaded(item:MediaItem):void {
			//trace("OVERLAY LOADEDDDDDDDDDDDDDD");
			//addChild(_imgOverlay);
			//addChild(_navigator);
			//_imgOverlay.alpha = 1;
			//_imgOverlay.visible = true;
			//_imgOverlay.fadeIn();
		//}
		//private function onOverlayReady(item:MediaItem):void {
			//D
		//}
		//private function removeOverlay():void {
			//_imgOverlay.removeFromParent();
			//_imgOverlay.fadeOut(0.1, true);
		//}
		public function get navigator():NavigatorBalls 
		{
			return _navigator;
		}

	}

}