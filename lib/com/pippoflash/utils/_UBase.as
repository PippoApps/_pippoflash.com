/* _UBase - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Abstract class to be extended for all Ufì framework utilities.

*/

package com.pippoflash.utils {
	import flash.geom.*; import flash.display.*; import flash.text.*; import flash.net.*; import flash.events.*; import flash.utils.*; import flash.external.*; import	flash.system.*; // Flash

	
	public class _UBase {
		// DEBUG SWITCHES
		// CINSTANTS
		// MODIFIABLE OCNSTANTS - can be modified by direct assignement
		// UTY
		// DATA HOLDERS
		// MARKERS
		// REFERENCES
		protected static var _mainApp:MovieClip; // Reference to mainapp
// FRAMEWORK ///////////////////////////////////////////////////////////////////////////////////////
		public static function setMainApp(c:MovieClip):void {
			_mainApp = c;
		}
// INIT ///////////////////////////////////////////////////////////////////////////////////////
// SETUP ///////////////////////////////////////////////////////////////////////////////////////
// CHECKS ///////////////////////////////////////////////////////////////////////////////////////
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