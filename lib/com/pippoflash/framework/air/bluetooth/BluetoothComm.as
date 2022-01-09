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
		public static const EVT_COMMAND_OK:String = "onBluetoothCommandOk"; // BluetoothMessage - on OK only
		public static const EVT_COMMAND_ERROR:String = "onBluetoothCommandError"; // BluetoothMessage - on ERROR only
		
		
		
		public var CHARACTER_MAIN_DIVIDER:String = "|"; 
		public var ADD_CHARACTER_COUNT:Boolean = true; // Adds a first slot with character count
		public var ADD_COMMAND_ID:Boolean = true; // Adds command ID as a second parameter
		public var MAX_COMMANS_STORED:uint = 100; // Maximum
		public var WAIT_MESSAGE_CONFIRMATION:Boolean = true; // Commander hangs until a reply is received or timeout
		public var WAIT_TIMEOUT:uint = 5000; // Timeout when waiting for command in milliseconds
		// SYSTEM
		private var _customAdds:Vector.<String> = new Vector.<String>(); // Adds custom content to every call
		private var _commands:Vector.<String> = new Vector.<String>(); // Stores the list of issued coimmands
		private var _commandStatus:uint = 0; // 0 idle, 1 ready, 2 waiting for reply
		private var _commandReplyTimeout:uint = 5000; // Command timeout in milliseconds
		private var _timeoutTimer:Timer; // Creates a dummy timer
		// COMMAND
		private var _activeMessage:BluetoothMessage;
		private var _activeCommand:String; // full command including length and ID
		private var _activeCommandId:String; // ID of active command
		private var _activeCommandCmd:String; // Command only cmd
		private var _activeCommandData:String; // Command only data
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
		
		
		// UTY - SEND COMMAND
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
			_timeoutTimer.reset();
			if (WAIT_MESSAGE_CONFIRMATION) {
				_timeoutTimer.start();
				_commandStatus = 2;
			}
			_activeCommand = createCommand(cmd, data);
			const sentOk:Boolean = DistriqtBluetoothLE.write(_activeCommand);
			if (sentOk) Debug.debug(_debugPrefix, "Command sent: " + _activeCommand);
			else Debug.error(_debugPrefix, "Command sending error: " + _activeCommand);
			PippoFlashEventsMan.broadcastInstanceEvent(this, sentOk ? EVT_COMMAND_SENT : EVT_COMMAND_SEND_ERROR, _activeMessage);
			return sentOk;
		}
		private function createCommand(cmd:String, data:String=null):String {
			// Add parameters
			const commandParameters:Vector.<String> = new Vector.<String>();			
			var commandId:String = UText.getRandomString(2);
			_activeCommandId = commandId;
			if (ADD_COMMAND_ID) {
				commandParameters.push(commandId);
			}
			for (var i:int = 0; i < _customAdds.length; i++) {
				commandParameters.push(_customAdds[i]);
			}
			commandParameters.push(cmd);
			if (data) commandParameters.push(data);
			var fullCommand:String = commandParameters.join(CHARACTER_MAIN_DIVIDER);
			if (ADD_CHARACTER_COUNT) {
				fullCommand = CHARACTER_MAIN_DIVIDER + fullCommand; // Add didiver at the beginning (9)
				var count:uint = fullCommand.length; // Add the correct nmber of characters before
				if (count < 10) count += count == 9 ? 2 : 1;
				else if (count < 100) count += count >= 98 ? 3 : 2;
				else if (count < 1000) count += count >= 997 ? 4 : 3;
				else if (count < 10000) count += count >= 9996 ? 5 : 4;
				fullCommand = String(count) + fullCommand;
			}
			if (_activeMessage) UMem.storeInstance(_activeMessage);
			_activeMessage = UMem.getInstance(BluetoothMessage, commandId, cmd, data);
			return fullCommand;
		}
		private function onTimeoutTimerElapsed(e:TimerEvent):void {
			if (waiting) {
				Debug.debug(_debugPrefix, "Command timeout elapsed.");
				setTimedout();
			} else {
				Debug.error(_debugPrefix, "Command timeout but system not waiting.");
			}
		}
		// UTY - COMMAND
		private function processReceivedCommand(cmd:String):void {
			// A command is received, I need to do all checks here
			if (!waiting) {
				Debug.error(_debugPrefix, "Command received but I was not waiting.");
				return;
			}
			const mainSplit:Array = cmd.split(CHARACTER_MAIN_DIVIDER);
			
		}
		private function setTimedout():void {
			_activeMessage.setTimedout();
			resetStatus();
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_COMMAND_TIMEOUT, _activeMessage);
		}
		private function resetStatus():void {
			_commandStatus = 1;
		}
		
		// DistriqtBluetoothLE Listeners
		public function onBluetoothLECommandReceived(cmd:String):void {
			Debug.debug(_debugPrefix, "Received blutooth reply: " + cmd);
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