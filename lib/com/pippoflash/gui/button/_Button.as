/* _Button - Base class for all Buttons
*/

package com.pippoflash.gui.button {
	
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UCode;
	import 											com.pippoflash.utils.UEffect;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	
	public dynamic class _Button extends MovieClip {
		// STATIC ////////////////////////////////////////////////////////////////////////////////
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		public static var _debugPrefix						:String = "_Button";
		public static var _isTouchDevice						:Boolean = false;
		// USER VARIABLES
		// REFERENCES
// 		public var _txt									:TextField;
// 		public var _size									:Point;
		public var _bg									:DisplayObject;
		public var _w									:Number;
		public var _h									:Number;
		// MARKERS		
		public var _txt									:TextField;
// 		public var _shield									:MovieClip;

// INIT ////////////////////////////////////////////////////////////////////////////////////
		public function _Button							(par:Object=null) {
			if (par)									for (var s:String in par) this[s] = par[s];
		}
// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function setToTouchDevice					(t:Boolean=true):void {
			_isTouchDevice								= t;
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setText							(s:String, f=null) {
			_txt.text 									= s;
			if (f)										UText.setTextFormat(_txt, f);
			setSize									(width, height);
		}
		public function setSize							(w:Number, h:Number):void {
			_w = w; _h = h; scaleX = scaleY = 1; resize(_bg);
			_txt.width = _w; _txt.x = 0; UDisplay.centerToArea(_txt, _w, _h);
		}
		public function resize								(c):void {
			// This is called on each frame of the button. REMEMBER to place the resize() on each frame of button
// 			trace(currentFrame);
// 			_bg.visible = false;
			c.width = _w; c.height = _h;
// 			_bg.visible = true;
// 			_bg.visible = false;
// 			_bg.visible= true;
// 			addChild(_bg); addChild(_txt);
		}
// STATUSES /////////////////////////////////////////////////////////////////////////////////////////
		// I cannot resize a different clip in another frame, because of absurd behaviours in flash. It triggers strange errors. If I call and resize the clip with the same name it only shows the first one. Horrible.
		// So I need to call IN FRAME setUp() setOver() setDown() - Horrible, but it works...
		public function setUp								():void {
			UEffect.clear								(_bg);
// 			trace("SETUP");
		}
		public function setOver							():void {
			UEffect.setBrightness							(_bg, -50);
		}
		public function setDown							():void {
			UEffect.setBrightness							(_bg, -50);
		}
		public function setSelected							(s:Boolean):void {
			if (s)										setDown();
			else										setUp();
		}
		// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}