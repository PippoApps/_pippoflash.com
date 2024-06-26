/* _PippoFlashBaseNoDisplayUMem - (c) Filippo Gregoretti - PippoFlash.com */
/* This class is the base for ALL (non-static) NON-SINGLETON classes, visual or non-visual, that have to be instantiated several times, and are managed by UMem 
This one doesn't have any broadcasting mechanism since its possibly used for a lot of items.
*/


package com.pippoflash.framework.plugin {
	// IMPORTS ///////////////////////////////////////////////////////////////////////////
	import com.pippoflash.framework.interfaces.IPippoFlashEventDispatcher;
	import com.pippoflash.framework.PippoFlashEventsMan;
	// DECLARATION /////////////////////////////////////////////////////////////////////////////
	public dynamic class _PippoFlashBaseNoDisplayUMemDispatcherPlugin extends _PippoFlashBaseNoDisplayUMemPlugin implements IPippoFlashEventDispatcher {
		// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function _PippoFlashBaseNoDisplayUMemDispatcherPlugin(id:String="_PippoFlashBaseNoDisplayUMemDispatcherPlugin") {
			super(id);
		}
		// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function addListener(l:Object):void {
			PippoFlashEventsMan.addInstanceListener(this, l); // Listens to all events
		}
		public function addListenerTo(l:Object, methodName:String):void {
			PippoFlashEventsMan.addInstanceListenerTo(this, l, methodName); // Listens to all events
		}
		public function addMethodListenerTo(methodName:String, method:Function):void {
			PippoFlashEventsMan.addInstanceMethodListenerTo(this, methodName, method); // Listens to all events
		}
		public function removeListener(l:Object):void {
			PippoFlashEventsMan.removeInstanceListener(this, l); // Listens to all events
		}
		public function removeListenerTo(l:Object, methodName:String):void {
			PippoFlashEventsMan.removeInstanceListenerTo(this, l, methodName); // Listens to all events
		}
		public function removeMethodListenerTo(methodName:String, method:Function):void {
			PippoFlashEventsMan.removeInstanceMethodListenerTo(this, methodName, method); // Listens to all events
		}
		public function broadcastEvent(methodName:String, ...rest):void {
			PippoFlashEventsMan.broadcastInstanceEvent(this, methodName, rest);
		}
		public function callPrivateEvent(evt:String, pars:Array):Boolean {
			return false;
		}
		// MEMORY MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		// Release is used to release any rendering and be ready to be re-rendered. But not to be store din UMem.
		public override function release():void {
			super.release();
			PippoFlashEventsMan.disposeInstance(this);
		}
		// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}