/* P2PFallback - 1.0 - For P2P not available communication, this class routes through an Adobe Media Server instance
Filippo Gregoretti - www.pippoflash.com

*/
package com.pippoflash.net {
	
	import									flash.media.*;
	import									flash.geom.*;
	import									flash.utils.*;
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
	
	public class P2PFallback extends _PippoFlashBaseNoDisplay {
		// VARIABLES /////////////////////////////////////////////////////////////////////////////////////////////////
// 		private static const USE_AMAZON_AMS		:Boolean = true;
// 		private static const DEF_P2P_CONN_SERVER	:String = "rtmfp://p2p.rtmfp.net";
// 		private static const DEF_DEV_KEY			:String = "e6c407ad8800c57a95664393-e84406920ece"; // Unique developer key
		private static const AMS_AMAZON_URL		:String = "rtmp://54.171.132.10/lavazza/PippoChat";
// 		private static const DEF_APP42_APP_KEY		:String = "751bd1bfefb11c0109e45d1b86a4883112037d94b06adec68db412ee83c8ce23"; // App42 default application key
// 		private static const DEF_APP42_SEC_KEY		:String = "60c13780d36d9ac2b1868ba3e4e9e0e870e7924bd45c83faba0016fff584b954"; // App42 secret key
// 		private static const DEF_APP42_DBNAME		:String = "P2PCLIENTID"; // Name of the DB in the app (it is unique, but App42 requires it)
// 		private static const DEF_APP42_COLLNAME	:String = "PippoFlashTest"; // Name of files collections
// 		private static const DEF_APP42_DOCNAME		:String = "544166c0e4b0e826d615abea"; // ID of document with PEER IDs
		// EVENTS - EVENTS WILL HAVE ID ADDED AT THE END (onConnectionSuccessP2PIdName)
// 		private static const EV_STATUS_CHANGE		:String = "onStatusChange"; // This is broadcasted every time a status us changed
		private static const EV_MIC_MUTED		:String = "onMicMuted"; // Connection to P2P server established
		private static const EV_MIC_ACTIVE		:String = "onMicActive"; // Connection to P2P server established
		private static const EV_CONNECTION_SUCCESS:String = "onConnectionSuccess"; // Connection to P2P server established
		private static const EV_CONNECTION_ERROR	:String = "onConnectionError"; // Connection to P2P server error (while connecting)
		private static const EV_CONNECTION_LOST	:String = "onConnectionLost"; // Connection to P2P server lost (when already connected)
		private static const EV_STREAM_IN_CLOSED	:String = "onPeerStreamClosed"; // When a peer logs off, reloads, or just loses connection
		private static const EV_STREAM_OUT_BADNAME:String = "onPublishingNameTaken"; // When I am publishing on AMS but my OUT stream name is taken
		// NORMAL EVENTS WITHOUT ID ADDED
		private static const EV_EXTERNAL_METHOD	:String = "onPeerSendMethod"; // When a peer sends an event with "EXTERNAL". Receives an array where the first slot is name of method.
		private static const EV_MESSAGE_RECEIVED	:String = "onMessageFromPeer"; // When the peer I am connected to sends me a message (may be group or personal)
// 		private static const EV_PEERS_RECEIVED		:String = "onPeersReceived"; // List of peers farID from App42 received
// 		private static const EV_PEERS_ERROR		:String = "onPeersError"; // Error receiving List of peers farID from App42
// 		private static const EV_LOGIN_SUCCESS		:String = "onLoginSuccess"; // Near ID successfully written to App42
// 		private static const EV_LOGIN_ERROR		:String = "onLoginError"; // Near ID writing on App42 error
// 		private static const EV_PEER_REQUESTING	:String = "onPeerRequest"; // Requesting a direct connection with peer
// 		private static const EV_PEER_REQUEST_ERROR	:String = "onPeerRequestError"; // Peer is not reachable or didn't answer
// 		private static const EV_PEER_CONNECT		:String = "onPeerConnect"; // Connected to peer
		// Implementa da uqi in giu!!!!
// 		private static const EV_PEER_DISCONNECT	:String = "onPeerDisconnect"; // Disconnected from peer
// 		private static const EV_PEER_CALL_SENT		:String = "onPeerCallSent"; // I sent a call to a peer 
// 		private static const EV_PEER_CALL_RINGING	:String = "onPeerCallRinging"; // The call I sent is ringing on peer
// 		private static const EV_PEER_CALL_DENIED	:String = "onPeerCallDenied"; // Peer refused my call
// 		private static const EV_PEER_CALL_ANSWERED	:String = "onPeerCallAnswered"; // Peer answered my call
// 		private static const EV_PEER_HANGED		:String = "onPeerCallHanged"; // Peer hanged up during a call
		// PEER COMMUNICATION
		private static const SERVER_CONNECTION_ALIVE_TIMEOUT:uint = 10; // Seconds to wait for keeping connection alive for CONNECTED P2P SERVER
		private static const P2P_PEER_EVENT_NAME	:String = "onPeerEvent"; // Name method allowed to call on ALL connected peers
		private static const P2P_SINGLE_PEER_EVENT_NAME:String = "onSinglePeerEvent"; // Name of the only method allowed to call on the single connected peer
		private static const RECONNECT_ON_BADNAME	:Boolean = true; // When BadName error arrives. should I try to reconnect again?
		private static const CHECK_PEER_ID_ON_SEND_SINGLE_PEER:Boolean = true; // If I send to a single peer, it checks if it is the peer I am connected to
		// Allowed incoming methods. Cannot be static because it references instance methods.
		private const INCOMING_METHODS			:Object = { // Only these methods are allowed received from client. If a method is NOT in this list it will be rejected.
			// Peer can only call "onPeerEvent" and "onSinglePeerEvent", with 2 parameters, method name (PINGME, MESSAGE, ETC.) and method parameters if any.
			PINGME							:onPeerAskedPing, // When called, client returns a ping to the sender to confirm he is online
			PINGBACK							:onPeerPingedBack, // The other peer has replied to my ping
			VIDEOSTEALTH						:UCode.dummyFunction, // Controller wants me to activate video without showing a video back
			VIDEOCHAT						:UCode.dummyFunction, // Controller wants to activate a videochat
			MSGIN							:onPeerSentMessage, // Receives a message from connected peer
// 			HANGUP							:UCode.dummyFunction, // Controller wants to interrupt all video operations
			EXTERNAL							:onPeerCallBroadcastMethod, // Peer sends a method that needs to be broadcasted
			EMPTY							:null // Somehow the method is empty
		};
		// SWITCHES
		private static var _verbose					:Boolean = true;
		// USER DEFINED
		private var _id							:String; // ID of the P2P connection
		private var _userId						:String; // My user id
		private var _peerId						:String; // Name of peer ID I am receiving
		// SYSTEM - P2P
		private var _p2pServerUrl					:String; // Complet url (uri + key)
		private var _netConnection					:NetConnection; // The P2P Cirrus NetConnection
		private var _farPeerUserName				:String; // The UserName of far peer
		private var _keepServerConnectionAlive			:Boolean; // If connection to P2P SERVER has to be kept alive.
		private var _keepConnectionAliveId			:Number; // An ID to make sure the call is right
		private var _waitingToReconnect				:Boolean; // Marks if I am already waiting for a for a reconnection
		private var _localEchoSuppressionActive			:Boolean;
		private var _micMuted						:Boolean; // If microphone is muted for echo suppression
// 		private var _keepPeerConnectionAlive		:Boolean; // If connection to PEER has to be kept alive. It uses PINGME and PINGBACK.
		private var _pingBackId					:String; // Stores the string to be sent as PINGME to connected peer, and that has to be returned back to confirm pingback.
// 		private var _callId						:String; // ID of the call in progress
		// SYSTEM - CALL AND CONNECTION
		// SYSTEM - NETSTREAM
// 		private static const PUBLISH_STREAM_NAME		:String = "PippoFlashTest"; // Name of publish stram for in and out
		private var _netStreamOut					:NetStream; // This is the public stream I use to connect to P2P service, to receive incoming conections, and to broadcast video and audio
		private var _netStreamIn					:NetStream; // This is the stream I use as a peer connection, to send data messages, and to receive audio and video from a peer
		private var _netStreamOutClient				:Object; // This is the client for streamOut. Gets the onPeerConnect.
		private var _netStreamInClient				:Object; // This is the client for streamIn. Gets the "onPeerEvent" and "onSinglePeerEvent" Object from a peer.
		// LOCAL CAMERA AND MICROPHONE, and remote VVIDEO
		private var _remotePFVideo					:PFVideo; // PFVideo instance to connect to remote video
		private var _PFAVLocal						:PFAVLocal; // PFAVLocal instance to get camera and microphone from
		// MARKERS
		private var _transmittingMedia				:Boolean;
		private var _receivingMedia					:Boolean;
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function P2PFallback					(id:String=null, serverUrl:String=null):void {
			_id								= id ? id : "PippoFlashP2P"; 
			super							(id ? id : _id + Math.random()); // This is NOT singleton, so ID can't be the same
			_p2pServerUrl 						= serverUrl ? serverUrl : AMS_AMAZON_URL;
			Debug.debug						(_debugPrefix, "Initialized on",_p2pServerUrl);
			_netConnection 						= new NetConnection();
			_netConnection.addEventListener			(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
			_netConnection.addEventListener			(SecurityErrorEvent.SECURITY_ERROR, onNetConnectionSecurityError);
			// Initialize NetStream client objects, routing only relevant events.
			_netStreamOutClient					= {
// 				startTransmit					:onStreamOutStartTransmit,
// 				stopTransmit					:onStreamOutStopTransmit,
// 				onPeerConnect					:onPeerConnect
			};
			_netStreamInClient					= {
				startTransmit					:onStreamInStartTransmit,
				stopTransmit					:onStreamInStopTransmit,
// 				onCuePoint						:traceClientEvent,
// 				onImageData					:traceClientEvent,
// 				onMetaData					:traceClientEvent,
// 				onPlayStatus					:traceClientEvent,
// 				onSeekPoint					:traceClientEvent,
// 				onTextData						:traceClientEvent,
				onSinglePeerEvent				:onSinglePeerEvent,
				onPeerEvent					:onPeerEvent // This is the only method accepted by a peer. 
			};
		}
		private function traceClientEvent				(v1:*=null, v2:*=null, v3:*=null):void {
			Debug.debug						(_debugPrefix, "StreamIn Client Event",v1,v2,v3);
		}
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VIDEO AND AUDIO INIT ////////////////////////////////////////////////////
		public function reset						():void { // Closes streams, disconnects from server.
			resetOutStream						();
			resetInStream						();
			disconnect							();
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
		public function connect					(keepServerAlive:Boolean=true, disconnectPrevious:Boolean=false):void { // Connects to a server
			Debug.debug						(_debugPrefix, "Attempting to connect to " + _p2pServerUrl + ". Is already connected? " + isConnected());
			if (isConnected()) {
				if (disconnectPrevious)				disconnect();
				else							return;
			}
			_netConnection.connect				(_p2pServerUrl);
			_keepServerConnectionAlive				= keepServerAlive;
		}
		public function disconnect					():void { 
			_netConnection.close					();
		}
// CHECKS ///////////////////////////////////////////////////////////////////////////////////////
		public function isConnected					(error:String=null):Boolean { // Is connected to Server??? Also an error is traced if sent as parameter.
			if (_netConnection.connected)			return true;
			if (error)							Debug.error(_debugPrefix, error + " NetConnection.connected = false");
			return							false;
		}
		public function isPublishing					():Boolean {
			return							_transmittingMedia;
		}
		public function isReceiving					():Boolean {
			return							_receivingMedia;
		}
// STREAMS /////////////////////////////////////////////////////////////////////
	// GENERAL
		public function activateLocalEchoSuppression		(a:Boolean=true):void {
			// Activates an enterframe event to detect sound level from received stream, and if level is high, the gain of local mic will be set to 0 in order to avoid horrible echo on devices such as nexus 7
			setLocalSuppressionActive				(a);
		}
	// PUBLISHING
		public function publishStream				(streamName:String, audio:Boolean=false, video:Boolean=false):void {
			if (!isConnected("Cannot publish stream.")) 	return;
			resetOutStream						();
			_userId							= streamName;
			Debug.debug						(_debugPrefix, "Publishing stream: " + _userId);
			_netStreamOut.publish					(_userId, "live");
			publishMedia						(audio, video);
		}
		public function publishMedia				(audio:Boolean=true, video:Boolean=true):void {
			if (!isConnected("Cannot publish media.")) 	return;
			_transmittingMedia					= audio || video;
			unMuteMic							();
			_netStreamOut.attachCamera			(video ? _PFAVLocal.getDefaultCam() : null);
			_netStreamOut.attachAudio				(audio ? _PFAVLocal.getDefaultMic() : null);
		}
		public function stopPublishing				():void {
			resetOutStream						();
		}
	// RECEIVING
		public function receiveStream				(streamName:String=null, audio:Boolean=false, video:Boolean=false):void {
			if (!isConnected("Cannot receive stream.")) 	return;
			_peerId							= streamName;
			Debug.debug						(_debugPrefix, "Receiving stream: " + _peerId);
			resetInStream						();
			_netStreamIn.play					(_peerId, -2, -1, false);
			receiveMedia						(audio, video);
		}
		public function receiveMedia				(audio:Boolean=true, video:Boolean=true):void {
			if (!isConnected("Cannot receive media.")) 	return;
			unMuteMic							();
			_netStreamIn.receiveAudio				(audio);
			_netStreamIn.receiveVideo				(video);
			_receivingMedia						= audio || video;
		}
		public function stopReceiving				():void {
			resetInStream						();
		}
	// METHODS FOR CONNECTED CLIENTS - the ones who have recipient:null, can be sent to one or all
		public function pingMe					():void { // Sends a message to pingback to JUST CONNECTED PEER
			if (_peerId)						sendSinglePeerEvent(_peerId, "PINGME");
			else								Debug.error(_debugPrefix, "No peer connected. Cannot send PINGME.");
		}
		public function sendExternal				(...rest):void { // Sends an array to one or all external peers, and they will only broadcast it with EV_EXTERNAL_METHOD
			sendSinglePeerEvent					(_peerId, "EXTERNAL", rest); 
		}
		public function sendMessage				(msg:String=""):void {
			sendSinglePeerEvent					(_peerId, "MSGIN", msg);
		}
		public function sendMessageAll				(recipient:String=null, msg:String=""):void {
			sendPeersEvent						("MSGIN", msg)
		}
	// UTY TO SEND METHODS
			private function sendPeersMethod			(recipient:String=null, method:String="UNDEFINED", par:*=null):void {
				if (recipient)					sendSinglePeerEvent(recipient, method, par);
				else							sendPeersEvent(method, par);
			}
// PEER EVENTS SEND ///////////////////////////////////////////////////////
	// SENDS AN EVENT TO ALL SUBSCRIBERS. THEY WILL ALL RECEIVE IT AND THEY WILL ALL REACT TO IT
		private function sendPeersEvent				(methodName:String="MESSAGE", par:*=null):void {
			if (!isConnected("Cannot send peer event " + methodName)) 	return;
			// Check for errors
			var error							:String = null;
			if (!INCOMING_METHODS[methodName])	error = "Method " + methodName + " not allowed in P2P communication.";
			if (error) {
				Debug.error					(_debugPrefix, error);
				return;
			}
			// No errors, proceed with function
			// Perform specific tasks for specific functions
			if (methodName == "PINGME") 			par = createPingId(par); // If PINGME has no parameter, it will be created here
			// Proceed sending command
			Debug.debug						(_debugPrefix, "Sending peer event:",methodName,(par ? "with param: "+par : ""));
			if (par)							_netStreamOut.send(P2P_PEER_EVENT_NAME, methodName, par);
			else								_netStreamOut.send(P2P_PEER_EVENT_NAME, methodName);
		}
	// SENDS AN EVENT TO A SINGLE PEER. THEY MAY ALL RECEIVE IT, BUT THEY FILTER IT, AND I MAY FILTER HERE TOO
		private function sendSinglePeerEvent			(recipient:String=null, methodName:String="MESSAGE", par:*=null):void {
			if (!isConnected("Cannot send single peer event " + methodName + " to " + recipient)) return;
			// Check for errors
			var error							:String = null;
			if (!INCOMING_METHODS[methodName]) error = "Method " + methodName + " not allowed in P2P communication.";
			else if (!recipient || (CHECK_PEER_ID_ON_SEND_SINGLE_PEER && recipient != _peerId)) error = "Cannot send " + methodName + " to " + recipient + " because I am connected to " + _peerId;
			if (error) {
				Debug.error					(_debugPrefix, error);
				return;
			}
			// No errors, proceed with function
			// Perform specific tasks for specific functions
			if (methodName == "PINGME") 			par = createPingId(par); // If PINGME has no parameter, it will be created here
			// Proceed sending command
			Debug.debug						(_debugPrefix, "Sending peer event:",methodName,(par ? "with param: "+par : ""));
			if (par)							_netStreamOut.send(P2P_SINGLE_PEER_EVENT_NAME, recipient, methodName, par);
			else								_netStreamOut.send(P2P_SINGLE_PEER_EVENT_NAME, recipient, methodName);
		}
	// UTYS FOR SENDING PEER MESSAGES
		private function createPingId				(par:String=null):String {
			if (!par)							par = String(Math.random());
			_pingBackId						= par;
			return							par;
		}
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CONNECTION //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		private function keepConnectionAlive			():void { // Called on connection lost or error (not on connection closed)
			if (_waitingToReconnect) {
				return;
				Debug.error					(_debugPrefix, "Keep connection alive is already active. Cannot keep it again.");
			}
			else if (_keepServerConnectionAlive) {
				Debug.debug					(_debugPrefix, "Connection must be kept alive. Next attempt to connect in " + SERVER_CONNECTION_ALIVE_TIMEOUT + " seconds.");
				_keepConnectionAliveId			= Math.random();
				_waitingToReconnect				= true;
				UExec.time					(10, reconnect, _keepConnectionAliveId);
			}
		}
		private function reconnect					(id:Number):void {
			if (_waitingToReconnect && id == _keepConnectionAliveId) {
				_keepConnectionAliveId			= -1;
				_waitingToReconnect				= false;
				if (_p2pServerUrl)				connect(_keepServerConnectionAlive);
			}
		}
// ECHO SUPPRESSION ///////////////////////////////////////////////////////////////////////////////////////
		private function setLocalSuppressionActive		(a:Boolean):void {
			// Things happen only when status changes
			if (a && !_localEchoSuppressionActive) {
				_mainApp.addEventListener			(Event.ENTER_FRAME, onEchoSuppressionFrameElapsed);
			}
			else if (!a && _localEchoSuppressionActive) {
				_mainApp.removeEventListener		(Event.ENTER_FRAME, onEchoSuppressionFrameElapsed);
			}
			_localEchoSuppressionActive				= a;
			Debug.debug						(_debugPrefix, "Local Echo Suppression " + (_localEchoSuppressionActive ? "ACTIVE" : "DISABLED"));
		}
		

		private static const MIC_MUTE_LEVEL			:uint = 100; // Starts muting when audio bytes per second go over this
		private static const MIC_UNMUTE_LEVEL		:uint = 600; // Unmutes when level starts decreasing and it goes below this
		private static const MIC_MUTE_MIN_TIME		:uint = 300; // Milliseconds that have to be elapsed at least before a change of status (on Android it strangely does some quick ping-pong)
		private static const MIC_UNMUTE_MIN_TIME		:uint = 200; // Milliseconds that have to be elapsed at least before a change of status (on Android it strangely does some quick ping-pong)
		private var _audioBytePeak					:Number;
		private var _checkAudioBytesFunc				:Function;
// 		private var _lastMicStatusChange				:uint; // getTimer() stores last time audio has changed
		private var _lastMicStatusChangeTarget			:uint; 
		private var _audioBytesPerSecond				:Number;
		private function onEchoSuppressionFrameElapsed	(e:Event):void {
			if (_netStreamIn && _receivingMedia) {
// 				trace(_netStreamIn.info.audioBytesPerSecond);
// 				_lastAudioBytes					= _netStreamIn.info.audioByteCount;
				_audioBytesPerSecond				= _netStreamIn.info.audioBytesPerSecond;
				_checkAudioBytesFunc				();
			}
		}
		private function checkWhenToMute			():void {
			if (getTimer() > _lastMicStatusChangeTarget && _audioBytesPerSecond > MIC_MUTE_LEVEL && _audioBytesPerSecond > _audioBytePeak) {
				// Ok I have to mute and prepare to mute here
				muteMic						();
			}
			else {
				_audioBytePeak					= _audioBytesPerSecond;
			}
		}
		private function checkWhenToUnmute			():void {
			if (_audioBytesPerSecond > _audioBytePeak) {
				_audioBytePeak					= _audioBytesPerSecond;
			}
			else if (getTimer() > _lastMicStatusChangeTarget && _audioBytesPerSecond < MIC_UNMUTE_LEVEL) {
				if (_audioBytePeak > MIC_UNMUTE_LEVEL || _audioBytesPerSecond < MIC_MUTE_LEVEL) unMuteMic();
			}
		}
		private function unMuteMic					():void {
			_micMuted							= false;
			_audioBytePeak						= MIC_MUTE_LEVEL;
			_PFAVLocal.setMicGain					(50);
			_lastMicStatusChangeTarget				= getTimer() + MIC_UNMUTE_MIN_TIME;
			_checkAudioBytesFunc					= checkWhenToMute;
			broadcastP2PEvent					(EV_MIC_ACTIVE);
			Debug.debug						(_debugPrefix, "Mic set to ACTIVE");
		}
		private function muteMic					():void {
			_micMuted							= true;
			_PFAVLocal.setMicGain					(0);
			_lastMicStatusChangeTarget				= getTimer() + MIC_MUTE_MIN_TIME;
			_checkAudioBytesFunc					= checkWhenToUnmute;
			broadcastP2PEvent					(EV_MIC_MUTED);
			Debug.debug						(_debugPrefix, "Mic set to MUTED");
		}
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STREAMS MANAGEMENT ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Stream OUT initialization - performed only when I connect to P2P server the first time.
		private function initializeOutStream			():void { 
			// This is called ONLY ONCE, when the netConnection is opened successfully
			if (!isConnected("Cannot initialize OUT stream.")) return;
			if (_netStreamOut)					return;
			_netStreamOut						= new NetStream(_netConnection, NetStream.CONNECT_TO_FMS);
			_netStreamOut.bufferTime				= 0; // As specified in www.adobe.com/devnet/flashplayer/articles/acoustic-echo-cancellation.html
			_netStreamOut.useJitterBuffer			= true; // As specified in www.adobe.com/devnet/flashplayer/articles/acoustic-echo-cancellation.html
			_netStreamOut.addEventListener			(NetStatusEvent.NET_STATUS, onStreamOutStatus);
			_transmittingMedia					= false;
			Debug.debug						(_debugPrefix, "Initialized OUT NetStream");
		}
		private function resetOutStream				():void {
			if (!_netStreamOut)					return;
			Debug.debug						(_debugPrefix, "OUT stream RESET");
			publishMedia						(false, false);
			_netStreamOut.removeEventListener		(NetStatusEvent.NET_STATUS, onStreamOutStatus);
// 			if (isConnected()) {
				try {
					_netStreamOut.close				();
					_netStreamOut.dispose			();
				}
				catch (e:Error) {
					Debug.error				(_debugPrefix, "_netStreamOut.dispose() " + e);
				}
// 			}
			_netStreamOut						= null;
			_userId							= null;
			initializeOutStream					();
		}
	// Stream IN initialization, performed when I accept a connection from another peer...
		private function initializeInStream			(farId:String=null):void { // Initializes IN stream. Only once the connected peer is connected.
			if (!isConnected("Cannot initialize IN stream.")) return;
			if (_netStreamIn)					return;
			_netStreamIn						= new NetStream(_netConnection, NetStream.CONNECT_TO_FMS);
			_netStreamIn.bufferTime				= 0; // As specified in www.adobe.com/devnet/flashplayer/articles/acoustic-echo-cancellation.html
			_netStreamIn.useJitterBuffer			= true; // As specified in www.adobe.com/devnet/flashplayer/articles/acoustic-echo-cancellation.html
			_netStreamIn.addEventListener			(NetStatusEvent.NET_STATUS, onStreamInStatus);
			_netStreamIn.client					= _netStreamInClient;
			_remotePFVideo.attachStream			(_netStreamIn);
			Debug.debug						(_debugPrefix, "Initialized IN NetStream");
			_receivingMedia						= false;
		}
		private function resetInStream				():void {
			if (!_netStreamIn)					return;
			// There is a bug, if I do not re-create a tream, it will connect always to the same client! even if I call dispose()
			Debug.debug						(_debugPrefix, "IN stream RESET");
			receiveMedia						(false, false);
			_netStreamIn.removeEventListener		(NetStatusEvent.NET_STATUS, onStreamInStatus);
			_netStreamIn.client					= {};
// 			if (isConnected()) {
				try {
					_netStreamIn.close			();
					_netStreamIn.dispose			();
				}
				catch (e:Error) {
					Debug.error				(_debugPrefix, "_netStreamIn.dispose() " + e);
				}
// 			}
			_netStreamIn						= null;
			initializeInStream						();
		}
// onPeerEvent METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Methods in NetStream clients (They MUST be public) 
	// OUT STREAM
		public function onPeerConnect				(connectedStream:NetStream=null):Boolean {
// 			// Called when another peer sends me a netstream. In this caseI have to grab it, and resend my stream by myself.
// 			// Find the peer name if I have it in list
// 			var peerName						:String = "[Name not found]";
// 			for (var n:String in _clientPeerIds) {
// 				if (_clientPeerIds[n] == connectedStream.farID) {
// 					peerName					= n;
// 					break;
// 				}
// 			}
			Debug.debug						(_debugPrefix, "onPeerConnect");
// 			// If I receive this, if streamin is not initialized, I do initialize it. It means somebody has called me.
// 			/* WARNING THIS IS AN AUTOMATED ACCEPTANCE FOR CALL */
// 			if (!_netStreamIn || _netStreamIn.farID != connectedStream.farID) {
// 				initializeInStream				(connectedStream.farID);
// 				setStatus						(6);
// 			}
// 			connectedStream.client				= _netStreamInClient;
// 			// A peer has connected successfully
// 			setStatus							(7);
// 			broadcastP2PEvent					(EV_PEER_CONNECT);
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
		public function onPeerEvent					(methodName:String="EMPTY", par:*=null):void {
			// This is the only handler allowed in clint for IN NetStream. Here I filter handlers and interpret which one I should call.
			Debug.debug						(_debugPrefix, "Received from connected peer ["+_peerId+"] method",methodName,(par ? "with param: "+par : ""));
			if (INCOMING_METHODS[methodName]) {
				if (par)						INCOMING_METHODS[methodName](par);
				else							INCOMING_METHODS[methodName]();
			}
			else {
				Debug.error					(_debugPrefix, "Method not allowed. Execution aborted.");
			}
		}
		public function onSinglePeerEvent				(recipient:String, methodName:String="EMPTY", par:*=null):void {
			// This is the only handler allowed in clint for IN NetStream. Here I filter handlers and interpret which one I should call.
			Debug.debug						(_debugPrefix, "Received " + methodName + " for " + recipient + (par ? " with param: "+par : ""));
			if (_userId != recipient) {
				Debug.debug					(_debugPrefix, "I cant execute since it is not me, I am " + _userId);
				return;
			}
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
		private function onCallReceived				(callId:String=null):void { // Connected peer is calling me
// 			Debug.debug						(_debugPrefix, "Receiving call...");
// 			if (isInCall(false)) { // I am already in a call or calling someone
// 				Debug.error					(_debugPrefix, "Somebody called me but I am already in a call. Status: " + _statusDescription);
// 				return;
// 			}
// 			else {
// 				_callId						= callId;
// 				sendPeersEvent					("ITSRINGING", _callId);
// 				setStatus						(9);
// 				Debug.debug					(_debugPrefix, "Ringing... Ringing... Ringing...");
// 			}
		}
	// Internal methods accepted by peers
		private function onPeerAskedPing				(pingId:String=null):void { // Just ot make sure I add a parameter
			Debug.debug						(_debugPrefix, "Connected peer has requested a ping with ID: " + pingId);
			sendSinglePeerEvent					(_peerId, "PINGBACK", pingId);
		}
		private function onPeerPingedBack			(pingId:String=null):void {
			Debug.debug						(_debugPrefix, "Connected peer has sent a ping back with ID: " + pingId);
			if (pingId == _pingBackId)				onPeerPingBackSuccessful();
			else								onPeerPingBackError(pingId);
		}
		private function onPeerPingBackError			(pingId:String=null):void {
			Debug.error						(_debugPrefix, "PINGBKACK returned has ID " + pingId + " while expected ping was " + _pingBackId);
		}
		private function onPeerPingBackSuccessful		():void {
			Debug.debug						(_debugPrefix, "PINGBACK was successfully received.");
			_pingBackId						= null;
		}
		private function onPeerSentMessage			(msg:String=null):void {
			Debug.debug						(_debugPrefix, _peerId + ": " + msg);
			broadcastEvent						(EV_MESSAGE_RECEIVED, msg);
		}
	// External method, this will be only launched as a broadcast - CALLED WHEN RECEIVING A SENDEXTERNAL
		private function onPeerCallBroadcastMethod		(par:Array):void {
			Debug.debug						(_debugPrefix, "Broadcasting external event : " + Debug.object(par));
			broadcastEvent(EV_EXTERNAL_METHOD, par);
// 			if (rest.length) {
// 				if (rest.length == 1)				broadcastEvent(EV_EXTERNAL_METHOD, method, rest[0]);
// 				else if (rest.length == 2)			broadcastEvent(EV_EXTERNAL_METHOD, method, rest[0], rest[1]);
// 				else if (rest.length == 3)			broadcastEvent(EV_EXTERNAL_METHOD, method, rest[0], rest[1], rest[2]);
// 			}
// 			else								broadcastEvent(EV_EXTERNAL_METHOD, method);
		}
// 		private function onMessageReceived			(msg:String="message empty"):void {
// 			Debug.debug						(_debugPrefix, "Received message: " + msg);
// 		}
// 		private function onCallReceived				(callId:String=null):void { // Connected peer is calling me
// 			Debug.debug						(_debugPrefix, "Receiving call...");
// 			if (isInCall(false)) { // I am already in a call or calling someone
// 				Debug.error					(_debugPrefix, "Somebody called me but I am already in a call. Status: " + _statusDescription);
// 				return;
// 			}
// 			else {
// 				_callId						= callId;
// 				sendPeersEvent					("ITSRINGING", _callId);
// 				setStatus						(9);
// 				Debug.debug					(_debugPrefix, "Ringing... Ringing... Ringing...");
// 			}
// 		}
// 		private function onCallSentRinging			(callId:String=null):void { // Peer I called, confirmed me that it is ringing on his side
// 			if (callId == _callId) { // The correct call is ringing on peer
// 				Debug.debug					(_debugPrefix, "Peer is ringing from my call.");
// 				broadcastP2PEvent				(EV_PEER_CALL_RINGING);
// 			}
// 			else {
// 				Debug.error					(_debugPrefix, "Peer says he is ringing, but the call id is wrong! His ID " + callId + ", my ID " + _callId);
// 			}
// 		}
// 		private function onCallAnswered			():void {
// 			Debug.debug						(_debugPrefix, "Peer just answered the call! Opening P2P call on my side.");
// 			openP2PCall						();
// 		}
// 		private function onCallHanged				():void {
// 			if (isInCall(false)) { // I am either calling him or in a call
// 				if (isCalling(true)) {
// 					Debug.debug				(_debugPrefix, "User DENIED, he didnt answer the call and hanged up in your face!");
// 				}
// 				else if (isInCall(true)) {
// 					Debug.debug				(_debugPrefix, "User hanged up.");
// 				}
// 			}
// 			else {
// 				Debug.error					(_debugPrefix, "Received a call hangup, but my status is " + _statusDescription);
// 			}
// 		}
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// CONNECTION listeners
		public function onNetConnectionSecurityError		(e:SecurityErrorEvent):void {
			Debug.error						(_debugPrefix, "SECUTIRY ERROR EVENT:",e);
		}
		public function onNetConnectionStatus			(e:NetStatusEvent):void {
			// Analyse connection status
			NetStatusEventAnalyzer.analyze			(e);
			var genEvent						:String = NetStatusEventAnalyzer.getGeneralEvent();
			Debug.debug						(_debugPrefix, "onNetConnectionStatus",e,Debug.object(e.info),genEvent);
			if (this.hasOwnProperty(genEvent))		this[genEvent]();
			else {
				Debug.error					(_debugPrefix, "Event",genEvent,"not defined in P2P!");
				// Proceed with simple analisys
				if (NetStatusEventAnalyzer.isNetStream()) {
						Debug.error			(_debugPrefix, "NetConnection NEtStream event:" + e);
				}
			}
		}
			public function onNetConnectionConnectSuccess():void {
				Debug.debug					(_debugPrefix, "Connection successful.");
				initializeOutStream				();
				initializeInStream					();
				broadcastP2PEvent				(EV_CONNECTION_SUCCESS);
			}
			public function onNetConnectionConnectError():void {
				Debug.debug					(_debugPrefix, "Connection ERROR.");
				resetInStream					();
				resetOutStream					();
				broadcastP2PEvent				(EV_CONNECTION_ERROR);
				keepConnectionAlive				();
			}
			public function onNetConnectionConnectLost():void {
				Debug.debug					(_debugPrefix, "Connection LOST.");
				resetInStream					();
				resetOutStream					();
				broadcastP2PEvent				(EV_CONNECTION_LOST);
				keepConnectionAlive				();
			}
			public function onNetStreamConnectLost 	():void { // It means we have lost NetStream connection with a connected peer
				Debug.debug					(_debugPrefix, "Connection with PEER lost.");
// 				destroyPeerConnectionAndReset		();
			}
	// Listeners for NetStream NetStatus events
		private function onStreamOutStatus			(e:NetStatusEvent):void {
			Debug.debug						(_debugPrefix, "OUT>>> ",e,Debug.object(e.info));
			// Here some analisis of netstreams should be done...
			if (e.info.code == "NetStream.Publish.BadName") {
				// The other peer stopped publishing
				broadcastP2PEvent				(EV_STREAM_OUT_BADNAME);
				if (RECONNECT_ON_BADNAME)		disconnect();
			}
		}
		private function onStreamInStatus			(e:NetStatusEvent):void {
			Debug.debug						(_debugPrefix, "IN>>> ",e,Debug.object(e.info));
			// Here some analisis of netstreams should be done...
			if (e.info.code == "NetStream.Play.UnpublishNotify") {
				// The other peer stopped publishing
				broadcastP2PEvent				(EV_STREAM_IN_CLOSED);
			}
		}
		// UTY //////////////////////////////////////////////////////////////////////////////////////////////////////////
		private function broadcastP2PEvent			(n:String):void {
			broadcastEvent						(n + _id, this);
		}
		// P2P CONNECTION ///////////////////////////////////////////////////////////////////////////////////////
	}
}