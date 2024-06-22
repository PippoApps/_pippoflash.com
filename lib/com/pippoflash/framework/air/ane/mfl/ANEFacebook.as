/* ANEFacebook - ver 0.2 - Filippo Gregoretti - www.pippoapps.com
 * Upgraded to new Facebook ANE 4.3.0

NOTE
Requesting READ and PUBLISH permissions at the same time, messes up with login window.
Permissions request practically broadcast a LOGIN event, also on second request.



*/
/* Apple test users
filippo+en1@isointeractive.com			Th3MooseIsYapping	
ethan+en1@kattare.com					Th3MooseIsYapping
*/


package com.pippoflash.framework.air.ane.mfl {

// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import flash.net.URLRequestMethod;
	import com.pippoflash.utils.*; import com.pippoflash.framework._ApplicationAir; // PippoFlash
	import flash.display.*; import flash.events.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*; import flash.geom.*; import flash.external.*;// FLash
	import flash.html.*; import flash.display.*;  // AIR
	//import com.myflashlab.air.extensions.dependency.OverrideAir;
	//import com.myflashlab.air.extensions.facebook.access.Permissions;
	//import com.myflashlab.air.extensions.facebook.access.Auth;
	import com.myflashlab.air.extensions.fb.*;
	import com.myflashlab.air.extensions.fb.AccessToken;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public class ANEFacebook {
	// VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		// DEBUG SWITCHES
		// CONSTANTS
		private static const PUBLISH_PERMISSION_GRANTED_VAR_NAME:String = "PFAneFacebookPublishPermissionGranted";
		private static const _debugPrefix:String = "ANEFacebook";
		// REFERENCES
		static private var _initCallbackSuccess:Function; //no parameters- initialized, but user not logged in
		static private var _initCallbackError:Function; // no parameters
		static private var _initCallbackAlreadyLogged:Function; // token:String - initialized, and user already logged in on device
		static private var _initCallbackInvoke:Function; // deeplink:String - if app has been called invoked from a facebook invitation
		static private var _loginCallbackSuccess:Function;
		static private var _loginCallbackCancel:Function;
		static private var _loginCallbackError:Function;
		static private var _publishSuccess:Function;
		static private var _publishError:Function;
		// FRAMERATE
		// DATA
		private static var _appId:String;
		static private var _permissionsRead:Array = ["public_profile"]; // Just some basic permissions are here
		static private var _permissionsPublish:Array = []; // Just some basic permissions are here
		static private var _accessToken:AccessToken;
		// AIR DEVICE ID
		// MARKERS - SYSTEM
		static private var _init:Boolean;
		static private var _logged:Boolean;
		static private var _useStoredToken:Boolean; // If using stored tocken or not
		// MARKERS - PERMISSIONS
		//static private var _permissionsGranted:Object = {}; // Stored permission names as strings i.e.: _permissionsGranted.public_profile == true;
		// UTY
	// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init(appId:String, callbackSuccess:Function, callbackError:Function, callbackLoggedOnInit:Function, callBackInvoke:Function):void {
			_appId = appId;
			_initCallbackSuccess = callbackSuccess;
			_initCallbackError = callbackError;
			_initCallbackAlreadyLogged = callbackLoggedOnInit;
			_initCallbackInvoke = callBackInvoke;
			Debug.debug(_debugPrefix, "Initializing facebook app " + _appId);
			//if (_init) {
				//Debug.debug(_debugPrefix, "App has already been initialized. Triggering directly login window.");
				//toLogin();
				//return;
			//}
			//if (!loginOnInit) Debug.debug(_debugPrefix, "Login will NOT be performed at init. ANEFaceboo.login() should be called.");
			Facebook.init(_appId);
			Facebook.listener.addEventListener(FacebookEvents.INIT, onAneInit);
			Facebook.listener.addEventListener(FacebookEvents.INVOKE, onAneInvoke);
			if (USystem.isAndroid()) Debug.debug(_debugPrefix, "Android hash key: " + Facebook.hashKey);
		}
		public static function onAneInvoke(e:FacebookEvents):void {
			Debug.debug(_debugPrefix, "Ane Invoke: " + decodeURIComponent(e.deeplink));
			_initCallbackInvoke(e.deeplink);
		}

		public static function onAneInit(e:FacebookEvents):void {
			// check if user is already logged in or not
			_accessToken = Facebook.auth.currentAccessToken;

			
			
			Debug.debug(_debugPrefix, "ANE init: " + (_accessToken ? "with token: " + _accessToken.token : "without access token."));
			if (_accessToken) {
				_logged = true;
				_init = true;
				_initCallbackAlreadyLogged(_accessToken.token);
			}
			else {
				_init = false;
				_initCallbackSuccess();
			}
			/*
				IMPORTANT: in practice you should let users click on a login button 
				not logging them automatically.
			*/
		}
		static public function login(callbackSuccess:Function, callbackError:Function, callbackCancel:Function = null):void {
			_loginCallbackSuccess = callbackSuccess;
			_loginCallbackError = callbackError;
			_loginCallbackCancel = callbackCancel ? callbackCancel : callbackError;
			toLogin();
		}
		
		
		private static function toLogin():void
		{
			/*
				It is recommended to login users with minimal permissions. Later, whe your app 
				needs more permissions, you can call "Facebook.auth.login" again with more permissions.
				
				To ask for publish permissions, set the first parameter to "true".
			*/
			Debug.debug(_debugPrefix, "Calling Facebook.auth.login()");

			var permissions:Array = [Permissions.public_profile, Permissions.user_friends, Permissions.email];
			Facebook.auth.login(false, permissions, loginCallback);
			
			function loginCallback($isCanceled:Boolean, $error:Error, $accessToken:AccessToken, $recentlyDeclined:Array, $recentlyGranted:Array):void {
				if($error) {
					Debug.debug(_debugPrefix, "Login error: ", $error.message);
					_loginCallbackError($error.message);
				}
				else
				{
					if ($isCanceled) {
						Debug.debug(_debugPrefix, "Login canceled by user.");
						_loginCallbackCancel("Login Cancelled by User");
					}
					else
					{
						trace("$recentlyDeclined: " + $recentlyDeclined);
						trace("$recentlyGranted: " + $recentlyGranted);
						_accessToken = $accessToken;
						_logged = true;
						trace("token: " + _accessToken.token);
						trace("userId: " + _accessToken.userId);
						trace("declinedPermissions: " + _accessToken.declinedPermissions);
						trace("grantedPermissions: " + _accessToken.grantedPermissions);
						trace("expiration: " + new Date(_accessToken.expiration).toLocaleDateString());
						trace("lastRefresh: " + new Date(_accessToken.lastRefresh).toLocaleDateString());
						_loginCallbackSuccess(_accessToken.token);
					}
				}
			}
		}		
		// Init listeners
	// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		// SET PERMISSIONS
		//static public function addPermission(isReadPermission:Boolean, perm:String, requestImmediately:Boolean=false):void { // Adds one permission
			//var targetList:Array = isReadPermission ? _permissionsRead : _permissionsPublish;
			//if (!Permissions[perm]) Debug.error(_debugPrefix, "Canno att permission to " + (isReadPermission ? "READ" : "PUBLISH") + " permissions. Term not allowed: " + perm);
			//else if (targetList.indexOf(perm) == -1) targetList.push(perm);
			//// Trigger request if logged already
			//if (requestImmediately && isLogged()) {
				//if (isReadPermission) requestReadPermissions();
				//else requestPublishPermissions();
			//}
		//}
		//static public function setPermissions(isReadPermission:Boolean, perms:Array, requestImmediately:Boolean = false):void { // Overwrites permissions
			//// Reset requested array
			//if (isReadPermission) _permissionsRead = [];
			//else _permissionsPublish = [];
			//// Keep pushing permissions one by one
			//for each (var perm:String in perms) addPermission(isReadPermission, perm, false);
			//// Talk
			//var permType:String = (isReadPermission ? "READ" : "PUBLISH");
			//Debug.debug(_debugPrefix, "Setting " + permType + " permissions: " + (isReadPermission ? _permissionsRead : _permissionsPublish));
			//// Trigger request if logged already
			//if (requestImmediately && isLogged()) {
				//if (isReadPermission) requestReadPermissions();
				//else requestPublishPermissions();
			//}
		//}
		// LOGIN (and request read permissions)
		//static public function login(callbackSuccess:Function, callbackError:Function, callbackCancel:Function=null):void {
			//_loginCallbackSuccess = callbackSuccess;
			//_loginCallbackError = callbackError;
			//_loginCallbackCancel = callbackCancel ? callbackCancel : UCode.dummyFunction;
			//Debug.debug(_debugPrefix, "Loggin in to facebook...");
			//FB.auth.addEventListener(FBEvent.LOGIN_DONE, onLoginSuccess);
			//FB.auth.addEventListener(FBEvent.LOGIN_CANCELED, onLoginCanceled);
			//FB.auth.addEventListener(FBEvent.LOGIN_ERROR, onLoginError);
			// Request permissions for read only
			//requestReadPermissions();
		//}
		
		
		
		
		
		
		
		
		
	// LOGOUT	
		static private var _onLogoutCallback:Function;
		static public function logout(onLogoutCallback:Function, logoutOnlyIfLoggedIn:Boolean=false):void {
			if (logoutOnlyIfLoggedIn && !isLogged()) {
				Debug.warning(_debugPrefix, "Cannot logout, since I never logged in...");
				return;
			}
			Debug.warning(_debugPrefix, "Logging out user.");
			_logged = false;
			//if (USystem.isAndroid()) {
				Debug.warning(_debugPrefix, "On Android also Graph logot is required.");
				_onLogoutCallback = onLogoutCallback;
				Facebook.graph.call("https://graph.facebook.com/v3.0/me/permissions/", URLRequestMethod.POST, new URLVariables("method=delete"), onGraphLogout);
				//call($url:String, $urlRequestMethod:String, $urlVariables:URLVariables, $callback:Function):void
			//}
			//else {
				//Facebook.auth.logout(); // On IOS logout immediately
				//UExec.next(onLogoutCallback);
			//}
		}
		static private function onGraphLogout(data:String = null, req:String = null):void {
			Debug.debug(_debugPrefix, "On Graph Logout feedback:",data+"\n"+req);
			Facebook.auth.logout();
			UExec.next(_onLogoutCallback);
			_onLogoutCallback = null;
		}
		
		
	// PUBLISH
		static public function publish(publishSuccess:Function, publishError:Function, uri:String, quote:String=null, hashtag:String=null, pageId:String=null, placeId:String=null, ref:String=null):void {
			_publishSuccess = publishSuccess;
			_publishError = publishError;
			var sc:ShareLinkContent = new ShareLinkContent();
			sc.contentUrl = uri;
			if (placeId) sc.quote = quote;
			if (hashtag) sc.hashtag = hashtag;
			if (pageId) sc.pageId = pageId;
			if (placeId) sc.placeId = placeId;
			if (ref) sc.ref = ref;
			Facebook.share.shareDialog(sc, onPublishFeedback);		
		}
		static private function onPublishFeedback(isCanceled:Boolean, error:Error=null):void {
			if (error) {
				Debug.error(_debugPrefix, "Error publishing on facebook: " + error.message);
				_publishError(error.message);
			}
			else {
				if (isCanceled) _publishError("User Canceled");
				else {
					Debug.debug(_debugPrefix, "Facebook publish successful.");
					_publishSuccess();
				}
			}
			_publishSuccess = null;
			_publishError = null;
		}
		static public function isActive():Boolean {
			return _init;
		}
		static public function isLogged():Boolean {
			return _logged;
		}
	// INVITE FRIENDS AND GAME REQUESTS ///////////////////////////////////////////////////////////////////////////////////////
		static private var _inviteFriendsOk:Function;
		static private var _inviteFriendsCancel:Function;
		static private var _inviteFriendsError:Function;
		static public function inviteFacebookFriendsToApp(message:String, funcOk:Function, funcError:Function = null, funcCancel:Function = null):void { // This invites facebook friends to the application
			_inviteFriendsOk = funcOk; // result:Object
			_inviteFriendsCancel = funcCancel;
			_inviteFriendsError = funcError; // error:Error
			var requestContent:GameRequestContent = new GameRequestContent();
			requestContent.message = message;
			Facebook.games.requestDialog(requestContent, onFriendsInvite);
		}
		static private function onFriendsInvite(isCanceled:Boolean, error:Error, result:Object):void {
			if (error) {
				Debug.error(_debugPrefix, "Invite friends error: " + error);
				if (_inviteFriendsError) _inviteFriendsError(error);
			}
			else if (isCanceled) {
				Debug.debug(_debugPrefix, "User canceled.");
				if (_inviteFriendsCancel) _inviteFriendsCancel();
			} else {
				Debug.debug(_debugPrefix, "Sent friends invite: " + Debug.object(result));
				_inviteFriendsOk(result);
			}
		}
			//static public function canPublish():Boolean { /* DEBUG */
			//return true;
			//return Facebook.auth.permissions.indexOf("publish_actions") != -1;
		//}
		
		
	// SETTERS ///////////////////////////////////////////////////////////////////////////////////////
		//static public function set useStoredToken(b:Boolean):void {
			//_useStoredToken = b;
		//}
	// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		// LOGIN
		//static private function onLoginSuccess(e:FBEvent):void {
			//Debug.debug(_debugPrefix, "Login Success");
			//removeLoginListeners();
			//// Proceed with login
			//_logged = true;
			//_loginCallbackSuccess(FB.auth.token);
		//}
		//static private function onLoginCanceled(e:FBEvent):void {
			//Debug.debug(_debugPrefix, "Login Canceled");
			//removeLoginListeners();
			//_logged = false;
			//_loginCallbackCancel("Login Cancelled by User");
		//}
		//static private function onLoginError(e:FBEvent):void {
			//Debug.debug(_debugPrefix, "Login Error");
			//_loginCallbackError(String(e));
			//_logged = false;
			//removeLoginListeners();
		//}
		// GENERAL PERMISSIONS (they 
		//static private function onPermissionReqSuccess(e:FBEvent):void {
			//// Setup granted permissions
			////for each (var p:String in _permissionsPublish) _permissionsGranted[p] = true;
		//}
		//static private function onPermissionReqCancel(e:FBEvent):void {
			//
		//}
		//static private function onPermissionReqError(e:FBEvent):void {
			//
		//}
		// SHARING
		//static private function onSharingResult(status:String, msg:String):void {
			//if (status == FacebookEvents.SHARING_DONE) {
				//Debug.debug(_debugPrefix, "Content shared successfully.");
				//_publishSuccess(msg);
			//}
			//else {
				//if (status == FacebookEvents.SHARING_CANCELED) onPublishError("Canceled by user.");
				//else {
					//onPublishError("Error in sharing content: " +  msg);
				//}
			//}
			//_publishSuccess = null;
			//_publishError = null;
		//}
		//static private function onPublishError(msg:String):void {
			//Debug.error(_debugPrefix, "Publish error: " + msg);
			//if (_publishError) _publishError(msg);
		//}
	// UTY ///////////////////////////////////////////////////////////////////////////////////////
		//static private function removeLoginListeners():void {
			//FB.auth.removeEventListener(FBEvent.LOGIN_DONE, onLoginSuccess);
			//FB.auth.removeEventListener(FBEvent.LOGIN_CANCELED, onLoginCanceled);
			//FB.auth.removeEventListener(FBEvent.LOGIN_ERROR, onLoginError);
		//}
		//static private function removePermissionListeners():void {
			//FB.auth.removeEventListener(FBEvent.LOGIN_DONE, onPermissionReqSuccess);
			//FB.auth.removeEventListener(FBEvent.LOGIN_CANCELED, onPermissionReqCancel);
			//FB.auth.removeEventListener(FBEvent.LOGIN_ERROR, onPermissionReqError);
		//}
	// PERMISSIONS UTY (canot access ...rest)
		//static private function reqPermR1():void {
			//FB.auth.requestPermission(Auth.WITH_READ_PERMISSIONS, _permissionsRead[0]);
		//}
		//static private function reqPermR2():void {
			//FB.auth.requestPermission(Auth.WITH_READ_PERMISSIONS, _permissionsRead[0], _permissionsRead[1]);
		//}
		//static private function reqPermR3():void {
			////Debug.warning(_debugPrefix, "Requesting permissions: " +  Permissions.email, Permissions.user_friends, Permissions.public_profile);
			////FB.auth.requestPermission(false, Permissions.email, Permissions.user_friends, Permissions.public_profile);
			//FB.auth.requestPermission(Auth.WITH_READ_PERMISSIONS, _permissionsRead[0], _permissionsRead[1], _permissionsRead[2]);
		//}
		//static private function reqPermR4():void {
			//FB.auth.requestPermission(Auth.WITH_READ_PERMISSIONS, _permissionsRead[0], _permissionsRead[1], _permissionsRead[2], _permissionsRead[3]);
		//}
		//static private function reqPermP1():void {
			//FB.auth.requestPermission(Auth.WITH_PUBLISH_PERMISSIONS, _permissionsPublish[0]);
		//}
		//static private function reqPermP2():void {
			//FB.auth.requestPermission(Auth.WITH_PUBLISH_PERMISSIONS, _permissionsPublish[0], _permissionsPublish[1]);
		//}
		//static private function reqPermP3():void {
			//FB.auth.requestPermission(Auth.WITH_PUBLISH_PERMISSIONS, _permissionsPublish[0], _permissionsPublish[1], _permissionsPublish[2]);
		//}
		//static private function reqPermP4():void {
			//FB.auth.requestPermission(Auth.WITH_PUBLISH_PERMISSIONS, _permissionsPublish[0], _permissionsPublish[1], _permissionsPublish[2], _permissionsPublish[3]);
		//}
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