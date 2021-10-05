/* SWFAddMan - Provides base functionalities for applications */
/* Usage

override initOnStage();  // Performs initialization when stage is available - FACULTATIVE

TO START THE APPLICATION
override init(); // Initializes the following frame after stage is available

*/

package com.pippoflash.framework {
	import com.adobe.serialization.json.JSON;
	import com.pippoflash.framework.Config;
	import com.pippoflash.framework.prompt._Prompt;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.ULoader;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	// PROJECT IMPORT ////////////////////////////
	import com.asual.swfaddress.*;
	
	public dynamic class SWFAddMan extends _PippoFlashBase {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC - DEBUG SWITCHES
		// STATIC CONSTANTS
		public static var _dontProcessList				:Array = ["/"]; // List of strings that will not be processed
		// SYSTEM
		// USER VARIABLES
		// HTML VARIABLES - FLASHVARS HAVE TO BE PUBLIC
		// REFERENCES
		// STAGE INSTANCES
		// REFERENCE LISTS
		// MARKERS
		// DATA HOLDERS
		// STATIC UTY
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function SWFAddMan					():void {
			super							("SWFAddMan");
			SWFAddress.addEventListener			(SWFAddressEvent.INIT, onInit);
			SWFAddress.addEventListener			(SWFAddressEvent.CHANGE, onChange);
			SWFAddress.addEventListener			(SWFAddressEvent.EXTERNAL_CHANGE, onExternalChange);
			SWFAddress.addEventListener			(SWFAddressEvent.INTERNAL_CHANGE, onInternalChange);
		}
// CONFIG LOADER ///////////////////////////////////////////////////////////////////////////////////////
// PROMPTS MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
// STARTUP ///////////////////////////////////////////////////////////////////////////////////////
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function setValue					(s:String):void {
			SWFAddress.setValue					(processSetString(s));
		}
		public function setValueStraight				(s:String):void {
			SWFAddress.setValue					(s);
		}
		public function setTitle						(s:String):void {
			SWFAddress.setTitle					(s);
		}
// UTY //////////////////////////////////////////////////////////////////////////////////
		// THIS CAN BE CUSTOMIZED PROJECT BY PROJECT
		private function processSetString				(s:String):String { // Process the received string before setting it as a deep link
			return							_dontProcessList.indexOf(s) < 0 ? s.substr(0,s.length-4) : s; // Removes .xml
		}
		private function processGetString				(s:String):String { // Process the received eeplink before broadcasting it
			return							_dontProcessList.indexOf(s) < 0 ? s + ".xml" : s; // Adds .xml
		}
// LOADER /////////////////////////////////////////////////////////////////////////////////////
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		public function onInit						(e:SWFAddressEvent):void {
// 			trace("onInit",e);
			broadcastEvent						("onSWFAddInit", processGetString(e.value));
		}
		public function onChange					(e:SWFAddressEvent):void {
// 			trace("onChange",e);
			broadcastEvent						("onSWFAddChange", processGetString(e.value));
		}
		public function onExternalChange				(e:SWFAddressEvent):void {
// 			trace("onExternalChange",e);
			broadcastEvent						("onSWFAddExternalChange", processGetString(e.value));
		}
		public function onInternalChange				(e:SWFAddressEvent):void {
// 			trace("onInternalChange",e);
			broadcastEvent						("onSWFAddInternalChange", processGetString(e.value));
		}
// DEBUG LISTENERS  ///////////////////////////////////////////////////////////////////////////////////////
	}
}