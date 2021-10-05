/* IPippoFlashBase - (c) Filippo Gregoretti - PippoFlash.com */
/* Interface for PippoFlashBase stuff. All of it. */


package com.pippoflash.framework.interfaces {
	public interface IUMem {
		// Remember, always to add mthod recycle(), this will be used for instantiating
		function release():void;
		function cleanup():void;
		function harakiri():void;
	}
}
