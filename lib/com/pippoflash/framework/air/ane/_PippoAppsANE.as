package com.pippoflash.framework.air.ane 
{
	import com.pippoflash.framework._PippoFlashBaseNoDisplay;
	import com.pippoflash.framework.air.UAir;
	import com.pippoflash.utils.Debug;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class _PippoAppsANE extends _PippoFlashBaseNoDisplay 
	{
		
		private var _windowsCompatible:Boolean;
		private var _macCompatible:Boolean;
		private var _iosCompatible:Boolean;
		private var _androidCompatible:Boolean;
		
		

		
		
		
		
		
		
		
		
		
		
		
		
		public function _PippoAppsANE(id:String, cl:Class=null) 
		{
			super(id, cl);
			
		}
		
		
		
		
		
		
		
		// GET SET ///////////////////////////////////////////////////////////////////////////////////////
		public function get windowsCompatible():Boolean 
		{
			return _windowsCompatible;
		}
		
		public function set windowsCompatible(value:Boolean):void 
		{
			_windowsCompatible = value;
		}
		
		public function get macCompatible():Boolean 
		{
			return _macCompatible;
		}
		
		public function set macCompatible(value:Boolean):void 
		{
			_macCompatible = value;
		}
		
		public function get iosCompatible():Boolean 
		{
			return _iosCompatible;
		}
		
		public function set iosCompatible(value:Boolean):void 
		{
			_iosCompatible = value;
		}
		
		public function get androidCompatible():Boolean 
		{
			return _androidCompatible;
		}
		
		public function set androidCompatible(value:Boolean):void 
		{
			_androidCompatible = value;
		}
		
		
		
		//protected function init():Boolean {
			///* OVERRIDE */
		//}
		
	}

}