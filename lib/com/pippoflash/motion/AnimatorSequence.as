/*
var a = new AnimatorSequence([clip,clip,clip], [motionObj, motionObj, motionObj], interval);
a.start();
a.stop();
a.harakiri();

motionObj can be an object for frame mover:{steps:10, pow:2, endPos:{x:100,y:100}}
or a string for an animator method: "fadeIn", "fadeOut" ...
*/


package com.pippoflash.motion {
	import											com.pippoflash.utils.UCode;
	import											com.pippoflash.motion.PFMover;
	import											com.pippoflash.motion.Animator;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	
	public class AnimatorSequence {
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		public static var _i								:uint;
		// USER VARIABLES
		private var _interval								:uint;
		private var _clips									:Array = new Array();
		private var _motions								:Array = new Array();
		private var _functions								:Array = new Array();
		private var _initObjects							:Array = new Array();
		// SYSTEM
		private var _timeouts								:Array = new Array();
		// MARKERS
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function AnimatorSequence						(interval:uint=50):void {
			_interval = interval;
// 			_clips = clips; _motions = motions; _interval = interval; _functions = functions;
		}
// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public function addStep							(clip:DisplayObject, motion:Object, func:Function=null, initObj:Object=null):void {
			_clips.push(clip); _motions.push(motion); _functions.push(func); _initObjects.push(initObj);
		}
		public function start								():void {
			stop										();
			_timeouts									= new Array();
			for (_i=0; _i<_clips.length; _i++) {
				_timeouts[_i]							= setTimeout(startClipMotion, _interval*_i, _i);
// 				PFMover.removeMotion					(_clips[_i]);
				UCode.setParameters						(_clips[_i], _initObjects[_i]);
			}
		}
		public function stop								():void {
			for (_i=0; _i<_clips.length; _i++) {
				clearTimeout							(_timeouts[_i]);
				PFMover.removeMotion					(_clips[_i]);
			}
		}
		public function reverse								():void {
			_clips.reverse(); _motions.reverse(); _functions.reverse(); 
		}
		public function harakiri								():void {
			stop										();
			_motions = new Array(); _clips = new Array(); _timeouts = new Array();
		}
// SEQUENCES ///////////////////////////////////////////////////////////////////////////////////////
		private function startClipMotion						(n:uint):void {
			if (_motions[n] is String)						Animator[_motions[n]](_clips[n]);
			else										PFMover.slideIn(_clips[n], _motions[n]);
			if (_functions[n])								_functions[n]();
		}
		
// UTY /////////////////////////////////////////////////////////////////////////////////////////
// END MOTION ACTIONS ////////////////////////////////////////////////////////////////////////////
// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
}