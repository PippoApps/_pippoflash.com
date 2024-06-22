/* SimpleQueueLoader - 1.0 - Filippo Gregoretti - www.pippoflash.com

Loads all kind of content depending on file extension, and holds them in memory.

METHODS
	SuperLoader.queueFile(uri:String, listener:Object, prioritize:Boolean=false, funcPostfix:String="", anticache:Boolean=false, listNum:int=-1, fileType:String="");
		Enqueues a file in the queue list.
	
		uri			URL of the file to load
		listener		Object to listen to single file events
		prioritize		If true, file gets queued first position in first list, otherwise last position in last list
		funcPostfix	Added to the events broadcasted by single loading instance
		anticache		If true, a random number is added at the end of url - [url]?0.23423423424
		listNum		Number of list to add the file to (if prioritize is false) file will be enqueued in this specified list
		fileType		txt,xml,data or text uses an URLLoader, while img,png, gif, etc. uses a Loader. If not specified, load type is retrieved from filename (not reliable for complex server calls)

	SuperLoader.addListener(listener:Object)
		Adds a listener to general SUperLoader events
	
	SuperLoader.removeListener(listener:Object)
		Removes a listener from general SUperLoader events


	
BROADCASTS - SuperLoader events
	These events are called on listeners added with SuperLoader.addListener();
	
	onQueueListComplete(listNum:uint);
		Called when a list has been completely loaded
	
	onQueueComplete()
		Called when the queue is completely loaded

BROADCASTS - SuperLoaderObject events
	These avents are triggered in the listener defined for single loader with queueFile();
	All events can be added with funcPostfix: onLoadStart+funcPostfix();
	
	onLoadStart(SuperLoaderObject);
	onLoadProgress(SuperLoaderObject);
	onLoadError(SuperLoaderObject);
	onLoadComplete(SuperLoaderObject);
	
	
	
	


*/
package com.pippoflash.net {
	
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import									flash.system.*;
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.UMem;
	import									com.pippoflash.utils.Debug;
	import									com.pippoflash.net.SimpleQueueLoaderObject;
	
	public class SimpleQueueLoader {
		// VARIABLES /////////////////////////////////////////////////////////////////////////////////////////////////
		// SWITCHES
		public static var _debugPrefix				:String = "SQLoader";
		private static var _verbose					:Boolean = false;
		private static var _isDebug					:Boolean = false;
		// DEFAULT
		public static var _maxConcurrentLoads			:uint = 1;
		// SYSTEM
		public static var _loadedContent				:Object = new Object(); // Stores each loaded content (may be Loader or URLLoader) by name of the url
// 		public static var _loadLists					:Array = [[]]; // Stores a sequence of lists based on priority - has to start with 1 for init purposes
		public static var _loadList					:Array = new Array(); // Sequence of loaders based on priority
		public static var _activeLoaders				:Object = new Object(); // Stores the active loaders (removed from lists)
		public static var _listenersList				:Array = new Array();
		public static var _allLoaders					:Array = new Array();
		// MARKERS
		public static var _loadsActive				:uint = 0; // The number of loads actually active
		// METHODS ////////////////////////////////////////////////////////////////////////////////////////////////////
		public static function reset():void {
			// Resets all lists, all items, stops all loadings, and resets, ONLY QUEUES!!!!!
			return;
		}
		public static function remove(uri:String):void {
			// Removes the selected load item
// 			_loadedContent[uri].harakiri				();
		}
		public static function queueFile				(uri:String, listener:Object, prioritize:Boolean=false, funcPostfix:String="", anticache:Boolean=false, fileType:String=""):SimpleQueueLoaderObject {
			var o								:Object = {
				// User parameters
				_url							:uri
				,_listener						:listener
				,_anticache					:anticache
// 				,_listNum						:listNum < 0 ? _loadLists.length -1 : listNum
				,_prioritize						:prioritize 
				,_fileType						:fileType
				,_funcPostfix					:funcPostfix
				,_isSuperLoaderQueue				:true
// 				,_timeout						:timeout
			}
			var slo							:SimpleQueueLoaderObject = UMem.give_SQLObject([o]); // Since I KNOW the code, I will ask it fastly UMem.give(SuperLoaderObject, o); // new SuperLoaderObject(o);
			_loadedContent[uri]					= slo;
			addToList							(slo);
			_allLoaders.push						(slo);
			checkForQueue						();
			return							slo;
		}
		public static function loadFile				(uri:String, listener:Object, funcPostfix:String="", anticache:Boolean=false, fileType:String=""):SimpleQueueLoaderObject {
		// This command DOESNT QUEUE anything, just creates a SuperLoaderObject to be returned and executes it right away
			var o								:Object = {
				// User parameters
				_url							:uri
				,_listener						:listener
				,_anticache					:anticache
				,_fileType						:fileType
				,_funcPostfix					:funcPostfix
// 				,_isSuperLoaderQueue				:false
// 				,_timeout						:timeout
			}
			var slo							:SimpleQueueLoaderObject = UMem.give_SQLObject([o]); // Since I KNOW the code, I will ask it fastly UMem.give(SuperLoaderObject, o); // new SuperLoaderObject(o);
			slo.startLoad						();
			return							slo;
		}
		public static function addListener				(o:Object):void {
			for (var i:Number=0; i<_listenersList.length; i++) if (_listenersList[i] == o) return;
			_listenersList.push					(o);
		}
		public static function removeListener			(o:Object):void {
			for (var i:Number=0; i<_listenersList.length; i++) {
				if (_listenersList[i] == o) {
// 					delete					_listenersList[i];
					_listenersList.splice			(i, 1);
					return;
				}
			}
		}
		public static function destroyObject			(s:String):void {
			delete							_loadedContent[s];
		}
		public static function getObject				(s:String):* {
			if (_loadedContent[s] == undefined)		Debug.debug(_debugPrefix, "LOADER NOT PRESENT:",s);
			else								return _loadedContent[s];
		}
		public static function getData				(s:String):* {
			return							getObject(s)._loader.data;
		}
		public static function getContent				(s:String):* {
			return							getObject(s).getContent();
		}
// UTY //////////////////////////////////////////////////////////////////////////////////////////////////////////
		// LIST LOAD MANAGEMENT
		private static function onStepCompleted			(o:SimpleQueueLoaderObject):void {
			if (_verbose) {
				if (o._isError)						Debug.debug(_debugPrefix, "Error loading:",o._url);
				else								Debug.debug(_debugPrefix, "Loading complete:",o._url);
			}
			delete							_activeLoaders[o._url];
			// Proceed with next loading
			_loadsActive						--;
			checkForQueue						();
		}
		private static function checkForQueue			():void {
			if (_loadsActive < _maxConcurrentLoads)	activateNextLoader();
		}
		private static function activateNextLoader		():void {
			if (_loadList.length == 0)				UCode.broadcastEventList(_listenersList, "onQueueComplete");
			else								loadNextItem();
		}
		private static function loadNextItem			():void {
			startLoadObject						(_loadList.shift());
		}
		public static function startLoadObject			(o:Object):void {
			if (_verbose)						Debug.debug(_debugPrefix, "Start loading:",o._url);
			_activeLoaders[o._url]					= o._listNum;
			o.startLoad							();
			_loadsActive						++;
		}
		private static function addToList				(o:SimpleQueueLoaderObject):void {
			// If prioritized add it at the beginning of first list
			if (o._prioritize) 						_loadList.unshift(o);
			else  							_loadList.push(o);
		}
// LISTENERS////////////////////////////////////////////////////////////////////////////////////////////////////
		// LOADER
		public static function onLoadCompleteLoader		(o:SimpleQueueLoaderObject):void { // Called by SQLObj when the loading process is completed with a success or with an error
			onStepCompleted						(o);
		}
	}
}