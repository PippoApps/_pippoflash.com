package com.pippoflash.net 
{
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem;
	import com.pippoflash.utils.*;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import framework._MainAppBaseAir;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
     * Loads a file from network, if network is not available loads latest version from SharedObject, if SharedObject not available loads from local files URL
	 */
	public dynamic class LoadNetOrSharedObjectOrLocal extends _PippoFlashBaseNoDisplayUMem 
	{
        private static const EVT_LOAD_COMPLETE:String = "onMultiSearchFileLoadComplete"; // this
		private var _netUrl:String;
		private var _localUrl:String;
		private var _soName:String;
		private var _useAnticache:Boolean;
        private var _loadedContent:String;
        private var _status:uint; // 0 idle, 1 loading net, 2 loading SO, 3 loading local, 4 complete, 5 error
        private var _loadedAs:uint; // 0 none, 1 net, 2 SO, 3 local
        private var _qlo:SimpleQueueLoaderObject;
		
		public function LoadNetOrSharedObjectOrLocal(netUrl:String, localUrl:String=null, soName:String=null, useAnticache:Boolean=true) 
		{
			super("LoadNetOrSharedObjectOrLocal");
            recycle(netUrl, localUrl, soName, useAnticache);
            Debug.debug(_debugPrefix, "Initialized. Call start() to start load process.");
		}
		public function recycle(netUrl:String, localUrl:String=null, soName:String=null, useAnticache:Boolean=true):void { // Callled on each instantiation
			//trace("RECYCLEEEEEEE", sourceObj, Debug.object(sourceObj));
			//trace(this.isPropertyEnumerable("fromUdid"));
            cleanup();
            _netUrl = netUrl;
            _localUrl = localUrl;
            _soName = soName;
            _useAnticache = useAnticache;
            complete();
		}
		override public function cleanup():void {
            _netUrl = null;
            _localUrl = null;
            _soName = null;
            _loadedContent = null;
            _useAnticache = false;
            _qlo = null;
            _loadedAs = 0;
            _status = 0;
            PippoFlashEventsMan.removeAllListeningToInstance(this);
            super.cleanup();
		}

        // Start and load from network
        public function start(onComplete:Function=null):void {
            _status = _loadedAs = 1;
            if (onComplete) PippoFlashEventsMan.addInstanceMethodListenerTo(this, EVT_LOAD_COMPLETE, onComplete);
            _qlo = QuickLoader.loadFile(_netUrl, this, "Net", _useAnticache, "txt");
        }
        public function onLoadCompleteNet(o:SimpleQueueLoaderObject):void {
            broadcastComplete(o.getContent() as String);
        } 
        // Proceed from SharedObject or Load Local
        public function onLoadErrorNet(o:SimpleQueueLoaderObject, e:*):void {
            _status = _loadedAs = 2;
            const soContent:String = (_mainApp as _MainAppBaseAir).getSharedObject(_netUrl);
            if (soContent) {
                _loadedAs = 1;
                broadcastComplete(soContent);
            } else if(_localUrl) { // There is a local version
                _status = _loadedAs = 3;
                _qlo = QuickLoader.loadFile(_localUrl, this, "Local", _useAnticache, "txt");
            } else broadcastError("All failed and Local version not required.");
        }
        public function onLoadCompleteLocal(o:SimpleQueueLoaderObject):void {
            broadcastComplete(o.getContent() as String);
        } 
        // Proceed from SharedObject or Load Local
        public function onLoadErrorLocal(o:SimpleQueueLoaderObject, e:*):void {
            broadcastError("All failed...");
        }
		
        private function broadcastComplete(content:String):void {
            _loadedContent = content;
            _status = 4;
            PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_LOAD_COMPLETE, this);
        }
        private function broadcastError(e:String):void { // This means file is not found anywhere
            _loadedAs = 0;
            _status = 5;
            Debug.error(_debugPrefix, "Load error " + e);
        }
	}

}