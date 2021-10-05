/* _LoaderBase - (c) Filippo Gregoretti - PippoFlash.com */
/* This is the base class for all Loaders */

package com.pippoflash.movieclips.loaders {
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.UExec;
	import									com.pippoflash.movieclips.loaders._LoaderBase;
	import									flash.display.*;
	import									flash.text.*;
	import									flash.events.*;
	
	public dynamic class CircleLoader extends _LoaderBase {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		// SYSTEM
		// USER VARIABLES
		// REFERENCES
		// MARKERS
		// DATA HOLDERS
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function CircleLoader					() {
			super							();
		}
		public function rotateMyself					(e:Event) {
			_rotator.rotation 						+= 4;
		}
// RENDER //////////////////////////////////////////////////////////////////////////////////////////
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public override function setText				(t:String):void {
			super.setText						(t);
			_txt.text							= _text;
		}
		public override function setPercent(n:Number):void {
			//trace("PERCENT " + n);
			super.setPercent(n);
			_txtPercent.text = n ? Math.floor(n)+"%" : "";
		}
		//protected override function appear				(instant:Boolean=true, onArrived:Function=null):void {
			//visible							= true;
		//}
		//protected override function disappear			(instant:Boolean=true, onComplete:Function=null):void {
			//visible							= false;
		//}
		public override function stopAnim				():void {
			super.stopAnim						();
			UExec.removeEnterFrameListener			(rotateMyself);	
		}
		public override function startAnim				():void {
			super.startAnim						();
			UExec.addEnterFrameListener			(rotateMyself);	
		}
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}