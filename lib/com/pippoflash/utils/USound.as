

/* USound - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
0.1 - 12 dec 2009


	
	
*/
// Good tutorial: http://www.8bitrocket.com/newsdisplay.aspx?newspage=11839
// Good tutorial on multiple classes in one as file: http://probertson.com/articles/2006/07/28/one-file-many-as3-classes/
package com.pippoflash.utils {

	import									flash.display.*;
	import									flash.events.*;
	import									flash.utils.*;
	import									com.pippoflash.utils.UCode;
	import 									flash.net.URLRequest;
	import 									flash.media.Sound;
	import 									flash.media.SoundChannel;
	import 									flash.media.SoundTransform;
	import 									flash.media.SoundMixer;

	
	public class USound {
		public static var _verbose					:Boolean = false;
		public static const _debugPrefix				:String = "USound";
		public static var _listeners					:Array = new Array(); // this contains direct references to listeners
		public static var _sounds					:Object = new Object(); // This stores reference IDs for all Sound
		public static var _channels					:Object = new Object(); // This stores reference IDs for all SoundChannel
		public static var _transforms					:Object = new Object(); // Stores all sound transforms associated to a sound
		public static var _internalListeners				:Object = new Object(); // Stores the internal sound listeners
		public static var _soundMixerTransform			:SoundTransform = new SoundTransform(1, 0); // The global soundtransform object to use for mixer
		public static var _loadedSoundId				:String; // Marks a sound which is actually loading or playing
		public static var FADE_SOUND_FRAMES		:uint = 30;
		// SYSTEM SOUNDS LIST
		public static var _soundLists					:Object = {DEFAULT:{active:true, soundsById:[]}}; // this stores special sound lists
		private static var _soundListsIdToAttachId		:Object = {}; // Stores a direct connection to sound saved with custom ID, so that they can be played with playSound
		// UTY
		public static var _list:*;						// Reference to a listener
		public static var _i						:int;
		public static var _s						:String;
		public static var _o						:Object;
		public static var _j:*;
		public static var _b						:Boolean;
		public static var _spectrum					:Array;
		public static var _byteArray					:ByteArray = new ByteArray();
		public static var _spectrumVector				:Vector.<Number>;
		public static var _fadeVector					:Vector.<Number>;
		public static var _faderClip					:MovieClip = new MovieClip(); // Needed for fade volume
// INIT CHAIN //////////////////////////////////////////////////////////////////////////////
		public static function init					():void {
			UMem.addClass						(USoundListener);
		}
// SOUNDS LIST ////////////////////////////////////////////////////////////////////////////
		// This creates a new sound list
		public static function addSoundList			(id:String, active:Boolean=true):void {
			if (!_soundLists[id]) { // Create one if it doesn't already exist
				_soundLists[id]					= {active:active, soundsById:[]};
			}
		}
		// This adds or substitutes a sound in a list
		public static function addSoundToList			(classId:String, soundId:String=null, listId:String="DEFAULT", soundInstance:Sound=null):Boolean {
			// if soundInstance is defined, the sound	 will be added directly, and not extracted by getDefinition(). This is useful when plugins want to inject sounds in lists of a host application.
			if (!soundId)						soundId = classId; // If sound ID is not specified, it will use class ID
			var soundFound						:Boolean =  soundInstance ? doCreateSound(classId, null, false, false, soundInstance) : initializeSound(classId);
			if (soundFound) {
				addSoundList					(listId);
				_soundListsIdToAttachId[soundId]	= classId;
				_soundLists[listId].soundsById[soundId] = classId;
				return						true;
			}
			return							false;
		}
		public static function addSound				(classId:String, soundId:String, soundInstance:*=null):void { // Adds a sound to default list
			addSoundToList						(classId, soundId, null, soundInstance);
		}
		// Sets activation of a class
		public static function setListActive(active:Boolean, listId:String="DEFAULT"):void {
			_soundLists[listId].active = active;
			if (_verbose) Debug.debug(_debugPrefix, "Setting list " + listId + " to " + (active ? "ACTIVE" : "SILENT"));
		}
		static public function isListActive(listId:String):Boolean {
			return _soundLists[listId].active;
		}
		// Play a sound in a list
		public static function playListSound			(soundId:String, listId:String="DEFAULT", listener:*=null, loops:uint=1, vol:Number=1):void {
			if (_soundLists[listId].active) {
				if (_verbose)					Debug.debug(_debugPrefix, "Playing sound " + soundId + " in list " + listId);
				if (_soundLists[listId].soundsById[soundId]) {
					playSound(_soundLists[listId].soundsById[soundId], loops, listener, vol);
				}
				else							Debug.error(_debugPrefix, "Should play Sound " + soundId + " in list " + listId + " but it doesn't exist!");
			}
			else {
				if (_verbose)					Debug.debug(_debugPrefix, "Can't play sound " + soundId + " in list " + listId + " because list is set to inactive.");
			}
		}
		public static function playDelayedSound			(delay:Number, soundId:String, useFrames:Boolean=false):void {
			if (useFrames)						UExec.frame(Math.ceil(delay), playSound, soundId);
			else								UExec.time(delay, playSound, soundId);
		}
// GENERAL //////////////////////////////////////////////////////////////////////////////
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function reset				():void {
		}
		public static function setActive				(a:Boolean):void {
		}
	// Sound system management
		public static function disposeLoadedSound	():void {
			if (_loadedSoundId) {
				disposeSound(_loadedSoundId);
				_loadedSoundId = null;
			}
		}
		public static function disposeSound		(id:String):* {
			if (!_sounds[id])					return Debug.error(_debugPrefix, "disposeSound() fail, sound ID not found: " + id);
			Debug.debug					(_debugPrefix, "Disposing sound: " + _loadedSoundId);
			var sound						:Sound = _sounds[id];
			var list						:USoundListener = _internalListeners[id];
			// Close stream first
			if (list.isExternal() && !list.isLoaded()) {
				// Apparently sound is still loading
				try { // Sound might already be stopped
					sound.close();
				} catch (e:Error) {
					// Sound is just not open
					Debug.debug(_debugPrefix, "disposeSound() stream.close() error: " + e);
				}
			}
			// First stop sound
			if (_channels[id]) {
				Debug.debug				(_debugPrefix, "Channel found, stopping it: " + _channels[id]);
				_channels[id].stop			();
				_channels[id].removeEventListener(Event.SOUND_COMPLETE, _internalListeners[id].onSoundPlayComplete);
				delete					_channels[id];
			}
			sound.removeEventListener			(IOErrorEvent.IO_ERROR, list.onLoadError);
			sound.removeEventListener			(Event.COMPLETE, list.onLoadComplete);
			sound.removeEventListener			(Event.ID3, list.onID3);
			sound.removeEventListener			(Event.OPEN, list.onLoadStart);
			sound.removeEventListener			(ProgressEvent.PROGRESS, list.onLoadProgress);
			delete						_sounds[id];
			delete						_transforms[id];
			delete						_internalListeners[id];
			delete						_soundListsIdToAttachId[id];
			// Dispose listener
			list.dispose						();
		}
	// LISTENERS
		public static function addListener			(list:*):void {
			// Adds a general listener
			if (_listeners.indexOf(list) == -1)		_listeners.push(list);
		}
		public static function removeListener			(list:*):void {
			// Removes a general listener
			UCode.removeArrayItem				(_listeners, list);
		}
		public static function addSoundListener		(id:String, list:*):void {
			// Adds a listener for a single sound
			if (!_internalListeners[id]) {
				Debug.error					(_debugPrefix, "ERROR!!!!!!! Sound " + id + " is not defined, cannot add listener.");
			}
			else {
				Debug.debug					(_debugPrefix, "Adding listener to " + id + " = " + list);
				_internalListeners[id].addListener		(list);
			}
		}
		public static function removeSoundListener		(id:String, list:*):void {
			// Adds a listener for a single sound
			if (!_internalListeners[id]) {
				Debug.error					(_debugPrefix, "ERROR!!!!!!! Sound " + id + " is not defined, cannot remove listener.");
			}
			else {
				Debug.debug					(_debugPrefix, "Removing listener from " + id + " = " + list);
				_internalListeners[id].removeListener	(list);
			}
		}
	// CONTROL SOUNDS
		public static function playSound(id:String, loops:uint=1, listener:*=null, vol:Number=1):void { // This accepts the class id, or a custom ID used for sound lists
			if (_soundListsIdToAttachId[id]) id = _soundListsIdToAttachId[id]; // If it was a list sound with custom ID, I set the ID as for the real attach id
			Debug.debug(_debugPrefix, "Play:",id,"loops",loops,"listener",listener);
			initializeSound(id, listener);
			startPlaying(id, 0, loops, listener, vol);
		}
		public static function stopSound				(id:String):void {
			if (_soundListsIdToAttachId[id]) id = _soundListsIdToAttachId[id]; // If it was a list sound with custom ID, I set the ID as for the real attach id
			if (_channels[id]) _channels[id].stop();
		}
		public static function stopAllSounds():void {
			disposeLoadedSound();
			for each (_j in _channels) _j.stop();
		}
		public static function stopListSounds(listId:String="DEFAULT"):void {
			if (!_soundLists[listId]) {
				Debug.error(_debugPrefix, "stopListSounds() fail, list doesn't exist: " + listId);
				return;
			}
			var list:Object = _soundLists[listId].soundsById;
			for (var s:String in list) {
				stopSound(s);
			}
		}
	// SINGLE SOIUND VOLUME
		public static function fadeOutSound			(id:String):void {
			// TO BE IMPLEMENTED - By now it switches the sound off
			if (_sounds[id]) {
				try {
					_sounds[id].close			();	
				} catch (e) {
					Debug.debug				(_debugPrefix, "Sound cannot be closed:",id);
				}
			}
			stopSound							(id);
		}
		/**
		 * Sets volume for a single sound.
		 * @param	id Id  of the sound
		 * @param	volume from 0 to 1
		 */
		static public function setSoundVolume(id:String, volume:Number):* {
			if (!_channels[id]) return Debug.error(_debugPrefix, "Cannot setSoundVolume, sound not found: " + id);
			setSoundVolumePan(id, volume, (_channels[id].soundTransform as SoundTransform).pan);
		}
		static public function setSoundPan(id:String, pan:Number):* {
			if (!_channels[id]) return Debug.error(_debugPrefix, "Cannot setSoundPan, sound not found: " + id);
			setSoundVolumePan(id, pan, (_channels[id].soundTransform as SoundTransform).volume);
		}
		static public function setSoundVolumePan(id:String, volume:Number, pan:Number):* {
			if (!_channels[id]) return Debug.error(_debugPrefix, "Cannot setSoundVolumePan, sound not found: " + id);
			Debug.debug(_debugPrefix, "Set sound " + id + " volume to " + volume + " pan to " + pan);
			const st:SoundTransform = new SoundTransform(volume, pan);
			st.volume = volume;
			_channels[id].soundTransform = st;
		}
	// GENERAL VOLUME
		public static function setGeneralVolume		(v:Number):void {
// 			Debug.debug						(_debugPrefix, "Set general volume (range is 0 to 1) to:",v);
			_soundMixerTransform.volume			= v;
			SoundMixer.soundTransform			= _soundMixerTransform;
		}
		public static function fadeGeneralVolumeTo	(v:Number):void {
			if (getGeneralVolume()==v)			return;
			doFadeVolumeTo					(v);
		}
		public static function getGeneralVolume		():Number {
			return							_soundMixerTransform.volume;			
		}
	// LOAD SOUND
		public static function loadSound(id:String, autoPlay:Boolean=true, listener:*=null):void {
			if (_verbose) Debug.debug(_debugPrefix, "Loading sound: " + id + " autoPlay: " + autoPlay);
			// if (stopPrevious) { // There is a loaded sound already playing, therefore I stop it before loading another one
			// 	Debug.debug(_debugPrefix, "There was a loaded sound already playing to be disposed: " + _loadedSoundId)
			// 	disposeLoadedSound();
			// }
			if (!_sounds[id]) {
				createLoadedSound(id, listener, autoPlay);
			} else {
				if (_verbose) Debug.debug(_debugPrefix, "Sound already created. Using existing laoder.");
				UExec.next(playSound, id);
			}
// 			if (autoPlay) {
// 				startPlaying					(id, listener);
// 			_loadedSoundId						= id;
// 			}
			_loadedSoundId						= id;
		}
	// SPECTRUM ANALYZER
		public static function getSpectrumByteArray		():ByteArray { // Returns the spectrum of the sound actually playing
// 			_spectrum							= 
			SoundMixer.computeSpectrum			(_byteArray, true, 1);
			return							_byteArray;
		}
		public static function getSpectrumVector		(interval:uint=8):Vector.<Number> {
			_spectrumVector						= new Vector.<Number>;
			getSpectrumByteArray					();
			for (_i = 0; _i<256; _i+=interval)			_spectrumVector.push(_byteArray.readFloat());
			return							_spectrumVector;
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////	
		private static function initializeSound(id:String, listener:*=null):Boolean {
			if (!_sounds[id]) return createSound(id, listener);
			else return true;
		}
		private static function createSound			(id:String, listener:*=null):Boolean {
			return							doCreateSound(id, listener, false);
		}
		private static function createLoadedSound(id:String, listener:*=null, autoPlay:Boolean=false):Boolean {
			return doCreateSound(id, listener, true, autoPlay);
		}
				private static function doCreateSound(id:String, listener:*=null, isExternal:Boolean=false, autoPlay:Boolean=false, soundInstance:Sound=null):Boolean {
					// Sound instance can be used o inject directly a sound instance without having UCode to look in library exports. This is useful when a plugin wants to add sounds to the host application domain USoiund.
					Debug.debug(_debugPrefix, "Creating sound : " + id);
					var sound:Sound;
					try {
						if (soundInstance) sound = soundInstance;
						else sound = isExternal ? new Sound(new URLRequest(id)) : UCode.getInstance(id);
					} catch (e) {
						Debug.error(_debugPrefix, "ERROR CREATING SOUND",id);
						return false;
					}
					if (!sound) {
						Debug.error(_debugPrefix, "Sound not found:",id);
						return false;
					}
					var transform:SoundTransform = new SoundTransform();
					var list:USoundListener = UMem.getInstance(USoundListener, id, isExternal, autoPlay);
					sound.addEventListener(IOErrorEvent.IO_ERROR, list.onLoadError);
					sound.addEventListener(Event.COMPLETE, list.onLoadComplete);
					sound.addEventListener(Event.ID3, list.onID3);
					sound.addEventListener(Event.OPEN, list.onLoadStart);
					sound.addEventListener(ProgressEvent.PROGRESS, list.onLoadProgress);
					if (listener)list.addListener(listener);
					_sounds[id] = sound;
					_transforms[id] = transform;
					_internalListeners[id] = list;
					return true;
				}
		private static function startPlaying			(id:String, startAt:uint=0, loops:uint=1, listener:*=null, vol:Number=1):void {
			try {
				_channels[id]					= _sounds[id].play(startAt, loops, _transforms[id]);
				_channels[id].addEventListener		(Event.SOUND_COMPLETE, _internalListeners[id].onSoundPlayComplete);
				if (listener)					_internalListeners[id].addListener(listener);
				// Set volume
				var st						:SoundTransform = new SoundTransform();
				st.volume						= vol;
				_channels[id].soundTransform		= st;				
				_internalListeners[id].onSoundPlayStart();
			}
			catch (e:Error) {
				Debug.error					(_debugPrefix, "Something wrong playing sound:",id,"_sounds[]:",_sounds[id],"_channels[]:",_channels[id]);
			}
		}
		private static function getSoundListener			(id:String):USoundListener {
			if (!_internalListeners[id])				initializeSound(id);
			return							_internalListeners[id];
		}
		private static function doFadeVolumeTo			(v:Number):void {
			_fadeVector 						= new Vector.<Number>();
			_j								= (v - getGeneralVolume()) / FADE_SOUND_FRAMES;
			for (_i=1; _i<=FADE_SOUND_FRAMES; _i++) {
				_fadeVector.push					(getGeneralVolume()+(_j*_i));
			}
			_faderClip.addEventListener				(Event.ENTER_FRAME, doStepVolumeFade);
		}
			private static function doStepVolumeFade	(e:Event):void {
				if (_fadeVector.length) 			setGeneralVolume(_fadeVector.splice(0,1)[0]);
			}
	}

}
// HELPER CLASSES ///////////////////////////////////////////////////////////////////////////////////////	
	import									flash.events.*;
	import									com.pippoflash.utils.*;
	import									com.pippoflash.framework._PippoFlashBaseNoDisplayUMem;
	// USoundListener ///////////////////////////////////////////////////////////////////////////////////////
	class USoundListener extends _PippoFlashBaseNoDisplayUMem {
		public var _id							:String;
		public var _loaded						:Boolean; // this is needed for loaded files
		public var _autoPlay						:Boolean;
		public var _isExternal						:Boolean;
		public var _listeners						:Array;
		public function USoundListener				(id:String, isExternal:Boolean=false, autoPlay:Boolean=false):void {
			super							("USoundListener");
			recycle							(id, isExternal, autoPlay);
		}
		// METHODS - Framework
		public function recycle					(id:String, isExternal:Boolean=false, autoPlay:Boolean=false):void {
			_loaded							= false;
			_listeners							= [];
			_autoPlay							= autoPlay;
			_id								= id;
			_isExternal							= isExternal;
		}
		public function dispose					():void { // Dispose this item and puts it in UMem
			_listeners							= null;
			UMem.storeInstance					(this);
		}
		// METHODS - getters
		public function isLoaded					():Boolean { // If sound is completely loaded
			return							_loaded;
		}
		public function isExternal					():Boolean { // If sound is completely loaded
			return							_isExternal;
		}
		// METHODS - LISTENERS
		public function addListener					(list:*):void {
			// Adds a general listener
			if (_listeners.indexOf(list) == -1)			_listeners.push(list);
		}
		public function removeListener				(list:*):void {
			// Removes a general listener
			UCode.removeArrayItem				(_listeners, list);
		}
		// LISTENERS
		// From Sound
		public  function onLoadError					(e:Event):void {
			if (USound._verbose)					Debug.debug(_id, e);
			UCode.callGroupMethod				(_listeners, "onSoundLoadError", _id);
		}
		public  function onLoadComplete				(e:Event):void {
			if (USound._verbose)					Debug.debug(_id, e);
			_loaded							= true;
			if (_autoPlay)						USound.playSound(_id);
			UCode.callGroupMethod				(_listeners, "onSoundLoadComplete", _id);
		}
		public  function onID3						(e:Event):void {
			if (USound._verbose)					Debug.debug(_id, e);
			UCode.callGroupMethod				(_listeners, "onSoundID3", _id);
		}
		public  function onLoadStart					(e:Event):void {
			if (USound._verbose)					Debug.debug(_id, e);
			UCode.callGroupMethod				(_listeners, "onSoundLoadStart", _id);
		}
		public  function onLoadProgress				(e:Event):void {
			//if (USound._verbose)					Debug.debug(_id, e);
			UCode.callGroupMethod				(_listeners, "onSoundLoadProgress", _id);
		}
		// From SoundChannel
		public  function onSoundPlayComplete			(e:Event):void {
			if (USound._verbose)					Debug.debug(_id, e);
			UCode.callGroupMethod				(_listeners, "onSoundPlayComplete", _id);
		}
		// Manully Activated
		public function onSoundPlayStart():void {
			if (USound._verbose)					Debug.debug(_id, "onSoundPlayStart");
			UCode.callGroupMethod				(_listeners, "Event: onSoundPlayStart (manually triggered)", _id);
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