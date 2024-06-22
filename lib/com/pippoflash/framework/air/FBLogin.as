/* FBLogin - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
 Performs login on facebook.
*/

package com.pippoflash.framework.air {

// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import com.pippoflash.utils.*; import com.pippoflash.framework.*; import com.pippoflash.motion.Animator; // PippoFlash
	import flash.display.*; import flash.events.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*; import flash.geom.*; import flash.external.*;// FLash
	import flash.html.*; import flash.media.StageWebView; // AIR
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public class FBLogin extends _PippoFlashBase {
	// VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		public static var FORCE_STAGE_WEB_VIEW		:Boolean = true;
		public static var LOAD_PAGE_TIMEOUT			:uint = 20; // Seconds to timeout on first facebook login page access
		public static var _verbose					:Boolean = true;
		public static var _oldUrl					:String = "http://www.facebook.com/login.php?api_key=[APIKEY]&next=[SUCCESS]&cancel_url=[FAILURE]&display=popup&session_key_only=true&fbconnect=true&req_perms=read_stream,publish_stream,read_mailbox,offline_access&connect_display=popup&nochrome=true&return_session=true&v=1.0";
		public static var _newUrl					:String = "https://www.facebook.com/dialog/oauth?client_id=[APPID]&redirect_uri=[FEEDBACK]&display=popup&scope=[SCOPE]&response_type=token";
		public static var _useOldLogin				:Boolean = false; // Old login is kind of better, because it has much less graphics
		// New login instance vars
		public var _feedbackUrl						:String = "https://www.facebook.com/connect/login_success.html"; // this is for new login
		public var _appId							:String = "190270390990832"; // New login system
		public var _scope						:String = "read_stream,publish_stream,read_mailbox,offline_access,email";
		// Old login instance vars
		public var _apiKey						:String = "904357cca54ff30aa4d1b59253a6975e"; // Old login system
		public var _successUrl						:String = "http://www.facebook.com/connect/login_success.html"; // Old login
		public var _failureUrl						:String = "http://www.facebook.com/connect/login_failure.html"; // Old login
		// REFERENCES
		private var _html							:HTMLLoader;
		private var _stageWebView					:StageWebView;
		private var _listener						:*;
		private static var _instance					:FBLogin;
		// MARKERS
		private var _isHtml						:Boolean;
		private var _active						:Boolean;
		private var _loginPageAccess					:Boolean; // This marks if I am waiting for the FIRST access to FB login page, in order to trigger a timeout
		// UTY
		private static var _s						:String;
		private static var _h						:HTMLLoader;
		private static var _j						:*;
	// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		public static function login					(listener:*, par:Object=null):FBLogin {
			_j								= new FBLogin(listener, par);
			_j.login							();
			return							_instance;
		}
	// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function FBLogin						(listener:*, par:Object=null):void {
			super							("FBLogin");
			UCode.setParameters					(this, par);
			if (_instance)						Debug.error(_debugPrefix, "Another instance of FBLogin is already active!!! Cannot instantiate twice!!!");
// 			init								();
			addListener							(listener);
			_listener							= listener;
			_instance							= this;
			Debug.debug						(_debugPrefix, "Initiated on " + listener, Debug.object(par));
		}
		public function init						():void {
			if (HTMLLoader.isSupported && !FORCE_STAGE_WEB_VIEW) {
				_html							= new HTMLLoader();
				_html.paintsDefaultBackground		= true;
				_html.useCache					= false;
				_html.cacheAsBitmap				= false;
				_isHtml						= true;
			}
			else if (StageWebView.isSupported) {
				_stageWebView					= new StageWebView();
				_isHtml						= false;
			}
			UGlobal.addResizeListener				(onResize);
			activateEvents						();
			onResize							();
		}
	// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function login						():void {
			init								();
			var fbUrl							:URLRequest = _useOldLogin ? getOldLoadUrl() : getNewLoadUrl();
			Debug.debug						(_debugPrefix, "Connecting to Facebook: ",fbUrl.url);
			if (_isHtml) {
				UGlobal.stage.addChild				(_html);
				_html.load						(fbUrl);
			}
			else {
				_stageWebView.loadURL			(fbUrl.url); 
				_stageWebView.viewPort			= UGlobal.getStageRect();
// 				_stageWebView.stage				= UGlobal.stage;
			}
// 			_mainApp.setMainLoader				(true, "connecting to facebook");
// 			_html.visible						= false;
// 			_html.alpha							= 0;
			_loginPageAccess						= true; // I am accessing FB for the first time
			_active							= true;
			// Here I have to start a connection timeout
			UExec.time						(LOAD_PAGE_TIMEOUT, onFbLoginPageAccessTimeout);
		}
			private function getOldLoadUrl			():URLRequest {
				return						new URLRequest(UText.insertParams(_oldUrl, {APIKEY:_apiKey, SUCCESS:_successUrl, FAILURE:_failureUrl}));
			}
			private function getNewLoadUrl			():URLRequest {
				return						new URLRequest(UText.insertParams(_newUrl, {APPID:_appId, FEEDBACK:_feedbackUrl, SCOPE:_scope}));
			}
			private function onFbLoginPageAccessTimeout	():void { // Called when timeout is reached on first login
				if (_loginPageAccess) {
					stopLogin					();
					harakiri					();
					broadcastEvent				("onFacebookTimeout");
					_loginPageAccess				= false;
				}
			}
		public function stopLogin					():void { // Stops all operations
			if (_isHtml) {
				_html.cancelLoad					();					
			}
			else {
				_stageWebView.stop				();
			}
		}
		public function harakiri						():void {
			removeEvents						();
			if (_isHtml) {
				UDisplay.removeClip				(_html);
				_html.visible					= false;
			}
			else {
				_stageWebView.stage				= null;
				_stageWebView.dispose			();
			}
			_stageWebView						= null;
			_html								= null;
			_active							= false;
			_loginPageAccess						= false;
		}
	// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function activateEvents				():void {
			if (_isHtml) {
				_html.addEventListener				(Event.COMPLETE, onHtmlEvent, false, 0, true);
				_html.addEventListener				(Event.LOCATION_CHANGE, onHtmlEvent, false, 0, true);
			}
			else {
				_stageWebView.addEventListener		(Event.COMPLETE, onHtmlEvent, false, 0, true);
				_stageWebView.addEventListener		(ErrorEvent.ERROR, onHtmlEvent, false, 0, true);
				_stageWebView.addEventListener		(LocationChangeEvent.LOCATION_CHANGE, onHtmlEvent, false, 0, true);
				_stageWebView.addEventListener		(LocationChangeEvent.LOCATION_CHANGING, onHtmlEvent, false, 0, true);
			}
		}
		private function removeEvents				():void {
			if (_isHtml) {
				_html.removeEventListener			(Event.COMPLETE, onHtmlEvent);
				_html.removeEventListener			(Event.LOCATION_CHANGE, onHtmlEvent);
				_html.visible					= false;
			}
			else {
				_stageWebView.removeEventListener	(Event.COMPLETE, onHtmlEvent);
				_stageWebView.removeEventListener	(ErrorEvent.ERROR, onHtmlEvent);
				_stageWebView.removeEventListener	(LocationChangeEvent.LOCATION_CHANGE, onHtmlEvent);
				_stageWebView.removeEventListener	(LocationChangeEvent.LOCATION_CHANGING, onHtmlEvent);
			}
		}
		public function onHtmlEvent					(e:Event):void {
			Debug.debug						(_debugPrefix, "Html event received:",e);
			if (e.type == "complete") { // Here I analyze the content
				_loginPageAccess					= false; // Something happened as event, block the first login thing
				_mainApp.setMainLoader			(false);
				Debug.debug					(_debugPrefix, "Received url",e.target.location);
				if (_isHtml) {
					if (!_html.visible)				Animator.fadeInTotal(_html);
				}
				else {
					if (!_stageWebView.stage)		_stageWebView.stage = UGlobal.stage;
				}
				// Check login
				if (_useOldLogin) { // Old login style checks
					if (e.target.location.indexOf(_successUrl) == 0) onLoginOk("retrieve code here!!!");
					else if (e.target.location.indexOf(_failureUrl) == 0) onLoginError();
				}
				else { // New login style checks
					// Success url: http://www.facebook.com/connect/login_success.html#access_token=190270390990832%7C5c92c6caa500cc6ce2856ba1-769037268%7CKihfDY3FWGTqRQIfkQlzaNnKS8s&expires_in=0
					// Error url: http://www.facebook.com/connect/login_success.html?error=sdfads
					if (e.target.location.indexOf(_feedbackUrl) == 0) { // This is a facebook feedback, and not internal navigation
						if (e.target.location.indexOf("error") > -1) { // Error
							var uu			:URLVariables = new URLVariables(e.target.location.split("?")[1]); // Error variables are split with a "?"
							Debug.debug		(_debugPrefix, "Facebook login error:",uu.error_description);
							onLoginError		(uu.error_description);
						}
						else { // Success
							var uu			:URLVariables = new URLVariables(e.target.location.split("#")[1]); // Success variables are split with a "#"
							Debug.debug		(_debugPrefix, "Facebook login OK!");
							onLoginOk			(uu.access_token);
						}
					}
					
				}
			}
		}
			private function onLoginOk				(code:String):void {
				Debug.debug					(_debugPrefix, "Login Ok, code:",code);
				broadcastEvent					("onFacebookLoginOk", code);
				harakiri						();
			}
			private function onLoginError				(error:String="Facebook Login Error"):void {
				Debug.debug					(_debugPrefix, "Login error:",error);
				broadcastEvent					("onFacebookLoginError", error);
				harakiri						();
			}
		public function onResize					():void {
			if (!_active)						return;
			if (_isHtml) {
				_html.width						= UGlobal._sw;
				_html.height					= UGlobal._sh;
			}
			else {
				_stageWebView.viewPort			= UGlobal.getStageRect();
			}
		}
	}
}
