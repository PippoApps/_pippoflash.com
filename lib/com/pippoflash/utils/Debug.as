/* Debug - ver 0.01 - Filippo Gregoretti - www.pippoflash.com
	Last update 12 dec 2009.

*/

package com.pippoflash.utils {

	import com.pippoflash.framework.PippoFlashEventsMan;
	import flash.geom.*;
	import flash.display.*;
	import flash.utils.*;
	import flash.external.*;
	import com.pippoflash.utils.*;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;

	
	public class Debug {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		//public static const EVT_ERROR:String = "onErrorTriggered";
		private static const REST_JOINER:String = ", "; // Joins ...rest elements
		public static const EVT_ABOUT_TO_RESET:String = "onAboutToResetConsole"; // When console is about to be reset. BEFORE it is reset.
		//public static const EVT_PARTIAL_ENTRY_SIZE_REACHED:String = "onPartialEntrySizeReached"; // When partial entries console max char size has been reached
		static public var PARTIAL_ENTRY_MAX_CHAR_SIZE:uint = 1024;
		// Size in textformats is the size to be ADDED to size retrieved from console
		private static const TEXTFORMAT_SOURCE:Object = {ERROR:{color:0xff0000}, ALL:{color:0x444444}, WARNING:{color:0x0000ff}, SCREAM:{bold:true, color:0x000000}}; // Colors for type of messages in console
		private static const EVT_UPDATED_PREFIX:String = "onNewDebugLine"; // This gets triggered when you add a listener to an event with setListenerFor(_debugPrefix:String, f:Funtcion); - This sets ONE listener for each debugPrefix
		private static const LINE_SOURCE:String = "-------------------------------------------<[ID]>-------------------------------------------";
		private static const ERROR_DISPLAY_PREFIX:String = "\n**********************************************************************\nERROR |\t"; // Prefix error line
		private static const ERROR_DISPLAY_POSTFIX:String = "\n**********************************************************************\n"; // Postfix after entire error line
		private static const WARNING_DISPLAY_PREFIX:String = "\n---------------------------------------------------------\nWARNING |\t"; // Prefix error line
		private static const WARNING_DISPLAY_POSTFIX:String = "\n---------------------------------------------------------\n"; // Postfix after entire error line
		private static const OBJECT_STRING_EOF:String = ""; // Set this to "\n" to have line feed on each object property
		private static const _debugPrefix:String = "Debug";
// 		private static const DUMMY_FUNCTION			:Function = new Function():void {}; // Dummy function to be used (without ...rest to allocate an array)
		// SWITCHES
		private static var MAXLINES:uint = 2000;
		private static var MAXCHARSCHECK:uint = 20; // Maximum amounts of chars to check for a ">" to convert to ID
		private static var EXPORT_TO_CONSOLE:Object = {ALL:false, ERRORS:false, WARNING:false}; // What to export to JS console. Defaults to false. Must be set with set export to console.
		// UTY
		private static var _s:String;
		private static var _i:int;
		private static var _length:int;
		private static var _counter:int = 0;
		// FILTERS
		private static var _filterIn:Vector.<String> = new Vector.<String>(); // A comma separated list of trace to be filtered (if this is active, only senders in this list will be displayed)
		private static var _filterOut:Vector.<String> = new Vector.<String>(); // Comma separated list of sender to NOT display
		// SYSTEM
		private static var _filterObject:Object = new Object(); // Divides all by Prefix
		private static var _prefixListeners:Object = {}; // Stores the entrie messages by ID only
		private static var _allEntries:Vector.<String> = new Vector.<String>(); // Stores the entire sequence of entries
		private static var _partialEntries:Vector.<String> = new Vector.<String>(); // Stores the entire sequence of entries
		static private var _partialEntriesCharLength:uint;
		private static var _warnings:Vector.<String> = new Vector.<String>(); // Stores the entire sequence of entries
		private static var _errors:Object = new Object(); // Divides all by prefix, traces error
		private static var _mainApp:MovieClip; // this is needed for monster debugger
		private static var _textFormats:Object; //  = {ALL:null, ERROR:null, WARNING:null};
		private static var _mainPrefix:String = ""; // This is when a PF app is loaded in another PF app to distinguish traces...
		// HOLDERS
		private static var _debugConsole:*; // Stores the address of a debug console to use with appendText();
		// FUNCTION SHORTCUTS
		private static var d:Function = debug;
		private static var go:Function = debug;
		private static var t:Function = debug;
		//private static var _debugToExternalMethod:Function = UCode.dummyFunction; // This can be used to browser console, or any other method
		// MARKERS
		static private var _addTimer:Boolean = false;
		private static var _initialized:Boolean;
		static private var _traceOut:Boolean = true; // If tracing output messages
		// SPECIAL METHODS
		static private var _additionalMethods:Vector.<Function> = new Vector.<Function>(); // Additional methods to be called on trace
		static private var _idsToExcludeFromAdditionalMethods:Vector.<String> = new Vector.<String>(); // These IDs will be excluded from tracing additional methods
		// FILTERS - WHAT TO TRACE OR NOT TO TRACE - JUST SET THOSE VARIABLES EXTERNALLY
		static public var _showOnlyIDSContaining:Vector.<String>; 
		static public var _hideIDSContaining:Vector.<String>; /* not yet implemente */
		//private static var DEBUG:Boolean = true; // Set from MainApp when present. defaults to true.
// DUMMIES //////////////////////////////////////////////////////////////////////////////
// 		public static var _dummyTextField				:TextField = new TextField();
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init(c:MovieClip=null):void { // Called by UGlobal immediately, before stage
			// This initializes system stuff before stage is allowed
			// Create textformats
			_textFormats = {};
			for (_s in TEXTFORMAT_SOURCE) {
				_textFormats[_s] = UText.makeTextFormat(TEXTFORMAT_SOURCE[_s]);
			}
			
		}
		public static function initOnStage(c:MovieClip=null):void { // Called by UGlobal once stage is set
			_mainApp = c;
			if (_mainApp.BLOCK_CONSOLE) { // MainApp is in DEPLOY state, I switch off all debugging functions
				debug("DEBUG", "Console blocked. Now on only errors will be traced.");
				debug = UCode._dummyFunction;
				object = UCode._dummyFunction;
			}
			_initialized = true;
			// Reset debug console
			if (_debugConsole) setupConsole(_debugConsole);
			// Setup debugging
			if (_mainApp && _mainApp.isDebug) debugDebugging = _mainApp.isDebug() ? doDebugDebugging : UCode.dummyFunction; // Switch off debug methods in deploy mode
		}
		//static public function outputToExternalMethod(method:Function, exportLevel:uint=0, comment:String="External Method", switchOffInternalTrace:Boolean=false):void {
			//EXPORT_TO_CONSOLE.ALL = exportLevel == 0;
			//EXPORT_TO_CONSOLE.WARNING = exportLevel <= 1;
			//EXPORT_TO_CONSOLE.ERRORS = exportLevel <= 2;
			//_debugToExternalMethod =  method;
			//_traceOut = !switchOffInternalTrace;
			//debug(_debugPrefix, "Extra output set to: " + comment + " at level " +  object(EXPORT_TO_CONSOLE));
			//if (exportLevel > 2) warning(_debugPrefix, "Nothing will be logged. Set log level to less than 3");
		//}
		//public static function outputToBrowserConsole(exportLevel:uint, switchOffInternalTrace:Boolean=false):void { // 0 = all, 1 = errors + warnings, 2 = errors only, >= 3 = nothing
			//if (ExternalInterface.available) {
				//EXPORT_TO_CONSOLE.ALL = exportLevel == 0;
				//EXPORT_TO_CONSOLE.WARNING = exportLevel <= 1;
				//EXPORT_TO_CONSOLE.ERRORS = exportLevel <= 2;
			//}
			//else {
				//EXPORT_TO_CONSOLE.ALL = false;
				//EXPORT_TO_CONSOLE.WARNING = false;
				//EXPORT_TO_CONSOLE.ERRORS = false;
				//warning(_debugPrefix, "Cannot activate exportToConsole() since ExternalInterface is not available.");
			//}
			//_debugToExternalMethod = exportLevel < 3 ? outputToConsole : UCode.dummyFunction;
			//_traceOut = !switchOffInternalTrace;
			//debug(_debugPrefix, "Output to browser console status: " + object(EXPORT_TO_CONSOLE));
		//}
		public static function setupConsole(t:*):void { // TextField or Console Component. As long as it has TextField methods.
			// This sets up a textfield to use as debug
			traceDebug("Debug console initialized on "+t+".");
			_debugConsole = t;
			if (!_initialized) {
				// Debug not yet initialized, therefore this will be called again by init
				return;
			}
			// Update textformats to add size to regular size
			var txtSize:Number = _debugConsole.getTextFormat().size;
			for (_s in TEXTFORMAT_SOURCE) {
				if (TEXTFORMAT_SOURCE[_s].size) _textFormats[_s].size = txtSize + TEXTFORMAT_SOURCE[_s].size;
			}
// 			UGlobal.setDebugConsole				(t);
		}
		public static function setMainPrefix(p:String=""):void {
			_mainPrefix = p;
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////		
	// CONSOLE
		static public function showConsole():void {
			if (_debugConsole) {
				if (_debugConsole.hasOwnProperty("show")) _debugConsole.show();
			}
		}
		static public function hideConsole():void {
			if (_debugConsole) {
				if (_debugConsole.hasOwnProperty("hide")) _debugConsole.hide();
			}
		}
		static public function showConsoleRectangle(r:Rectangle):void {
			showConsole();
			if (_debugConsole) {
				//trace("RESIZZOOOO", _debugConsole);
				//_debugConsole.resize(100, 100);
				if (_debugConsole.hasOwnProperty("resize")) _debugConsole.resize(r.width,r.height);
			}
		}
	// DEBUG
		static public function debugObjectToJson(id:String, comment:String, o:Object):void {
			var s:String;
			try {
				s = JSON.stringify(o);
			}
			catch (e:Error) {
				Debug.error(_debugPrefix, "debugObjectToJson() Error stringifying Object. Using regular debug.");
				s = Debug.object(o);
			}
			windowDebug("[Launched by Debug.throwError] " + id, comment + "\n" + s);
		}
		static public function fillClipboardText(newLine:String = "\n"):void { // Puts entire console content into clipboard
			if (!USystem.isAir()) {
				Debug.error(_debugPrefix, "Clipboard cannot be filled in user action. fillClipboardText() can only be called in AIR.");
				return;
			}
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, _allEntries.join(newLine));
			Debug.warning(_debugPrefix, "Clipboard filled with debug data.");
		}
		public static var debug:Function = doDebug;
		public static function doDebug(id:String, ...rest):void {
			windowDebug(id, rest.join(" "));
		}
		// ERROR
		public static var error:Function = processError;
		static public function throwError(id:String, ...rest):void {
			_s = rest.join(REST_JOINER);
			throw new Error(id + "> " + _s);
			error(id, _s);
		}
		// WARNING
		public static var warning:Function = processWarning;
		// DEBUG IF DEBUG
		static public var debugDebugging:Function = doDebugDebugging; // This is set to normal debug only if _mainApp.isDebug() (or default if no mainapp)		
		static private function doDebugDebugging(id:String, ...rest):void {
			windowDebug("DEBUG|" + id, rest.join(" "));
		}
		// SCREAM
		public static function scream(id:String, ...rest):void { // this traces 2 highlighters so that I cna see immediately the highlight!!!
			var initIndex:uint;
			if (_debugConsole) initIndex = _debugConsole.length;
			forceDebug(id, ">>>>>>---------------------------------------->>>>>>>>\n" + rest.join(" "));
			if (_debugConsole && _textFormats) {
				try { // This sometimes triggers an out of index error
					_debugConsole.setTextFormat(_textFormats.SCREAM, initIndex, _debugConsole.length);
				}
				catch (e:Error) {
					// Her eI can't use a Debug.error or will trigger an infinite loop
					//trace(_debugPrefix + " ERROR SETTING TEXTFORMAT");
				}
			}
		}
	// FILTERS
		public static function addFilterIn(s:String):void {
			if (!_filterIn) _filterIn = new Vector.<String>();
			if (_filterIn.indexOf(s) == -1) _filterIn.push(s);
			setFiltersActive(true);
		}
		public static function clearFilters():void {
			_filterOut = new Vector.<String>();
			_filterIn = new Vector.<String>();
			setFiltersActive(false);
		}
		static public function filterAlsoWarning(a:Boolean):void {
			traceWarning = a ? traceWithFilters : traceNormal;
		}
	// LINE
		public static function line(id:String=""):void {
			traceDebug(getLine(id));
		}
		public static function getLine(id:String=""):String {
			return UText.insertParams(LINE_SOURCE, {ID:id});
		}
	// UTY
		public static function resetConsole():void {
			// Resets all arrays and consoles to free memory
			PippoFlashEventsMan.broadcastStaticEvent(Debug, EVT_ABOUT_TO_RESET);
			
			_counter							= 0;
			_filterObject						= new Object();
			_errors							= new Object();
			_allEntries							= new Vector.<String>();
			resetPartialEntries();
			//_partialEntries = new Vector.<String>();
			_warnings							= new Vector.<String>();
			if (_debugConsole) _debugConsole.text = "";
			debug(_debugPrefix, "Console reset.");
// 			if (_debugConsole
		}
	// Object analisys
		public static var array:Function = getArrayString;
		public static var object:Function = getItemString;
		public static var objectJson:Function = getItemJson;
		public static function traceObject(o:*, recursive:Boolean=true, uniteProps:String=", "):void {
			trace(o is Array ? getArrayString(o, recursive, uniteProps) : getObjectString(o, recursive, uniteProps));
		}
	// Error objects - get an Error instance ad argument
		public static function debugError(id:String, e:Error, comment:String):void {
			error(id, comment + "\n" + comment + "\n" + e.getStackTrace());
		}
	// Title
		public static function title(tit:String):void {
			traceNormal("\n\n\n()()()()()()()()---------------------------------["+tit+"]---------------------------------()()()()()()()()\n");
		}
	// Forces output to browser console
		public static function debugToJSConsole(id:String, t:String):void { // This forces output to console, and also adds to debug chain 
			debug(id, t);
			// If EXPORT_TO_CONSOLE.ALL == true, debug already outputs all to console no need to do it twice
			if (!EXPORT_TO_CONSOLE.ALL && ExternalInterface.available) {
				outputToConsole(_allEntries[_allEntries.length-1]);
			}
			else if (!ExternalInterface.available) {
				Debug.debug(_debugPrefix, "Cannot output last event to browser console since ExternalInterface is not available.");
			}
		}
// METHODS FOR SPECIAL EXTERNAL FUNCTIONS ///////////////////////////////////////////////////////////////////////////////////////
		/**
		 * Adds a method that will be called each time a new debug entry is added
		 * @param	f
		 */
		static public function addExternalMethod(f:Function):void {
			if (_additionalMethods.indexOf(f) == -1) _additionalMethods.push(f);
		}
		/**
		 * Adds an ID that will not trigger additional methods
		 * @param	id
		 */
		static public function addExternalMethodExcludedId(id:String):void {
			if (_idsToExcludeFromAdditionalMethods.indexOf(id) == -1) _idsToExcludeFromAdditionalMethods.push(id);
		}
// METHODS UTY ///////////////////////////////////////////////////////////////////////////////////////
		/**
		 * Returns and resets a partial version of console with the last additions from last call, or from normal console reset.
		 * To intercept normal console reset listen to event EVT_ABOUT_TO_RESET and call partial console from there.
		 * @return The string with partial entries.
		 */
		static public function getPartialConsole():String {
			var partialConsole:String = _partialEntries.join("\n");
			resetPartialEntries();
			return partialConsole;
		}
		static public function hasPartialConsole():Boolean{
			return _partialEntries.length;
		}
		static public function resetPartialEntries():void {
			_partialEntries = new Vector.<String>();
			_partialEntriesCharLength = 0;
		}
		static public function addToPartialEntries(s:String):void {
			_partialEntriesCharLength += s.length + 2;
			_partialEntries.push(_s);
		}
		
		static public function getAllConsoleString(joiner:String = "\n"):String {
			return _allEntries.join(joiner);
		}
		static public function getSomeConsoleString(lastLines:int, joiner:String = "\n"):String {
			if (_allEntries.length > lastLines) return _allEntries.slice(_allEntries.length - lastLines, _allEntries.length).join(joiner);
			return getAllConsoleString(joiner); // If there are less lines than requested
		}
		private static function getItemJson(o:Object):String {
			return JSON.stringify(o);
		}
		private static function getObjectString(o:Object, recursive:Boolean=true, uniteProps:String=", "):String {
			var prop:String;
			var a:Array = [];
			if (recursive) for (prop in o) a.push(prop+":"+(o[prop] && o[prop] is Array ? array(o[prop], true) : o[prop] && o[prop].toString() == "[object Object]" ? getObjectString(o[prop], true) : o[prop])+OBJECT_STRING_EOF);
			else for (prop in o) a.push(prop+":"+o[prop]+OBJECT_STRING_EOF);
			return "{"+a.join(uniteProps)+"}";
		}
		private static function getArrayString(arr:Array, recursive:Boolean=true, uniteProps:String=", "):String {
			var i:*;
			var a:Array = [];
			if (recursive) for (i in arr) a.push(i+":"+(arr[i] && arr[i] is Array ? array(arr[i], true) : arr[i] && arr[i].toString() == "[object Object]" ? getObjectString(arr[i], true) : arr[i]));
			else for (i in arr) a.push(i+":"+arr[i]);
			return "["+a.join(uniteProps)+"]";
		}
		private static function getItemString(o:*, recursive:Boolean=true, uniteProps:String=", "):String {
			if (o is Array) return "\n" + getArrayString(o, recursive, uniteProps);
			else if (o is String) return o;
			else return "\n" + getObjectString(o, recursive, uniteProps);
		}
// LISTING OBJECTS /////////////////////////////////////////////////////////////////////////////////
		public static function listObject(o:Object, s:String="LIST"):void {
			for (var i:* in o) debug(s, i,  " : " + o[i]);
		}
		public static function listObjectRecursive(o:Object, s:String="ListREC>"):void {
			for (var i:* in o) {
				debug(s, i + " : "+ o[i]);
				if (o[i] is Object || o[i] is Array) {
					listObjectRecursive(o[i], s+"     ");
				}
			}				
		}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public static function setListenerFor(debugPrefix:String, f:Function):void {
			_prefixListeners[debugPrefix] = f;
		}
// UTY INTERNALS///////////////////////////////////////////////////////////////////////////////////////
		private static function outputToConsole(t:String):void {
			if (ExternalInterface.available) {
				if (USystem.isLocal()) ExternalInterface.call("console.log", escapeMultiByte(t));
				else ExternalInterface.call("console.log", t);
			}
		}
		private static function checkConsoleSize():void {
			// Checks if console length is more than, just reset everything to save ram
			if (_counter > MAXLINES) resetConsole();
		}
	// NORMAL TRACE
		private static function forceDebug(id:String="Debug", t:String=""):void { // This forces debug independently of filters and settings (used for errors and warnings)
			if (_addTimer) _s	= UText.getFormattedTime() + " [" +id + "]\t\t" + t;
			else _s = _counter + " [" +id + "]\t\t" + t;
			_allEntries.push(_s);
			addToPartialEntries(_s);
			addFilter(id.toUpperCase(), _s);
			if (_prefixListeners[id]) _prefixListeners[id](t);
			traceWarning(_s, id);
		}
		private static function windowDebug(id:String = "Debug", t:String = ""):void {
			var debugLog:String;
			if (_addTimer) debugLog	= UText.getFormattedTime() + " [" +id + "]\t\t" + t;
			else debugLog = _counter + " [" +id + "]\t\t" + t;
			_allEntries.push(debugLog);
			addToPartialEntries(debugLog);
			addFilter(id.toUpperCase(), debugLog);
			if (_prefixListeners[id]) _prefixListeners[id](t);
			traceDebug(debugLog, id);
		}
		// TRACE MANAGEMENT ACCORDING TO SETTINGS
		private static var traceDebug:Function = traceNormal;
		static private var traceWarning:Function = traceNormal;
		private static function traceNormal(t:String, id:String=""):void { // Only traces to debug windows
			if (_traceOut) trace(_mainPrefix + t);
			if (_debugConsole) {
				_debugConsole.appendText("\n"+t);
				_debugConsole.scrollV = _debugConsole.maxScrollV;
			}
			//_debugToExternalMethod(t);
			if (_additionalMethods.length && _idsToExcludeFromAdditionalMethods.indexOf(id) == -1) {
				for (var i:int = 0; i < _additionalMethods.length; i++) _additionalMethods[i](t);
			}
			postTrace();
		}
		private static function traceWithFilters(t:String, id:String = "Debug"):void {
			for (var i:int = 0; i < _filterIn.length; i++) {
				if (id.indexOf(_filterIn[i]) != -1) {
					traceNormal(t, id);
					postTrace();
					return;
				};
			}
			//if (_filterIn.indexOf(id) != -1) {
			//}
		}
		private static function postTrace():void {
			_counter ++;
			checkConsoleSize();
		}
		// TRACE ACTIVATION
		private static function setFiltersActive(a:Boolean):void {
			traceDebug = a ? traceWithFilters : traceNormal;
		}
	// PROCESS DEBUGS
		private static function processError(id:String, ...rest):void {
			_s = rest.join(REST_JOINER);
			addError(id, _s);
			forceDebug(id, ERROR_DISPLAY_PREFIX + _s + ERROR_DISPLAY_POSTFIX);
			
			if (_debugConsole && _textFormats) {
				var initIndex:uint = _debugConsole.length;
				try { // This sometimes triggers an out of index error
					_debugConsole.setTextFormat(_textFormats.ERROR, initIndex, _debugConsole.length);
				}
				catch (e:Error) {
					// Her eI can't use a Debug.error or will trigger an infinite loop
					//trace(_debugPrefix + " ERROR SETTING TEXTFORMAT");
				}
			}
			
		}
		private static function processWarning(id:String, ...rest):void {
			_s = rest.join(REST_JOINER);
			addError(id, _s);
			forceDebug(id, WARNING_DISPLAY_PREFIX + _s + WARNING_DISPLAY_POSTFIX);
			//try { // This might be called before it's initialized
			if (_debugConsole && _textFormats) {
				var initIndex:uint = _debugConsole.length;
				_debugConsole.setTextFormat(_textFormats.WARNING, initIndex, _debugConsole.length);
			}
			//} catch (e:Error) {};
		}
	// ADD ELEMENTS TO LISTS
		private static function addFilter(id:String, t:String):void {
			if (_filterObject[id] == null) _filterObject[id] = new <String>[];
			_filterObject[id].push(t);
		}
		private static function addError(id:String, t:String):void {
			if (_errors[id] == null) _errors[id] = new <String>[];
			_errors[id].push(t);
		}
	}
}