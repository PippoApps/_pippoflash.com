/* _LoaderBase - (c) Filippo Gregoretti - PippoFlash.com */
/* This is the base class for all Loaders */

package com.pippoflash.movieclips.widgets {
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.UDisplay;
	import									com.pippoflash.utils.UGlobal;
	import									com.pippoflash.motion.PFMover;
	import									flash.geom.*;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.net.*;
	import									flash.events.*;
	import 									flash.utils.*;
	
	public dynamic class TextPop extends Sprite {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		private static var _marginX					:Number = 30;
		private static var _marginY					:Number = 60;
		// SYSTEM
		private var _w, _h, _margin:Number;
		// USER VARIABLES
		// REFERENCES
		// MARKERS
		private var _isOpen						:Boolean = false;
		private var _targX						:Number;
		private var _targY						:Number;
		// DATA HOLDERS
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function TextPop					() {
			_w = width; _h = height; _margin = _txt.x; _txt.autoSize = "center"; UGlobal.addResizeListener(onResize);
		}
// RENDER //////////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setText					(t:String):void {
			_txt.text							= t;
			resize							();
		}
		public function setHtmlText					(t:String):void {
			_txt.text							= t;
			resize							();
		}
		public function show						():void {
			_isOpen							= true;
			PFMover.slideIn					(this, {steps:8, pow:3, endPos:{x:_targX}});
		}
		public function hide						():void {
			_isOpen							= false;
			PFMover.slideIn					(this, {steps:4, pow:3, endPos:{x:UGlobal._sw+20}});
		}
		public function onResize					(e:*=null):void {
			_targX 							= UGlobal._sw - (_bg.width+_marginX);
			_targY 							= UGlobal._sh - (_bg.height+_marginY);
			if (_isOpen) {
				x = _targX; y = _targY;
			}
			else {
				x = UGlobal._sw + 20; y = _targY;
			}
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		private function resize						():void {
			_txt.x = _txt.y 						= _margin; 
			_bg.width 							= _txt.width + _margin*2;
			_bg.height 							= _txt.height + _margin*2;
			onResize							();
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}