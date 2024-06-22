/* P2P - 1.0 - Filippo Gregoretti - www.pippoflash.com

*/
package com.pippoflash.net {
	
	import									flash.media.*;
	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import									flash.system.*;
	import									com.pippoflash.net.NetStatusEventAnalyzer;
	import									com.pippoflash.app42.*;
	import									com.pippoflash.media.PFVideo;
	import									com.pippoflash.media.PFAVLocal;
	import									com.pippoflash.utils.*;
	import									com.pippoflash.framework._PippoFlashBaseNoDisplay;
	
	public class P2P extends _PippoFlashBaseNoDisplay {
		// VARIABLES /////////////////////////////////////////////////////////////////////////////////////////////////
		private static const USE_AMAZON_AMS		:Boolean = false;
		private static const DEF_P2P_CONN_SERVER	:String = "rtmfp://p2p.rtmfp.net";
		private static const DEF_DEV_KEY			:String = "e6c407ad8800c57a95664393-e84406920ece"; // Unique developer key
		private static const AMS_AMAZON_URL		:String = "rtmp://54.171.132.10/lavazza/PippoChat";
		private static const DEF_APP42_APP_KEY	:String = "751bd1bfefb11c0109e45d1b86a4883112037d94b06adec68db412ee83c8ce23"; // App42 default application key
		private static const DEF_APP42_SEC_KEY	:String = "60c13780d36d9ac2b1868ba3e4e9e0e870e7924bd45c83faba0016fff584b954"; // App42 secret key
		private static const DEF_APP42_DBNAME	:String = "P2PCLIENTID"; // Name of the DB in the app (it is unique, but App42 requires it)
		private static const DEF_APP42_COLLNAME	:String = "PippoFlashTest"; // Name of files collections
		private static const DEF_APP42_DOCNAME	:String = "544166c0e4b0e826d615abea"; // ID of document with PEER IDs
		// EVENTS - EVENTS WILL HAVE ID ADDED AT THE END (onConnectionSuccessP2PIdName)
		private static const EV_STATUS_CHANGE	:String = "onStatusChange"; // This is broadcasted every time a status us changed
		private static const EV_CONNECTION_SUCCESS:String = "onConnectionSuccess"; // Connection to P2P server established
		private static const EV_CONNECTION_ERROR	:String = "onConnectionError"; // Connection to P2P server error (while connecting)
		private static const EV_CONNECTION_LOST	:String = "onConnectionLost"; // Connection to P2P server lost (when already connected)
		private static const EV_PEERS_RECEIVED	:String = "onPeersReceived"; // List of peers farID from App42 received
		private static const EV_PEERS_ERROR		:String = "onPeersError"; // Error receiving List of peers farID from App42
		private static const EV_LOGIN_SUCCESS	:String = "onLoginSuccess"; // Near ID successfully written to App42
		private static const EV_LOGIN_ERROR		:String = "onLoginError"; // Near ID writing on App42 error
		private static const EV_PEER_REQUESTING	:String = "onPeerRequest"; // Requesting a direct connection with peer
		private static const EV_PEER_REQUEST_ERROR:String = "onPeerRequestError"; // Peer is not reachable or didn't answer
		private static const EV_PEER_CONNECT		:String = "onPeerConnect"; // Connected to peer
		// Implementa da uqi in giu!!!!
		private static const EV_PEER_DISCONNECT	:String = "onPeerDisconnect"; // Disconnected from peer
		private static const EV_PEER_CALL_SENT	:String = "onPeerCallSent"; // I sent a call to a peer 
		private static const EV_PEER_CALL_RINGING	:String = "onPeerCallRinging"; // The call I sent is ringing on peer
		private static const EV_PEER_CALL_DENIED	:String = "onPeerCallDenied"; // Peer refused my call
		private static const EV_PEER_CALL_ANSWERED:String = "onPeerCallAnswered"; // Peer answered my call
		private static const EV_PEER_HANGED		:String = "onPeerCallHanged"; // Peer hanged up during a call
		// STATUS
		private static const STATUS_LIST				:Array = ["IDLE", "CONNECTING", "CONNECTED", "LOGGING", "LOGGED", "REQUESTING", "REQUESTED", "PAIRED", "CALLING", "RINGING", "TALKING", "HANGING"];
		private static const STATUS_DESCRIPTION		:Object = {
			// Status is set and checked with a number. Higher status ALWAYS implies lower one. I.e. isLogged() returns true also if PAIRED or RINGING.
			// Not all of them of course. Some like IDLE are true only when IDLE.
			IDLE								:"Just started, or connection disconnected. Needs a netConnection again.", // 0
			CONNECTING						:"Connecting to P2P startus server.", // 1
			CONNECTED						:"Connected to a P2P server.", // 2
			LOGGING							:"Logging int with a user ID (writing nearID to App42 DB)", // 3
			LOGGED							:"Logged in with credentials and received peer ids from list", // 4 - This is basically where client will stay most of the time
			REQUESTING						:"I am requesting a direct connection with another peer.", // 5
			REQUESTED						:"Another peer has requested my connection.", // 6
			PAIRED							:"I am paired with another peer. Now we can message, or call.", // 7
			CALLING							:"Calling another peer.", // 8
			RINGING							:"Another peer is calling me", // 9
			TALKING							:"A conversation is in progress", // 10
			HANGING							:"I am hanging up the call (going back to LOGGED)" // 11
		};
		private var _status						:uint; // Index describing the status
		private var _statusDescription				:String; // Verbose description of status
		// PEER COMMUNICATION
		private static const P2P_PEER_EVENT_NAME	:String = "onPeerEvent"; // Name of the only method allowed to call on connected peer
		private static const SERVER_CONNECTION_ALIVE_TIMEOUT:uint = 10; // Seconds to wait for keeping connection alive for CONNECTED P2P SERVER
		private static const PEER_CONNECTION_ALIVE_TIMEOUT:uint = 10; // Seconds to wait for keeping connection alive for CONNECTED PEER
		// Allowed incoming methods. Cannot be static because it references instance methods.
		private const INCOMING_METHODS			:Object = { // Only these methods are allowed received from client. If a method is NOT in this list it will be rejected.
			// Peer can only call "onPeerEvent", with 2 parameters, method name (PINGME, MESSAGE, ETC.) and method parameters if any.
			PINGME							:onPeerAskedPing, // When called, client returns a ping to the sender to confirm he is online
			PINGBACK							:onPeerPingedBack, // The other peer has replied to my ping
			MESSAGE							:onMessageReceived, // Receives a message from connected peer
			LETSTALK							:onCallReceived, // A request for a videocall is received
			ITSRINGING						:onCallSentRinging, // A request I sent for a call is ringing on connected peer
 			ANSWER							:onCallAnswered, // A call I sent has been answered by peer
			HANGUP							:onCallHanged, // The guy I was talking to, or I was calling, hanged up. Or the guy who was calling me.
			EMPTY							:null // Somehow the method is empty
		};
		// SWITCHES
		private static var _verbose					:Boolean = true;
		// USER DEFINED
		private var _uri							:String; // Uri of Adobe Cirrus server
		private var _key							:String; // Adobe Cirrus developer key
		private var _id							:String; // ID of the P2P connection
		private var _userId						:String; // My user id
		// SYSTEM - P2P
		private var _p2pServerUrl					:String; // Complet url (uri + key)
		private var _netConnection					:NetConnection; // The P2P Cirrus NetConnection
		private var _connected					:Boolean; // If netconnection has been successfully established, and peers list has been loaded
		private var _nearId						:String; // My own unique identifier
		private var _farId						:String; // Remote client unique identifier
		private var _farPeerUserName				:String; // The UserName of far peer
		private var _keepServerConnectionAlive			:Boolean; // If connection to P2P SERVER has to be kept alive.
		private var _keepPeerConnectionAlive			:Boolean; // If connection to PEER has to be kept alive. It uses PINGME and PINGBACK.
		private var _pingBackId					:String; // Stores the string to be sent as PINGME to connected peer, and that has to be returned back to confirm pingback.
		private var _callId						:String; // ID of the call in progress
		// SYSTEM - CALL AND CONNECTION
		// SYSTEM - NETSTREAM
		private static const PUBLISH_STREAM_NAME		:String = "PippoFlashMedia"; // Name of publish stram for in and out
		private static const PAIR_REQUEST_TIMEOUT		:uint = 10; // When requesting to pair with a peer, this is the timeout to say that I didnt find the peer
		private var _netStreamOut					:NetStream; // This is the public stream I use to connect to P2P service, to receive incoming conections, and to broadcast video and audio
		private var _netStreamIn					:NetStream; // This is the stream I use as a peer connection, to send data messages, and to receive audio and video from a peer
		private var _netStreamOutClient				:Object; // This is the client for streamOut. Gets the onPeerConnect.
		private var _netStreamInClient				:Object; // This is the client for streamIn. Gets the "onPeerEvent" Object from a peer.
		// LOCAL CAMERA AND MICROPHONE, and remote VVIDEO
		private var _remotePFVideo					:PFVideo; // PFVideo instance to connect to remote video
		private var _PFAVLocal						:PFAVLocal; // PFAVLocal instance to get camera and microphone from
		// App42
		private var _appKey						:String; // Application key
		private var _secKey						:String; // Secret key
		private var _dbName						:String; // Name of database
		private var _collName						:String; // Name of collection
		private var _idsDocName					:String; // ID of peers IDs doc to maintain
		private var _app42DocumentPeers				:App42Document; // The domunet to write peers IDs
		private var _clientPeerIds					:Object; // Stores a username->key of clients IDs.
		private var _peerListReceived				:Boolean; // If app is successfully connected to a webservice and loaded a peers list.
		private var _peerIdSaved					:Boolean; // If app has sended its own peer ID (nearId).
		// MARKERS
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function P2P						(id:String=null, uri:String=null, key:String=null):void {
			_id								= id ? id : "PippoFlashP2P"; 
			super							(id ? id : _id + Math.random()); // This is NOT singleton, so ID can't be the same
			_uri								= uri ? uri : DEF_P2P_CONN_SERVER;
			_key								= key ? key : DEF_DEV_KEY;
			_p2pServerUrl						= _uri + "/" + _key;
			setToIdle							();
			if (USE_AMAZON_AMS)				_p2pServerUrl = AMS_AMAZON_URL;
			Debug.debug						(_debugPrefix, "Initialized on",_p2pServerUrl);
			_netConnection 						= new NetConnection();
			_netConnection.addEventListener			(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
			// Initialize NetStream client objects, routing only relevant events.
			_netStreamOutClient					= {
				startTransmit					:onStreamOutStartTransmit,
				stopTransmit					:onStreamOutStopTransmit,
				onPeerConnect					:onPeerConnect
			};
			_netStreamInClient					= {
				startTransmit					:onStreamInStartTransmit,
				stopTransmit					:onStreamInStopTransmit,
				onPeerEvent					:onPeerEvent // This is the only method accepted by a peer. 
			};
		}
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VIDEO AND AUDIO INIT ////////////////////////////////////////////////////
		public function reset						():void { // Closes streams, disconnects from server.
			/* TO BE IMPLEMENTED */
			setToIdle							();
		}
		// Setup stuff for transmitting
		public function setupPFAVLocal				(a:PFAVLocal):void {
			_PFAVLocal							= a;
		}
		// Setup stuff for receiving
		public function setupRemotePFVideo			(v:PFVideo):void {
			_remotePFVideo						= v;
		}
// CONNECTING AND LOGGING IN ///////////////////////////////////////////////////////////////////////////////////////
		public function connect					(keepServerAlive:Boolean=true):void { // Connects to a server
			if (_connected)						disconnect();
			setStatus							(1);
			_connected							= false;
			_netConnection.connect				(_p2pServerUrl);
			_keepServerConnectionAlive				= keepServerAlive;
		}
		public function disconnect					():void { 
			/* TO BE ADDED CODE FOR DISCONNECTION */
			_connected						= false;
		}
	// App42
		public function initializeApp42API				(appKey:String=null, secretKey:String=null, dbName:String=null, collName:String=null, docName:String=null):void {
			_peerListReceived					= false;
			_peerIdSaved						= false;
			_appKey							= appKey ? appKey : DEF_APP42_APP_KEY;
			_secKey							= secretKey ? secretKey : DEF_APP42_SEC_KEY;
			_dbName							= dbName ? dbName : DEF_APP42_DBNAME;
			_collName							= collName ? collName : DEF_APP42_COLLNAME;
			_idsDocName						= docName ? docName : DEF_APP42_DOCNAME;
			_App42Base.initApp42					(_appKey, _secKey, _dbName, _id);
			_app42DocumentPeers					= new App42Document(_collName, _idsDocName, "Peers");
			_app42DocumentPeers.addListener		(this);
		}
		public function loginWithUserId				(userId:String):void {
			Debug.debug						(_debugPrefix, "Logging in as " + userId);
			if (isConnected()) {
				setStatus						(3);
				_userId						= userId;
				_app42DocumentPeers.writeKey		(_userId, _nearId);
			}
			else {
				Debug.error					(_debugPrefix, "Login operation aborted. I am not connected to a RTMFP server.");
			}
		}
// PEER PAIRING ////////////////////////////////////////////////////////////
		// Open a connection
		public function connectToUserName			(userName:String, keepPeerAlive:Boolean=true):void {
			Debug.debug						(_debugPrefix, "Connecting to",userName);
			_farPeerUserName					= userName;
			_keepPeerConnectionAlive				= keepPeerAlive;
			initializeInStream					(getPeerId(userName));
		}
		public function disconnectFromPeer			():void {
			if (isPaired()) {
				/* DISCONNECTION FROM PEER CODE GOES HERE */
			}
		}
// PEER CALLS /////////////////////////////////////////////////////////////////////
		public function callConnectedPeer			():void {
			Debug.debug						(_debugPrefix, "Calling connected peer...");
			// Error check
			var error							:String = null;
			if (isInCall(false))					error = "I am in another call or already calling somone, cannot do a new call now.";
			else if (!isPaired(true))				error = "I am not paired to any peer, I can't call him.";
			if (error) {
				Debug.error					(_debugPrefix, error + "  Status: " + _statusDescription);
				return;
			}
			// Proceed with no error
			setStatus							(8);
			_callId							= String("CALL_"+Math.random());
			sendPeerEvent						("LETSTALK", _callId);
		}
		public function acceptIncomingCall			():void { // Only if it's ringing, this method works
			if (isRinging(true)) {
				setStatus						(10);
				sendPeerEvent					("ANSWER");
				openP2PCall					();
			}
			else {
				Debug.error					(_debugPrefix, "I am not Ringin, I can't accept an incoming call.");
			}
		}
		public function hangUp					():void { // This just works both when calling, ringing or talking
			if (isRinging(true))					denyIncomingCall();
			else if (isInCall(true))				hangUpOngoingCall();
			else 								Debug.error(_debugPrefix, "Cannot hangup: " + getStatus());
		}
		public function hangUpOngoingCall			():void { // This just works when a call is running
			
		}
		public function denyIncomingCall			():void { // Only if it's ringing, this method works
			if (isRinging(true)) {
				sendPeerEvent					("HANGUP");
				setStatus						(7);
			}
			else {
				Debug.error					(_debugPrefix, "I am not Ringin, I can't DENY an incoming call.");
			}
		}
// PEER EVENTS SEND ///////////////////////////////////////////////////////
		public function sendPeerEvent				(methodName:String="MESSAGE", par:*=null):void {
// 		private const INCOMING_METHODS			:Object = { // Only these methods are allowed received from client. If a method is NOT in this list it will be rejected.
// 			// Peer can only call "onPeerEvent", with 2 parameters, method name (PINGME, MESSAGE, ETC.) and method parameters if any.
// 			PINGME							:onPeerAskedPing, // When called, client returns a ping to the sender to confirm he is online
// 			PINGBACK							:onPeerPingedBack, // The other peer has replied to my ping
// 			MESSAGE							:UCode.dummyFunction, // Receives a message from connected peer
// 			LETSTALK							:UCode.dummyFunction, // A request for a videocall is sent
// 			HANGUP							:UCode.dummyFunction, // The guy I have called hanged up
// 			EMPTY							:null // Somehow the method is empty
// 		};
			// Check for errors
			var error							:String = null;
			if (!INCOMING_METHODS[methodName])	error = "Method " + methodName + " not allowed in P2P communication.";
			else if (!isPaired(false))				error = "P2P not paired with any peer. Cannot send Peer Event!";
			if (error) {
				Debug.error					(_debugPrefix, error);
				return;
			}
			// No errors, proceed with function
			// Perform specific tasks for specific functions
			if (methodName == "PINGME") { // If PINGME has no parameter, it will be created here
				if (!par)						par = String(Math.random());
				_pingBackId					= par;
			}
			// Proceed sending command
			Debug.debug						(_debugPrefix, "Sending peer event:",methodName,(par ? "with param: "+par : ""));
			if (par)							_netStreamOut.send(P2P_PEER_EVENT_NAME, methodName, par);
			else								_netStreamOut.send(P2P_PEER_EVENT_NAME, methodName);
		}
// UTY /////////////////////////////////////////////////
	// Get data
		public function getNearID					():String {
			return							_netConnection.nearID;
		}
		public function getFarID					():String {
			return							_farId;
		}
	// Peers uty
		public function refreshPeers				():void {
			_app42DocumentPeers.readDocument	();
		}
		public function getPeerIds					():Object {
			return							_clientPeerIds;
		}
		public function getPeerId					(userName:String):String {
			if (!_clientPeerIds[userName]) 			Debug.error(_debugPrefix, "getPeerIde() Peer id not found for username", userName);
			return							_clientPeerIds[userName];
		}
		public function getPairedPeerName			():String {
			return							_farPeerUserName;
		}
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STATUS ///////////////////////////////////////////////////////////////////////////////////////
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 		private static const STATUS_LIST			:Array = ["IDLE", "CONNECTING", "CONNECTED", "LOGGED", "REQUESTING", "REQUESTED", "PAIRED", "CALLING", "RINGING", "TALKING", "HANGING"];
// 		private static const STATUS_DESCRIPTION		:Object = {
// 			// Status is set and checked with a number. Higher status ALWAYS implies lower one. I.e. isLogged() returns true also if PAIRED or RINGING.
// 			// Not all of them of course. Some like IDLE are true only when IDLE.
// 			IDLE								:"Just started, or connection disconnected. Needs a netConnection again.", // 0
// 			CONNECTING						:"Connecting to P2P startus server.", // 1
// 			CONNECTED						:"Connected to a P2P server.", // 2
// 			LOGGING							:"Logging int with a user ID (writing nearID to App42 DB)", // 3
// 			LOGGED							:"Logged in with credentials and received peer ids from list", // 4 - This is basically where client will stay most of the time
// 			REQUESTING						:"I am requesting a direct connection with another peer.", // 5
// 			REQUESTED						:"Another peer has requested my connection.", // 6
// 			PAIRED							:"I am paired with another peer. Now we can message, or call.", // 7
// 			CALLING							:"Calling another peer.", // 8
// 			RINGING							:"Another peer is calling me", // 9
// 			TALKING							:"A conversation is in progress", // 10
// 			HANGING							:"I am hanging up the call (going back to LOGGED)" // 11
// 		};
		private function setStatus					(n:uint):void {
			var id							:String = STATUS_LIST[n];
			if (!id) {
				Debug.error					(_debugPrefix, "Received wrong status. No status ID found for num "+n);
				return;
			}
			// Check for status changes operations
			var error							:String = performStatusTo(n);
			if (error) {
				Debug.error					(_debugPrefix, "Status change from " + _status + " to " + n + " not allowed. " + error);
				return;
			}
			// Status ID found, proceed with status change
			_status							= n;
			_statusDescription					= _status + " [" + id + "] " + STATUS_DESCRIPTION[id];
			Debug.debug						(_debugPrefix, "Status: " + _statusDescription);
			broadcastP2PEvent					(EV_STATUS_CHANGE);
		}
		private function performStatusTo			(n:uint):String { // This tells if status change is allowed, and performs stuff to do like checks, etc. If it returns a string, then it is an error!!!!
			if (n == 5) { // I am asking a peer to PAIR
				UExec.second					(PAIR_REQUEST_TIMEOUT, onPeerPairRequestTimeout, _farId);
			}
			return							null; // Everything went fine. Status change is allowed.
		}
		// Timed UExec checks
		private function onPeerPairRequestTimeout	(farId:String=null):void { // Launched when I request a pairing. If this times out and is the same farId, client refused.
			Debug.debug						(_debugPrefix, "Pairing request timed out.");
			if (isPairing(true) && farId == _farId) {
				Debug.debug					(_debugPrefix, "Request correct, it is a timeout. Aborting pairing request.");
				setStatus						(4);
				broadcastP2PEvent				(EV_PEER_REQUEST_ERROR);
			}
			else {
				Debug.debug					(_debugPrefix, "Received a pairing timeout, but: " + (isPairing(true) ? "" : "[P2P is not in status pairing!] ") + (farId == _farId ? "" : "[farID timed out is not the same I am reguesting!]") + " - Status: " + _statusDescription);
			}
		}
		// Setters
		private function setToIdle					():void {
			setStatus							(0);
		}
		// Methods
		public function getStatus					():String {
			return							_statusDescription;
		}
		// CHECKS - They all default to NON-PRECISE, it means statuses >=. If true, status is ==.
		public function isIdle						(precise:Boolean=false):Boolean {
			return							_status == 0; // Always precise
		}
		public function isConnected				(precise:Boolean=false):Boolean { // Is connected to P2P network? (Stratus or FMS?)
			if (((precise && _status == 2) || (!precise && _status >= 2)) && _netConnection.connected) return true;
			else if (!_netConnection.connected) 		Debug.error(_debugPrefix, "_netConnection.connected is false!!!!");
			return							false;
		}
		public function isLogged					(precise:Boolean=false):Boolean {
			return							(precise && _status == 4) || (!precise && _status >= 4); 
		}
		public function isPairing					(precise:Boolean=false):Boolean {
			return							_status == 5; // Always PRECISE
		}
		public function isPaired					(precise:Boolean=false):Boolean { // Has a direct connection opened with a peer?
			return							(precise && _status == 7) || (!precise && _status >= 7); // It means any status after PAIRED
		}
		public function isCalling					(precise:Boolean=false):Boolean { // It means I am in the process of calling someone
			return							(precise && _status == 8) || (!precise && _status >= 8);
		}
		public function isRinging					(precise:Boolean=false):Boolean { // It means it is ringing. Or up.
			return							(precise && _status == 9) || (!precise && _status >= 9); 
		}
		public function isInCall					(precise:Boolean=false):Boolean { // It means I am in the process of calling someone, or I am having a conversation
			return							(precise && _status == 10) || (!precise && _status >= 8); // 10 is talking, >=8 is calling, ringing, talking, etc.
		}
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CALL MANAGEMENT ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		private function openP2PCall				():void { // When I am receiving a call, and I decide to answer (checks already happen in public function)
			var error							:String = null;
			if (!_PFAVLocal)					error = "_PFAVLocal instance not defined.";
			else if (!_remotePFVideo)				error = "_remotePFVideo instance not defined.";
			if (error) {
				Debug.error					(_debugPrefix, "Cannot open P2P call:  " + error);
				return;
			}
			_netStreamOut.attachCamera			(_PFAVLocal.getDefaultCam());
			_netStreamOut.attachAudio			(_PFAVLocal.getDefaultMic());
			_netStreamIn.receiveAudio			(true);
			_netStreamIn.receiveVideo			(true);
			_netStreamIn.play					(PUBLISH_STREAM_NAME);
// 			_remotePFVideo.play					("videotest.mp4");
			_remotePFVideo.attachStream			(_netStreamIn);
			setStatus							(10);
			Debug.debug						(_debugPrefix, "CAZZO DOVREBBE INIZIARE LA CHIAMATA MINCHIA!!!!!");
		}
		private function destroyPeerConnectionAndReset():void { // This is called in case of StreamConnectionlost, or NetConnectionlost, - goes back to LOGGED
			// Somehow I have to completely destroy peer connection, first I destroy the call
			Debug.debug						(_debugPrefix, "Destroying entire Peer connection...");
			destroyPeerCall						();
		}
		private function destroyPeerCall			():void { // This is calle don hangup received, sent, during call, or during ringing - goes back to PAIRED
			Debug.debug						(_debugPrefix, "Closing entirely call with Peer. Stream IN will be destroyed...");
			_netStreamOut.attachCamera			(null);
			_netStreamOut.attachAudio			(null);
			_netStreamIn.receiveAudio			(false);
			_netStreamIn.receiveVideo			(false);
			_netStreamIn.close					();
			_netStreamIn.dispose				();
		}
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STREAMS MANAGEMENT ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Stream OUT initialization - performed only when I connect to P2P server the first time.
		private function initializeOutStream			():void { 
			// This is called ONLY ONCE, when the netConnection is opened successfully
			Debug.debug						(_debugPrefix, "Initializing OUT NetStream");
			_netStreamOut						= new NetStream(_netConnection, NetStream.DIRECT_CONNECTIONS);
			_netStreamOut.addEventListener		(NetStatusEvent.NET_STATUS, onStreamOutStatus);
			_netStreamOut.client					= _netStreamOutClient;
			_netStreamOut.publish				(PUBLISH_STREAM_NAME);
		}
	// Stream IN initialization, performed when I accept a connection from another peer...
		private function initializeInStream			(farId:String=null):void { // Initializes IN stream. Only once the connected peer is connected.
			Debug.debug						(_debugPrefix, "Pairing with farID Peer. Initializing IN NetStream with "+farId);
			// Look for errors
			var error							:String = null;
			if (!farId)							error = "Far ID not found. NetStream IN initialization aborted.";
			else if (isPairing(true) && farId == _farId) error = "Client is already trying to pair with the same ID. Duplicate pairing aborted.";
			if (error) {
				Debug.error					(_debugPrefix, error);
				return;
			}
			// Procees
			_farId							= farId;
			broadcastP2PEvent					(EV_PEER_REQUESTING);
			setStatus							(5);
			_netStreamIn						= new NetStream(_netConnection, _farId);
			_netStreamIn.addEventListener			(NetStatusEvent.NET_STATUS, onStreamInStatus);
			_netStreamIn.client					= _netStreamInClient;
			_netStreamIn.play					(PUBLISH_STREAM_NAME);
		}
// onPeerEvent METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Methods in NetStream clients (They MUST be public) 
	// OUT STREAM
		public function onPeerConnect				(connectedStream:NetStream):Boolean {
			// Called when another peer sends me a netstream. In this caseI have to grab it, and resend my stream by myself.
			// Find the peer name if I have it in list
			var peerName						:String = "[Name not found]";
			for (var n:String in _clientPeerIds) {
				if (_clientPeerIds[n] == connectedStream.farID) {
					peerName					= n;
					break;
				}
			}
			Debug.debug						(_debugPrefix, "onPeerConnect",connectedStream.farID,"|",peerName);
			// If I receive this, if streamin is not initialized, I do initialize it. It means somebody has called me.
			/* WARNING THIS IS AN AUTOMATED ACCEPTANCE FOR CALL */
			if (!_netStreamIn || _netStreamIn.farID != connectedStream.farID) {
				initializeInStream				(connectedStream.farID);
				setStatus						(6);
			}
			connectedStream.client				= _netStreamInClient;
			// A peer has connected successfully
			setStatus							(7);
			broadcastP2PEvent					(EV_PEER_CONNECT);
			return			 				true;
		}
		public function onStreamOutStartTransmit		(o1:*=null, o2:*=null):Boolean {
			Debug.debug						(_debugPrefix, "onStreamOutStartTransmit " + o1  + " : " + o2);
			return							true;
		}
		public function onStreamOutStopTransmit		(o1:*=null, o2:*=null):Boolean {
			Debug.debug						(_debugPrefix, "onStreamOutStopTransmit " +o1  + " : " + o2);
			return							true;
		}
	// IN STREAM
		public function onPeerEvent				(methodName:String="EMPTY", par:*=null):void {
			// This is the only handler allowed in clint for IN NetStream. Here I filter handlers and interpret which one I should call.
			Debug.debug						(_debugPrefix, "Received from connected peer method",methodName,(par ? "with param: "+par : ""));
			if (INCOMING_METHODS[methodName]) {
				if (par)						INCOMING_METHODS[methodName](par);
				else							INCOMING_METHODS[methodName]();
			}
			else {
				Debug.error					(_debugPrefix, "Method not allowed. Execution aborted.");
			}
		}
		public function onStreamInStartTransmit		(o1:*=null, o2:*=null):Boolean {
			Debug.debug						(_debugPrefix, "onStreamOutStartTransmit " + o1  + " : " + o2);
			return							true;
		}
		public function onStreamInStopTransmit		(o1:*=null, o2:*=null):Boolean {
			Debug.debug						(_debugPrefix, "onStreamOutStopTransmit " + o1  + " : " + o2);
			return							true;
		}
	// Internal methods accepted by peers
		private function onPeerAskedPing			(pingId:String=null):void { // Just ot make sure I add a parameter
			Debug.debug						(_debugPrefix, "Connected peer has requested a ping with ID: " + pingId);
			sendPeerEvent						("PINGBACK", pingId);
		}
		private function onPeerPingedBack			(pingId:String=null):void {
			Debug.debug						(_debugPrefix, "Connected peer has sent a ping back with ID: " + pingId);
			if (pingId == _pingBackId)			onPeerPingBackSuccessful();
			else								onPeerPingBackError(pingId);
		}
		private function onPeerPingBackError		(pingId:String=null):void {
			Debug.error						(_debugPrefix, "PINGBKACK returned has ID " + pingId + " while expected ping was " + _pingBackId);
		}
		private function onPeerPingBackSuccessful	():void {
			Debug.debug						(_debugPrefix, "PINGBACK was successfully received.");
			_pingBackId						= null;
		}
		private function onMessageReceived			(msg:String="message empty"):void {
			Debug.debug						(_debugPrefix, "Received message: " + msg);
		}
		private function onCallReceived				(callId:String=null):void { // Connected peer is calling me
			Debug.debug						(_debugPrefix, "Receiving call...");
			if (isInCall(false)) { // I am already in a call or calling someone
				Debug.error					(_debugPrefix, "Somebody called me but I am already in a call. Status: " + _statusDescription);
				return;
			}
			else {
				_callId						= callId;
				sendPeerEvent					("ITSRINGING", _callId);
				setStatus						(9);
				Debug.debug					(_debugPrefix, "Ringing... Ringing... Ringing...");
			}
		}
		private function onCallSentRinging			(callId:String=null):void { // Peer I called, confirmed me that it is ringing on his side
			if (callId == _callId) { // The correct call is ringing on peer
				Debug.debug					(_debugPrefix, "Peer is ringing from my call.");
				broadcastP2PEvent				(EV_PEER_CALL_RINGING);
			}
			else {
				Debug.error					(_debugPrefix, "Peer says he is ringing, but the call id is wrong! His ID " + callId + ", my ID " + _callId);
			}
		}
		private function onCallAnswered			():void {
			Debug.debug						(_debugPrefix, "Peer just answered the call! Opening P2P call on my side.");
			openP2PCall						();
		}
		private function onCallHanged				():void {
			if (isInCall(false)) { // I am either calling him or in a call
				if (isCalling(true)) {
					Debug.debug				(_debugPrefix, "User DENIED, he didnt answer the call and hanged up in your face!");
				}
				else if (isInCall(true)) {
					Debug.debug				(_debugPrefix, "User hanged up.");
				}
			}
			else {
				Debug.error					(_debugPrefix, "Received a call hangup, but my status is " + _statusDescription);
			}
		}
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// CONNECTION listeners
		public function onNetConnectionStatus		(e:NetStatusEvent):void {
			// Analyse connection status
			NetStatusEventAnalyzer.analyze			(e);
			var genEvent						:String = NetStatusEventAnalyzer.getGeneralEvent();
			Debug.debug						(_debugPrefix, "onNetConnectionStatus",e,Debug.object(e.info),genEvent);
			if (this.hasOwnProperty(genEvent))		this[genEvent]();
			else {
				Debug.error					(_debugPrefix, "Event",genEvent,"not defined in P2P!");
				// Proceed with simple analisys
				if (NetStatusEventAnalyzer.isNetStream()) {
					try {
						var farID				:String = e.info.stream.farID;
						if (farID == _farId) {
							Debug.debug		(_debugPrefix, "NetStream Event from connected PEER: " + genEvent);
						}
						Debug.debug			(_debugPrefix, "E' qullo out?", (e.info.stream == _netStreamOut));
						Debug.debug			(_debugPrefix, "E' qullo in?", (e.info.stream == _netStreamIn));
						Debug.debug			(_debugPrefix, "Vediamo se ha un far id", e.info.stream.farID);
					}
					catch (e:Error) {
						Debug.error			(_debugPrefix, "Analisys of NetStream NetStatus event received from NetConnection went wrong: " + e);
					}
				}
			}
		}
			public function onNetConnectionConnectSuccess():void {
				setStatus						(2);
				_nearId						= getNearID();
				Debug.debug					(_debugPrefix, "Connection successful. ID:",_nearId);
				initializeOutStream				();
				broadcastP2PEvent				(EV_CONNECTION_SUCCESS);
			}
			public function onNetConnectionConnectError():void {
				Debug.debug					(_debugPrefix, "Connection ERROR.");
				broadcastP2PEvent				(EV_CONNECTION_ERROR);
				reset							(); // Reset brings again all to IDLE
			}
			public function onNetConnectionConnectLost():void {
				Debug.debug					(_debugPrefix, "Connection LOST.");
				broadcastP2PEvent				(EV_CONNECTION_LOST);
				reset							(); // Reset brings again all to IDLE
			}
			public function onNetStreamConnectLost 	():void { // It means we have lost NetStream connection with a connected peer
				Debug.debug					(_debugPrefix, "Connection with PEER lost.");
				destroyPeerConnectionAndReset		();
			}
	// Listeners for NetStream NetStatus events
		private function onStreamOutStatus			(e:NetStatusEvent):void {
			Debug.debug						(_debugPrefix, "OUT>>> ",e,Debug.object(e.info),"farId:"+_netStreamOut.farID,"nearId:"+_netConnection.nearID);
		}
		private function onStreamInStatus			(e:NetStatusEvent):void {
			Debug.debug						(_debugPrefix, "IN>>> ",e,Debug.object(e.info),"farId:"+_netStreamIn.farID,"nearId:"+_netConnection.nearID);
		}
		// UTY //////////////////////////////////////////////////////////////////////////////////////////////////////////
		private function broadcastP2PEvent			(n:String):void {
			broadcastEvent						(n + _id, this);
		}
		// P2P CONNECTION ///////////////////////////////////////////////////////////////////////////////////////
		public function onApp42DocReadSuccessPeers	(doc:App42Document):void {
			_peerListReceived					= true;
			_clientPeerIds						= {};
			var data							:Object = _app42DocumentPeers.getDocObject();
			for (var s:String in data)				if (data[s] is String) _clientPeerIds[s] = data[s];
			broadcastP2PEvent					(EV_PEERS_RECEIVED);
		}
		public function onApp42DocReadErrorPeers	(doc:App42Document):void {
			Debug.error						(_debugPrefix, "Error reading peers list.");
			broadcastP2PEvent					(EV_PEERS_ERROR);
		}
		public function onApp42DocWriteSuccessPeers	(doc:App42Document):void {
			setStatus							(4);
			_peerIdSaved						= true;
			broadcastP2PEvent					(EV_LOGIN_SUCCESS);
		}
		public function onApp42DocWriteErrorPeers	(doc:App42Document):void {
			broadcastP2PEvent					(EV_LOGIN_ERROR);
		}
	}
}