package com.pippoflash.components {
	
	import											com.pippoflash.utils.*;
	import											com.pippoflash.components.SuperTextField;
	import											com.pippoflash.components.PippoFlashButton;
	
	import											com.pippoflash.net.P2PGroupLocalCommander;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import											flash.net.*;
	import											flash.geom.*;
	
	public dynamic class P2PGroupLocalInterface extends _cBase {
// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
	// P2P PARAMETERS
		[Inspectable 									(name="0.0 - Mode (if mode is locked, this is ignored)", type=String, defaultValue="NEUTRAL", enumeration="NEUTRAL,SLAVE,MASTER")]
		public var _defaultMode							:String = "NEUTRAL"; // Locks mode of device. If locked, this is discarded.
		[Inspectable 									(name="0.1 - Expected APP", type=String, defaultValue="ExpectedAppId")]
		public var _defaultExpectedApp						:String = "ExpectedAppId"; // Expected App ID
		[Inspectable 									(name="0.2 - PIN", type=String, defaultValue="0000")]
		public var _defaultPin								:String = "0000"; // Expected App ID
		[Inspectable 									(name="0.4 - Expected Device ID", type=String, defaultValue="")]
		public var _defaultExpectedUDID						:String = ""; // Expected App ID
		[Inspectable 									(name="0.5 - Screen Name", type=String, defaultValue="User_[RND]")]
		public var _defaultUserName						:String = "User_[RND]"; // Screen name of P2P neighbor
		[Inspectable 									(name="0.6 - Keep connection alive", type=Boolean, defaultValue=true)]
		public var _defaultKeepAlive							:Boolean = true; // Allows to simulate a different device ID
		[Inspectable 									(name="0.7 - IP:PORT", type=String, defaultValue="225.225.0.1:30303")]
		public var _defaultIpPort							:String = "225.225.0.1:30303"; // Screen name of P2P neighbor
		[Inspectable 									(name="0.8 - Group/SubGroup", type=String, defaultValue="myGroup/groupOne")]
		public var _defaultGroup							:String = "myGroup/groupOne"; // Screen name of P2P neighbor
		[Inspectable 									(name="0.9 - Simulated App ID", type=String, defaultValue="")]
		public var _defaultSimulatedAppId						:String = ""; // Screen name of P2P neighbor
	// UTILITIES
		[Inspectable 									(name="1.0 - Lock mode to", type=String, defaultValue="BOTTOM_LEFT", enumeration="NONE,NEUTRAL,SLAVE,MASTER")]
		public var _lockMode								:String = "NONE"; // Locks mode of device
		[Inspectable 									(name="1.1 - Allow simulation of app ID", type=Boolean, defaultValue=false)]
		public var _allowChangeAppId						:Boolean = true; // Allows to simulate a different device ID
		[Inspectable 									(name="1.2 - Allow unique device pairing", type=Boolean, defaultValue=false)]
		public var _allowUniqueDeviceLock					:Boolean = false; // If I allow user to lock pairing to a unique ID instead of an app
		[Inspectable 									(name="1.3 - Verbose", type=Boolean, defaultValue=true)]
		public var _verboseOutput							:Boolean = true; // Allows to simulate a different device ID
		[Inspectable 									(name="1.4 - Key Combination Popup", type=Array, defaultValue="P,2,C")]
		public var _keyCombination							:Array = ["P","2", "C"]; // When pressed, broadcasts "onP2PConsoleNeedsAttention"
		[Inspectable 									(name="1.5 - SO variable name", type=String, defaultValue="PippoFlashP2PLocalGroupSettings")]
		public var _soVarName							:String = "PUPPOLOOOOOOOO"; // Locks mode of device
		[Inspectable 									(name="1.6 - Auto Connect", type=Boolean, defaultValue=false)]
		public var _autoConnect							:Boolean = false; // Connects on startup
		[Inspectable 									(name="1.7 - Auto Activates (careful, shared object may be messed up)", type=Boolean, defaultValue=false)]
		public var _autoActivate							:Boolean = false; // Activates P2P data on startup
		[Inspectable 									(name="1.8 - Process CMD into PippoFlash Framework {target:'MainApp', action:'promptOk', pars:['text','title']}", type=Boolean, defaultValue=false)]
		public var _processPippoFlashCommands				:Boolean = false; // Activates P2P data on startup
// VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		private static const STATUS_TXT						:String = "Total neighbors <font color='#990000'>[TOT]</font><br/>Slaves: <font color='#000099'>[S]</font>, Masters: <font color='#000099'>[M]</font>, Neutrals: <font color='#000099'>[N]</font>.<br/>[MESSAGE]";
		private static const MAX_CONSOLE_LINES				:int = 1000;
		private static const P2P_COMMANDER_ID				:String = "P2PComponentCommander";
		private static const CONSOLE_DIVIDER					:String = " |   ";
		private static const EVT_CHANGE_MODE_LOCKED			:String = "onP2PChangeModeLocked";
		private static const EVT_P2P_NEEDS_ATTENTION			:String = "onP2PNeedsAttention";
		// USER VARIABLES
		// SYSTEM
		private var _consoleLines							:int = 0;
		// REFERENCES - to fool component definition export - BE CAREFUL - these must be REAL classes references or weird errors will trigger
		public var _bg									:Sprite;
		public var _txtName								:SuperTextField;
		public var _txtExpectedApp							:SuperTextField;
		public var _txtPin								:SuperTextField;
		public var _txtExpectedUDID						:SuperTextField;
		public var _txtGroupName							:SuperTextField;
		public var _txtGroupIpPort							:SuperTextField;
		public var _txtApp								:SuperTextField;
		public var _txtMsg								:SuperTextField;
		public var _txtStatus								:TextField;
		public var _txtConsole								:TextField;
		public var _buttNeutral							:PippoFlashButton;
		public var _buttMaster								:PippoFlashButton;
		public var _buttSlave								:PippoFlashButton;
		public var _buttConnect							:PippoFlashButton;
		// REFERENCES
		private var _p2pComm							:P2PGroupLocalCommander;
		// MARKERS
		private var _isDataTakenFromSO						:Boolean; // Marks if some data has been retrieved from shared object
		private var _activated								:Boolean; // This is to prevent double activation
		private var _p2pInitialized							:Boolean; // This is to prevent double initialization of p2p
		// DATA HOLDERS
		private var _mode								:String; // M, N or S
		private var _message								:String = "";
		private var _soData								:Object = {name:"", pin:"", mode:"", targetUDID:"", app:"", targetApp:"", group:"", ipPort:""}; // This contains ALL data
		private var _settings								:XML; // XML standard activation settings
// INIT /////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function P2PGroupLocalInterface					(par:Object=null) {
			// Init super
			super									("P2PGroupLocalInterface", par);
		}
		protected override function initAfterVariables				():void {
			super.initAfterVariables						();
			UKey.addSequenceListener						(this, _keyCombination, "P2C");
			Debug.setListenerFor							(_debugPrefix, onDebugConsole);
			Debug.setListenerFor							(P2P_COMMANDER_ID, onDebugConsole);
			// Setup bitmap caching of text fields
			for (var i:uint=0; i<10; i++)					UDisplay.cacheAsBitmapMatrix(this["_txtCache"+i]);
			// Start initializing data
			initializeP2P								();
			if (_autoActivate)							initializeData();
			if (_autoActivate && _autoConnect)				connect();
		}
			protected override function initDimensions			():void {
				var sx								:Number = scaleX;
				var sy								:Number = scaleY;
				super.initDimensions						();
				_w									= _bg.width;
				_h									= _bg.height;
				scaleX								= sx;
				scaleY								= sy;
			}
		private function initializeP2P				():void {
			if (_p2pInitialized) {
				Debug.error				(_debugPrefix, "Careful. initializeP2P() has been called twice, and it shouldn't");
				return;
			}
			Debug.debug					(_debugPrefix, "Initializing P2P...");
			// I only instantiate P2P here, with dummy data, but it doesn't connect. No it doesn't. I will set real data later and connect it.
			_p2pComm						= new P2PGroupLocalCommander(P2P_COMMANDER_ID, _mainApp ? _mainApp.getAppId() : "temporaryAppId", USystem.getUDID());
			// Pairing data must be inserted with this method
			_p2pComm.updatePairing			(_txtExpectedApp.text, _txtPin.text, _txtExpectedUDID.text, _txtExpectedUDID.text);
			// Listening to P2P events
			_p2pComm.addListener			(this);
			// Add P2P initializer
			_p2pInitialized					= true;
			// Setup mirroring methods
			isConnected					= _p2pComm.isConnected;
			disconnect						= _p2pComm.disconnect;
		}
	// Data initialization
		private function initializeData						():void {
			// Error check
			if (_activated) {
				Debug.error						(_debugPrefix, "Careful. initializeData() has been called twice, and it shouldn't");
				return;
			}
			// Find stored data
			_soData									= _mainApp.getSharedObject(_soVarName);
			if (!_soData) { // Data was not previously stored on server, I initialize data now
				_soData = {
					name								:UText.insertParams(_defaultUserName, {RND:UText.getRandomString(4)}), // Screen name of user (if default has random id inside)
					mode								:isModeLocked() ? _lockMode.charAt(0) : _defaultMode.charAt(0), // N, M, or S
					targetUDID							:_defaultExpectedUDID, // Expected master
					pin								:_defaultPin, // Pin generated or inserted
					app								:_allowChangeAppId && _defaultSimulatedAppId.length ? _defaultSimulatedAppId : _mainApp.getAppId(), // My own simulated app
					targetApp							:_defaultExpectedApp, 
					group							:_defaultGroup, 
					ipPort							:_defaultIpPort
				}
			}
			else {
				_isDataTakenFromSO						= true;
				Debug.debug							(_debugPrefix, "Found stored settings: " + Debug.object(_soData));
			}
			// Populate local variables with default data or with data retrieved from SO
			confirmAndApplyLoadedData			();
			// Setup texfields interaction according to options
			_txtExpectedUDID.setActive			(_allowUniqueDeviceLock);
			_txtApp.setActive				(_allowChangeAppId);
			// Save data in SharedObject
			if (!_isDataTakenFromSO)			updateData();
			// Set to activated
			_activated						= true;
		}
		private function confirmAndApplyLoadedData	():void {
			if (!_allowChangeAppId)			_soData.app = _mainApp.getAppId();
			_txtName.text					= _soData.name;
			_txtExpectedApp.text				= _soData.targetApp;
			_txtPin.text					= _soData.pin;
			_txtExpectedUDID.text				= _soData.targetUDID;
			_txtGroupName.text				= _soData.group;
			_txtGroupIpPort.text				= _soData.ipPort;
			_txtApp.text					= _soData.app; // Application can be SIMULATED here ONLY if simulation is allowed
			_mode						= _soData.mode;
			if (_mode == "N")				_buttNeutral.setSelected(true);
			else if (_mode == "M")			_buttMaster.setSelected(true);
			else if (_mode == "S")			_buttSlave.setSelected(true);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function activate				():void {
			Debug.debug					(_debugPrefix, "ACTIVATE");
			initializeData					();
			connect						();
		}
		public function connect				():void {
			onP2PNeigborsUpdate				();
			_p2pComm.connect				();
		}
		public function setup					(settings:XML, overwriteStored:Boolean=false):void {
			_settings						= settings;
			Debug.debug						(_debugPrefix, "SETUP");
			if (!_activated)					initializeData();
			if (_isDataTakenFromSO && !overwriteStored) { // Data has already been taken from SO, but I haven't said that I should overwrite them. So I trigger an error.
				Debug.error				(_debugPrefix, "Data has already been retrieved from SharedObject, settings xml is not used as real data: " + _settings.toXMLString());
				return;
			}
			// Setup data from XML node
			// <SETTINGS ipPort="" group="" name="" targetUDID="" pin="" app="" targetApp="" mode="" />
			for (var s:String in _soData) {
				if (UXml.hasFullAttribute(_settings, s)) _soData[s] = String(_settings.@[s]);
			}
			Debug.debug					(_debugPrefix, "Applied settings from: " + _settings.toXMLString());
			Debug.debug					(_debugPrefix, "Result data object: " + Debug.object(_soData));
			confirmAndApplyLoadedData			(); // Change variables and interface according to loaded data (and checks conformity)
			applyChanges					();
		}
		public function isModeLocked			():Boolean {
			return						_lockMode != "NONE";
		}
		public override function addListener		(listener:Object) {
			super.addListener				(listener);
			_p2pComm.addListener			(listener);
		}
		public override function removeListener		(listener:Object) {
			super.removeListener				(listener);
			_p2pComm.removeListener			(listener);
		}
		public var isConnected					:Function;
		public var disconnect					:Function;
	// SLAVE CONTROL
		public function sendCommand			(command:*, askReceipt:Boolean=false):void { // Sends command to paired slave
			_p2pComm.sendCmdToSlave			(command, askReceipt);
		}
		public function sendFeedback			(command:*):void { // Sends feedback to paired master
			_p2pComm.sendFeedback			(command);
		}
// RESIZER ////////////////////////////////////////////////////////////////////////////////////////////////////////
// P2P Listeners ///////////////////////////////////////////////////////////////////////////////////////
		public function onP2PStatus				():void {
			updateStatus					();
		}
		public function onP2PMsgReceived		(from:String, msg:String):void {
			Debug.debug					(_debugPrefix, "["+from+"]   " + msg);
		}
		public function onP2PNeighborUpdate		(o:Object):void {
			Debug.debug					(_debugPrefix, "User discovered: "+o.name);
		}
		public function onP2PNeigborsUpdate		():void { // Neighbors data has been updated
			updateStatus					();
		}
		public function onP2PPairingSuccess():void {
			broadcastEvent("onP2PPairingSuccess");
		}
		public function onP2PConnected			():void {
			_buttConnect.setSelected			(true);
			_buttConnect.setText				("DISCONNECT");
			broadcastEvent("onP2PConnected");
			updateStatus					();
		}
		public function onP2PDisconnected		():void {
			_buttConnect.setSelected			(false);
			_buttConnect.setText				("CONNECT");
			updateStatus					();
		}
		public function onP2PCommand			(cmd:Object):void {
			// Received a command. It gets broadcasted anyway, if local execution is active I also call PippoFlash object method.
			Debug.debug					(_debugPrefix, "Received command: " + Debug.object(cmd));
			if (_processPippoFlashCommands)	{
				Debug.debug				(_debugPrefix, "Executing on PippoFlash stack.");
				if (cmd.hasOwnProperty("target") && cmd.hasOwnProperty("action")) _mainApp.callObjectMethod(cmd);
				else 						Debug.error(_debugPrefix, "Cannot execute PippoFlash Object method. Objet is not well formed.");
			} else broadcastEvent("onP2PCommand", cmd);
		}
// GUI UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function updateStatus			():void {
			var o							:Object = _p2pComm.getCounters();
			o.MESSAGE					= _p2pComm.getMessage();
			_txtStatus.htmlText				= UText.insertParams(STATUS_TXT, o);
		}
// GRAPH UTY //////////////////////////////////////////////////////////////////////////////////////
// MODE SETUP ///////////////////////////////////////////////////////////////////////////////////////
		private function setToMaster			():void {
			if (modeSelectionBlocked()) 		return;
			_mode						= "M";
			_buttMaster.setSelected			(true);
			applyChanges					();
		}
		private function setToSlave				():void {
			if (modeSelectionBlocked()) 		return;
			_mode						= "S";
			_buttSlave.setSelected				(true);
			applyChanges					();
		}
		private function setToNeutral			():void {
			if (modeSelectionBlocked()) 		return;
			_mode						= "N";
			_buttNeutral.setSelected			(true);
			applyChanges					();
		}
		// Returns true if selection of mode is blocked, and reselectes correct mode button
		private function modeSelectionBlocked		():Boolean {
			if (_lockMode) {
				if (_p2pComm.isNeutral())		_buttNeutral.setSelected(true);
				else if (_p2pComm.isSlave())	_buttSlave.setSelected(true);
				else if (_p2pComm.isMaster())	_buttMaster.setSelected(true);
				broadcastEvent				(EVT_CHANGE_MODE_LOCKED);
				return					true;
			}
			return						false;
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onPressConnect			(c:*=null):void {
			if (c.isSelected()) { // I am connecting
				_p2pComm.connect			();
			}
			else { // I am disconnecting
				_p2pComm.disconnect			();
			}
		}
		public function onPressMaster			(c:DisplayObject=null):void {
			setToMaster					();
		}
		public function onPressSlave			(c:DisplayObject=null):void {
			setToSlave						();
		}
		public function onPressNeutral			(c:DisplayObject=null):void {
			setToNeutral					();
		}
		public function onPressApplyChanges		(c:DisplayObject):void {
			applyChanges					();
		}
		public function onPressChatAll			(c:DisplayObject=null):void {
			_p2pComm.sendChatToAll			(_txtMsg.text);
		}
		public function onPressChatSlave			(c:DisplayObject=null):void {
			_p2pComm.sendChatToSlave		(_txtMsg.text);
		}
		public function onPressAlertSlave			(c:DisplayObject=null):void {
			_p2pComm.sendCmdToSlave			({action:"promptOk", target:"MainApp", pars:[_txtMsg.text, "ALERT FROM MASTER"]}, true);
		}
		public function onPressKeepAlive			(c:*=null):void {
			_p2pComm.keepAlive 				(c.isSelected());
		}
		private function onDebugConsole			(s:String):void {
			_consoleLines					++;
			if (_consoleLines > MAX_CONSOLE_LINES) {
				_txtConsole.text				= "";
				_consoleLines				= 1;
			}
			_txtConsole.appendText			(_consoleLines + CONSOLE_DIVIDER + s + "\n");
			UText.scrollToBottom				(_txtConsole);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function applyChanges			():void { // Applies all changes from textfields to network
			// Data object is created by textfields, then stored in SO, then applied to P2P
			updateData					();
			_p2pComm.updateSystem			(_soData.ipPort, _soData.group, false);
			_p2pComm.updateUser			(_soData.mode, _soData.name, _soData.app, USystem.getUDID(), false); // first call doesn't notify
			_p2pComm.updatePairing			(_soData.targetApp, _soData.pin, _soData.slave, _soData.master, false); // Second call notifies neighbors
		}
		private function updateData				():void {
			// Grabs data from textfields and saves SharedObject
			_soData = {
				name						:_txtName.text,
				mode						:_mode,
				targetUDID					:_txtExpectedUDID.text,
				pin						:_txtPin.text,
				app						:_txtApp.text,
				targetApp					:_txtExpectedApp.text,
				group					:_txtGroupName.text,
				ipPort					:_txtGroupIpPort.text
			}
			_mainApp.setSharedObject			(_soVarName, UCode.duplicateObject(_soData));
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onKeyPressP2C				() {
			Debug.debug								(_debugPrefix, "P2P console needs attention. Triggering event: " + EVT_P2P_NEEDS_ATTENTION);
			broadcastEvent								(EVT_P2P_NEEDS_ATTENTION);
			trace("CAZZOFREGNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
		}
	}
}