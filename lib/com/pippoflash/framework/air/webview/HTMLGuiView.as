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
		public function notifyDeviceCommandError(errorCode:String):void {
			callJSAirApplicationMethod("triggerError", errorCode);
		}
		public function promptBluetoothSystemError(okFuncID:String=null):void {
			callJSAirApplicationMethod("triggerBluetoothSystemError", okFuncID);
		}
		public function setMainButtonsVisible(v:Boolean):void {
			callJSAirApplicationMethod("setMainButtonsVisible",v);
		}
		// System
		public function confirmDataUpdate(id:String):void { // when GUI sends a data update, DEVICE responds correctly, this confirms data has been updated successfully
			callJSAirApplicationMethod("confirmDataUpdate", id);
		}
		
		
		
		// Pin management
		public function setPin(pin:String):void {
			callJSAirApplicationMethod("setPin", pin);
		}
		public function promptInitialPin():void {
			callJSAirApplicationMethod("choosePin");
		}
		public function promptWrongPin():void {
			callJSAirApplicationMethod("promptPin");
		}
		public function promptNewPin():void {
			callJSAirApplicationMethod("changePin");
		}
		
		// Date / time
		public function promptDateTime():void {
			callJSAirApplicationMethod("changeDateTime");
		}
		
		
		
		// Data settings
		public function setFullSettings(settings:String):void {
			callJSAirApplicationMethod("setFullSettings", settings);
		}
		public function setLed(led:String):void {
			
		}
		public function setWeekly(weekly:String):void {
			
		}
		public function setTime(time:String):void {
			
		}
		
		
	}

}