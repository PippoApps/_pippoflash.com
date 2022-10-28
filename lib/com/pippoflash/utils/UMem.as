/* UMem - ver 0.2 - Filippo Gregoretti - www.pippoflash.com


0.2 - Removed _busy list since useless



Manages Instances and garbage Collection, so that the instances that can be reused, such as Loaders, etc, are just reused without instantiating hundreds of them...

The classes managed by this system, share 3 functions: instantiation or recycle(), cleanup() on store, and harakiri() on kill
- cleanup() - releases everything but keeps the instance stored and ready to be reaused
- harakiri() - shuts them down and frees memory as much as possible...
- recycle() - re-initializes them with exactly same parameters as in constructor....

Before adding a new class, I have to call the addManagedClass(id:String, class:Class);
in this way UMem knows how to manage recycled classes

then, I can call:
giveInstanceId(id:String);
or
getInstance(class);
and it returns a new instance or a recycled one.


*/

package com.pippoflash.utils {

	import com.pippoflash.framework.PippoFlashEventsMan;
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.Debug;
	import									com.pippoflash.utils.Buttonizer;
	import									com.pippoflash.utils.UDisplay;
	//import									com.pippoflash.net.SuperLoaderObject;
	import									com.pippoflash.net.SimpleQueueLoaderObject;
	import									flash.display.*;
	import									flash.system.*;
	import									flash.net.*;
	import 									flash.utils.*;
	import									flash.utils.Dictionary;

	public class UMem {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		public static var _verbose					:Boolean = false;
		public static var _debugPrefix				:String = "UMem";
		// UTY
		// MARKERS
		// HOLDERS
		public static var _classes					:Object = { // This contains classes objects to manage free and busy references. Default internal classes must be pre-defined here
			//SLObject:{_free:[], _class:SuperLoaderObject, _max:100}, 
			SQLObject:{_free:[], _class:SimpleQueueLoaderObject, _max:100}
		}; 
		public static var _classToId					:Dictionary = new Dictionary(); // This links directly the class  to the ID string
 		// STATIC UTY
		private static var _s						:String;
		private static var _o						:Object;
		private static var _clip						:DisplayObject;
		private static var _obj						:*;
// METHODS TO ADD MANAGED CLASSES ///////////////////////////////////////////////////////////////////////////////////////
		public static function addClass				(cl:Class):void { // Adds the class guessing the id from string
			addManagedClass					(String(cl), cl);
		}
		public static function addClassString(id:String):void { // Gets a string and adds a class from the string
			if (_classes[id]) return; // Class is alredy added as managed, no need to add again
			var cl							:Class = Class(getDefinitionByName(id));
			try {
				addManagedClass(id, cl);
			}
			catch (e:Error) {
				Debug.error						(_debugPrefix, "Cannot find class for name: " + id);
			}
		}
		public static function addManagedClass(id:String, cl:Class) {
			// This creates an object for each kind of class. Each object contains a list of busy, a reference object of busy one, and a reference to the class. ONLY IF IT DOESNT ALREADY EXIST
			if (!_classes[id])	{ // This is so that class is not associated twice
				_classes[id] = {_free:[], _class:cl};
				_classToId[cl]					= id; // This associates the class directly to its own id
			}
		}
		public static function addClasses				(classes:Array):void {
			for (var i:uint=0; i<classes.length; i++)		addClass(classes[i]);
		}
		public static function addManagedInstance		(item:*):void {
			addClass							(Object(item).constructor as Class);
		}
// METHODS - CREATORS /////////////////////////////////////////////////////////////////////////////////////
		public static function getInstance				(cl:Class, ...rest):* {
			return							getInstanceInternal(_classToId[cl], rest);
		}
		public static var giveInstanceId				:Function = getInstanceId;
		public static function getInstanceId			(id:String, ...rest):* {
			return							getInstanceInternal(id, rest);
		}
	// PIPPOFLASH DEDICATED
		//public static function give_SLObject			(rest:Array):SuperLoaderObject { // this returns objects. Parameters are set in a sequence of parameters
			//return							getInstanceInternal("SLObject", rest);
		//}
		public static function give_SQLObject			(rest:Array):SimpleQueueLoaderObject { // this returns objects. Parameters are set in a sequence of parameters
			return							getInstanceInternal("SQLObject", rest);
		}
// METHODS - KILLERS /////////////////////////////////////////////////////////////////////////////////////////
		public static function killInstance				(obj:*):void { // This kills the instance and removes it completely!!!
// 			trace("KILL INSTAMCEEEEEEEEEEEEEEEEE " , obj);
// 			releaseInstance						(_classToId[Object(obj).constructor as Class], obj); // Removes instance from busy list
			UCode.callMethod					(obj, "harakiri"); // In case harakiri exists its called
		}
		public static function storeInstance			(obj:*) { // this stores the instance for later use - without killing it
// 			trace("chiamano storeInstance()");
			storeInstanceId						(_classToId[Object(obj).constructor as Class], obj);
		}
		public static function storeAndRemove			(obj:*):void {
			UDisplay.removeClip(obj);
			storeInstance(obj);
		}
		public static var storeInstances:Function = storeInstanceList;
		public static function storeInstanceList(l:*):void { // This grabs an array or a vector or an object
			if (_verbose) Debug.debug(_debugPrefix, "Storing a list of instances: " + l);
			for each (_obj in l) {
				storeInstance(_obj);
			}
			_obj = null;
		}
		public static function storeAndRemoveList		(l:*):void {
			if (l)								for each (_obj in l) storeAndRemove(_obj);
			_obj								= null;
		}
	// PIPPOFLASH DEDICATED
		//public static function kill_SLObject			(obj:SuperLoaderObject) {
			//obj.harakiri						();
			//storeInstanceId						("SLObject", obj);
		//}
		public static function kill_SQLObject(obj:SimpleQueueLoaderObject) {
			if (obj.isKilled()) return;
			obj.cleanup();
			storeInstanceId("SQLObject", obj);
		}
		public static function kill_Loader(obj:Loader):void {
			obj.unloadAndStop();
			obj.unload();
		}
// METHODS  - GENERAL UTILITIES ///////////////////////////////////////////////////////////////////////////////////////
		public static function killClipList				(a:*, recursive:Boolean=false) {
			for each (_clip in a)					killClip(_clip, recursive);
		}
		public static var killClips					:Function = killClipList;
		public static function killClip					(c:*, recursive:Boolean=false) {
// 			trace("UCCIDO CLIP",c);
			if (c == null)						return;
			else if (c is Bitmap)					killBitmap(c);
			else if (c is BitmapData)				killBitmapData(c);
			else {
				Buttonizer.removeButton			(c);
				UDisplay.removeClip				(c);
				UCode.callMethod				(c, "harakiri");
				if (recursive)					clearRecursiveProperties(c);
			}
			// Here I should remove all possible event listeners
		}
		public static function killBitmap(b:Bitmap):void {
			UDisplay.removeClip(b);
			b.bitmapData.dispose();
		}
		public static function killBitmapData			(b:BitmapData):void {
			b.dispose							();
		}
		public static function killLoadedSwf			(c:MovieClip):void {
			UDisplay.removeClip					(c);
			UCode.callMethod					(c, "dispose");
			UCode.callMethod					(c, "harakiri");
			UCode.callMethod					(c, "unloadAndStop");
		}
		public static function clearRecursiveProperties		(c:*) {
			for (_s in c) {
				clearRecursiveProperties			(c[_s]);
				c[_s]							= null;
				delete						c[_s];
			}
		}
		public static function clearProperties			(c:*):void {
			for (_s in c) {
				c[_s]							= null;
				delete						c[_s];
			}
		}
		public static function forceGarbageCollection		() {
			System.gc							();
			try {
				new LocalConnection().connect('garbageCollector');
				new LocalConnection().connect('garbageCollector');
			} catch(e){}
		}
	// CHECKS
		public static function hasClass				(cl:Class):Boolean { // Tells if a class is already managed
			return							Boolean(_classToId[cl])					
		}
		public static function hasClassId				(id:String):Boolean { 
			// this checks for components. they are added with addManagedClass(class, componentId) so I alreayd know the id!
			return							Boolean(_classes[id]);
		}
// UTY - GET INSTANCE ///////////////////////////////////////////////////////////////////////////
		private static function getInstanceInternal		(id:String, rest:Array):* {
// 			return createNewInstance(id, rest); // CREATES A NEW INSTANCE
// 			trace("ORA DEVO CAPIRE CHE CAZZO PERCHE' NON CESTANNO!",id,_classes[id],_classes[id]._free.length);
// 			try {
				if (_classes[id]._free.length)				return recycleInstance(id, rest); // Recycles a stored instance
				else								return createNewInstance(id, rest); // CREATES A NEW INSTANCE
// 			}
// 			catch (e:Error) {
// 				Debug.error						(_debugPrefix, "Cannot find instances for class: " + id);
// 				return null;
// 			}
		}
	// CREATE - Creates new instances according to number of parameters
		private static function createNewInstance		(id:String, rest:Array):* {
				if (_verbose)					Debug.debug(_debugPrefix, "Create new instance:", id, rest);
// 			trace("CAZZO RICICLO ISTANZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",id,rest,rest.length);
				var o							:* = UMem["createInstance"+rest.length](id, rest);
// 			trace("adding to busy list:",o);
// 				addInstanceToBusyList				(id, o);
// 			traceContents						();
// 			trace("CREATE",id,". Free:"+_classes[id]._free.length+". Busy:"+_classes[id]._busy.length);
				return 						o;
		}
		private static function createInstance0			(id:String, a:Array=null) {
			return							new _classes[id]["_class"]();
		}
		private static function createInstance1			(id:String, a:Array) {
			return							new _classes[id]["_class"](a[0]);
		}
		private static function createInstance2			(id:String, a:Array) {
// 			trace("CAZZO QUESTAAAAAAAAAAAAAAAAAAAAAAAAA");
			return							new _classes[id]["_class"](a[0], a[1]);
		}
		private static function createInstance3			(id:String, a:Array) {
			return							new _classes[id]["_class"](a[0], a[1], a[2]);
		}
		private static function createInstance4		(id:String, a:Array) {
			return							new _classes[id]["_class"](a[0], a[1], a[2], a[3]);
		}
	// RECYCLE - Grabs an instance from the _free list
		private static function recycleInstance			(id:String, a:Array) { // Gets a free instance and launches a recycle
// 			trace("RICICLO ISTANZA DI",id,"la lunghezza ora è di:",_classes[id]._free.length);
			var o								:* = _classes[id]._free.pop();
// 			trace("dopo il pop() invece è lunga",_classes[id]._free.length);
			if (_verbose)						Debug.debug(_debugPrefix, "Recycles an old",o);
// 			addInstanceToBusyList					(id, o);
// 			trace("CAZZO RICICLO ISTANZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",id,a);
			UCode.callMethodArray				(o, "recycle", a);
// 			traceContents						();
// 			trace("RECYCLE",id,". Free:"+_classes[id]._free.length+". Busy:"+_classes[id]._busy.length);
			return							o;
		}
	// BUSY LIST	
// 		private static function addInstanceToBusyList		(id:String, obj:*) {
// 			_classes[id]._busy.push				(obj);
// 			trace("addInstanceToBusyList("+id+","+obj+")",_classes[id]._busy.length,_classes[id]._busy.indexOf(obj),_classes[id]._busy);
// 			trace("POSITION?",_classes[id]._busy.indexOf(obj));
// 		}
// UTY //////////////////////////////////////////////////////////////////////////////////////////
// 		private static function traceContents			():void {
// 			for (_s in _classes) {
// 				_o							= _classes[_s];
// 				trace(_s+"> Free:"+_o._free.length+" - Busy:"+_o._busy.length);
// 			}
// 		}
// UTY - KILL INSTANCE /////////////////////////////////////////////////////////////////////////////
		private static function storeInstanceId			(id:String, obj:*):void { // This works with any ID which has been added
			if (_verbose)						Debug.debug(_debugPrefix, "Storing instance",id,obj);
			// Here, first I have to check if instance is not already stored
			if (_classes[id]._free.indexOf(obj) != -1) {
				Debug.error					(_debugPrefix, "storeInstanceId ERROR - obj",obj,"is already stored in UMem");
// 				trace("SEMBRA CHE L'ARRAY SIA LUNGO: ",_classes[id]._free.length,"index è",_classes[id]._free.indexOf(obj));
// 				trace("ECCO L?ARRAY:",_classes[id]._free);
// 				trace("FINE STORE ERROR ");
				return;
			}
			// Here I have to check if instance has NEVER been stored
// 			else if (_classes[id]._busy.indexOf(obj) == -1) {
// 				Debug.error					(_debugPrefix, "storeInstanceId ERROR - obj",obj,"in not contained in busy list. Cannot store.");
// 				return;
// 			}
			PippoFlashEventsMan.removeAllListeningToInstance(obj);
			UCode.callMethod(obj, "cleanup");
			if (obj is DisplayObject) { // Reset display object properties
				if (obj.parent)					obj.parent.removeChild(obj);
				obj.x = obj.y = obj.rotation			= 0;
				obj.scaleX = obj.scaleY = obj.alpha	= 1;
			}
// 			releaseInstance						(id, obj);
			_classes[id]._free.push				(obj); // Add the object to the free list
			if (_verbose)						Debug.debug(_debugPrefix, "Instance stored in slot:",_classes[id]._free.indexOf(obj));
		}
// 		private static function releaseInstance			(id:String, obj) { // This removes instance from busy list
// 			if (_verbose)						Debug.debug(_debugPrefix, "Releasing instance from busy list. Length:",_classes[id]._busy.length,"pos:",_classes[id]._busy.indexOf(obj));
// 			UCode.removeArrayItem				(_classes[id]._busy, obj); // Remove reference in busy list
// 		}
	}
}

/* ________________________________________________________
All AS files and libraries included in the domain com.pippoflash.*
Are open.source libraries developed by Filippo Gregoretti, and are therefore not copyrightable.
They can be used in commercial projects but must be left free for re-distribution and usage.
They go with all MovieClips included in the .fla or .xfl document, in the folders:
- PippoFlash.com - Framework

- PippoFlash.com - Components
All movieclips and assets within those folders in the source flash document (fla or xfl) 
are open source anc dan be used in commercial projects, but cannot be copyrighted.
__________________________________________________________ */