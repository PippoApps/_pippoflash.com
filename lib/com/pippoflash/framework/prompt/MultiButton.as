
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.framework.prompt {
	import											com.pippoflash.framework.prompt._Prompt;
	import											com.pippoflash.utils.*;
	import flash.display.*;
	public dynamic class MultiButton extends _Prompt {
		// STATIC ////////////////////////////////////////////////////////////////////////////////
		private static const TOTAL_BUTTONS:uint = 10;
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		// REFERENCES
		private var _selButtons:Array;
		// MARKERS
// INIT ////////////////////////////////////////////////////////////////////////////////////
		public function MultiButton() {
			super("MultiButton");
		}
		protected override function initializePrompt():void {
			super.initializePrompt();
			_selButtons = [];
			for (var i:uint=0; i<TOTAL_BUTTONS; i++) {
				_selButtons[i] = this["_buttGen" + i];
			}
		}
		protected override function renderPrompt(par:Object=null):void {
			// This one uses:
			// _funcSelection:Function
			// _buttonTexts:Array - this decides which buttons are visible
			if (!par._buttonTexts || !par._funcSelection) {
				Debug.error(_debugPrefix, "Missing some mandatory parameters: _funcSelection:Function or _buttonTexts:Array. Prompt aborted.");
				setOut();
				return;
			}
			for (var i:uint=0; i<TOTAL_BUTTONS; i++) {
				if (par._buttonTexts[i]) {
					_selButtons[i].visible = true;
					_selButtons[i].setText(par._buttonTexts[i]);
				} else {
					_selButtons[i].visible = false;
				}
			}
		}
		public function onPressSelectionButton(c:DisplayObject=null):void { // This is the selection button
			_par._funcSelection(_selButtons.indexOf(c));
			onPressClose();
		}
	}
	
	
	
}