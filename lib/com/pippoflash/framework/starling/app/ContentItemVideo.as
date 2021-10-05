package com.pippoflash.framework.starling.app 
{
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.framework.starling.gui.elements.ScrollBase;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UExec;
	import flash.display3D.textures.RectangleTexture;
	import flash.geom.Rectangle;
	import starling.display.Sprite;
	import com.pippoflash.framework.starling.gui.elements.MediaItem;
	import com.pippoflash.framework.starling.app.ContentItem;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import starling.text.TextField;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class ContentItemVideo extends ContentItem 
	{
		//protected static const _controls;
		public static const EVT_STOP:String = "onStopMovie"; // Stop or pause
		public static const EVT_COMPLETE_STOP:String = "onCompleteStopMovie"; // Stop when movie is complete
		public static const EVT_COMPLETE_LOOP:String = "onCompleteLoopMovie"; // Loop when movie is complete
		public static const EVT_SCRUB:String = "onScrubMovie"; // Scrubbing
		public static const EVT_PLAY:String = "onPlayMovie"; // Play or resume
		public static const SCRUB_INTERVAL:Number = 0.6; // Interval in which to scrub movie when dragging scroller around
		public static const EVT_TUNNEL_MediaItem:Class = MediaItem; // Use this to add events
		protected var _controls:ScrollBase;
		protected var _elapsedTime:TextField; // Set these externally and they will be updated all the time
		protected var _totalTime:TextField;
		protected var _scrubbing:Boolean;
		
		
		
		public function ContentItemVideo(id:String="ContentItemVideo") // , controlsSize:Rectangle=null, controlHandleSprite:Sprite=null) 
		{
			super(id, ContentItemVideo);
			PippoFlashEventsMan.addInstanceEventsReBroadcaster(_mediaItem, this);
			StarlingGesturizer.addTap(_mediaItem, onVideoTap);
		}
		
		// SETUP
		public function setupControls(controlsSize:Rectangle=null, controlHandleSprite:Sprite=null):void {
			_controls = new ScrollBase(controlsSize ? controlsSize : new Rectangle(0, 0, _size.width, 60), "ContentItemVideoControls", null, {direction:"horizontal"});
			addChild(_controls);
			uDisplay.positionTo(_controls, controlsSize);
			if (controlHandleSprite) _controls.setHandle(controlHandleSprite);
			PippoFlashEventsMan.addInstanceListener(_controls, this);
		}
		
		override public function renderXml(xmlData:XML, andActivate:Boolean = true):void {
			super.renderXml(xmlData, andActivate);
			if (_controls) {
				const showControls:Boolean = String(xmlData.@controls).length ? UCode.isTrue(xmlData.@controls) : true;
				_controls.visible = showControls;
			}
		}
		
		
		
		// METHODS
		public function playMovie():void {
			_mediaItem.playVideo();
		}
		public function stopMovie():void {
			_mediaItem.pauseVideo();
		}
		public function scrubMovie(ratio:Number):void {
			_mediaItem.scrubVideo(ratio);
		}
		public function playMovieFrom(time:Number):void {
			_mediaItem.playVideoFrom(time);
		}
		public function scrubMovieTime(time:Number):void {
			_mediaItem.scrubVideoTime(time);
		}
		override public function pause():void {
			super.pause();
			_mediaItem.pauseVideo();
		}		
		override public function resume():void {
			super.resume();
			_mediaItem.resumeVideo();
		}
		
		// Video controls settings
		override public function onVideoStart(c:MediaItem):void {
			super.onVideoStart(c);
			_controls.setScrollValue(0, true);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PLAY, this);
		}
		override public function onVideoData(c:MediaItem):void {
			super.onVideoData(c);
			_controls.setScrollValue(_mediaItem.videoCompletion);
			_controls.scrollHandleInTime(1, c.videoTimeRemaining);
		}
		override public function onVideoPause(c:MediaItem):void {
			super.onVideoPause(c);
			_controls.stopHandle();
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_STOP, this);
		}
		override public function onVideoResume(c:MediaItem):void {
			super.onVideoPause(c);
			_controls.scrollHandleInTime(1, c.videoTimeRemaining);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PLAY, this);
		}
		override public function onVideoStop(c:MediaItem):void {
			super.onVideoStop(c);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_COMPLETE_STOP, this);
		}
		override public function onVideoLoop(c:MediaItem):void {
			super.onVideoLoop(c);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_COMPLETE_LOOP, this);
		}
		
		
		
		
		
		
		
		
		// TAP VIDEO
		private function onVideoTap(c:MediaItem):void {
			_mediaItem.toggleVideoPause();
		}
		
		
		
		
		// CONTROLS LISTENERES
		public function onScrollStart(c:ScrollBase):void {
			_mediaItem.pauseVideo();
		}
		public function onScrollEnd(c:ScrollBase):void {
			//_mediaItem.resumeVideo();
			doScrub();
			_scrubbing = false;
		}
		public function onScroll(c:ScrollBase):void {
			if (_mediaItem.videoIsPlaying) _mediaItem.pauseVideo(false); // when tapping on scroller
			if (!_scrubbing) {
				_scrubbing = true;
				checkForScrubbing();
			}
			
			//_mediaItem.scrubVideo(c.scroll);
			//PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCRUB, this, c.scroll);
		}
		public function onScrollStep(c:ScrollBase):void {
			_mediaItem.scrubVideo(_controls.scroll);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCRUB, this, _controls.scroll);
		}
		
		// SCRUB TIMED EXECUTION
		private function checkForScrubbing():void {
			if (isActive && _scrubbing) {
				doScrub();
				UExec.time(SCRUB_INTERVAL, checkForScrubbing);
			}
		}
		private function doScrub():void {
			if (isActive && _scrubbing) {
				_mediaItem.scrubVideo(_controls.scroll);
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_SCRUB, this, _controls.scroll);
			}
		}
		
		
		// SYSTEM
		override public function deactivate():void 
		{
			_scrubbing = false;
			super.deactivate();
		}
		
		override public function release():void 
		{
			super.release();
		}
		
		
		
		// GET SET
		public function get controls():ScrollBase {
			return _controls;
		}
		
	}

}