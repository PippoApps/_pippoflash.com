/* the _BG class is extensible. It provides a bg for anything, from flat color to image to sequence of images. */


package com.pippoflash.gui.bg {
	

	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.motion.Animator;
	import											com.pippoflash.net.QuickLoader;
	import											com.pippoflash.gui.bg._BG;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class BGImage extends _BG {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		private var _halign								:String;
		private var _valign								:String;
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		protected var _img								:Bitmap;
		// MARKERS ////////////////////////////////////////////////////////////////////////
// INIT ///////////////////////////////////////////////////////////////////////////////////////

		public function BGImage							(color:uint=0, rect:Rectangle=null) {
			super									(color, rect);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function loadImage							(u:String, h:String="CENTER", v:String="MIDDLE"):void {
			_halign = h; _valign = v; QuickLoader.loadFile(u, this);
		}
		public function alignImage						(h:String="CENTER", v:String="MIDDLE"):void {
			UDisplay.alignSpriteTo						(_img, _bg, _halign, _valign);
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onLoadComplete					(o:Object) {
			_img										= o.getContent();
			_img.smoothing								= true;
			addChild									(_img);
			UDisplay.resizeSpriteTo						(_img, _bg, "CROP-RESIZE", true);
			alignImage								(_halign, _valign);
			Animator.fadeInTotal						(_img, 20);
		}
	}
}
