
/* _LoaderBase - (c) Filippo Gregoretti - PippoFlash.com */
/* This is the base class for all Loaders */
/* INCOMPLETO!!!! E' stato cambiato con il renderer si può anche cancellare */

package com.pippoflash.movieclips.widgets {
	import com.pippoflash.utils.*;
	import com.pippoflash.framework._PippoFlashBase;
	import com.pippoflash.motion.Animator;
	import flash.display.*;
	import com.pippoflash.utils.UCode;
	import flash.display.Sprite;
	import flash.html.__HTMLScriptArray;
	import com.pippoflash.framework._Application;
	import com.pippoflash.utils.UGlobal;
	import starling.core.starling_internal;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UDisplay;
	import com.pippoflash.motion.PFMover;
	import flash.text.TextField;

	
	
	public dynamic class MovieClipFrameStepper extends _PippoFlashBase {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		public static var _fadeInFrames:uint = 60;
		public static var _fadeOutFrames:uint = 30;
		public static const EVT_FRAMESTEP:String = "onClipStepperFrameStep"; // When a new step is rendered (0 to ...)
		public static const EVT_FRAMEFINISH:String = "onClipStepperFrameFinish"; // When the last step is clicked
		// SYSTEM
		private var _clip:MovieClip;

		private function get clip():MovieClip
		{
			return _clip;
		}
		private var _resizeToScreen:Boolean;
		private var _advanceOnClick:Boolean;
		private var _advanceOnTime:Boolean;
		protected var _millisecondsToAdvance:Number = 5000;
		private var _timer:Timer = new Timer(0, 1);
		private var _targetFrame:uint;
		private var _elapsedFrames:uint;
		private var _frameTextContent:Array; // Each slot contains an object with textfield name and text content
		// USER VARIABLES
		// REFERENCES
		// MARKERS
		private var _activeFrame:uint;
		private var _active:Boolean;
		protected function get activeFrame():uint
		{
			return _activeFrame;
		}

		// DATA HOLDERS
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function MovieClipFrameStepper(movieClipId:String, id:String="MovieClipFrameStepper", resizeToScreen:Boolean=true) {
			super(id, MovieClipFrameStepper);  
			_clip = UCode.getInstance(movieClipId);
			_resizeToScreen = resizeToScreen;
			_timer.addEventListener(TimerEvent.TIMER, onTimerElapsed);
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function setupTextContent(framesTextFields:Array):void { // Sets text content for each frame
			_frameTextContent = framesTextFields;
		}
		public function clearTextContent():void {
			
		}
		public function showOnRoot():void {
			UGlobal.stage.addChild(_clip);
			_clip.alpha = 0;
			_clip.gotoAndStop(1);
			_activeFrame = 0;
			_elapsedFrames = 0;
			_targetFrame = 1;
		}
		public function freeze():void {
			_active = false;
			Animator.stopMotion(_clip);
		}
		public function hide():void {
			UDisplay.removeClip(_clip);
		}
		public function dispose():void {
			hide();
			_clip.stopAllMovieClips();
			_clip = null;
		}
		public function startOnClick():void {

		}
		public function startOnTime(milliseconds:uint):void {
			_active = true;
			_advanceOnClick = false;
			_advanceOnTime = true;
			_millisecondsToAdvance = milliseconds;
			_timer.delay = _millisecondsToAdvance;
			_timer.repeatCount = 1;
			_elapsedFrames = 0;
			Debug.debug(_debugPrefix, "Clip started rendering first frame with timer.");
			renderStep(1);
		}
		public function renderFrame(step:uint, textFieldsContent:Object=null):void {
			freeze();
			_clip.gotoAndStop(step);
			for(var tf:String in textFieldsContent)
			{
				var textField:TextField = _clip[tf];
				if (textField) textField.htmlText = textFieldsContent[tf];
			}
			renderStepHard(step);
		}

// RENDER //////////////////////////////////////////////////////////////////////////////////////////
		private function renderStep(step:uint):void
		{
			Debug.debug(_debugPrefix, "Activating frame " + step);
			_targetFrame = step;
			resetTimer();
			if (_clip.alpha > 0) {
				Animator.fadeOut(_clip, _fadeOutFrames, onFadeOutComplete);
			} else {
				onFadeOutComplete();
			}
		}
		private function renderStepHard(step:uint):void { // Renders directly the step without fade out
			Debug.debug(_debugPrefix, "Activating frame HARD " + step);
			_targetFrame = step;
			resetTimer();
			onFadeOutComplete();
		}
		private function resetTimer():void {
			_timer.reset();
			_timer.delay = _millisecondsToAdvance;
		}

// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
		private function onClickStage():void {
			
		}
		private function onFadeOutComplete(c:*=null):void {
			if (!_active) return;
			if (_activeFrame >= _clip.totalFrames) { // Arrived to the end of clip
				Debug.debug(_debugPrefix, "Clip completely displayed all frames.");
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_FRAMEFINISH);
			} else {
				Debug.debug(_debugPrefix, " : " + _activeFrame);
				_activeFrame = _targetFrame
				if (_clip.currentFrame != _activeFrame) _clip.gotoAndStop(_activeFrame);
				UDisplay.resizeTo(_clip, UGlobal.getStageRect());
				UDisplay.centerToStage(_clip);
	 			Animator.fadeIn(_clip, _fadeInFrames, onFadeInComplete);
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_FRAMESTEP);
			}
		}
		private function onFadeInComplete(c:*=null):void {
			if (!_active) return;
			// _elapsedFrames ++;
			if (_advanceOnTime) {
				_timer.start();
			}
		}
		private function onTimerElapsed(e:TimerEvent):void {
			if (!_active) return;
			Debug.debug(_debugPrefix, "Timer elapsed");
			_timer.stop();
			renderStep(_activeFrame+1);
		}
	}
}