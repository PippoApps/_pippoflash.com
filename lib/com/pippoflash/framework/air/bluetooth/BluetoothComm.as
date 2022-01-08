package com.pippoflash.framework.air.bluetooth 
{
	import com.pippoflash.framework._PippoFlashBaseNoDisplay;
	import com.pippoflash.framework.air.ane.distriqt.DistriqtBluetoothLE;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UText;
	
	/**
	 * Used to communicate or simulate communication with BluetoothLE devices.
	 * @author Pippo Gregoretti
	 */
	public class BluetoothComm extends _PippoFlashBaseNoDisplay 
	{
		public var CHARACTER_MAIN_DIVIDER:String = "|"; 
		public var ADD_CHARACTER_COUNT:Boolean = true; // Adds a first slot with character count
		public var ADD_COMMAND_ID:Boolean = true; // Adds command ID as a second parameter
		private var _customAdds:Vector.<String> = new Vector.<String>(); // Adds custom content to every call
		private var _commands:Vector.<String> = new Vector.<String>(); // Stores the list of issued coimmands
		private var _activeCommand:String;
		private var _activeCommandId:String;
		private var _commandStatus:uint = 0; // 0 idle, 1 ready, 2 waiting for reply
		//private var _status:uint = 0;;
		
		
		
		
		public function BluetoothComm(id:String) {
			super("BluetoothComm_"+id, BluetoothComm);
		}
		
		
		// SETUP
		public function setupDistriqtBluetoothLE():void {
			PippoFlashEventsMan.addStaticListener(DistriqtBluetoothLE, this);
			_commandStatus = 1;
		}
		public function setCustomAdd(index:uint, t:String):void { // Adds a custom element
			_customAdds[index] = t;
			Debug.debug(_debugPrefix, "Setting custom adds: " + _customAdds);
		}
		public function setPin(pin:String):void {
			setCustomAdd(0, pin);
		}
		// COMMANDS
		public function getSettings():Boolean {
			trace("FREGNAAAAAAAAFREGNAAAAAAAAFREGNAAAAAAAAFREGNAAAAAAAAFREGNAAAAAAAAFREGNAAAAAAAAFREGNAAAAAAAA");
			return sendCommand("g");
		}
		
		
		// UT
		private function sendCommand(cmd:String, data:String=null, force:Boolean=false):Boolean {
			if (!ready && !force) {
				Debug.error(_debugPrefix, "Not ready to issue a new command: " + cmd + ". Still waiting for command: " + _activeCommand);
				return false;
			}
			_commandStatus = 2;
			_activeCommand = createCommand(cmd, data);
			Debug.debug(_debugPrefix, "Sending command: " + _activeCommand);
			return DistriqtBluetoothLE.write(_activeCommand);
		}
		private function createCommand(cmd:String, data:String=null):String {
			// Add parameters
			const commandParameters:Vector.<String> = new Vector.<String>();			
			if (ADD_COMMAND_ID) {
				var commandId:String = UText.getRandomString(2);
				_activeCommandId = commandId;
				commandParameters.push(commandId);
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
			return fullCommand;
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
		
		
	}

}