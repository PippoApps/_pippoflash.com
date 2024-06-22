package com.pippoflash.data 
{
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework._Application;
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMemDispatcher;
	import com.pippoflash.net.QuickLoader;
	import com.pippoflash.utils.*;
	import com.pippoflash.net.SimpleQueueLoaderObject;
	
	/**
	 * Stores a Json or XML set of data. It can have a default, reload it, or save it locally.
	 * @author Pippo Gregoretti
	 */
	public class DataSet extends _PippoFlashBaseNoDisplayUMemDispatcher 
	{
		public static const SO_PRE_DATASET_NAME:String = "PippoApps_DataSet__|-";
		public static const EVT_DATA_UPDATED:String = "onDataSetUpdated"; // this
		public static const EVT_UPDATE_STEP_ERROR:String = "onDataSetUpdateStepError"; // this, step:String
		public static const EVT_DATA_ERROR:String = "onDataSetError"; // this, error:String
		private static const SHARED_OBJECT:String = "SharedObject";
		private static const _dataIdsUsed:Object = {}; // Stores instance references to data ID to check whether a new data ID is used
		private var _type:String = "xml"; // Defaults to XML
		private var _dataId:String;
		private var _dataFileId:String;
		private var _dataXml:XML;
		private var _dataJson:Object;
		//private var _storeLocally:Boolean;
		private var _storeAsSharedObject:Boolean;
		//private var _storeAsFile:Boolean;
		
		private var _updateSequence:Array;
		private var _updateStep:String;
		private var _updateStepNum:uint;
		private var _urlLoadHeaders:Object;
		//private var _url:String;
		//private var _localUrl:String;
		
		
		
		// STATIC METHODS
		static public function getDataFromId(id:String):DataSet {
			return _dataIdsUsed[SO_PRE_DATASET_NAME + id];
		}
		static public function isUrl(s:String):Boolean {
			return s.indexOf("https://") == 0 || s.indexOf("http://") == 0; 
		}
		
		
		
		
		// INIT
		public function DataSet(id:String, type:String="xml") {
			super(SO_PRE_DATASET_NAME + id);
			if (getDataFromId(id)) {
				Debug.error(_debugPrefix, "Data id " + id + " is already used! Aborting initialization.");
				return;
			}
			_dataId = id;
			_type = type;
			//_storeLocally = storeLocally;
			_dataIdsUsed[id] = this;
			_dataFileId = SO_PRE_DATASET_NAME + id + "." + _type;
			//setupDataSet();
		}
		/**
		 * Attemps to load data from a sequence of urls (no matter if remote or local) using also keywords
		 * @param	sequence List of urls or keywords: SharedObject, File
		 */
		public function updateFrom(sequence:Array):void {
			Debug.debug(_debugPrefix, "Updating from sequence: " + sequence);
			_updateSequence = sequence;
			updateStep(0);
		}
		
		
		// METHODS
		///**
		 //* Updates data from a URL. If URL is not available, a sharedobject will be used. If shared object is not available, a file will be used.
		 //* @param	url the url where to look for file
		 //* @param	sharedObjectFallback if no internet or url not found a shared bject saved version will be looked for
		 //* @param	fileFallbackDataFolder the data folder where to look for file (as ID + extension).
		 //*/
		//public function updateFromUrl(url:String, sharedObjectFallback:Boolean=true, fileFallbackDataFolder:String=null):void {
			//
		//}
		//public function updateFromSharedObject():void {
			//Debug.debug(_debugPrefix, "Updating from shared object: " + _dataFileId);
		//}
		//public function updateFromFile(dataFolder:String):void {
			//
		//}
		//public function loadDefaultFromSharedObject():void {
			//
		//}
		//public function loadDefaultFromFile():void {
			//
		//}
		
		
		// UTY
		private function updateStep(s:uint):void {
			_updateStepNum = s;
			if (_updateStepNum < _updateSequence.length) {
				_updateStep = _updateSequence[_updateStepNum];
				Debug.debug(_debugPrefix, "Updating step", _updateStepNum, _updateStep);
				if (_updateStep == SHARED_OBJECT) updateFromSharedObject();
				else updateFromUrl();
			} else { // Out of update steps
				Debug.debug(_debugPrefix, "Out of steps. Data updte failed.");
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_DATA_ERROR);
			}
		}
		private function updateNextStep():void {
			updateStep(_updateStepNum + 1);
		}
		private function updateFromUrl():void {
			Debug.debug(_debugPrefix, "Updating from URL.");
			QuickLoader.loadFile(_updateStep, this, "Url", false, "xml", _urlLoadHeaders);
		}
		private function updateFromSharedObject():void {
			Debug.debug(_debugPrefix, "Updating from SharedObject: " + _dataFileId);
			if (typeXml) {
				_dataXml = _Application.instance.getSharedObject(_dataFileId);
			}
			if (data) {
				Debug.debug(_debugPrefix, "SharedObject found.");
				completeUpdateProcess();
			}
			else {
				Debug.debug(_debugPrefix, "SharedObject not found.");
				updateNextStep();
			}
		}
		private function completeUpdateProcess():void {
			// If store as shared object and it is not taken from shared object
			if (_storeAsSharedObject && _updateStep != SHARED_OBJECT) {
				Debug.debug(_debugPrefix, "Saving data in SharedObject.");
				_Application.instance.setSharedObject(_dataFileId, data);
			}
			Debug.debug(_debugPrefix, "Update process successful.");
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_DATA_UPDATED, this);
		}
		// LISTENERS
		public function onLoadCompleteUrl(o:SimpleQueueLoaderObject):void {
			Debug.debug(_debugPrefix, "Load complete: " + _updateStep);
			Debug.debug(_debugPrefix, o.getContent());
			if (typeXml) {
				Debug.debug(_debugPrefix, "Setting up as XML.");
				_dataXml = new XML(o.getContent());
			}
			completeUpdateProcess();
		}
		public function onLoadErrorUrl(o:SimpleQueueLoaderObject, error:String):void {
			Debug.debug(_debugPrefix, "Load error: " + _updateStep, error);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_UPDATE_STEP_ERROR, _updateStep);
			updateNextStep();
		}
		
		
		// GET SET
		
		public function get typeJson():Boolean {
			return _type == "json";
		}
		public function get typeXml():Boolean {
			return _type == "xml";
		}
		/**
		 * Returns data XML or JSON according to file type
		 */
		public function get data():Object {
			return typeXml ? _dataXml : _dataJson;
		}
		/**
		 * Whether data once loaded has to be stored as a shared object.
		 */
		 public function get dataXml():XML 
		 {
			 return _dataXml;
		 }
		 
		 public function get dataJson():Object 
		 {
			 return _dataJson;
		 }
		 
		public function set storeAsSharedObject(value:Boolean):void 
		{
			_storeAsSharedObject = value;
		}
		
		public function set urlLoadHeaders(value:Object):void 
		{
			_urlLoadHeaders = value;
		}
		
	}

}