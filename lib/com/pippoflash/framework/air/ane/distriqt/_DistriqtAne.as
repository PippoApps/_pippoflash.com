package com.pippoflash.framework.air.ane.distriqt 
{
	import com.pippoflash.framework.air.ane._PippoAppsANE;
	import com.distriqt.extension.core.Core;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.USystem;
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
		
		// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function _DistriqtAne(id:String, cl:Class=null) 
		{
			super(id, cl);
			
		}
		
		
		
		
		
	}

}