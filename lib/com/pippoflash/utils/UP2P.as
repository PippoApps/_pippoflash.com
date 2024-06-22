package com.pippoflash.utils 
{
	import com.pippoflash.net.P2PGroupLocalCommander;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.utils.*;
	import com.pippoflash.net.P2PGroupLocalCommanderMultiSlave;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * this class makes it simple to work with local P2P UDP features.
	 */
	public class UP2P extends _UBase 
	{
		
		
		// SYSTEM
		static private var _udidCounter:uint = 0;
		static private var _debugPrefix:String = "UP2P";
		static private var _init:Boolean;		
		static private var _p2ps:Vector.<P2PGroupLocalCommander> = new Vector.<P2PGroupLocalCommander>();
		static private var _p2pByConnectionId:Object = {}; // 
		// DEFAULTS
		static private var _defaultGroupId:String = "PippoApps/DefaultGroup";
		static private var _defaultMulticastAddress:String = "225.225.0.1:30303";
		static private var _defaultAppId:String = "com.pippoapps.p2p.master"; // If I am a master, this must be set as _pairingApp on the other side slave.
		static private var _defaultUserName:String = "P2PUser";
		//static private var _defaultMasterApp:String = "com.pippoapps.p2p.master"; // If I am a slave, this is the MASTER app set as _appId on the other side.  This is _pairingApp.
		static private var _defaultUdid:String = "com.pippoapps.p2p.[COUNT]"; // Udid of this machine, with number of P2P instance to be added. THIS MUST BE UNIQUE ON NETWORK. Once machines are paired, the other machine gets this UDID and uses it for direct messages.
		
		private function checkInit():void {
			if (_init) return;
			_init = true;
		}
		/**
		 * Create and setup a new P2P instance
		 * @param	connectionId ID used o retrieve this connection
		 * @param	slaveMasterOrNeutral connections mode, "M" for master, "S" for slave, "N" for neutral (can only sniff or chat)
		* @param	listener Object that will listen to direct P2P events (P2PGroupLocalCommander.EVT_...)
		 * @param	udid Unique device identifier. Once paired, this will be used to identify for sure both sides. NOT USED FOR PAIRING.
		 * @param	pin Pin that can be manually inserted in order to allow connection between apps
		 * @return	P2PGroupLocalCommander instance.
		 */
		static public function createP2P(connectionId:String, listener:Object, mode:String="O", localUdid:String=null, remoteUdid:String=null, pin:String = "0000"):P2PGroupLocalCommander {
			//if (!udid) {
				//udid = UText.insertParam(_defaultUdid, "COUNT", String(_udidCounter));
				//Debug.warning(_debugPrefix, "Attention, udid has not been set. Udid for connection ["+connectionId+"] will be: " + udid);
			//}
			var p:P2PGroupLocalCommander = new P2PGroupLocalCommander(connectionId, _defaultAppId, mode, _defaultUserName, localUdid, remoteUdid, pin, _defaultGroupId, _defaultMulticastAddress);//connectionId, _defaultAppId, udid, _defaultUserName, slaveMasterOrNeutral, pin, _defaultGroupId, _defaultMulticastAddress);
					//public function P2PGroupLocalCommander		(id:String, appId:String, udid:String, name:String="TestUser", mode:String="N", groupId:String=null, multicastAddress:String=null):void {
			_p2ps.push(p);
			_p2pByConnectionId[connectionId] = p;
			PippoFlashEventsMan.addInstanceListener(p, listener);
			// Connect and start pairing process
			if (!P2PGroupLocalCommander.AUTO_CONNECT) p.connect();
			return p;
		}
		static public function createP2PMulti(connectionId:String, listener:Object, mode:String="P", localUdid:String=null, remoteUdids:Array=null, pin:String = "0000"):P2PGroupLocalCommanderMultiSlave {
			//if (!udid) {
				//udid = UText.insertParam(_defaultUdid, "COUNT", String(_udidCounter));
				//Debug.warning(_debugPrefix, "Attention, udid has not been set. Udid for connection ["+connectionId+"] will be: " + udid);
			//}
			//trace("FREGNA",remoteUdids);
			var p:P2PGroupLocalCommanderMultiSlave = new P2PGroupLocalCommanderMultiSlave(connectionId, _defaultAppId, mode, _defaultUserName, localUdid,  remoteUdids, pin, _defaultGroupId, _defaultMulticastAddress);//connectionId, _defaultAppId, udid, _defaultUserName, slaveMasterOrNeutral, pin, _defaultGroupId, _defaultMulticastAddress);
					//public function P2PGroupLocalCommander		(id:String, appId:String, udid:String, name:String="TestUser", mode:String="N", groupId:String=null, multicastAddress:String=null):void {
			_p2ps.push(p);
			_p2pByConnectionId[connectionId] = p;
			PippoFlashEventsMan.addInstanceListener(p, listener);
			// Connect and start pairing process
			if (!P2PGroupLocalCommander.AUTO_CONNECT) p.connect();
			return p;
		}
		
		
		
		static public function getP2P(connectionId:String):P2PGroupLocalCommander {
			return _p2pByConnectionId[connectionId];
		}
		
		//static public function set defaultMasterApp(value:String):void 
		//{
			//_defaultMasterApp = value;
		//}
		
		static public function set defaultAppId(value:String):void 
		{
			_defaultAppId = value;
		}
		
		static public function get connectionsNumber():uint 
		{
			return _p2ps.length;
		}
		
		static public function set defaultUserName(value:String):void 
		{
			_defaultUserName = value;
		}
		
	}

}