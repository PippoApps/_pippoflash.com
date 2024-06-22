package com.pippoflash.framework.air.ane.distriqt 
{
	import com.pippoflash.framework.air.ane._PippoAppsANE;
	import com.distriqt.extension.core.Core;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.USystem;
	import com.pippoflash.framework.air.UAir;
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class _DistriqtAne extends _PippoAppsANE 
	{
		static private var _debugPrefix:String = "DistriqtAneCore";
		static private var _initializedCore:Boolean;
		
		static public function initCore():Boolean {
			if (_initializedCore) return true;
			_initializedCore = true;
			Debug.debug(_debugPrefix, "Initializing Distriqt Core ANE ver " + Core.VERSION);
			if (USystem.isWin() || USystem.isMac()) {
				Debug.debug(_debugPrefix, "Initializing desktop Core.");
				Core.init();
				return true;
			} else {
				if (!Core.isSupported) {
					Debug.error(_debugPrefix, "Distriq Core not supported.");
					return false;
				}
			}
			Debug.debug(_debugPrefix, "Initializing device Core.");
			Core.init();
			return true;
		}
		static public function get initialized():Boolean {
			return _initializedCore;
		}
		//static protected function activateApplicationWakeListeners():void {
			//UAir.addSleepListener(onPermissionRequestSleep);
			//UAir.addWakeListener(onPermissionRequestAwake);
		//}
		//static protected function deActivateApplicationWakeListeners():void {
			//UAir.removeSleepListenerSleepListener(onPermissionRequestSleep);
			//UAir.removeWakeListenerWakeListener(onPermissionRequestAwake);
		//}
		//static protected function onPermissionRequestSleep(e:*):void {
			//Debug.debug(_debugPrefix, "Application went to sleep.");
		//}
		//static protected function onPermissionRequestAwake(e:*):void {
			//Debug.debug(_debugPrefix, "Application woke up.");
		//}
		
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function _DistriqtAne(id:String, cl:Class=null) 
		{
			super(id, cl);
			
		}
		
		
		
		
		
	}

}