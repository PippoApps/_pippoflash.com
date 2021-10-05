package com.pippoflash.smartfox {
// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
import com.pippoflash.framework._PippoFlashBase; import com.pippoflash.utils.*; import com.pippoflash.smartfox.*; import it.gotoandplay.smartfoxserver.*; import it.gotoandplay.smartfoxserver.data.*;
import flash.display.*; import flash.events.*; import flash.geom.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*;
// DECLARATION //////////////////////////////////////////////////////////////////////////
	public dynamic class PFRooms extends com.pippoflash.framework._PippoFlashBase {
		// STATIC - DEBUG SWITCHES
		// STATIC CONSTANTS
		private static var ROOM_TYPE_CLASS		:Object = {Lobby:PFRoom, Game:PFRoom}; // Class associated to room types (it can be granular or just general. Each ID added checks for room name to BEGIN with the ID and associates the class)
// 		private static var MAIN_LOBBY_NAME		:String = "MainLobby";
		private static const VERBOSE		:Boolean = true;
		public static var BROADCAST_ONLY_AFTER_HANDSHAKE:Boolean = true; // If broadcasting has to be done only after SFS handshake is received
		private static const BROADCAST_ON_JOIN_ROOM:String = "onJoinedPFRoom";
		private static const BROADCAST_ON_JOIN_ROOM_ERROR:String = "onJoinPFRoomError";
		private static const BROADCAST_JOIN_FIXED_ROOM:Object = { // Broadcasts to be sent for joining different rooms. En extra broadcast will be done on first access.
			// If a room with this name is joined, this will be broadcasted
			MainLobby:"onJoinPokerLobby",
			LoginArea:"onJoinLoginArea",
			CasinoLobby:"onJoinCasinoLobby",
			RouletteLobby:"onJoinRouletteLobby",
			RouletteGame:"onJoinRouletteGame"
		};
		private static const BROADCAST_POSTFIX_FIRST_TIME_JOIN:String = "FirstTime"; // another broadcast will be done with "first time" for everytime I join a lobby the first time. This will be added to room specific broadcast. Both will be done.
		// SYSTEM
		private static var _roomLoginAreaName		:String;
		private static var _roomMainLobbyName		:String;
		// REFERENCES
		protected var _sfMan					:SmartFoxMan;
		// MARKERS
		protected var _reRender				:Boolean = false;
		protected var _handshakeReceived		:Boolean = false;
		protected var _joinedRoom			:PFRoom;
		protected var _connectedRoom			:Room;
		protected var _connectedPFRoom		:PFRoom;
		protected var _lastConnectedLobby		:PFRoom; // The last lobby I was connected to, in case of "go back" functions
		protected var _joinedRooms			:Object; // Room name to # of joins
		// GALLERY
		// DATA HOLDERS
		protected var _defaultRooms			= {}; // Stores default PF rooms by name, only for default rooms that can get processed BEFORE receiving handshake
		protected var _allRooms				= []; // All rooms in array
		protected var _roomsByName			= {}; // All rooms by NAME
		protected var _roomsById				= []; // All rooms by ID
		protected var _gameRooms			= []; // All game rooms in array
		protected var _gameRoomsPublic		= {}; // Only public game rooms
		protected var _gameRoomsPrivate		= {}; // Only private game rooms
		// CONFIG REFERENCES
		// STATIC UTY
		private static var _room				:Room;
		private static var _PFRoom				:*;
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function PFRooms					():void {
			super							("PFRooms");
			PFRoom._rooms					= this;
		}
		public function init						(sfMan:SmartFoxMan):void { // Called by SmartFoxMan
			_joinedRooms						= {};
			UMem.addClass					(ROOM_TYPE_CLASS.Game);
			UMem.addClass					(ROOM_TYPE_CLASS.Lobby);
			_sfMan							= sfMan;
			_sfMan.addListenerTo				("onSmartFoxRoomListUpdate", this);
			_sfMan.addListenerTo				("onSmartFoxRoomDeleted", this);
			_sfMan.addListenerTo				("onSmartFoxRoomAdded", this);
			// Updated a list of PF rooms
			_sfMan.addListenerTo				("onSmartFoxPFRLU", this); // This event has to be fired by server, since variables are updated ONLY if I am inside the room itself
			// Updated ONE PF room
			_sfMan.addListenerTo				("onSmartFoxPFRU", this); // This event has to be fired by server, since variables are updated ONLY if I am inside the room itself
			// Also a room variables update - COMMENTED - There is a bug in SFS code, it sends old variables
			_sfMan.addListenerTo				("onSmartFoxRoomVariablesUpdate", this); // This event has to be fired by server, since variables are updated ONLY if I am inside the room itself
			// Room join and leave
			_sfMan.addListenerTo				("onSmartFoxJoinRoom", this); // The room I have joined
			_sfMan.addListenerTo				("onSmartFoxJoinRoomError", this); // The room I have joined
			// Add reference to rooms
			_mainApp.setReference				("_rooms", this);
		}
		public function onSmartFoxRoomVariablesUpdate(par:Object):void {
			_PFRoom							= getRoomByRoom(par.room);
			if (!_PFRoom || _PFRoom.isUnknown()) {
				Debug.error					(_debugPrefix, par.room.getName(),"is unknown or unexistant. Brodacast of variables update aborted.");
				return;
			}
			_PFRoom.refreshRoomVars				();
			broadcastEvent						("onRoomUpdated", _PFRoom);
		}
		public function onConfig					():void {
			_roomLoginAreaName					= _config._settings.SMARTFOX.LOGINAREA.@name;
			_roomMainLobbyName					= _config._settings.SMARTFOX.MAINLOBBY.@name;
			PFRoom.onConfigStatic				();
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function reset						():void {
			// This is supposed to happen on refresh, but I removed it so that when rooms are refreshed, it uses old PFRooms for the same room
			UMem.storeInstances					(_allRooms);
			_allRooms							= [];
			_gameRooms						= [];
			_roomsById							= [];
			_roomsByName						= {};
			_gameRoomsPublic					= {};
			_gameRoomsPrivate					= {};
			_reRender							= false;
		}
		public function setClass					(roomClass:Class, type:String="ALL"):void {
			if (type == "ALL") 					for (_s in ROOM_TYPE_CLASS) ROOM_TYPE_CLASS[_s] = roomClass;
			else								ROOM_TYPE_CLASS[type] = roomClass;
		}
		public function renderFineDataInAllRooms			():void {
			_handshakeReceived					= true;
			for each (_PFRoom in _allRooms) {
				_PFRoom.updateRoomData			();
			}
			processStoredRoomsList				();
			// If so, I haven't broadcasted anything before, therefore it is now that I broadcast that I have received a list of rooms
			if (BROADCAST_ONLY_AFTER_HANDSHAKE)	broadcastEvent("onRoomsReceived");
		}
// ROOMS ///////////////////////////////////////////////////////////////////////////////////
		private function processStoredRoomsList			():void {
			// To finally process stored rooms list once handshake is received
			
		}
		private function processRoomsList			(roomsList:Array):void {
// 			reset								();
			// Delete disappeared rooms if it is not the first render
			if (_reRender) 						deleteRoomsNotInList(roomsList) // NOT the first time list is rendered, I first proceed deleting rooms
			// Update or create rooms - reset containers EXCEPT rooms by name
			_allRooms							= [];
			_gameRooms						= [];
			_roomsById						= {};
			_gameRoomsPublic					= {};
			_gameRoomsPrivate					= {};
			if (_handshakeReceived) {
 				if (VERBOSE) Debug.debug(_debugPrefix, "Processing entire rooms list...");
				for each (_room in roomsList) {
// 					// Controllo che sia effetivamente una stanza POKER, altrimenti vattanaffancala
// 					if (isPokerRoom(_room)) {
						processRoom			(_room);
// 					}
// 					else {
// 						if (VERBOSE) 			Debug.debug(_debugPrefix, "Room is NOT a Poker room. I am not processing it.");
// 					}
				}
// 				trace("ECCO GLI ARRAY:");
// 				trace("_allRooms",_allRooms.length,_allRooms);
// 				trace("_gameRooms",_gameRooms.length,_gameRooms);
// 				trace("_gameRoomsPublic",Debug.object(_gameRoomsPublic));
// 				trace("_gameRoomsPrivate",Debug.object(_gameRoomsPrivate));
			}
			else {
				Debug.debug(_debugPrefix, "SFS Handshake not yet received, processing temporary rooms list.");
				for each (_room in roomsList) {
					if (_config.isDefaultRoom(_room.getName())) {
						_defaultRooms[_room.getName()] = processRoom(_room);
					}
				}
				Debug.debug				(_debugPrefix, "Default room rendered before handshake: ", Debug.object(_defaultRooms));
			}
			broadcastEvent					("onRoomsReceived");
		}
				private function deleteRoomsNotInList	(roomsList:Array):void {
					// Debug.debug				(_debugPrefix, "Deleting rooms which are not in list. List items:"+_allRooms.length);
					// Debug.debug				(_debugPrefix, Debug.object(_allRooms));
					var roomNames				:Array = [];
					for each (_room in roomsList) {
						roomNames.push			(_room.getName());
					}
					var roomNamesString		:String = roomNames.join(",");
					var roomName				:String;
					for each (_PFRoom in _allRooms) {
						if (_PFRoom) {
							roomName				= _PFRoom.getRoomName();
							if (roomNamesString.indexOf(roomName) == -1) { // Room has been deleted
								// Debug.debug		(_debugPrefix, "Deleting room " + roomName);
								removeRoom		(roomName, _PFRoom.getRoomId(), false);
							}
						}
					}
				}
		private function processRoom				(room:Room):PFRoom {
			if (!isPokerRoom(room)) {
				if (VERBOSE) 			Debug.debug(_debugPrefix, room.getName() + " is NOT a Poker room. I am not processing it.");
				return null;
			}
			// Prepare standard PFRoom, do styuff before HANDSHAKE
			var roomName						:String = room.getName();
			if (VERBOSE) 						Debug.debug(_debugPrefix, "Processing "+roomName);
			_PFRoom							= _roomsByName[roomName];
			if (_PFRoom) { // Recycle by hand a PFRoom
				_PFRoom.recycle				(room);
			}
			else { // Use a new one received from UMem
				_PFRoom						= UMem.getInstance(ROOM_TYPE_CLASS.Game, room);
			}
			if (_allRooms.indexOf(_PFRoom) == -1)	_allRooms.push(_PFRoom);
			_roomsById[_room.getId()]			= _PFRoom;
			_roomsByName[roomName]			= _PFRoom;
			// Proceed only if handshake is already received
			if (_handshakeReceived) {
				if (_PFRoom.isUnknown()) {
					Debug.error				(_debugPrefix, _PFRoom.getRoomName(),"is unknown. Not added to ANY list.");
					return					_PFRoom;
				}
				// Proceed with game or non-game setup
				if (_PFRoom.isGame) { // Check if room is game room using new logic
					if (_gameRooms.indexOf(_PFRoom) == -1) _gameRooms.push(_PFRoom);
					if (_PFRoom.isPublic())		_gameRoomsPublic[roomName] = _PFRoom;
					else						_gameRoomsPrivate[roomName] = _PFRoom;
				}
				else { // Room is not a game room - Not much has to be done now.
					// Nothing happens for non-game rooms
				}
			}
			return							_PFRoom;
		}
		private function removeRoom				(roomName:String, roomId:int, broadcast:Boolean=true):void {
			
			_PFRoom							= _roomsByName[roomName];
			
			if (!_PFRoom || _PFRoom.isUnknown()) {
				Debug.error					(_debugPrefix, roomName,"is unknown or unexistant. Broadcast of REMOVE canceled.");
				return;
			}
			if (_PFRoom.isGame) { // Room is a game room
				UCode.removeArrayItem			(_gameRooms, _PFRoom);
				delete						_gameRoomsPublic[roomName];
				delete						_gameRoomsPrivate[roomName];
			}
// 			else { // Room is not a game room
// 				// Noting happens. So far non-game rooms can't be destroyed.
// 				// Mhhhhhh....  ERROR!!!! Non game rooms also can be destroyed!
// 			}
			// Perform stuff for all kinds of room
			delete							_roomsByName[roomName];
			delete							_roomsById[roomId];
			UCode.removeArrayItem				(_allRooms, _PFRoom);
			// Broadcast room was detroyed - BEFORE STORING INSTANCE - So that PFRoom data can eventually be accessed
			if (broadcast)						broadcastEvent("onRoomRemoved", roomName); // PFRoom is still available when this is called
			// Delete counter for specific room number of accesses (in case it was accessed before)
			delete							_joinedRooms[_PFRoom.getName()];
			// Store instance
			UMem.storeInstance					(_PFRoom);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function broadcastGranularJoinRoomEvent(room:PFRoom):void { // Called by join room event, I need this to broadcast particular join room events
			// This is needed to broadcast special joined room events. For special actions. They will be listened by ApiMan who then will make some API work.
			if (room.isTournamentLobby()) { // I have antered a tournament lobby
				if (room.isStatic) 				broadcastEvent("onJoinMTTTour", room, true); /* TO IMPROVE - Now this is broadcasted also if I join as a spectator */
			}
			if (room.isPokerGame) { // This means I am joining a poker table 
				/* TO IIMPROVE WITH SERVER SIDE EVENTS, I DON'T KNOW IF I AM A PLAYER OR SPECTATOR HERE */
// 				trace("JOINOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
// 				trace("DEBUG SATELLITES", room.getDebugSatelliteString());
				if (room.isCash()) 				broadcastEvent("onJoinCashTable", room);
				else if (room.isSatelliteStep)		broadcastEvent("onJoinSatellitePokerRoom", room);
				else if (room.isEuro()) 			broadcastEvent("onJoinSitGoCashTable", room);
				else if (room.isGold()) 			broadcastEvent("onJoinSitGoGoldTable", room);
			}
		}
// DATA RETRIEVAL ///////////////////////////////////////////////////////////////////////////////////////
		public function getMainLobby				():PFRoom { // La MainLobby del POKER
			return							getDefaultRoom("MainLobby");
		}
		public function getDefaultRoom				(id:String):PFRoom {
			return							_defaultRooms[id];
		}
		public function getRoomByName			(n:String):PFRoom {
			if (_roomsByName[n])				return _roomsByName[n];
			else {
				Debug.error					(_debugPrefix, "Cannot find room in getRoomByName()",n);
				return						null;
			}
		}
		public function getRoomById				(id:*):PFRoom {
			return							_roomsById[uint(id)];
		}
		public function getGameRooms				():Object {
			return							_gameRooms;
		}
		public function getPublicGameRooms			():Object {
			return							_gameRoomsPublic;
		}
		public function getPrivateGameRooms		():Object {
			return							_gameRoomsPrivate;
		}
		public function getRoomByRoom			(room:Room):PFRoom {
			return							getRoomByName(room.getName());
		}
		public function getRoomByNameRoot			(s:String):PFRoom { // Returns a PFRoom using the beginning of name: TUHU, TUHU_2
			for (var i:String in _roomsByName) {
				if (i.indexOf(s) == 0) 			return _roomsByName[i]; // Room with name that srat
			}
			return							null;
		}
		public function getRoomListByNameRoot		(s:String):Array { // Returnsthe complete list of PFRooms using the beginning of name: TUHU, TUHU_2
			var a							:Array = [];
			for (var i:String in _roomsByName) {
				if (i.indexOf(s) == 0) 			a.push(_roomsByName[i]); // Room with name that srat
			}
			return							a;
		}
		public function getConnectedRoom			():PFRoom { // Returns the room I am in at this moment (first room if I am connected in several rooms)
			return							_connectedPFRoom ? _connectedPFRoom : null;
		}
		public function isGameRoom				():Boolean {
			return							_connectedPFRoom && _connectedPFRoom.isGame;
		}
	// LAST CONNECTED LOBBY - THIS SHOULD BE DEPRECATED AND USE THE GOBACK METHOD
		public function hasLastConnectedLobby		():Boolean { // If I was previously in a lobby room. This is NOT the room I am coonected now, but the previous room.
			return							Boolean(_lastConnectedLobby);
		}
		public function joinLastConnectedLobby		():void {
			if (hasLastConnectedLobby()) {
				joinPFRoom					(_lastConnectedLobby);
				_lastConnectedLobby				= null;
			}
			else								Debug.error(_debugPrefix, "I have been asked to join last connected lobby, but there isn't any!");
		}
// JOIN ROOMS ///////////////////////////////////////////////////////////////////////////////////////
		public function joinPFRoom				(r:PFRoom):void {
			_sfMan.sendXtMessage				("RoomMan", "joinLobbyRoom", {n:r.getRoomName()});		}
// UTY /////////////////////////////////////////////////////////////////////////////////////
		public override function broadcastEvent		(evt:String, ...rest):void {
			// I cannot use super.broadcastEvent() here becose of the use of ...rest.
			// I have to rewrite the entire method
			if (BROADCAST_ONLY_AFTER_HANDSHAKE && !_handshakeReceived) return; // Do not broadcast if blocked before receipt of handshake
			for each (_j in _listeners)				UCode.broadcastEvent(_j, evt, rest);
			for each (_j in _eventListeners[evt])	UCode.broadcastEvent(_j, evt, rest);
		}
// UTY for PFRoom  ///////////////////////////////////////////////////////////////////////////////////////
		public function isPokerRoom				(room:Room):Boolean { // Questo per centralizzare, in modo che continui a funzionare anche dove le stanze non hanno nuove variabili
			return							true;
			// E' stato sistemato, adesso funziona anche con le stanze che non sono poker
			var gameType						:String = room.getVariable("k");
			if (!gameType)						gameType = "P"; // Legacy for old servers!
			return							gameType && gameType == "P";
		}
		public function isInRoomName				(n:String, andJoin:Boolean=false):Boolean { // If I am already in a room by name. CasinoLobby, or CSH2_5_300.100
			return							_connectedPFRoom && _connectedPFRoom.getRoomName() == n;
		}
		public function isInMainLobby				(andJoin:Boolean=false):Boolean { // If I am in POKER lobby
			if (_connectedPFRoom && _connectedPFRoom.isMainLobby) return true;
			else if (andJoin) 					_ref._gameControl.joinPokerLobby();
			return							false;
		}
		public var isInPokerLobby					:Function = isInMainLobby;
		public function isInCasinoLobby				(andJoin:Boolean=false):Boolean {
			if (_connectedPFRoom && _connectedPFRoom.isCasinoLobby) return true;
			else if (andJoin) 					_ref._gameControl.joinCasinoLobby();
			return							false;
		}
		public function isInPokerTourLobby			():Boolean {
			return							_connectedPFRoom && _connectedPFRoom.isTournamentLobby();
		}
		public function getRoomNameJoins			(roomName:String):uint { // Quante volte sono entrato in una stanza?
			return							_joinedRooms[roomName] ? _joinedRooms[roomName] : 0;
		}
	// TABLE UNDERSTANDING
		public function isInPokerNormalTable			():Boolean { // It is a poker game table NOT tournament 
			return							_connectedPFRoom && _connectedPFRoom.isTable() && _connectedPFRoom.isPokerGame && !_connectedPFRoom.isTournamentTable();
		}
		public function isInPokerTourTable			():Boolean { // It is a tournament game table
			return							_connectedPFRoom && _connectedPFRoom.isTournamentTable()
		}
		public function isInPokerGame				():Boolean { // If is a POKER game room (both tournament and normal, also lobbies - EVERYTHING related to poker)
			return							_connectedPFRoom && _connectedPFRoom.isPokerGame();
		}
		public function isInOpenTable				():Boolean { // If the table I am sitting on is open and a friend can subscribe.
			return							( _connectedPFRoom && _connectedPFRoom.isTable() && _connectedPFRoom.isOpen()  && !_connectedPFRoom.isTournamentTable());
		}
		public function isInQuittableTable			():Boolean { // If the table I am sitting on can be left without mess. Invitation prompts are displayed ONLY when I am here.
			return							_connectedPFRoom && (_connectedPFRoom.isLobby || _connectedPFRoom.isCash() || _connectedPFRoom.isTournamentLobby());
		}
		public function isInGameRoom				():Boolean { // If is a Game Room and NOT a lobby (roulette, poker, etc...)
			return							_connectedPFRoom && _connectedPFRoom.isGame;
		}
// ROOM PROPERTIES ///////////////////////////////////////////////////////////////////////////////////////
		public function roomHasFooter				():Boolean {
			return							_connectedPFRoom && _connectedPFRoom.hasFooter();
		}
		public function roomHasPowerups			():Boolean {
			return							_connectedPFRoom && _connectedPFRoom.hasPowerups();
		}		public function roomHasPowerupsOpen		():Boolean {
			return							_connectedPFRoom && _connectedPFRoom.hasPowerupsOpen();
		}
		public function roomHasMainBack			():Boolean {
			return							_connectedPFRoom && _connectedPFRoom.hasMainBack();
		}
		public function get roomMainBack			():String {
			return							_connectedPFRoom ? _connectedPFRoom.mainBack : "CasinoLobby";
		}
		public function roomHasMainBackConfirmId	():Boolean {
			return							_connectedPFRoom && _connectedPFRoom.hasMainBackConfirmId();
		}
		public function get roomMainBackConfirmId	():String { 
			return							_connectedPFRoom ? _connectedPFRoom.mainBackConfirmId : null;
		}
		public function get roomHasTentHalfOpen		():Boolean {
			return							_connectedPFRoom && _connectedPFRoom.hasTentHalfOpen();
		}
		public function get roomBgUrl				():String { // If room has a bg, url is returned here, otherwise null
			return							_connectedPFRoom ? _connectedPFRoom.bgUrl : null;
		}
		public function get roomMusicUrl			():String { // If room has a bg, url is returned here, otherwise null
			return							_connectedPFRoom ? _connectedPFRoom.musicUrl : null;
		}
// SMARTFOX LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onSmartFoxRoomListUpdate		(par):void {
// 			if (_handshakeReceived) {
				processRoomsList						(par.roomList);
				_reRender							= true;
// 			}
// 			else {
// 				Debug.debug						(_debugPrefix, "SFS HandShake not yet received. Aborting rooms rendering.");
// 			}
		}
		public function onSmartFoxRoomDeleted			(par:Object):void {
			
			var roomName						:String = par.room.getName();  
			var roomId							:int = par.room.getId();
			Debug.debug						(_debugPrefix, "onSmartFoxRoomDeleted: " + roomName  + " : " + roomId);
			if (!isPokerRoom(par.room)) {
				if (VERBOSE) 			Debug.debug(_debugPrefix, roomName + " is NOT a Poker room. I am not processing it.");
				return;
			}
			removeRoom						(roomName, roomId);
		}
		public function onSmartFoxRoomAdded		(par:Object):void {
			if (VERBOSE)						Debug.debug(_debugPrefix, "onSmartFoxRoomAdded: " + par.room.getName());
			if (!isPokerRoom(par.room)) {
				if (VERBOSE) 			Debug.debug(_debugPrefix, par.room.getName() + " is NOT a Poker room. I am not processing it.");
				return;
			}

			var newRoom						:PFRoom = processRoom(par.room);
			// If room is unknown do not broadcast anything
			if (newRoom.isUnknown()) {
				Debug.error					(_debugPrefix, newRoom.getRoomName(),"is unknown. Broadcast aborted.");
				return;
			}
			// Room is ok, broadcast event
			broadcastEvent						("onRoomAdded", newRoom);
		}
		public function onSmartFoxPFRLU				(par:Object):void {
			for each (var update:Object in par.data) {
				_PFRoom						= getRoomByName(update.id);
				if (_PFRoom) {
					if (_PFRoom.isUnknown()) {
						Debug.error			(_debugPrefix, _PFRoom.getRoomName(),"is unknown. Broadcast aborted.");
						return;
					}
					_PFRoom.updateRoomVars		(update);
					broadcastEvent				("onRoomUpdated", _PFRoom);
				}
				else {
					Debug.error				(_debugPrefix, "Room " + update.id + " not already present. Ignoring update.");
				}
			}
		}
		public function onSmartFoxPFRU				(par:Object):void {
			// This is sent by extension. Sometimes it can arrive before the onRoomAdded, therefore I ignore it until room is added.
			_PFRoom							= getRoomByName(par.data.id);
			if (_PFRoom) {
				if (_PFRoom.isUnknown()) {
					Debug.error				(_debugPrefix, _PFRoom.getRoomName(),"is unknown. Broadcast aborted.");
					return;
				}
				_PFRoom.updateRoomVars			(par.data);
				broadcastEvent					("onRoomUpdated", _PFRoom);
			}
			else {
				Debug.error					(_debugPrefix, "Room " + par.data.id + " not already present. Ignoring update.");
			}
		}
		public function onSmartFoxJoinRoom				(par:Object):void {
			// Process the last connected lobby
			if (_connectedPFRoom) {
				if (_connectedPFRoom.isLobby) {
					_lastConnectedLobby				= _connectedPFRoom;
				}
				else {
					_lastConnectedLobby				= null;
				}
			}
			_connectedRoom						= par.room;
			_connectedPFRoom						= getRoomByRoom(par.room);
			if (!_connectedPFRoom) {
				// Errore critico!!!
				Debug.error						(_debugPrefix, "Joined room but cannot find PFRoom",_connectedRoom, (_connectedRoom ? _connectedRoom.getName() : "Not even SFS room found."));
				onSmartFoxJoinRoomError				();
				return;
			}
			// Setup number of accesses
			var accesses							= _joinedRooms[_connectedRoom.getName()] ? _joinedRooms[_connectedRoom.getName()]+1 : 1;
			_joinedRooms[_connectedRoom.getName()]	= accesses;
			// Broadcast single room join
			Debug.debug							(_debugPrefix, "JOINED ROOM",_connectedPFRoom, "Settings ID:",_connectedPFRoom.settingsId);
			broadcastEvent							(BROADCAST_ON_JOIN_ROOM, _connectedPFRoom);
			// Check for specific broadcasts - BASED ON ROOM NAME
			var eventByRoomName					:String = BROADCAST_JOIN_FIXED_ROOM[_connectedRoom.getName()];
			if (eventByRoomName) {
				// Broadcast access for single room first time join
				if (accesses == 1) {
					broadcastEvent					(eventByRoomName + BROADCAST_POSTFIX_FIRST_TIME_JOIN);
				}
				// Brodacast normal event
				Debug.debug						(_debugPrefix, "Broadcasting join room event",eventByRoomName);
				broadcastEvent						(eventByRoomName);
			}
			// Broadcast special join room events
			broadcastGranularJoinRoomEvent			(_connectedPFRoom);
		}
		public function onSmartFoxJoinRoomError			(par:Object=null):void {
			broadcastEvent							(BROADCAST_ON_JOIN_ROOM_ERROR, _connectedPFRoom);
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