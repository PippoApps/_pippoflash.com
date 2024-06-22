/* UFileRef - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
This helps to work with files, both locally for AIR or for file upload.
This is a FIFO system, it allows only for one operation at a time.

*/

package com.pippoflash.utils {

	import com.pippoflash.framework.air.UFile;

	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	import									flash.external.*;
	import									flash.system.*;
	import									com.pippoflash.utils.*;
	import com.pippoflash.framework.air.UFile;
	
	public class UFileRef {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// SWITCHES
		public static var _verbose					:Boolean = true;
		// STATIC CONSTANTS
		private static var _debugPrefix				:String = "UFileRef";
		private static var _filters					:Object = { // This stores defaults for filters in file selection
			image:[new FileFilter("Images","*.jpg;*.jpeg;*.png")],
			all:[new FileFilter("All Files","*.*")]
		};
		public static var _fileUploadDefaultValues			:Object = { // This is public since I may want to modify defaults
			_command:"UPLOAD", 					// SYSTEM - This determines the type of command - NOT TO BE USED
			_maxSize:10000000,
			_fileDataFieldName:"Filedata",
			_targetUrl:"http://www.alphaserver.net/_test/flash/upload/test2.php",
			_useMainLoader:false, 					// B - If true, this connects to the main loader (if _funcLoader not defined, it uses ULoader directly)
			_startFunc:UCode.dummyFunction,			// F - _startFunc() - This gets called when network operation starts
			_okFunc:UCode.dummyFunction, 			// F - _okFunc() - This gets triggered when network operation is complete
			_okOnDataFunc:UCode.dummyFunction, 		// F - _okOnDataFunc(data:*) - this gets triggered when network operation is complete and page data is retrieved (mostly this will be used)
			_errorFunc:UCode.dummyFunction,  		// F - _errorFunc(e:IOErrorEvent);
			_fileTooLargeFunc:UCode.dummyFunction, 	// F - _fileTooLargeFunc(fileRef); 
			_progressFunc:UCode.dummyFunction, 		// F - _progressFunc(e:ProgressEvent);
			_funcLoader:UCode.dummyFunction, 		// F - _funcLoader(v:Boolean, t:String=null) -  This function is called to start and end loading if _useMainLoader is set to true
			_funcFileSelected:UCode.dummyFunction, 	// F - _funcFileSelected(fileRef) - If this function is not defined, file selected will trigger upload automatically.
			_funcFileSelectCancel:UCode.dummyFunction, 	// F - _funcFileSelectCancel(e:Event) | If this function is not defined, file selected will trigger upload automatically.
			_progressText:"transferring...", 			// S - Text to use when network operation is in progress
			_filter:"all" // If this is a string it grabs the filter array from _filters, BUT!!! it can also be directly a filter array
		};
		// SYSTEM
		private static var _fileRef					:FileReference = new FileReference();
		private static var _commandList				:Array = []; // Stores the queue of commands
		private static var _command					:Object; // Stores the active command
		// REFERENCES
		private static var _onFileSelected				:Function; // These can be used also outside of command but directly to browse a file
		private static var _onFileSelectCancel			:Function;
		// UTY
		// MARKERS
		private static var _fileSelected				:Boolean; // Marks if the file from file ref is selected
		private static var _isBusy					:Boolean; // Marks if the UFile is already running sth else
		private static var _initedCommands				:Object = {}; // Whenever a command is inited, it is stored with {UPLOAD:true}, if not inited iit calls init_UPLOAD()
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init					():void {
			// Call this to activate file reference
			_fileRef.addEventListener				(Event.SELECT, onSelectFile);
			_fileRef.addEventListener				(Event.CANCEL, onSelectFileCancel);
		}
		private static function init_UPLOAD			():void {
			// Here I choose if I have to listen to data retrieved from http, or just to upload complete status - ONE OR THE OTHER - NOT BOTH
			_fileRef.addEventListener				(Event.COMPLETE, onUploadComplete);
			_fileRef.addEventListener				(DataEvent.UPLOAD_COMPLETE_DATA, onUploadCompleteData);
			_fileRef.addEventListener				(IOErrorEvent.IO_ERROR, onUploadError);
			_fileRef.addEventListener				(ProgressEvent.PROGRESS, onUploadProgress);
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function uploadFile				(cmd:Object):void {
			UCode.setDefaults					(cmd, _fileUploadDefaultValues);
			cmd._command						= "UPLOAD";
			addCommand						(cmd);
		}
		public static function browseFile				(filter:*, onFileSelect:Function, onFileSelectCancel:Function=null):void {
			_fileSelected						= false;
			_onFileSelected						= onFileSelect;
			_onFileSelectCancel					= Boolean(onFileSelectCancel) ? onFileSelectCancel : UCode.dummyFunction;
			if (filter) {
				if (filter is String)				filter = _filters[filter];
			}
			else								filter = _filters.all;
			_fileRef.browse						(filter);
		}
		public static function startUpload				():void { // This is triggered automatically, or can be triggered from the outside
			if (!_fileSelected) { // Stop if file has not been selected
				Debug.debug					(_debugPrefix, "startUpload() called, but file to upload has not yet been selected.");
				return;
			}
		}
// COMMANDS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		private static function addCommand			(cmd:Object):void {
			_commandList.push					(cmd);
			checkNextCommand					();
		}
	// COMMAND QUEUE ///////////////////////////////////////////////////////////////////////////////////////	
		private static function checkNextCommand		():void { // This checks if I can launch another command
			if (_isBusy)							return;
			if (_commandList.length) {
				launchCommand					(_commandList.shift());
			}
		}
			private static function launchCommand		(cmd:Object):void {
				_command						= cmd;
				_isBusy						= true;
				Debug.debug					(_debugPrefix, "Launching:",_command._command);
				// Make general command processing
				if (!UCode.existsFunction(_command._funcLoader)) _command._funcLoader = ULoader.setLoader;
				// Checks for initialization
				if (!_initedCommands[_command._command]) {
					UFile["init_"+_command._command]	();
					if (_verbose)				Debug.debug(_debugPrefix, "Initializing",_command._command);
					_initedCommands[_command._command] = true;
				}
				// Call command
				UFile["launchCommand_"+_command._command]();
			}
			// HERE ARE THE SINGLE COMMAND STARTUP FUNCTIONS
				private static function launchCommand_UPLOAD():void {
					// Upload doesn't have to do much....
					browseFileForCommand			();
				}
			// SINGLE COMMANDS COMPLETE FUNCTIONS
				private static function completeCommand_UPLOAD():void {
					
				}
			// GENERAL COMMAND FUNCTIONS ///////////////////////////////////////////////////////////////////////////////////////
				private static function completeCommand():void {
					// Nothing so far
				}
				private static function browseFileForCommand():void {
					if (!UCode.existsFunction(_command._funcFileSelected)) _command._funcFileSelected = UFile["onFileSelected_"+_command._command];
					browseFile					(_command._filter, _command._funcFileSelected, _command._funcFileSelectCancel);
				}
// FILE REFERENCE LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public static function onSelectFile				(e:Event) {
			if (_verbose) 						Debug.debug(_debugPrefix, "File selected:",e);
			if (_command && _fileRef.size > _command._maxSize) {
				if (_verbose) 					Debug.debug(_debugPrefix, "File tool large, max size:",_command._maxSize,"- file size:",_fileRef.size);
				_command._fileTooLargeFunc			(_fileRef);
				return;
			}
			_fileSelected						= true;
			_onFileSelected						(_fileRef);
		}
		public static function onSelectFileCancel			(e:Event):void {
			Debug.debug						(_debugPrefix, "File selection canceled.");
			resetStatus						();
			_onFileSelectCancel					(e);
			checkNextCommand					();
		}
// UPLOAD LISTENERS //////////////////////////////////////////////////////////////////////////////
		public static function onFileSelected_UPLOAD		(_fileRef):void { // This calls specific behaviour for the type of command in file selected
			if (_verbose)						Debug.debug(_debugPrefix, "Start internal upload.");
			startUpload							();
			setLoader							(true, _command._progressText);
			_command._startFunc					();			
			_fileRef.upload						(new URLRequest(_command._targetUrl), _command._fileDataFieldName);
		}
		public static function onUploadError			(e:IOErrorEvent) {
			if (_verbose)						Debug.debug(_debugPrefix, e);
			setLoader							(false);
			resetStatus						();
			_command._errorFunc					(e);
		}
		public static function onUploadComplete			(e:Event) {
			if (_verbose)						Debug.debug(_debugPrefix, e);
			setLoader							(false);
			resetStatus						();
			_command._okFunc					(e);
		}
		public static function onUploadCompleteData		(e:DataEvent) {
			if (_verbose)						Debug.debug(_debugPrefix, e);
			setLoader							(false);
			resetStatus						();
			_command._okOnDataFunc				(e.data);
		}
		public static function onUploadProgress			(e:ProgressEvent) { // Set progress ALWAYS works with ULoader
			if (_verbose)						Debug.debug(_debugPrefix, e);
			setLoaderProgress					(Math.round(UCode.calculatePercent(e.bytesLoaded, e.bytesTotal)));
			_command._progressFunc				(e);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private static function setLoader				(v:Boolean, t:String=null):void {
			// This performs loader operations according to settings in _command
			if (_command._useMainLoader) {
				_command._funcLoader				(v, t);
			}
		}
		private static function setLoaderProgress		(p:Number):void {
			if (_command._useMainLoader)			ULoader.setProgress(p);
		}
		private static function resetStatus				():void {
			_fileSelected						= false;
			_isBusy							= false;
		}
	}
}