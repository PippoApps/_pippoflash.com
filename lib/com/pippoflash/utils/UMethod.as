/* UMethod - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
Utility class to call methods in sequence according to number of arguments. Works with both vectors and arrays.
*/


package com.pippoflash.utils {

	import									flash.display.*;
	import									flash.events.*;
	import									flash.utils.*;

	
	public class UMethod {
		public static const _verbose					:Boolean = false;
		public static const _debugPrefix				:String = "UMethod";
		// Constants
		private static const MAX_ARGUMENTS			:uint = 8; // Maximum number of arguments accepted
		// Methods holders
		private static var _methods					:Vector.<Function> = new <Function>[method0, method1, method2, method3, method4, method5, method6, method7, method8];
// INIT ////////////////////////////////////////////////////////////////////////////
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		// Core of the system, calls a method in a target object according to number of parameters
		public static function callMethodName(o:Object, fn:String, ...rest):* {
			if (o.hasOwnProperty(fn)) return _methods[rest.length](o[fn], rest);
		}
		public static function callMethod(f:Function, ...rest):void {
			_methods[rest.length](f, rest);
		}
		public static function callArrayMethodName(a:Array, fn:String, ...rest):void {
			var i:uint = rest.length;
			for each (var o:Object in a) if (o.hasOwnProperty(fn)) _methods[i](o[fn], rest);
		}
		public static function callVectorMethodName(a:Vector.<*>, fn:String, ...rest):void {
			var i:uint = rest.length;
			for each (var o:Object in a) {
				if (o.hasOwnProperty(fn)) _methods[i](o[fn], rest);
				else Debug.error(_debugPrefix, "Cannot find method "+fn+" in "+o);
			}
		}
	// TUNNELING METHODS (...rest has already been interpretated - legacy from UCode)
		public static function callVectorMethodNameTunnel(a:Vector.<*>, fn:String, pars:Array):void {
			const i:uint = pars.length;
			for each (var o:Object in a) if (o && o.hasOwnProperty(fn)) _methods[i](o[fn], pars);
		}
		public static function callArrayMethodNameTunnel	(a:Array, fn:String, pars:Array):void {
			var i								:uint = pars.length;
			for each (var o:Object in a)			if (o.hasOwnProperty(fn)) _methods[i](o[fn], pars);
		}
		public static function callMethodNameTunnel		(o:Object, fn:String, pars:Array):void { /* THIS IS CALLED AS A TUNNEL FROM A METHOD THAT ALREADY USES ...rest */
			// trace(o, fn, pars);
			if (o.hasOwnProperty(fn))				_methods[pars.length](o[fn], pars);
		}
		public static function callMethodTunnel			(f:Function, pars:Array=null):void {
			_methods[pars.length]				(f, pars);
		}
		
		
		public static function callMethodNameWithParamsArray(o:Object, fn:String, pars:Array):* {
			if (o.hasOwnProperty(fn)) return _methods[pars.length](o[fn], pars);
			else Debug.error(_debugPrefix, "Object does not have requested method:",o,fn);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private static function method0				(f:Function, p:Array=null):void {
			f								();
		}
		private static function method1				(f:Function, p:Array):void {
			f								(p[0]);
		}
		private static function method2				(f:Function, p:Array):void {
			f								(p[0], p[1]);
		}
		private static function method3				(f:Function, p:Array):void {
			f								(p[0], p[1], p[2]);
		}
		private static function method4				(f:Function, p:Array):void {
			f								(p[0], p[1], p[2], p[3]);
		}
		private static function method5				(f:Function, p:Array):void {
			f								(p[0], p[1], p[2], p[3], p[4]);
		}
		private static function method6				(f:Function, p:Array):void {
			f								(p[0], p[1], p[2], p[3], p[4], p[5]);
		}
		private static function method7				(f:Function, p:Array):void {
			f								(p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
		}
		private static function method8				(f:Function, p:Array):void {
			f								(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]);
		}
		
		
		
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