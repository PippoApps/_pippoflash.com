/* UAir - ver 0.1 - Filippo Gregoretti - www.pippoflash.com

Performs typical Air actions and utilities.

*/

package com.pippoflash.framework.air.ane.mfl {
// IMPORTS ///////////////////////////////////////////////////////////////////////////////////////
	import com.pippoflash.utils.*; // PippoFlash
	import flash.display.*; 
	import flash.events.*; 
	import flash.media.*; 
	import flash.net.*; 
	import flash.system.*; 
	import flash.text.*; 
	import flash.utils.*; 
	import flash.geom.*;
	import flash.external.*;
	import flash.html.*;
	// MyFlashLabs
	import com.myflashlab.air.extensions.billing.Billing;
	import com.myflashlab.air.extensions.billing.BillingType;
	import com.myflashlab.air.extensions.billing.Purchase;
	import com.myflashlab.air.extensions.billing.Product;
	
// CLASS ///////////////////////////////////////////////////////////////////////////////////////
	public class ANEBilling {
	// VARIABLES ///////////////////////////////////////////////////////////////////////////////////////
		// DEBUG SWITCHES
		// CONSTANTS
		private static const _debugPrefix:String = "ANEBilling";
		// REFERENCES
		static private var _initCallback:Function; // Boolean as parameter - true success false error
		static private var _permPurchasesCallback:Function; // Array as parameter for success (empty or full), null if error
		static private var _purchaseCallback:Function; // success:Boolean, productId:String=null, devMsg:String=null. - If failed, nothing else is returned
		static private var _subPurchasesCallback:Function; 
		// FRAMERATE
		// DATA
		static private var _permPurchases:Array; // Stores permanent purchases
		// AIR DEVICE ID
		// MARKERS
		static private var _init:Boolean;
		static private var _simulation:Boolean;
		// UTY
	// INIT ///////////////////////////////////////////////////////////////////////////////////////
		static public function setCallbacks(initCallback:Function, consumablePurchasesCallback:Function, permanentPurchasesCallback:Function, subscriptionPurchasesCallback:Function):void {
			_initCallback = initCallback;
			_permPurchasesCallback = permanentPurchasesCallback;
			_purchaseCallback = consumablePurchasesCallback;
			_subPurchasesCallback = subscriptionPurchasesCallback;
		}
		public static function init(androidKey:String, androidProducts:Array, iosProducts:Array, debugMode:Boolean = false):void {
			// Check if this is a second initialization, which is not required
			if (isActive()) onBillingInitResult(1, "SECOND INITIALIZATION SKIPPED");
			// Check if callbacks are setup
			if (!_initCallback) {
				Debug.error(_debugPrefix, "Cannot call init(), please call setCallbacks before.");
				return;
			}
			// Convert android products to string
			//var realProducts:Array = USystem.isIOS() ? iosProducts : androidProducts;
			var androidStringProducts:Array = [];
			var iosStringProducts:Array = [];
			var product:*;
			for each (product in androidProducts) androidStringProducts.push(String(product));
			for each (product in iosProducts) iosStringProducts.push(String(product));
			// Proceed
			if (USystem.isAndroid()) Debug.debug(_debugPrefix, "Initializing billing with android key " + androidKey + "\nProduct IDs: " + androidStringProducts);
			else if (USystem.isIOS()) Debug.debug(_debugPrefix, "Initialising on iOS with products: " + iosStringProducts);
			if (debugMode) Debug.warning(_debugPrefix, "Billing is initialized in DEBUG MODE.");
			Billing.IS_DEBUG_MODE = debugMode;
			if (USystem.isRunningOnDesktop()) { // This only works on iOS or Android, on desktop test it works in simulation mode
				_simulation = true;
				Debug.warning(_debugPrefix, "ATTENTION - App is running in desktop debug mode. ANEBilling will work in SIMULATION mode.");
				onBillingInitResult(1, "SIMULATED INITIALIZATION");
			}
			else Billing.init(androidKey, androidStringProducts, iosStringProducts, onBillingInitResult);
		}
		static private function onBillingInitResult(status:int, msg:String):void {
			if (status) {
				Debug.debug(_debugPrefix, "Initialization Successful: " + msg);
				_init = true;
			} else {
				Debug.error(_debugPrefix, "Initialization error: " + msg);
				_init = false;
			}
			_initCallback(_init); // Call listener method with success status
		}
	// METHODS ///////////////////////////////////////////////////////////////////////////////////////
		static public function isActive():Boolean {
			return _init;
		}
		static public function isSimulation():Boolean {
			return _simulation;
		}
		static public function getPermanentPurchases():void { // Loads whatever static purchase (not consumable) user has already done on store
			Billing.getPurchases(onPermPurchasesResult);
		}
		static public function clearCache():void {
			Debug.warning(_debugPrefix, "Clearing purchases cache...");
			Billing.clearCache();
		}
		// Purchase methods are divided in 3: consumable, permanent and subscription.
		static public function purchaseConsumable(itemId:*, payloadMessage:String = ""):void {
			Debug.debug(_debugPrefix, "Purchasing: " + itemId + ". Message: " + payloadMessage);
			// Simulate purchase
			if (isSimulation()) {
				var success:Boolean = Math.random() < 0.8;
				Debug.warning(_debugPrefix, "Purchase is made in simulation mode. Success is: " + success);
				UExec.time(1, onSimulationPurchase, success, BillingType.CONSUMABLE, String(itemId), payloadMessage); // Send simulated callback after 1 second
			}
			// Regular purchase
			else {
				Debug.debug(_debugPrefix, "Processing a purchase on Device: " + itemId);
				Billing.doPayment(BillingType.CONSUMABLE, String(itemId), payloadMessage, onPurchaseResult);
			}
		}
		static public function consumeConsumablePurchase(purchaseId:String):void {
			// Consumable purchases are locally stored in case they have not been consumed
			// There will be a server consuming purchase, and notiying client
			// Client can then call this method if purchase has been successfully deleted
			Debug.debug(_debugPrefix, "Removing from client cache consulable purchase: " + purchaseId);
		}
	// LISTENERS ///////////////////////////////////////////////////////////////////////////////////////
		// Permanent retrieved purchases
		static private function onPermPurchasesResult(purchases:Array):void {
			if (purchases) { // means we have successfully connected the server.
				_permPurchases = purchases;
				if (purchases.length > 0) {
					
					var purchaseData:Purchase;
					var lng:int = purchases.length;
					var i:int;
					
					for (i = 0; i < lng; i++) {
						purchaseData = purchases[i];
						trace("----------------");
						trace("purchaseData.orderId = " + purchaseData.orderId);
						trace("purchaseData.productId = " + purchaseData.productId);
						trace("purchaseData.purchaseState = " + purchaseData.purchaseState);
						trace("purchaseData.purchaseTime = " + purchaseData.purchaseTime);
						trace("purchaseData.purchaseToken = " + purchaseData.purchaseToken);
						trace("----------------");
					}
				}
			else { // if it's an empty Array, it means there are no purchase records for this user on the server.
					Debug.debug(_debugPrefix, "There are no purchase records for this user on Google or Apple servers.");
				}
				// Broadcast with empty or full array
				_permPurchasesCallback(_permPurchases);
			}
			else {
					Debug.error(_debugPrefix, "Error while trying to get the list of previously purchased records. Calling callback with null as parameter.")
					_permPurchasesCallback(null);
			}
			// Clear callback
			_permPurchasesCallback = null;
		}
		// Regular purchases
		static private function onPurchaseResult(status:int, data:Purchase = null, msg:String = ""):void {
			Debug.debug(_debugPrefix, "Purchase result received: " + data);
			// Process success/failure
			var success:Boolean = Boolean(status);
			// Find correct variables (defaults are set for simulation mode)
			var billingType:uint = data ? data.billingType : 1; // Default to 1
			var productId:String = data ? data.productId : null; // Default to 0
			var developerPayload:String = data ? data.productId : null;
			var purchaseToken:String = data ? data.purchaseToken : "purchase_token";
			// Call the correct callback
			// Find the correct callback according to billing type
			var callback:Function;
			if (billingType == BillingType.CONSUMABLE) callback = _purchaseCallback;
			else if (billingType == BillingType.PERMANENT) callback = _permPurchasesCallback;
			else if (billingType == BillingType.AUTO_RENEWAL) callback = _subPurchasesCallback;
			trace("callback == _purchaseCallback", callback == _purchaseCallback);
			trace("callback == _permPurchasesCallback", callback == _permPurchasesCallback);
			trace("callback == _subPurchasesCallback", callback == _subPurchasesCallback);
			// PROCESS SUCCESS OR FAILURE
			if (success) {
				// Generate info string
				var purchaseInfo:String = "Purchase info:";
				if (data) {
					purchaseInfo += "\n" + ("----------------");
					purchaseInfo += "\n" + ("data.billingType = " + data.billingType);
					purchaseInfo += "\n" + ("data.orderId = " + data.orderId);
					purchaseInfo += "\n" + ("data.developerPayload = " + data.developerPayload);
					purchaseInfo += "\n" + ("data.productId = " + data.productId);
					purchaseInfo += "\n" + ("data.purchaseState = " + data.purchaseState);
					purchaseInfo += "\n" + ("data.purchaseTime = " + data.purchaseTime);
					purchaseInfo += "\n" + ("data.purchaseToken = " + data.purchaseToken);
					if(Billing.os == Billing.ANDROID)
					 {
						purchaseInfo += "\n" + ("data.autoRenewing = " + data.autoRenewing);
						purchaseInfo += "\n" + ("data.signature = " + data.signature);
					 }					
					 else {
						purchaseInfo += "\n" + ("data.iOSReceipt = " + Billing.iOSReceipt);
					 }
					 purchaseInfo += "\n" + ("----------------");
				}
				else purchaseInfo += " no Purchase instance received.";
				Debug.debug(_debugPrefix, "Purchase successful:\n" + msg + "\n" + purchaseInfo);
				callback(success, productId, data as Object, msg, Billing.iOSReceipt);
			}
			else { 
				Debug.error(_debugPrefix, "Purchase failed: " + msg);
				callback(false);
			}
			// this is probably the right spot to process purchase
			UExec.frame(10, clearCache);
			
			
			
			//if (msg == Billing.ALREADY_OWNED_ITEM) {
				//trace(msg);
			//}
			//else if (msg == Billing.NOT_FOUND_ITEM) {
				//trace(msg);
			//}
			//else	{
				//trace("purchase result message = " + msg);
			//}
			//
			//if (data) {
				//trace("----------------");
				//trace("data.billingType = " + 			data.billingType);
				//trace("data.orderId = " + 				data.orderId);
				//trace("data.developerPayload = " + 	data.developerPayload);
				//trace("data.productId = " +			data.productId);
				//trace("data.purchaseState = " +		data.purchaseState);
				//trace("data.purchaseTime = " +			data.purchaseTime);
				//trace("data.purchaseToken = " +		data.purchaseToken);
				//trace("----------------");
			//}
			
			/* - IMFORMATION ON Purchase PROPERTIES -

				billingType	property
				public var billingType:int = -1
				After a successful payment operation, this value will be one of the following types, BillingType.PERMANENT, BillingType.CONSUMABLE or BillingType.AUTO_RENEWAL.

				NOTICE: This property value is NOT saved in the cache. Meaning that when you restore your products or call Billing.getPurchases() you will always receive -1 for this value. you can use this value ONLY when the purchase result is returned as a successful operation.

				See also

				BillingType
				developerPayload	property	 
				public var developerPayload:String
				developerPayload is a short developer-specified string you may optionally use when letting users make payments. When the transfer is completed successfully, this value will be returned along with the rest of the payment details so you can check the payment legitimation before letting users access your software packages. This is just an extra step for securing your payments and using it is totaly optional.

				NOTICE: This property value is NOT saved in the cache. Meaning that when you restore your products or call Billing.getPurchases() you will receive and empty string for this value. you can use this value ONLY when the purchase result is returned as a successful operation.

				orderId	property	 
				public var orderId:String
				order id is a unique string which identifies the order. on iOS platform, this value is equal to purchaseToken

				See also

				purchaseToken
				productId	property	 
				public var productId:String
				A string used to identify a product that can be purchased from within your application.

				purchaseState	property	 
				public var purchaseState:int
				The purchase state of the order. On Android, possible values are 0 (purchased), 1 (canceled), or 2 (refunded) but on iOS it will always be 0 (purchased)

				purchaseTime	property	 
				public var purchaseTime:Number
				The time the product was purchased, in milliseconds since the epoch (Jan 1, 1970).

				purchaseToken	property	 
				public var purchaseToken:String
				Transaction identifier or purchase token is a unique string which identifies a successful payment transaction. you may wish to save this value for your later references in your app.

			 */
			
			
		}	
		// SIMULATION
		static private function onSimulationPurchase(success:Boolean, billingType:int, itemId:String, payloadMessage:String = ""):void {
			// Find the correct callback according to billing type
			var callback:Function;
			if (billingType == BillingType.CONSUMABLE) callback = _purchaseCallback;
			else if (billingType == BillingType.PERMANENT) callback = _permPurchasesCallback;
			else if (billingType == BillingType.AUTO_RENEWAL) callback = _subPurchasesCallback;
			// Proceed with callbacks
			callback(success, itemId, "purchase_token", payloadMessage);
		}
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