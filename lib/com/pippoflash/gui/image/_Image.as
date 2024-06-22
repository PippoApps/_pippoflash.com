/* the _BG class is extensible. It provides a bg for anything, from flat color to image to sequence of images. */


package com.pippoflash.gui.image {
	

	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UGlobal;
	import											com.pippoflash.utils.UDisplay;
	import											com.pippoflash.motion.Animator;
	import											com.pippoflash.net.QuickLoader;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class _Image extends MovieClip {
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		protected var _color								:uint;
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
		protected var _halign								:String = "CENTER";
		protected var _valign								:String = "MIDDLE";
		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		public var _debugPrefix								:String = "_Image";
		protected var _rect								:Rectangle;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		protected var _bg								:Sprite;
		protected var _img								:*;
		// MARKERS ////////////////////////////////////////////////////////////////////////
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function _Image								(color:uint=0, rect:Rectangle=null) {
			_bg										= UDisplay.getSquareSprite();
			addChild									(_bg);
			_rect										= rect ? rect : UGlobal.getStageRect();
			_color									= color;
			updateBg									();
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function resizeToStage						():void {
			_rect 									= UGlobal.getStageRect(); 
			y = UGlobal._y; x = UGlobal._x;
			updateBg									();
			if (_img)									alignImage(_img);
		}
		public function updateBg							():void {
			_bg.width = _rect.width; _bg.height = _rect.height;
			UDisplay.setClipColor							(_bg, _color);
			addChildAt									(_bg, 0);
			_bg.visible = false;
		}
		public function loadImage							(u:String, h:String="CENTER", v:String="MIDDLE"):void {
			_halign = h; _valign = v; QuickLoader.loadFile(u, this);
		}
		public function alignImage							(img:Bitmap, h:String="CENTER", v:String="MIDDLE"):void {
			UDisplay.resizeSpriteTo						(img, _bg, "CROP-RESIZE", true);
			UDisplay.alignSpriteTo							(img, _bg, _halign, _valign);
		}
		public function onResize							():void {
			updateBg									();
			alignImage									(_img);
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		protected function setupImage						(img:Bitmap):void {
			img.smoothing								= true;
			alignImage									(img, _halign, _valign);
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		public function onLoadComplete						(o:Object):void {
			_img										= o.getContent();
			addChild									(_img);
			setupImage									(_img);
			Animator.fadeInTotal							(_img, 20);
		}
	}
}