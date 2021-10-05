package com.pippoflash.smartfox {
// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem; import com.pippoflash.utils.*; import com.pippoflash.smartfox.*; import it.gotoandplay.smartfoxserver.*; import it.gotoandplay.smartfoxserver.data.*; import com.pippoflash.string.DateManager;
import flash.display.*; import flash.events.*; import flash.geom.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*;
import system.RoomData; import system.RoomFineData;
// DECLARATION //////////////////////////////////////////////////////////////////////////
	public dynamic class PFRoom extends com.pippoflash.framework._PippoFlashBaseNoDisplayUMem {
		// CONSTANTS
		private static const ROOM_NUMBER_SEPARATOR:String = "."; // Separates room name divided by "_" from room number
// 		private static const BUY_IN_RAKE_FRACTION	:Number = 0.2; // Money to be removed form buyIn to calculate pot
		private static const INFO_OBJECT_BLUEPRINT	:Object = {CREATOR:"", STARTDATE:"", STATUS:"", SUBSCRIBED:""};
		// STATIC
		public static var _rooms					:PFRooms; // Will be initialized by PFRooms
		public static var _statusEmpty				:String;		public static var _statusFull				:String;
		public static var _statusComplete			:String;
		public static var _descriptionInfoObject		:Object; // Stores the info object to customize toolTip and description
		// SYSTEM
		// REFERENCES
		// MARKERS
		private var _rendered					:Boolean;
		// DIRECT DATA HOLDERS AUTOMATIC - SET BEFORE HANDSHAKE
		private var _room						:Room; // Direct reference to smartfox room
		private var _roomId						:uint; // room.getId()
		private var _roomName					:String; // room.getName(); - the real name of room
		private var _gameId						:String; // Full name without room # (TUHU_2_5)
		// DATA HOLDERS - RETRIEVED AFTER HANDSHAKE - COMPUTED ONCE, OR ON CHANGE
		private var _roomData					:RoomData;
		private var _roomFineData					:RoomFineData;
		private var _name						:String; // Display name of room. Is setup once here because CLUBS may differ so we do not need to require calculations all the time. THIS IS NOT THE REAL NAME, but display name.
		private var _status						:String; // W for waiting. P for playing. C for closing.
		private var _statusText					:String; // Stores the status text for the room
		private var _subscribed					:int;
		private var _subscribedText				:String;
		private var _access						:String; // P for public. F for friends.
		private var _roomType					:String; // Type of room if SPECIAL. Taken from room variable "t". (can be tournament it belongs to, or else)
// 		private var _settingsId					:String; // The tyoe of settings taken from ROOMSETTINGS in config.xml. If the room is a defaultroom, room name is used, otherwose this id.
		private var _settings						:XML; // The xml SETTINGS node taken from config
		// BLINDS
		private var _blindsText					:String;
		// CLUB
		private var _creator						:String; // Creator of CLUB room
		private var _creatorName					:String; // Name of Creator of CLUB room
		private var _bgId						:uint = 0; // Stores the BG id for table
		private var _clubAccess					:String;
		// STATIC
		private var _startDate					:Date = new Date(); // Start date
		private var _startDateText					:String; // Start date display name
		// Visualization Mode
		private var _group						:uint;
// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		static public function onConfigStatic			():void {
			// Called once config has been loaded, bu PFRooms
			_statusFull						= _config._words.listStatusClosed.toString();
			_statusEmpty						= _config._words.listStatusOpen.toString();
			_statusComplete					= _config._words.listStatusComplete.toString();
		}
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function PFRoom					(room:Room):void {
			super							("PFRoom");
			recycle							(room);
		}
		public function recycle					(room:Room):void {
			_room							= room;
			_roomId							= room.getId();
			_roomName						= room.getName();
			_gameId							= _roomName.split(".")[0];
			// Proceed with data rendering only after config has received pertinent data
// 			if (USE_OLD_ROOM_RENDERING)			renderFineDataOldStyle();
			if (RoomData.isInitialized())				renderFineData();
		}
		private function renderFineData			():void {
			// this is rendered only AFTER sfs handshake is received
			_roomData						= RoomData.getRoomData(_gameId);
			_roomFineData						= RoomData.getRoomFineData(_gameId);
			_name							= _roomFineData.name; // Get default name (in case of CLUB will be substituted)
			// Grab data from initial room variables
			_status							= _room.getVariable("s");
			_subscribed						= _room.getVariable("p");
			_access							= _room.getVariable("a");
			// Grab data ONLY for club rooms
			if (_roomData.isClub) {
				_creator						= room.getVariable("c");
				_creatorName					= room.getVariable("cn");
				_clubAccess					= room.getVariable("ca");
				_name						= _creatorName;
			}
			else {
				_creatorName					= "";
			}
			// Setup background, if not present, default background
			var bgId							:* = _room.getVariable("f");
			_bgId							= bgId ? uint(bgId) : 0;
			// Setup STATIC rooms values
			if (_roomData.isStatic) {
				var d						:String = _room.getVariable("d");
				_startDate						= new Date(Number(d));
				_startDateText					= DateManager.convertDateToString(_startDate, "R") + _config._words.dayAndTimeJoiner + DateManager.convertDateToString(_startDate, "H:m");
			}
			// Settings id
// 			_settingsId						= _roomData.isLobby ? _roomName : _roomData.propsId;
			_settings							= _config.getRoomSettings(_roomName);
			if (!_settings) {
				_settings 						= _config.getRoomSettings(String(_roomData.propsId));
			}
			if (!_settings)						_settings = _config.getRoomSettings("DEFAULT");
			// Update textual data according to rom vairables
			updateDataAccordingToRoomVariables	();  
			// Set to rendered
			_rendered							= true;
		}
		private function updateDataAccordingToRoomVariables():void {
			_statusText						= isTournamentLobby() ? (isComplete() || isPlaying() ? _statusComplete : _statusEmpty) : isFull() ? _statusFull : _statusEmpty;
			_subscribedText						= _subscribed + "/" + _roomFineData.seats;
		}
		public override function cleanup				():void {
			// RoomData and FineRoomData have to remain since they are used and shared amongst rooms
			// UMem.storeInstance					(_roomData);
			// UMem.storeInstance					(_roomFineData);
			_room = null;
			_roomData = null;
			_roomFineData = null;
			_startDate = null;
// 			_settingsId = null;
			_rendered = false;
			_roomId = _group = _subscribed = _bgId = 0; // Number
			_roomName = _gameId = _name = _status = _statusText = _subscribedText = _access = _roomType = _blindsText = _creator = _creatorName = _clubAccess = _startDateText = null; // String	
			
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function refreshRoomVars			():void {
			updateRoomVars					(_ref._sfMan.updateRoomVariables());
		}
		public function updateRoomVars			(par:Object):void { // Whenever a room update is received from server, room crunches it with this
			if (UCode.exists(par.p))				_subscribed = par.p;
			if (UCode.exists(par.s))				_status = par.s;
			if (UCode.exists(par.t))				_roomType = par.t;
			updateDataAccordingToRoomVariables	();
		}
		public function updateRoomData			():void { // Called by RoomData once data is received and PFRooms have to update associated data.
			// This is called only when data is received after first rendering of rooms
			renderFineData						();
		}
// COMPLEX DATA METHODS ///////////////////////////////////////////////////////////////////f////////////////////
		public function getInfoText				():String {
			return							fineDescription;
		}
		public function toString					():String {
			return							"["+(_roomName ? _roomName   : "PFRoom Empty")+"]"; 
		}
// INTERNAL UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function updateRoomType			():void {
			_roomType  						= _room.getVariable("t");
		}
		private function getUpdatedInfoObject		():Object {
			_descriptionInfoObject 				= UCode.duplicateObject(INFO_OBJECT_BLUEPRINT);
			_descriptionInfoObject.CREATOR		= _creatorName;
			_descriptionInfoObject.STARTDATE		= _startDateText;
			_descriptionInfoObject.SUBSCRIBED		= _subscribed;
			// Setup status
			var pre							:String = _roomData.isTournamentLobby ? "tournament" : "table";
			var post							:String = isOpen() ? "Open" : (isPlaying() ? "Running" : "Complete");
			_descriptionInfoObject.STATUS			= _config._words.roomFineDescriptionsInfoText.STATUS[pre+post].toString();
			return							_descriptionInfoObject;
		}
// DATA METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function isUnknown					():Boolean {
			return							_roomData && _roomData.isUnknown;
		}
		public function getTournamentName			():String { // Complete rom name of tournament to which this table is connected
			return							_roomType;
		}
		public function getName					():String { 
			return							_name;
		}
		public function getRoomName				():String { // Complete name of the room
			return							_roomName;
		}
		public function getRoomId					():uint {
			return							_roomId;
		}
		public function get maxBuyInMult			():uint { // Maximum multiplier for buyin when accessing a cash table
			return							_roomData.maxBuyInMult;
		}
	// GETTERS ////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function get name					():String {
			return							_name;
		}
		public function get blinds					():String { // Returns the TEXT of blinds. No sequence.
			return							_blindsText;
		}
		public function get smallBlinds				():Array { // List of blinds
			return							_roomFineData.smallBlinds;
		}
		public function get bigBlinds				():Array { // List of blinds
			return							_roomFineData.bigBlinds;
		}
		public function get bgId					():uint {
			return							_bgId;
		}
		public function get status					():String { // Status of the room (W, P)
			return							_status;
		}
		public function get subscribed				():uint { // Amount of subscribed users
			return							_subscribed;
		}
		public function get access					():String { // Status of the room (W, P)
			return							_status;
		}
		public function get group					():uint {
			return							_roomData.group;
		}
		public function get statusText				():String {
			return							_statusText;
		}
		public function get subscribedText			():String {
			return							_subscribedText;
		}
		public function get room					():Room {
			return							_room;
		}
		public function get id					():String { // Real complete name of room
			return							_room.getName();
		}
		public function get roomId				():uint { // The ID of SFS Room
			return							_room.getId();
		}
		public function get seats					():uint {
			return							_roomFineData.seats;
		}
		public function get game					():String { // TUHU_10_20_P - without .n
			return							_gameId;
		}
		public function get currency				():String {
			return							_roomFineData.currency;
		}
		public function get buyIn					():Number {
			return							_roomFineData.buyIn;
		}
		public function get buyInText				():String {
			return							_roomFineData.buyInText;
		}
		public function get gameId				():String { // The full ID of game, i.e. TUHU_2_100
			return							_roomFineData.gameId;
		}
		public function get prizeCurrency			():String { // Currency of prizes. If present. If null, prizes have same currency as buyin.
			return							_roomFineData.prizeCurrency; // If no currency, null is returned;
		}
	// DATE
		public function get startDateText			():String {
			return							_startDateText;
		}
		public function getDate					():Date {
			return							_startDate;
		}
		public function get startDate				():Date {
			return							_startDate;
		}
	// CLUB TO BE DEBUGGED
	// CLUB
		public function getCreator					():String {
			return							_creator;
		}
		public function getCreatorName				():String {
			return							_creatorName;
		}
		public function getClubAccess				():String {
			return							_clubAccess;
		}
		public function canSeeClub				():Boolean { // If the user can SEE IN THE LIST the club room (if is open or by invitation, or if the user is a friend). If the room should be shown in the list.
			return							_clubAccess == "A" || _clubAccess == "M" || _clubAccess == "F" && _ref._sfMan.isBuddyName(_creatorName);
		}
		public function canJoinClub				():Boolean { // If club can be joined without requesting access (table is open, or is mixed/friends and made by my friend).
			return							_clubAccess == "A" || ((_clubAccess == "M" || _clubAccess == "F") && _ref._sfMan.isBuddyName(_creatorName));
		}
	// TOOLTIP
		public function get hasToolTip				():Boolean {
			return							_roomFineData.hasToolTip;
		}
		public function get toolTip					():String {
			var tt							:String = _roomFineData.getToolTip(_subscribed);
			return							UText.insertParams(tt, getUpdatedInfoObject());
		}
		public function get fineDescription			():String {
			var fineDescription					:String = _roomFineData.getFineDescription(_subscribed);
			return							UText.insertParams(fineDescription, getUpdatedInfoObject());
		}
// ROOM TYPE CHECKS ///////////////////////////////////////////////////////////////////////////////////////
		public function isFixedPrizes				():Boolean {
			return							_roomData.prizesType == "LIST";
		}
		public function get isStatic				():Boolean {
			return							_roomData.isStatic;
		}
		public function isPublic					():Boolean { /* TO BE DEBUGGED */
			return true;
			return							_access == "P"; // Looks for the "accessible" property
		}
		public function isPrivate					():Boolean {
			return							_access == "F"; // Looks for the "accessible" property
		}
		// isOpen() is used by lists to show if rooms are still open
		public function isOpen					():Boolean {
			if (isCash())						return !isFull(); // Cash games are open always until full
			else { // For all Sit&Go tables and tournaments, status must be Wait and table must not be full
				return 						isWaiting() && !isFull(); // Normal games are open only when status is set to Waiting
			}
		}
		public function isSubscribable				():Boolean { // Room can be subscribed as game
			return							isGameRoom();
		}
		public function hasUser					(nickOrId:*):Boolean { // If it contains a user, nick or id is ok
			return							Boolean(_room.getUser(nickOrId));
		}
		public function isFull						():Boolean {
			return							_roomData.isStatic ? _subscribed >= _roomData.maxPlayers : _subscribed == _roomFineData.seats;
		}
		public function isEmpty					():Boolean {
			return							_subscribed == 0;
		}
// 		public function get isSatelliteStep			():Boolean {
// 			return							_roomData.isSatelliteStep;
// 		}
// 		public function get satelliteStep				():* { // 0, 1, 2 or null if it is not a step
// 			return							_roomData.satelliteStep;
// 		}
		public function get isSatelliteStep			():Boolean { // Only if is step 0, step 1, or staellite tournament. If it is a satellite tournament table returns false.
			if (_roomData.isSatellite) {
				var sat						:Object = RoomData.getSatellite(_roomData.satelliteId);
				if (sat.steps && sat.steps.indexOf(game) != -1) return true; // I am a step of satellite
			}
			return							false;
		}
		public function get satelliteStep				():* { // returns the uint of satellite step, or null if it is not a satellite step
			if (isSatelliteStep)					return RoomData.getSatellite(_roomData.satelliteId).steps.indexOf(game);
			return							null;
		}
// 		public function getDebugSatelliteString		():String {
// 			var s								:String = "Debugging satellite " + getRoomName();
// 			s								+= "\n\r vediamo un pò di dati: " + isSatelliteStep  + " : " + satelliteStep;
// 			return							s;
// 		}
	// STATUS
		public function isPlaying					():Boolean {
			return							_status == "P";
		}
		public function isWaiting					():Boolean {
			return							_status == "W";
		}
		public function isComplete					():Boolean {
			return							_status == "E";
		}
	// CURRENCY
		public function isGold					():Boolean {
			return							_roomFineData.currency == "G";
		}
		public function isEuro					():Boolean {
			return							_roomFineData.currency  == "P";
		}
		public function isMixedCurrency				():Boolean { // If table is accessed paying cash opnly, and prize is always gold
			return							_roomFineData.currency  == "M";
		}
		public function isMixedAccess				():Boolean { // If table can be accessed in both cash and gold, and prize is always in gold
			return							false;
		}
	// TYPES OF ROOM CHECK
		public function get isSitGo					():Boolean {
			return							_roomData.isSitGo;
		}
		public function get isSatellite				():Boolean {
			return							_roomData.isSatellite || _roomData.isSatTourTable;
		}
		public function isTournamentLobby			():Boolean {
			return							_roomData && _roomData.isTournamentLobby;
		}
		public function isTournamentTable			():Boolean { // This should tell me if it's a tournament table, and where should I go. Tournament tables ONLY have a variable called "t" which is the ID of tournament
			updateRoomType					();
			return							_roomType ? _roomType.indexOf("TR") == 0 || _roomType.indexOf("TP") == 0 || _roomType.indexOf("TG") == 0 : false;
		}
		public function isGameRoom				():Boolean { // PippoFlash game room. Is subscribable, etc.
			return							isGame; //_rooms.isGameRoom(_room);
		}
		public function isTable					():Boolean { // Dice se è un tavolo da gioco. Prima dell'arrivo di handshake dice sempre no.
			return							_roomData ? _roomData.isTable : false;
		}
		public function isClub					():Boolean {
			return							_roomData.isClub;
		}
		public function isCash					():Boolean {
			return							_roomData.isCash;
		}
		public function get isCasinoLobby			():Boolean {
			return							_roomData.isCasinoLobby;
		}
		public function get isRouletteLobby			():Boolean {
			return							_roomData.isRouletteLobby;
		}
		public function get isRouletteGame			():Boolean {
			return							_roomData.isRouletteGame;
		}
		public function get isMainLobby				():Boolean {
			return							_roomData.isMainLobby;
		}
		public function get isLoginArea				():Boolean {
			return							_roomData.isLoginArea;
		}
		public function get isGame				():Boolean {
			return							_roomData.isGame;
		}
		public function get isPokerGame			():Boolean {
			return							_roomData && _roomData.isGame && _roomData.gameId == "P";
		}
		public function get isLobby				():Boolean {
			return							_roomData && _roomData.isLobby;
		}
// 		public function isFixedPrizes				():Boolean {
// 			return							_roomData.prizesType == "LIST";
// 		}
// 		public function get isStatic				():Boolean {
// 			return							_roomData.isStatic;
// 		}
	// ROOM SETTINGS
		public function get settingsId				():String {
			return							_settings ? _settings.name() : "SETTINGS NOT YET RECEIVED";
		}
		public function hasFooter					():Boolean {
			return							UCode.isTrue(_settings.@footer);
		}
		public function hasPowerups				():Boolean {
			return							UCode.isTrue(_settings.@showPowerUps);
		}		public function hasPowerupsOpen			():Boolean {
			return							UCode.isTrue(_settings.@openPowerUps);
		}
		public function hasTentHalfOpen			():Boolean {
			return							UCode.isTrue(_settings.@tentHalfOpen);
		}
		public function get bgUrl					():String {
			// If the nodename is standard, .jpg will be added. Otherwise I MUST also put file extension (some bgs ar ein png due to transparency needed for 3d on stage)
			if (UCode.isTrue(_settings.@hasBg))	return _config.getStandardRoomBgUrl(_settings.name().localName) + ".jpg";
			else if (UXml.hasFullAttribute(_settings, "customBgName")) return _config.getStandardRoomBgUrl(_settings.@customBgName);
			return							null;
		}
		public function get musicUrl				():String {
			if (UCode.isTrue(_settings.@hasMusic))	return _config.getStandardRoomMusicUrl(_settings.name().localName);
			else if (UXml.hasFullAttribute(_settings, "customMusicName")) return _config.getStandardRoomMusicUrl(_settings.@customMusicName);
			return							null;
		}
	// MAIN BACK
		public function hasMainBack				():Boolean {
			return							UXml.hasFullAttribute(_settings, "mainBackMethod");
		}
		public function get mainBack				():String {
			return							_settings.@mainBackMethod;
		}
		public function hasMainBackConfirmId		():Boolean {
			return							UXml.hasFullAttribute(_settings, "mainBackConfirmId");
		}
		public function get mainBackConfirmId		():String {
			return							_settings.@mainBackConfirmId;
		}
// 		public function hasBg					():Boolean {
// 			return							UCode.isTrue(_settings.@bg);
// 		}
// 		public function bgUrl						():String {
// 			return							_settings.@bg;
// 		}
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