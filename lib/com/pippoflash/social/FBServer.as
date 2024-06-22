// SERVER CLASS //////////////////////////////////////////////////////////////////////////////////////
// _executing._status = IDLE, EXECUTING, ERROR, COMPLETE
package com.pippoflash.social {
// 	import flash.net.URLVariables;
// 	import flash.system.Security;
	import com.pippoflash.net.Server;
// 	import com.pippoflash.net.QuickLoader;
// 	import com.pippoflash.net.SimpleQueueLoaderObject;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.Debug;
// 	import com.pippoflash.utils.UText;
// 	import com.pippoflash.utils.UMem;
// 	import com.pippoflash.utils.UXml;
	import com.adobe.serialization.json.JSON;
	import com.pippoflash.social.FBMan;

	public dynamic class FBServer extends Server {
// VARIABLES ////////////////////////////////////////////////////////////////////////////////////
		// CONSTANTS ///////////////////////////////////////////////////////
		private static var _facebookApi			:String = "http://graph.facebook.com/[id]";
		private static var _facebookLoggedApi		:String = "https://graph.facebook.com/[id]";
		// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		public var _FBMan					:FBMan;
		// USER DEFINED /////////////////////////////////////////////////////////
		public var _debugToken				:String = "142815229063883|335282117d68709f9c765a17-769037268|b9BE58d72E1VBeZGnnKig5Vykc8.";
		// FLASHVARS ///////////////////////////////////////////////////////
		// DATA HOLDERS //////////////////////////////////////////////////////////
		private var _loggedUserData				:Object;
		private var _sessionToken				:String;
		// MARKERS //////////////////////////////////////////////////////////////
		private var _isFBAppSetup				:Boolean;
		private var _isLogged					:Boolean;
		// REFERENCES //////////////////////////////////////////////////////
		// COMMAND MANAGEMENT ////////////////////////////////////////////
		// STATIC UTY
// INIT ////////////////////////////////////////////////////////////////////////////////////////
		public function FBServer				(listener:*):void { // Here it creates a server instance connected to an API only
			super						(listener, _facebookApi);
			_debugPrefix					= "FBServer";
		}
// SETUP METHODS //////////////////////////////////////////////////////////////////////////
		public function setAppId				(id:String, permissions:String="publish_stream,read_stream,user_photos,user_photo_video_tags,user_likes"):void { // Setup facebook application ID
			_FBMan						= new FBMan(this, id, permissions);
			_isFBAppSetup					= true;
			login							= _FBMan.login;
		}
// FACEBOOK METHODS ///////////////////////////////////////////////////////////////////////
		public var login						:Function;
		public function autoLogin				():void {
			if (UGlobal.isLocal()) {
				_FBMan.loginLocalDebug		(_debugToken);
			}
			else							_FBMan.autoLogin();
		}
// FBMAn LISTENERS /////////////////////////////////////////////////////////////////
		// These listeners apply for all, login or other operations
		public function onUserLogged			(o:Object, token:String):void {
			_isLogged						= true;
			_loggedUserData					= o;
			_sessionToken					= token;
			Debug.debug					(_debugPrefix, "Successfully logged into FACEBOOK.");
			UCode.callMethod				(_listener, "onUserLogged", _loggedUserData);
		}
		public function onFacebookError			():void {
			Debug.debug					(_debugPrefix, "FACEBOOK ERROR.");
			UCode.callMethod				(_listener, "onFacebookError");
		}
// DO LAUNCH SERVER CALL ////////////////////////////////////////////////////////////////////
// CALL STANDARD COMMAND //////////////////////////////////////////////////////////////////////
// POST-PROCESS FEEDBACK ///////////////////////////////////////////////////////////////////////////////////////
// ANLYSIS UTY ///////////////////////////////////////////////////////////////////////////////////////
		// this functions here prepare the feedback object according to the type of encoding
				public function analyzeFeedback_FACEBOOKGRAPHGET():void {
					_executing._feedback		= {_data:{}};
					try { // Just convert and check if its a decode error
						var o				:Object = JSON.decode(_executing._loaderObject.getContent());
						_executing._feedback	= {success:true, data:o};
						_executing._feedback._data = o;
						// Check for facebook errors
						if (o.error) { // Its a facebook error
							_executing._feedback = {success:false, data:o, message:{type:"error", text:o.error.message}};
						}
						else {
							formatGeneralFacebookFeedback();
						}
					}
					catch (e) { // JSON unparsable
						_executing._feedback	= _jsonDecodeError;
					}
					// Check for message and errors
					_executing._error			= !UCode.isTrue(_executing._feedback.success);
					if (_executing._feedback.message) {
						_executing._message	= _executing._feedback.message.text ? _executing._feedback.message.text : "Message malformed: " + _executing._feedback.message;
						_executing._messageType = _executing._feedback.message.type ? _executing._feedback.message.type : "alert";
					}
				}
					private function formatGeneralFacebookFeedback():void {
						// This performs general optimizations in facebook output
						
					}
				public function analyzeFeedback_FACEBOOKGRAPHCOMMENTS():void {
					analyzeFeedback_FACEBOOKGRAPHGET(); // Generally check feedback for facebook answer, then format all comments
					// Create empty comments array if comments are not there
// 					if (!_executing._feedback._data) _executing._feedback._data = [];
					// Create standard comments parameters
					_executing._feedback._data._list = [];
					for each (_o in _executing._feedback._data.data) {
						_executing._feedback._data._list.push(_o);
					}
				}
// COMMANDS FEEDBACK LISTENERS //////////////////////////////////////////////////////////////////
// NON-STANDARD COMMANDS ///////////////////////////////////////////////////////////////
		public function getAllData				(id:String, par:Object):void {
			// It works like any other command, just it needs the item id first
			Debug.debug					(_debugPrefix, "getAllData()");
			processParamsObject				(par, id);
			sendCommand					(par);
		}
		public function getFeed				(id:String, par:Object):void {
			Debug.debug					(_debugPrefix, "getFeed()");
			processParamsObject				(par, id+"/feed");
			par._format						= "FACEBOOKGRAPHCOMMENTS";
			sendCommand					(par);
		}
		public function getComments				(id:String, par:Object):void {
			// This is good for ALBUMs, PHOTOS, pretty much anything which has the "comments" array - NOT PAGES OR PROFILES
			Debug.debug					(_debugPrefix, "getComments()");
			processParamsObject				(par, id+"/comments");
			par._format						= "FACEBOOKGRAPHCOMMENTS";
			sendCommand					(par);
		}
		public function postComment				(id:String, comment:String, par:Object):void {
			Debug.debug					(_debugPrefix, "postComment()");
			processParamsObject				(par, id+"/comments");
			par._paramsPost					= {message:comment};
			sendCommand					(par);
		}
		public function postFeed				(id:String, feed:String, par:Object):void {
			Debug.debug					(_debugPrefix, "postFeed()");
			processParamsObject				(par, id+"/feed");
			par._paramsPost					= {message:feed};
			sendCommand					(par);
		}
		public function shareLink				(id:String, link:String, par:Object):void {
			Debug.debug					(_debugPrefix, "shareLink()");
			processParamsObject				(par, id+"/feed");
			par._paramsPost					= {link:link};
			sendCommand					(par);
		}
			private function processParamsObject	(par:Object, id:String):void {
				par._paramsUrl				= {id:id};
				par._paramsGet 				= {metadata:true, limit:99999999};
				par._format					= "FACEBOOKGRAPHGET";
				// Here I use 2 different methods and urls, one if user i logged, one if its not logged
				if (_isLogged) {
					_api					= _facebookLoggedApi;
					par._paramsGet.access_token = _sessionToken;
				}
				else {
					_api					= _facebookApi;
				}
			}
// UTY /////////////////////////////////////////////////////////////////////////////////
		public function getProfileThumbUrl			(id:String):String {
			return						"http://graph.facebook.com/"+id+"/picture";
		}
// CHECK FOR STATUSES ////////////////////////////////////////////////////////////////////
// GET URLS //////////////////////////////////////////////////////////////////////////////
// CONFIG MANAGEMENT //////////////////////////////////////////////////////////////////////
	}
}
