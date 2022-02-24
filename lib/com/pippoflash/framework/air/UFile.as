/* UFile - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
This helps to work with files, both locally for AIR or for file upload.
This is a FIFO system, it allows only for one operation at a time.

*/

package com.pippoflash.framework.air {

	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	import									flash.external.*;
	import									flash.filesystem.*;
	import									com.pippoflash.utils.*;
	import flash.filesystem.FileStream;
	import flash.events.PermissionEvent;
	import flash.permissions.PermissionStatus;	
	import flash.display.JPEGEncoderOptions;
	import flash.display.PNGEncoderOptions;
	import flash.utils.ByteArray;
	
	//import flash.events.PermissionEvent.PERMISSION_STATUS

	
	public class UFile {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// SWITCHES
		public static var _verbose:Boolean = true;
		static public var FORCE_AUTHORISATION:Boolean = false;
		// STATIC CONSTANTS
		private static const DEFAULT_FILE_PATH_FOR_PREMISSION:String = "PippoAppsDummyFolder/permission.txt";
		private static const _debugPrefix:String = "UFile";
		private static const _filters:Object = { // This stores defaults for filters in file selection
			image:[new FileFilter("Images","*.jpg;*.jpeg;*.png")],
			all:[new FileFilter("All Files","*.*")]
		};
		// SYSTEM
		private static var _file:File;
		private static var _fileDestination:File; // Defaults to local storage folder
		private static var _filePaths:Object;
		static private var _fileReference:FileReference;
		// REFERENCES
		private static var _onFileSelected:Function; // These can be used also outside of command but directly to browse a file
		private static var _onFileSelectCancel:Function;
		// UTY
		static private var _authorized:Boolean; // Whether UFile is authorized to read/write files
		// MARKERS
		private static var _fileSelected:Boolean; // Marks if the file from file ref is selected
		private static var _isBusy:Boolean; // Marks if the UFile is already running sth else
		private static var _initedCommands:Object; // Whenever a command is inited, it is stored with {UPLOAD:true}, if not inited iit calls init_UPLOAD()
		// ASYNC OPERATIONS MANAGEMENT
		static private var _asyncOperationInProgress:Boolean;
		static private var _asyncCallbackOk:Function;
		static private var _asyncCallbackError:Function;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init():void {
			// Prevent double init
			if (_file) return;
			// Call this to activate file reference
			_file = new File();
			
			
			
			
			
			
			//_file.addEventListener(PermissionEvent.PERMISSION_STATUS, onPermissionStatus);
			
			
			_filePaths = {};
			_filePaths.application = File.applicationDirectory;
			_filePaths.storage = File.applicationStorageDirectory;
			_filePaths.documents = File.documentsDirectory;
			_filePaths.cache = File.cacheDirectory;
			_filePaths.user = File.userDirectory;
			_filePaths.desktop = File.desktopDirectory;
			/* Files embedded in AIR are available with URL scheme format in the "application" folder */
			if (_verbose) {
				Debug.debug(_debugPrefix, "Native paths: \n" + "applicationDirectory " +  _filePaths.application.nativePath + "\nstorage " +  _filePaths.storage.nativePath + "\ndocuments " +  _filePaths.documents.nativePath + "\ncache " +  _filePaths.user.nativePath + "\nuser " +  _filePaths.user.nativePath );
				Debug.debug(_debugPrefix, "URLs: \n" + "applicationDirectory " +  _filePaths.application.url + "\nstorage " +  _filePaths.storage.url + "\ndocuments " +  _filePaths.documents.url + "\ncache " +  _filePaths.user.url + "\nuser " +  _filePaths.user.url + "\ndesktop " +  _filePaths.desktop.url + "\n" +  File.desktopDirectory.nativePath);
				Debug.debug(_debugPrefix, "Root directories:");
				import flash.filesystem.File;
				//var rootDirs:Array = File.getRootDirectories();
//
				//for (var i:uint = 0; i < rootDirs.length; i++) {
					//Debug.debug(_debugPrefix, rootDirs[i].nativePath + " ||| " + rootDirs[i].url);
				//}
				// Check for authorization
				if (USystem.isAndroid()) {
					Debug.warning(_debugPrefix, "This is an Android device, UFil requires authorization before.");
				}
				else _authorized = true;
			}
		}
// METHODS FOR BROWSING ON HD ///////////////////////////////////////////////////////////////////////////////////////
		public static function browseFile				(filter:*, onFileSelect:Function, onFileSelectCancel:Function=null):void { // Brwse for a file in the local system
			_fileSelected						= false;
			_onFileSelected						= onFileSelect;
			_onFileSelectCancel					= Boolean(onFileSelectCancel) ? onFileSelectCancel : UCode.dummyFunction;
			if (filter) {
				if (filter is String)				filter = _filters[filter];
			}
			else								filter = _filters.all;
			_file.addEventListener(Event.SELECT, onSelectFile);
			_file.addEventListener(Event.CANCEL, onSelectFileCancel);
			_file.browse						(filter);
		}
		private static function fileExists(action:String=""):Boolean { // Cheks if a file has been selected with a browse
			if (_file.exists) return true;
			Debug.error(_debugPrefix, "File not selectect. Can't " + action);
			return false;
		}
// METHODS TO REFERENCE A FILE ///////////////////////////////////////////////////////////////////////////////////////////////
		static public function referenceFile(path:String, target:String = "storage", verbose:Boolean=true):File {
			if (verbose) Debug.debug(_debugPrefix, "Referencing file: " + path +  " in " + target);
			_file = _filePaths[target].resolvePath(path);
			_file.addEventListener(Event.CANCEL, onFileOperationCanceled);
			_file.addEventListener(Event.COMPLETE, onFileOperationComplete);
			_file.addEventListener(FileListEvent.DIRECTORY_LISTING, onFileDirectoryListing);
			_file.addEventListener(IOErrorEvent.DISK_ERROR, onFileIOError);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onFileIOError);
			_file.addEventListener(IOErrorEvent.NETWORK_ERROR, onFileIOError);
			_file.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onFileIOError);
			_file.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, onFileIOError);
			_file.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onFileIOError);
			_file.addEventListener(IOErrorEvent.VERIFY_ERROR, onFileIOError);
			_file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileSecurityError);
			if (!_file.exists) Debug.warning(_debugPrefix, "File " + path +  " in " + target + " not found.");
			return _file;
		}
		
		
		
		
		
// METHODS WHEN A FILE IS ALREADY SELECTED ///////////////////////////////////////////////////////////////////////////////////////
		public static function copyToDesktop(newName:String=null, overwrite:Boolean=true):void {
			if (fileExists("copyToDesktop "+ newName)) {
				var newFile:File = File.desktopDirectory.resolvePath(newName); 
				_file.copyTo(newFile, overwrite);
			}
		}
		public static function copyToStorage(newName:String = null, overwrite:Boolean = true, file:File = null):void {
			if (file || fileExists("copyToStorage "+ newName)) {
				var newFile:File = File.applicationStorageDirectory.resolvePath(newName); 
				(file ? file : _file).copyTo(newFile, overwrite);
			}
		}
		public static function copyToCache(newName:String = null, overwrite:Boolean = true, file:File = null, async:Boolean = false, callbackOk:Function = null, callbackError:Function = null):void {
			copyToTarget(newName, overwrite, "cache", file, async, callbackOk, callbackError);
			//if (file || fileExists("copyToCache "+ newName)) {
				//var newFile:File = File.cacheDirectory.resolvePath(newName); 
				//(file ? file : _file).copyTo(newFile, overwrite);
			//}
		}
		public static function copyToTarget(newName:String = null, overwrite:Boolean = true, target:String = "storage",  file:File = null, async:Boolean = false, callbackOk:Function = null, callbackError:Function = null):Boolean {
			Debug.debug(_debugPrefix, "Copy to target: ", newName, overwrite, target, file, async, callbackOk, callbackError);
			if (file || fileExists("copyToTarget "+ newName)) {
				var newFile:File = _filePaths[target].resolvePath(newName); 
				if (async) {
					if (_asyncOperationInProgress) {
						Debug.error(_debugPrefix, "Async operation already in project. File operation aborted.");
						return false;
					}
					_asyncCallbackOk = callbackOk;
					_asyncCallbackError = callbackError;
					(file ? file : _file).copyToAsync(newFile, overwrite);
				}
				else (file ? file : _file).copyTo(newFile, overwrite);
			}
			return true;
		}
		public static function setToDesktop():void {
			_fileDestination = File.desktopDirectory; 
		}
		public static function copy(newName:String, overwrite:Boolean=true):void { // copies to default directory
			if (fileExists("copy ")) {
				var newFile:File = _fileDestination.resolvePath(newName); 
				_file.copyTo(newFile, overwrite);
			}
		}
		public static function getDestinationPath(fileName:String, target:String = "storage", isUrl:Boolean = true, canonicalize:Boolean = true, verbose:Boolean=false):String { // To load file (i.e. from an image conponent) the url must be used instead of nativePath
			//trace("1");
			var f:File = _filePaths[target].resolvePath(fileName);
			if (_verbose || verbose) {
				Debug.debug(_debugPrefix, "Returning destination path for: ", _filePaths[target], fileName);
				Debug.scream(_debugPrefix, "Prova per urls!!!", _filePaths.application.url, _filePaths.application.nativePath);
				Debug.debug(_debugPrefix, "File founbd? " + f.exists);
				Debug.debug(_debugPrefix, "Container  : " + (_filePaths[target] as File).isDirectory);
				Debug.debug(_debugPrefix, "Container file path: " + (_filePaths[target] as File).url);
			}
			//trace("2");
			if (canonicalize) {
				Debug.warning(_debugPrefix, fileName + " File path has been canonicalized: " + fileName);
				f.canonicalize();
			}
			//Debug.debug(_debugPrefix,  "canonicalize!! " + f.nativePath);
			//Debug.debug(_debugPrefix, "canonicalize!! " + f.url);
			var p:String = isUrl ? f.url : f.nativePath;
			if (_verbose || verbose) Debug.debug(_debugPrefix, "getDestinationPath('"+fileName+"') --> " + (isUrl ? " URL: " : "NATIVE PATH: ") + p);
			return p;
		}
		
		
		
		
		
		
		
		// PERMISSIONS
		// PERMISSION SHOULD BE GRANTED USING PERMISSION EVENT, BUT ACTUALLY SINCE IT USES SYSTEM DIALOG, APPLICATION GOES TO SLEEP
		static private var _permissionFile:File;
		static private var _permissionListenerMethod:Function;
		static public function checkPermission(onPermissionGranted:Function):void {
			//trace("PERMISSIOIONSSSSSSSSSSS");
			// If already authorized just call the callback
			if (_authorized) {
				UExec.time(0.2, onPermissionGranted);
				return;
			}
			// Proceed requesting
			_permissionListenerMethod = onPermissionGranted;
			_permissionFile = File.documentsDirectory.resolvePath(DEFAULT_FILE_PATH_FOR_PREMISSION);  
			_permissionFile.addEventListener(PermissionEvent.PERMISSION_STATUS, onFilePermission);
			UAir.addSleepListener(onApplicationSleep);
			UAir.addWakeListener(onApplicationWake);
			_permissionFile.requestPermission();
		}
		static private function onFilePermission(e:PermissionEvent):void {
			Debug.debug(_debugPrefix, "Premission event received:",e.status);
			//_MainAppBase.instance.promptOk(e.status);
			if (e.status == "granted") {
				_authorized = true;
			}
			_permissionFile.removeEventListener(PermissionEvent.PERMISSION_STATUS, onFilePermission);
			_permissionFile = null;
		}
		
		static private function onApplicationSleep(e:Event):void {
			Debug.debug(_debugPrefix, "Application goes to sleep to request file permission.");
			UAir.removeSleepListener(onApplicationSleep);
		}
		static private function onApplicationWake(e:Event):void {
			Debug.debug(_debugPrefix, "Application woke up again, authorized: " + _authorized);
			UAir.removeWakeListener(onApplicationWake);
			if (_authorized) UExec.next(_permissionListenerMethod);
			else {
				if (FORCE_AUTHORISATION) UExec.time(0.2, checkPermission, _permissionListenerMethod);
				else _permissionListenerMethod();
			}
			_permissionListenerMethod = null;
		}
		
		
		
		static public function requestReadPermission(fileName:String, target:String = "storage", listenerMethod:Function=null ):void {
			var f:File = _filePaths[target].resolvePath(fileName);
			_permissionListenerMethod = listenerMethod;
			f.addEventListener(PermissionEvent.PERMISSION_STATUS, onPermissionStatus);
			f.requestPermission();
		}
		static public function onPermissionStatus(e:PermissionEvent):void {
			//Debug.debug(_debugPrefix, "Permission status changed: " + e);
			Debug.debug(_debugPrefix, "Permission: " + e.status);
			if (_permissionListenerMethod) _permissionListenerMethod(e.status == "granted");
			_permissionListenerMethod = null;
		}
		
		
		
		
		
		
		
// METHODS TO CREATE A FILE LOCALLY /////////////////////////////////////////////////////////////
		public static function loadFile				(path:String, target:String="storage", isText:Boolean=true):ByteArray { /* NOT YET WORKING */
			// This does NOT work now
			try {
				var f							:File = _filePaths[target].resolvePath(path); 
				f.canonicalize					();
				Debug.debug					(_debugPrefix, "Loading file: " + f.nativePath);
				// create a file stream
				var fs:FileStream				= new FileStream();
				fs.open						(f, FileMode.READ);
				var result						:*;
				if (isText)						result =  fs.readUTF();
				else {
					result						= new ByteArray(); 
					fs.readBytes				(result);
				}
				fs.close						();
				return						result;
			} catch (e:Error) {
				Debug.error					(_debugPrefix, "Error loading file " + path + "\n" + e);
				return						null;
			}
			return							null;
		}
		public static function saveFile(path:String, file:*, target:String="storage"):* { // This savea a ByteArray as a binary or a string as an UTF8 somewhere...
			try {
				var fBase:File = _filePaths[target] ? _filePaths[target] : new File(target); // Use a default folder or get a custom one if default is not defined
				var f:File = fBase.resolvePath(path); 
				f.canonicalize();
				Debug.debug(_debugPrefix, "Saving file in " +target +" : " + f.nativePath);
				// create a file stream
				var fs:FileStream = new FileStream();
				// open the stream for writting
				fs.open(f, FileMode.WRITE);
				// write the string data down to the file
				if (file is String) fs.writeUTFBytes(file);
				else fs.writeBytes(file);
				fs.close();
			} catch (e:Error) {
				Debug.error(_debugPrefix, "Error saving file " + path + "\n" + e);
				return false;
			}
			return true;
		}
		
		
		
		
		
		
		
// DIRECTORY ///////////////////////////////////////////////////////////////////////////////////////
		public static function getDirectoryListing		(path:String, target:String = "application", listFiles:Boolean=false):Array { // Returns an array of File with all content of directory (no subdirs)
			Debug.debug(_debugPrefix, "getDirectoryListing() in folder " + target + " (" + _filePaths[target] + ") " + path );
			var d:File = _filePaths[target].resolvePath(path); 
			Debug.debug(_debugPrefix, "Is folder: " + d.isDirectory);
			Debug.debug(_debugPrefix, "Native path: " + d.nativePath);
			d.canonicalize();
			if (!d.exists) {
				Debug.error(_debugPrefix, path + " does not exist.");
				return [];
			}
			if (!d.isDirectory) {
				Debug.error(_debugPrefix,  path + " is not a directory.");
				return [];
			}
			const files:Array = d.getDirectoryListing();
			Debug.debug(_debugPrefix, "Files array: " + files);
			Debug.debug(_debugPrefix, d.nativePath + " contains " + files.length + " files.");
			if (listFiles) {
				const fileNames:Array = [];
				for (var i:int = 0; i <  files.length; i++) {
					const file:File = files[i];
					fileNames.push(file.name);
				}
				Debug.debug(_debugPrefix, "Files in folder: " + fileNames.join(", "));
			}
			return files;
		}
		public static function getDirectoryListingStrings	(path:String, target:String = "application"):Vector.<String> { // Returns a Vector of STRINGS with FILENAME ONLY of files found in a folder
			Debug.debug(_debugPrefix, "Retrieving path " + path + " in " + target);
			var a								:Array = getDirectoryListing(path, target);
			var b								:Vector.<String> = new Vector.<String>(a.length);
			// Find a string length in order to isolaate filename only
			var tot							:uint = a.length;
			var stringCut						:uint = tot ? (_filePaths[target].resolvePath(path).url + "/").length : 0;
			for (var i:uint=0; i<tot; i++) {
				b[i]							= a[i].url.substr(stringCut-1);
			}
			return							b;
		}
		static public function createDirectory(path:String, target:String="storage"):void {
			Debug.debug(_debugPrefix, "Creating folder " + path + " in " + target);
			var f:File = _filePaths[target].resolvePath(path);
			if (f.exists && f.isDirectory) Debug.debug(_debugPrefix, "Directory already exists.");
			else f.createDirectory();
		}
		static public function deleteDirectory(path:String, deleteContents:Boolean=true, target:String = "storage"):void {
			Debug.debug(_debugPrefix, "Deleting folder " + path + " in " + target);
			var f:File = _filePaths[target].resolvePath(path);
			if (f.exists && f.isDirectory) f.deleteDirectory(deleteContents);
			else Debug.debug(_debugPrefix, "Folder does not exist, no need to delete.");
		}
		
		static public function renameFile(path:String, newPath:String, deleteContents:Boolean=true, target:String = "storage"):void {
			Debug.debug(_debugPrefix, "Moving folder " + path + " to " + newPath + " in " + target);
			var f:File = _filePaths[target].resolvePath(path);
			var newF:File = _filePaths[target].resolvePath(newPath);
			f.moveTo(newF, true);
		}
		// METHODS WITH CALLBACKS
		private var _callbackFunc:Function;
		static public function copyDirectoryContent(sourceFolder:String, destFolder:String,  sourceTarget:String = "storage", destTarget:String = "storage", overwrite:Boolean = true, callbackFunc:Function=null, async:Boolean=false):void {
			var files:Array = getDirectoryListing(sourceFolder, sourceTarget);
			var f:File;
			for (var i:int = 0; i < files.length; i++) {
				f = files[i];
				var targ:String = destFolder + "/" + f.name;
				// If callbackFunc is defiend copy is disributed amongst frames
				if (callbackFunc) {
					UExec.frame(i+1, copyToTarget, destFolder + "/" + f.name, true, destTarget, f, async);
				}
				else {
					copyToTarget(destFolder + "/" + f.name, true, destTarget, f, async); 
				}
			}
			if (callbackFunc) UExec.frame(files.length + 2, callbackFunc);
		}
		
		
		
		
// FILE LISTENERS FOR BROWSING ///////////////////////////////////////////////////////////////////////////////////////
		public static function onSelectFile				(e:Event) {
			if (_verbose) 						Debug.debug(_debugPrefix, "File selected:",e);
			_fileSelected						= true;
			_onFileSelected						(_file);
		}
		static public function onSelectMultipleFile(e:Event):void {
			Debug.debug(_debugPrefix, "onSelectMultipleFile " + e);
		}
		
		public static function onSelectFileCancel			(e:Event):void {
			Debug.debug						(_debugPrefix, "File selection canceled.");
			_onFileSelectCancel					(e);
		}
		// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		static public function onFileOperationComplete(e:Event):void {
			Debug.debug(_debugPrefix, "onFileOperationComplete " + e);
			broadcastAsyncOk(e);
		}
		static public function onFileDirectoryListing(e:Event):void {
			Debug.debug(_debugPrefix, "onFileDirectoryListing " + e);
			broadcastAsyncOk(e);
		}
		static public function onFileOperationCanceled(e:Event):void {
			Debug.debug(_debugPrefix, "onFileOperationCanceled " + e);
			broadcastAsyncError(e);
		}
		static public function onFileIOError(e:Event):void {
			Debug.debug(_debugPrefix, "onFileIOError " + e);
			broadcastAsyncError(e);
		}
		static public function onFileSecurityError(e:Event):void {
			Debug.debug(_debugPrefix, "onFileSecurityError " + e);
			broadcastAsyncError(e);
		}
		
		
		static private function broadcastAsyncOk(e:Event):void {
			if (_asyncCallbackOk) _asyncCallbackOk(e);
			_asyncOperationInProgress = false;
			_asyncCallbackOk = _asyncCallbackError = null;
		}
		static private function broadcastAsyncError(e:Event):void {
			if (_asyncCallbackError) _asyncCallbackError(e);
			_asyncOperationInProgress = false;
			_asyncCallbackOk = _asyncCallbackError = null;
		}
		
		
		
		
		
		
		
		
		
		
		
		
		// SPECIFIC FILE FORMATS ///////////////////////////////////////////////////////////////////////////////////////
		static public function saveJPG(path:String, bmp:Bitmap, quality:Number=100, target:String="storage"):void {
			//const bmp:Bitmap = new Bitmap(_selectedCap.bmp.bitmapData.clone());
			Debug.debug(_debugPrefix, "Saving JPEG: " + bmp.bitmapData);
			const options:JPEGEncoderOptions = new JPEGEncoderOptions(quality);
			//const options:PNGEncoderOptions = new PNGEncoderOptions(false);
			bmp.scaleX = bmp.scaleY = 1;
			const jpg:ByteArray = bmp.bitmapData.encode(new Rectangle(0, 0, bmp.width, bmp.height), options); 
			Debug.debug(_debugPrefix, "Encoded JPG bytes ", jpg.length);
			saveFile(path, jpg, target);
		}
		static public function savePNG(path:String, bmp:Bitmap, fastCompression:Boolean=false, target:String="storage"):void {
			//const bmp:Bitmap = new Bitmap(_selectedCap.bmp.bitmapData.clone());
			Debug.debug(_debugPrefix, "Saving PNG: " + bmp.bitmapData);
			//const options:JPEGEncoderOptions = new JPEGEncoderOptions(quality);
			const options:PNGEncoderOptions = new PNGEncoderOptions(fastCompression);
			bmp.scaleX = bmp.scaleY = 1;
			const png:ByteArray = bmp.bitmapData.encode(new Rectangle(0, 0, bmp.width, bmp.height), options); 
			Debug.debug(_debugPrefix, "Encoded PNG bytes ", png.length);
			saveFile(path, png, target);
		}
		
		
		 	 	
    //cancel
//Dispatched when a pending asynchronous operation is canceled.	File
 	 	//
    //complete
//Dispatched when an asynchronous operation is complete.	File
 	 	//
    //directoryListing
//Dispatched when a directory list is available as a result of a call to the getDirectoryListingAsync() method.	File
 	 	//
    //ioError
//Dispatched when an error occurs during an asynchronous file operation.	File
 	 	//
    //permissionStatus
//Dispatched when the application requests permission to access filesystem.	File
 	 	//
    //securityError
//Dispatched when an operation violates a security constraint.	File
 	 	//
    //select
//Dispatched when the user selects a file or directory from a file- or directory-browsing dialog box.	File
 	 	//
    //selectMultiple
//Dispatched when the user selects files from the dialog box opened by a call to the browseForOpenMultiple() method.	File

		// GET SET ///////////////////////////////////////////////////////////////////////////////////////
		/**
		 * If UFile is authorized to read/write file son machine. Implemented only for Android so far.
		 */
		static public function get authorized():Boolean 
		{
			return _authorized;
		}
	}
}