/* USystem - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
Gathers simplified informations about user system

isOnline():Boolean;
isDevice():Boolean;


*/

package com.pippoflash.utils {

	import									com.pippoflash.utils.Debug;
	import									com.pippoflash.utils.UGlobal;
	import									com.pippoflash.utils.UText;
	import									flash.system.*;
	import									flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
// 	import									flash.net.NetworkInterface;
// 	import									flash.net.NetworkInfo;
	
	public class USystem extends _UBase {
		// DEBUG SWITCHES - they only work if main application is isDebug()
		private static const FORCE_DPI:uint = 0; // = 326; // If > 0, DPI will be forced
		private static const FORCE_RESOLUTION:Point = null; // = new Point(1280, 720);// = new Point(2048, 1536); // If specified, this resolution will be used, otherwise if null, real resolution
		public static var FORCE_DEVICE:Boolean = false; // Forces detection of a device if this is an AIR app or a desktop app
		private static const FORCE_DEVICE_TYPE:String = "IPHONE"; // The type of device forced to
		private static const FORCE_DEVICE_SYSTEM_TYPE:String = "IOS"; // The type of device forced to
		private static const DEVICE_UDID_SO_VAR_NAME:String = "PippoFlash_App_UDID"; // The name of variable in main shared object where UDID of device is stored. UDID is unique to EACH APPLICATION, it cannot be shared among different applications.
		// CINSTANTS
		public static const instance:Class = USystem; // Fool singleton lookers
		private static const _verbose:Boolean = false;
		private static const _debugPrefix:String = "USystem";
		private static const _capabilitiesFullList:Array = ["manufacturer","os","version","isDebugger","playerType","screenDPI","screenResolutionX","screenResolutionY","hasPrinting","language","touchscreenType","localFileReadDisable","maxLevelIDC","pixelAspectRatio","screenColor","hasVideoEncoder","hasTLS","hasStreamingVideo","hasStreamingAudio","hasScreenPlayback","hasScreenBroadcast","hasMP3","hasIME","hasEmbeddedVideo","hasAudioEncoder","hasAudio","hasAccessibility","avHardwareDisable","cpuArchitecture","isEmbeddedInAcrobat","languages","prototype","serverString","supports32BitProcesses","supports64BitProcesses"];
		private static const _capabilitiesBasicList:Array = ["manufacturer","os","version","isDebugger","playerType","language","touchscreenType"];
		// MODIFIABLE OCNSTANTS - can be modified by direct assignement
		private static const ALLOWED_LANGUAGES:String = "en,it,es,fr,de,zh,ja,ko"; // The only languages allowed
		private static const DEFAULT_LANGUAGE:String = "en"; // The fallback language if discovered language is not in the list of allowed languages
		// UTY
		private static var _s:String;
		// DATA HOLDERS
		private static var _fullReport:String = "";
		private static var _language:String; // Stores the 2 digits code for language. It is the 2 strings maximum, and ONLY taken from available languages.
		private static var _UDID:String; // Stores the device UDID. If it is not 
		// MARKERS
		private static var _isAir:Boolean;
		private static var _isDevice:Boolean;
		private static var _dpi:uint;
		private static var _resolution:Point;
		private static var _deviceType:String = "DESKTOP"; // UNKNOWN, DESKTOP, ANDROID, IPHONE, (IPAD not yet defined) - this is the fine device ID
		private static var _systemType:String = "DESKTOP"; // UNKNOWN, DESKTOP, IOS, ANDROID - this is the general device id
		private static var _deviceTypeDetail:String = ""; // This is a fine device name - to be implemented
		private static var _init:Boolean; // Marks if it is already initialized
		// DEVICE CHARACTERISTIC
		static private var _osVersion:Number = 0; // Number of the os version - Implemented only on IOS - Only the first 2 . (i.e. 9.3.5 becomes 9.3)
		
		// MEMORY REPORT
		static private var _memoryConsole:TextField;
		static private var _maxKb:int = 0; // max memory occupied in KB 
		static private var _maxKbString:String; // formatted for display
		static private var _minKbString:String; // formatted for display, marked with storeMinMemory
		static private var _memStringBase:String = ""; // Memory string default without current memory
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init():void { // This is necessary to setup all variables (called by UGlobal on init, there is NO NEED to manually call this)
			if (_init) {
				Debug.error(_debugPrefix, "USystem.init() called more than once. Aborting call.");
				return;
			}
			updateSystemReport();
			Debug.debug(_debugPrefix, "System initialized. DPI:" + _dpi, "RES:" + _resolution, (_isDevice ? "- DEVICE" : "- DESKTOP"), "LANGUAGE:", _language);
			// Setup memory console
			_memoryConsole = new TextField();
			_memoryConsole.border = true;
			_memoryConsole.background = true;
			_memoryConsole.backgroundColor = 0xffffff;
			setMemoryConsoleTextFormat(new TextFormat(null, 36, 0, false, false, false, null, null, TextFormatAlign.LEFT));
			_memoryConsole.autoSize = "left";
			storeMinMemory();
			// Set to initialized
			_init = true;
		}
		static public function updateSystemReport():void {
			var s:String = Capabilities.manufacturer.toUpperCase() + "_" + Capabilities.os.toUpperCase();
			// If is deploy all debug switches are killed
			var isTest:Boolean = !UGlobal.isDeploy(); 
			_isAir = Capabilities.playerType == "Desktop";
			_isDevice = isTest && (FORCE_DEVICE && _isAir) ? true : s.indexOf("ANDROID") != -1 || s.indexOf("IOS") != -1;
			_dpi = isTest && FORCE_DPI ? FORCE_DPI : uint(USystem.getCapability("screenDPI"));
			_resolution = isTest && FORCE_RESOLUTION ? FORCE_RESOLUTION : new Point(Capabilities.screenResolutionX,Capabilities.screenResolutionY);
			// Setup device type other than PLAYER (which is default)
			if (_isAir) {
				_deviceType = "DESKTOP";
				if (_isDevice) {
					if (s.indexOf("ANDROID") != -1){
						_deviceType = "ANDROID";
						_systemType = "ANDROID";
					}
					else if (s.indexOf("IOS") != -1) {
						_deviceType = "IPHONE";
						_systemType = "IOS";
					}
					else {
						_deviceType = _systemType = "UNKNOWN";
						if (FORCE_DEVICE) {
							_deviceType = FORCE_DEVICE_TYPE;
							_systemType = FORCE_DEVICE_SYSTEM_TYPE;
						}
					}
				}
				if (isIOS()) { // String is: "iPhone OS 9.3.5 iPad3,1"
					var a:Array = Capabilities.os.split(" ");
					if (a.length > 1) {
						var digits:Array = a[2].split(".");
						_osVersion = digits.length > 1 ? Number(digits[0] + "." + digits[1]) : Number(digits[0]);
					}
					Debug.warning(_debugPrefix, "OS VERSION ["+Capabilities.os+"] = " + _osVersion);
				}
			}
			// Setup language
			_language = _isAir ? Capabilities["languages"][0].substr(0,2) : Capabilities["language"]; // I strip off regional version of language in case (langages array exists only in Air, in SWF only language string)
			limitLanguage(ALLOWED_LANGUAGES, DEFAULT_LANGUAGE); // Limits languages using default internal settings
			// Prepare full report
			_fullReport +=[_deviceType,_deviceTypeDetail,"DPI:"+_dpi,"RESOLUTION:"+_resolution].join(",") + "\n";
			for each (_s in _capabilitiesFullList) _fullReport += _s + "  >  " + Capabilities[_s] + "\n";
			_fullReport += "isDevice()  >  " + isDevice() + "\n";
			_fullReport += "isAir()  >  " + isAir() + "\n";
			_fullReport += "isExternal()  >  " + isExternal() + "\n";
			_fullReport += "isAndroid()  >  " + isAndroid() + "\n";
			_fullReport += "isIOS()  >  " + isIOS() + "\n";
			// Report
			// Set to initialized
			_init = true;		
		}

// SETUP ///////////////////////////////////////////////////////////////////////////////////////
		public static function limitLanguage(allowedList:String="en,es,it", defaultLanguage:String="en"):void { // Limits language to one in list, otherwise falls to default
			if (allowedList.indexOf(_language) == -1)	_language = defaultLanguage;
		}
		static public function forceDevice():void { // Tells USystem to return always psitive to device
			_isDevice = true;
		}
// REPORTS ///////////////////////////////////////////////////////////////////////////////////////
		public static function report(full:Boolean = false):void {
			updateSystemReport();
			if (full) printFullReport();
			else printReport();
		}
		public static function printReport():void {
			for each (_s in _capabilitiesBasicList) Debug.debug(_debugPrefix, _s,"|",Capabilities[_s]);
		}
		public static function printFullReport():void {
			Debug.debug(_debugPrefix, _fullReport);
			if (UGlobal.isSetup()) {
				Debug.debug(_debugPrefix, "Content scale factor: " + UGlobal.stage.contentsScaleFactor);
			}
		}
		public static function get fullReport():String {
			return _fullReport;
		}
		
		static public function get osVersion():Number 
		{
			return _osVersion;
		}
		static public function getJsonReport(properties:Array = null):String { // Returns a JSON string with inputed capabilities. If no capabilites list is sent, full list is used.
			//private static const _capabilitiesFullList:Array = ["manufacturer","os","version","isDebugger","playerType","screenDPI","screenResolutionX","screenResolutionY","hasPrinting","language","touchscreenType","localFileReadDisable","maxLevelIDC","pixelAspectRatio","screenColor","hasVideoEncoder","hasTLS","hasStreamingVideo","hasStreamingAudio","hasScreenPlayback","hasScreenBroadcast","hasMP3","hasIME","hasEmbeddedVideo","hasAudioEncoder","hasAudio","hasAccessibility","avHardwareDisable","cpuArchitecture","isEmbeddedInAcrobat","languages","prototype","serverString","supports32BitProcesses","supports64BitProcesses"];
			var o:Object = {};
			if (!properties) properties = _capabilitiesFullList;
			for each (var prop:String in properties) o[prop] = Capabilities[prop];
			return JSON.stringify(o);
		}
// CHECKS ///////////////////////////////////////////////////////////////////////////////////////
		public static function isLocal(c:*=null):Boolean { // If the file is running on the local file system (localhost is not considered, it returns online)
			return UGlobal.isLocal(); 
		}
		public static function isOnline():Boolean {
			return UGlobal.isOnline(); 
		}
		public static function isTest():Boolean { // This is when I am testing with Flash Pro IDE or Flash Builder, and LOCALLY
			return isLocal() && isDebugPlayer() && isExternal();
		}
		public static function isDebugPlayer():Boolean { // If I am working in the debug player
			return Capabilities.isDebugger;
		}
		public static function isExternal():Boolean { // If its the external player.
			return Capabilities.playerType == "External";
		}
		public static function getCapability(s:String):* { // Direct link to Capabilities
			return Capabilities[s];
		}
		public static function getPlayerType():String {
			return Capabilities.playerType;
		}
		public static function getDeviceType():String {
			return _deviceType;
		}
		public static function getSystemType():String {
			return _systemType;
		}
	// ENVIRONMENT PLAYER
		public static function isAir():Boolean {
			// This has to be computed in real time, since it can be called before USystem is initialized.
			return _isAir;
		}
		public static function isSwf():Boolean {
			return !isAir();
		}
	// OS
		public static function isMac():Boolean {
			//Debug.warning(_debugPrefix, "TEASTING FOR MAC: ", Capabilities["os"],UText.contains(Capabilities["os"], "Mac"));
			return Boolean(UText.contains(Capabilities["os"], "Mac"));
		}
		public static function isWin():Boolean {
			return Boolean(UText.contains(Capabilities["os"], "Win"));
		}
	// DEVICES
		public static function isDevice():Boolean { // This can be forced to mimic device working also when debugging on desktop
			return _isDevice;
		}
		public static function isDesktop():Boolean { // This can be forced to mimic device working also when debugging on desktop
			return !_isDevice;
		}
		static public function isRunningOnDesktop():Boolean { // This cannot be forced, returns correctly if is running on a windows or mac machine
			return isMac() || isWin();
		}
		public static function isIOS():Boolean {
			return _systemType == "IOS";
		}
		public static function isAndroid				():Boolean {
			return							_deviceType == "ANDROID";
		}
		public static function isPhone				():Boolean {
			return							false;
		}
		public static function isTablet				():Boolean {
			return							false;
		}
		public static function isLandscape				():Boolean {
			return							false;
		}
		public static function isPortrait				():Boolean {
			return							false;
		}
		public static function isRetina				():Boolean {
			return							false;
		}
		public static function getUDID				():String {
			// This device info is UNIQUE only for a single app. This kay CANNOT be shared amongst apps since it is stored in a shared object which is dependant on the app.
			// Also, if SharedObject is set to be saved with version number, device UDID will change with each new version number of the app
			// Possible parameters to build device id: ["manufacturer","os","version","isDebugger","playerType","screenDPI","screenResolutionX","screenResolutionY","hasPrinting","language","touchscreenType","localFileReadDisable","maxLevelIDC","pixelAspectRatio","screenColor","hasVideoEncoder","hasTLS","hasStreamingVideo","hasStreamingAudio","hasScreenPlayback","hasScreenBroadcast","hasMP3","hasIME","hasEmbeddedVideo","hasAudioEncoder","hasAudio","hasAccessibility","avHardwareDisable","cpuArchitecture","isEmbeddedInAcrobat","languages","prototype","serverString","supports32BitProcesses","supports64BitProcesses"];
			// If device ID is already set
			if (_UDID)							return _UDID;
			// I try to grab it from shared object
			else {
				var id						:String = UGlobal.mainApp.getSharedObject(DEVICE_UDID_SO_VAR_NAME);
				if (id) {
					_UDID					= id;
					return					id;
				}
			}
			// UDID was not found. Generating one now and storing it in the shared object.
			var deviceInfoParams					:Vector.<String> = new <String>["manufacturer","os","cpuArchitecture","screenResolutionX","screenResolutionY","screenDPI"];
			var deviceInfo						:Vector.<String> = new Vector.<String>(deviceInfoParams.length+1);
			for (var i:uint=0; i<deviceInfoParams.length; i++) deviceInfo[i] = Capabilities[deviceInfoParams[i]];
			deviceInfo[deviceInfoParams.length]		= "RND_" + Math.random() * Math.random();
			var udid							:String = escape(UGlobal.mainApp.getAppId() + "-" + deviceInfo.join("-"));
			UGlobal.mainApp.setSharedObject		(DEVICE_UDID_SO_VAR_NAME, udid);
			return							udid;
		}
	// localization
		public static function setLanguage(l:String):void { // Force system language
			_language = l;
		}
		public static function getLanguage():String {
			return _language ? _language : Capabilities["languages"][0].substr(0,2); // This one works on AIR only
		}
	// DPI
		public static function getDPI				():uint {
			return							_dpi;
		}
	// RESOLUTIION
		public static function getResolution			():Point {
			return							_resolution;
		}
	// HUMAN INTERFACE
		public static function isTouch				():Boolean {
			return							false;
		}
	// GENERAL
		public static function hasInternet				():Boolean {
			return							false;
		}
		
	// PLAYER VERSION
		public static function getPlayerFullVersion		():String {
			return							Capabilities.version;
		}
		public static function getPlayerMainVersion		():uint {
			return							uint(Capabilities.version.split(",")[0].split(" ")[1]);
		}
		public static function getPlayerVersion			():Number {
			var a								:Array = Capabilities.version.split(",");
			var b								:Array = a[0].split(" ");
			return							Number(b[1]+"."+a[1]);
		}
	// MEMORY
		static public function printMemory():void {
			Debug.debug(_debugPrefix, "Memory usage: freeMemory " + 
			UText.formatNumber(Math.floor(System.freeMemory / 1000)) + "Kb, privateMemory " + 
			UText.formatNumber(Math.floor(System.privateMemory / 1000)) + "Kb, totalMemory " + 
			UText.formatNumber(Math.floor(System.totalMemory / 1000)));
		}
		static public function storeMinMemory():void {
			_minKbString = UText.formatNumber(Math.floor(System.privateMemory/1000));
		}
		static public function showMemory():void {
			if (_verbose) Debug.debug(_debugPrefix, "Showing memory values.");
			var m:int = Math.floor(System.privateMemory / 1000);
			if (m > _maxKb) {
				_maxKb = m;
				_maxKbString = UText.formatNumber(_maxKb);
				_memStringBase = "Max " + _maxKbString + "\nMin " + _minKbString + "\n";
			}
			_memoryConsole.text = _memStringBase + "Memory: " + UText.formatNumber(m);
			UGlobal.stage.addChild(_memoryConsole);
		}
		static public function garbageCollect():void {
			if (_verbose) Debug.debug(_debugPrefix, "Triggared garbage collection.");
			System.gc();
		}
		static public function setMemoryConsoleTextFormat(tf:TextFormat):void {
			_memoryConsole.defaultTextFormat = tf;
			_memoryConsole.setTextFormat(tf);
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