package com.pippoflash.framework.air.webview 
{
	import flash.geom.Rectangle;
	import com.pippoflash.utils.*;
	
	/**
	 * Controls generic HTML gui elements based on PippoAppsJS framework.
	 * Based on the first CAOS bluetooth app.
	 * Extends PAWEbView, so it can be used instead of PAWebView.
	 * @author Pippo Gregoretti
	 */
	public class HTMLGuiView extends PAWebView 
	{
		
		public function HTMLGuiView(id:String=null, cl:Class=null, htmlFolder:String=null, viewPort:Rectangle=null) 
		{
			super(id, cl, htmlFolder, viewPort);
			
		}
		
		// GUI METHODS ///////////////////////////////////////////////////////////////////////////////////////
		public function setGuiLoader(active:Boolean, textId:String=""):void {
			callJSAirApplicationMethod("setLoader", active, textId);
		}
		public function guiPrompt(promptId:String, okFuncID:String=null, cancelFuncID:String=null, okFuncParam:String=null, cancelFuncParam:String=null):void {
			Debug.debug(_debugPrefix, "Prompting: " + promptId);
			callJSAirApplicationMethod("triggerPrompt", promptId, okFuncID, cancelFuncID, okFuncParam, cancelFuncParam);
		}
		public function notifyDeviceCommandError(errorCode:uint):void {
			callJSAirApplicationMethod("triggerError", errorCode);
		}
		
		
		
	}

}