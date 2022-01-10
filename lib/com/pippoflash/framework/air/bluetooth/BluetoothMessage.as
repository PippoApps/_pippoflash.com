package com.pippoflash.framework.air.bluetooth 
{
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem;
	import com.pippoflash.utils.*;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class BluetoothMessage extends _PippoFlashBaseNoDisplayUMem 
	{
		private static const STATUSES:Array = ["IDLE", "SENT", "REPLIED", "TIMED OUT", "SYNTAX ERROR"];
		private var _id:String;
		private var _cmd:String;
		private var _data:String;
		private var _sent:Date;
		private var _msgStatus:uint; // 0 idle, 1 sent, 2 replied, 3 timed out, 4 syntax error
		private var _reply:String;
		private var _metadata:*; // Manually set
		private var _errorDescription:String;
		public function BluetoothMessage(id:String, cmd:String, data:String=null) {
			super("BluetoothMessage");
			recycle(id, cmd, data);
		}
		
		// FRAMEWORK
		public function recycle(id:String, cmd:String, data:String):void {
			_id = id;
			_cmd = cmd;
			_data = data;
			_sent = new Date();
			_msgStatus = 1;
			_errorDescription = null;
		}
		override public function release():void {
			_msgStatus = 0;
			_cmd = _data = _reply = _id = _metadata = null;
			super.release();
		}
		
		// METHODS
		public function setReplied(reply:String):void {
			_reply = reply;
			_msgStatus = 2;
		}
		public function setTimedout():void {
			_msgStatus = 3;
		}
		public function setToSyntaxError(desc:String):void {
			_errorDescription = desc;
			_msgStatus = 4;
			Debug.debug(_debugPrefix, "Set to Syntax error: " + desc);
		}
		
		
		// GET DATA
		public function get cmd():String {
			return _cmd;
		}
		public function get id():String {
			return _id;
		}
		public function get data():String {
			return _data;
		}
		public function get reply():String {
			return _reply;
		}
		
		
		// METADATA GET SET
		public function get metadata():* 
		{
			return _metadata;
		}
		
		public function set metadata(value:*):void 
		{
			_metadata = value;
		}
		
		
		
		// GET STATUS
		public function get sent():Boolean {
			return _msgStatus == 1;
		}
		public function get replied():Boolean {
			return _msgStatus == 2;
		}
		public function get timedOut():Boolean {
			return _msgStatus == 3;
		}
		public function get syntaxError():Boolean {
			return _msgStatus == 4;
		}
		public function get syntaxErrorDescription():String {
			return syntaxError ? _errorDescription : "";
		}
		
		
		// SYSTEM
		public function toString():String {
			return "BluetoothMessage ID: " + id + ", status: " + STATUSES[_msgStatus] + ", cmd & data: " + (_cmd + "|" + _data) + ", reply: " + _reply;
		}
		
	}

}