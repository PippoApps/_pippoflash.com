/* LoaderUtils - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
0.15 - getPathFromString(origin:DisplayObject, path:String); // Converts a string "parent.parent.clip3" into a reference.

*/

package com.pippoflash.utils {
	
	//import com.pippoflash.movieclips.loaders.ILoader;
	import com.pippoflash.movieclips.loaders.CircleLoader; // Default used loader
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.movieclips.loaders._LoaderBase;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	import com.pippoflash.net.QuickLoader;
	import fl.motion.Color;
	
	import flash.display.*;
	import flash.events.*;
	import flash.external.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;

	
	public class ULoader {
// VARIABLES ////////////////////////////////////////////////////////////////////////////
		// REFERENCES
		public static var _stageLoaderInstance:_LoaderBase;
		public static var _loaderInstant:Boolean = true; // If true, loader comes and goes instantly, without any fade in/out
		public static var _loaderInstances:Object = {}; // Instances of loaders based on PippoFlashID for single clip loader
		public static var _shieldInstances:Object = {}; // Instances of shields based on PippoFlashID for single clip loader
		public static var _defaultLoaderId:String = "com.pippoflash.movieclips.loaders.CircleLoader";
		private static var _active:Boolean;
		private static var _c:MovieClip;
		private static var _debugPrefix:String = "ULoader";
		private static var _loaderDefaultParameters:Object; // If this is defined, loader when instantiated gets this parameters applied. Use setLoaderDefaultParams({scaleX:3});
		// UTY
		// MARKERS
// SETUP ///////////////////////////////////////////////////////////////////////////////////////
		public static function setMainLoaderClassId(id:String):void {
			_defaultLoaderId = id;
			if (_stageLoaderInstance) {
				UMem.killInstance(_stageLoaderInstance);
				UDisplay.removeClip(_stageLoaderInstance);
				_stageLoaderInstance = null;
			}
		}
// MAIN LOADER ///////////////////////////////////////////////////////////////////////////////////////
		public static function setLoader(v:Boolean, t:String = "", shield:Boolean = true, onArrivedOrHidden:Function = null):_LoaderBase {
			//trace("AAAAAAAAAAAAAAA");
			if (!_stageLoaderInstance) {
				var loaderClass:Class = Class(getDefinitionByName(_defaultLoaderId));
				_stageLoaderInstance = new loaderClass();
			}
			if (v) { // Activate loader
				//if (!_stageLoaderInstance) { // Create loader clip if it doesnt exist
					//var loader:ILoader = getMemoryClass(id);
					//_stageLoaderInstance = UDisplay.addChild(UGlobal.stage, loader);
				//}
				UGlobal.stage.addChild(_stageLoaderInstance as DisplayObject);
				//UDisplay.centerOnStage(_stageLoaderInstance as DisplayObject);
				//trace("CENTRO AR ETTANGOLOOOOOOOOOO", UGlobal.getStageRect());
				centerStageLoader();
				//UDisplay.alignSpriteTo(_stageLoaderInstance as DisplayObject, UGlobal.getStageRect());
				_stageLoaderInstance.show(_loaderInstant, t, onArrivedOrHidden);
				_stageLoaderInstance.setStageShield(true);
				if (_loaderDefaultParameters) setParameters(_loaderDefaultParameters);
				UGlobal.addResizeListener(centerStageLoader);
				_active = true;
			}
			else { // Deactivate loader
				
				//Debug.scream(_debugPrefix, "ULOADER FALSE");
				UGlobal.removeResizeListener(centerStageLoader);
				_stageLoaderInstance.hide(_loaderInstant, onArrivedOrHidden);
				//_stageLoaderInstance= null;
				_active = false;
				//UDisplay.removeClip(_stageLoaderInstance as DisplayObject);
			}
			return _stageLoaderInstance;
		}
			public static function centerStageLoader():void {
				
				if (_stageLoaderInstance) {
					//trace("ALLINEO STAGE LOADER", UGlobal.getStageRect());
					UDisplay.alignSpriteTo(_stageLoaderInstance as DisplayObject, UGlobal.getStageRect(), "CENTER", "MIDDLE", true);
					_stageLoaderInstance.setStageShield(true);
				}
				//if (_stageLoaderInstance) UDisplay.centerToStage(_stageLoaderInstance as DisplayObject);
			}
		public static function shutDownLoader():void {
			if (!_stageLoaderInstance) return; // Remove loader, but loader doesn't exist
			(_stageLoaderInstance as DisplayObject).visible = false; 
			(_stageLoaderInstance as DisplayObject).alpha = 0;
			UGlobal.removeResizeListener(centerStageLoader);
			UGlobal.setStageShield(false);
			UDisplay.removeClip(_stageLoaderInstance as DisplayObject);
			//_stageLoaderInstance = null;
			_active = false;
		}
		public static function connectLoader(o:SimpleQueueLoaderObject, t:String=null):SimpleQueueLoaderObject { // Connects the stage loader anime to a loader object
			if (!_stageLoaderInstance) {
				setLoader(true, t);
			}
			_stageLoaderInstance.connectToLoader(o);
			return o;
		}
		public static function setText(t:String="") {
			_stageLoaderInstance.setText(t);
		}
		public static function setProgress(n:Number = 0) {
			//trace("CAZZO",n);
			_stageLoaderInstance.setPercent(UCode.setRange(n));
		}
		public static function setParameters(o:Object):void {
			UCode.setParameters(_stageLoaderInstance, o);
		}
		public static function isActive():Boolean {
			return _active;
		}
		public static function moveLoaderToTop():void {
			if (_active && _stageLoaderInstance) UDisplay.addChild(UGlobal.stage, _stageLoaderInstance);
		}
		public static function setLoaderDefaultParams(o:Object):void { // Sets a parameters object that gets applied to loader
			_loaderDefaultParameters = o;
		}
		static public function getLoaderInstance():Object { // This can be an instance of anything set by mainapp
			return _stageLoaderInstance as Object;
		}
		static public function getLoaderInstanceAsLoaderBase():com.pippoflash.movieclips.loaders._LoaderBase { // This can be an instance of anything set by mainapp
			return _stageLoaderInstance;
		}
// CLIP LOADER ///////////////////////////////////////////////////////////////////////////////////////
		public static function setClipLoader(clip:DisplayObjectContainer, v:Boolean, t:String=null, rect:Rectangle=null, shield:Boolean=false, id:String=null):* {
			id 								= id ? id : _defaultLoaderId;
			var clipId							:String = UCode.getPippoFlashId(clip);
			activateMemoryClass					(id);
			if (_loaderInstances[clipId])				UMem.storeInstance(_loaderInstances[clipId]);
			// This inserts a loader animation within a clip
			if (v) {
				var c							:* = getMemoryClass(id);
				var goodRect					:Rectangle = rect ? rect : new Rectangle(0,0,clip.width,clip.height);
				UDisplay.addChild				(clip, c, {alpha:0, x:0, y:0});
				_loaderInstances[clipId]			= c;
				PFMover.fadeInTotal(c);
				c.x 							= goodRect.x + (goodRect.width / 2); 
				c.y 							= goodRect.y + (goodRect.height / 2);
				if (t)							UCode.callMethod(c, "setText", t);
				// Shield
				if (shield) {
					_shieldInstances[clipId]		= UDisplay.addChild(clip, UDisplay.getSquareSprite(goodRect.width, goodRect.height), {alpha:0});
				}
				// setup
				if (c is CircleLoader) {
					(c as CircleLoader).startAnim();
					(c as CircleLoader).setPercent(0);
				}
				// Return loader
				return	c;
			}
			else {
				// Shield
				if (_shieldInstances[clipId]) {
					UDisplay.removeClip			(_shieldInstances[clipId]);
					delete					_shieldInstances[clipId];
				}
				// Loader
				var c:*						= _loaderInstances[clipId];
				PFMover.fadeOutAndKill(c, 3, storeMemoryClass, c);
				delete						_loaderInstances[clipId];
// 				storeMemoryClass				(_c);
				return						c;
			}
		}
		public static function removeClipLoader			(clip:DisplayObjectContainer):void { // Removes immediately without fade out
			var clipId							:String = UCode.getPippoFlashId(clip);
			if (_loaderInstances[clipId]) {
				var c							:* = _loaderInstances[clipId];
				delete						_loaderInstances[clipId];
				c.stopAnim						();
				UDisplay.removeClip				(c);
				UMem.storeInstance				(c);
			}
		}
		static public function getClipLoader(clip:DisplayObjectContainer):_LoaderBase {
			return _loaderInstances[UCode.getPippoFlashId(clip)] as _LoaderBase;
		}
// COMPONENT LOADER ///////////////////////////////////////////////////////////////////////////////////////
		// These are designed to work with pippoflash visual framework, in this case, _cBase
		public static function setComponentLoader		(c:MovieClip, v:Boolean, t:String=null, shield:Boolean=false, id:String=null):MovieClip {
			var lo								:MovieClip = setClipLoader(c, v, t, new Rectangle(0,0,c._w,c._h), shield, id);
			if (v) {
			lo.x = c._w/2; lo.y = c._h/2;
			}
			return lo;
		}
// LOADING FROM EXTERNALLY LOADED STUFF ///////////////////////////////////////////////////////////////////////////////////////
		private static var _extAssetsLoaderSettings		:Object = {};
		public static function loadExternalAsset		(uri:String, caption:String, onComplete:Function, onError:Function, useLoader:Boolean=true, shield:Boolean=true, antiCache:Boolean = false):SimpleQueueLoaderObject {
			var sqlo							:SimpleQueueLoaderObject = QuickLoader.loadFile(uri, ULoader, "ExternalAsset", antiCache);
			_extAssetsLoaderSettings[uri]			= {useLoader:useLoader, onComplete:onComplete, onError:onError, uri:uri, sqlo:sqlo};
			if (useLoader) {
				setLoader						(true, caption, shield);
				connectLoader					(sqlo);
			}
			return							sqlo;
		}
		public static function onLoadCompleteExternalAsset(o:SimpleQueueLoaderObject):void {
			completeExtAssetLoad				(o, false);
		}
		public static function onLoadErrorExternalAsset(o:SimpleQueueLoaderObject):void {
			completeExtAssetLoad				(o, true);
		}
				private static function completeExtAssetLoad(o:SimpleQueueLoaderObject, isError:Boolean=false):void {
					var obj					:Object = _extAssetsLoaderSettings[o._url];
					if (isError)				obj.onError(o.getContent());
					else						obj.onComplete(o.getContent());
					delete					obj.sqlo;
					delete					_extAssetsLoaderSettings[o._url];
				}
// EMBED RENDERING //////////////////////////////////////////////////////////////////////////////
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		public static function activateMemoryClass(id:String):void { // This is ONLY for UMem stuff
			UMem.addClass(Class(getDefinitionByName(id)));
		}
		public static function getMemoryClass(id:String):* {
// 			return UCode.getInstance(id);
			return UMem.getInstance(Class(getDefinitionByName(id)));
		}
		public static function storeMemoryClass(obj:*):void {
// 			UMem.storeInstance						(obj);
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