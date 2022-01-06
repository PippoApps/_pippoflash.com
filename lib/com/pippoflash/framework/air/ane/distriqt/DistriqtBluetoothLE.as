package com.pippoflash.framework.air.ane.distriqt 
{
	import com.distriqt.extension.bluetoothle.*;
	import com.distriqt.extension.bluetoothle.events.*;
	import com.distriqt.extension.bluetoothle.objects.*;
	import com.distriqt.extension.bluetoothle.utils.*;
	import com.pippoflash.framework.air.UAir;
	import com.pippoflash.utils.UExec;
	import com.pippoflash.utils.UText;
	import com.distriqt.extension.nativewebview.platform.WindowsOptions;
	import com.pippoflash.framework.PippoFlashEventsMan;
	import com.pippoflash.framework.air.ane._PippoAppsANE;
	import com.distriqt.extension.nativewebview.*;
	import com.distriqt.extension.nativewebview.events.*;
	import com.distriqt.extension.core.Core;
	import com.pippoflash.utils.Debug;
	import com.pippoflash.utils.UGlobal;
	import com.pippoflash.utils.USystem;
	import flash.display.Stage;
	import flash.geom.Rectangle;
	import flash.display.Screen;
	import com.pippoflash.framework.air.webview.PAWebView;
	
	/**
	 * ...
	 * @author Pippo Gregoretti
	 */
	public class DistriqtBluetoothLE extends _DistriqtAne 
	{

		
						//_webView.addEventListener(NativeWebViewEvent.COMPLETE, webViewCompleteHandler);
				//_webView.addEventListener(NativeWebViewEvent.LOCATION_CHANGE, webViewChangedHandler);
				//_webView.addEventListener(NativeWebViewEvent.LOCATION_CHANGING, webViewChangingHandler);
				//_webView.addEventListener(NativeWebViewEvent.ERROR, webViewErrorHandler);
				//_webView.addEventListener( NativeWebViewEvent.JAVASCRIPT_RESPONSE, javascriptResponseHandler );
				//_webView.addEventListener( NativeWebViewEvent.JAVASCRIPT_MESSAGE, javascriptMessageHandler );

		
		// MODIFIABLE CONSTANTS ///////////////////////////////////////////////////////////////////////////////////
		static public var DO_NOT_ADD_PERIPHERALS_WITH_BLANK_NAME:Boolean = true; // Peripherals with name "" are not added to eligible list (also if "" is one of the eligible names)
		static public var CHARACTER_COMMAND_START:String = "<";
		static public var CHARACTER_COMMAND_STOP:String = ">";
		// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		static private var  _initialized:Boolean;
		static private var _hasPermission:Boolean;
		static private var _authorizationType:String;
		static private var _debugPrefix:String = "BluetoothLE";
		static private var _initCallback:Function;
		// Bluetooth system
		static private var _setupAsCentral:Boolean;
		static private var _devicesNamesToPair:Vector.<String> = new Vector.<String>();
		// Bluetooth connection
		static private var _activePeripheral:Peripheral;
		static private var _periferalNameFound:Boolean;
		static private var _eligiblePeripherals:Object; // Peripherals by uuid
		static private var _eligiblePeripheralsList:Vector.<Peripheral>; // List of peripherals
		static private var _serviceToScan:Service;
		static private var _notificationCharacteristics:Vector.<Characteristic>; // List of Characteristic subscribed for notification, read, notify
		static private var _writeCharacteristics:Vector.<Characteristic>; // List of Characteristic to send data to, writeWithoutResponse
		// Bluetooth communication
		static private var _textBufferPerCharacteristicByUuid:Object = {}; // udid:String
 		// EVENTS - INITIALIZATION AND CONNECTION
		public static const EVT_SCAN_START:String = "onBluetoothLEScanStart";
		public static const EVT_SCAN_STOP:String = "onBluetoothLEScanStop";
		public static const EVT_ELIGIBLE_PERIPHERAL_FOUND:String = "onBluetoothLEEligiblePeripheralFound";
		public static const EVT_PERIPHERAL_PAIRED:String = "onBluetoothLEPeripheralPaired"; // uuid:String
		public static const EVT_FIRST_SERVICE_SETUP:String = "onBluetoothLEFirstServiceSetup";
		// EVENTS - COMMUNICATION
		public static const EVT_COMMAND_RECEIVED:String = "onBluetoothLECommandReceived"; // command:String
		//public static const EVT_CHANGE:String = "onNativeWebViewHtmlChanged";
		//public static const EVT_ERROR:String = "onNativeWebViewHtmlError";
		//public static const EVT_JS_RESPONSE:String = "onNativeWebViewHtmlJSResponse";
		//public static const EVT_JS_MESSAGE:String = "onNativeWebViewHtmlJSMessage";
		
		//private static var _nativeOptions:NativeWebViewOptions;
		
		
		// CONNECTED DEVICES
		
		
		
		// STATIC METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function get isSupported():Boolean {
			if (!BluetoothLE.isSupported) Debug.error(_debugPrefix, "Bluetooth not supported.");
			return BluetoothLE.isSupported;
		}
		static public function init():Boolean {
			if (isSupported) {
				_DistriqtAne.initCore();
				//BluetoothLE.init();
				Debug.debug(_debugPrefix, "Initializing ver " + BluetoothLE.VERSION);
				_initialized = true;
				setupAuthorizationStatus(BluetoothLE.service.authorisationStatus());
				//_authorizationType = BluetoothLE.service.authorisationStatus();
				//analyzeAuthorization(false);
			} else Debug.error(_debugPrefix, "NOT SUPPORTED ON THIS PLATFORM");
			return _initialized;
		}
		static private function setupAuthorizationStatus(auth:String):void {
			_authorizationType = auth;
			switch (_authorizationType) {
				case AuthorisationStatus.AUTHORISED:
						_hasPermission = true;
						return;
			}
		}
		
		static private var _authorizationCallback:Function; // True or false whether authorization is requested
		static public function requestAuthorization(authorizationCallback:Function):void {
			Debug.debug(_debugPrefix, "Requesting Bluetooth Authorisation.");
			setupAuthorizationStatus(BluetoothLE.service.authorisationStatus());
			if (hasPermission) {
				Debug.debug(_debugPrefix, "Bluetooth already authorised.");
				authorizationCallback(true);
				return;
			}
			// Proceed requesting authorisation
			_authorizationCallback = authorizationCallback;
			BluetoothLE.service.addEventListener(AuthorisationEvent.CHANGED, authorisationChangedHandler);
			BluetoothLE.service.requestAuthorisation();
		}
		static private function authorisationChangedHandler( event:AuthorisationEvent ):void {
			setupAuthorizationStatus(event.status);
			if (_authorizationCallback) _authorizationCallback(_hasPermission);
			_authorizationCallback = null;			//_authorizationType = event.status;
		}
		
		
		// CLASS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function DistriqtBluetoothLE(id:String, cl:Class=null){
			super(id, cl ? cl : DistriqtBluetoothLE);
			if (!initialized) Debug.error(_debugPrefix, "Must be initialized with init() before using.");
			//_paWebViewConnected = paWebViewConnected;
		}
		
		// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function setupCentral(devicesNamesToPair:Vector.<String> = null):void {
			if (_setupAsCentral) return;
			_setupAsCentral = true;
			Debug.debug(_debugPrefix, "Setting up as central.");
			BluetoothLE.service.centralManager.addEventListener( PeripheralEvent.DISCOVERED, central_peripheralDiscoveredHandler );
			BluetoothLE.service.centralManager.addEventListener( PeripheralEvent.CONNECT, central_peripheralConnectHandler );
			BluetoothLE.service.centralManager.addEventListener( PeripheralEvent.CONNECT_FAIL, central_peripheralConnectFailHandler );
			BluetoothLE.service.centralManager.addEventListener( PeripheralEvent.DISCONNECT, central_peripheralDisconnectHandler );
			scanForDevices(devicesNamesToPair);
			//traceDebug();
		}
		static public function scanForDevices(devicesNamesToPair:Vector.<String> = null, timeout:uint=4):void {
			if (devicesNamesToPair) _devicesNamesToPair = devicesNamesToPair;
			_eligiblePeripherals = {};
			Debug.debug(_debugPrefix, "Looking for devices: " + _devicesNamesToPair);
			if (BluetoothLE.service.centralManager.isScanning) return; // Scanning is already active
			
			if (!BluetoothLE.service.centralManager.scanForPeripherals()) {
				Debug.error(_debugPrefix, "Bluetooth cannot scan for peripherals.");
			} else {
				UExec.time(timeout, doStopScan);
				PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_SCAN_START);
			}
		}
		static public function stopScan():void {
			Debug.debug(_debugPrefix, "Stopping scan.");
			if (BluetoothLE.service.centralManager.isScanning) {
				BluetoothLE.service.centralManager.stopScan();
				// Setup eligible peripherals list
				_eligiblePeripheralsList = new Vector.<com.distriqt.extension.bluetoothle.objects.Peripheral>();
				for (var u:String in _eligiblePeripherals) {
					_eligiblePeripheralsList.push(_eligiblePeripherals[u]);
				}
			}
		}
		static public function connectToEligiblePeripheral(uuid:String = null):Boolean { // If only one, it connects directly, otherwise returns false and I need the uuid
			Debug.debug(_debugPrefix, "Connecting to eligible peripheral.: ", Debug.object(_eligiblePeripherals));
			if (_eligiblePeripheralsList.length == 0) {
				Debug.error(_debugPrefix, "No eligible peripherals.");
				return false;
			}
			var peripheral:Peripheral;
			if (uuid) {
				peripheral = _eligiblePeripherals[uuid];
				if (!peripheral) {
					Debug.error(_debugPrefix, "No peripheral found with uuid: " + uuid);
					return false;
				}
			} else if (_eligiblePeripheralsList.length > 1) {
				Debug.error(_debugPrefix, "No uuid provided and more than one eligible peripherals found.");
				return false;
			} else peripheral = _eligiblePeripheralsList[0];
			// Connect to the only peripheral available
			Debug.debug(_debugPrefix, "Connecting to peripheral: " + peripheral.name);
			BluetoothLE.service.centralManager.connect(peripheral );
			return true;
			
		}
		static public function scanFirstServiceOfConnectedPeripheral():void {
			Debug.debug(_debugPrefix, "Scanning first service of peripheral.");
			if (!_activePeripheral) {
				Debug.error(_debugPrefix, "Aborted: No active peripheral set.");
				return;
			}
			_notificationCharacteristics = new Vector.<com.distriqt.extension.bluetoothle.objects.Characteristic>();
			_writeCharacteristics = new Vector.<com.distriqt.extension.bluetoothle.objects.Characteristic>();
			_activePeripheral.addEventListener( PeripheralEvent.DISCOVER_SERVICES, peripheral_discoverServicesHandler );
			_activePeripheral.addEventListener( PeripheralEvent.DISCOVER_CHARACTERISTICS, peripheral_discoverCharacteristicsHandler );
			_activePeripheral.discoverServices();
		}
// SCANNING HANDLERS ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				static private function central_peripheralDiscoveredHandler( event:PeripheralEvent ):void{
					// event.peripheral will contain a Peripheral object with information about the Peripheral
					Debug.debug(_debugPrefix,  "peripheral discovered: " + event.peripheral, event.peripheral.identifier, event.peripheral.name, event.peripheral.uuid);
					if (_devicesNamesToPair.indexOf(event.peripheral.name) != -1) {
						if (event.peripheral.name == "" && DO_NOT_ADD_PERIPHERALS_WITH_BLANK_NAME) {
							Debug.warning(_debugPrefix, "Eligible peripheral found but name is blank, therefore it is not added to list.");
							return;
						}
						Debug.debug(_debugPrefix, "Found eligible peripheral. Added to list.");
						_eligiblePeripherals[event.peripheral.uuid] = event.peripheral;
						PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_ELIGIBLE_PERIPHERAL_FOUND);
					}
					//BluetoothLE.service.centralManager.connect( event.peripheral );
				}
				static private function central_peripheralConnectHandler( event:PeripheralEvent ):void{
					trace( "peripheral connected: "+ event.peripheral.toString() ); 
					// Store the peripheral for further interaction
					_activePeripheral = event.peripheral;
					PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_PERIPHERAL_PAIRED, _activePeripheral.uuid);
					scanFirstServiceOfConnectedPeripheral();
				}
				static private function central_peripheralConnectFailHandler( event:PeripheralEvent ):void{
					trace( "peripheral connect fail: "+ event.peripheral.name );    
					_activePeripheral = null;
				}
				static private function central_peripheralDisconnectHandler( event:PeripheralEvent ):void{
					trace( "peripheral disconnect: "+ event.peripheral.name );  
					_activePeripheral = null;
				}
// SCANNING SERVICES AND CHARACTERISTIC HANDLERS ////////////////////////////////////////////////////////////////////////
				static private function peripheral_discoverServicesHandler( event:PeripheralEvent ):void {
					trace( "peripheral discover services: " + event.peripheral.name );
					if (event.peripheral.services.length > 0)
					{
						for each (var service:Service in event.peripheral.services)
						{
							trace( "service: "+ service.uuid );
						}
						// As an example discover the characteristics of the first available service
						//_serviceToScan = peripheral.services[0];
						event.peripheral.discoverCharacteristics( event.peripheral.services[0] );
					}
				}

				static private function peripheral_discoverCharacteristicsHandler( event:PeripheralEvent ):void {
					trace( "peripheral discover characteristics: " + event.peripheral.name );
					for each (var service:Service in event.peripheral.services)
					{
						trace( "service: "+ service.uuid );
						for each (var ch:Characteristic in service.characteristics)
						{
							if (ch.properties.indexOf("read") != -1 && ch.properties.indexOf("notify") != -1) {
								Debug.debug(_debugPrefix, "Found a readable characteristic",ch.uuid,ch.properties);
								_notificationCharacteristics.push(ch);
								_textBufferPerCharacteristicByUuid[ch.uuid] = ""; // Create text buffer for each characteristic
								//if (ch.properties.indexOf("notify") != -1) {
									Debug.debug(_debugPrefix, "Subscribing to notifications for characteristic.");
									event.peripheral.addEventListener( CharacteristicEvent.UPDATE, peripheral_characteristic_updatedHandler );
									event.peripheral.addEventListener( CharacteristicEvent.UPDATE_ERROR, peripheral_characteristic_errorHandler );
									event.peripheral.addEventListener( CharacteristicEvent.SUBSCRIBE, peripheral_characteristic_subscribeHandler );
									event.peripheral.addEventListener( CharacteristicEvent.SUBSCRIBE_ERROR, peripheral_characteristic_subscribeErrorHandler );
									event.peripheral.addEventListener( CharacteristicEvent.UNSUBSCRIBE, peripheral_characteristic_unsubscribeHandler );								
								//}
								if (!event.peripheral.subscribeToCharacteristic( ch )) {
									Debug.error(_debugPrefix, "Characteristic subscription failed.");
								}
							}
							if (ch.properties.indexOf("writeWithoutResponse") != -1) {
								Debug.debug(_debugPrefix, "Found a writable characteristic",ch.uuid,ch.properties);
								_writeCharacteristics.push(ch);
							}
						}
					}
				}
// CHARACTERISTIC SUBSCRIPTION HANDLERS ///////////////////////////////////////////////////////////////////////////////////////
				static private function peripheral_characteristic_updatedHandler( event:CharacteristicEvent ):void {
					addNotificationValue(event.characteristic.uuid, event.characteristic.value.readUTFBytes( event.characteristic.value.length));
					//const uuid:String = event.characteristic.uuid;
					//const value:String = event.characteristic.value.readUTFBytes( event.characteristic.value.length)
					//trace( "peripheral characteristic updated: " + uuid + " : " + value );
					////trace( "value=" + value);
					
				}
				static private function peripheral_characteristic_errorHandler( event:CharacteristicEvent ):void {
					trace( "peripheral characteristic error: [" + event.errorCode +"] "+event.error );
				}
				static private function peripheral_characteristic_subscribeHandler( event:CharacteristicEvent ):void {
					trace( "peripheral characteristic subscribe: " + event.peripheral.name );
				}       
				static private function peripheral_characteristic_subscribeErrorHandler( event:CharacteristicEvent ):void {
					trace( "peripheral characteristic error: [" + event.errorCode +"] "+event.error );
				}       
				static private function peripheral_characteristic_unsubscribeHandler( event:CharacteristicEvent ):void {
					trace( "peripheral characteristic unsubscribe: " + event.peripheral.name );
				}




				// VALUE RECEIVED ANALISYS ///////////////////////////////////////////////////////////////////////////////////////
				static private function addNotificationValue(uuid:String, value:String ):void { // Adds value to buffer
					//if (_textBufferPerCharacteristicByUuid[uuid] != null) {
						_textBufferPerCharacteristicByUuid[uuid] = processTextCommandBuffer(_textBufferPerCharacteristicByUuid[uuid] + value);
					//} else Debug.error(_debugPrefix, "Cannot add value: " +value+" to uuid: " + uuid + " because text buffer was not found");
					//trace(Debug.object(_textBufferPerCharacteristicByUuid));
					//trace("14e49b6a-7cd1-482c-848b-bc77682172a6");
					//trace(_textBufferPerCharacteristicByUuid["14e49b6a-7cd1-482c-848b-bc77682172a6"]);
				}
				static private function processTextCommandBuffer(t:String):String { // Analyzes command and checks whether to start new, end old, or continue
					Debug.debug(_debugPrefix, "Analyzing text: " + t);
					// Check for start index character
					const startOccurrences:int = UText.stringContainsHowmany(t, CHARACTER_COMMAND_START);
					// No start command occurrances
					if (startOccurrences == 0) {
						Debug.debug(_debugPrefix, "No start index detected. Discarding text.");
						return "";
					}
					// Continue with stop check
					const stopOccurrences:int = UText.stringContainsHowmany(t, CHARACTER_COMMAND_STOP);
					if (stopOccurrences == 0) { // No stop occurrances, waiting for one
						//Debug.error(_debugPrefix, "No stop index detected. Discarding text.");
						return t;
					}
					// There is a stop, process whatever is before the stop and return whatever is left afterwards for further checks
					const stopIndex:int = t.indexOf(CHARACTER_COMMAND_STOP);
					const splitStop:Array = t.split(CHARACTER_COMMAND_STOP);
					const textUntilStop:String = splitStop.shift();
					const textAfterStop:String = splitStop.join(CHARACTER_COMMAND_STOP); // Rejoin since there might be more than one stop afterwards
					if (textUntilStop.indexOf(CHARACTER_COMMAND_START) != -1) { // There is a command start in the first sentence, so it is a candidate for a command
						// Process only the last slot after command start and before first command stop. Avoind empty strings ""
						const command:String = textUntilStop.split(CHARACTER_COMMAND_START).pop();
						if (command.length) PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_COMMAND_RECEIVED, command);
					}
					return textAfterStop; // Continue analyzing whatever was after the first stop
					//
					//
					//
					//const textUntilStop:String = t.substring(0, stopIndex);
					//const textAfterStop:String = stopIndex == t.length - 1 ? "" : t.substr(stopIndex + 1); // If stop is the last letter save an empty string, else whatever is behind
					
					
					
					//const startIndex:int = t.indexOf(CHARACTER_COMMAND_START);
					//// one start occurrance
					//if (startOccurrences == 1 && startIndex == 0) { // Only one at the beginning of the word, check as a single command
						//return _processTextCommandBufferSingleSlotWithoutStart(t);
					//}
					//// More than one start. > 1 occurrences. Only process and remove the first occurrance and leave whatever is left
					//Debug.debug(_debugPrefix, "More than one start index found. Processing only first word.");
					//const splitStart:Array = t.split(CHARACTER_COMMAND_START);
					//_processTextCommandBufferSingleSlotWithoutStart(splitStart.shift());
					//return CHARACTER_COMMAND_START + splitStart.join(CHARACTER_COMMAND_START); // Leave whatever is left afterwards putting again start command at the beginning
				}
				//private function _processTextCommandBufferSingleSlotWithoutStart(t:String):String {
					//// Check fro end command
					//var commandComplete:String;
					//if (stopIndex != -1) { // There is a command stop
						//if (stopIndex == t.length -1) {
							//Debug.debug(_debugPrefix, "Command is complete!");
							//commandComplete = t;
							//t = "";
						//} else {
							//const splitStop:Array = t.split(CHARACTER_COMMAND_STOP);
							//commandComplete = splitStop.shift();
							//t = splitStop.length ? splitStop.join(CHARACTER_COMMAND_STOP) : "";
							//Debug.debug(_debugPrefix, "Command is complete but there is something else afterwards: " + t);
						//}
						//PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_COMMAND_RECEIVED, commandComplete);
					//}
					//// Return the initial text or whatever is left
					//return t;
				//}
				
				
				
	
				
		// UTILS
		static private function doStopScan():void { // Stops scanning and broadcasts
			if (BluetoothLE.service.centralManager.isScanning) {
				Debug.debug(_debugPrefix, "Stopping scan due to timeout.");
				stopScan();
				PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_SCAN_STOP);
			} else Debug.debug(_debugPrefix, "Scanning timeout. Scan was already stopped.");
		}
		// DEBUG
		static private function traceDebug():void {
			Debug.debug(_debugPrefix, "Scanning:",BluetoothLE.service.centralManager.isScanning," peripherals: ", BluetoothLE.service.centralManager.peripherals );
			UExec.time(5, traceDebug);
		}
	// ////////
		// GETTERS ///////////////////////////////////////////////////////////////////////////////////////
		static public function get initialized():Boolean {
			return _initialized;
		}
		static public function get hasPermission():Boolean {
			return _hasPermission;
		}
		
		static public function get eligiblePeripherals():Object {
			return _eligiblePeripherals;
		}
		
		static public function get activePeripheral():Peripheral 	{
			return _activePeripheral;
		}
		
		static public function get eligiblePeripheralsList():Vector.<Peripheral> {
			return _eligiblePeripheralsList;
		}
		static public function get eligiblePeripheralsNames():Vector.<String> {
			var names:Vector.<String> = new Vector.<String>(_eligiblePeripherals.length);
			for (var i:int = 0; i < _eligiblePeripheralsList.length; i++) {
				names[i] = _eligiblePeripheralsList[i].name;
			}
			return names;
		}		
	}
}