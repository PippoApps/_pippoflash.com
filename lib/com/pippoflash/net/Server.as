// SERVER CLASS //////////////////////////////////////////////////////////////////////////////////////
// _executing._status = IDLE, EXECUTING, ERROR, COMPLETE
package com.pippoflash.net {
	import flash.net.URLVariables;
	import flash.system.Security;
	import com.pippoflash.net.QuickLoader;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	import com.pippoflash.utils.*;
	import com.pippoflash.string.JsonMan;
	
	public dynamic class Server {
// VARIABLES ////////////////////////////////////////////////////////////////////////////////////
		// CONSTANTS ///////////////////////////////////////////////////////
		public static var _verbose				:Boolean = true;
		public static var _traceFeedback			:Boolean = true;
		public static var _traceErrors			:Boolean = true;
		protected static var _debug				:Boolean = true;
		protected static var _debugServer			:Boolean = false; // If true, it pops up all server errors
		protected var _callLaunchCommand		:String = "onServerCall"; // Calls on main listener - EVERYTIME A COMMAND IS LAUNCHED			onServerCall(commandObj);
		protected var _callCommandFeedback		:String = "onServerFeedback"; // Calls on main listener - EVERYTIME A FEEDBACK IS RECEIVED 		onServerFeedback(feedback);
		protected var _callNetworkError			:String = "onServerNetworkError"; // Calls on main listener - ON NETWORK ERROR					onServerNetworkError(error:String);
		protected var _callSetLoader				:String = "setMainLoader"; // Calls on main listener - IF A LOADER UFNCTION IS SET 				setMainLoader(true, "text");
		protected var _callServerMessage			:String = "onServerMessage"; // Calls on main listener - EACH TIME A SERVER MESSAGE IS RECEIVED		onServerMessage("msg", "alert");
		protected var _callCommandError			:String = "onCommandMalformed"; // Calls on main listener - EACH TIME A COMMAND MISSES PARAMETERS	onCommandMalformed(commandObj);
		protected var _callFeedbackError			:String = "onCallError"; // Calls on main listener - EACH TIME AN ERROR IS RECEIVED FROM SERVER		onCallError(feedback);
		protected var _callFeedbackSuccess		:String = "onCallSuccess"; // Calls on main listener - EACH TIME A SUCCESSFUL CALL RETURNS FROM SERVER onCallSuccess(feedback);
		public var _workLocally					:Boolean = false; // If it has to work locally, url is constructed differently
		protected var _useULoader				:Boolean = false; // Uses ULoader main loading process, therefore I can connect to main loader
		protected var _debugPrefix				:String = "Server";
// 		protected var _feedbackFormat			:String = "XML"; // JSON, XML, VARS, STRING, FILE - This is the formatting of returned object
		protected var _defaultCommandObject		:Object = { // This stores the default values for each command, and preparees all necessary parameters
			_encodeParams:true,				// All params except url keywords are uri encoded
			_anticache:false, 				// This can block _alwaysAnticache function
			_format:"XML",					// This is the format of the call: JSON, XML, STRING, VARS, FILE - Depending on value a different interpretation is done
			_loadText:"",					// This is used as loader text if default loader is activated
			_hasLoader:true, 				// This shows loader and inhibits clicks
			_okFunc:UCode.dummyFunction, 	// Function to call on interpreted success
			_errorFunc:UCode.dummyFunction, 	// Function to call on intrpreted error
			_networkErrorFunc:UCode.dummyFunction, // Function to call on network error
			_status:"IDLE", 					// Initial status of command
			_paramsGet:null, 				// Parameters to be added as GET
			_paramsPost:null,				// Parameters to be added as POST
			_requestHeaders:null,				// Request headers to be launched (useful for PUT and DELETE as stated in  http://cambiatablog.wordpress.com/2010/08/10/287/)
			_paramsUrl:null,					// Parameters to be inserted in the url api in square brackets http://[paramName] + {paramName:"pippo"} = http://pippo
			_loaderObject:null,				// Reference to the command loader object
			_id:null,						// Unique id of command - Random if not defined
			_feedback:null,					// Direct link to feedback content - SYSTEM
			_isError:false,					// Marks if it was an API error - SYSTEM
			_error:null,						// Stores ERROR DATA if an error is received
			_message:null,					// Message to broadcast - SYSTEM
			_messageType:null,				// Type of message to broadcast - SYSTEM
			_data:null,						// Direct reference to the data node or object - SYSTEM
			_command:null,					// If this is defined, it will call a special command - SYSTEM
			_isUpload:false,					// If this is true, I am trying to upload a file
			_addFedbackToData:false			// If true, adds metadata feedback to data node
		}; 
		protected var _mandatoryCommandParameters:Array = ["_okFunc", "_errorFunc"]; // List to check. If a command object does not have one of those params, will trigger an error
		// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		protected static var _servers			:Array = []; // Stores a list of Server instances
		protected var _listener					:*; // The listener for main commands, such as messages, etc
		protected var _api					:String; // Stores the main URL of the API
		protected var _externalCheckMethod		:Function; // If htis is defined, check for API feedback is done externally
		// USER DEFINED /////////////////////////////////////////////////////////
// 		protected var _launchCommandFunc		:Function = launchStandardCommand; /* This stores the function I have to call to call a method (can be url variables, etc.) */
		protected var _jsonDecodeError			:Object = {success:false, error:{code:-99, text:"Server feedback cannot be intepreted"}}; // If json returned is failed to decode, return this as error message
		protected var _xmlDecodeError			:XML = new XML("<FEEDBACK success='false'><ERROR code='internal default'>Server feedback syntax is incorrect. Impossible to parse feedback object.</ERROR><MESSAGE>There was an error communicating with server. Please try again.</MESSAGE></FEEDBACK>"); // If returned XML is impossible to parse, this is the message I get.
		// FLASHVARS ///////////////////////////////////////////////////////
		// DATA HOLDERS //////////////////////////////////////////////////////////
		// MARKERS //////////////////////////////////////////////////////////////
		// REFERENCES //////////////////////////////////////////////////////
		// COMMAND MANAGEMENT ////////////////////////////////////////////
		protected var _commandList				:Array = new Array(); // Stores the list of commands
		protected var _serverBusy				:Boolean = false; // If server is executing a command
		protected var _executing				:Object; // The command actually executing
		// STATIC UTY
		protected static var _x					:XML;
		protected static var _counter			:int;
		protected static var _o				:Object;
		protected static var _a				:Array;
		protected static var _n				:Number;
		protected static var _s					:String;
		protected static var _i					:int;
		protected static var _sqlo				:SimpleQueueLoaderObject;
// INIT ////////////////////////////////////////////////////////////////////////////////////////
		public function Server					(listener:*, api:String, externalCheckMethod:Function=null):void { // Here it creates a server instance connected to an API only
			if (USystem.isSwf()) { // These calls trigger an error in AIR
				Security.allowDomain			("*");
				Security.allowInsecureDomain	("*");
			}
			JsonMan.init					();
			_listener						= listener;
			_api							= api;
			_externalCheckMethod				= externalCheckMethod;
			_debugPrefix					+= "-" + _servers.length;
			_servers.push					(this);
			Debug.debug						(_debugPrefix, "Created",listener," ---> ",_api);
		}
// SETUP METHODS //////////////////////////////////////////////////////////////////////////
		public function setErrorFunction			(f:Function) {
			_defaultCommandObject._errorFunc	= f;
		}
		public function setNetworkErrorFunction	(f:Function) {
			_defaultCommandObject._networkErrorFunc = f;
		}
		public function setDefaultParameter		(s:String, val:*):void {
			_defaultCommandObject[s]			= val;
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// SEND COMMAND METHODS ///////////////////////////////////////////////////////////////////////
		public function sendCommand			(commandParams:Object) {
			// This one adds a command oto the command queue - See parameters in default object
			if (prepareCommandObject(commandParams)) { // If command is well formed add it to commands list otherwise broadcast error
				_commandList.push			(commandParams);
				checkNextCommand			();
			}
			else {
				UCode.callMethod			(_listener, _callCommandError, commandParams);
				Debug.error				(_debugPrefix, "WARNING: Command aborted because not well formed.");
			}
		}
	// STOP COMMANDS METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function skipCommand				():void {
			// Skips actual command
			if (isBusy())					stopRunningCommand();
			proceedAfterFeedback				();
		}
		public function resetCommads			():void {
			Debug.debug					(_debugPrefix, "Resetting all commands and STOP.");
			// Resets all commands
			if (isBusy())					stopRunningCommand();
		}
			private function stopRunningCommand	():void {
				if (_executing._loaderObject)		UMem.kill_SQLObject(_executing._loaderObject);
				disposeCommandObject			();
				_commandList				= new Array();
				_serverBusy				= false;
			}
			private function stopCommandObject	():void {
				// TO BE DONE - THIS STOPS A CURRENTLY RUNNING SERVER METHOD
			}
	// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function isBusy					():Boolean {
			return						_serverBusy;
		}
		public function getUrl					(par:Object):String { // Returns a server correctly formatted URL from parameters
			return						getCommandUrl(par);
		}
// CHECK COMMANDS QUEUE /////////////////////////////////////////////////////////////////
		private function prepareCommandObject		(o:Object):Boolean {
			UCode.setDefaults				(o, _defaultCommandObject); // Set default parameters for the ones not defined
			var ok						:Boolean = true;
			for each (_s in _mandatoryCommandParameters) {
				if (!o[_s]) {
					Debug.error			(_debugPrefix, "WARNING: missing parameter:",_s);
					ok					= false;
				}
			}
			return						ok;
		}
			private function checkNextCommand		() {
				if (_serverBusy)					return; // If server is already executing a command, then I can't execute another one
				if (_commandList.length > 0)			executeNextCommand();
			}
			private function executeNextCommand		() {
				_serverBusy					= true; // Launch command execution
				_executing						= _commandList.pop(); // Get first command in the queue
				_executing._status				= "EXECUTING"; // Set status
				if (_executing._hasLoader) {
					UCode.callMethod(_listener, _callSetLoader, true, _executing._loadText); // Setup loader
				}
				launchServerCall					();
			}
		private function proceedAfterFeedback			():void {
			_serverBusy						= false; 
			checkNextCommand					();
		}
// DO LAUNCH SERVER CALL ////////////////////////////////////////////////////////////////////
		private function launchServerCall			() {
			// Proceed, and call command. If command is listed in a special call function, call that function instead.
			UCode.callMethod				(_listener, _callLaunchCommand, _executing);
			if (_executing._command) { // Call custom command as stored in _command
				Debug.debug				(_debugPrefix, "Calling custom command:",_executing._command);
				this[_executing._command]		(); // This is good for extending this class, subclasses can have specific methods
			}
			else							launchCommand(); // Otherwise, proceed with standard command (as defined in static variables)
		}
// CALL STANDARD COMMAND //////////////////////////////////////////////////////////////////////
// All methods down here are voerridable or can be called from extensions
		// 1 - make url, 2 - add get vars, 3 - add post vars
		protected function launchCommand		() {
			_executing._formattedUrl			= getCommandUrl(_executing);
			if (_verbose)					Debug.debug(_debugPrefix, _executing._formattedUrl);
			if (_executing._paramsPost)			doCallCommandPost();
			else							doCallCommand();
		}
			public function getCommandUrl		(o:Object):String { // this can be called from the outside to construct urls for other purposes
				// Create url inserting params if necessary
				if (_workLocally)				return prepareLocalUrl(o);
				var u						:String = o._paramsUrl ? UText.insertParams(_api, o._paramsUrl) : _api;
				// Add get params to url if defined
				if (o._paramsGet)			u = addGetParamsToString(u+(u.indexOf("?") < 0 ? "?" : "&"), o._paramsGet); // If there is already a ?, only & will be added
				if (o._anticache)				u += (u.indexOf("?") < 0 ? "?" : "&")+"__anticache__="+Math.random()+""+Math.random(); // If there is already a ?, only & will be added
				return					u;
			}
				private function prepareLocalUrl	(o:Object):String { // This has to be changed at will according to the situation
					var u					:String = "_data/" + o._paramsUrl.resource.split("/").join("_");
					Debug.debug			(_debugPrefix, "Using local data URL:",u);
					return				u;
				}
			protected function addGetParamsToString(u:String, p:Object):String {
				Debug.listObject				(p, "VAR");
				if (p._encodeParams)			for (_s in p) u += _s + "=" + encodeURIComponent(p[_s]) + "&";
				else						for (_s in p) u += _s + "=" + p[_s] + "&";
				return					u.substr(0,u.length-1); // Remove last & and return 
			}
			protected function doCallCommand		():void {
				_sqlo						= QuickLoader.loadFile(_executing._formattedUrl, this, "StandardCommand", false, _executing._format.toLowerCase(), _executing._requestHeaders);
				checkConnectLoader			();
			}
			protected function doCallCommandPost	():void {
				Debug.debug				(_debugPrefix, "Launching POST variables call...");
				var paramsString			:String = addGetParamsToString("", _executing._paramsPost);
				_sqlo						= QuickLoader.loadFilePostVars(_executing._formattedUrl, this, "StandardCommand", new URLVariables(paramsString), false, _executing._format.toLowerCase(), _executing._requestHeaders);
				checkConnectLoader			();
			}
				protected function checkConnectLoader():void {
					if (_useULoader && _executing._hasLoader) ULoader.connectLoader(_sqlo);
				}
// POST-PROCESS FEEDBACK ///////////////////////////////////////////////////////////////////////////////////////
		private function postProcessFeedback		(o:SimpleQueueLoaderObject):void {
			// Called after every feedback
			UCode.callMethod				(_listener, _callCommandFeedback, o);
			// Prepare processing object
			_executing._loaderObject			= o;
			// Proceed with processing
			removeLoader					();
			analyzeFeedback					();
			postFeedbackOperations			();
			proceedAfterFeedback				(); // Queue
		}
			private function removeLoader		():void {
				if (_executing._hasLoader)		UCode.callMethod(_listener, _callSetLoader, false);
			}
			private function analyzeFeedback		():void {
				// Here all feedback analysis happens, and methods are called
				if (_externalCheckMethod) { // Check for external feedback analisys
					Debug.debug			(_debugPrefix, "External feedback analisys method is processing feedback...");
					_externalCheckMethod		(_executing);
				}
				else { // No external feedback analisys, using internal defaults
					this["analyzeFeedback_"+_executing._format]();
				}
				// Here after analysis is done and object is processed, I proceed with standard checks
				// Trace output
				if (_traceFeedback)			Debug.debug(_debugPrefix, "Feedback: <"+_executing._formattedUrl+">\n",_executing._feedback is XML ? _executing._feedback.toXMLString() : _executing._feedback is Object ? Debug.object(_executing._feedback) : _executing._feedback);
				// Check for error and perform broadcasts
				if (_executing._isError) { // Broadcast error
					if (_traceErrors)			Debug.error(_debugPrefix, "ERROR:",_executing._feedback is XML ? _executing._feedback.toXMLString() : _executing._feedback);
					UCode.callMethod		(_listener, _callFeedbackError, _executing);
					_executing._errorFunc		(_executing._feedback); // Call functiuon listener
				}
				else	{ // Broadcast success
					UCode.callMethod		(_listener, _callFeedbackSuccess, _executing._error);
					_executing._okFunc		(_executing._data);
				}
				// Check for message - MOVED DOWN SINCE OTHER ACTIONS MAY COVER MESSAGE PROMPT
				if (_executing._message)		UCode.callMethod(_listener, _callServerMessage, _executing._message, _executing._messageType);
			}
			private function postFeedbackOperations():void {
				// this happens at the end of any feedback, any kind, any status
				disposeCommandObject			();
			}
				private function disposeCommandObject	():void {
					for each (_s in _executing)		_executing[_s] = null;
					_executing					= null;
				}
		// Methods to operate on received feedback object - used internally or externally
		public function feedbackSetString			():void { // Converts loader object to string
			_executing._feedbackString			= _executing._loaderObject.getContent();
		}
		public function feedbackSetError			(errorMessage:String="[Server default message] Server error received. No info provided."):void {
			_executing._isError				= true;
			_executing._error				= errorMessage;
		}
		// Processes network error
		private function processNetworkError		(o:SimpleQueueLoaderObject, error:String):void {
			Debug.error					(_debugPrefix, "NETWORK ERROR: " + error);
			removeLoader					();
			_executing._networkErrorFunc		();
			trace("CHIAMO METODO NETWORK ERROR SU",_listener,_callNetworkError);
			UCode.callMethod				(_listener, _callNetworkError, error);
			postFeedbackOperations			();
			proceedAfterFeedback				(); // Queue
		}
// ANLYSIS UTY ///////////////////////////////////////////////////////////////////////////////////////
		// this functions here prepare the feedback object according to the type of encoding
				private function analyzeFeedback_JSON():void {
					feedbackSetString				(); // Grab string from content
					try { // Here I must do as much as I can to trigger errors if feedback is not formatted the way I like
						_executing._feedback	= JsonMan.decode(_executing._feedbackString);
						_executing._data		= _executing._feedback.data;
						// Check for error is done only if JSON parsing succeeds
						if (!UCode.isTrue(_executing._feedback.success)) {
							feedbackSetError				(_executing._feedback.error);
						}
					}
					catch (e) {
						Debug.error		(_debugPrefix, "Cannot parse DATA node, or JSON decoding error. Feedback is:\n",_executing._loaderObject.getContent());
						_executing._isError	= true;
						_executing._feedback	= _jsonDecodeError;
					}
					// Check for message
					if (_executing._feedback.message) {
						_executing._message 	= _executing._feedback.message;
						_executing._messageType = _executing._isError ? "error" : "alert";
					}
				}
				private function analyzeFeedback_XML			():void {
					try { // Here I must do as much as I can to trigger errors if feedback is not formatted the way I like
						_executing._feedback	= new XML(_executing._loaderObject.getContent());
						_executing._data		= _executing._feedback.DATA[0];
						// Here I execute some random checks to trigger error
						if (_executing._feedback.name() != "FEEDBACK" || !UXml.hasFullAttribute(_executing._feedback, "success")) setDefaultXmlError();
					}
					catch (e) {
						setDefaultXmlError	();
					}
					// Check for error
					if (!UCode.isTrue(_executing._feedback.@success)) {
						feedbackSetError					(_executing._feedback.ERROR[0]);
// 						_executing._isError	= true;
// 						_executing._error		= _executing._feedback.ERROR[0];
					}
					// Check for message
					if (_executing._feedback.MESSAGE.length()) { /* TO BE CONTROLLED */
						_executing._message	= _executing._feedback.MESSAGE[0].toString();
						_executing._messageType = _executing._isError ? "error" : "alert"; //UXml.hasAttribute(_executing._feedback.MESSAGE[0], "type") ? _executing._feedback.MESSAGE[0].@type : "alert";
					}
				}
					private function setDefaultXmlError():void {
						Debug.error		(_debugPrefix, "Cannot parse feedback. Reverting to internal default error. Feedback received is:",_executing._loaderObject.getContent());
						_executing._feedback	= _xmlDecodeError;
					}
				private function analyzeFeedback_STRING():void {
					// Do nothing, just return the string
					_executing._feedback		= _executing._loaderObject.getContent();
					_executing._data			= _executing._feedback;
				}
				private function analyzeFeedback_VARS():void {
					// TO BE IMPLEMENTED
					_executing._feedback		= _executing._loaderObject.getContent();
					_executing._data			= _executing._feedback;
				}
				private function analyzeFeedback_FILE():void {
					// Do nothing, just return the content
					_executing._feedback		= _executing._loaderObject.getContent();
					_executing._data			= _executing._feedback;
				}
// GENERAL UTY ///////////////////////////////////////////////////////////////////////////////////////
		public function isError					(xml:XML):Boolean {
			return						!UCode.isTrue(xml.@success);
		}
		public function checkForMessage			(xml:XML):* {
			return						xml.MESSAGE.length() ? xml.MESSAGE[0].toString() : null;
		}
		public function getDefaultError			():XML {
			return						_xmlDecodeError;
		}
		public function setDefaultError			(xml:XML):void {
			_xmlDecodeError					= xml;
		}
// COMMANDS FEEDBACK LISTENERS //////////////////////////////////////////////////////////////////
		public function onLoadStartStandardCommand(o:SimpleQueueLoaderObject) {
			// Avoid UCode trace that method does not exists
		}
		public function onLoadProgressStandardCommand(o:SimpleQueueLoaderObject) {
			// Avoid UCode trace that method does not exists
		}
		public function onLoadCompleteStandardCommand(o:SimpleQueueLoaderObject) {
			if (isNotMyLoaderObject(o)) 			return;  // If SQLO which continues to work even after killed calls it, prevent if its not the right one
			postProcessFeedback				(o);
		}
		public function onLoadErrorStandardCommand	(o:SimpleQueueLoaderObject, error:String) {
			if (isNotMyLoaderObject(o)) 			return;  // If SQLO which continues to work even after killed calls it, prevent if its not the right one
			processNetworkError				(o, error);
		}
			private function isNotMyLoaderObject	(o:SimpleQueueLoaderObject):Boolean {
				return 					(!isBusy() || o._url != _executing._formattedUrl);
			}
// NON-STANDARD COMMANDS ///////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////
// CHECK FOR STATUSES ////////////////////////////////////////////////////////////////////
// GET URLS //////////////////////////////////////////////////////////////////////////////
// CONFIG MANAGEMENT //////////////////////////////////////////////////////////////////////
	}
	
	
}


/* ________________________________________________________
All AS files and libraries included in the domain com.pippoflash.*
Are open.source libraries developed by Filippo Gregoretti, and are therefore not copyrightable.
They can be used in commercial projects but must be left free for re-distribution and usage.
They go with all MovieClips included in the .fla or .xfl document, in the folders:
- PippoFlash.com - Framework
- PippoFlash.com - Components
All movieclips and assets within those folders in the source flash document (fla or xfl) 
are open source anc dan be used in commercial projects, but cannot be copyrighted.
__________________________________________________________ */