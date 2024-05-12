/* PFVideo - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Uses ByteArray class SimpleStageVideo.	

*/

package com.pippoflash.media {

	import com.adobe.protocols.dict.Database;
	import flash.utils.Timer;
	import com.pippoflash.framework.PippoFlashEventsMan;

	import									com.pippoflash.utils.*;
	import									com.pippoflash.framework._PippoFlashBaseNoDisplayUMemDispatcher;
	import									flash.media.*;
	import									flash.net.*;
	import									flash.events.*;
	import									flash.geom.*;
	import									flash.display.*;
	
	public class PFVideo extends _PippoFlashBaseNoDisplayUMemDispatcher {
// VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		public static const EV_SV_AVAIL				:String = "onStageVideoAvailability"; // (available:Boolean) Broadcasted when after PFVideo.init(), it is known if stagevideo is available or not. Do stuff AFTER this event.
		public static const PLAY_START_EVENT		:String = "onPFVideoPlayStart";
		// public static const EVT_PLAY_REACHED_END:String = "EVT_PLAY_REACHED_END"; // Not sure why play complete does    not work locally on  windows
		public static const EVT_PLAY_STOP:String = "EVT_PLAY_STOP"; // Not sure why play complete does    not work locally on  windows
		public static const EVT_PLAYING:String = "EVT_PLAYING"; // this - Regularly sends data on playhead position
		public static const PLAY_COMPLETE_EVENT		:String = "onPFVideoPlayComplete";
		public static const LOOP_COMPLETE_EVENT		:String = "onPFVideoLoopComplete";
		public static const PLAY_DELAY_ELAPSED_EVENT	:String = "onPFVideoPlayDelayElapsed";
		public static const STREAM_NOT_FOUND_EVENT	:String = "onPFVideoNotFound";
		public static const ON_METADATA				:String = "onPFVideoMetaData";
		private static const SECONDS_DELAY_VISIBLE	:uint = 2; // If frame daley is active, this is the time (IN SECONDS) it is going to wait before making video visible, in order to prevent a bug on android
		private static var _forceSoftwareVideo			:Boolean;
		private static var _debugPrefix				:String = "PFVideo";
		private static var _stageVideosUsed			:uint = 0; // This lets us know if
		private static var _pfVideos					:Array = [];
		public static var _verbose					:Boolean = true;

		private var _triggerEventsWithBytes:Boolean;

		public function get triggerEventsWithBytes():Boolean
		{
			return _triggerEventsWithBytes;
		}

		public function set triggerEventsWithBytes(value:Boolean):void
		{
			_triggerEventsWithBytes = value;
		}


		private var _svNum						:uint; // Which number in stagevideos array I am using
		// REFERENCE TO VIDEO OBJECT
		private var _sv							:StageVideo;
		private var _v							:Video;
		private var _myVideo						:*; // References to Video or StageVideo according to the kind of initialization done
		private var _id							:String;
		private var _nc							:NetConnection;
		private var _ns							:NetStream;
		private var _rect							:Rectangle;
		private var _isStageVideo					:Boolean;
		private var _url							:String;
		private var _repeat						:Boolean;
		private var _showOnlyWhenPlaying			:Boolean; // If this is on, video will be visible ONLY when is playing
		private var _delayOneFrameOnPlay			:Boolean; // If this is on, shows the video 1 frame after it is playing, to prevent the bug on Android that shows a frame of the previous video
		private var _eventPostfix					:String;
		private var _playEventTimer:Timer = new Timer(100, 0);
		private var _playEventTimerLastTime:Number; // Stores last time and broadcasts only if different
		// private var _metaData:Object;
		// LOOPING
		private var _playLoops						:uint; // Stors howmany loops we have to play
		private var _loopsPlayed					:uint; // Stores howmany loops we played already
		// FRAMEWORK
		private var _PFAVLocal						:PFAVLocal;
		// Formatted data holders
		private var _metaData					:Object; // Object as returned from metadata
		// STATIC
		//private static var _initListener:Object;
		private static var _initListenerMethod:Function;
		private static var _svAvailable				:Boolean; // Marks if stage video is available. Must call the static init() function
// 		// 1 stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, availabilityChanged);
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PFVideo					(videoId:String=null, videoUrl:String=null, r:Rectangle=null, repeat:Boolean=false, listener:*=null, postfix:String="", forceSoftware:Boolean=false):void {
			super							(videoId ? videoId : ("PFVideo"+Math.random()));
			_rect								= r ? r : UGlobal.getStageRect();		
			_repeat							= repeat;
			if (listener)						addListener(listener);
			_eventPostfix						= postfix;
			_id								= _debugPrefix + "_" + (postfix ? postfix : Math.random());
			_nc								= new NetConnection();
			_nc.connect						(null);
			_nc.addEventListener					(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
			initVideo							(forceSoftware);
			Debug.debug						(_debugPrefix, "Initializing " + (_isStageVideo ? "StageVideo instance." : "Regular Video (StageVideo not available)."));
			_playEventTimer.addEventListener(TimerEvent.TIMER, onPlayEventTimer);
			if (videoUrl)						play(videoUrl);
		}
// STATIC ///////////////////////////////////////////////////////////////////////////////////////
/**
 * Must be called at the beginning of each video session. Init method is returned with a boolean.
 * @param	listenerMethod called with a boolean (HW video available) if set.
 */
		public static function init(listenerMethod:Function = null):void { /* MUST BE CALLED ON INIT */
			//if (listenerMethod) {
				_initListenerMethod = listenerMethod;
			//}
			//else if (listener) {
				//_initListener						= listener;
				//_initListenerMethod = listenerMethod ? listenerMethod : _initListener[EV_SV_AVAIL];
			//} else Debug.warning(_debugPrefix, "No INIT listener method has been defined.");
			UGlobal.stage.addEventListener			(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, availabilityChanged);
		}
		private static function availabilityChanged		(e:StageVideoAvailabilityEvent):void {
			_svAvailable						= e.availability == StageVideoAvailability.AVAILABLE && !_forceSoftwareVideo;
			UGlobal.stage.removeEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, availabilityChanged);			
			Debug.debug(_debugPrefix, "Stage video " + (_svAvailable ? (" is available! Num:" + UGlobal.stage.stageVideos.length) : " is NOT AVAILABLE."));
			UMethod.callMethod(_initListenerMethod, _svAvailable);
			_initListenerMethod = null;
			// UCode.broadcastEvent				(_initListener, EV_SV_AVAIL, [_svAvailable]);

// 			_initListener						= null;
		}
		public static function forceSoftwareVideo(f:Boolean=true):void { // This will always force software video to be used instead of stage video
			_forceSoftwareVideo = f;
		}
		public static function stageVideoAvailable():Boolean {
			return _svAvailable;
		}
// METHODS ///////////////////////////////////////////////////////////////////////////
	// VIDEO OBJECT ///////////////////////////////////////////////////////////////////////////////////////
		public function addVideo(container:DisplayObjectContainer):void { // If it is a Video object, it gets attached to the parent, otherwise, it gets simply activated
			if (_isStageVideo) {
				Debug.debug(_debugPrefix, "This is a StageVideo, no need to add it.");
				// Code to play StageVideo. Nothing particularily. StageVideo is already there.
			}
			else {
				Debug.debug(_debugPrefix, "Adding a software Video renderer.");
				container.addChild(_v);
				/* WORKAROUND FOR ANDROID IN PORTRAIT MODE 
				 * https://github.com/airsdk/Adobe-Runtime-Support/issues/1025 */
				/*
				var w:Number = _v.width;
				var h:Number = _v.height;
				_v.height = w;
				_v.width = h;
				_v.rotation = -90;
				_v.y = h;
				// Adding mirroring
				// It reports correct scaling, but width and height are inverted! Read after rotation.
				// trace(_v.scaleY, _v.height, _v.scaleX, _v.width, _v.y, _v.x);
				_v.scaleY *= -1;
				_v.x = _v.width; // This should be height, but it reports inverted height and width
				*/
			}
		}
		public function removeVideo():void {
			if (_isStageVideo) {
				stop();
			} else {
				UDisplay.removeClip(_v);
			}
		}
		public function setVideoVisible(v:Boolean):void {
			if (!_isStageVideo) {
				Debug.debug(_debugPrefix, "Setting video visible: " + v);
				_myVideo.visible = v;
			}
		}
		public function setRepeat(r:Boolean):void { // This sets infinite repeat on and off
			_repeat = r;
		}
		public function setVisibleOnlyWhenPlaying(v:Boolean, delay:Boolean=false):void {
			_showOnlyWhenPlaying = v;
			_delayOneFrameOnPlay = delay;
		}
		public function play(u:String, loops:uint=1, resetStream:Boolean=true):void {
			if (_verbose) Debug.debug(_debugPrefix, "Play video " + u);
			// Activate loops and reset counters
			_playLoops = loops > 1 ? loops : 1;
			_loopsPlayed = 0;
			// Go ahead with playing
			_url = u;
			if (resetStream || !_ns) { // this is used to prevent a bug on Android, that when I play a new video, it shows the last frame of the last played video
				stop(resetStream);
				resetVideo();
				createNetStream();
			}
			if (_showOnlyWhenPlaying) setVideoVisible(false); // If visible only when playing, video gets visible only on play started
			_metaData = null;
			_playEventTimerLastTime = -1;
			_ns.play(_url);
		}
		public function pause():void {
			if (!_ns) {
				Debug.warning(_debugPrefix, "pause() error: NetStream not defined.");
				return;
			}
			_ns.pause();
		}
		public function resume():void {
			if (!_ns) {
				Debug.warning(_debugPrefix, "resume() error: NetStream not defined.");
				return;
			}
			_ns.resume();
		}
		public function seekToEnd():void {
			Debug.debug(_debugPrefix, "Seeking to END: " + getDuration());
			if (!_ns) {
				Debug.warning(_debugPrefix, "seekToEnd() error: NetStream not defined.");
				return;
			}
			_ns.seek(getDuration());
		}
		public function seek(n:Number):void {
			if (!_ns) {
				Debug.warning(_debugPrefix, "seek() error: NetStream not defined.");
				return;
			}
			Debug.debug(_debugPrefix, "sSeeking playhead to: " + n);
			_ns.seek(n);
		}
		public function seekPercent(n:Number):void {
			if (!_ns) {
				Debug.warning(_debugPrefix, "seekPercent() error: NetStream not defined.");
				return;
			}
			_ns.seek(UNumber.getPercent(getDuration(), n));
		}
		public function stop(andDispose:Boolean=false):void {
			if (_ns) {
				_ns.close();
				if (andDispose) {
					_ns.dispose();
					disposeNetStream();
				}
			}
			if (_myVideo is Video)				_myVideo.clear();
			if (_showOnlyWhenPlaying)				_myVideo.visible = false;
		}
		public function replay():void {
			_ns.seek(0);
			_ns.resume();
		}
		public function resetLoops					():void { // starts loop counting again from 0
			_loopsPlayed						= 0;
		}
		public function getStageVideo				():StageVideo {
			return							_sv;
		}
		public function getVideo					():Video {
			Debug.debug						(_debugPrefix, "Software video? ",_v,_sv);
			return							_v;
		}
		public function getAvailableVideo				():* {
			return							_isStageVideo ? _sv : _v;
		}
		public function getLoopsPlayed				():int {
			return							_loopsPlayed;
		}
		public function resize						(r:Rectangle):void {
			if (_isStageVideo) {
				_sv.viewPort					= r;
			}
			else {
				_v.x							= r.x;
				_v.y							= r.y;
				_v.height						= r.height;
				_v.width						= r.width;
			}
		}
		public function isStageVideo():Boolean {
			return _isStageVideo;
		}
		public function isSoftwareVideo():Boolean {
			return !_isStageVideo;
		}
		public function setupLocalAV				(av:PFAVLocal, activate:Boolean=true):void {
			_PFAVLocal							= av;
			if (activate)						activateLocalAV();
		}
		public function activateLocalAV				(a:Boolean=true):void {
			if (!_PFAVLocal) {
				Debug.error					(_debugPrefix, "Can't activateLocalAV(), PFAVLocal not setup, call setupLocalAV(pf:PFAVLocal); first!");
				return;
			}
			if (a) {
				Debug.debug					(_debugPrefix, "Activating PFAVLocal on " + (_isStageVideo ? "StageVideo #"+_svNum : "normal Video object."));
				_myVideo.attachCamera			(_PFAVLocal.getDefaultCam());
			}
			else {
				_myVideo.attachCamera			(null);
			}
		}
		public function attachStream				(ns:NetStream):void {
			_ns								= ns;
			_myVideo.attachNetStream				(_ns); // this is the same for Video and StageVideo
		}
// VIDEO INFO ///////////////////////////////////////////////////////////////////////////////////////
		public function getDuration				():Number { // duration string
			return							_metaData ? _metaData.duration : 0;
		}
		public function getDurationString			():String {
			return							_metaData ? UText.checkOneZero(Math.floor(Math.round(getDuration())/60)) + ":" + UText.checkOneZero(Math.round(getDuration())%60) : "00:00";
		}
		public function getElapsed				():Number {
			return							_ns ? _ns.time : 0;
		}
		public function getElapsedString			():String {
			return							_metaData ? UText.checkOneZero(Math.floor(Math.round(getElapsed())/60)) + ":" + UText.checkOneZero(Math.round(getElapsed())%60) : "00:00";
		}
// PLAY EVENT TIMER ////////////////////////////////////////////////////////////////////////////////////
		public function activatePlayEventTimer():void {
			_playEventTimer.reset();
			_playEventTimer.start();
		}
		public function deActivatePlayEventTimer():void {
			_playEventTimer.stop();
		}
		public function onPlayEventTimer(e:TimerEvent):void {
			// trace("timer " + (_ns ? _ns.time : 0));
			if (_playEventTimerLastTime != _ns.time) {
				_playEventTimerLastTime = _ns.time;
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_PLAYING);
			} 
		}
// NET LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onNetStreamStatus			(e:NetStatusEvent):void {
			if (_verbose)						Debug.debug(_id, "onNetStreamStatus",e,Debug.object(e.info));
			processNetStatusEventObject			(e.info);
		}
		public function onNetConnectionStatus		(e:NetStatusEvent):void {
			if (_verbose)						Debug.debug(_id, "onNetConnectionStatus",e,Debug.object(e.info));
		}
		private function processNetStatusEventObject	(o:Object):void {
			if (_verbose) Debug.debug(_debugPrefix, "Processing: " + o.code);
			if (o.code == "NetStream.Play.Start") onPlayStarted();
			else if (o.code == "NetStream.Play.Stop") onPlayStop();
			else if (o.code == "NetStream.Pause.Notify") {
				deActivatePlayEventTimer();
				// Debug.warning(_debugPrefix, "REMEMBER TO INTERCEPT UNPAUSE AND REACTVATE TIMEER EvENT");
			}
			else if (o.code == "NetStream.Play.Complete") {
				_loopsPlayed ++;
				if (_loopsPlayed >= _playLoops) onPlayComplete();
				else onLoopComplete();
			}
			else if (o.code == "NetStream.Play.StreamNotFound") {
				onStreamNotFound();
			}
		}
		private function onPlayStarted():void {
			if (_verbose) Debug.debug(_debugPrefix, "onPlayStarted()");
			if (_showOnlyWhenPlaying) {
				if (_delayOneFrameOnPlay && _loopsPlayed == 0) { // Only does this on first play, if it is looping, no need to hide the video
					setVideoVisible				(false);
					UExec.time(SECONDS_DELAY_VISIBLE, onPlayDelayElapsed);
				}
				else _myVideo.visible = true;
			}
			broadcastEvent(PLAY_START_EVENT, this);
			activatePlayEventTimer();
		}
		private function onPlayDelayElapsed(e:*=null):void {
			setVideoVisible(true);
			broadcastEvent(PLAY_DELAY_ELAPSED_EVENT);
		}
		// private function onPlayReachedEnd():void {
		// 	broadcastEvent						(EVT_PLAY_REACHED_END+_eventPostfix);
		// }
		private function onLoopComplete():void {
			Debug.debug(_debugPrefix, "Loop Complete.");
			broadcastEvent(LOOP_COMPLETE_EVENT, _loopsPlayed);
			_ns.seek(0);
		}
		private function onPlayStop(e:*=null):void {
			if (_verbose) Debug.debug(_debugPrefix, "onPlayStop()");
			// _ns.seek(_ns.info.);
			// _ns.pause();
			broadcastEvent(EVT_PLAY_STOP);
			deActivatePlayEventTimer();
			if (_repeat) replay();
		}
		private function onPlayComplete():void {
			Debug.debug(_debugPrefix, "onPlayComplete()");
			// if (_showOnlyWhenPlaying) _myVideo.visible = false;
			broadcastEvent(PLAY_COMPLETE_EVENT);
			// if (_repeat) _ns.seek(0);
		}
		private function onStreamNotFound			():void {
			Debug.debug						(_debugPrefix, "Stream not found: " + _url + ". Broadcasting " + STREAM_NOT_FOUND_EVENT+_eventPostfix+"()");
			broadcastEvent						(STREAM_NOT_FOUND_EVENT);
		}
		// For full description please look: http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/net/NetStream.html#client
		public function onCuePoint				(o:Object):void {
			if (_verbose)						Debug.debug						(_id, "onCuePoint\n",Debug.object(o));
		}
		public function onXMPData				(o:Object):void {
			if (_verbose)						Debug.debug						(_id, "onXMPData\n",Debug.object(o));
		}
		public function onMetaData				(o:Object):void {
			if (_verbose)						Debug.debug(_id, "onMetaData\n",Debug.object(o));
			// trace("o.duration",o.duration);
			_metaData						= o;
			broadcastEvent						(ON_METADATA, o);
		}
		public function onPlayStatus				(o:Object):void {
			if (_verbose) 						Debug.debug(_id, "onPlayStatus\n",Debug.object(o));
			processNetStatusEventObject			(o);
			// onPlayStatus {level:status, code:NetStream.Play.Complete}
		}
		public function onSeekPoint				(o:Object):void {
			if (_verbose)						Debug.debug						(_id, "onSeekPoint\n",Debug.object(o));
		}
		public function onTextData				(o:Object):void {
			if (_verbose)						Debug.debug						(_id, "onTextData\n",Debug.object(o));
		}
		public function onImageData				(o:Object):void {
			if (_verbose)						Debug.debug						(_id, "onImageData\n",Debug.object(o));
		}
		public function stopTransmit				(o:Object=null):void {
			if (_verbose)						Debug.debug						(_debugPrefix, "received stopTransmit " + Debug.object(o));
		}
	// PippoFlash Framework /////////////////////////////////////////////////////
		// onCuePoint(), onImageData(), onMetaData(), onPlayStatus(), onSeekPoint(), onTextData(), and onXMPData().
		
// NETSTREAM ///////////////////////////////////////////////////////////////////////////////////////
		private function createNetStream():void {
			_ns = new NetStream(_nc);
			_ns.client = this;
			_ns.inBufferSeek = true;
			_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
			attachStream(_ns); // By default it attaches the internal netstream
		}
		private function disposeNetStream():void {
			if (_ns) {
				_ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
				_ns.client = {};
			}
			_myVideo.attachNetStream(null); // this is the same for Video and StageVideo
			_ns = null;
		}
// VIDEO  - INIT ///////////////////////////////////////////////////////////////////////////////////////
		private function initVideo(forceSoftware:Boolean=false):void {
			if (isAvailable() && !forceSoftware) initStageVideo();
			else initRegularVideo();
		}
		public function resetVideo					():void { // this resets video instance and creates a new one with the same characteristics
			var container						:DisplayObjectContainer;
			if (_myVideo) {
				if (_myVideo is Video)			_myVideo.clear();
				_myVideo.attachNetStream			(null);
				_myVideo.attachCamera			(null);
				if (_isStageVideo) { // Stuff for StageVideo
					_sv.removeEventListener		(StageVideoEvent.RENDER_STATE, onStageVideoRender);
					UCode.removeArrayItem		(_pfVideos, this);
					_stageVideosUsed			--;
				}
				else { // Stuff for regular video
					if (_myVideo.parent) {
						container				= _myVideo.parent;
					}
				}
			}
			_sv = null; _v = null; _myVideo = null;
			if (_isStageVideo)					initStageVideo();
			else								initRegularVideo();
			if (!_isStageVideo && container)			addVideo(container);
		}
// STAGE VIDEO ///////////////////////////////////////////////////////////////////////////////////////
		private function initStageVideo				():void {
			_isStageVideo						= true;
			_svNum							= _stageVideosUsed;
			_sv								= UGlobal.stage.stageVideos[_stageVideosUsed];
			_stageVideosUsed					++;
			_pfVideos.push						(this);
			_sv.addEventListener					(StageVideoEvent.RENDER_STATE, onStageVideoRender);
// 			_sv.viewPort						= _rect;
			_sv.attachNetStream					(_ns);
			_myVideo							= _sv;
			Debug.debug						(_debugPrefix, "Initialized StageVideo: " + _sv);
		}
		private function onStageVideoRender			(e:StageVideoEvent):void {
			Debug.debug						(_id, "onStageVideoRender", e);
			_sv.viewPort						= _rect;
		}
// NORMAL VIDEO ///////////////////////////////////////////////////////////////////////////////////////
		private function initRegularVideo				():void {
			_isStageVideo						= false;
			_v								= new Video(_rect.width, _rect.height);
			_v.x								= _rect.x;
			_v.y								= _rect.y;
			_v.smoothing = true;
			_myVideo							= _v;
			Debug.debug						(_debugPrefix, "Initialized Software Video: " + _v);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		public function isAvailable					():Boolean {
			return							_svAvailable && !_forceSoftwareVideo && _stageVideosUsed < UGlobal.stage.stageVideos.length;
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