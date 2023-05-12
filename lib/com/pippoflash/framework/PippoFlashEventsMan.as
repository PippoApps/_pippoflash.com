/* PippoFlashEventsMan - (c) Filippo Gregoretti - PippoFlash.com */
/* Manages events at Class level, instance level, or duplicated as a single dispatcher.

- Listeners can be added as general listener, or listener to, but that means methods will be called directly from instance, and they have to be public.
- Listeners can be also added as functions to single methods. In that case they can also be private.

Class can broadcast events here, or single instances.
Also, manager can be instantiated and will work on his own. Still have to find out why this would be useful :) probvably for UMem stuff that wants to make sure all references are destroyed.

This class can be statically used to broadcast events for other static classes, or can be instantiated to create a single events manager. No need to be extended, you can just instantiate one, or use directly the broadcaster.

Events are called with callPrivateEvent... that means _PippoFlashBase will call the event. EVENTS MUST BE PROTECTED, not PRIVATE;




*/


package com.pippoflash.framework {
// IMPORT FLASH /////////////////////////////////////////////////////////
	import flash.geom.*; import flash.display.*; import flash.events.*; import flash.utils.*;
// IMPORT PIPPOFLASH /////////////////////////////////////////////////////
	import com.pippoflash.utils.UCode; 
	import com.pippoflash.utils.Debug; 
// 	import com.pippoflash.framework.interfaces.IPippoFlash;  
	import com.pippoflash.framework.interfaces.IPippoFlashEventDispatcher;  
	import com.pippoflash.framework._PippoFlashBaseStatic;  
	// import com.pippoflash.framework.interfaces.IPippoFlashEventsReceiver;
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public class PippoFlashEventsMan extends _PippoFlashBaseStatic {
	// STATIC USER DEFINABLE //////////////////////////////////////////////////////
	// STATIC BROADCAST ///////////////////////////////////////////////////////////////////////////////////////
		protected static var _staticListeners			:Dictionary = new Dictionary(true); // Stores listener for all events of a static class
		protected static var _staticListenersTo			:Dictionary = new Dictionary(true); // Stores listeners for a single event of a static class
		protected static var _staticListenersToFunc		:Dictionary = new Dictionary(true); // Stores functiuons to listen to single events of a static class
		
		protected static var _staticInstanceListeners:Dictionary = new Dictionary(true); // Stores listener for all events of an instance
		protected static var _staticInstanceListenersTo:Dictionary = new Dictionary(true); // Stores listeners for a single event of an instance
		protected static var _staticInstanceListenersToFunc:Dictionary = new Dictionary(true); // Stores listeners for a single event of an instance
		static protected var _staticInstanceReBroadcasters:Dictionary = new Dictionary(true); // Stores other instances, that re-broadcast the same events as it they were their events
	// DYNAMIC ///////////////////////////////////////////////////////////////////////////////////////
		// SYSTEM
		//protected var _listeners					:Vector.<Object>; // List of listeners for each instance (They must implement the IPippoFlashBase). This will become a vector.
		//protected var _eventListeners				:Object; // Stores references by event name to listener 
		//protected var _eventListenersFunc			:Object; // Stores direct function references for a single listener
		protected var _id						:String;
		protected var _postfix						:String;
		// STATIC UTY
		protected static var _pf					:Object; // Temporarily stores an event listener
		protected static var _pfGroup				:Vector.<Object>; // Temporarily stores a group of event listeners
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function PippoFlashEventsMan			(id:String="PFEventsMan", postfix:String="") { // instance will become IPippoFlashBase
			_id								= id;
			_postfix							= postfix;
			//resetListeners						();
		}
// EVENTS ///////////////////////////////////////////////////////////////////////////////////////
		//public function resetListeners				():void {
			//_listeners							= new <Object>[];
			//_eventListeners						= {};
			//_eventListenersFunc					= {};
		//}
		//public function broadcastEvent				(evt:String, ...rest):void {
			//// events will be broadcasted with internal caller, so that also private functions can be added
			//broadcastIPFGroupEvent				(_listeners, evt+_postfix, rest);
			//if (_eventListeners[evt]) 				broadcastIPFGroupEvent(_eventListeners[evt], evt+_postfix, rest);
			//if (_eventListenersFunc[evt])			callMethods(_eventListenersFunc[evt], rest);
		//}
// GROUP LISTENERS MANAGEMENT //////////////////////////////////////////////////////////////////////////////////////
		//public function addListener					(listener:Object):void {
			//if (_listeners.indexOf(listener) == -1)		_listeners.push(listener);
		//}
		//public function removeListener				(listener:Object):void {
			//UCode.removeVectorItem				(_listeners, listener);
		//}
// SINGLE EVENT LISTENERS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		//public function addListenerTo				(evt:String, listener:Object):void { // Adds a listener for a single event
			//if (!_eventListeners[evt])				_eventListeners[evt] = new <Object>[];
			//// If Listener was already defined remove it from general listeners chain
			//if (_listeners.indexOf(listener))			UCode.removeVectorItem(_listeners, listener);
		//}
		//public function removeListenerTo				(evt:String, listener:Object):void {
			//if (_eventListeners[evt]) 				UCode.removeVectorItem(_eventListeners[evt] , listener);
		//}
// SINGLE EVENTS SINGLE FUNCTION ///////////////////////////////////////////////////////////////////////////////////////
		//public function addMethodListenerTo(evt:String, f:Function):void { // Adds a listener for a single event
			//if (!_eventListenersFunc[evt]) _eventListenersFunc[evt] = new <Function>[];
			//if (_eventListenersFunc[evt].indexOf(f) == -1) _eventListenersFunc[evt].push(f);
		//}
		//public function removeMethodListenerTo		(evt:String, f:Function):void {
			//if (_eventListenersFunc[evt]) UCode.removeVectorItem(_eventListenersFunc[evt], f);
		//}
//  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STATIC BROADCASTERS /////////////////////////////////////////////////////////////////////////////////////
//  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// This adds event broadcasting capabilities to static classes. No need to extend this.
	// Static listener management is not cleanable or recyclable automatically, as it refers to Static classes only, not poolable
	// Always add classes with "Class as _PippoFlashBaseStatic" or compiler will throw an error
		public static function addStaticListener(cl:Class, listener:Object):void {
			if (!_staticListeners[cl]) _staticListeners[cl] = new <Object>[];
			if (_staticListeners[cl].indexOf(listener) == -1) _staticListeners[cl].push(listener);
		}
		public static function removeStaticListener(cl:Class, listener:Object):void {
			trace("E");
			if (_staticListeners[cl]) UCode.removeVectorItem(_staticListeners[cl], listener);	
		}
		public static function addStaticListenerTo(cl:Class, evt:String, listener:Object):void {
			if (!_staticListenersTo[cl]) _staticListenersTo[cl] = {};
			if (!_staticListenersTo[cl][evt]) _staticListenersTo[cl][evt] = new <Object>[];
			if (_staticListenersTo[cl][evt].indexOf(listener) == -1) _staticListenersTo[cl][evt].push(listener);
			// Is some listener is already also in the general class listening
			if (_staticListeners[cl]) {
				Debug.error("PippoFlashEventsMan", "Static Listener " + listener + " for class " + cl + " is already registered as general listener, I add it to listen for " + evt + " and remove it from general listeners.");
				removeStaticListener(cl, listener);
			}
		}
		public static function removeStaticListenerTo(cl:Class, evt:String, listener:Object):void {
			if (_staticListenersTo[cl] && _staticListenersTo[cl][evt])	{ // Listener exists
				UCode.removeVectorItem(_staticListenersTo[cl][evt], listener);
			}
		}
		public static function addStaticMethodListenerTo	(cl:Class, evt:String, f:Function):void {
			if (!_staticListenersToFunc[cl]) _staticListenersToFunc[cl] = {};
			if (!_staticListenersToFunc[cl][evt]) _staticListenersToFunc[cl][evt] = new <Function>[];
			if (_staticListenersToFunc[cl][evt].indexOf(f) == -1) _staticListenersToFunc[cl][evt].push(f);
		}
		public static function removeStaticMethodListenerTo(cl:Class, evt:String, f:Function):void {
			if (_staticListenersToFunc[cl] && _staticListenersToFunc[cl][evt])	{ // Listener exists
				UCode.removeVectorItem(_staticListenersToFunc[cl][evt], f);
			}
		}
	// Broadcasting events
		public static function broadcastStaticEvent(cl:Class, evt:String, ...rest):void {
			if (_staticListeners[cl]) broadcastIPFGroupEvent(_staticListeners[cl], evt, rest);
			if (_staticListenersTo[cl] && _staticListenersTo[cl][evt]) broadcastIPFGroupEvent(_staticListenersTo[cl][evt], evt, rest);
			if (_staticListenersToFunc[cl] && _staticListenersToFunc[cl][evt]) callMethods(_staticListenersToFunc[cl][evt], rest);
		}
//  ///////////////////////////////////////////////////////////////////////////////////////
// STATIC INSTANCE LISTENERS /////////////////////////////////////////////////////
//  ///////////////////////////////////////////////////////////////////////////////////////
	// This manages listeners for an instance, not necessarily for a class. This can be used for single instance events broadcasting.
	// Just use this to centralize all events. Just be careful to remove it if instance needs to be garbage collected
		public static function addInstanceListener(c:Object, listener:Object):void {
			if (!_staticInstanceListeners[c]) _staticInstanceListeners[c] = new <Object>[];
			if (_staticInstanceListeners[c].indexOf(listener) == -1) _staticInstanceListeners[c].push(listener);
		}
		public static function removeInstanceListener(c:Object, listener:Object):void {
			if (_staticInstanceListeners[c]) UCode.removeVectorItem(_staticInstanceListeners[c], listener);	
		}
		
		
		public static function addInstanceListenerTo(c:Object, listener:Object, evt:String):void {
			if (!_staticInstanceListenersTo[c]) _staticInstanceListenersTo[c] = {};
			if (!_staticInstanceListenersTo[c][evt]) _staticInstanceListenersTo[c][evt] = new <Object>[];
			if (_staticInstanceListenersTo[c][evt].indexOf(listener) == -1) _staticInstanceListenersTo[c][evt].push(listener);
			// Is some listener is already also in the general class listening
			if (_staticInstanceListeners[c]) {
				Debug.error("PippoFlashEventsMan", "Static Listener " + listener + " for class " + c + " is already registered as general listener, I add it to listen for " + evt + " and remove it from general listeners.");
				removeInstanceListener(c, listener);
			}
		}
		public static function removeInstanceListenerTo(c:Object, listener:Object, evt:String):void {
			if (_staticInstanceListenersTo[c] && _staticInstanceListenersTo[c][evt])	{ // Listener exists
				UCode.removeVectorItem(_staticInstanceListenersTo[c][evt], listener);
			}
		}
		
		public static function addInstanceMethodListenerTo(c:Object, evt:String, f:Function):void {
			if (!_staticInstanceListenersToFunc[c]) _staticInstanceListenersToFunc[c] = {};
			if (!_staticInstanceListenersToFunc[c][evt]) _staticInstanceListenersToFunc[c][evt] = new <Function>[];
			if (_staticInstanceListenersToFunc[c][evt].indexOf(f) == -1) _staticInstanceListenersToFunc[c][evt].push(f);
		}
		public static function removeInstanceMethodListenerTo(c:Object, evt:String, f:Function):void {
			if (_staticInstanceListenersToFunc[c] && _staticInstanceListenersToFunc[c][evt])	{ // Listener exists
				UCode.removeVectorItem(_staticInstanceListenersToFunc[c][evt], f);
			}
		}
		/**
		 * Adds an instance that will re-broadcast all events as its own.
		 * @param	c The instance whose events must be re-broadcasted
		 * @param	reBroadcaster The instance who's listeners will receive the events re-broadcasted
		 */
		static public function addInstanceEventsReBroadcaster(c:Object, reBroadcaster:Object):void { // Adds another instance that can re-broadcast events as if they were their own
			if (!_staticInstanceReBroadcasters[c]) _staticInstanceReBroadcasters[c] = new <Object>[];
			if (_staticInstanceReBroadcasters[c].indexOf(reBroadcaster) == -1) _staticInstanceReBroadcasters[c].push(reBroadcaster);
		}
		
		
		
	// Remove all listeners from an instance
		static public function removeAllListeningToInstance(c:Object):void {
			//Debug.debugDebugging(_debugPrefix, "Removing all listeners for instance: " + c);
			disposeInstance(c);
			_staticInstanceListeners[c] = null;
			_staticInstanceListenersTo[c] = null;
			_staticInstanceListenersToFunc[c] = null;
			_staticInstanceReBroadcasters[c] = null;
		}
		
	// Broadcasting events
		public static function broadcastInstanceEvent(c:Object, evt:String, ...rest):void {
			// First its own listeners
			if (_staticInstanceListeners[c]) broadcastIPFGroupEvent(_staticInstanceListeners[c], evt, rest);
			if (_staticInstanceListenersTo[c] && _staticInstanceListenersTo[c][evt]) broadcastIPFGroupEvent(_staticInstanceListenersTo[c][evt], evt, rest);
			if (_staticInstanceListenersToFunc[c] && _staticInstanceListenersToFunc[c][evt]) callMethods(_staticInstanceListenersToFunc[c][evt], rest);
			// Then the listeners who re-broadcast - since I can't reuse ...rest again, I need to relaunch the same flow using the rebroadcaster as clip
			if (_staticInstanceReBroadcasters[c]) { // In order to reuse  "rest", I can only relaunch all the same logic using the reBroadcaster as reference
				const reBroadcaster:Object = _staticInstanceReBroadcasters[c];
				if (_staticInstanceListeners[reBroadcaster]) broadcastIPFGroupEvent(_staticInstanceListeners[reBroadcaster], evt, rest);
				if (_staticInstanceListenersTo[reBroadcaster] && _staticInstanceListenersTo[reBroadcaster][evt]) broadcastIPFGroupEvent(_staticInstanceListenersTo[reBroadcaster][evt], evt, rest);
				if (_staticInstanceListenersToFunc[reBroadcaster] && _staticInstanceListenersToFunc[reBroadcaster][evt]) callMethods(_staticInstanceListenersToFunc[reBroadcaster][evt], rest);
			}
		}
		//public static function broadcastInstanceEventTunnel(c:Object, evt:String, pars:Array=null):void { // This is used when ...rest is already in a parent method
			//if (_staticInstanceListeners[c])				broadcastIPFGroupEvent(_staticInstanceListeners[c], evt, pars);
			//if (_staticInstanceListenersTo[c] && _staticInstanceListenersTo[c][evt]) broadcastIPFGroupEvent(_staticInstanceListenersTo[c][evt], evt, pars);
			//if (_staticInstanceListenersToFunc[c] && _staticInstanceListenersToFunc[c][evt]) callMethods(_staticInstanceListenersToFunc[c][evt], pars);
		//}
	// Memory management - REMEMBER TO CALL THIS WEHN DISPOSING AN INSTANCE
		public static function disposeInstance			(c:Object):void {
			if (_staticInstanceListeners[c])			delete _staticInstanceListeners[c];
			if (_staticInstanceListenersTo[c])			delete _staticInstanceListenersTo[c];
			if (_staticInstanceListenersToFunc[c])		delete _staticInstanceListenersToFunc[c];
			if (_staticInstanceReBroadcasters[c])		delete _staticInstanceReBroadcasters[c];
		}
// STATIC UTY ///////////////////////////////////////////////////////////////////////////////////////
		public static function broadcastIPFGroupEvent	(g:Vector.<Object>, evt:String, pars:Array):void {
			//trace(g);
			for each (_pf in g) {
				//trace(_pf);
				//if (_pf.hasOwnProperty("callPrivateEvent")) {
					//trace("ho private event?????");
					//_pf.callPrivateEvent(evt, pars)
				//}
				//else {
					//trace(_pf);
					//trace("evt");
					callMethodParams(_pf, evt, pars);
				//}
			}
		}
		public static function callMethods				(g:Vector.<Function>, pars:Array):void {
// 			try {
			const intMethod						:Function = PippoFlashEventsMan["callMethodPar"+pars.length];
			for each (var f:Function in g) {
// 				var f							:Function;
				for each (f in g)					intMethod(f, pars);
			}
// 			catch (e:Error) {
// 				Debug.error					("PippoFlashEventsMan", "Error calling callMethods. Pars: " + pars);
// 			}
		}
		// General purpose method used instead of the one in UCode
		public static function callListenerMethodNames	(l:Object, e:Vector.<String>, ...rest):void {
			// Since this is a list of calls with the same parameters, I fist check the length then launch the calls
			var m:String;
			if (rest.length) {
				for each (m in e) {
					if (Object(l).hasOwnProperty(m)) {
						PippoFlashEventsMan["callMethodPar"+rest.length](l[m], rest);
					}
				}
			}
			else {
				for each (m in e) {
					if (Object(l).hasOwnProperty(m)) {
						l[m]					();;
					}
				}
			}
		}
		// General purpose call single method
		public static function callMethodParams			(l:Object, m:String, rest:Array=null):void { // This works as a tunnel for methods that already implement ...rest. par is like ...rest
			// Array is always there, so I can rely on length
			if (Object(l).hasOwnProperty(m)) {
				if (rest)						PippoFlashEventsMan["callMethodPar"+rest.length](l[m], rest);
				else							l[m]();
			}
		}
		public static var callMethod:Function					= callListenerMethodName;
		public static function callListenerMethodName		(l:Object, e:String, ...rest):Boolean {
			if (Object(l).hasOwnProperty(e)) {
				PippoFlashEventsMan["callMethodPar"+rest.length](l[e], rest);
				return true;
			}
			return false;
		}
		private static function callMethodPar0			(m:Function, p:Array=null):void {
			m								();
		}
		private static function callMethodPar1			(m:Function, p:Array):void {
			m								(p[0]);
		}
		private static function callMethodPar2			(m:Function, p:Array):void {
			m								(p[0], p[1]);
		}
		private static function callMethodPar3			(m:Function, p:Array):void {
			m								(p[0], p[1], p[2]);
		}
		private static function callMethodPar4			(m:Function, p:Array):void {
			m								(p[0], p[1], p[2], p[3]);
		}
		private static function callMethodPar5			(m:Function, p:Array):void {
			m								(p[0], p[1], p[2], p[3], p[4]);
		}
		private static function callMethodPar6			(m:Function, p:Array):void {
			m								(p[0], p[1], p[2], p[3], p[4], p[5]);
		}
//  ///////////////////////////////////////////////////////////////////////////////////////
	}
}