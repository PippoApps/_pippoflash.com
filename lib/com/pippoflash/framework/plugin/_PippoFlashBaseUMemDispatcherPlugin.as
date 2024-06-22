/* _PippoFlashBaseUMemDispatcher - (c) Filippo Gregoretti - PippoFlash.com */
/* This class is the base for ALL (non-static) NON-SINGLETON classes, visual or non-visual, that have to be instantiated several times, and are managed by UMem 
This one doesn't have any broadcasting mechanism since its possibly used for a lot of items.
*/


package com.pippoflash.framework.plugin {
	// IMPORTS ///////////////////////////////////////////////////////////////////////////
	import com.pippoflash.framework.interfaces.IPippoFlashEventDispatcher;
	import com.pippoflash.framework.PippoFlashEventsMan;
	//import com.pippoflash.framework.interfaces.IPippoFlashEventListener;
	import com.pippoflash.utils.UMethod;
	// DECLARATION /////////////////////////////////////////////////////////////////////////////
	public dynamic class _PippoFlashBaseUMemDispatcherPlugin extends _PippoFlashBaseUMemPlugin implements IPippoFlashEventDispatcher {
		// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function _PippoFlashBaseUMemDispatcherPlugin(id:String="_PippoFlashBaseUMemDispatcherPlugin") {
			super(id);
		}
		// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function addListener(l:*):void {
			PippoFlashEventsMan.addInstanceListener(this, l); // Listens to all events
		}
		public function addListenerTo(l:*, methodName:String):void {
			PippoFlashEventsMan.addInstanceListenerTo(this, l, methodName); // Listens to all events
		}
		public function addMethodListenerTo(methodName:String, method:Function):void {
			PippoFlashEventsMan.addInstanceMethodListenerTo(this, methodName, method); // Listens to all events
		}
		public function removeListener(l:*):void {
			PippoFlashEventsMan.removeInstanceListener(this, l); // Listens to all events
		}
		public function removeListenerTo(l:*, methodName:String):void {
			PippoFlashEventsMan.removeInstanceListenerTo(this, l, methodName); // Listens to all events
		}
		public function removeMethodListenerTo(methodName:String, method:Function):void {
			PippoFlashEventsMan.removeInstanceMethodListenerTo(this, methodName, method); // Listens to all events
		}
		public function broadcastEvent(methodName:String, ...rest):void {
			PippoFlashEventsMan.broadcastInstanceEventTunnel(this, methodName, rest);
		}
		public override function callPrivateEvent(evt:String, pars:Array):Boolean {
			UMethod.callMethodNameTunnel(this, evt, pars);
			return Boolean(this[evt]);
		}
		// MEMORY MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		// Cleanup is used to release any rendering and bring this to a natural status. It can also be collected by UMem. 
		// Release does not remove events listeners
		public override function cleanup():void {
			super.cleanup();
			PippoFlashEventsMan.disposeInstance(this);
		}
		// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}