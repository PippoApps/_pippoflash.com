package com.pippoflash.framework.air.bluetooth 
{
	import com.pippoflash.framework._PippoFlashBaseNoDisplay;
	import com.pippoflash.framework.air.ane.distriqt.DistriqtBluetoothLE;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.utils.*;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * Used to communicate or simulate communication with BluetoothLE devices.
	 * @author Pippo Gregoretti
	 */
	public class BluetoothComm extends _PippoFlashBaseNoDisplay 
	{
		public static const EVT_COMMAND_SEND_ERROR:String = "onBluetoothCommandSendError"; // BluetoothMessage
		public static const EVT_COMMAND_SENT:String = "onBluetoothCommandSent"; // BluetoothMessage
		public static const EVT_COMMAND_TIMEOUT:String = "onBluetoothCommandTimeout"; // BluetoothMessage
		public static const EVT_COMMAND_REPLIED:String = "onBluetoothCommandReply"; // BluetoothMessage - On any reply
		//public static const EVT_COMMAND_OK:String = "onBluetoothCommandOk"; // BluetoothMessage - on OK only
		//public static const EVT_COMMAND_ERROR:String = "onBluetoothCommandError"; // BluetoothMessage - on ERROR only
		public static const EVT_COMMAND_SYNTAX_ERROR:String = "onBluetoothCommandSyntaxError"; // Command received  unrecognizable
		
		
		public var CHARACTER_MAIN_DIVIDER:String = "|"; 
		public var ADD_CHARACTER_COUNT:Boolean = true; // Adds a first slot with character count
		public var ADD_COMMAND_ID:Boolean = true; // Adds command ID as a second parameter
		public var MAX_COMMANS_STORED:uint = 100; // Maximum
		public var WAIT_MESSAGE_CONFIRMATION:Boolean = true; // Commander hangs until a reply is received or timeout
		public var WAIT_TIMEOUT:uint = 5000; // Timeout when waiting for command in milliseconds
		public var MAX_MESSAGE_WRITE_LENGTH:uint = 20; // If messages are longer that this, message is splitted in subsequent calls 
		public var LONG_MESSAGE_SPLIT_INTERVAL:Number = 0.2; // Seconds interval used to split message into longer intervals
//		Risposta comando OK
//<31|xy|000|0202112222310|1|data>
//31 : numero totale di caratteri tra < e >
//xy : univoco comando
//000 - stati della device (vedi Formato dei dati, i 3 numeri rappresentato lo stato di base, stato attività e stato riscaldamento)
//02112222310 - Giorno della settimana e data/ora (0-6: dom-lun-mar-mer-gio-ven-sab, e data/ora: yymmhhmm)
//1 : comando OK (0 per errore comando)
//data : (facoltativo) eventuali dati di ritorno necessari al comando
//Risposta Errore
//<26|xy|000|0202112222310|0|0>
//26 : numero totale di caratteri tra < e >
//… (univoco, stato, data/ora)
//0 : esito errato
//0 : tipo di errore (in questo caso: pin errato)

		// Replies simulation
		public var SIMULATE_BLUETOOTH_REPLIES:Boolean = true;
		public var SIMULATED_REPLIES_PREFIX:String = "222|0202112222310|"; // Prefix to all simulated replies
		public var SIMULATED_REPLIES:Object = { // Replies aare simulated here. Command ID is created accordingly.
			// If a reply is an array, a random message will be selected
			g:["1|BLE_Caos|1,255-0.3,16777215-1|13183060-132200120,13123090,130720120-13193045,,,131030200,,","0|0"],
			p:["1"], // Set pin, nothing to return
			"0":["1","0|0","0|1","0|2","0|3"], // Power OFF
			"1":["1"], // Power ON
			"c":["1","0|0"], // Check PIN
			"t":["1"], // Set Date/Time
			empty:null
		}
		// STOPPER DEBUGS
		public var DETECT_MAXIMUM_SEND_LENGTH:Boolean = false; // This makes so that the frist message is overwritten by a 0 to max length string to test the amount of allowed characters
		public var SIMULATE_LONG_MESSAGES:Boolean = false; // This sends ONE single message simulated and splits it into smaller strings
		
		// SYSTEM
		private var _customAdds:Vector.<String> = new Vector.<String>(); // Adds custom content to every call
		private var _commands:Vector.<String> = new Vector.<String>(); // Stores the list of issued coimmands
		private var _commandStatus:uint = 0; // 0 idle, 1 ready, 2 waiting for reply, 3 replied
		private var _commandReplyTimeout:uint = 5000; // Command timeout in milliseconds
		private var _timeoutTimer:Timer; // Creates a dummy timer
		// COMMAND
		private var _activeMessage:BluetoothMessage;
		private var _activeCommand:String; // full command including length and ID
		private var _activeCommandId:String; // ID of active command
		//private var _activeCommandCmd:String; // Command only cmd
		//private var _activeCommandData:String; // Command only data
		//private var _status:uint = 0;;
		
		
		
		
		public function BluetoothComm(id:String) {
			super("BluetoothComm_" + id, BluetoothComm);
			_timeoutTimer = new Timer(WAIT_TIMEOUT, 1);
			_timeoutTimer.addEventListener(TimerEvent.TIMER, onTimeoutTimerElapsed);
			UMem.addManagedClass("BluetoothMessage", BluetoothMessage);
		}
		
		
		// SETUP
		public function setupDistriqtBluetoothLE():void {
			PippoFlashEventsMan.addStaticListener(DistriqtBluetoothLE, this);
			//PippoFlashEventsMan.addStaticListenerTo(DistriqtBluetoothLE, DistriqtBluetoothLE.EVT_COMMAND_RECEIVED, onBluetoothCommandReceived);
			_commandStatus = 1;
		}
		public function setCustomAdd(index:uint, t:String):void { // Adds a custom element
			_customAdds[index] = t;
			Debug.debug(_debugPrefix, "Setting custom adds: " + _customAdds);
		}
		public function getCustomAdd(index:uint):String {
			return _customAdds[index];
		}

		// COMMANDS
		//public function getSettings():Boolean {
			//return sendCommand("g");
		//}
		
		
		// METHODS - SEND COMMANDS
		private var _debugTestLength:String = ""; // Use donly for debugging maximum sendable string
		public function resendLastCommand(force:Boolean=false):Boolean {
			if (!ready && !force) {
				Debug.error(_debugPrefix, "Not ready toresend last command " + _activeCommand);
				return false;
			}
			return sendCommand(_activeMessage.cmd, _activeMessage.data, force);
		}
		public function sendCommand(cmd:String, data:String=null, force:Boolean=false):Boolean {
			if (!ready && !force) {
				Debug.error(_debugPrefix, "Not ready to issue a new command: " + cmd + ". Still waiting for command: " + _activeCommand);
				return false;
			}
			resetTimeout(WAIT_MESSAGE_CONFIRMATION);
			if (WAIT_MESSAGE_CONFIRMATION) _commandStatus = 2;
			_activeCommand = createCommand(cmd, data);
			if (DETECT_MAXIMUM_SEND_LENGTH) { // Breaking debug 1 - just for debugging purposes
				_debugTestLength = UText.getRandomString(_debugTestLength.length + 1);
				Debug.debug(_debugPrefix, "Testing sending a string long: " + _debugTestLength.length);
				UExec.time(0.5, sendCommand, cmd, data, true);
				return DistriqtBluetoothLE.write(_debugTestLength);
			}
			// Proceed with normal sending
			if (_activeCommand.length < MAX_MESSAGE_WRITE_LENGTH) { // Normal sending in one shot
				return doWriteMessage(_activeCommand, true, true);
			} 
			return _sendCommandInChunks(); // Send in chunks
		}
		
		// Split send chunks utilities
		private function _sendCommandInChunks():Boolean {
			_activeCommand = DistriqtBluetoothLE.encloseInCommandBrackets(_activeCommand);
			const chunksNum:uint = Math.ceil(_activeCommand.length/MAX_MESSAGE_WRITE_LENGTH);
			_splitCommandChunks = new Vector.<String>(chunksNum);
			for (var i:int = 0; i < chunksNum; i++) {
				_splitCommandChunks[i] = _activeCommand.substr(i * MAX_MESSAGE_WRITE_LENGTH, MAX_MESSAGE_WRITE_LENGTH);
			}
			Debug.debug(_debugPrefix, "Sending a command longer than maximum lenght, splitted in several chunks: " + chunksNum + "\n" + _splitCommandChunks);
			return _sendNextChunk();
		}
		private function _sendNextChunk():Boolean {
			resetTimeout(WAIT_MESSAGE_CONFIRMATION); // Resets timeout timer for each chunk and eventually starts timer
			const chunk:String = _splitCommandChunks.shift();
			Debug.debug(_debugPrefix, "Sending command chunk: " + chunk + " - remaining: " + _splitCommandChunks.length);
			if (_splitCommandChunks.length == 0) return doWriteMessage(chunk, true, false);  // Last command, sent complete
			// Proceed sending next chunk
			doWriteMessage(chunk, false, false);
			UExec.time(LONG_MESSAGE_SPLIT_INTERVAL, _sendNextChunk);
			return false;
		}
		private var _splitCommandChunks:Vector.<String>;
		
		// Do send command
		private function doWriteMessage(msg:String, broadcastComplete:Boolean=true, encloseInCommandBrackets:Boolean=true):Boolean {
			const sentOk:Boolean = DistriqtBluetoothLE.write(msg, 0, encloseInCommandBrackets);
			if (broadcastComplete) UExec.next(PippoFlashEventsMan.broadcastInstanceEvent, this, sentOk ? EVT_COMMAND_SENT : EVT_COMMAND_SEND_ERROR, _activeMessage);
			return sentOk;
		}
		
		
		
		
		// COMMAND UTY
		private function createCommand(cmd:String, data:String=null):String {
			// Add parameters
			const commandParameters:Vector.<String> = new Vector.<String>();			
			//var commandId:String = UText.getRandomString(2);
			_activeCommandId = UText.getRandomString(2);
			if (ADD_COMMAND_ID) {
				commandParameters.push(_activeCommandId);
			}
			for (var i:int = 0; i < _customAdds.length; i++) {
				commandParameters.push(_customAdds[i]);
			}
			commandParameters.push(cmd);
			if (data) commandParameters.push(data);
			var fullCommand:String = commandParameters.join(CHARACTER_MAIN_DIVIDER);
			if (ADD_CHARACTER_COUNT) fullCommand = addCharacterCount(fullCommand);
			if (_activeMessage) UMem.storeInstance(_activeMessage);
			_activeMessage = UMem.getInstance(BluetoothMessage, _activeCommandId, cmd, data);
			if (SIMULATE_LONG_MESSAGES) { // Breaking debug 2
				const randomStringLength:uint = 1024; // Math.ceil(Math.random() * 200) + MAX_MESSAGE_WRITE_LENGTH;
				Debug.warning(_debugPrefix, "Simulating a longer command to test split string. Length = " + randomStringLength);				
				fullCommand += "Random:" + UText.getRandomString(randomStringLength);
			}
			return fullCommand;
		}
		private function addCharacterCount(t:String, addDivider:Boolean=true):String {
			if (addDivider) t = CHARACTER_MAIN_DIVIDER + t; // Add didiver at the beginning (9)
			var count:uint = t.length; // Add the correct nmber of characters before
			if (count < 10) count += count == 9 ? 2 : 1;
			else if (count < 100) count += count >= 98 ? 3 : 2;
			else if (count < 1000) count += count >= 997 ? 4 : 3;
			else if (count < 10000) count += count >= 9996 ? 5 : 4;
			t = String(count) + t;
			return t;
		}
		private function resetTimeout(andStart:Boolean=false):void {
			_timeoutTimer.reset();
			if (andStart) _timeoutTimer.start();
			else _timeoutTimer.stop();
		}
		private function setTimedout():void {
			_activeMessage.setTimedout();
			resetStatus();
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_COMMAND_TIMEOUT, _activeMessage);
		}
		private function resetStatus():void {
			_commandStatus = 1;
		}
		private function triggerSimulatedReply():Boolean {
			if (!SIMULATED_REPLIES[_activeMessage.cmd]) {
				Debug.debug(_debugPrefix, "Simulated reply for stored command not preset: " + _activeMessage.cmd);
				return false;
			}
			// Create simulated reply
			var reply:String = "";
			if (ADD_COMMAND_ID) reply += _activeCommandId + CHARACTER_MAIN_DIVIDER;
			reply += SIMULATED_REPLIES_PREFIX;
			reply += SIMULATED_REPLIES[_activeMessage.cmd] is String ? SIMULATED_REPLIES[_activeMessage.cmd] : UCode.getArrayRandom(SIMULATED_REPLIES[_activeMessage.cmd]);
			if (ADD_CHARACTER_COUNT) reply = addCharacterCount(reply, true);
			Debug.debug(_debugPrefix, "Triggering simulated reply: " + reply);
			UExec.next(onBluetoothLECommandReceived, reply);
			return true;
		}
		
		// COMMAND PROCESSING ///////////////////////////////////////////////////////////////////////////////////////
		private function processReceivedCommand(cmd:String):Boolean { // 
			// A command is received, I need to do all checks here
			if (!waiting) {
				Debug.error(_debugPrefix, "Command received but I was not waiting, therefore it gets discarded.");
				return false;
			}
			const mainSplit:Array = cmd.split(CHARACTER_MAIN_DIVIDER);
			if (ADD_CHARACTER_COUNT) { // Check characters count
				const charsData:uint = uint(mainSplit.shift());
				const charsNum:uint = cmd.length; // Adding the main divider at the beginning
				Debug.debug(_debugPrefix, "Checking character count, variable says " + charsData + " count is " + charsNum);
				if (charsData != charsNum) return doCommandSyntaxError("Number of characters received not correspondant to string length.");
			}
			if (ADD_COMMAND_ID) { // Check for msg id
				const id:String = mainSplit.shift();
				Debug.debug(_debugPrefix, "Checking message ID, received: " + id + " stored: " + _activeMessage.id);
				if (id != _activeMessage.id) return doCommandSyntaxError("Wrong message ID received.");
			}
			// Chars were right and message id correct, therefore message is replied!
			_activeMessage.setReplied(mainSplit.join(CHARACTER_MAIN_DIVIDER));
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_COMMAND_REPLIED, _activeMessage);
			// Reset status
			resetStatus();
			return true;
		}
		private function doCommandSyntaxError(msg:String):Boolean {
			_activeMessage.setToSyntaxError(msg);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_COMMAND_SYNTAX_ERROR, _activeMessage);
			return false;
		}
		
		
		
		
		
		
		// LISTENERS
		private function onTimeoutTimerElapsed(e:TimerEvent):void {
			if (waiting) {
				Debug.debug(_debugPrefix, "Command timeout elapsed.");
				if (SIMULATE_BLUETOOTH_REPLIES && triggerSimulatedReply()) {}
				else setTimedout();
			} else {
				Debug.error(_debugPrefix, "Command timeout but system not waiting.");
			}
		}
		public function onBluetoothLECommandReceived(cmd:String):void {
			Debug.debug(_debugPrefix, "Received blutooth reply: " + cmd);
			processReceivedCommand(cmd);
		}
		
		
		// getters
		public function get idle():Boolean {
			return _commandStatus == 0;
		}
		public function get ready():Boolean {
			return _commandStatus == 1;
		}
		
		
		public function get waiting():Boolean {
			return _commandStatus == 2;
		}
		public function get activeMessage():BluetoothMessage 
		{
			return _activeMessage;
		}
		
		
	}

}