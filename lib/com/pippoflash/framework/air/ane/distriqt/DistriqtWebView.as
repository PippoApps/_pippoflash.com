package com.pippoflash.framework.air.ane.distriqt 
{
	import com.distriqt.extension.nativewebview.platform.WindowsOptions;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.air.ane._PippoAppsANE;
	import com.distriqt.extension.nativewebview.*;
	import com.distriqt.extension.nativewebview.events.*;
	import com.distriqt.extension.core.Core;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.USystem;
	import flash.display.Stage;
	import flash.geom.Rectangle;
	import flash.display.Screen;
	import com.pippoflash.framework.air.webview.PAWebView;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class DistriqtWebView extends _DistriqtAne 
	{

		
						//_webView.addEventListener(NativeWebViewEvent.COMPLETE, webViewCompleteHandler);
				//_webView.addEventListener(NativeWebViewEvent.LOCATION_CHANGE, webViewChangedHandler);
				//_webView.addEventListener(NativeWebViewEvent.LOCATION_CHANGING, webViewChangingHandler);
				//_webView.addEventListener(NativeWebViewEvent.ERROR, webViewErrorHandler);
				//_webView.addEventListener( NativeWebViewEvent.JAVASCRIPT_RESPONSE, javascriptResponseHandler );
				//_webView.addEventListener( NativeWebViewEvent.JAVASCRIPT_MESSAGE, javascriptMessageHandler );

		
		
		// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		static private var  _initialized:Boolean;
		static private var _debugPrefix:String = "NativeWebView";
		public static const USER_AGENT:String = "airsdk/webview";
		// EVENTS
		public static const EVT_COMPLETE:String = "onNativeWebViewHtmlComplete";
		public static const EVT_CHANGING:String = "onNativeWebViewHtmlChanging";
		public static const EVT_CHANGE:String = "onNativeWebViewHtmlChanged";
		public static const EVT_ERROR:String = "onNativeWebViewHtmlError";
		public static const EVT_JS_RESPONSE:String = "onNativeWebViewHtmlJSResponse";
		public static const EVT_JS_MESSAGE:String = "onNativeWebViewHtmlJSMessage";
		
		private static var _nativeOptions:NativeWebViewOptions;
		static private var _initCallback:Function;
		// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function get isSupported():Boolean {
			return NativeWebView.isSupported;
		}
		static public function init(initCallback:Function):Boolean {
			if (_initialized) {
				initCallback();
				return true;
			}
			if (isSupported) {
				_DistriqtAne.initCore();
				Debug.debug(_debugPrefix, "Initializing Distriqt NativeWebView ver " + NativeWebView.VERSION);
				//Core.init();
				
				_nativeOptions = new NativeWebViewOptions();
				_nativeOptions.setUserAgent(USER_AGENT);
				if (USystem.isWin()) {
					var windowsOptions = new WindowsOptions();
					
					// Set to a value between 1024 and 65535 to enable remote debugging on the specified port. For example, if 8080 is specified the remote debugging URL will be http://localhost:8081. CEF can be remotely debugged from any CEF or Chrome browser window.
					//windowsOptions.setRemoteDebuggingPort(8081);
					_nativeOptions.setWindowsOptions(windowsOptions);
				}
				_initCallback = initCallback;
				NativeWebView.service.addEventListener(NativeWebViewEvent.INITIALISED, onNativeWebViewServiceInitialized);
				NativeWebView.service.initialisePlatform(_nativeOptions);
				
				//NativeWebView.init();
				return true;
			}
			Debug.error(_debugPrefix, "NOT SUPPORTED ON THIS PLATFORM");
			return false;
		}
		static private function onNativeWebViewServiceInitialized(e:NativeWebViewEvent):void {
			NativeWebView.service.removeEventListener(NativeWebViewEvent.INITIALISED, onNativeWebViewServiceInitialized);
			_initialized = true;
			Debug.debug(_debugPrefix, "Correctly initialized.");
			_initCallback();
			_initCallback = null;
		}
		static public function get initialized():Boolean 
		{
			return _initialized;
		}
		
		
		
		// CLASS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		private var _options:WebViewOptions;
		//private var _viewport:Rectangle;
		private var _webView:WebView;
		//private var _paWebViewConnected:PAWebView;
		private var _x:Number;
		private var _y:Number;
		private var _w:Number;
		private var _h:Number;
		private var _rect:Rectangle;
		
		
		public function DistriqtWebView(id:String, cl:Class=null, paWebViewConnected:PAWebView=null){
			super(id, cl ? cl : DistriqtWebView);
			if (!initialized) Debug.error(_debugPrefix, "NativeWebView must be initialized with init() before using.");
			//_paWebViewConnected = paWebViewConnected;
		}
		public function setViewport(r:Rectangle):void {
			_x = r.x; _y = r.y; _w = r.width; _h = r.height; _rect = r;
			updateViewport();
		}
		public function createWebView(viewPort:Rectangle=null, options:WebViewOptions = null, stage:Stage = null):Boolean {
			setViewport(viewPort ? viewPort : new Rectangle( 0, 0, Screen.mainScreen.visibleBounds.width, Screen.mainScreen.visibleBounds.height));
			if (!stage) stage = UGlobal.stage;
			if (!options) {
				_options = new WebViewOptions();
				_options.allowInlineMediaPlayback = true;
				_options.allowZooming = false;
				_options.bounces = false;
				_options.mediaPlaybackRequiresUserAction = false;
				_options.backgroundEnabled = true;
				//_options.autoScale = false;
			} else _options = options;
			try {
				_webView = NativeWebView.service.createWebView( _rect, _options) ;
				_webView.addEventListener(NativeWebViewEvent.COMPLETE, webViewCompleteHandler);
				_webView.addEventListener(NativeWebViewEvent.LOCATION_CHANGE, webViewChangedHandler);
				_webView.addEventListener(NativeWebViewEvent.LOCATION_CHANGING, webViewChangingHandler);
				_webView.addEventListener(NativeWebViewEvent.ERROR, webViewErrorHandler);
				_webView.addEventListener( NativeWebViewEvent.JAVASCRIPT_RESPONSE, javascriptResponseHandler );
				_webView.addEventListener( NativeWebViewEvent.JAVASCRIPT_MESSAGE, javascriptMessageHandler );
				return true;
			} catch (e:Error){
				Debug.error(_debugPrefix, e);
			}
			return false;
		}

		
		
		public function loadHtmlFile(u:String, additionalHeaders:Vector.<Header>=null):void {
			_webView.loadURL(u, additionalHeaders);
		}
		
		public function callJavaScriptMethod(method:String):void {
			var u:String = "javascript:" + method;
			Debug.debug(_debugPrefix, "CallingJS: " + method);
			_webView.evaluateJavascript(method);
			//_webView.evaluateJavascript("window.IS_DESKTOP=" + String(USystem.isDesktop()));
		}
		
		
		
		
		
		
		
		
		
	// VIEWPORT MANAGEMENT
		public function get x():Number {
			return _x;
		}
		public function set x(value:Number):void {
			_x = value;
			updateViewport();
		}
		public function get y():Number {
			return _y;
		}
		public function set y(value:Number):void {
			_y = value;
			updateViewport();
		}
		public function get w():Number {
			return _w;
		}
		public function set w(value:Number):void {
			_w = value;
			updateViewport();
		}
		public function get h():Number {
			return _h;
		}		
		public function set h(value:Number):void 
		{
			_h = value;
			updateViewport();
		}
		private function updateViewport():void {
			//trace(_debugPrefix, _rect.x);
			_rect.x = _x;
			_rect.y = _y;
			_rect.width = _w;
			_rect.height = _h;
			//Debug.debug(_debugPrefix, "Updating Viewport:",_rect);
			if (_webView) _webView.viewPort = _rect;
		}		

//// ---- WEBVIEW CHANGE HANDLERS ---- /////

		private function webViewCompleteHandler(evt:NativeWebViewEvent):void {
			_webView.visible = true;		
			if (verbose) Debug.debug(_debugPrefix, "HTML completely loaded.");
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_COMPLETE, this);
		} //end functions
				
		private  function webViewChangingHandler(evt:NativeWebViewEvent):void {
			if (verbose) Debug.debug(_debugPrefix, "URL changing to " + evt.data);
			//evt.preventDefault();
				//trace("CHANGING FIRED: " +_webView.location);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_CHANGING, this, evt);
		} //end function
				
		private  function webViewChangedHandler(evt:NativeWebViewEvent):void {
			if (verbose) Debug.debug(_debugPrefix, "URL changed.");
			//trace("CHANGED FIRED: " +_webView.location);
			
		} //end function

		private  function webViewErrorHandler(evt:NativeWebViewEvent):void {
			Debug.error(_debugPrefix, "WebView Error " + evt);
		} //end function
				 
		private  function javascriptResponseHandler( event:NativeWebViewEvent ):void{
			if (event.data) {
				if (verbose) Debug.debug(_debugPrefix, "JS RESPONSE: " + event.data);
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_JS_RESPONSE, this, event.data);
			}
		}

		private  function javascriptMessageHandler( event:NativeWebViewEvent ):void{
			// This is the message sent from the javascript 
			// AirBridge.message i.e. 'content-for-air' 
			if (verbose) Debug.debug(_debugPrefix, "JS MESSAGE: " + event.data);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_JS_MESSAGE, this, event.data);
			//trace( "message from JS: " + event.data );
			//if (_paWebViewConnected) _paWebViewConnected.checkLocation(event.data);
		}		
		
		
		
	}

}