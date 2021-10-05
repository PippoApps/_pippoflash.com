/* Shows an image and centers it. Grabs either a BMP or a movieclip. */


package com.pippoflash.visual {
	

	import											com.pippoflash.utils.*;
	import											com.pippoflash.motion.Animator;
	import											com.pippoflash.net.QuickLoader;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	import 											flash.geom.*;
	
	public class Image extends Sprite {
		private static const _debugPrefix:String = "visual.Image";
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
  		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		protected var _rect:Rectangle;
		protected var _img:DisplayObject;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		// MARKERS ////////////////////////////////////////////////////////////////////////
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function Image(rect:Rectangle) {
			_rect = rect;
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setDisplayObject(c:DisplayObject, resize:String = "FILL"):void {
			// Release if there is an image
			release();
			// Sets up a display object within image
			if (resize == "FILL") { 
				// Larger than taller, set height
				c.height = _rect.height;
				c.scaleX = c.scaleY;
				var myRect:Rectangle = new Rectangle(Math.round((_rect.width - c.width)/2), _rect.width, 0 , _rect.height);
				// If taller than larger, use width
				if (c.width < _rect.width) {
					c.width = _rect.width;
					c.scaleY = c.scaleX;
					// Setup masking based on larger height
					myRect = new Rectangle(0, _rect.width,  Math.round((_rect.height - c.height) / 2), _rect.height);
				}
				// Setup masking and offset
				c.scrollRect = myRect;
			}
			else Debug.error(_debugPrefix, "Only FILL is implemented as resize. Not possible: " + resize);
			_img = c;
			addChild(_img);
		}
		public function release():void {
			if (_img) {
				UDisplay.removeClip(_img);
				_img.scrollRect = null;
				_img.scaleX = _img.scaleY = 1;
				_img = null;
			}
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}