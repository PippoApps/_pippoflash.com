/* UAirFake - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Needed to fool compiler.

*/
package com.pippoflash.framework.air {
import com.pippoflash.framework._Application;

// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import com.pippoflash.utils.*; // PippoFlash
	import flash.display.*; import flash.events.*; import flash.media.*; import flash.net.*; import flash.system.*; import flash.text.*; import flash.utils.*; import flash.geom.*; import flash.external.*;// FLash
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public class UAirFake {
		public static var _debugPrefix				:String = "UAirFake";
	// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public static function init					(j:*=null, newSize:Rectangle=null):void {
			// WARNING
			Debug.debug						(_debugPrefix, "--------------------------------------------------------------------");
			Debug.debug						(_debugPrefix, "||| WARNING ||| Using UAirFake instead of UAir!!!! ---------------|||");
			Debug.debug						(_debugPrefix, "---------------------------------------------------------------------");
		}
	// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		public static function addNativewindowOptions	(id:String, options:Object):void {
		}
		public static function getId					():String {
			return							_Application.instance.applicationId;
		}
		public static function getOptimalScale():Number {
			return UGlobal.getContentScale();
		}
		static public function getOptimalScaleRelativeToUGlobal():Number {   
			return UGlobal.getContentScale();
		}
		public static function addSleepListener			(f:Function):void {
		}
		public static function addWakeListener			(f:Function):void {
		}
	// WINDOWS ///////////////////////////////////////////////////////////////////////////////////////	
		public static function getNativeWindow(pars:Object=null, options:String="default", listener:*=null):* {
			return null;
		}
		public static function getHtmlWindow(pars:Object=null, options:String="default", listener:*=null):* { // returns a window with on depth 0 has as child and HTMLLoader object
			return null;
		}
		public static function onHtmlEvent(e:Event):void {
		}
		
	}
}
