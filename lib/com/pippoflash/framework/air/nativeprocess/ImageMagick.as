package com.pippoflash.framework.air.nativeprocess 
{
	import com.pippoflash.framework._PippoFlashBaseStatic;
	import com.pippoflash.utils.*;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import com.pippoflash.framework.air.UFile;
	import flash.filesystem.File;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class ImageMagick extends _PippoFlashBaseStatic 
	{
		static private var _imageMagickPath:String;
		static private var _startupInfo:NativeProcessStartupInfo;
		static private var _process:NativeProcess;
		public function ImageMagick(id:String=null) 
		{
			super(id);
			
		}
		
		static public function init(imageMagickPath:String):void {
			if (!NativeProcess.isSupported) {
				Debug.error(_debugPrefix, "ImageMagick.init() fail: NATIVE PROCESS NOT SUPPORTED!!!!");
				return;
			}
			const file:File = File.applicationDirectory.resolvePath(_imageMagickPath);
			if (!file.exists) {
				Debug.error(_debugPrefix, "ImageMagick library not found at specified path: " + _imageMagickPath);
				return;
			}
			UFile.init();
			_imageMagickPath = imageMagickPath;
			_startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo(); 
			_startupInfo.executable = file;
		}
		
				
		public static function setupNative():void {

			nativeProcessStartupInfo.executable = file; 
			var processArgs:Vector.<String> = new Vector.<String>(); 
			//processArgs[0] = "montage -border 0 -geometry 960x -tile 2x2 pippo* final.png"; 
			//processArgs[0] = "-help";
			processArgs.push("montage");
			processArgs.push("-border");
			processArgs.push("0");
			processArgs.push("-geometry");
			processArgs.push(_viewport.viewport.width+"x");
			processArgs.push("-tile");
			processArgs.push(_bmpScale+"x" + _bmpScale);
			if (USystem.isMac()) {
				//processArgs.push("/Users/filippogregoretti/Desktop/amrita_tiles/"+"pippo"+namePostfix+"*");
				//processArgs.push("/Users/filippogregoretti/Desktop/amrita_finals/"+String((new Date()).time) + ".png");
				processArgs.push("/Users/filippogregoretti/Desktop/"+tileFullPathPrefix+"*");
				processArgs.push("/Users/filippogregoretti/Desktop/"+imageFullPath+ ".png");
			}else {
				processArgs.push(tileFullPathPrefix+"*");
				processArgs.push(imageFullPath+".png");
			}
			//processArgs.push("final.png");
			nativeProcessStartupInfo.arguments = processArgs; 
			nativeProcessStartupInfo.workingDirectory = File.desktopDirectory; 
			_process = new NativeProcess(); 
			_process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData); 
			_process.start(nativeProcessStartupInfo); 			
			// Restart app
			UExec.frame(3, onApplicationWake);
		}
		private var _process:NativeProcess;		
		
        static public function onOutputData(event:ProgressEvent):void
        {
			trace("onOutputData");
            trace("Got: ", process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable)); 
        }
        
        static public function onErrorData(event:ProgressEvent):void
        {
			trace("onErrorData");
            trace("ERROR -", process.standardError.readUTFBytes(process.standardError.bytesAvailable)); 
        }
        
        static public function onExit(event:NativeProcessExitEvent):void
        {
			trace("onExit");
            trace("Process exited with ", event.exitCode);
        }
        
        static public function onIOError(event:IOErrorEvent):void
        {
			trace("onIOError");
             trace(event.toString());
        }	
		
	}

}