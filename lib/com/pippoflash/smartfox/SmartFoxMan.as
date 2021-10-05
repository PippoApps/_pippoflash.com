/* SmartFoxMan - 0.01 - PippoFlash.com
onAdminMessage : String
Dispatched when a message from the Administrator is received.
onBuddyList : String
Dispatched when the buddy list for the current user is received or a buddy is added/removed.
onBuddyListError : String
Dispatched when an error occurs while loading the buddy list.
onBuddyListUpdate : String
Dispatched when the status or variables of a buddy in the buddy list change.
onBuddyPermissionRequest : String
Dispatched when the current user receives a request to be added to the buddy list of another user.
onBuddyRoom : String
Dispatched in response to a SmartFoxClient.getBuddyRoom request.
onConfigLoadFailure : String
Dispatched when an error occurs while loading the external SmartFoxClient configuration file.
onConfigLoadSuccess : String
Dispatched when the external SmartFoxClient configuration file has been loaded successfully.
onConnection : String
Dispatched in response to the SmartFoxClient.connect request.
onConnectionLost : String
Dispatched when the connection with SmartFoxServer is closed (either from the client or from the server).
onCreateRoomError : String
Dispatched when an error occurs during the creation of a room.
onDebugMessage : String
Dispatched when a debug message is traced by the SmartFoxServer API.
onExtensionResponse : String
Dispatched when a command/response from a server-side extension is received.
onJoinRoom : String
Dispatched when a room is joined successfully.
onJoinRoomError : String
Dispatched when an error occurs while joining a room.
onLogin : String
Dispatched when the login to a SmartFoxServer zone has been attempted.
onLogout : String
Dispatched when the user logs out successfully.
onModeratorMessage : String
Dispatched when a message from a Moderator is received.
onObjectReceived : String
Dispatched when an Actionscript object is received.
onPlayerSwitched : String
Dispatched in response to the SmartFoxClient.switchPlayer request.
onPrivateMessage : String
Dispatched when a private chat message is received.
onPublicMessage : String
Dispatched when a public chat message is received.
onRandomKey : String
Dispatched in response to a SmartFoxClient.getRandomKey request.
onRoomAdded : String
Dispatched when a new room is created in the zone where the user is currently logged in.
onRoomDeleted : String
Dispatched when a room is removed from the zone where the user is currently logged in.
onRoomLeft : String
Dispatched when a room is left in multi-room mode, in response to a SmartFoxClient.leaveRoom request.
onRoomListUpdate : String
Dispatched when the list of rooms available in the current zone is received.
onRoomVariablesUpdate : String
Dispatched when Room Variables are updated.
onRoundTripResponse : String
Dispatched when a response to the SmartFoxClient.roundTripBench request is received.
onSpectatorSwitched : String
Dispatched in response to the SmartFoxClient.switchSpectator request.
onUserCountChange : String
Dispatched when the number of users and/or spectators changes in a room within the current zone.
onUserEnterRoom : String
Dispatched when another user joins the current room.
onUserLeaveRoom : String
Dispatched when a user leaves the current room.
onUserVariablesUpdate : String
Dispatched when a user in the current room updates his/her User Variables.
*/
package com.pippoflash.smartfox {
	import flash.net.URLVariables;
	import flash.system.Security;
	import com.pippoflash.utils.*;
	import com.pippoflash.framework._PippoFlashBase;
	import com.adobe.crypto.MD5;
	import it.gotoandplay.smartfoxserver.*;
	import it.gotoandplay.smartfoxserver.data.*;
	import flash.events.*;
	
	public dynamic class SmartFoxMan extends _PippoFlashBase {
// VARIABLES ////////////////////////////////////////////////////////////////////////////////////
	// STATIC SWITCHES ///////////////////////////////////////////////////////////////////////////////////////
		public static var _verbose				:Boolean = true; // Traces my messages
		public static var _debugServer			:Boolean = false; // Traces some internal smartfox messages
		public static var _autoLogin				:Boolean = true; // ?
		public static var _autoJoin				:Boolean = false; // ?
		public static var _mainExt				:String = "MainExt"; // Name of the main zone extension
// 		public static var _roomExt				:String = "RoomExt"; // Name of the main room extension
		public static var _key					:*;
		public static var _useCustomLogin			:Boolean = true; // If set to false, no key, no hash, just send plain clear stuff
// 		public static var _hashPassword			:Boolean = true;
	// STATIC CONSTANTS
		private static const INFO_CLIENT_PROPERTIES	:Array = ["smartConnect","httpPort","httpPollSpeed","blueBoxIpAddress","blueBoxPort"];
// 		private static var NETWORK_OPEN_STATUSES	:Array = ["CONNECT","DISCONNECT","LOGIN","JOIN"]; // List of statuses that broadcast a network open
// 		private static var NETWORK_CLOSE_STATUSES:Array = ["CONNECTED","DISCONNECTED","LOGGED","JOINED"]; // List of statuses that broadcast a network close
		public static var _smartfoxActiveEvents 		= { // These are the events that will be listened to
			onAdminMessage:true,				// These are main SmartFox events, they have not to ba overridden with custom events
			onBuddyList:true,
			onBuddyListError:true,
			onBuddyListUpdate:true,
			onBuddyPermissionRequest:true,
			onBuddyRoom:false,
			onConfigLoadFailure:false,
			onConfigLoadSuccess:false,
			onConnection:true,
			onConnectionLost:true,
			onCreateRoomError:false,
			onDebugMessage:false,
			onExtensionResponse:true,
			onJoinRoom:true,
			onJoinRoomError:true,
			onLogin:true,
			onLogout:true,
			onModeratorMessage:true,
			onObjectReceived:false,
			onPlayerSwitched:false,
			onPrivateMessage:true,
			onPublicMessage:true,
			onRandomKey:true,
			onRoomAdded:true,
			onRoomDeleted:true,
			onRoomLeft:true, 					// Dispatched when a room is left in multi-room mode, in response to a SmartFoxClient.leaveRoom request.
			onRoomListUpdate:true,
			onRoomVariablesUpdate:true,
			onRoundTripResponse:true,
			onSpectatorSwitched:false,
			onUserCountChange:true,
			onUserEnterRoom:true,
			onUserLeaveRoom:true,
			onUserVariablesUpdate:true
		}
	// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		private static var _debugPrefix			:String = "SmartFoxMan";
		private static var CLEAR_PASSWORD_SEPARATOR:String = "[|||]";
// 		private var _status					:String = "IDLE"; // IDLE, CONNECT, CONNECTED, DISCONNECT, DISCONNECTED, LOGIN, LOGGED, JOIN, JOINED
		public var _smartfox					:SmartFoxClient;
		public var _server					:SmartFoxClient;
	// SMARTOFX ///////////////////////////////////////////////////////
		private var _defaultZone				:String = "CardGamesZone";
		private var _mainLobbyName			:String = "MainLobby"; // This is used to recognize if I have joined main lobby. It can be set with: setMainLobbyName()
		private var _loginAsGuest				:Boolean; // If this is true (set with setGuest(true)) smartfox will login as a guest
		private var _defaultUser				:String;
		private var _defaultPassword			:String; // If this is set, password will be hashed before sending
		private var _hashedPassword			:String; // If this is set, this is used (without hashing), not regular password
		private var _clearPassword			:String; // If this is defined, key and password are sent separated by the string CLEAR_PASSWORD_SEPARATOR but clear
		private var _sentPassword				:String; // This stores the final password sent to system
		private var _ip						:String = "127.0.0.1";
		private var _port					:uint = 9339;
		private var _firstJoin					:Boolean; // Marks if the user joined a room for the first time. On each login this is reset to true. On first join, I broadcast onSmartFoxFirstJoin.
	// SMARTFOX DEFINED ///////////////////////////////////////////////////////// - These hold data received from server
		private var _roomList					:Array;
		private var _joinedRoom				:Room;
		private var _mainLobby				:Room;
		private var _connected				:Boolean = false;
		private var _logged					:Boolean = false;
		private var _buddyList				:Array = []; 
		private var _buddyListByName			:Object = {};
		private var _roomVariablesArray		:Array; // Stores the original array retrieved from room getVariables()
		private var _roomVariables			:Object; // Stores the variables of the joined room as a hash key:value
		private var _roomMainExtension			:String = "RoomExt"; // Stores the name of extension defined in room variable "_mainExtName"
	// METHODS STORAGE ///////////////////////////////////////////////////////
		private var _promptConfirm			= {}; // Stores data for prompt confirm - onUserConfirm
		private var _promptOk				= {}; // Stores data for simple prompt - onUserPrompt
		public var _configPromptData;			// Contains a special key for prompts when SFS calls onConfigPrompt
	// PIPPOFLASH FRAMEWORK //////////////////////////////////////////////////////////
		private var _rooms					:PFRooms = new PFRooms();
		// MARKERS //////////////////////////////////////////////////////////////
		// REFERENCES //////////////////////////////////////////////////////
		// COMMAND MANAGEMENT ////////////////////////////////////////////
		// STATIC UTY
		protected static var _x				:XML;
		protected static var _counter			:int;
		protected static var _o				:Object;
		protected static var _a				:Array;
		protected static var _n				:Number;
		protected static var _s				:String;
		protected static var _i				:int;
		protected static var _room				:Room;
// INIT ////////////////////////////////////////////////////////////////////////////////////////
		public function SmartFoxMan			(ip:String=null, port:*=null, zone:String=null):void { // Here it creates a server instance connected to an API only
			super						("SmartFoxMan");
			reset							();
			setNetwork					(ip, port, zone);
			_smartfox						= new SmartFoxClient(_debugServer);
			_server						= _smartfox;
			_rooms.init					(this);
			setupAllListeners				();
			// Here I try to activate the bluebox IP address
			_smartfox.blueBoxIpAddress			= ip;
			_smartfox.httpPollSpeed			= 1000;
			// Here I trace inofrmations about smartfox
			for each (_s in INFO_CLIENT_PROPERTIES) Debug.debug(_debugPrefix, "SmartFox."+_s+" = "+_smartfox[_s]);
		}
			private function setupAllListeners		():void { // Setups all listeners according to active listeners list
				for (_s in _smartfoxActiveEvents) {
					if (_smartfoxActiveEvents[_s]) {
						_smartfox.addEventListener(SFSEvent[_s], onSmartfoxEvent);
					}
				}
				_smartfox.addEventListener		(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				_smartfox.addEventListener		(IOErrorEvent.IO_ERROR, onIOError);
			}
// SETUP PAMARETERS METHODS  ///////////////////////////////////////////////////////////////////////////////////////
		public function setHashedPassword		(s:String):void { // If this is set, password is not hashed
			_hashedPassword					= s;
			_defaultPassword = _clearPassword	= null;
		}
		public function setClearPassword			(s:String):void { // If this is set, password is sent clear
			_clearPassword					= s;
			_defaultPassword = _hashedPassword	= null;
		}
		public function setPassword				(s:String):void { // If this is set, password IS hashed
			_defaultPassword					= s;
			_hashedPassword	= _clearPassword	= null;
		}
		public function setUsername				(s:String):void {
			_defaultUser					= s;
		}
		public function setGuest				(b:Boolean):void {
			_loginAsGuest					= b;
		}
		public function setKey					(key:String):void { // Needed to skip key rendering from server, and used to bypass hashing of password
			_key							= key; 
		}
		public function useCustomLogin			(ucl:Boolean):void { // If set to false, password is NOT received by server
			// Also, key is not asked.
			_useCustomLogin					= ucl;
		}
// 		public function hashPassword			(b:Boolean):void { // If set to true, password is not hashed, but key is retrieved
// 			// passwoprd is sent clear to server
// 			_hashPassword					= b;
// 		}
		public function isGuest					():Boolean {
			return						_loginAsGuest;
		}
		public function setNetwork				(ip:String=null, port:*=null, zone:String=null):void {
			if (ip)						_ip = ip;
			if (port)						_port = uint(port);
			if (zone)						_defaultZone = zone;
		}
		public function setMainLobbyName		(n:String):void {
			_mainLobbyName				= n;
		}
// SFS METHODS //////////////////////////////////////////////////////////////////////////
	// MAIN METHODS
		public function reset					():void {
			if (_connected)					disconnect();
			_connected					= false;
			_logged						= false;
			_roomList						= null;
			_buddyList						= [];
			_buddyListByName				= {};
			resetRoom						();
			broadcastNetworkClose				();
		}
		public function resetRoom				():void {
			_joinedRoom					= null;
			_roomVariablesArray				= null;
			_roomVariables					= null;
// 			_roomMainExtension				= null;
		}
	// CONNECT AND LOGIN
		public function connect				(ip:String=null, port:*=null, zone:String=null):void {
// 			setStatus						("CONNECT");
			_connected					= false;
			_key							= null;
			setGuest						(false);
			setNetwork						(ip, port, zone);
			Debug.debug					(_debugPrefix, "Connecting to",_ip+":"+_port,"zone:"+_defaultZone);
			_smartfox.connect				(_ip, _port);
			broadcastNetworkOpen				();
		}
		public function connectAsGuest			(ip:String=null, port:*=null, zone:String=null):void {
			connect						(ip, port, zone);
			setGuest						(true);
		}
		public function disconnect				():void {
// 			setStatus						("DISCONNECT");
			_connected					= false;
			try {
				_smartfox.disconnect			();
			}
			catch (e) {
				Debug.error				(_debugPrefix, "ERROR in disconnect()",e);
			};
		}
		public function login					():void {
// 			setStatus						("LOGIN");
			broadcastNetworkOpen				();
			_firstJoin						= true;
			if (_useCustomLogin && _key)	onEvent_onRandomKey({key:_key}); // Simulate event if key is already taken. On second request of key server doe nothing!
			else if (_useCustomLogin)			_smartfox.getRandomKey();
			else { // I do not use custom login. How does this work?
				// I set the first password I find
				_sentPassword				= _clearPassword ? _clearPassword : _hashedPassword ? _hashedPassword : _defaultPassword;
				doLogin					();
			}
		}
			private function doLogin			():void {
				if (_loginAsGuest) { // Set correct username to log as guest
					_defaultUser			= "guest";
				}
				Debug.debug				(_debugPrefix, "Logging user in zone:",_defaultZone,_loginAsGuest?"GUEST":"NORMAL", _defaultUser, _sentPassword);
				_smartfox.login				(_defaultZone, _defaultUser, _sentPassword);
			}
		public function refreshRoomsList			():void {
			broadcastNetworkOpen				();
			_smartfox.getRoomList				();
		}
		public function autoJoin				():void {
			if (isJoined())					return; // No need to autojoin if I am already joined in a room...
			Debug.debug					(_debugPrefix, "Auto joining default room.");
			_smartfox.autoJoin				();
		}
		public function logout					():void {
			_smartfox.logout					();
		}
	// EXTENSIONS COMMUNICATION
		public function sendXtMessage			(ext:String, cmd:String, par:Object=null, type:String="json"):void {
			if (!par)						par = {};
			Debug.debug					(_debugPrefix, "Sending XT msg:",ext,cmd,par is Object ? Debug.object(par) : par);
			_smartfox.sendXtMessage			(ext, cmd, par, type);
		}
		public function sendRoomExtension			(cmd:String, par:*=null, type:String="json"):void { // This communicates with the main extension set in Room variable as "_mainExtName"
			if (_roomMainExtension)			sendXtMessage(_roomMainExtension, cmd, par, type);
		}
		public function sendMainExtension			(cmd:String, par:*=null, type:String="json"):void { // This communicates with the main extension set in class static var "_mainExt"
			sendXtMessage					(_mainExt, cmd, par, type);
		}
	// ROOM MANAGEMENT
		public function joinRoom				(r:*):void {
			leaveAllRooms					();
			if (r is Room) { // Is Room instance
				doJoinRoom					(r);
			}
		}
		public function joinRoomId				(id:uint):void {
			doJoinRoom						(id);
		}
			private function doJoinRoom			(id:uint):void {
// 				setStatus					("JOIN");
				Debug.debug				(_debugPrefix, "Joining room id:",id);
				if (_smartfox.getActiveRoom() && _smartfox.getActiveRoom().getId() == id) {
					Debug.debug			(_debugPrefix, "User is already in this room.");
// 					broadcastNetworkClose		();
					broadcastSmartFoxEvent	("onJoinRoom", true, {room:_joinedRoom});
				}
				else {
					_smartfox.joinRoom		(id);
				}
			}
		public function updateRoomVariables		():Object {
			_roomVariablesArray				= _joinedRoom.getVariables();
			Debug.debug					(_debugPrefix+"-VAR", "Received room variables.");
			_roomVariables					= {};
			for (_s in _roomVariablesArray) {
				Debug.debug				(_debugPrefix+"-VAR", _s,":",_roomVariablesArray[_s]);
				_roomVariables[_s] 			= _roomVariablesArray[_s];
			}
			// Specific variables
			if (_roomVariables._mainExtName)		_roomMainExtension = _roomVariables._mainExtName; // Update main room extension name only if there is a room variable setup
			// Return variables
			return						_roomVariables;
		}
		public function getLoggedRoomVariables		():Object {
			updateRoomVariables				();
			return						_roomVariables;
		}
		public function refreshLoggedRoomVariables	():void {
			_rooms.getRoomByRoom(_joinedRoom).updateRoomVars(getLoggedRoomVariables());
		}
		public function leaveAllRooms			():void {
			_room						= _smartfox.getActiveRoom();
			if (_room)						_smartfox.leaveRoom(_room.getId());
		}
	// BUDDY LIST
		public function loadBuddyList				():void {
			_smartfox.loadBuddyList			();
		}
		public function addBuddy				(userName:String):void { // User object or user name as string is fine
			_smartfox.addBuddy				(userName);				
		}
		public function removeBuddy				(userName:String):void { // User object or user name as string is fine
			_smartfox.removeBuddy			(userName);				
		}
		public function acceptBuddy				(userName:String):void {
			_smartfox.sendBuddyPermissionResponse 	(true, userName) 
		}
		public function refuseBuddy				(userName:String):void {
			_smartfox.sendBuddyPermissionResponse 	(false, userName) 
		}
		public function getBuddyList				():Array {
			return						_buddyList;
		}
		public function getBuddiesNum			():uint {
			return						_buddyList.length;
		}
		public function isBuddy					(user:User):Boolean {
			return						isBuddyName(user.getName());
		}
		public function isBuddyName				(userName:String):Boolean {
			return						Boolean(_smartfox.getBuddyByName(userName));
			//return						_buddyListByName[userName];
		}
	// CHAT
		public function sendPublicMessage			(m:String):void {
			_smartfox.sendPublicMessage			(m);
		}
		public function sendPrivateMessage		(m:String, userId:int, roomId:*=null):void { // Room id should be an integer, but I can't set null for integers...
			_smartfox.sendPrivateMessage		(m, userId);
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function getClient				():SmartFoxClient {
			return						_smartfox;
		}
	// UTY-DEBUG ///////////////////////////////////////////////////////////////////////////////////////
		public function traceRooms				():void {
			for each (_room in _roomList) 		traceRoom(_room);
		}
		public function traceRoom				(r:Room):void {
			Debug.debug					("Room", getRoomString(r));
		}
		public function getRoomString			(r:Room):String {
			return						r.getId()+":"+r.getName()+":"+r.getUserCount();
		}
	// CHECKS ///////////////////////////////////////////////////////////////////////////////////////
		public function isConnected				():Boolean {
			return						_smartfox.isConnected;
		}
		public function isMe					(user:User):Boolean {
			return						user.getId() == _smartfox.myUserId;
		}
		public function isMyName				(s:String):Boolean {
			return						s == _smartfox.myUserName;
		}
		public function isLogged				():Boolean {
			return						_logged;
		}
		public function isJoined				():Boolean {
			return						Boolean(_smartfox.getActiveRoom());
		}
	// PFROOMS ///////////////////////////////////////////////////////////////////////////////////////
		public function getRooms				():PFRooms {
			return						_rooms;
		}
		public function getJoindPFRoom			():PFRoom { // Returns the joined PFRoom if I am joined
			return						_joinedRoom && _joinedRoom.hasOwnProperty("getName") ? _rooms.getRoomByName(_joinedRoom.getName()) : null;
		}
	// SFS ROOMS ///////////////////////////////////////////////////////////////////////////////////////
		public function getActiveRoom			():Room {
			return						_smartfox.getActiveRoom();
		}
		public function getRoomList				():Array {
			return						_roomList;
		}
		public function getJoinedRoom			():Room {
			return						_joinedRoom;
		}
		public function isInMainLobby			():Boolean {
			return						_joinedRoom == _mainLobby;
		}
		public function getJoinedRoomName		():String {
			return						_joinedRoom ? _joinedRoom.getName() : "<No Room Joined>";
		}
		public function get joinedRoom			():Room {
			return						getJoinedRoom();
		}
		public function getMyName				():String {
			return						_smartfox.myUserName;
		}
		public function getMyId				():int {
			return						_smartfox.myUserId;
		}
		public function getMyself				():User { /* TO BE IMPLEMENTED */
			// This should return my user self...???
			return						new Object() as User;
		}
		public function getRoomVariable			(key:String):* { // Returns variables from LOGGED ROOM
			return						_roomVariables[key];
		}
		public function get smartfox				():SmartFoxClient {
			return						_smartfox;
		}
// GENERAL LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onSmartfoxEvent			(e:SFSEvent):void {
			// Debug.debug					(_debugPrefix, e.type,Debug.getObjectString(e.params, true));
			_o							= e.params ? e.params : {};
			if (_o.success || !UCode.exists(_o.success)) { // On successful call - OR FOR CALLS WHICH DO NOT HAVE A SUCCESS STATUS - Some calls do not have a params at all
				UCode.callMethod			(this, "onEvent_"+e.type, _o);
				broadcastEvent				("onSmartFoxEvent", e.type, _o);
				broadcastSmartFoxEvent		(e.type, true, _o);
			} else { // On failure
// 				broadcastNetworkClose			();
				broadcastEvent				("onSmartFoxEvent", e.type, _o);
				broadcastSmartFoxEvent		(e.type, false, _o);
			}
		}
	// EXTENSION RESPONSE ///////////////////////////////////////////////////////////////////////////////////////
			public function onEvent_onExtensionResponse(e:Object):void {
				//Debug.debug				(_debugPrefix, "Extension:",Debug.getObjectString(e.dataObj, true));
				UCode.callMethod			(this, "onEvent_"+e.dataObj.cmd, e.dataObj);
				broadcastSmartFoxEvent		(e.dataObj.cmd, e.dataObj.ok, e.dataObj);
			}
	// INTERNAL SPECIFIC LISTENERS //////////////////////////////////////////////////////////////////////////
		// CONNECTION ///////////////////////////////////////////////////////////////////////////////////
			public function onEvent_onConnection	(e:Object):void {
				Debug.debug				(_debugPrefix, "Connected successfully.");
// 				setStatus					("CONNECTED");	
				_connected				= true;
				if (_autoLogin)				login();
				broadcastNetworkClose			();
			}
			public function onEvent_onConnectionLost(e:Object):void {
				_connected				= false;
			}
		// LOGIN-LOGOUT ///////////////////////////////////////////////////////////////////////////////////
			public function onEvent_onRandomKey	(e:Object):void {
				if (!_loginAsGuest) {
					_key					= e.key;
					Debug.debug			(_debugPrefix, "Key received:",_key);
					if (_defaultPassword) {
						Debug.debug		(_debugPrefix, "Received default password: " + _defaultPassword);
						_sentPassword 		= MD5.hash(_key + _hashedPassword);
					}
					else if (_hashedPassword) {
						Debug.debug		(_debugPrefix, "Received hashed password: " + _hashedPassword);
						_sentPassword		= _hashedPassword;
					}
					else if (_clearPassword) {
						Debug.debug		(_debugPrefix, "Received clear password: " + _clearPassword);
						_sentPassword		= _key + CLEAR_PASSWORD_SEPARATOR + _clearPassword;	
					}
					Debug.debug			(_debugPrefix, "Sent password: " + _sentPassword);
				}
				doLogin					();
			}
			public function onEvent_onLogin		(e:Object):void {
				_logged					= true;
				// Smartfox Client properties are not populated magically when using custom login
				_smartfox.myUserId			= e.data.id;
				_smartfox.myUserName			= e.data.nick;
				_defaultUser				= e.data.nick;
				broadcastNetworkClose			();
				refreshRoomsList				();
			}
			public function onEvent_onLogout		(e:Object=null):void {
				_smartfox.myUserId			= null;
				_smartfox.myUserName			= null;
				_defaultUser				= null;
				_logged					= false;
			}
		// ROOMS ///////////////////////////////////////////////////////////////////////////////////////
			public function onEvent_onRoomListUpdate(e:Object):void {
				_roomList					= e.roomList;
				// Loop in rooms to check variables
				for each (_room in _roomList) {
// 					var roomVars:Array = _room.getVariables()
				}
				// traceRooms					();
				broadcastNetworkClose			();
				if (_autoJoin) 				autoJoin();
// 				prepareMyRoomsList			();
			}
			public function onEvent_onJoinRoom	(e:Object):void {
				_joinedRoom				= e.room;
				Debug.debug				(_debugPrefix, "Joined room:",getRoomString(_joinedRoom));
				updateRoomVariables			();
				broadcastNetworkClose		();
				if (_firstJoin) {
					broadcastSmartFoxEvent	("onFirstJoin", true);
					_firstJoin				= false;
				}
				if (_joinedRoom.getName() == _mainLobbyName) {
					_mainLobby			= _joinedRoom;
					broadcastSmartFoxEvent	("onJoinMainLobby", true);
				}
			}
			public function onEvent_onLeaveRoom	(e:Object):void {
				resetRoom					();
				Debug.debug				(_debugPrefix, "User has left room.");
// 				setStatus					("JOIN");
			}
			public function onEvent_onRoomVariablesUpdate(e:Object):void { // This tells that room variables have been updated, we update them all!
				updateRoomVariables			();
			}
		// BUDDY LIST ///////////////////////////////////////////////////////////////////////////////////////
			public function onEvent_onBuddyList	(e:Object):void {
				// There is a bug in SmartFox, if I remove a buddy, the list arrives with empty slots...
				_buddyList					= [];
				_buddyListByName			= {};
				for each (_o in e.list) {
					if (!_buddyListByName[_o.name]) { // strange bug in server buddy list, if buddy has already arrived I do not add it again
						_buddyList.push		(_o);
						_buddyListByName[_o.name] = _o;
					}
				}
			}
			public function onEvent_onBuddyListUpdate(e:Object):void {
				_o						= _buddyListByName[e.buddy.name];
				_buddyList[_buddyList.indexOf(_o)] = e.buddy;
				_buddyListByName[e.buddy.name]	= e.buddy;
			}
		// SYSTEM-PIPPOFLASH ///////////////////////////////////////////////////////////////////////////////////////
			public function onEvent_onSystemTrace	(e:Object):void { // This simply traces very loud a string in the trace output window
				Debug.line					("sfs - "+e.data.from);
				Debug.debug				("", e.data.msg);
				Debug.line					("-------------------------");
			}
			public function onEvent_onUserPrompt	(e:Object):void { // this prompts automatically the user using standard PippoFlash Prompt system
				// Parameters in this data object are: txt, tit, ok, okCall, isMain (if true, callback is done in main extension, otherwise in room extension, defaults in room)
				// Also I can set keywords for config, txtData:Object is the object for main txt, titData:Object the one for the title)
				// Text parameters are all taken from config
				// If text is not found in config, I will use direct text
				_promptOk					= e.data; // Store data for further usage
				_promptOk.txt				= _promptOk.txt ? (_config.getWord(_promptOk.txt) ? _config.getWord(_promptOk.txt, _promptOk.txtData) : _promptOk.txt) : null;
				_promptOk.tit				= _promptOk.tit ? (_config.getWord(_promptOk.tit) ? _config.getWord(_promptOk.tit, _promptOk.titData) : _promptOk.tit) : null;
				_promptOk.ok				= _promptOk.ok ? _config.getWord(_promptOk.ok) : null;
				_promptOk.cancel			= _promptOk.ok ? _config.getWord(_promptOk.ok) : null;
				Debug.debug				(_debugPrefix, "Prompting user OK:", Debug.object(_promptOk));
				_mainApp.promptOk			(_promptOk.txt, _promptOk.tit, onUserPromptOk, _config.getWord(_promptOk.ok));
			}
					// Callbacks for user prompt
					public function onUserPromptOk(o:*=null):void {
						if (_promptOk.okCall) { // I have to call something for OK
							if (_promptOk.isMain) sendMainExtension(_promptOk.okCall);
							else			sendRoomExtension(_promptOk.okCall);
						}
						_promptOk		= null;
					}
			public function onEvent_onUserConfirm	(e:Object):void { // this prompts automatically the user for a confirm using standard PippoFlash Prompt system
				// Parameters in this data object are: txt, tit, ok, cancel, okCall, cancelCall, isMain (if true, callback is done in main extension, otherwise in room extension, defaults in room)
				// Text parameters are all taken from config
				_promptConfirm				= e.data; // Store data for further usage
				_promptConfirm.txt			= _promptConfirm.txt ? (_config.getWord(_promptConfirm.txt) ? _config.getWord(_promptConfirm.txt, _promptConfirm.txtData) : _promptConfirm.txt) : null;
				_promptConfirm.tit			= _promptConfirm.tit ? (_config.getWord(_promptConfirm.tit) ? _config.getWord(_promptConfirm.tit, _promptConfirm.titData) : _promptConfirm.tit) : null;
				_promptConfirm.ok			= _promptConfirm.ok ? _config.getWord(_promptConfirm.ok) : null;
				_promptConfirm.cancel			= _promptConfirm.ok ? _config.getWord(_promptConfirm.ok) : null;
				Debug.debug				(_debugPrefix, "Prompting user CONFIRM/CANCEL:", Debug.object(_promptConfirm));
				_mainApp.promptConfirm		(_promptConfirm.txt, _promptConfirm.tit, onUserConfirmOk, onUserConfirmCancel, _promptConfirm.ok, _promptConfirm.cancel);
			}
					// Callbacks for user confirm
					public function onUserConfirmOk(o:*=null):void {
						if (_promptConfirm.okCall) { // I have to call something for OK
							if (_promptConfirm.isMain) sendMainExtension(_promptConfirm.okCall);
							else			sendRoomExtension(_promptConfirm.okCall);
						}
						_promptConfirm		= null;
					}
					public function onUserConfirmCancel(o:*=null):void {
						if (_promptConfirm.cancelCall) { // I have to call something for OK
							if (_promptConfirm.isMain) sendMainExtension(_promptConfirm.cancelCall);
							else			sendRoomExtension(_promptConfirm.cancelCall);
						}
						_promptConfirm		= null;
					}
			public function onEvent_onConfigPrompt	(e:Object):void {
				// Config prompt, expects 2 values, a par, that holds in _sfMan, and a keys, that is the wildcards to modify the text
				// ATTENTION: to prompt codes received, the string "prompt" is added at the beginning
				// code on server: sendUserNameResponse(nick, "onConfigPrompt", {prompt:"MyPrompt", par:{buyIn:this.buyIn}, keys:{}}); // Will call promptMyPrompt
				_mainApp.processConfigPrompt	("prompt"+e.data.prompt, e.data.keys);
				_configPromptData			= e.data.par;
			}
			public function onEvent_onConfigAction	(e:Object):void {
				_mainApp.processConfigAction	(e.data);
			}
// ERROR LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onSecurityError			(e:SecurityErrorEvent):void {
			Debug.debug					(_debugPrefix, "SecurityErrorEvent", e);
			broadcastNetworkError				(e);
		}
		public function onIOError				(e:IOErrorEvent):void {
			Debug.debug					(_debugPrefix, "IOErrorEvent", e);
			broadcastNetworkError				(e);
		}
// NETWORK UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function broadcastNetworkOpen		():void {
			broadcastEvent					("onSmartFoxNetworkOpen");
		}
		private function broadcastNetworkClose		():void {
			broadcastEvent					("onSmartFoxNetworkClose");
		}
		private function broadcastNetworkError		(e:Event):void {
			broadcastEvent					("onSmartFoxNetworkError");
		}
		private function broadcastSmartFoxEvent	(e:String, success:Boolean, par:*=null):void {
			// This changes events: onLogin -> onSmartFoxLogin
			if (e.toLowerCase().indexOf("smartfox") < 0) { // The word smartfox is not in the event
				e						= "onSmartFox"+e.substr(2);
			}
			try {
				par.success 				= success;
			} catch (e) {
				par						= {success:success};
			}
			// Do not trace debug for system stuff
			if (e.indexOf("SystemTrace") < 0 && e.indexOf("ExtensionResponse") < 0) Debug.debug(_debugPrefix, e+"("+Debug.getObjectString(par, true)+")");
			broadcastEvent					(e, par);
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
// STATUS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
// 		private function setStatus				(status:String):void {
// 			_status						= status;
// 			// Check for network open/close
// 			if (NETWORK_OPEN_STATUSES.indexOf(status) >= 0) broadcastNetworkOpen();
// 			else if (NETWORK_CLOSE_STATUSES.indexOf(status) >= 0) broadcastNetworkClose();
// 		}
// UTY /////////////////////////////////////////////////////////////////////////////////
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