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
	import flash.utils.ByteArray;
	
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
		static public var TARGET_NOTIFICATION_CHARACTERISTICS:uint = 1; // Amount of characteristics necessary to trigger pairing completed
		static public var TARGET_WRITABLE_CHARACTERISTICS:uint = 1;
		// STATIC ///////////////////////////////////////////////////////////////////////////////////////
		static private var  _initialized:Boolean;
		static private var _hasPermission:Boolean;
		static private var _isOn:Boolean;
		//static private var _authorizationType:String;
		static private var _debugPrefix:String = "BluetoothLE";
		static private var _initCallback:Function;
		// Bluetooth system
		static private var _setupAsCentral:Boolean;
		static private var _devicesNamesToPair:Vector.<String> = new Vector.<String>();
		static private var _pairingComplete:Boolean;
		// Bluetooth connection
		static private var _discoveredPeripherals:Object; // Stores peripherals already discovered to avoid infinite trace in Android (keeps discovering the same peripherals all the time)
		static private var _activePeripheral:Peripheral;
		static private var _periferalNameFound:Boolean;
		static private var _eligiblePeripherals:Object; // Peripherals by uuid
		static private var _eligiblePeripheralsList:Vector.<Peripheral>; // List of peripherals
		static private var _serviceToScan:Service;
		static private var _notificationCharacteristics:Vector.<Characteristic>; // List of Characteristic subscribed for notification, read, notify
		static private var _writeCharacteristics:Vector.<Characteristic>; // List of Characteristic to send data to, writeWithoutResponse
		// Target elements to connect to
		static private var _targetServiceID:String; // The service ID I want to connect to (first one in list if blank)
		static private var _targetReadNotifyCharacteristic:String; // UYdid of the read/noitify characteristic to subscribe to
		static private var _targetWriteCharacteristic:String; // Udid of the write or writewithoutResponse characteristic to subscribe to
		
		// Bluetooth communication
		static private var _textBufferPerCharacteristicByUuid:Object = {}; // udid:String
 		// EVENTS - INITIALIZATION AND CONNECTION
		public static const EVT_HARDWARE_STATE_ON:String = "onBluetoothHardwareStateOn";
		public static const EVT_HARDWARE_STATE_OFF:String = "onBluetoothHardwareStateOff";
		public static const EVT_AUTHORIZATION_CHANGE:String = "onBluetoothAuthorizationChange";
		public static const EVT_AUTHORIZATION_PROVIDED:String = "onBluetoothAuthorizationProvided";
		public static const EVT_AUTHORIZATION_SHOULDEXPLAIN:String = "onBluetoothAuthorizationShouldExplain";
		public static const EVT_AUTHORIZATION_DENIED:String = "onBluetoothAuthorizationDenied";
		public static const EVT_SCAN_START:String = "onBluetoothLEScanStart";
		public static const EVT_SCAN_STOP:String = "onBluetoothLEScanStop";
		public static const EVT_ELIGIBLE_PERIPHERAL_FOUND:String = "onBluetoothLEEligiblePeripheralFound";
		public static const EVT_PERIPHERAL_PAIRED:String = "onBluetoothLEPeripheralPaired"; // uuid:String
		public static const EVT_PERIPHERAL_CHARACTERISTIC_SUBSCRIBED:String = "onBluetoothLEPeripheralCharacteristicSubscribed"; // c:Characteristic - one characteristic has been subscribed
		public static const EVT_FIRST_SERVICE_SETUP:String = "onBluetoothLEFirstServiceSetup";
		public static const EVT_PAIRING_SEQUENCE_COMPLETE:String = "onBluetoothLEPairingComplete"; // Pairing sequence and characteristics subscription complete
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
				//_DistriqtAne.initCore();
				//BluetoothLE.init();
				Debug.debug(_debugPrefix, "Initializing ver " + BluetoothLE.VERSION);
				_initialized = true;
				updateHardwareState(false, "init");
				updateAuthorizationStatus(false, false, "init");
				BluetoothLE.service.addEventListener(BluetoothLEEvent.STATE_CHANGED, stateChangedHandler);
				//_authorizationType = BluetoothLE.service.authorisationStatus();
				//analyzeAuthorization(false);
			} else Debug.error(_debugPrefix, "NOT SUPPORTED ON THIS PLATFORM");
			return _initialized;
		}
		
		
		// BLE HARDWARE STATE ///////////////////////////////////////////////////////////////////////////////////////
		static private function stateChangedHandler(event:BluetoothLEEvent):void {
			Debug.debug(_debugPrefix, "Hardware State Changed");
			updateHardwareState(true, "stateChangedHandler");
			//if (USystem.isAndroid() && BluetoothLE.service.state == BluetoothLEState.STATE_UNAUTHORISED)
		}
		static private function updateHardwareState(broadcast:Boolean=true, msg:String="no msg", forceOn:Boolean=false):void {
			//_authorizationType = BluetoothLE.service.authorisationStatus();
			Debug.debug(_debugPrefix, "updateHardwareState: "+BluetoothLE.service.state+" (" + msg + ")");
			_isOn = forceOn;
			switch (BluetoothLE.service.state) {
				case BluetoothLEState.STATE_ON: 
					_isOn = true;
					break;
				case BluetoothLEState.STATE_OFF:
					break;
				case BluetoothLEState.STATE_RESETTING:  
					break;
				case BluetoothLEState.STATE_UNAUTHORISED:   
					//_isOn = true; // This still means hardware is ON. Authorisation will be asked for later.
					break;
				case BluetoothLEState.STATE_UNSUPPORTED:    
					break;
				case BluetoothLEState.STATE_UNKNOWN:
					break;
			}
			if (broadcast) PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, _isOn ? EVT_HARDWARE_STATE_ON : EVT_HARDWARE_STATE_OFF);
		}
		// BLE AUTHORIZATION ///////////////////////////////////////////////////////////////////////////////////////
		static public function requestAuthorization():void {
			Debug.debug(_debugPrefix, "Requesting Bluetooth Authorisation.");
			// Proceed requesting authorisation
			updateAuthorizationStatus(false, false, "requestAuthorization"); // Update authorisation before checking
			if (hasPermission) {
				Debug.debug(_debugPrefix, "Bluetooth already authorised.");
				updateAuthorizationStatus(false, true, "hasPermission"); // Broadcasts permissions without asking for auth changed
				return;
			}
			// Proceed requesting authorisation
			else {
				BluetoothLE.service.addEventListener(AuthorisationEvent.CHANGED, authorisationChangedHandler);
				UExec.next(BluetoothLE.service.requestAuthorisation);
			}
		}
		static private function authorisationChangedHandler( event:AuthorisationEvent ):void {
			BluetoothLE.service.removeEventListener(AuthorisationEvent.CHANGED, authorisationChangedHandler);
			updateAuthorizationStatus(false, true, "authorisationChangedHandler");
		}
		static private function updateAuthorizationStatus(askAgain:Boolean=false, broadcast:Boolean=false, msg:String="no msg"):void {
			//_authorizationType = BluetoothLE.service.authorisationStatus();
			Debug.debug(_debugPrefix, "updateAuthorizationStatus: "+BluetoothLE.service.authorisationStatus()+" (" + msg + ")");
			_hasPermission = false;
			switch (BluetoothLE.service.authorisationStatus()) {
				case AuthorisationStatus.AUTHORISED:
					_hasPermission = true;
					if (broadcast) PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_AUTHORIZATION_PROVIDED);
					break;
				case AuthorisationStatus.NOT_DETERMINED:
					break;
				case AuthorisationStatus.SHOULD_EXPLAIN:
					// The user has not yet been asked or 
					// has denied once and you should explain
					if (broadcast) PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_AUTHORIZATION_SHOULDEXPLAIN);
					break;
				case AuthorisationStatus.DENIED:
					if (broadcast) PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_AUTHORIZATION_DENIED);
					break;
				case AuthorisationStatus.RESTRICTED:
					break;
				case AuthorisationStatus.UNKNOWN:
					break;
			}
			if (broadcast) PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_AUTHORIZATION_CHANGE);
			if (!_hasPermission && askAgain) {
				Debug.debug(_debugPrefix, "Authorization not granted, I ask again.");
				requestAuthorization();
			}
		}
		
		
// CLASS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		public function DistriqtBluetoothLE(id:String, cl:Class=null){
			super(id, cl ? cl : DistriqtBluetoothLE);
			if (!initialized) Debug.error(_debugPrefix, "Must be initialized with init() before using.");
			//_paWebViewConnected = paWebViewConnected;
		}
		
// METHODS ///////////////////////////////////////////////////////////////////////////////////////
	// SETUP AND SCAN
		static public function setupCentral(devicesNamesToPair:Vector.<String> = null):void {
			//if (_setupAsCentral) return;
			_setupAsCentral = true;
			Debug.debug(_debugPrefix, "Setting up as central.");
			BluetoothLE.service.centralManager.addEventListener( PeripheralEvent.DISCOVERED, central_peripheralDiscoveredHandler );
			BluetoothLE.service.centralManager.addEventListener( PeripheralEvent.CONNECT, central_peripheralConnectHandler );
			BluetoothLE.service.centralManager.addEventListener( PeripheralEvent.CONNECT_FAIL, central_peripheralConnectFailHandler );
			BluetoothLE.service.centralManager.addEventListener( PeripheralEvent.DISCONNECT, central_peripheralDisconnectHandler );
			scanForDevices(devicesNamesToPair);
			//traceDebug();
		}
		static public function scanForDevices(devicesNamesToPair:Vector.<String> = null, timeout:uint=30):void {
			if (devicesNamesToPair) _devicesNamesToPair = devicesNamesToPair;
			_eligiblePeripherals = {};
			_discoveredPeripherals = {};
			Debug.debug(_debugPrefix, "Looking for devices now: " + _devicesNamesToPair + " is scalling: "  + BluetoothLE.service.centralManager.isScanning + " peripherals: " + BluetoothLE.service.centralManager.peripherals.length + " state: " + BluetoothLE.service.centralManager.state);
			if (BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_UNKNOWN) {
				Debug.warning(_debugPrefix, "State is UnKNOWN - retrying in 3 seconds.");
				UExec.time(3, scanForDevices, devicesNamesToPair, timeout);
				return;
			}
			if (BluetoothLE.service.centralManager.isScanning) {
				Debug.debug(_debugPrefix, "Scanning is already active. Aborting.");
				return; // Scanning is already active
			}
			
			if (!BluetoothLE.service.centralManager.scanForPeripherals()) {
				Debug.error(_debugPrefix, "Bluetooth cannot scan for peripherals.");
			} else {
				UExec.time(timeout, stopScan);
				Debug.debug(_debugPrefix, "Starting scan...");
				PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_SCAN_START);
			}
		}
		static public function stopScan():void {
			Debug.debug(_debugPrefix, "Stopping scan.");
			doStopScan();
		}
		/**
		 * Connects one of the eligible peripherals. 
		 * @param	uuid The uuid of peripheral to conect to (otherwise will be the first)
		 * @param	targetServiceId The udid of service to subscribe to (otherwise first will be used)
		 * @return 	Returns true if it can connect to an eligible peripheral or fals eif no eligible peripherals are there
		 */
		static public function connectToEligiblePeripheral(uuid:String = null, targetServiceId:String=null):Boolean { 
			_pairingComplete = false;
			_targetServiceID = targetServiceId;
			Debug.debug(_debugPrefix, "Connecting to eligible peripheral.: ", Debug.object(_eligiblePeripherals));
			if (_eligiblePeripheralsList.length == 0) {
				Debug.error(_debugPrefix, "No eligible peripherals.");
				return false;
			}
			if (_eligiblePeripheralsList.length == 0) {
				Debug.error(_debugPrefix, "No eligible peripherals in list. Cannot connect.");
				return false;
			}
			var peripheral:Peripheral;
			if (uuid) {
				peripheral = _eligiblePeripherals[uuid];
				if (!peripheral) {
					Debug.warning(_debugPrefix, "No peripheral found with uuid: " + uuid + " - connecting to the first one found.");
				}
			}
			if (!peripheral && _eligiblePeripheralsList.length > 1) {
				Debug.warning(_debugPrefix, "Several eligible peripherals found: " + _eligiblePeripheralsList.length);
			}
			if (!peripheral) {
				Debug.debug(_debugPrefix, "Connecting to the first peripheral in list.");
				peripheral = _eligiblePeripheralsList[0];
			}
			// Connect to the only peripheral available
			Debug.debug(_debugPrefix, "Connecting to peripheral: " + peripheral.name);
			BluetoothLE.service.centralManager.connect(peripheral );
			return true;
			
		}
		static private function scanFirstServiceOfConnectedPeripheral():void {
			Debug.debug(_debugPrefix, "Scanning first service of peripheral.");
			if (_targetServiceID) Debug.debug(_debugPrefix, "Will try to connect to service: " + _targetServiceID);
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
	// COMMUNICATION
		static public function write(t:String, writeCharacteristicIndex:uint = 0, encloseInBrackets:Boolean=true):Boolean {
			if (encloseInBrackets) t = encloseInCommandBrackets(t);
			/* PROVO AD ACCORCIARE LA STRINGA */
			//t = "ff";
			Debug.debug(_debugPrefix, "Writing to Characteristic " + writeCharacteristicIndex + " : " + t);
			if (!_pairingComplete) {
				Debug.error(_debugPrefix, "Cannot write. Bluetooth not paired completely.");
				return false;
			}
			var value:ByteArray = new ByteArray();
			value.writeUTFBytes(t);
			/* SOMETIMES THERES AN ERROR HERE */
			if (!activePeripheral) Debug.error(_debugPrefix, "activePeripheral NOT FOUND.");
			if (!_writeCharacteristics) Debug.error(_debugPrefix, "_writeCharacteristics NOT FOUND.");
			try { // These traces are error prone
				Debug.debug(_debugPrefix, "Writing to charateristic: peripheral: " + activePeripheral.uuid + ",  characteristic("+_writeCharacteristics[writeCharacteristicIndex]+"): " + _writeCharacteristics[writeCharacteristicIndex].uuid + " : " + _writeCharacteristics[writeCharacteristicIndex].permissions + " : " + _writeCharacteristics[writeCharacteristicIndex].properties+ " : " + _writeCharacteristics[writeCharacteristicIndex].value);
			}
			catch (e:Error) {};
			if (!_writeCharacteristics[writeCharacteristicIndex]) {
				Debug.error(_debugPrefix, "_writeCharacteristics[writeCharacteristicIndex] NOT FOUND.");
				return false;
			}
			if (!activePeripheral) {
				Debug.error(_debugPrefix, "activePeripheral NOT FOUND.");
				return false;
			}
			var success:Boolean = activePeripheral.writeValueForCharacteristic(_writeCharacteristics[writeCharacteristicIndex], value);
			if (success) Debug.debug(_debugPrefix, "Message sent: " + t);
			else Debug.error(_debugPrefix, "Message sending error: " + t);
			return success;
		}
		static public function encloseInCommandBrackets(t:String):String {
			return CHARACTER_COMMAND_START + t + CHARACTER_COMMAND_STOP;
		}
// SCANNING HANDLERS ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				static private function central_peripheralDiscoveredHandler( event:PeripheralEvent ):void{
					if (_discoveredPeripherals[event.peripheral.uuid]) {
						/* PERIPHERAL ALREADY DISCOVERED */
						return;
					}
					// event.peripheral will contain a Peripheral object with information about the Peripheral
					Debug.debug(_debugPrefix,  "peripheral discovered: " + event.peripheral, event.peripheral.identifier, event.peripheral.name, event.peripheral.uuid);
					_discoveredPeripherals[event.peripheral.uuid] = event.peripheral;
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
// SCANNING SERVICES AND CHARACTERISTIC SUBSCRIPTION ////////////////////////////////////////////////////////////////////////
				static private function peripheral_discoverServicesHandler( event:PeripheralEvent ):void {
					Debug.debug(_debugPrefix, "Discovered peripheral services: " + event.peripheral.services.length);
					//var serviceFoundForTargetID:Service;
					if (event.peripheral.services.length > 0) {
						for each (var service:Service in event.peripheral.services){
							Debug.debug(_debugPrefix, "Discovered service: " + service.uuid);
							//event.peripheral.discoverCharacteristics(service);
							if (_targetServiceID == service.uuid) {
								Debug.debug(_debugPrefix, "Found target service ID. Subscribing.");
								event.peripheral.discoverCharacteristics(service);
								return; // Break cycle since target service has been found
							}
						}
						if (_targetServiceID) {
							Debug.error(_debugPrefix, "Target service Id not found: " + _targetServiceID + ", aborting.");
						} else {
							Debug.debug(_debugPrefix, "Subscribing to characteristics for the first service in list: " + event.peripheral.services[0].uuid);
							event.peripheral.discoverCharacteristics(event.peripheral.services[0]);
						}
					}
				}
				static private function peripheral_discoverCharacteristicsHandler( event:PeripheralEvent ):void {
					Debug.debug(_debugPrefix, "Characteristics retrieved for " + event.peripheral.name );
					for each (var service:Service in event.peripheral.services) {
						for each (var ch:Characteristic in service.characteristics)
						{
							var connect:Boolean = true;
							Debug.debug(_debugPrefix, "Checking characteristic with properties: ",ch.uuid,ch.properties);
							if (ch.properties.indexOf("read") != -1 && ch.properties.indexOf("notify") != -1) {
								if (_targetReadNotifyCharacteristic) {
									if (_targetReadNotifyCharacteristic == ch.uuid) Debug.debug(_debugPrefix, "Characteristic read & notify matches target UDID.");
									else {
										Debug.debug(_debugPrefix, "Characteristic read & notify does not match target UDID.");
										connect = false;
									}
								} else Debug.debug(_debugPrefix, "No target UDID set for read & notify characteristic, subscribing.");
								if (connect) {
									subscribeToCharacteristicCommonEvents(event.peripheral, ch);
									subscribeToCharacteristicNotificationEvents(event.peripheral, ch);
								}
							}
							if (ch.properties.indexOf("writeWithoutResponse") != -1 || ch.properties.indexOf("write") != -1) {
								if (_targetWriteCharacteristic) {
									if (_targetWriteCharacteristic == ch.uuid) Debug.debug(_debugPrefix, "Characteristic write or writeWithoutResponse matches target UDID.");
									else {
										Debug.debug(_debugPrefix, "Characteristic write or writeWithoutResponse does not match target UDID.");
										connect = false;
									}
								} else Debug.debug(_debugPrefix, "No target UDID set for write or writeWithoutResponse characteristic, subscribing.");
								if (connect) {
									subscribeToCharacteristicCommonEvents(event.peripheral, ch);
									subscribeToCharacteristicWritableEvents(event.peripheral, ch);
								}
							}
						}
					}
					// Check for initialization complete
					if (!_pairingComplete && _writeCharacteristics.length >= TARGET_WRITABLE_CHARACTERISTICS && _notificationCharacteristics.length >= TARGET_NOTIFICATION_CHARACTERISTICS) {
						Debug.debug(_debugPrefix, "Device pairing is complete.");
						_pairingComplete = true;
						PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_PAIRING_SEQUENCE_COMPLETE);
					}
				}
				static private function subscribeToCharacteristicNotificationEvents(peripheral:Peripheral, ch:Characteristic):void {
					Debug.debug(_debugPrefix, "Subscribing to notifications for characteristic: " + ch.uuid);
					_notificationCharacteristics.push(ch);
					_textBufferPerCharacteristicByUuid[ch.uuid] = ""; // Create text buffer for each characteristic
					peripheral.addEventListener( CharacteristicEvent.UPDATE, peripheral_characteristic_updatedHandler );
					peripheral.addEventListener( CharacteristicEvent.UPDATE_ERROR, peripheral_characteristic_errorHandler );
					if (!peripheral.subscribeToCharacteristic( ch )) {
						Debug.error(_debugPrefix, "Characteristic subscription failed!");
					}
				}
				static private function subscribeToCharacteristicWritableEvents(peripheral:Peripheral, ch:Characteristic):void {
					Debug.debug(_debugPrefix, "Subscribing to a writable characteristic: " + ch.uuid);
					_writeCharacteristics.push(ch);
					peripheral.addEventListener( CharacteristicEvent.WRITE_SUCCESS, peripheral_characteristic_writeHandler  );
					peripheral.addEventListener( CharacteristicEvent.WRITE_ERROR, peripheral_characteristic_writeErrorHandler  );
				}
				static private function subscribeToCharacteristicCommonEvents(peripheral:Peripheral, ch:Characteristic):void {
					peripheral.addEventListener( CharacteristicEvent.SUBSCRIBE, peripheral_characteristic_subscribeHandler );
					peripheral.addEventListener( CharacteristicEvent.SUBSCRIBE_ERROR, peripheral_characteristic_subscribeErrorHandler );
					peripheral.addEventListener( CharacteristicEvent.UNSUBSCRIBE, peripheral_characteristic_unsubscribeHandler );								
				}
// CHARACTERISTIC HANDLERS AND UTY ///////////////////////////////////////////////////////////////////////////////////////
		// SUBSCRIPTION HANDLERS
				static private function peripheral_characteristic_subscribeHandler( event:CharacteristicEvent ):void {
					Debug.debug(_debugPrefix, "Successfully subscribed to characteristic: "+ event.peripheral.name, event.characteristic.uuid);
					PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_PERIPHERAL_CHARACTERISTIC_SUBSCRIBED, event.characteristic);
				}       
				static private function peripheral_characteristic_subscribeErrorHandler( event:CharacteristicEvent ):void {
					trace( "peripheral characteristic subscribe error: [" + event.errorCode +"] "+event.error );
				}       
				static private function peripheral_characteristic_unsubscribeHandler( event:CharacteristicEvent ):void {
					trace( "peripheral characteristic unsubscribe: " + event.peripheral.name );
				}
		// NOTIFICATION HANDLERS
				static private function peripheral_characteristic_updatedHandler( event:CharacteristicEvent ):void {
					addNotificationValue(event.characteristic.uuid, event.characteristic.value.readUTFBytes( event.characteristic.value.length));
				}
				static private function peripheral_characteristic_errorHandler( event:CharacteristicEvent ):void {
					trace( "peripheral characteristic notification error: [" + event.errorCode +"] "+event.error );
				}
		// WRITING HANDLERS
				static private function peripheral_characteristic_writeHandler( event:CharacteristicEvent ):void {
					Debug.debug(_debugPrefix, "peripheral characteristic write success." );
				}
				static private function peripheral_characteristic_writeErrorHandler( event:CharacteristicEvent ):void {
					Debug.debug(_debugPrefix, "peripheral characteristic write error: [" + event.errorCode +"] "+event.error );
				}
		// NOTIFICATION ANALISYS ///////////////////////////////////////////////////////////////////////////////////////
				static private function addNotificationValue(uuid:String, value:String ):void { // Adds value to buffer
					_textBufferPerCharacteristicByUuid[uuid] = processTextCommandBuffer(_textBufferPerCharacteristicByUuid[uuid] + value);
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
						if (command.length) { 
							PippoFlashEventsMan.broadcastStaticEvent(DistriqtBluetoothLE, EVT_COMMAND_RECEIVED, command);
						}
					}
					return textAfterStop; // Continue analyzing whatever was after the first stop
				}
				
				
		// UTILS
		static private function doStopScan():void { // Stops scanning and broadcasts
			if (BluetoothLE.service.centralManager.isScanning) {
				BluetoothLE.service.centralManager.stopScan();
				// Setup eligible peripherals list
				_eligiblePeripheralsList = new Vector.<com.distriqt.extension.bluetoothle.objects.Peripheral>();
				for (var u:String in _eligiblePeripherals) {
					_eligiblePeripheralsList.push(_eligiblePeripherals[u]);
				}
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
		static public function get isOn():Boolean {
			updateHardwareState(false, "_isOn getter");
			return _isOn;
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
		// SETTERS ///////////////////////////////////////////////////////////////////////////////////////
		static public function set targetReadNotifyCharacteristic(value:String):void 
		{
			_targetReadNotifyCharacteristic = value;
		}
		
		static public function set targetWriteCharacteristic(value:String):void 
		{
			_targetWriteCharacteristic = value;
		}
		
	}
}