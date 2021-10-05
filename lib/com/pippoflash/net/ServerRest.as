/* ServerRest - ver 0.1 - (c) Filippo Gregoretti - PippoFlash.com
Extension of Server to manage REST paradigm, using PUT and DELETE vriables methods (simulated as explaind in http://cambiatablog.wordpress.com/2010/08/10/287/)
This allows now to send variables not just in GET and POST format, but also in PUT and DELETE
*/

package  com.pippoflash.net {

	import 									flash.text.*;
	import 									flash.utils.*;
	import									com.pippoflash.net.Server;
	import									com.pippoflash.utils.Debug;
	import									com.pippoflash.utils.UCode;
	import									com.pippoflash.utils.UText;
	import									com.pippoflash.utils.UXml;
	import									com.pippoflash.net.QuickLoader;

	
	public class ServerRest extends Server {
// UTYLITIES ////////////////////////////////////////////////////////////////////////////
		// REFERENCES
		// DATA HOLDERS
		// MARKERS
		// STATIC UTY
// INIT ///////////////////////////////////////////////////////////////////////////////////////
		public function ServerRest					(listener:*, api:String):void {
			super							(listener, api);
			_debugPrefix						= "ServerRest";
			updateDefaultParams					();
		}
			private function updateDefaultParams		():void {
				// This updates the default params object so that it can also add PUT and DELETE variables
				_defaultCommandObject._requestHeaders 
				_defaultCommandObject._paramsPut	= null; // Params for PUT variables
				_defaultCommandObject._paramsDelete	= null; // Params for DELETE variables
			}
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
// DATA CRUNCH ///////////////////////////////////////////////////////////////////////////////////////
// CONTENT ///////////////////////////////////////////////////////////////////////////////////////
// CALL STANDARD COMMAND	///////////////////////////////////////////////////////////////////////////////////////
		override protected function launchCommand	() {
			_executing._formattedUrl			= getCommandUrl(_executing);
			if (_verbose)					Debug.debug(_debugPrefix, _executing._formattedUrl);
			if (_executing._paramsPost)			doCallCommandPost(); // in Server
			else if (_executing._paramsPut)		doCallParamsPut(); // Here
			else if (_executing._paramsDelete)		doCallParamsDelete(); // Here
			else							doCallCommand(); // is Server
		}
			protected function doCallCommanPut	():void {
				Debug.listObject				(_executing._paramsPut, "PUT");
				var paramsString				:String = addGetParamsToString("", _executing._paramsPost);
				QuickLoader.loadFilePostVars	(_executing._formattedUrl, this, "StandardCommand", new URLVariables(paramsString), false, _executing._format.toLowerCase());
			}
// EMBED RENDERING //////////////////////////////////////////////////////////////////////////////
// UTY ///////////////////////////////////////////////////////////////////////////////////////
	}
}

