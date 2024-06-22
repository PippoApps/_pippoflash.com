/* NetStatusEventAnalyzer - 1.0 - Filippo Gregoretti - www.pippoflash.com

Analyzes responses from NetStatusEvent and reports if it is a correct answer.


"NetConnection.Call.BadVersion"	"error"	Packet encoded in an unidentified format.
"NetConnection.Call.Failed"	"error"	The NetConnection.call() method was not able to invoke the server-side method or command.
"NetConnection.Call.Prohibited"	"error"	An Action Message Format (AMF) operation is prevented for security reasons. Either the AMF URL is not in the same domain as the file containing the code calling the NetConnection.call() method, or the AMF server does not have a policy file that trusts the domain of the the file containing the code calling the NetConnection.call() method.
"NetConnection.Connect.AppShutdown"	"error"	The server-side application is shutting down.
"NetConnection.Connect.Closed"	"status"	The connection was closed successfully.
"NetConnection.Connect.Failed"	"error"	The connection attempt failed.
"NetConnection.Connect.IdleTimeout"	"status"	Flash Media Server disconnected the client because the client was idle longer than the configured value for <MaxIdleTime>. On Flash Media Server, <AutoCloseIdleClients> is disabled by default. When enabled, the default timeout value is 3600 seconds (1 hour). For more information, see Close idle connections.
"NetConnection.Connect.InvalidApp"	"error"	The application name specified in the call to NetConnection.connect() is invalid.
"NetConnection.Connect.NetworkChange"	"status"	
Flash Player has detected a network change, for example, a dropped wireless connection, a successful wireless connection,or a network cable loss.

Use this event to check for a network interface change. Don't use this event to implement your NetConnection reconnect logic. Use "NetConnection.Connect.Closed" to implement your NetConnection reconnect logic.

"NetConnection.Connect.Rejected"	"error"	The connection attempt did not have permission to access the application.
"NetConnection.Connect.Success"	"status"	The connection attempt succeeded.
"NetGroup.Connect.Failed"	"error"	The NetGroup connection attempt failed. The info.group property indicates which NetGroup failed.
"NetGroup.Connect.Rejected"	"error"	The NetGroup is not authorized to function. The info.group property indicates which NetGroup was denied.
"NetGroup.Connect.Success"	"status"	The NetGroup is successfully constructed and authorized to function. The info.group property indicates which NetGroup has succeeded.
"NetGroup.LocalCoverage.Notify"	"status"	Sent when a portion of the group address space for which this node is responsible changes.
"NetGroup.MulticastStream.PublishNotify"	"status"	Sent when a new named stream is detected in NetGroup's Group. The info.name:String property is the name of the detected stream.
"NetGroup.MulticastStream.UnpublishNotify"	"status"	Sent when a named stream is no longer available in the Group. The info.name:String property is name of the stream which has disappeared.
"NetGroup.Neighbor.Connect"	"status"	Sent when a neighbor connects to this node. The info.neighbor:String property is the group address of the neighbor. The info.peerID:String property is the peer ID of the neighbor.
"NetGroup.Neighbor.Disconnect"	"status"	Sent when a neighbor disconnects from this node. The info.neighbor:String property is the group address of the neighbor. The info.peerID:String property is the peer ID of the neighbor.
"NetGroup.Posting.Notify"	"status"	Sent when a new Group Posting is received. The info.message:Object property is the message. The info.messageID:String property is this message's messageID.
"NetGroup.Replication.Fetch.Failed"	"status"	Sent when a fetch request for an object (previously announced with NetGroup.Replication.Fetch.SendNotify) fails or is denied. A new attempt for the object will be made if it is still wanted. The info.index:Number property is the index of the object that had been requested.
"NetGroup.Replication.Fetch.Result"	"status"	Sent when a fetch request was satisfied by a neighbor. The info.index:Number property is the object index of this result. The info.object:Object property is the value of this object. This index will automatically be removed from the Want set. If the object is invalid, this index can be re-added to the Want set with NetGroup.addWantObjects().
"NetGroup.Replication.Fetch.SendNotify"	"status"	Sent when the Object Replication system is about to send a request for an object to a neighbor.The info.index:Number property is the index of the object that is being requested.
"NetGroup.Replication.Request"	"status"	Sent when a neighbor has requested an object that this node has announced with NetGroup.addHaveObjects(). This request must eventually be answered with either NetGroup.writeRequestedObject() or NetGroup.denyRequestedObject(). Note that the answer may be asynchronous. The info.index:Number property is the index of the object that has been requested. The info.requestID:int property is the ID of this request, to be used by NetGroup.writeRequestedObject() or NetGroup.denyRequestedObject().
"NetGroup.SendTo.Notify"	"status"	Sent when a message directed to this node is received. The info.message:Object property is the message. The info.from:String property is the groupAddress from which the message was received. The info.fromLocal:Boolean property is TRUE if the message was sent by this node (meaning the local node is the nearest to the destination group address), and FALSE if the message was received from a different node. To implement recursive routing, the message must be resent with NetGroup.sendToNearest() if info.fromLocal is FALSE.
"NetStream.Buffer.Empty"	"status"	Flash Player is not receiving data quickly enough to fill the buffer. Data flow is interrupted until the buffer refills, at which time a NetStream.Buffer.Full message is sent and the stream begins playing again.
"NetStream.Buffer.Flush"	"status"	Data has finished streaming, and the remaining buffer is emptied. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Buffer.Full"	"status"	The buffer is full and the stream begins playing.
"NetStream.Connect.Closed"	"status"	The P2P connection was closed successfully. The info.stream property indicates which stream has closed. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Connect.Failed"	"error"	The P2P connection attempt failed. The info.stream property indicates which stream has failed. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Connect.Rejected"	"error"	The P2P connection attempt did not have permission to access the other peer. The info.stream property indicates which stream was rejected. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Connect.Success"	"status"	The P2P connection attempt succeeded. The info.stream property indicates which stream has succeeded. Note: Not supported in AIR 3.0 for iOS.
"NetStream.DRM.UpdateNeeded"	"status"	A NetStream object is attempting to play protected content, but the required Flash Access module is either not present, not permitted by the effective content policy, or not compatible with the current player. To update the module or player, use the update() method of flash.system.SystemUpdater. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Failed"	"error"	(Flash Media Server) An error has occurred for a reason other than those listed in other event codes.
"NetStream.MulticastStream.Reset"	"status"	A multicast subscription has changed focus to a different stream published with the same name in the same group. Local overrides of multicast stream parameters are lost. Reapply the local overrides or the new stream's default parameters will be used.
"NetStream.Pause.Notify"	"status"	The stream is paused.
"NetStream.Play.Failed"	"error"	An error has occurred in playback for a reason other than those listed elsewhere in this table, such as the subscriber not having read access. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Play.FileStructureInvalid"	"error"	(AIR and Flash Player 9.0.115.0) The application detects an invalid file structure and will not try to play this type of file. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Play.InsufficientBW"	"warning"	(Flash Media Server) The client does not have sufficient bandwidth to play the data at normal speed. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Play.NoSupportedTrackFound"	"status"	(AIR and Flash Player 9.0.115.0) The application does not detect any supported tracks (video, audio or data) and will not try to play the file. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Play.PublishNotify"	"status"	The initial publish to a stream is sent to all subscribers.
"NetStream.Play.Reset"	"status"	Caused by a play list reset. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Play.Start"	"status"	Playback has started.
"NetStream.Play.Stop"	"status"	Playback has stopped.
"NetStream.Play.StreamNotFound"	"error"	The file passed to the NetStream.play() method can't be found.
"NetStream.Play.Transition"	"status"	(Flash Media Server 3.5) The server received the command to transition to another stream as a result of bitrate stream switching. This code indicates a success status event for the NetStream.play2() call to initiate a stream switch. If the switch does not succeed, the server sends a NetStream.Play.Failed event instead. When the stream switch occurs, an onPlayStatus event with a code of "NetStream.Play.TransitionComplete" is dispatched. For Flash Player 10 and later. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Play.UnpublishNotify"	"status"	An unpublish from a stream is sent to all subscribers.
"NetStream.Publish.BadName"	"error"	Attempt to publish a stream which is already being published by someone else.
"NetStream.Publish.Idle"	"status"	The publisher of the stream is idle and not transmitting data.
"NetStream.Publish.Start"	"status"	Publish was successful.
"NetStream.Record.AlreadyExists"	"status"	The stream being recorded maps to a file that is already being recorded to by another stream. This can happen due to misconfigured virtual directories.
"NetStream.Record.Failed"	"error"	An attempt to record a stream failed.
"NetStream.Record.NoAccess"	"error"	Attempt to record a stream that is still playing or the client has no access right.
"NetStream.Record.Start"	"status"	Recording has started.
"NetStream.Record.Stop"	"status"	Recording stopped.
"NetStream.SecondScreen.Start"	"status"	Sent when the PlayTo session starts. The description field attached to this event will contain the name of the device that will be getting the video. Applies only to Windows 8.1, IE11, modern mode.
"NetStream.SecondScreen.Stop"	"status"	Sent when the PlayTo session ends. Applies only to Windows 8.1, IE11, modern mode.
"NetStream.Seek.Failed"	"error"	The seek fails, which happens if the stream is not seekable.
"NetStream.Seek.InvalidTime"	"error"	For video downloaded progressively, the user has tried to seek or play past the end of the video data that has downloaded thus far, or past the end of the video once the entire file has downloaded. The info.details property of the event object contains a time code that indicates the last valid position to which the user can seek.
"NetStream.Seek.Notify"	"status"	
The seek operation is complete.

Sent when NetStream.seek() is called on a stream in AS3 NetStream Data Generation Mode. The info object is extended to include info.seekPoint which is the same value passed to NetStream.seek().

"NetStream.Step.Notify"	"status"	The step operation is complete. Note: Not supported in AIR 3.0 for iOS.
"NetStream.Unpause.Notify"	"status"	The stream is resumed.
"NetStream.Unpublish.Success"	"status"	The unpublish operation was successfuul.
"SharedObject.BadPersistence"	"error"	A request was made for a shared object with persistence flags, but the request cannot be granted because the object has already been created with different flags.
"SharedObject.Flush.Failed"	"error"	The "pending" status is resolved, but the SharedObject.flush() failed.
"SharedObject.Flush.Success"	"status"	The "pending" status is resolved and the SharedObject.flush() call succeeded.
"SharedObject.UriMismatch"	"error"	An attempt was made to connect to a NetConnection object that has a different URI (URL) than the shared object.
"NetStream.Video.DimensionChange"	"status"	The video dimensions are available or have changed. Use the Video or StageVideo videoWidth/videoHeight property to query the new video dimensions. New in Flash Player 11.4/AIR 3.4.
*/

package com.pippoflash.net {
	
	import									flash.media.*;
	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import									flash.system.*;
	import									com.pippoflash.utils.*;
	
	public class NetStatusEventAnalyzer {
		// Possible events /////////////////////////////////////////////////////////////////////////////////////////////
		// onNetConnectionConnectSuccess
		// onNetConnectionConnectError
		// onNetConnectionConnectLost
		// onNetConnectionConnectWarning		
		// onNetConnectionCallError
		// VARIABLES /////////////////////////////////////////////////////////////////////////////////////////////////
		private static const _debugPrefix				:String = "NetStatusEventAnalyzer";
		private static const GENERAL_EVENTS_ID		:Array = ["Unknown", "Success", "Error", "Lost", "Warning", "Connect", "Received"];
		private static const GENERAL_EVENTS			:Object = {
			NetConnection:{
				Call:{
					// Errors
					BadVersion					:2,
					Failed					:2,
					Prohibited					:2					
				},
				Connect:{
					// Successes
					Success					:1, // Connected!
					// Lost connection
					Closed					:3, // Lost
					AppShutdown				:3,
					IdleTimeout				:3,
					// Errors
					Failed					:2, 
					Rejected					:2,
					InvalidApp					:2,
					// Warnings
					NetworkChange				:3
				}
			},
			NetStream:{
				Connect:{
					// Success
					Success					:1,
					// Lost
					Closed					:3,
					Failed					:3,
					Rejected					:3
				}
			},
			NetGroup:{
				Connect:{
					Failed					:3,
					Rejected					:3,
					Closed					:3,
					Success					:1
				},
				Posting:{
					Notify					:6
				},
				Neighbor:{
					Connect					:5,
					Disconnect					:3
				}
			}
			/* ADD NetStream, NetGroup, and SharedObject. By now I do not need them. */
		};
		private static const EVENT_DESCRIPTION		:Object = {
			"NetConnection.Call.BadVersion"			:"Packet encoded in an unidentified format.",
			"NetConnection.Call.Failed"				:"The NetConnection.call() method was not able to invoke the server-side method or command.",
			"NetConnection.Call.Prohibited"			:"An Action Message Format (AMF) operation is prevented for security reasons. Either the AMF URL is not in the same domain as the file containing the code calling the NetConnection.call() method, or the AMF server does not have a policy file that trusts the domain of the the file containing the code calling the NetConnection.call() method.",
			"NetConnection.Connect.AppShutdown"	:"The server-side application is shutting down.",
			"NetConnection.Connect.Failed"			:"The connection attempt failed.",
			"NetConnection.Connect.InvalidApp"		:"The application name specified in the call to NetConnection.connect() is invalid.",
			"NetConnection.Connect.Rejected"		:"The connection attempt did not have permission to access the application.",
			"NetConnection.Connect.Closed"			:"The connection was closed successfully.",
			"NetConnection.Connect.IdleTimeout"		:"Flash Media Server disconnected the client because the client was idle longer than the configured value for <MaxIdleTime>. On Flash Media Server, <AutoCloseIdleClients> is disabled by default. When enabled, the default timeout value is 3600 seconds (1 hour). For more information, see Close idle connections.",
			"NetConnection.Connect.NetworkChange"	:"Flash Player has detected a network change, for example, a dropped wireless connection, a successful wireless connection,or a network cable loss. Use this event to check for a network interface change. Don't use this event to implement your NetConnection reconnect logic. Use \"NetConnection.Connect.Closed\" to implement your NetConnection reconnect logic.",
			"NetConnection.Connect.Success"		:"The connection attempt succeeded.",
			

			"NetStream.Connect.Closed"			:"The P2P connection was closed successfully. The info.stream property indicates which stream has closed. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Connect.Success"			:"The P2P connection attempt succeeded. The info.stream property indicates which stream has succeeded. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Connect.Failed"			:"The P2P connection attempt failed. The info.stream property indicates which stream has failed. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Connect.Rejected"			:"The P2P connection attempt did not have permission to access the other peer. The info.stream property indicates which stream was rejected. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Play.InsufficientBW"			:"(Flash Media Server) The client does not have sufficient bandwidth to play the data at normal speed. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Play.FileStructureInvalid"		:"(AIR and Flash Player 9.0.115.0) The application detects an invalid file structure and will not try to play this type of file. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Play.NoSupportedTrackFound"	:"(AIR and Flash Player 9.0.115.0) The application does not detect any supported tracks (video, audio or data) and will not try to play the file. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Play.PublishNotify"			:"The initial publish to a stream is sent to all subscribers.",
			"NetStream.Play.Reset"				:"Caused by a play list reset. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Play.Start"				:"Playback has started.",
			"NetStream.Play.Stop"				:"Playback has stopped.",
			"NetStream.Play.Transition"			:"(Flash Media Server 3.5) The server received the command to transition to another stream as a result of bitrate stream switching. This code indicates a success status event for the NetStream.play2() call to initiate a stream switch. If the switch does not succeed, the server sends a NetStream.Play.Failed event instead. When the stream switch occurs, an onPlayStatus event with a code of \"NetStream.Play.TransitionComplete\" is dispatched. For Flash Player 10 and later. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Play.UnpublishNotify"		:"An unpublish from a stream is sent to all subscribers.",
			"NetStream.Play.Failed"				:"An error has occurred in playback for a reason other than those listed elsewhere in this table, such as the subscriber not having read access. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Play.StreamNotFound"		:"The file passed to the NetStream.play() method can't be found.",
			"NetStream.Publish.BadName"			:"Attempt to publish a stream which is already being published by someone else.",
			"NetStream.Record.Failed"				:"An attempt to record a stream failed.",
			"NetStream.Record.NoAccess"			:"Attempt to record a stream that is still playing or the client has no access right.",
			"NetStream.Seek.Failed"				:"The seek fails, which happens if the stream is not seekable.",
			"NetStream.Seek.InvalidTime"			:"For video downloaded progressively, the user has tried to seek or play past the end of the video data that has downloaded thus far, or past the end of the video once the entire file has downloaded. The info.details property of the event object contains a time code that indicates the last valid position to which the user can seek.",
			"NetStream.Buffer.Empty"				:"Flash Player is not receiving data quickly enough to fill the buffer. Data flow is interrupted until the buffer refills, at which time a NetStream.Buffer.Full message is sent and the stream begins playing again.",
			"NetStream.Buffer.Flush"				:"Data has finished streaming, and the remaining buffer is emptied. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Buffer.Full"				:"The buffer is full and the stream begins playing.",
			"NetStream.DRM.UpdateNeeded"		:"A NetStream object is attempting to play protected content, but the required Flash Access module is either not present, not permitted by the effective content policy, or not compatible with the current player. To update the module or player, use the update() method of flash.system.SystemUpdater. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.MulticastStream.Reset"		:"A multicast subscription has changed focus to a different stream published with the same name in the same group. Local overrides of multicast stream parameters are lost. Reapply the local overrides or the new stream's default parameters will be used.",
			"NetStream.Pause.Notify"				:"The stream is paused.",
			"NetStream.Publish.Idle"				:"The publisher of the stream is idle and not transmitting data.",
			"NetStream.Publish.Start"				:"Publish was successful.",
			"NetStream.Record.AlreadyExists"		:"The stream being recorded maps to a file that is already being recorded to by another stream. This can happen due to misconfigured virtual directories.",
			"NetStream.Record.Start"				:"Recording has started.",
			"NetStream.Record.Stop"				:"Recording stopped.",
			"NetStream.SecondScreen.Start"		:"Sent when the PlayTo session starts. The description field attached to this event will contain the name of the device that will be getting the video. Applies only to Windows 8.1, IE11, modern mode.",
			"NetStream.SecondScreen.Stop"		:"Sent when the PlayTo session ends. Applies only to Windows 8.1, IE11, modern mode.",
			"NetStream.Seek.Notify"				:"The seek operation is complete. Sent when NetStream.seek() is called on a stream in AS3 NetStream Data Generation Mode. The info object is extended to include info.seekPoint which is the same value passed to NetStream.seek().",
			"NetStream.Step.Notify"				:"The step operation is complete. Note: Not supported in AIR 3.0 for iOS.",
			"NetStream.Unpause.Notify"			:"The stream is resumed.",
			"NetStream.Unpublish.Success"			:"The unpublish operation was successful.",
			"NetStream.Video.DimensionChange"		:"The video dimensions are available or have changed. Use the Video or StageVideo videoWidth/videoHeight property to query the new video dimensions. New in Flash Player 11.4/AIR 3.4.",
			"NetStream.Failed"					:"(Flash Media Server) An error has occurred for a reason other than those listed in other event codes.",


			
			"NetGroup.Connect.Failed"				:"The NetGroup connection attempt failed. The info.group property indicates which NetGroup failed.",
			"NetGroup.Connect.Rejected"			:"The NetGroup is not authorized to function. The info.group property indicates which NetGroup was denied.",
			"NetGroup.Connect.Success"				:"The NetGroup is successfully constructed and authorized to function. The info.group property indicates which NetGroup has succeeded.",
			"NetGroup.Connect.Closed"				:"NetGroup connection has ben closed (this in undocumented in Adobe docs).",
			"NetGroup.LocalCoverage.Notify"		:"Sent when a portion of the group address space for which this node is responsible changes.",
			"NetGroup.MulticastStream.PublishNotify"	:"Sent when a new named stream is detected in NetGroup's Group. The info.name:String property is the name of the detected stream.",
			"NetGroup.MulticastStream.UnpublishNotify":"Sent when a named stream is no longer available in the Group. The info.name:String property is name of the stream which has disappeared.",
			"NetGroup.Neighbor.Connect"			:"Sent when a neighbor connects to this node. The info.neighbor:String property is the group address of the neighbor. The info.peerID:String property is the peer ID of the neighbor.",
			"NetGroup.Neighbor.Disconnect"			:"Sent when a neighbor disconnects from this node. The info.neighbor:String property is the group address of the neighbor. The info.peerID:String property is the peer ID of the neighbor.",
			"NetGroup.Posting.Notify"				:"Sent when a new Group Posting is received. The info.message:Object property is the message. The info.messageID:String property is this message's messageID.",
			"NetGroup.Replication.Fetch.Failed"		:"Sent when a fetch request for an object (previously announced with NetGroup.Replication.Fetch.SendNotify) fails or is denied. A new attempt for the object will be made if it is still wanted. The info.index:Number property is the index of the object that had been requested.",
			"NetGroup.Replication.Fetch.Result"		:"Sent when a fetch request was satisfied by a neighbor. The info.index:Number property is the object index of this result. The info.object:Object property is the value of this object. This index will automatically be removed from the Want set. If the object is invalid, this index can be re-added to the Want set with NetGroup.addWantObjects().",
			"NetGroup.Replication.Fetch.SendNotify"	:"Sent when the Object Replication system is about to send a request for an object to a neighbor.The info.index:Number property is the index of the object that is being requested.",
			"NetGroup.Replication.Request"			:"Sent when a neighbor has requested an object that this node has announced with NetGroup.addHaveObjects(). This request must eventually be answered with either NetGroup.writeRequestedObject() or NetGroup.denyRequestedObject(). Note that the answer may be asynchronous. The info.index:Number property is the index of the object that has been requested. The info.requestID:int property is the ID of this request, to be used by NetGroup.writeRequestedObject() or NetGroup.denyRequestedObject().",
			"NetGroup.SendTo.Notify"				:"Sent when a message directed to this node is received. The info.message:Object property is the message. The info.from:String property is the groupAddress from which the message was received. The info.fromLocal:Boolean property is TRUE if the message was sent by this node (meaning the local node is the nearest to the destination group address), and FALSE if the message was received from a different node. To implement recursive routing, the message must be resent with NetGroup.sendToNearest() if info.fromLocal is FALSE.",
			
			
			"SharedObject.BadPersistence"			:"A request was made for a shared object with persistence flags, but the request cannot be granted because the object has already been created with different flags.",
			"SharedObject.UriMismatch"			:"An attempt was made to connect to a NetConnection object that has a different URI (URL) than the shared object.",
			"SharedObject.Flush.Failed"			:"The \"pending\" status is resolved, but the SharedObject.flush() failed.",
			"SharedObject.Flush.Success":"The \"pending\" status is resolved and the SharedObject.flush() call succeeded."
		};
		// SYSTEM
		private static var _event					:NetStatusEvent; // Last event analyzed
		private static var _info						:Object; // Info object from the event
		private static var _code					:String; // Code of the event
		private static var _level					:String;
		private static var _description				:String; // Description as received from the event
		private static var _verboseDescription			:String; // Description stored in memory
		private static var _split					:Array; // Splits code with "."
		private static var _class					:String; // Pos 0 of split
		private static var _action					:String; // Pos 1 of split
		private static var _feedback					:String; // Pos 2 of split. Pos 1 when pos 2 is not available.
		// MARKERS
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		// METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////
		public static function traceAllPossibleGeneralEvents			():void {
			var eventNames								:Object = {};
			var prefix									:String = "on";
			for (var c:String in GENERAL_EVENTS) {
				for (var a:String in GENERAL_EVENTS[c]) {
					for (var f:String in GENERAL_EVENTS[c][a]) {
						eventNames[prefix + c + a + GENERAL_EVENTS_ID[GENERAL_EVENTS[c][a][f]]] = true;
					}
				}
			}
			// Loop for names
			for (var en:String in eventNames)					trace(en);
			
		}
		public static function analyze							(e:NetStatusEvent):void {
			_event										= e;
			_info											= e.info;
			_level										= _info.level;
			_code										= _info.code;
			_description									= _info.description;
			_split											= _code.split(".");
			_class										= _split[0];
			_action										= _split[1];
			_feedback										= _split[2];
			_verboseDescription								= EVENT_DESCRIPTION[_code];
			if (!_verboseDescription) {
				Debug.error								(_debugPrefix, "ERROR, Event not recognized!", e, Debug.object(_info));
			}
		}
		// These methods can be used obnly after setting an event with analyze
		public static function isError							():Boolean {
			return										_level == "error";
		}
		public static function isStatus							():Boolean {
			return										_level == "status";
		}
		public static function isWarning							():Boolean {
			return										_level == "warning";
		}
		public static function isNetConnection					():Boolean {
			return										startsWith("NetC");
		}
		public static function isNetStream						():Boolean {
			return										startsWith("NetS");
		}
		public static function isNetGroup						():Boolean {
			return										startsWith("NetG");
		}
		public static function isSharedObject						():Boolean {
			return										startsWith("S");
		}
			private static function startsWith					(s:String):Boolean {
				return									_code.indexOf(s) == 0;
			}
		public static function getFineEvent						():String { // Returns the fine event from NetStatus: onNetConnectionSuccess, etc...
			return										"on" + _split.join("");
		}
		public static function getEvent						():NetStatusEvent {
			return									_event;
		}
		public static function getEventInfo					():Object {
			return									_event.info;
		}
		public static function getEventInfoMessage				():* {
			return									_event.info && _event.info.hasOwnProperty("message") ? _event.info.message : null;
		}
		public static function getCode						():String {
			return									_code;
		}
		public static function getGeneralEvent					():String { // Returns the general event
			// Events are simplified in groups, they end with Success, Error, Lost, Warning. I.e.: onNetConnectionCallError, instead of all the possible errors.
			var code										:String = "Unknown";
			var evts										:Object = GENERAL_EVENTS[_class];
			//trace("EVENti",evts,_action,evts[_action],_feedback);
			if (evts && evts[_action]) {
				code										= GENERAL_EVENTS_ID[uint(evts[_action][_feedback])];
			}
// 			traceAllPossibleGeneralEvents();
			return										"on" + _class + _action + code;
		}
		// UTY //////////////////////////////////////////////////////////////////////////////////////////////////////////
		// LISTENERS////////////////////////////////////////////////////////////////////////////////////////////////////
	}
}