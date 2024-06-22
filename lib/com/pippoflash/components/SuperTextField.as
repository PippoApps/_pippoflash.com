/* SuperTextField - 1.3


1.3 - Added removal of special html characters (_preventHtml, HTML_STRIP_CHARS) - it works in listener onTextChange
1.2 - Fixed changed return, only if text is different from "", "   ", Default Text and Previous Text



Boradcasts 
	onChange...		When the text content is changed
	onCommit...		When text is changed and focus is changed or return is pressed
	onSetFocus...
	onLooseFocus...
	
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.UKey;
	import											com.pippoflash.utils.UExec;
	import											com.pippoflash.utils.Debug;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.USystem;
	import											com.pippoflash.string.Validator;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	
	public dynamic class SuperTextField extends _cBase {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="TXT - Text", type=String, defaultValue="")]
		public var _lastText								:String = "";
		[Inspectable 									(name="TXT - Max Characters", type=Number, defaultValue=0)]
		public function set maxChars							(n:int):void {
			_txt.maxChars								= n;
		}
		[Inspectable 									(name="TXT - Restrict", type=String)]
		public function set restrict							(s:String):void {
			_txt.restrict								= s;
		}
		[Inspectable 									(name="TXT - Type", type=String, defaultValue="input", enumeration="input,dynamic")]
		public function set type							(s:String):void {
			_txt.type									= s;
		}
		[Inspectable	 								(name="TXT - Password", type=Boolean, defaultValue=false)]
		public function set displayAsPassword					(b:Boolean):void {
			_txt.displayAsPassword						= b;
			_isPassword								= b;
		}
		[Inspectable 									(name="TXT - Selectable", type=Boolean, defaultValue=true)]
		public function set selectable						(b:Boolean):void {
			_txt.selectable								= b;
		}
		[Inspectable 									(name="TXT - Embed Fonts", type=Boolean, defaultValue=false)]
		public function set embedFonts						(b:Boolean):void {	
			_txt.embedFonts								= b;
		}
		[Inspectable 									(name="TXT - Multiline", type=Boolean, defaultValue=false)]
		public function set multiline							(b:Boolean):void {
			_txt.multiline								= b;
			_txt.wordWrap								= b;
		}
		[Inspectable 									(name="UX - Auto-select text", type=Boolean, defaultValue=true)]
		public var _autoSelect								:Boolean = true;
		[Inspectable 									(name="UX - Reset on ESC", type=Boolean, defaultValue=true)]
		public var _resetOnEsc								:Boolean = true;
		[Inspectable 									(name="SYS - Default Text", type=String, defaultValue="")]
		public var _userDefaultText							:String = "";
		[Inspectable 									(name="SYS - Prevent HTML chars", type=Boolean, defaultValue=true)]
		public var _preventHtml							:Boolean = true;
		[Inspectable 									(name="UI - Margins", type=Array, defaultValue="Top,Bottom,Left,Right")]
		public var _defaultTextMargins						:Array = [0,0,0,0];
		[Inspectable 									(name="TAB - Tabbing Group", type=String, defaultValue="")]
		public var _tabGroup								:String = "";
		[Inspectable 									(name="TAB - Tab Index", type=Number, defaultValue=-1)]
		public var _tabIndex								:int = -1;
		[Inspectable 									(name="TAB - Don't Tab Out", type=Boolean, defaultValue=false)]
		public var _blockTabbing							:Boolean = false;
		[Inspectable 									(name="UX - Clear on select?", type=Boolean, defaultValue=true)]
		public var _clearOnSelect							:Boolean = true;
		[Inspectable 									(name="UX - re-select on return?", type=Boolean, defaultValue=false)]
		public var _reselectOnReturn						:Boolean = false;
		[Inspectable 									(name="UI - Text Color", type=Color, defaultValue="#2c2c2c")]
		public var _colorNorm								:uint = 0x2c2c2c;
		[Inspectable 									(name="UI - Text Default Color", type=Color, defaultValue="#a2a2a2")]
		public var _colorDefault							:uint = 0xa2a2a2;
		[Inspectable 									(name="UI - Text Error Color", type=Color, defaultValue="#ff0000")]
		public var _colorError								:uint = 0xff0000;
		[Inspectable 									(name="UI - Show Default Background", type=Boolean, defaultValue=true)]
		public var _showBackground							:Boolean = true;
		[Inspectable 									(name="UI - Alignement", type=String, defaultValue="left", enumeration="left,center,right,justify")]
		public var _align									:String = "left";
		[Inspectable 									(name="CHECK - Is Mandatory", type=Boolean, defaultValue=true)]
		public var _checkMandatory							:Boolean = true;
		[Inspectable 									(name="CHECK - Check", type=String, defaultValue="NEVER", enumeration="NEVER,TYPING,ON LOOSE FOCUS,ON CALL")]
		public var _check								:String = "NEVER";
		[Inspectable 									(name="CHECK - Check Mode", type=String, defaultValue="NONE", enumeration="NONE,PARAMS,SEQUENCE,PARAMS_SEQUENCE,EMAIL,ZIP,DATE,NUMBER,URL")]
		public var _checkType								:String = "NONE";
		[Inspectable 									(name="CHECK - Check Params", type=Array, defaultValue="Min Chars,Max Chars,Must Have,Must NOT Have")]
		public var _checkParams							:Array;
		[Inspectable 									(name="CHECK - Check Sequence", type=Array, defaultValue="Accepted values are:number (must be number) - or any character in position")]
		public var _checkSequence							:Array;
// ERROR CHECK ///////////////////////////////////////////////////////////////////////////////////////
		private function checkContentError					():void {
			_error									= false;
			if ((_checkMandatory && (isDefault() || isEmpty())) || this["hasError_"+_checkType]()) _error = true;
			updateColor								();
		}
			private function hasError_EMAIL					():Boolean {
				return								!Validator.check("EMAIL", text);
			}
			private function hasError_NONE					():Boolean {
				// This means I am checking a mandatory field, so just check if its mandatory and empty
				return								_checkMandatory && isEmpty();
			}
			private function hasError_PARAMS					():Boolean {
				var checkObj							:Object = {};
				if (_checkParams[0] && _checkParams[0] != "Min Chars") checkObj.minLength = uint(_checkParams[0]);
				if (_checkParams[1] && _checkParams[1] != "Max Chars") checkObj.maxLength = uint(_checkParams[1]);
				if (_checkParams[2] && _checkParams[2] != "Must Have")	checkObj.mustHave = _checkParams[2];
				if (_checkParams[3] && _checkParams[3] != "Must NOT Have") checkObj.mustNotHave = _checkParams[3];
					Debug.traceObject(checkObj);
				return								!Validator.check(checkObj, text);
			}
			private function hasError_SEQUENCE				():void {
				Debug.debug						(_debugPrefix, "SEQUENCE ERROR CHECK NOT YET DEFINED IN SUPERTEXTFIELD");
			}
			private function hasError_PARAMS_SEQUENCE				():void {
				Debug.debug						(_debugPrefix, "PARAMS_SEQUENCE ERROR CHECK NOT YET DEFINED IN SUPERTEXTFIELD");
			}
// GETTERS /////////////////////////////////////////////////////////////////////////////////////
		public function get textField							():TextField {
			return									_txt;
		}
		public function set text							(s:String):void {
			setText									(s ? s : "");
		}
		public function get text							():String {
			return									getText();
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function checkGroupOk					(id:String):Boolean { // Checks if a TAB group of textfields has no errors
			var ok									:Boolean = true;
			if (!_tabGroups[id]) {					
				Debug.debug							("SuperTextField.checkGroupOk()", "ERROR, tab group id <"+id+"> doesn't exist!!!");
				return								false;
			}
			var t										:SuperTextField;
			for each (t in _tabGroups[id])					if (t.isError()) ok = false; // I loop in all so that I can get error statuses
			return									ok;
		}
		public static function higlightGroupErrors					(id:String):void {
			if (!_tabGroups[id]) {					
				Debug.debug							("SuperTextField.higlightGroupErrors()", "ERROR, tab group id <"+id+"> doesn't exist!!!");
				return;
			}
			// This higlights and flashes textfields with errors
		}
		public static function callGroupMethod					():void {
			
		}
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC SWITCHES
		private static const HTML_STRIP_CHARS				:String = "<>"; // Just remove those 2 characters if _preventHtml == true;
 		private static const EMPTY_TEXT_ON_DEFAULT			:String = ""; // The text that gets inserted if when focusing there is no text
		private static const PREVENT_FULLSCREEN_INPUT_ERROR	:Boolean = false; // Does shit if I am in fullscreen
		private static const EXIT_FULLSCREEN_ON_FOCUS			:Boolean = false; // If textfield is input textfield, then exit fullscreen when input textfield gains focus (to prevent adobe safety measure)
		public static const EVT_COMMITCHANGES				:String = "onCommit"; // Commit change - exiting texfield after changing it
		public static const EVT_TEXTCHANGERETURN 			:String = "onChangedReturn"; // Hitting return with changed text
		public static const EVT_CHANGETEXT 					:String = "onChange"; // Typing
		public static const EVT_PRESSESC					:String= "onEsc"; // Pressing escape key
		public static const EVT_INPUTINFULLSCREEN 			:String = "onInputTextWhenFullScreen"; // When inputing a textfield in fullscreen (input text is prevented in fullscreen)
		public static const EVT_SETFOCUS					:String = "onSetFocus";
		public static const EVT_LOOSEFOCUS					:String = "onLooseFocus";
		// STATIC
		private static var _tabGroups						:Object = new Object();
		// USER VARIABLES
		private var _userMargins							:Array;
		// REFERENCES
// 		public var _vector								:Vector.<SuperTextField>;
		public var _txt									:TextField;
		public var _bg									:Sprite;
		public var _select								:Sprite;
		// MARKERS
		private var _defaultText							:String = "";
		private var _error								:Boolean; // This is used to check for mistakes
		private var _isPassword							:Boolean; // Stores if it is a password field, in order to remove password on default text, and set it back when user types
// INIT ////////////////////////////////////////////////////////////////////////////////////////////////
		public function SuperTextField						(par:Object=null) {
			super									("SuperTextField", par);
		}
		protected override function initAfterVariables				():void {
			UCode.setParameters							(_bg, {width:_w, height:_h});
			UCode.setParameters							(_select, {width:_w, height:_h});
			setTextMargins								(_defaultTextMargins);
			_bg.visible									=  _showBackground;
			_select.visible								= false;
			if (_txt.restrict is String && _txt.restrict.length == 0)	_txt.restrict = null;
			_txt.needsSoftKeyboard 						= true;
			activateListeners								();
			if (hasTab())								addToTabGroup();
			if (UText.exists(_lastText))						text = _lastText;
			else if (UText.exists(_userDefaultText))				setDefaultText(_userDefaultText);
			UText.setTextFormat							(_txt, {align:_align});
			setAutoPost								("_txt");
			super.initAfterVariables						();
		}
		private function addToTabGroup						():void {
			if (!_tabGroups[_tabGroup])						_tabGroups[_tabGroup] = new Array();
			_tabGroups[_tabGroup][_tabIndex]					= this;
			addInstanceToGroup							(_tabGroup);
		}
// FRAMEWORK METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
			UCode.setParameters							(_bg, {width:_w, height:_h});
			UCode.setParameters							(_select, {width:_w, height:_h});
			setTextMargins								(_defaultTextMargins);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setTextMargins						(a:Array):void {
			_userMargins								= a;
			for (var i:* in _userMargins)						_userMargins[i] = uint(_userMargins[i]);
			UCode.setParameters							(_txt, {y:_userMargins[0], x:_userMargins[2], height:(_h-(_userMargins[0]+_userMargins[1])), width:(_w-(_userMargins[2]+_userMargins[3]))});
		}
		public function setBlockTabbing						(b:Boolean):void {
			_blockTabbing								= b;
		}
		public function setDefaultText						(s:String):void {
			_defaultText								= s;
			restoreDefaultText							();
		}
		public function setText							(s:String):void {
			_lastText									= _txt.text;
			_txt.text									= s;
			UText.setTextFormat							(_txt, {color:_colorNorm});
		}
		public function selectAll							(e:*=null):void {
			_txt.setSelection								(0, _txt.text.length);
		}
		public function focus								():void {
			UGlobal.setFocus							(_txt);
		}
		public function focusAndSelectAll						(e:*=null):void {
			focus										();
			selectAll									();
		}
		public function clearFocus							():void {
			UGlobal.resetFocus							();
		}
		public function getText							():String {
			return									_txt.text == _defaultText ? "" : UText.stripSpaces(_txt.text);
		}
		public function getTextField							():TextField {
			return									_txt;
		}
		public function setTextFormat						(tf:*):void { // Object or TextFormat. Do not set color, it will be overridden by internal default colors
			UText.setTextFormat							(_txt, tf);
		}
		public function setActive							(a:Boolean):void {
			_txt.type									= a ? "input" : "dynamic";
			_txt.alpha									= a ? 1 : 0.4;
			_txt.selectable								= a;
		}
		public function updateColor							():void {
			if (_error)									setErrorColor();
			else if (isDefault())							setDefaultColor();
			else										setNormalColor();
		}
		public function setColor							(c:uint):void {
			UText.setTextFormat							(_txt, {color:c});
		}
		public function setDefaultColor						():void {
			setColor									(_colorDefault);
		}
		public function setNormalColor						():void {
			setColor									(_colorNorm);
		}
		public function setErrorColor							():void {
			setColor									(_colorError);
		}
		public function scrollParentToMe						(cb:ContentBox=null):void { // This tells a content box to scroll enough to make this TF visible...
			// If cb is not defined, it will try to look for one itself...
			if (!cb) { // finds the content box
				var c:*									= this;
				while (c.parent) {
					if (c.parent is ContentBox) {
						c.parent.scrollToShowContent		(this);
						return;
					}
					c								= c.parent;
				}
			}
			else										cb.scrollToShowContent(this);
		}
		public function restoreDefaultText					():void {
			_lastText									= null;
			_txt.text									= _defaultText;
			UText.resetScroll							(_txt);
			setDefaultColor								();
			_txt.displayAsPassword						= false;
		}
		public function hasTab								():Boolean {
			return									UText.exists(_tabGroup);
		}
	// CHECKS
		public function isError								():Boolean {
			checkContentError							();
			return									_error;
		}
		public function isDefault							():Boolean {
			return									_txt.text == _defaultText;
		}
		public function isEmpty							():Boolean {
			return									!UText.exists(UText.stripSpaces(text));
		}
		public function hasCheck							():Boolean {
			return									_check != "NEVER";
		}
		public function hasText(exactlyLikeDefault:Boolean=false):Boolean { // If it contains text and text is different from default text and or _lastText (this can also be called after setFocus())
			var txt									:String = getText();
			if (txt.length == 0)							return false; // There is no text
			// Check on default
			if (exactlyLikeDefault) { // Check if it is exactly like a default
				if (txt == _defaultText)					return false;
			}
			else if (_defaultText.length) { // check if they contain each other ONLY IF DEFAULT TEXT IS SET!
				if (_defaultText.indexOf(txt) != -1 || txt.indexOf(_defaultText) != -1) return false;
			}
			// Check on last text
			if (txt == _lastText)							return false;
			// We have some new text
			return									true;
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function broadcastCommitChange				():void {
			if (_txt.text != _lastText) {
				broadcastEvent							(EVT_COMMITCHANGES, this);
			}
			else										_txt.text = _lastText;
		}
		private function performAfterReturn					(e:*=null):void {
			// First I grab text from textfield, before setting all default behaviours
			var txt									:String = UText.stripSpaces(_txt.text);
			// 1.2 - EVT_TEXTCHANGERETURN is now triggered only if input text is different from previous, default, and it is not only spèaces
			if (txt.length && txt != _lastText && txt != _defaultText) {
				setText								(txt);
				broadcastEvent							(EVT_TEXTCHANGERETURN, this);
			}
			if (_reselectOnReturn)							focusAndSelectAll();
			else									 	clearFocus();
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		private function activateListeners						():void {
			_txt.addEventListener							(Event.CHANGE, onTextChange);
			_txt.addEventListener							(FocusEvent.FOCUS_IN, onSetMyFocus);
			_txt.addEventListener							(FocusEvent.FOCUS_OUT, onLooseMyFocus);
		}
		public function onTextChange						(e:Event=null):void {
			 if (_preventHtml) {
				if (HTML_STRIP_CHARS.indexOf(_txt.text.charAt(_txt.text.length-1)) != -1) {
					Debug.debug						(_debugPrefix, "Removed HTML special character.");
					setText							(_txt.text.substr(0, _txt.text.length-1));
				}
			}
			broadcastEvent								(EVT_CHANGETEXT, this);
		}
		public function onMyKeyDown						(e:KeyboardEvent):void {
			if (UKey.isEsc(e)) {
				if (_txt.text != _lastText) {
					if (_lastText)						setText(_lastText);
					else								restoreDefaultText();
					onTextChange						();
				}
				clearFocus								();
				broadcastEvent							(EVT_PRESSESC, this);
			}
			else if (UKey.isReturn(e) && !_txt.multiline) {
// 				trace("PREMO RETURN");
				UExec.next							(performAfterReturn);
			}
			else if (UKey.isTab(e)) {
				setTimeout								(afterTabActions, 10, e.shiftKey);
// 				UExec.next							(afterTabActions, e.shiftKey);
// 				setTimeout								(afterTabActions, 10, e.shiftKey);
// 				UCode.execNextMoment					(afterTabActions);
			} 
		}
		private function afterTabActions						(shiftPressed:Boolean=false):void {
			// If tab is bloccked, reselect. If index is -1, select nothing. If its a group, select next one.
			// If none of the 3, proceed with normal flash selection
			if (_blockTabbing)							focusAndSelectAll(); // Reselct this one if tabbing is blocked
			else if (_tabIndex < 0) 						stage.focus = null; // Select nothing if tabindex is -1
			else if (hasTab()) { // Here it selectes the next tabbed field
				var nextTf								:SuperTextField;
				if (shiftPressed) { // Tabbing with shift (backwards)
					if (_tabIndex > 0) 					nextTf = _tabGroups[_tabGroup][_tabIndex-1];
					else								nextTf = _tabGroups[_tabGroup][_tabGroups[_tabGroup].length-1];
				}
				else { // Normal tabbing (forward)
					if (_tabGroups[_tabGroup].length > (_tabIndex+1)) nextTf = _tabGroups[_tabGroup][_tabIndex+1];
					else								nextTf = _tabGroups[_tabGroup][0];
				}
				nextTf.focusAndSelectAll					();
				// Scroll content to my height
				nextTf.scrollParentToMe					();
			}
		}
		private function compareTabIndex						(t1:SuperTextField, t2:SuperTextField):int {
			return									t1._tabIndex < t2._tabIndex ? -1 : t1._tabIndex  > t2._tabIndex ? 1 : 0;
		}
		public function onSetMyFocus						(e:FocusEvent):void {
			if (_txt.type == "dynamic")						return;
			if (PREVENT_FULLSCREEN_INPUT_ERROR && UGlobal.isFullScreen()) {
				if (EXIT_FULLSCREEN_ON_FOCUS) {
					// Do not go now on focus, but do the fullscreen stuff and then reset focus
					UGlobal.resetFocus					();
					UGlobal.setFullScreen					(false);
 					// UExec.frame						(2, reselectAfterExitFullScreen); 
				}
				UGlobal.callSystem						(EVT_INPUTINFULLSCREEN, this);
				return; // Input focus selection is not working, so its useless to proceed, just notify system class
			}
			UText.setTextFormat							(_txt, {color:_colorNorm});
			_select.visible								= _showBackground;
			if (_clearOnSelect && _txt.text == _defaultText)		_txt.text = EMPTY_TEXT_ON_DEFAULT;
			else if (_autoSelect)							UExec.next(focusAndSelectAll);
			_txt.text									= UText.stripSpaces(_txt.text); // Added this in 2016 to prevent the unexplicable " " that fills text field
// 			else if (_autoSelect)							UExec.next(performAfterReturn);
			_txt.addEventListener							(KeyboardEvent.KEY_DOWN , onMyKeyDown);
			_txt.displayAsPassword						= _isPassword; // Grab password status from internal variable
			_txt.requestSoftKeyboard						();
			// 1.2 in order to check text really changed, I se _lastText here
			_lastText									= _txt.text;
			// Proceed broadcasting
			broadcastEvent								(EVT_SETFOCUS, this);
		}
// 			public function reselectAfterExitFullScreen			():void {
// 				focusAndSelectAll						();
// 			}
		public function onLooseMyFocus						(e:FocusEvent):void {
			if (_txt.type == "dynamic")						return; // It's not an input textfield, therefore all checks for input are disabled
			if (_clearOnSelect && (_txt.text == EMPTY_TEXT_ON_DEFAULT || _txt.text == "")) restoreDefaultText();
			_select.visible								= false;
			_txt.removeEventListener						(KeyboardEvent.KEY_DOWN , onMyKeyDown);
			if (_check == "ON LOOSE FOCUS")				checkContentError();
			broadcastCommitChange						();
			broadcastEvent								(EVT_LOOSEFOCUS, this);
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