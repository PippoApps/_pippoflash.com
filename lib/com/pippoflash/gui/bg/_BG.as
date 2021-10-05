/* the _BG class is extensible. It provides a bg for anything, from flat color to image to sequence of images. */


package com.pippoflash.gui.bg {
	

	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UDisplay;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class _BG extends Sprite {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		protected var _color								:uint;
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		protected var _bg								:Sprite;
		// MARKERS ////////////////////////////////////////////////////////////////////////
// INIT ///////////////////////////////////////////////////////////////////////////////////////

		public function _BG								(col:uint=0, rect:Rectangle=null) {
			visible									= false;
			if (!_bg) {									_bg = UDisplay.getSquareSprite();
				addChild								(_bg);
			}
			setColor									(col);
			if (rect)									resize(rect);
			else 										UGlobal.callOnStage(resizeToStage);
		}
		public function resizeToStage						():void {
			resize									(UGlobal.getStageRect());
		}
		public function update								(r:Rectangle, col:uint):void {
			resize									(r);
			setColor									(col);
		}
		public function resize								(r:Rectangle):void {
			UDisplay.resizeToRect							(_bg, r);
			visible									= true;
		}
		public function setColor							(col:uint):void {
			_color									= col;
			UDisplay.setClipColor							(_bg, col);
		}
		
// METHODS //////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
// RESIZE ///////////////////////////////////////////////////////////////////////////////////////
		public function onResize					():void {
			resizeToStage						();
		}
	}
}