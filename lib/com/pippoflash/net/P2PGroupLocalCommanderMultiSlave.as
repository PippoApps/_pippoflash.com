package com.pippoflash.net 
{
	/**
	 * This one has several other UDIDs to pair, and sets as paired only when all remote udids are paired.
	 * @author Pippo Gregoretti
	 */
	import com.pippoflash.utils.*;
	public class P2PGroupLocalCommanderMultiSlave extends P2PGroupLocalCommander 
	{
		
		public static const EVT_SINGLE_REMOTE_PAIRED:String = "onP2PRemoteUdidPaired"; // remoteIndex:int - a remote device has been paired
		private var _remoteUdids:Array;
		private var _pairedUdids:Array;
		
		
		public function P2PGroupLocalCommanderMultiSlave(id:String, appId:String, mode:String="P", name:String=null, localUdid:String=null, remoteUdids:Array=null, pin:String=null, groupId:String=null, multicastAddress:String=null, requestWelcomeOnAnnounce:Boolean=false) 
		{
			super(id, appId, mode, name, localUdid, null, pin, groupId, multicastAddress, requestWelcomeOnAnnounce);
			_remoteUdids = remoteUdids;
			if (!_remoteUdids) {
				Debug.error(_debugPrefix, "CRITICAL ERROR - LIST OF REMOTE UDIDS MUST BE DEFINED.");
			}
			if (!isPairable()) {
				Debug.error(_debugPrefix, "CRITICAL ERROR - This MUST be pairable. Mode must be P or M or S");
			}
		}
		
		
		
		// METHODS
		public function isRemoteIndexPaired(remoteIndex:int):Boolean {
			return _pairedUdids[remoteIndex];
		}
		public function sendComandToRemoteIndex(remoteIndex:int, arg:*, receipt:Boolean = false, info:String = null, extraParams:Object = null):void {
			sendCmdTo(_remoteUdids[remoteIndex], arg, receipt, info, extraParams);
		}
		
		
		
		
		// OVERRIDES
		override protected function analyzeAndSendPairing(data:P2PLocalCommanderMessageData):Boolean { // Whenever a message is received (ANOUNCE or else) this analyzes whether I should send the other guy a request for pairing
			Debug.debug(_debugPrefix, "analyzing pairing.",isPairable(),isPairedInAnyWay());
			if (!isPairable()) return false; // I am not pairable
			//if (isPairedInAnyWay()) return false; // I am already paired
			// check if I have to pair with sender and eventually send a "IAMYOURPAIR";
			if (_remoteUdids.indexOf(data.fromUdid) != -1) {
				Debug.debug(_debugPrefix, "I have found my pair. I send him a pairing request.");
				sendCommandTo(data.fromUdid, "IAMYOURPAIR");
				return true;
			} 
			return false;
		}

		override protected function processCommand_IAMYOURPAIR(data:P2PLocalCommanderMessageData):Boolean { // A client has replied to my introduction message
			Debug.debug(_debugPrefix, data.identity, "send me a pairing request."); 
			if (isPairable() && _remoteUdids.indexOf(data.fromUdid) != -1  && data.toUdid == _localUdid) {
				const index:int = _remoteUdids.indexOf(data.fromUdid);
				_pairedUdids[index] = true;
				Debug.debug(_debugPrefix, index + " is paired:", _pairedUdids);
				broadcastEvent(EVT_SINGLE_REMOTE_PAIRED, index);
				for each (var paired:Boolean in _pairedUdids) if (!paired) return true; // Just return true for pairing correct before changing status
				setSatusToPaired();
			}
			else {
				trace(isPairable());
				Debug.warning(_debugPrefix, "PAIRING REQUEST REFUSED, remote:" + _remoteUdids + " local:" + _localUdid + data);
				return false;
				
			}
			return true;
		}
		
		override public function resetConnection():void {
			_pairedUdids = null;
			super.resetConnection();
		}
		
		override public function connect():Boolean {
			_pairedUdids = [];
			for (var i:int = 0; i < _remoteUdids.length; i++) _pairedUdids[i] = false;
			return super.connect();
		}
		// OVERRIDES TO INHIBIT METHODS
		override public function sendCmdToRemote(arg:*, receipt:Boolean = false, info:String = null, extraParams:Object = null):void {
			Debug.error(_debugPrefix, "sendCmdToRemote() not working in multiple slaves.");
		}
		override public function sendChatToSlave(t:String):void {
			Debug.error(_debugPrefix, "sendChatToSlave() not working in multiple slaves.");
		}
		override public function sendCmdToSlave(arg:*, receipt:Boolean = false):void {
			Debug.error(_debugPrefix, "sendCmdToSlave() not working in multiple slaves.");
		}
		override protected function sendCommandToSlave(cmd:String, arg:*, receipt:Boolean = false, info:String = null):void {
			Debug.error(_debugPrefix, "sendCommandToSlave() not working in multiple slaves.");
		}
	}
}