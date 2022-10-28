
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
	
	import 											com.pippoflash.components._cBase;
	import											com.pippoflash.utils.*;
	import											com.pippoflash.motion.Animator;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	// COMPONENT ASSETS IMPORT
// 	import											PippoFlashAS3_Components_PippoFlashButton_Blue;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Default;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Empty;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Green;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Minimal;
// 	import											PippoFlashAS3_Components_PippoFlashButton_Tick;
// 	import											PippoFlashButton_SimpleRadio;
	
	
	public class PippoFlashButton extends _cBase {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		[Inspectable 									(name="Icon Attachment", type=String, defaultValue="NO ICON")]
		public var _iconAttachment							:String = "NO ICON"; // This decides an icon to be attached
		[Inspectable 									(name="Icon Frame", type=Number, defaultValue=1)]
		public var _iconFrame								:Number = 1; // This decides a frame of the icon to go
		[Inspectable 									(name="Icon positioning", type=String, defaultValue="LEFT", enumeration="LEFT,RIGHT,TOP,BOTTOM,CENTERED (no text)")]
		public var _iconPositioning							:String = "LEFT";
		[Inspectable 									(name="Icon Y Offset", type=Number, defaultValue=0)]
		public var _yIOff									:Number = 0;
		[Inspectable 									(name="Icon X Offset", type=Number, defaultValue=0)]
		public var _xIOff									:Number = 0;
		[Inspectable 									(name="Button Class Name", type=String, defaultValue="PippoFlashAS3_Components_PippoFlashButton_Default")]
		public var _buttonLinkage							:String = "PippoFlashAS3_Components_PippoFlashButton_Default";
		[Inspectable 									(name="Text", type=String, defaultValue="PippoFlash.com")]
		public var _text									:String = "PippoFlash.com";
		[Inspectable 									(name="Text Alignment", type=String, defaultValue="CENTER", enumeration="CENTER,JUSTIFY,LEFT,RIGHT")]
		public var _textAlign								:String = "CENTER";
		[Inspectable 									(name="Is Radio Group (overrides switch)", type=String)]
		public var _radioGroup								:String;
		[Inspectable 									(name="Is Switch", type=Boolean, defaultValue=false)]
		public var _switch								:Boolean = false;
		[Inspectable 									(name="Is HTML", type=Boolean, defaultValue=false)]
		public var _isHtml								:Boolean = false;
		[Inspectable 									(name="Force embed fonts", type=Boolean, defaultValue=true)]
		public var _embed								:Boolean = true;
		[Inspectable 									(name="Is Selected", type=Boolean, defaultValue=false)]
		public var _selected								:Boolean = false;
		[Inspectable 									(name="Text Size (0 for text field)", type=Number, defaultValue=0)]
		public var _textSize									:Number = 0;
		[Inspectable 									(name="Text Y Offset", type=Number, defaultValue=0)]
		public var _yOff									:Number = 0;
		[Inspectable 									(name="Text X Offset", type=Number, defaultValue=0)]
		public var _xOff									:Number = 0;
		[Inspectable 									(name="Margin", type=Number, defaultValue=4)]
		public var _textMargin								:Number = 4;
		[Inspectable 									(name="Status Change", type=String, defaultValue="SMOOTH", enumeration="SMOOTH,INSTANT")]
		public var _appearStyle							:String = "SMOOTH";
		[Inspectable 									(name="Double Click prevent millisecs", type=Number, defaultValue=500)]
		public var _doubleClickPreventOffset					:Number = 500; // How long it will wait before triggering a new click action
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		private static const VERBOSE						:Boolean = false;
// 		private static const NORMAL_BUTTON_BUTTONIZER_EVENTS	:String = "onPress,onRollOver,onRollOut,onRelease";
// 		private static const TOUCH_BUTTON_BUTTONIZER_EVENTS	:String = "onPress,onRelease";
		public static var SMOOTH_APPEAR_FRAMES				:int = 8;
		public static var _radioButtonGroups					:Array = new Array();
		public static var _radioGroupsList						:Object = new Object();
		public const _instanceList							:Array = ["_up","_over","_down","_sleep"];
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		public static var _horizAlign							:String;
		public static var _vertAlign							:String;
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
// 		private var _alpha_down							:Number;
// 		private var _alpha_over							:Number;
		private var _doubleMargin							:Number; // Stores _textMargin*2;
		private var _rect								:Rectangle;
		private var _appearFunction						:Function;
		private var _clickTimerOffset						:uint = 0; // Marks last click timer so that I can calculate if double click prevention worked. Set to 0, first click is always good.
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		protected var _button								:*;
		protected var _txt									:TextField;
		private var _icon									:MovieClip; // Stores the attached icon instance
		// MARKERS ////////////////////////////////////////////////////////////////////////
		protected var _isRadio								:Boolean = false;
		protected var _active								:Boolean = true;
// 		public var _isHtml								:Boolean = false; // This turns into true using setHtmlText
		// DATA ///////////////////////////////////////////////////////////////////////////////////////
		private var _toolTipText								:String;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function PippoFlashButton					(par:Object=null) {
			super									("PippoFlashButton", par);
		}
		protected override function initialize					():void {
			_appearFunction								= USystem.isDevice() ? appearInstant : _appearStyle == "SMOOTH" ? appearSmooth : appearInstant;
			_doubleMargin								= _textMargin*2;
			attachButtonGraphics							();
			setupButtonMode							();
			setText									(_text);
			super.initialize								();
		}
		private function attachButtonGraphics					() {
			UMem.addClassString							(_buttonLinkage);
			addAndSetupButton							(UMem.getInstanceId(_buttonLinkage));
		}
		private function setupButtonMode						():void {
			if (_radioGroup) {
				if (_radioGroupsList[_radioGroup] == undefined)	_radioGroupsList[_radioGroup] = new Array();
				_radioGroupsList[_radioGroup].push				(this);
				_isRadio								= true;
				_switch								= false; // Just to make sure both things don't overlap
			}
			if (_selected && (_isRadio || _switch)) setSelected(true);
			if (!UCode.exists(_cBase_eventPostfix)) setAutoPost("_butt");
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function addAndSetupButton					(c:*) {
			_button									= c;
			_button.name								= "PippoFlashButtonContent_" + UText.getRandomString(16);
			addChild									(c);
			setupButton								();
		}
		public function setToHtml							(v:Boolean):void { // Sets button to use html or not
			_isHtml									= v;
		}
		public function setText							(s:String, params:Object=null) {
			_text										= params ? UText.insertParams(s, params) : s;
			setTextInRectangle							();
		}
		public function setHtmlText						(s:String, params:Object=null) {
			_text										= params ? UText.insertParams(s, params) : s;
			_isHtml									= true;
			setTextInRectangle							();
		}
		public function getText							():String {
			return									_text;
		}
		public function getButtonClip							():Sprite {
			return									_button;
		}
		public function setSelected(s:Boolean=true) {
			if (!_isRadio && !_switch) return; // Only radio and switch can be set selected
			_selected = s;
			if (_button["_over"]) _button["_over"].visible = false;
			_button["_down"].visible = _selected;
			if (_isRadio && _selected) {
				for (var i:uint=0; i<_radioGroupsList[_radioGroup].length; i++) {
					if (_radioGroupsList[_radioGroup][i] != this)	_radioGroupsList[_radioGroup][i].setSelected(false);
				}
			}
			if (_selected) setTextDown();
			else setTextUp();
		}
		public function setActive							(b:Boolean) {
			_active									= b;
			if (_button) {
				_button.buttonMode						= b;
				_button.mouseEnabled						= b;
				_button["_sleep"].visible					= !b;
			}
		}
		public function toggleSelected						():void {
			setSelected									(!_selected);
		}
		public var setToolTip:Function = setTooltip;;
		public function setTooltip							(s:String):void {
			_toolTipText								= s;
		}
		public function clearTooltip							():void {
			_toolTipText								= null;
		}
		public function getTextFormat						():TextFormat { // Returns textofrmat of text field in button
			if (_txt)									return _txt.getTextFormat();
			else {
				Debug.warning							(_debugPrefix, "Requested TextFormat from button without TextField.");
			}
			return									null;
		}
		public function setTextFormat						(tf:*):void { // TextFormat or Object
			if (_txt) {
				UText.setTextFormat						(_txt, tf);
				setTextInRectangle						();
			}
			else {
				Debug.warning							(_debugPrefix, "Cannot set TextFormat from button without TextField.");
			}
		}
		public function getTextField						():TextField {
			if (_txt)									return _txt;
			else {
				Debug.warning							(_debugPrefix, "Cannot get getTextField() from button without TextField.");
				return								null;
			}
		}
	// TRIGGER EVENT
		public function triggerEvent							(evt:String="onPress"):void {
			Buttonizer.triggerButtonEvent					(_button);
		}
	// CHECKS
		public function isSelected							():Boolean {
			return									_selected;
		}
		public function isActive							():Boolean {
			return									_active;
		}
// FRAMEWORK METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public override function resize						(w:Number, h:Number):void {
			super.resize								(w, h);
			setupButton								();
			setTextInRectangle							();
			if (_selected)								setSelected(true);
		}
		public override function release						():void {
			super.release								();
		}
		public override function cleanup						():void {
			// Here I have to cleanup also for radiogroup. I remove myself, and if group is finished I remove group.
			if (_radioGroup) {
				UCode.removeArrayItem					(_radioGroupsList[_radioGroup], this);
				if (_radioGroupsList[_radioGroup].length == 0)	_radioGroupsList[_radioGroup] = null;
				_radioGroup							= null;
			}
			if (_icon) {
				UDisplay.removeClip						(_icon);
				_icon									= null;
			}
			if (_txt) {
				_txt.text								= "";
				_txt									= null;
			}
			Buttonizer.removeButton						(_button);
			UDisplay.removeClip							(_button);
			UMem.storeInstance							(_button);
			_button									= null;
			super.cleanup								();
		}
		public override function recycle						(par:Object=null):void {
			super.recycle								(par);
		}
// GETTERS/SETTERS ///////////////////////////////////////////////////////////////////////////////////////
		public function set text							(s:String) {
			setText									(s);
		}
		public function get text							():String {
			return									getText();
		}
// ICON PLACEMENT ///////////////////////////////////////////////////////////////////////////////////////
		private function positionForIcon						() {
			if (_icon)									UDisplay.removeClip(_icon);
			_icon										= UDisplay.addChild(this, UCode.getInstance(_iconAttachment)) as MovieClip;
			_icon.gotoAndStop							(_iconFrame);
			Buttonizer.setClickThrough						(_icon);
			// Resize icon
			if (_icon.height > _rect.height || _icon.width > _rect.width) {
				UDisplay.resizeSpriteTo					(_icon, _rect);
			}
			// Position icon
			if (_iconPositioning == "LEFT") {
				_horizAlign								= "LEFT";
				_vertAlign								= "MIDDLE";
				UDisplay.alignSpriteTo					(_icon, _rect, _horizAlign,_vertAlign);
				resetToRectangle							(new Rectangle(_icon.width+_doubleMargin,_textMargin,(_w-_icon.width)-(_textMargin*3),_h-_doubleMargin));
// 				_rect									= new Rectangle(_icon.width+_doubleMargin,_textMargin,(_w-_icon.width)-(_textMargin*3),_h-_doubleMargin);
			}
			else if (_iconPositioning == "CENTERED (no text)") {
				_horizAlign								= "CENTER";
				_vertAlign								= "MIDDLE";
				UDisplay.alignSpriteTo					(_icon, _rect, _horizAlign,_vertAlign);
				_txt.visible								= false;
			}
			else if (_iconPositioning == "RIGHT") {
				_horizAlign								= "RIGHT";
				_vertAlign								= "MIDDLE";
				UDisplay.alignSpriteTo					(_icon, _rect, _horizAlign,_vertAlign);
				resetToRectangle							(new Rectangle(_textMargin,_textMargin,(_w-_icon.width)-(_textMargin*3),_h-_doubleMargin));
// 				_rect									= new Rectangle(_textMargin,_textMargin,(_w-_icon.width)-(_textMargin*3),_h-_doubleMargin);
			}
			else if (_iconPositioning == "BOTTOM") {
				_horizAlign								= "CENTER";
				_vertAlign								= "BOTTOM";
				UDisplay.alignSpriteTo					(_icon, _rect, _horizAlign,_vertAlign);
				resetToRectangle							(new Rectangle(_textMargin,_textMargin,_w-_doubleMargin,(_h-_icon.height)-(_textMargin*3)));
// 				_rect									= new Rectangle(_textMargin,_textMargin,_w-_doubleMargin,(_h-_icon.height)-(_textMargin*3));
			}
			else if (_iconPositioning == "TOP") {
				_horizAlign								= "CENTER";
				_vertAlign								= "TOP";
				UDisplay.alignSpriteTo					(_icon, _rect, _horizAlign,_vertAlign);
				resetToRectangle							(new Rectangle(_textMargin,_icon.height+_doubleMargin,_w-_doubleMargin,(_h-_icon.height)-(_textMargin*3)));
// 				_rect									= new Rectangle(_textMargin,_icon.height+_doubleMargin,_w-_doubleMargin,(_h-_icon.height)-(_textMargin*3));
			}
			_icon.x									+= _xIOff;
			_icon.y									+= _yIOff;
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function setTextInRectangle					() {
			// Apply rectangle dimensions and overwrite rectangle positioning
			resetToRectangle								();
			// Proceed with dynamic size textfield
			setTextDynamicSize							();
			// Update text color
			updateTextColor								();
		}
				private function setTextDynamicSize			():void {
					if (VERBOSE)						Debug.debug(_debugPrefix, "Text goes out of button boundaries. Resizing and re-centering.");
					// Sets text with dynamically sized textfield that expands and then is centered
					if (!_txt)							return;
					// Reset from UText in order to restore size and else
					UText.resetTextFieldToOriginal			(_txt); // Reset textfield original properties in order oto reset it's size to original
					// Apply correct settings
					_txt.autoSize						= TextFieldAutoSize.CENTER;
					_txt.width							= _rect.width;
					// Proceed with alignment
					UText.setTextFormat					(_txt, {align:_textAlign.toLowerCase()});
					// Set properties
					_txt.embedFonts 					= _embed ? _embed : false;
					// Insert text
					if (_isHtml)						_txt.htmlText = _text;
					else								_txt.text = _text;
					// If text expands outside button proceed with second sizing using dynamic settings
					if (_txt.width > _rect.width || _txt.height > _rect.height) {
						setTextResizeToFit				();
					}
					// Text doesn't expand, just align textfield to rectangle
					else {
						UDisplay.alignSpriteTo			(_txt, _rect);
					}
					// Set offset in any case
					_txt.x							+= _xOff;
					_txt.y							+= _yOff;
				}
				private function setTextResizeToFit			():void {
					if (VERBOSE)						Debug.debug(_debugPrefix, "Text goes out of button boundaries. Resizing and re-centering.");
					// Remove autosize and reset textfield to it's original dimensions
					_txt.autoSize						= TextFieldAutoSize.NONE;
					UText.resetTextFieldToOriginal			(_txt); // Reset textfield original properties in order oto reset it's size to original
					if (_isHtml)						UText.setHtmlTextDynamicSize(_txt, _text);
					else								UText.setTextDynamicSize(_txt, _text);
					// Restore AutoSize so that TF can be centered
					_txt.autoSize						= TextFieldAutoSize.CENTER;
					UText.centerTextInOriginalRectangle		(_txt, false);
				}
		private function setupButton						() {
			// Setup _txt variable as first thing
			if (_button.hasOwnProperty("_txt")) {
				_txt = _button["_txt"];
				if (_textSize)							UText.setTextFormat(_txt, {size:_textSize});
			}
			// Proceed with rectangle according to margins
// 			_rect										= new Rectangle(_textMargin,_textMargin,_w-(_doubleMargin),_h-(_doubleMargin));
			resetToRectangle								(new Rectangle(_textMargin,_textMargin,_w-(_doubleMargin),_h-(_doubleMargin)));
			var b										:Sprite;
			for (var i:uint=0; i<_instanceList.length; i++) {
				UCode.setParameters(_button[_instanceList[i]], {width:_w, height:_h, visible:false});
			}
			Buttonizer.setupButton						(_button, this, "Button", USystem.isDevice() ? "onPress" : "onPress,onRollOver,onRollOut");
			if (_button["_up"]) _button["_up"].visible							= true;
			if (!_active)								setActive(_active);
			if (UCode.exists(_iconAttachment) && _iconAttachment != "NO ICON") positionForIcon();
			if (USystem.isDevice()) {
				// I can remove rollover state if is device
				UMem.killClip(_button["_over"]);
				_button["_over"] = null;
				delete _button["_over"];
			}
		}
		private function resetToRectangle						(rect:Rectangle=null):void { // Resets text to original _rect dimensions, and overwrites original settings
// 			trace("RESETTO A RECTANGLEEEEEEEEEEEEE",_rect,_txt);
			if (rect)									_rect = rect;
			_txt.x									= _rect.x;
			_txt.y									= _rect.y;
			_txt.width									= _rect.width;
			_txt.height									= _rect.height;
			UText.setTextFieldOriginalRectangle				(_txt, _rect); // Overwrites stored rectangle with computed one
		}
		private function appearSmooth						(c:DisplayObject, a:Boolean) {
			if (a) {
				Animator.fadeInTotal						(c, SMOOTH_APPEAR_FRAMES);
			}
			else	 									Animator.fadeOut(c, SMOOTH_APPEAR_FRAMES);
		}
		private function appearInstant						(c:DisplayObject, a:Boolean) {
			c.visible									= a;
		}
		private function doubleClickPrevented				():Boolean { // If timer for double click prevention is not expired from last click. If true, do NOT click.
			return									getTimer() < _clickTimerOffset;
		}
		private function updateDoubleClickTimer				():void { // Starts avain double click prevention timer
// 			_doubleClickPreventOffset _clickTimerOffset
			_clickTimerOffset							= getTimer() + _doubleClickPreventOffset;
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onPressButton(c:DisplayObject, isInternal:Boolean=false) { // This is to set button selected
			if (doubleClickPrevented()) {
				Debug.warning(_debugPrefix, "Press blocked. Double click prevention timer not elapsed.");
				return;
			}
			updateDoubleClickTimer();
			_appearFunction(_button["_down"], true);
			// Event is broadcasted immediately only on normal buttons, switch and radio broadcast on release, after changing _selected status
			if (!_isRadio && !_switch) broadcastEvent("onPress", this);
			UExec.time(0.1, onReleaseButton);
			if (_toolTipText) UGlobal.removeToolTip(this);
		}
		public function onRollOverButton(c:DisplayObject) {
			if (_toolTipText) UGlobal.setToolTip(true, _toolTipText, this);
			if (_selected) return;
			_appearFunction(_button["_over"], true);
			setTexRoll();
			broadcastEvent("onRollOver", this);
		}
		public function onRollOutButton						(c:DisplayObject) {
			if (_toolTipText)							UGlobal.removeToolTip(this);
			if (_selected)								return;
			_appearFunction							(_button["_over"], false);
			setTextUp									();
			broadcastEvent						("onRollOut", this);
		}
		public function onReleaseButton(j:*=null) { // I have put this parameter because once I had an error with "expected 0 received 1"
			if (_isRadio && _selected) return;
			if (_switch || (_isRadio && !_selected)) { // If radio or switch button gets selected or deselected
				setSelected(!_selected);
				// Let's try to broadcast next frame
				UExec.next(broadcastEvent, "onPress", this);
				//broadcastEvent("onPress", this);
				return;
			}
			// Otherwise continue normally
			_appearFunction							(_button["_down"], false);
			broadcastEvent							("onRelease", this);
			UGlobal.setToolTip							(false);
		}
	// TEXT COLORER TO BE OVERRIDDEN ///////////////////////////////////////////////////////////////////////////////////////
		protected function updateTextColor					():void {
			
		}
		protected function setTexRoll						():void {
			
		}
		protected function setTextUp						():void {
			
		}
		protected function setTextDown					():void {
			
		}
		protected function setTextSleep					():void {
			
		}
	}
	
	
	
}