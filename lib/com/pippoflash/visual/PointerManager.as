/* PointerManager - (c) Filippo Gregoretti - PippoFlash.com */
/* Changes the mouse pointer with custom movieclips

PointerManager.change(myClip);
PointerManager.restore();

*/

package com.pippoflash.visual {
	import com.pippoflash.visual.PointerManager;
	import									com.pippoflash.utils.UCode;
// 	import									com.pippoflash.utils.Debug;
	import									com.pippoflash.utils.UGlobal;
	import									com.pippoflash.utils.UDisplay;
	import									com.pippoflash.utils.Buttonizer;
	import									flash.display.*;
	import									flash.geom.*;
	import									flash.ui.Mouse;
	import									flash.events.*;
	import									flash.system.*;
	import									flash.display.*;
	
	
	public dynamic class PointerManager {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
// 		private static var _debugPrefix				:String = "PointerManager";
		// SYSTEM - USER DEFINABLE
		// USER VARIABLES
		// REFERENCES
		private static var _mousePointer				:*;
		private static var _stage					:Stage;
		// MARKERS
		// DATA HOLDERS
		private static var _infoObject				:Object;
		// UTY
		public static var _i						:int;
		public static var _n						:Number;
		public static var _s						:String;
		public static var _c						:DisplayObject;
// INIT //////////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public static function change				(c:*):void {
			if (_mousePointer)					restore();
			Mouse.hide						();
			_mousePointer						= c;
			_stage							= UGlobal.stage;
			_stage.addChild						(_mousePointer);
			_mousePointer.visible					= true;
			Buttonizer.setClickThrough				(_mousePointer);
			UCode._dummyClip.addEventListener		(Event.ENTER_FRAME, positionPointer);
		}
		public static function restore					():void {
			Mouse.show						();
			UCode._dummyClip.removeEventListener		(Event.ENTER_FRAME, positionPointer);
			_mousePointer.visible					= false;
			UDisplay.removeClip					(_mousePointer);
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
		public static function positionPointer			(e:Event):void {
			_mousePointer.x						= _stage.mouseX;
			_mousePointer.y						= _stage.mouseY;
		}
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}