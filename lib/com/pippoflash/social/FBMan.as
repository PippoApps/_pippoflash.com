package com.pippoflash.social {
	// SYSTEM IMPORTS 
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.Debug;
// 	import											com.pippoflash.net.QuickLoader;
	import											flash.display.LoaderInfo;
	import											flash.net.URLLoader;
	import											flash.net.URLVariables;
	import											flash.net.URLLoaderDataFormat;
	import											flash.net.URLRequestMethod;
	
	

	// EXTERNAL IMPORTS
// 	import 											com.facebook.Facebook; 
// 	import 											com.facebook.utils.FacebookSessionUtil;  
// 	import 											com.facebook.events.FacebookEvent;
	import											com.adobe.serialization.json.JSON;
	import											com.facebook.data.auth.GetSessionData;
	import 											sk.yoz.events.FacebookOAuthGraphEvent;
	import 											sk.yoz.net.FacebookOAuthGraph;
	
	public class FBMan {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		private static var _debugPrefix				:String = "FBMan";
		private static var _fbGraphApi				:String = "http://graph.facebook.com/";
		private static var _callbackUri				:String = "http://www.talco.eu/AI10/callback.html";
		private static var _defaultPermissions			:String = "publish_stream,read_stream,user_photos,user_photo_video_tags,user_likes"; // Permissions info: http://developers.facebook.com/docs/authentication/permissions
		// SYSTEM - FACEBOOK
		private var _facebook						:FacebookOAuthGraph;
		// SYSTEM - MARKERS FOR CALLS
		private var _lastCallback					:Function;
		// USER VARIABLES
		// REFERENCES
		private var _listener						:Object;
		// MARKERS
		public var _status						:String = "IDLE"; // AUTOLOGIN, LOGIN
		public var _connected						:Boolean = false;
		// DATA HOLDERS
		public var _token							:String = "132239350155991|2.FS5vaMGoPzLmD_YEuxffFQ__.3600.1283706000-769037268|QwfD3w3VVqnQqO1zRyMpdQ0QlDQ.";
		public var _pageId						:String; // When connecting to a page, this is the page ID to be connected to
		private var _appId						:String; // Application ID for oAuth
		private var _loggedUserData					:Object;
		// STATIC UTY
		public static var _s						:String;
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function FBMan						(listener:Object, appId:String, permissions:String) {
			Debug.debug						(_debugPrefix, "Instantiated with listener", listener);
			_listener							= listener;
			initOAuth							(appId, permissions);
		}
// LOGIN ///////////////////////////////////////////////////////////////////////////////////////
		public function initOAuth					(appId:String, permissions:String):void {
			_appId							= appId;
			_facebook							= new FacebookOAuthGraph(this);
			_facebook.clientId 					= _appId;
			_facebook.redirectURI 					= _callbackUri;
			_facebook.scope 						= permissions;
			Debug.debug						(_debugPrefix, "Permissions requested:",_facebook.scope );
			_facebook.useSecuredPath 				= true;
			_facebook.addEventListener				(FacebookOAuthGraphEvent.AUTHORIZED, onAuthorized);
// 			_facebook.addEventListener				(FacebookOAuthGraphEvent.ERROR, onError);
		}
			public function onAuthorized				(event:FacebookOAuthGraphEvent):void {
				_loggedUserData					= event.data;
				Debug.debug					(_debugPrefix, "Login Successful. User id:",_loggedUserData.id);
				UCode.callMethod				(_listener, "onUserLogged", _loggedUserData, _facebook.token);
			}
			public function onError					(event:FacebookOAuthGraphEvent):void {
				Debug.debug					(_debugPrefix, "ERROR ERROR");
				if (_status == "AUTOLOGIN") {
					Debug.debug				(_debugPrefix, "Auto Login not successful, trying login.");
					login						();
				}
				UCode.callMethod				(_listener, "onFacebookError");
			}
// USER ///////////////////////////////////////////////////////////////////////////////////////
		public function getUserInfo					(id:String="me", callback:Function=null):void {
			callData							(id, callback);
		}
		public function getUserPhotoUrl				(id:String="me"):String {
			return							_fbGraphApi + id + "/picture";
		}
// PAGE ///////////////////////////////////////////////////////////////////////////////////////
		// Anything, firsta call set page
		public function setPage					(id:String):void {
			_pageId							= id;
		}
		public function getPageData					(callback:Function):void {
			callData							(_pageId, callback);
		}
		public function getPageFeed					(callback:Function):void {
			callData							(_pageId + "/feed", callback);
		}
		public function sendPageFeed				(callback:Function, txt:String):void {
			sendData							(_pageId + "/feed", callback, {message:txt});
		}
// GENERAL CALLS ///////////////////////////////////////////////////////////////////////////////////////
		public function sendData					(u:String, callback:Function=null, d:Object=null):void {
			_lastCallback						= callback;
			var uv							:URLVariables = new URLVariables();
			for (_s in d)						uv[_s] = d[_s];
			var l								:URLLoader = _facebook.call(u, uv, URLRequestMethod.POST);
			l.addEventListener					(FacebookOAuthGraphEvent.ERROR, onSendDataError);
			l.addEventListener					(FacebookOAuthGraphEvent.DATA, onSendDataSuccess);
		}
			public function onSendDataSuccess		(e:FacebookOAuthGraphEvent):void {
				Debug.debug					(_debugPrefix, "Data sent succesfully");
				if (_lastCallback)					_lastCallback(e.data);
				else							UCode.callMethod(_listener, "onDataSent", e.data);
			}
			public function onSendDataError			(e:FacebookOAuthGraphEvent):void {
				Debug.debug						(_debugPrefix, "Send data ERROR");
			}
		public function callData					(u:String, callback:Function=null, d:Object=null):void {
			call								(u, callback, d, false);
		}
		public function callBinary					(u:String, callback:Function=null, d:Object=null):void {
			// TODO - CALL BINARY ANCORA DA DEFINIRE. IL CODICE INIZIALE FA SCHIFO
			call								(u, callback, d, true);
		}
		private function call						(u:String, callback:Function=null, d:Object=null, binary:Boolean=false):void {
			_lastCallback						= callback;
			var l								:URLLoader = _facebook.call(u);
			l.dataFormat 						= binary ? URLLoaderDataFormat.BINARY : URLLoaderDataFormat.TEXT;
			l.addEventListener					(FacebookOAuthGraphEvent.ERROR, onDataError);
			l.addEventListener					(FacebookOAuthGraphEvent.DATA, binary ? onBinaryReceived : onDataReceived);
		}
			public function onDataError				(e:FacebookOAuthGraphEvent):void {
				Debug.debug					(_debugPrefix, "DATA ERROR", e);
				UCode.callMethod				(_listener, "onFacebookError");
			}
			public function onDataReceived			(e:FacebookOAuthGraphEvent):void {
				if (_lastCallback)					_lastCallback(e.data);
				else							UCode.callMethod(_listener, "onDataReceived", e.data);
			}
			public function onBinaryReceived			(e:FacebookOAuthGraphEvent):void {
			}
// LOGIN //////////////////////////////////////////////////////////////////////////////////////
		public function autoLogin					():void { // This works ONLY online, if I am already logged in
			_status							= "AUTOLOGIN";
			Debug.debug						(_debugPrefix, "Trying autologin...");
			_facebook.autoConnect				(UGlobal.root.loaderInfo.parameters);
		}
		public function login						():void {
			Debug.debug						(_debugPrefix, "logging in...");
			_facebook.connect					();
		}
		public function loginLocalDebug				(token:String=null):void { // If I am not on the server I need to try this connections
			Debug.debug						(_debugPrefix, "Performing debug login with token:",token);
			_status							= "AUTOLOGIN";
			_facebook.autoConnect				({session:JSON.encode({access_token:token ? token : _token})});
		}
		public function logout						():void {
			Debug.debug						(_debugPrefix, "logout...");
		}
// SINGLE METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function getItemData					(id:String, callback:Function, fields:Array=null):void {
			_lastCallback						= callback;
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
}