package  com.pippoflash.framework.air.webview 
{
	import com.pippoflash.framework._ApplicationStarling;
	import com.pippoflash.framework._PippoFlashBaseNoDisplay;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import com.pippoflash.framework.air.UFile;
	import com.pippoflash.utils.*;
	import flash.events.OutputProgressEvent;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 * Improved version of : http://coenraets.org/blog/2009/12/air-2-0-web-server-using-the-new-server-socket-api/
	 */
	public class FileServer extends _PippoFlashBaseNoDisplay 
	{
            
		
		static public var VERBOSE:Boolean = false;
		//import mx.controls.Alert;
		private var _port:Number = 8888; // https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
		
		public function FileServer(id:String, storageId:String="application", assetsFolder:String="_assets", port:uint=8888) 
		{
			super(id, FileServer);
			_port = port;
			_storageId = storageId;
			_assetsFolder = assetsFolder;
			init();
		}

		
		
		
		
			
            private var serverSocket:ServerSocket;
            private var mimeTypes:Object = new Object();
			private var _fileStorage:File;
			private var _storageId:String;
			private var _assetsFolder:String;
			private var _removeParametersAfterFilePath:Boolean = true; // Removes everything after and including ? from file url
			
 
            private function init():void
            {
                // The mime types supported by this mini web server
                mimeTypes[".css"]   = "text/css";
                mimeTypes[".gif"]   = "image/gif";
                mimeTypes[".htm"]   = "text/html";
                mimeTypes[".html"]  = "text/html";
                mimeTypes[".ico"]   = "image/x-icon";
                mimeTypes[".jpg"]   = "image/jpeg";
                mimeTypes[".js"]    = "application/x-javascript";
                mimeTypes[".png"]   = "image/png";
                mimeTypes[".mp3"]   = "audio/mpeg";
                mimeTypes[".ogg"]   = "audio/ogg";
                mimeTypes[".m4a"]   = "audio/mp4";
				// FONTS AND ICONS
                mimeTypes[".eot"]   = "application/vnd.ms-fontobject";
                mimeTypes[".ttf"]   = "application/font-sfnt";
                mimeTypes[".svg"]   = "image/svg+xml";
                mimeTypes[".woff"]   = "application/font-woff";
                mimeTypes[".woff2"]   = "font/font-woff2";

                // Initialize the web server directory (in applicationStorageDirectory) with sample files
				
				Debug.debug(_debugPrefix, "Querying File referencing for ",_assetsFolder, _storageId);
				_fileStorage = UFile.referenceFile(_assetsFolder, _storageId);
				Debug.debug(_debugPrefix, "Found: " + _fileStorage.url);
					var indexUrl:String = UFile.getDestinationPath(_assetsFolder, "application", true, true, true);
				Debug.debug(_debugPrefix, "Local URL of destination file: " + indexUrl);
				//var ff:File = new File(new File(indexUrl).nativePath);
				//Debug.debug(_debugPrefix, ff.url);
				//new File(new File(indexUrl).nativePath).url;
				
                //var webroot:File = File.applicationDirectory.resolvePath("_assets");
				
                if (!_fileStorage.exists) {
					Debug.error(_debugPrefix, "Storage folder not found: " + _fileStorage.url);
                    //File.applicationDirectory.resolvePath("_assets").copyTo(webroot);
                } else {
					//Debug.debug(_debugPrefix, "Found data folder in: " + _fileStorage.url);
					Debug.debug(_debugPrefix, "Content: \n" + UFile.getDirectoryListingStrings(_fileStorage.url));
					//DebuUFile.getDirectoryListingStrings("_assets");
				}
				listen();
            }
 
            private function listen():void
            {
                try
                {
                    serverSocket = new ServerSocket();
                    serverSocket.addEventListener(Event.CONNECT, socketConnectHandler);
                    serverSocket.bind(_port);
                    serverSocket.listen();
					Debug.debug(_debugPrefix, "Listening on port " + _port + "...");
                }
                catch (error:Error)
                {
					Debug.error(_debugPrefix,"Port " + _port +
                        " may be in use. Enter another port number and try again.\n(" +
                        error.message +")", "Error");
                }
            }
			
			public function cleanup():void {
				if (!serverSocket) return;
				Debug.debug(_debugPrefix, "Cleaning up...");
                serverSocket.removeEventListener(Event.CONNECT, socketConnectHandler);
				serverSocket.close();
				serverSocket = null;
			}
			
			
            private function socketConnectHandler(event:ServerSocketConnectEvent):void
            {
				//Debug.debug(_debugPrefix, "socketConnectHandler", event);
                var socket:Socket = event.socket;
                socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
            }
 
            private function socketDataHandler(event:ProgressEvent):*
            {
                try
                {
                    var socket:Socket = event.target as Socket;
                    var bytes:ByteArray = new ByteArray();
                    socket.readBytes(bytes);
                    var request:String = "" + bytes;
                    var filePath:String = request.substring(4, request.indexOf("HTTP/") - 1);
					if (_removeParametersAfterFilePath && filePath.indexOf("?") != -1) {
						filePath = filePath.substr(0, filePath.indexOf("?"));
					}
					if (VERBOSE) Debug.debug(_debugPrefix, "Serving and looking for local url: " + _assetsFolder + filePath);
					var file:File = UFile.referenceFile(_assetsFolder + filePath, _storageId, VERBOSE);
					if (!file.exists) return Debug.debug(_debugPrefix, "File not found.");
					const fileType:String = filePath.split(".").pop();
                    //log(request);
                    //var file:File = File.applicationDirectory.resolvePath("_assets" + filePath);
                    if (file.exists && !file.isDirectory)
                    {
                        var stream:FileStream = new FileStream();
                        stream.open( file, FileMode.READ );
                        var content:ByteArray = new ByteArray();
                        stream.readBytes(content);
                        stream.close();
                        socket.writeUTFBytes("HTTP/1.1 200 OK\n");
                        socket.writeUTFBytes("Content-Type: " + getMimeType(filePath) + "\n\n");
                        socket.writeBytes(content);
 
						
						
						
						socket.flush();
						//socket.close();

						if (socket.bytesPending && String("mp3,jpg,png").indexOf(fileType) != -1) {
							//Debug.warning(_debugPrefix, "SPECIAL FILEEEEEEE", socket.bytesPending);
							socket.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onSocketOutputProgress, false, 0, true);
						} else socket.close();
						
						
					}
                    else
                    {
						if (fileType == "html" || fileType == "htm") {
							socket.writeUTFBytes("HTTP/1.1 404 Not Found\n");
							socket.writeUTFBytes("Content-Type: text/html\n\n");
							socket.writeUTFBytes("<html><body><h2>Page Not Found</h2></body></html>");
						}
						socket.flush();
						socket.close();
					}
					
					
					
					//socket.addEventListener(flash.events.OutputProgressEvent.OUTPUT_PROGRESS,
					//function(evt:OutputProgressEvent)
					//{
					////trace("x");
						//if (evt.target.bytesPending==0)
						//{
							//evt.target.close();
							//evt.currentTarget.removeEventListener(evt.type, arguments.callee);// remove this listener
						//}
					//}, false, 0, true);					
					
                    //socket.flush();
                    //socket.close();
                }
                catch (error:Error)
                {
                    Debug.error(_debugPrefix, error.message);
                }
            }
			
			private function onSocketOutputProgress(e:OutputProgressEvent):void {
				if (e.target.bytesPending==0)
				{
					e.target.close();
					e.currentTarget.removeEventListener(e.type, onSocketOutputProgress);// remove this listener
				}
			}
			
			
			
			
			
            private function getMimeType(path:String):String
            {
                var mimeType:String;
                var index:int = path.lastIndexOf(".");
                if (index > -1)
                {
                    mimeType = mimeTypes[path.substring(index)];
                }
                return mimeType == null ? "text/html" : mimeType; // default to text/html for unknown mime types
            }		
		
		
		
			private function log(t:String):void {
				Debug.debug(_debugPrefix, t);
			}
		
		
	}

}