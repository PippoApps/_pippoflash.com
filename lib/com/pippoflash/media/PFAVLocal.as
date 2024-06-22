/* PFAVLocal - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Uses ByteArray class SimpleStageVideo.	

*/

package com.pippoflash.media {

	import									com.pippoflash.utils.*;
	import									com.pippoflash.framework._PippoFlashBase;
	import									flash.media.*;
	import									flash.net.*;
	import									flash.events.*;
	import									flash.geom.*;
	import flash.events.PermissionEvent;
	import flash.permissions.PermissionStatus;
	
	
	public class PFAVLocal extends _PippoFlashBase {
// VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		// Static
		private static const EV_CAM_ALLOWED		:String = "onCameraPermissionAllowed";
		private static const EV_CAM_DENIED		:String = "onCameraPermissionDenied";
		private static const EV_CAM_ACTIVATING	:String = "onCameraActivating";
		private static const EV_CAM_DEACTIVATING	:String = "onCameraDeactivating";
		private static const EV_MIC_ALLOWED		:String = "onMicrophonePermissionAllowed";
		private static const EV_MIC_DENIED		:String = "onMicrophonePermissionDenied";
		private static const CAM_MAX_W			:uint = 720; // 720x480 = HD, I use half (360*240)
		private static const CAM_MAX_H			:uint = 480;
		private static const CAM_MAX_FPS		:uint = 12;
		private static const CAM_BANDWIDTH_RATIO	:int = 24000;
		private static const CAM_QUALITY_RATIO	:int = 80;
		private static const DEFAULT_FAVOR_AREA	:Boolean = true; // Default favor area when setting dimensions for camera
		private static var _activationVideo			:Video; // Used to activate camera
// 		private static const CAMERA_WRITEABLE_PROPERTIES:Vector.<String> = new <String>["quality", "bandwidth"];
		private static const CAMERA_PROPERTIES	:String = "activityLevel,bandwidth,currentFPS,fps,height,width,index,keyFrameInterval,loopback,motionLevel,motionTimeout,muted,name,quality";
// 			activityLevel : Number
// [read-only] The amount of motion the camera is detecting.
// Camera
//  	 	bandwidth : int
// [read-only] The maximum amount of bandwidth the current outgoing video feed can use, in bytes.
// Camera
//  	 	currentFPS : Number
// [read-only] The rate at which the camera is capturing data, in frames per second.
// Camera
//  	 	fps : Number
// [read-only] The maximum rate at which the camera can capture data, in frames per second.
// Camera
//  	 	height : int
// [read-only] The current capture height, in pixels.
// Camera
//  	 	index : int
// [read-only] A zero-based index that specifies the position of the camera in the Camera.names array, which lists all available cameras.
// Camera
//  	 	isSupported : Boolean
// [static] [read-only] The isSupported property is set to true if the Camera class is supported on the current platform, otherwise it is set to false.
// Camera
//  	 	keyFrameInterval : int
// [read-only] The number of video frames transmitted in full (called keyframes) instead of being interpolated by the video compression algorithm.
// Camera
//  	 	loopback : Boolean
// [read-only] Indicates whether a local view of what the camera is capturing is compressed and decompressed (true), as it would be for live transmission using Flash Media Server, or uncompressed (false).
// Camera
//  	 	motionLevel : int
// [read-only] The amount of motion required to invoke the activity event.
// Camera
//  	 	motionTimeout : int
// [read-only] The number of milliseconds between the time the camera stops detecting motion and the time the activity event is invoked.
// Camera
//  	 	muted : Boolean
// [read-only] A Boolean value indicating whether the user has denied access to the camera (true) or allowed access (false) in the Flash Player Privacy dialog box.
// Camera
//  	 	name : String
// [read-only] The name of the current camera, as returned by the camera hardware.
// Camera
//  	 	names : Array
// [static] [read-only] An array of strings containing the names of all available cameras.
// Camera
//  	 	quality : int
// [read-only] The required level of picture quality, as determined by the amount of compression being applied to each video frame.
// Camera
//  	 	width : int
// [read-only] The current capture width, in pixels.
		// System
		private var _cam						:Camera;
		private var _mic						:Microphone;
		private var _camPermissionGrantedFunction:Function;
		// SWITCHES
		// Cam
		private var _hasCam						:Boolean;
		private var _camInit						:Boolean; // If Camera has been initialized
		private var _camAccess					:Boolean; // If access to camera is granted
		// Mic
		private var _hasMic						:Boolean;
		private var _isEnhanced					:Boolean; // If the mic received is enhanced or not
		private var _micInit						:Boolean; // If MIC Has been initialized
		private var _micAccess					:Boolean; // If access to mic is granted
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PFAVLocal(id:String="PFAVLocal"):void {
			super(id, PFAVLocal);
		}
// METHODS ///////////////////////////////////////////////////////////////////////////
	// INIT
		public function initCam(onPermissionGranted:Function, camIndex:* = 0, askPermission:Boolean = true, listenActivity:Boolean = false, listenFrame:Boolean = false):Boolean { // Returns true if camera is available
			_camPermissionGrantedFunction = onPermissionGranted;
			var selectedCam:Camera;
			// Check if there are cameras attached
			if (Camera.names.length) {
				Debug.warning(_debugPrefix, "Availabe cameras: " + Camera.names);
				var i:uint;
				if (camIndex is String) {
					Debug.debug(_debugPrefix, "Selected camera ID is string: " + camIndex);
					var cam:Camera;
					if (camIndex == CameraPosition.FRONT || camIndex == CameraPosition.BACK) {
						Debug.debug(_debugPrefix, "Looking for  camera by POSITION: " + camIndex);
						for (i = 0; i < Camera.names.length; i++) {
							cam = Camera.getCamera(String(i));
							Debug.debug(_debugPrefix, "Checking position for " + Camera.names[i] + " located: " + cam.position);
							if (cam.position == camIndex) {
								Debug.debug(_debugPrefix, "Found camera for chosen position.");
								selectedCam = cam;
								break;
							}
						}
					} else {
						Debug.debug(_debugPrefix, "Looking for  camera by NAME: " + camIndex);
						//var cam:Camera = Camera.getCamera(camIndex);
						for (i = 0; i < Camera.names.length; i++) {
							cam = Camera.getCamera(String(i));
							Debug.debug(_debugPrefix, "Checking camera name " + Camera.names[i]);
							if (String(Camera.names[i]).toUpperCase().indexOf(String(camIndex).toUpperCase()) != -1) {
								Debug.debug(_debugPrefix, "Camera found!");
								selectedCam = cam;
								break;
							}
						}
					}
				} else { // Cam index is a number
					Debug.debug(_debugPrefix, "Selected camera ID is number: " + camIndex);
					selectedCam = Camera.getCamera(String(i))
				}
				_cam = selectedCam;
				if (!_cam) {
					_cam = Camera.getCamera(String("0"));
					Debug.warning(_debugPrefix, "Preferred camera not found. Selecting camera at position 0: " + Camera.names[0]);
				}
				// Absurdely, parameter for getCamera() is the index, but as String!!!
				_hasCam = _camInit = Boolean(_cam);
				Debug.debug(_debugPrefix, "Camera selection success: " + _hasCam);
				if (_hasCam) {
					_cam.addEventListener(StatusEvent.STATUS, onCamStatus);
					if (listenActivity) _cam.addEventListener(ActivityEvent.ACTIVITY, onCamActivity);
					if (listenFrame) _cam.addEventListener(Event.VIDEO_FRAME, onCamFrame);
					//if (askPermission) askCamPermission();
					if (Camera.permissionStatus != PermissionStatus.GRANTED) {
						Debug.debug(_debugPrefix, "Requesting camera permission.");
						_cam.addEventListener(PermissionEvent.PERMISSION_STATUS, onPermissionFeedback);
						_cam.requestPermission();
					} else UExec.next(onPermissionGranted);
				} else {
					Debug.error(_debugPrefix, "Camera initialization failed.");
				}
			} else {
				Debug.warning(_debugPrefix, "No cameras are available on this device.");
			}
			// Grant evetually permission
			return _hasCam;
		}
		private function onPermissionFeedback(e:PermissionEvent):void {
			if (e.status == PermissionStatus.GRANTED) {
					Debug.debug(_debugPrefix, "Permissions granted. Camera: " ,_cam.name,_cam.width, _cam.height);
				_camPermissionGrantedFunction();
				_camPermissionGrantedFunction = null;
			} else Debug.error(_debugPrefix, "Camera permission denied.");
		}
		public function initAll(onCameraPermissionGranted:Function):Boolean { // Returns true if both camera and mic can be initialized
			return initCam(onCameraPermissionGranted) && initMic();
		}
	// CAMERA
		public function getCams():Array {
			return Camera.names;
		}
		//public function askCamPermission			():void {
			//if (camInit()) {
				//// If I am on AIR, permission is ALWAYS granted. But I have to set the variables, status will not be called.
				//if (USystem.isAir() || !_cam.muted) {
					//setCamAccess				(true);
				//}
				//else {
					//_activationVideo			= new Video();
					//_activationVideo.attachCamera	(_cam);
				//}
			//}
		//}
		public function getDefaultCam				():Camera {
			camInit							();
			return							_cam;
		}
		public function hasCam					():Boolean {
			return							_hasCam;
		}
		public function getCamProperties				():String {
// 			var s								:String = "Camera properties: ";
			if (camInit()) {
				var a:Array = CAMERA_PROPERTIES.split(",");
				var p:Vector.<String> = new <String>[];
				for each (var i:String in a) {
					p.push					(i + ":" + _cam[i]);
				}
			}
			return p.join(", ");
		}
		public function get camWidth():int {
			return _cam.width;
		}
		public function get camHeight():int {
			return _cam.height;
		}
	// Camera settings - predefined
		public function setCameraToBEST(fps:uint=60):void {
			setCamMode						(1920, 1080, fps);
			setCamQuality						(0, 100);
			Debug.debug						(_debugPrefix, "Setting camera to BEST: " + getCamProperties());
		}
		public function setCameraToHD				(fps:uint=30):void { // Sets camera to HD dimensions
			setCamMode						(720, 480, fps);
			setCamQuality						(80000, 90);
			Debug.debug						(_debugPrefix, "Setting camera to HD: " + getCamProperties());
		}
		public function setCameraToWebcam			(fps:uint=30):void {
			setCamMode						(320, 240, fps);
			setCamQuality						(32000, 50);
			Debug.debug						(_debugPrefix, "Setting camera to WEBCAM: " + getCamProperties());
		}
		public function setCamDefaultQuality			():void {
			setCamMode						(CAM_MAX_W, CAM_MAX_H, CAM_MAX_FPS);
			_cam.setQuality						(CAM_BANDWIDTH_RATIO, CAM_QUALITY_RATIO);
		}
		public function setCamAndroidHDQuality		():void { // Used on LavazzaChat project for Nexus 7
			setCamProperties					({width:720, height:480, quality:80, bandwidth:120000, keyFrameInterval:60, fps:8});
// 			setCamMode						(720, 240, 8);
// 			setCamQuality						(120000, 80);
// 			_cam.keyFrameInterval				= 60;
		}
		public function setCamMacTransmitQuality		():void { // Used on LavazzaChat project for Mac
			setCamProperties					({width:640, height:480, quality:80, bandwidth:80000, keyFrameInterval:60, fps:8});
// 			setCamMode						(640, 480, 8);
// 			setCamQuality						(80000, 80);
// 			_cam.keyFrameInterval				= 60;
		}
// 		activityLevel:25, bandwidth:120000, currentFPS:8.1, fps:8, height:480, width:720, index:1, keyFrameInterval:60, loopback:false, motionLevel:50, motionTimeout:2000, muted:false, name:1, quality:80}

		public var setCamMaxQuality				:Function = setCamDefaultQuality;
	// Camera settings, controls
		public function setCamMode					(w:uint, h:uint, fps:uint, favorArea:*=null):void {
			if (camInit()) {
				_cam.setMode					(w, h, fps, favorArea != null ? favorArea : DEFAULT_FAVOR_AREA);
			}
		}
		public function setCamQuality				(bandwidthRatio:uint=16000, qualityRatio:uint=50):void {
			if (camInit()) {
				qualityRatio					= UCode.setRange(qualityRatio, 1, 100);
				_cam.setQuality					(bandwidthRatio, qualityRatio);
			}
		}
		public function setCamProperties				(o:Object):void {
			Debug.debug						(_debugPrefix, "Setting cam properties " + Debug.object(o));
// 			trace("DEBUD setto a webcam");
// 			setCameraToWebcam();
// 			return;
			// bandwidth/quality
			if (o.quality != undefined || o.bandwidth != undefined) {
				if (o.quality == undefined)			o.quality = _cam.quality;
				if (o.bandwidth == undefined)		o.bandwidth = _cam.bandwidth;
				_cam.setQuality					(o.bandwidth, o.quality);
			}
			// Size and fps
			if (o.width || o.height || o.fps || o.favorArea != undefined) {
				if (!o.width	)					o.width = _cam.width;
				if (!o.height)					o.height = _cam.height;
				if (!o.fps)						o.fps = _cam.currentFPS;
				if (o.favorArea == undefined)		o.favorArea = DEFAULT_FAVOR_AREA;
				_cam.setMode					(o.width, o.height, o.fps, false);
			}
			// Key frame interval
			if (o.keyFrameInterval) {
				_cam.setKeyFrameInterval			(o.keyFrameInterval);
			}
		}
// MIC METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function initMic					(micIndex:uint=0, askPermission:Boolean=true, enhanced:Boolean=true, listenActivity:Boolean=false, checkActivityLevel:Boolean=false):Boolean { // Initializes mic. Returns true if mic is available. Enhanced is the mic with echo cancellation.
			if (Microphone.isSupported) {
				if (Microphone.names.length) {
// <					if (Microphone.names.length > 1) {
						var micReport			:String = "\n------------------------- Available Microphones --------------------------------\n";
						for (var i:uint=0; i<Microphone.names.length; i++) {
							micReport			+= i + " > " + Microphone.names[i] + "\n";
						}
						micReport				+= "----------------------------------------------------------------------";
						Debug.debug						(_debugPrefix, micReport);
// 					}
					if (!Microphone.names[micIndex]) {
						Debug.debug			(_debugPrefix, "Mic index " + micIndex + " not available. forcing to 0.");
						micIndex = 0;
					}
					Debug.debug				(_debugPrefix, "Activating microphone",micIndex,Microphone.names[micIndex],(checkActivityLevel ? "And I will check activity level" : "Without checking activity level"));
					// Absurdely, parameter for getCamera() is the index, but as String!!!
					_isEnhanced				= enhanced;
					_mic						= enhanced ? Microphone.getEnhancedMicrophone(micIndex) : Microphone.getMicrophone(micIndex);
					if (!_mic) {
						_mic					= Microphone.getMicrophone(micIndex);
						_isEnhanced			= false;
					}
					Debug.debug				(_debugPrefix, "Microphone inizialized " +(_isEnhanced ? "WITH" : "WITHOUT") + " enhanced mode.");
					_hasMic 					= _micInit = Boolean(_mic);
					if (_mic) {
						_mic.addEventListener		(StatusEvent.STATUS, onMicStatus);
						if (listenActivity)			_mic.addEventListener(ActivityEvent.ACTIVITY, onMicActivity);
						if (askPermission)		askMicPermission();
						if (checkActivityLevel)		startMicActivityLevelCheck();
					} else {
						Debug.error			(_debugPrefix, "Error initializing microphone. It reports as supported but then it was impossible to retrieve a mic instance.");
					}
				}
			}
			else {
				Debug.error					(_debugPrefix, "Cannot initialize mic. Microphone is not supported on this device.");
			}
			return							_hasMic;
		}
		private static const MIC_RATE				:Array = [22, 11, 8, 5];
		public function setMicQuality				(i:uint):void { // 0, 1, 2, 3 - perfect, ok, low, emergency
			if (_isEnhanced) {
				Debug.debug					(_debugPrefix, "Mic quality not supported with enhanced mode.");
			}
			else {
				Debug.debug					(_debugPrefix, "Setting mic quality to " + ["Best","Ok","Low","Emergency"][i]);
				trace("MIC",_mic);
				_mic.rate						= MIC_RATE[i];
			}
		}
		
		
		public function setTooSpeech				():void { // Optimizes microphone for speech recognition (not working when on the other side there is an android with mic activity detection)
			// www.adobe.com/devnet/flashplayer/articles/acoustic-echo-cancellation.html
			if (!_mic) {
				Debug.error					(_debugPrefix, "Mic not initialized. Cannot setToSpeech()");
				return;
			}
			_mic.codec							= SoundCodec.SPEEX;
			_mic.enableVAD						= true;
			_mic.framesPerPacket					= 1;
			_mic.gain							= 50; // this is the default, means that packets are not modified
			_mic.setSilenceLevel					(0, 2000);	
			_mic.noiseSuppressionLevel				= -70;
			_mic.encodeQuality					= 2;
			// Set microphone to speech for enahanced and non enhanced mode
			if (_isEnhanced) {
				var options						:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
				options.mode 					= MicrophoneEnhancedMode.FULL_DUPLEX;
				options.autoGain 				= false;
				options.echoPath 				= 128;
				options.nonLinearProcessing 			= true;
				_mic["enhancedOptions"] 			= options;
			}
			else {
				_mic.setUseEchoSuppression			(true);
				_mic.setSilenceLevel				(0, 2000);	
			}
			Debug.debug			(_debugPrefix, (_isEnhanced ? "Enchanced MIC " : "Non-enhanced Mic ") + "set to speech. Echo supperssion:"+ _mic.useEchoSuppression + "VAD:" + _mic.enableVAD);
		}
		public function setToDesktopSpeech			():void { // Optimizes microphone for speech recognition (not working when on the other side there is an android with mic activity detection)
			Debug.debug						(_debugPrefix, "Setting to DESKTOP send microphone.");
			// www.adobe.com/devnet/flashplayer/articles/acoustic-echo-cancellation.html
			if (!_mic) {
				Debug.error					(_debugPrefix, "Mic not initialized. Cannot setToSpeech()");
				return;
			}
			_mic.codec							= SoundCodec.SPEEX;
			_mic.enableVAD						= true;
			_mic.framesPerPacket					= 1;
			_mic.gain							= 50; // this is the default, means that packets are not modified
			_mic.setSilenceLevel					(0, 2000);	
			_mic.noiseSuppressionLevel				= -70;
			_mic.encodeQuality					= 2;
			// Set microphone to speech for enahanced and non enhanced mode
			if (_isEnhanced) {
				var options						:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
				options.mode 					= MicrophoneEnhancedMode.HALF_DUPLEX;
 				// options.mode 					= MicrophoneEnhancedMode.FULL_DUPLEX;
				options.autoGain 				= false;
				options.echoPath 				= 128;
				options.nonLinearProcessing 			= true;
				_mic["enhancedOptions"] 			= options;
			}
			else {
				_mic.setUseEchoSuppression			(true);
				_mic.setSilenceLevel				(0, 2000);	
			}
			Debug.debug			(_debugPrefix, (_isEnhanced ? "Enchanced MIC " : "Non-enhanced Mic ") + "set to speech. Echo supperssion:"+ _mic.useEchoSuppression + "VAD:" + _mic.enableVAD);
			//			Test rate for LAVAZZA CHAT firewire input
// 			var rate:int = 22;
// 			Debug.debug						(_debugPrefix, "Setting MIC capture rate to: " + rate);
// 			_mic.rate							= rate;
		}
		public function setToAndroidSpeech			():void {
			Debug.debug						(_debugPrefix, "Setting to ANDROID speech microphone.");
			if (!_mic) {
				Debug.error					(_debugPrefix, "Mic not initialized. Cannot setToSpeech()");
				return;
			}
			_mic.setLoopBack					(false);
			_mic.setUseEchoSuppression				(true);
			_mic.codec							= SoundCodec.SPEEX;
			_mic.enableVAD						= true;
			_mic.framesPerPacket					= 1;
			_mic.gain							= 50; // this is the default, means that packets are not modified
			_mic.setSilenceLevel					(0, 2000);	
			_mic.noiseSuppressionLevel				= -30;
			_mic.encodeQuality					= 3;
			Debug.debug						(_debugPrefix, (_isEnhanced ? "Enchanced MIC " : "Non-enhanced Mic ") + "set to speech. Echo supperssion:"+ _mic.useEchoSuppression + "VAD:" + _mic.enableVAD);
		}
		public function setMicGain					(g:int):void {
			try {
			_mic.gain							= g;
			} catch(e) {
				Debug.error					(_debugPrefix, "Error setting mic gain: " + e);
			}
		}
// MIC AND CAM CONTROLLING ///////////////////////////////////////////////////////////////////////////////////////
		public function setMicOption					(n:String, v1:*):void {
			if (hasMic())						setMediaOption(_mic, n, v1);
		}
		public function setCamOption				(n:String, v1:*):void {
			if (hasCam())						setMediaOption(_cam, n, v1);
		}
				private function setMediaOption		(o:*, n:String, v1:*):void {
					Debug.debug				(_debugPrefix, o + "." + n + " = " + v1);
					o[n] 						= v1;
				}
		public function callMicMethod				(n:String, v1:*=null, v2:*=null, v3:*=null):void {
			if (hasMic())						calMediaMethod(_mic, n, v1, v2, v3);
		}
		public function callCamMethod				(n:String, v1:*=null, v2:*=null, v3:*=null):void {
			if (hasCam())						calMediaMethod(_cam, n, v1, v2, v3);
		}
				private function calMediaMethod		(o:*, n:String, v1:*=null, v2:*=null, v3:*=null):void {
					var t						:String = o + "." + n + "(";
					if (v3) {
						t					+= v1 + ", " + v2 + ", " + v3;
						o[n]					(v1, v2, v3);
					}
					else if (v2) {
						t					+= v1 + ", " + v2;
						o[n]					(v1, v2);
					}
					else if (v1) {
						t					+= v1;
						o[n]					(v1);
					}
					else {
						o[n]					();
					}
					Debug.debug				(_debugPrefix, t + ");");
				}
		public function getMics					():Array {
			return							Microphone.names;
		}
		public function askMicPermission			():void {
			if (micInit()) {
				// If I am on AIR, permission is ALWAYS granted. But I have to set the variables, status will not be called.
				if (USystem.isAir() || !_mic.muted) {
					setMicAccess				(true);
				}
				else {
					_mic.setLoopBack			(true);
					_mic.setLoopBack			(false);
				}
			}
		}
		public function hasMic						():Boolean {
			return							_hasMic;
		}
		public function getDefaultMic				():Microphone {
			micInit							();
			return							_mic;
		}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
	// CAM
		private function onCamStatus				(e:StatusEvent):void {
			if (_activationVideo) {
				_activationVideo.attachCamera		(null);
				_activationVideo.clear			();
				_activationVideo				= null;
			}
			if (e.code == "Camera.Unmuted") { // Permission granted
				setCamAccess					(true);
			}
			else if (e.code == "Camera.Muted") { // PErmission revoked
				setCamAccess					(false);
			}
		}
			private function setCamAccess			(a:Boolean):void {
				_camAccess					= a;
				broadcastEvent					(a ? EV_CAM_ALLOWED : EV_CAM_DENIED, this);
			}
		private function onCamActivity				(e:ActivityEvent):void {
			Debug.debug						(_debugPrefix, "Cam activity:",e);
		}
		private function onCamFrame				(e:Event):void {
			Debug.debug						(_debugPrefix, "Cam frame:",e);
		}
	// MIC
		private function onMicStatus				(e:StatusEvent):void {
			Debug.debug						(_debugPrefix, "Mic status: " + e);
		}
			private function setMicAccess			(a:Boolean):void {
				_micAccess						= a;
// 				_mic.setLoopBack				(false);
				broadcastEvent					(a ? EV_MIC_ALLOWED : EV_MIC_DENIED, this);
			}
		private function onMicActivity				(e:ActivityEvent):void {
			Debug.debug						(_debugPrefix, "Mic activity:",e);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function camInit					():Boolean {
			if (_camInit)						return true;
			Debug.error						(_debugPrefix, "Camera not yet initialized. Call initCam() before.");
			return							false;
		}
		private function micInit					():Boolean {
			if (_camInit)						return true;
			Debug.error						(_debugPrefix, "Microphone not yet initialized. Call initCam() before.");
			return							false;
		}
		private function startMicActivityLevelCheck		():void {
			UExec.second						(1, traceActivityLevel);
		}
				private function traceActivityLevel	():void {
					UExec.second				(1, traceActivityLevel);
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