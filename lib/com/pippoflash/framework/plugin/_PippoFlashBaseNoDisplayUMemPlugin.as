/* _PippoFlashBaseNoDisplayUMem - (c) Filippo Gregoretti - PippoFlash.com */
/* This class is the base for ALL (non-static) NON-SINGLETON classes, visual or non-visual, that have to be instantiated several times, and are managed by UMem 
This one doesn't have any broadcasting mechanism since its possibly used for a lot of items.
*/


package com.pippoflash.framework.plugin {
	// IMPORTS ///////////////////////////////////////////////////////////////////////////
	import com.pippoflash.utils.UMem; import com.pippoflash.utils.UCode; import flash.display.MovieClip; import flash.display.Sprite; import flash.geom.Point;
	// DECLARATION /////////////////////////////////////////////////////////////////////////////
	public dynamic class _PippoFlashBaseNoDisplayUMemPlugin {
		// STATIC USER DEFINABLE //////////////////////////////////////////////////////
		public static var _mainApp					:*; // Reference to MainApp
		public static var _config					:*; // Reference to config file
		public static var _ref						:*; // Reference to _ref in 
		// STATIC SYSTEM 
		private static var _instancesCounterById		:Object = {}; // this holds the amount of instantiated instances
		private static var _instancesById				:Object = {}; // This holds a direct reference to each instance by debug id
		private static var _instancesByType			:Object = {}; // Holds an array by type without id, useful to launch a command to all instances
		// STATIC REFERENCES
		// UTY - STATIC
		protected static var _b						:Boolean;
		protected static var _xml					:XML;
		protected static var _node					:XML;
		protected static var _clip					:MovieClip;
		protected static var _c						:MovieClip;
		protected static var _sprite					:Sprite;
		protected static var _counter				:int = 0;
		protected static var _o						:Object;
		protected static var _a						:Array;
		protected static var _n						:Number;
		protected static var _i						:int;
		protected static var _s						:String;
		protected static var _point					:Point;
		protected static var _j						:*;
		// DYNAMIC SYSTEM ///////////////////////////////////////////////////////
		protected var _debugPrefix					:String; // Marks the ID of the item, good for initialization, text, and storage purposes
		protected var _classId						:String;
		private var _refToList						:Array; // a reference to its own array list
		private var _status						:int = 0;
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function _PippoFlashBaseNoDisplayUMemPlugin	(id:String="_PippoFlashBaseNoDisplayUMemPlugin") {
			// Remember to add this to UMEM in the class that uses it
			_classId							= id;
			// Create array for type of instance
			if (_instancesByType[id]) {
				_instancesByType[id].push			(this);
				_instancesCounterById[id] 			+= 1;
			}
			else {
				_instancesByType[id]				= [this];
				_instancesCounterById[id] 			= 1;
			}
			_refToList							= _instancesByType[id];
			_debugPrefix						= id + (_instancesCounterById[id]-1);
			_instancesById[_debugPrefix]			= this;
		}
// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		public static function callClassInstancesMethod	(group:String, method:String, ...rest):void {
			var a								:Array = _instancesByType[group];
			if (a) {
				for (var i:uint=0; i<a.length; i++)	{
					UCode.broadcastEvent(a[i], method, rest);
				}
			}
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		protected function setInitialized():void {
			_status = 1;
		}
		protected function setRecycled():void {
			_status = 2;
		}
		protected function setReady():void {
			_status = 3;
		}
		protected function complete():void {
			_status = 4;
		}
		public function isStartup():Boolean {
			return _status == 0;
		}
		public function isInitialized():Boolean {
			return _status == 1;
		}
		public function isRecycled():Boolean { // Stored and ready to be retrieved from UMem
			return _status == 2;
		}
		public function isReady():Boolean { // Ready to be rendered
			return _status == 3;
		}
		public function isRendered():Boolean { // Rendered - Occupied with data and working
			return _status == 4;
		}
		// MEMORY MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		// Recycle is not set since number and type of parameters may change
		// this is called by UMem once memory has to be cleaned
		public function harakiri():void { // Called on a UMem.killInstance
			cleanup();
			UCode.removeArrayItem(_refToList, this);
			delete _instancesById[_debugPrefix];
			_status = 0;
		}
		// Cleanup is set and must be overridden since its called by harakiri also
		// This is called by UMem once an instance is stored
		public function cleanup():void {
			release();
			setRecycled();
		}
		// Release is used to release any rendering and be ready to be re-rendered.
		public function release():void {
			setReady();
		}
		// UTY /////////////////////////////////////////////////////////////////////////////////////////
		public function getClassId():String {
			return _classId;
		}
		// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}