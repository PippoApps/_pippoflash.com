/* UFile - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
This helps to work with files, both locally for AIR or for file upload.
This is a FIFO system, it allows only for one operation at a time.

*/

package com.pippoflash.framework.air {

	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	import									flash.external.*;
	import									flash.filesystem.*;
	import									com.pippoflash.utils.*;
	
	import flash.events.PermissionEvent;
	import flash.permissions.PermissionStatus;	
	import flash.sensors.Geolocation;
	import flash.events.GeolocationEvent;
	//import flash.events.PermissionEvent.PERMISSION_STATUS

	
	public class ULocation {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// SWITCHES
		public static var _verbose:Boolean = true;
		static private var _debugPrefix:String = "ULocation";
		static private var _geolocation:Geolocation;
		static private var _authorized:Boolean;
		// STATIC CONSTANTS
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		private static var _permissionGrantedCallback:Function;
		private static var _permissionDeniedCallback:Function;
		public static function init(onPermissionGranted:Function, onPermissionDenied:Function):void {
			_permissionGrantedCallback = onPermissionGranted;
			_permissionDeniedCallback = onPermissionDenied;
			// Check whether is supported
			if (!Geolocation.isSupported) {
				Debug.error(_debugPrefix, "Geolocation not available on this device.");
				onPermissionDenied();
				return;
			}
			// Proced with permission
			_geolocation = new Geolocation();
			Debug.debug(_debugPrefix, "Initializing Geolocation: " + Geolocation.permissionStatus);
			if (hasPermission(Geolocation.permissionStatus)) {
				sendPermissionGranted();
				return;
			}
			checkPermission(onPermissionGranted, onPermissionDenied);
		}
		static private function checkPermission(onPermissionGranted:Function, onPermissionDenied:Function):Boolean {
			if (_authorized) return sendPermissionGranted();
			Debug.debug(_debugPrefix, "Requesting permission.");
			_permissionGrantedCallback = onPermissionGranted;
			_permissionDeniedCallback = onPermissionDenied;
			UAir.addSleepListener(onApplicationSleep);
			UAir.addWakeListener(onApplicationWake);
			_geolocation.addEventListener(PermissionEvent.PERMISSION_STATUS, onPermission);
			UExec.next(_geolocation.requestPermission);
			//_geolocation.requestPermission();
			return false;
		}
		static private function onPermission(e:PermissionEvent):void {
			Debug.debug(_debugPrefix, "Premission event received:",e.status);
			//_MainAppBase.instance.promptOk(e.status);
			if (hasPermission(e.status)) {
				_authorized = true;
			}
			_geolocation.removeEventListener(PermissionEvent.PERMISSION_STATUS, onPermission);
		}
		static private function onApplicationSleep(e:Event):void {
			Debug.debug(_debugPrefix, "Application goes to sleep to request file permission.");
			UAir.removeSleepListener(onApplicationSleep);
		}
		static private function onApplicationWake(e:Event):void {
			Debug.debug(_debugPrefix, "Application woke up again, authorized: " + _authorized);
			UAir.removeWakeListener(onApplicationWake);
			if (_authorized) UExec.next(sendPermissionGranted);
			else sendPermissionDenied();
			//else UExec.time(0.2, checkPermission, _permissionGrantedCallback, _permissionDeniedCallback);
		}
		
		static private function hasPermission(status:String):Boolean {
			return status == PermissionStatus.GRANTED || status == PermissionStatus.ONLY_WHEN_IN_USE;
		}
		static private function sendPermissionGranted():Boolean {
			Debug.debug(_debugPrefix, "Permission is granted.");
			_permissionGrantedCallback();
			_permissionGrantedCallback = _permissionDeniedCallback = null;
			return true;
		}
		static private function sendPermissionDenied():void {
			Debug.debug(_debugPrefix, "Permission is denied.");
			_permissionDeniedCallback();
			_permissionGrantedCallback = _permissionDeniedCallback = null;
		}
		// GET SET
		static public function get authorized():Boolean 
		{
			return _authorized;
		}

		static private function debug(...rest):void {
			if (_verbose) Debug.debug("ULocation", rest.join(", "));
		}
	}
}