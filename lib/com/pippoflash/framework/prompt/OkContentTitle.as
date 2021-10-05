
// Date(yearOrTimevalue:Object, month:Number, date:Number = 1, hour:Number = 0, minute:Number = 0, second:Number = 0, millisecond:Number = 0)

package com.pippoflash.framework.prompt {
	import											com.pippoflash.framework.prompt._Prompt;
	import											com.pippoflash.utils.UCode;
	public dynamic class OkContentTitle extends _Prompt {
		// STATIC ////////////////////////////////////////////////////////////////////////////////
		// VARIABLES //////////////////////////////////////////////////////////////////////////
		// USER VARIABLES
		// REFERENCES
		// MARKERS
// INIT ////////////////////////////////////////////////////////////////////////////////////
		public function OkContentTitle						() {
			super									("OkContentTitle");
		}
		public override function prompt						(par:Object=null) {
			_contentBox.release							();
			super.prompt								(par);
			// Content
			_contentBox.setContent						(_par._content);
		}
		// UTY /////////////////////////////////////////////////////////////////////////////////////////
		// LISTENERS //////////////////////////////////////////////////////////////////////////////////////
	}
	
	
	
}