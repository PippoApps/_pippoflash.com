/* UGlobal - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Manaes all informations about Global values.
- Stage sizes and alignment
- Focus management
- Main application links

*/

package com.pippoflash.utils {

	import									com.pippoflash.utils.*;
	import									com.pippoflash.motion.PFMover;
	import									com.pippoflash.framework.Ref;
	import									com.pippoflash.framework.PippoFlashEventsMan;
	import									flash.system.*;
	import									flash.display.*;
	import									flash.geom.*;
	import									flash.events.*;
	import									flash.utils.*;
	import									flash.text.TextField;
	
	public dynamic class UGlobal {
		// CONSTANTS
		// RENDER QUALITY CAN BE SET NUMERICALLY - 															0	1					2				3		4				5					6				7	
		private static const RENDER_QUALITIES		:Vector.<String> = new <String>["low",	"medium",	"high",	"best",	"8x8",	"8x8linear",	"16x16",	"16x16linear"]; 
		
// 		    BEST : String = "best"
// [static] Specifies very high rendering quality. 
// StageQuality 
//     HIGH : String = "high"
// [static] Specifies high rendering quality. 
// StageQuality 
//     HIGH_16X16 : String = "16x16"
// [static] Specifies very high rendering quality. 
// StageQuality 
//     HIGH_16X16_LINEAR : String = "16x16linear"
// [static] Specifies very high rendering quality. 
// StageQuality 
//     HIGH_8X8 : String = "8x8"
// [static] Specifies very high rendering quality. 
// StageQuality 
//     HIGH_8X8_LINEAR : String = "8x8linear"
// [static] Specifies very high rendering quality. 
// StageQuality 
//     LOW : String = "low"
// [static] Specifies low rendering quality. 
// StageQuality 
//     MEDIUM : String = "medium"
// [static] Specifies medium rendering quality. 

		// STATIC VARIABLES
		private static var _verbose					:Boolean = false;
		private static var _debugPrefix				:String = "UGlobal";
		// ACCESSIBLE VARS
		public static var _systemClass				:*; // System class where to call static methods for framework: _PippoFlashBase (but I do not want to import it if I do not use it)
		public static var _mainApp					:*; // Reference to the mainapp object. This has to be * since it could be anything, and we do not necessarily import everything.
		private static var _isDebug					:Boolean;
		public static var _sw						:Number;
		
		static public function get W():Number 
		{
			return _sw;
		}
		public static var _sh						:Number;
		
		static public function get H():Number 
		{
			return _sh;
		}
		public static var _x						:Number;
		public static var _y						:Number;
		private static var _centerPoint				:Point; // The absolute stage center point
		private static var _rootCenterPoint			:Point; // The center point used when rescaling root. This works for items within the root object.
		private static const _startCorner			:Point = new Point(0, 0); // Used for global to local
		private static var _endCorner				:Point; // Used for global to loacl. Assigned onResize...
 		public static var _shield					:*;
		public static var _shieldMethod				:Function; // If click on shield should trigger a method
		public static var _colorShield				:Sprite;
		public static var _global					:Object = {}; // Stores global variables
		public static var _stageAlign				:String; // This because I may need to read from it
		public static var _stageScaleMode			:String; // This because I may need to read from it
		public static var _renderQuality				:int = -1; // Sets the initial render quality (0 = best, 3 = minimum (high), 7 maximum, -1 default (unchanged));
		// UTY
		private static var _root					:DisplayObjectContainer;
		private static var _stage					:Stage;
		private static var _isSetup					:Boolean = false;
		private static var _isOnline					:Boolean = false;
		private static var _stageRect:Rectangle; // The complete stage rectangle, 0,0,stageWidth,stageHeight.
		private static var _stageResizeListeners		:Array = []; // Stores a list of listeners if stage is not defined. Once stage is defined, it will add listeners
		private static var _stageResizeDelay			:uint = 0; // I can set this, in order to have a delay so that on browser resizing its not triggered continuously, but only after user stopped resizing
		private static var _resizeTimeout			:*;
		private static var _fullScreenRect			:Rectangle; // The rectangle used for hardware accelerated fullscreen
		private static var _scrollRect				:Rectangle; // Sets it to the root since Stage does not have the scrollRect parameter. It shields the root and let us see through it.
		private static var _originalSizeRect			:Rectangle; // Stores the original size rect, with which it calculates all scalings and positions. It stays always the same is set only initially.
		static private var _relativeScaleX:Number; // Relative scaling to original size rect
		static private var _relativeScaleY:Number; // Relative scaling to original size rect
		static private var _relativeScaleChosen:Number; // Scaling is usually done using the msallest of sizes in order to preserve aspect ration. This stores the value.
		//private static var _resizeRect				:Rectangle; // This is set automatically, and will be then reset on resize. {x, y, w, h}; 
		//private static var _resizeScale				:Number = 1; // this is also set automatically. It give the best scaling according to positioning.
		//private static var _resizeScaleX				:Number = 1;
		//private static var _resizeScaleY				:Number = 1;
		// PLUGINS
		private static var _isSameDomain			:Boolean; // Marks if plugins are loaded in same application domain
		private static var _plugins					:Array;
		private static var _pluginInstances			:Array = []; // Stores the complete list of main plugins
		private static var _pluginInstancesById		:Object = {}; // Stores the complete list of main plugins by name ID
		private static var _pfInstancesPerPlugin		:Object = {}; // Stores the complete list of instances for each plugin for callOnAll in plugin. (plugins do not own static variables)
		private static var _pfInstancesPerPluginById	:Object = {}; // Stores the complete list of instances divided by instance id.
		private static var _pfUMemInstancesPerPluginById:Object = {}; // Stores the complete list of instances divided by instance id.
		private static var _pfPluginInstanceVars		:Object; // Sotres an object with _ref, etc, to bo fed to all instances of plugin
		// TOOLTIP
		private static var _toolTip:MovieClip; // Reference to the tooltip object
		private static var _toolTipActive				:Boolean = false; // If tooltip is active
		private static var _toolTipCaller				:*; // Stores the class or instance that calls the tooltip. If is defined, tooltip is removed only if the caller is the same as the remover
		// FRAMEWORK
// 		private static var _debugConsole			:*; // This holds a reference to main application debug console, so that the main console on host application in used
		private static var _isPlugin					:Boolean; // This marks if this is a plugin
		private static var _isMainApp				:Boolean = true; // This marks that we are the mainapp UGlobal
		private static var _containerUGlobal			:Class; // Register UGlobal received form container
		private static var _hostApp					:*; // register MainApp as HostApp - useful if not same domain
		private static var _UFramework				:Object; // Stores an object with ALL U[utility] from PippoFlash framework, so that plugin can access all host utilities, and vice-versa
		private static var _hostUFramework			:Object; // Grabs the framework from host
// SETUP & STAGE ///////////////////////////////////////////////////////////////////////////
		// This needs to be called before stage at instantiatiuon of main application
		public static function init(c:MovieClip):void { 
			if (_mainApp) {
				Debug.warning(_debugPrefix, "Already initialized, aborting init();");
				return;
			}
			_mainApp = c; // Mainapp can be setup even before stage is available
			_hostApp = c;
			_UBase.setMainApp(c);
			Debug.init();
			USystem.init();
			PFMover.init();
			Buttonizer.init();
			USound.init();
		}
		public static function setup(c:*, resizeDelay:uint = 500, stageAlign:String = null, stageScaleMode:String = null, originalStageSize:Rectangle=null) {
			if (_isSetup) {
				Debug.warning(_debugPrefix, "Already setup, aborting setup();");
				return;
			}
			if (!c.stage) {
				Debug.error(_debugPrefix, "Stage is not yet defined, retrying next frame.");
				UExec.next(setup, c, resizeDelay, stageAlign, stageScaleMode);
				return;
			}
// 			USystem.init						();
// 			PFMover.init						();
// 			Buttonizer.init						();
// 			PippoFlashEventsMan.init				();
			_hostUFramework = _UFramework		= {
				UGlobal:UGlobal,
				UText:UText,
				USound:USound,
				UMem:UMem,
				USystem:USystem,
				UCode:UCode,
				Buttonizer:Buttonizer,
				ULoader:ULoader
			}
			if (_isMainApp) Debug.initOnStage(_mainApp);
			_stageResizeDelay = resizeDelay;
			_root = _mainApp.root;
			_isOnline = _mainApp.root.loaderInfo.url.indexOf("file://") == -1 && _mainApp.root.loaderInfo.url.indexOf("app:/") == -1; // If file is not there, I assume we are online
			Debug.debug(_debugPrefix, "Setting up online status. Url is:",_mainApp.root.loaderInfo.url,"is swf in browser:",_isOnline);
			_isSetup = true;	
			Debug.debug(_debugPrefix, "Initialized on",c+". Resize is triggered after a delay of",_stageResizeDelay+". Align and scale mode are: "+stageAlign,stageScaleMode);
			setStage(c.stage, stageAlign, stageScaleMode, originalStageSize);
			initStageListener();
			_isDebug = _mainApp.isDebug ? _mainApp.isDebug() : false; //UCode.callMethod(_mainApp, "isDebug"); // Calling like this since mainapp could be anything
			if (USystem.isSwf()) { // Performs SWF only initializations (gives error in AIR)
				try {
					Security.allowDomain("*");
					Security.allowInsecureDomain("*");
				} catch (e:Error) {
					Debug.error(_debugPrefix, "Security.allowDomain('*') Error - this is an AIR app.");
				}
			}
			// check if I have scroll rect before setting root
			if (_scrollRect)						setupScrollRect(_scrollRect);
			// Call onResize() Immediately
			//onStageResize						();
		}
	// Sets the rectangle to be used as full screen area. It needs to be set in order to use hardware fullscreen.
	// If cutMask, the recatngle will also be masked (not yet implemented)
		public static function setupScreenRect		(rect:Rectangle, cutMask:Boolean=false):void {
			_fullScreenRect						= rect;
			//if (_stage)						_stage.fullScreenSourceRect = rect;
			_stage.fullScreenSourceRect = null;
			//if (cutMask)						setupScrollRect(_fullScreenRect);
		}
		public static function setupScrollRect			(rect:Rectangle):void {
			_scrollRect						= rect;
			if (_root)							_root.scrollRect = _scrollRect;
		}
// PLUGINS ///////////////////////////////////////////////////////////////////////////////////////
	// Called by the plugin to grab data from this UGlobal
		public static function registerSimplePlugin(plugin:*):void {
			// In this function I am the container
			Debug.debug(_debugPrefix, "Registering plugin: " + plugin);
			plugin.register(UGlobal);
			if (!_plugins) _plugins = [];
			_plugins.push(UCode.callMethodAlert(plugin, "getUGlobal"));
			confirmStageProperties();
		}
	// Called by the plugin himself on his UGlobal to tell him he is a plugin. The real UGlobal coming from container has to be used as single parameter of this.
		public static function setupAsPlugin(containerUGlobal:*):void {
			// This is called by MainApp in the UGlobal that should belong to the plugin. On same application domain, UGlobal IS the one from MainApp.
			Debug.debug(_debugPrefix, "Setting up as Plugin...");
			_containerUGlobal = containerUGlobal;
			// This is NOT working if same application domain
			if (containerUGlobal.mainApp == _mainApp) { // I am in the same application domain, that means NOTHING has to be replaced because this UGlobal is the HOST APP UGlobal!
				// Or, I am myself the plugin registering in standalone
				// I am still the mainApp UGlobal - therefore nothing changes much.
				Debug.debug(_debugPrefix, "Setting up plugin in same application domani. I am the MainApp UGlobal.");
				_isPlugin = false;
				_isMainApp = true;
				_hostUFramework = getFramework();
				_isSameDomain = true;
			}
			else {
				// In this function I am the plugin
				Debug.debug						(_debugPrefix, "Setting up plugin in different application domain. I am the plugin UGlobal.");
				_isPlugin							= true;
				_isMainApp						= false;
				UCode.callMethodAlert				(_containerUGlobal, "setPropertiesInPluginUGlobalBeforeSetup", UGlobal);
				setup							(containerUGlobal.mainApp, 0, containerUGlobal._stageAlign, containerUGlobal._stageScaleMode);
				if (containerUGlobal.getToolTip())		UGlobal.registerToolTip(containerUGlobal.getToolTip());
				if (containerUGlobal.getDebugConsole())	Debug.setupConsole(containerUGlobal.getDebugConsole());
				setOriginalSize						(containerUGlobal.getOriginalSizeRect());
				setupScrollRect						(containerUGlobal.getScrollRect());
				if (containerUGlobal.getFullScreenRect())	setupScreenRect(containerUGlobal.getFullScreenRect());
				_hostUFramework					= UCode.callMethodAlert(_containerUGlobal, "getFramework");
			}
		}
				public static function setPropertiesInPluginUGlobalBeforeSetup(pluginUGlobal:*):void {
					// In this function I am the container
					// Called by plugin, when I am container, to grab my properties. I have to set properties in plugin UGLobal before it is setup.
					// Render quality gets changed only if variable is set differently than -1 (between 0 and 7)
					if (_renderQuality >= 0 && _renderQuality <= 7)		pluginUGlobal._renderQuality = _renderQuality;
				}
// 	// Called in host app. Calls a method in ALL uGlobals from plugins. - I am container.
		private static function callPluginsMethod		(method:String, ...pars):void {
			if (_plugins && _isMainApp) { // Only main apps can do this
				for each (var uGlobal:* in _plugins)	UCode.callMethodArray(uGlobal, method, pars);
			}
		}
	// Called by plugin to retrieve container uglobal
	// I am plugin, if I call uGlobal with small u it will be the container UGlobal. Otherwise it defaults on plugin UGlobal if standalone.
		public static function get uGlobal			():* {
			return							_containerUGlobal ? _containerUGlobal : UGlobal;
		}
	// PLUGIN INSTANCES REGISTRATION
		public static function registerNewPlugin		(id:String, plugin:*):void {
			// Proceed registering plugin
			if (_pluginInstancesById[id] || _pluginInstances.indexOf(plugin) != -1) { // Plugin has already been registered
				Debug.error				(_debugPrefix, "Trying to register plugin",id,"but it is already registered.");
				return;
			}
			// This is calle din plugin instantiation. In standalone mode, this maybe the first call UGlobal receives.
			if (!_isSetup) {
				setup						(plugin);
				setupSystemClass				(plugin.getSystemClass(), {_plugin:plugin, _ref:new Ref(), _mainApp:null, _config:null, _uGlobal:UGlobal});
			}
			// Proceed setting up main plugin
			Debug.debug						(_debugPrefix, "Registering PLUGIN",id);
			_pluginInstances.push				(plugin); // the main plugin
			_pluginInstancesById[id]				= plugin; // The main plugin
			_pfInstancesPerPlugin[id]				= []; // All instances related to that plugin
			_pfInstancesPerPluginById[id]			= {}; // All instances related to plugin divided by id
			_pfUMemInstancesPerPluginById[id]		= {};
			// Now i setup all variables in PLUGIN
			setCommonVariablesInPluginInstance		(id, plugin);
		}
		public static function registerPluginInstance	(pluginId:String, instanceId:String, instance:*):void {
// 			trace("REGGISTRO",pluginId,instanceId,instance);
			if (pluginDoesntExist(pluginId, "registerPluginInstance("+instanceId+")", instance))			return;
			Debug.debug						(_debugPrefix, "Registering Plugin INSTANCE",pluginId,instanceId);
			_pfInstancesPerPlugin[pluginId].push		(instance);
			_pfInstancesPerPluginById[pluginId][instanceId] = instance;
			// Now i setup all variables in instance
			setCommonVariablesInPluginInstance		(pluginId, instance);
		}
		public static function registerpluginInstanceUMem(pluginId:String, instanceId:String, instance:*):void {
			if (pluginDoesntExist(pluginId, "registerPluginInstanceUMem("+instanceId+")", instance)) return;
			if (!_pfUMemInstancesPerPluginById[pluginId][instanceId]) _pfUMemInstancesPerPluginById[pluginId][instanceId] = [];
			if (_pfUMemInstancesPerPluginById[pluginId][instanceId].indexOf(instance) == -1) _pfUMemInstancesPerPluginById[pluginId][instanceId].push(instance);
			setCommonVariablesInPluginInstance		(pluginId, instance);
		}
				private static function setCommonVariablesInPluginInstance(pluginId:String, instance:*):void { // Sets in plugin and plugin instances the variables needed
					// Used variables: _mainApp, _ref, _plugin, _config, _uGlobal
					// Now i setup all variables in PLUGIN - Plugin is set dynamically since it can be different
					_pfPluginInstanceVars._plugin	= _pluginInstancesById[pluginId];
					UCode.setParameters		(instance, _pfPluginInstanceVars);
				}
	// PLUGINS METHODS MANAGEMENT
		public static function collOnAllPluginInstances	(pluginId:String, method:String, par:*=null):void {
			if (pluginDoesntExist(pluginId, "callOnAll", method)) return;
			// Calls on all instances and ALSO on plugin itself
			if (par) {
				UCode.callMethod(_pluginInstancesById[pluginId], method, par);
				UCode.callMethodList(_pfInstancesPerPlugin[pluginId], method, par);
			}
			else {
				UCode.callMethod(_pluginInstancesById[pluginId], method);
				UCode.callMethodList(_pfInstancesPerPlugin[pluginId], method);
			}
		}
		public static function getPluginInstance(pluginId:String, instanceId:String):* {
			if (pluginDoesntExist(pluginId, "getPluginInstance", instanceId)) return;
			return _pfInstancesPerPlugin[pluginId][instanceId]
		}
	// PLUGINS INTERNAL UTY
		private static function pluginDoesntExist(pluginId:String, operation:String="NO OPERATION", object:*=null):Boolean {
			if (!_pluginInstancesById[pluginId]) {
				Debug.error				(_debugPrefix, "Performing", operation ? operation : "" ,object?object:"","on plugin",pluginId,"but Plugin has never been registered. Call registerNewPlugin() first!!!");
				return true;
			}
			return false;
		}
		
// STAGE MENEGEMENT AND LISTENERS ///////////////////////////////////////////////////////////////////////////////////////		
	// This is needed in order to have a real reference of initial sizes (size in browser can be set with empbed)
	// Call this in MainApp constructor
		public static function setOriginalSize(r:Rectangle):void {
			Debug.debug(_debugPrefix, "setOriginalSize", r);
			if (_originalSizeRect) Debug.warning(_debugPrefix, "setting original size rect for the second time (Use _Application._originalStageSize variable instead)");
			_originalSizeRect = r;
			_rootCenterPoint = new Point(Math.round(_originalSizeRect.width/2), Math.round(_originalSizeRect.height/2));
			if (_isSetup) {
				resetStageSizes();
				callPluginsMethod("setOriginalSize", r);
			}
		}
	// This is called by INIT
		private static function setStage(s:Stage, stageAlign:String=null, stageScaleMode:String=null, originalStageSize:Rectangle=null) {
			Debug.debug(_debugPrefix, "setStage()");
			if (!s) {
				Debug.error(_debugPrefix, "Stage is not defined. Cannot proceed setting up stage.");
				return;
			}
			else if (_stage) {
				Debug.error(_debugPrefix, "Stage is already defined. Second call aborted.");
				return;
			}
			// Proceed
			_originalSizeRect = originalStageSize;
			if (!_originalSizeRect) {
				Debug.debug(_debugPrefix, "_Application._originalStageSize was not defined. Using actual stage size as reference.");
				_originalSizeRect = new Rectangle(0, 0, s.stageWidth, s.stageHeight);
			} else Debug.debug(_debugPrefix, "Original stage size: " + _originalSizeRect);
			_stage = s;
			_stageAlign = stageAlign ? stageAlign : _stage.align; // Defaults to stage properties (if this is loaded externally doesn't need to mess up with things)
			_stageScaleMode = stageScaleMode ? stageScaleMode : _stage.scaleMode; // Defaults to resize
			_stage.align = _stageAlign;
			_stage.scaleMode = _stageScaleMode;
			setRenderQuality(_renderQuality);
			// Check if I have a fullScreenRect setup
			if (_fullScreenRect) setupScreenRect(_fullScreenRect);
			resetStageSizes();
			initShields();
			triggerResize();
			callOnStageFunctions();
		}
	// This can be called after loading an external SWF that messes up stage aling properties, it confirms the memorized stage align params
		public static function confirmStageProperties():void {
			_stage.align = _stageAlign;
			_stage.scaleMode = _stageScaleMode;
		}
		public static function setStageResizeDelay(n:uint):void {
			// This is useful to prevent browsers sending a lot of onresize while resizing. It will be triggered only after a while onresize has stopped.
			_stageResizeDelay = n;
		}
		
		public static function resetStageSizes(e:*= null) {
			// Resets internal stage sizes to real stage dimensions
			var x:int = 0; var y:int = 0; _stageRect = new Rectangle(0, 0, _stage.stageWidth, _stage.stageHeight);
			Debug.debug(_debugPrefix, "resetStageSizes();",_stageRect);
			// Here I have to fix the stage align bug
			if (_stage.align != StageAlign.TOP_LEFT && _originalSizeRect) {
				Debug.debug(_debugPrefix, "Stage alignment is: " + _stage.align + ", therefore I have to adjust X and Y values according to alignment to overcome stage positioning bug.");
				// Perform horizontal adjustments
				if (_stage.align == StageAlign.TOP || _stage.align == StageAlign.BOTTOM) {
					// Stage is HORIZONTALLY CENTERED
					x = (_originalSizeRect.width - _stage.stageWidth) /2;
				}
				else if (_stage.align == StageAlign.TOP_RIGHT || _stage.align == StageAlign.BOTTOM_RIGHT) {
					// Stage is HORIZONTALLY RIGHT
					x = (_originalSizeRect.width - _stage.stageWidth);
				}
				// Perform vertical adjustments - there is no MIDDLE alignment vertically
				if (_stage.align == StageAlign.BOTTOM || _stage.align == StageAlign.BOTTOM_RIGHT || _stage.align == StageAlign.BOTTOM_LEFT) {
					// Stage is HORIZONTALLY RIGHT
					y = (_originalSizeRect.height - _stage.stageHeight);
				}
			}
			setCustomStageSizes(x, y, _stage.stageWidth, _stage.stageHeight);
		}
		public static function setCustomStageSizes(x:Number, y:Number, w:Number, h:Number):void {
			Debug.debug(_debugPrefix, "setCustomStageSizes",x,y,w,h);
			// Overwrites stage dimensions with custom stage dimensions
			_x = Math.round(x); _y = Math.round(y); _sw = Math.round(w); _sh = Math.round(h); 
			Debug.debug(_debugPrefix, "Rounded to",_x,_y,_sw,_sh);
			_centerPoint = new Point(_x+Math.round(_sw/2),_y+Math.round(_sh/2));
			_rootCenterPoint = new Point(_centerPoint.x, _centerPoint.y);
			_stageRect = new Rectangle(_x,_y,_sw,_sh);
			_endCorner = new Point(_sw, _sh);
			// Compute scaling according to original size rect - only if it has been defined
			_relativeScaleX = _originalSizeRect ? _stageRect.width / _originalSizeRect.width : 1; 
			_relativeScaleY = _originalSizeRect ? _stageRect.height / _originalSizeRect.height : 1;
			_relativeScaleChosen = _relativeScaleY < _relativeScaleX ? _relativeScaleY : _relativeScaleX; // The smallest scale is the one dictating
			Debug.warning(_debugPrefix, "Relative scaling is " + _relativeScaleX,_relativeScaleY);
		}
		private static function initStageListener		():void {
			// Automatica resizing is handled only in container app, not in plugins
			if (_isMainApp) {
				_stage.addEventListener(Event.RESIZE, onStageResize);
			}
		}
			public static function onStageResize		(e:Event=null):void {
				if (_stageResizeDelay) { // Delay is >0, therefore I add the delay functions
					activateTimeout				();
				} else {
					triggerResize				();
				}
			}
				private static function activateTimeout():void {
					if (_resizeTimeout != null) clearTimeout(_resizeTimeout);
					_resizeTimeout = setTimeout(triggerResize, _stageResizeDelay);
				}
				private static function triggerResize	():void {
					/* FIX STAGE ALIGN BUG
						- If stage is not aligned TOP_LEFT, it will get centered. Reported size is correct, but 0,0 will originate from MOVED corner. Therefore popup centering will not work.
						- Here, using original size rect, I am going to deduct according to scalemode, how to determin offset */
					Debug.debug(_debugPrefix, "triggerResize()");
					resetStageSizes				();
					updateShieldSize				();
					_resizeTimeout				= null;
					if (_verbose) USystem.report(true);
					Debug.debug				(_debugPrefix, "Stage resized: ", _stageRect, "center point", _centerPoint, "root center point",_rootCenterPoint, "alignment", _stage.align, "scale mode", _stage.scaleMode, "Scale factor:"+_stage.contentsScaleFactor);
					for each (var f:Function in _stageResizeListeners) {
						f();
					}
				}
		public static function addResizeListener(func:Function) { // Adds a listener for a resize event, only if listener is not already there
			if (_stageResizeListeners.indexOf(func) == -1) _stageResizeListeners.push(func);
		}
		public static function removeResizeListener(func:Function):void {
			if (_stageResizeListeners.indexOf(func) != -1) UCode.removeArrayItem(_stageResizeListeners, func);
		}
		public static function resizeToStage(c:DisplayObject) {
			c.width = _sw; c.height = _sh;
		}
		public static function getOriginalSizeRect():Rectangle {
			return _originalSizeRect;
		}
		public static function getStageRect():Rectangle { // Returns a rect with real stage dimensions
			return _stageRect.clone();
		}
		public static function getScrollRect():Rectangle { // It a scroll rect used to MASK the entirre stage using a scrollRect
			return _scrollRect;
		}
		public static function getFullScreenRect():Rectangle { // Returns the rectangle that CAN BE set as stage enlargement. Only if it is set.
			return _fullScreenRect;
		} 
		static public function getContentScale():Number { // Calculates scaling for content according to _originalScreenRect and _stageRect differences
			// This only works when content is set to NO_SCALE
			//var xSc:Number = _stageRect.width / _originalSizeRect.width; 
			//var ySc:Number = _stageRect.height / _originalSizeRect.height; 
			//return xSc < ySc ? xSc : ySc; // Returns the smallest scale, which is the one content should conform
			return _relativeScaleChosen;
			//return _relativeScaleX < _relativeScaleY ? _relativeScaleX : _relativeScaleY; // Returns the SMALLEST scale
		}
		static public function getContentScaleY():Number { // Returns relative scaling on Y axis only
			return _relativeScaleY;
		}
		static public function getContentScaleX():Number { // Returns relative scaling on X axis only
			return _relativeScaleX;
		}
		static public function scaleObjectToContent(o:Object):void { // Gets any object and sets it's sclaeX and scaleY properties to optimal scale
			o.scaleX = o.scaleY = _relativeScaleChosen;
		}
		static public function getContentOffset():Object { // Returns the offset of content acccording to scale. This only works in NO_SCALE
			// Returns an Object applicable to a display object: {scaleX, scaleY, x, y}
			var scale:Number = getContentScale();
			var xOff:int = Math.round((_stageRect.width  - Math.round(_originalSizeRect.width * scale))/2);
			var yOff:int = Math.round((_stageRect.height - Math.round(_originalSizeRect.height * scale))/2);
			return {scaleX:scale, scaleY:scale, x:xOff, y:yOff};
		}
		static public function getRelativeY(y:Number):Number { // Returns Y position according to original size * real stage size - CAREFUL: This is not the optimal scale.
			return y * _relativeScaleY;
		}
		static public function getRelativeX(x:Number):Number { // Returns Y position according to original size * real stage size -  CAREFUL: This is not the optimal scale.
			return x * _relativeScaleX;
		}
		static public function getRelativePos(n:Number):Number { // Returns value scaled with the optimal chosen dimension
			return n * _relativeScaleChosen;
		}
		static public var scaleValueToContent:Function = getRelativePos; // Easier to find name
		static public function scaleValuesToContent(values:Object, duplicate:Boolean = false):Object {
			// If duplicate returns a new object
			var o:Object = duplicate ? {} : values;
			for (var id:String in o) o[id] = o[id] * _relativeScaleChosen;
			return o;
		}
		
		
		
		public static function getCenterPoint():Point { // Gets the center point relative to stage only. It is absolute in stage coordinastes.
			return _centerPoint.clone();
		}
		public static function getRootCenterPoint():Point { // Gets the center point relative to ROOT coordinates. That means it works on resizing.
			return _rootCenterPoint.clone();
		}
	/* TO BE DEBUGGED */
		public static function getRelativeStageRect		(c:DisplayObject):Rectangle { // Returns a rectangle with position relative to the coordinate space of container clip
// 			return							c.parent.getRect(c);
			var topLeft:Point = c.globalToLocal(_startCorner);
			var bottomRight = c.globalToLocal(_endCorner);
			bottomRight.x += topLeft.x > 0 ? -topLeft.x : Math.abs(topLeft.x);
			bottomRight.y += topLeft.y > 0 ? -topLeft.y : Math.abs(topLeft.y);
			return							new Rectangle(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
			
			var newStart						:Point = c.globalToLocal(_startCorner);
			var newEnd						:Point = c.globalToLocal(_endCorner);
			var w							:Number = newStart.x > 0 ? newEnd.x - newStart.x : newEnd.x + Math.abs(newEnd.x);
			var h							:Number = newStart.y > 0 ? newEnd.y - newStart.y : newEnd.y + Math.abs(newEnd.y);
			var rect							:Rectangle = new Rectangle(newStart.x, newStart.y, w, h);
			return							rect;
		}
		public static function getRelativeStageCenterPoint(c:DisplayObject):Point {
			return							c.globalToLocal(_centerPoint);
		}
// GETERS /////////////////////////////////////////////////////////////////////////////////////////////
		public static function get originalW():int {
			return _originalSizeRect.width;
		}
		public static function get originalH():int {
			return _originalSizeRect.height;
		}
		public static function get originalSizeRect():Rectangle {
			return _originalSizeRect.clone();
		}
		/**
		 * Returns the stage dimensions in coordinates space of resized original size rect.
		 * @param	verticalScaleReference Use vertical scale as reference. False to use horizontal scale.
		 * @return
		 */
		public static function getStageRectProportional(verticalScaleReference:Boolean=true):Rectangle {
			var r:Rectangle = originalSizeRect;
			if (verticalScaleReference) r.width = _sw / _relativeScaleY;
			else r.height = _sh / _relativeScaleX;
			return r;
		}
// STAGE INITIALIZATION ///////////////////////////////////////////////////////////////////////////////////////
		private static var _callOnStageFunctions		:Array = new Array();
		public static function callOnStage			(f:Function):void { 
			// A list of functions to be activated once stage is available.
			// Stage availability is not set directly, but called by a mainApp.
			// Whatever is initalized automatically and relie on stage needs to be initialized by this.
			// If stage is already setup function is called immediately
			if (_isSetup)						f();
			else								_callOnStageFunctions.push(f);
		}
		private static function callOnStageFunctions		():void {
			if (_callOnStageFunctions.length == 0)		return; // No functions to call
			for (var i:uint=0; i<_callOnStageFunctions.length; i++) {
				_callOnStageFunctions[i]			();
			}
			_callOnStageFunctions					= new Array();
		}
// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		/**
		 * Called by any interaction in order to reset screen saver count.
		 * Each new interactive object that doesn't use Buttonizer or Gesturizer should call this on interaction in order to reset screen saver count.
		 */
		static public function resetScreenSaverCount():void {
			UMethod.callMethodName(_mainApp, "resetScreenSaverCount");
		}
// FRAMEWORK ACTIONS ///////////////////////////////////////////////////////////////////////////////////////
		public static function setupSystemClass		(cl:Class, pluginVars:Object=null):void { // This needs to be called with _PippoFlashBase as argument
			// Varibales for plugins can be also set manually
			_systemClass						= cl;
			_pfPluginInstanceVars				= pluginVars ? pluginVars : {_ref:_systemClass._ref, _mainApp:_systemClass._mainApp, _config:_systemClass._config, _hostApp:_systemClass._mainApp, _uGlobal:UGlobal};
		}
		public static function getSystemClass			():Class {
			return							_systemClass;
		}
		public static function callSystem			(funcName:String, par:*=null):void {
			// If we are working on PippoFlash framework, it calls a method in all components inheriting from _PippoFlashBase
			if (_systemClass)					_systemClass.callOnAll(funcName, par);
			else								Debug.debug(_debugPrefix, "ERROR: _systemClass not defined, can't call",funcName+"()");
		}
	// FRAMEWORK ELEMENTS
		public static function getFramework			():Object {
			return							_UFramework;
		}
		public static function getFrameworkItem		(id:String):* {
			if (_UFramework[id])				return _UFramework[id];
			else {
				Debug.error					(_debugPrefix, "Framework item",id,"not found.");
			}
		}
		public static function getHostFrameworkItem	(id:String):* {
			if (_hostUFramework[id])				return _hostUFramework[id];
			else {
				Debug.error					(_debugPrefix, "HOST Framework item",id,"not found.");
			}
		}
// GLOBAL LINKS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		public static function setGlobal(name:String, obj:*):void {
			_global[name] = obj;
		}
		public static function getGlobal(name:String):* {
			return _global[name] || null;
		}
		public static function removeGlobal(name:String):void {
			delete _global[name];
		}
// FOCUS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		public static function resetFocus() {
			_stage.focus = null;
		}
		public static function setFocus(t:TextField):void {
			_stage.focus = t;
		}
		public static function setFocusAndSelectAll(t:TextField):void {
			_stage.focus = t;
			t.setSelection(0, t.text.length);
		}
// SHIELDING ///////////////////////////////////////////////////////////////////////////////////////
		public static function setStageShield(b:Boolean, onClick:Function=null):* {
			// If onClick function is triggered, shield is NOT removed
			if (b) {
				updateShieldSize();
				stage.addChild(_shield);
				if (Boolean(onClick)) {
					_shieldMethod = onClick;
					Buttonizer.setupButton(_shield, UGlobal, "AutomaticShield", "onPress");
				}
				return _shield;
			}
			else {
				_shieldMethod = null;
				Buttonizer.removeButton(_shield);
				UDisplay.removeClip(_shield);
			}
		}
		public static function setStageShieldColor(b:Boolean, col:uint=0xffffff, fade:Boolean=false, alpha:Number=1, frames:uint=10, onClick:Function=null):void {
			if (b) {
				updateShieldSize();
				UDisplay.setClipColor(_colorShield, col);
				_colorShield.alpha = alpha;
				stage.addChild(_colorShield);
				if (Boolean(onClick)) {
					_shieldMethod = onClick;
					Buttonizer.setupButton(_colorShield, UGlobal, "AutomaticShield", "onPress");
				}
				if (fade) {
					_colorShield.alpha = 0;
					PFMover.fadeTo(_colorShield, alpha, frames);
				}
			}
			else {
				Buttonizer.removeButton(_colorShield);
				_shieldMethod = null;
				if (fade) PFMover.fadeOutAndKill(_colorShield, frames);
				else UDisplay.removeClip(_colorShield);
			}
		}
				public static function onPressAutomaticShield(c:DisplayObject):void {
					// Method can be called several times. Shield must be manually switched off.
					if (Boolean(_shieldMethod)) {
						_shieldMethod();
					}
				}
		private static function initShields				():void {
			_colorShield						= UDisplay.getSquareMovieClip(_sw, _sh);
			_shield							= UDisplay.getSquareMovieClip(_sw, _sh);
			_shield.alpha						= 0;
		}
		private static function updateShieldSize			():void {
			_colorShield.width = _shield.width = _sw; _colorShield.height = _shield.height = _sh;
		}
// QUALITY ///////////////////////////////////////////////////////////////////////////////////////
		public static function setRenderQuality		(q:int):void {
			// 0 = best, 3 = minimum.
			if (q < 0) {
				Debug.debug					(_debugPrefix, "Render quality has not been set, using default one: " + _stage.quality);
				return;
			}
			if (q > RENDER_QUALITIES.length-1)		q = RENDER_QUALITIES.length-1;
// 			var qualities						:Array = ["best","high","medium","low"];
			var quality							:String = RENDER_QUALITIES[q];
			Debug.debug						(_debugPrefix, "Setting render quality to",quality);
			_renderQuality = q;
			_stage.quality						= quality;
		}
		public static function getRenderQuality():String {
			return RENDER_QUALITIES[_renderQuality];
		}
// MOUSE EVENTS //////////////////////////////////////////////////////////////////////////////////////
		public static function addStageOnMouseUp		(f:Function) {
			if (_stage)						_stage.addEventListener(MouseEvent.MOUSE_UP, f);
		}
		public static function removeStageOnMouseUp	(f:Function) {
			if (_stage)						_stage.removeEventListener(MouseEvent.MOUSE_UP, f);
		}
		public static function addMouseMoveListener	(f:Function):void {
			if (_stage)						_stage.addEventListener(MouseEvent.MOUSE_MOVE, f);
		}
		public static function removeMouseMoveListener(f:Function):void {
			if (_stage)						_stage.removeEventListener(MouseEvent.MOUSE_MOVE, f);
		}
		public static function mouseIsOnTop			(o:DisplayObject, shape:Boolean=false):Boolean { // If mouse is on top of the displayobject
			return							o.hitTestPoint(_stage.mouseX, _stage.mouseY, shape);
		}
// UTILITIES ///////////////////////////////////////////////////////////////////////////////////////
		public static function isLocal				():Boolean {
// 			Debug.debug						(_debugPrefix, "Test _isSetup", _isSetup, _isOnline, !_isOnline);
			return							!_isOnline;
// 			if (_isSetup) {
// 				Debug.debug						(_debugPrefix, "Test _root", _root);
// 				Debug.debug						(_debugPrefix, "Test _root.loaderInfo", _root.loaderInfo);
// 				Debug.debug						(_debugPrefix, "Test _root.loaderInfo.url", _root.loaderInfo.url);
// 			}
// 			return							_isSetup ? _root.loaderInfo.url.indexOf("file://") != -1 : true;
		}
		public static function isOnline				():Boolean {
			return							_isOnline;
// 			return							!isLocal();
		}
		public static function urlContains			(s:String):Boolean {
			return							_isSetup ? _root.loaderInfo.url.indexOf(s) != -1 : false;
		}
		public static function getUrl				():String {
			return							_isSetup ? _root.loaderInfo.url : "UGlobal not yet initialized.";
		}
// FULLSCREEN ///////////////////////////////////////////////////////////////////////////////////////
		public static function setFullScreen(f:Boolean=true, stage:Stage=null):void {
			// Check if I can add the rectangle
			stage = stage ? stage : _stage;
			stage.fullScreenSourceRect = null;
			// Be careful, if this is not execuded by a user event, it will trigger a security error
			if (USystem.isAir()) stage.displayState = f ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
			else stage.displayState = f ? StageDisplayState.FULL_SCREEN : StageDisplayState.NORMAL;
		}
		public static function toggleFullScreen			():void {
			setFullScreen						(!isFullScreen());
		}
		public static function isFullScreen(stage:Stage=null):Boolean {
			stage = stage ? stage : _stage;
			return stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE || stage.displayState == StageDisplayState.FULL_SCREEN;
		}
// TOOLTIP ///////////////////////////////////////////////////////////////////////////////////////
		public static function registerToolTip(c:MovieClip):void {
			_toolTip = c;
			_toolTipActive = true;
		}
		public static function setToolTip(v:Boolean, s:String=null, callerId:*=null):void {
			if (_toolTipActive) {
				if (v) {
					_toolTip.followMouseTip(s);
					_toolTipCaller = callerId;
				}
				else {
					removeToolTip(callerId);
				}
			}
			else {
				if (_verbose) Debug.debug(_debugPrefix, "ToolTip inactive"+(s ? ": "+s : ""));
				_toolTipCaller = callerId;
			}
		}
		public static function removeToolTip(callerId:*=null):void {
			if (_toolTip && _toolTipActive && _toolTipCaller == callerId) {
				_toolTip.hideTip(callerId);	
				_toolTipCaller= null;
			}
		}
		public static function setToolTipActive(a:Boolean):void {
			if (!a) setToolTip(false);
			_toolTipActive = a;
		}
		public static function getToolTip():MovieClip {
			return _toolTip;
		}
	// TOOLTIP STATIC, NOT MOVING WITH MOUSE
		static public function setToolTipStatic(txt:String, position:Point, removeId:String=null, invertY:Boolean=false):void { // Sets the tooltip fixed in a position
			if (_toolTip && _toolTipActive) {
				_toolTip.showStillTip(txt, position, removeId, invertY);
			} else Debug.error(_debugPrefix, "setToolTipStatic() fail. ToolTip not defined or not active.");
		}
		static public function hideToolTipStatic(id:String):void {
			if (_toolTip && _toolTipActive) {
				_toolTip.hideTip(id);
			}
		}
// GETTERS/SETTERS ///////////////////////////////////////////////////////////////////////////////////////
		public static function get mainApp				():* {
			if (_mainApp)						return _mainApp;
			else 								Debug.error(_debugPrefix, " someone requested mainApp, but mainApp variable is not defined!!!!!!");
			return							null;
		}
		public static function get stage				():Stage {
			// This returns _stage. If not defined it warns me
			if (_isSetup)						return _stage;
			else {
				Debug.error					(_debugPrefix, " someone requested stage, but _stage variable is not defined!!!!!!");
				return						null;
			}
		}
		public static function get root				() {
			if (_isSetup)						return _root;
			else								Debug.debug(_debugPrefix, "someone called _root but nothing is defined yet");
		}
		public static function get stageRect			():Rectangle {
			return							_stageRect.clone();
		}
		public static function get centerPoint			():Point {
			return							_centerPoint;
		}
		static public function get isDebug():Boolean 
		{
			return _isDebug;
		}
// CHECKS ///////////////////////////////////////////////////////////////////////////////////////
		public static function isSetup				():Boolean {
			return							_isSetup;
		}
		public static function isDeploy():Boolean {
			if (_mainApp.isDeploy && _mainApp.isDeploy is Function) return _mainApp.isDeploy();
			else {
				Debug.warning(_debugPrefix, "This is not a PF Application, so it is always considered in deploy mode");
				return true;
			}
		}
// MAINAPP TUNNELING ///////////////////////////////////////////////////////////////////////////////////////
	// Sometimes other static variables should use methods stored in Application. Tunneling can happen through here.
		static public function writeSOData(varName:String, value:*):void {
			if (_mainApp) {
				try {
					_mainApp.setSharedObject(varName, value);
				} catch (e:Error) {
					Debug.debug(_debugPrefix, "writeSOData() fail: " + e);
				}
			}
		}
		static public function readSOData(varName:String):* {
			if (_mainApp) {
				try {
					var value:* = _mainApp.getSharedObject(varName, value);
					return value;
				} catch (e:Error) {
					Debug.debug(_debugPrefix, "readSOData() fail: " + e);
				}
			}
		}
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