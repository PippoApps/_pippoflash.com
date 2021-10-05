/* UExec - ver 0.1 - Executes applications in a certain amount of frames


*/

package com.pippoflash.utils {

	import com.adobe.protocols.dict.DictionaryServer;
	import flash.display.*;
	import flash.system.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;

	public class UExec {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// CONSTANTS
		private static const _debugPrefix:String = "UExec";
		private static var _myClip:MovieClip = new MovieClip();
		public static var _defaultCommandObject:Object = {
			f:"function",
			p:"params, array"
		};
		private static var _counter:uint = 0;
		private static var _commandsAtFrame:Array = [];
		private static var _next:Array = [];
		private static var _o:Object;
		private static var _now:Array;
		// TIMED EXECUTION
		private static var _timedExecutions:Dictionary = new Dictionary(); // Stored by TIMER instance
		static private var _timedExecutionsByMethods:Dictionary = new Dictionary();
		
		
		// Sequenced execution
		private static var _sequenceCounter:int;
		static private var _sequenceFrameInterval:uint = 1;
// SEQUENCE METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function resetSequence(frameInterval:uint = 1):void { // Resets sequence counter
			_sequenceFrameInterval = frameInterval;
			_sequenceCounter = frameInterval;
		}
		static public function addSequence(f:Function, ...rest):void {
			if (!_commandsAtFrame[_sequenceCounter]) {
				_commandsAtFrame[_sequenceCounter] = [makeCommandObject(f, rest)];
			}
			else _commandsAtFrame[_sequenceCounter].push(makeCommandObject(f, rest));
			startListener();
			_sequenceCounter += _sequenceFrameInterval;
		}
		
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public static function next(f:Function, ...rest):void {
			// Adds a function to next fame
			if (!_commandsAtFrame[1]) {
				_commandsAtFrame[1] = [makeCommandObject(f, rest)];
			}
			else _commandsAtFrame[1].push(makeCommandObject(f, rest));
			startListener();
		}
		public static function frame(n:uint, f:Function, ...rest):void {
			// Calls a function after a certain amount of frames
			if (!_commandsAtFrame[n]) {
				_commandsAtFrame[n] = [makeCommandObject(f, rest)];
			}
			else _commandsAtFrame[n].push(makeCommandObject(f, rest));
			startListener();
		}
		public static var second					:Function = seconds; // Makes sense. The other one is "frame"
		public static function seconds				(secsToFrames:uint, f:Function, ...rest):void {
			var n							:uint = secsToFrames * UGlobal.stage.frameRate;
			// Calls a function after a certain amount of frames
			if (!_commandsAtFrame[n]) {
				_commandsAtFrame[n] 			= [makeCommandObject(f, rest)];
			}
			else 								_commandsAtFrame[n].push(makeCommandObject(f, rest));
			startListener						();
		}
		public static function time(realSeconds:Number, f:Function, ...rest):void {
			var o:Object = makeCommandObject(f, rest);
			if (realSeconds <= 0) {
				execObject(o);
				return;
			}
			var t:Timer = new Timer(realSeconds*1000, 1);
			o.timer = t;
			_timedExecutions[t] = o;
			_timedExecutionsByMethods[f] = o;
			t.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete, false, 0, true);
			t.start();
		}
				private static function onTimerComplete(e:Event):void {
					delete _timedExecutions[e.target].timer;
					execObject(_timedExecutions[e.target]);
					e.target.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete, false);
					delete _timedExecutions[e.target];
				}
		public static function distributeCalls(calls:Array, pars:Array=null):void {
			if (pars) {
				for (var i:uint=0; i<calls.length; i++) {
					frame(i+1, calls[i], pars[i]);
				}
			}
			else {
				for (var ii:uint=0; ii<calls.length; ii++) {
					frame(ii+1, calls[ii]);
				}
			}
		}
		public static function removeMethod(f:Function, info:String=""):void { // Removes all commands with method - ONLY FRAME EVENTS
			Debug.debug(_debugPrefix, "Trying to remove a single method " + info);
			// Look for timed executions
			var o:Object = _timedExecutionsByMethods[f];
			if (o) { // There is a timed execution, just destoyr it
				cleanupObject(o);
			}
			// Look for frame executions
			if (_commandsAtFrame.length) {
				for (var i:uint=0; i<_commandsAtFrame.length; i++) {
					if (_commandsAtFrame[i]) {
						for (var ii:uint=0; ii<_commandsAtFrame[i].length; ii++) {
							if (_commandsAtFrame[i][ii].f == f) {
								Debug.debug	(_debugPrefix, "Removed method at frame " + i);
								cleanupObject(_commandsAtFrame[i].splice(i, 1));
							}
						}
					}						
				}
			}
		}
		public static function reset				():void { // This removes all taska, and resets everything as new
			Debug.debug						(_debugPrefix, "Interrupting all motions! (only the ones in frames, with reset())");
			if (_commandsAtFrame.length) {
				for (var i:uint=0; i<_commandsAtFrame.length; i++) {
					if (_commandsAtFrame[i])		Debug.debug(_debugPrefix, "Removing " + Debug.object(_commandsAtFrame[i]));
				}
			}
			_commandsAtFrame					= [];
			_next							= [];
			_counter							= 0;
			checkStop							();
		}
		public static function addEnterFrameListener(f:Function):void {
			_myClip.addEventListener(Event.ENTER_FRAME, f, false, 0, true);
		}
		public static function removeEnterFrameListener(f:Function):void {
			_myClip.removeEventListener(Event.ENTER_FRAME, f, false);
		}
	// UTY ///////////////////////////////////////////////////////////////////////////////////////
			private static function makeCommandObject(f:Function=null, par:Array=null):Object {
				if (Boolean(f)) {
					return					{f:f, p:par};
				}
				else {
					Debug.error				(_debugPrefix, "UExec.makeCommandObject() received an empty function! I am setting dummyfunction, params are",par);
					return					{f:UCode.dummyFunction, par:null};
				}
			}
			private static function startListener():void { // Starts listening waiting for right frame
				_myClip.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			public static function onEnterFrame(e:Event):void {
				if (_next.length) {
					execList(_next);
					_next = [];
				}
				_now = _commandsAtFrame.shift();
				if (_now) execList(_now);
			}
			private static function execList(a:Array):void {
				// This executes a list of commands
				for each (_o in a) execObject(_o);
				checkStop();
			}
			private static function execObject(o:Object):void {
				if (o.p.length > 8) {
					Debug.error(_debugPrefix, "Cannot execute method with params: ", Debug.object(o.p),"length is longer than maximum params: 8");
					return;
				}
				UExec["exec"+o.p.length](o);
				cleanupObject(o);
			}
			static private function cleanupObject(o:Object):void {
				var t:Timer = o.timer;
				if (t) {
					t.stop();
					t.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete, false);
					delete _timedExecutionsByMethods[o.f];
					delete o.timer;
				}
				delete o.f;
				delete o.p;
				
			}
			private static function checkStop		():void {
				if (!_next.length && !_commandsAtFrame.length) _myClip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			private static function exec0			(o:Object):void {
				o.f							();
			}
			private static function exec1			(o:Object):void {
				o.f							(o.p[0]);
			}
			private static function exec2			(o:Object):void {
				o.f							(o.p[0], o.p[1]);
			}
			private static function exec3			(o:Object):void {
				o.f							(o.p[0], o.p[1], o.p[2]);
			}
			private static function exec4			(o:Object):void {
				o.f							(o.p[0], o.p[1], o.p[2], o.p[3]);
			}
			private static function exec5			(o:Object):void {
				o.f							(o.p[0], o.p[1], o.p[2], o.p[3], o.p[4]);
			}
			private static function exec6			(o:Object):void {
				o.f							(o.p[0], o.p[1], o.p[2], o.p[3], o.p[4], o.p[5]);
			}
			private static function exec7			(o:Object):void {
				o.f							(o.p[0], o.p[1], o.p[2], o.p[3], o.p[4], o.p[5], o.p[6]);
			}
			private static function exec8			(o:Object):void {
				o.f							(o.p[0], o.p[1], o.p[2], o.p[3], o.p[4], o.p[5], o.p[6], o.p[7]);
			}
	}
}



/* ________________________________________________________
All AS files and libraries included in the domain com.pippoflash.*
Are open.source libraries developed by Filippo Gregoretti, and are therefore not copyrightable.
They can be used in commercial projects but must be left free for re-distribution and usage.
They go with all MovieClips included in the .fla or .xfl document, in the folders:
- PippoFlash.com - Framework

- PippoFlash.com - Components
All movieclips and assets within those folders in the source flash document (fla or xfl) 
are open source anc dan be used in commercial projects, but cannot be copyrighted.
__________________________________________________________ */