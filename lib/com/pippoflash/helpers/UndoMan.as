/* UndoMan - Once instantiated creates an undo chain. */

package com.pippoflash.helpers {
	import com.pippoflash.framework._PippoFlashBaseNoDisplayUMem;
	import com.pippoflash.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.profiler.*;

	public dynamic class UndoMan extends _PippoFlashBaseNoDisplayUMem {
// VARIABLES //////////////////////////////////////////////////////////////////////////
		// SETUP CONSTANTS TO BE MODIFIED IN MAINAPP
		// NON-STATIC SWITCHES - MODIFIABLE VIA CONFIG - SET IN MAINAPP (DEFAULTS ONLY HERE)
		// SYSTEM
		private var _playhead					:uint; // Position of next method.
		private var _commands					:Array; // List of methods.
		// REFERENCES
		// STAGE INSTANCES
		// MARKERS
		// DATA HOLDERS
		private var _undoId						:String;
		// STATIC UTY
// INIT //////////////////////////////////////////////////////////////////////////////////
		public function UndoMan					(id:String=""):void {
			super							("UndoMan");
			_undoId							= id;
			reset								();
		}
// STARTUP ///////////////////////////////////////////////////////////////////////////////////////
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function reset						():void {
			_playhead							= 0;
			_commands						= [];
		}
		public function addCommand				(command:*):void { // Any kind of comand can be added to the undo chain
			if (_commands[_playhead]) {
				// I have already stepped back, therefore adding a command I delete all forward history
				_commands.splice				(_playhead);
			}
			_commands[_playhead]				= command;
			_playhead							++;
		}
		public function stepBack					(andDestroy:Boolean=false):* { // Grabs the previous command, and broadcasts the event
			// If andDestroy is selected, step forward will not be possible and last command is destroyed
			if (hasBack()) {
				_playhead						--;
				return 						andDestroy ? _commands.pop() : _commands[_playhead];
			}
			Debug.debug						(_debugPrefix, "Can't step back anymore.");
		}
		public function stepForward				():* { // Grabs the following command, and broadcasts the event
			if (hasForward()) {
				return						_commands[_playhead];
				_playhead						++;
			}
			Debug.debug						(_debugPrefix, "Can't step forward anymore.");
		}
		public function hasBack					():Boolean {
			return							_playhead > 0;
		}
		public function hasForward				():Boolean {
			return							_commands[_playhead] ? true : false;
		}
// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
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