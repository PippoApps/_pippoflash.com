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
	
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem;
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMemDispatcher;
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
		private static const VERSION				:String = "0.1"; // Version of this commander
		private static const MODES					:Object = {N:"Neutral", M:"Master", S:"Slave"};
		private static const DEFAULT_NET_CONNECTION	:String = "rtmfp:";
		private static const STATUSES				:Vector.<String> = new <String>["IDLE", "DISCONNECTED", "CONNECTED", "GROUPED", "ANNOUNCED", "WELCOMED", "MASTER", "SLAVE", "PAIRED"];
		private static const MESSAGES			:Object = {
			IDLE							:"Welcome to P2PComm Console.",
			DISCONNECTED					:"Disconnected from network..",
			CONNECTED					:"Connected to network.",
			GROUPED						:"Connected to P2P group.",
			ANNOUNCED					:"Announced to neighbors.",
			WELCOMED					:"Welcomed by neighbors.",
			MASTER						:"Waiting for my slave...",
			SLAVE						:"Waiting for my master...",
			PAIRED						:"Paired."
			
		};
		private static const ALLOWED_COMMANDS		:String = "ANNOUNCE,WELCOME,UPDATE,MSG,IAMYOURMASTER,YESYOUARE,NOWAY,IAMYOURSLAVE,CMD,RECEIPT,FEEDBACK"; // Used to check that commands received are allowed
		public static const AUTO_CONNECT			:Boolean = false; // Connects on initialization
		private static const KEEP_ALIVE_INTERVAL		:int = 5; // Seconds to keep alive
		private static const ACCEPT_FROM_ALL_GROUPS	:Boolean = false; // Also processes commends from another group
		//private static const USE_STRICT_PAIRING		:Boolean = false; // Using strict pairing, makes it so that once pairing is established, I will look for that precise user ID, not just for key
		// EVENTS
		private static const EVT_STATUS_CHANGE		:String = "onP2PStatus"; // () - When there is a change of status in P2PComm
		private static const EVT_CONNECTED			:String = "onP2PConnected"; // ()
		private static const EVT_DISCONNECTED		:String = "onP2PDisconnected"; // ()
		private static const EVT_MSG				:String = "onP2PMsgReceived"; // ({name:String, msg:String}) -  When a chat message is received (for me or for all)
		private static const EVT_NEIGHBOR_DATA		:String = "onP2PNeighborUpdate"; // (neighbor:Object) - When ONE neighbor calls ANNOUNCE, WELCOME or UPDATE
		private static const EVT_NEIGHBORS_UPDATE	:String = "onP2PNeigborsUpdate"; // Every time neighbors data is updated (counters, names, etc.)
		// PAIRING EVENTS
		private static const EVT_PAIRREQUEST			:String = "onP2PSlavePairingRequest"; // I am requesting my slave to be paired
		private static const EVT_PAIRREFUSED			:String = "onP2PSlavePairingRefused"; // The slave said I cannot pair with him
		private static const EVT_PAIRSUCCESS			:String = "onP2PPairingSuccess"; // I am successfully paired with either my slave or my master
		private static const EVT_PAIRLOST			:String = "onP2PPairingLost"; // I am not paired anymore
		// COMMANDS
		private static const EVT_EXEC				:String = "onP2PCommand"; // (arg:*) I received a P2P command from a MASTER and confirmed he was my master
		private static const EVT_EXECFAIL			:String = "onP2PCommandFail"; // (arg:*) I received a P2P command but he is not my master
		private static const EVT_RECEIPT_OK			:String = "onP2PCommandSuccess"; // (o.arg:Object) I sent a command waiting for receipt, receipt received, and the command was executed successfully on the target machine
		private static const EVT_RECEIPT_KO			:String = "onP2PCommandFailed"; // (o.arg:Object) I sent a command waiting for receipt, and the command was failed on target machine!
		// FEEDBACKS
		private static const EVT_FEEDBACK			:String = "onP2PFeedback"; // (arg:*) I received a P2P feedback from a SLAVE and confirmed he was my slave
		private static const EVT_FEEDBACKFAIL			:String = "onP2PFeedbackFail"; // (arg:*) I received a P2P feedback but he is not my slave
		// USER DATA - This data has default values in it, but it can be amended
		private var _groupId						:String = "myGroup/groupOne";
		private var _multicastAddress				:String = "225.225.0.1:30303";
		// SYSTEM
		private var _nc							:NetConnection;
		private var _groupSpec					:GroupSpecifier;
		private var _group						:NetGroup;
		private var _status						:uint = 0; // Status 0 is IDLE
// 		private var _p2p							:P2P;
		// SWITCHES
		private static var _verbose					:Boolean = true;
		// DATA
		private var _id							:String;
		
		// MARKERS
		private var _connected					:Boolean;
		private var _grouped						:Boolean;
		private var _keepAlive						:Boolean = true; // Keep alive defaults to true
		// IDENTITY VARIABLES
		private var _mode						:String = "N"; // Defaults to neutral
		private var _udid						:String; // UDID taken from USystem (Application dependant. It can't be shared between apps.)
		private var _name						:String; // Screen name for the local sender
		private var _appId						:String; // Taken from _mainApp.getAppId();
		private var _baseIdentity					:Object = { // This is the base of all commands. Whatever I do, a copy of this object is sent populated where it needs to be
			// Fixed values - MY OWN - these do not change overtime.
			from :null, // String - UDID of sender
			app :null, // String - App ID of sender (general name)
			group :null, // Group ID of the messages - general large group
			mode :null, // String - M, S, or N (Master, Slave or Neutral) - This usually doesnt change, but it MAY change
			name :null, // Screen name for user
			ver :null, // String - MY Version of P2PGroupLocalCommander
			// Variable values - coming from OTHER PARTY or sent to OTHER PARTY
			to								:null, // String - "ALL" or UDID of recipient
			type								:null,	 // String - Type of message (ANNOUNCE, WELCOME, UPDATE, MSG, EXEC, RECEIPT, IWANTYOU, NOWAY, PROVEME, HANDSHAKE)
			id								:null, // String - Unique ID of message (in order to confirm execution)
			arg								:null, // * - Argument of the message
			key								:null, // String - a pairing key to be passed back and forth between slave and master
			pairingApp							:null, // String with the app I am looking for (if any)
			receipt							:null, // Boolean - If I need a receipt that this message has been received
			success							:null, // Boolean - Positive or negative response (only on receipt, if message has been executed)
			info								:null // String - Verbose info regarding the message (this is metadata, not intended to be used in app, but only for debugging purposes)
		};
		// COMMANDS AND NEIGHBORS
		private var _commandsWaitingReceipt			:Object; // Sent commands awaiting for a receipt are stored here
		private var _neighborsById					:Object; // Stores announcement object received on ANNOUNCE by user ID
		private var _neighborsByMode				:Object; // Stores neighbors by their mode {M:{}, S:{}, N:{}}
		private var _neighborsNames				:Vector.<String>; // List of neighbors name - INDEX is ID
		private var _neighborsObjects				:Vector.<Object>; // List ofall objects (indexInArray is also stored in neighbors object) - INDEX is ID
		// SLAVE/MASTER VARS
		//private var _slaveUDID					:String = ""; // UDID of expected slave
		//private var _masterUDID					:String = ""; // UDID of expected master
		private var _pairingKey					:String = ""; // Unique key generated by MASTER app id and a PIN generated by slave (USERS have to input manually a PIN generated by slave on screen)
		private var _pairingPin						:String = ""; // Unique PIN generated by slave (for both MASTER and SLAVE mode)
		private var _pairingApp					:String = ""; // MASTER app to be mixed with PIN in order to generate key
		private var _pairedNeighbor					:Object; // Stored the identity object of paired neighbor. For both slave and master.
		// STATUS OF GROUP
		private var _counters						:Object = { // This can be used as keywords substitute
			M:0, // Masters
			N:0, // Neutrals
			S:0, // Slaves
			TOT:0 // Total
		};
 		// COUNTERS
		private var _messagesSent					:int = 0; // Counts messages sent
		private var _messagesReceived				:int = 0; // Counts messages received
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function P2PGroupLocalCommander		(id:String, appId:String, udid:String, name:String="TestUser", mode:String="N", pin:String="0000", groupId:String=null, multicastAddress:String=null):void {
			super(id); // This is NOT singleton, so ID can't be the same
			_id = id;
			_baseIdentity.ver = VERSION;
			if (groupId) _groupId = groupId;
			if (multicastAddress) _multicastAddress = multicastAddress;
			updateUser(mode, name, appId, udid, false); // I am not connected yet. No need to notify.
			//updatePairing(isSlave() ? udid, pin);
			Debug.debug						(_debugPrefix, "Ver " + VERSION + " on " + _groupId + ":" +_multicastAddress + " started as: " + getMode());
			Debug.debug						(_debugPrefix, "Application ID: " + _appId);
			Debug.debug						(_debugPrefix, "UDID: " +_udid);
			resetNeighbourHolders					();
			if (AUTO_CONNECT)					connect();
		}
// STARTUP ///////////////////////////////////////////////////////////////////////////////////////
		private function initializeNetwork				():void {
			Debug.debug						(_debugPrefix, "Initializing network...");
			_nc								= new NetConnection();
			_nc.addEventListener					(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
			_nc.addEventListener					(SecurityErrorEvent.SECURITY_ERROR, onNetConnectionStatus);
    			_nc.connect						(DEFAULT_NET_CONNECTION);
		}
		private function initializeGroup				():void {
			// Initialize specification
			_groupSpec 						= new GroupSpecifier(_groupId);
			_groupSpec.postingEnabled 				= true;
			_groupSpec.ipMulticastMemberUpdatesEnabled = true;
// 			_groupSpec.addIPMulticastAddress			(_multicastAddress);
			/* 	There is a bug in addIPMulticastAddress(), if I don't set "" but set null as last parameter, I get an ArgumentError 
				That's why I need to split address in 2, and then set "" as last argument. 
			*/
			var addressPort						:Array = _multicastAddress.split(":");
			try {
				_groupSpec.addIPMulticastAddress			(addressPort[0], addressPort[1], "");
			}
			catch(e) {
				Debug.error						(_debugPrefix, "Error setting multicast address: " + e);
			}
			_group = new NetGroup				(_nc, _groupSpec.groupspecWithAuthorizations());
			_group.addEventListener				(NetStatusEvent.NET_STATUS, onGroupConnectionStatus);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SETUP
		public function setNetwork					(ipPort:String, groupName:String):void {
			_multicastAddress					= ipPort;
			_groupId							= groupName;
			/* TO BE IMPLEMENTED - Checks to see if it is already connected, and in case close connection and start a new one. This will more likely never be called. */
		}
		public function keepAlive					(ka:Boolean):void { // It defaults to true, can be switched of with this
			_keepAlive							= ka;
			if (_keepAlive)						startConnectionCheck();
			else								endConnectionCheck();
		}
		public function connect					():Boolean {
			if (_connected) {
				Debug.error					(_debugPrefix, "I am already connected. Call disconnect before connecting.");
				return						false;
			}
			Debug.debug						(_debugPrefix, "Connecting...");
			if (!_nc)							initializeNetwork();
			else {
				_nc.connect					(DEFAULT_NET_CONNECTION);
			}
			keepAlive							(_keepAlive);
			return							true;
		}
		public function disconnect					():Boolean {
			Debug.debug						(_debugPrefix, "Disconnecting...");
			if (_grouped) {
				_group.close					();
				_group						= null;
				_groupSpec					= null;
				_grouped						= false;
			}
			if (_connected) {
				_nc.close						();
				_connected						= false;
				return						true;
			}
			Debug.error						(_debugPrefix, "Cannot disconnect since I am not connected.");
			return							false;
		}
		public function setName					(n:String):void {
			Debug.debug						(_debugPrefix, "Changed my name into " + _name);
			updateUser							(n);
		}
		// These update functions, it is better to call them BEFORE connection
		public function updateSystem				(ipPort:String=null, group:String=null, andDisconnect:Boolean=false):void {
			if (ipPort)							_multicastAddress = ipPort;
			if (group)							_groupId = group;
			if (andDisconnect)					disconnect();
		}
		public function updateUser					(mode:String=null, name:String=null, appId:String=null, udid:String=null, notify:Boolean=true):void {
			if (mode)							_mode = mode;
			if (name)							_name = name;
			if (appId)							_appId = appId;
			if (udid)							_udid = udid;
			updateIdentity						(notify);
		}
		public function updatePairing				(pairingApp:String = null, pairingPin:String = null) {// , slaveUDID:String = null, masterUDID:String = null, notify:Boolean = true):void {
			// This updates all data regarding pairing (SLAVE/MASTER) 
			if (pairingApp)						_pairingApp = pairingApp;
			if (pairingPin)						_pairingPin = pairingPin;
			//if (slaveUDID)						_slaveUDID = slaveUDID;
			//if (masterUDID)						_masterUDID = masterUDID;
			updateMastering						(true); // (notify);
		}
		// These 3 below are called on connection done. It is a subsequent change of status.
		public function setToMaster					(pairingApp:String):void {
			// When I set to master, I setup the app I am expecting to find, check into my registered neighbors if my slave is there, and check again everytime users are updated
			updateUser							("M", null, null, null, false);
			updatePairing						(pairingApp);
		}
		public function setToSlave					(pairingApp:String):void {
			// When I am set into slave mode, I may have alreay registered an expected master, or I may wait for another master to register, I will generate the pin, and wait for his confirmation
			updateUser							("S", null, null, null, false);
			updatePairing						(pairingApp);
		}
		public function setToNeutral					(pairingApp:String):void {
			// When I am set into slave mode, I may have alreay registered an expected master, or I may wait for another master to register, I will generate the pin, and wait for his confirmation
			updateUser							("N", null, null, null, false);
			updatePairing						(pairingApp);
		}
	// DATA RETIREVAL
		public function getAllNames					():Vector.<String> {
			return							_neighborsNames;
		}
		public function getAllNeighbors				():Vector.<Object> {
			return							_neighborsObjects;
		}
		public function getNeighbor					(index):Object {
			if (_neighborsObjects[index])			return _neighborsObjects[index];
			else {
				Debug.error					(_debugPrefix, "getNeighbor() aborted. Index out of range: " + index);
			}
			return							null;
		}
		public function getNeighborById				(from:String):Object { // Returns a neighbor using his unique device id
			return							_neighborsById[from];
		}
		public function get neighborsNum				():int {
			return							_neighborsObjects.length;
		}
		public function getCounters					():Object { // Returns an object with counters i.e. {M:3, N:1, S:0, TOT:4}
			return							_counters;
		}
	// COMMANDS
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
		public function isMaster					():Boolean {
			return							_mode == "M";
		}
		public function isSlave						():Boolean {
			return							_mode == "S";
		}
		public function isNeutral					():Boolean {
			return							_mode == "N";
		}
		public function hasNeighbors				():Boolean {
			return							neighborsNum;
		}
	// STATUS CHECKS
		public function isIdle						(orHigher:Boolean=true):Boolean { // IDLE or LOST is the same thing (0, 1)
			return							checkStatus(0, orHigher) || isDisconnected(orHigher);
		}
		public function isDisconnected				(orHigher:Boolean=true):Boolean { // IDLE or LOST is the same thing (0, 1)
			return							checkStatus(1, orHigher);
		}
		public function isConnected					(orHigher:Boolean=true):Boolean {
			return							checkStatus(2, orHigher) && _connected;
		}
		public function isGrouped					(orHigher:Boolean=true):Boolean {
			return							checkStatus(3, orHigher) && _grouped;
		}
		public function isAnnounced					(orHigher:Boolean=true):Boolean {
			return							checkStatus(4, orHigher);
		}
		public function isWelcomed					(orHigher:Boolean=true):Boolean {
			return							checkStatus(5, orHigher);
		}
		public function isPairing					(orHigher:Boolean=true):Boolean { // It Means i am in MASTER or SLAVE waiting for pairing
			return							checkStatus(6, true);
		}
		public function isPaired					(orHigher:Boolean=true):Boolean { // Paired to a slave or master
			return							checkStatus(8, orHigher);
		}
			private function checkStatus			(n:int, h:Boolean):Boolean {
				return						h ? _status >= n : _status == n;
			}
	// GETTERS
		public function getMode					():String { // Returns the NAME of mode
			return							MODES[_mode];
		}
		public function getMessage					():String {
			return							MESSAGES[STATUSES[_status]];
		}
// GENERAL UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function updateIdentity				(notify:Boolean=true):void { // Grabs local variables and updates identity object
			// This update smy identity status. That means name, appId, udid, etc. 
			_baseIdentity.app					= _appId;
			_baseIdentity.from					= _udid;
			_baseIdentity.mode					= _mode;
			_baseIdentity.name					= _name;
			// I use the "notify" trick because I may call these 2 in a row, then I only notify on second shot
			if (isGrouped()) { // I am already connected to network
				if (notify) {
					notifyNeighbors				();
					resetPairing				();
				}
			}
		}
		private function updateMastering(notify:Boolean=true):void {
			_baseIdentity.pairingApp = _pairingApp;
			const pairingKeySource:String = _pairingPin + (isSlave() ? _pairingApp : _appId);
			Debug.debug(_debugPrefix, "Creating key using: " + pairingKeySource);
			
			// Create and update pairing key - if I am slave the key is generated with the app I expect. If I am a master I generate it with my app id.
			_baseIdentity.key = _pairingKey = MD5.hash(pairingKeySource); // Create pairing key
			// I use the "notify" trick because I may call these 2 in a row, then I only notify on second shot
			// If  I am already grouped (connected to network) I update my pairing initiation, and in case re-pair with new slave/master info
			if (isGrouped()) { // I am already connected to network
				if (notify) {
					notifyNeighbors();
					resetPairing();
				}
			}
		}
		private function setDisconnected				():void {
			if (_connected && _grouped) {
				resetNeighbourHolders				();
				_connected = _grouped			= false;
				broadcastEvent					(EVT_DISCONNECTED);
				disconnect						();
				Debug.debug					(_debugPrefix, "RTMFP Connection Lost");
				setStatus						(1);
				startConnectionCheck				();
			}
		}
		private function resetNeighbourHolders			():void {
			_counters							= {M:0, S:0, N:0, TOT:0};
			_neighborsById						= {};
			_commandsWaitingReceipt				= {};
			_neighborsByMode					= {M:{}, N:{}, S:{}};
			_neighborsObjects					= new <Object>[];
			_neighborsNames					= new <String>[];
		}
// KEEP ALIVE CONNECTION ///////////////////////////////////////////////////////////////////////////////////////
		private var _keepingAlive					:Boolean; // This means a keep alive operation is in progress
		private function startConnectionCheck			():void { // Kepps running throughout the whole journey
			if (_keepingAlive || !_keepAlive)			return; // If an operation is already in proress or keep alive is switched off just abort
			UExec.time						(KEEP_ALIVE_INTERVAL, checkConnectionIsActive);
			_keepingAlive						= true;
		}
			private function checkConnectionIsActive	():void {
				if (_keepingAlive && !isGrouped()) {
					_keepingAlive				= false;
					Debug.debug				(_debugPrefix, "Detected a loss of connection. Triggering reconnect.");
					connect					();
				}
				else {
					_keepingAlive				= false;
					startConnectionCheck			();
				}
			}
		private function endConnectionCheck			():void { // This is only called if user stops with keepAlive(false);
			_keepingAlive						= false; // This makes that a next check, the check is not performed.
		}
// PAIRING MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		private function resetPairing				():void {
			// This resets all pairing parameters, and sets me in status previous to pairing, and brings me back to pre-paired status, checks also again if I have to pair
			Debug.debug						(_debugPrefix, "Reset pairing status.");
			_pairedNeighbor						= null;
			setStatusToUnpaired					();
			checkPairingInitiation					();
		}
		
		private function checkPairingNeighbor			(o:Object):void { 
			// This is called when a neighbor is announced, or welcomed, or updated, so I can do internal pairing operations if I am not paired, or if I am paired wih this guy.
			Debug.debug						(_debugPrefix, "Neighbor updated or new neighbor detected. Checking if we are paired, or if I should pair with him.");
			//if (isPaired() && USE_STRICT_PAIRING) { // I am already paired with someone, let's check if I need to do stuff for this guy
				//if (o.from == _pairedNeighbor.from) { // Yes, the new or updated guy is the one I was previously paired with. So I need to reset the pairing status.
					//Debug.debug				(_debugPrefix, "He was paired with me. Lets proceed re-pairing.");
					//resetPairing				();
				//}
			//}
			//else { // I am not paired, I check for initiaion
				checkPairingInitiation				();
			//}
		}
		
		// This has to be called everytime somethig changes either in neighbors or myself.
		// Pairing works, that a master looks for a slave, and if found asks to pair... first he tries the key inside, otherwise slave prompts to change pin
		private function checkPairingInitiation			():void {
			// This is called ONLY by pairing utilities, nowhere else.
			// I call this when I am not paired and I need to check if I can pair with someone.
			// Proceed with checks - So far pairing initiation is done ONLY if I am a master
			Debug.debug						(_debugPrefix, "Checking if I can pair with neighbors...");
			if (isMaster()) { // If I am Master, I need to look for the slave I am looking for (app ID will be enough)
				Debug.debug					(_debugPrefix, "I am a MASTER looking for my slaves...");
				for each (var o:Object in _neighborsByMode.S) {
					if (checkForMySlave(o))		return;
				}
			}
			else if (isSlave()) { // If I am a slave, I need to look for a Master who I am expecting, and probably notify him of an update so he can join me
				Debug.debug					(_debugPrefix, "I am a slave. I just wait for my master to connect.");
			}
		}
				private function checkForMySlave		(o:Object):Boolean {
					trace("Looking for alsve: " + Debug.object(o));
					trace("o.app",o.app,o);
					trace("_pairingApp",_pairingApp,o.app);
					if (o.app == _pairingApp) { // I found my paired APP!!!!!
						Debug.debug			(_debugPrefix, "I have found a slave with my pairing app: " + o.name);
						// Check if group is the same
						if (o.group != _groupId) {
							Debug.debug		(_debugPrefix, "This guy belongs to another group: " + o.group + ", he is not my slave.");
							return			false;
						}
						// This check is done only if using STRICT PAIRING, that means, looking EXACTLY for the UDID of the guy I was previously paired with, or I am expecting
						//if (USE_STRICT_PAIRING) {
							//if (_slaveUDID && _slaveUDID.length > 2) {
								//if (o.from == _slaveUDID) {
									//Debug.debug	(_debugPrefix, "I have found exactly the slave I was looking for!!!");
									//return true;
								//}
								//else {
									//Debug.debug	(_debugPrefix, "I have found a guy with the right app, but he is not the ID I am precisely looking for: " + _slaveUDID);
									//return		false;
								//}
							//}
						//}
						Debug.debug			(_debugPrefix, "I have found my slave with App ID, storing his udid information: " + o.from);
						pairWithSlave			(o);
						return				true;
					}
					return					false;
				}
				private function checkForMyMaster	(o:Object):Boolean {
					return					false;
				}
		private function pairWithSlave				(o:Object):void {
			// Asks a slave to accept me as a master
			broadcastEvent						(EVT_PAIRREQUEST, o);
			sendCommandTo						(o.from, "IAMYOURMASTER");
		}
		private function checkPairingRequestFromMaster	(o:Object):void {
			// A guy sent me a IAMYOURMASTER command, here I answer to him
			if (isMyMaster(o)) { // YES I have found my master!!!
				// I just overwrite ANY previous pairing from a master with this master
				sendYesYouAre					(o);
				Debug.debug					(_debugPrefix, "I have surrendered and paired to my master: " + o.name);
			}
			else {
				sendNoWay					(o, "Security keys do not match.");
			}
		}
		private function isMyMaster					(o:Object):Boolean { // Confirm that he is my master
			// When a master asks me to be his slave, I check with this that he is the one I am waiting for
			if (_pairingKey != o.key)				return false; // Key is different, just return false
			return							isSlave(); // Key is OK, so now I accept a master IF I am a slave
		}
		private function isMySlave					(o:Object):Boolean { // Confirm that he is my slave
			// When a master asks me to be his slave, I check with this that he is the one I am waiting for
			if (_pairingKey != o.key)				return false; // Key is different, just return false
			return							isMaster(); // Key is OK, so now I accept a slave IF I am a master
		}
		private function setUserAsPairingNeighbor		(o:Object):void {
			// I have received a YESYOUARE answer from slave, or I have accepted my master, I set my status to paired
			_pairedNeighbor						= o;
			setStatus							(8);
			broadcastEvent						(EVT_PAIRSUCCESS);
		}
		private function isPairedWith				(id:String):Boolean { // If I am already paired with this gui
			return							_pairedNeighbor && _pairedNeighbor.from == id;
		}
// SENDING MESSAGES ///////////////////////////////////////////////////////////////////////////////////////
	// MAIN MESSAGES
		private function announcePresence			():void {
			// First time a neighbor shows up, I announce my presence to all network
			sendCommandToAll					("ANNOUNCE");
		}
		private function sendWelcome				(to:String):void { // Sends a welcome in response to an announcement
			sendCommandTo						(to, "WELCOME");
		}
		private function notifyNeighbors				():void { // This is called everytime a parameter is changed (Master to Slave, or Name change, etc.) in order to notify neighbors that I have changed my data
			if (isGrouped())						sendCommandToAll("UPDATE");
		}
		private function sendNoWay				(o:Object, reason:String):void {
			Debug.debug						(_debugPrefix, "Refusing pairing request from " + o.name);
			sendCommandTo						(o.from, "NOWAY", reason);
		}
		private function sendYesYouAre				(o:Object):void {
			_pairedNeighbor						= o;
			setStatus							(8);
			Debug.debug						(_debugPrefix, "I am now paired with " + o.name);
			sendCommandTo						(o.from, "YESYOUARE");
		}
	// RECEIPT
		private function sendReceipt				(o:Object, ok:Boolean, info:String):void {
			if (!o.receipt) {
				Debug.debug					(_debugPrefix, "No need to send a receipt.");
				return;
			}
			Debug.debug						(_debugPrefix, "Sending "+(ok ? "OK" : "FAILED")+" receipt to " + o.name + " because " + info);
			sendCommandTo						(o.from, "RECEIPT", o.id, false, info, {success:ok});
		}
		private function processReceipt				(o:Object):void { // I process a received receipt
			var cmdObj						:Object = _commandsWaitingReceipt[o.arg];
			if (cmdObj) {
				delete						_commandsWaitingReceipt[o.arg];
				if (o.success) {
					Debug.debug				(_debugPrefix, "Cmd executed successfully: " + Debug.object(cmdObj.arg));
					broadcastEvent				(EVT_RECEIPT_OK, o.arg);
				}
				else  {
					Debug.debug				(_debugPrefix, "Cmd execution FAILED: " + Debug.object(cmdObj.arg));
					broadcastEvent				(EVT_RECEIPT_KO, o.arg);
				}
			}
			else {
				Debug.error					(_debugPrefix, "Received receipt for cmd " + o.arg + " but no command is stored with that id.");
			}
		}
	// UTY ///////////////////////////////////////////////////////////
	// SENDING UTY
		private function sendCommandToAll			(cmd:String, arg:*=null, receipt:Boolean=false, info:String=null, extraParams:Object=null):void {
			// This sends a command to ALL conneted neighbours. 
			sendCommandTo						("ALL", cmd, arg, receipt, info, extraParams);
		}
		private function sendCommandToSlave			(cmd:String, arg:*, receipt:Boolean=false, info:String=null):void { // This sends a CMD action to connected slave.
			// arg is mandatory since the CMD method must have an ARG to send to receiving party, otherwise the CMD method is useless.
			if (!isMaster()) {
				Debug.error					(_debugPrefix, "I am not in MASTER mode. Cannot sendCommandToSlave: " + Debug.object(arg));
				return;
			}
			if (!isPaired()) {
				Debug.error					(_debugPrefix, "I am not paired to any slave. Cannot sendCommandToSlave: " + Debug.object(arg));
				return;
			}
			if (!_pairedNeighbor) {
				Debug.error					(_debugPrefix, "Internal critical error: I result as paired but paired neighbor is not setup!!! Aborting pairing... and forget about sendCommandToSlave " + Debug.object(arg));
				resetPairing					();
				return;
			}
			// Ok error check passed. Now I have to retrieve the ID of my paired slave in order to send a command to him only.
			Debug.debug						(_debugPrefix, "Sending " + cmd +" to my slave: " + arg  + " : " + Debug.object(arg));
			sendCommandTo						(_pairedNeighbor.from, cmd, arg, receipt, info);
		}
		private function sendFeedbackToMaster			(cmd:String, arg:*, receipt:Boolean=false, info:String=null):void { // This sends a CMD action to connected slave.
			// arg is mandatory since the CMD method must have an ARG to send to receiving party, otherwise the CMD method is useless.
			if (!isSlave()) {
				Debug.error					(_debugPrefix, "I am not in SLAVE mode. Cannot sendFeedbackToMaster: " + Debug.object(arg));
				return;
			}
			if (!isPaired()) {
				Debug.error					(_debugPrefix, "I am not paired to any master. Cannot sendFeedbackToMaster: " + Debug.object(arg));
				return;
			}
			if (!_pairedNeighbor) {
				Debug.error					(_debugPrefix, "Internal critical error: I result as paired but paired neighbor is not setup!!! Aborting pairing... and forget about sendFeedbackToMaster " + Debug.object(arg));
				resetPairing					();
				return;
			}
			// Ok error check passed. Now I have to retrieve the ID of my paired slave in order to send a command to him only.
			Debug.debug						(_debugPrefix, "Sending "+cmd+" to my master: " + arg  + " : " + Debug.object(arg));
			sendCommandTo						(_pairedNeighbor.from, cmd, arg, receipt, info);
		}
		private function sendCommandTo				(to:String, cmd:String, arg:*=null, receipt:Boolean=false, info:String=null, extraParams:Object=null):void {
			var o								:Object = getBaseCommandObject(to, cmd, arg, receipt);
			o.to								= to;
			if (extraParams)						for (var s in extraParams) o[s] = extraParams[s];
			sendCommand						(o);
		}
		private function getBaseCommandObject		(to:String, cmd:String, arg:*=null, receipt:Boolean=false, info:String=null):Object {
			var o								:Object = {to:to, cmd:cmd, id:UText.getRandomString(4), group:_groupId};
			for (var s:String in _baseIdentity)		if (_baseIdentity[s]) o[s] = _baseIdentity[s];
			if (arg)							o.arg = arg;
			if (info)							o.info = info;
			if (receipt)	{
				_commandsWaitingReceipt			[o.id] = o;
				o.receipt 						= true;
			}
			return							o;
		}
		private function sendCommand				(o:Object):void {
			Debug.debug						(_debugPrefix, "Sending command: " + o  + " : " + Debug.object(o));
			if (!isGrouped()) {					// Can't send messages if I am not successfully AT LEAST grouped
				Debug.error					(_debugPrefix, "My status is " + getStatusName() + " cannot send command.");
				return; 
			}
			_group.post						(o);
		}
// RECEIVING MESSAGES ///////////////////////////////////////////////////////////////////////////////////////
		private function processReceivedMessage		(o:Object):Boolean {
			// Check integrity of message, to make sure it can integrate in P2PComm and doesnt trigger an error
			if (messageIsNotStandard(o)) {
				Debug.error						(_debugPrefix, "Message received is not standard. Aborting message processing.");
				return false;
			}
			// Check if I am the recipient of this message
			var forMe							:Boolean = o.to == _udid;
			var forMyGroup						:Boolean = o.group == _groupId || ACCEPT_FROM_ALL_GROUPS;
			var process						:Boolean = (o.to == "ALL" || forMe) && forMyGroup;
			if (process) {
				Debug.debug					(_debugPrefix, "Message is for " + (forMe ? "ME ONLY" : "EVERYBODY") + ", and in my group, I can process it.");
			}
			else {
				Debug.debug					(_debugPrefix, "This message is " + (forMyGroup ? " for my group but " : " NOT for my group and") + (forMe ? " for me only. " : " not for me!"));
				return						false;
			}
			// Ok, I can process this message. Check if they need a receipt.
			var receipt							:Boolean = o.receipt;
			var success						:Boolean;
			var hasMethod						:Boolean;
			// Check if there is a method
			try {
				hasMethod						= Boolean(this["processCommand_" + o.cmd]);
			} catch(e:Error) {
				Debug.error					(_debugPrefix, "Command " + o.cmd + " was not found in Class.");
				return						false;
			}
			// Method found
			if (hasMethod) {
				success						= this["processCommand_" + o.cmd](o);
			} 
			// Message was processed successfully
			return							true;
		}
				private function messageIsNotStandard(o:Object):Boolean { // If the message DOES NOT fit into P2PComm standard (message wil be ignored)
					// Check commands are allowed
					if (ALLOWED_COMMANDS.indexOf(o.cmd) == -1) return true;
					// Check modes are allowed
					var modes					:String = "MNS";
					if (modes.indexOf(o.mode) == -1) return true; // Mode is not one of the allowed modes
					// Command is standard
					return					false;
				}
		private function processCommand_MSG		(o:Object):Boolean { // I have received a chat message. It always returns true.
			broadcastEvent						(EVT_MSG, o.name, o.arg);
			return							true;
		}
		private function processCommand_ANNOUNCE	(o:Object):Boolean { // I have received a messge from a client introducing himself
			Debug.debug						(_debugPrefix, o.name + " announced himself.");
			sendWelcome						(o.from);
			setupNeighborData					(o);
			return							true;
		}
		private function processCommand_UPDATE		(o:Object):Boolean { // A neighbor has updated his data. If I didn't previously know neighbor, I treat this as an ANNOUNCE
			var update							:Boolean = Boolean(getNeighborById(o.from));				
			Debug.debug						(_debugPrefix, o.name + " updated his data.");
			setupNeighborData					(o);
			if (!update) {
				Debug.debug					(_debugPrefix, "I didn't have this user in memory before, therefore I send him a welcome.");
				sendWelcome					(o.from);
			}
			return							true;
		}
		private function processCommand_WELCOME		(o:Object):Boolean { // A client has replied to my introduction message
			Debug.debug						(_debugPrefix, o.name + " welcomed me.");
			if (isAnnounced(false)) { // If I am announced. This happens only once, I either move to WELCOMED or MASTER or SLAVE
				setStatusToUnpaired				();
			}
			// This WELCOME, if I am a slave, can arrive AFTER my MASTER already grabbed me. So if I am already paired with him, on welcome nothing is changed since the announce.
			if (isPaired() && isPairedWith(o.from)) {
				Debug.debug					(_debugPrefix, "I know this user, I am already paired with him. No action required.");
			}
			else {
				setupNeighborData				(o);
			}
			return							true;
		}
		private function processCommand_IAMYOURMASTER(o:Object):Boolean { // Someone claims he is my master!
			Debug.debug						(_debugPrefix, o.name + " claims he is my MASTER?");
			// Here I have several checks to do. I may be waiting for an EXACT user. By now I only check if key is correct.
			setupNeighborData					(o);
			checkPairingRequestFromMaster			(o);
			return							true;
		}
		private function processCommand_NOWAY		(o:Object):Boolean { // He is not my slave...
			Debug.debug						(_debugPrefix, o.name + " says he is not my slave because: " + o.arg);
			broadcastEvent						(EVT_PAIRREFUSED);
			return							true;
		}
		private function processCommand_YESYOUARE	(o:Object):Boolean { // He is not my slave...
			setUserAsPairingNeighbor				(o);
			Debug.debug						(_debugPrefix, o.name + " is now paired as my slave.");
			return							true;
		}
		private function processCommand_CMD		(o:Object):Boolean { // He is not my slave...
			Debug.debug						(_debugPrefix, o.name + " sent me a comand " + Debug.object(o.arg));
			return							processReceivedCommand(o);
		}
		private function processCommand_RECEIPT		(o:Object):Boolean { // I received a command receipt from a slave...
			Debug.debug						(_debugPrefix, o.name + " sent me a receipt.");
			processReceipt						(o);
			return							true;
		}
		private function processCommand_FEEDBACK	(o:Object):Boolean { // I received a feedback from a slave...
			Debug.debug						(_debugPrefix, o.name + " sent me a feedback.");
			return							processReceivedFeedback(o);
		}
// RECEIVED COMMAND MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		private function processReceivedCommand		(o:Object):void {
			// He is my master and I trust him to control me
			var ok							:Boolean = isMyMaster(o);
			Debug.debug						(_debugPrefix, ok ? "My master sent me a command, and I will execute it." : "This is not my master. Command is refused.");
			broadcastEvent						(ok ? EVT_EXEC : EVT_EXECFAIL, o.arg);
			sendReceipt						(o, ok, ok ? "Thank you master I executed your command." : "I refuse your command because you are not my master.");
			if (!isPaired() || !isPairedWith(o.from)) {
				Debug.debug					(_debugPrefix, "I am not paired, or I was paired with someone else. I re-pair with this guy.");
				checkPairingRequestFromMaster		(o);
			}
		}
		private function processReceivedFeedback		(o:Object):void {
			// He is my slave and I trust his feedback
			var ok							:Boolean = isMySlave(o);
			Debug.debug						(_debugPrefix, ok ? "My slave sent me a feedback." : "This is not my slave. Feedback is refused.");
			broadcastEvent						(ok ? EVT_FEEDBACK : EVT_FEEDBACKFAIL, o.arg);
		}
// NEIGHBOR MANAGEMENT //////////////////////////////////////////////////////////////////////////////////////////////////////////////
		private function setupNeighborData			(o:Object):void {
			/* 	This sets up data for each neighbor who announces, welcomes or updates. 
				It can be called also when other messages are received, and only if neighbor is not yet setup.
			
			*/
			// first check if neighbor has already been stored, and in case destroy the old data object
			if (_neighborsById[o.from]) {
				deleteNeighborData				(o.from);
			}
			// Setup neighbor data
			_neighborsById[o.from]				= o;
			_neighborsByMode[o.mode][o.from]		= o; // This works, integrity of message has been checked upon receipt otherwise it doesn't get processed
			_neighborsObjects.push				(o);
			_neighborsNames.push					(o.name);
			o.index							= _neighborsObjects.length-1;
			// Update counters
			_counters[o.mode]					++;
			_counters.TOT						++;
			broadcastEvent						(EVT_NEIGHBOR_DATA, UCode.duplicateObject(o));
			broadcastEvent						(EVT_NEIGHBORS_UPDATE);
			// After I setup a neigbor data, I do check if pairing logic needs to do something with it
			checkPairingNeighbor					(o);
		}
		private function deleteNeighborData			(id:String):void { // Destroy stored instance of neghbor data
			// Deletion is done ONLY on update, since disconnection is NOT registered
			var o								:Object = _neighborsById[id];
			var index							:int = _neighborsObjects.indexOf(o);
			_neighborsObjects.splice				(index, 1);
			_neighborsNames.splice				(index, 1);
			delete							_neighborsById[id];
			// Update counters
			_counters[o.mode]					--;
			_counters.TOT						--;
			// To make sure, I just delete them from each array
			delete							_neighborsByMode.M[id];
			delete							_neighborsByMode.N[id];
			delete							_neighborsByMode.S[id];
		}
// INTERNAL UTY ///////////////////////////////////////////////////////////////////////////////////////
	// STATUS
		private function getStatusName				():String {
			return							STATUSES[_status];
		}
		private function getStatus					():int {
			return							_status;
		}
		private function setStatus					(i:int):void {
			if (_status == i)						return;
			Debug.debug						(_debugPrefix, "Status changed from " + STATUSES[_status] + " to " + STATUSES[i]);
			_status							= i;
			broadcastEvent						(EVT_STATUS_CHANGE);
		}
		private function setStatusToUnpaired			():void { // This sets the correct status after announced. 
			//It can be colled each time a user receives a welcome. Or it can be called to reverse pairing status..
			// BEWARE - this will reset status to before pairing EVEN if I am already paried.
			var broadcastUnpaired					:Boolean = isPaired(); // Register if I have to broadcast pair lost before changing status
			if (isMaster())						setStatus(6);
			else if (isSlave())					setStatus(7);
			else								setStatus(5);
			if (broadcastUnpaired)					broadcastEvent(EVT_PAIRLOST); // If I have lost pairing I broadcast the event
		}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
	// NetGroup
		public function onGroupConnectionStatus		(e:NetStatusEvent):void {
			// Analyse connection status
			NetStatusEventAnalyzer.analyze			(e);
			Debug.debug						(_debugPrefix, NetStatusEventAnalyzer.getCode());
			var genEvent						:String = NetStatusEventAnalyzer.getGeneralEvent();
			if (this.hasOwnProperty(genEvent))		this[genEvent]();
			else {
				Debug.debug					(_debugPrefix,genEvent+"()\n",e,Debug.object(e.info)+"\n------------------------------------");
				Debug.error					(_debugPrefix, "NetGroup:",genEvent,"not defined in Class");
			}
		}
		public function onNetGroupConnectSuccess		():void { // Somehow this should be called by NetGroup, but it is called by NetConnection
			Debug.debug						(_debugPrefix, "Group connection successful.");
			if (isConnected()) {
				setStatus						(3);	
				Debug.debug					(_debugPrefix, "Waiting for neighbors to show up...");
			}
			_grouped							= true;
			broadcastEvent						(EVT_CONNECTED);
		}
		public function onNetGroupNeighborConnect		():void {
			Debug.debug						(_debugPrefix, "New neighbor detected. If no welcome arrives it means he belongs to another group.");
// 			Debug.debug						(_debugPrefix, Debug.object(NetStatusEventAnalyzer.getEvent().info));
			if (isGrouped(false)) {
				announcePresence				();
				setStatus						(4);
			}
		}
		public function onNetGroupNeighborLost		():void {
			Debug.debug						(_debugPrefix, "Neighbor lost.");
// 			Debug.debug						(_debugPrefix, Debug.object(NetStatusEventAnalyzer.getEvent().info));
		}
		public function onNetGroupPostingReceived		():void {
			Debug.debug						(_debugPrefix, "Post received.");
// 			Debug.debug						(_debugPrefix, Debug.object(NetStatusEventAnalyzer.getEvent().info));
			var 								o:* = NetStatusEventAnalyzer.getEventInfoMessage();
			if (o && o is Object) {
				Debug.debug					(_debugPrefix, "Received post: " + Debug.object(o));
				processReceivedMessage			(o);
			}
			else {
				Debug.error					(_debugPrefix, "Received unrecognized message: " + o);
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
		public function onNetConnectionConnectSuccess 	():void {
			Debug.debug						(_debugPrefix, "RTMFP Connection Successful.");
			if (isIdle()) {
				setStatus						(2);
				initializeGroup					();
			}
			_connected							= true;
		}
		public function onNetConnectionConnectLost		():void {
			Debug.debug						(_debugPrefix, "NetConnection lost.");
			setDisconnected						();
		}
// UTY //////////////////////////////////////////////////////////////////////////////////////////////////////////
	}
}