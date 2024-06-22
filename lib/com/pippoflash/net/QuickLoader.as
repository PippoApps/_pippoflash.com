/* QuickLoader - 1.0 - Filippo Gregoretti - www.pippoflash.com

Loads all kind of content depending on file extension, with or without post vars.

*/
package com.pippoflash.net {
	
	import flash.display.*;
	import flash.text.*;
	import flash.net.*;
	import flash.events.*;
	import flash.system.*;
	import com.pippoflash.utils.*;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	
	public class QuickLoader {
		// VARIABLES /////////////////////////////////////////////////////////////////////////////////////////////////
		// EVENT CONSTANTS
		public static const EVT_START:String = "onLoadStart";
		public static const EVT_INIT:String = "onLoadInit";
		public static const EVT_PROGRESS:String = "onLoadProgress";
		public static const EVT_ERROR:String = "onLoadError";
		/**
		 * Fired on load complete.
		 */
		public static const EVT_COMPLETE:String = "onLoadComplete";
		// STATIC VARIABLES
		private static const _debugPrefix:String = "QuickLoader";
		// SWITCHES
		public static var _verbose:Boolean = false;
		// DEFAULT
		// SYSTEM
		// MARKERS
		// METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////
		/**
		 * 
		 * @param	uri The complete url of file
		 * @param	listener An object to contain public methods accessible (see constants EVT_...). All events will have the instance of SimpleQueueLoaderObject as single parameter.
		 * @param	funcPostfix Will be added at the end of callbak names (i.e., set "Image", callbacks will be "onLoadStartImage", etc.)
		 * @param	anticache Set to true to add a ?random at the end of url (only works on http)
		 * @param	fileType This is found automatically, but can be set as (txt,json,xml... or bmp,img,jpg...). Binary or text.
		 * @param	headers Add custom headers.
		 * @return 	Returns an instance of  SimpleQueueLoaderObject
		 */
		public static function loadFile(uri:String, listener:Object, funcPostfix:String="", anticache:Boolean=false, fileType:String="", headers:Object=null, forceURLStream:Boolean=false):SimpleQueueLoaderObject {
		// This command DOESNT QUEUE anything, just creates a SuperLoaderObject to be returned and executes it right away
		if (_verbose) Debug.debug(_debugPrefix, "Loading: " + uri);
			var o:Object = {
				// User parameters
				_url:uri
				,_listener:listener
				,_anticache:anticache
				,_fileType:fileType
				,_funcPostfix:funcPostfix
				,_isSuperLoaderQueue:false
				,_requestHeaders:headers
				,_forceURLStream:forceURLStream
			}
			var slo:SimpleQueueLoaderObject = UMem.give_SQLObject([o]); // new SimpleQueueLoaderObject(o);
			slo.startLoad();
			return slo;
		}
		public static function loadFilePostVars			(uri:String, listener:Object, funcPostfix:String="", postVars:Object=null, anticache:Boolean=false, fileType:String="", headers:Object=null):SimpleQueueLoaderObject {
		// This command DOESNT QUEUE anything, just creates a SuperLoaderObject to be returned and executes it right away
		if (_verbose)							Debug.debug(_debugPrefix, "POSTVARS> " + uri);
			var o								:Object = {
				// User parameters
				_url							:uri
				,_listener						:listener
				,_anticache					:anticache
				,_fileType						:fileType
				,_funcPostfix					:funcPostfix
				,_isSuperLoaderQueue				:false
				,_dataObject					:postVars
				,_isPost						:true
				,_requestHeaders				:headers
			}
			var slo							:SimpleQueueLoaderObject = UMem.give_SQLObject([o]); // new SimpleQueueLoaderObject(o);
			slo.startLoad						();
			return							slo;
		}
		// UTY //////////////////////////////////////////////////////////////////////////////////////////////////////////
		// LISTENERS////////////////////////////////////////////////////////////////////////////////////////////////////
	}
}