package com.pippoflash.framework.air 
{
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * Updates content from online and saves it locally.
	 * This is a static class and does everything statically.
	 */
	import com.pippoflash.net.PreLoader;
	import com.pippoflash.framework.air.UFile;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.utils.UText;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	public final class LocalContentUpdater {
		// STATIC
		private static const _debugPrefix:String = "LocalContentUpdater";
		private static const CONTENT_FOLDER:String = "_data"; // This folder contains all content
		private static const ASSETS_SUBFOLDER:String = "assets"; // This folder contains assets
		private static const TEMP_CONTENT_FOLDER:String = "_data_downloading"; // Here all new content is downloaded
		private static const STATUSES:Array = ["IDLE", "READY", "LOADING", "RENAMING"];
		// EVENT NAMES
		public static const EVT_UPDATE_STARTED:String = "onLocalContentUpdateStarted";
		public static const EVT_UPDATE_PROGRESS:String = "onLocalContentUpdateProgress"; // progress:Number // 0 to 1
		public static const EVT_UPDATE_COMPLETE:String = "onLocalContentUpdateComplete"; // Update event is complete
		public static const EVT_UPDATE_ERROR:String = "onLocalContentUpdateError"; // Update event is complete
		// SYSTEM
		static private var _listener:Object;
		// MARKERS
		static private var _status:int = 0; // 0 idle, 1 ready, 2 loading, 3  renaming
		static private var _statusDesc:String;
		// DATA
		static private var _contentLocation:String; // String to be placed before of folders
		static private var _urls:Array; // Urls of files to be downloaded. 
		static private var _updateId:String;
		// 
		
		
		// INIT
		static public function init():void {
			PreLoader.init();
			UFile.init();
			_status = 1;
		}
		
		
		
		// run update
		static public function updateContent(urls:Array):void {
			if (_status != 1) {
				Debug.error(_debugPrefix, "Content update cannot start because status is: " + statusDescription);
				return;
			}
			_urls = urls;
			_updateId = "LocalContentUpdater" + Math.random(); // To make sure is a new update process
			if (!PreLoader.isIdle()) {
				Debug.warning(_debugPrefix, "PreLoader is busy. Cannot start update now.");
			}
			else startUpdateProcess();
		}
		
		static private function startUpdateProcess():void {
			_status = 2; _statusDesc = "LOADING";
			if (!_urls) Debug.warning(_debugPrefix, "Update not launched, no urls present.");
			var urls:Vector.<String> = new Vector.<String>(_urls.length);
			for (var i:int = 0; i < _urls.length; i++) {
				urls[i] = _urls[i];
			}
			PreLoader.addListener(LocalContentUpdater);
			PreLoader.forceFileStream = true;
			PreLoader.queueFiles(urls);
			PreLoader.startQueue(_updateId);
		}
		
		// PreLoader listeners
		static public function onQueueLoadComplete(id:String):void {
			if (id == _updateId) {
				Debug.debug(_debugPrefix, "Loading Queue is complete.");
				finalizeUpdate();
			}
			else startUpdateProcess();
		}
		static private function onQueueLoadError(id:String):void {
			if (id == _updateId) {
				Debug.error(_debugPrefix, "Loading Queue error. Update process aborted.");
			}
			else startUpdateProcess();
		}
		
		// Update finalization
		static private function finalizeUpdate():void {
			_status = 2; _statusDesc = "FILE OPERATIONS";
			PreLoader.removeListener(LocalContentUpdater);
			Debug.debug(_debugPrefix, "Finalizing update.");
			Debug.debug(_debugPrefix, "Creating folder: " + TEMP_CONTENT_FOLDER);
			UFile.deleteDirectory(TEMP_CONTENT_FOLDER);
			UFile.createDirectory(TEMP_CONTENT_FOLDER);
			// Save all files
			var stripChars:String = "<>:\"/\\|?*"; // Characters to be removed from url
			for each (var u:String in _urls) {
				var fileName:String = UText.stripCharacters(u, stripChars);
				Debug.debug(_debugPrefix, "Saving ByteArray from url: " + u + " > " + fileName);
				var file:* = PreLoader.getFile(u, false, false);
				Debug.debug(_debugPrefix, "Saving ByteArray.");
				UFile.saveFile(TEMP_CONTENT_FOLDER + "/" + fileName, file);
			}
			PreLoader.forceFileStream = false;
			// Continue after all files have been successfully saved
			Debug.debug(_debugPrefix, "All files successfully saved.");
			Debug.debug(_debugPrefix, "Removing existing data folder.");
			UFile.deleteDirectory(CONTENT_FOLDER);
			UFile.renameFile(TEMP_CONTENT_FOLDER, CONTENT_FOLDER);
		}
		
		
		// UTY
		private function setToError(error:String):void {
			PippoFlashEventsMan.broadcastStaticEvent(LocalContentUpdater, EVT_UPDATE_ERROR, error);
		}
		private function reset():void {
			_urls = null; _updateId = null;
		}
		
		
		// GETTERS SETTERS
		static public function get statusDescription():String {
			return _statusDesc;
		}
		
		// ERROR ON INSTANTIATION
		public function LocalContentUpdater() {
			throw new Error("LocalContentUpdater is a static class and cannot be instantiated.");
		}
		
		
	}

	
	
	
	
	
}