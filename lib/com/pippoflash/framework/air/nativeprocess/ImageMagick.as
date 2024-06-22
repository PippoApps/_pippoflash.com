package com.pippoflash.framework.air.nativeprocess 
{
	import com.pippoflash.framework._PippoFlashBaseStatic;
	import com.pippoflash.utils.*;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import com.pippoflash.framework.air.UFile;
	import flash.filesystem.File;
	import flash.events.*;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class ImageMagick extends _PippoFlashBaseStatic 
	{
		static private var _imageMagickPath:String;
		static private var _startupInfo:NativeProcessStartupInfo;
		static private var _process:NativeProcess;
		static private var _debugPrefix:String = "ImageMagick";
		static private var _processRunning:Boolean;
		static private var _processCallback:Function;
		static private var _init:Boolean;
		static public var _verbose:Boolean;
		public function ImageMagick(id:String=null) {
			super(id);
		}
		
		static public function init(imageMagickPath:String):void {
			if (!NativeProcess.isSupported) {
				Debug.error(_debugPrefix, "ImageMagick.init() fail: NATIVE PROCESS NOT SUPPORTED!!!!");
				return;
			}
			_imageMagickPath = imageMagickPath;
			Debug.debug(_debugPrefix, "Looking for ImageMagick process at: " + _imageMagickPath);
			const file:File = File.applicationDirectory.resolvePath(_imageMagickPath);
			if (!file.exists) {
				Debug.error(_debugPrefix, "ImageMagick library not found at specified path: " + _imageMagickPath);
				return;
			}
			UFile.init();
			_startupInfo = new NativeProcessStartupInfo(); 
			_startupInfo.executable = file;
			_process = new NativeProcess(); 
			_process.addEventListener(NativeProcessExitEvent.EXIT, onExit); 
			// Errors
			_process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onStandardErrorIOError); 
			_process.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, onStandardInputIOError); 
			_process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onStandardOutputIOError); 
			// Data
			_process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onStandardErrorData); 
			_process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onStandardOutputData); 
			_process.addEventListener(ProgressEvent.STANDARD_INPUT_PROGRESS, onStandardInputProgress); 
			//
			//
			//_process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData); 
			//_process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData); 
			//_process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData); 
			//
			_init = true;
			Debug.debug(_debugPrefix, "NativeProcess found and supported.");
		}
		
		static public function runWithArguments(args:Vector.<String>, callback:Function = null):Boolean {
			if (_verbose) Debug.debug(_debugPrefix, "runWithArguments: " + args);
			if (!_init) {
				Debug.error(_debugPrefix, "runWithArguments fail. ImageMagick is not init()");
				return false;
			}
			if (_processRunning) {
				Debug.error(_debugPrefix, "Process is already running. runWithArguments() call aborted.");
				return false;
			}
			_processRunning = true;
			_startupInfo.arguments = args;
			_process.start(_startupInfo);
			_processCallback = callback;
			return true;
		}
		
		static public function mergePngsTo(pngs:Vector.<String>, to:String, callback:Function=null):Boolean {
			var args:Vector.<String> = new Vector.<String>();
			for (var i:int = 0; i < pngs.length; i++) {
				args.push(pngs[i].split("\\").join("/"));
			}
			//args.push("D:/Projects/The Astronut/Image Exporter/_work/source/0_0.png");
			//args.push("D:/Projects/The Astronut/Image Exporter/_work/source/2_1.png");
			//args.push("D:/Projects/The Astronut/Image Exporter/_work/source/3_2.png");
			args.push("-background");
			args.push("None");
			args.push("-layers");
			args.push("Flatten");
			//args.push("D:/Projects/The Astronut/Image Exporter/_work/export/result_with_app.png");
			args.push(to.split("\\").join("/"));
			return runWithArguments(args, callback);
		}
				
		//public static function setupNative():void {
//
			//nativeProcessStartupInfo.executable = file; 
			//var processArgs:Vector.<String> = new Vector.<String>(); 
			////processArgs[0] = "montage -border 0 -geometry 960x -tile 2x2 pippo* final.png"; 
			////processArgs[0] = "-help";
			//processArgs.push("montage");
			//processArgs.push("-border");
			//processArgs.push("0");
			//processArgs.push("-geometry");
			//processArgs.push(_viewport.viewport.width+"x");
			//processArgs.push("-tile");
			//processArgs.push(_bmpScale+"x" + _bmpScale);
			//if (USystem.isMac()) {
				////processArgs.push("/Users/filippogregoretti/Desktop/amrita_tiles/"+"pippo"+namePostfix+"*");
				////processArgs.push("/Users/filippogregoretti/Desktop/amrita_finals/"+String((new Date()).time) + ".png");
				//processArgs.push("/Users/filippogregoretti/Desktop/"+tileFullPathPrefix+"*");
				//processArgs.push("/Users/filippogregoretti/Desktop/"+imageFullPath+ ".png");
			//}else {
				//processArgs.push(tileFullPathPrefix+"*");
				//processArgs.push(imageFullPath+".png");
			//}
			////processArgs.push("final.png");
			//nativeProcessStartupInfo.arguments = processArgs; 
			//nativeProcessStartupInfo.workingDirectory = File.desktopDirectory; 
			//_process = new NativeProcess(); 
			//_process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData); 
			//_process.start(nativeProcessStartupInfo); 			
			//// Restart app
			//UExec.frame(3, onApplicationWake);
		//}
		private var _process:NativeProcess;		
		
        static public function onExit(event:NativeProcessExitEvent):void {
			if (_verbose) trace("onExit " + event);
			_processRunning = false;
			if (_processCallback) UExec.next(_processCallback, event.exitCode == 0);
			_processCallback = null;
        }
        static public function onStandardErrorClose(event:Event):void {
			if (_verbose) trace("onStandardErrorClose " + event);
        }
        static public function onStandardErrorData(event:ProgressEvent):void {
			if (_verbose) trace("onStandardErrorData " + event);
			//var stdOut:ByteArray = _process.standardOutput as ByteArray; 
			var data:String = _process.standardError.readUTFBytes(_process.standardError.bytesAvailable); 
			Debug.error(_debugPrefix, "Process interrupted with error: " + data);
        }
		public function onOutputData(event:ProgressEvent):void {
			Debug.debug(_debugPrefix, "Received NativeProcess output event.");
			//_process.standard
			if (!_process.standardOutput) return;
			trace(_process.standardOutput);
			trace(_process.standardOutput.bytesAvailable);
			trace(_process.standardOutput.readUTFBytes);
			//var stdOut:ByteArray = _process.standardOutput as ByteArray; 
			var data:String = _process.standardOutput.readUTFBytes(_process.standardOutput.bytesAvailable); 
			trace("Got: ", data); 
		}				
		
		
		
        static public function onStandardErrorIOError(event:Event):void {
			trace("onStandardErrorIOError " + event);
        }
        static public function onStandardInputClose(event:Event):void {
			trace("onStandardInputClose " + event);
        }
        static public function onStandardInputIOError(event:Event):void {
			trace("onStandardInputIOError " + event);
        }
        static public function onStandardInputProgress(event:Event):void {
			trace("onStandardInputProgress " + event);
        }
        static public function onStandardOutputClose(event:Event):void {
			trace("onStandardOutputClose " + event);
        }
        static public function onStandardOutputData(event:Event):void {
			trace("onStandardOutputData " + event);
        }
        static public function onStandardOutputIOError(event:Event):void {
			trace("onStandardOutputIOError " + event);
        }
		
		
		
		

	}

}