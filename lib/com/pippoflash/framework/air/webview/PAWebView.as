package com.pippoflash.framework.air.webview 
{
	import com.distriqt.extension.nativewebview.events.NativeWebViewEvent;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework._PippoFlashBase;
	import com.pippoflash.framework._PippoFlashBaseNoDisplay;
	import com.pippoflash.framework.air.ane.distriqt.DistriqtWebView;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.UMethod;
	import com.pippoflash.utils.USystem;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.events.LocationChangeEvent;
	import com.pippoflash.framework.air.UFile;
	import flash.filesystem.File;
	import com.pippoflash.utils.*;
	import flash.net.*;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * EVOLUTED: Now only works with Distriqt WebView and not with regular WebView
	 * This needs AirUtil.js in page JavaScript.
	 */
	public class PAWebView extends _PippoFlashBaseNoDisplay 
	{
		public static const EVT_READY:String = "onWebViewReady";
		public static const EVT_REPORTED_READY:String = "onWebViewJSReportedIsReady";
		public static var USE_NATIVE_WEBVIEW:Boolean = true;
		private static const SEND_SYSTEM_ALERTS:Boolean = true;
		static private var _systemAlertSent:Boolean; // Sends system alert the first time
		static private var DEFAULT_HTML_FOLDER:String = "_assets/html/";
		static private var OPEN_HTTP_LINKS_EXTERNALLY:Boolean = true; // Default. Set this with openHttpLinksExternally
		static private var HTML_LOG_METHOD_NAME:String = "addToHTMLLog"; // Method to be called by Debug in HTML AirApplication in order to trace flash events in html output
		//static public var VERBOSE:Boolean = false;
		
		
		//static private var _nativeWebViewDistriqtClass:DistriqtWebView; // Use an external native webview class to initialize (no OOP so it can work on desktop)
		static private var _addAdditionalTunnelMethod:Boolean = true;
		static private var _useDistriqtAne:Boolean;
		static private var _initialized:Boolean;
		static private var _initCallback:Function;
		
		
		
		private var _webView:StageWebView;
		private var _distriqtWebView:DistriqtWebView; // This is the nativewebview created with class. 
		private var _htmlFolder:String; // Tha base HTML folder, might also be a url
		private var _isOnline:Boolean; // If the base url contains http at the beginning
		private var _ready:Boolean = false; // In order to be ready, size must be initialized
		private var _active:Boolean = false; // If WebView is active and visible
		private var _loaded:Boolean; // If webview has been completely loaded
		private var _reportedReady:Boolean; // If WebView has sent a JS message repoting itself as ready
		private var _rect:Rectangle;
		private var _nativeUrl:String;
		private var _defaultWindowValues:Object; // Values to be sent to AirUtils as default value
		
		
		
		private static var _destinationStorage:String = "application"; // this changes to storage on android, if copy to storage == true
		private static const _defaultHtmlfolderCopiedSOName:String = "PippoApps_PAWebView_HTMLFolderCopied";
		static private var _copyHtmlFolderCallback:Function; // success:Boolean
		private var _openHttpLinksExternally:Boolean;
		//private var _url:String;
		
		private var _x:Number;
		private var _y:Number;
		private var _w:Number;
		private var _h:Number;
		
		// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function setupDefaultHtmlFolder(folder:String, copyToCache:Boolean = false, copyToCacheCallback:Function=null):void {
			Debug.warning("PAWebView", "Setting dfault HTML folder: " + folder);
			DEFAULT_HTML_FOLDER = folder;
			
			if (copyToCache) {
				_destinationStorage = "cache";
				_copyHtmlFolderCallback = copyToCacheCallback;
				//trace(_MainAppBase.instance.getSharedObject(_defaultHtmlfolderCopiedSOName));
				const skipSaving:Boolean = _MainAppBase.instance.getSharedObject(_defaultHtmlfolderCopiedSOName);
				if (skipSaving) {
					copySuccessCallback("Folder has already been copied.");
					return;
				}
				Debug.debug("PAWebView", "Copy to cache...");
				UFile.referenceFile(folder, "application");
				UFile.copyToCache(folder, true, null, true, copySuccessCallback, copyErrorCallback);
				//UFile.copyToStorage
			}
		}
		static private function copySuccessCallback(e:*=null):void {
			Debug.debug("PAWebView", "Copy to cache successful: " + e);
			_MainAppBase.instance.setSharedObject(_defaultHtmlfolderCopiedSOName, true);
			if (_copyHtmlFolderCallback) _copyHtmlFolderCallback(true);
		}
		static private function copyErrorCallback(e:*=null):void {
			Debug.error("PAWebView", "Copy to cache ERROR: " + e);
			if (_copyHtmlFolderCallback) _copyHtmlFolderCallback(false);
		}
		
		
		static public function set useDistriqtAne(value:Boolean):void 
		{
			_useDistriqtAne = value;
		}
		static public function init(initCallback:Function):void {
			Debug.debug("PAWebView", "Static initialization.");
			_initCallback = initCallback;
			if (_useDistriqtAne) DistriqtWebView.init(distriqtInitialized);
			else {
				Debug.debug("PAWebView", "Initializing with regular StageWebView.");
				_initCallback();
			}
		}
		static private function distriqtInitialized():void {
			_initialized = true;
			_initCallback();
			_initCallback = null;
		}
		
		/**
		 * Checks if a string is an online url with http or https
		 * @param	url
		 * @return	ture if it is an online url
		 */
		static public function checkIfOnlineUrl(url:String):Boolean {
			return url.toLowerCase().indexOf("http") == 0;
		}
		
		
		
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PAWebView(id:String=null, cl:Class=null, htmlFolder:String=null, viewPort:Rectangle=null) 
		{
			super("PaWebView" + (id ? "_" + id : ""), cl ? cl : PAWebView);
			_htmlFolder = htmlFolder ? htmlFolder : DEFAULT_HTML_FOLDER;
			_isOnline = checkIfOnlineUrl(_htmlFolder);
			Debug.debug(_debugPrefix, "Created with assets location: " + _htmlFolder + " - " + (_isOnline ? "ONLINE" : "LOCAL"));
			//Debug.debug(_debugPrefix, "WebView content folder: " + _htmlFolder);
			if (!createNativeWebView(id)) createInternalWebView(); // First try to create a native webvie
			setViewport(viewPort ? viewPort : UGlobal.stageRect);
			Debug.debug(_debugPrefix, "Set viewport: " + viewPort);
			_openHttpLinksExternally = OPEN_HTTP_LINKS_EXTERNALLY;
		}
		private function createNativeWebView(id:String):Boolean {
			if (_useDistriqtAne && DistriqtWebView.initialized) {
				Debug.debug(_debugPrefix, "Creating native web view: " + DistriqtWebView);
				_distriqtWebView = new DistriqtWebView("DistriqtWebView_"+id, null, this);
				//_distriqtWebView.setViewport(_rect);
				PippoFlashEventsMan.addInstanceListener(_distriqtWebView, this);
				_distriqtWebView.createWebView(_rect);
				return true;
			}
			return false;
		}
		private function createInternalWebView():void {
			Debug.debug(_debugPrefix, "Creating internal web view.");
			_webView = new StageWebView(USE_NATIVE_WEBVIEW);
			_webView.stage = UGlobal.stage;
			_webView.addEventListener(LocationChangeEvent.LOCATION_CHANGING, onWebViewLocationChanging);
			_webView.addEventListener(LocationChangeEvent.LOCATION_CHANGE, onWebViewLocationChange);
			_webView.addEventListener(Event.COMPLETE, onWebViewLoadComplete);
		}
		
		
		
		
		// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function setViewport(r:Rectangle):void {
			_ready = true;
			_active = true;
			//_rect = r.clone();
			//if (_distriqtWebView) {
				//_distriqtWebView.setViewport(_rect);
				//return;
			//}
			// Proceed with internal web view
			_x = r.x; _y = r.y; _w = r.width; _h = r.height;
			updateViewport();
		}
		
		public function loadHtmlFile(u:String, skipBaseFolder:Boolean=false, defaultWindowValues:Object=null, anticache:Boolean=false):void {
			if (!_ready) {
				Debug.error(_debugPrefix, "loadHtmlFile() failed: Rectangle not set. Set rectangle first calling setViewport()");
				return;
			}
			const fullUrl:String = skipBaseFolder ? u : _htmlFolder + u; // With or without base folder
			_isOnline = checkIfOnlineUrl(fullUrl);
			Debug.debug(_debugPrefix, "Opening html: " + fullUrl + " - " + (_isOnline ? "ONLINE" : "LOCAL"));
			_defaultWindowValues = defaultWindowValues ? defaultWindowValues : {};
			// Creating target path according to online or offline status
			const targetHtmlPath:String = fullUrl;
			if (!_isOnline) { // Loding from local folder
				var indexUrl:String = UFile.getDestinationPath(fullUrl, _destinationStorage, true, false, true);
				Debug.debug(_debugPrefix, "Local URL of destination file: " + indexUrl);
				_nativeUrl = new File(new File(indexUrl).nativePath).url;
			} else {
				_nativeUrl = fullUrl;
				if (anticache) _nativeUrl += (_nativeUrl.indexOf("?") == -1 ? "?" : "&") + (new Date()).time;
			}
			// Load the url
			Debug.debug(_debugPrefix, "Loading final url: " + _nativeUrl);
			if (_distriqtWebView) _distriqtWebView.loadHtmlFile(_nativeUrl);
			else _webView.loadURL(_nativeUrl);
		}
		
		public function callJavaScriptMethodSimple(methodName:String, param1:*=null, param2:*=null, param3:*=null, param4:*=null,  param5:*=null):void {
			var method:String = methodName + "(";
			if (param1) method += (param1 is String ? "'"+param1+"'" : param1);
			if (param2) method += ", " + (param2 is String ? "'" + param2 + "'" : param2);
			if (param3) method += ", " + (param3 is String ? "'" + param3 + "'" : param3);
			if (param4) method += ", " + (param4 is String ? "'" + param4 + "'" : param4);
			if (param5) method += ", " + (param5 is String ? "'" + param5 + "'" : param5);
			method += ");";
			callJavaScriptMethod(method);
		}
		
		public function callJavaScriptMethod(method:String):void {
			if (_distriqtWebView) {
				_distriqtWebView.callJavaScriptMethod(method);
				return;
			}
			var u:String = "javascript:" + method;
			Debug.debug(_debugPrefix, "Calling regular WebView JS method: " + u);
			_webView.loadURL(u);
		}
		
		public function callJSAirApplicationMethod(methodName:String, param1:*=null, param2:*=null, param3:*=null, param4:*=null, param5:*=null):void {
			callJavaScriptMethodSimple("window._airApplication." + methodName, param1, param2, param3, param4, param5);
		}
		/**
		 * Seta a property in _airApplication instance in HTML
		 * @param	propName Name of the variable
		 * @param	propValue Value of the variable
		 * @param	propType Type of variable (Number, Boolean, defaults to String)
		 */
		public function setJSAirApplicationProperty(propName:String, propValue:*, propType:String=null):void {
			var method:String = "window.setAirApplicationProperty('" + propName + "', '" + propValue + (propType ? "', " + propType : "'") + ");";
			callJavaScriptMethod(method);
		}
		public function printToHtmlLog(msg:String):void {
			callJSAirApplicationMethod(HTML_LOG_METHOD_NAME, encodeURI(msg), true);
		}
		
		
		
		// JAVASCRIPT MESSAGES PROCESSING ///////////////////////////////////////////////////////////////////////////////////////
		/**
		 * Checks if a location is normal browser navigation behavior or needs to be treated like a message to AIR.
		 * @param	location
		 * @return	true if navigation needs to be blocked, false if navigation can continue
		 */
		private function checkIfLocationIsInternalMessage(location:String):Boolean { // Returns true if event needs to be stopped from propagation
			if (verbose) Debug.debug(_debugPrefix, "Checking how to react  to location: " + location);
			if (checkIfOnlineUrl(location)) {
				Debug.debug(_debugPrefix, "URL appears online navigation. No need to block navigation.");
				return false;
			}
			// Check whether it is a command and rgular navigation should be blocked
			return  processJavaScriptMessage(location);
		}
		
		/**
		 * Processes a string to execute commands received from JavaScript
		 * @param	msg
		 * @return	true if it is a recognized commmand
		 */
		private function processJavaScriptMessage(location:String):Boolean {
			// Remove airBridge: if it is remained (not needed anymore since on Windows we use NativeWeb View anyway.
			if (location.indexOf("airbridge:") == 0) { // Crop Distriqt specific webview links (useful when testing in old WebViews)
				location = location.substr(10);
			}
			const COMMAND_READY:String = "ready:";
			const COMMAND_TRACE:String = "trace:";
			const COMMAND_AS:String = "actionscript:";
			const COMMAND_EXTERNALBROWSER:String = "externalbrowser:";
			if (location.indexOf(COMMAND_READY) == 0) {
				Debug.debug(_debugPrefix, "HTML Page reported Air Features in JavaScript READY!");
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_REPORTED_READY, this);
				return true;
			}
			else if (UText.stringContains(location, COMMAND_TRACE)) {
				// Substitute <brwith \n
				const joiner:String = "\n\t\t[JS]";
				var txt:String = UText.removeTextUpTo(decodeURI(location), COMMAND_TRACE);
				txt = joiner + UText.substituteInString(txt, "<br>", joiner);
				Debug.debug(_debugPrefix, "JS CONSOLE> " + txt);
				return true;
			}
			else if (UText.stringContains(location, COMMAND_EXTERNALBROWSER)) {
				const url:String = decodeURI(UText.removeTextUpTo(location, COMMAND_EXTERNALBROWSER));
				Debug.debug(_debugPrefix, "Open external url in browser: " + url);
				var req:URLRequest = new URLRequest(url);
				navigateToURL(req, "_self");
				return true;
			}
			else if (UText.stringContains(location, COMMAND_AS)) { // AcrtionScript command
				const splitted:Array = location.split("__ALL_PARAMETERS__");
				trace(location);
				trace(splitted);
				trace(splitted.length);
				splitted[0] = UText.removeTextUpTo(splitted[0], COMMAND_AS); // Remove suffix "actionscript:" from isntance id
				if (splitted.length > 1) _PippoFlashBase.callPippoFlashInstanceMethod(splitted[0], splitted[1].split("__PARAM__"));
				else _PippoFlashBase.callPippoFlashInstanceMethod(splitted[0]);
				return true;
			}
			Debug.debug(_debugPrefix, "No Javascript Command recognized in: " + location);
			return false;
		}
		
		
		
		
		// REGULAR WEBVIEW LISTENERS ///////////////////////////////////////////////////////////////////////////////////////////////////
		private function onWebViewLoadComplete(e:Event):void {
			Debug.debug(_debugPrefix, "COMPLETE " + _webView.location);
			if (SEND_SYSTEM_ALERTS && !_systemAlertSent) {
				_systemAlertSent = true;
			}
			setupHtmlIsReady();
		}
		private function onWebViewLocationChanging(e:LocationChangeEvent):void {
			Debug.debug(_debugPrefix, "WebView changin to: " + e.location);
			if (checkIfLocationIsInternalMessage(e.location)) {
				e.stopImmediatePropagation();
				e.stopPropagation();
				e.preventDefault();
			}
		}		
		private function onWebViewLocationChange(e:LocationChangeEvent):void {
			Debug.debug(_debugPrefix, "CHANGE: " + e.location);
		}
		
		
		
		
		
		
		
		
		// NATIVE WEB VIEW LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onNativeWebViewHtmlComplete(v:DistriqtWebView):void {
			Debug.debug(_debugPrefix, "HTML loading complete.");
			setupHtmlIsReady();
		}
		public function onNativeWebViewHtmlChanging(v:DistriqtWebView, evt:NativeWebViewEvent):void {
			Debug.debug(_debugPrefix, "NativeWebView changin to: " + evt.data);
			if (checkIfLocationIsInternalMessage(evt.data)) {
				evt.preventDefault();
			}
		}
		public function onNativeWebViewHtmlChanged(v:DistriqtWebView, location:String):void {
			//checkLocation(location);
		}
		public function onNativeWebViewHtmlJSMessage(v:DistriqtWebView, msg:String):void {
			processJavaScriptMessage(msg);
		}
		
		
		
		
		
		//  UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function setupHtmlIsReady():void {
			_loaded = true;
			const systemProperties = {};
			if (USystem.isDesktop()) systemProperties.isDesktop = true;
			if (USystem.isDevice()) systemProperties.isDevice = true;
			if (USystem.isWin()) systemProperties.isWin = true;
			if (USystem.isMac()) systemProperties.isMac = true;
			if (USystem.isAndroid()) systemProperties.isAndroid = true;
			if (USystem.isIOS()) systemProperties.isIOS = true;
			UExec.resetSequence();
			UExec.addSequence(callJavaScriptMethod, "window.intializeAirFeatures(true, " + String(USystem.isDesktop()) + ", "+Debug.object(_defaultWindowValues)+", " + Debug.object(systemProperties)+ ")");
			if (_addAdditionalTunnelMethod) UExec.addSequence(activateHTMLLogTunnel);
			UExec.addSequence(PippoFlashEventsMan.broadcastInstanceEvent, this, EVT_READY, this);
		}
		private function activateHTMLLogTunnel():void {
			Debug.addExternalMethodExcludedId(_debugPrefix);
			if (_distriqtWebView) Debug.addExternalMethodExcludedId(_distriqtWebView._debugPrefix);
			//var startLog:String = Debug.getAllConsoleString("<br>");
			//var startLog:String = "<hr><br>INITIAL APP LOG<br><hr><br>" + UText.substituteInString(startLog, "\n", "<br>") + "<br><hr>";
			//UExec.addSequence(printToHtmlLog, "<hr><br>INITIAL APP LOG<br><hr><br>" + UText.substituteInString(startLog, "\n", "<br>") + "<br><hr>");
			Debug.addExternalMethod(printToHtmlLog);
		}
		private function updateViewport():void {
			_rect = new Rectangle();
			_rect.x = _x;
			_rect.y = _y;
			_rect.width = _w;
			_rect.height = _h;
			if (_distriqtWebView) {
				_distriqtWebView.setViewport(_rect);
				//Debug.debug(_debugPrefix, "Updated Sitriqt Viewport.");
			}
			else if (_webView) {
				//Debug.debug(_debugPrefix, "updateViewport() " + _rect);
				_webView.viewPort = _rect;
				//Debug.debug(_debugPrefix, "Updated regular webView viewport.");
			}
		}
		// GET SET ////////////////////////////////////////////////////////////
		
		public function toString():String {
			return "[" + _debugPrefix + "]";
		}
		
		// Positioning
		public function get x():Number 
		{
			return _x;
		}
		
		public function set x(value:Number):void 
		{
			_x = value;
			updateViewport();
		}
		
		public function get y():Number 
		{
			return _y;
		}
		
		public function set y(value:Number):void 
		{
			_y = value;
			updateViewport();
		}
		
		public function get w():Number 
		{
			return _w;
		}
		
		public function set w(value:Number):void 
		{
			_w = value;
			updateViewport();
		}
		
		public function get h():Number 
		{
			return _h;
		}
		
		public function get nativeUrl():String 
		{
			return _nativeUrl;
		}
		
		public function get loaded():Boolean 
		{
			return _loaded;
		}
		
		public function get reportedReady():Boolean 
		{
			return _reportedReady;
		}
		
		public function set h(value:Number):void 
		{
			_h = value;
			updateViewport();
		}
		
		static public function get initialized():Boolean 
		{
			return _initialized;
		}
		
		public function set openHttpLinksExternally(value:Boolean):void 
		{
			_openHttpLinksExternally = value;
		}
				
		override public function set verbose(value:Boolean):void {
			Debug.warning(_debugPrefix, "VERBOSE is false.");
			_distriqtWebView.verbose = false;
			super.verbose = value;
		}
		
		static public function set addAdditionalTunnelMethod(value:Boolean):void 
		{
			_addAdditionalTunnelMethod = value;
		}
		
		
	}

}