/* UCode - ver 0.15 - Filippo Gregoretti - www.pippoflash.com
0.15 - getPathFromString(origin:DisplayObject, path:String); // Converts a string "parent.parent.clip3" into a reference.

*/
// PACKAGE ///////////////////////////////////////////////////////////////////////////////////////
package com.pippoflash.utils {
// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import flash.geom.*; import flash.display.*; import flash.text.*; import flash.net.*; import flash.events.*; import flash.utils.*; import flash.external.*; import	flash.system.*; // Flash
	import com.pippoflash.utils.*; // PippoFlash
// CLASS ///////////////////////////////////////////////////////////////////////////////////////	
	public class UCode {
// SWITCHES ///////////////////////////////////////////////////////////////////////
		private static const _verbose				:Boolean = false;
// UTILITIES ////////////////////////////////////////////////////////////////////////////
		public static var _a						:Array;
		public static var _s						:String;
		public static var _i						:int;
		public static var _b						:Boolean;
		public static var _j;						// Jolly variable, can be anything
		public static var _n						:Number;
		public static var _clip						:MovieClip;
		public static var _counter					:int;
		public static var _debugPrefix				:String = "UCode";
// DUMMIES //////////////////////////////////////////////////////////////////////////////
		public static var _dummyClip					:MovieClip = new MovieClip();
		public static var _dummyTextField				:TextField = new TextField();
		public static var _dummyObject				:Object = new Object();
		public static var _dummyFunction				:Function = dummyFunction;
// GENERAL //////////////////////////////////////////////////////////////////////////////
		public static function dummyFunction			(... rest):Function {
			return							dummyFunction; // In case I do the typical error to assign with () in the end
		}
// 		public static var _debugConsole				= _dummyTextField; // Stores the address of a debug console to use with appendText();
// 		public static function debug					(... rest) {
// 			windowDebug						(rest.join(" "));
// 		}
// 		public static function windowDebug			(t:String) {
// 			Debug.autoDebug					(t);
// 		}
// 		public static function setupConsole			(t) {
// 			// This sets up a textfield to use as debug
// 			Debug.setupConsole					(t);
// 		}
// PIPPOFLASH FRAMEWORK ///////////////////////////////////////////////////////////////////////////////////////
		public static var _pippoFlashIdVarName			:String = "___PippoFlash___IdVarName";
		public static function getPippoFlashId			(o):String {
			if (!o.hasOwnProperty(_pippoFlashIdVarName)) o[_pippoFlashIdVarName] = createPippoFlashId();
			return 							o[_pippoFlashIdVarName];
		}
		private static function createPippoFlashId		():String {
			return							"PippoFlashId_" + UText.getRandomString(16);
		}
		public static function isPippoFlashButton			(c):Boolean {
			return							isPippoFlashComponent(c) && c._componentId == "PippoFlashButton";
		}
		public static function isComponentType			(c:MovieClip, s:String):Boolean {
			return							isPippoFlashComponent(c) && c._componentId == s;
		}
		public static function isPippoFlashComponent		(c):Boolean {
			return							c.hasOwnProperty("_componentId");
		}
		public static function getFamilyId(c):String { // Returns the family ID of PippoFlash framework object.
			if (c.hasOwnProperty("_debugPrefix")) return c._debugPrefix;
			else if (c.hasOwnProperty("getFamilyId")) return c.getFamilyId();
			else return "UCode.getFamilyId() Cannot find an ID in",c;
		}
	// SIZE /////////////////
		public static function getWidth				(c:*):Number {
			return							c.hasOwnProperty("_w") ? c._w : c.width;
		}
		public static function getHeight				(c:*):Number {
			return							c.hasOwnProperty("_h") ? c._h : c.height;
		}
// SET TEXT BY TYPE ////////////////////////////////////////////////////////////////////////
		public static function setTextByType			(e, s:String):void { // this one stes text according to type of element
			if (!s)							s = "";
			if (e is TextField)					e.text = s;
			else if (isPippoFlashComponent(e)) {
				if (isPippoFlashButton(e))			e.setText(s);
				else if (isComponentType(e, "SuperTextField")) e.setText(s);
			}
			else {
				try {
					e._txt.text					= s;
				}
				catch (e) {
					Debug.debug				(_debugPrefix + " WARNING", "Cannot set text for",e);
				}
			}
		}
// FLASH VARS //////////////////////////////////////////////////////////////////////
		public static function getFlashVar(s:String) {
			return UGlobal.stage.loaderInfo.parameters[s];
		}
		public static function flashVars():Object {
			return UGlobal.stage.loaderInfo.parameters;
		}
		public static function setListFlashVars(d:Object, pars) {
			if (pars is String) _a = pars.split(",");
			else _a = pars;
			for (var i:uint=0; i<_a.length; i++) setFlashVar(d, _a[i]);
		}
		public static function setFlashVar(d:Object, prop:String) {
			Debug.debug(_debugPrefix, "Setting FlashVar",prop,"=",exists(getFlashVar(prop)) ? getFlashVar(prop) : (d[prop] + " (is default value, no flashvar defined)"));
			if (d.hasOwnProperty(prop) && exists(getFlashVar(prop))) d[prop] = getFlashVar(prop);
		}
// SET PARAMETERS & GET PROPERTIES ///////////////////////////////////////////////////////////////////
		public static function setParameters(d:Object, s:Object) {
			if (!exists(d) || !exists(s)) return;
			// Sets parameters to one object from another - ONLY IF VARIABLES ARE DEFINED
			// d - destination, s - source
			for (var i in s) {
				if (d.hasOwnProperty(i)) d[i] = s[i];
			}
			return d;
		}
		public static function setParametersForced(d:Object, s:Object) {
			if (!exists(d) || !exists(s)) return;
			// Sets parameters to one object from another - ALWAYS
			for (var i in s) d[i] = s[i];
		}
		public static function setGroupParameters(a:Array, o:Object) {
			// Sets parameters for a group of objects
			for (var i:uint=0; i<a.length; i++) setParameters(a[i], o);
		}
		public static function setParametersList(d:Object, s:Object, l:Array) {
			// Sets parameters to one object from another, only parameters listed in an array ["_x","_y",ecc...]
			// d - destination, s - source
			for (var i in l) d[l[i]] = s[l[i]];
			return d;
		}
		public static function setDefaults(d:Object, s:Object) {
			// Sets a parameter ONLY if it is undefined
			for (var i in s) {
				if (d[i] is Number && isNaN(d[i])) d[i] = s[i]; // If in a class is Number but not defined, evaluates as NaN, so it is not null either undefined
				else if (!exists(d[i])) d[i] = s[i];
			}
			return d;
		}
		public static function setDefaultsList(d:Object, s:Object, l:Array) {
			// Sets a parameter from a list ONLY if it is undefined
			for (var i in l) if (d[l[i]] == undefined) d[l[i]] = s[l[i]];
			return d;
		}
		public static function setListParameters(obs:Array, par:Object) {
			for (var i:Number=0; i<obs.length; i++) setParameters(obs[i], par);
		}
		public static function getBestMatchingProperty	(props:Object, id:String):* { // Retrieves the best matching properties in a hash.
			// It looks for an id in a hash, starting from full string, and then removing a character at the end step by step
			var result							:*;
			while (!result && id.length) {
				result							= props[id];
				id							= id.substr(0, id.length-1);
				
			}
			return							result;
		}
		public static function disposeObject(o:Object):void { // Simply loops in Object properties and sets everything to null
			for (var s:String in o) o[s] = null;
		}
// NAVIGATION //////////////////////////////////////////////////////////////////////////
		public static function processLinkNode			(xml:*, pars:Object=null) {
			trace(xml.toXMLString());
			if (!(xml is XML) && !(xml is XMLList)) {
				Debug.debug					(_debugPrefix, "Link node:",xml,"is not valid - processLinkNode() aborted.");
				return;
			}
			if (xml is XMLList)					xml = xml.children()[0];
			Debug.debug						(_debugPrefix, "Processing link node:",xml.toXMLString());
			// Check if its a JS command
			if (xml.@type == "javascript") {
				// <REGISTER url="http://www.pippolfash.com" type="javascript" func="jsRegister" params="param1,param2,param3" />
				var parsList					:Array = new Array();
				if (UCode.exists(xml.@params))		parsList = xml.@params.split(",");
				callExternalInterface				(xml.@func, parsList);
			}
			// Otherwise follow link
			else {
				var targetUrl					:String = UXml.hasFullAttribute(xml, "url") ? xml.@url : xml; // URL can be in url attribute or in node content
				Debug.debug					(_debugPrefix, "Going to url:",targetUrl);
				navigateToURL					(new URLRequest(UText.insertParams((isTrue(xml.@escaped) ? unescape(targetUrl) : targetUrl), pars)), xml.@target ? xml.@target : "_blank");
			}
		}
		public static function getBlankUrl(s:String, tar:String="_blank") {
			navigateToURL(new URLRequest(s), tar); 
		}
// EXTERNALINTERFACE ///////////////////////////////////////////////////////////////////////////////////////
		public static function callExternalInterface		(callName:String, ...parsList):void {
			Debug.debug						(_debugPrefix, "ExternalInterface.call(\""+callName+"\""+(parsList.length ? ", "+parsList.join(",") : "")+");");
			if (!ExternalInterface.available) { // ExternalInterface is NOT availale
				Debug.error					(_debugPrefix, "ERROR - ExternalInterface not available.");
				return;
			}
			if (parsList.length == 0)				ExternalInterface.call(callName);
			else if (parsList.length == 1)			ExternalInterface.call(callName, parsList[0]);
			else if (parsList.length == 2)			ExternalInterface.call(callName, parsList[0], parsList[1]);
			else if (parsList.length == 3)			ExternalInterface.call(callName, parsList[0], parsList[1], parsList[2]);
			else if (parsList.length == 4)			ExternalInterface.call(callName, parsList[0], parsList[1], parsList[2], parsList[3]);
		}
		public static function addExternalInterfaceCall		(callName:String, callBack:Function):void {
			if (!ExternalInterface.available) { // ExternalInterface is NOT availale
				Debug.error					(_debugPrefix, "ERROR - ExternalInterface not available. Can't add:",callName);
				return;
			}
			ExternalInterface.addCallback			(callName, callBack);
		}
// OOP - CLASSES - INSTANCES ///////////////////////////////////////////////////////////////////////////////
		public static var getClassInstanceByName		:Function = getInstance;
		public static function getInstance			(n:String, par:Object=null):* {
			var c								:Class = Class(getDefinitionByName(n));
			return							par == null ? new c() : new c(par);
		}
		public static function getInstanceParams			(n:String, ...rest):* {
			var c								:Class = Class(getDefinitionByName(n));
			if (rest.length) {
				if (rest.length == 1)				return new c(rest[0]);
				else if (rest.length == 2)			return new c(rest[0], rest[1]);
				else if (rest.length == 3)			return new c(rest[0], rest[1], rest[2]);
				else {
					if (rest.length > 4) 			Debug.error(_debugPrefix, "ERROR - "+n+"cannot be instantiated, max 4 params supported! Returning it with 4 params...");
					return 					new c(rest[0], rest[1], rest[2], rest[4]);
				}
			}
			return							new c();
		}
		public static function getClassFromInstance		(obj:*):Class {
			return							Object(obj).constructor as Class;
		}
		public static function getClassFromString	(n:String):Class {
			// String must be full reference: slides.package.Class;  NOT just Class;
			// getDefinitionByName(n) if class is not defined throws an error, cannot be checked. Therefore check can only be done with try/catch
			try {
				return						Class(getDefinitionByName(n));
			} catch (e) {
				Debug.error					(_debugPrefix, "Cannot find class: " + n);
			}
			return							null;
		}
// METHODS AND BROADCASTING ///////////////////////////////////////////////////////////////////////////////////////
	/* Headaches of method calling:
		Methods can be called with 
			- ...rest (that means 0 length if array is present), 
			- with an array=null, that means array can be or not be there, 
			- or with param:*=null, that means a single param 
		When there is anything =null I have to check before calling, or it will receive a ...rest with [null] therefore counting to 1
		Methods here have been named and renamed in time causing headaches. Therefore I will only use a few methods and legacy pointers.
		
	*/
	// Method with params list or with no params
		public static function callMethodParams			(f:Function, pars:Array=null):* {
			return 							UMethod.callMethodTunnel(f, pars ? pars : []);
		}
		public static var callMethodArray				:Function = callMethodNameParams;
		public static var broadcastEvent				:Function = callMethodNameParams;
		public static function callMethodNameParams		(o:Object, fn:String, pars:Array=null):* {
			return 							UMethod.callMethodNameTunnel(o, fn, pars ? pars : []);
		}
	// Method list with params or not
		public static function callArrayMethodNameParams	(a:Array, fn:String, pars:Array=null):void {
			UMethod.callArrayMethodNameTunnel		(a, fn, pars ? pars : []);
		}
		public static function callVectorMethodNameParams	(v:Vector.<*>, fn:String, pars:Array=null):void {
			UMethod.callVectorMethodNameTunnel		(v, fn, pars ? pars : []);
		}
		public static function callMethodListVector		(v:Vector.<*>, fn:String, ...rest):void {
			UMethod.callVectorMethodNameTunnel		(v, fn, rest);
		}
	// Single method with ...rest
		public static var callMethod:Function = callMethodName;
		public static var callMethodAlertFullParams:Function = callMethodName;
		public static var callMethodAlert:Function = callMethodName;
		public static var callMethodSilent:Function = callMethodName;
		public static var broadcastStandardEvent:Function = callMethodName;
		public static function callMethodName(o:Object, fn:String, ...rest):* {
			UMethod.callMethodNameTunnel(o, fn, rest);
		}
	// Method list with ...rest
		public static var callFunctionArray = callFunctionParams;
		public static function callFunctionParams(f:Function, pars:Array=null):void {
			if (pars) UMethod.callMethodTunnel(f, pars);
		}
		public static var callMethodList:Function = callArrayMethodName;
		public static var broadcastEventList:Function = callArrayMethodName;
		public static function callArrayMethodName(a:Array, fn:String, ...rest):void {
			UMethod.callArrayMethodNameTunnel(a, fn, rest);
		}
	// LEGACY METHOD - with single parameter
		public static function callGroupMethod(a:Array, fn:String, param:*=null) {
			if (param) UMethod.callArrayMethodName(a, fn, param);
			else UMethod.callArrayMethodName(a, fn);
		}
	// Conversion of methods
		static public function convertMethodString(s:String):Function { // converts a PippoFlash String method: i.e..: "MainApp.isDebug", "PluginManager.changeRoom" in a ethod
			// s gets a full qualified static class path (i.e. com.pippoflash.utils.USYstem, or a pippoflash singleton id i.e. to reach an instance "MainApp");
			_a = s.split(".");
			if (_a.length < 2) {
				return Debug.error(_debugPrefix, "convertMethodString() fail. Cannot convert " + s);
			}
			var methodName:String = _a.pop(); // Remove last element and use it as method name
			var className:String = _a.join(".");
			var instance:Object = UGlobal.mainApp.getInstance(className);
			// Try to get a class directly for a static method if instance is not found
			if (!instance) {
				instance = getClassFromString(className);
			}
			if (!instance) return Debug.error(_debugPrefix, "convertMethodString() fail. Cannot find instance or class " + className);
			var f:Function;
			if (instance.hasOwnProperty(methodName)) f = instance[methodName];
			if (!f) {
				Debug.error(_debugPrefix, "convertMethodString() fail. Cannot find method " + s);
				return _dummyFunction;
			}
			return f;
		}
// DATA ANALISYS /////////////////////////////////////////////////////////////////////////////////
		public static function exists(o):Boolean {
			if (o == undefined || o == null) return false;
			else if (o is String) return o != "";
			else if (o is MovieClip) return o != _dummyClip;
			else return true;
		}
		public static function isNull(o):Boolean {
			if (o == undefined || o == null) return true;
			else if (o is String) return o != "";
			else if (o is Number || o is uint || o is int) return !isNaN(o);
			else {
				Debug.debug(_debugPrefix, "WARNING!!! isNull cannot find type for: " + o + ", and will return FALSE");
				return false;
			}
		}
		public static function isNothing(v:*):Boolean { // Any variable, it checks that is NOTHING. If a string is "" is SOMETHING.
			return v == null || v == undefined || isNaN(v);
		}
		/**
		 * Analyzes anything that arrives, trying to guess whether is true or false. If regular false is not found, becomes a string (f, false, 0, "") all return false, else true.
		 * @param	s
		 * @return
		 */
		public static function isTrue(s:*):Boolean {
			if (s == null || s == undefined || s == false || s == 0) return false;
			else {
				const b:String = String(s).toLowerCase();
				if (b == "0" || b == "" || b == "false" || b == "f") return false;
			}
			return true;
			//if (s is String) {
				//var ss:String = s.toLowerCase();
				//if (ss == "false" || ss == "0" || ss == "") return false;
			//}
			//else if (s == null || s == undefined || s == false || s == 0) return false;
			//return true;
		}
		public static function isObject(o:*):Boolean {
			return String(o) == "[object Object]";
		}
		public static function existsFunction(f:Function):Boolean {
			return f != dummyFunction && !isNothing(f);
		}
// ARRAY //////////////////////////////////////////////////////////////////////////////////////
		public static function getArrayRandom(a:Array):* {
			return a[Math.floor(Math.random()*a.length)];
		}
		public static function removeArrayRandom(a:Array):* {
			return a.splice(Math.floor(Math.random()*a.length), 1)[0];
		}
		public static function duplicateArray(a:Array):Array {
			// Returns an exact copy of the specified array - now can be used an empty concat
			return a.concat();
		}
		public static function duplicateArrayRecursive(a:Array):Array { // Duplicates an array recursively looking for ARRAYS or OBJECTS only!
			var na = new Array();
			var l = a.length;
			for (var i:uint=0; i<l; i++) {
				if (a[i] is Array) na[i] = duplicateArrayRecursive(a[i]);
				else if (isObject(a[i])) na[i] = duplicateObjectRecursive(a[i]);
				else na[i] = a[i];
			}
			return na;
		}
		public static function shuffleArray(a:Array):Array { // This returns a shuffled copy of the array. It does not shuffle the original array!!
			var len:int = a.length;
			var arr2:Array = new Array(len);
			var killArray:Array = duplicateArray(a);
			for(var i:int = 0; i<len; i++) {
				arr2[i] = killArray.splice(int(Math.random() * (len - i)), 1)[0];
			}
			return arr2;
		}
		public static function execForEach(a:Array, funcName:String, par1=null) {
			if (par1 == null) for (var i in a) a[i][funcName]();
			else for (var ii in a) a[ii][funcName](par1);
		}
		public static function swapLastArray(a:Array):* { // Removes last item, puts it first, and returns it
			a.unshift(a.pop());
			return a[0];
		}
		public static function swapFirstArray(a:Array):* { // Removes first item, puts it last, and returns it
			a.push(a.shift());
			return a[a.length-1];
		}
		public static function removeArrayItem(a:Array, item:*):void {
			var pos:Number = a.indexOf(item);
			if (pos != -1) removeItemAt(a, pos);
			else {
				Debug.throwError(_debugPrefix, "Cannot remove",item,"from array",a);
			}
		}
		public static function removeItemAt(a:Array, n:uint):* {
			return a.splice(n,1)[0];
		}
		public static function arrayContains(a:Array, item:*):Boolean {
			return a.indexOf(item) != -1;
		}
// VECTOR ///////////////////////////////////////////////////////////////////////////////////////
		public static function removeVectorItem(a:*, item:*):void {
			var pos:Number = a.indexOf(item);
			if (pos != -1) removeVectorItemAt(a, pos);
			else {
				Debug.error(_debugPrefix, "Cannot remove",item,"from Vector",a);
			}
		}
		public static function removeVectorItemAt(a:*, n:uint):* {     
			return a.splice(n,1)[0];
		}
		static public function vectorToArray(v:*):Array {
			var a:Array = [];
			for each (var el:* in v) a.push(el);
			return a;
		}
// OBJECTS /////////////////////////////////////////////////////////////////////////////////
		public static function duplicateObject			(o:Object):Object {
			var no							:Object = new Object();
			for (var i:String in o)					no[i] = o[i];
			return							no;
		}
		public static function compareObjects			(o1, o2):Boolean { // Returns true if 2 objects are equal (not recursive)
			for (_j in o1)						if (o1[_j] != o2[_j]) return false;
			return							true;
		}
		public static function duplicateObjectRecursive		(o:Object):Object { // Duplicates an object recursively looking for ARRAYS or OBJECTS only!
			var no							:Object = new Object();
			for (var i:String in o) {
				if (o[i] is Array)					no[i] = duplicateArrayRecursive(o[i]);
				else if (isObject(o[i]))				no[i] = duplicateObjectRecursive(o[i]);
				else							no[i] = o[i];
			}
			return							no;
		}
// NUMBER ///////////////////////////////////////////////////////////////////////////////////////
		public static function isEven					(n):Boolean {
			// Tells if a number is even. It does not work with decimals.
			return							(Math.floor(Math.abs(n))%2) == 0;
		}
		public static function setRange				(n:Number, min:Number=0, max:Number=100):Number {
			return							n<min ? min : n>max ? max : n;
		}
		public static function isInRange				(n:Number, min:Number, max:Number):Boolean {
			return							n > min && n < max;
		}
		public static function getRandomNumber			(n:uint):uint { // Returns an optimized number within 0 and the number choosen (to be added 1 for starting with 1)
			return							Math.floor(Math.random()*n);
		}
		public static function hasDecimals				(n:Number):Boolean {
			return							!!(n%1);
		}
// PERCENT ////////////////////////////////////////////////////////////////////////////////
		public static function getPercent				(total:Number, percent:Number):Number {
			// Finds a percentage (total, percent)
			return							(total/100)*percent;
		}
		public static function calculatePercent			(fraction:Number, total:Number):Number {
			// (20,200) = 10;  (3,10) = 30;
			return							100/(total/fraction);
		}
		public static function calculatePercentRange		(fraction:Number, total:Number):Number {
			// Calculates a percent which is in range 0-100
			return							checkPercentRange(calculatePercent(fraction, total));
		}
		public static function checkPercentRange		(n:Number):Number {
			// Returns a number which is in the 0-100 range
			return							n < 0 ? 0 : n > 100 ? 100 : n;
		}
// MEASUREMENTS ///////////////////////////////////////////////////////////////////////////////////////
		public static function milesToMeters			(m:Number):Number {
			return							m * 1609.344;
		}
		public static function metersToMiles			(m:Number):Number {
			return							m / 1609.344;
		}
// PATH AND TARGETING ///////////////////////////////////////////////////////////////////////////////////
		public static function getAbsolutePath			(c:DisplayObject):String {
			var s								:String = c.name;
			var o								:Object = c.parent;
			while (o != c.stage) {
				s							= o.name + "." + s;
				o							= o.parent;
			}
			return							s;
		}
		public static function getPathFromString		(c:DisplayObject, s:String):* {
			var a								:Array = s.split(".");
			var count							:uint = 0;
			var cont							:DisplayObject = c;
			var targ							:DisplayObject;
			while (count < a.length) {
				targ							= cont[a[count]];
				count						++;
				cont							= targ;
			}
			if (UCode.exists(targ)) 				return targ;		
			else								Debug.debug(_debugPrefix, "getPathFromString " + s + " gave null result. Aborting");
		}
// DEVELOPMENT ///////////////////////////////////////////////////////////////////////////////////////
		public static function getTestImageUrl			(id="1", res:String="m"):String {
			// It can come in 4 resolutions: t (80x80), s (200x200), m (800x600), h (large)
			return							"http://www.pippoflash.com/_img/"+res + id+".jpg";
		}
		public static function getBubblingClass			(clip:DisplayObject, cl) {
			return							clip.parent is cl ? clip.parent : getBubblingClass(clip.parent, cl);
		}
		public static function getBubblingProperty		(clip:DisplayObject, prop:String) {
			return							clip.parent.hasOwnProperty(prop) ? clip.parent : exists(clip.parent) ? getBubblingProperty(clip.parent, prop) : null;
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