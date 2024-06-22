package com.pippoflash.motion {
	import											com.pippoflash.utils.UMem;
// 	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.utils.UText;
	import											com.pippoflash.utils.UMem;
	import 											com.greensock.*;
	import 											com.greensock.easing.*;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	
	public class AnimatorMax {
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		public static var _endMotionList						:Object = new Object();
		// USER VARIABLES
		// REFERENCES
		// MARKERS
		
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		// UTY ///////////////////////////////////////////////////////////////////////////////////////
		
		// JUMP ///////////////////////////////////////////////////////////////////////////////////////
		public static function jumpIn							(c:DisplayObject, fadeTime:Number=1, delay:Number=0):void {
// 			c.visible									= true;
			var bgTrans								:Object = {delay:delay, startAt:{scaleX:0.1, scaleY:0.1, visible:true}, scaleX:1, scaleY:1, ease:Elastic.easeOut};
			TweenMax.to								(c, fadeTime, bgTrans);
		}
		// FADE ///////////////////////////////////////////////////////////////////////////////////////
		public static function fadeIn							(c:DisplayObject, fadeTime:Number=1, delay:Number=0):void {
			TweenMax.to								(c, fadeTime, {delay:delay, alpha:1, ease:Linear.easeNone});
		}
		public static function move							(c:DisplayObject, par:Object, fadeTime:Number=1, delay:uint=0):void {
			TweenMax.to								(c, fadeTime, par);
		}
// SEQUENCES ///////////////////////////////////////////////////////////////////////////////////////
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// END MOTION ACTIONS ////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
}