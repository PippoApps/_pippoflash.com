/* Config - ver 2.7 - Filippo Gregoretti - www.pippoflash.com - THIS ONLY WORKS WITH XML CONFIG - MAKES SENSE

2.7 - Added separate prompt management. VOCABULARY.PROMPTS - _prompts - getPrompt()


*/

package com.pippoflash.framework {

	import 									flash.text.*;
	import 									flash.utils.*;
	import 									flash.net.*;
	import									com.pippoflash.utils.*;
	import									com.pippoflash.framework._PippoFlashBase;
	import									com.pippoflash.net.QuickLoader;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	
	public dynamic class Config {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		protected static const _verbose:Boolean = true;
		protected static const LANGUAGE_CODE_GROUP:Object = {en:"en", it:"it", es:"es"}; // Some specific languages refer to other languages
		protected static const PREFERENCES_SO_VAR_NAME:String = "PF_PREFERENCES"; // Name of variable in SharedObject for preferences name
		protected static const PREFERENCES_NODE_NAME:String = "PREFERENCES"; // Name of the preferences node
		protected static const CONFIG_VERSION:String = "2.7"; // Checks that XML config version is relevant with this version of Config.as
		// SWITCHES
		protected static var USE_ANTICACHE:Boolean = false;
		// STATIC
		protected static var _debugPrefix:String = "Config";
		protected static var PRE_XML_KEYWORDS:Object = {}; /* Every item set here, will be looked for in config string with "pre_" before, and substituted.
				i.e.: defining PRE_XML_KEYWORDS.DATAURL = "_data/"; will substitute all occurrances of [pre_DATAURL] in loaded string, withg provided string. 
				This is destructive. Can be only launched once at startup. It is useful for contents which doesn't change after first load. */
		// SYSTEM
		private var _substituteKeys:Object = {}; // Stores KEY PAIR to substitute, such as LOCALE:_assets/en/, TARGET:_Assets_desktop/, TARGETLOCALE:_assets_desktop/en/
		//private var _assetsLocation:String = "_assets/";
		// REFERENCE
		private var _loadedFunc:Function;
		private var _errorFunc:Function;
		// DATA HOLDERS
		private var _requiredLocale:String; // If this is defined, a setLanguage is called automatically deferring onLoadComplete - USED ONLY FOR LOADING EXTERNAL LOCALE
		protected var _configUrl:String;
		protected var _configString:String;
		public var _config:XML;
		public var _configLocaleAddOn:XML; 
		public var _data:XML;
		public var _vocabulary:Object;
		public var _words:Object;
		public var _urls:Object;
		public var _settings:Object;
		//public var _structure						:Object;
		//public var _contents						:Object;
		public var _keywords:Object;
		public var _variables:Object;
		public var _dynamic:Object;
		public var _pippoflashWords:Object; // Stores all nodes into VOCABULARY.PIPPOFLASH;
		public var _prompts:Object; // Stores all nodes in VOCABULARY.PROMPTS
		private var _preferencesDefault:XML; // Direct reference to DEFAULT PREFERENCES node retrieved from config.xml
		private var _preferences:XML; // Direct reference to PREFERENCES node
		private var _uri_location:Object;
		private var ___coordinateNodes:Object = {}; // Populated with "add coordinates list"
		
		
		private var _dynamic_settings:Object; // Holds nodes to subsitute
		private var _dynamic_settings_conditions:Object; // substitutes _uri_location
		//private var _languageName					:String;
		private var _languageCode:String;
		private var _locationCode:String = "en"; // Default if dynamic locations is not set
		private var _configAddOnPath:String = ""; // This can be set with setConfigPath();
		// LOCALE
		private var _localeVocabulary:XML;
		// CONTENTS
		private var _contentSrcPrefix:String = ""; // Adds this to all content src urls
		// MARKERS
		private var _isComplete					:Boolean; // Config is already complete and initialized (to load language)
		// STATIC UTY
		protected static var _o					:Object;
		protected static var _node					:XML;
		protected static var _s						:String;
		protected static var _c					:*;
		protected static var _a					:Array;
		protected static var _i						:int;
		private static var _instance				:Config;
// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		public static function get instance():Config {
			return _instance;
		}
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function Config(url:String=null, funcOk:Function=null, funcErr:Function=null, useAnticache:Boolean=false, requiredLocale:String=null):void {
			Debug.debug(_debugPrefix, "Initializing Config... required language is:",requiredLocale);
			_instance = this;
			_PippoFlashBaseUMem._config = this;
			_PippoFlashBaseNoDisplayUMem._config = this;
			// If config url is defined, I do load it here
			if (url) load(url, funcOk, funcErr, useAnticache, requiredLocale);
			else { // I do not load config here, so I just set the variables for later use
				_loadedFunc = funcOk;
				_errorFunc = funcErr;
				USE_ANTICACHE = useAnticache;
				//_requiredLocale = requiredLocale;
			}
		}
		
		
		
		
		
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// INIT AND LOAD ///////////////////////////////////////////////////////////////////////////////////////
		public function setPreKeywords			(preKeys:Object):void {
			for (_s in preKeys)				setPreKeyword(_s, preKeys[_s]);
		}
		public function setPreKeyword			(key:String, value:String):void {
			Debug.debug					(_debugPrefix, "Setting pre-rpcess keyword: " + key + " = " + value);
			PRE_XML_KEYWORDS[key]			= value;
		}
		public function load						(url:String, funcOk:Function=null, funcErr:Function=null, useAnticache:Boolean=false, requiredLocale:String=null):void {
			USE_ANTICACHE					= useAnticache;
			_configUrl							= url;
			_loadedFunc						= Boolean(funcOk) ? funcOk : _loadedFunc;
			_errorFunc						= Boolean(funcErr) ? funcErr : _errorFunc;		
			//_requiredLocale						= requiredLocale ? requiredLocale : _requiredLocale; // If this is defined, in case it will load a new addendum locale to config. After  main config is loaded, if it differs from the default defined in config.
			reload							();
		}
		public function reload					():void {
			Debug.debug					(_debugPrefix, "Loading config file:", _configUrl);
			QuickLoader.loadFile				(_configUrl, this, "Config");
		}
				public function onLoadCompleteConfig(o:Object):void {
					Debug.debug				(_debugPrefix, "Config loaded successfully.");
					_configString				= substitutePreKeywords(o.getContent());
					parseXML					();
					onConfigLoaded				();
				}
					// SUB KEYWORDS METHOD
						private function substitutePreKeywords			(source:String):String {
							Debug.debug(_debugPrefix, "Performing substitution of pre-process keywords...");
							// Substitute keywords in XML only if object is defined
							if (PRE_XML_KEYWORDS) {
								var pre						:String = "[pre_";
								var post						:String = "]";
								var full						:String;
								for (var key:String in PRE_XML_KEYWORDS) {
									full						= pre + key + post;
									if (source.indexOf(full) != -1) {
										Debug.debug				(_debugPrefix, "Substituting Keyword: " + full + " with " + PRE_XML_KEYWORDS[key]);
										source 					= source.split(full).join(PRE_XML_KEYWORDS[key]);
									}
									else {
										Debug.debug			(_debugPrefix, "No occurrance found for key " + full);
									}
								}
							}
							return							source;
						}
				protected function onConfigLoaded	():void { // this is just to be used in ProjConfig, the extension, to be overridden
					// Override this in ProjConfig in order to perform tasks, but call this before to setup variables and default language
					// This is called when everything is done internally, but BEFORE mainapp is notified
					setupVariables				();
					// onConfigcompleted() is called by this, once lanuage is parsed or loaded
					setDefaultLanguage			();
				}
				protected function onConfigCompleted():void {
					_isComplete				= true;
					if (Boolean(_loadedFunc))		_loadedFunc(_data);
					_loadedFunc				= null;
				}
				public function onLoadErrorConfig		(o:*=null, o1:*=null):void {
					Debug.error				(_debugPrefix, "Error loading config:", o, o1);
					_errorFunc					();
				}
		public function setConfigAddOnPath			(path:String):void {
			_configAddOnPath					= path;
		}
		public function isComplete					():Boolean {
			return							_isComplete;
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	// DATA INITIALIZATION ///////////////////////////////////////////////////////////////////////////////////////
		protected function parseXML					():void {
			//Debug.debug(_debugPrefix, _configString);
			_data									= UXml.getCleanedXML(_configString);
			_data.ignoreWhitespace					= true;
			_config								= _data;
			// Setup main version of config
			Debug.debug						(_debugPrefix, "Configuration file loaded. Version", _data.@version, "framework", _data.@framework);
			// Setup direct links
			for each (_node in _data.children()) {
				_s 							= "_"+String(_node.name()).toLowerCase();
				Debug.debug					(_debugPrefix, "Adding direct reference to:",_s);
				this[_s]						= _node;
			}
			// Setup vocabulary
			_words							= {};
			for each (_node in _vocabulary.WORDS[0].children()) {
				_words[_node.name()]				= _node;
			}
			// Setup PippoFlash vocabulary
			_pippoflashWords					= {};
			for each (_node in _vocabulary.PIPPOFLASH[0].children()) {
				_pippoflashWords[_node.name()]	= _node;
			}
			// Setup prompts
			_prompts							= {};
			for each (_node in _vocabulary.PROMPTS[0].children()) {
				_prompts[_node.name()]	= _node;
			}
			// SETUP CONTENTS
			//if (_contents) {
				//_contentsById					= new Object();
				//for each (var xx:XML in _contents.CONTENT)	_contentsById[xx.@id]	= xx;
			//}
			// GET LOCALE PART
			_localeVocabulary = _data.LOCALE_VOCABULARY[0];
			// SETUP FORMATS NODE
			UXml.addFormatNodes				(_settings.APPEARANCE.TEXTSTYLES.children());
			// Trace a debug to be sure
			Debug.debug						(_debugPrefix, "Checking location nodes...");
			// SETUP LOCATION
			if (_dynamic_settings && _dynamic_settings_conditions) {
				_locationCode = _dynamic_settings_conditions.@["default"];
				var loc:String = UGlobal.getUrl();
				var appId:String = _Application.instance.getAppId();
				Debug.debug(_debugPrefix, "Checking for dynamic config nodes. App id: " + appId+", location: "+loc+", default dynamic node: "+_locationCode);
				for each (_node in _dynamic_settings_conditions.children()) {
					Debug.debug(_debugPrefix, "Checking location node " + _node.toXMLString());
					//if (loc.indexOf(String(_node.@urlContains)) != -1) {
						// Set it to comply
						var complies:Boolean = true;
						// Check url
						if (String(_node.@urlContains).length) {
							Debug.debug(_debugPrefix, "Checking if url contains: " + _node.@urlContains);
							if (loc.indexOf(String(_node.@urlContains)) != -1) Debug.debug(_debugPrefix, "Url contains string.");
							else {
								Debug.debug(_debugPrefix, "Url does not contain string.");
								complies = false;
							}
						}
						// Find to see if conditions are met not just node contains
						if (complies && String(_node.@methods).length) {
							Debug.debug(_debugPrefix, "Node has methods to check. Checking methods.");
							var methodsList:Array = String(_node.@methods).split(",");
							var methodPars:Array;
							for each (var method:String in methodsList) {
								Debug.debug(_debugPrefix, "Checking method: " + method);
								methodPars	= method.split(".");
								// Check if method is well formed (ID.methodName)
								if (methodPars.length != 2) {
									Debug.error(_debugPrefix, "Checking for settings plugin, methods must comply, but method " + method + " is malformed.");
									complies = false;
									break;
								}
								// Check if instance is _PippoFlashBase
								var instance:_PippoFlashBase;
								try {
									instance = UGlobal.mainApp.getInstance(methodPars[0]);
								}
								catch (e) {
									Debug.error(_debugPrefix, "This is not a _PippoFlashBase instance " + methodPars[0]);
									complies = false;
									break;
								}
								// Check if instance exists
								if (!instance) {
									Debug.error(_debugPrefix, "Cannot find _PippoFlashBase instance " + methodPars[0]);
									complies = false;
									break;
								}
								// Check if method exists
								if (!instance.hasOwnProperty(methodPars[1])) {
									Debug.error(_debugPrefix, "Cannot find property " + methodPars[1] + " in instance " + methodPars[0]);
									complies	= false;
									break;
								}
								// Check if method is a method and NOT a property
								if (!instance[methodPars[1]] is Function) {
									Debug.error(_debugPrefix, "Property " + methodPars[1] + " in instance " + methodPars[0] + " is NOT a method!");
									complies	= false;
									break;
								}
								// Check that method complies
								var result:Boolean = instance[methodPars[1]]();
								Debug.debug(_debugPrefix, "Method " + method + " returned " + result);
								if (!result) {
									Debug.debug(_debugPrefix, "Method " + method + " does not comply...");
									complies = false;
									break;
								}
							}
							if (complies) {
								_locationCode = _node.@code;
							}
						//}
						// Check if it still complies and proceed
						
						if (complies) {
							_locationCode = _node.@code;
						Debug.debug(_debugPrefix, "Found dynamic settings to substitute: " +  _locationCode);
							break;
						}
					}
				}
			}
			// SETUP PATHS IN LOCATION
			_dynamic = _dynamic_settings[_locationCode];
			// Overwrite or add nodes in settings
			if (_dynamic.children().length()) {
				Debug.debug(_debugPrefix, "Substituting nodes:\n" + _dynamic.children().toXMLString());
				for each (var dynNode:XML in _dynamic.children()) {
					_settings[dynNode.name()] = dynNode;
				}
				// ALERT WARNING IF ANY
				if (_dynamic.WARNING.length()) Debug.warning(_debugPrefix, "DYNAMIC NODES WARNING: " + String(_dynamic.WARNING));
			} else Debug.debug(_debugPrefix, "No nodes to substitute with code: ", _locationCode);
			// SETUP PREFERENCES - Only setup default internal node. SharedObject managed preferences are managed afterwards from MainApp if needed.
			setupDefaultPreferences();
			// SETUP OF SOUNDS
			setupPippoFlashSounds();
			// DEVICE DYNAMIC SETTINGS
			setupDeviceSettings();
			// SETUP NUMBER POSITIONING FORMATTING (1st, 2nd, etc.);
			setupNumberPositioning();
			
		}
		// SETUP INITIAL DEFAULT PREFENRENCES NODE
			private function setupDefaultPreferences	():void { // Sets default preferences as internal preferences
				_preferencesDefault				= _data.PREFERENCES.length() ? _data.PREFERENCES[0] : new XML("<"+PREFERENCES_NODE_NAME+"/>");
				Debug.debug					(_debugPrefix, "Activating default preferences. Nomber pf preferences nodes:",_preferencesDefault.children().length());
				if (_verbose)					Debug.debug(_debugPrefix, "-------- DEFAULT PREFERENCES -------\n" + _preferencesDefault.toXMLString());
			}
		// SETUP INTERNAL SETTINGS SOUNDS NODE
			private function setupPippoFlashSounds	():void {
				for each (var soundNode:XML in _data.SOUNDS.children()) {
					if (USound.addSoundToList(soundNode.@classId, soundNode.name(), soundNode.@group)) {
						Debug.debug			(_debugPrefix, "Setup sound:", soundNode.toXMLString());
					}
					else {
						Debug.error			(_debugPrefix, "Cannot setup sound:",soundNode.toXMLString());
					}
				}
			}
		// SETUP DEVICE DYNAMIC SETTINGS
			private function setupDeviceSettings		():void {
				if (USystem.isDevice() || !UCode.isTrue(_data.DEVICE_DYNAMIC_SETTINGS.@applyOnlyOnDevices)) {
					// Here I have to set device settings according to several values
					// DPI
					Debug.debug				(_debugPrefix, "Setting DEVICE_DYNAMIC_SETTINGS values.");
					if (_data.DEVICE_DYNAMIC_SETTINGS.ACCORDING_TO_DPI.length()) {
						var dpi				:uint = USystem.getDPI();
						Debug.debug			(_debugPrefix, "Setting according to dpi. DPI is:",dpi);
						var dpiNum				:uint;
						var goodNode			:XML;
						for each (var dpiNode:XML in _data.DEVICE_DYNAMIC_SETTINGS.ACCORDING_TO_DPI.children()) {
							dpiNum			= uint(dpiNode.name().toString().substr(3));
							if (dpiNum > dpi) {
								goodNode		= dpiNode;
								break;
							}
						}
						if (!goodNode) {
							goodNode			= _data.DEVICE_DYNAMIC_SETTINGS.ACCORDING_TO_DPI.children()[_data.DEVICE_DYNAMIC_SETTINGS.ACCORDING_TO_DPI.children().length()-1];
							Debug.debug		(_debugPrefix, "DPI node not found. Defaulting to last node.");
						}
						Debug.debug			(_debugPrefix, "Found DPI node:",goodNode.name());
						substituteSettings		(goodNode);
					}
				}
			}
		// SETUP NUMBER POSITIONING FORMATTING (1st, 2nd, etc.);
			private function setupNumberPositioning():void {
				/* Be careful, I have updated this to use a different kind of numbering. Will triger an error with old configs. */
				_numberPositioningPostfix = []; // This stores from 0 to 30, since below 20 are treated singularily, while over 20 will work for everything over 20
				if (_pippoflashWords.NUMBERPOSITIONING) {
					var n:XML;
					var s:String;
					var num:int;
					// Here I setup all positions computing number
					for (var i:uint=0; i<_pippoflashWords.NUMBERPOSITIONING.NUMBERS.children().length(); i++) {
						n = _pippoflashWords.NUMBERPOSITIONING.NUMBERS.children()[i];
						//s = String(n);
						//num = int(s.substr(1));
						_numberPositioningPostfix[i] = String(n);
					}
					// Here I overwrite position 0 with it's own number
					//_numberPositioningPostfix[0] = String(_pippoflashWords.NUMBERPOSITIONING.MZERO);
				}
			}
		// SETUP XML VARIABLES
			private function setupVariables			():void {
				// Imports variables from XML file and sets them up in instances and classes
				if (_variables) {
					Debug.debug				(_debugPrefix, "Setting up variables from XML.");
					for each (_node in _variables.children()) {
						setupXmlVariable			(_node);
					}
				}
			}
					private function setupXmlVariable	(node:XML):void {
						Debug.debug			(_debugPrefix, node.toXMLString());
						if (UXml.hasAttribute(node, "className")) { // I have found a static class variable
							var cl			:Class = _PippoFlashBase.getClassById(node.@className);
							if (!cl)			cl = UCode.getClassFromString(node.@className);
							if (cl)			cl[node.@name] = node.@type == "Boolean" ? UCode.isTrue(node.toString()) : node.toString();
						}
						else { // It is an instance variable, send the XML node directly (PippoFlash framework can understand it)
							_PippoFlashBase.setInstanceXmlVariable(node);
						}
					}		
		
		
			
			
			
			
			
			
	// INIT LANGUAGE ///////////////////////////////////////////////////////////////////////////////////////
		private function setDefaultLanguage():void {
			/* THIS IS DESTRUCTIVE, NEEDS TO BE CALLED ONLY AT STARTUP, CANNOT BE CHNAGED LATER */
			Debug.debug(_debugPrefix, "Setting internal default language (as set in config.xml):",_vocabulary.@defaultLocale,",while required language is:",_requiredLocale);
			setInternalLanguage(String(_vocabulary.@defaultLocale));
			// check if language has to be loaded or not
			if (_requiredLocale) { // Some language is required
				if (_requiredLocale == _languageCode) { // Required locale was already setup in default language
					onConfigCompleted();
				}
				else {
					setInternalLanguage(_requiredLocale);
					checkToLoadLanguage();
				}
			} else onConfigCompleted();
		}
			private function setInternalLanguage(lang:String):void {
				languageCode = lang;
				Debug.debug(_debugPrefix, "Looking for LOCALE to overwrite in main config.xml.");
				if (_data.LOCALE.hasOwnProperty(_languageCode)) {
					for each (_node in _data.LOCALE[_languageCode].children()) {
						_words[_node.name()] = _node;
					}
				}
				else {
					Debug.debug(_debugPrefix, "Language",_languageCode,"is not found in default <LOCALE> node in main config.xml.");
				}
			}
		// CHECK IF LANGUAGE HAS TO BE LOADED
			private function checkToLoadLanguage	():void {
				Debug.debug(_debugPrefix, "Checking if " + _languageCode + " needs to be loaded as an external plugin...");
				if (_vocabulary.@externalIds.indexOf(_languageCode) != -1) {
					var addOnUrl:String = UText.insertParams(_vocabulary.@externalPath, {PATH:_configAddOnPath, ID:_languageCode})
					Debug.debug(_debugPrefix, "Loading language",_languageCode,"on",addOnUrl);
					QuickLoader.loadFile(addOnUrl, this, "AddOn");
				}
				else {
					Debug.debug(_debugPrefix, "Language",_languageCode,"has not to be loaded externally. Config is complete.");
					onConfigCompleted();
				}
			}
				public function onLoadCompleteAddOn(o:Object=null):void {
					if (o) {
						var addOnXmlString		:String = substitutePreKeywords(o.getContent());
						parseAddOnXml			(UXml.getCleanedXML(addOnXmlString));
					}
					// Call add-on completed only if it is loaded in a second time. If config is still initializing, I call config complete.
					if (isComplete()) {
						_PippoFlashBase.callOnAll	("onConfigAddOn");
					}
					else {
						onConfigCompleted		();
					}
				}
				public function onLoadErrorAddOn(o:Object=null):void {
					Debug.error(_debugPrefix, "Error loading add-on, file not found!");
					onLoadCompleteAddOn();
				}		
		
					
					
					
				
				
				
				
				
					
					
		
		
	// LANGUAGE METHODS
	/**
	 * Change language code. Keywords will be substituted, and language depending words in config will overwrite standard words.
	 * @param	lang
	 */
		public function setLanguage(lang:String):void { // this has to be called just like a function.
			if (_languageCode == lang) { // Language was already setup, skipping
				Debug.warning(_debugPrefix, "Language " + lang + " is already setup. Aborted: setLanguage()");
				return;
			}
			// Proceed setting language
			Debug.debug(_debugPrefix, "Setting language:",lang);
			// I first grab the nodes set in internal (if any)
			setInternalLanguage(lang);
			//checkToLoadLanguage();
		}
		public function getLanguageCode():String {
			return _languageCode;
		}
		//public function getLanguageName():String {
			//return _languageName;
		//}
		public function parseAddOnXml(xml:XML):void { // Overwrites some values with parsed xml
			var prop:Object;
			var value:XML;
			var node:XML;
			Debug.debug(_debugPrefix, "Updating language nodes.");
			for each (node in xml.VOCABULARY.WORDS.children()) {
				_words[node.name()] = node;
			}
			// Setup pippoflash locale stuff
			for each (node in xml.VOCABULARY.PIPPOFLASH.children()) {
				_pippoflashWords[node.name()] = node;
			}
			for each (node in xml.MAIN_NODES.children()) {
				prop = this["_"+String(node.name()).toLowerCase()];
				Debug.debug(_debugPrefix, "Updating node: " + String(node.name()));
				if (prop) {
					for each (value in node.children()) {
						prop[value.name()] = value;
					}
				}
				else {
					Debug.error(_debugPrefix, "Prop:",node.name(),"not found in main config. Update aborted.");
				}
			}
		}
		
		
		
		
		
		
		
		
		
		
	// VOCABULARY AND WORDS LOCALE ///////////////////////////////////////////////////////////////////////////////////////
		public function getWordNodeLocale(word:String, locale:String=null):XML {
			return _localeVocabulary[locale ? locale : _languageCode][word][0];
		}
		public function getSubnodeLocaleXML(node:XML, locale:String=null):XML {
			if (!locale) locale = _languageCode;
			// Returns node with selected local or default required locale. If not present returns first child.
			//<ITEM type="loadingScreen">
				//<en><![CDATA[Image 3 EN]]></en>
				//<ru><![CDATA[Image 3 RU]]></ru>
				//<az><![CDATA[Image 3 AZ]]></az>
			//</ITEM>
			if (node[locale].length()) return node[locale][0];
			else return node.children()[0];
		}
		
		
		
		
		
	// DateManager
		public function getDateManagerConfigNode():XML {
			if (_pippoflashWords.DATEMANAGER) return _pippoflashWords.DATEMANAGER;
			else return null;
		}
		
		
		
		
		
		
		

					
	// INTERNAL MìUTILITY METHODS ///////////////////////////////////////////////////////////////////////////////////////
			protected function addCordinatesNode(n:XML):void { // Converts <NODE x="0" y="0" w="10", h="10" /> to a rectangle and makes it retrievable with getCoordinates
				___coordinateNodes[String(n.name())] = new Rectangle(int(n.@x), int(n.@y), int(n.@w), int(n.@h));
				Debug.debug(_debugPrefix, "Added coordinates:",n.name(),___coordinateNodes[String(n.name())]);
			}
			protected function addCoordinatesNodeChildren(n:XML):void { // Adds a list of node children to coordinates system
				for each (var c:XML in n.children()) addCordinatesNode(c);
			}

				
				
				
				
				
				
				
				
				
				
				
				
	// PREFERENCES ///////////////////////////////////////////////////////////////////////////////////////
		public function loadPreferences():XML { // Reverts to saved preferences node. First action from MainApp in startApplication() is done using this method.
			var prefs :XML = _Application.instance.getSharedObject(PREFERENCES_SO_VAR_NAME); // Get save preferences node
// 			trace("==========================================LOADED PERFSSSSSSS"+ prefs.toXMLString() +"==========================================");
			if (prefs) { // If there is a saved one, check all nodes are present or duplicate a default node
// 				trace("TROVATE",_preferences, prefs.children().length());
				// If preferences are loaded for the first time, we should add all default nodes that are not actually stored in the node
// 				if (!_preferences) {
// 					trace("MA CHE LOOPPOOOOO???");
					for each (var n:XML in _preferencesDefault.children()) {
// 						trace("Provo se ci sta la pref",prefs[n.name().localName].toXMLString(),prefs[n.name().localName].length());
						if (!prefs[n.name().localName].length()) {
							prefs.appendChild(n.copy()); // If saved preferences miss a node add the default one
						}
					}
					_preferences				= prefs.copy();
// 					_preferences				= new XML("<" + PREFERENCES_NODE_NAME + "/>");
// 					for each (var nn:XML in prefs.children()) {
// 						_preferences.appendChild	(nn.copy());
// 					}
// 				}
				if (_verbose)					Debug.debug(_debugPrefix, "--------- PREFERENCES LOADED FROM SHARED OBJECT ------------\n" + _preferences.toXMLString());
			}
			else { // No saved preferences, just set the dafaultNode and save it
				if (_verbose)					Debug.debug(_debugPrefix, "Saved preferences not found. Saving default preferences.");
				_preferences					= _preferencesDefault.copy();
// 				_preferences					= new XML();
// 				for each (var n:XML in _preferencesDefault.children()) _preferences.appendChild(n.copy()); // If saved preferences miss a node add the default one
				savePreferences					();
			}
			return 							_preferences;
		}
		public function getPreferences				():XML { // Returns a reference to the preferences node
			return							_preferences;
		}
		public function getPreference				(p:String):* { // Returns one preference according to type (S, N, B, X);
			if (_preferences[p].length()) {
				var n							:XML = _preferences[p][0];
				var t							:String = String(n.@type);
				if (t == "S")					return String(n);
				else if (t == "N")				return Number(n);
				else if (t == "B") {
					return UCode.isTrue(String(n));
				}
				else							return n; // By default it returns the reference it finds
			}
			else {
				Debug.error					(_debugPrefix, "Node in preferences not found: " + p);
				return						null;
			}
		}
		public function setPreference				(p:String, v:*, andSave:Boolean=true):Boolean { // Returns OK. Sets one preference. Only accepts a number, a Boolean, a String or an XML
			// Saves onto shared object a preferences node. If save is false, they must be saved later with savePreferences(); or restored with loadPreferences();
			var t								:String;
			if (v is Number)					t = "N";
			else if (v is String)					t = "S";
			else if (v is Boolean)					t = "B";
			else if (v is XML || v is XMLList)			t = "X";
			else {
				Debug.error					(_debugPrefix, "Cannot set preference " + p + " as " + v + ". Type is not acepted. Only Number, Boolean, String or XML are accepted");
				return 						false;
			}
			var n								:XML = new XML("<"+p+">"+String(v)+"</"+p+">")
			n.@type							= t;
// 			trace("CONTROLLIAMO i NODI",_preferences[p]==n,_preferences[p]==_preferencesDefault[p]);
			if (_preferences[p].length())			_preferences.replace(p, n);
			else								_preferences.appendChild(n);
			if (_verbose)						Debug.debug(_debugPrefix, "Setup preference node " + n.toXMLString() + (andSave ? " - SAVING ALL PREFERENCES." : " - NOT SAVING"));
			if (andSave)						savePreferences();
			return							true;
		}
		public function revertPreferences():void { // Reverts to saved preferences
			loadPreferences();
		}
		public function savePreferences():void { // Saves stored preferences node
			var n								:XML = _preferences.copy();
			if (_verbose)						Debug.debug(_debugPrefix, "-------- SAVING PREFERENCES --------\n",n.toXMLString());
			else								Debug.debug(_debugPrefix, "Saving preferences.");
			_Application.instance.setSharedObject(PREFERENCES_SO_VAR_NAME, n);
		}
		public function clearPreferences				(resetToDefault:Boolean=true):void { /* CAREFUL - this removes all stored preferences */
			_preferences						= resetToDefault ? _preferencesDefault.copy() : new XML("<"+PREFERENCES_NODE_NAME+"/>");
			savePreferences						();
		}
		
		
		
		
		
		
		
		
		
		
	// SETTINGS ///////////////////////////////////////////////////////////////////////////////////////
		public function getSetting(id:String):String {
			return String(_settings[id][0]);
		}
		public function getSettingNode(id:String):XML {
			return _settings[id][0];
		}
		public function substituteSettings(newSettings:XML):void { // Grabs an XML node, and uses it's content to overwrite nodes within settings
			for each (var dynNode:XML in newSettings.children()) {
				_settings[dynNode.name()] = dynNode;
				if (_verbose) Debug.debug(_debugPrefix, "Setup setting:",dynNode.toXMLString());
			}
		}
		
		
		
		
		
		
		
		
	// LINK AND TEXTFIELD ///////////////////////////////////////////////////////////////////////////////////////
		public function processLink(id:String, par:Object=null):void {
			_s = getLink(id, par);
			navigateToURL(new URLRequest(_s), _data.URLS[id].@target);
		}
		public function getLink(id:String, par:Object=null):String {
			return UText.insertParams(_data.URLS[id].toString(), par);
		}
		public function setupTextsByName(a:Array):void {
			for each (_c in a) setupTextByName(_c);
		}
		public function setupTextByName(c:*):void {
			setupTextInElement(c, _words[c.name]);
		}
		public function setupTextId(c:*, id:String):void {
			setupTextInElement(c, _words[id]);
		}
		public function setupTextInElement(c:*, s:String):void {
			if (c.text) c.text = s;
			else if (c.setText) c.setText(s);
			else if (c._txt) c._txt.text = s;
		}
		
		
		
		
		
		
		
		
		
		
	// VOCABULARY ///////////////////////////////////////////////////////////////////////////////////////
		public function getWord(s:String, par:Object=null):String {
			if (_words[s]) return par ? UText.insertParams(_words[s], par) : _words[s];
			else {
				Debug.debug(_debugPrefix, "Word:",s,"not found in vocabulary.");
				return null; // I have to return null
			}
		}
		public function getWordNode(s:String):XML {
			return _words[s] ? _words[s][0] : new XML("<WORD_NOT_FOUND />");
		}
		public function getPrompt(id:String):XML {
			return _prompts[id];
		}
		public function setWord(t:TextField, s:String, par:Object=null):void { // Sets some text in a text field
			t.text = getWord(s, par);
		}
		public function formatWord(s:String, form:String):String {
			return format(getWord(s), form);
		}
		public function getWordMultiple(id:String, pars:Object=null, num:uint=0):String {
			// This grabs the node of formatted word. If it has multiple=true, then it must have 3 subnodes
			// M0, M1, MM, which contain the formatting for 0, one or multiple amounts
			var word:* = _words[id];
			if (word is XML && word.children().length()) { // It is an xml
				if (UCode.isTrue(word.@multiple)) {
					if (num == 0) return UText.insertParams(word.M0[0].toString(), pars);
					else if (num == 1) return UText.insertParams(word.M1[0].toString(), pars);
					else return UText.insertParams(word.MM[0].toString(), pars);
				}
			}
			return word;
		}
		
		var _numberPositioningPostfix:Array; // This stores specific positioning for a number. If specific positioning is not found, it will be calculated with usual routine.
		public function getNumberPositioning(num:uint):String {
			// Returns the formatted positioning taken from config
			/* It uses a node stored in VOCBULARY.PIPPOFLASH.
			      <NUMBERPOSITIONING>
				<!-- the numberPositioning node is needed to convert a number to a position. -->
				<MNONE>Not Ranked</MNONE><!-- When a number is at 0 -->
				<!-- Below here, the last digit of number is used to determine how to format a number. all nodes must be present, from 0 to 9 -->
				<MZERO>G</MZERO><!-- Only for 0 -->
				<M0>[NUM]th</M0><!-- For 10, 20, 30, 110... -->
				<M1>[NUM]st</M1><!-- For 1 and 21, 31, 151... same until 9 -->
				<M2>[NUM]nd</M2>
				<M3>[NUM]rd</M3>
				<M4>[NUM]th</M4>
				<M5>[NUM]th</M5>
				<M6>[NUM]th</M6>
				<M7>[NUM]th</M7>
				<M8>[NUM]th</M8>
				<M9>[NUM]th</M9>
			      </NUMBERPOSITIONING>
			*/
			// Check first if number is set as predefined
			if (_numberPositioningPostfix[num]) { 
				return UText.insertParams(_numberPositioningPostfix[num], {NUM:num});
			} else if (num > 29) {
				// Retrieve value of last digit
				var n:String = String(num).charAt(String(num).length - 1);
				// Add 2 so it becomes a digit of 20
				var nn = int("2" + n);
				return UText.insertParams(_numberPositioningPostfix[nn], {NUM:nn}); 
			}
			// Number is not pre-defined, proceed computing
			//if (_pippoflashWords.NUMBERPOSITIONING) {
				//var numString					:String = String(num);
				//var pos						:int = int(numString.charAt(numString.length-1));
				//var s							:String = num == 0 ? _pippoflashWords.NUMBERPOSITIONING["MZERO"] : _pippoflashWords.NUMBERPOSITIONING["M"+pos];
				//return						UText.insertParams(s, {NUM:num});
			//}
			
			else {
				Debug.error(_debugPrefix, "getNumberPositioning("+num+") requested but system node is not defined. Returning normal number.");
				return String(num);
			}
		}
		public function format						(formatId:String, cont:*):String { // content can be anything
			// this grabs an element called "FORMAT_" + the format Id, and substitutes the [CONTENT] with the content var
			return							UText.insertParams(_words["FORMAT_"+formatId], {CONT:cont});
		}
		public function getSequencePos				(seq:String, pos:uint, par:Object=null):String {
			// this returns an element of a comma delimited list in a node which starts with "SEQUENCE_"
			// Node must have a list of children nodes called <s>Primo Posto</s>, as many as needed.
			// There must also be a node called <outOfRange>[NUM]° posto</outOfRange> - for when not enough <s> nodes are present. NUM is used as param internally.
			var node							:XML = _words["SEQUENCE_"+seq];
			var txt							:String = node.s.length() > pos ? node.s[pos].toString() : UText.insertParams(node.outOfRange.toString(), {NUM:pos});
			return							par ? UText.insertParams(txt, par) : txt;
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	// KEYWORDS ///////////////////////////////////////////////////////////////////////////////////////
		public var keyword:Function = getKeyword;
		public function getKeyword(id:String):String {
			return _keywords[id].toString();
		}
		public var keywords:Function = getKeywords;
		public function getKeywords():Array {
			var a:Array = [];
			for each (_node in _keywords.children())	a.push(String(_node.toString()));
			return a;
		}
		
		public function setSubstituteKey(key:String, value:String):void {
			Debug.debug(_debugPrefix, "Setting substitute key:",key,"to",value);
			_substituteKeys[key] = value;
		}
		public function deleteSubstituteKey(key:String):void {
			delete _substituteKeys[key];
		}
		
		
		
	// STYLING ///////////////////////////////////////////////////////////////////////////////////////
		public function styleTextNode(n:XML):String { // Grabs a node and 
			return UXml.formatNode(n);
		}
		
	// COORDINATES ///////////////////////////////////////////////////////////////////////////////////////
		public function getCoordinates(id:String):Rectangle {
			return ___coordinateNodes[id];
		}
		public function getCoordinatesPos(id:String):Object {
			return {x:___coordinateNodes[id].x, y:___coordinateNodes[id].y};
		}
		public function coordinatesContain(id:String, p:Point):Boolean {
			var c:Rectangle = ___coordinateNodes[id];
			return p.x > c.x && p.y > c.y && p.x < c.right && p.y < c.bottom;
		}
	// URLS ///////////////////////////////////////////////////////////////////////////////////////
		public function processUrl(id:String, par:Object=null):void {
			UCode.processLinkNode(_urls[id][0], par);
		}
		
	// ERRORS ///////////////////////////////////////////////////////////////////////////////////////
		public function getAction(id:String):XML { // returns the error node associated with code.
			// Errors are the LOCALE language, in the node ACTIONS. Each ACTION node is called with its code.
			return _words.ACTIONS[id][0];
		}
		
	// LOCATION ///////////////////////////////////////////////////////////////////////////////////////
		public function getLocation():String {
			return _locationCode;
		}
	// DYNAMIC NODES //////////////////////////////////////////////////////////////////////////////////
		public function getDynamicString(id:String, par:Object=null):String {
			if (par) {
				return UText.insertParams(_dynamic[id].toString(), par);
			}
			else {
				return _dynamic[id];
			}
		}
		public function getDynamicNode(id:String):XML {
			return _dynamic[id][0];
		}
		
		
		
		
		
		
		
// CONTENT ///////////////////////////////////////////////////////////////////////////////////////
// Used to manage standard content nodes
		public function getLocationSrcUrl(node:XML, useSubKeys:Boolean = true):String { // Gets a XML node with attribute src=...
			var src:String = String(node.@src);
			return getLocationSrcUrlFromString(src, useSubKeys);
			//return _contentSrcPrefix + (useSubKeys ? UText.insertParams(src, _substituteKeys) : src);
		}
		public function getLocationSrcUrlChildren(node:XML, useSubKeys:Boolean=true):Array { // Gets the list of all URLS in children nodes
			const a:Array = [];
			for each (var xx:XML in node.children()) a.push(getLocationSrcUrl(xx, useSubKeys));
			return a;
		}
		public function getLocationSrcUrlList(nodes:XMLList, useSubKeys:Boolean=true):Array { // Gets the list of all URLS in children nodes
			const a:Array = [];
			for each (var xx:XML in nodes) a.push(getLocationSrcUrl(xx, useSubKeys));
			return a;
		}
		public function getLocationSrcUrlFromString(baseUrl:String, useSubKeys:Boolean = true):String { // Gets a XML node with attribute src=...
			return _contentSrcPrefix + (useSubKeys ? UText.insertParams(baseUrl, _substituteKeys) : baseUrl);
		}
		
		
		
		
		
		
		
		
		
		
		
		
// GETTERS ///////////////////////////////////////////////////////////////////////////////////////
		public function get preferences():Object {
			return _preferences;
		}
		
		public function get requiredLocale():String {
			return _requiredLocale;
		}
		
		public function set requiredLocale(value:String):void {
			_requiredLocale = value;
		}
		
		public function get languageCode():String 
		{
			return _languageCode;
		}
		
		public function set languageCode(value:String):void 
		{
			_languageCode = value;
			// Cheangin defualt locale key to new language
			Debug.warning(_debugPrefix, "Changing [LOCALE] key in assets urls with " + _languageCode + "/");
			setSubstituteKey("LOCALE", _languageCode + "/");
		}
		
		public function get contentSrcPrefix():String 
		{
			return _contentSrcPrefix;
		}
		
		public function set contentSrcPrefix(value:String):void 
		{
			_contentSrcPrefix = value;
			Debug.warning(_debugPrefix, "All content URLs will have this as a prefix: " + value);
		}
// SETUP	///////////////////////////////////////////////////////////////////////////////////////
// EMBED RENDERING //////////////////////////////////////////////////////////////////////////////
// UTY ///////////////////////////////////////////////////////////////////////////////////////
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