package com.pippoflash.framework.starling.gui.elements 
{
	import com.pippoflash.framework.Config;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.starling._StarlingBase;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UExec;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.UNumber;
	import com.pippoflash.utils.USystem;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.textures.Texture;
	import com.pippoflash.framework.starling.PFVideoStarling;
	import com.pippoflash.framework.starling.Transitioner;
	import com.pippoflash.framework.starling.util.ImageViewer;
	import flash.net.NetStream;
	import flash.net.NetConnection;
	
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * this can hold either an image or video
	 * on complete is triggered on load when it is an image or when video starts playing if it's a video
	 * for images, it can trigger enlargement
	 */
	public class MediaItem extends _StarlingBase 
	{
		// GENERAL MEDIA
		public static const EVT_LOADED:String = "onMediaLoaded"; // When media has been correctly prepared (do not use this to show media, bbut just to count if media has been preloaded)
		public static const EVT_READY:String = "onMediaReady"; // When video started playing or media is visible (and transition in started)
		public static const EVT_ARRIVED:String = "onMediaArrived"; // When transition to appear is completed (or when instant view is active, or wehn video playes)
		public static const EVT_LEFT:String = "onMediaLeft"; // Broadcasted when an mage has left with either hide(), fadeOut() or swipeOut();
		// IMG ONLY
		public static const EVT_IMAGE_VIEWER_READY:String = "onImageViewerReady"; // Image viewer has moved an image, pos object
		public static const EVT_IMAGE_VIEWER_MOVED:String = "onImageViewerMoved"; // Image viewer has moved an image, pos object
		// VIDEO ONLY
		public static const EVT_VIDEO_DATA:String = "onVideoData"; // When video metadata has been received
		public static const EVT_VIDEO_START:String = "onVideoStart"; // When video is playing
		public static const EVT_VIDEO_PLAYING:String = "onVideoPlaying"; // When video is playing
		public static const EVT_VIDEO_STOP:String = "onVideoStop"; // When video is complete AND STOPS PLAYING
		public static const EVT_VIDEO_LOOP:String = "onVideoLoop"; // When video loops - STOP IS NOT BROADCASTED IF VIDEO IS LOOPING
		public static const EVT_VIDEO_PAUSE:String = "onVideoPause"; // When video is playing
		public static const EVT_VIDEO_RESUME:String = "onVideoResume"; // When video is playing
		public static const FADE_TIME:Number = 0.3;
		private static const MOVIE_PLAYING_INTERVAL:Number = 1000; // Milliseconds for each movie playing check interval
		static private var _transitioner:Transitioner;
		private var _imageViewer:ImageViewer;
		//static private var _mediaItemWithImageViewer;
		private var _url:String;
		private var _assetId:String;
		private var _imageViewerUrl:String; // If ImageViewer should load another image
		private var _type:String; // img or mov
		private var _rendered:Boolean;
		private var _img:Image;
		private var _rect:Rectangle;
		//private var _pfVideo:PFVideoStarling;
		private var _motion:String; // "INSTANT", "FADE", "SWIPE...";
		
		private var _active:Boolean; // If this is visible
		private var _moving:Boolean; // If this is transitioning here
		private var _transitionTime:Number;
		private var _swipeDirection:String;
		
		
		private var _hAlign:String = "CENTER";
		private var _vAlign:String = "MIDDLE";
		private var _fill:String = "FILL";
		private var _loadOnVisible:Boolean; // If image is kept loaded all the time, or loaded only when media item is visible
		private var _debugObject:DisplayObject; // Just to be shown on top of rendered content
		// VIDEO ONLY VARIABLES
		private var _nc:NetConnection;
		private var _ns:NetStream;
		private var _videoTexture:Texture;
		private var _videoImage:Image;
		private var _loop:Boolean;
		private var _videoClient:Object; // When video metadata is received it is stored here
		private var _videoMetaData:Object; // Stores MetaData info for the video
		private var _videoIsPlaying:Boolean;
		private var _videoCheckTimer:Timer;

		
		// INIT
		public function MediaItem(url:String=null, type:String=null, rect:Rectangle=null, loadOnVisible:Boolean=false, id:String="") {
			super("MediaItem"+id, MediaItem, false);
			if (!_transitioner) _transitioner = new Transitioner("MediaItem");
			//_pfVideo = new PFVideoStarling(_debugPrefix);
			// Debug media item
			//if (_MainAppBase.instance.isDebug()) {
				//var c:Canvas = new Canvas();
				//c.beginFill(Math.random() * 0xffffff);
				//c.drawCircle(200, 200, 100);
				//addChild(c);
				//_debugObject = c;
			//}
			
			
			_videoClient = {
				onMetaData:onVideoMetaData
			}
			
			
			//if (_rendered) cleanup();
			recycle(url, type, rect, loadOnVisible);
		}
		
		
		
		public function recycle(url:String=null, type:String=null, rect:Rectangle=null, loadOnVisible:Boolean=false):void {
			if (_rendered) cleanup();
			_loadOnVisible = loadOnVisible;
			_rect = rect ? rect : UGlobal.getStageRectProportional();
			_url = url;
			_assetId = _url ? getAssetTextureNameFromPath(_url) : "NONE";
			//_debugPrefix = toString();
			_type = type;
			//trace(_url, type);
			if (_url && !_loadOnVisible) renderUrl(_url);
		}
		
		public function renderXML(xx:XML, rect:Rectangle = null, loadOnVisible:Boolean = false):void { // Grabs data from a stndard XML node <XXX type="img/mov" src="..." loop="true"/>
			Debug.debug(_debugPrefix, "Rendering XML", xx.toXMLString());
			var nodeFill:String = String(xx.@resize);
			fill = uDisplay.validateResizeMode(String(xx.@resize));
			loop = UCode.isTrue(xx.@loop);
			recycle(Config.instance.getLocationSrcUrl(xx, true), String(xx.@type), rect, loadOnVisible);
		}
		
		
		
		// IMAGE VIEWER
		public function activateImageViewer(hasZoom:Boolean = true, hasPan:Boolean = true, hasRotation:Boolean = true, tunnelEventsTarget:DisplayObject = null, url:String=null):void {
			if (isVideo) {
				Debug.debug(_debugPrefix, "Cannot activate ImageViewer on Video.");
				return;
			}
			_imageViewerUrl = url;
			if (!_imageViewer) {
				_imageViewer = new ImageViewer(_rect, hasZoom, hasPan, hasRotation, tunnelEventsTarget, instanceId);
				PippoFlashEventsMan.addInstanceListener(_imageViewer, this);
			}
			//else deactivateImageViewer();
			Debug.debug(_debugPrefix, "Activating image viewer with " + (_imageViewerUrl ? _imageViewerUrl : _assetId));
			//addChild(new Image(mainAssets.getTexture(_assetId)));
			//return;
			
			
			
			if (_imageViewerUrl) _imageViewer.loadImage(_imageViewerUrl);
			else _imageViewer.setImage(new Image(mainAssets.getTexture(_assetId)));
			addChild(_imageViewer);
			//if (_debugObject) addChild(_debugObject);
			_imageViewer.setMotionActive(true);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_IMAGE_VIEWER_READY, this);
		}
		public function deactivateImageViewer():void {
			if (_imageViewer) {
				Debug.debug(_debugPrefix, "Deactivate image viewer.");
				//_imageViewer.setMotionActive(false);
				clearImageViewer();
			}
		}
		public function clearImageViewer():void {
			if (_imageViewer) {
				_imageViewer.clearImage(false);
				//_imageViewer.removeFromParent();
				_imageViewerUrl = null;
			}
		}
		
		public function moveImageViewer(pos:Object):void {
			_imageViewer.jumpToPosition(pos);
		}
		
		
		
		// LOAD NEW URL
		public function renderUrl(url:String):void { // This preloads media, or loads and shows depending on prepareMediaCompete();
			//trace("DAJEEEEEEEEEE");
			_url = url;
			if (!_type) _type = PFVideoStarling.isVideo(_url) ? "mov" : "img";
			_assetId = _url ? getAssetTextureNameFromPath(_url) : "NONE";
			_debugPrefix = toString();
			Debug.debug(_debugPrefix, "renderUrl("+url+")");
			if (isImage)  preloadImage();
			else UExec.next(prepareMediaCompete);
		}
		
		
		// VIDEO ONLY METHODS
		public function playVideo():void {
			if (isVideo) {
				Debug.debug(_debugPrefix, "PLAY");
				Debug.debug(_debugPrefix, "Playing video url: " + _url);
				_ns.play(_url);
			} else Debug.error(_debugPrefix, "Cannot playVideo(), this is an image moron.");
		}
		public function pauseVideo(broadcast:Boolean=true):void {
			if (isVideo && videoIsPlaying) {
				Debug.debug(_debugPrefix, "PAUSE");
				if (broadcast) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_VIDEO_PAUSE, this);
				setVideoPlaying(false, false); // I do not want to broadcast start or stop
				_ns.pause(); 
			} else Debug.error(_debugPrefix, "Cannot pauseVideo(), this is an image moron.");
		}
		public function resumeVideo(broadcast:Boolean=true):void {
			if (isVideo && !videoIsPlaying) {
				Debug.debug(_debugPrefix, "RESUME");
				if (broadcast) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_VIDEO_RESUME, this);
				setVideoPlaying(true, false);  // I do not want to broadcast start or stop
				_ns.resume(); 
			} else Debug.error(_debugPrefix, "Cannot resumeVideo(), this is an image moron.");
		}
		public function toggleVideoPause(broadcast:Boolean=true):void {
			if (isVideo) {
				Debug.debug(_debugPrefix, "TOGGLE PAUSE");
				if (videoIsPlaying) pauseVideo(broadcast);
				else resumeVideo(broadcast);
			} else Debug.error(_debugPrefix, "Cannot togglevideoPause(), this is an image moron.");
		}
		public function playVideoFrom(time:Number):void {
			scrubVideoTime(time);
			resumeVideo();
		}
		/**
		 * Scrubs between 0 and 1.
		 * @param	ratio number from 0 to 1
		 */
		public function scrubVideo(ratio:Number):void {
			ratio = UNumber.getRanged01(ratio);
			scrubVideoTime(UNumber.getRanged(videoDuration * ratio, videoDuration, 0));
			//const time:Number = UNumber.getRanged(videoDuration * ratio, videoDuration, 0);
			//Debug.debug(_debugPrefix, "SCRUB to",ratio,videoDuration,time);
			//_ns.seek(time);
		}
		public function scrubVideoTime(time:Number):void {
			if (_ns) _ns.seek(time);
		}
		
		
		
		
		//public function ():void {
			//
		//}
		
		
		
		
		// PREPARE MEDIA FOR PRELOAD
		private function preloadImage():void {
			if (mainAssets.getTexture(_assetId)) onImageLoaded();
			else loadSingleAsset(_url, onImageLoaded, null, onImageLoadError);
		}
		private function onImageLoaded():void {
			_img = getImage(_assetId);
			addChild(_img);
			if (_debugObject) addChild(_debugObject);
			uDisplay.alignAndResize(_img, _rect, _fill, _hAlign, _vAlign);
			prepareMediaCompete();
		}
		private function onImageLoadError():void {
			Debug.error(_debugPrefix, "Error loading media: " + _url);
			prepareMediaCompete();
		}
		private function prepareMediaCompete():void { // this can be called both on preload or on load on view
			if (_loadOnVisible) startActivation(); // It means this has been loaded on show
			else PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_LOADED, this); // This was only preloaded
		}
		
		
		
		
		
		// MOTION - Media Items only appear, they never disappear unless another media item is on top
		// Fade in
		public function show():void {
			activate("INSTANT");
		}
		public function hide(andDispose:Boolean=false):void {
			deactivate("INSTANT", andDispose);
		}
		public function fadeIn(time:Number = 0):void {
			_transitionTime = time ? time : FADE_TIME;
			activate("FADE");
		}
		public function fadeOut(time:Number = 0, andDispose:Boolean = false):void {
			//trace("FADEOUTTTTTT",andDispose);
			_transitionTime = time ? time : FADE_TIME;
			deactivate("FADE", andDispose);
		}
		public function swipeIn(time:Number=0, direction:String="L"):void {
			_transitionTime = time ? time : FADE_TIME;
			_swipeDirection = direction;
			activate("SWIPE");
		}
		public function swipeOut(time:Number=0, direction:String="L", andDispose:Boolean=false):void {
			_transitionTime = time ? time : FADE_TIME;
			_swipeDirection = direction;
			deactivate("SWIPE", andDispose);
		}
		
		
		

		// ACTIVATE MEDIA
		private function activate(motion:String):void { // Prepare media to be displayed
			if (moving) stopMotion();
			_moving = true;
			_motion = motion;
			_active = true;
			if (_loadOnVisible) renderUrl(_url);
			else startActivation();
		}
		private function startActivation():void { // this can be called immediately if image is preloaded, or after load if image needs to be loaded on view
			if (isImage) mediaIsActive();
			else activateVideo();
		}
		private function stopMotion():void { // Stops a running motion
			if (isFade) mover.stopMotion(this);
			else if (isSwipe) _transitioner.stop(this);
		}
		private function activateVideo():void {
			Debug.debug(_debugPrefix, "activateVideo()");
			if (_nc) {
				Debug.warning(_debugPrefix, "Video already playing. Deactivating first.");
				UExec.next(activate, _motion);
				cleanup();
				return;
			}
			_videoCheckTimer = new Timer(MOVIE_PLAYING_INTERVAL);
			_videoCheckTimer.addEventListener(TimerEvent.TIMER, onVideoPlayCheck);
			_nc = new NetConnection();
			_nc.connect(null);
			_ns = new NetStream(_nc);
			if (USystem.isRunningOnDesktop()) _ns.inBufferSeek = true;
			try { // Testing in SWF video is not available
				_videoTexture = Texture.fromNetStream(_ns, 1, onTextureReady);
			} catch (e:Error) {
				Debug.error(_debugPrefix, "ERROR INITIALIZING VideoTexture: " + e.message);
				return;
			}
			_videoCheckTimer.start();
			_ns.client = _videoClient;
			_ns.addEventListener(NetStatusEvent.NET_STATUS, netStream_Status_Handler);
			playVideo();
		}
		
		
		
		
		// VIDEO NETSTREAM AND METADATA LISTENERS
		private function netStream_Status_Handler(e:NetStatusEvent):void {
			//Debug.debug(_debugPrefix, "NetStream Status: " + Debug.object(e.info));
			const code:String = e.info.code;
			if (code == "NetStream.Play.Start") {
				if (!videoIsPlaying) {
					setVideoPlaying(true);
				}
			}
			else if (code == "NetStream.Play.Stop") { //(code == "NetStream.Play.Stop" && USystem.isDesktop()) || (code ==  "NetStream.Buffer.Empty" && USystem.isDesktop())) {
				if (videoIsPlaying) {
					Debug.debug(_debugPrefix, "NetStream play stopped.");
					//if (USystem.isDevice()) {
					//setVideoPlaying(false);
					if (loop) {				
						setVideoPlaying(false, false); // I do not broadcast stop, but broadcast loop complete
						Debug.debug(_debugPrefix, "Looping...");
						PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_VIDEO_LOOP, this);
						_ns.seek(0);
						_ns.close();
						playVideo(); // this one is used on device since Empty is not triggered
					} else {
						setVideoPlaying(false); // video is complete and broadcasts event
					}
				}
			}
					//}
			//}
			//else if (code ==  "NetStream.Buffer.Empty") {
					//Debug.debug(_debugPrefix, "NetStream buffer emptied.");
					//if (USystem.isDesktop()) {
						//PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_VIDEO_COMPLETE, this);
						//setVideoPlay
					//}
					//if (loop && USystem.isDesktop()) {
						//Debug.debug(_debugPrefix, "On Desktop, looping on buffer empty.");
						//playVideo(); // this one is broadcasted only on desktop
					//}
			//}
		}
		
		private function onVideoMetaData(o:Object):void {
			_videoMetaData = o;
			Debug.debug(_debugPrefix, "Metadata receivd: ", Debug.object(o));
			if (_videoIsPlaying) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_VIDEO_DATA, this);
			else Debug.debug(_debugPrefix, "Not broadcasting event since video is scrubbing.");
		}
		
		private function onVideoPlayCheck(e:TimerEvent):void {
			//Debug.debug(_debugPrefix, "Check play.");
			if (_videoIsPlaying) {
				//Debug.debug(_debugPrefix, "PLAYING");
				starlingCore.skipUnchangedFrames = false; // Kepps setting this to false in case somewhere else is set to true
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_VIDEO_PLAYING, this);
			}
		}
		
		// VIDEO UTILITIES
		private function onTextureReady():void { // Called by 
			Debug.debug(_debugPrefix, "onTextureReady()");
			if (!_active) {
				cleanup();
				return;
			}
			starlingCore.skipUnchangedFrames = false;
			onTexturePlayReady(_videoTexture);
		}
		private function onTexturePlayReady(t:Texture):void {
				_img = new Image(t);
				addChild(_img);
				if (_debugObject) addChild(_debugObject);
				uDisplay.alignAndResize(_img, _rect, _fill);
				UExec.next(mediaIsActive);
		}
		private function setVideoPlaying(playing:Boolean, broadcast:Boolean=true):void {
			_videoIsPlaying = playing;
			if (playing) {
				Debug.debug(_debugPrefix, "Set video to PLAYING");
				_videoCheckTimer.start();
				starlingCore.skipUnchangedFrames = false;
				if (broadcast) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_VIDEO_START, this);
			}
			else {
				Debug.debug(_debugPrefix, "Set video to STOPPED");
				_videoCheckTimer.stop();
				starlingCore.skipUnchangedFrames = true;
				if (broadcast) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_VIDEO_STOP, this);
			}
		}
		
		// UTILITIES
		private function mediaIsActive():void { // Media is ready to be displayed
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_READY, this);
			if (isFade) {
				alpha = 0;
				mover.fade(this, _transitionTime, 1, onMotionInComplete);
			}
			else if (isSwipe) {
				_transitioner.timeIn = _transitionTime;
				_transitioner.maskIn(this, _rect, _swipeDirection, onMotionInComplete);
			}
			else { // Instant show
				onMotionInComplete();
			}
		}
		private function onMotionInComplete():void {
			_moving = false;
			Debug.debug(_debugPrefix, "Arrived ", _url);
			if (!_active) return;
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_ARRIVED, this);
		}
		
		
		
		
		
		
		
		
		
		// DEACTIVATE MEDIA
		public function deactivate(motion:String = "INSTANT", andDispose:Boolean = false):void { // For images basically does nothing
			//trace("DISATTOVI", andDispose);
			if (isVideo) Debug.warning(_debugPrefix, "DEACTIVATE VIDEO");
			if (_moving) stopMotion();
			_motion = motion;
			_moving = true;
			_active = false;
			if (isFade) {
				mover.fade(this, _transitionTime, 0, onMotionOutComplete, andDispose);
			} 
			else if (isSwipe) {
				_transitioner.timeIn = _transitionTime;
				_transitioner.maskOut(this, _rect, _swipeDirection, onMotionOutComplete, andDispose);
			} 
			else onMotionOutComplete(andDispose);
		}
		private function onMotionOutComplete(andDispose:Boolean = false):void {
			if (andDispose || _loadOnVisible) cleanup();
			else if (isVideo) {
				cleanup();
				//_pfVideo.stopAndStore();
				//_pfVideo.fadeOutAudio(0.2, true);
			}
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_LEFT, this);
			clearImageViewer();
			_moving = false;
		}
		
		
		
		
		
		// IMAGE MOTION LISTENERS
		public function onImgMotionComplete(pos:Object):void {
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_IMAGE_VIEWER_MOVED, pos);
		}
		public function onImgMoving(pos:Object):void {
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_IMAGE_VIEWER_MOVED, pos);
		}
		
		
		
		
		// UTILITIES
		public function toString():String {
			return instanceId + " : " + _assetId;
		}
		public function cleanup():void {
			Debug.debug(_debugPrefix, "Cleaning up", _url);
			if (_moving) stopMotion();
			// Remove listeners
			// Cleanup and dispose everything here
			if (isVideo) { // Only video
				if (_nc) {
					_ns.client = {};
					_ns.removeEventListener(NetStatusEvent.NET_STATUS, netStream_Status_Handler);
					_nc.close();
					_ns.close();
					_ns.dispose();
					_nc = null;
					_ns = null;
					_videoMetaData = null;
					_videoIsPlaying = false;
					_videoCheckTimer.stop();
					_videoCheckTimer.reset();
					_videoCheckTimer.removeEventListener(TimerEvent.TIMER, onVideoPlayCheck);
					_videoCheckTimer = null;
					//for (var s:String in _videoMetaData) _videoMetaData[s] = null;
					//_videoMetaData = null;
				}
				if (_videoTexture) {
					_videoTexture.dispose();
				}
				starlingCore.skipUnchangedFrames = true;
			} else { // Only image
				clearImageViewer();
				if (_img) {
					if (_img.texture) _img.texture.dispose(); 
					unloadAssetUrl(_url);
				}
			}
			if (_img) { // Both image and video
				//removeChild(_img);
				_img.removeFromParent();
				_img.dispose();
			}
			_rendered = false;
			_moving = false;
			_active = false;
			_img = null;
			_videoTexture = null;
			_type = null;
		}
		public function removeAllListeners():void { // Called form outside
			PippoFlashEventsMan.removeAllListeningToInstance(this);
		}
		// GETTERS
		public function get active():Boolean {
			return _active;
		}
		public function get moving():Boolean {
			return _moving;
		}
		public function get isImage():Boolean {
			return _type == "img";
		}
		public function get isVideo():Boolean {
			return _type == "mov";
		}
		public function get isInstant():Boolean {
			return _motion == "INSTANT";
		}
		public function get isFade():Boolean {
			return _motion == "FADE";
		}
		public function get isSwipe():Boolean {
			return _motion == "SWIPE";
		}
		/**
		 * CENTER, LEFT, RIGHT
		 */
		public function set hAlign(value:String):void {
			_hAlign = value;
		}
		/**
		 * MIDDLE, TOP, BOTTOM
		 */
		public function set vAlign(value:String):void {
			_vAlign = value;
		}
		 public function get url():String {
			 return _url;
		 }
		/**
		 * _StarlingUDisplay.RESIZE_ constants.
		 */
		public function set fill(value:String):void {
			_fill = value;
		}
		public function get loop():Boolean {
			return _loop;
		}
		public function set loop(value:Boolean):void {
			_loop = value;
		}
		public function get videoDuration():Number {
			return _videoMetaData ? _videoMetaData.duration : 0;
		}
		/**
		 * percent of completion of video between 0 and 1
		 */
		public function get videoCompletion():Number { // Video completion between 0 and 1
			return videoPlayed / videoDuration;
		}
		public function get videoIsPlaying():Boolean 
		{
			return _videoIsPlaying;
		}
		
		public function get videoMetaData():Object 
		{
			return _videoMetaData;
		}
		
		public function get videoPlayed():Number {
			//trace("PLKAYEDDDDDDDDDDDDDDDDD", _ns.time);
			return _ns ? _ns.time : 0;
		}
		public function get videoTimeRemaining():Number {
			return _videoMetaData ? _videoMetaData.duration - videoPlayed : 0;
		}
	}

}