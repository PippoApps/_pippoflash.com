package com.pippoflash.net 
{
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem;
	import com.pippoflash.utils.*;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public dynamic class P2PLocalCommanderMessageData extends _PippoFlashBaseNoDisplayUMem 
	{
		
		private var _fromUdid:String;
		private var _fromName:String;
		private var _fromMode:String;
		private var _fromGroup:String;
		private var _fromApp:String;
		private var _fromVersion:String;
		
		private var _toUdid:String;
		private var _toName:String;
		
		private var _msgType:String;
		private var _msgArgument:Object;
		private var _msgId:String;
		private var _msgReceipt:Boolean;
		private var _msgSuccess:Boolean;
		
		private var _info:String;
		private var _extraParams:Object;		

		
		
		
		public function P2PLocalCommanderMessageData(sourceObj:Object=null) 
		{
			super("P2PLocalCommanderMessageData");
			//trace("SETTO ENUMERABLEEEEEEEEEEEEEEEEEEEEEEEEEEE");
			//this.setPropertyIsEnumerable("fromUdid", true);
			//trace(this.propertyIsEnumerable("fromUdid"));
			recycle(sourceObj);
		}
		public function recycle(sourceObj:Object = null):void { // Callled on each instantiation
			//trace("RECYCLEEEEEEE", sourceObj, Debug.object(sourceObj));
			//trace(this.isPropertyEnumerable("fromUdid"));
			if (sourceObj) {
				for (var s:String in sourceObj) {
					//trace("par",s,sourceObj[s]);
					this[s] = sourceObj[s];
				}
			}
		}
		override public function cleanup():void {
			//trace("CLEANINGUUUUUUUUUUUUUUUUUUUUUP!!!!!");
			// All non sure to be written arguments are nullified
			_msgId = null;
			_fromName = null;
			_toName = null;
			_toUdid = null;
			_msgReceipt = null;
			_msgSuccess = null;
			_msgArgument = null;
			_extraParams = null;
			_info = null;
		}
		
		public function toString():String {
			var info:Array = [];
			const props:Array = ("fromApp,fromGroup,fromMode,fromName,fromUdid,fromVersion,toName,toUdid,msgType,msgId,msgArgument,msgReceipt,msgSuccess,info,extraParams").split(",");
			
			for each (var s:String in props) {
				//trace(s);
				if ( this[s]) info.push(s + ":" + this[s]);
			}
			info.push(Debug.object(msgArgument));
			return "<" + _debugPrefix + ">\n" + info.join("\n");
		}
		public function get identity():String { // Returns a readable identity
			return (_fromName ? _fromName : "") + " - " + _fromUdid;
		}
		
		public function get fromUdid():String 
		{
			return _fromUdid;
		}
		
		public function set fromUdid(value:String):void 
		{
			_fromUdid = value;
		}
		
		public function get fromName():String 
		{
			return _fromName;
		}
		
		public function set fromName(value:String):void 
		{
			_fromName = value;
		}
		
		public function get fromMode():String 
		{
			return _fromMode;
		}
		
		public function set fromMode(value:String):void 
		{
			_fromMode = value;
		}
		
		public function get fromGroup():String 
		{
			return _fromGroup;
		}
		
		public function set fromGroup(value:String):void 
		{
			_fromGroup = value;
		}
		
		public function get fromApp():String 
		{
			return _fromApp;
		}
		
		public function set fromApp(value:String):void 
		{
			_fromApp = value;
		}
		
		public function get fromVersion():String 
		{
			return _fromVersion;
		}
		
		public function set fromVersion(value:String):void 
		{
			_fromVersion = value;
		}
		
		public function get toUdid():String 
		{
			return _toUdid;
		}
		
		public function set toUdid(value:String):void 
		{
			_toUdid = value;
		}
		
		public function get toName():String 
		{
			return _toName;
		}
		
		public function set toName(value:String):void 
		{
			_toName = value;
		}
		
		public function get msgType():String 
		{
			return _msgType;
		}
		
		public function set msgType(value:String):void 
		{
			_msgType = value;
		}
		
		public function get msgArgument():Object 
		{
			return _msgArgument;
		}
		
		public function set msgArgument(value:Object):void 
		{
			_msgArgument = value;
		}
		
		public function get msgId():String 
		{
			return _msgId;
		}
		
		public function set msgId(value:String):void 
		{
			_msgId = value;
		}
		
		public function get msgReceipt():Boolean 
		{
			return _msgReceipt;
		}
		
		public function set msgReceipt(value:Boolean):void 
		{
			_msgReceipt = value;
		}
		
		public function get msgSuccess():Boolean 
		{
			return _msgSuccess;
		}
		
		public function set msgSuccess(value:Boolean):void 
		{
			_msgSuccess = value;
		}
		
		public function get info():String 
		{
			return _info;
		}
		
		public function set info(value:String):void 
		{
			_info = value;
		}
		
		public function get extraParams():Object 
		{
			return _extraParams;
		}
		
		public function set extraParams(value:Object):void 
		{
			_extraParams = value;
		}
		
	}

}