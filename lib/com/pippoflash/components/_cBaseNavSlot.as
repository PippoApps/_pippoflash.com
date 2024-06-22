/* _cBaseNav - Is a base class for menu items with advanced properties and functions.
This can be extended directly in the library.
*/
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.components {
// 	import											com.pippoflash.utils.UCode;
// 	import											com.pippoflash.utils.Buttonizer;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.motion.Animator;
	import											com.pippoflash.motion.PFMover;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public dynamic class _cBaseNavSlot extends MovieClip {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		private static var _textMargin						:uint = 30;
		private static var _textOffsetV						:uint = 3;
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		// DATA HOILDERS ///////////////////////////////////////////////////////////////////////////////////////
		public var _node									:XML;
		public var _w									:Number;
		// MARKERS ////////////////////////////////////////////////////////////////////////
		public var _selected								:Boolean = false;
// INIT ///////////////////////////////////////////////////////////////////////////////////////

		public function _cBaseNavSlot						() {
			_txt.alpha = _roll.alpha = _sel.alpha 				= 0;
			_txt.autoSize								= "left";
			resetVisible									();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function fadeIn								():void {
			resetVisible									();
			Animator.fadeIn								(_txt, 20);
			_bg.width									= 0;
			PFMover.slideIn							(_bg, {steps:10, pow:2, endPos:{width:_w, alpha:1}});
			setSelected								(_selected);
		}
		public function fadeOut							():void {
			Animator.fadeOut							(_txt, 20);
			PFMover.slideIn							(_bg, {steps:10, pow:2, endPos:{width:0, alpha:0}});
			PFMover.slideIn							(_roll, {steps:10, pow:2, endPos:{width:0, alpha:0}});
			PFMover.slideIn							(_sel, {steps:10, pow:2, endPos:{width:0, alpha:0}});
		}
		public function rollOver								():void {
			PFMover.slideIn							(_roll, {steps:10, pow:2, endPos:{width:_w, alpha:1}});
		}
		public function rollOut								():void {
			PFMover.slideIn							(_roll, {steps:4, pow:2, endPos:{width:0, alpha:0}});
		}
		public function setSelected							(sel:Boolean=true):void {
			if (sel)									PFMover.slideIn(_sel, {steps:10, pow:2, endPos:{width:_w, alpha:1}});
			else										PFMover.slideIn(_sel, {steps:10, pow:2, endPos:{width:0, alpha:0}});
			_selected									= sel;
		}
		public function setSize							(w:Number, h:Number):void {
			_w										= w;
			_bg.width = _roll.width = _sel.width = _top.width = w; 
			_bg.height = _roll.height = _sel.height = _top.height = h; 
			UDisplay.centerV(_txt, h); UDisplay.centerH(_txt, w);
			_txt.y += _textOffsetV;
		}
		public function setAutoSize							(h:Number):void { // Sets size based on text width
			setSize									(_txt.textWidth+_textMargin, h);
		}
		public function setText							(s:String):void {
// 			_txt.html 									= true;
			_txt.htmlText								= s;
			UText.setTextFormat							(_txt, {letterSpacing:1});
		}
// GETTERS/SETTERS ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function resetVisible							():void {
			_txt.alpha = _roll.alpha = _sel.alpha 				= 0;
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}