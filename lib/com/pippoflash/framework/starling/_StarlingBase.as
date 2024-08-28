package com.pippoflash.framework.starling 
{
	import com.pippoflash.motion.PFMover;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	import com.pippoflash.utils.*;
	import starling.utils.Color;
	//import flash.net.NetConnection;
	//import flash.net.NetStream;
	import starling.display.Image;
	import starling.textures.Texture;
	import starling.assets.AssetManager;
	import com.pippoflash.framework._ApplicationStarling;
	import starling.text.*;
	
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * This is the main to extend for Starling singleton visual sprites.
	 */
	public class _StarlingBase extends Sprite {
		// DEBUG SWITCHES
		public static var LOADING_VERBOSE:Boolean = false;
		// STATIC REFERENCES
		static private var _mainApp:_ApplicationStarling;
		static private var _starlingCore:Starling;
		static private var _starlingApp:_StarlingApp;
		// STATIC UTILITIES
		private static var _mainAssets:AssetManager;
		private static var _mover:PFMover;
		static private var _uDisplay:_StarlingUDisplay;
		static private var _uMem:_StarlingUMem;
		// STATIC UTY
		static private var _instances:Vector.<_StarlingBase> = new Vector.<_StarlingBase>();
		static private var _instancesById:Object = {}; // Only for singletons
		static private var _instancesByClass:Dictionary = new Dictionary(true); // Only for singletons
		static private var _instancesListByClass:Dictionary = new Dictionary(true); // For multiple instances (non singleton) - contains arrays
		static private var _sharedMover:PFMover = new PFMover("_StarlingBase");
		//static private var _initialAssetsLoading:Array = []; // Stores a list of assets to be loaded at startup
		
		// Initial assets loading
		// SYSTEM
		protected var _debugPrefix:String = "StarlingApp"; // This might be changed by user.
		protected var _instanceId:String; // This is the initial id, can never be changed by user
		// STATIC INIT
		// INIT
		public function _StarlingBase(id:String, cl:Class, singleton:Boolean=true) {
			super();
			// Singleton error check
			if (singleton) {
				if (_instancesByClass[cl]) {
					Debug.error("_StarlingBase", "Error instantiating " + cl + ". It should be a singleton but already exists one. Aborting instantiation. THIS IS A SERIOUS SYSTEM ERROR.");
					return;
				}
				// Proceed with singleton initialization
				//_instanceId = id;
				_instanceId = _debugPrefix = id;
				_instancesById[id] = this;
				_instancesByClass[cl] = this;
				Debug.debug(_debugPrefix, "Starling Singleton Element Initialized: " + cl);
			} 
			else { // Multi instance initialization - Multi instances can have unique names, otherwise a number will be added at the end.
				if (!_instancesListByClass[cl]) _instancesListByClass[cl] = [];
				_instanceId = _debugPrefix = _instancesById[id] ? id + "." + _instancesListByClass[cl].length : id;
				_instancesListByClass[cl].push(this);
				_instancesById[_instanceId] = this;
				Debug.debug(_debugPrefix, "Starling Element Added: " + cl);
			}
			// Static initialization
			if (!_mainApp) { // This is the first instance to be initialized, therefore it handles general static initialization
				_mainApp = _ApplicationStarling.instance; // MainApp on regualr Flash Display List
				_starlingCore = Starling.current; // Current instance on Starling engine
				_mover = new PFMover("StarlingBase");
				_mainAssets = new AssetManager();
				_uDisplay = new _StarlingUDisplay();
				_uMem = new _StarlingUMem();
			}
			if (!_starlingApp) _starlingApp = _StarlingApp.instance; // Instance of the main starling app root
		}
		
		
		
		// ASSETS LOADING
		private var _onAssetsLoadSuccess:Function;
		private var _onAssetsLoadSuccessParam:Object;
		private var _onAssetsLoadError:Function;
		protected function loadAssetsList(paths:Array, onSuccess:Function, onSuccessParam:Object=null, onError:Function = null, useFullPathAsReference:Boolean=false):void {
			if (LOADING_VERBOSE) Debug.debug(_debugPrefix, "Loading assets list: " + paths);
			doLoadAssets(paths, onSuccess, onSuccessParam, onError, useFullPathAsReference);
		}
		protected function loadSingleAsset(path:String, onSuccess:Function, onSuccessParam:Object=null, onError:Function = null, useFullPathAsReference:Boolean=false):void { // This loads a single asset with a single callback
			if (LOADING_VERBOSE) Debug.debug(_debugPrefix, "Loading single asset: " + path);
			doLoadAssets(path, onSuccess, onSuccessParam, onError, useFullPathAsReference);
		}
		protected function unloadAssetUrl(url:String):void {
			if (LOADING_VERBOSE) Debug.debug(_debugPrefix, "Unloading Asset", url);
			mainAssets.removeTexture(getAssetTextureNameFromPath(url), true);
		}
		private function doLoadAssets(pathOrPaths:*, onSuccess:Function, onSuccessParam:Object=null, onError:Function = null, useFullPathAsReference:Boolean=false):void {
			if (_mainAssets.numQueuedAssets) {
				Debug.error(_debugPrefix, "AssetsManager busy loading. Aborting single asset load.");
				return;
			}
			if (LOADING_VERBOSE) Debug.debug(_debugPrefix, "Enqueing files: " + pathOrPaths);
			_onAssetsLoadSuccess = onSuccess;
			_onAssetsLoadSuccessParam = onSuccessParam;
			_onAssetsLoadError = onError;
			if (useFullPathAsReference) {
				if (LOADING_VERBOSE) Debug.debug(_debugPrefix, "Full file path is used as reference.");
				if (pathOrPaths is String) _mainAssets.enqueueSingle(pathOrPaths, pathOrPaths);
				else { // It is an array or vector of paths, looping through each
					for each (var path:String in pathOrPaths) _mainAssets.enqueueSingle(path, path);
				}
			}
			else _mainAssets.enqueue(pathOrPaths);
			_mainAssets.loadQueue(onAssetsLoadSuccess, onAssetsLoadError);
		}
		private function onAssetsLoadSuccess():void {
			if (LOADING_VERBOSE) Debug.debug(_debugPrefix, "Assets load operation complete.");
			// Storing and resetting callbacks before calling in case in callback another load operation is called.
			var success:Function = _onAssetsLoadSuccess;
			var par:Object =  _onAssetsLoadSuccessParam;
			resetAssetsLoadCallbacks();
			if (success) {
				if (par) success(par);
				else success();
			} else Debug.debug(_debugPrefix, "Success callback not defined.");
			
			
		}
		private function onAssetsLoadError():void {
			Debug.error(_debugPrefix, "Error in assets loading operation.");
			var error:Function = _onAssetsLoadError;
			resetAssetsLoadCallbacks();
			if (error) error();
		}
		private function resetAssetsLoadCallbacks():void {
			_onAssetsLoadSuccess = _onAssetsLoadError = null;
			_onAssetsLoadSuccessParam = null;
		}
		/**
		 * Removes file extension and path from file.
		 */
		protected function getAssetTextureNameFromPath(source:String):String {
			return source.split("/").pop().split(".")[0];
		}
		// GET IMAGES
		public function getImage(id:String, resizeRect:Rectangle=null, resizeMode:String="FILL"):Image {
			var img:Image = new Image(mainAssets.getTexture(id));
			if (resizeRect) uDisplay.resizeTo(img, resizeRect, resizeMode);
			return img;
		}
		public function getImageFromFullPath(id:String, resizeRect:Rectangle=null, resizeMode:String="FILL"):Image {
			return getImage(getAssetTextureNameFromPath(id), resizeRect, resizeMode);
		}
		
		
		
		
		
		// Textfields and Textformat
		//public function createTextField():void {
			//_textOptions = new TextOptions(false, false);
		//}
		//public function createTextFormat():void {
			//
		//}
		public function createTextField(r:Rectangle, txt:String, format:TextFormat = null, options:TextOptions = null):TextField {
			var t:TextField = new starling.text.TextField(r.width, r.height, txt, format, options);
			return t;
		}
		
		
			// Quick text creation
				//const textOptions = new TextOptions(false, false);
				//(textOptions as TextOptions).autoScale = true;
				////(textOptions as TextOptions).autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
				//const textFormat:TextFormat = new TextFormat("Athelas Regular", TXT_SIZE, 0xffffff);
				//textFormat.horizontalAlign = "left";
				//_headerTxt = new TextField(TXT_BOX_W, TXT_BOX_H, "Building", textFormat, textOptions);

		
			//if (!_titleFormat) {
				////_textOptions = new TextOptions(false, false);
				//_titleFormat  = new TextFormat("Avenir", TITLE_FONT_SIZE, TEXT_COLOR, "left", "top");
				//_subtitleFormat  = new TextFormat("Avenir LT Std 55 Roman", SUBTITLE_FONT_SIZE, TEXT_COLOR, "left", "top");
				//_subtitleFormat.leading = SUBTITLE_LEADING;
				//_mainFormat  = new TextFormat("Avenir LT Std 55 Roman", MAIN_FONT_SIZE, TEXT_COLOR, "left", "top");
				//_mainFormat.leading = MAIN_LEADING;
				////_navigator = new Navigator(1);
				////_navigator.x = _navigator.height / 2;
				////_navigator.scale = 1.2;
				//UMem.addClass(InfoBoxBullet);
				//UMem.addClass(InfoBoxLine);
				//UMem.addClass(InfoBoxPayoff);
				//
			//}
			////_allContent = new Sp
			//_mainContent = new Sprite();
			//_specialContent.x = TXT_RIGHT_X;
			//StarlingGesturizer.addSwipe(_mainContent, onContentSwipe, "LR");
			//var showBorders:Boolean = false;
			//var textY:int = 4;
			//// Add icon
			//// TITLE
			//_tfTitle = new TextField(TXT_LEFT_W, 10, "Title", _titleFormat, new TextOptions(true, false));
			//_tfTitle.autoSize = TextFieldAutoSize.VERTICAL;
			//_tfTitle.border = showBorders;
			//_tfTitle.y = textY;
			//_tfTitle.x = TXT_LEFT_X;
			//_mainContent.addChild(_tfTitle);
			//// SUBTITLE
			//_tfSubtitle = new TextField(TXT_LEFT_W, 300, "Subtitle<br/>Subtitle<br/>Subtitle", _subtitleFormat, new TextOptions(true, false));
			//_tfSubtitle.autoSize = TextFieldAutoSize.VERTICAL;
			//_tfSubtitle.isHtmlText = true;
			//_tfSubtitle.border = showBorders;
			//_tfSubtitle.y = 80;
			//_tfSubtitle.x = TXT_LEFT_X;
			//_mainContent.addChild(_tfSubtitle);
			//// MAIN
			//_tfMain = new TextField(TXT_RIGHT_W, 200, "Main Text<br/>Main Text<br/>Main Text", _subtitleFormat, new TextOptions(true, false));
			//_tfMain.autoSize = TextFieldAutoSize.VERTICAL;
			//_tfMain.isHtmlText = true;
			//_tfMain.border = showBorders;
			//_tfMain.y = textY;
			//_tfMain.x = TXT_RIGHT_X;
			//_mainContent.addChild(_tfMain);
			//// MAIN COL 2
			//_tfCol2 = new TextField(MAIN_COL2_W, 200, "Main Text<br/>Main Text<br/>Main Text", _subtitleFormat, new TextOptions(true, false));
			//_tfCol2.autoSize = TextFieldAutoSize.VERTICAL;
			//_tfCol2.isHtmlText = true;
			//_tfCol2.border = showBorders;
			//_tfCol2.y = textY;
			//_tfCol2.x = MAIN_COL2_X;
			//_mainContent.addChild(_tfCol2);
			//_tfCol2.visible = false;
		
		
		
		// TEXTFIELDS
		/**
		 * This is just a reference method to remember how TextFields ar emade in Starling.
		 * @return
		 */
		protected function makeTextField():TextField { 
			const textOptions:TextOptions = new TextOptions(false, false);
			(textOptions as TextOptions).autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
			//const textFormat:TextFormat = new TextFormat("Athelas Regular", 38, 0xffffff); // font name must be font + style
			const textFormat:TextFormat = new TextFormat("Noto Serif", 36, 0xffffff); // font name must be font + style
			//Noto Serif
			textFormat.horizontalAlign = "left";
			const txt:TextField = new TextField(200, 40, "Dummy Text", textFormat, textOptions);
			txt.border = true;
			return txt;
		}
		
		
		
		
		
		
		// STATIC GETTERS
		// App references
		static public function get mainApp():_ApplicationStarling {
			return _mainApp;
		}
		static public function get starlingCore():Starling {
			return _starlingCore;
		}
		static public function get starlingApp():_StarlingApp {
			return _starlingApp;
		}
		static public function get contentScale():Number {
			return _StarlingApp.contentScale;
		}
		
		// Utilities
		static public function get mainAssets():AssetManager {
			return _mainAssets;
		}
		static public function get mover():PFMover {
			return _mover;
		}
		static public function get uDisplay():_StarlingUDisplay {
			return _uDisplay;
		}
		static public function get originalRectangle():Rectangle {
			return UGlobal.getOriginalSizeRect();
		}
		// Markers
		/**
		 * Unique instance ID at startup.
		 */
		public function get instanceId():String 
		{
			return _instanceId;
		}
		
		static public function get uMem():_StarlingUMem 
		{
			return _uMem;
		}
		
		
		public function getInstanceById(id:String):_StarlingBase 
		{
			return _instancesById[id];
		}
		
		public function get isSingleton():Boolean {
			return _instancesById[_debugPrefix]; // This is populated only for singletons
		}
		
		// STATIC SETTERS
	}
}