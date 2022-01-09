package com.pippoflash.framework.air.bluetooth 
{
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem;
	import com.pippoflash.utils.UMem;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class BluetoothMessage extends _PippoFlashBaseNoDisplayUMem 
	{
		private var _id:String;
		private var _cmd:String;
		private var _data:String;
		private var _sent:Date;
		private var _msgStatus:uint; // 0 idle, 1 sent, 2 replied, 3 timed out
		private var _reply:String;
		private var _metadata:*; // Manually set
		public function BluetoothMessage(id:String, cmd:String, data:String=null) {
			super("BluetoothMessage");
			recycle(id, cmd, data);
		}
		
		
		public function recycle(id:String, cmd:String, data:String):void {
			_id = id;
			_cmd = cmd;
			_data = data;
			_sent = new Date();
			_msgStatus = 1;
		}
		
		public function setReplied(reply:String):void {
			_reply = reply;
			_msgStatus = 2;
		}
		public function setTimedout():void {
			_msgStatus = 3;
		}
		
		
		
		// GET
		public function get cmd():String 
		{
			return _cmd;
		}
		
		public function get id():String 
		{
			return _id;
		}
		
		public function get data():String 
		{
			return _data;
		}
		
		
		// GET SET
		public function get metadata():* 
		{
			return _metadata;
		}
		
		public function set metadata(value:*):void 
		{
			_metadata = value;
		}
		
		
	}

}