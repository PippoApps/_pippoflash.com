
/* MovieClipFrameRenderer - (c) Filippo Gregoretti - PippoFlash.com */
/* Gets a MovieClip, uses different frames to move between labels and render textfields from an object */

package com.pippoflash.movieclips.widgets {
	import com.pippoflash.utils.*;
	import com.pippoflash.framework._PippoFlashBase;
	import com.pippoflash.motion.Animator;
	import flash.display.*;
	import com.pippoflash.utils.UCode;
	import flash.display.Sprite;
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
	import flash.geom.Rectangle;
	import com.pippoflash.framework._PippoFlashBaseNoDisplay;
	import flash.geom.Matrix;
	public class MovieClipFrameRenderer extends _PippoFlashBaseNoDisplay {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// STATIC
		public static const EVT_FRAMESTART:String = "onClipRendererFrameStart"; // When a new step is rendered (0 to ...)
		public static const EVT_FRAMEARRIVED:String = "onClipRendererFrameArrived"; // When a new step is rendered (0 to ...)
		public static const EVT_FRAMELEFT:String = "onClipRendererFrameLeft"; // When the last step is clicked
		public static const EVT_ALLCOMPLETE:String = "onClipRendererComplete"; // When the last step is clicked
        // EDITABLE DEFAULTS
		private var _fadeInFramesDefault:uint = 50;
		private var _fadeOutFramesDefault:uint = 20;
        private var _defaultTime:uint = 5000;
		private var _advanceOnClick:Boolean = true;
		private var _advanceOnTime:Boolean = true;
		private var _resizeToScreen:Boolean = true;
		private var _loop:Boolean = false;
        // DATA
        private var _dataRenderObject:Array;
        // TIMER
		private var _timer:Timer = new Timer(0, 1);
		private var _frameTextContent:Array; // Each slot contains an object with textfield name and text content
		// NAVIGATION
        private var _activeStep:uint;
        private var _totalSteps:uint;
		private var _nextStep:uint;
		private var _durationTime:uint;
		private var _fadeInFrames:uint;
		private var _fadeOutFrames:uint;
		// REFERENCES
		private var _clip:MovieClip;
        private var _targetViewport:Rectangle; // Stage.getRect();
		// MARKERS
        private var _animating:Boolean;
        // GETTERS
		private function get clip():MovieClip {return _clip;}
		protected function get activeStep():uint {return _activeStep;}
// INIT //////////////////////////////////////////////////////////////////////////////////////////
		public function MovieClipFrameRenderer(movieClipId:String, id:String="MovieClipFrameRenderer", resizeToScreen:Boolean=true, advanceOnClick:Boolean=true) {
			super(id, MovieClipFrameRenderer);  
			_advanceOnClick = advanceOnClick;
			Debug.debug(_debugPrefix, "Inizialized with id: " + id + " and clip " + movieClipId);
			_clip = UCode.getInstance(movieClipId);
			_resizeToScreen = resizeToScreen;
			_timer.addEventListener(TimerEvent.TIMER, onTimerElapsed);
		}
// SETTERS ///////////////////////////////////////////////////////////////////////////////////////
		private function set advanceOnTime(value:Boolean):void
		{
			_advanceOnTime = value;
		}
   		private function set advanceOnClick(value:Boolean):void
		{
			_advanceOnClick = value;
		}
        private function set defaultTime(value:uint):void
        {
        	_defaultTime = value;
        }
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		// INITIAL SETUP AND START
        public function renderContent(dataRenderObject:Array):void { // Sets up content to render for the selected clip
            freeze();
            _dataRenderObject = dataRenderObject;
            _totalSteps = _dataRenderObject.length;
        }
        public function playOnStage(startStep:uint=0):void { // Plays the animation on stage
            reset();
            setupClipOnStage();
			playStep(startStep);
        }
		// CONTROLS
		public function playStep(step:uint, immediate:Boolean=false):void {
			if (immediate) renderStep(step);
			else fadeOutAndRenderStep(step);
		}



		// STOP OR RESET
		public function freeze():void {
			_animating = false;
			Animator.stopMotion(_clip);
            resetTimer();
		}
		public function hide():void {
			UDisplay.removeClip(_clip);
		}
		public function dispose():void {
			reset();
			_clip.stopAllMovieClips();
			_clip = null;
            _timer.reset();
            _timer = null;
		}
// RENDER //////////////////////////////////////////////////////////////////////////////////////////
		// POSITION AND SETUP
        private function setupClipOnStage():void {
			_clip.gotoAndStop(1);
			UGlobal.stage.addChild(_clip);
			UDisplay.centerToStage(_clip);
            positionToViewport(UGlobal.getStageRect());
        }
        private function positionToViewport(viewport:Rectangle=null):void {
            if (viewport) _targetViewport = viewport;
			if (_resizeToScreen) UDisplay.resizeTo(_clip, _targetViewport);			
			_clip.cacheAsBitmap = false;
			_clip.cacheAsBitmapMatrix = _clip.transform.matrix.clone();
			_clip.cacheAsBitmap = true;
        }
        private function reset():void {
            freeze();
            hide();
			_clip.alpha = 0;
            _activeStep = 0;
        }
		// RENDER STEP
		private function renderStep(step:uint):void { // Renders step immediately
			freeze();
			_activeStep = step;
			_nextStep = step+1;
			renderStepContent();
			fadeIn();
		}
		private function fadeOutAndRenderStep(step:uint):void { // Renders step after fading out whatever is in display
			_activeStep = step;
			_nextStep = step;
			if (_clip.alpha > 0) fadeOut();
			else onFadeOutDone(null, false);
		}
		private function renderStepContent():void {
			var textFieldsContent:Object = _dataRenderObject[_activeStep];
			_durationTime = textFieldsContent.duration ? textFieldsContent.duration : _defaultTime;
			_fadeInFrames = textFieldsContent.fadeInFrames ? textFieldsContent.fadeInFrames : _fadeInFramesDefault;
			_fadeOutFrames = textFieldsContent.fadeOutFrames ? textFieldsContent.fadeOutFrames : _fadeOutFramesDefault;
			_clip.gotoAndStop(textFieldsContent.frameLabel);
			for(var tf:String in textFieldsContent)
			{
				Debug.debug(_debugPrefix, "Rendering tf " + tf + " : " + textFieldsContent[tf] + " : " + _clip[tf]);
				var textField:TextField = _clip[tf];
				if (textField) textField.text = textFieldsContent[tf];
			}
		}		
		// FADES
		private function fadeOut():void {
			_animating = true;
			Animator.fadeOut(_clip, _fadeOutFrames, onFadeOutDone);
		}
		private function onFadeOutDone(c:DisplayObject=null, broadcastFrameLeft:Boolean=true):void {
			_animating = false;
			if (broadcastFrameLeft) PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_FRAMELEFT);
			if (_nextStep >= _totalSteps) { /// Presentation completey elapsed
				PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_ALLCOMPLETE);
			} else {
				renderStep(_nextStep);
			}
		}
		private function fadeIn():void {
			_animating = true;
			if (_advanceOnClick) activateClickNext();
			Animator.fadeInTotal(_clip, _fadeInFrames, onFadeInDone);
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_FRAMESTART);
		}
		private function onFadeInDone(c:DisplayObject=null):void {
			_animating = false;
			if (_advanceOnTime) activateTimeNext();
			PippoFlashEventsMan.broadcastInstanceEvent(this, EVT_FRAMEARRIVED);
		}

		// MOVING FROM ONE FRAME TO THE NEXT
		private function activateClickNext():void {
			UGlobal.setStageShield(true, onStageClick);
		}
		private function onStageClick(e:*=null):void {
			Debug.debug(_debugPrefix, "Clicked Stage.");
			proceedAfterTimeOrAction();
		}
		private function activateTimeNext():void {
			resetTimer();
			_timer.delay = _durationTime;
			_timer.start();
		}
		private function onTimerElapsed(e:TimerEvent):void {
			// if (!_active) return;
			Debug.debug(_debugPrefix, "Timer elapsed");
			proceedAfterTimeOrAction();
		}
		private function proceedAfterTimeOrAction():void {
			resetTimer();
			resetClick();
			fadeOut();
		}
		private function resetTimer():void {
			_timer.reset();
			_timer.delay = _defaultTime;
		}
		private function resetClick():void {
			UGlobal.setStageShield(false);
		}


// UTY /////////////////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
}



// EXAMPLE OBJECT TO RENDER
/*

*/