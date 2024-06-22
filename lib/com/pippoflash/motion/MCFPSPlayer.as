/* - MCFPSPlayer 1.0 - Plays a timeline animation with a diffferent (or same) FPS, moving playhead according to elapsed time.
*/

package com.pippoflash.motion {
	import											flash.display.*;
	import 											flash.events.*;
	import 											flash.utils.*;
	import											com.pippoflash.utils.*;
	import											com.pippoflash.framework._PippoFlashBaseNoDisplayUMemDispatcher;
	
	public class MCFPSPlayer extends _PippoFlashBaseNoDisplayUMemDispatcher {
	// CONSTANTS
	private static const EVT_FRAME_ELAPSED					:String = "onMCPlayerFrameElapsed"; // Everytime a new frame is set
	private static const EVT_COMPLETE						:String = "onMCPlayerComplete"; // When animation is complete
	private static const EVT_LOOP							:String = "onMCPlayerLoop"; // When a loop is complete
	private static const ENTER_FRAME_CLIP					:MovieClip = new MovieClip(); // Needed to register frame events
	// SYSTEM
	private var _divider									:Number; // Divider to calculate playhead according to position in time, computed from MovieClip FPS.
	private var _playhead									:uint; // Stores where exactly is playhead
	private var _nextFrame								:uint; // Stores next proposed frame
	private var _startTime									:uint; // Time animation starts
	private var _elapsedTime								:uint; // Time passed from start
	// USER VARIABLES
	private var _loop										:Boolean; // If animation must be looped
	private var _mc										:MovieClip; // Processed MovieClip
	private var _mcFPS									:uint;
	private var _firstFrame								:uint;
	private var _lastFrame									:uint;
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function MCFPSPlayer						(id:String=null):void {
			super									("MCFPSPlayer");
			_debugPrefix								+= id ? "<" + id +">" : "";
		}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function setMovieClip							(mc:MovieClip, mcFPS:uint):void {
			_mc										= mc;
			_mcFPS									= mcFPS;
			_playhead									= mc.currentFrame;
			Debug.debug								(_debugPrefix, "Setting up for MovieClip: " + _mc);
			_divider									= 1000/mcFPS;
		}
		public function play								(firstFrame:uint=1, lastFrame:uint=0, loop:Boolean=false):void {
			Debug.debug								(_debugPrefix, "Launching animation from frame " + firstFrame + " to frame " + lastFrame);
			if (playError("PLAY"))							return;
			_firstFrame									= firstFrame;
			_lastFrame									= lastFrame < 1 ? _mc.totalFrames : lastFrame;
			_loop										= _loop;
			startPlay									();
		}
		public function stop								():void {
			if (playError("STOP"))							return;
			completeAnimation							();
		}
		public function pause								():void {
			if (playError("PAUSE"))						return;
		}
		public function resume							():void {
			if (playError("RESUME"))						return;
		}
// ANIMATION ///////////////////////////////////////////////////////////////////////////////////////
		private function startPlay							():void {
			if (_lastFrame < _firstFrame) {
				Debug.error							(_debugPrefix, "Animation start frame is set before end frame. Obviously cannot animate.");
				return;
			}
			Debug.debug								(_debugPrefix, "Animation started from frame " + _firstFrame + " to frame " + _lastFrame);
			_mc.gotoAndStop							(_firstFrame);
			_playhead									= _nextFrame = _firstFrame;
			_startTime									= getTimer();
			_elapsedTime								= 0;
			ENTER_FRAME_CLIP.addEventListener				(Event.ENTER_FRAME, onEnterFrame);
		}
// UTY ///////////////////////////////////////////////////////////////////////////////////////
		private function playError							(id=""):Boolean {
			var error									:String;
			if (!_mc)									error = "MovieClip not defined. Please call setMovieClip() before any play operation.";
			if (error) {
				Debug.error							(_debugPrefix, id + " Error playing MovieClip: " + error);
				return								true;
			}
			return									false;
		}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		private function onEnterFrame				(e:Event):void {
			_elapsedTime						= getTimer() - _startTime;
			_nextFrame						= Math.round(_firstFrame + (_elapsedTime/_divider));
			if (_nextFrame == _playhead) {
// 				trace("salto " , _nextFrame,_playhead,_lastFrame);
				return; // We still didn't pass enough time to move to next frame, therefore nothing happens
				
			}
			if (_nextFrame <= _lastFrame) { // There is stilla frame of animation to play, could also be the last
				moveToNextFrame				(); // Perform last frame of animation
			}
			else { // This is the next frame after last, here I chek if it loops or if it's complete
// 				trace("CAZZOOOOOOOOOOOOOOOOOO");
				if (_loop) {
					broadcastEvent				(EVT_LOOP, this); // Broadcast new loop started
					startPlay					(); // Restart animation
				}
				else { // Animation is complete and I do not have to loop
					broadcastEvent				(EVT_COMPLETE, this); // Broadcast new loop started
					completeAnimation			();
				}
			}
		}
				
				private function moveToNextFrame	():void {
					_playhead					= _nextFrame;
// 					Debug.debug						(_debugPrefix, "Moving ot playhead: " + _playhead);
					_mc.gotoAndStop			(_playhead);
					broadcastEvent				(EVT_FRAME_ELAPSED, this);
				}
				private function completeAnimation	():void {
					_mc.gotoAndStop			(_lastFrame);
					ENTER_FRAME_CLIP.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
					Debug.debug				(_debugPrefix, "Animation stopped.");
				}
	}
}
