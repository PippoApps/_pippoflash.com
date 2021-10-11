package com.pippoflash.framework.air.ane.distriqt 
{
	import com.distriqt.extension.bluetoothle.*;
	import com.distriqt.extension.bluetoothle.events.*;
	import com.distriqt.extension.bluetoothle.objects.*;
	import com.distriqt.extension.bluetoothle.utils.*;
	import com.pippoflash.framework.air.UAir;
	
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
	public class DistriqtBluetoothLE extends _DistriqtAne 
	{

		
						//_webView.addEventListener(NativeWebViewEvent.COMPLETE, webViewCompleteHandler);
				//_webView.addEventListener(NativeWebViewEvent.LOCATION_CHANGE, webViewChangedHandler);
				//_webView.addEventListener(NativeWebViewEvent.LOCATION_CHANGING, webViewChangingHandler);
				//_webView.addEventListener(NativeWebViewEvent.ERROR, webViewErrorHandler);
				//_webView.addEventListener( NativeWebViewEvent.JAVASCRIPT_RESPONSE, javascriptResponseHandler );
				//_webView.addEventListener( NativeWebViewEvent.JAVASCRIPT_MESSAGE, javascriptMessageHandler );

		
		
		// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		static private var  _initialized:Boolean;
		static private var _hasPermission:Boolean;
		static private var _authorizationType:String;
		
		static private var _debugPrefix:String = "BluetoothLE";
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
		
		
		// CONNECTED DEVICES
		
		
		
		// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function get isSupported():Boolean {
			if (!BluetoothLE.isSupported) Debug.error(_debugPrefix, "Bluetooth not supported.");
			return BluetoothLE.isSupported;
		}
		static public function init():Boolean {
			if (isSupported) {
				_DistriqtAne.initCore();
				//BluetoothLE.init();
				Debug.debug(_debugPrefix, "Initializing ver " + BluetoothLE.VERSION);
				_initialized = true;
				setupAuthorizationStatus(BluetoothLE.service.authorisationStatus());
				//_authorizationType = BluetoothLE.service.authorisationStatus();
				//analyzeAuthorization(false);
			} else Debug.error(_debugPrefix, "NOT SUPPORTED ON THIS PLATFORM");
			return _initialized;
		}
		static public function get initialized():Boolean {
			return _initialized;
		}
		static public function get hasPermission():Boolean {
			return _hasPermission;
		}
		static private function setupAuthorizationStatus(auth:String):void {
			_authorizationType = auth;
			switch (_authorizationType) {
				case AuthorisationStatus.AUTHORISED:
						_hasPermission = true;
						return;
			}
		}
		
		static private var _authorizationCallback:Function; // True or false whether authorization is requested
		static public function requestAuthorization(authorizationCallback:Function):void {
			Debug.debug(_debugPrefix, "Requesting Bluetooth Authorisation.");
			setupAuthorizationStatus(BluetoothLE.service.authorisationStatus());
			if (hasPermission) {
				Debug.debug(_debugPrefix, "Bluetooth already authorised.");
				authorizationCallback(true);
				return;
			}
			// Proceed requesting authorisation
			_authorizationCallback = authorizationCallback;
			BluetoothLE.service.addEventListener(AuthorisationEvent.CHANGED, authorisationChangedHandler);
			BluetoothLE.service.requestAuthorisation();
		}
		static private function authorisationChangedHandler( event:AuthorisationEvent ):void {
			setupAuthorizationStatus(event.status);
			if (_authorizationCallback) _authorizationCallback(_hasPermission);
			_authorizationCallback = null;			//_authorizationType = event.status;
		}
		
		
		// CLASS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function DistriqtBluetoothLE(id:String, cl:Class=null, paWebViewConnected:PAWebView=null){
			super(id, cl ? cl : DistriqtBluetoothLE);
			if (!initialized) Debug.error(_debugPrefix, "Must be initialized with init() before using.");
			//_paWebViewConnected = paWebViewConnected;
		}
	}

}