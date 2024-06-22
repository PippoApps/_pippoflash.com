package com.pippoflash.movieclips.loaders 
{
	import flash.events.Event;
	import com.pippoflash.motion.PFMover;
	import com.pippoflash.utils.UDisplay;
	import com.pippoflash.utils.Debug;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * Extend this class for an animation with several images each in one frame (imported from online anim gifs)
	 * @author Pippo Gregoretti
	 */
	public class _LoaderBaseFullScreen extends _LoaderBase 
	{
		private static const FADE_TIME:Number = 1;
		private var _removeCallback:Function;
		public function _LoaderBaseFullScreen(id:String=null, cl:Class=null) 
		{
			super(id);
			alpha = 0;
		}
		override public function show(instant:Boolean = true, txt:String = "", onArrived:Function=null):void 
		{
			//super.show(instant, txt);
			startAnim();
			visible = true;
			setText(txt);
			//alpha = 1;
			//return;
			PFMover.instance.fade(this, FADE_TIME, 1, onArrived);
		}
		override public function hide(instant:Boolean = true, onHidden:Function=null):void 
		{
			_onHidden = onHidden;
			PFMover.instance.fade(this, FADE_TIME, 0, remove);
		}
		private var _onHidden:Function;
		private function remove():void {
			stopAnim();
			UDisplay.removeClip(this);
			if (_onHidden) _onHidden();
			_onHidden = null;
		}
		override public function startAnim():void 
		{
			//super.startAnim();
			play();
			//addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		override public function stopAnim():void 
		{
			stop();
			//super.stopAnim();
			//removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		//private function onEnterFrame(e:Event):void {
			//stop();
		//}
		override public function setText(t:String):void 
		{
			super.setText(t);
			if (this["_txt"]) this["_txt"].text = t;
		}
		//override public function setStageShield(shield:Boolean=true):void {
			//if (this["_shield"]) {
				//this["_shield"].update();
				//this["_shield"].visible = true;
				//this["_shield"].alpha = 1;
			//}
		//}
	}

}