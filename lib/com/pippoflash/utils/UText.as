/* UText - ver 0.15 - Filippo Gregoretti - www.pippoflash.com
0.15 - getPathFromString(origin:DisplayObject, path:String); // Converts a string "parent.parent.clip3" into a reference.

*/

package com.pippoflash.utils {

	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	import									flash.external.*;
	import									flash.system.*;
	import 									fl.motion.Color; 
// 	import									PippoFlashAS3.*;
	import 									flash.filters.BlurFilter;

	
	public class UText {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		public static var _verbose					:Boolean = false;
		// CONSTANTS
		private static const UTY_TF				:TextField = new TextField(); // It is useful to have an abstaract textfield
		// STATIC VARIABLES CONSTANTS
		public static var _deviceUniversalFonts		:Array = ["Arial", "Helvetica", "Verdana"];
		public static var _debugPrefix				:String = "UText";
		public static var _numbers					:String = "0123456789";
		public static var _uppercase				:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		public static var _lowercase				:String = "abcdefghijklmnopqrstuvwxyz";
		public static var _european				:String = "àèìòùÀÈÌÒÙáéíóúýÁÉÍÓÚÝâêîôûÂÊÎÔÛãñõÃÑÕäëïöüÿÄËÏÖÜŸåÅæÆœŒçÇðÐøØ¿¡ß";
		public static var _stringRandomList			:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"; // No special characters because I could use this on online operations
		public static var _allGlyphs					:String;
		public static var _textFieldProperties			:Array = ["alwaysShowSelection", "antiAliasType", "background", "backgroundColor", "border", "borderColor", "condenseWhite", "defaultTextFormat", "displayAsPassword", "embedFonts", "gridFitType", "maxChars", "mouseWheelEnabled", "multiline", "restrict", "scrollH", "scrollV", "selectable", "sharpness", "styleSheet", "textColor", "thickness", "type", "useRichTextClipboard", "wordWrap"];
		public static var _textFieldVisualProperties		:Array = ["antiAliasType", "condenseWhite", "defaultTextFormat", "embedFonts", "selectable", "sharpness", "textColor"];
		public static var _textFormatProperties		:Array = ["font", "size", "color", "bold", "italic", "underline", "url", "target", "align", "leftMargin", "rightMargin", "indent", "leading"];
		// UTY
		public static var _a						:Array;
		public static var _s						:String;
		public static var _i						:int;
		public static var _b						:Boolean;
		public static var _j:*;						// Jolly variable, can be anything
		public static var _n						:Number;
		public static var _counter					:int;
		public static var _tfo						:TextFormat;
		// MARKERS
		public static var _initFunction				:Function = firstTimeInit;
		// HOLDERS
		public static var _totalList					:Array;
		public static var _embeddedList				:Array;
		public static var _deviceList				:Array = new Array();
		public static var _reliableList				:Array; // Fonts which are available for all european languages
		public static var _embeddedByName			:Object; // ALL FONT NAMES ARE STORED IN LOWER CASE
		public static var _deviceByName				:Object; // ALL FONT NAMES ARE STORED IN LOWER CASE
		public static var _reliableByName			:Object;
		// Dynamic text sizing, vocabulary to store original text size
		private static var _originalTextFieldsData		:Dictionary = new Dictionary();
// DUMMIES //////////////////////////////////////////////////////////////////////////////
		public static var _dummyTextField			:TextField = new TextField();
// SETUP	///////////////////////////////////////////////////////////////////////////////////////
		public static var init						:Function = firstTimeInit;
		private static function firstTimeInit			():void {
			_initFunction						= UCode.dummyFunction;
			init								= UCode.dummyFunction;
			_allGlyphs							= _numbers + " " + _uppercase + _lowercase + _european;
			updateFontsList						();
		}
// EMBED RENDERING //////////////////////////////////////////////////////////////////////////////
		public static function hasGlyphs				(fn:String, s:String):Boolean {
			_initFunction						();
			if (!UCode.exists(getEmbeddedFont(fn))) {
				Debug.debug					(_debugPrefix,fn,"is not an embedded font.");
				return						false;
			}
			else								return getEmbeddedFont(fn).hasGlyphs(s);
		}
		public static function setToUniversalFont			(t:TextField):void {
			t.embedFonts						= false;
			for each (_s in _deviceUniversalFonts) {
				if (UCode.exists(getDeviceFont(_s))) {
					setTextFormat				(t, {font:_s});
					return;
				}
			}
			var dummyFilter:BlurFilter 				= new BlurFilter(1,1,1);
			t.filters 							= new Array(dummyFilter);
			setTextFormat						(t, {font:"_sans"});
			Debug.debug						(_debugPrefix,"no universal font is available on system. Setting _sans as device font.");
		}
		public static function updateFontsList			():void {
			_initFunction						();
			_totalList							= Font.enumerateFonts(true);
			_embeddedList						= Font.enumerateFonts();
			_reliableList							= new Array();
			_deviceByName						= new Object();
			_embeddedByName					= new Object();
			_reliableByName						= new Object();
			for each (_j in _totalList) {
				if (_j.fontType == FontType.DEVICE) {
					_deviceList.push				(_j);
					_deviceByName[_j.fontName.toLowerCase()] = _j;
				} else {
					_embeddedByName[_j.fontName.toLowerCase()] = _j;
					if (_j.hasGlyphs(_allGlyphs)) {
						_reliableList.push			(_j);
						_reliableByName[_j.fontName.toLowerCase()] = _j;
					}
				}
			}
			if (_verbose) {
				Debug.debug					(_debugPrefix, "updating fonts list.");
				Debug.listObject					(_embeddedByName, _debugPrefix+ " - Embedded font")
				Debug.listObject					(_embeddedByName, _debugPrefix+ " - Reliable for european languages")
			}
		}
// SET TEXT ///////////////////////////////////////////////////////////////////////////////////
		public static function setForcedText			(t:TextField, s:String=" "):Boolean {			
			// this sets a cut text in a textfield, and if its not possible to render it, it will convert it to universal font
			_s								= t.getTextFormat().font;
			if (!hasGlyphs(_s, s))					setToUniversalFont(t);
			return 							setText(t, s);
		}
		public static function setText				(t:TextField, s:String=" ", cutChar:String="..."):Boolean {
			// Sets text in textfield. If text is scrollable adds ... at the end and returns true
			return							t.multiline || t.wordWrap ? setTextMultiline(t, s, cutChar) : setTextSingleLine(t, s, cutChar);
		}
		public static function setTextNormal			(t:TextField, s:String=" "):void {
			t.text							= s;
		}
		public static function setTextHtml				(t:TextField, s:String=" "):void {
			/* TO BE IMPLEMENTED SOMETHING THAT WORKS IN HTML */
			t.htmlText							= s;
		}
		public static function setTextMultiline			(t:TextField, s:String=" ", cutChar:String="..."):Boolean {
			t.text							= s;
			t.scrollV							= 1;
			if (hasScroll(t)) {
				try {
					_i						= t.getLineOffset(t.bottomScrollV); // Index of last visible character
				}
				catch(e) {
					_i						= s.length;
				}
				t.replaceText					(_i-cutChar.length, t.text.length, cutChar);
				return						true;
			}
			return							false;
		}
		public static function setTextSingleLine			(t:TextField, s:String=" ", cutChar:String="..."):Boolean {
			t.text								= s;
			if (t.maxScrollH == 0)					return false; // Text is shorter than textfield
			_a								= s.split(" ");
			_counter							= _a.length;
			while (t.maxScrollH > 0) {
				_a.pop						();
				t.text							= _a.join(" ") + cutChar;
			}
			return							true;
		}
	// Dynamic resizing of text
		public static function setTextDynamicSize(tf:TextField, s:String=""):void {
			var format							:TextFormat = new TextFormat();
			format.size							= getTextFieldOriginalTextFormat(tf).size;
			tf.defaultTextFormat					= format;
			tf.text							= s;
			while (tf.maxScrollV > 1 || tf.maxScrollH) {
				format.size						= Number(format.size) - 1;
				tf.defaultTextFormat				= format;
				tf.text						= s;
			}
		}
		public static function setHtmlTextDynamicSize(tf:TextField, s:String="", boldIt:Boolean=false, minSize:uint=99):void {
			// Here I DO NOT need to store original textfield data, since html sizing is in text, doesnt change textfield properties
			var format:TextFormat  = getTextFieldOriginalTextFormat(tf);
			tf.defaultTextFormat					= format;
			var size							:uint = 0;
			var t								:String;
			if (boldIt)							s = bold(s);
			tf.htmlText							= s;
			while ((tf.maxScrollV>1 || tf.maxScrollH) && size<minSize) {
				t							= fontSize(s, "-"+String(size));
				tf.htmlText						= t;
				size							++;
			}
		}
		public static function centerTextInOriginalRectangle(tf:TextField, useTextBounds:Boolean=false):void { // Centers TextField vertically and horizontally according to original rectangle
			var rect							:Rectangle = getTextFieldOriginalRectangle(tf);
			UDisplay.alignSpriteTo				(tf, rect);
			if (useTextBounds) { // Center according to real text dimensions and not textfield dimensions
				// TextField is already centered to rectangle, I just need to adjust according to textWidth and textHeihgt
// 				if (tf.autoSize == TextFieldAutoSize.NONE)	tf.autoSize = TextFieldAutoSize.CENTER;
				var hoffset:Number = (tf.width - tf.textWidth) / 2;
				var voffset:Number = (tf.height - tf.textHeight) / 2;
				tf.x += hoffset;
				tf.y += voffset;
			}
		}
	// Center text vertically
		public static function centerTextVertically(tf:TextField, txt:String, html:Boolean=true, halign:String="center"):void { // Centers textfield inside original textfield vertical dimensions.
			// I collect textfield data initially so that it will not be changed in case it has not been stored before
			var data:Object = getTextFieldData(tf);
			var h:Number = data.height;
			resetTextFieldToOriginal(tf);
			tf.autoSize = halign;
			if (html) tf.htmlText = txt;
			else tf.text = txt;
			// Height of rendered TextField is larger than original height. Therefore I just set it up normally.
			if (tf.height > h) {
				tf.autoSize = "none";
				tf.height = h;
			}
			// Instead size is less, therefore I position it centrally vertical.
			else {
				tf.y = getTextFieldData(tf).y + ((h-tf.height)/2);
			}
		}
// TEXTFIELD AUTOMATIC MANAGEMENT ///////////////////////////////////////////////////////////////////////////////////////
		// TextField does NOT retain styles if set in IDE and then modified at runtime (yes, this sucks), therefore it can be "prepared", and it will retain styles
		public static function prepareTextField			(tf:TextField):void {
			setTextFormat						(tf, tf.getTextFormat());
		}
		// Stores and manages properties related to a textfield
		// It also stores original position and format
		public static function addTextFieldOriginalData	(tf:TextField, overwrite:Boolean=false, rect:Rectangle=null, f:TextFormat=null):void {
			// Can choose to overwrite and add a custom rectangle
			if (!_originalTextFieldsData[tf] || overwrite) {
				_originalTextFieldsData[tf] 			= {format:duplicateTextFormat(f ? f : tf.getTextFormat())};
				_originalTextFieldsData[tf].rect		= rect ? rect : tf.getBounds(tf.parent);
			}
		}
		// Overwrite rectangle from textfield or custom
		public static function setTextFieldOriginalRectangle	(tf:TextField, rect:Rectangle=null):void { // This one sets the rectangle, doesn't matter if it was set before, it's always overwritten. If no rectangle is specified, getBounds(parent) is used
			// If no data is specified, just create original data with eventually custom rect
			if (!_originalTextFieldsData[tf])			addTextFieldOriginalData(tf, true, rect); // If no data was defined just create it from scratch
			// Otherwise just eventully substitute with rect or with actual bounds
			else if (rect)						_originalTextFieldsData[tf].rect = rect ? rect : tf.getBounds(tf.parent);
		}
		// Overwrite format from textfield or custom
		public static function setTextFieldOriginalTextFormat(tf:TextField, f:TextFormat=null):void {
			// If no data is specified, just create original data with eventually custom rect
			if (!_originalTextFieldsData[tf])			addTextFieldOriginalData(tf, true, null, f); // If no data was defined just create it from scratch
			// Otherwise just eventully substitute with rect or with actual bounds
			else if (f)							_originalTextFieldsData[tf].format = duplicateTextFormat(f ? f : tf.getTextFormat());
		}
		public static function resetTextFieldToOriginal	(tf:TextField):void {
			if (!_originalTextFieldsData[tf]) { // Nothing to reset, just add the data
				addTextFieldOriginalData			(tf);
				return;
			}
			// Proceed resetting
			var data							:Object = getTextFieldData(tf);
			tf.width							= data.rect.width;
			tf.height							= data.rect.height;
			tf.x								= data.rect.x;
			tf.y								= data.rect.y;
			setTextFormat						(tf, data.format);
		}
		private static function addTextFieldProperty		(tf:TextField, propName:String, value:*):void {
			addTextFieldOriginalData				(tf);
			_originalTextFieldsData[tf][propName]		= value;
		}
		private static function getTextFieldData			(tf:TextField):Object {
			addTextFieldOriginalData				(tf);
			return							_originalTextFieldsData[tf];
		}
		private static function getTextFieldOriginalTextFormat(tf:TextField):TextFormat {
			addTextFieldOriginalData				(tf);
			return							_originalTextFieldsData[tf].format;
		}
		private static function getTextFieldOriginalRectangle(tf:TextField):Rectangle {
			addTextFieldOriginalData				(tf);
			return							_originalTextFieldsData[tf].rect;
		}
// TEXTFIELD //////////////////////////////////////////////////////////////////////
		public static function makeTextFieldAutoSize		(t:TextField, s:String="left"):void {
			t.autoSize							= s;
			if (s == TextFieldAutoSize.LEFT || s == TextFieldAutoSize.RIGHT) t.wordWrap = true;
		}
		public static function copyTextFieldProperties		(dest:TextField, source:TextField):void {
			Debug.debug						(_debugPrefix, "Copying properties from",source,"to",dest);
			for each (_s in _textFieldProperties) {
// 				trace(_s, dest[_s]);
				dest[_s] = source[_s];
			}
		}
		public static function getTextFieldVisualProperties	(t:TextField):Object {
			var o:Object = {};
			for each (_s in _textFieldVisualProperties)	o[_s] = t[_s];
			return							o;
		}
		public static function copyStyle(dest:TextField, source:TextField):void {
			setTextFormat (dest, source.getTextFormat());
			copyTextFieldProperties (dest, source);
		}
		public static function scrollToBottom(t:TextField):void {
			t.scrollV = t.maxScrollV;
		}
		public static function scrollToTop(t:TextField):void {
			t.scrollV = 0;
		}
		public static function addToScroll(t:TextField, n:int):void {
			t.scrollV += n;
		}
		public static function scrollPage(t:TextField, n:int):void {
			t.scrollV += (t.bottomScrollV - t.scrollV)*n;
		}
		public static function resetScroll(t:TextField):void {
			scrollToTop(t);
			t.scrollH = 0;
		}
		public static function setTextColor(tf:TextField, c:uint):void { // Sets color of text in a textfield using textformat
			setTextFormat(tf, {color:c});
		}
		
		
		
// TEXTFORMAT //////////////////////////////////////////////////////////////////////
		public static function makeTextFormat(props:Object):TextFormat {
			// Creates a text format object with properties
			var t:TextFormat = new TextFormat();
			for (var i:String in props) t[i] = props[i];
			return t;
		}
		public static function setTextFormat(targ:TextField, props:*):void { // this can get a TextFormat or an object with properties
			var t:TextFormat = props is TextFormat ? props : makeTextFormat(props);
			targ.defaultTextFormat = t;
			targ.setTextFormat(t);
		}
		public static function updateTextFormat(t:TextField, props:Object):void {
			_tfo = t.getTextFormat();
			for (_s in props) _tfo[_s] = props[_s];
			setTextFormat(t, _tfo);
		}
		public static function duplicateTextFormat(t:TextFormat):TextFormat {
			var tf:TextFormat = new TextFormat();
			for each (_s in _textFormatProperties) if (t[_s] != null) tf[_s] = t[_s];
			return tf;
		}
		public static function convertTextFormatToObject(t:TextField):Object {
			var o:Object = new Object();
			var tf:TextFormat = t.getTextFormat();
			for each (_s in _textFormatProperties) if (tf[_s]) o[_s] = tf[_s];
			return o;
		}
		public static function setXmlTextFormat(tf:TextField, xf:*, setTextFieldProps:Boolean=false):void {
			setTextFormat(tf, convertXmlTextFormat(xf));
			if (setTextFieldProps) {
				// Also text field props have to be set here
			}
		}
		public static function convertXmlTextFormat		(xf:*):TextFormat {
			if (xf is XMLList)						xf = xf[0];
			var props							:Object = {};
			var attList							:XMLList = xf.@*;
			for each (var par:* in attList) {
				props[String(par.name())]			= String(par);
			}
			return							makeTextFormat(props);
		}
		public static function getTextFormat			(tf:TextField):TextFormat {
			return							tf.defaultTextFormat;
		}
		 

// CHECKS /////////////////////////////////////////////////////////////////////////////////////
		public static function hasScroll				(t:TextField):Boolean {
			return							hasScrollV(t) || hasScrollH(t);
		}
		public static function hasScrollV				(t:TextField):Boolean {
			return							t.maxScrollV > 1; // maxScrollV == 1 means there is no possible scroll
		}
		public static function hasScrollH				(t:TextField):Boolean {
			return							t.maxScrollH > 0;
		}
		public static var contains:Function = stringContains;
		public static function stringContains(s:String, s1:String, caseSensitive:Boolean=true):Boolean {
			return caseSensitive ? s.indexOf(s1) != -1 : s.toUpperCase().indexOf(s1.toUpperCase()) != -1;
		}
		public static function exists(s:String=null):Boolean {
			return s && s != "";
		}
		static public function stringContainsHowmany(source:String, key:String):int {
			if (source.indexOf(key) == -1) return 0; // No instances of the string found
			const split:Array = source.split(key);
			return split.length -1;
		}
		/**
		 * Checks if string contains any value from the array
		 */
		public static function stringIsArrayItem(s:String, a:Array):Boolean {
			for each(var item:String in a) {
				// trace(s, a, item, s == item)
				// if (s.indexOf(value) != -1) return true;
				if (s == item) return true;
			}
			return false;
		}
		/**
		 * If checkString contains ALL characters in fromString, checked one by one 
		 */
		public static function stringContainsAllCharactersFromString(checkString:String, fromString:String):Boolean {
			var len:int = fromString.length;
			for(var i:int = 0; i < len; i++) {
				if (checkString.indexOf(fromString.charAt(i)) == -1) return false;
			}
			return true;
		}
		/**
		 * If checkString contains at least ONE character in fromString, checked one by one 
		 */
		public static function stringContainsOneCharacterFromString(checkString:String, fromString:String):Boolean {
			var len:int = fromString.length;
			for(var i:int = 0; i < len; i++) {
				if (checkString.indexOf(fromString.charAt(i)) != -1) return true;
			}
			return false;
		}
		
		
		
// STRING ///////////////////////////////////////////////////////////////////////////////////////
		public static function insertParams(s:String, pars:Object=null):String {
			s = String(s);
			if (pars) for (var i:String in pars) s = s.split("["+i+"]").join(String(pars[i]));
			return s;
		}
		public static function insertParam(s:String, par:String, cont:Object):String {
			return s.split("["+par+"]").join(cont);
		}
		public static function getRandomString(n:uint = 10):String {
			var s:String = "";
			var l:uint = _stringRandomList.length;
			for (var i:Number=0; i<n; i++) {
				s += _stringRandomList.charAt(Math.floor(Math.random()*l));
			}
			return s;
		}
		public static function stripSpaces(s:String):String {
			var initialSpace:uint = 0;
			var finalSpace:uint = s.length-1;
			while (s.charAt(initialSpace) == " ") initialSpace++;
			while (s.charAt(finalSpace) == " ") finalSpace--;
			return s.substr(initialSpace, (finalSpace-initialSpace)+1);
		}
		static public function stripCharacters(source:String, stripChars:String, joinChar:String="_"):String {
			for (var i:int = 0; i < stripChars.length; i++) {
				//trace("Check " + stripChars.charAt(i) );
				//trace(source.indexOf(stripChars.charAt(i)));
				if (source.indexOf(stripChars.charAt(i)) != -1) source = source.split(stripChars.charAt(i)).join(joinChar);
			}
			return source;
		}
		/**
		 * Looks for a string inside another string. If found only text after the occurrance found is returned.
		 * @param	s the full string
		 * @param	searchFor the string to look for
		 * @return 	the string after the occurrance (if any) or the entire string
		 */
		static public function removeTextUpTo(s:String, searchFor:String):String {
			const index:int = s.indexOf(searchFor);
			const newS:String = s;
			if (index != -1) {
				s = s.substr(index + searchFor.length);
			}
			return s;
		}
		/**
		 * Adds single characters from source to target only if that character is not already in target
		 */
		public static function addCharactersToStringIfNotPresent(target:String, source:String):String {
			var len:int = source.length;
			var char:String;
			for(var i:int = 0; i < len; i++) {
				char = source.charAt(i);
				if (target.indexOf(char) == -1) target += char;
			}
			return target;
		}
		
		
// FORMATTING ////////////////////////////////////////////////////////////////////////////////
// STRING - NUMBERS //////////////////////////////////////////////////////////////////////////////////
	// This gets a number or a string, and converts it to human readable format
	// 9999 = 9.9999; -12.23 = -12,23;
		public static function formatNumber(n:*):String {
			var source:String = String(n);
			var a:Array = source.split("."); var s:String = a[0]; var hasMinus:Boolean = false;
			if (a[0].indexOf("-") != -1) {
				hasMinus = true;	
				s = a[0].substr(1,9999999);
			}
			var f:String = "";
			while (s.length > 3) {
				f = f + "," + s.substr(s.length-3,3); s = s.substr(0,s.length-3);
			}
			f = s + f;
			if (hasMinus) f = "-" + f;
			if (a.length == 2) f = f + "," + a[1];
			return f;
		}
	// Fomrats a number to a complete money+cents format. I.e.: 2345678 = 23.456,78. In case of ,00 it can be chosen to omit it.
		public static function formatMoneyCents		(amount:Number, removeCentsIf00:Boolean=true, if0:String="0"):String {
			if (amount > 99999) { // Format money over 5 digits
				// Here I can simply remove cents and format as money the rest
				var value						:String = String(amount);
				var step						:uint = value.length-2;
				var main						:String = UText.formatMoney(uint(value.substr(0,step)));
				var change					:String = value.substr(step, 2); // Find the rest
				if (removeCentsIf00 && change == "00") return main;
				else							return main + "," + change;
			}
			else { // Format money under 5 digits (simple)
				return						UText.formatCents(amount, removeCentsIf00, if0);
			}
		}
	// Grabs a number and converts t to euro cents. 234 = 2.34, 3 = 0.03; 1234567 = 12345,67
		public static function formatCents			(amount:Number, removeCentsIf00:Boolean=true, if0:String="0"):String { 
			var value							:String = String(amount);
			if (amount > 99) { // Full amount. Over 1.
				var step						:uint = value.length-2;
				var main						:String = value.substr(0,step);
				var change					:String = value.substr(step, 2); // Find the rest
				if (removeCentsIf00 && change == "00") return main;
				else							return main + "," + change;
			}
			else if (amount > 9) { // Between 10 and 99
				return 						"0," + value;
			}
			else if (amount) { // Between 1 and 9
				return 						"0,0" + value;
			}
			else { // It is 0
				return						if0;
			}
		}
	// Gets a number and converts it to money format: 1000.34 = 1.000,34. It can be added ,00 or not. If no decimals, converts only to money: 1234567 = 1.234.567
		public static function formatMoney				(amount:Number, addCentsToNoCents:Boolean=false, thousands:String=",", cents:String="."):String {
			// If addCentsToNoCents=true, amounts without decimals wil have ,00 added at the end. If number HAS decimals, they are always added.
			// Prepare for negative
			var isMinus							:Boolean;
			if (amount < 0) {
				isMinus						= true;
				amount						= Math.abs(amount);
			}
// 			var i								:uint = uint(amount); // The part without decimals
			var result							:String = String(Math.floor(amount));
			if (amount > 999) { // Initiate integer formatting if necessary
				var source						:String = result;
				var first						:uint = source.length%3; // Find the length of the first amount
				if (first == 0)					first =3;
				var loops						:uint = (source.length-first)/3; // find the amount of thousands
				result							= source.substr(0, first); // Get the first number
				for (var step:uint=0; step<loops; ++step) {
					result						+= thousands + source.substr(first+(3*step), 3);
				}
			}
			if (UCode.hasDecimals(amount)) { // Number has decimals
				result							+= cents + String(amount%1).substr(2,2);
			}
			else if (addCentsToNoCents) { // Has no decimeals, but I have to add ,00 at the end
				result							+= cents + "00";
			}
			return							isMinus ? "-" + result : result;
		}
		public static function millisecondsToTimeString(n:Number):String { // Number holds a larger amount. uint collapses with a smaller number. Use Number.
			// This converts an amout of milliseconds into a 00:30 format.
			if (n < 60000) return "00:"+checkOneZero(Math.round(n/1000),2);
			var secs:uint = Math.round(n/1000);
			var mins:uint = Math.floor(secs/60);
			_a = String(secs/60).split(".");
			var s:String = checkOneZero(mins)+":";
			if (_a.length == 1) return s + "00";
			var remainingSecs:uint = secs%60;
			return s+checkOneZero(remainingSecs);
		}
		public static function checkOneZero			(n:Number, digits:uint=2):String {
			// This returns a number formatted. 3,2 = 03; 3,3 = 003; 20,2 = 20; 20,4 = 0020; 200,2 = 200;
			_s								= String(n);
			if (_s.length >= digits)					return _s; // If its same or over length, just convert it to string
			for (_i=0; _i<digits-_s.length; _i++)		_s = "0" + _s;
			return							_s;
		}
		/**
		 * Grabs a string and converts it to a number with advanced features
		 * @param	s if "10" will become 10, if 10/100 will return a random number between 10 and 100
		 * @return
		 */
		static public function convertStringToNumber(s:String):Number {
			if (s.indexOf("/") != -1) { // Random timing
				const a:Array = s.split("/");
				const min:Number = Number(a[0]);
				const max:Number = Number(a[1]);
				const missingAmount:Number = max - min;
				const randomAmount:Number = Math.random() * missingAmount;
				//const randomAmount:Number = Math.round(Math.random() * missingAmount);
				return min + randomAmount;
			}
			return Number(s);
		}
		
		
		
		
		
		
// STRING - SUBSTITUTE //////////////////////////////////////////////////////////////////////////////
		// this is useful when testing, o overcome security nags, will substitute each occurance as specified
		// with addStringSub(source, change); I can set a text to be changed in a string, i.e. addStringSub("http://www.server.com/_data/", "c:\_data\")
		// I can set an unlimited number of keywords to search
		// then, with <myString = UCode.stringSub(myString);> all occurrances of set changes will be done
		public static var _stringSubsList:Array = new Array();
		public static function addStringSub(source:String, change:String):void {
			_stringSubsList.push({s:source, x:change});
		}
		public static function stringSub				(s:String):String {
			Debug.debug						(_debugPrefix,"check for stringSub: <" + s + ">");
			for (var i:uint=0; i<_stringSubsList.length; i++) if (s.indexOf(_stringSubsList[i].s) != -1) s = s.split(_stringSubsList[i].s).join(_stringSubsList[i].x);
			Debug.debug						(_debugPrefix,"result: <" + s + ">");
			return							s;
		}
		static public function substituteInString(source:String, key:String, value:String):String {
			return source.split(key).join(value);
		}
// STRING - DATE ///////////////////////////////////////////////////////////////////////////////////
		public static function getDateFromString			(d:String):String {
			var s								:String = d.substr(6,2) + "/" + d.substr(4,2) + "/" + d.substr(0,4) + " - " + d.substr(8,2) + ":" + d.substr(10,2);
			return							s;
		}
// HTML ///////////////////////////////////////////////////////////////////////////////////////
		public static function bold					(t:String):String{
			return							"<b>"+t+"</b>";
		}
		public static function italic					(t:String):String{
			return							"<i>"+t+"</i>";
		}
		public static function font					(t:String, o:Object):String{
			var s								:String = "<font ";
			for (_s in o)						s += _s + "='" + o[_s] + "'";
			s								+= ">"
			return							s + t + "</font>";
		}
		public static function fontSize(t:String, size:*, boldize:Boolean=false):String { // size can be a number or a string ("-1", "+3", 8)
			t = "<font size='"+size+"'>"+t+"</font>";
			return boldize ? bold(t) : t;
		}
		public static function link					(t:String, link:String, underline:Boolean=false, target:String="_self"):String {
			if (underline)						t = "<u>"+t+"</u>";
			var txt							:String = "<a href='"+link+"' target='"+target+"'>"+t+"</a>";
			return							txt;
		}
		public static function htmlToText(hs:String="undefined"):String {
			UTY_TF.htmlText = hs;
			return UTY_TF.text;
		}
		/**
		 * Gets a string, another string with list of characters, a tag open and a tag close, and returns the same string with special characters enclosed in tag. 
		 * Subsequent characters are enclosed together. I.e.: "pippo1e123", "12", "<b>", "</b>" - returns: "pippo<b>1</b>e<b>12</b>3"
		 * @param	source The string to be changed
		 * @param	characters The list of characters to be enclosed by tag
		 * @param	tagPre Start tag
		 * @param	tagPost End tag
		 * @return
		 */
		static public function encloseCharactersInTag(source:String, characters:String, tagPre:String, tagPost:String):String {
			// Loop in source
			//Debug.debug(_debugPrefix, "Changing",source,characters,tagPre,tagPost);
			var loopInt:int;
			//var foundCount:int;
			var foundString:String = "";
			var changedString:String = "";
			var char:String;
			for (loopInt = 0; loopInt <= source.length; loopInt++) {
				char = source.charAt(loopInt);
				if (loopInt < source.length && characters.indexOf(char) != -1) { // Char is of special characters
					foundString += char;
				} else { // Analyzed character is not special
					if (foundString.length) { // I have found some special characters before, so I need to add special string to string
						changedString += (tagPre + foundString + tagPost);
						foundString = "";  // Reset string of found special characters
					} 
					changedString += char;
				}
			}
			
			changedString += foundString;
			//Debug.debug(_debugPrefix, "Modified in " + changedString);
			return changedString; 
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		public static function getEmbeddedFont			(fn:String):Font {
			return							_embeddedByName[fn.toLowerCase()];
		}
		public static function getDeviceFont			(fn:String):Font {
			return							_deviceByName[fn.toLowerCase()];
		}
// 		public static function clearFocus				() {
// 			resetFocus							();
// 		}
	// FOCUS /////////////////////////////////////////////////////////////
		public static function resetFocus():void {
			UGlobal.resetFocus();
		}
		public static function setFocus				(t:TextField):void {
			UGlobal.setFocus					(t);
// 			UCode._stage.focus					= t;
		}
		public static function setFocusAndSelectAll		(t:TextField):void {
// 			UCode._stage.focus					= t;
		}
	// FORMAT TIME ///////////////////////////////////////////////////////////////////////////////////////
		static private var _timer:Date;
		static public function getFormattedTime():String { // Returns time with MM:SS:mm
			_timer = new Date();
			//var ss:int = (getTimer() / 1000) % 60;
			//var ms:Number = ss - getTimer();
			//var mm:int =  (ss / 1000) % 60;
			//return checkOneZero(mm) + ":" + checkOneZero(ss) + ":" + checkOneZero(ms);
			return checkOneZero(_timer.minutes) + ":" + checkOneZero(_timer.seconds) + ":" + _timer.milliseconds;
		}
		public static function getFormattedMilliseconds(t:int):String { // converts milliseconds to MM:SS:MM
			//var ms:Number = (t/1000) - Math.floor(t / 1000);
			var ss:int = (t / 1000) % 60;
			var mm:int = (ss / 60) % 60;
			//return mm + ":" + ss + ":" + ms;
			return checkOneZero(mm) + ":" + checkOneZero(ss);
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