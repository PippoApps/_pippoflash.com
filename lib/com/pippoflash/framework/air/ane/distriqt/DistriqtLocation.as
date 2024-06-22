package com.pippoflash.framework.air.ane.distriqt 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.air.ane._PippoAppsANE;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.USystem;
	import com.distriqt.extension.playservices.base.ConnectionResult;
	import com.distriqt.extension.playservices.base.GoogleApiAvailability;
	import com.distriqt.extension.location.*;
	import com.distriqt.extension.location.events.*;
	import com.distriqt.extension.location.geofences.*;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class DistriqtLocation extends _DistriqtAne 
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
		static private var _requestedOnlyForeground:Boolean;
		static private var _debugPrefix:String = "LocationANE";
		public static const EVT_UPDATE:String = "onLocationUpdate"; // lat:Number, long:Number
		public static const EVT_ENTER_REGION:String = "onEnterRegion"; // ID:String
		public static const EVT_EXIT_REGION:String = "onExitRegion"; // ID:String
		
		static public function get isSupported():Boolean {
			return Location.isSupported;
		}
		static public function get isFullyAvailable():Boolean {
			return Location.isSupported && _hasPermission && Location.service.isAvailable(); 
		} // Is all available nd authorised
		static public function get isAvailable():Boolean { // Is available only wify or settings
			return Location.service.isAvailable(); 
		}
		static public function init(initCallbackOnlyAndroid:Function=null):Boolean {
			if (_initialized) return true;
			if (isSupported && _DistriqtAne.isSupported) {
				_DistriqtAne.init();
				Debug.warning(_debugPrefix, "Initializing " + Location.VERSION);
				if (USystem.isAndroid()) {
					//if (!initCallbackOnlyAndroid) {
						//Debug.error(_debugPrefix, "On Android there must be a callback to check for google play location services.");
						//return false;
					//}
					// Proceed initialising android
					var result:int = GoogleApiAvailability.instance.isGooglePlayServicesAvailable();
					if (result != ConnectionResult.SUCCESS){
						if (GoogleApiAvailability.instance.isUserRecoverableError(result)){
							Debug.warning(_debugPrefix, "Asking user to fix goolge play services.");
							GoogleApiAvailability.instance.showErrorDialog(result);
						} else {
							Debug.warning(_debugPrefix, "Google play services not available, therefore Location not available.");
						}
						return false;
					} else {
						Debug.debug(_debugPrefix, "Google play services available.");
					}					
				}
				// iOS initialization is straightforward
				_initialized = true;
				return true;
			}
			Debug.warning(_debugPrefix, "NOT SUPPORTED ON THIS PLATFORM");
			return false;
		}
		static public function get initialized():Boolean 
		{
			return _initialized;
		}
		
		static public function get hasPermission():Boolean 
		{
			return _hasPermission;
		}
		static private var _authorizationCallback:Function; // True or false whether authorization is requested
		static public function requestAuthorization(authorizationCallback:Function, onlyOnForeground:Boolean = true):void {
			Location.service.addEventListener(AuthorisationEvent.CHANGED, authorisationChangedHandler);
			_authorizationType = Location.service.authorisationStatus();
			_authorizationCallback = authorizationCallback;
			_requestedOnlyForeground = onlyOnForeground;
			//Debug.debug(_debugPrefix, "Authorizing. Current status: " + _authorizationType);
			analyzeAuthorization(true);
			
			
			//switch (Location.service.authorisationStatus()) {
				//case AuthorisationStatus.ALWAYS:
				//case AuthorisationStatus.IN_USE:
					//trace( "User allowed access: " + Location.service.authorisationStatus() );
					//break;
				//
				//case AuthorisationStatus.NOT_DETERMINED:
				//case AuthorisationStatus.SHOULD_EXPLAIN:
					//Location.service.requestAuthorisation(onlyOnForeground ? AuthorisationStatus.IN_USE : AuthorisationStatus.ALWAYS);
					//break;
				//
				//case AuthorisationStatus.RESTRICTED:
				//case AuthorisationStatus.DENIED:
				//case AuthorisationStatus.UNKNOWN:
					//trace( "User denied access" );
					//break;
			//}
		}

		static private function authorisationChangedHandler( event:AuthorisationEvent ):void {
			_authorizationType = event.status;
			analyzeAuthorization(false);
		}			
		static private function analyzeAuthorization(andRequestIfNegative:Boolean):void {
			Debug.debug(_debugPrefix, "Analyzing authorization: " + _authorizationType);
			switch (_authorizationType) {
				case AuthorisationStatus.ALWAYS:
						setAuthorization(true, false);
						return;
						break;
				case AuthorisationStatus.IN_USE:
						setAuthorization(_authorizationType == AuthorisationStatus.IN_USE, andRequestIfNegative);
						return;
						break;
				// Any other case request again authorization
			}
			setAuthorization(false, andRequestIfNegative);
		}
		static private function setAuthorization(auth:Boolean, requestInsteadOfBroadcast:Boolean):void {
			_hasPermission = auth;
			Debug.debug(_debugPrefix, "Permission " + (_hasPermission ? "GRANTED" : "DENIED"));
			if (auth || !requestInsteadOfBroadcast) {
				if (_authorizationCallback) _authorizationCallback(_hasPermission);
				_authorizationCallback = null;
			}
			else if (requestInsteadOfBroadcast) {
				Debug.debug(_debugPrefix, "Requesting authorization for: " + (_requestedOnlyForeground ? AuthorisationStatus.IN_USE : AuthorisationStatus.ALWAYS));
				Location.service.requestAuthorisation(_requestedOnlyForeground ? AuthorisationStatus.IN_USE : AuthorisationStatus.ALWAYS);
			}
		}
		//static private var broadcastUnauthorized;
		//}
		
		
		
		
		// CLASS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		
		public function DistriqtLocation(id:String, cl:Class=null){
			super("DistriqtLocation_" + id, cl ? cl : DistriqtLocation);
		}
		
		
		//private var _pointsToMonitor:Vector.<Array>;
		private var _regionsToMonitor:Vector.<Region>;
		private var _locationRequests:Vector.<LocationRequest>;
		
		
		
		
		
		
		
		// ACCESS LOCATION
		public function requestLocationUpdate():Boolean {
			if (!_locationRequests) {
				_locationRequests = new Vector.<com.distriqt.extension.location.LocationRequest>();
				Location.service.addEventListener(LocationEvent.UPDATE, location_updateHandler);
			}
			var request:LocationRequest = new LocationRequest()
				.setAccuracy( LocationRequest.ACCURACY_NEAREST_TEN_METERS )
				.setPriority( LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY );
			var success:Boolean = Location.service.startLocationMonitoring( request );
			if (success) {
				Debug.debug(_debugPrefix, "Requesting location success: " + request);
				_locationRequests.push(request);
			} else {
				Debug.error(_debugPrefix, "Location request failed.");
				return false;
			}
			return true;
		}
		
		
		function location_updateHandler( event:LocationEvent ):void
		{
			trace( "location updated: [" + event.position.latitude+"," + event.position.longitude +"]");
			//trace(event.position.latitude+addLat, event.position.longitude+addLong);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_UPDATE, event.position.latitude, event.position.longitude);
			//_testPaWebView.callJavaScriptMethod("positionUserToLatLong("+(event.position.latitude+addLat)+","+(event.position.longitude+addLong)+")");
		}			
				
		
		
		
		
		
		
		
		
		
		// MONITORING
		public function addPointToMonitor(id:String, lat:Number, lon:Number, radius:uint = 100):void {
			if (!_regionsToMonitor) initPointMonitoring();
			var region:Region = new Region();
			region.identifier = id;
			region.latitude = lat;
			region.longitude = lon;
			region.radius = radius;
			region.startApplicationOnEnter = true;
			if (Location.service.geofences.startMonitoringRegion( region)) {
				Debug.debug(_debugPrefix, "Successfully added region: " + region.identifier);
				_regionsToMonitor.push(region);
			} else {
				Debug.error(_debugPrefix, "Error monitoring region: " + region.identifier);
			}
		}
		// UTY
		private function initPointMonitoring():void {
			_regionsToMonitor = new Vector.<com.distriqt.extension.location.geofences.Region>();
			Location.service.geofences.addEventListener( RegionEvent.START_MONITORING, startMonitoringHandler );
			Location.service.geofences.addEventListener( RegionEvent.ENTER, enterHandler );
			Location.service.geofences.addEventListener( RegionEvent.EXIT, exitHandler );
		}
		
		
		
		



		private function startMonitoringHandler( event:RegionEvent ):void
		{
			Debug.debug(_debugPrefix, "Start monitoring: [" + event.region.identifier + "]        " + event.region);
		}


		private function enterHandler( event:RegionEvent ):void
		{
			Debug.warning(_debugPrefix, "Enter region: " + event.region.identifier, event.region);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_ENTER_REGION, event.region.identifier);
		}

		private function exitHandler( event:RegionEvent ):void
		{
			Debug.warning(_debugPrefix, "Exit region: " + event.region.identifier, event.region);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_EXIT_REGION, event.region.identifier);
		}

		
		
	}

}