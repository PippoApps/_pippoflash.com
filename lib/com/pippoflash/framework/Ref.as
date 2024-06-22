/* Ref - ver 0.1 - Filippo Gregoretti - www.pippoflash.com
Manages configuration files
*/

package com.pippoflash.framework {


	// Import for system
	import com.pippoflash.utils.UCode;
	import com.pippoflash.utils.Debug;
	// Import for references
	public class Ref {
		// This is the class which both _PippoFlashBase and _PippoFlashBaseUMeme reference with _ref
		// This is a dynamic class, so whatever variable can be assigned
		// But if in this class I setup static typed variables, using references from _ref will trigger also compilation errors
		// This has to be set in initialization of MainApp with:
		// _PippoflashBase._ref = _PippoFlashReferences; 
		// _PippoflashBaseUMem._ref = _PippoFlashReferences; 
		// SYSTEM ///////////////////////////////////////////////////////////////////////////////////////
		protected var _debugPrefix				:String = "Reference";
// 		private var _listeners						:Array = [];
// 		private var _listenersForVars				:Object = {};
// 		private var _j							:*;
// 		private var _s							:String;
		// REFERENCES /////////////////////////////////////////////////////////////
		public var _config						:Config;
		// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function Ref						():void {
		}
		public function setReference				(varName:String, ref:*):void {
			this[varName]						= ref; // Set reference
			Debug.debug						(_debugPrefix, "Setting reference",varName,"to",ref);
			onReferenceSet						(varName, ref);
		}
		public function setReferences				(refs:Object):void { // {key:Object, key:Object}
			for (var ref:String in refs)			setReference(ref, refs[ref]);
		}
		public function callMethod					(prop:String, method:String, ...rest):void {
			if (this.hasOwnProperty(prop)) {
				UCode.callMethodArray			(this[prop], method, rest);
			}
			else {
				Debug.error					("Ref", "Property",prop,"not found. Cannot call method",method,rest);
			}
		}
		public var addReference					:Function = setReference;
		public var add							:Function = setReference;
		public var set							:Function = setReference;
		// OVERRIDABLE METHODS ///////////////////////////////////////////////////////////////////////////////////////
		protected function onReferenceSet			(refName:String, ref:*):void {
			// This can be overridden by project references in order to perform specifica actions
		}
	}
}