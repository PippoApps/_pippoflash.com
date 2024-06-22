package com.pippoflash.framework.starling 
{
	import com.pippoflash.framework._ApplicationStarling;
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMemDispatcher;
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.utils.UExec;
	import com.pippoflash.utils.UText;
	import flash.events.NetStatusEvent;
	import flash.geom.Rectangle;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import starling.textures.Texture;
	import com.pippoflash.utils.Debug;
	import flash.media.SoundTransform;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * This uses the same emethods as PFVideo, but works on Starling using textures, and always recycles the same txtures.
	 * It can show up to 4 concurrent videos respecting 4 textures limitation in AIR.
	 * It will allowinfinite instantiation and usage but will always return one texture.
	 * Visually, callback on video play has only one parameter, the used texture.
	 */
	public class PFVideoStarling extends _PippoFlashBaseNoDisplayUMemDispatcher 
	{
		// CONSTANTS
		public static const EVT_INIT:String = "onVideoInit"; // When video has started playing for the first time
		public static const EVT_START:String = "onVideoStart"; // When video has started playing, first time and loops
		public static const EVT_LOOP:String = "onVideoLoop"; // When video started playinf from first loop onwards
		public static const EVT_COMPLETE:String = "onVideoComplete"; // When video has complete playing, single or loop
		public static const EVT_ERROR:String = "onVideoError"; // Video error, not found or stream error
		private static const MAXIMUM_VIDEO_INSTANCES:uint = 0; // N more than 4
		// STATIC VARIBALES
		private static const _mover:PFMover = new PFMover("PFVideoStarling");
		static private var _textureInstances:Vector.<Texture>;
		static private var _netStreams:Vector.<NetStream>;
		static private var _netConnections:Vector.<NetConnection>;
		
		static private var _activeVideoInstances:Vector.<PFVideoStarling>; // Active video instances assigned with number
		static private var _videoInstances:Vector.<PFVideoStarling>; // All created video instances
		
		
		static private var _freeTextures:Vector.<Texture>;
		
		
		static private var _isPlaying:Boolean; // Marks if one of the video instances is actully playing
		static private var _starlingSkipUnchangedFrames:Boolean; // Stores original value of this to disable and re-enable on video playing
		
		
		
		// INSTANCE
		private var _id:uint;
		private var _callback:Function; // Called with one parameter: Texture when play is ready
		private var _myTexture:Texture; // Marks if this video instance has a video texture
		
		
		// When playing
		private var _textureId:int; // 0 to 3, -1 when not active
		private var _active:Boolean; // If there is a texture connected
		private var _url:String;
		private var _repeat:Boolean;
		private var _texture:Texture;
		private var _ns:NetStream;
		private var _nc:NetConnection;
		private var _loopsPlayed:uint;
		private var _isRunning:Boolean;
		// STSTIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function isVideo(url:String):Boolean { // If a URL type is a video
			return UText.stringContains(url, ".mp4");
		}
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PFVideoStarling(videoId:String = null) {
			super("PFVideoStarling_" + videoId);
			initPFVideoStarling();
			_videoInstances.push(this);
		}
		static private function initPFVideoStarling():void {
			if (_textureInstances) return; // It has already been initialized
			_starlingSkipUnchangedFrames = _ApplicationStarling.skipUnchangedFrames; // Store whether application has skip unchanged frames to true		
			var videoInstancesNum:uint = MAXIMUM_VIDEO_INSTANCES;
			// Debug to change number
			//videoInstancesNum = 50;
			//if (!_textureInstances) { // initialization goes here
				_videoInstances = new Vector.<PFVideoStarling>();
				_activeVideoInstances = new Vector.<PFVideoStarling>(videoInstancesNum);
				_freeTextures = new Vector.<starling.textures.Texture>();
				_textureInstances = new Vector.<starling.textures.Texture>(videoInstancesNum);
				_netStreams = new Vector.<flash.net.NetStream>(videoInstancesNum);
				_netConnections = new Vector.<flash.net.NetConnection>(videoInstancesNum);
				var nc:NetConnection; var ns:NetStream; var t:Texture;
				var netStreamListeners:Array = [onNetStreamStatus0, onNetStreamStatus1, onNetStreamStatus2, onNetStreamStatus3];
				var playReadyListeners:Array = [onTexturePlayReady0, onTexturePlayReady1, onTexturePlayReady2, onTexturePlayReady3];
				for (var i:int = 0; i < videoInstancesNum; i++) 
				{
					activateVideoInstance(i, netStreamListeners[i], playReadyListeners[i]);
					//UExec.frame((i * 60) + 1, activateVideoInstance, i, netStreamListeners[i], playReadyListeners[i]);
					//UExec.frame((i * 60) + 1, activateVideoInstance, i, function() {}, function() {});
				}
				//activateVideoInstance(0, onNetStreamStatus0, onTexturePlayReady0);
				//activateVideoInstance(1, onNetStreamStatus1, onTexturePlayReady1);
				//activateVideoInstance(2, onNetStreamStatus2, onTexturePlayReady2);
				//activateVideoInstance(3, onNetStreamStatus3, onTexturePlayReady3);
				//for (var i:int = 0; i < videoInstancesNum; i++) {
					//Debug.debug("PFVideoStarling", "Initializing video instance # " + i);
					////trace(netStreamListeners);
					////trace(playReadyListeners);
					//nc = new NetConnection();
					//nc.connect(null);
					//ns = new NetStream(nc);
					//ns.addEventListener(NetStatusEvent.NET_STATUS, netStreamListeners[i]);
					//t = Texture.fromNetStream(ns, 1, playReadyListeners[i]);
					//_freeTextures.push(t);
					//_textureInstances[i] = t;
					//_netStreams[i] = ns;
					//_netConnections[i] = nc;
				//}
			//}
			
		}
		//static private function activateVideoInstance():void {
		//}
		private static function activateVideoInstance(i:uint, netStreamHandler:Function, onTextureReadyHandler:Function):void {
			Debug.debug("PFVideoStarling", "Initializing video instance # " + i, netStreamHandler, onTextureReadyHandler);
			var nc:NetConnection; var ns:NetStream; var t:Texture;
			nc = new NetConnection();
			nc.connect(null);
			ns = new NetStream(nc);
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStreamHandler);
			t = Texture.fromNetStream(ns, 1, onTextureReadyHandler);
			_freeTextures.push(t);
			_textureInstances[i] = t;
			_netStreams[i] = ns;
			_netConnections[i] = nc;
		}
		
		
		// STATIC //////////////////////////////////////////////////////////////////////////////////////////////
		private static function onTexturePlayReady0():void {
			onTexturePlayReady(0);
		}
		private static function onTexturePlayReady1():void {
			onTexturePlayReady(1);
		}
		private static function onTexturePlayReady2():void {
			onTexturePlayReady(2);
		}
		private static function onTexturePlayReady3():void {
			onTexturePlayReady(3);
		}
		static private function onTexturePlayReady(id:uint):void {
			// Real event processing is done in NetStream events
			Debug.debug("PFVideoStarling", "Texture first intializaion complete # " + id);
		}
		private static function onNetStreamStatus0(e:NetStatusEvent):void {
			onNetStreamStatus(0, e.info);	
		}
		private static function onNetStreamStatus1(e:NetStatusEvent):void {
			onNetStreamStatus(1, e.info);	
		}
		private static function onNetStreamStatus2(e:NetStatusEvent):void {
			onNetStreamStatus(2, e.info);	
		}
		private static function onNetStreamStatus3(e:NetStatusEvent):void {
			onNetStreamStatus(3, e.info);	
		}
		private static function onNetStreamStatus(id:uint, info:Object):void {
			_activeVideoInstances[id].processNetStreamEvent(info);
		}
		//static private function getFreeTexture():Texture {
			//return _texture;
		//}
		
		// INSTANCE ////////////////////////////////////////////////////////////////////////////////////////////////////////
		// PUBLIC METHODS
		public function play(u:String, callback:Function, repeat:Boolean=false):void {
			Debug.debug(_debugPrefix, "Playing video: " + u);
			if (!_active && !_freeTextures.length) {
				Debug.error(_debugPrefix, "There is no video texture free avilable. Maximum number in use.");
				return; 
			}
			// If video is already playing, just kill this one and play another one (instance will be freed by this)
			// In case is fading audio, remove motions, store and start at next frame
			if (_active) {
				_mover.stopMotion(this);
				stopAndStore();
				UExec.next(play, u, callback, repeat);
				return;
			}
			// Proceed playing - there is already a texture
			if (!_active) { // Create texture and netstream
				_texture = _freeTextures.pop();
				_textureId = _textureInstances.indexOf(_texture);
				_ns = _netStreams[_textureId];
				_nc = _netConnections[_textureId];
				_activeVideoInstances[_textureId] = this;
				_active = true;
			}
			checkForActiveVideos();
			_callback = callback;
			_repeat = repeat;
			_url = u;
			_loopsPlayed = 0;
			Debug.debug(_debugPrefix, "Playing video on texture # " + _textureId);
			_ns.soundTransform = new SoundTransform(1);
			_ns.play(_url);
			//_ns.seek(0);
		}
		public function replay():void {
			if (!_active) return;
			Debug.debug(_debugPrefix, "Replaying video.");
			if (_ns) _ns.seek(0);
			else Debug.error(_debugPrefix, "replay() error: netstream not active and defined.");
		}
		public function fadeInAudio(time:Number = 0.4):void {
			_ns.soundTransform = new SoundTransform(0);
			_mover.move(this, time, {volume:1}, "Linear.easeOut");
		}
		public function fadeOutAudio(time:Number=0.4, stopAndStoreOnFade:Boolean=false):void {
			_mover.move(this, time, {volume:0, onComplete:stopAndStoreOnFade ? stopAndStore : null}, "Linear.easeOut");
		}
		public function stopAndStore():void { // Stops the video and stores the instance
			if (!_active) return;
			_active = false;
			_ns.close();
			Debug.scream(_debugPrefix, "DISPOSING NETSRTEAM");
			_ns.dispose();
			_ns = null;
			//_nc.close();
			_nc = null;
			_freeTextures.push(_texture);
			//_texture.dispose();
			_texture = null;
			_activeVideoInstances[_textureId] = null;
			_textureId = -1;
			_url = null;
			checkForActiveVideos();
		}		
		// METHODS CALLED FROM STATIC
		protected function processNetStreamEvent(info:Object):void {
			Debug.debug("PFVideoStarling", _id, "onNetStreamStatus", Debug.object(info));		
			if (info.code == "NetStream.Play.Start") {
				if (_loopsPlayed == 0) {
					broadcastEvent(EVT_INIT, _texture);
					_callback(_texture);
					_callback = null;
				}
				broadcastEvent(EVT_START);
			}
			else if (info.code == "NetStream.Play.Complete" || info.code == "NetStream.Play.Stop") {
				if (_active) {
					_loopsPlayed ++;
					broadcastEvent(EVT_COMPLETE);
					if (_repeat) replay();
					else stopAndStore();
				}
			}
			else if (info.code == "NetStream.Play.StreamNotFound") {
				broadcastEvent(EVT_ERROR);
				checkForActiveVideos();
			}
		}
		// GETTERS AND SETTRS
		public function get volume():Number {
			if (_ns) return _ns.soundTransform.volume;
			else return 0;
		}
		
		public function get active():Boolean 
		{
			return _active;
		}
		
		public function set volume(v:Number):void {
			if (_ns) _ns.soundTransform = new SoundTransform(v);
		}
		// UTILITIES
		static protected function checkForActiveVideos():void {
			//return;
			if (!_starlingSkipUnchangedFrames) return; // Skip unchanged frames is not set
			var av:PFVideoStarling;
			for each (av in _activeVideoInstances) {
				if (av) { // Found an active video - one is enough to force remove skip unchanged frames
					Debug.warning(PFVideoStarling, "Removing skipUnchangedFrames in order to play video smoothly.");
					_ApplicationStarling.skipUnchangedFrames = false;
					return; 
				}
			}
			// No active videos found
			Debug.warning(PFVideoStarling, "No videos playing. Setting again skipUnchangedFrames to true.");
			_ApplicationStarling.skipUnchangedFrames = true;
		}
	}

}