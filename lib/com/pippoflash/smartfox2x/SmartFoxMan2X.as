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
package com.pippoflash.smartfox2x {
	import flash.net.URLVariables;
	import flash.system.Security;
	import com.pippoflash.utils.*;
	import com.pippoflash.framework._PippoFlashBaseNoDisplay;
	import com.adobe.crypto.MD5;
	import com.smartfoxserver.v2.*; 
	import com.smartfoxserver.v2.core.*; 
	import com.smartfoxserver.v2.entities.*; 
	import com.smartfoxserver.v2.entities.data.*; 
	import com.smartfoxserver.v2.entities.variables.*; 
	import com.smartfoxserver.v2.entities.managers.*; 
	import com.smartfoxserver.v2.requests.*; 
	import com.smartfoxserver.v2.util.*;
	import com.smartfoxserver.v2.requests.buddylist.*;
	import flash.utils.Timer;
// 	import it.gotoandplay.smartfoxserver.*;
// 	import it.gotoandplay.smartfoxserver.data.*;
	import flash.events.*;
	import com.smartfoxserver.v2.SmartFox;
	
	public dynamic class SmartFoxMan2X extends _PippoFlashBaseNoDisplay {
// VARIABLES ////////////////////////////////////////////////////////////////////////////////////
	// STATIC SWITCHES ///////////////////////////////////////////////////////////////////////////////////////
		protected static var _verbose:Boolean = true; // Traces my messages
		protected static var _debugServer:Boolean = false; // Traces some internal smartfox messages
		protected static var _useKeepAlive:Boolean = true; // Uses SFS Keep alive method
	// STATIC CONSTANTS
		// SYSTEM
		private static const KEEP_ALIVE_MILLISECONDS_INTERVAL:int = 60000; // Interval in milliseconds for keep alive
		private static const KEEP_ALIVE_SERVER_COMMAND:String = "kA"; // Command to be sent to SFS for keep alive
	// EVENTS CONSTANTS
		public static const EVT_CONFIGLOADED:String = "onSFSConfigLoaded"; // no params
		public static const EVT_CONFIGERROR:String = "onSFSConfigError"; // no params
		// CONNECTION
		public static const EVT_CONNECT_SUCCESS:String = "onSFSConnection"; // no params
		public static const EVT_CONNECT_ERROR:String = "onSFSConnectionError"; // no params
		public static const EVT_RECONNECT_SUCCESS:String = "onSFSReconnection"; // no params
		public static const EVT_DISCONNECT:String = "onSFSConnectionLost"; // no params
		// LOGIN
		public static const EVT_LOGIN_SUCCESS:String = "onSFSLogin"; // no params
		public static const EVT_LOGIN_ERROR:String = "onSFSLoginError"; // error:String
		// ROOM NAVIGATION
		public static const EVT_ROOM_JOIN:String = "onSFSRoomJoin"; // A new room is joined - event param Room
		public static const EVT_ROOM_JOIN_ERROR:String = "onSFSRoomJoinError"; // An error occurrred while joining a new room - event params Object
		// User variables
		public static const EVT_MY_VARIABLES_UPDATED:String = "onMyVariablesUpdated"; // varNames:Array - When MY variables have been updated
		public static const EVT_USER_VARIABLES_UPDATED:String = "onUserVariablesUpdated"; // user:SFSUser, varNames:Array - When any user (player, spectator, me) variables have been updated
		public static const EVT_PLAYER_VARIABLES_UPDATED:String = "onPlayerVariablesUpdated"; // user:SFSUser, varNames:Array - When only player user (also if I am a player) variables have been updated
		// BUDDY LIST
		public static const EVT_BUDDY_LIST_INIT:String = "onSFSBuddyListInit"; // Initialised buddy list
		public static const EVT_BUDDY_LIST_ERROR:String = "onSFSBuddyListError"; // General buddy list error
		public static const EVT_BUDDY_ADD:String = "onSFSBuddyAdd"; // Added buddy
		public static const EVT_BUDDY_REMOVE:String = "onSFSBuddyRemove"; // Removed buddy
		public static const EVT_BUDDY_BLOCK:String = "onSFSBuddyBlock"; // Blocked buddy
		public static const EVT_BUDDY_MESSAGE:String = "onSFSBuddyMessage"; // Message received from buddy
		public static const EVT_BUDDY_MESSAGE_RECEIPT:String = "onSFSBuddyMessageReceipt"; // Message received from buddy
		public static const EVT_BUDDY_NET_UPDATE:String = "onSFSBuddyNetStatus"; // Online status of buddy changed
		public static const EVT_BUDDY_VAR_UPDATE:String = "onSFSBuddyVar"; // Buddy variable updated
		// USERS
		public static const EVT_PLAYER_JOINED:String = "onSFSPlayerJoined"; // user:SFSUser, room:SFSRoom
		public static const EVT_PLAYER_LEFT:String = "onSFSPlayerLeft"; // user:SFSUser, room:SFSRoom
		public static const EVT_SPECTATOR_JOINED:String = "onSFSSpectatorJoined"; // user:SFSUser, room:SFSRoom
		public static const EVT_SPECTATOR_LEFT:String = "onSFSSpectatorLeft"; // user:SFSUser, room:SFSRoom
		public static const EVT_USER_JOINED:String = "onSFSUserJoined"; // user:SFSUser, room:SFSRoom - when it is not a player either a spectator of room
		public static const EVT_USER_LEFT:String = "onSFSUserLeft"; // user:SFSUser, room:SFSRoom - when it is not a player either a spectator of room
	// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
// 		private static var CLEAR_PASSWORD_SEPARATOR:String = "[|||]";
// 		private var _status					:String = "IDLE"; // IDLE, CONNECT, CONNECTED, DISCONNECT, DISCONNECTED, LOGIN, LOGGED, JOIN, JOINED
		protected static var _sf:SmartFox;
		protected var _smartfox:SmartFox;
		protected var _keepAliveTimer:Timer;
// 		protected var _myself					:User;
		protected var _debug:Boolean;
		protected var _activeListeners:Object = {}; // Pairs with event string associated to method
		protected var _reconnecting:Boolean = false; // Marks if user is reconnecting (this gets reset after connection)
		protected var _reconnected:Boolean = false; // Marks if this is a subsequent connection (this stays true)
	// BUDDY LIST //////////////////////////////////////////////////////
		protected var _buddyManager:SFSBuddyManager;
		protected var _buddyList:Array;
		protected var _myBuddyVariables:Array;
	// SMARTOFX ///////////////////////////////////////////////////////
// 		private var _defaultZone				:String = "CardGamesZone";
// 		private var _mainLobbyName			:String = "MainLobby"; // This is used to recognize if I have joined main lobby. It can be set with: setMainLobbyName()
// 		private var _loginAsGuest				:Boolean; // If this is true (set with setGuest(true)) smartfox will login as a guest
// 		private var _defaultUser				:String;
// 		private var _defaultPassword			:String; // If this is set, password will be hashed before sending
// 		private var _hashedPassword			:String; // If this is set, this is used (without hashing), not regular password
// 		private var _clearPassword			:String; // If this is defined, key and password are sent separated by the string CLEAR_PASSWORD_SEPARATOR but clear
// 		private var _sentPassword				:String; // This stores the final password sent to system
// 		private var _ip						:String = "127.0.0.1";
// 		private var _port						:uint = 9339;
// 		private var _firstJoin					:Boolean; // Marks if the user joined a room for the first time. On each login this is reset to true. On first join, I broadcast onSmartFoxFirstJoin.
	// SMARTFOX DEFINED ///////////////////////////////////////////////////////// - These hold data received from server
// 		private var _roomList					:Array;
// 		private var _joinedRoom				:Room;
// 		private var _mainLobby				:Room;
		//protected var _connected	:Boolean = false;
		protected var _logged:Boolean = false;
		protected var _lastLoggedRoom:Room; // Stores last successfully logged in room
// 		private var _buddyList				:Array = []; 
// 		private var _buddyListByName			:Object = {};
// 		private var _roomVariablesArray		:Array; // Stores the original array retrieved from room getVariables()
// 		private var _roomVariables			:Object; // Stores the variables of the joined room as a hash key:value
// 		private var _roomMainExtension			:String = "RoomExt"; // Stores the name of extension defined in room variable "_mainExtName"
	// METHODS STORAGE ///////////////////////////////////////////////////////
// 		private var _promptConfirm			= {}; // Stores data for prompt confirm - onUserConfirm
// 		private var _promptOk				= {}; // Stores data for simple prompt - onUserPrompt
// 		public var _configPromptData;			// Contains a special key for prompts when SFS calls onConfigPrompt
	// PIPPOFLASH FRAMEWORK //////////////////////////////////////////////////////////
// 		private var _rooms					:*;
		// MARKERS //////////////////////////////////////////////////////////////
		// REFERENCES //////////////////////////////////////////////////////
		// COMMAND MANAGEMENT ////////////////////////////////////////////   
		// STATIC UTY
// INIT ////////////////////////////////////////////////////////////////////////////////////////
		public function SmartFoxMan2X			(debug:Boolean=false):void { // Here it creates a server instance connected to an API only
			super						("SmartFoxMan2x", SmartFoxMan2X);
			// Error check for singleton
			_debug						= debug;
			if (_sf) {
				Debug.error			(_debugPrefix, "Server already initialised. Critical error. Second initialisation aborted.");
				return;
			}
			// Proceed instantiation
			_activeListeners = {}; // Create listeners storage
			initClient();
// 			_sf						= new SmartFoxClient(_debugServer);
// 			_rooms.init					(this);
// 			// Here I try to activate the bluebox IP address
// 			_smartfox.blueBoxIpAddress			= ip;
// 			_smartfox.httpPollSpeed			= 1000;
// 			// Here I trace inofrmations about smartfox
// 			for each (_s in INFO_CLIENT_PROPERTIES) Debug.debug(_debugPrefix, "SmartFox."+_s+" = "+_smartfox[_s]);
		}
			private function initClient():void {
				_smartfox = _sf = new SmartFox(_debug); 
				Debug.debug(_debugPrefix, "-----------------------------------------------------");
				Debug.debug(_debugPrefix, "| SmartFoxServer 2X API Version: " + _sf.version);
				Debug.debug(_debugPrefix, "-----------------------------------------------------");
				setupAllListeners();
			}
			private function setupAllListeners():void { // Setups all listeners according to active listeners list
				Debug.debug(_debugPrefix, "Setting up listeners for SFS...");
				// Config load
				setupSFSListener(SFSEvent.CONFIG_LOAD_SUCCESS, onConfigLoadSuccess);
				setupSFSListener(SFSEvent.CONFIG_LOAD_FAILURE, onConfigLoadError);
				// Connection
				setupSFSListener(SFSEvent.CONNECTION, onConnection);
				setupSFSListener(SFSEvent.CONNECTION_LOST, onConnectionLost);
				// Login
				setupSFSListener(SFSEvent.LOGIN, onLoginOk);
				setupSFSListener(SFSEvent.LOGIN_ERROR, onLoginError);
				// Main extension listener
				setupSFSListener(SFSEvent.EXTENSION_RESPONSE, onExtensionResponse); // Main listener for methods sent by extension
				// Room join listeners
				setupSFSListener(SFSEvent.ROOM_JOIN, onJoinRoom);
				setupSFSListener(SFSEvent.ROOM_JOIN_ERROR, onJoinRoomError);
				// Messages listeners
				setupSFSListener(SFSEvent.PUBLIC_MESSAGE, onPublicMessage);
				setupSFSListener(SFSEvent.PRIVATE_MESSAGE, onPrivateMessage);
				setupSFSListener(SFSEvent.ADMIN_MESSAGE, onAdminMessage);
				setupSFSListener(SFSEvent.MODERATOR_MESSAGE, onModeratorMessage);
				// Buddy List
				setupSFSListener(SFSBuddyEvent.BUDDY_LIST_INIT, onBuddyListInitialized);
				setupSFSListener(SFSBuddyEvent.BUDDY_ERROR, onBuddyError)
				setupSFSListener(SFSBuddyEvent.BUDDY_ADD, onBuddyAdd)
				setupSFSListener(SFSBuddyEvent.BUDDY_BLOCK, onBuddyBlock)
				setupSFSListener(SFSBuddyEvent.BUDDY_MESSAGE, onBuddyMessage)
				setupSFSListener(SFSBuddyEvent.BUDDY_ONLINE_STATE_UPDATE, onBuddyOnlineStateUpdate)
				setupSFSListener(SFSBuddyEvent.BUDDY_REMOVE, onBuddyRemove)
				setupSFSListener(SFSBuddyEvent.BUDDY_VARIABLES_UPDATE, onBuddyVarUpdate)
				// User variables
				setupSFSListener(SFSEvent.USER_VARIABLES_UPDATE, onUserVariableUpdate);
				// User
				setupSFSListener(SFSEvent.USER_ENTER_ROOM, onUserEnterRoom);
				setupSFSListener(SFSEvent.USER_EXIT_ROOM, onUserLeaveRoom);
				// Player-spectator
				setupSFSListener(SFSEvent.PLAYER_TO_SPECTATOR, onPlayerToSpectator);
				setupSFSListener(SFSEvent.SPECTATOR_TO_PLAYER, onSpectatorToPlayer);
			}
			private function setupSFSListener(evt:String, callback:Function):void {
				Debug.debug(_debugPrefix, "Setting listener for " + evt);
				_sf.addEventListener(evt, callback);
				_activeListeners[evt] = callback;
			}
		public function resetClient():void { // In order to re-load config and re-connect, SF client needs to be recreated. This must be called on re-connect.
			Debug.warning(_debugPrefix, "Re-setting SFS client to re-connect.");
			// Check if I am still connected
			if (_sf.isConnected) {
				Debug.error(_debugPrefix, "resetClient() fail. I can't reset client while still connected.");
				Debug.debug(_debugPrefix, "Trying to disconnect, and then relaunch connection.");
				_sf.disconnect();
				UExec.frame(10, resetClient);
				return;
			}
			// Removing listeners from existing client
			// Loop in registered listeners and remove them
			for (var evt:String in _activeListeners) {
				Debug.debug(_debugPrefix, "Removing listener for: " + evt, _activeListeners[evt]);
				_sf.removeEventListener(evt, _activeListeners[evt]);
			}
			// Re-init client
			_reconnecting = true; // This is a new connection
			initClient();
		}
// SYSTEM UTY ///////////////////////////////////////////////////////////////////////////////////////
		public function get smartfox():SmartFox {
			return _sf;
		}
// CONFIG LOADING ///////////////////////////////////////////////////////////////////////////////////////
// Use this to load an external XML configuration file like this:
// <SmartFoxConfig>
//     <ip>204.13.9.139</ip>
//     <port>80</port>
//     <zone>bunco1</zone>
//     <debug>false</debug>
// </SmartFoxConfig>
		public function loadConfig(configUrl:String, connectOnSuccess:Boolean=false):void {
			_sf.loadConfig(configUrl, connectOnSuccess);
		}
		private function onConfigLoadSuccess(e:SFSEvent):void {
			broadcastEvent(EVT_CONFIGLOADED);
		}
		private function onConfigLoadError(e:SFSEvent):void {
			Debug.error(_debugPrefix, "Config load error: " + e);
			broadcastEvent(EVT_CONFIGERROR);
		}
// CONNECTION ///////////////////////////////////////////////////////////////////////////////////////
		public function connectWithConfig(config:XML):void {
			// Accepts a config XML description that accepts the same parameters as SmartFoxConfig, plus all others defined here: http://docs2x.smartfoxserver.com/api-docs/asdoc/
			Debug.debug(_debugPrefix, "Connecting with parameters: " + config.toXMLString());
			var configObj:ConfigData = new ConfigData();
			configObj.host = "127.0.0.1";
			configObj.port = 9933;
			configObj.zone = "bunco1";
			configObj.debug = true;
			_sf.connectWithConfig(configObj);
		}
		public function connect(ip:String=null, port:int=-1):void { // Connects directly, either using loaded configuration file, or setting IP ad PORT here
			Debug.debug(_debugPrefix, "Connecting to server...");
			_sf.connect(ip, port);
		}
		private function onConnection(e:SFSEvent):void {
			Debug.debug(_debugPrefix, "Connection to server " + (e.params.success ? "SUCCESS!" : "ERROR!"));
			_reconnected = _reconnecting;
			if (e.params.success) broadcastEvent(_reconnecting ? EVT_RECONNECT_SUCCESS : EVT_CONNECT_SUCCESS);
			else broadcastEvent(EVT_CONNECT_ERROR, _reconnecting);
			_reconnecting = false;
			if (_useKeepAlive) {
				if (!_keepAliveTimer) {
					_keepAliveTimer = new Timer(KEEP_ALIVE_MILLISECONDS_INTERVAL);
					_keepAliveTimer.addEventListener(TimerEvent.TIMER, sendKeepAlive);
				}
				_keepAliveTimer.start();
			}
		}
		public function disconnect():void {
			_sf.disconnect();
		}
		private function onConnectionLost(e:SFSEvent):void {
			Debug.debug(_debugPrefix, "Disconnected from server: " + e);
			//_connected = false;
			_logged = false;
			if (_keepAliveTimer) _keepAliveTimer.stop();
			broadcastEvent(EVT_DISCONNECT);
		}
// LOGIN ///////////////////////////////////////////////////////////////////////////////////////
		public function login():void { // This should be overridden since every app uses a different login
		}
		protected function onLoginOk(e:SFSEvent):void {
			Debug.debug(_debugPrefix, "Login to SFS successful.");
			broadcastEvent(EVT_LOGIN_SUCCESS);
		}
		protected function onLoginError(e:SFSEvent):void {
			Debug.error(_debugPrefix, "Login to SFS ERROR: " + Debug.object(e.params));
			broadcastEvent(EVT_LOGIN_ERROR, String(Debug.object(e.params)));
		}
// BUDDY LIST ///////////////////////////////////////////////////////////////////////////////////////
		public function initBuddyList():void { // Activates listeners and requests buddy list initialization to server
			Debug.debug(_debugPrefix, "Initialising buddy list...");
			// Add al necessary listeners
			activateBuddyManager();
// 			activateBuddyListListeners();
			// Initialize buddy list
			_sf.send(new InitBuddyListRequest());
		}
		protected function activateBuddyManager():void {
			_buddyManager = new SFSBuddyManager(_sf);
		}
		// GENERAL
		protected function onBuddyListInitialized(e:SFSBuddyEvent):void {
			Debug.debug(_debugPrefix, "Buddy list correctly initialised.");
			traceSFSEvent(e, "Buddy List");
			_buddyList = e.params.buddyList;
			_myBuddyVariables = e.params.myVariables;
			broadcastEvent(EVT_BUDDY_LIST_INIT);
		}
		protected function onBuddyError(e:SFSBuddyEvent):void {
			Debug.error(_debugPrefix, "Error performing Buddy List operation: " + e.params.errorMessage);
			broadcastEvent(EVT_BUDDY_LIST_ERROR);
		}
		// BUDDYING
		protected function onBuddyAdd(e:SFSBuddyEvent):void { // Dispatched when a buddy is added successfully to the current user's buddies list.
			traceSFSEvent(e, "Buddy List");
			if (_buddyList.indexOf(e.params.buddy) != -1) {
				Debug.error(_debugPrefix, "onBuddyAdd() error - buddy is already in list.");
				return;
			}
			_buddyList.push(e.params.buddy);
			broadcastEvent(EVT_BUDDY_ADD, e.params.buddy);
			processBuddyListUpdate(e.params.buddy, true);
		}
		protected function onBuddyRemove(e:SFSBuddyEvent):void { // Dispatched when a buddy is removed successfully from the current user's buddies list.
			traceSFSEvent(e, "Buddy List");
			if (_buddyList.indexOf(e.params.buddy) == -1) {
				Debug.error(_debugPrefix, "onBuddyRemove() error - buddy is not in list.");
				return;
			}
			UCode.removeArrayItem(_buddyList, e.params.buddy);
			broadcastEvent(EVT_BUDDY_REMOVE, e.params.buddy);
			processBuddyListUpdate(e.params.buddy, false);
		}
		// UPDATES
		protected function onBuddyBlock(e:SFSBuddyEvent):void { // Dispatched when a buddy is blocked or unblocked successfully by the current user.
			traceSFSEvent(e, "Buddy List");
			if (_buddyList.indexOf(e.params.buddy) == -1) {
				Debug.error(_debugPrefix, "onBuddyBlock() error - buddy is not in list.");
				return;
			}
			broadcastEvent(EVT_BUDDY_BLOCK, e.params.buddy);
			processBuddyUpdate(e.params.buddy);
		}
		protected function onBuddyOnlineStateUpdate(e:SFSBuddyEvent):void { // Dispatched when a buddy in the current user's buddies list changes his online state in the Buddy List system.
			traceSFSEvent(e, "Buddy List");
			if (_buddyList.indexOf(e.params.buddy) == -1) {
				Debug.error(_debugPrefix, "onBuddyOnlineStateUpdate() error - buddy is not in list.");
				return;
			}
			broadcastEvent(EVT_BUDDY_NET_UPDATE, e.params.buddy);
			processBuddyUpdate(e.params.buddy);
		}
		protected function onBuddyVarUpdate(e:SFSBuddyEvent):void { // Dispatched when a buddy in the current user's buddies list updates one or more Buddy Variables.
			traceSFSEvent(e, "Buddy List");
			if (!e.params.buddy) {
				Debug.warning(_debugPrefix, "Reported buddy variables update for myself. onBuddyVarUpdate() aborted. " + Debug.object(e.params));				
				return;
			}
			else if (_buddyList.indexOf(e.params.buddy) == -1) {
				Debug.error(_debugPrefix, "onBuddyVarUpdate() error - buddy is not in list.");
				return;
			}
			broadcastEvent(EVT_BUDDY_VAR_UPDATE, e.params.buddy);
			processBuddyUpdate(e.params.buddy);
		}
		// MESSAGING
		protected function onBuddyMessage(e:SFSBuddyEvent):void {
			traceSFSEvent(e, "Buddy List");
			if (e.params.isItMe) { // This is a receipt for a message I have sent
				Debug.debug(_debugPrefix, "onBuddyMessage() from MYSELF: " + e.params.message + "\nData: " + (e.params.data ? e.params.data.getDump() : " no data.")); 
				processBuddyMessageReceipt(e.params);
				return;
			}
			else if (_buddyList.indexOf(e.params.buddy) == -1) {
				Debug.error(_debugPrefix, "onBuddyMessage() error - buddy is not in list.");
				return;
			}
			processBuddyMessage(e.params);
		}
		
		// BUDDY LIST EVENTS UTY
		
		private function traceSFSEvent(e:BaseEvent, id:String=null):void {
			Debug.debug(_debugPrefix, (id ? id : "SFS") + "Event: " + e + Debug.object(e.params));
		}
		protected function processBuddyMessageReceipt(eventParams:Object):void {
			// EXTEND
			broadcastEvent(EVT_BUDDY_MESSAGE_RECEIPT, eventParams);
		}
		protected function processBuddyMessage(eventParams:Object):void {
			// EXTEND
			broadcastEvent(EVT_BUDDY_MESSAGE, eventParams);
		}
		protected function processBuddyListUpdate(buddy:SFSBuddy, isAdded:Boolean):void { // When a change at the list is done (i.e. buddy deleted or added)
			// EXTEND
		}
		protected function processBuddyUpdate(buddy:SFSBuddy):void { // When a single buddy has been updated
			// EXTEND
		}
		
// MESSAGES ///////////////////////////////////////////////////////////////////////////////////////
	// These are extended in order to trigger project related events
		protected function onPublicMessage(e:SFSEvent):void {
			Debug.debug(_debugPrefix, "onPublicMessage: " + Debug.object(e.params));
		}
		protected function onPrivateMessage(e:SFSEvent):void {
			Debug.debug(_debugPrefix, "onPrivateMessage: " + Debug.object(e.params));
			if (e.params.data) Debug.debug(_debugPrefix, e.params.data.getDump());
		}
		protected function onAdminMessage(e:SFSEvent):void {
			Debug.debug(_debugPrefix, "onAdminMessage: " + Debug.object(e.params));
		}
		protected function onModeratorMessage(e:SFSEvent):void {
			Debug.debug(_debugPrefix, "onModeratorMessage: " + Debug.object(e.params));
		}
// USER VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		private function onUserVariableUpdate(e:SFSEvent):void {
			// Debug.line("USER VARIABLES UPDATE")
			// Debug.debug(_debugPrefix, "User variables update: " + Debug.object(e.params));
			// Debug.debug(_debugPrefix, "Existing user variables: " + Debug.object(e.params.user.getVariables()));
			// MY OWN USER VARIABLES
			var updated:Vector.<SFSUserVariable> = new Vector.<SFSUserVariable>(); // Array of updated SFSUserVariable
			var deleted:Vector.<String> = new Vector.<String>(); // Array of NAMES of deleted user variables
			var updatedVarNames:Array = []; // List of updated var names, useful to check right away if variable is updated
			var user:SFSUser = e.params.user;
			var userDescription:String; // This changes for reports, according to which kind of user has variables updated
			userDescription = user.isItMe ? "My own" : user.toString();
			// At the beginning, querying "isPlayer" triggers an internal error in SFS api.
			// I check if the error is triggered then I assume is not a player
			var isPlayer:Boolean;
			try {
				isPlayer = user.isPlayer;
			}
			catch (e:Error) {
				Debug.error(_debugPrefix, "Error accessing user.isPlayer. I assume he is not a player.");
			}
			userDescription += " ("+(isPlayer ? "Player" : "Normal User")+")";
			var varName:String;
			for (var i:uint=0; i<e.params.changedVars.length; i++) {
				varName = e.params.changedVars[i];
				var v:SFSUserVariable = e.params.user.getVariable(String(varName));
				if (v) {
					updated.push(v);
					updatedVarNames.push(varName);
				}
				else {
					deleted.push(varName);
				}
			}
			/* REPORT SWITCHED OFF
			var report:String = userDescription + " Variables update reported: " + e.params.changedVars;
			if (deleted.length) report += "\nDeleted: " + deleted;
			if (updated.length) report += "\nUpdated: " + updated;
			Debug.warning(_debugPrefix,report);
			*/
			if (user.isItMe) { // This is me
				if (updated.length) {
					broadcastEvent(EVT_MY_VARIABLES_UPDATED, e.params.changedVars);
					processMyVariablesUpdated(updated, updatedVarNames);
				}
				if (deleted.length) {
					processMyVariablesDeleted(deleted); 
				}
			}
			// Broadcast also player or user
			if (updated.length) {
				if (isPlayer) broadcastEvent(EVT_PLAYER_VARIABLES_UPDATED, user, updatedVarNames);
				broadcastEvent(EVT_USER_VARIABLES_UPDATED, user, updatedVarNames);
			}
		}
		protected function processMyVariablesUpdated(vars:Vector.<SFSUserVariable>, varNames:Array):void {
			/* IF NEEDED - THIS HAS TO BE EXTENDED */
		}
		protected function processMyVariablesDeleted(vars:Vector.<String>):void {
			/* IF NEEDED - THIS HAS TO BE EXTENDED */
		}
// USER ///////////////////////////////////////////////////////////////////////////////////////
		private function onUserEnterRoom(e:SFSEvent):void {
			var user:SFSUser = e.params.user;
			// check for standard events broadcast
			//if (!user.isItMe) {
				var room:SFSRoom = e.params.room;
				if (user.isPlayerInRoom(room)) broadcastEvent(EVT_PLAYER_JOINED, user, room);
				else if (user.isSpectatorInRoom(room)) broadcastEvent(EVT_SPECTATOR_JOINED, user, room);
				else broadcastEvent(EVT_USER_JOINED, user, room);
				// Process if it's not me
				if (!user.isItMe) userEnterRoom(user, e.params.room);
			//}
		}
		private function onUserLeaveRoom(e:SFSEvent):void {
			var user:SFSUser = e.params.user;
			// check for standard events broadcast
			//if (!user.isItMe) {
				var room:SFSRoom = e.params.room;
				if (user.isPlayerInRoom(room)) broadcastEvent(EVT_PLAYER_LEFT, user, room);
				else if (user.isSpectatorInRoom(room)) broadcastEvent(EVT_SPECTATOR_LEFT, user, room);
				else broadcastEvent(EVT_USER_LEFT, user, room);
				// Process if it's not me
				if (!user.isItMe) userLeaveRoom(user, e.params.room);
			//}
		}
		protected function userEnterRoom(user:SFSUser, room:SFSRoom):void {
			/* IF NEEDED - THIS HAS TO BE EXTENDED */
		}
		protected function userLeaveRoom(user:SFSUser, room:SFSRoom):void {
			/* IF NEEDED - THIS HAS TO BE EXTENDED */
		}
	// Plyer - spectator
		private function onPlayerToSpectator(e:SFSEvent):void {
			Debug.scream(_debugPrefix, "onPlayerToSpectator"  + Debug.object(e.params));
		}
		private function onSpectatorToPlayer(e:SFSEvent):void {
			Debug.scream(_debugPrefix, "onSpectatorToPlayer"  + Debug.object(e.params));
		}

// ROOMS NAIVGATION ///////////////////////////////////////////////////////////////////////////////////////
		protected function onJoinRoom(e:SFSEvent):void {
			Debug.debug(_debugPrefix, "Joined room: " + e.params.room.name);
			_lastLoggedRoom = e.params.room;
			broadcastEvent(EVT_ROOM_JOIN, _lastLoggedRoom);
		}
		protected function onJoinRoomError(e:SFSEvent):void {
			Debug.error(_debugPrefix, "Error joining room: " + Debug.object(e.params));
			broadcastEvent(EVT_ROOM_JOIN_ERROR, e.params);
		}
// ROOMS ///////////////////////////////////////////////////////////////////////////////////////
	// http://docs2x.smartfoxserver.com/api-docs/asdoc/com/smartfoxserver/v2/entities/SFSRoom.html
	// If user is in a kind of room
		public function inLobby():Boolean { 
			return isLobby(_sf.lastJoinedRoom);
		}
		public function inLimbo():Boolean { 
			return isLimbo(_sf.lastJoinedRoom);
		}
		public function inGame():Boolean { 
			return isGameRoom(_sf.lastJoinedRoom) || isGameLobby(_sf.lastJoinedRoom);
		}
		public function inGameRoom():Boolean {
			return isGameRoom(_sf.lastJoinedRoom);
		}
		public function inGameLobby():Boolean {
			return isGameLobby(_sf.lastJoinedRoom);
		}
	// What kind of room is this
		public function isGameRoom				(r:Room):Boolean {
				Debug.error(_debugPrefix, "ERROR - SrmatFoxMan2X.isGameRoom() needs to be overridden.");
				return false;
		}
		public function isGameLobby				(r:Room):Boolean {
				Debug.error(_debugPrefix, "ERROR - SrmatFoxMan2X.isGameLobby() needs to be overridden.");
				return false;
		}
		public function isLobby					(r:Room):Boolean {
				Debug.error(_debugPrefix, "ERROR - SrmatFoxMan2X.isLobby() needs to be overridden.");
				return false;
		}
		public function isLimbo					(r:Room):Boolean {
				Debug.error(_debugPrefix, "ERROR - SrmatFoxMan2X.isLimbo() needs to be overridden.");
				return false;
		}
	// GET ROOMS
		public function getLastLoggedRoom():Room {
			return _lastLoggedRoom;
		}
	// ROOM DATA - OR LAST ROOM DATA - OTHER NEED TO BE ADDED WHEN NEEDED
		public function getRoomId(r:SFSRoom=null):int {
			return getRoomProp("id", r);
		}
		public function getRoomUserCount(r:SFSRoom=null):int {
			return getRoomProp("userCount", r);
		}
		public function getRoomName(r:SFSRoom=null):String {
			return getRoomProp("name", r);
		}
		private function getRoomProp(prop:String, r:SFSRoom=null):* {
			return r ? r[prop] : _lastLoggedRoom[prop];
		}
// USER ///////////////////////////////////////////////////////////////////////////////////////
		public function isMyself(u:User):Boolean {
			return _sf.mySelf == u;
		}
// EXTENSION RESPONSES ///////////////////////////////////////////////////////////////////////////////////////		
		public function onExtensionResponse(e:SFSEvent):void { /* THIS ONE NEEDS TO BE OVERRIDDEN ALL THE TIME */
			Debug.debug(_debugPrefix, "Received response from server: " + Debug.object(e.params));
		}
		
// EXTENSIONS CONTROL ///////////////////////////////////////////////////////////////////////////////////////
		public function sendSFSCommand(cmd:String, params:SFSObject=null):void {
			if (params) {
				Debug.debug(_debugPrefix, "Sending extension request: " + cmd +  params.getDump());
				_sf.send(new ExtensionRequest(cmd, params));
			} else {
				Debug.debug(_debugPrefix, "Sending extension request: " + cmd);
				_sf.send(new ExtensionRequest(cmd, params));
			}
		}


// METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		public static function getClient():SmartFox {
			return _sf;
		}
	// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		public function sendKeepAlive(event:*=null):void {
			//Debug.warning(_debugPrefix, "SENDING KEEP ALIVE");
			sendSFSCommand(KEEP_ALIVE_SERVER_COMMAND);
		}
	// CHECKS ///////////////////////////////////////////////////////////////////////////////////////
		public function isConnected():Boolean {
			return _sf.isConnected;
		}
		public function isReconnecting():Boolean { // If client is reconnecting
			return _reconnecting;
		}
		public function isReconnected():Boolean { // If client has been connected more than once
			return _reconnected;
		}
	// METHODS ON MYSELFS ///////////////////////////////////////////////////////////////////////////////////////

		public function getMyself():SFSUser { 
			return _sf.mySelf as SFSUser;
		}
		public function getMyVariable(id:String):UserVariable {
			return _sf.mySelf.getVariable(id);
		}
		public function getMyVariableValue(id:String):* {
			var v:UserVariable = _sf.mySelf.getVariable(id);
			return v ? v.getValue() : null;
		}
		public function isPlayer():Boolean {
			return _sf.mySelf.isPlayer;
		}
		public function isPlayerInRoom(room:SFSRoom):Boolean {
			return _sf.mySelf.isPlayerInRoom(room);
		}
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