/* _ButtonClips - Base class for all Buttons
*/

package com.pippoflash.gui.button {
	
	import											com.pippoflash.utils.UDisplay;
	import											flash.display.*;
	import											flash.text.*;
	import											flash.events.*;
	import 											flash.utils.*;
	
	public dynamic class _ButtonClips extends _Button {
		// STATIC ////////////////////////////////////////////////////////////////////////////////
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		public static var _debugPrefix						:String = "_ButtonClips";
		public static var _deviceRollOverTimeout					:uint = 120;
		// USER VARIABLES
		// REFERENCES
		public var _roll									:DisplayObject;
		// FOOL COMPILER - Vars are defined like instance var in superclass. Here I define them static not to interfere.
		public static var _txt								:TextField;
		public static var _bg								:MovieClip;
		// MARKERS	
		public var _txtYOff								:int; // Vertical offset of textfield; Defined in first frame of movieclip.
		public var _selected								:Boolean = false;

// INIT ////////////////////////////////////////////////////////////////////////////////////
		public function _ButtonClips							(par:Object=null) {
			super									(par);
			_roll.visible									= false;
		}
		// METHODS //////////////////////////////////////////////////////////////////////////////////////
		public override function setSize						(w:Number, h:Number):void {
			_w = w; _h = h; scaleX = scaleY = 1; resize(_bg); resize(_roll);
			_txt.width 									= _w - _txt.x; 
			UDisplay.centerV								(_txt, _h); // X is not moved since text needs to have an offset
			_txt.y									+= _txtYOff;
		}
// STATUSES /////////////////////////////////////////////////////////////////////////////////////////
		// I cannot resize a different clip in another frame, because of absurd behaviours in flash. It triggers strange errors. If I call and resize the clip with the same name it only shows the first one. Horrible.
		// So I need to call IN FRAME setUp() setOver() setDown() - Horrible, but it works...
		public override function setUp						():void {
			if (_isTouchDevice)							hideRollTimeout();
			else										hideRoll();
		}
			private function hideRollTimeout					():void {
				setDown								();
				setTimeout								(hideRoll, _deviceRollOverTimeout);
			}
			private function hideRoll						():void {
				if (_selected)							return;
				_roll.visible								= false;
			}
		public override function setOver						():void {
			_roll.visible									= true;
		}
		public override function setDown						():void {
			_roll.visible									= true;
		}
		public override function setSelected					(s:Boolean):void {
			_selected									= s;
			_roll.visible									= s;
		}
		// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}