/* Gets a list of images, resizes and crops them, and can swipe between images keeping unordered list (they can be all the same, or just show 3 in order to allow swiping */


package com.pippoflash.visual {
	
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.visual.Image;
	import com.pippoflash.utils.*;
	import com.pippoflash.motion.Animator;
	import com.pippoflash.net.QuickLoader;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	
	public class Images extends Sprite {
		private static const _debugPrefix:String = "visual.Images";
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////////////
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC UTY ////////////////////////////////////////////////////////////////////////- These are to be reused instead of creating new temp vars
		protected static const _mover:PFMover = new PFMover("visual.Images");
		// USER VARIABLES ////////////////////////////////////////////////////////////////////////
  		// SYSTEM ///////////////////////////////////////////////////////////////////////////
		protected var _rect:Rectangle;
		protected var _externalImages:Vector.<DisplayObject>;
		protected var _imgs:Vector.<Image>;
 		// REFERENCES ////////////////////////////////////////////////////////////////////////
		// MARKERS ////////////////////////////////////////////////////////////////////////
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function Images(rect:Rectangle) {
			_rect = rect;
			UMem.addClass(Image);
			addChild(UDisplay.getSquareSprite(_rect.width, _rect.height, 0xff0000));
			alpha = 0.5;
			x = _rect.x;
			y = _rect.y;
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setDisplayObjects(extImgs:Vector.<DisplayObject>, startIndex:int=0):void {
			// Release if there is an image
			release();
			// Sets up a display object within image
			_externalImages = extImgs;
			// Create images
			var img:Image;
			for (var i:int = 0; i < _externalImages.length; i++) {
				img = UMem.getInstance(Image, _rect);
				img.setDisplayObject(_externalImages[i]);
				img.x = _rect.width * i;
			}
			setToImage(startIndex);
		}
		public function setToImage(index:int):void { // Sets to a single image
			for each (var img:Image in _imgs) UDisplay.removeClip(img);
			_imgs[index].x = 0;
			addChild(_imgs[index]);
		}
		public function release():void {
			if (_imgs) for each (var img:Image in _imgs) UMem.storeInstance(img);
			_imgs = null;
			_externalImages = null;
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}