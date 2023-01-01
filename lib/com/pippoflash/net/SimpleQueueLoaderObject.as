/* SimpleQueueLoaderObject - 1.0 - Filippo Gregoretti - www.pippoflash.com

Loads one file and manages all events in a simplified way.
Used by SimpleQueueLoader to manage queues and priorities.
Also used by QuickLoader to load a dirty quick file.

METHODS
	new SuperLoaderObject(params:Object);
		Parameters to be used always
		
		_url			:String;	The url to load
		_anticache	:Boolean;	If true, an anticache variable is appended at the end of url
		_fileType		:String;	Type of file, if not specified, type will be retrieved by filename
		_listener		:Object;	Listener for broadcasted functions
		_funcPostfix	:String;	String to add to listener function names
	

	SuperLoader.startLoad()
		Starts to load the url specified in _url


BROADCASTS
	All events can be added with funcPostfix: onLoadStart+funcPostfix();
	
	onLoadStart(SuperLoaderObject);
	onLoadProgress(SuperLoaderObject);
	onLoadError(SuperLoaderObject);
	onLoadComplete(SuperLoaderObject);
	
*/


package com.pippoflash.net {
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import									flash.system.*;
	import 									flash.utils.*;
	import									com.pippoflash.utils.*;
	import flash.net.URLStream;
	
	public dynamic class SimpleQueueLoaderObject {
		// EVENT CONSTANTS
		public static const EVT_START:String = "onLoadStart"; // this
		public static const EVT_INIT:String = "onLoadInit"; // this
		public static const EVT_PROGRESS:String = "onLoadProgress"; // this
		public static const EVT_ERROR:String = "onLoadError"; // this, error:String
		public static const EVT_COMPLETE:String = "onLoadComplete"; // this
		private static const DEFAULT_TO_BINARY:Boolean = true; // If a file extension for tring is found uses RLLoader, otherwise default tobinary loader. Set to false for the opposite.
		// STATIC VARIABLES
		public static var _verbose:Boolean = true; //  T races events - also progress
		static public var _traceLoadUrl:Boolean = false; // traces only loaded images
		public static var _debug:Boolean = false; // Traces loaded object
		public static var _forceSameApplicationDomain:Boolean = false; // Forces same applicaiton domain in swf loading (set manually if loading too many SWFs)
		static public var _setSameAppDomainForSwfOnIOS:Boolean = false; // If running on iOS, and loading an SWF, application domain is always the same 
		static public var _setSameAppDomainForSwfAlways:Boolean = false; // If running on iOS, and loading an SWF, application domain is always the same 
		public static var _swfPluginNames:String = "swf";
		public static var _debugPrefix:String = "SQLoaderObj";
		/* CHANGED SYSTEM, NOW DEFAULT IS BINARY, AND IF STRING EXTENSION IS FOUND A STRING IS USED */
		public static var _byteLoaderNames:String = "jpg,png,jpeg,swf,gif,bmp,img"; // If filename has this extension a Loder will be created, else an URLLoader. These are files that can be used by flash natively. (imgs and swfs)
		public static var _dataLoaderNames:String = "xml,txt,text,vars,var,json,string,data,ascii"; // If user fileType is one of these, return a URLLoader. These are srings parsable.
		// SYSTEM
		public var _loader:*; // This may be a Loader or a URLLoader or a URLStream depending on file
		public var _request						:URLRequest = new URLRequest();
		public var _urlLoader						:URLLoader = new URLLoader();
		public var _contentLoader					:Loader = new Loader();
		public var _urlStream:URLStream = new URLStream();
		public var _contentLoaderInfo				:LoaderInfo;
		private var _id							:String; // A unique ID generated for the loader on each load operation
		// USER VARIABLES
		public var _url							:String;
		public var _anticache						:Boolean;
// 		public var _listNum						:uint;
		public var _fileType						:String;
		public var _dataObject						:*;
		public var _isPost						:Boolean;
		public var _requestHeaders					:Object; // Object: {no-cache:"false", X-HTTP-Method-Override:"PUT"} - It will be converted in request headers
// 		public var _prioritize						:Boolean;
		public var _listener						:Object;
		public var _loaderListener					:*;
		public var _funcPostfix					:String = "";
		public var _forceURLStream:Boolean = false;
		// MARKERS
		public var _isSuperLoaderQueue				:Boolean = false; // If set to true, it performs actions on SuperLoader
		public var _loading						:Boolean = false;
		public var _isError						:Boolean = false;
		public var _loaded						:Boolean = false;
		public var _isLoader						:Boolean;
		public var _bytesLoaded					:uint;
		public var _bytesTotal						:uint;
		public var _percent						:uint;
		public var _killed							:Boolean; // This prevents further executions after harakiri
		public var _width						:Number; // Width of loaded LoaderInfo
		public var _height						:Number; // Height of loaded LoaderInfo
		public var _isSwf:Boolean; // Marks if I am loading an SWF file (useful to force same application domain on iOS)
		// STATIC UTY
		public static var _s						:String;
// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function SimpleQueueLoaderObject(par:Object=null) {
			recycle(par);
		}
		public function recycle(par:Object=null) {
			_killed = false;
			UCode.setParameters(this, par);
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////////
		public function startLoad() {
			// if (_verbose) 
			if (_traceLoadUrl) Debug.debug(_debugPrefix, "Loading:",_url); // Always say what do you load
			if (_killed) return;
			_id = String(Math.random());
			_loader = UCode.exists(_fileType) ? getLoaderByFileType(_fileType) : getLoaderByFileName(_url);
			_isLoader = _loader is Loader;
			_isSwf = _url.lastIndexOf(".swf") == (_url.length - 4); // If url ends with .swf
			var l = _isLoader ? _loader.contentLoaderInfo : _loader;
			l.addEventListener(Event.OPEN, onLoadStartLoader);
			l.addEventListener(Event.INIT, onLoadInitLoader);
			l.addEventListener(Event.COMPLETE, onLoadCompleteLoader);
			l.addEventListener(IOErrorEvent.IO_ERROR, onLoadErrorLoader);
			l.addEventListener(ProgressEvent.PROGRESS, onLoadProgressLoader);
			l.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadErrorLoader);
			_contentLoaderInfo = _isLoader ? _loader.contentLoaderInfo : null;
			if (UGlobal.isLocal()) _anticache = false;
			// Set default loader context. New application domain, with same security domain if is online
			var context:LoaderContext = UGlobal.isLocal() || USystem.isAir() ? new LoaderContext(true, new ApplicationDomain(null)) : new LoaderContext(true, new ApplicationDomain(null), SecurityDomain.currentDomain);
			// Behaviors for same application domain
			if (_forceSameApplicationDomain // Always same application domain
			|| (_setSameAppDomainForSwfAlways && _isSwf) // Always same for SWFs only
			|| (_setSameAppDomainForSwfOnIOS && USystem.isIOS() && _isSwf)) // Same only on iOS and SWFs
			{ // on IOS, multiple application domains are NOT allowed
			//if (_forceSameApplicationDomain) {
				context = new LoaderContext(false, ApplicationDomain.currentDomain, null);
				if (USystem.isOnline()) {
					context.securityDomain = SecurityDomain.currentDomain; // Local SWFs cannot use security domain. This only works when in browser.
					if (_verbose) Debug.debug(_debugPrefix, "WARNING - Loading in same application domain, and same security domain: " + _url);
				}
				else {
					if (_verbose) Debug.debug(_debugPrefix, "WARNING - Loading in same application domain, different security domain: " + _url);
				}
			}
			// Create url request for POST, GET
			_request.url						= _url;
			_request.method 					= _isPost ? "POST" : "GET";
			if (_dataObject)	{
				if (_dataObject is URLVariables)		_request.data = _dataObject;
				else if (_dataObject is String)		_request.data = _isPost ? _dataObject : new URLVariables(_dataObject); // If is post, anyway is just the direct string
				else if (_dataObject  is Object) {		
// 					var v						:URLVariables = new URLVariables();
					var s:String = "";
					for (_s in _dataObject) s+= _s + "=" +encodeURIComponent(_dataObject[_s])+"&";
					s = s.substr(0,s.length-1)
					var v:URLVariables = new URLVariables(s);
// 					for (_s in _dataObject)		v[_s] = _dataObject[_s];
					_request.data = v;
					if (_verbose) Debug.debug(_debugPrefix, "Converto oggetto in urlvariables", v.toString());
				}
				if (_verbose) Debug.debug(_debugPrefix, _isPost ? "POST data:" : "GET data",_request.data);
			}
			else _request.data = null;
			// Check for headers, and eventually add them (useful for PUT and DELETE as stated in  http://cambiatablog.wordpress.com/2010/08/10/287/)
			// If I want to use PUT or DELETE, I need to make sure there is at least 1 post variable or it will not work
			if (_requestHeaders) {
				var headers					:Array = [];
				for (_s in _requestHeaders) {
					Debug.debug				(_debugPrefix, "HEADER", _s,"=",_requestHeaders[_s]);
					headers.push				(new URLRequestHeader(_s, _requestHeaders[_s]));
				}
				_request.requestHeaders			= headers;
			}
			// Shoot loading
			// I get a context domain error when loading stuff internalli in air apps. When I am on an air app, he doesn't see me as local.
			try { // Sometimes Security Error Events are triggered at runtime in local debug loader
				if (_isLoader)						_loader.load(_request, context);
				else								_loader.load(_request);
			} catch (e:Error) {
				var ee:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR, false, false, "Runtime security error: " + String(e));
				onLoadErrorLoader(ee);
			}
		}
		public function getContent():* {
			if (_loader is Loader)	return _loader.content;
			else if (_loader is URLLoader) return _loader.data;
			else if (_loader is URLStream) {
				Debug.debug(_debugPrefix, "Returning a ByteArray frol URLStream for url: " + _url);
				var fileData:ByteArray = new ByteArray(); 
				_urlStream.readBytes(fileData, 0, _urlStream.bytesAvailable); 
				return fileData;
			}
		}
		public function getJsonContent():Object {
			return JSON.parse(getContent());
		}
		public function getInternalClass				(className:String):Class { // This gives the opportunity to get a class that has been exported internally in the application context
			Debug.debug						(_debugPrefix, "I'm requested class from loaded file: " + className);
			if (isLoader()) {
				if (_loader.content.isPippoFlashLibrary) {
					return					_loader.content.getInternalClass(className) as Class;
				}
				var c:Class					= _contentLoaderInfo.applicationDomain.getDefinition(className) as Class;
				return						c;
			} else {
				Debug.error					(_debugPrefix, "I am requested a class",className,"but I am a data loader, not an swf.");
			}
			return							null;
		}
		public function connectWithMe				(c:DisplayObject):void { // This connects an instance of Loader to this loader for automatic counting
			_loaderListener						 = c;
		}
		public function isLoaded					():Boolean {
			return							_loaded;
		}
		public function isLoader					():Boolean { // If it is a content loader or a url loader (if its binary or text basically)
			return							_isLoader;
		}
		public function getLoaderInfo				():LoaderInfo {
			return							_contentLoaderInfo;
		}
		public function getUrl					():String {
			return							_url;
		}
		public function getId						():String {
			return							_id;
		}
		public function checkId					(id:String):Boolean {
			return							id == _id;
		}
		public function isKilled():Boolean {
			return _killed;
		}
		// HARAKIRI ////////////////////////////////////////////////////////////////////////////////
		public function cleanup():void {
			if (_killed) return; // Ibj has already been killed
			_killed = true;
			killLoading();
			_requestHeaders = null; _request.requestHeaders = null; _request.data = null; _fileType = null; _url = null; _dataObject = null; _anticache = false; _isPost = false; _loaderListener = null; _listener = null;
			_contentLoaderInfo = null;
			_isSuperLoaderQueue = _loading = _isError = _loaded = _isLoader = false;
			_bytesLoaded = _bytesTotal = _percent = _width = _height	= 0;
			_funcPostfix = "";
			
		}
		public function harakiri					() {
			cleanup							();
		}
		private function killLoading					() {
			try {
				if (_loader == _contentLoader) { // Kill Loader
					killListeners				(_loader.contentLoaderInfo);
					_loader.close				();
					_loader.unload				();
					_loader.unloadAndStop			();
				}
				else if (_loader == _urlLoader || _loader == _urlStream) { // Kill URLLoader
					killListeners				(_loader);
					_loader.close				();
				}
			}
			catch(e){}
		}
		private function killListeners					(o:Object) {
			o.removeEventListener					(Event.OPEN, onLoadStartLoader);
			o.removeEventListener					(Event.INIT, onLoadInitLoader);
			o.removeEventListener					(Event.COMPLETE, onLoadCompleteLoader);
			o.removeEventListener					(IOErrorEvent.IO_ERROR, onLoadErrorLoader);
			o.removeEventListener					(ProgressEvent.PROGRESS, onLoadProgressLoader);
			o.removeEventListener					(SecurityErrorEvent.SECURITY_ERROR, onLoadErrorLoader);
		}
		// LISTENERS ////////////////////////////////////////////////////////////////////////////////
		// LOADER
		public function onLoadStartLoader					(e:Event) {
			if (_killed)								return;
			_loading								= true;
			if (_verbose)							Debug.debug(_debugPrefix, EVT_START+_funcPostfix, _loader, _url);
			UCode.broadcastEvent						(_listener, EVT_START+_funcPostfix, [this])	
			if (UCode.exists(_loaderListener))				_loaderListener.onLoadStart(this);
		}
		public function onLoadInitLoader					(e:Event) {
			if (_killed)								return;
			if (_verbose)							Debug.debug(_debugPrefix, EVT_INIT+_funcPostfix);
			if (_contentLoaderInfo) {
				_width							= _contentLoaderInfo.width;
				_height							= _contentLoaderInfo.height;
			}
			UCode.broadcastEvent						(_listener, EVT_INIT+_funcPostfix, [this])			
			if (UCode.exists(_loaderListener))				_loaderListener.onLoadInit(this);	
		}
		public function onLoadCompleteLoader				(e:Event) {
			if (_killed)								return;
			if (_verbose)							Debug.debug(_debugPrefix, EVT_COMPLETE+_funcPostfix);
			_loading								= false;
			_loaded								= true;
			UCode.callMethod						(_listener, EVT_COMPLETE+_funcPostfix, this);
			if (UCode.exists(_loaderListener))			_loaderListener.onLoadComplete(this);
			if (_isSuperLoaderQueue)					SimpleQueueLoader.onLoadCompleteLoader(this);
			completeLoadingProcess					();
		}
// 		public function onLoadHttpStatus					(e):void {
// 			
// 		}
		public function onLoadErrorLoader(e:ErrorEvent) {
			if (_killed)								return;
			_loading								= false;
			_loaded								= false;
			_isError								= true;
			// if (_verbose)							
			Debug.debug(_debugPrefix, "ERROR:",_funcPostfix,e); // This is always triggered
			UCode.callMethod(_listener, EVT_ERROR+_funcPostfix, this, String(e));
			if (UCode.exists(_loaderListener)) _loaderListener.onLoadError(this);
			if (_isSuperLoaderQueue) SimpleQueueLoader.onLoadCompleteLoader(this);
			completeLoadingProcess();
		}
		public function onLoadProgressLoader				(e:ProgressEvent) {
			if (_killed)								return;
			_bytesLoaded							= e.bytesLoaded;
			_bytesTotal							= e.bytesTotal;
			_percent								= Math.round(UCode.calculatePercent(e.bytesLoaded, e.bytesTotal));
			if (_verbose)							Debug.debug(_debugPrefix, EVT_PROGRESS+_funcPostfix,e.bytesLoaded,_percent,"%");
			UCode.broadcastEvent						(_listener, EVT_PROGRESS+_funcPostfix, [this]);			
			if (UCode.exists(_loaderListener))				_loaderListener.onLoadProgress(this);
		}
		// UTY ///////////////////////////////////////////////////////////////////////////////////
		// STATIC - LOAD OBJECT INITIALIZE
		private function getLoaderByFileType			(fileType:String):Object {
			if (_forceURLStream) return _urlStream;
			if (_dataLoaderNames.toLowerCase().indexOf(fileType.toLowerCase()) != -1) return _urlLoader;
			else if (_byteLoaderNames.toLowerCase().indexOf(fileType.toLowerCase()) != -1) return _contentLoader;
			else return _urlStream;
		}
		private function getLoaderByFileName(fileName:String):Object {
			// Get filename extension
			var a:Array = fileName.split(".");
			return getLoaderByFileType(a[a.length-1].toLowerCase()); 
		}
		// LOAD COMPLETE, GARBAGE COLLECTION, ETC:
		private function completeLoadingProcess() {
			// Now, I have to setup in UGlobal the libraries for the app
			//setTimeout							(suicide, 50);
			UExec.time(0.5, suicide); // suicide after half second in order not to overlap with other operations from outside on load complete (some componenets do operations on next frame)
			//UExec.next(suicide);
		}
		public function suicide() {
			UMem.kill_SQLObject(this);
		}
	}
	
	
	
	
	
}