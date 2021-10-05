package com.pippoflash.framework.starling.app 
{
	/**
	 * Gallery movable back and forth swiping.
	 * @author Pippo Gregoretti
	 */
	import com.pippoflash.framework.starling.StarlingGesturizer;
	import com.pippoflash.utils.Debug;
	import starling.display.DisplayObject;
	//import com.pippoflash.framework.starling.Transitioner;
	public class ContentSwiper extends ContentGallery 
	{
		//private var _transitioner:Transitioner;
		public function ContentSwiper(id:String="ContentSwiper", cl:Class=null)
		{
			//if (!cl) cl = getDefinitionByName(getQualifiedClassName(this))
			super(id, cl);
			StarlingGesturizer.addSwipe(this, onSwipe, "L,R");
		}
		private function onSwipe(target:DisplayObject, direction:String):void {
			//Debug.debug(_debugPrefix, "Swipe: " + par1, par2);
			if (direction == "R") previous();
			else next();
		}
		override protected function showImage(forward:Boolean = true):void {
			_images[_currentStep].swipeIn(.8, forward ? "L" : "R");
		}
	}

}