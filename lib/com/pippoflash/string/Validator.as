/* Validator - (c) Filippo Gregoretti - PippoFlash.com */
/* Validates text fields (email, zip code, etc.) */

package com.pippoflash.string {
	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.UText;
	import									com.pippoflash.utils.Debug;
	
	public dynamic class Validator extends MovieClip {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		private static var _numbers					:String = "0123456789";
		// USER STATIC
		public static var _countryZip					:String = "US";
		public static var _PippoFlashId				:String = "Validator";
		// Predefined checks
		private static var _check_EMAIL				:Object = {mustHave:".@", minLength:7, mustNotHave:" |!\"£$%&/()='^,;:°§*+<> \\][{}"};		
		private static var _check_ZIP_US				:Object = {minLength:5, justNumbers:true};
		private static var _check_DATE				:Object = {sequence:["number","number","/","number","number","/","number","number","number","number"]}; // nn/nn/nnnn
		private static var _check_DATE2				:Object = {sequence:["number","/","number","number","/","number","number","number","number"]}; // n/nn/nnnn
		private static var _check_DATE3				:Object = {sequence:["number","number","/","number","/","number","number","number","number"]}; // nn/n/nnnn
		private static var _check_DATE4				:Object = {sequence:["number","/","number","/","number","number","number","number"]}; // n/n/nnnn
		// SYSTEM
		public static var _txt						:String; // Stores the text to check
		public static var _splitText					:Array; // Stores the text to check split into an array
		public static var _splitPar					:Array; // Stores the actual parameter splitted in array
		public static var _par;						// Stores the actual parameter to check
		// HTML VARIABLES			
		// USER VARIABLES
		// REFERENCES _references._dateSequence
		// MARKERS
		// DATA HOLDERS
		// UTY
		public static var _s						:String;
		public static var _a						:Array;
		public static var _i						:Number;
		public static var _b						:Boolean;
		public static var _o						:Object;
		public static var _counter					:uint;
		public static var _date						:Date;
		public static var _seq						:String;
// 		private var _counter						:uint;
// 		private var _clip							:MovieClip;
// 		public var _isTrue						:Boolean;
// INIT //////////////////////////////////////////////////////////////////////////////////////////
// RENDER //////////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public static function check					(id:*, txt:String):Boolean { // This grabs an ID for internal predefined, or a new object!!!
			// Add exceptions
			if (id == "ZIP")						id += "_" + _countryZip;
			// Trace action
			Debug.debug						(_PippoFlashId,"> checking for", id,txt);
			// Set parameters
			_o								= id is String ? Validator["_check_"+id] : id;
			_splitText							= txt.split("");
			_txt								= txt;
			for (_s in _o) {
				_par							= _o[_s];
				if (!Validator["check_"+_s]())		return false;
			}
			return							true;
		}
		public static function checkSequence			(txt:String, seq:Array):Boolean { // Gets a string, and an array. The array has a sequence of checks. If its a single digit, then it must be equal, otherwise is a comand
			if (!UText.exists(txt))				return false;
			_splitText							= txt.split("");
			for (var i:uint=0; i<seq.length; i++) {
				if (!UText.exists(_splitText[i]))	return false;
				else if (seq[i].length == 1) {
					if (_splitText[i] != seq[i]) return false;
				}
				else {
					if (!Validator["checkChar_"+seq[i]](_splitText[i])) return false;
				}
			}
			return							true;
		}
			// These are checks for sequence - sequnce checks for checkChar_[id], otherwise if it is the chatacter
			// These are ALL single digit checks
			public static function checkChar_number			(s:String):Boolean {
				return							_numbers.indexOf(s) != -1;
			}
		// Check by parameter name. Return true if its ok.
		public static function check_sequence			():Boolean {
			return							checkSequence(_txt, _par);
		}
		public static function check_mustHave			():Boolean {
			splitPar							();
			for each (_s in _splitPar) {
				if (_txt.indexOf(_s) == -1) return false;
			}
			return							true;
		}
		public static function check_minLength			():Boolean {
			return							_txt.length >= _par;
		}
		public static function check_maxLength			():Boolean {
			return							_txt.length <= _par;
		}
		public static function check_mustNotHave		():Boolean {
			for each (_s in _splitText) {
				if (_par.indexOf(_s) != -1) return false;
			}
			return							true;
		}
		public static function check_justNumbers		():Boolean {
			for each (_s in _splitText) {
				if (_numbers.indexOf(_s) == -1) return false;
			}
			return							true;
		}
// UTY ////////////////////////////////////////////////////////////////////////////////////
		private static function splitPar				() {
			_splitPar							= _par.split("");
		}
// SPECIAL METHODS //////////////////////////////////////////////////////////////////////
// DATE COMPARISON ///////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}