/* P2PGroupLocalCommander - For LAN, without using Cirrus, this connects to groups and tunnels events
Filippo Gregoretti - www.pippoflash.com

This manages communication in a LAN serverless P2P group of machines.
It can be set as MASTER or SLAVE or NEUTRAL (M, S, N). Master and slave can be paired. Neutrals can't do a shit except sniff communications and chat.


Commands can be:

ANNOUNCE
I am announcing my presence to all neighbors

WELCOME
Neighbors reply to my annouce (or to my update, if I am new to them)

UPDATE
I have changed status or data

MSG
I have sent a chat message

IAMYOURMASTER
I found my slave, and send him a message to tell him that I am his master. With this message also the key is sent. If key is correct slave will reply YESYOUARE or if key is wrong slave will reply NOWAY, and will wait for another IAMYOURMASTER with the correct pin. Actually, if key is correct, MASTER can start sending commands right away.

YESYOUARE
Slave accepts connection with master, and replies to his commands correctly.

NOWAY
Slave doesn't recognize key. Master can try again with correct pin.

IAMYOURSLAVE
I found my master, and I wran him that I am ready.

CMD
I am seding a command to either my slave or everybody.

RECEIPT
I am sending a receipt for a command with a receipt request.



*/
package com.pippoflash.net {
	
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem;
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMemDispatcher;
	import com.pippoflash.utils.UMem;
	import									flash.media.*;
	import									flash.geom.*;
	import									flash.utils.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import									flash.system.*;
	import									com.pippoflash.net.NetStatusEventAnalyzer;
	import									com.pippoflash.utils.Debug;
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.UText;
	import									com.pippoflash.utils.UExec;
	import									com.pippoflash.framework._PippoFlashBaseNoDisplay;
	import 									com.adobe.crypto.MD5;
	
	public class P2PGroupLocalCommander extends _PippoFlashBaseNoDisplayUMemDispatcher {
		// VARIABLES /////////////////////////////////////////////////////////////////////////////////////////////////
		protected static const VERSION:String = "2.0.1"; // Version of this commander
		protected static const MODES:Object = {N:"Neutral", M:"Master", S:"Slave", O:"Open", P:"Pair"};
		protected static const DEFAULT_NET_CONNECTION	:String = "rtmfp:";
		protected static const STATUSES:Vector.<String> = new <String>[
		"IDLE", // 0
		"DISCONNECTED", // 1
		"CONNECTED", // 2
		"GROUPED", // 3
		"ANNOUNCED", // 4
		"WELCOMED", // 5
		"PAIRING", // 6 - Looking for Pair, Master or Slave
		"PAIRED",  // 7 - Paird with pair device
		"MASTER", // 8 - Master paired with slave
		"SLAVE",  // 9 - Slave paired with master
		"OPEN" // 10 - After I am announced, I am set to open status
		];
		protected static const MESSAGES:Object = {
			IDLE:"Welcome to P2PComm Console.",
			DISCONNECTED:"Disconnected from network..",
			CONNECTED:"Connected to network.",
			GROUPED:"Connected to P2P group.",
			ANNOUNCED:"Announced to neighbors.",
			WELCOMED:"Welcomed by neighbors.",
			MASTER:"Waiting for my slave...",
			SLAVE:"Waiting for my master...",
			PAIRED:"Paired.",
			OPEN:"Opened to bi-directional communication."
		};
		protected static const ALLOWED_COMMANDS:String = "ANNOUNCE,ANNOUNCEANDREQUEST,WELCOME,UPDATE,IAMYOURPAIR,MSG,CMD,RECEIPT,FEEDBACK,IAMYOURMASTER,YESYOUARE,NOWAY,IAMYOURSLAVE"; // Used to check that commands received are allowed
		public static const AUTO_CONNECT:Boolean = false; // Connects on initialization
		public static const KEEP_ALIVE_INTERVAL:int = 5; // Seconds to keep alive
		public static const ACCEPT_FROM_ALL_GROUPS:Boolean = false; // Also processes commends from another group
		public static const RESTART_ON_NEIGHBOUR_LOST:Boolean = true; // On neighbour lost, connection is restarted
		// EVENTS
		public static const EVT_STATUS_CHANGE:String = "onP2PStatus"; // () - When there is a change of status in P2PComm
		public static const EVT_CONNECTED:String = "onP2PConnected"; // ()
		public static const EVT_DISCONNECTED:String = "onP2PDisconnected"; // ()
		public static const EVT_MSG:String = "onP2PMsgReceived"; // ({name:String, msg:String}) -  When a chat message is received (for me or for all)
		public static const EVT_NEIGHBOR_DATA:String = "onP2PNeighborUpdate"; // (neighbor:Object) - When ONE neighbor calls ANNOUNCE, WELCOME or UPDATE
		public static const EVT_NEIGHBORS_UPDATE:String = "onP2PNeigborsUpdate"; // Every time neighbors data is updated (counters, names, etc.)
		public static const EVT_CONNECTION_RESET:String = "onP2PConnectionReset"; // When connection is reset locally calling resetConneciton();
		// PAIRING EVENTS
		public static const EVT_PAIRREQUEST:String = "onP2PSlavePairingRequest"; // I am requesting my slave to be paired
		public static const EVT_PAIRREFUSED:String = "onP2PSlavePairingRefused"; // The slave said I cannot pair with him
		public static const EVT_PAIRSUCCESS:String = "onP2PPairingSuccess"; // I am successfully paired. (Or all group paired remotes are paired)
		public static const EVT_PAIRLOST:String = "onP2PPairingLost"; // I am not paired anymore
		// COMMANDS
		public static const EVT_EXEC:String = "onP2PCommand"; // (arg:*) I received a P2P command from a MASTER and confirmed he was my master
		private static const EVT_EXECFAIL:String = "onP2PCommandFail"; // (arg:*) I received a P2P command but he is not my master
		private static const EVT_RECEIPT_OK:String = "onP2PCommandSuccess"; // (o.arg:Object) I sent a command waiting for receipt, receipt received, and the command was executed successfully on the target machine
		private static const EVT_RECEIPT_KO:String = "onP2PCommandFailed"; // (o.arg:Object) I sent a command waiting for receipt, and the command was failed on target machine!
		// FEEDBACKS
		private static const EVT_FEEDBACK:String = "onP2PFeedback"; // (arg:*) I received a P2P feedback from a SLAVE and confirmed he was my slave
		private static const EVT_FEEDBACKFAIL:String = "onP2PFeedbackFail"; // (arg:*) I received a P2P feedback but he is not my slave
		// STATIC VARIABLES
		static private var _init:Boolean;
		// USER DATA - This data has default values in it, but it can be amended
		protected var _groupId:String = "myGroup/groupOne";
		protected var _multicastAddress:String = "225.225.0.1:30303";
		protected var _id:String; // Connection ID
		protected var _localUdid:String; // Udid of local app
		protected var _remoteUdid:String; // Udid of remote app. Can be PAIR, SLAVE or MASTER
		protected var _generalApp:String; // App environment where connection belongs
		protected var _userName:String; // Name of user
		protected var _mode:String = "N"; // Defaults to neutral - S, M, O, N
		protected var _name:String; // Screen name for the local sender
		protected var _requestWelcomeOnAnnounce:Boolean; // If when I am announcing myself I request welcome message sback
		// SYSTEM
		protected var _nc:NetConnection;
		protected var _groupSpec:GroupSpecifier;
		protected var _group:NetGroup;
		protected var _status:uint = 0; // Status 0 is IDLE
		// SWITCHES
		protected static var _verbose:Boolean = true;
		// DATA
		protected var _lastReceivedCommand:P2PLocalCommanderMessageData;
		// MARKERS
		protected var _connected:Boolean;
		protected var _grouped:Boolean;
		protected var _keepAlive:Boolean = true; // Keep alive defaults to true
		protected var _active:Boolean; // this activates send and receive messages
		protected var _openToSendAllCommands:Boolean; // Sends messages and commands anyway even if it is not paired, sesn't have a slave, etc.
		protected var _openToReceiveAllCommands:Boolean; // Receives all commands just like if they were meant to be received (no problem for authentication or recipient, they all get here as if they were for ALL),
 		// IDENTITY VARIABLES
		protected var _dataSender:Object = { // My data
			app:null, // String - General app id
			group:null, // String - Group I belong to
			mode:null, // String - Mode I am into (N, S, M, O)
			ver:null, // string - version of class
			udid:null, // My udid
			name:null // My username
		};
		protected var _dataRecipient:Object = {
			udid:null, // Udid of recipient (if any, must be checked)
			name:null // Name of recipient (if any, must be checked)
		};
		protected var _dataMessage:Object = {
			type:null, // type iof message: ANNOUNCE,WELCOME,UPDATE,MSG,IAMYOURMASTER,YESYOUARE,NOWAY,IAMYOURSLAVE,CMD,RECEIPT,FEEDBACK
			arg:null, // Argument of CMD object
			id:null, // ID of message
			receipt:null, // Boolean - whether I need a receipt for the command
			success:null // Boolean - if FEEDBACK, this means success or not of received command
		}
		
		
		protected var _udid:String; // UDID taken from USystem (Application dependant. It can't be shared between apps.)
		protected var _appId:String; // Taken from _mainApp.getAppId();
		// COMMANDS AND NEIGHBORS
		protected var _commandsWaitingReceipt:Object; // Sent commands awaiting for a receipt are stored here
		protected var _pairingApp:String = ""; // MASTER app to be mixed with PIN in order to generate key
 		// COUNTERS
		protected var _messagesSent:int = 0; // Counts messages sent
		protected var _messagesReceived:int = 0; // Counts messages received
		// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static protected function staticInit():void {
			if (_init) return;
			UMem.addClass(P2PLocalCommanderMessageData);
		}
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function P2PGroupLocalCommander(id:String, appId:String, mode:String="O", name:String=null, localUdid:String=null, remoteUdid:String=null, pin:String=null, groupId:String=null, multicastAddress:String=null, requestWelcomeOnAnnounce:Boolean=false):void {
			super(id); // This is NOT singleton, so ID can't be the same
			staticInit();
			_id = id;
			_generalApp = _appId = appId;
			_localUdid = localUdid;
			_remoteUdid = remoteUdid;
			_userName = _name = name;
			_mode = mode;
			if (groupId) _groupId = groupId;
			if (multicastAddress) _multicastAddress = multicastAddress;
			// Populate data sender - FIXED
			//_baseIdentity.ver = VERSION;
			_dataSender.ver = VERSION;
			_dataSender.app = _generalApp;
			_dataSender.group = _groupId;
			_dataSender.mode = _mode;
			_dataSender.udid = _localUdid;
			_dataSender.name = _userName;
			
			_active = true;
			//
		//private var _dataSender:Object = { // My data
			//app:null, // String - General app id
			//group:null, // String - Group I belong to
			//mode:null, // String - Mode I am into (N, S, M, O)
			//ver:null, // string - version of class
			//udid:null, // My udid
			//name:null // My username
		//};
			
			
			
			Debug.debug(_debugPrefix, "Ver " + VERSION + " on " + _groupId + ":" +_multicastAddress + " started as: " + MODES[_mode]);
			Debug.debug(_debugPrefix, "General Application ID: " + _generalApp);
			if (_localUdid) Debug.debug(_debugPrefix, "Local UDID: " +_localUdid);
			if (_remoteUdid) Debug.debug(_debugPrefix, "Remote UDID: " +_remoteUdid);
			if (_userName) Debug.debug(_debugPrefix, "My user name: " +_userName);
			//resetNeighbourHolders();
			if (AUTO_CONNECT) connect();
		}
// STARTUP ///////////////////////////////////////////////////////////////////////////////////////
		protected function initializeNetwork():void {
			Debug.debug(_debugPrefix, "Initializing network...");
			if (_nc) {
				Debug.error(_debugPrefix, "Network already initialized.");
				return;
			}
			_nc = new NetConnection();
			_nc.addEventListener(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
			_nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onNetConnectionStatus);
    		_nc.connect(DEFAULT_NET_CONNECTION);
		}
		//private function initializeGroup():void {
			//// Initialize specification
			//_groupSpec = new GroupSpecifier(_groupId);
			//_groupSpec.postingEnabled = true;
			//_groupSpec.ipMulticastMemberUpdatesEnabled = true;
//// 			_groupSpec.addIPMulticastAddress			(_multicastAddress);
			///* 	There is a bug in addIPMulticastAddress(), if I don't set "" but set null as last parameter, I get an ArgumentError 
				//That's why I need to split address in 2, and then set "" as last argument. 
			//*/
			//var addressPort						:Array = _multicastAddress.split(":");
			//try {
				//_groupSpec.addIPMulticastAddress			(addressPort[0], addressPort[1], "");
			//}
			//catch(e) {
				//Debug.error						(_debugPrefix, "Error setting multicast address: " + e);
			//}
			//_group = new NetGroup(_nc, _groupSpec.groupspecWithAuthorizations());
			//_group.addEventListener(NetStatusEvent.NET_STATUS, onGroupConnectionStatus);
		//}
// METHODS //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SETUP
		public function setNetwork(ipPort:String, groupName:String):void {
			_multicastAddress = ipPort;
			_groupId = groupName;
			/* TO BE IMPLEMENTED - Checks to see if it is already connected, and in case close connection and start a new one. This will more likely never be called. */
		}
		public function keepAlive(ka:Boolean):void { // It defaults to true, can be switched of with this
			_keepAlive = ka;
			if (_keepAlive) startConnectionCheck();
			else endConnectionCheck();
		}
		public function connect():Boolean {
			if (_connected) {
				Debug.error(_debugPrefix, "I am already connected. Call disconnect before connecting.");
				return false;
			}
			Debug.debug(_debugPrefix, "Connecting...");
			if (!_nc) initializeNetwork();
			else {
				_nc.connect(DEFAULT_NET_CONNECTION);
			}
			keepAlive(_keepAlive);
			return true;
		}
		public function disconnect():Boolean {
			Debug.debug(_debugPrefix, "Disconnecting...");
			if (_grouped) {
				_group.close();
				_group = null;
				_groupSpec = null;
				_grouped = false;
			}
			if (_connected) {
				_nc.close();
				_connected = false;
				return true;
			}
			Debug.error(_debugPrefix, "Cannot disconnect since I am not connected.");
			return false;
		}
		public function resetConnection():void {
			Debug.debug(_debugPrefix, "Resetting connection.");
			broadcastEvent(EVT_CONNECTION_RESET);
			disconnect();
			UExec.time(0.2, connect);
		}
		//public function setName					(n:String):void {
			//Debug.debug						(_debugPrefix, "Changed my name into " + _name);
			//updateUser							(n);
		//}
		//// These update functions, it is better to call them BEFORE connection
		//public function updateSystem				(ipPort:String=null, group:String=null, andDisconnect:Boolean=false):void {
			//if (ipPort)							_multicastAddress = ipPort;
			//if (group)							_groupId = group;
			//if (andDisconnect)					disconnect();
		//}
		//public function updateUser(mode:String=null, name:String=null, appId:String=null, udid:String=null, notify:Boolean=true):void {
			//if (mode) _mode = mode;
			//if (name) _name = name;
			//if (appId) _appId = appId;
			//if (udid) _udid = udid;
			//updateIdentity(notify);
		//}
		//public function updatePairing				(pairingApp:String = null, pairingPin:String = null) {// , slaveUDID:String = null, masterUDID:String = null, notify:Boolean = true):void {
			//// This updates all data regarding pairing (SLAVE/MASTER) 
			//if (pairingApp)						_pairingApp = pairingApp;
			//if (pairingPin)						_pairingPin = pairingPin;
			////if (slaveUDID)						_slaveUDID = slaveUDID;
			////if (masterUDID)						_masterUDID = masterUDID;
			//updateMastering						(true); // (notify);
		//}
		// These 3 below are called on connection done. It is a subsequent change of status.
		//public function setToMaster					(pairingApp:String):void {
			//// When I set to master, I setup the app I am expecting to find, check into my registered neighbors if my slave is there, and check again everytime users are updated
			//updateUser							("M", null, null, null, false);
			//updatePairing						(pairingApp);
		//}
		//public function setToSlave					(pairingApp:String):void {
			//// When I am set into slave mode, I may have alreay registered an expected master, or I may wait for another master to register, I will generate the pin, and wait for his confirmation
			//updateUser							("S", null, null, null, false);
			//updatePairing						(pairingApp);
		//}
		//public function setToNeutral					(pairingApp:String):void {
			//// When I am set into slave mode, I may have alreay registered an expected master, or I may wait for another master to register, I will generate the pin, and wait for his confirmation
			//updateUser							("N", null, null, null, false);
			//updatePairing						(pairingApp);
		//}
	// DATA RETIREVAL
		//public function getAllNames					():Vector.<String> {
			//return							_neighborsNames;
		//}
		//public function getAllNeighbors				():Vector.<Object> {
			//return							_neighborsObjects;
		//}
		//public function getNeighbor					(index):Object {
			//if (_neighborsObjects[index])			return _neighborsObjects[index];
			//else {
				//Debug.error					(_debugPrefix, "getNeighbor() aborted. Index out of range: " + index);
			//}
			//return							null;
		//}
		//public function getNeighborById				(from:String):Object { // Returns a neighbor using his unique device id
			//return							_neighborsById[from];
		//}
		//public function get neighborsNum				():int {
			//return							_neighborsObjects.length;
		//}
		//public function getCounters					():Object { // Returns an object with counters i.e. {M:3, N:1, S:0, TOT:4}
			//return							_counters;
		//}
	// UTY
		public function setActive(a:Boolean):void {
			_active = a;
		}
	// COMMANDS
		public function sendCmdTo(id:String, arg:*, receipt:Boolean=false, info:String=null, extraParams:Object=null):void {
			sendCommandTo(id, "CMD", arg, receipt, info, extraParams);
		}
		public function sendCmdToRemote(arg:*, receipt:Boolean=false, info:String=null, extraParams:Object=null):void {
			sendCmdTo(_remoteUdid, arg, receipt, info, extraParams);
		}
	
	
	
		public function sendChatToAll				(t:String):void { // Sends a message to all clients
			sendCommandToAll					("MSG", t);
		}
		public function sendChatToSlave				(t:String):void { // Sends a chat message only to slave machine
			sendCommandToSlave					("MSG", t);
		}
		public function sendCmdToSlave				(arg:*, receipt:Boolean=false):void { // Sends a custom command to slave machine
			sendCommandToSlave					("CMD", arg, receipt);
		}
		public function sendFeedback				(arg:*):void { // This sends a feedback to Master - no receipt for feedback
			sendFeedbackToMaster					("FEEDBACK", arg);
		}
	// CHECKS
		public function isMaster():Boolean {
			return _mode == "M";
		}
		public function isSlave():Boolean {
			return _mode == "S";
		}
		public function isNeutral():Boolean {
			return _mode == "N";
		}
		public function isOpen():Boolean {
			return _mode == "O";
		}
		public function isPair():Boolean {
			return _mode == "P";
		}
		public function isPairable():Boolean { // If is pairable (pair, slave or master);
			return isPair() || isMaster() || isSlave();
		}
		//public function hasNeighbors():Boolean {
			//return neighborsNum;
		//}
	// STATUS CHECKS
		public function isIdle(orHigher:Boolean=true):Boolean { // IDLE or LOST is the same thing (0, 1)
			return checkStatus(0, orHigher) || isDisconnected(orHigher);
		}
		public function isDisconnected(orHigher:Boolean=true):Boolean { // IDLE or LOST is the same thing (0, 1)
			return checkStatus(1, orHigher);
		}
		public function isConnected(orHigher:Boolean=true):Boolean {
			return checkStatus(2, orHigher) && _connected;
		}
		public function isGrouped(orHigher:Boolean=true):Boolean {
			return checkStatus(3, orHigher) && _grouped;
		}
		public function isAnnounced(orHigher:Boolean=true):Boolean {
			return checkStatus(4, orHigher);
		}
		public function isWelcomed(orHigher:Boolean=true):Boolean {
			return checkStatus(5, orHigher);
		}
		public function isPairing(orHigher:Boolean=true):Boolean { // It Means i am in MASTER or SLAVE waiting for pairing
			return checkStatus(6, true);
		}
		public function isPaired(orHigher:Boolean=true):Boolean { // Paired to a slave or master
			return checkStatus(7, orHigher);
		}
		public function isPairedAsMaster():Boolean {
			return checkStatus(8, false);
		}
		public function isPairedAsSlave():Boolean {
			return checkStatus(9, false);
		}
		public function isPairedInAnyWay():Boolean { // Paired as master or slave or anything
			return _status >= 7 && _status <= 9;
		}
		public function isOpenToAll():Boolean {
			return checkStatus(10, false);
		}
			protected function checkStatus(n:int, h:Boolean):Boolean {
				return h ? _status >= n : _status == n;
			}
	// GETTERS
		public function getMode					():String { // Returns the NAME of mode
			return							MODES[_mode];
		}
		public function getMessage					():String {
			return							MESSAGES[STATUSES[_status]];
		}
// GENERAL UTY ///////////////////////////////////////////////////////////////////////////////////////
		//private function updateIdentity(notify:Boolean=true):void { // Grabs local variables and updates identity object
			//// This update smy identity status. That means name, appId, udid, etc. 
			//_baseIdentity.app = _appId;
			//_baseIdentity.from = _udid;
			//_baseIdentity.mode = _mode;
			//_baseIdentity.name = _name;
			//// I use the "notify" trick because I may call these 2 in a row, then I only notify on second shot
			//if (isGrouped()) { // I am already connected to network
				//if (notify) {
					//notifyNeighbors();
					//resetPairing();
				//}
			//}
		//}
		//private function updateMastering(notify:Boolean=true):void {
			//_baseIdentity.pairingApp = _pairingApp;
			//const pairingKeySource:String = _pairingPin + (isSlave() ? _pairingApp : _appId);
			//Debug.debug(_debugPrefix, "Creating key using: " + pairingKeySource);
			//
			//// Create and update pairing key - if I am slave the key is generated with the app I expect. If I am a master I generate it with my app id.
			//_baseIdentity.key = _pairingKey = MD5.hash(pairingKeySource); // Create pairing key
			//// I use the "notify" trick because I may call these 2 in a row, then I only notify on second shot
			//// If  I am already grouped (connected to network) I update my pairing initiation, and in case re-pair with new slave/master info
			//if (isGrouped()) { // I am already connected to network
				//if (notify) {
					//notifyNeighbors();
					//resetPairing();
				//}
			//}
		//}
		protected function setDisconnected				():void {
			if (_connected && _grouped) {
				//resetNeighbourHolders				();
				_connected = _grouped			= false;
				broadcastEvent					(EVT_DISCONNECTED);
				disconnect						();
				Debug.debug					(_debugPrefix, "RTMFP Connection Lost");
				setStatus						(1);
				startConnectionCheck				();
			}
		}
		//private function resetNeighbourHolders			():void {
			//_counters = {M:0, S:0, N:0, O:0, TOT:0};
			//_neighborsById = {};
			//_commandsWaitingReceipt = {};
			//_neighborsByMode = {M:{}, N:{}, S:{}};
			//_neighborsObjects = new <Object>[];
			//_neighborsNames = new <String>[];
		//}
// KEEP ALIVE CONNECTION ///////////////////////////////////////////////////////////////////////////////////////
		protected var _keepingAlive:Boolean; // This means a keep alive operation is in progress
		protected function startConnectionCheck():void { // Kepps running throughout the whole journey
			if (_keepingAlive || !_keepAlive) return; // If an operation is already in proress or keep alive is switched off just abort
			UExec.time(KEEP_ALIVE_INTERVAL, checkConnectionIsActive);
			_keepingAlive = true;
		}
			protected function checkConnectionIsActive():void {
				if (_keepingAlive && !isGrouped()) {
					_keepingAlive = false;
					Debug.debug(_debugPrefix, "Detected a loss of connection. Triggering reconnect.");
					connect();
				}
				else {
					_keepingAlive = false;
					startConnectionCheck();
				}
			}
		protected function endConnectionCheck():void { // This is only called if user stops with keepAlive(false);
			_keepingAlive = false; // This makes that a next check, the check is not performed.
		}
// PAIRING MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		//private function resetPairing():void {
			//// This resets all pairing parameters, and sets me in status previous to pairing, and brings me back to pre-paired status, checks also again if I have to pair
			//Debug.debug(_debugPrefix, "Reset pairing status.");
			////_pairedNeighbor = null;
			//setStatusToUnpaired();
			//checkPairingInitiation();
		//}
		
		//private function checkPairingNeighbor			(o:Object):void { 
			//// This is called when a neighbor is announced, or welcomed, or updated, so I can do internal pairing operations if I am not paired, or if I am paired wih this guy.
			//Debug.debug						(_debugPrefix, "Neighbor updated or new neighbor detected. Checking if we are paired, or if I should pair with him.");
			////if (isPaired() && USE_STRICT_PAIRING) { // I am already paired with someone, let's check if I need to do stuff for this guy
				////if (o.from == _pairedNeighbor.from) { // Yes, the new or updated guy is the one I was previously paired with. So I need to reset the pairing status.
					////Debug.debug				(_debugPrefix, "He was paired with me. Lets proceed re-pairing.");
					////resetPairing				();
				////}
			////}
			////else { // I am not paired, I check for initiaion
				//checkPairingInitiation				();
			////}
		//}
		
		// This has to be called everytime somethig changes either in neighbors or myself.
		// Pairing works, that a master looks for a slave, and if found asks to pair... first he tries the key inside, otherwise slave prompts to change pin
		//private function checkPairingInitiation			():void {
			//// This is called ONLY by pairing utilities, nowhere else.
			//// I call this when I am not paired and I need to check if I can pair with someone.
			//// Proceed with checks - So far pairing initiation is done ONLY if I am a master
			//Debug.debug						(_debugPrefix, "Checking if I can pair with neighbors...");
			//if (isMaster()) { // If I am Master, I need to look for the slave I am looking for (app ID will be enough)
				//Debug.debug					(_debugPrefix, "I am a MASTER looking for my slaves...");
				//for each (var o:Object in _neighborsByMode.S) {
					//if (checkForMySlave(o))		return;
				//}
			//}
			//else if (isSlave()) { // If I am a slave, I need to look for a Master who I am expecting, and probably notify him of an update so he can join me
				//Debug.debug					(_debugPrefix, "I am a slave. I just wait for my master to connect.");
			//}
		//}
				//private function checkForMySlave		(o:Object):Boolean {
					//trace("Looking for alsve: " + Debug.object(o));
					//trace("o.app",o.app,o);
					//trace("_pairingApp",_pairingApp,o.app);
					//if (o.app == _pairingApp) { // I found my paired APP!!!!!
						//Debug.debug			(_debugPrefix, "I have found a slave with my pairing app: " + o.name);
						//// Check if group is the same
						//if (o.group != _groupId) {
							//Debug.debug		(_debugPrefix, "This guy belongs to another group: " + o.group + ", he is not my slave.");
							//return			false;
						//}
						//// This check is done only if using STRICT PAIRING, that means, looking EXACTLY for the UDID of the guy I was previously paired with, or I am expecting
						////if (USE_STRICT_PAIRING) {
							////if (_slaveUDID && _slaveUDID.length > 2) {
								////if (o.from == _slaveUDID) {
									////Debug.debug	(_debugPrefix, "I have found exactly the slave I was looking for!!!");
									////return true;
								////}
								////else {
									////Debug.debug	(_debugPrefix, "I have found a guy with the right app, but he is not the ID I am precisely looking for: " + _slaveUDID);
									////return		false;
								////}
							////}
						////}
						//Debug.debug			(_debugPrefix, "I have found my slave with App ID, storing his udid information: " + o.from);
						//pairWithSlave			(o);
						//return				true;
					//}
					//return					false;
				//}
				//private function checkForMyMaster	(o:Object):Boolean {
					//return					false;
				//}
		//private function pairWithSlave				(o:Object):void {
			//// Asks a slave to accept me as a master
			//broadcastEvent						(EVT_PAIRREQUEST, o);
			//sendCommandTo						(o.from, "IAMYOURMASTER");
		//}
		//private function checkPairingRequestFromMaster	(o:Object):void {
			//// A guy sent me a IAMYOURMASTER command, here I answer to him
			//if (isMyMaster(o)) { // YES I have found my master!!!
				//// I just overwrite ANY previous pairing from a master with this master
				//sendYesYouAre					(o);
				//Debug.debug					(_debugPrefix, "I have surrendered and paired to my master: " + o.name);
			//}
			//else {
				//sendNoWay					(o, "Security keys do not match.");
			//}
		//}
		//private function isMyMaster					(o:Object):Boolean { // Confirm that he is my master
			//// When a master asks me to be his slave, I check with this that he is the one I am waiting for
			//if (_pairingKey != o.key)				return false; // Key is different, just return false
			//return							isSlave(); // Key is OK, so now I accept a master IF I am a slave
		//}
		//private function isMySlave					(o:Object):Boolean { // Confirm that he is my slave
			//// When a master asks me to be his slave, I check with this that he is the one I am waiting for
			//if (_pairingKey != o.key)				return false; // Key is different, just return false
			//return							isMaster(); // Key is OK, so now I accept a slave IF I am a master
		//}
		//private function setUserAsPairingNeighbor		(o:Object):void {
			//// I have received a YESYOUARE answer from slave, or I have accepted my master, I set my status to paired
			//_pairedNeighbor						= o;
			//setStatus							(8);
			//broadcastEvent						(EVT_PAIRSUCCESS);
		//}
		//private function isPairedWith				(id:String):Boolean { // If I am already paired with this gui
			//return							_pairedNeighbor && _pairedNeighbor.from == id;
		//}
// SENDING MESSAGES ///////////////////////////////////////////////////////////////////////////////////////
	// MAIN MESSAGES
		protected function announcePresence(andRequestWelcome:Boolean=false):void {
			// First time a neighbor shows up, I announce my presence to all network
			//trace("Announcing presence.");
			sendCommandToAll(andRequestWelcome ? "ANNOUNCEANDREQUEST" : "ANNOUNCE");
		}
		protected function sendWelcome				(to:String):void { // Sends a welcome in response to an announcement
			sendCommandTo						(to, "WELCOME");
		}
		protected function notifyNeighbors				():void { // This is called everytime a parameter is changed (Master to Slave, or Name change, etc.) in order to notify neighbors that I have changed my data
			if (isGrouped())						sendCommandToAll("UPDATE");
		}
		protected function analyzeAndSendPairing(data:P2PLocalCommanderMessageData):Boolean { // Whenever a message is received (ANOUNCE or else) this analyzes whether I should send the other guy a request for pairing
			Debug.debug(_debugPrefix, "analyzing pairing. Am I pairable: ",isPairable());
			if (!isPairable()) return false; // I am not pairable
			//if (isPairedInAnyWay()) return false; // I am already paired
			// check if I have to pair with sender and eventually send a "IAMYOURPAIR";
			if (data.fromUdid == _remoteUdid) {
				Debug.debug(_debugPrefix, "I have found my pair. I send him a pairing request.");
				sendCommandTo(_remoteUdid, "IAMYOURPAIR");
				return true;
			} 
			return false;
		}
		//private function sendNoWay				(o:Object, reason:String):void {
			//Debug.debug						(_debugPrefix, "Refusing pairing request from " + o.name);
			//sendCommandTo						(o.from, "NOWAY", reason);
		//}
		//private function sendYesYouAre				(o:Object):void {
			//_pairedNeighbor						= o;
			//setStatus							(8);
			//Debug.debug						(_debugPrefix, "I am now paired with " + o.name);
			//sendCommandTo						(o.from, "YESYOUARE");
		//}
	// RECEIPT
		protected function sendReceipt				(data:P2PLocalCommanderMessageData, ok:Boolean, info:String):void {
			//if (!o.receipt) {
				//Debug.debug					(_debugPrefix, "No need to send a receipt.");
				//return;
			//}
			//Debug.debug						(_debugPrefix, "Sending "+(ok ? "OK" : "FAILED")+" receipt to " + o.name + " because " + info);
			//sendCommandTo						(o.from, "RECEIPT", o.id, false, info, {success:ok});
		}
		protected function processReceipt				(data:P2PLocalCommanderMessageData):void { // I process a received receipt
			//var cmdObj						:Object = _commandsWaitingReceipt[o.arg];
			//if (cmdObj) {
				//delete						_commandsWaitingReceipt[o.arg];
				//if (o.success) {
					//Debug.debug				(_debugPrefix, "Cmd executed successfully: " + Debug.object(cmdObj.arg));
					//broadcastEvent				(EVT_RECEIPT_OK, o.arg);
				//}
				//else  {
					//Debug.debug				(_debugPrefix, "Cmd execution FAILED: " + Debug.object(cmdObj.arg));
					//broadcastEvent				(EVT_RECEIPT_KO, o.arg);
				//}
			//}
			//else {
				//Debug.error					(_debugPrefix, "Received receipt for cmd " + o.arg + " but no command is stored with that id.");
			//}
		}
	// UTY ///////////////////////////////////////////////////////////
	// SENDING BASE MESSAGE (Called COMMAND but it is not actually a command)
		protected function sendCommandToAll			(cmd:String, arg:*=null, receipt:Boolean=false, info:String=null, extraParams:Object=null):void {
			// This sends a command to ALL conneted neighbours. 
			//trace("send command to all");
			sendCommandTo						("ALL", cmd, arg, receipt, info, extraParams);
		}
		protected function sendCommandToSlave			(cmd:String, arg:*, receipt:Boolean=false, info:String=null):void { // This sends a CMD action to connected slave.
			//// arg is mandatory since the CMD method must have an ARG to send to receiving party, otherwise the CMD method is useless.
			//if (!isMaster()) {
				//Debug.error					(_debugPrefix, "I am not in MASTER mode. Cannot sendCommandToSlave: " + Debug.object(arg));
				//return;
			//}
			//if (!isPaired()) {
				//Debug.error					(_debugPrefix, "I am not paired to any slave. Cannot sendCommandToSlave: " + Debug.object(arg));
				//return;
			//}
			//if (!_pairedNeighbor) {
				//Debug.error					(_debugPrefix, "Internal critical error: I result as paired but paired neighbor is not setup!!! Aborting pairing... and forget about sendCommandToSlave " + Debug.object(arg));
				//resetPairing					();
				//return;
			//}
			//// Ok error check passed. Now I have to retrieve the ID of my paired slave in order to send a command to him only.
			//Debug.debug						(_debugPrefix, "Sending " + cmd +" to my slave: " + arg  + " : " + Debug.object(arg));
			//sendCommandTo						(_pairedNeighbor.from, cmd, arg, receipt, info);
		}
		protected function sendFeedbackToMaster			(cmd:String, arg:*, receipt:Boolean=false, info:String=null):void { // This sends a CMD action to connected slave.
			//// arg is mandatory since the CMD method must have an ARG to send to receiving party, otherwise the CMD method is useless.
			//if (!isSlave()) {
				//Debug.error					(_debugPrefix, "I am not in SLAVE mode. Cannot sendFeedbackToMaster: " + Debug.object(arg));
				//return;
			//}
			//if (!isPaired()) {
				//Debug.error					(_debugPrefix, "I am not paired to any master. Cannot sendFeedbackToMaster: " + Debug.object(arg));
				//return;
			//}
			//if (!_pairedNeighbor) {
				//Debug.error					(_debugPrefix, "Internal critical error: I result as paired but paired neighbor is not setup!!! Aborting pairing... and forget about sendFeedbackToMaster " + Debug.object(arg));
				//resetPairing					();
				//return;
			//}
			//// Ok error check passed. Now I have to retrieve the ID of my paired slave in order to send a command to him only.
			//Debug.debug						(_debugPrefix, "Sending "+cmd+" to my master: " + arg  + " : " + Debug.object(arg));
			//sendCommandTo						(_pairedNeighbor.from, cmd, arg, receipt, info);
		}
		protected function sendCommandTo(to:String, cmd:String, arg:*= null, receipt:Boolean = false, info:String = null, extraParams:Object = null):void {
			//trace("COMANDO E' ARRAYYYYYYYYYYYYYYYYYYYYY",arg, arg.length);
			var o:P2PLocalCommanderMessageData = getBaseCommandObject(to, cmd, arg, receipt);
			//o.to = to;
			//if (extraParams) for (var s in extraParams) o[s] = extraParams[s];
			sendCommand(o);
		}
		protected function getBaseCommandObject(to:String, msgType:String, msgArg:Object= null, receipt:Boolean = false, info:String = null):P2PLocalCommanderMessageData {
			// Creates tha bes NON POPULATED command object
			//var o:Object = {to:to, cmd:cmd, id:UText.getRandomString(4), group:_groupId};
			var data:P2PLocalCommanderMessageData = UMem.getInstance(P2PLocalCommanderMessageData);
			// Populate from
			data.fromVersion = VERSION;
			data.fromGroup = _groupId;
			data.fromMode = _mode;
			data.fromName = _userName;
			data.fromUdid = _localUdid;
			data.fromApp = _generalApp;
			// Populate to
			data.toUdid = to;
			// Populate message
			data.msgType = msgType;
			data.msgArgument = msgArg;
			data.msgReceipt = receipt;
			// Setup randon ID
			data.msgId = UText.getRandomString();
		
			//trace("creo command", data, Debug.object(data));
			
			
			//var o:Object = {from:UCode.duplicateObject(_dataSender)};
			//o.to = {};//  UCode.duplicateObject(_dataRecipient);
			//o.to.udid = to; // ALL or _recipientUdid
			//o.to.name = _userName;
			//o.msg = {}; // UCode.duplicateObject(_dataMessage);
			//if (arg) o.msg.arg = arg;
			//if (cmd) o.msg.cmd = cmd;
			//if (info) o.msg.info = info;
			//o.msg.id = UText.getRandomString(4);
			//if (receipt) {
				//_commandsWaitingReceipt[o.msg.id] = o;
				//o.msg.receipt = true;
			//}
			return data;
		}
		protected function sendCommand(o:P2PLocalCommanderMessageData):void {
			//trace("1");
			if (checkActive("Send command")) return;
			//trace("2");
			//Debug.debug(_debugPrefix, "Sending command: " + o  + " : " + Debug.object(o));
			if (!isGrouped()) {					// Can't send messages if I am not successfully AT LEAST grouped
				Debug.error(_debugPrefix, "My status is " + getStatusName() + " cannot send command.");
				return; 
			}
			Debug.debug(_debugPrefix, "SEND " + o);
			_group.post(o);
			UMem.storeInstance(o);
		}
		protected function checkActive(action:String ="Action"):Boolean {
			if (!_active) {
				Debug.debug(_debugPrefix, action + " aborted because not active.");
				return true;
			}
			return false;
		}
		
// RECEIVING MESSAGES ///////////////////////////////////////////////////////////////////////////////////////
		protected function processReceivedMessage(o:Object):Boolean {
			if (checkActive("Process received message")) return false;
			//return false;
			var data:P2PLocalCommanderMessageData = convertAndCheckReceivedObject(o);
			if (!data) {
				Debug.error(_debugPrefix, "Message received is not standard. Message process aborted.");
				return false;
			}
			
			
			
			
			const sameApp:Boolean = data.fromApp == _generalApp;
			const forMe:Boolean = data.toUdid == "ALL" || o.toUdid == _localUdid;
			const sameGroup:Boolean = data.fromGroup== _groupId || ACCEPT_FROM_ALL_GROUPS;
			const accepted:Boolean = sameApp && sameGroup && forMe;
			if (!accepted) {
				Debug.debug(_debugPrefix, "Message refused> sameApp:"+sameApp,"forMe:"+forMe,"sameGroup:"+sameGroup);
				return false;
			}
			//return false;
			
			Debug.debug(_debugPrefix, "RECEIVED " + data);
			// Ok, I can process this message. Check if they need a receipt.
			//const receipt:Boolean = o.msg.receipt;
			var methodExecuted:Boolean; /* TO BE IMPLEMENTED */
			var needsReceipt:Boolean; /* TO BE IMPLEMENTED */
			var hasMethod:Boolean;
			//var msgType:String = data.msgType;
			//if (data.fromrece
			// Check if there is a method
			try {
				hasMethod = Boolean(this["processCommand_" + data.msgType]);
			} catch(e:Error) {
				Debug.error(_debugPrefix, "Command " + data.msgType + " was not found in Class.");
				return false;
			}
			// Method found
			if (hasMethod) {
				_lastReceivedCommand = data;
				methodExecuted = this["processCommand_" + data.msgType](data);
				needsReceipt = data.msgReceipt && data.msgType != "RECEIPT"; // Receipts cannot ask for another receipt
				//if (!methodExecuted) Debug.debug(_debugPrefix, "Command returned");
			} 
			// Message was processed successfully
			return true;
		}
				protected function convertAndCheckReceivedObject(o:Object):P2PLocalCommanderMessageData { // If the message DOES NOT fit into P2PComm standard (message wil be ignored)
					// Check commands are allowed
					try {
						var data:P2PLocalCommanderMessageData = UMem.getInstance(P2PLocalCommanderMessageData, o);
					} catch (e:Error) {
						Debug.error(_debugPrefix, e);
						return null;
					}
					//trace("DATAAAAAAAAAAAAaAA" + Debug.object(data));
					if (ALLOWED_COMMANDS.indexOf(data.msgType) == -1) return null;
					// Check modes are allowed
					if (!MODES[data.fromMode]) return null; // Mode is not one of the allowed modes
					// Command is standard
					return data;
				}
		protected function processCommand_MSG(data:P2PLocalCommanderMessageData):Boolean { // I have received a chat message. It always returns true.
			//broadcastEvent(EVT_MSG, o.from.name, o.msg.arg);
			return true;
		}
		
		
		
		
		
		protected function processCommand_ANNOUNCE(data:P2PLocalCommanderMessageData):Boolean { // I have received a messge from a client introducing himself
			Debug.debug(_debugPrefix, data.fromName,data.fromUdid, " announced himself.");
			//sendWelcome						(o.from);
			//setupNeighborData					(o);
			analyzeAndSendPairing(data);
			return true;
		}
		
		
		
		
		
		
		protected function processCommand_ANNOUNCEANDREQUEST(data:P2PLocalCommanderMessageData):Boolean { // I have received a messge from a client introducing himself
			Debug.debug(_debugPrefix, data.fromName,data.fromUdid, " announced himself and requested a WELCOME back..");
			sendWelcome(data.fromUdid);
			analyzeAndSendPairing(data);
			//setupNeighborData					(o);
			return true;
		}
		//protected function processCommand_UPDATE		(data:P2PLocalCommanderMessageData):Boolean { // A neighbor has updated his data. If I didn't previously know neighbor, I treat this as an ANNOUNCE
			//var update							:Boolean = Boolean(getNeighborById(o.from));				
			//Debug.debug						(_debugPrefix, o.name + " updated his data.");
			//setupNeighborData					(o);
			//if (!update) {
				//Debug.debug					(_debugPrefix, "I didn't have this user in memory before, therefore I send him a welcome.");
				//sendWelcome					(o.from);
			//}
			//return							true;
		//}
		protected function processCommand_WELCOME(data:P2PLocalCommanderMessageData):Boolean { // A client has replied to my introduction message
			//Debug.debug(_debugPrefix, data.fromUdid,data.fromName, " welcomed me.");
			//if (isAnnounced(false)) { // If I am announced. This happens only once, I either move to WELCOMED or MASTER or SLAVE
				//setStatusToUnpaired				();
			//}
			//// This WELCOME, if I am a slave, can arrive AFTER my MASTER already grabbed me. So if I am already paired with him, on welcome nothing is changed since the announce.
			//if (isPaired() && isPairedWith(o.from)) {
				//Debug.debug					(_debugPrefix, "I know this user, I am already paired with him. No action required.");
			//}
			//else {
				//setupNeighborData				(o);
			//}
			return true;
		}
		protected function processCommand_IAMYOURPAIR(data:P2PLocalCommanderMessageData):Boolean { // A client has replied to my introduction message
			Debug.debug(_debugPrefix, data.identity, "send me a pairing request."); 
			if (isPairable() && data.fromUdid == _remoteUdid  && data.toUdid == _localUdid) setSatusToPaired();
			else {
				trace(isPairable());
				Debug.warning(_debugPrefix, "PAIRING REQUEST REFUSED, remote:"+_remoteUdid+" local:"+_localUdid + data);
				
			}
			return isPairedInAnyWay();
		}
		protected function processCommand_IAMYOURMASTER(data:P2PLocalCommanderMessageData):Boolean { // Someone claims he is my master!
			//Debug.debug						(_debugPrefix, data.identity + " claims he is my MASTER?");
			// Here I have several checks to do. I may be waiting for an EXACT user. By now I only check if key is correct.
			//setupNeighborData					(o);
			//checkPairingRequestFromMaster			(o);
			return							true;
		}
		protected function processCommand_NOWAY		(data:P2PLocalCommanderMessageData):Boolean { // He is not my slave...
			//Debug.debug						(_debugPrefix, data.identity + " says he is not my slave because: " + o.arg);
			//broadcastEvent						(EVT_PAIRREFUSED);
			return							true;
		}
		protected function processCommand_YESYOUARE	(data:P2PLocalCommanderMessageData):Boolean { // He is not my slave...
			//setUserAsPairingNeighbor				(o);
			//Debug.debug						(_debugPrefix, o.name + " is now paired as my slave.");
			return							true;
		}
		protected function processCommand_CMD(data:P2PLocalCommanderMessageData):Boolean { // He is not my slave...
			//Debug.debug(_debugPrefix, o.from.udid + " sent me a comand ",o.msg.arg, Debug.object(o.msg.arg));
			//trace("HO RICEUTO UN COMANDOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
			return processReceivedCommand(data);
		}
		protected function processCommand_RECEIPT		(data:P2PLocalCommanderMessageData):Boolean { // I received a command receipt from a slave...
			//Debug.debug						(_debugPrefix, o.from.udid + " sent me a receipt.");
			//processReceipt						(o);
			return							true;
		}
		protected function processCommand_FEEDBACK	(data:P2PLocalCommanderMessageData):Boolean { // I received a feedback from a slave...
			//Debug.debug						(_debugPrefix, o.from.udid + " sent me a feedback.");
			return							processReceivedFeedback(data);
		}
// RECEIVED COMMAND MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		protected function processReceivedCommand(data:P2PLocalCommanderMessageData):void {
			//var ok							:Boolean = isMyMaster(o);
			//Debug.debug						(_debugPrefix, ok ? "My master sent me a command, and I will execute it." : "This is not my master. Command is refused.");
			//broadcastEvent						(ok ? EVT_EXEC : EVT_EXECFAIL, o.arg);
			//sendReceipt						(o, ok, ok ? "Thank you master I executed your command." : "I refuse your command because you are not my master.");
			//if (!isPaired() || !isPairedWith(o.from)) {
				//Debug.debug					(_debugPrefix, "I am not paired, or I was paired with someone else. I re-pair with this guy.");
				//checkPairingRequestFromMaster		(o);
			//}
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_EXEC, data.msgArgument);
			//broadcastEvent(EVT_EXEC, data.msgArgument);
		}
		protected function processReceivedFeedback		(data:P2PLocalCommanderMessageData):void {
			// He is my slave and I trust his feedback
			//var ok							:Boolean = isMySlave(o);
			//Debug.debug						(_debugPrefix, ok ? "My slave sent me a feedback." : "This is not my slave. Feedback is refused.");
			//broadcastEvent						(ok ? EVT_FEEDBACK : EVT_FEEDBACKFAIL, o.arg);
		}
// NEIGHBOR MANAGEMENT //////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//private function setupNeighborData			(o:Object):void {
			///* 	This sets up data for each neighbor who announces, welcomes or updates. 
				//It can be called also when other messages are received, and only if neighbor is not yet setup.
			//
			//*/
			//// first check if neighbor has already been stored, and in case destroy the old data object
			//if (_neighborsById[o.from]) {
				//deleteNeighborData				(o.from);
			//}
			//// Setup neighbor data
			//_neighborsById[o.from]				= o;
			//_neighborsByMode[o.mode][o.from]		= o; // This works, integrity of message has been checked upon receipt otherwise it doesn't get processed
			//_neighborsObjects.push				(o);
			//_neighborsNames.push					(o.name);
			//o.index							= _neighborsObjects.length-1;
			//// Update counters
			//3[o.mode]					++;
			//_counters.TOT						++;
			//broadcastEvent						(EVT_NEIGHBOR_DATA, UCode.duplicateObject(o));
			//broadcastEvent						(EVT_NEIGHBORS_UPDATE);
			//// After I setup a neigbor data, I do check if pairing logic needs to do something with it
			//checkPairingNeighbor					(o);
		//}
		//private function deleteNeighborData			(id:String):void { // Destroy stored instance of neghbor data
			//// Deletion is done ONLY on update, since disconnection is NOT registered
			//var o								:Object = _neighborsById[id];
			//var index							:int = _neighborsObjects.indexOf(o);
			//_neighborsObjects.splice				(index, 1);
			//_neighborsNames.splice				(index, 1);
			//delete							_neighborsById[id];
			//// Update counters
			//_counters[o.mode]					--;
			//_counters.TOT						--;
			//// To make sure, I just delete them from each array
			//delete							_neighborsByMode.M[id];
			//delete							_neighborsByMode.N[id];
			//delete							_neighborsByMode.S[id];
		//}
// INTERNAL UTY ///////////////////////////////////////////////////////////////////////////////////////
	// STATUS
		protected function getStatusName				():String {
			return							STATUSES[_status];
		}
		protected function getStatus					():int {
			return							_status;
		}
		protected function setStatus					(i:int):void {
			if (_status == i)						return;
			Debug.debug						(_debugPrefix, "Status changed from " + STATUSES[_status] + " to " + STATUSES[i]);
			_status							= i;
			broadcastEvent						(EVT_STATUS_CHANGE);
		}
		protected function setStatusToUnpaired():void { // This sets the correct status after announced. 
			//It can be colled each time a user receives a welcome. Or it can be called to reverse pairing status..
			// BEWARE - this will reset status to before pairing EVEN if I am already paried.
			var broadcastUnpaired:Boolean = isPaired(); // Register if I have to broadcast pair lost before changing status
			if (isPairable()) setStatus(6);
			if (broadcastUnpaired) broadcastEvent(EVT_PAIRLOST); // If I have lost pairing I broadcast the event
		}
		protected function setSatusToPaired():void {
			if (isPairable()) {
				if (isMaster()) setStatus(8);
				else if (isSlave()) setStatus(9);
				else if (isPair()) setStatus(7);
				broadcastEvent(EVT_PAIRSUCCESS);
			}
		}
	
		
		
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
	// NetGroup
		public function onGroupConnectionStatus(e:NetStatusEvent):void {
			// Analyse connection status
			NetStatusEventAnalyzer.analyze(e);
			Debug.debug(_debugPrefix, NetStatusEventAnalyzer.getCode());
			var genEvent:String = NetStatusEventAnalyzer.getGeneralEvent();
			if (this.hasOwnProperty(genEvent)) this[genEvent]();
			else {
				Debug.debug(_debugPrefix,genEvent+"()\n",e,Debug.object(e.info)+"\n------------------------------------");
				Debug.error(_debugPrefix, "NetGroup:",genEvent,"not defined in Class");
			}
		}
		public function onNetGroupConnectSuccess():void { // Somehow this should be called by NetGroup, but it is called by NetConnection
			Debug.debug(_debugPrefix, "Group connection successful.");
			if (isConnected()) {
				setStatus(3);	
				Debug.debug(_debugPrefix, "Waiting for neighbors to show up...");
			}
			_grouped = true;
			broadcastEvent(EVT_CONNECTED);
		}
		public function onNetGroupNeighborConnect():void { // When a new neighbour is detected on network
			Debug.debug(_debugPrefix, "New neighbor detected. If no welcome arrives it means he belongs to another group. Am I grouped: " + isGrouped(true) );
			if (isGrouped(true)) announcePresence(_requestWelcomeOnAnnounce);
		}
		public function onNetGroupNeighborLost():void {
			Debug.debug(_debugPrefix, "Neighbor lost.");
			resetConnection();
		}
		public function onNetGroupPostingReceived():void {
			Debug.debug(_debugPrefix, "Post received.");
// 			Debug.debug						(_debugPrefix, Debug.object(NetStatusEventAnalyzer.getEvent().info));
			var o:* = NetStatusEventAnalyzer.getEventInfoMessage();
			if (o && o is Object) {
				//Debug.debug(_debugPrefix, "RECEIVE " + Debug.object(o));
				processReceivedMessage(o);
			}
			else {
				Debug.error(_debugPrefix, "Received unrecognized message: " + Debug.object(o));
			}
		}
		public function onNetGroupConnectLost			():void { // Somehow this should be called by NetGroup, but it is called by NetConnection
			Debug.debug						(_debugPrefix, "NetGroup lost.");
			setDisconnected						();
		}
	// NetConnection
		public function onNetConnectionStatus			(e:*):void {
			// Analyse connection status
			NetStatusEventAnalyzer.analyze			(e);
// 			Debug.debug						(_debugPrefix, NetStatusEventAnalyzer.getCode());
			var genEvent						:String = NetStatusEventAnalyzer.getGeneralEvent();
			if (this.hasOwnProperty(genEvent))		this[genEvent]();
			else {
				Debug.error					(_debugPrefix, "NetConnection:",genEvent,"not defined in Class");
				Debug.debug					(_debugPrefix,genEvent+"()\n",e,Debug.object(e.info)+"\n------------------------------------");
			}
		}
		public function onNetConnectionConnectSuccess():void {
			Debug.debug(_debugPrefix, "RTMFP Connection Successful.");
			if (isIdle()) {
				setStatus(2);
				//initializeGroup					();
				_groupSpec = new GroupSpecifier(_groupId);
				_groupSpec.postingEnabled = true;
				_groupSpec.ipMulticastMemberUpdatesEnabled = true;
				/* 	There is a bug in addIPMulticastAddress(), if I don't set "" but set null as last parameter, I get an ArgumentError 
					That's why I need to split address in 2, and then set "" as last argument. 
				*/
				var addressPort:Array = _multicastAddress.split(":");
				try {
					_groupSpec.addIPMulticastAddress(addressPort[0], addressPort[1], "");
				}
				catch(e) {
					Debug.error(_debugPrefix, "Error setting multicast address: " + e);
				}
				_group = new NetGroup(_nc, _groupSpec.groupspecWithAuthorizations());
				_group.addEventListener(NetStatusEvent.NET_STATUS, onGroupConnectionStatus);
			}
			_connected = true;
		}
		
		
		public function onNetConnectionConnectLost		():void {
			Debug.debug						(_debugPrefix, "NetConnection lost.");
			setDisconnected						();
		}
// GET SET //////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function get lastReceivedCommand():P2PLocalCommanderMessageData 
		{
			return _lastReceivedCommand;
		}
	}
}