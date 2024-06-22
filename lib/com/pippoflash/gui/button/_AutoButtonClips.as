 /* _AutoButtonClips - Base class for all Buttons which are not instantiated in timeline but exported.
var b = new _AutoButtonClips("text", new MyButton());
MyButton must adhere to the button bases
*/

package com.pippoflash.gui.button {
	
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.UCode;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	
	public dynamic class _AutoButtonClips extends MovieClip {
		public static var _debugPrefix						:String = "_AutoButtonClips";
		private static var _useHtml							:Boolean = false;
		private static var _setTextFunction					:Function = UText.setTextNormal;
		// STATIC - FOOL COMPILER
		// USER VARIABLESasd
		// REFERENCES
		private var _buttonClip								:MovieClip; // The button clip containing the thing
		// FOOL COMPILER - Vars are defined like instance var in superclass. Here I define them static not to interfere.
		// MARKERS	
		private var _selected								:Boolean = false;
		// System
		
// STATIC FUNCTIONS ///////////////////////////////////////////////////////////////////////////////////////
		public static function setToHtml						(b:Boolean):void {
			_useHtml									= b;
			_setTextFunction								= b ? UText.setTextHtml : UText.setTextNormal;
		}
// INIT ////////////////////////////////////////////////////////////////////////////////////
		public function _AutoButtonClips						(c:MovieClip, listener:*=null, funcPost:String="", actions:String="onPress") {
			initialize									(c, listener, funcPost, actions);
		}
		public function recycle								(c:MovieClip, listener:*=null, funcPost:String="", actions:String="onPress"):void {
			initialize									(c, listener, funcPost, actions);
		}
			private function initialize						(c:MovieClip, listener:*=null, funcPost:String="", actions:String="onPress"):void {
				_buttonClip = c; _buttonClip._press.visible = _buttonClip._roll.visible = false;
				_buttonClip.setOver = setOver; _buttonClip.setUp = setUp; _buttonClip.setDown = setDown;
				addChild								(_buttonClip);
				if (listener)								Buttonizer.setupButton(_buttonClip, listener, funcPost, actions);
			}
		public function cleanup							():void {
			UCode.callMethod							(_buttonClip, "cleanup");
			harakiri									();
		}
		public function harakiri								():void {
			if (_buttonClip) {
				delete _buttonClip.setOver; delete _buttonClip.setUp; delete _buttonClip.setDown; 
				Buttonizer.removeButton					(_buttonClip);
				UDisplay.removeClip						(_buttonClip);
				_buttonClip								= null;
			}
		}
		// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setText						(s:String, varSize:Boolean=true, f:*=null) {
			if (f)									UText.setTextFormat(_buttonClip._txt, f);
			_buttonClip._txt.multiline					= true;
			_buttonClip._txt.mouseWheelEnabled			= false;
			_setTextFunction							(_buttonClip._txt, s);
			if (varSize)	{
				_buttonClip._txt.autoSize				= "left";
				setSize							(_buttonClip._txt.width + (_buttonClip._txt.x*2), _buttonClip._txt.height + (_buttonClip._txt.y*2));
			}
			else {
				_buttonClip._txt.width					= _buttonClip._bg.width - _buttonClip._txt.x*2;
			}
		}
		public function setTextVert						(s:String, varSize:Boolean=false, f:*=null) {
			if (f)									UText.setTextFormat(_buttonClip._txt, f);
			_buttonClip._txt.text						= "";
			_buttonClip._txt.height	= _buttonClip._bg.height = _buttonClip._roll.height = _buttonClip._press.height = 0;
			_buttonClip._txt.multiline					= true;
			_buttonClip._txt.wordWrap					= true;
			_buttonClip._txt.autoSize					= "center";
			_setTextFunction							(_buttonClip._txt, s);
			_buttonClip._txt.y = 3;
			setSize								(_buttonClip._txt.width + (_buttonClip._txt.x*2), height+_buttonClip._txt.y);
		}
		public function setSize						(w:Number, h:Number):void {
			scaleX = scaleY = 1; 
			w = Math.round(w); h = Math.round(h);
			_buttonClip._bg.width = _buttonClip._roll.width = _buttonClip._press.width = w;
			_buttonClip._bg.height = _buttonClip._roll.height = _buttonClip._press.height = h;
		}
		public function setUp						():void {
			_buttonClip._roll.visible = _buttonClip._press.visible = false;
		}
		public function setOver						():void {
			_buttonClip._roll.visible = true; _buttonClip._press.visible = false;
		}
		public function setDown						():void {
			_buttonClip._press.visible = true;
		}
		public function setSelected					(s:Boolean):void {
			_selected = _buttonClip._press.visible = s;
		}
	}
	
	
	
}